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

# ---- zaak 9 t/m 11: tellercommits (Ben, 30-9-2026, optie b) -------------
# Commit b9fd33a zette op 30-9 één onzichtbare tellerregel in elke bladzij, en
# werd daarmee de "laatste verandering" van oefenboeken/ozp1/. De wachter moet
# zo'n commit overslaan -- maar ALLEEN zo'n commit. De regel komt uit
# tellerregel.py naast de wachter die we toetsen, niet overgetikt.
REGEL="$(python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); from tellerregel import REGEL; print(REGEL)' "$(dirname "$WACHT")")"
OZP="oefenboeken/ozp1/00_fundament/00_fundament.html"
op() {   # $1 = map, $2 = datum JJJJ-MM-DD, $3 = boodschap
  git -C "$1" add -A
  GIT_AUTHOR_DATE="$2T12:00:00+02:00" GIT_COMMITTER_DATE="$2T12:00:00+02:00" \
    git -C "$1" commit -qm "$3"
}
teller_erbij() { printf '  %s\n' "$REGEL" >> "$1/$2"; }

# zaak 9: alleen de teller erbij -> overslaan, en dat hardop zeggen
T9="$(mktemp -d)"; klaarzetten "$T9"
plank_schrijven "$T9" "19 september 2026" "Vier"
op "$T9" 2026-09-19 "plank"
teller_erbij "$T9" "$OZP"; teller_erbij "$T9" oefenboeken/ozp1/index.html
op "$T9" 2026-09-30 "Bezoekersteller erbij"
H9="$(git -C "$T9" log -1 --format=%h)"
zaak "9  een commit met alleen de teller telt niet als boekwijziging" 0 \
     "alle nagerekende beloftes kloppen" "$T9"
zaak "9b en de overslag staat bij naam in de uitvoer" 0 \
     "1 tellercommit(s) overgeslagen in oefenboeken/ozp1/: $H9" "$T9"

# zaak 10: teller erbij ÉN iets anders -> telt gewoon mee.
# 10 in hetzelfde bestand, 10b in een ander bestand binnen dezelfde commit.
T10="$(mktemp -d)"; klaarzetten "$T10"
plank_schrijven "$T10" "19 september 2026" "Vier"
op "$T10" 2026-09-19 "plank"
teller_erbij "$T10" "$OZP"; echo '<p>nieuwe opgave</p>' >> "$T10/$OZP"
op "$T10" 2026-09-30 "Bezoekersteller erbij"   # <- de boodschap liegt met opzet
zaak "10 teller plus inhoud in één bestand telt wél" 1 \
     "is voor het laatst veranderd op 2026-09-30" "$T10"
T10b="$(mktemp -d)"; klaarzetten "$T10b"
plank_schrijven "$T10b" "19 september 2026" "Vier"
op "$T10b" 2026-09-19 "plank"
teller_erbij "$T10b" "$OZP"; echo '<p>nieuwe opgave</p>' >> "$T10b/oefenboeken/ozp1/index.html"
op "$T10b" 2026-09-30 "Bezoekersteller erbij"
zaak "10b teller in het ene, inhoud in het andere bestand telt wél" 1 \
     "is voor het laatst veranderd op 2026-09-30" "$T10b"

# zaak 11: de teller WEGHALEN is geen tellercommit. Eerst een echte
# tellercommit (25-9, overgeslagen), dan eentje die hem weer weghaalt (30-9).
T11="$(mktemp -d)"; klaarzetten "$T11"
plank_schrijven "$T11" "19 september 2026" "Vier"
op "$T11" 2026-09-19 "plank"
teller_erbij "$T11" "$OZP"
op "$T11" 2026-09-25 "Bezoekersteller erbij"
echo '<html>x</html>' > "$T11/$OZP"
op "$T11" 2026-09-30 "Bezoekersteller weer weg"
zaak "11 een commit die de teller weghaalt telt wél" 1 \
     "is voor het laatst veranderd op 2026-09-30" "$T11"

# zaak 11b: een inhoudsregel VERVANGEN door de teller. Toegevoegd is dan alleen
# de tellerregel -- alleen de weggehaalde regel verraadt dat hier inhoud
# verdween. Zaak 11 vangt dat niet: een commit zonder één toegevoegde regel
# telt ook al mee, dus daar hoeft de wachter weggehaalde regels niet te zien.
# De mutatieproef bewees het: "weggehaalde regels tellen niet" bleef groen.
T11b="$(mktemp -d)"; klaarzetten "$T11b"
plank_schrijven "$T11b" "19 september 2026" "Vier"
op "$T11b" 2026-09-19 "plank"
printf '  %s\n' "$REGEL" > "$T11b/$OZP"   # '<html>x</html>' eruit, teller erin
op "$T11b" 2026-09-30 "Bezoekersteller erbij"
zaak "11b een inhoudsregel vervangen door de teller telt wél" 1 \
     "is voor het laatst veranderd op 2026-09-30" "$T11b"
rm -rf "$T9" "$T10" "$T10b" "$T11" "$T11b"

# ---- zaak 12 t/m 14: doorstuurcommits (1-10-2026) ----------------------
# Het oude adres van OZP 1-thema 3 (gewisseld met 4 op 19-9) kreeg een
# doorstuurder, en die staat ÍN oefenboeken/ozp1/. Zonder uitzondering eiste de
# wachter daarna "Bijgewerkt 1 oktober" voor een bestand dat geen lezer leest.
# Overslaan mag -- maar alleen als er echt niets anders gebeurde.
doorstuurder() {   # $1 = bestand, $2 = doel
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<HTML
<!doctype html>
<html lang="nl"><head><meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=$2">
</head><body><a href="$2">verhuisd</a></body></html>
HTML
}
OUD="oefenboeken/ozp1/03_oud/03_oud.html"

# zaak 12: alleen een doorstuurder erbij -> overslaan, en dat hardop zeggen
T12="$(mktemp -d)"; klaarzetten "$T12"
plank_schrijven "$T12" "19 september 2026" "Vier"
op "$T12" 2026-09-19 "plank"
doorstuurder "$T12/$OUD" /oefenboeken/ozp1/00_fundament/00_fundament.html
op "$T12" 2026-10-01 "Doorstuurder voor het oude adres"
H12="$(git -C "$T12" log -1 --format=%h)"
zaak "12 een commit met alleen een doorstuurder telt niet als boekwijziging" 0 \
     "alle nagerekende beloftes kloppen" "$T12"
zaak "12b en de overslag staat bij naam in de uitvoer" 0 \
     "1 doorstuurcommit(s) overgeslagen in oefenboeken/ozp1/: $H12" "$T12"
# 12c: dezelfde doorstuurder later naar een ander doel (M, oud en nieuw allebei
# doorstuurder) is nog steeds geen boekwijziging.
doorstuurder "$T12/$OUD" /oefenboeken/ozp1/index.html
op "$T12" 2026-10-02 "Doorstuurder wijst ergens anders heen"
zaak "12c een doorstuurder bijstellen telt ook niet" 0 \
     "2 doorstuurcommit(s) overgeslagen" "$T12"

# zaak 13: doorstuurder erbij ÉN een echte bladzij veranderd -> telt wél
T13="$(mktemp -d)"; klaarzetten "$T13"
plank_schrijven "$T13" "19 september 2026" "Vier"
op "$T13" 2026-09-19 "plank"
doorstuurder "$T13/$OUD" /oefenboeken/ozp1/00_fundament/00_fundament.html
echo '<p>nieuwe opgave</p>' >> "$T13/$OZP"
op "$T13" 2026-10-01 "Doorstuurder voor het oude adres"   # <- de boodschap liegt met opzet
zaak "13 doorstuurder plus inhoud in één commit telt wél" 1 \
     "is voor het laatst veranderd op 2026-10-01" "$T13"

# zaak 14: een ECHTE bladzij vervangen door een doorstuurder -> telt wél.
# Na de commit is alles een doorstuurder; alleen de oude versie verraadt dat
# hier inhoud verdween. Zelfde val als zaak 11b bij de teller.
T14="$(mktemp -d)"; klaarzetten "$T14"
plank_schrijven "$T14" "19 september 2026" "Vier"
op "$T14" 2026-09-19 "plank"
doorstuurder "$T14/$OZP" /oefenboeken/ozp1/index.html
op "$T14" 2026-10-01 "Doorstuurder"
zaak "14 een bladzij vervangen door een doorstuurder telt wél" 1 \
     "is voor het laatst veranderd op 2026-10-01" "$T14"

# zaak 14b: een themamap met alleen een doorstuurder is geen verweesd thema,
# en telt ook niet mee als thema ("Vier" blijft vier).
T14b="$(mktemp -d)"; klaarzetten "$T14b"
plank_schrijven "$T14b" "19 september 2026" "Vier"
doorstuurder "$T14b/oefenboeken/psychometrie/05_oud/05_oud.html" /oefenboeken/psychometrie/04_pca/04_pca.html
op "$T14b" 2026-09-19 "oude adres van thema 5"
zaak "14b een map met alleen een doorstuurder is geen thema" 0 \
     "alle nagerekende beloftes kloppen" "$T14b"

# zaak 14c: een echte bladzij VERWIJDEREN telt wél. De nakijker van 1-10 zag
# dat geen zaak dit bewaakte: "D": [] liet de hele toets groen.
T14c="$(mktemp -d)"; klaarzetten "$T14c"
plank_schrijven "$T14c" "19 september 2026" "Vier"
op "$T14c" 2026-09-19 "plank"
git -C "$T14c" rm -q "$OZP"
op "$T14c" 2026-10-01 "Fundament weg"
zaak "14c een bladzij verwijderen telt wél" 1 \
     "is voor het laatst veranderd op 2026-10-01" "$T14c"

# zaak 14d: alleen een FIGUUR vervangen (binair, geen html) telt wél -- en de
# wachter mag er niet op omvallen. Gevonden door de nakijker van 1-10: de eerste
# versie van is_doorstuurcommit las elk bestand als tekst, kreeg bij een PNG een
# UnicodeDecodeError, en naar_buiten.sh las die crash als "werk het kaartje bij".
T14d="$(mktemp -d)"; klaarzetten "$T14d"
plank_schrijven "$T14d" "19 september 2026" "Vier"
op "$T14d" 2026-09-19 "plank"
printf '\211PNG\r\n\032\n\000\000\000\rIHDR\377\376' > "$T14d/oefenboeken/ozp1/00_fundament/figuur.png"
op "$T14d" 2026-10-01 "Figuur verbeterd"
zaak "14d een commit met alleen een figuur telt wél, zonder om te vallen" 1 \
     "is voor het laatst veranderd op 2026-10-01" "$T14d"
rm -rf "$T12" "$T13" "$T14" "$T14b" "$T14c" "$T14d"

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
# Sinds 30-9-2026 hangt er een TWEEDE wachter aan dezelfde draad: --productie
# kijkt ook of elke oefenboek-bladzij de bezoekersteller draagt. Die moet hier
# mee, anders meet zaak 8 niet "laat een kloppend kaartje door" maar "de
# tellerwachter ontbreekt" -- en dan staat de toets rood om de verkeerde reden.
cp "$BRON/_tools/controleer_tellers.py" "$T7/_tools/"
cp "$BRON/_tools/tellerregel.py"        "$T7/_tools/"
# En sinds 1-10-2026 een DERDE: de doorstuurwachter. Die is hier nagemaakt en
# groen -- zaak 7 en 8 meten de plank, en de doorstuurpoort heeft zijn eigen
# toets (doorstuurders_test.sh, met de echte naar_buiten.sh).
printf 'print("doorstuurders - nagemaakt, alles in orde")\n' > "$T7/_tools/doorstuurders.py"
# Eén echte bladzij mét teller, zodat de tellerwachter hier groen staat omdat
# hij iets ZAG en niet omdat er niets te zien was.
mkdir -p "$T7/oefenboeken/geteld"
cat > "$T7/oefenboeken/geteld/index.html" <<'HTML'
<!doctype html>
<html lang="nl"><head><meta charset="utf-8"><title>Geteld</title>
<script data-goatcounter="https://countcamp.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>
</head><body><p>een bladzij die geteld wordt</p></body></html>
HTML
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
