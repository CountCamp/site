#!/usr/bin/env bash
# ============================================================
# sitemapwacht_test.sh — proeft de bouwstap (sitemap_zetten.py) én de wachter
# (sitemapwacht.py) op ECHTE bladzijden uit deze repo, in een proefboom in /tmp.
#
#   bash _tools/tests/sitemapwacht_test.sh
#   WACHTER=<kreupele kopie> bash _tools/tests/sitemapwacht_test.sh   # mutatieproef
#
# De proefboom: bladzijden zoals ze in deze repo staan, elk gekozen om één geval
# te dragen:
#   oefenboeken/ggz_vs/index.html     een map-index: adres …/ en niet …/index.html
#   power/index.html                  draagt in de bron al een canonical (goed)
#   speeltjes/solomon.html + -en      een taalpaar: hreflang over en weer
#   en/index.html                     Engels, hreflang naar de wortel
#   manuscript/handleiding/hoofdstuk-1---het-beschrĳven-….html
#                                     een ĳ in de bestandsnaam: procent-codering
#   manuscript/h4.html                groot (2 MB, alles ingebakken)
#   manuscript/handleiding/404.html   een foutbladzij: niet in de sitemap
#   werkboeken/ggz_vs/index.html      een doorstuurder: niet in de sitemap
#   google7b04654a69a0c7b2.html       een fragment zonder <head>
# plus een kleine wortel-index.html (die rendert Quarto; hij staat niet als
# bestand in de repo, en en/index.html verwijst ernaar).
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
WACHTER="${WACHTER:-_tools/sitemapwacht.py}"

M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
gezakt=0
getoetst=0

G="$M/gereed"
mkdir -p "$G/_tools"
cp _tools/tellerregel.py _tools/teller.html _tools/teller_zetten.py _tools/sitemapregel.py \
   _tools/sitemap_zetten.py _tools/doorstuurders.py _tools/doorstuurders.tsv "$G/_tools/"
cp "$WACHTER" "$G/_tools/sitemapwacht.py"
printf '# leeg\nbladzij\twijst_naar\n' > "$G/_tools/canoniek_anders.tsv"

HANDLEIDING1="$(cd manuscript/handleiding && ls hoofdstuk-1---*.html)"
BLADZIJDEN="oefenboeken/ggz_vs/index.html power/index.html speeltjes/solomon.html
speeltjes/solomon-en.html en/index.html manuscript/h4.html
manuscript/handleiding/404.html werkboeken/ggz_vs/index.html google7b04654a69a0c7b2.html"

verse_boom() {   # $1 = naam van de boom
  rm -rf "$M/$1"
  for b in $BLADZIJDEN; do
    mkdir -p "$(dirname "$M/$1/$b")"
    cp "$b" "$M/$1/$b"
  done
  mkdir -p "$M/$1/manuscript/handleiding"
  cp "manuscript/handleiding/$HANDLEIDING1" "$M/$1/manuscript/handleiding/"
  cat > "$M/$1/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="nl"><head>
<meta charset="utf-8">
<title>CountCamp</title>
<link rel="alternate" hreflang="nl" href="https://countcamp.org/">
<link rel="alternate" hreflang="en" href="https://countcamp.org/en/">
</head><body><p>Thuis.</p></body></html>
HTML
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
  if command grep -qF -- "$2" "$M/uit"; then
    echo "  ok    $1"
  else
    echo "  ZAKT  $1 — '$2' staat niet in de uitvoer:"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

zetten() { python3 "$G/_tools/sitemap_zetten.py" --anders "$G/_tools/canoniek_anders.tsv" "$@"; }
wacht()  { python3 "$G/_tools/sitemapwacht.py" --anders "$G/_tools/canoniek_anders.tsv" "$@"; }

muteer() {  # $1 = bestand, $2 = python-uitdrukking over s (de inhoud) -> nieuwe inhoud
  python3 - "$1" "$2" <<'PY'
import sys
pad, expr = sys.argv[1], sys.argv[2]
s = open(pad, encoding="utf-8").read()
nieuw = eval(expr)
if nieuw == s:
    sys.exit("mutatie veranderde niets aan " + pad + " -- deze zaak zou om de verkeerde reden slagen")
open(pad, "w", encoding="utf-8").write(nieuw)
PY
}

C_GGZ='<link rel="canonical" href="https://countcamp.org/oefenboeken/ggz_vs/">'

echo "== de afspraak staat op één plek"
getoetst=$((getoetst + 1))
if python3 - <<'PY'
import re, sys
sys.path.insert(0, "_tools")
import sitemapregel as R
bronnen = {
    "_quarto.yml": re.findall(r'^\s*site-url:\s*"([^"]*)"', open("_quarto.yml").read(), re.M),
    "_quarto-echt.yml": re.findall(r'^\s*site-url:\s*"([^"]*)"', open("_quarto-echt.yml").read(), re.M),
    "CNAME": ["https://" + open("CNAME").read().strip()],
}
mis = {k: v for k, v in bronnen.items() if v != [R.SITE_URL]}
if mis:
    sys.exit("sitemapregel.SITE_URL is %r, maar: %r" % (R.SITE_URL, mis))
PY
then echo "  ok    0  SITE_URL = site-url in _quarto.yml en _quarto-echt.yml = CNAME"
else echo "  ZAKT  0  SITE_URL wijkt af"; gezakt=$((gezakt + 1)); fi

echo "== echt: de bronnen zoals ze nu zijn, door de bouwstap"
verse_boom echt
zaak "1  de bronnen zelf zakken (geen sitemap, geen canonical)" 1 wacht --echt --site "$M/echt"
in_uitvoer "1b ... en de wachter zegt waarom" "geen sitemap.xml: 1"
in_uitvoer "1c ... ook de canonicals" "geen canonical: 5"
zaak "2  bouwstap --echt" 0 zetten --echt --site "$M/echt"
in_uitvoer "2b ... 8 echte bladzijden, doorstuurder, fragment en 404 erbuiten" "8 echte bladzijden; buiten de sitemap: 1 doorstuurders, 1 fragmenten, 0 noindex, 1 foutbladzijden (404)"
in_uitvoer "2c ... 5 canonicals gezet, 3 stonden al goed (power, solomon, solomon-en)" "canonical gezet in 5 bladzijden, 3 hadden hem al goed"
zaak "3  wachter --echt staat groen na de bouwstap" 0 wacht --echt --site "$M/echt"
in_uitvoer "3b ... alle 8" "alle 8 echte bladzijden"
getoetst=$((getoetst + 1))
if command grep -qxF '  <url><loc>https://countcamp.org/oefenboeken/ggz_vs/</loc></url>' "$M/echt/sitemap.xml" \
   && command grep -qxF '  <url><loc>https://countcamp.org/</loc></url>' "$M/echt/sitemap.xml" \
   && ! command grep -qF 'index.html' "$M/echt/sitemap.xml" \
   && command grep -qF 'beschr%C4%B3ven' "$M/echt/sitemap.xml" \
   && ! command grep -qF 'werkboeken' "$M/echt/sitemap.xml" \
   && ! command grep -qF '404' "$M/echt/sitemap.xml"; then
  echo "  ok    3c adressen in de vorm …/, ĳ gecodeerd, geen doorstuurder en geen 404"
else echo "  ZAKT  3c de sitemap ziet er anders uit:"; sed 's/^/          /' "$M/echt/sitemap.xml"; gezakt=$((gezakt + 1)); fi
getoetst=$((getoetst + 1))
if command grep -qF "$C_GGZ" "$M/echt/oefenboeken/ggz_vs/index.html" \
   && [ "$(command grep -c 'rel="canonical"' "$M/echt/power/index.html")" = 1 ]; then
  echo "  ok    3d canonical in de vorm …/, en power houdt er één"
else echo "  ZAKT  3d canonical niet zoals verwacht"; gezakt=$((gezakt + 1)); fi
( cd "$M/echt" && find . -type f -exec shasum {} + | sort ) > "$M/voor.sha"
zaak "4  bouwstap nog eens (idempotent)" 0 zetten --echt --site "$M/echt"
in_uitvoer "4b ... verandert dan niets" "ongewijzigd met 8 adressen; canonical gezet in 0 bladzijden"
( cd "$M/echt" && find . -type f -exec shasum {} + | sort ) > "$M/na.sha"
getoetst=$((getoetst + 1))
if cmp -s "$M/voor.sha" "$M/na.sha"; then echo "  ok    4c ... ook byte voor byte"
else echo "  ZAKT  4c de tweede run veranderde bestanden"; gezakt=$((gezakt + 1)); fi
getoetst=$((getoetst + 1))
if cmp -s google7b04654a69a0c7b2.html "$M/echt/google7b04654a69a0c7b2.html" \
   && cmp -s werkboeken/ggz_vs/index.html "$M/echt/werkboeken/ggz_vs/index.html" \
   && cmp -s manuscript/handleiding/404.html "$M/echt/manuscript/handleiding/404.html"; then
  echo "  ok    4d fragment, doorstuurder en 404 onaangeroerd"
else echo "  ZAKT  4d het fragment, de doorstuurder of de 404 is veranderd"; gezakt=$((gezakt + 1)); fi

echo "== mutaties op de gebouwde boom: de wachter moet bijten"
cp -R "$M/echt" "$M/schoon"
herstel() { rm -rf "$M/echt"; cp -R "$M/schoon" "$M/echt"; }
muteer "$M/echt/oefenboeken/ggz_vs/index.html" "s.replace('$C_GGZ\n', '')"
zaak "5  canonical weggehaald -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "5b ... met de naam van de bladzij" "geen canonical: 1"
herstel
muteer "$M/echt/oefenboeken/ggz_vs/index.html" "s.replace('$C_GGZ', '$C_GGZ\n$C_GGZ')"
zaak "6  canonical dubbel -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "6b ... want Google negeert er dan twee" "meer dan één canonical"
herstel
muteer "$M/echt/oefenboeken/ggz_vs/index.html" "s.replace('$C_GGZ', '$C_GGZ'.replace('ggz_vs/', 'ggz_vs/index.html'))"
zaak "7  canonical in de vorm …/index.html -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "7b ... verkeerd adres" "canonical naar het verkeerde adres"
herstel
muteer "$M/echt/oefenboeken/ggz_vs/index.html" "s.replace('$C_GGZ\n', '').replace('</body>', '$C_GGZ\n</body>')"
zaak "8  canonical in <body> in plaats van <head> -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "8b ... Google leest hem daar niet" "canonical buiten <head>"
herstel
muteer "$M/echt/sitemap.xml" "s.replace('</urlset>', '  <url><loc>https://countcamp.org/werkboeken/ggz_vs/</loc></url>\n</urlset>')"
zaak "9  doorstuurder in de sitemap -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "9b ... bij naam" "doorstuurder in de sitemap: 1"
herstel
muteer "$M/echt/sitemap.xml" "s.replace('  <url><loc>https://countcamp.org/power/</loc></url>\n', '')"
zaak "10 echte bladzij uit de sitemap gevallen -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "10b ... bij naam" "power/index.html"
herstel
muteer "$M/echt/sitemap.xml" "s.replace('/oefenboeken/ggz_vs/</loc>', '/oefenboeken/ggz_vs/index.html</loc>')"
zaak "11 adres in de vorm …/index.html in de sitemap -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "11b ... het dubbele adres" "adres in de vorm …/index.html"
herstel
muteer "$M/echt/sitemap.xml" "s.replace('</urlset>', '  <url><loc>https://countcamp.org/power/</loc></url>\n</urlset>')"
zaak "12 adres twee keer in de sitemap -> rood" 1 wacht --echt --site "$M/echt"
herstel
muteer "$M/echt/sitemap.xml" "s.replace('</urlset>', '  <url><loc>https://countcamp.org/bestaat/niet.html</loc></url>\n</urlset>')"
zaak "13 adres zonder bladzij -> rood" 1 wacht --echt --site "$M/echt"
herstel
muteer "$M/echt/sitemap.xml" "s.replace('</urlset>', '')"
zaak "14 kapotte XML -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "14b ... en hij zegt het" "geen geldige XML"
herstel
muteer "$M/echt/sitemap.xml" "s.replace('</urlset>', '  <url><loc>https://countcamp.org/manuscript/handleiding/404.html</loc></url>\n</urlset>')"
zaak "15 foutbladzij in de sitemap -> rood" 1 wacht --echt --site "$M/echt"
herstel
muteer "$M/echt/speeltjes/solomon-en.html" "s.replace('href=\"https://countcamp.org/speeltjes/solomon.html\">', 'href=\"https://countcamp.org/speeltjes/index.html\">', 1)"
zaak "16 hreflang naar een adres dat niet in de sitemap staat -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "16b ... bij naam" "hreflang naar een adres dat niet in de sitemap staat"
herstel
muteer "$M/echt/power/index.html" "s.replace('<head>', '<head>\n<meta name=\"robots\" content=\"noindex\">', 1)"
zaak "17 noindex-bladzij die in de sitemap blijft staan -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "17b ... bij naam" "noindex-bladzij in de sitemap"
zaak "17c bouwstap haalt hem eruit" 0 zetten --echt --site "$M/echt"
in_uitvoer "17d ... en telt hem als noindex" "1 noindex"
zaak "17e wachter weer groen" 0 wacht --echt --site "$M/echt"
herstel

echo "== tweede bron: doorstuurders.tsv"
python3 - "$G/_tools/doorstuurders.tsv" <<'PY'
import sys
p = sys.argv[1]
kop = [r for r in open(p, encoding="utf-8") if r.startswith("oud\t")][0].rstrip("\n").split("\t")
rij = dict.fromkeys(kop, "-")
rij.update(oud="power/index.html", nieuw="tabellen/index.html", besluit="bouwen")
open(p, "a", encoding="utf-8").write("\t".join(rij[k] for k in kop) + "\n")
PY
zaak "18 een oud adres uit de tabel staat in de sitemap -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "18b ... ook als het bestand zelf geen doorstuurder is" "oud adres uit doorstuurders.tsv in de sitemap: 1"
cp _tools/doorstuurders.tsv "$G/_tools/doorstuurders.tsv"

echo "== kopieën: canoniek_anders.tsv"
printf 'bladzij\twijst_naar\nspeeltjes/solomon-en.html\tspeeltjes/solomon.html\n' > "$G/_tools/canoniek_anders.tsv"
zaak "19 een kopie die nog naar zichzelf wijst -> rood" 1 wacht --echt --site "$M/echt"
in_uitvoer "19b ... want ze staat in de sitemap" "kopie in de sitemap"
zaak "19c bouwstap zet haar canonical om en haalt haar uit de sitemap" 0 zetten --echt --site "$M/echt"
in_uitvoer "19d ... 7 adressen, 1 kopie" "1 kopieën (canoniek_anders.tsv)"
getoetst=$((getoetst + 1))
if command grep -qF '<link rel="canonical" href="https://countcamp.org/speeltjes/solomon.html">' "$M/echt/speeltjes/solomon-en.html" \
   && [ "$(command grep -c 'rel="canonical"' "$M/echt/speeltjes/solomon-en.html")" = 1 ]; then
  echo "  ok    19e de kopie wijst naar het origineel, één keer"
else echo "  ZAKT  19e de kopie wijst niet (alleen) naar het origineel"; gezakt=$((gezakt + 1)); fi
# De hreflang van solomon wijst nog naar de kopie: die staat niet meer in de sitemap.
zaak "19f ... en dan bijt de hreflang-toets: die wijst nu naar een kopie" 1 wacht --echt --site "$M/echt"
in_uitvoer "19g ... bij naam" "speeltjes/solomon.html  [en -> https://countcamp.org/speeltjes/solomon-en.html]"
herstel
printf 'bladzij\twijst_naar\nmanuscript/h4.html\tpower/index.html\n' > "$G/_tools/canoniek_anders.tsv"
zaak "19h een kopie zonder taalpaar: bouwstap en wachter groen" 0 zetten --echt --site "$M/echt"
zaak "19i ... wachter groen" 0 wacht --echt --site "$M/echt"
in_uitvoer "19j ... 7 in de sitemap, 1 kopie" "1 kopie(ën) uit canoniek_anders.tsv"
herstel
printf 'bladzij\twijst_naar\nmanuscript/h4.html\twerkboeken/ggz_vs/index.html\n' > "$G/_tools/canoniek_anders.tsv"
zaak "20 kopie die naar een doorstuurder wijst: bouwstap weigert" 1 zetten --echt --site "$M/echt"
printf 'bladzij\twijst_naar\nmanuscript/h4.html\tpower/index.html\npower/index.html\ten/index.html\n' > "$G/_tools/canoniek_anders.tsv"
zaak "21 ketting van kopieën: bouwstap weigert" 1 zetten --echt --site "$M/echt"
in_uitvoer "21b ... en zegt dat het een ketting is" "ketting"
printf 'bladzij\twijst_naar\nmanuscript/h4.html\n' > "$G/_tools/canoniek_anders.tsv"
zaak "22 kapotte tabel: bouwstap weigert" 1 zetten --echt --site "$M/echt"
zaak "22b ... en de wachter ook" 1 wacht --echt --site "$M/echt"
printf '# leeg\nbladzij\twijst_naar\n' > "$G/_tools/canoniek_anders.tsv"
herstel
muteer "$M/echt/manuscript/h4.html" "s.replace('<link rel=\"canonical\" href=\"https://countcamp.org/manuscript/h4.html\">', '<link rel=\"canonical\" href=\"https://countcamp.org/power/\">')"
zaak "23 een bron met een canonical naar een andere bladzij: bouwstap weigert" 1 zetten --echt --site "$M/echt"
in_uitvoer "23b ... met de naam en wat er te doen is" "manuscript/h4.html draagt al een canonical naar https://countcamp.org/power/"
herstel

echo "== spook: de proefdruk"
verse_boom spook
printf '<?xml version="1.0"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>/index.html</loc></url></urlset>\n' > "$M/spook/sitemap.xml"
# Precies wat Quarto 1.9.38 bij `site-url: ""` schrijft (gemeten 24-11-2026).
printf 'Sitemap: /sitemap.xml' > "$M/spook/robots.txt"
zaak "24 bouwstap --spook" 0 zetten --spook --site "$M/spook"
in_uitvoer "24b ... haalt de sitemap en de robots.txt van Quarto weg" "weggehaald wat Quarto schreef: sitemap.xml, robots.txt"
getoetst=$((getoetst + 1))
if [ ! -e "$M/spook/sitemap.xml" ] && [ ! -e "$M/spook/robots.txt" ] \
   && cmp -s oefenboeken/ggz_vs/index.html "$M/spook/oefenboeken/ggz_vs/index.html"; then
  echo "  ok    24c geen sitemap, en geen canonical bijgezet"
else echo "  ZAKT  24c er staat nog een sitemap, of de bouwstap veranderde een bladzij"; gezakt=$((gezakt + 1)); fi
zaak "25 wachter --spook groen" 0 wacht --spook --site "$M/spook"
in_uitvoer "25b ... en telt wat de bronnen meebrachten (power, solomon, solomon-en, de doorstuurder)" "4 canonical(s), allemaal uit de bronnen"
zaak "26 wachter --spook op de echte bouw -> rood" 1 wacht --spook --site "$M/schoon"
in_uitvoer "26b ... sitemap in een proefdruk" "sitemap in een proefdruk"
zaak "27 wachter --echt op een proefdruk -> rood" 1 wacht --echt --site "$M/spook"
printf 'User-agent: *\nDisallow:\nSitemap: /sitemap.xml\n' > "$M/spook/robots.txt"
zaak "27b een eigen robots.txt laat de bouwstap staan" 0 zetten --spook --site "$M/spook"
in_uitvoer "27c ... en zegt dat" "robots.txt is niet die van Quarto en blijft staan"
zaak "27d ... en de wachter bijt op zijn Sitemap-regel" 1 wacht --spook --site "$M/spook"
in_uitvoer "27e ... bij naam" "robots.txt wijst in een proefdruk naar een sitemap"
rm -f "$M/spook/robots.txt"
printf 'Sitemap: https://countcamp.org/sitemap.xml\n' > "$M/schoon/robots.txt"
zaak "27f echt: robots.txt naar de echte sitemap is goed" 0 wacht --echt --site "$M/schoon"
printf 'Sitemap: https://countcamp.org/oud/sitemap.xml\n' > "$M/schoon/robots.txt"
zaak "27g echt: robots.txt naar een andere sitemap -> rood" 1 wacht --echt --site "$M/schoon"
rm -f "$M/schoon/robots.txt"
muteer "$M/spook/oefenboeken/ggz_vs/index.html" "s.replace('<head>', '<head>\n<link rel=\"canonical\" href=\"/oefenboeken/ggz_vs/\">', 1)"
zaak "28 proefdruk met een relatieve canonical -> rood" 1 wacht --spook --site "$M/spook"
in_uitvoer "28b ... bij naam" "oefenboeken/ggz_vs/index.html  [/oefenboeken/ggz_vs/]"

echo "== profielen, weigeren en blind"
zaak "29 bouwstap leest het profiel uit QUARTO_PROFILE (spook)" 0 env QUARTO_PROFILE=spook,nl python3 "$G/_tools/sitemap_zetten.py" --site "$M/spook"
in_uitvoer "29b ... en doet dan wat bij spook hoort" "sitemap_zetten (spook)"
# De Engelse ronde: canonicals wel, sitemap niet. En daarna moet de Nederlandse
# bouw die bladzijden byte voor byte laten staan -- dat eist en_bouw.py gelijk in
# stap 5 van publiceer_en.sh (een Engelse bladzij uit de repo moet in de
# Nederlandse bouw precies zo terugkomen).
verse_boom en
zaak "30 Engelse ronde (en,echt): canonicals gezet" 0 env QUARTO_PROFILE=en,echt python3 "$G/_tools/sitemap_zetten.py" --anders "$G/_tools/canoniek_anders.tsv" --site "$M/en"
in_uitvoer "30b ... in 5 van de 8, en geen sitemap" "canonical gezet in 5 van de 8 echte bladzijden, 3 hadden hem al goed. Geen sitemap"
getoetst=$((getoetst + 1))
if [ ! -e "$M/en/sitemap.xml" ] && command grep -qF '<link rel="canonical" href="https://countcamp.org/en/">' "$M/en/en/index.html"; then
  echo "  ok    30c ... geen sitemap geschreven, en en/index.html wijst naar /en/"
else echo "  ZAKT  30c de Engelse ronde schreef een sitemap, of zette de canonical niet"; gezakt=$((gezakt + 1)); fi
( cd "$M/en" && find . -name '*.html' -exec shasum {} + | sort ) > "$M/en_voor.sha"
zaak "30d daarna de Nederlandse bouw" 0 zetten --echt --site "$M/en"
in_uitvoer "30e ... zet er geen canonical meer bij" "canonical gezet in 0 bladzijden, 8 hadden hem al goed"
( cd "$M/en" && find . -name '*.html' -exec shasum {} + | sort ) > "$M/en_na.sha"
getoetst=$((getoetst + 1))
if cmp -s "$M/en_voor.sha" "$M/en_na.sha"; then echo "  ok    30f ... elke bladzij byte voor byte gelijk (en_bouw.py gelijk zakt dus niet)"
else echo "  ZAKT  30f de Nederlandse bouw veranderde bladzijden uit de Engelse ronde:"; diff "$M/en_voor.sha" "$M/en_na.sha" | sed 's/^/          /'; gezakt=$((gezakt + 1)); fi
zaak "30g Engelse proefdruk (en,spook): niets gedaan" 0 env QUARTO_PROFILE=en,spook python3 "$G/_tools/sitemap_zetten.py" --site "$M/spook"
in_uitvoer "30h ... en zegt dat" "Engelse proefdruk -- niets gedaan"
# De vingerafdruk van en_bouw.py: alleen het Nederlandse deel van de sitemap telt.
waar_fn() { python3 - "$@" <<'PYY'
import sys
sys.path.insert(0, sys.argv[1])
from sitemapregel import sitemap_zonder_engels as z
a = '<urlset><url><loc>https://countcamp.org/</loc></url><url><loc>https://countcamp.org/en/</loc></url></urlset>'
b = a.replace('</urlset>', '<url><loc>https://countcamp.org/en/nieuw.html</loc></url></urlset>')
c = a.replace('</urlset>', '<url><loc>https://countcamp.org/nieuw.html</loc></url></urlset>')
d = a.replace('<url><loc>https://countcamp.org/</loc></url>', '') + '<url><loc>https://countcamp.org/</loc></url>'
fout = []
if z(a) != z(b): fout.append("een Engelse bladzij erbij verandert de Nederlandse vingerafdruk")
if z(a) == z(c): fout.append("een Nederlandse bladzij erbij verandert hem NIET")
if z(a) != z(d): fout.append("een andere volgorde verandert hem")
sys.exit("; ".join(fout) or 0)
PYY
}
getoetst=$((getoetst + 1))
if waar_fn "$G/_tools" > "$M/uit" 2>&1; then echo "  ok    30i vingerafdruk van de sitemap: Engels erbij telt niet, Nederlands erbij wel"
else echo "  ZAKT  30i vingerafdruk van de sitemap:"; sed 's/^/          /' "$M/uit"; gezakt=$((gezakt + 1)); fi
getoetst=$((getoetst + 1))
if command grep -qF 'inhoud = sitemap_zonder_engels(' _tools/en_bouw.py; then echo "  ok    30j en_bouw.py foto gebruikt hem"
else echo "  ZAKT  30j en_bouw.py foto gebruikt sitemap_zonder_engels niet"; gezakt=$((gezakt + 1)); fi
zaak "31 bouwstap met onbekend profiel weigert" 1 env QUARTO_PROFILE=spok python3 "$G/_tools/sitemap_zetten.py" --site "$M/schoon"
mkdir -p "$M/leeg"
zaak "32 lege map: kon niet kijken" 3 wacht --echt --site "$M/leeg"
zaak "33 map bestaat niet: kon niet kijken" 3 wacht --echt --site "$M/bestaat_niet"
zaak "34 bouwstap in lege map: niets gezien" 3 zetten --echt --site "$M/leeg"

echo "== de bedrading: hangt hij ook ergens?"
# Een wachter die bestaat maar nergens hangt, is de faalvorm van akkoord_hek.py,
# dat zes dagen nergens bedraad stond.
waar() {  # $1 = naam, $2.. = commando dat 0 moet geven
  local naam="$1"; shift
  getoetst=$((getoetst + 1))
  if "$@" > "$M/uit" 2>&1; then echo "  ok    $naam"
  else echo "  ZAKT  $naam"; sed 's/^/          /' "$M/uit"; gezakt=$((gezakt + 1)); fi
}
waar "35 _quarto.yml: sitemap_zetten.py als laatste post-render-stap" python3 - <<'PY'
import re, sys
t = open("_quarto.yml", encoding="utf-8").read()
m = re.search(r"^  post-render:\n((?:    - .+\n)+)", t, re.M)
stappen = re.findall(r"- (\S+)", m.group(1)) if m else []
if not stappen or stappen[-1] != "_tools/sitemap_zetten.py":
    sys.exit("post-render: %s" % stappen)
PY
waar "36 publish.yml: sitemapwacht --echt na Render, vóór Publish" python3 - <<'PY'
import re, sys
t = open(".github/workflows/publish.yml", encoding="utf-8").read()
namen = re.findall(r"^      - name: (.+)$", t, re.M)
stap = {n: i for i, n in enumerate(namen)}
pub = next((i for n, i in stap.items() if n.startswith("Publish")), None)
if "Render" not in stap or "Sitemapwacht" not in stap or pub is None:
    sys.exit("stappen in publish.yml: %s" % namen)
blok = t.split("- name: Sitemapwacht", 1)[1].split("- name:", 1)[0]
if "python3 _tools/sitemapwacht.py --echt" not in blok:
    sys.exit("de stap Sitemapwacht draait de wachter niet met --echt")
if not (stap["Render"] < stap["Sitemapwacht"] < pub):
    sys.exit("volgorde klopt niet: %s" % namen)
PY
waar "37 proefdruk.yml: sitemapwacht --spook vóór het neerzetten" python3 - <<'PY'
import sys
t = open(".github/workflows/proefdruk.yml", encoding="utf-8").read()
w, n = t.find("python3 _tools/sitemapwacht.py --spook"), t.find("- name: Neerzetten")
if w < 0 or n < 0 or w > n:
    sys.exit("wachter op %d, neerzetten op %d" % (w, n))
PY
waar "38 naar_buiten.sh: --productie na de bouw blokkerend en vóór de push, --lokaal meldend" \
  python3 - "${NAAR_BUITEN:-_tools/naar_buiten.sh}" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
def tak(naam):
    m = re.search(r"^%s\)\n(.*?)^  ;;" % re.escape(naam), s, re.S | re.M)
    return m.group(1) if m else ""
prod, lok = tak("--productie"), tak("--lokaal")
BOUW = "_tools/schone_bouw.py --uit _site -- render"
fout = []
r, a, b = prod.find(BOUW), prod.find("gebouwde_sitemap_nakijken echt blokkerend"), prod.find("doe git push origin main")
if a < 0 or r < 0 or b < 0 or not (r < a < b):
    fout.append("--productie: bouw op %d, wacht op %d, push op %d" % (r, a, b))
elif "exit 1" not in prod[a:prod.find("\n", a)]:
    fout.append("--productie stopt niet als de sitemappoort rood is")
r, a = lok.find(BOUW), lok.find("gebouwde_sitemap_nakijken spook melden")
if a < 0 or r < 0 or a < r:
    fout.append("--lokaal roept de sitemappoort niet (spook, meldend) na de bouw aan")
romp = s.split("gebouwde_sitemap_nakijken() {", 1)[-1].split("\n}\n", 1)[0]
if 'if [ "$streng" = blokkerend ]; then return 1; fi' not in romp:
    fout.append("de sitemappoort houdt nooit tegen")
if 'sitemapwacht.py" "--$profiel"' not in romp:
    fout.append("de sitemappoort draait de wachter niet met het profiel")
sys.exit("; ".join(fout) if fout else 0)
PY

# De functie zelf, letterlijk uit naar_buiten.sh, op de bomen van hierboven.
POORT="$(sed -n '/^gebouwde_sitemap_nakijken() {/,/^}/p' "${NAAR_BUITEN:-_tools/naar_buiten.sh}")"
poort() {  # $1 = naam, $2 = verwachte afloopcode, $3 = site, $4 = echt|spook, $5 = blokkerend|melden
  getoetst=$((getoetst + 1))
  local r="$M/poortrepo"
  rm -rf "$r"; mkdir -p "$r"; cp -R "$G/_tools" "$r/_tools"; cp -R "$3" "$r/_site"
  ( HIER="$r"; eval "$POORT"; gebouwde_sitemap_nakijken "$4" "$5" ) > "$M/uit" 2>&1
  local echt=$?
  if [ "$echt" = "$2" ]; then echo "  ok    $1 (afloopcode $echt)"
  else echo "  ZAKT  $1 — verwacht $2, kreeg $echt"; sed 's/^/          /' "$M/uit"; gezakt=$((gezakt + 1)); fi
}
poort "39 poort: de goede bouw laat door" 0 "$M/schoon" echt blokkerend
muteer "$M/echt/sitemap.xml" "s.replace('</urlset>', '  <url><loc>https://countcamp.org/werkboeken/ggz_vs/</loc></url>\n</urlset>')"
poort "40 poort: een doorstuurder in de sitemap HOUDT TEGEN" 1 "$M/echt" echt blokkerend
in_uitvoer "40b ... en zegt het in gewone taal" "De sitemap of de canonicals kloppen niet"
poort "41 poort: dezelfde bouw op een proefweg laat door" 0 "$M/echt" echt melden
in_uitvoer "41b ... maar zegt het wel hardop" "op een proefweg houdt dit je niet tegen"
poort "42 poort: de echte bouw als proefdruk gekeurd HOUDT TEGEN" 1 "$M/schoon" spook blokkerend
poort "43 poort: een lege _site HOUDT TEGEN, als blinde" 1 "$M/leeg" echt blokkerend
in_uitvoer "43b ... en noemt dat blindheid" "stilte betekent ongeldig, nooit goed"
getoetst=$((getoetst + 1))
rm -rf "$M/poortrepo"; mkdir -p "$M/poortrepo/_tools"; cp -R "$M/schoon" "$M/poortrepo/_site"
( HIER="$M/poortrepo"; eval "$POORT"; gebouwde_sitemap_nakijken echt blokkerend ) > "$M/uit" 2>&1
code=$?
if [ "$code" = 1 ] && command grep -qF "is dus ONGEMETEN" "$M/uit" \
   && ! command grep -qF "kloppen niet" "$M/uit"; then
  echo "  ok    44 poort zonder wachter: houdt tegen, en legt de schuld niet bij de bladzijden"
else echo "  ZAKT  44 poort zonder wachter (afloop $code):"; sed 's/^/          /' "$M/uit"; gezakt=$((gezakt + 1)); fi
herstel

echo
echo "$((getoetst - gezakt)) ok, $gezakt gezakt (van $getoetst)"
[ "$gezakt" -eq 0 ]
