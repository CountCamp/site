#!/usr/bin/env bash
# ============================================================
# doorstuurders_mutatieproef.sh — meet de TOETS, niet de wachter.
#
# `doorstuurders_test.sh` staat groen. Dat is een bewering, geen bewijs: een
# toets die nooit rood kán worden, staat ook groen. Deze proef maakt de
# wachter telkens op één plek kreupel en eist dat de toets dat merkt.
#
#   bash _tools/tests/doorstuurders_mutatieproef.sh
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
SLECHT=0

proef() {  # $1 = naam, $2 = 'oud|||nieuw' dat de wachter kreupel maakt
  cp _tools/doorstuurders.py "$M/kreupel.py"
  # Een mutatie die niet aanslaat, mag niet als uitslag tellen -- dan meet de
  # proef zichzelf in plaats van de wachter.
  if ! python3 - "$M/kreupel.py" "$2" <<'PY'
import sys
pad, oud_nieuw = sys.argv[1], sys.argv[2]
oud, nieuw = oud_nieuw.split("|||")
s = open(pad, encoding="utf-8").read()
if oud not in s:
    sys.exit(f"mutatie niet gevonden: {oud!r}")
open(pad, "w", encoding="utf-8").write(s.replace(oud, nieuw, 1))
PY
  then
    echo "  MISLUKT    $1 -- de mutatie sloeg niet aan; dit is geen uitslag"
    SLECHT=$((SLECHT + 1))
    return
  fi
  if DOORSTUUR="$M/kreupel.py" bash _tools/tests/doorstuurders_test.sh >"$M/uit" 2>&1; then
    echo "  ZORGELIJK  $1 -- de toets bleef GROEN terwijl de wachter kreupel is"
    SLECHT=$((SLECHT + 1))
  else
    echo "  ok         $1 -- de toets wordt rood ($(grep -c 'ZAKT' "$M/uit") gezakt)"
  fi
}

echo "mutatieproef — maakt de doorstuurwachter kreupel en kijkt of de toets dat merkt"
# De melding wordt ingeslikt, het script blijft heel. (Een eerdere versie
# van deze mutatie maakte een syntaxfout en liet 17 zaken zakken -- dan meet
# je of Python draait, niet of de wachter bijt.)
proef "een verdwenen doorstuurder telt als goed" \
  "            fouten.append('ONTBREEKT|||            (lambda *a: None)('ONTBREEKT"
proef "de inhoud wordt niet met de tabel vergeleken" \
  "            elif t != stub(nieuw):|||            elif False:"
proef "het doel wordt niet nagekeken" \
  "        if wordt is None:|||        if False:"
proef "een ketting van doorstuurders mag" \
  "        elif wordt == 'bestand' and soort(lees(os.path.join(site, nieuw))) != 'bladzij':|||        elif False:"
proef "--bouw schrijft over een echte bladzij heen" \
  "            if soort(staat) != 'doorstuurder':|||            if False:"
proef "vreemde doorstuurders worden niet nagekeken" \
  "        elif wordt_bladzij(site, d) is None:|||        elif False:"
proef "een bron (.qmd) telt niet als bladzij" \
  "        for ext in BRONNEN:|||        for ext in ():"
proef "zonder tabel heet het goed" \
  "        return 3
    rijen = lees_tabel(tabel)|||        return 0
    rijen = lees_tabel(tabel)"
proef "een tabel zonder bouwrijen heet goed" \
  "    if not bouwen:|||    if False:"
proef "geen procent-codering in het doel" \
  "    return '/' + quote(nieuw, safe='/')|||    return '/' + nieuw"
[ "$SLECHT" -eq 0 ] || { echo "mutatieproef: $SLECHT proef/proeven zonder uitslag of zonder beet"; exit 1; }
echo "elke mutatie werd opgemerkt; de toets meet echt iets."
