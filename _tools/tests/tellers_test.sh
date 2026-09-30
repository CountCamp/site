#!/usr/bin/env bash
# ============================================================
# tellers_test.sh — proeft `controleer_tellers.py` op een verse boom in /tmp.
#
#   bash _tools/tests/tellers_test.sh
#
# Waarom een eigen boom en niet de echte site: de wachter moet ROOD kunnen
# worden, en dat is op de echte site niet te maken zonder haar te beschadigen.
# Elke zaak hieronder zet één bladzij neer en eist één uitslag.
#
# De zwaartepunten zitten bij de drie SCHRIJFWIJZEN waarin de teller echt in de
# site staat. Ze zijn hier nagemeten (30-9-2026), niet bedacht:
#   * `<head>`, over twee regels geknipt  — zo schrijft `_quarto-echt.yml` hem
#   * onderaan de `<body>`, met async=""  — zo staat hij in broertjes en ggz_vs
#   * op één regel                        — zo staat hij op de thuispagina
# Een toets die alleen de eerste vorm kent, verklaart de andere twee ten onrechte
# blind. Dat is huisregel 5(c): hetzelfde ding op twee manieren geschreven is
# voor een zoekopdracht twee verschillende dingen.
#
# WACHTER= laat de mutatieproef een kreupele kopie doorschuiven.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
WACHTER="${WACHTER:-_tools/controleer_tellers.py}"
REGEL="${REGEL:-_tools/tellerregel.py}"

M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
gezakt=0
getoetst=0

# De wachter importeert `tellerregel` uit zijn eigen map, dus de kreupele kopie
# moet naast de kreupele regel staan.
GEREED="$M/gereed"
mkdir -p "$GEREED"
cp "$WACHTER" "$GEREED/controleer_tellers.py"
cp "$REGEL"   "$GEREED/tellerregel.py"

# --- de drie schrijfwijzen, letterlijk zoals ze in de site staan ------------
TELLER_EEN_REGEL='<script data-goatcounter="https://countcamp.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>'
TELLER_TWEE_REGELS='<script data-goatcounter="https://countcamp.goatcounter.com/count"
        async src="//gc.zgo.at/count.js"></script>'
TELLER_QUARTO='<script data-goatcounter="https://countcamp.goatcounter.com/count" async="" src="//gc.zgo.at/count.js"></script>'

bladzij() {  # $1 = pad onder de proefboom, $2 = wat er in <head>, $3 = wat er vóór </body>
  mkdir -p "$(dirname "$M/boom/$1")"
  { printf '<!doctype html>\n<html lang="nl">\n<head>\n<meta charset="utf-8">\n<title>proef</title>\n'
    printf '%s\n' "$2"
    printf '</head>\n<body>\n<p>inhoud</p>\n'
    printf '%s\n' "$3"
    printf '</body>\n</html>\n'
  } > "$M/boom/$1"
}

zaak() {  # $1 = naam, $2 = verwachte afloopcode, $3.. = extra vlaggen
  local naam="$1" verwacht="$2"; shift 2
  getoetst=$((getoetst + 1))
  python3 "$GEREED/controleer_tellers.py" --site "$M/boom" \
      --map oefenboeken --map werkboeken "$@" > "$M/uit" 2>&1
  local echt=$?
  if [ "$echt" = "$verwacht" ]; then
    echo "  ok    $naam (afloopcode $echt)"
  else
    echo "  ZAKT  $naam — verwacht afloopcode $verwacht, kreeg $echt"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

verwacht_in_uitvoer() {  # $1 = naam, $2 = tekst die erin moet staan
  getoetst=$((getoetst + 1))
  if grep -qF "$2" "$M/uit"; then
    echo "  ok    $1"
  else
    echo "  ZAKT  $1 — '$2' staat niet in de uitvoer"
    gezakt=$((gezakt + 1))
  fi
}

verwacht_regel() {  # $1 = naam, $2 = regel met enkele spaties, bv "oefenboeken/a 3 3"
  # Witruimte plat: de toets mag niet zakken op de kolombreedte van de wachter.
  # Dat gebeurde hier bij het schrijven — twee zaken stonden rood terwijl de
  # telling klopte, alleen met een andere hoeveelheid spaties. Een toets die op
  # opmaak zakt, leert je hem te negeren.
  getoetst=$((getoetst + 1))
  if tr -s ' ' < "$M/uit" | sed 's/^ //' | grep -qF "$2"; then
    echo "  ok    $1"
  else
    echo "  ZAKT  $1 — regel '$2' staat niet in de uitvoer"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

verwacht_niet_in_uitvoer() {  # $1 = naam, $2 = tekst die er NIET in mag staan
  getoetst=$((getoetst + 1))
  if grep -qF "$2" "$M/uit"; then
    echo "  ZAKT  $1 — '$2' staat wél in de uitvoer"
    gezakt=$((gezakt + 1))
  else
    echo "  ok    $1"
  fi
}

verse_boom() { rm -rf "$M/boom"; mkdir -p "$M/boom/oefenboeken" "$M/boom/werkboeken"; }

echo "tellers_test — wachter: $WACHTER, regel: $REGEL"
echo ""

# === 1. een lege boom bewijst niets en mag niet groen staan =================
verse_boom
zaak "lege boom is BLIND, niet schoon" 3
verwacht_in_uitvoer "  en zegt dat hardop" "NIETS GEMETEN"

# === 2. de drie schrijfwijzen worden alle drie erkend =======================
verse_boom
bladzij "oefenboeken/a/een_regel.html"   "$TELLER_EEN_REGEL"   ""
bladzij "oefenboeken/a/twee_regels.html" "$TELLER_TWEE_REGELS" ""
bladzij "oefenboeken/a/na_body.html"     ""                    "$TELLER_QUARTO"
zaak "alle drie de schrijfwijzen tellen als geteld" 0
verwacht_regel "  en de telling zegt 3 van 3" "oefenboeken/a 3 3 0"

# === 3. een bladzij zonder teller maakt hem rood ============================
verse_boom
bladzij "oefenboeken/a/met.html"    "$TELLER_EEN_REGEL" ""
bladzij "oefenboeken/a/zonder.html" ""                  ""
zaak "een blinde bladzij maakt de wachter rood" 1
verwacht_in_uitvoer "  en noemt het bestand bij naam" "oefenboeken/a/zonder.html"
verwacht_regel      "  en telt 1 van 2"               "oefenboeken/a 1 2 0"

# === 4. een doorstuurder is machinerie, geen bladzij ========================
#     Een teller hier zou ÉÉN bezoek TWEE keer boeken: oude pad plus nieuwe pad.
verse_boom
mkdir -p "$M/boom/werkboeken/ozp1"
cat > "$M/boom/werkboeken/ozp1/index.html" <<'HTML'
<!doctype html>
<html lang="nl"><head><meta charset="utf-8">
<title>Verhuisd naar /oefenboeken/ozp1</title>
<meta name="robots" content="noindex">
<meta http-equiv="refresh" content="0; url=/oefenboeken/ozp1">
</head><body><p>Je wordt doorgestuurd.</p></body></html>
HTML
bladzij "oefenboeken/a/met.html" "$TELLER_EEN_REGEL" ""
zaak "een doorstuurder wordt uitgesloten, niet gemist" 0
verwacht_in_uitvoer  "  en staat bij naam in de uitsluitingen" "doorstuurder   werkboeken/ozp1/index.html"
verwacht_niet_in_uitvoer "  en niet bij de missers"            "ZONDER TELLER"

# === 5. een fragment zonder <head> heeft geen plek voor een script ==========
verse_boom
bladzij "oefenboeken/a/met.html" "$TELLER_EEN_REGEL" ""
printf '<div class="stuk"><p>losse brok</p></div>\n' > "$M/boom/oefenboeken/a/brok.html"
zaak "een fragment zonder head wordt uitgesloten" 0
verwacht_in_uitvoer "  en staat bij naam in de uitsluitingen" "fragment       oefenboeken/a/brok.html"

# === 6. een HALVE teller telt niets en mag niet als geteld gelden ===========
verse_boom
bladzij "oefenboeken/a/half.html" \
  '<script data-goatcounter="https://countcamp.goatcounter.com/count"></script>' ""
zaak "een halve teller maakt de wachter rood" 1
verwacht_in_uitvoer "  en wordt apart als half gemeld" "HALVE TELLER"

# === 7. --repareer zet hem erin, en twee keer draaien zet hem niet twee keer =
verse_boom
bladzij "oefenboeken/a/zonder.html" "" ""
zaak "--repareer maakt de blinde bladzij goed" 0 --repareer
verwacht_in_uitvoer "  en meldt wat het invoegde" "+ oefenboeken/a/zonder.html"
n1=$(grep -cF 'gc.zgo.at/count.js' "$M/boom/oefenboeken/a/zonder.html")
zaak "een tweede ronde vindt niets meer te doen" 0 --repareer
n2=$(grep -cF 'gc.zgo.at/count.js' "$M/boom/oefenboeken/a/zonder.html")
getoetst=$((getoetst + 1))
if [ "$n1" = "1" ] && [ "$n2" = "1" ]; then
  echo "  ok    de teller staat er precies één keer in (na 1 ronde: $n1, na 2: $n2)"
else
  echo "  ZAKT  teller staat er $n1 keer na één ronde en $n2 keer na twee — moet 1 en 1"
  gezakt=$((gezakt + 1))
fi

# === 7b. met_teller() is ZELF idempotent ====================================
#     De zaak hierboven proeft de voorwacht in `controleer_tellers.py`: die
#     roept `met_teller` alleen aan als de teller ontbreekt. `publish_workbook.py`
#     doet dat NIET -- daar gaat elke bladzij er ongezien door. Verliest
#     `met_teller` zijn eigen idempotentie, dan zet het publiceer-script de
#     teller twee keer neer en merkte niets het. Gevonden door de mutatieproef,
#     30-9-2026: dit was een gat in de toets, niet in de wachter.
getoetst=$((getoetst + 1))
if python3 - "$GEREED" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from tellerregel import met_teller, REGEL
kaal = '<!doctype html><html><head><title>p</title></head><body>x</body></html>'
een, wat1 = met_teller(kaal)
twee, wat2 = met_teller(een)
n = twee.count('gc.zgo.at/count.js')
if wat1 != 'toegevoegd':
    sys.exit('eerste ronde gaf %r, moet toegevoegd' % wat1)
if wat2 != 'al_goed':
    sys.exit('tweede ronde gaf %r, moet al_goed' % wat2)
if n != 1:
    sys.exit('teller staat er %d keer in na twee rondes, moet 1' % n)
if twee != een:
    sys.exit('de tweede ronde veranderde de tekst toch')
PY
then
  echo "  ok    met_teller() zet de teller er niet twee keer in"
else
  echo "  ZAKT  met_teller() is niet idempotent"
  gezakt=$((gezakt + 1))
fi

# === 8. --repareer verandert alleen die ene regel ===========================
verse_boom
bladzij "oefenboeken/a/zonder.html" "" ""
cp "$M/boom/oefenboeken/a/zonder.html" "$M/voor.html"
python3 "$GEREED/controleer_tellers.py" --site "$M/boom" --map oefenboeken \
        --map werkboeken --repareer > /dev/null 2>&1
getoetst=$((getoetst + 1))
anders=$(diff "$M/voor.html" "$M/boom/oefenboeken/a/zonder.html" \
         | grep -c '^[<>]')
toegevoegd=$(diff "$M/voor.html" "$M/boom/oefenboeken/a/zonder.html" \
             | grep '^>' | grep -cF 'gc.zgo.at/count.js')
if [ "$anders" = "1" ] && [ "$toegevoegd" = "1" ]; then
  echo "  ok    het verschil is precies één regel, en dat is de teller"
else
  echo "  ZAKT  $anders regel(s) verschil, waarvan $toegevoegd de teller — moet 1 en 1"
  gezakt=$((gezakt + 1))
fi

echo ""
if [ "$gezakt" = "0" ]; then
  echo "$getoetst zaken getoetst, alles groen."
  exit 0
fi
echo "$getoetst zaken getoetst, $gezakt GEZAKT."
exit 1
