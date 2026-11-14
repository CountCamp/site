#!/usr/bin/env bash
# ============================================================
# tellerwacht_test.sh — proeft de bouwstap (teller_zetten.py) én de wachter
# (tellerwacht.py) op ECHTE bladzijden uit deze repo, in een proefboom in /tmp.
#
#   bash _tools/tests/tellerwacht_test.sh
#   WACHTER=<kreupele kopie> bash _tools/tests/tellerwacht_test.sh   # mutatieproef
#
# De proefboom bestaat uit bronnen zoals ze in deze repo staan, mét de teller
# zoals die er tot 8-10-2026 in stond. Dat zijn precies de vijf schrijfwijzen
# die in de site voorkwamen, en elke bladzij is er bij gekozen om er één te
# dragen:
#   oefenboeken/ggz_vs/index.html       async=""          onderaan <body>
#   manuscript/h4.html                  data-external="1" (1,9 MB, alles ingebakken)
#   power/index.html                    één regel         onderaan <body>
#   manuscript/handleiding/index.html   over twee regels  in <head>
#   speeltjes/casino.html               één regel         in <head>
# plus een doorstuurder en het Google-verificatiebestand (geen <head>).
#
# Wat de opdracht vroeg (8-10-2026) staat in zaak 3 en 4: haal één teller weg,
# zet er één dubbel in -- de wachter moet rood worden. De rest van de zaken
# bestaat omdat elk ervan een manier is waarop het in het echt mis kan gaan.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
WACHTER="${WACHTER:-_tools/tellerwacht.py}"

M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
gezakt=0
getoetst=0

# Het gereedschap gaat mee naar de proefboom: de toets moet teller.html kunnen
# veranderen (zaak 8) zonder het echte bestand aan te raken.
G="$M/gereed"
mkdir -p "$G/_tools" "$G/_spooksite"
cp _tools/tellerregel.py _tools/teller.html _tools/teller_zetten.py "$G/_tools/"
cp "$WACHTER" "$G/_tools/tellerwacht.py"
cp _spooksite/maak_banner.sh "$G/_spooksite/"
bash "$G/_spooksite/maak_banner.sh" "toets" "tellerwacht_test" >/dev/null

BLADZIJDEN="oefenboeken/ggz_vs/index.html manuscript/h4.html power/index.html
manuscript/handleiding/index.html speeltjes/casino.html werkboeken/ggz_vs/index.html
google7b04654a69a0c7b2.html"

verse_boom() {   # $1 = naam van de boom; kopieert de bronnen zoals ze in de repo staan
  rm -rf "$M/$1"
  for b in $BLADZIJDEN; do
    mkdir -p "$(dirname "$M/$1/$b")"
    cp "$b" "$M/$1/$b"
  done
}

zaak() {  # $1 = naam, $2 = verwachte afloopcode, $3.. = commando
  local naam="$1" verwacht="$2"; shift 2
  getoetst=$((getoetst + 1))
  "$@" > "$M/uit" 2>&1
  local echt=$?
  if [ "$echt" = "$verwacht" ]; then
    echo "  ok    $naam (afloopcode $echt)"
  else
    echo "  ZAKT  $naam — verwacht afloopcode $verwacht, kreeg $echt"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

in_uitvoer() {  # $1 = naam, $2 = tekst die erin moet staan
  getoetst=$((getoetst + 1))
  if grep -qF -- "$2" "$M/uit"; then
    echo "  ok    $1"
  else
    echo "  ZAKT  $1 — '$2' staat niet in de uitvoer:"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

zetten() { python3 "$G/_tools/teller_zetten.py" "$@"; }
wacht()  { python3 "$G/_tools/tellerwacht.py" --teller "$G/_tools/teller.html" "$@"; }

muteer() {  # $1 = bestand, $2 = python-uitdrukking over s (de inhoud) -> nieuwe inhoud
  python3 - "$1" "$2" "$G/_tools/teller.html" <<'PY'
import sys
pad, expr, tellerpad = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(pad, encoding="utf-8").read()
blok = open(tellerpad, encoding="utf-8").read().strip() + "\n"
OUD = '<script data-goatcounter="https://countcamp.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>'
nieuw = eval(expr)
if nieuw == s:
    sys.exit("mutatie veranderde niets aan " + pad + " -- deze zaak zou om de verkeerde reden slagen")
open(pad, "w", encoding="utf-8").write(nieuw)
PY
}

echo "== echt: de bronnen zoals ze nu zijn, door de bouwstap"
verse_boom echt
zaak "0  de bronnen zelf zakken (losse tellers, geen hostwacht)" 1 wacht --echt --site "$M/echt"
in_uitvoer "0b ... en de wachter zegt waarom" "losse teller zonder hostwacht: 5"
zaak "1  bouwstap --echt" 0 zetten --echt --site "$M/echt"
in_uitvoer "1b ... 5 bladzijden, 1 doorstuurder, 1 fragment, 5 bijgewerkt" "5 bladzijden, 1 doorstuurders, 1 fragmenten; 5 bestanden bijgewerkt"
zaak "2  wachter --echt staat groen na de bouwstap" 0 wacht --echt --site "$M/echt"
in_uitvoer "2b ... alle 5 bladzijden" "alle 5 bladzijden dragen precies één teller"
( cd "$M/echt" && find . -type f -exec shasum {} + | sort ) > "$M/voor.sha"
zaak "2c bouwstap nog eens (idempotent)" 0 zetten --echt --site "$M/echt"
in_uitvoer "2d ... verandert dan niets" "0 bestanden bijgewerkt"
( cd "$M/echt" && find . -type f -exec shasum {} + | sort ) > "$M/na.sha"
getoetst=$((getoetst + 1))
if cmp -s "$M/voor.sha" "$M/na.sha"; then echo "  ok    2e ... ook byte voor byte"
else echo "  ZAKT  2e de tweede run veranderde bestanden"; gezakt=$((gezakt + 1)); fi
getoetst=$((getoetst + 1))
if cmp -s google7b04654a69a0c7b2.html "$M/echt/google7b04654a69a0c7b2.html" \
   && cmp -s werkboeken/ggz_vs/index.html "$M/echt/werkboeken/ggz_vs/index.html"; then
  echo "  ok    2f fragment en doorstuurder onaangeroerd"
else echo "  ZAKT  2f het fragment of de doorstuurder is veranderd"; gezakt=$((gezakt + 1)); fi

echo "== mutaties op de gebouwde boom (de opdracht: weghalen, verdubbelen)"
cp -R "$M/echt" "$M/schoon"
muteer "$M/echt/power/index.html" 's.replace(blok, "")'
zaak "3  één teller weggehaald -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "3b ... met de naam van de bladzij" "power/index.html  [geen teller]"
rm -rf "$M/echt"; cp -R "$M/schoon" "$M/echt"
muteer "$M/echt/manuscript/h4.html" 's.replace(blok, blok + blok)'
zaak "4  teller verdubbeld -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "4b ... en hij zegt dat het dubbel telt" "teller 2x -- elk bezoek telt dubbel"
rm -rf "$M/echt"; cp -R "$M/schoon" "$M/echt"
muteer "$M/echt/speeltjes/casino.html" 's.replace("</body>", OUD + "\n</body>")'
zaak "5  oude teller zonder hostwacht erbij geplakt -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "5b ... als losse teller" "speeltjes/casino.html  [losse teller zonder hostwacht (1x)"
rm -rf "$M/echt"; cp -R "$M/schoon" "$M/echt"
muteer "$M/echt/oefenboeken/ggz_vs/index.html" 's.replace(blok, blok.replace("countcamp.org", "countcamp.org\x27 || true || \x27"))'
zaak "6  hostwacht in één bladzij uitgeschakeld -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "6b ... als verouderde teller" "verouderde teller"
rm -rf "$M/echt"; cp -R "$M/schoon" "$M/echt"
muteer "$M/echt/manuscript/handleiding/index.html" 's.replace("</body>", "<noscript><img src=\"https://countcamp.goatcounter.com/count?p=/x\"></noscript>\n</body>")'
zaak "7  telpixel zonder script (ziet de knipper niet) -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "7b ... dankzij de domme telling" "onbekende teller"
muteer "$M/echt/werkboeken/ggz_vs/index.html" 's.replace("</head>", OUD + "</head>")'
zaak "7c doorstuurder met teller -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "7d ... want één bezoek telt dan twee keer" "doorstuurder met teller"
zaak "7e bouwstap herstelt wat hij kan" 0 zetten --echt --site "$M/echt"
zaak "7f ... de telpixel blijft rood (die moet een mens weghalen)" 1 wacht --echt --site "$M/echt"
in_uitvoer "7g ... en alleen die" "FOUT -- 1 bevinding"

echo "== de teller veranderen = één bestand veranderen"
rm -rf "$M/echt"; cp -R "$M/schoon" "$M/echt"
cp "$G/_tools/teller.html" "$M/teller.bewaard"
python3 - "$G/_tools/teller.html" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(s.replace("gc.zgo.at/count.js", "gc.zgo.at/count.v5.js"))
PY
zaak "8  nieuwe teller.html, oude bouw -> rood op alle 5" 1 wacht --echt --site "$M/echt"
in_uitvoer "8b ... verouderde teller: 5" "verouderde teller: 5"
zaak "8c bouwstap zet overal de nieuwe" 0 zetten --echt --site "$M/echt"
zaak "8d wachter groen" 0 wacht --echt --site "$M/echt"
getoetst=$((getoetst + 1))
n=$(grep -l 'count.v5.js' $(find "$M/echt" -name '*.html') | wc -l | tr -d ' ')
if [ "$n" = 5 ]; then echo "  ok    8e de nieuwe versie staat in alle 5 bladzijden"
else echo "  ZAKT  8e de nieuwe versie staat in $n van de 5 bladzijden"; gezakt=$((gezakt + 1)); fi
cp "$M/teller.bewaard" "$G/_tools/teller.html"

echo "== spook: de proefdruk"
verse_boom spook
zaak "9  bouwstap --spook" 0 zetten --spook --site "$M/spook"
zaak "10 wachter --spook groen" 0 wacht --spook --site "$M/spook"
in_uitvoer "10b ... geen teller, overal balk en noindex" "alle 5 bladzijden dragen de balk en noindex"
zaak "11 wachter --echt op een proefdruk -> rood" 1 wacht --echt --site "$M/spook"
zaak "12 wachter --spook op de echte bouw -> rood" 1 wacht --spook --site "$M/schoon"
in_uitvoer "12b ... teller in een proefdruk" "teller in een proefdruk"
cp -R "$M/spook" "$M/spookschoon"
muteer "$M/spook/power/index.html" 's.replace("</body>", OUD + "\n</body>")'
zaak "13 proefdruk met een teller erin -> rood" 1 wacht --spook --site "$M/spook"
rm -rf "$M/spook"; cp -R "$M/spookschoon" "$M/spook"
muteer "$M/spook/manuscript/h4.html" 's.replace("class=\"spookbalk\"", "class=\"gewoon\"")'
zaak "14 proefdruk zonder balk -> rood" 1 wacht --spook --site "$M/spook"
in_uitvoer "14b ... met de naam van de bladzij" "manuscript/h4.html  [proefdruk-balk 0x"

echo "== weigeren en blind"
zaak "15 bouwstap met onbekend profiel weigert" 1 env QUARTO_PROFILE=spok python3 "$G/_tools/teller_zetten.py" --site "$M/schoon"
zaak "16 bouwstap leest het profiel uit QUARTO_PROFILE" 0 env QUARTO_PROFILE=echt python3 "$G/_tools/teller_zetten.py" --site "$M/schoon"
mv "$G/_spooksite/banner.html" "$M/banner.bewaard"
zaak "17 spook zonder balkbestand weigert" 1 zetten --spook --site "$M/spookschoon"
mv "$M/banner.bewaard" "$G/_spooksite/banner.html"
mkdir -p "$M/leeg"
zaak "18 lege map: kon niet kijken" 3 wacht --echt --site "$M/leeg"
zaak "19 map bestaat niet: kon niet kijken" 3 wacht --echt --site "$M/bestaat_niet"
zaak "20 bouwstap in lege map: niets gezien" 3 zetten --echt --site "$M/leeg"

echo
echo "$((getoetst - gezakt)) ok, $gezakt gezakt (van $getoetst)"
[ "$gezakt" -eq 0 ]
