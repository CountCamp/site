#!/usr/bin/env bash
# ============================================================
# plankwacht_test.sh — bijt de plankwacht, of doet hij maar alsof?
#
# Elke zaak hieronder bouwt een ECHTE kleine git-repo met echte commits op
# echte datums, en laat de wachter daar los. Niet met een nagemaakte
# git-uitvoer: de val die we hier vangen zit juist in git (een ondiepe kloon
# geeft geen fout maar leegte), en die val kun je niet namaken.
#
# De twee zaken van deze week staan er als zaak 2 en 3 in. Zaak 1 is de
# tegenproef -- een kaartje dat klopt moet stil blijven -- en zaak 1b is de
# belangrijkste van allemaal: bij groen moet hij ook echt IETS gemeten hebben.
# Een wachter die nul beloftes narekent en "goed" zegt, is precies het soort
# stilte waar dit huis al vaker in is gelopen.
#
#   bash _tools/tests/plankwacht_test.sh
#
# Afloopcode 0 = alle zaken goed, 1 = er zakt er een.
# ============================================================
set -uo pipefail

# PLANKWACHT wijst desgewenst naar een andere kopie. Dat is er niet voor de
# smaak: zo kun je een kreupel gemaakte wachter erdoor halen en zien dat deze
# toets dán rood wordt. Een toets die alleen groen kan worden, meet niets.
WACHT="${PLANKWACHT:-$(cd "$(dirname "$0")/../.." && pwd)/_tools/plankwacht.py}"
GOED=0
ZAKT=0

klaarzetten() {   # $1 = doelmap; bouwt een boek met 4 thema's + een plank
  local T="$1"
  mkdir -p "$T/oefenboeken/psychometrie" "$T/oefenboeken/ozp1"
  for n in 01_meten 02_betrouwbaarheid 03_validiteit 04_pca; do
    mkdir -p "$T/oefenboeken/psychometrie/$n"
    echo "<html>thema $n</html>" > "$T/oefenboeken/psychometrie/$n/$n.html"
  done
  {
    echo '<html><body>'
    for n in 01_meten 02_betrouwbaarheid 03_validiteit 04_pca; do
      echo "<a href=\"./$n/$n.html\">$n</a>"
    done
    echo '</body></html>'
  } > "$T/oefenboeken/psychometrie/index.html"
  mkdir -p "$T/oefenboeken/ozp1/00_fundament"
  echo '<html><a href="./00_fundament/00_fundament.html">x</a></html>' > "$T/oefenboeken/ozp1/index.html"
  echo '<html>x</html>' > "$T/oefenboeken/ozp1/00_fundament/00_fundament.html"

  git -C "$T" init -q
  git -C "$T" config user.email toets@countcamp.org
  git -C "$T" config user.name  plankwacht-toets
  git -C "$T" add -A
  GIT_AUTHOR_DATE="2026-09-19T12:00:00+02:00" \
  GIT_COMMITTER_DATE="2026-09-19T12:00:00+02:00" \
    git -C "$T" commit -qm "de boeken, gepubliceerd op 19 september"
}

plank_schrijven() {   # $1 = doelmap, $2 = datum-belofte, $3 = telling-belofte
  cat > "$1/oefenboeken/index.qmd" <<QMD
---
title: "Oefenboeken"
---

## Online

::: {.cc-plank}

::: {.cc-boek .cc-boek-vak}
### [Oefenboek Psychometrie →](psychometrie/index.html) [R]{.cc-chip}
Een tweedejaarsvak. **$3 van de zeven thema's staan online:** meten,
betrouwbaarheid, validiteit en PCA.
:::

::: {.cc-boek .cc-boek-vak}
### [Oefenboek OZP 1 →](ozp1/index.html) [SPSS]{.cc-chip}
Onderzoekspracticum 1, een eerstejaarsvak.

**Bijgewerkt $2** — nieuw hoofdstuk Meten & methodenleer.
:::

::: {.cc-boek .cc-boek-straks}
### Oefenboek OZP 2 [in opbouw]{.cc-chip .cc-chip-straks}
Er is nog niets te lezen.
:::

:::
QMD
}

zaak() {   # $1 = naam, $2 = verwachte afloopcode, $3 = tekst die erin moet staan, $4 = map
  local naam="$1" wil="$2" moet="$3" T="$4"
  local uit code
  uit="$(python3 "$WACHT" --wortel "$T" 2>&1)"; code=$?
  local oordeel="goed"
  [ "$code" = "$wil" ] || oordeel="fout"
  if [ -n "$moet" ] && ! printf '%s' "$uit" | grep -qF -- "$moet"; then oordeel="fout"; fi
  if [ "$oordeel" = goed ]; then
    GOED=$((GOED + 1))
    printf '  ok      %s (afloopcode %s)\n' "$naam" "$code"
  else
    ZAKT=$((ZAKT + 1))
    printf '  ZAKT    %s -- wilde afloopcode %s en de tekst %s\n' "$naam" "$wil" "${moet:-<geen>}"
    printf '%s\n' "$uit" | sed 's/^/            /'
  fi
}

# Geen aantal in deze kop: dat getal verouderde al bij de eerste zaak die erbij
# kwam. De telling staat onderaan, en die telt zichzelf.
echo "plankwacht_test — zaken:"

# ---- zaak 1: een kaartje dat klopt, moet stil blijven -------------------
T1="$(mktemp -d)"; klaarzetten "$T1"
plank_schrijven "$T1" "19 september 2026" "Vier"
zaak "1  een kloppende plank blijft stil" 0 "alle nagerekende beloftes kloppen" "$T1"

# ---- zaak 1b: ... maar dan moet hij wél iets gemeten hebben -------------
# Zonder deze zaak zou een wachter die nul beloftes herkent ook "ok" halen.
if python3 "$WACHT" --wortel "$T1" 2>&1 | grep -qF "2 belofte(s) nagerekend"; then
  GOED=$((GOED + 1)); echo "  ok      1b groen betekent ook echt gemeten (2 beloftes)"
else
  ZAKT=$((ZAKT + 1)); echo "  ZAKT    1b groen zonder dat er iets nagerekend is"
  python3 "$WACHT" --wortel "$T1" 2>&1 | sed 's/^/            /'
fi

# ---- zaak 2: de OZP 1-zaak van 22-9-2026 -------------------------------
# Het kaartje zegt 10 september, de map is op 19 september ververst.
T2="$(mktemp -d)"; klaarzetten "$T2"
plank_schrijven "$T2" "10 september 2026" "Vier"
zaak "2  verouderde Bijgewerkt-datum (OZP 1, 22-9)" 1 \
     "is voor het laatst veranderd op 2026-09-19" "$T2"
zaak "2b en hij noemt wélk kaartje" 1 "Oefenboek OZP 1" "$T2"

# ---- zaak 3: de Psychometrie-zaak van 21-9-2026 ------------------------
# Het kaartje zegt twee, er staan er vier online.
T3="$(mktemp -d)"; klaarzetten "$T3"
plank_schrijven "$T3" "19 september 2026" "Twee"
zaak "3  verouderde thema-telling (Psychometrie, 21-9)" 1 \
     "maar er staan er 4" "$T3"
zaak "3b en hij noemt de thema's bij naam" 1 "03_validiteit" "$T3"

# ---- zaak 4: blind is niet groen ---------------------------------------
# Een map zonder enige commit -- zoals in een ondiepe kloon (actions/checkout
# zonder fetch-depth). Leeg mag daar nooit "goed" heten.
T4="$(mktemp -d)"; klaarzetten "$T4"
plank_schrijven "$T4" "19 september 2026" "Vier"
mkdir -p "$T4/oefenboeken/nieuw/01_x"
echo '<html><a href="./01_x/01_x.html">x</a></html>' > "$T4/oefenboeken/nieuw/index.html"
echo '<html>x</html>' > "$T4/oefenboeken/nieuw/01_x/01_x.html"
cat >> "$T4/oefenboeken/index.qmd" <<'QMD'

::: {.cc-boek}
### [Oefenboek Nieuw →](nieuw/index.html)
**Bijgewerkt 22 september 2026** — nog nergens gecommit.
:::
QMD
zaak "4  een map zonder geschiedenis heet blind, niet goed" 3 \
     "geen enkele commit raakt" "$T4"

# ---- zaak 5: veranderde formulering is ook blind -----------------------
# Als niemand de beloftes meer herkent, is dat geen schone plank.
T5="$(mktemp -d)"; klaarzetten "$T5"
cat > "$T5/oefenboeken/index.qmd" <<'QMD'
---
title: "Oefenboeken"
---

::: {.cc-boek}
### [Oefenboek Psychometrie →](psychometrie/index.html)
Bijgehouden sinds kort; er zijn inmiddels aardig wat thema's beschikbaar.
:::
QMD
zaak "5  geen herkende belofte heet blind, niet goed" 3 \
     "geen enkele belofte herkend" "$T5"

# ---- zaak 6: een thema-map waar het boek niet naar linkt ---------------
T6="$(mktemp -d)"; klaarzetten "$T6"
plank_schrijven "$T6" "19 september 2026" "Vier"
mkdir -p "$T6/oefenboeken/psychometrie/05_cfa"
echo '<html>x</html>' > "$T6/oefenboeken/psychometrie/05_cfa/05_cfa.html"
git -C "$T6" add -A
GIT_AUTHOR_DATE="2026-09-19T12:00:00+02:00" GIT_COMMITTER_DATE="2026-09-19T12:00:00+02:00" \
  git -C "$T6" commit -qm "thema 5 erbij gezet maar niet gelinkt"
zaak "6  een thema-map zonder link bereikt geen lezer" 1 "05_cfa" "$T6"

# ---- zaak 6b en 6c: de kale vorm "<telwoord> thema's" (het MVDA-kaartje) --
# Dat kaartje opent met "er komen nog thema's bij" en noemt zijn telling pas
# in de zin daarna. Wie bij de eerste treffer stopt, leest "nog", ziet dat dat
# geen getal is, en meldt dat er geen belofte staat -- stil en fout.
mvda_plank() {   # $1 = map, $2 = telwoord
  cat > "$1/oefenboeken/index.qmd" <<QMD
---
title: "Oefenboeken"
---
::: {.cc-boek}
### [Oefenboek MVDA →](psychometrie/index.html) [R]{.cc-chip}
**Voorlopige versie — er komen nog thema's bij.** Een opfris plus $2 thema's:
meten, betrouwbaarheid, validiteit en PCA.
:::
QMD
}
T6b="$(mktemp -d)"; klaarzetten "$T6b"; mvda_plank "$T6b" "vier"
zaak "6b de kale vorm wordt herkend en klopt" 0 "1 belofte(s) nagerekend" "$T6b"
T6c="$(mktemp -d)"; klaarzetten "$T6c"; mvda_plank "$T6c" "zes"
zaak "6c de kale vorm vuurt als hij verouderd is" 1 "maar er staan er 4" "$T6c"
rm -rf "$T6b" "$T6c"

# ---- zaak 7 en 8: de BEDRADING, niet de wachter ------------------------
# Een wachter die werkt maar nergens aan hangt, gaat nooit af. Dat is hier op
# 18-8-2026 gebeurd met zeven mechanismen tegelijk: alle zelftests groen, geen
# enkele hook geïnstalleerd. Dus draaien we hier de echte naar_buiten.sh.
BRON="$(cd "$(dirname "$0")/../.." && pwd)"
T7="$(mktemp -d)"; BLOOT="$(mktemp -d)"
klaarzetten "$T7"
mkdir -p "$T7/_tools"
cp "$BRON/_tools/naar_buiten.sh" "$T7/_tools/"
cp "$BRON/_tools/plankwacht.py"  "$T7/_tools/"
plank_schrijven "$T7" "19 september 2026" "Vier"
git -C "$T7" add -A
git -C "$T7" commit -qm "de plank en het gereedschap"
git -C "$BLOOT" init -q --bare
git -C "$T7" remote add origin "$BLOOT"
git -C "$T7" branch -M main
git -C "$T7" push -q origin main
# één commit vóór op origin, anders stopt --productie al bij "niets te leveren"
plank_schrijven "$T7" "10 september 2026" "Vier"   # <- weer verouderd gemaakt
git -C "$T7" commit -qam "kaartje verouderd"

uit7="$(cd "$T7" && bash _tools/naar_buiten.sh --productie --droogloop 2>&1)"; code7=$?
if [ "$code7" -ne 0 ] && printf '%s' "$uit7" | grep -qF "Niet geleverd"; then
  GOED=$((GOED + 1)); echo "  ok      7  --productie houdt een verouderd kaartje tegen (afloopcode $code7)"
else
  ZAKT=$((ZAKT + 1)); echo "  ZAKT    7  --productie liet een verouderd kaartje door (afloopcode $code7)"
  printf '%s\n' "$uit7" | sed 's/^/            /'
fi

plank_schrijven "$T7" "19 september 2026" "Vier"   # <- weer kloppend
git -C "$T7" commit -qam "kaartje bijgewerkt"
uit8="$(cd "$T7" && bash _tools/naar_buiten.sh --productie --droogloop 2>&1)"; code8=$?
if [ "$code8" -eq 0 ] && printf '%s' "$uit8" | grep -qF "alle nagerekende beloftes kloppen"; then
  GOED=$((GOED + 1)); echo "  ok      8  --productie laat een kloppend kaartje door"
else
  ZAKT=$((ZAKT + 1)); echo "  ZAKT    8  --productie hield een kloppend kaartje tegen (afloopcode $code8)"
  printf '%s\n' "$uit8" | sed 's/^/            /'
fi

rm -rf "$T1" "$T2" "$T3" "$T4" "$T5" "$T6" "$T7" "$BLOOT"

echo
echo "goed: $GOED   gezakt: $ZAKT"
[ "$ZAKT" -eq 0 ] || exit 1
