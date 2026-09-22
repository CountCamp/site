#!/usr/bin/env bash
# ============================================================
# plankwacht_mutatieproef.sh — meet de TOETS, niet de wachter.
#
# `plankwacht_test.sh` staat groen. Dat is een bewering, geen bewijs: een toets
# die nooit rood kán worden, staat ook groen. Deze proef maakt de wachter
# telkens op één plek kreupel en eist dat de toets dat merkt.
#
# Blijft de toets groen bij een kreupele wachter, dan is die zaak versiering.
#
#   bash _tools/tests/plankwacht_mutatieproef.sh
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"

proef() {  # $1 = naam, $2 = sed-uitdrukking die de wachter kreupel maakt
  cp _tools/plankwacht.py "$M/kreupel.py"
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
    return
  fi
  if PLANKWACHT="$M/kreupel.py" bash _tools/tests/plankwacht_test.sh >"$M/uit" 2>&1; then
    echo "  ZORGELIJK  $1 -- de toets bleef GROEN terwijl de wachter kreupel is"
  else
    echo "  ok         $1 -- de toets wordt rood"
    grep -c 'ZAKT' "$M/uit" | sed 's/^/             gezakte zaken: /'
  fi
}

echo "mutatieproef — maakt de wachter kreupel en kijkt of de toets dat merkt"
proef "datumvergelijking uitgezet"    'if echt != beweerd:|||if False:'
proef "thema-telling uitgezet"        'if len(gepubliceerd) != beweerd:|||if False:'
proef "blind telt voortaan als goed"  '    if blind:|||    if False and blind:'
proef "niets gemeten telt als goed"   '    if getoetst == 0:|||    if False and getoetst == 0:'
proef "verweesde map wordt genegeerd" 'if verweesd:|||if False:'
rm -rf "$M"
