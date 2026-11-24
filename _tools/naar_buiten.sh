#!/usr/bin/env bash
# ============================================================
# naar_buiten.sh — de ENIGE deur waardoor werk de site verlaat.
# ------------------------------------------------------------
#   naar_buiten.sh --lokaal              proefdruk bouwen en hier bekijken
#   naar_buiten.sh --proefdruk           proefdruk op internet, via een PR
#   naar_buiten.sh --productie           naar de ECHTE site (countcamp.org)
#   naar_buiten.sh --nakijken            alleen de poorten draaien, verder niets
#
#   erbij mag:  --droogloop   zeg wat je zou doen, doe het niet
#               --tak <naam>  welke tak (standaard: de tak waar je op staat)
#
# Zónder vlag doet dit script niets. Dat is de hele bedoeling: er is geen
# handeling die "per ongeluk productie" kan worden. Wie de echte site wil
# raken, tikt --productie, en dat woord staat dan in zijn shell-geschiedenis.
#
# DRIE DEUREN, DRIE WEGEN — ze delen geen enkele stap.
#
#   --lokaal      quarto render met QUARTO_PROFILE=spook, naar _site/, klaar.
#                 (Elke bouw hier gaat via _tools/schone_bouw.py: in een kopie
#                 zonder .claude/, zodat Quarto de werkkopieën van zetters niet
#                 afloopt. Zie de kop van dat script.)
#                 Raakt geen tak, geen remote, niets buiten deze map.
#   --proefdruk   duwt je tak naar GitHub en maakt/ververst een pull request.
#                 De Action .github/workflows/proefdruk.yml bouwt hem met het
#                 spook-profiel en zet hem op countcamp.org/pr-preview/pr-N/.
#                 Raakt main niet.
#   --productie   duwt main. Alleen dat. De Action publish.yml bouwt met het
#                 echt-profiel en zet hem op countcamp.org.
#
# Waarom dit één script is en geen drie: zolang er drie scripts zijn, is er
# altijd iemand die de verkeerde pakt. Nu is er één script en moet je zéggen
# wat je wilt. En omdat de wegen binnenin niets delen, kan een fout in de
# proefdruk-tak niet doorlekken naar productie.
# ============================================================
set -euo pipefail
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH";; esac
export PATH
HIER="$(cd "$(dirname "$0")/.." && pwd)"      # de reporoot
cd "$HIER"

WEG=""
DROOG=""
TAK=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lokaal|--proefdruk|--productie|--nakijken) WEG="$1" ;;
    --droogloop) DROOG=ja ;;
    --tak) shift; TAK="${1:?geef een taknaam}" ;;
    *) echo "onbekende schakelaar: $1"; exit 1 ;;
  esac
  shift
done
[ -n "$WEG" ] || { sed -n '4,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

doe() {  # voer uit, of vertel het alleen bij een droogloop
  if [ -n "$DROOG" ]; then echo "  [droogloop] $*"; else echo "  \$ $*"; "$@"; fi
}

# ---- de controle die bij élke bouw hoort -------------------------------
# Een bladzij moet kunnen zeggen wat hij is. Deze controle leest de gebouwde
# HTML en eist dat de drie merktekens kloppen bij de weg die je koos. Hij
# bestaat omdat de omgekeerde fouten allebei stil zijn: een proefdruk zonder
# balk ziet eruit als de echte site, en een echte site met noindex verdwijnt
# uit Google zonder dat iemand iets merkt.
controleer() {   # $1 = spook | echt   $2 = bladzij
  local soort="$1" bz="$2" fout=0
  [ -f "$bz" ] || { echo "  FOUT: $bz is niet gebouwd"; return 1; }
  local heeft_noindex=nee heeft_balk=nee heeft_teller=nee
  grep -q 'name="robots" content="noindex' "$bz" && heeft_noindex=ja
  grep -q 'spookbalk' "$bz"                      && heeft_balk=ja
  grep -q 'goatcounter' "$bz"                    && heeft_teller=ja
  if [ "$soort" = spook ]; then
    [ "$heeft_noindex" = ja ] || { echo "  FOUT: proefdruk zonder noindex"; fout=1; }
    [ "$heeft_balk"    = ja ] || { echo "  FOUT: proefdruk zonder balk"; fout=1; }
    [ "$heeft_teller"  = nee ] || { echo "  FOUT: proefdruk telt mee in de bezoekcijfers"; fout=1; }
  else
    [ "$heeft_noindex" = nee ] || { echo "  FOUT: de echte site draagt noindex — die verdwijnt uit Google"; fout=1; }
    [ "$heeft_balk"    = nee ] || { echo "  FOUT: de echte site draagt de proefdruk-balk"; fout=1; }
    [ "$heeft_teller"  = ja  ] || { echo "  FOUT: de bezoekersteller ontbreekt (staat het echt-profiel aan?)"; fout=1; }
  fi
  [ "$fout" -eq 0 ] && echo "  gecontroleerd ($soort): noindex=$heeft_noindex balk=$heeft_balk teller=$heeft_teller"
  return "$fout"
}

# ---- de plank moet waarmaken wat hij belooft ---------------------------
# De kaartjes op /oefenboeken/ dragen beweringen die met de hand werden
# bijgehouden, en twee daarvan logen binnen twee dagen: het Psychometrie-
# kaartje telde twee thema's waar er vier stonden (21-9), het OZP 1-kaartje
# noemde een bijwerkdatum die negen dagen ouder was dan de map (22-9).
# `plankwacht.py` rekent ze allebei na uit de bestanden en de geschiedenis
# van deze repo.
#
# WAAROM HIER EN NIET IN DE ACTION: publish.yml checkt uit met
# actions/checkout@v4 zonder fetch-depth, dus met één commit geschiedenis.
# `git log` op een boekmap geeft daar niets terug -- en niets is dan geen
# antwoord maar blindheid.
#
# WAAROM HIJ OP --productie TEGENHOUDT EN OP DE PROEFWEGEN NIET:
# hij kan alleen rood worden doordat iemand een boek publiceerde zonder zijn
# kaartje bij te werken. Hij loopt niet mee met de kalender -- een kaartje dat
# vandaag klopt, klopt volgende week nog, want de wachter kijkt naar de laatste
# commit op de boekmap en niet naar vandaag. Een poort die alleen afgaat bij een
# echte fout, wordt niet omzeild. Op de proefwegen zegt hij het hardop en laat
# hij je door: daar kíjk je juist, en dan wil je het weten vóór je levert.
plank_nakijken() {   # $1 = blokkerend | melden
  local streng="$1" code=0
  python3 "$HIER/_tools/plankwacht.py" | sed 's/^/  /' || code=$?
  if [ "$code" -eq 0 ]; then return 0; fi
  if [ "$streng" = blokkerend ]; then
    echo "  De plank belooft iets dat niet klopt. Werk het kaartje bij, of"
    echo "  publiceer het boek waar het kaartje over gaat."
    return 1
  fi
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

# ---- elke oefenboek-bladzij moet geteld worden -------------------------
# `controleer()` hierboven kijkt naar de bezoekersteller, maar op ÉÉN bladzij:
# _site/index.html. Daar kon hij de echte blindheid niet zien, want de
# thuispagina kreeg zijn teller uit `_quarto-echt.yml` en stond dus altijd
# goed. De oefenboeken komen als RESOURCE binnen -- onveranderd gekopieerd,
# nooit door de site gerenderd -- dus voor die bladzijden zegt de teller op de
# thuispagina niets.
# (Sinds 14-11-2026 zet de bouw de teller in elke bladzij, ook in die bijlagen
# (_tools/teller_zetten.py, post-render); wat er gebouwd is leest
# `gebouwde_tellers_nakijken` hieronder. Deze poort leest nog steeds de BRONNEN:
# hij vangt een bijlage die zonder teller binnenkomt al vóór er gebouwd wordt.)
#
# Gemeten op 30-9-2026, vóór dit erin kwam: 112 van de 161 oefenboek-bladzijden
# droegen een teller. Het hele psychometrie-oefenboek was blind, en de
# bouwcontrole stond groen. Eén bladzij nakijken is geen steekproef maar een
# blinde vlek.
# Sinds 25-10-2026 (spoor en_voorpagina) loopt dezelfde wachter ook en/ na: de
# Engelse kant komt net zo als bijlage binnen, uit vier bouwwegen (publiceer_en.sh,
# de lab-pers voor en/book/, bouw_speelkist.py voor en/toys/, en sinds 28-10-2026
# publish_workbook.py --section en/workbooks voor de oefenboeken).
#
# WAAROM BLOKKEREND OP --productie EN MELDEND OP DE PROEFWEGEN: dit is dezelfde
# afweging als bij `plank_nakijken`. Rood kan hij alleen worden doordat er een
# bladzij binnenkwam zonder teller, en dat is altijd een echte fout -- hij loopt
# niet mee met de kalender. Een poort die alleen afgaat bij een echte fout, wordt
# niet omzeild.
tellers_nakijken() {   # $1 = blokkerend | melden
  local streng="$1" code=0
  python3 "$HIER/_tools/controleer_tellers.py" | sed 's/^/  /' || code=$?
  if [ "$code" -eq 0 ]; then return 0; fi
  # WAAROM DRIE REDENEN EN NIET ÉÉN: een verkeerde reden is erger dan geen, want
  # daar handelt iemand naar. Bij het schrijven hiervan gebeurde dat meteen: de
  # wachter stond niet in de proefrepo van plankwacht_test.sh, python kon het
  # bestand niet openen (afloopcode 2), en deze poort meldde vrolijk "er gaan
  # bladzijden de deur uit die niemand kan tellen". Er was niets met de
  # bladzijden; de wachter was er niet.
  case "$code" in
    1) echo "  Er gaan bladzijden de deur uit die niemand kan tellen."
       echo "  Herstellen: python3 _tools/controleer_tellers.py --repareer" ;;
    3) echo "  De tellerwachter kon niet kijken. Dat is geen schone uitslag maar"
       echo "  een blinde: stilte betekent ongeldig, nooit goed." ;;
    *) echo "  De tellerwachter zelf liep vast (afloopcode $code). Wat hij had"
       echo "  moeten meten is dus ONGEMETEN -- dit zegt niets over de bladzijden."
       echo "  Staat _tools/controleer_tellers.py er, en draait hij los?" ;;
  esac
  if [ "$streng" = blokkerend ]; then return 1; fi
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

# ---- elke oude bladwijzer moet ergens uitkomen -------------------------
# Sinds 1-10-2026 staan er doorstuurders op 181 oude adressen (zie
# _tools/doorstuurders.py). Die kunnen op twee manieren stil stukgaan:
#   * ze verdwijnen -- publish_workbook.py gooit oefenboeken/<boek>/ weg (hij
#     zet ze terug, maar een ander script doet dat misschien niet), en
#     publiceer_oefenboeken.sh spiegelt met rsync --delete;
#   * hun doel verhuist -- een thema krijgt een nieuw nummer, en de
#     doorstuurder wijst voortaan naar een 404.
# Allebei geven ze geen enkele foutmelding: de site bouwt, de 404 staat er
# gewoon. Zelfde afweging als hierboven: rood kan hij alleen worden door een
# echte fout, dus blokkerend op --productie en meldend op de proefwegen.
doorstuur_nakijken() {   # $1 = blokkerend | melden
  local streng="$1" code=0
  python3 "$HIER/_tools/doorstuurders.py" | sed 's/^/  /' || code=$?
  if [ "$code" -eq 0 ]; then return 0; fi
  case "$code" in
    1) echo "  Een oude bladwijzer komt niet (meer) uit waar hij hoort."
       echo "  Herstellen: python3 _tools/doorstuurders.py --bouw  (of --afleiden als een doel verhuisde)" ;;
    3) echo "  De doorstuurwachter kon niet kijken. Dat is geen schone uitslag maar"
       echo "  een blinde: stilte betekent ongeldig, nooit goed." ;;
    *) echo "  De doorstuurwachter zelf liep vast (afloopcode $code). Wat hij had"
       echo "  moeten meten is dus ONGEMETEN -- dit zegt niets over de doorstuurders."
       echo "  Staat _tools/doorstuurders.py er, en draait hij los?" ;;
  esac
  if [ "$streng" = blokkerend ]; then return 1; fi
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

# ---- elke losse tweeling draagt zijn taalstukken -----------------------
# Knopje NL · EN, hreflang en (op de Nederlandse kant) de taalbalk komen er op de
# site bij: _tools/taalonderdelen.py zet ze in elke bladzij die in taalparen.tsv
# `los` of `los-eigen` staat. Een pers die zo'n bladzij opnieuw neerzet, haalt ze
# weg: het boek (2-11 tot 11-11-2026, tot lever.sh ze zelf terugzette) en het
# Oefenboek TS (_werk/naar_site.sh en publish_workbook.py, 21-11-2026). Allebei
# stil: de site bouwt, de bladzij staat er, alleen de weg naar de andere taal is
# weg. Tot hier zag alleen publiceer_en.sh het, en die draait niet bij elke
# levering; deze poort en `--productie` bleven groen (gemeten 21-11, spoor
# ts_pers_beide: 9 Nederlandse TS-bladzijden kaal, "Alle poorten staan groen").
# Zelfde afweging als hierboven: rood kan hij alleen worden door een echte fout.
# Geen bouw nodig: hij leest de bladzijden zoals ze in de repo staan.
# Sinds 21-11-2026 (spoor taalpers) zet publish_workbook.py de stukken zelf terug
# (stap 5b). Deze poort blijft, want hij vangt elke andere weg: boek/publiceer.sh
# zonder lever.sh, een kopie met de hand, een pers die nog komt.
taalstukken_nakijken() {   # $1 = blokkerend | melden
  local streng="$1" code=0 uit
  uit="$(python3 "$HIER/_tools/taalonderdelen.py" los --controleer 2>&1)" || code=$?
  # Alleen wat níét in orde is, plus de telling; de rest is een lijst van 30+ regels.
  printf '%s\n' "$uit" | sed -n '/: in orde$/!s/^/  /p'
  if [ "$code" -eq 0 ]; then return 0; fi
  case "$code" in
    1) # Twee soorten gat, twee herstellen; de regels hierboven zeggen welke het is.
       echo "  Een bladzij met een tweeling mist zijn taalknopje, hreflang of taalbalk,"
       echo "  of een bladzij zonder tweeling draagt ze nog (een wees). Herstellen:"
       echo "    kale tweeling:  python3 _tools/taalonderdelen.py los  (en commit wat hij schrijft)"
       echo "    wees:           zet het paar terug in _tools/taalparen.tsv en draai los, of"
       echo "                    python3 _tools/taalonderdelen.py ruim <pad>" ;;
    3) echo "  De taalstukkenwachter kon niet kijken (de reden staat hierboven: de tabel"
       echo "  is niet te lezen, noemt geen losse tweeling, of het gereedschap liep vast)."
       echo "  Dat zegt niets over de bladzijden -- stilte betekent ongeldig, nooit goed." ;;
    *) echo "  De taalstukkenwachter zelf liep vast (afloopcode $code). Wat hij had"
       echo "  moeten meten is dus ONGEMETEN -- dit zegt niets over de bladzijden."
       echo "  Staat _tools/taalonderdelen.py er, en draait hij los?" ;;
  esac
  if [ "$streng" = blokkerend ]; then return 1; fi
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

# ---- geen testlezer-naam in een bestand van deze repo -------------------
# Deze repo is openbaar. Ben, 23-11-2026: "Site + speeltjes schoonmaken" -- de
# voornamen van de testlezers uit elk openbaar bestand, en een wachter erop.
# _tools/namenwacht.py leest elk bestand dat git kent (ook wat er in een zip, een
# .RData of een pdf zit) en kent alleen de uitzonderingen in
# _tools/namenwacht_uitzonderingen.tsv, elk met een reden.
# Geen bouw nodig: hij leest de repo, niet _site/. Hij moet ook niet wachten op
# een bouw, want wat in git staat is al openbaar zodra het gepusht is -- ook als
# het nooit op een bladzij komt (zo stonden de spoorverslagen in _logs/ er).
# Zelfde afweging als hierboven: rood kan hij alleen worden doordat er een naam
# in een bestand staat, en dat is altijd een echte fout. Blokkerend op
# --productie, meldend op de proefwegen. Bij een rode uitslag staat er
# <naam1>/<naam2> in plaats van de naam: zijn uitvoer komt ook in de openbare
# logboeken van de Actions.
# Ook alles wat de push nieuw openbaar maakt ($2, een bereik): de commitberichten,
# en elke TUSSENVERSIE van een bestand -- een push publiceert elke commit, niet
# alleen de top, en de Actions zien het pas daarna. Op --productie is dat
# origin/main..main, vlak na de fetch; zonder bereik (een repo zonder origin/main,
# zoals in de toetsen) zegt hij dat hardop. Staat een naam alleen in een
# tussenversie, dan zegt de wacht dat ook: lever de tak dan met een squash-merge.
namen_nakijken() {   # $1 = blokkerend | melden   $2 = bereik van de commitberichten (mag leeg)
  local streng="$1" bereik="${2:-}" code=0
  if [ -n "$bereik" ]; then
    python3 "$HIER/_tools/namenwacht.py" --bereik "$bereik" | sed 's/^/  /' || code=$?
  else
    echo "  (geen origin/main: commitberichten en tussenversies niet nagelezen, alleen de bestanden)"
    python3 "$HIER/_tools/namenwacht.py" | sed 's/^/  /' || code=$?
  fi
  if [ "$code" -eq 0 ]; then return 0; fi
  case "$code" in
    1) echo "  Er staat een testlezer-naam in een bestand van deze openbare repo."
       echo "  Herstellen: schrijf hem neutraal ('een testlezer', 'lezersronde 2'); de"
       echo "  regels staan hierboven. Wie de namen wil zien: python3 _tools/namenwacht.py --toon" ;;
    3) echo "  De namenwacht kon niet kijken (geen git, een bestand dat niet te lezen is,"
       echo "  of een uitzondering zonder reden). Stilte betekent ongeldig, nooit goed." ;;
    *) echo "  De namenwacht zelf liep vast (afloopcode $code). Wat hij had"
       echo "  moeten meten is dus ONGEMETEN -- dit zegt niets over de bestanden."
       echo "  Staat _tools/namenwacht.py er, en draait hij los?" ;;
  esac
  if [ "$streng" = blokkerend ]; then return 1; fi
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

# ---- de GEBOUWDE site: elke bladzij precies één teller, of geen ---------
# `tellers_nakijken` hierboven leest de BRONNEN van de bijlagen. Sinds
# 14-11-2026 (spoor teller2; ontworpen 9-10, spoor teller) zet de bouw zelf de
# teller erin (_tools/teller_zetten.py, post-render), en dan is de vraag die
# ertoe doet niet meer "staat hij in de bron" maar "staat hij in wat er de deur
# uitgaat". Dat leest deze: _site/, elke bladzij, niet alleen index.html.
#   echt   precies één teller per bladzij, het blok uit _tools/teller.html
#   spook  geen enkele teller, en overal de balk en noindex
# Gemeten op 8-10-2026: een spook-bouw droeg op 201 van de 213 bladzijden een
# werkende teller, en `controleer spook _site/index.html` stond groen --
# index.html was een van de twaalf die wél goed waren. Op 14-11: 224 van 243.
# Draait alleen NA een bouw, dus niet bij --nakijken: daar ligt geen verse
# _site/, en een oordeel over een oude bouw is een oordeel over iets anders.
# Dezelfde drie redenen als bij `tellers_nakijken`, om dezelfde reden.
gebouwde_tellers_nakijken() {   # $1 = echt | spook   $2 = blokkerend | melden
  local profiel="$1" streng="$2" code=0
  python3 "$HIER/_tools/tellerwacht.py" "--$profiel" --site "$HIER/_site" | sed 's/^/  /' || code=$?
  if [ "$code" -eq 0 ]; then return 0; fi
  case "$code" in
    1) if [ "$profiel" = echt ]; then
         echo "  De gebouwde site telt niet precies één keer per bladzij."
       else
         echo "  Deze proefdruk telt mee in Bens bezoekcijfers, of mist balk of noindex."
       fi ;;
    3) echo "  De tellerwacht kon niet kijken. Dat is geen schone uitslag maar"
       echo "  een blinde: stilte betekent ongeldig, nooit goed." ;;
    *) echo "  De tellerwacht zelf liep vast (afloopcode $code). Wat hij had"
       echo "  moeten meten is dus ONGEMETEN -- dit zegt niets over de bladzijden."
       echo "  Staat _tools/tellerwacht.py er, en draait hij los?" ;;
  esac
  if [ "$streng" = blokkerend ]; then return 1; fi
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

# ---- de GEBOUWDE site: sitemap en canonical ---------------------------------
# Ben, 24-11-2026: "Sitemap + dubbele adressen". De bouw schrijft sitemap.xml uit
# de gebouwde site en zet in elke echte bladzij één canonical
# (_tools/sitemap_zetten.py, post-render); dit leest _site/ na.
#   echt   elke echte bladzij in de sitemap met één canonical in de vorm .../, en
#          geen doorstuurder, noindex of 404 erin
#   spook  geen sitemap, en geen canonical die de proefdruk als echt adres opgeeft
# Draait alleen NA een bouw, om dezelfde reden als `gebouwde_tellers_nakijken`.
# Blokkerend op --productie, meldend op de proefwegen.
# Staat hier, tussen de teller en het commentaar, en niet onderaan: de
# mutatieproef van de commentaarpoort herkent die aan wat er direct onder staat.
gebouwde_sitemap_nakijken() {   # $1 = echt | spook   $2 = blokkerend | melden
  local profiel="$1" streng="$2" code=0
  python3 "$HIER/_tools/sitemapwacht.py" "--$profiel" --site "$HIER/_site" | sed 's/^/  /' || code=$?
  if [ "$code" -eq 0 ]; then return 0; fi
  case "$code" in
    1) if [ "$profiel" = echt ]; then
         echo "  De sitemap of de canonicals kloppen niet met de gebouwde site."
       else
         echo "  Deze proefdruk heeft een sitemap, of geeft zichzelf op als het echte adres."
       fi ;;
    3) echo "  De sitemapwacht kon niet kijken. Dat is geen schone uitslag maar"
       echo "  een blinde: stilte betekent ongeldig, nooit goed." ;;
    *) echo "  De sitemapwacht zelf liep vast (afloopcode $code). Wat hij had"
       echo "  moeten meten is dus ONGEMETEN -- dit zegt niets over de bladzijden."
       echo "  Staat _tools/sitemapwacht.py er, en draait hij los?" ;;
  esac
  if [ "$streng" = blokkerend ]; then return 1; fi
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

# ---- de GEBOUWDE site: geen HTML-commentaar in de bladzij -------------------
# Ben, 23-11-2026: "uit de pagina halen vóór publiceren (alle boeken)". De bouw
# haalt het eruit (_tools/commentaar_weg.py, post-render, na de teller); dit leest
# _site/ na, elke bladzij op elke diepte, met dezelfde ontleder. Toegestaan zijn
# alleen de merktekens van de teller en twee stempels die een machine terugleest
# (zie _tools/commentaarregel.py); de wachter noemt ze bij elke run.
# Draait alleen NA een bouw, om dezelfde reden als `gebouwde_tellers_nakijken`:
# bij --nakijken ligt er geen verse _site/, en de BRONNEN dragen hun commentaar
# met opzet ("qmd houdt korte verwijzing"). Blokkerend op --productie, meldend op
# de proefwegen -- rood kan hij alleen worden doordat de bouw er een liet staan,
# en dat is altijd een echte fout.
gebouwd_commentaar_nakijken() {   # $1 = blokkerend | melden
  local streng="$1" code=0
  # De hele uitvoer: bij een schone site zijn dat de tabel per map, de toegestane
  # lijst met hoe vaak, en het oordeel -- een uitsluiting die je niet ziet is een gat.
  python3 "$HIER/_tools/commentaarwacht.py" --site "$HIER/_site" | sed 's/^/  /' || code=$?
  if [ "$code" -eq 0 ]; then return 0; fi
  case "$code" in
    1) echo "  Er staat HTML-commentaar in de gebouwde site (zie de regels hierboven)." ;;
    3) echo "  De commentaarwacht kon niet (helemaal) kijken. Dat is geen schone uitslag"
       echo "  maar een blinde: stilte betekent ongeldig, nooit goed." ;;
    *) echo "  De commentaarwacht zelf liep vast (afloopcode $code). Wat hij had"
       echo "  moeten meten is dus ONGEMETEN -- dit zegt niets over de bladzijden."
       echo "  Staat _tools/commentaarwacht.py er, en draait hij los?" ;;
  esac
  if [ "$streng" = blokkerend ]; then return 1; fi
  echo "  (op een proefweg houdt dit je niet tegen -- op --productie wel)"
  return 0
}

huidige_tak() { git branch --show-current; }
# Het bereik van de commitberichten die nog niet op GitHub staan, voor namen_nakijken;
# leeg als er geen origin/main is.
nog_te_pushen() { git rev-parse --verify --quiet origin/main >/dev/null && echo "origin/main..HEAD" || true; }

# ============================================================
case "$WEG" in

# ---- 0. alleen nakijken ------------------------------------------------
# Draait de poorten die --productie ook draait, net zo streng, en doet daarna
# niets. Twee redenen om dit te hebben:
#
#   * je kunt vóór een levering vragen "zou dit doorkomen?" zonder main te
#     hoeven zijn en zonder iets te duwen;
#   * de poorten zijn ZO te proeven. Dat kon eerst niet: --productie eist dat
#     je op main staat en pusht daarna. Een wachter die je alleen kunt proeven
#     door te publiceren, wordt nooit geproefd -- en dan weet je niet of hij
#     bijt. Getoetst in _tools/tests/naar_buiten_teller_test.sh.
--nakijken)
  echo "== alleen nakijken (er wordt niets gebouwd en niets geduwd)"
  code=0
  plank_nakijken       blokkerend || code=1
  tellers_nakijken     blokkerend || code=1
  doorstuur_nakijken   blokkerend || code=1
  taalstukken_nakijken blokkerend || code=1
  namen_nakijken       blokkerend "$(nog_te_pushen)" || code=1
  echo
  if [ "$code" = 0 ]; then
    echo "Alle poorten staan groen. --productie zou hierop niet struikelen."
  else
    echo "Minstens één poort staat rood. --productie zou hier stoppen."
  fi
  exit "$code"
  ;;

# ---- 1. lokaal ---------------------------------------------------------
--lokaal)
  echo "== proefdruk bouwen, hier op de machine"
  plank_nakijken melden
  tellers_nakijken melden
  doorstuur_nakijken melden
  taalstukken_nakijken melden
  namen_nakijken melden "$(nog_te_pushen)"
  doe bash _spooksite/maak_banner.sh "lokale proefdruk" "tak $(huidige_tak)"
  if [ -z "$DROOG" ]; then
    # Niet ter plaatse: Quarto loopt dan de hele map af, ook .claude/worktrees/
    # van andere zetters (22-11-2026, zie de kop van _tools/schone_bouw.py).
    QUARTO_PROFILE=spook python3 _tools/schone_bouw.py --uit _site -- render
    controleer spook _site/index.html
    gebouwde_tellers_nakijken spook melden
    gebouwd_commentaar_nakijken melden
    gebouwde_sitemap_nakijken spook melden
    echo
    echo "klaar. Bekijken:"
    echo "  open $HIER/_site/index.html"
    echo "  of:  quarto preview   (dan ververst hij mee)"
    echo
    echo "LET OP: _site/ is nu een PROEFDRUK. Wil je hem weer als de echte site"
    echo "bekijken, draai dan: python3 _tools/schone_bouw.py --uit _site -- render"
  else
    echo "  [droogloop] QUARTO_PROFILE=spook python3 _tools/schone_bouw.py --uit _site -- render"
  fi
  ;;

# ---- 2. proefdruk op internet -----------------------------------------
--proefdruk)
  TAK="${TAK:-$(huidige_tak)}"
  echo "== proefdruk op internet, vanaf tak '$TAK'"
  plank_nakijken melden
  tellers_nakijken melden
  doorstuur_nakijken melden
  taalstukken_nakijken melden
  namen_nakijken melden "$(nog_te_pushen)"
  [ "$TAK" != main ] || { echo "STOP: main is de echte site, niet een proefdruk."; echo "  Maak eerst een tak: git switch -c <naam>"; exit 1; }
  git rev-parse --verify --quiet "$TAK" >/dev/null || { echo "STOP: tak '$TAK' bestaat niet"; exit 1; }
  if [ -n "$(git status --porcelain)" ]; then
    echo "STOP: er ligt ongecommit werk. Wat niet gecommit is, komt niet in de proefdruk:"
    git status --short | head -10 | sed 's/^/    /'
    exit 1
  fi
  doe git push -u origin "$TAK"
  if [ -z "$DROOG" ]; then
    if gh pr view "$TAK" >/dev/null 2>&1; then
      echo "  bestaande pull request bijgewerkt."
    else
      gh pr create --base main --head "$TAK" \
        --title "proefdruk: $TAK" \
        --body "Proefdruk-PR. De Action zet hem neer op /pr-preview/pr-<nummer>/ met noindex en een balk. Niet bedoeld om zomaar te mergen." \
        --draft
    fi
    NR="$(gh pr view "$TAK" --json number -q .number)"
    echo
    echo "over een minuut of twee staat hij hier:"
    echo "  https://countcamp.org/pr-preview/pr-$NR/"
    echo "de Action volgen:  gh run watch"
  else
    echo "  [droogloop] gh pr create --base main --head $TAK --draft"
  fi
  ;;

# ---- 3. de echte site --------------------------------------------------
--productie)
  echo "== NAAR DE ECHTE SITE (countcamp.org)"
  TAK="$(huidige_tak)"
  [ "$TAK" = main ] || { echo "STOP: je staat op '$TAK'. De echte site komt van main."; exit 1; }
  if [ -n "$(git status --porcelain)" ]; then
    echo "STOP: er ligt ongecommit werk. Commit het of laat het staan, maar lever het niet half:"
    git status --short | head -10 | sed 's/^/    /'
    exit 1
  fi
  git fetch --quiet origin main
  ACHTER="$(git rev-list --count main..origin/main)"
  [ "$ACHTER" = 0 ] || { echo "STOP: je loopt $ACHTER commit(s) achter op GitHub. Eerst: git pull"; exit 1; }
  VOOR="$(git rev-list --count origin/main..main)"
  [ "$VOOR" != 0 ] || { echo "Er is niets te leveren — main is gelijk aan GitHub."; exit 0; }

  echo "  te leveren: $VOOR commit(s)"
  git log --oneline origin/main..main | sed 's/^/    /'
  echo
  echo "  eerst nakijken of de plank waarmaakt wat hij belooft:"
  plank_nakijken blokkerend     || { echo "  Niet geleverd."; exit 1; }
  tellers_nakijken blokkerend   || { echo "  Niet geleverd."; exit 1; }
  doorstuur_nakijken blokkerend || { echo "  Niet geleverd."; exit 1; }
  taalstukken_nakijken blokkerend || { echo "  Niet geleverd."; exit 1; }
  namen_nakijken blokkerend origin/main..main || { echo "  Niet geleverd."; exit 1; }
  echo
  echo "  dan bouwen en controleren dat dit géén proefdruk is:"
  if [ -z "$DROOG" ]; then
    # In een kopie zonder .claude/: hier, in de gedeelde checkout, liep een bouw
    # ter plaatse twee keer vast op de werkkopie van een andere zetter
    # (22-11-2026, spoor pers_nacht; zie de kop van _tools/schone_bouw.py).
    python3 _tools/schone_bouw.py --uit _site -- render >/dev/null
    controleer echt _site/index.html || { echo "  Niet geleverd."; exit 1; }
    gebouwde_tellers_nakijken echt blokkerend || { echo "  Niet geleverd."; exit 1; }
    gebouwd_commentaar_nakijken blokkerend || { echo "  Niet geleverd."; exit 1; }
    gebouwde_sitemap_nakijken echt blokkerend || { echo "  Niet geleverd."; exit 1; }
  else
    echo "  [droogloop] python3 _tools/schone_bouw.py --uit _site -- render && controleer echt _site/index.html"
    echo "  [droogloop] python3 _tools/tellerwacht.py --echt"
    echo "  [droogloop] python3 _tools/commentaarwacht.py"
    echo "  [droogloop] python3 _tools/sitemapwacht.py --echt"
  fi
  echo
  doe git push origin main
  [ -n "$DROOG" ] || {
    echo
    echo "gepusht. De Action bouwt nu de site."
    echo "  volgen:   gh run watch"
    echo "  daarna:   curl -sI https://countcamp.org | head -1"
  }
  ;;
esac
