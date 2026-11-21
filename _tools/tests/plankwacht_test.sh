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

# Sinds 14-11-2026 kijkt de wachter ook of de Engelse plank en de twee
# thuiskaarten met de Nederlandse plank meelopen (de spiegel). Een proefrepo
# zonder die drie bestanden is dan blind (afloop 3), en elke zaak hierboven zou
# om die reden zakken in plaats van om de zijne. Daarom schrijft zaak() vóór
# elke run een KLOPPENDE spiegel, afgeleid uit de Nederlandse plank zoals hij
# op dat moment is. De zaken die de spiegel zelf toetsen (16 en verder) zetten
# SPIEGEL_LATEN=1 en schrijven hem met de hand.
spiegel_schrijven() {   # $1 = map
  python3 - "$1" <<'PY'
import os, re, sys
T = sys.argv[1]
regels = open(os.path.join(T, "oefenboeken/index.qmd"), encoding="utf-8").read().splitlines()
kaarten = []
for i, r in enumerate(regels):
    if not r.lstrip().startswith("::: {.cc-boek"):
        continue
    for r2 in regels[i + 1:]:
        if re.fullmatch(r":{3,}\s*", r2):
            break
        m = re.match(r"^#{2,4}\s*\[([^\]]*?)\s*→?\s*\]\(([^)]+)\)", r2.strip())
        if m:
            kaarten.append((m.group(1), m.group(2), ".cc-boek-vak" in r))
            break
os.makedirs(os.path.join(T, "en/workbooks"), exist_ok=True)
with open(os.path.join(T, "en/workbooks/index.qmd"), "w", encoding="utf-8") as f:
    f.write('---\ntitle: "Practice books"\n---\n')
    for titel, href, vak in kaarten:
        klas = ".cc-boek .cc-boek-vak" if vak else ".cc-boek"
        f.write(f"\n::: {{{klas}}}\n### [{titel} (in Dutch) →](../../oefenboeken/{href}){{hreflang=\"nl\"}}\n:::\n")
for pad, plank, voor in (("index.qmd", "oefenboeken/index.qmd", "oefenboeken/"),
                         ("en/index.qmd", "workbooks/index.qmd", "../oefenboeken/")):
    with open(os.path.join(T, pad), "w", encoding="utf-8") as f:
        f.write(f"---\ntitle: thuis\n---\n\n::: {{.cc-card .cc-card-werkboeken}}\n### [Oefenboeken]({plank})\n")
        # Op de Engelse thuiskaart draagt elke boeklink sinds 21-11-2026 hreflang en
        # "(in Dutch)" (het taalmerk); op de Nederlandse niet.
        if pad == "en/index.qmd":
            links = [f"[{t} (in Dutch)]({voor}{h}){{hreflang=\"nl\"}}" for t, h, v in kaarten if v]
        else:
            links = [f"[{t}]({voor}{h})" for t, h, v in kaarten if v]
        f.write("Volg je een vak? " + ", ".join(links) + ".\n:::\n")
PY
}

zaak() {   # $1 = naam, $2 = verwachte afloopcode, $3 = tekst die erin moet staan, $4 = map
  local naam="$1" wil="$2" moet="$3" T="$4"
  local uit code
  [ -n "${SPIEGEL_LATEN:-}" ] || spiegel_schrijven "$T"
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

# ---- zaak 15 t/m 15e: hoofdstukken en bijlagen (OZP 1, 28-10-2026) -------
# Het advies voor de OZP 1-zin zei "twee bijlagen"; het boek had er drie. En
# "Dertien hoofdstukken" stond er al maanden zonder dat iets het narekende.
# Het boek hieronder heeft drie hoofdstukken (00, 01, 02) en twee bijlagen
# (12, 14). Bijlage 14 krijgt ook een link uit de lopende tekst zónder het
# woord "Bijlage": één label in de zijbalk is genoeg, net als in het echte boek.
ozp_boek() {   # $1 = map
  local B="$1/oefenboeken/ozp1"
  for n in 01_a 02_b 12_tabellen 14_keuze; do
    mkdir -p "$B/$n"; echo '<html>x</html>' > "$B/$n/$n.html"
  done
  cat > "$B/index.html" <<'HTML'
<html><body><nav id="quarto-sidebar">
<a href="./00_fundament/00_fundament.html"><span class="menu-text">Deel 0 · Fundament</span></a>
<a href="./01_a/01_a.html"><span class="menu-text">Thema 1 · A</span></a>
<a href="./02_b/02_b.html"><span class="menu-text">Thema 2 · B</span></a>
<a href="./14_keuze/14_keuze.html"><span class="menu-text">Bijlage · Keuze</span></a>
<a href="./12_tabellen/12_tabellen.html"><span class="menu-text">Bijlage · Tabellen</span></a>
</nav><p>Zie <a href="./14_keuze/14_keuze.html">de keuze</a>.</p></body></html>
HTML
  op "$1" 2026-09-19 "OZP 1 met twee bijlagen"
}
ozp_plank() {   # $1 = map, $2 = hoofdstukken-zin, $3 = bijlagen-zin
  cat > "$1/oefenboeken/index.qmd" <<QMD
---
title: "Oefenboeken"
---
::: {.cc-boek .cc-boek-vak}
### [Oefenboek OZP 1 →](ozp1/index.html) [SPSS]{.cc-chip}
Een eerstejaarsvak. $2: van fundament naar B. $3: keuze en tabellen.
:::
QMD
}
T15="$(mktemp -d)"; klaarzetten "$T15"; ozp_boek "$T15"
ozp_plank "$T15" "Drie hoofdstukken" "Achterin twee bijlagen"
zaak "15  hoofdstukken en bijlagen die kloppen blijven stil" 0 "2 belofte(s) nagerekend" "$T15"
ozp_plank "$T15" "Dertien hoofdstukken" "Achterin twee bijlagen"
zaak "15b een verouderd aantal hoofdstukken vuurt" 1 \
     "zegt 'Dertien hoofdstukken', maar er staan er 3" "$T15"
ozp_plank "$T15" "Drie hoofdstukken" "Achterin drie bijlagen"
zaak "15c een verkeerd aantal bijlagen vuurt (het advies van 28-10)" 1 \
     "zegt 'drie bijlagen', maar er staan er 2 in oefenboeken/ozp1/: 12_tabellen, 14_keuze" "$T15"
# 15d: "Alle hoofdstukken" (het R-oefenboek) is geen getal en dus geen belofte;
# hij mag niet vuren en ook niet als blind tellen.
ozp_plank "$T15" "Alle hoofdstukken" "Achterin twee bijlagen"
zaak "15d 'Alle hoofdstukken' is geen belofte" 0 "1 belofte(s) nagerekend" "$T15"
# 15e: een map waar het boek niet (meer) naar linkt, telt nergens mee -- ook
# niet als hoofdstuk, al staat hij er nog. Het echte OZP 1 heeft er zo een paar
# (03_normaalverdeling_z en 04_discrete_kansvariabelen, oude adressen van 19-9).
sed -i.bak '/12_tabellen/d' "$T15/oefenboeken/ozp1/index.html" && rm -f "$T15/oefenboeken/ozp1/index.html.bak"
ozp_plank "$T15" "Drie hoofdstukken" "Achterin de bijlagen"
zaak "15e een map zonder link telt niet als hoofdstuk" 0 "1 belofte(s) nagerekend" "$T15"
rm -rf "$T15"

# ---- zaak 16 t/m 16h: de spiegel (14-11-2026) ----------------------------
# Op 12-11 kwam Toetsende Statistiek op de Nederlandse plank en twee dagen lang
# niet op de Engelse; niets zei het. Ben besliste op 14-11: Engels in dezelfde
# volgorde, en de thuiskaart noemt de vakken. plank_schrijven geeft twee boeken
# met een link, allebei een vak: Psychometrie en OZP 1 (OZP 2 heeft er geen).
T16="$(mktemp -d)"; klaarzetten "$T16"
plank_schrijven "$T16" "19 september 2026" "Vier"
zaak "16  een kloppende spiegel blijft stil, en zegt wat hij zag" 0 \
     "spiegel: 2 boek(en) met een link op oefenboeken/index.qmd, 2 daarvan ook op en/workbooks/index.qmd, in dezelfde volgorde" "$T16"
EN16="$T16/en/workbooks/index.qmd"
cp "$EN16" "$T16/en_goed.qmd"

# 16b: het geval van 12-11 -- een boek ontbreekt op de Engelse plank
python3 - "$EN16" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
s = re.sub(r"\n::: \{[^}]*\}\n### \[Oefenboek Psychometrie[^\n]*\n:::\n", "\n", s)
open(sys.argv[1], "w", encoding="utf-8").write(s)
PY
SPIEGEL_LATEN=1 zaak "16b een boek dat op de Engelse plank ontbreekt, vuurt (TS, 12-11)" 1 \
     "staat niet op en/workbooks/index.qmd -- geen enkel kaartje daar linkt naar oefenboeken/psychometrie/index.html" "$T16"
SPIEGEL_LATEN=1 zaak "16c en hij noemt het Nederlandse kaartje bij naam" 1 "FOUT  Oefenboek Psychometrie" "$T16"

# 16d: alle boeken staan er, maar in een andere volgorde
python3 - "$T16/en_goed.qmd" "$EN16" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
kop, *kaarten = re.split(r"\n(?=::: \{)", s)
open(sys.argv[2], "w", encoding="utf-8").write("\n".join([kop] + kaarten[::-1]))
PY
SPIEGEL_LATEN=1 zaak "16d de Engelse plank in een andere volgorde vuurt" 1 "staat in de verkeerde volgorde" "$T16"

# 16e: een Engels boek NAAST het Nederlandse is geen afwijking
cp "$T16/en_goed.qmd" "$EN16"
printf '\n::: {.cc-boek .cc-boek-vak}\n### [Psychometrics Practice Book →](psychometrics/index.html){hreflang="en"} [R]{.cc-chip}\n:::\n' >> "$EN16"
printf 'Volg je een vak? [Psychometrics](workbooks/psychometrics/index.html){hreflang="en"}.\n' > "$T16/regel"
python3 - "$T16/en/index.qmd" "$T16/regel" <<'PY'
import sys
s = open(sys.argv[1], encoding="utf-8").read()
s = s.replace("\n:::\n", "\n" + open(sys.argv[2], encoding="utf-8").read() + ":::\n", 1)
open(sys.argv[1], "w", encoding="utf-8").write(s)
PY
SPIEGEL_LATEN=1 zaak "16e een Engels boek naast het Nederlandse is geen afwijking" 0 \
     "2 daarvan ook op en/workbooks/index.qmd, in dezelfde volgorde" "$T16"

# 16f: een voorbeeldkaart in een commentaar is geen kaart. Gemeten 14-11-2026 op
# de echte Engelse plank: de BEN-notitie "WANNEER EEN ENGELS OEFENBOEK LANDT"
# draagt er een, ingesprongen. Hier wijst hij naar het ontbrekende boek, zodat
# een wachter die commentaar leest de spiegel ten onrechte kloppend noemt.
python3 - "$T16/en_goed.qmd" "$EN16" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
s = re.sub(r"\n::: \{[^}]*\}\n### \[Oefenboek Psychometrie[^\n]*\n:::\n", "\n", s)
s += ("\n<!-- BEN: zo ziet hij eruit als hij terugkomt:\n"
      "         ::: {.cc-boek .cc-boek-vak}\n"
      "         ### [Psychometrie (in Dutch) →](../../oefenboeken/psychometrie/index.html)\n"
      "         ::: -->\n")
open(sys.argv[2], "w", encoding="utf-8").write(s)
PY
SPIEGEL_LATEN=1 zaak "16f een kaart in een commentaar telt niet als kaart" 1 \
     "linkt naar oefenboeken/psychometrie/index.html" "$T16"

# 16g en 16h: de thuiskaarten
cp "$T16/en_goed.qmd" "$EN16"
spiegel_schrijven "$T16"
python3 - "$T16/index.qmd" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
s = re.sub(r",? ?\[Oefenboek OZP 1\]\([^)]*\)", "", s)
open(sys.argv[1], "w", encoding="utf-8").write(s)
PY
SPIEGEL_LATEN=1 zaak "16g een vak dat de thuiskaart niet noemt, vuurt" 1 \
     "op index.qmd linkt niet naar oefenboeken/ozp1/index.html" "$T16"
spiegel_schrijven "$T16"; rm "$T16/en/index.qmd"
SPIEGEL_LATEN=1 zaak "16h geen Engelse thuispagina heet blind, niet goed" 3 "en/index.qmd bestaat niet" "$T16"

# 16i: geen Engelse plank heet blind, niet goed
spiegel_schrijven "$T16"; rm "$EN16"
SPIEGEL_LATEN=1 zaak "16i geen Engelse plank heet blind, niet goed" 3 \
     "en/workbooks/index.qmd (regel 1): bestaat niet" "$T16"

# ---- zaak 17 t/m 17f: het taalmerk (21-11-2026) ---------------------------
# Ben, 21-11-2026: "Ja, taalmerk erop". Het EN- of NL-merk vóór een titel staat
# niet in de tekst; styles.css maakt het uit het hreflang van de link. Zonder
# hreflang verdwijnt het merk zonder één foutmelding, met een verkeerd hreflang
# liegt het. De kloppende spiegel van spiegel_schrijven heeft twee boeken op de
# Engelse plank en twee vakken op de Engelse thuiskaart, allemaal Nederlands.
spiegel_schrijven "$T16"
SPIEGEL_LATEN=1 zaak "17  een kloppend taalmerk blijft stil, en zegt hoeveel hij nakeek" 0 \
     "taalmerk nagelopen: 2 titel(s) op en/workbooks/index.qmd, 2 op en/index.qmd" "$T16"
cp "$EN16" "$T16/en_goed.qmd"; cp "$T16/en/index.qmd" "$T16/thuis_goed.qmd"

# 17b: een kaart op de plank zonder hreflang -- het merk is dan stil weg
python3 - "$EN16" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
s = s.replace('{hreflang="nl"}', "", 1)
open(p, "w", encoding="utf-8").write(s)
PY
SPIEGEL_LATEN=1 zaak "17b een plankkaart zonder hreflang vuurt" 1 "heeft geen hreflang, dus geen taalmerk" "$T16"

# 17c: hreflang="en" op een link naar een Nederlandse bladzij -- het merk liegt
cp "$T16/en_goed.qmd" "$EN16"
python3 - "$EN16" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
s = s.replace('{hreflang="nl"}', '{hreflang="en"}', 1)
open(p, "w", encoding="utf-8").write(s)
PY
SPIEGEL_LATEN=1 zaak "17c een hreflang dat niet bij de bestemming past, vuurt" 1 "het taalmerk zou dan liegen" "$T16"

# 17d: een Nederlands boek zonder "(in Dutch)" in de titel
cp "$T16/en_goed.qmd" "$EN16"
python3 - "$EN16" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
s = s.replace(" (in Dutch)", "", 1)
open(p, "w", encoding="utf-8").write(s)
PY
SPIEGEL_LATEN=1 zaak "17d een Nederlands boek zonder (in Dutch) vuurt" 1 'de titel zegt geen "(in Dutch)"' "$T16"

# 17e: een vak op de Engelse thuiskaart zonder hreflang (de MIEKE-noot van 14-11)
cp "$T16/en_goed.qmd" "$EN16"
python3 - "$T16/en/index.qmd" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
s = s.replace('{hreflang="nl"}', "", 1)
open(p, "w", encoding="utf-8").write(s)
PY
SPIEGEL_LATEN=1 zaak "17e een vak op de Engelse thuiskaart zonder hreflang vuurt" 1 \
     "en/index.qmd: [Oefenboek Psychometrie (in Dutch)]" "$T16"

# 17f: de kop "Practice books" en een link naar de plank zelf zijn geen boek, en
# hoeven dus geen merk -- de thuiskaart van spiegel_schrijven heeft zo'n kop al,
# hier komt er een link met een anker bij.
cp "$T16/thuis_goed.qmd" "$T16/en/index.qmd"
python3 - "$T16/en/index.qmd" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
s = s.replace(".\n:::\n", ". Some are [on their way in English](workbooks/index.qmd#on-its-way).\n:::\n", 1)
open(p, "w", encoding="utf-8").write(s)
PY
printf '\n## On its way in English {#on-its-way}\n' >> "$EN16"
SPIEGEL_LATEN=1 zaak "17f een link naar de plank zelf hoeft geen merk" 0 \
     "taalmerk nagelopen: 2 titel(s) op en/workbooks/index.qmd, 2 op en/index.qmd; 1 anker(s)" "$T16"

# 17g: dezelfde link, maar de kop met dat id is weg (hernoemd of geschrapt). De
# linkcontrole van en_bouw.py laat alles na "#" vallen; zonder deze zaak ziet
# niemand dat de laatste zin van de thuiskaart nergens meer heen wijst.
cp "$T16/en_goed.qmd" "$EN16"
SPIEGEL_LATEN=1 zaak "17g een anker naar een kop die er niet (meer) is, vuurt" 1 \
     "wijst naar #on-its-way op en/workbooks/index.qmd, maar daar staat geen kop" "$T16"
rm -rf "$T16"

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
# Sinds 21-11-2026 een VIERDE: de taalstukkenwachter. Zelfde reden; zijn eigen
# zaken staan in naar_buiten_teller_test.sh (zaak 6).
printf 'print("  losse bladzijden: 0 nagelopen, 0 gat(en) - nagemaakt")\n' > "$T7/_tools/taalonderdelen.py"
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
# De spiegel (14-11-2026) hoort er gecommit bij: --productie stopt bij
# ongecommit werk, en zonder spiegel staat de wachter blind.
spiegel_schrijven "$T7"
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
