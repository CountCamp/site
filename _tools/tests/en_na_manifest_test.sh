#!/usr/bin/env bash
# ============================================================
# en_na_manifest_test.sh — ziet stap 0 van publiceer_en.sh dat een Engelse
# bron veranderde NA de bouw die het manifest beschrijft?
#
# Aanleiding, 14-11-2026: de pers van die dag (bd2ff08) veranderde
# en/index.qmd en bouwde en/index.html niet opnieuw. Live stond een dag lang een
# zin die de bron al kwijt was, en `publiceer_en.sh --nakijken` zei "in orde".
# Het manifest noemde bron_commit=0c3a896; de .qmd veranderde daarna. Zaak 2
# hieronder is dat geval.
#
# Elke zaak bouwt een ECHTE kleine git-repo met de echte en_bouw.py erin, want
# de wachter leunt op git (een commit die niet bestaat, een ondiepe kloon) en die
# val kun je niet namaken. De laatste zaken maken de wachter kreupel en eisen
# dat de toets dat merkt: een toets die alleen groen kan worden, meet niets.
#
#   bash _tools/tests/en_na_manifest_test.sh
#
# Afloop: 0 alle zaken goed, 1 er zakt er een.
# ============================================================
set -uo pipefail
BRON="$(cd "$(dirname "$0")/../.." && pwd)"
GOED=0
ZAKT=0
OPRUIMEN=()
trap 'rm -rf ${OPRUIMEN[@]+"${OPRUIMEN[@]}"}' EXIT

op() {   # $1 = map, $2 = boodschap
  git -C "$1" add -A
  git -C "$1" commit -qm "$2"
}

# Een repo met één Nederlandse bladzij (a.qmd), zijn Engelse tweeling
# (en/a.qmd, gestempeld), het Engelse profiel, en een manifest dat de bouw van
# precies die stand beschrijft. Zet $H_BOUW op de commit van die bouw.
klaarzetten() {   # $1 = map, $2 = en_bouw.py die getoetst wordt
  local T="$1"
  mkdir -p "$T/_tools" "$T/en"
  cp "$2" "$T/_tools/en_bouw.py"
  cp "$BRON/_tools/taalonderdelen.py" "$BRON/_tools/tellerregel.py" "$T/_tools/"
  printf -- '---\ntitle: "A"\n---\n\nEen bladzij.\n' > "$T/a.qmd"
  printf 'website:\n  navbar:\n    left:\n      - text: Practice books\n' > "$T/_quarto-en.yml"
  git -C "$T" init -q
  git -C "$T" config user.email toets@countcamp.org
  git -C "$T" config user.name  en-na-manifest-toets
  op "$T" "het Nederlands"
  local H_NL; H_NL="$(git -C "$T" log -1 --format=%h)"
  printf -- '---\ntitle: "A"\nnl_bron: a.qmd@%s\n---\n\nA page.\n' "$H_NL" > "$T/en/a.qmd"
  op "$T" "de Engelse bron"
  H_BOUW="$(git -C "$T" log -1 --format=%h)"
  printf '# MANIFEST status=OK afloop=0 bladzijden=1 libs=0 machine=toets bron=toets wanneer=nu\n# bron_commit=%s bron_schoon=ja\n' \
    "$H_BOUW" > "$T/_tools/en_manifest.txt"
  op "$T" "de gebouwde en/ en het manifest"
}

zaak() {   # $1 = naam, $2 = map, $3 = tekst die erin moet staan, $4 = tekst die er NIET in mag ("" = geen)
  local naam="$1" T="$2" moet="$3" niet="${4:-}"
  local uit code oordeel=goed
  uit="$(python3 "$T/_tools/en_bouw.py" bronnen 2>&1)"; code=$?
  # Een waarschuwing, geen weigering: de afloop blijft 0.
  [ "$code" = 0 ] || oordeel=fout
  printf '%s' "$uit" | grep -qF -- "$moet" || oordeel=fout
  if [ -n "$niet" ] && printf '%s' "$uit" | grep -qF -- "$niet"; then oordeel=fout; fi
  if [ "$oordeel" = goed ]; then
    GOED=$((GOED + 1)); printf '  ok      %s\n' "$naam"
  else
    ZAKT=$((ZAKT + 1))
    printf '  ZAKT    %s -- wilde afloop 0, de tekst %s%s\n' "$naam" "$moet" "${niet:+ en NIET $niet}"
    printf '%s\n' "$uit" | sed 's/^/            /'
  fi
}

# Zet T (en H_BOUW) in de shell van de aanroeper -- niet in een $(...), want dan
# gaan die twee verloren met de subshell.
nieuw() { T="$(mktemp -d)"; OPRUIMEN+=("$T"); klaarzetten "$T" "${1:-$BRON/_tools/en_bouw.py}"; }

echo "en_na_manifest_test — zaken:"

# ---- 1: niets veranderd sinds de bouw -> stil, maar wel gezegd hoeveel ---
nieuw
zaak "1  niets veranderd: geen waarschuwing, wel de telling" "$T" \
     "1 Engelse bron(nen) en _quarto-en.yml vergeleken met bron_commit=" "ACHTER OP ZIJN BRON"

# ---- 2: het geval van 14-11 -- de bron gecommit na de bouw ---------------
printf '\nA sentence that the HTML does not have yet.\n' >> "$T/en/a.qmd"
op "$T" "en/a.qmd bijgewerkt, en/a.html niet opnieuw gebouwd"
H2="$(git -C "$T" log -1 --format=%h)"
zaak "2  bron gecommit na het manifest (bd2ff08, 14-11)" "$T" \
     "ACHTER OP ZIJN BRON: en/a.html: gebouwd van en/a.qmd@"
zaak "2b en hij noemt de commit die het deed" "$T" "1 keer gecommit na $H_BOUW, laatst: $H2"

# ---- 3: ongecommit veranderd ----------------------------------------------
nieuw
printf '\nNog niet gecommit.\n' >> "$T/en/a.qmd"
zaak "3  ongecommit veranderd telt ook" "$T" "ongecommit veranderd sinds $H_BOUW"

# ---- 4: een nieuwe Engelse bron, nog nooit gebouwd -------------------------
nieuw
cp "$T/en/a.qmd" "$T/en/b.qmd"
zaak "4  een nieuwe bron is nooit gekeurd gebouwd" "$T" "en/b.html: en/b.qmd is nieuw sinds het manifest"

# ---- 5: het menu veranderd ---------------------------------------------------
nieuw
printf '      - text: Toys\n' >> "$T/_quarto-en.yml"
op "$T" "menu erbij"
zaak "5  het Engelse profiel veranderd: elke bladzij loopt achter" "$T" \
     "ACHTER OP ZIJN BRON: elke Quarto-bladzij onder en/ (menu en voet)"

# ---- 6 en 7: kon niet kijken is geen 'niets veranderd' ----------------------
nieuw
rm "$T/_tools/en_manifest.txt"
zaak "6  geen manifest heet: kon niet kijken" "$T" "na het manifest: KON NIET KIJKEN" "0 veranderd"
nieuw
printf '# MANIFEST status=OK afloop=0\n# bron_commit=0000000 bron_schoon=ja\n' > "$T/_tools/en_manifest.txt"
zaak "7  een bron_commit die niet bestaat heet: kon niet kijken" "$T" \
     "bron_commit 0000000 bestaat niet in deze repo" "0 veranderd"

# ---- 8: een vuile bouw zegt dat de vergelijking wankelt --------------------
nieuw
sed -i.bak 's/bron_schoon=ja/bron_schoon=nee/' "$T/_tools/en_manifest.txt" && rm -f "$T/_tools/en_manifest.txt.bak"
zaak "8  bron_schoon=nee wordt hardop gezegd" "$T" "het manifest zegt bron_schoon=nee"

# ---- 9: de bedrading -- stap 0 draait vóór de keuze voor --nakijken ---------
# publiceer_en.sh zelf draaien kost drie quarto-bouwen; dit meet alleen dat
# `bronnen` (en dus deze wachter) vóór de nakijk-tak staat en daardoor in elke
# gang draait. Het echte bewijs staat in het verslag van plank_vakken: de regel
# "na het manifest" in de uitvoer van --nakijken.
r_bron="$(grep -n '^\$PY bronnen' "$BRON/_tools/publiceer_en.sh" | head -1 | cut -d: -f1)"
r_nak="$(grep -n '^if \[ "\$WEG" = nakijken \]' "$BRON/_tools/publiceer_en.sh" | head -1 | cut -d: -f1)"
if [ -n "$r_bron" ] && [ -n "$r_nak" ] && [ "$r_bron" -lt "$r_nak" ] \
   && grep -q '^    na_manifest()' "$BRON/_tools/en_bouw.py"; then
  GOED=$((GOED + 1)); echo "  ok      9  bronnen staat vóór de nakijk-tak (regel $r_bron < $r_nak) en roept na_manifest aan"
else
  ZAKT=$((ZAKT + 1)); echo "  ZAKT    9  bronnen staat niet vóór de nakijk-tak, of roept na_manifest niet aan (regels: '$r_bron' '$r_nak')"
fi

# ---- 10 t/m 12: de wachter kreupel -- dan moet de toets het merken ----------
kreupel() {   # $1 = naam, $2 = oud, $3 = nieuw, $4 = zaak-functie die rood moet worden
  local K; K="$(mktemp -d)"; OPRUIMEN+=("$K")
  python3 - "$BRON/_tools/en_bouw.py" "$K/en_bouw.py" "$2" "$3" <<'PY'
import sys
s = open(sys.argv[1], encoding="utf-8").read()
if sys.argv[3] not in s:
    sys.exit("mutatie niet gevonden")
open(sys.argv[2], "w", encoding="utf-8").write(s.replace(sys.argv[3], sys.argv[4], 1))
PY
  [ $? -eq 0 ] || { ZAKT=$((ZAKT + 1)); echo "  ZAKT    $1 -- de mutatie sloeg niet aan; geen uitslag"; return; }
  local voor=$ZAKT
  "$4" "$K/en_bouw.py" >/dev/null 2>&1
  if [ "$ZAKT" -gt "$voor" ]; then
    ZAKT=$voor; GOED=$((GOED + 1)); echo "  ok      $1 -- de toets wordt rood"
  else
    ZAKT=$((ZAKT + 1)); echo "  ZAKT    $1 -- de toets bleef groen bij een kreupele wachter"
  fi
}
geval_2() { local T; nieuw "$1"; printf '\nmeer\n' >> "$T/en/a.qmd"; op "$T" "na de bouw"
            zaak "kreupel: geval 2" "$T" "ACHTER OP ZIJN BRON: en/a.html"; }
geval_6() { local T; nieuw "$1"; rm "$T/_tools/en_manifest.txt"
            zaak "kreupel: geval 6" "$T" "KON NIET KIJKEN"; }
geval_5() { local T; nieuw "$1"; printf '      - text: X\n' >> "$T/_quarto-en.yml"; op "$T" "menu"
            zaak "kreupel: geval 5" "$T" "elke Quarto-bladzij onder en/"; }
kreupel "10 een veranderde bron telt als gelijk" \
  '        if r.returncode == 0:
            continue' \
  '        if True:
            continue' geval_2
kreupel "11 geen manifest telt als niets veranderd" \
  '    if not os.path.isfile(manifest):' '    if False:' geval_6
kreupel "12 het menu wordt niet meer vergeleken" \
  'NA_MANIFEST_OOK = ["_quarto-en.yml"]' 'NA_MANIFEST_OOK = []' geval_5

echo
echo "goed: $GOED   gezakt: $ZAKT"
[ "$ZAKT" -eq 0 ] || exit 1
