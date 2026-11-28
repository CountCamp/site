#!/usr/bin/env bash
# ============================================================
# boek_inhoud_en_test.sh — rekent het Engelse boekoverzicht echt uit wat er is?
#
#   bash _tools/tests/boek_inhoud_en_test.sh
#
# WAAROM (28-11-2026, spoor boek_overzicht_en). en/book/index.qmd toont alle
# hoofdstukken van het boek, de nog niet vertaalde grijs. Welke Engels zijn, rekent
# _tools/boek_inhoud_en.lua bij elke bouw uit (zie de kop daarvan). Deze toets
# bewijst dat dat ook gebeurt: dat een nieuw Engels hoofdstuk vanzelf een link
# wordt, en dat elke manier waarop het overzicht zou kunnen liegen hardop gaat.
#
# HOE. Een klein Quarto-project onder _site_en_werk/ (gitignored): drie Nederlandse
# hoofdstukken in manuscript/, één Engels in en/book/, een index.qmd met de tabel,
# en het echte filter uit _tools/. Per geval één render.
#
#   GOED (afloop 0, en de bladzij zegt het)
#   1  h0 Engels: rij 0 een link met de Engelse titel; rij 1 en 2 grijs, met de
#      Nederlandse titel, de Engelse regel uit de tabel en een link naar het
#      Nederlands; de bewegingen in het Engels; de MELD-regel telt 3/1/2
#   2  h1 komt erbij: rij 1 wordt een link, zonder dat er iets anders verandert,
#      en de bouw meldt de tabelrij H1 als overbodig (BIJ TE WERKEN)
#   3  de Nederlandse onderwerpregel van h2 verandert: de rij blijft, BIJ TE WERKEN
#   4  gekrulde en rechte apostrof, en opmaak (<em>), tellen niet als verschil
#   BIJTPROEF (de bouw moet stoppen, en zeggen waarom)
#   5  een Nederlands hoofdstuk zonder Engelse bladzij en zonder tabelrij
#   6  een beweging zonder Engels hoofdstuk en zonder tabelrij
#   7  een Engels hoofdstuk zonder Nederlandse tweeling
#   8  een Engelse kop met een ander getal dan de bestandsnaam
#   9  twee Engelse hoofdstukken die hun beweging anders noemen
#   10 een bladzij zonder kicker
#   11 het blok #boek-inhoud-en ontbreekt
#
# Afloop: 0 alles goed, 1 minstens één fout, 3 kon niet kijken.
# ============================================================
set -uo pipefail
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH";; esac
export PATH LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
P="$REPO/_site_en_werk/boek_inhoud_proef${BOEK_INHOUD_PROEF_ACHTER:-}"
# Het filter dat getoetst wordt. Standaard het echte; de mutatieproef
# (boek_inhoud_en_mutatieproef.sh) geeft hier een verknoeide kopie.
FILTER="${BOEK_INHOUD_LUA:-$REPO/_tools/boek_inhoud_en.lua}"
command -v quarto >/dev/null || { echo "KON NIET KIJKEN: quarto staat niet op het pad"; exit 3; }
[ -f "$FILTER" ] || { echo "KON NIET KIJKEN: $FILTER ontbreekt"; exit 3; }

FOUT=0; N=0
uitslag() {  # $1 = 0 goed / anders fout, $2 = wat
  N=$((N + 1))
  if [ "$1" -eq 0 ]; then echo "ok    $2"; else echo "FOUT  $2"; FOUT=$((FOUT + 1)); fi
}
opruimen() { rm -rf "$P"; }
trap opruimen EXIT

hoofdstuk() {  # $1 = pad, $2 = kicker, $3 = kop, $4 = onderwerpregel (leeg = geen)
  mkdir -p "$(dirname "$P/$1")"
  {
    echo '<html><body><main class="content" id="quarto-document-content">'
    [ -n "$2" ] && echo "<div class=\"kicker\">$2</div>"
    echo '<header id="title-block-header"><div class="quarto-title">'
    echo "<h1 class=\"title\">$3</h1>"
    [ -n "${4:-}" ] && echo "<p class=\"subtitle lead\">$4</p>"
    echo '</div></header><p>tekst</p></main></body></html>'
  } > "$P/$1"
}

TABEL='| | Nederlands | English |
|---|---|---|
| H1 | Gemiddelde en spreiding | Mean and spread |
| H2 | Kansen, odds en odds ratio’s | Probabilities, odds and odds ratios |
| beweging | Tweede beweging · Koppelen | Second movement · Coupling |'

index() {  # $1 = tabel (leeg = zonder blok)
  mkdir -p "$P/en/book"
  {
    printf -- '---\ntitle: proef\nfilters:\n  - ../../_tools/boek_inhoud_en.lua\n---\n\n'
    if [ -n "$1" ]; then
      printf '::: {#boek-inhoud-en later="Coming soon" in-nl="in Dutch"}\n\n%s\n\n:::\n' "$1"
    else
      printf 'geen blok\n'
    fi
  } > "$P/en/book/index.qmd"
}

basis() {
  rm -rf "$P"; mkdir -p "$P/_tools"
  cp "$FILTER" "$P/_tools/boek_inhoud_en.lua"
  printf 'project:\n  type: default\n  render:\n    - en/book/index.qmd\n' > "$P/_quarto.yml"
  hoofdstuk manuscript/h0.html "Eerste beweging · Loep" "Hoofdstuk 0 — Nul" ""
  hoofdstuk manuscript/h1.html "Eerste beweging · Loep" "Hoofdstuk 1 — Een" "Gemiddelde en <em>spreiding</em>"
  hoofdstuk manuscript/h2.html "Tweede beweging · Koppelen" "Hoofdstuk 2 — Twee" "Kansen, odds en odds ratio&#x27;s"
  # een bladzij die geen hoofdstuk is, mag niet meetellen
  hoofdstuk manuscript/h3_grabbel.html "" "Grabbel" ""
  hoofdstuk en/book/h0.html "First movement · Loupe" "Chapter 0 — Zero" ""
  index "$TABEL"
}

UIT="$P/en/book/index.html"
bouw() {  # zet $AFLOOP en $LOG
  LOG="$(cd "$P" && quarto render en/book/index.qmd 2>&1)"; AFLOOP=$?
}
heeft() { [ -f "$UIT" ] && grep -qF -- "$1" "$UIT"; }
zegt() { printf '%s' "$LOG" | sed 's/\x1b\[[0-9;]*m//g' | grep -qF -- "$1"; }

# ------------------------------------------------------------------ 1 ----
basis; bouw
uitslag "$AFLOOP" "1 de basis bouwt (afloop $AFLOOP)"
[ "$AFLOOP" -eq 0 ] || printf '%s\n' "$LOG" | tail -8 | sed 's/^/      /'
uitslag "$(heeft '<a class="cc-toc-kop" href="h0.html"><span class="cc-toc-num">0</span><span class="cc-toc-titel">Zero</span></a>' && echo 0 || echo 1)" \
  "1 rij 0 is een link naar h0.html met de Engelse titel, zonder onderwerpregel"
uitslag "$(heeft 'href="../../manuscript/h1.html" hreflang="nl"><span class="cc-toc-num">1</span><span class="cc-toc-titel" lang="nl">Een</span><span class="cc-toc-sub">Mean and spread</span><span class="cc-toc-later-regel">Coming soon · <span class="cc-toc-nl">in Dutch</span></span>' && echo 0 || echo 1)" \
  "1 rij 1 is grijs: Nederlandse titel, Engelse regel uit de tabel, link naar het Nederlands"
uitslag "$(heeft '<p class="cc-bew">First movement · Loupe</p>' && heeft '<p class="cc-bew">Second movement · Coupling</p>' && echo 0 || echo 1)" \
  "1 de bewegingen in het Engels: uit h0 (de eerste), uit de tabel (de tweede)"
uitslag "$(heeft 'h3_grabbel' && echo 1 || echo 0)" "1 h3_grabbel.html telt niet als hoofdstuk"
uitslag "$(zegt 'MELD: inhoud en/book/index: 3 hoofdstukken uit manuscript/, 1 in het Engels (0), 2 grijs met een link naar het Nederlands (1, 2), 2 bewegingen' && echo 0 || echo 1)" \
  "1 de MELD-regel zegt wat hij zag (3 / 1 / 2)"
uitslag "$(zegt 'BIJ TE WERKEN' && echo 1 || echo 0)" "4 geen BIJ TE WERKEN: ’ tegen &#x27; is geen verschil"

# ------------------------------------------------------------------ 2 ----
basis; hoofdstuk en/book/h1.html "First movement · Loupe" "Chapter 1 — One" "Mean and spread, in English"; bouw
uitslag "$AFLOOP" "2 met h1 erbij bouwt het (afloop $AFLOOP)"
uitslag "$(heeft '<a class="cc-toc-kop" href="h1.html"><span class="cc-toc-num">1</span><span class="cc-toc-titel">One</span><span class="cc-toc-sub">Mean and spread, in English</span></a>' && echo 0 || echo 1)" \
  "2 rij 1 is nu een link, met titel en onderwerpregel uit h1.html zelf (niet uit de tabel)"
uitslag "$(heeft 'manuscript/h1.html' && echo 1 || echo 0)" "2 rij 1 wijst niet meer naar het Nederlands"
uitslag "$(zegt 'BIJ TE WERKEN: en/book/index.qmd, rij H1 in de tabel is overbodig' && echo 0 || echo 1)" \
  "2 de bouw meldt de tabelrij H1 als overbodig"

# ------------------------------------------------------------------ 3 ----
basis; hoofdstuk manuscript/h2.html "Tweede beweging · Koppelen" "Hoofdstuk 2 — Twee" "Iets heel anders"; bouw
uitslag "$AFLOOP" "3 een veranderde Nederlandse regel houdt de bouw niet tegen (afloop $AFLOOP)"
uitslag "$(zegt 'BIJ TE WERKEN: en/book/index.qmd, rij H2 is vertaald van' && zegt 'Iets heel anders' && echo 0 || echo 1)" \
  "3 ... maar meldt hem, met de nieuwe Nederlandse regel"
uitslag "$(heeft 'Probabilities, odds and odds ratios' && echo 0 || echo 1)" "3 de rij blijft staan, met de vertaling van gisteren"

# --------------------------------------------------------- bijtproeven ----
# Een stop is: afloop niet 0, de reden in de uitvoer, en GEEN bladzij. Dat laatste is
# geen versiering: met error() in het filter gaf Quarto 1.9.38 bij vier van deze zeven
# gevallen afloop 0 en maakte hij de bladzij toch (zie fout() in het filter).
moet_stoppen() {  # $1 = nr en wat, $2 = tekst die de fout moet noemen
  bouw
  if [ "$AFLOOP" -ne 0 ] && zegt "ERROR: boek_inhoud_en.lua: " && zegt "$2" && [ ! -f "$UIT" ]; then
    uitslag 0 "$1"
  else
    uitslag 1 "$1 — verwacht een stop met \"$2\" en geen bladzij, kreeg afloop $AFLOOP$([ -f "$UIT" ] && echo ', en de bladzij staat er')"
    printf '%s\n' "$LOG" | sed 's/\x1b\[[0-9;]*m//g' | grep -i 'boek_inhoud\|error' | head -3 | sed 's/^/      /'
  fi
}
basis; hoofdstuk manuscript/h3.html "Tweede beweging · Koppelen" "Hoofdstuk 3 — Drie" "Nieuw"
moet_stoppen "5 een Nederlands hoofdstuk zonder Engelse bladzij en zonder tabelrij stopt de bouw" "heeft geen rij H3"
basis; hoofdstuk manuscript/h3.html "Derde beweging · Proef" "Hoofdstuk 3 — Drie" "Nieuw"
index "$TABEL
| H3 | Nieuw | New |"
moet_stoppen "6 een beweging zonder Engels hoofdstuk en zonder tabelrij stopt de bouw" "Derde beweging · Proef\" heeft geen Engels hoofdstuk"
basis; hoofdstuk en/book/h5.html "First movement · Loupe" "Chapter 5 — Five" ""
moet_stoppen "7 een Engels hoofdstuk zonder Nederlandse tweeling stopt de bouw" "en/book/h5.html heeft geen Nederlandse tweeling"
basis; hoofdstuk en/book/h1.html "First movement · Loupe" "Chapter 7 — Seven" ""
moet_stoppen "8 een kop met een ander getal dan de bestandsnaam stopt de bouw" "de kop zegt hoofdstuk 7, de bestandsnaam 1"
basis; hoofdstuk en/book/h1.html "First movement · Magnifier" "Chapter 1 — One" ""
moet_stoppen "9 twee namen voor één beweging stoppen de bouw" "noemt zijn beweging"
basis; hoofdstuk en/book/h1.html "" "Chapter 1 — One" ""
moet_stoppen "10 een bladzij zonder kicker stopt de bouw" 'en/book/h1.html: geen <div class="kicker">'
basis; index ""
moet_stoppen "11 zonder het blok #boek-inhoud-en stopt de bouw" "staat 0 keer op de bladzij"

echo
echo "$((N - FOUT)) ok, $FOUT fout, van $N"
[ "$FOUT" -eq 0 ] && exit 0 || exit 1
