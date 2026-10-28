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
#        veranderde ... De regels erboven zeggen welk. NIET leveren.
#     2  verkeerd aangeroepen of een voorwaarde ontbreekt (geen repo, geen
#        bronnen). NIET leveren.
#     3  kon niet kijken: quarto ontbreekt, of de Nederlandse bouw liep vast,
#        zodat niet vast te stellen is dat het Nederlands ongemoeid bleef; of
#        de run werd onderbroken (Ctrl-C, afgeschoten). Stilte betekent nooit
#        "goed". NIET leveren.
#
#   BIJ ELKE AFLOOP ANDERS DAN 0 STAAT DE REPO WEER PRECIES ZOALS VÓÓR DE RUN —
#   ook bij --alleen-spook, ook als het gat pas na het neerzetten van en/ komt,
#   ook als de run wordt onderbroken. Vóór stap 1 bewaart de run en/, het
#   manifest en git status (_site_en_werk/repo_voor_run/); stop() zet en/ en het
#   manifest terug en meet het na: elk bestand dezelfde sha256, git status
#   dezelfde regels. Zegt de laatste regel iets anders dan "git status gelijk",
#   dan klopt dat niet, en staat erbij wat er anders is.
#   Tot 25-10-2026 beloofde deze kop dit alleen "bij een gat in de echte stap",
#   en zelfs dat klopte niet: Quarto verplaatst de gecommitte en/*.html bij elke
#   Engelse bouw naar _site_en/ (zie en_bouw.py, bewaar/herstel), en stop()
#   schreef het manifest in _tools/. C zag het in de gedeelde checkout: vier
#   keer " D en/...", één keer " M _tools/en_manifest.txt", na afloop 1.
#   Getoetst: _tools/tests/publiceer_en_werkruimte_test.sh (gevallen 2 t/m 7).
#
#   WAT HET SCRIPT AANRAAKT: _site/, _site_spook/, _site_en/, _site_en_werk/
#   (bouwmappen, gitignored), _spooksite/banner.html (idem), en — alleen bij afloop 0 en
#   niet bij --alleen-spook — de gegenereerde bestanden onder en/ (de .html
#   naast elke en/*.qmd, en en/libs/) plus _tools/en_manifest.txt. Nooit een
#   Nederlandse bron, nooit iets buiten de repo. Het pusht niet en commit niet.
#   Het manifest van ELKE run, ook een mislukte, staat in _site_en_werk/en_manifest.txt;
#   in _tools/ komt het alleen bij afloop 0. Na een mislukte run beschrijft
#   _tools/en_manifest.txt dus nog steeds de en/ die er staat — die is immers
#   teruggezet — en niet deze run.
#
# DE GANG, en waarom in deze volgorde
#   0. voorwaarden: quarto, de tabel, de Engelse bronnen, de nl_bron-stempels.
#      Daarna bewaard: en/, het manifest en git status, voor stop().
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
# EEN ENGELSE BLADZIJ TOEVOEGEN — voor de volgende sporen (boek, speeltjes, R-oefenboek).
#   a. Een bladzij die Quarto bouwt: zet en/<naam>.qmd neer (submap mag), met in
#      de kop `nl_bron: <nederlandse bron>@<commit>` — de commit waarvan je
#      vertaalde (`git log -1 --format=%h -- <bron>`). Zonder stempel weigert stap 0.
#   b. Heeft hij een Nederlandse tweeling: één regel in _tools/taalparen.tsv
#      (nl-pad, en-pad, auto). Dan krijgen BEIDE kanten het knopje en hreflang,
#      en de Nederlandse kant de taalbalk.
#      Let op: de Nederlandse bladzij verandert daardoor (alleen regels erbij);
#      dat is de bedoeling, en het gebeurt bij de commit van de tabel, niet bij
#      een run van dit script — een run verandert nooit iets Nederlands. De
#      wachtrij laat precies die regels door (nl_negeer, uitgerekend door
#      `python3 _tools/taalonderdelen.py regels`); niets anders.
#   c. Hoort hij in het menu: _quarto-en.yml. Het menu toont alleen wat bestaat;
#      link naar een Nederlandse bladzij als .html, nooit als .qmd.
#   d. Een losse HTML-bladzij (een speeltje, een hoofdstuk uit het lab): zet hem
#      ergens onder en/ neer; hij wordt dan als Engelse bladzij gekeurd (links,
#      lang, teller). Staat hij BUITEN en/ (zoals speeltjes/solomon-en.html), zet
#      hem dan in ENGELS_BUITEN_EN in _tools/en_bouw.py, anders kijkt niemand naar
#      zijn links. Heeft hij een Nederlandse tweeling, zet het paar dan in
#      _tools/taalparen.tsv als `los` (knopje en hreflang komen er dan in via
#      _tools/taalonderdelen.py, zoals bij tabellen/ ↔ tables/) of `los-eigen`
#      (hij draagt ze al zelf, zoals solomon; dan alleen de balk).
#      LET OP, een speeltje uit het lab (spoor en_speeltjes, 25-10-2026): ergens
#      anders onder en/ zakt het in de spooksite op keuring 2 ("proefdruk met
#      bezoekersteller"), want het komt kant-en-klaar, met teller. Zet het dus in
#      en/toys/ via _tools/bouw_speelkist.py (EN_KIST): dan draagt het de herkomst
#      uit het lab (<meta name="nl_bron" content="boek/04_speeltjes/…">) en keurt
#      en_bouw.py het als bijlage (KIST_HERKOMST), zoals het boek onder en/book/.
#   d2. Een boekhoofdstuk: dat drukt het lab (countcamp_lab/boek/publiceer.sh --en H<n>)
#      naar en/book/h<n>.html, met de stempel van de lab-pers — en_bouw.py keurt hem
#      dan als bijlage (LAB_STEMPEL). Het paar met manuscript/h<n>.html staat al als
#      regel in _tools/taalparen.tsv, en het menu wijst al naar het boek: per
#      hoofdstuk verandert hier niets. De hele gang, in de fasen van de wachtrij:
#      bash _tools/pers_en_boek.sh H<n> spook|links|echt (spoor en_boekpers, 25-10-2026).
#   d3. Een Engels oefenboek: dat rendert het lab (bv. mvda_werkboek/en/, een eigen
#      Quarto-project), en het komt hier met
#      python3 _tools/publish_workbook.py --src <lab>/…/en/_site --section en/workbooks --name <naam>.
#      Die zet op elke bladzij een stempel (het oefenboek en de commit van het lab, en
#      alleen als de bron op die commit schoon is), en en_bouw.py keurt zo'n bladzij dan
#      als bijlage (WERKBOEK_STEMPEL) in plaats van als wees. Met de hand gekopieerd,
#      zonder stempel, blijft hij een wees (spoor vb_site2, 28-10-2026).
#   e. bash _tools/publiceer_en.sh  — en pas bij afloop 0 leveren.
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
  -h|--help) sed -n '2,/^# DE GANG/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "onbekende schakelaar: $1  (zie: bash $0 --help)"; exit 2 ;;
esac

stap() { echo; echo "== $*"; }
# De repo zoals hij vóór deze run was (zie de kop: BIJ ELKE AFLOOP ANDERS DAN 0).
BEWAARD="$WERK/repo_voor_run"
BEWAARD_NU=0
stop() {  # $1 = afloopcode, $2.. = waarom
  local code="$1"; shift
  trap - INT TERM HUP   # een tweede signaal mag het terugzetten niet halverwege afbreken
  echo; echo "NIET KLAAR (afloop $code): $*"
  if [ "$BEWAARD_NU" -eq 1 ]; then
    echo "  de repo terug zoals vóór deze run:"
    $PY herstel --van "$BEWAARD" \
      || echo "  LET OP: de repo is NIET (helemaal) terug zoals vóór de run — zie de regels hierboven"
  fi
  schrijf_manifest "GAT" "$code" "$*"
  [ "$WEG" = heel ] && echo "  manifest van deze run: ${MANIFEST#"$REPO"/} ($MANIFEST_IN_REPO blijft zoals hij was)"
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
# Het manifest van deze run gaat altijd naar de werkmap; pas bij afloop 0 kopieert
# stap 6 het naar _tools/, naast de en/ die het beschrijft.
MANIFEST="$WERK/en_manifest.txt"
MANIFEST_IN_REPO="_tools/en_manifest.txt"
schrijf_manifest() {  # $1 status, $2 afloop, $3 reden
  [ "$WEG" = heel ] || return 0   # alleen de hele gang levert een product
  local bladz libs
  # Een ontbrekende map telt als 0 en wordt hardop gezegd — niet weggegooid
  # (geen 2>/dev/null in een bewakingspad), want find's foutregel telde anders als bestand.
  bladz=0; libs=0
  if [ -d "$REPO/en" ]; then bladz="$(find "$REPO/en" -name '*.html' -not -path '*/libs/*' | wc -l | tr -d ' ')"; else libs="geen-en-map"; fi
  if [ -d "$REPO/en/libs" ]; then libs="$(find "$REPO/en/libs" -type f | wc -l | tr -d ' ')"; else libs="${libs/#0/geen-libs-map}"; fi
  {
    echo "# MANIFEST status=$1 afloop=$2 bladzijden=$bladz libs=$libs machine=$(hostname -s) bron=${EN_BRON:-sessie} wanneer=$(date '+%Y-%m-%dT%H:%M:%S%z')"
    echo "# bron_commit=$(git rev-parse --short HEAD) bron_schoon=$( [ -z "$(git status --porcelain -- ':(glob)en/**/*.qmd' _quarto.yml ':(glob)_quarto-*.yml' _tools/taalparen.tsv _tools/taalwissel.lua _tools/taalwissel _tools/taalonderdelen.py _tools/en_bouw.py)" ] && echo ja || echo nee)"
    echo "# reden=${3:-geen}"
    echo "# Gemaakt door _tools/publiceer_en.sh. Wie en/ levert, kijkt eerst hier:"
    echo "# status=OK met afloop=0 betekent dat stap 1 t/m 5 groen waren voor PRECIES"
    echo "# de bestanden die nu in en/ staan. Elke andere status: niet leveren."
    echo "# In _tools/ staat dit bestand alleen na afloop 0; het manifest van elke run,"
    echo "#   ook een mislukte, staat in _site_en_werk/en_manifest.txt."
    echo "# bron_schoon=nee: een bron (en/*.qmd, _quarto*.yml, taalparen, taalwissel(.lua en /), taalonderdelen.py, en_bouw.py)"
    echo "#   had ongecommit werk tijdens de bouw; dan is bron_commit niet de hele waarheid."
    echo "#   (De gegenereerde en/*.html tellen niet mee: die maakt deze run zelf.)"
    echo
    [ -f "$WERK/keur.txt" ] && cat "$WERK/keur.txt"
  } > "$MANIFEST"
}

# Onderbroken (Ctrl-C, afgeschoten, terminal dicht) loopt via stop(), dus ook dan
# gaat de repo terug zoals hij was. Bash voert dit uit zodra de lopende stap
# terugkomt; een Engelse bouw die op dat moment loopt, zet en/ zelf al terug.
trap 'stop 3 "onderbroken door een signaal — de run is niet afgemaakt"' INT TERM HUP

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

# Vanaf hier kan de run en/ en het manifest veranderen: eerst vastleggen hoe de
# repo erbij stond. Zonder die kopie begint hij niet — dan kan stop() niets terugzetten.
$PY bewaar --naar "$BEWAARD" || { echo "  niet begonnen: zonder bewaarde kopie kan een mislukte run de repo niet terugzetten"; exit 3; }
BEWAARD_NU=1
: > "$WERK/keur.txt"   # de keuring van een vorige run hoort niet in het manifest van deze

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
  echo; echo "Alleen de spooksite, zoals gevraagd. De repo hoort onaangeroerd te zijn — nagemeten:"
  $PY herstel --van "$BEWAARD" || { echo "  LET OP: de repo was NIET onaangeroerd — zie hierboven"; exit 1; }
  exit 0
fi

# ---------------------------------------------------------------- 3 ----
stap "3. echt, eerst in _site/ (nog niet in de repo)"
$PY bouw --soort echt || stop 1 "de Engelse bouw liep vast of gaf waarschuwingen"
$PY zet --naar _site || stop 1 "de Engelse bouw kon niet in _site/ gezet worden"
$PY keur --site _site --soort echt | tee "$WERK/keur.txt"
[ "${PIPESTATUS[0]}" -eq 0 ] || stop 1 "de echte Engelse site heeft gaten (zie hierboven)"

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
cp "$MANIFEST" "$REPO/$MANIFEST_IN_REPO" || stop 3 "het manifest kon niet naar $MANIFEST_IN_REPO"
trap - INT TERM HUP   # vanaf hier is het af: een signaal zet het geleverde niet meer terug
echo "  $(head -1 "$REPO/$MANIFEST_IN_REPO")"
echo
echo "KLAAR voor de echte site. De pers: git add en _tools/en_manifest.txt, commit,"
echo "en lever met _tools/naar_buiten.sh --productie."
git status --short -- en _tools/en_manifest.txt | sed 's/^/  /'
exit 0
