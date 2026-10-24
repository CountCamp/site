#!/usr/bin/env bash
# ============================================================
# publiceer_en_werkruimte_mutatieproef.sh — meet de TOETS, niet het script.
#
# `publiceer_en_werkruimte_test.sh` staat groen. Dat is een bewering, geen
# bewijs: een toets die nooit rood kán worden, staat ook groen. Deze proef maakt
# telkens één bescherming kapot (in de wegwerpkloon van de toets, nooit hier) en
# eist dat de toets dat merkt. Per mutatie draait alleen het geval dat erop hoort
# te bijten; het hele rondje duurt zo een minuut of zeven.
#
#   bash _tools/tests/publiceer_en_werkruimte_mutatieproef.sh
#
# Afloop: 0 elke mutatie gevangen, 1 minstens één niet (of sloeg niet aan).
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 3
TOETS=_tools/tests/publiceer_en_werkruimte_test.sh
UIT=_site_en_werk/mutatieproef_werkruimte
mkdir -p "$UIT"
SLECHT=0

proef() {  # $1 = naam, $2 = geval(len), $3 = "bestand|||oud|||nieuw"
  local log="$UIT/$(echo "$1" | tr -c 'a-z0-9' '_').log"
  PROEF_MUTATIE="$3" bash "$TOETS" $2 > "$log" 2>&1
  case $? in
    0) echo "  ZORGELIJK  $1 -- de toets bleef GROEN (geval $2)"; SLECHT=$((SLECHT + 1)) ;;
    1) echo "  ok         $1 -- de toets wordt rood (geval $2)"
       grep '^FOUT' "$log" | head -2 | sed 's/^/             /' ;;
    2) echo "  MISLUKT    $1 -- de mutatie sloeg niet aan; dit is geen uitslag"
       grep 'MUTATIE' "$log" | sed 's/^/             /'; SLECHT=$((SLECHT + 1)) ;;
    *) echo "  MISLUKT    $1 -- de toets kon niet kijken; dit is geen uitslag (zie $log)"; SLECHT=$((SLECHT + 1)) ;;
  esac
}

echo "mutatieproef — maakt één bescherming kapot en kijkt of de toets dat merkt"
# fout 1: .claude/ in de bouw
proef "de uitsluiting van .claude/ weg uit _quarto-nl.yml" 1 \
  '_quarto-nl.yml|||    - "!.claude/**"|||    - "!.claude-niet/**"'
proef "keuring 0 (werkruimte) uitgezet" 6 \
  '_tools/en_bouw.py|||        if WERKRUIMTE in dn:|||        if False:'
proef "de taalbalk-keuring loopt weer door .claude/" 6 \
  '_tools/en_bouw.py|||    for dp, _d, fs in loop(site):|||    for dp, _d, fs in os.walk(site):'
# fout 2: een mislukte run laat de repo zoals hij was
proef "de Engelse bouw zet en/ niet terug" 8 \
  '_tools/en_bouw.py|||        h_code, h_regels = herstel(voor_bouw)|||        h_code, h_regels = 0, ["(uitgezet)"]'
proef "stop() zet de repo niet terug" 4 \
  '_tools/publiceer_en.sh|||  if [ "$BEWAARD_NU" -eq 1 ]; then|||  if false; then'
proef "stop() schrijft het manifest weer in _tools/" 2 \
  '_tools/publiceer_en.sh|||MANIFEST="$WERK/en_manifest.txt"|||MANIFEST="$REPO/_tools/en_manifest.txt"'
proef "herstel zet alleen terug wat ontbreekt, niet wat anders is" 4 \
  '_tools/en_bouw.py|||        if rel not in nu or _sha(dst) != lijst["en"][rel]:|||        if rel not in nu:'
proef "herstel laat staan wat de run erbij zette" 4 \
  '_tools/en_bouw.py|||        os.remove(os.path.join(en, rel))|||        pass'
# de voor de hand liggende "reparatie" die iemand zou schrijven: terug naar de
# laatste commit. Gooit dan een geslaagde, nog niet gecommitte en/ weg.
proef "stop() gaat terug naar de laatste commit, niet naar wat er stond" 5 \
  '_tools/publiceer_en.sh|||    $PY herstel --van "$BEWAARD" \|||    git checkout -q -- en _tools/en_manifest.txt \'
proef "geen trap: afschieten zet niets terug" 7 \
  "_tools/publiceer_en.sh|||trap 'stop 3|||: 'stop 3"
proef "herstel gebruikt ook een halve kopie" 9 \
  '_tools/en_bouw.py|||    if {r: _sha(p) for r, p in oud.items()} != lijst["en"]:|||    if False:'

[ "$SLECHT" -eq 0 ] || { echo "mutatieproef: $SLECHT proef/proeven zonder uitslag of zonder beet"; exit 1; }
echo "mutatieproef: elke mutatie gevangen (logboeken: $UIT/)"
