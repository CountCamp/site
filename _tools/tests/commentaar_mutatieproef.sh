#!/usr/bin/env bash
# ============================================================
# commentaar_mutatieproef.sh — meet de TOETS, niet het filter of de wachter.
#
#   bash _tools/tests/commentaar_mutatieproef.sh
#
# `commentaar_test.sh` groen is een bewering: een toets die nooit rood kán
# worden, staat ook groen. Hier wordt telkens één plek in de ontleder, het
# filter of de wachter kreupel gemaakt (in een kopie van _tools/), en de toets
# moet dat merken. Blijft hij groen, dan was die plek versiering.
# Afloop: 0 elke mutatie opgemerkt, 1 minstens één versiering of mislukte mutatie.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
zorgelijk=0

mutatie() {  # $1 = naam, $2 = bestand in _tools/, $3 = oud, $4 = nieuw
  local naam="$1" bestand="$2"
  rm -rf "$M/kreupel"; mkdir -p "$M/kreupel"
  cp _tools/*.py _tools/teller.html _tools/taalparen.tsv "$M/kreupel/"
  [ -d _tools/taalwissel ] && cp -R _tools/taalwissel "$M/kreupel/"
  python3 - "$M/kreupel/$bestand" "$3" "$4" <<'PY'
import sys
pad, oud, nieuw = sys.argv[1:4]
s = open(pad, encoding="utf-8").read()
if s.count(oud) != 1:
    sys.exit("mutatie niet toepasbaar: %r staat er %d keer in" % (oud, s.count(oud)))
open(pad, "w", encoding="utf-8").write(s.replace(oud, nieuw))
PY
  if [ $? -ne 0 ]; then
    echo "  MISLUKT    $naam -- de mutatie paste niet meer op de code"
    zorgelijk=$((zorgelijk + 1)); return
  fi
  if GEREEDSCHAP="$M/kreupel" bash _tools/tests/commentaar_test.sh > "$M/uit" 2>&1; then
    echo "  VERSIERING $naam -- de toets bleef groen"
    zorgelijk=$((zorgelijk + 1))
  else
    echo "  opgemerkt  $naam -- $(command grep -c '^  ZAKT' "$M/uit") zaak/zaken zakten, bv.:"
    command grep -m1 '^  ZAKT' "$M/uit" | sed 's/^  ZAKT  /               /'
  fi
}

echo "nulmeting: het echte gereedschap"
if bash _tools/tests/commentaar_test.sh > "$M/uit" 2>&1; then
  echo "  ok         $(tail -1 "$M/uit")"
else
  echo "  MISLUKT    de toets staat al rood met het echte gereedschap; dit is geen uitslag"
  tail -8 "$M/uit"; exit 1
fi

echo "mutaties"
mutatie "filter haalt niets weg" commentaarregel.py \
  "    weg = [c for c in lz.commentaren if c.toegestaan is None]
    bewaard = [c for c in lz.commentaren if c.toegestaan is not None]
    if not weg:" \
  "    weg = []
    bewaard = [c for c in lz.commentaren if c.toegestaan is not None]
    if not weg:"
mutatie "script niet meer overgeslagen" commentaarregel.py \
  "RAUW = frozenset({'script', 'style', " "RAUW = frozenset({'style', "
mutatie "stempel van de boekpers niet meer toegestaan" commentaarregel.py \
  "     lambda c: bool(LAB_STEMPEL.fullmatch(c))),"  "     lambda c: False),"
mutatie "toegestane lijst te ruim (elke stempel-achtige)" commentaarregel.py \
  "     lambda c: bool(LAB_STEMPEL.fullmatch(c))),"  "     lambda c: 'countcamp-publicatie' in c),"
mutatie "tellermerken niet meer toegestaan" commentaarregel.py \
  "     lambda c: c in (TELLER_BEGIN, TELLER_EIND)),"  "     lambda c: False),"
mutatie "filter weigert een puzzel niet meer (wist dan zichtbare tekst)" commentaarregel.py \
  "    if nieuw:
        raise RuntimeError" "    if False:
        raise RuntimeError"
mutatie "wachter keurt niets af" commentaarwacht.py \
  "    if vondsten or zoekindex:
        print('\nFOUT" "    if False:
        print('\nFOUT"
mutatie "wachter leest search.json niet" commentaarwacht.py \
  "            if f == 'search.json':" "            if False:"
mutatie "wachter: lege map telt als schoon" commentaarwacht.py \
  "    if n_html == 0:" "    if False:"
mutatie "wachter: onleesbaar telt als schoon" commentaarwacht.py \
  "    if onleesbaar or som_fout:" "    if False:"
mutatie "wachter toont de hele tekst in plaats van 80 tekens" commentaarregel.py \
  "def kort(c: str, breed: int = 80) -> str:" "def kort(c: str, breed: int = 800) -> str:"

# De poort in naar_buiten.sh: een kreupele kopie via NAAR_BUITEN (deel D leest die).
poort() {  # $1 = naam, $2 = oud, $3 = nieuw
  python3 - _tools/naar_buiten.sh "$M/naar_buiten.sh" "$2" "$3" <<'PY'
import sys
bron, uit, oud, nieuw = sys.argv[1:5]
s = open(bron, encoding="utf-8").read()
if s.count(oud) != 1:
    sys.exit("mutatie niet toepasbaar: %r staat er %d keer in" % (oud, s.count(oud)))
open(uit, "w", encoding="utf-8").write(s.replace(oud, nieuw))
PY
  if [ $? -ne 0 ]; then
    echo "  MISLUKT    $1 -- de mutatie paste niet meer op de code"
    zorgelijk=$((zorgelijk + 1)); return
  fi
  if NAAR_BUITEN="$M/naar_buiten.sh" bash _tools/tests/commentaar_test.sh > "$M/uit" 2>&1; then
    echo "  VERSIERING $1 -- de toets bleef groen"
    zorgelijk=$((zorgelijk + 1))
  else
    echo "  opgemerkt  $1 -- $(command grep -c '^  ZAKT' "$M/uit") zaak/zaken zakten, bv.:"
    command grep -m1 '^  ZAKT' "$M/uit" | sed 's/^  ZAKT  /               /'
  fi
}
poort "--productie stopt niet als de commentaarpoort rood is" \
  '    gebouwd_commentaar_nakijken blokkerend || { echo "  Niet geleverd."; exit 1; }' \
  '    gebouwd_commentaar_nakijken blokkerend'
poort "--lokaal roept de commentaarpoort niet aan" \
  '    gebouwd_commentaar_nakijken melden
' ''
poort "de commentaarpoort houdt nooit tegen" \
  '  esac
  if [ "$streng" = blokkerend ]; then return 1; fi
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

huidige_tak()' \
  '  esac
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

huidige_tak()'

echo
if [ "$zorgelijk" -eq 0 ]; then
  echo "elke mutatie werd opgemerkt"
else
  echo "$zorgelijk mutatie(s) NIET opgemerkt of niet toepasbaar"
fi
[ "$zorgelijk" -eq 0 ]
