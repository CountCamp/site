#!/usr/bin/env bash
# ============================================================
# publiceer_en.sh — bouwt de Engelse kant van countcamp.org (en/), zet hem
# eerst op de spooksite, keurt hem, en maakt hem dan klaar voor de echte site.
# ------------------------------------------------------------
# DE AFSPRAAK MET DE PERS (wachtrij, spoor wachtrij_en) — lees dit eerst.
#
#   bash _tools/publiceer_en.sh               de hele gang (zie hieronder)
#   bash _tools/publiceer_en.sh --alleen-spook  alleen bouwen en keuren op de
#                                             spooksite; de repo blijft
#                                             onaangeroerd. Om te kijken.
#   bash _tools/publiceer_en.sh --nakijken    niets bouwen: keur wat er nu in
#                                             en/ gecommit staat, in een verse
#                                             Nederlandse bouw. Voor een poort.
#
#   Draaien vanuit elke map; het script zoekt zelf de wortel van de repo.
#   Geen argumenten nodig; omgevingsvariabele EN_BRON (standaard "sessie")
#   komt in het manifest als bron=, zodat een run van de wachtrij te
#   onderscheiden is van een handmatige (zet EN_BRON=wachtrij_en).
#
#   AFLOOP (huisafspraak):
#     0  klaar voor de echte site. en/ en _tools/en_manifest.txt zijn
#        bijgewerkt en gekeurd; de pers commit ze (git add en _tools/en_manifest.txt)
#        en levert met _tools/naar_buiten.sh --productie. Staat er na een
#        run niets anders dan het manifest gewijzigd, dan is er niets te leveren.
#     1  er is een gat: een link die nergens uitkomt, een merkteken dat niet
#        klopt, een tweeling zonder knopje, een Nederlandse bladzij die
#        veranderde ... De regels erboven zeggen welk. NIET leveren. Bij een gat
#        in de echte stap is en/ in de repo NIET aangeraakt.
#     2  verkeerd aangeroepen of een voorwaarde ontbreekt (geen repo, geen
#        bronnen). NIET leveren.
#     3  kon niet kijken: quarto ontbreekt, of de Nederlandse bouw liep vast,
#        zodat niet vast te stellen is dat het Nederlands ongemoeid bleef.
#        Stilte betekent nooit "goed". NIET leveren.
#
#   WAT HET SCRIPT AANRAAKT: _site/, _site_spook/, _site_en/, _site_en_werk/
#   (bouwmappen, gitignored), _spooksite/banner.html (idem), en — alleen bij afloop 0 en
#   niet bij --alleen-spook — de gegenereerde bestanden onder en/ (de .html
#   naast elke en/*.qmd, en en/libs/) plus _tools/en_manifest.txt. Nooit een
#   Nederlandse bron, nooit iets buiten de repo. Het pusht niet en commit niet.
#
# DE GANG, en waarom in deze volgorde
#   0. voorwaarden: quarto, de tabel, de Engelse bronnen, de nl_bron-stempels.
#   1. NULMETING. Nederlandse bouw (echt), vingerafdruk van alles behalve en/.
#   2. SPOOKSITE EERST. De Nederlandse site als proefdruk (noindex, balk, geen
#      teller) naar _site_spook/, de Engelse proefdruk erin onder en/, en dan
#      alle keuringen. Bekijken: open _site_spook/en/index.html
#   3. ECHT, maar nog niet in de repo. Engelse bouw (echt, met teller) in
#      _site/en/ gezet en gekeurd. Pas als dat schoon is:
#   4. IN DE REPO. Dezelfde bestanden naar en/; daarna nagemeten dat wat in de
#      repo staat byte voor byte is wat er gekeurd werd.
#   5. NEDERLANDS ONGEMOEID. Opnieuw de Nederlandse bouw, nu mét de nieuwe en/
#      als bijlage, en de vingerafdruk vergeleken met stap 1: geen enkel
#      Nederlands bestand mag anders zijn. Zo de Action het straks ook bouwt.
#   6. MANIFEST: wat er gekeurd is, hoeveel, waar, door wie, van welke commit.
#
# WAT DIT NIET DEKT — zodat niemand het denkt.
#   * De PR-proefdruk op countcamp.org/pr-preview/ (proefdruk.yml) kopieert
#     en/ zoals het in de repo staat: met teller, zonder balk. Dat geldt daar
#     al voor elke bijlage (oefenboeken, boek), en de spooksite van stap 2 is
#     waar de Engelse proefdruk wél als proefdruk staat.
#   * Of een tekst goed Engels is: dat is Mieke (MIEKE:-notities in en/*.qmd).
#   * Of het Nederlands sinds de vertaling bewoog: dat MELDT stap 0 (BIJ TE
#     WERKEN) maar houdt niet tegen — een vertaling van gisteren is beter dan
#     geen, en de keus om haar te vervangen is aan een mens.
#   * Hangende bouw: er is geen tijdslimiet; quarto zelf breekt af bij fouten.
#
# Ontstaan: spoor en_schil, 24-10-2026. Het waarom van de opzet (eigen en/-boom
# in plaats van babelquarto) staat in _quarto-en.yml en in de commit erbij.
# ============================================================
set -uo pipefail
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH";; esac
export PATH
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 2
PY="python3 $REPO/_tools/en_bouw.py"
# Werkbestanden van één run (vingerafdrukken, logboek, keuring). Gitignored; de
# Nederlandse bouw slaat de map over (_quarto-nl.yml).
WERK="$REPO/_site_en_werk"
mkdir -p "$WERK"
FOTO_VOOR="$WERK/foto_voor.json"
FOTO_NA="$WERK/foto_na.json"

WEG=heel
case "${1:-}" in
  "") ;;
  --alleen-spook) WEG=spook ;;
  --nakijken) WEG=nakijken ;;
  -h|--help) sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "onbekende schakelaar: $1  (zie: bash $0 --help)"; exit 2 ;;
esac

stap() { echo; echo "== $*"; }
stop() {  # $1 = afloopcode, $2.. = waarom
  local code="$1"; shift
  echo; echo "NIET KLAAR (afloop $code): $*"
  schrijf_manifest "GAT" "$code" "$*"
  exit "$code"
}
nlbouw() {  # $1 = profiel (leeg = echt), $2 = uitvoermap (leeg = _site)
  local args=(render)
  [ -n "${1:-}" ] && args+=(--profile "$1")
  [ -n "${2:-}" ] && args+=(--output-dir "$2")
  echo "  \$ quarto ${args[*]}"
  local log="$WERK/nlbouw.log"
  if ! quarto "${args[@]}" >"$log" 2>&1; then
    tail -15 "$log" | sed 's/^/    /'
    return 1
  fi
  return 0
}
MANIFEST="$REPO/_tools/en_manifest.txt"
schrijf_manifest() {  # $1 status, $2 afloop, $3 reden
  [ "$WEG" = heel ] || return 0   # alleen de hele gang levert een product
  local bladz libs
  bladz="$(find "$REPO/en" -name '*.html' -not -path '*/libs/*' 2>&1 | wc -l | tr -d ' ')"
  libs="$(find "$REPO/en/libs" -type f 2>&1 | wc -l | tr -d ' ')"
  {
    echo "# MANIFEST status=$1 afloop=$2 bladzijden=$bladz libs=$libs machine=$(hostname -s) bron=${EN_BRON:-sessie} wanneer=$(date '+%Y-%m-%dT%H:%M:%S%z')"
    echo "# bron_commit=$(git rev-parse --short HEAD) bron_schoon=$( [ -z "$(git status --porcelain -- ':(glob)en/**/*.qmd' _quarto.yml ':(glob)_quarto-*.yml' _tools/taalparen.tsv _tools/taalwissel.lua _tools/en_bouw.py)" ] && echo ja || echo nee)"
    echo "# reden=${3:-geen}"
    echo "# Gemaakt door _tools/publiceer_en.sh. Wie en/ levert, kijkt eerst hier:"
    echo "# status=OK met afloop=0 betekent dat stap 1 t/m 5 groen waren voor PRECIES"
    echo "# de bestanden die nu in en/ staan. Elke andere status: niet leveren."
    echo "# bron_schoon=nee: een bron (en/*.qmd, _quarto*.yml, taalparen, taalwissel, en_bouw.py)"
    echo "#   had ongecommit werk tijdens de bouw; dan is bron_commit niet de hele waarheid."
    echo "#   (De gegenereerde en/*.html tellen niet mee: die maakt deze run zelf.)"
    echo
    [ -f "$WERK/keur.txt" ] && cat "$WERK/keur.txt"
  } > "$MANIFEST"
}

# ---------------------------------------------------------------- 0 ----
stap "0. voorwaarden"
command -v quarto >/dev/null || { echo "  quarto staat niet op het pad"; exit 3; }
echo "  quarto $(quarto --version)"
[ -f _quarto-en.yml ] && [ -f _tools/taalparen.tsv ] && [ -f _tools/taalwissel.lua ] \
  || { echo "  _quarto-en.yml, _tools/taalparen.tsv of _tools/taalwissel.lua ontbreekt"; exit 2; }
n_bron="$(find en -maxdepth 3 -name '*.qmd' 2>/dev/null | wc -l | tr -d ' ')"
[ "$n_bron" -gt 0 ] || { echo "  geen Engelse bronnen (en/*.qmd)"; exit 2; }
echo "  $n_bron Engelse bron(nen) onder en/"
$PY bronnen || stop 2 "een Engelse bron mist zijn nl_bron-stempel of die wijst nergens heen"

# ---------------------------------------------------------- nakijken ----
if [ "$WEG" = nakijken ]; then
  stap "nakijken: de gecommitte en/ in een verse Nederlandse bouw"
  nlbouw || { echo "  de Nederlandse bouw liep vast — kon niet kijken"; exit 3; }
  $PY keur --site _site --soort echt; code=$?
  [ "$code" -eq 0 ] && echo && echo "Wat er in en/ staat, is in orde."
  exit "$code"
fi

# ---------------------------------------------------------------- 1 ----
stap "1. nulmeting: de Nederlandse site zoals hij nu is"
nlbouw || stop 3 "de Nederlandse bouw liep vast in de nulmeting"
$PY foto --site _site --uit "$FOTO_VOOR" || stop 3 "geen vingerafdruk van de Nederlandse site"

# ---------------------------------------------------------------- 2 ----
stap "2. spooksite eerst: Nederlands en Engels als proefdruk, naar _site_spook/"
bash _spooksite/maak_banner.sh "Engelse proefdruk" "tak $(git branch --show-current) · publiceer_en.sh" \
  || stop 3 "de proefdrukbalk kon niet geschreven worden"
nlbouw spook _site_spook || stop 3 "de Nederlandse proefdruk liep vast"
$PY bouw --soort spook || stop 1 "de Engelse proefdruk liep vast of gaf waarschuwingen"
$PY zet --naar _site_spook || stop 1 "de Engelse proefdruk kon niet in _site_spook/ gezet worden"
$PY keur --site _site_spook --soort spook || stop 1 "de spooksite heeft gaten (zie hierboven)"
echo "  bekijken: open $REPO/_site_spook/en/index.html"
if [ "$WEG" = spook ]; then
  echo; echo "Alleen de spooksite, zoals gevraagd. De repo is niet aangeraakt."
  exit 0
fi

# ---------------------------------------------------------------- 3 ----
stap "3. echt, eerst in _site/ (nog niet in de repo)"
$PY bouw --soort echt || stop 1 "de Engelse bouw liep vast of gaf waarschuwingen"
$PY zet --naar _site || stop 1 "de Engelse bouw kon niet in _site/ gezet worden"
$PY keur --site _site --soort echt | tee "$WERK/keur.txt"
[ "${PIPESTATUS[0]}" -eq 0 ] || stop 1 "de echte Engelse site heeft gaten (zie hierboven); en/ in de repo is NIET aangeraakt"

# ---------------------------------------------------------------- 4 ----
stap "4. in de repo: en/"
$PY zet --naar . || stop 1 "en/ in de repo kon niet bijgewerkt worden"

# ---------------------------------------------------------------- 5 ----
stap "5. Nederlands ongemoeid: opnieuw bouwen, zoals de Action het doet"
nlbouw || stop 3 "de Nederlandse bouw liep vast ná het neerzetten van en/"
$PY gelijk --site _site || stop 1 "wat in en/ staat, is niet wat er gekeurd werd"
$PY foto --site _site --uit "$FOTO_NA" || stop 3 "geen vingerafdruk ná"
$PY vergelijk "$FOTO_VOOR" "$FOTO_NA" || stop 1 "een Nederlands bestand veranderde (zie hierboven)"

# ---------------------------------------------------------------- 6 ----
stap "6. manifest"
schrijf_manifest OK 0 "alle stappen groen"
echo "  $(head -1 "$MANIFEST")"
echo
echo "KLAAR voor de echte site. De pers: git add en _tools/en_manifest.txt, commit,"
echo "en lever met _tools/naar_buiten.sh --productie."
git status --short -- en _tools/en_manifest.txt | sed 's/^/  /'
exit 0
