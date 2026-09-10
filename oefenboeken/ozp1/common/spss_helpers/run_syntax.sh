#!/usr/bin/env bash
# run_syntax.sh — batch-runner voor SPSS-syntax-files in dit werkboek.
#
# Gebruik:
#   ./run_syntax.sh <pad/naar/script.sps>
#
# Wat het doet:
#   - Probeert de SPSS Statistics .app op deze Mac aan te roepen in
#     batch-modus via /Applications/IBM SPSS Statistics/SPSS Statistics.app/Contents/MacOS/stats.
#   - Production-mode is op deze installatie *niet* headless werkend
#     (vereist GUI-licentiebinding). Daarom valt het script terug op
#     handmatige instructies als batch faalt.
#   - Als de batch lukt: PNG's verschijnen in ../pics/ en .spv in ../output_raw/.
#
# Status (2026-05-11): headless batch werkt niet op deze SPSS-install.
# Workaround: open de .sps in SPSS GUI (dubbelklik), run-all, en exporteer
# output via Bestand → Exporteren naar /pics/*.png.

set -e

if [ $# -lt 1 ]; then
  echo "Gebruik: $0 <pad/naar/script.sps>"
  exit 1
fi

SPS_FILE="$1"
if [ ! -f "$SPS_FILE" ]; then
  echo "Bestand niet gevonden: $SPS_FILE"
  exit 1
fi

SPSS_BIN="/Applications/IBM SPSS Statistics/SPSS Statistics.app/Contents/MacOS/stats"

if [ ! -x "$SPSS_BIN" ]; then
  echo "SPSS niet gevonden op $SPSS_BIN"
  echo "Installeer SPSS Statistics of pas dit script aan."
  exit 1
fi

echo "Probeer batch-run van: $SPS_FILE"
echo "(Headless batch is op deze SPSS-install niet betrouwbaar — kan stilletjes niets doen.)"
echo ""

"$SPSS_BIN" -production silent "$SPS_FILE" || true

echo ""
echo "Klaar. Controleer of PNGs/spv zijn aangemaakt."
echo "Als er niets gegenereerd is: open de .sps in SPSS GUI en run-all + export handmatig."
