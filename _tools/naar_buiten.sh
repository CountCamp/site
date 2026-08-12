#!/usr/bin/env bash
# ============================================================
# naar_buiten.sh — de ENIGE deur waardoor werk de site verlaat.
# ------------------------------------------------------------
#   naar_buiten.sh --lokaal              proefdruk bouwen en hier bekijken
#   naar_buiten.sh --proefdruk           proefdruk op internet, via een PR
#   naar_buiten.sh --productie           naar de ECHTE site (countcamp.org)
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
    --lokaal|--proefdruk|--productie) WEG="$1" ;;
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

huidige_tak() { git branch --show-current; }

# ============================================================
case "$WEG" in

# ---- 1. lokaal ---------------------------------------------------------
--lokaal)
  echo "== proefdruk bouwen, hier op de machine"
  doe bash _spooksite/maak_banner.sh "lokale proefdruk" "tak $(huidige_tak)"
  if [ -z "$DROOG" ]; then
    QUARTO_PROFILE=spook quarto render
    controleer spook _site/index.html
    echo
    echo "klaar. Bekijken:"
    echo "  open $HIER/_site/index.html"
    echo "  of:  quarto preview   (dan ververst hij mee)"
    echo
    echo "LET OP: _site/ is nu een PROEFDRUK. Wil je hem weer als de echte site"
    echo "bekijken, draai dan gewoon: quarto render"
  else
    echo "  [droogloop] QUARTO_PROFILE=spook quarto render"
  fi
  ;;

# ---- 2. proefdruk op internet -----------------------------------------
--proefdruk)
  TAK="${TAK:-$(huidige_tak)}"
  echo "== proefdruk op internet, vanaf tak '$TAK'"
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
  echo "  eerst bouwen en controleren dat dit géén proefdruk is:"
  if [ -z "$DROOG" ]; then
    quarto render >/dev/null
    controleer echt _site/index.html || { echo "  Niet geleverd."; exit 1; }
  else
    echo "  [droogloop] quarto render && controleer echt _site/index.html"
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
