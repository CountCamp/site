#!/usr/bin/env bash
# ============================================================
# tellerwacht_mutatieproef.sh — meet de TOETS, niet de wachter.
#
#   bash _tools/tests/tellerwacht_mutatieproef.sh
#
# `tellerwacht_test.sh` groen is een bewering: een toets die nooit rood kán
# worden, staat ook groen. Hier wordt de wachter telkens op één plek kreupel
# gemaakt, en de toets moet dat merken. Blijft hij groen, dan was die plek in
# de wachter versiering.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
zorgelijk=0

mutatie() {  # $1 = naam, $2 = oud, $3 = nieuw
  local naam="$1"
  python3 - "$2" "$3" "$M/kreupel.py" <<'PY'
import sys
oud, nieuw, uit = sys.argv[1], sys.argv[2], sys.argv[3]
s = open("_tools/tellerwacht.py", encoding="utf-8").read()
if s.count(oud) != 1:
    sys.exit("mutatie niet toepasbaar: %r staat er %d keer in" % (oud, s.count(oud)))
open(uit, "w", encoding="utf-8").write(s.replace(oud, nieuw))
PY
  if [ $? -ne 0 ]; then
    echo "  MISLUKT    $naam -- de mutatie paste niet meer op de code"
    zorgelijk=$((zorgelijk + 1)); return
  fi
  if WACHTER="$M/kreupel.py" bash _tools/tests/tellerwacht_test.sh > "$M/uit" 2>&1; then
    echo "  VERSIERING $naam -- de toets bleef groen"
    zorgelijk=$((zorgelijk + 1))
  else
    echo "  opgemerkt  $naam -- $(grep -c '^  ZAKT' "$M/uit") zaak/zaken zakten, bv.:"
    grep -m1 '^  ZAKT' "$M/uit" | sed 's/^  ZAKT  /               /'
  fi
}

echo "nulmeting: de echte wachter"
if bash _tools/tests/tellerwacht_test.sh > "$M/uit" 2>&1; then
  echo "  ok         $(tail -1 "$M/uit")"
else
  echo "  MISLUKT    de toets staat al rood met de echte wachter; dit is geen uitslag"
  tail -5 "$M/uit"; exit 1
fi

echo "mutaties"
mutatie "keurt niets meer af" \
  '    ruw = ruwe_telling(tekst)' \
  '    return []
    ruw = ruwe_telling(tekst)'
mutatie "ziet geen dubbele teller" \
  "if t['goed'] > 1:" "if t['goed'] > 2:"
mutatie "ziet geen losse teller" \
  "    if t['los']:" "    if False:"
mutatie "domme telling weg" \
  "if not fout and any(v != 1 for v in ruw.values()):" "if False:"
mutatie "doorstuurder niet gekeurd" \
  "        if n_ruw:
            fout.append('doorstuurder" \
  "        if False:
            fout.append('doorstuurder"
mutatie "balk niet geteld in proefdruk" \
  "if balken != 1:" "if balken < 0:"
mutatie "blind is groen" \
  "        return 3

    print('')" \
  "        return 0

    print('')"

echo
if [ "$zorgelijk" -eq 0 ]; then
  echo "Alle mutaties opgemerkt."
else
  echo "$zorgelijk mutatie(s) NIET opgemerkt of niet toepasbaar."
fi
[ "$zorgelijk" -eq 0 ]
