#!/usr/bin/env bash
# ============================================================
# naar_buiten_teller_test.sh — bijt de tellerpoort in de pers echt?
#
#   bash _tools/tests/naar_buiten_teller_test.sh
#
# `naar_buiten.sh --productie` draait twee poorten blokkerend: de plankwacht en
# de tellerwachter. Die weg is niet te proeven -- hij eist dat je op main staat
# en duwt daarna naar GitHub. Daarom bestaat `--nakijken`: dezelfde twee poorten,
# even streng, en daarna niets. Dat is wat deze toets aanroept.
#
# De nagemaakte repo's hieronder bestaan uit niets meer dan `_tools/` met een
# kopie van `naar_buiten.sh` en twee nagemaakte wachters. Dat werkt omdat
# `naar_buiten.sh` zijn reporoot uit zijn EIGEN plek afleidt (de map boven
# `_tools/`). Zo kan de toets rood maken zonder deze repo aan te raken -- een
# toets die de repo moet beschadigen om te kunnen meten, is een toets die
# niemand draait.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
gezakt=0
getoetst=0

# De plankwacht staat in deze repo los van de teller ROOD: het OZP 1-kaartje
# noemt 27 september terwijl de map op 28 september veranderde (commit 5cd1e5b).
# Dat stond er al vóór dit spoor. Deze toets moet de TELLERPOORT meten, dus
# krijgt elke nagemaakte repo een plankwacht die groen staat -- anders zou de
# toets rood blijven om een reden die niets met de teller te maken heeft, en dan
# meet hij niets.
nep_basis() {  # $1 = naam -> maakt de repo, geeft het pad terug
  local r="$M/$1"
  mkdir -p "$r/_tools"
  cp _tools/naar_buiten.sh "$r/_tools/"
  printf 'print("plankwacht - nagemaakt, alles in orde")\n' > "$r/_tools/plankwacht.py"
  echo "$r"
}

nep_repo() {  # $1 = naam, $2 = afloopcode van de nagemaakte tellerwachter, $3.. = wat hij zegt
  local naam="$1" code="$2"; shift 2
  local r; r="$(nep_basis "$naam")"
  { for regel in "$@"; do printf 'print(%s)\n' "\"$regel\""; done
    printf 'import sys; sys.exit(%s)\n' "$code"
  } > "$r/_tools/controleer_tellers.py"
  echo "$r"
}

echte_teller_repo() {  # de ECHTE tellerwachter op de ECHTE bladzijden van deze repo
  local r; r="$(nep_basis echterepo)"
  cp _tools/controleer_tellers.py _tools/tellerregel.py "$r/_tools/"
  # Wegwijzers naar het echte werk. Dat mag hier: `controleer_tellers.py`
  # gebruikt os.walk, en die volgt een gesymlinkt startpunt wel -- anders dan
  # `grep -r` en `find` zonder -L.
  ln -s "$PWD/oefenboeken" "$r/oefenboeken"
  ln -s "$PWD/werkboeken"  "$r/werkboeken"
  echo "$r"
}

keur() {  # $1 = naam, $2 = verwachte afloopcode, $3 = reporoot
  getoetst=$((getoetst + 1))
  bash "$3/_tools/naar_buiten.sh" --nakijken > "$M/uit" 2>&1
  local echt=$?
  if [ "$echt" = "$2" ]; then
    echo "  ok    $1 (afloopcode $echt)"
  else
    echo "  ZAKT  $1 — verwacht $2, kreeg $echt"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

verwacht() {  # $1 = naam, $2 = tekst die in de uitvoer moet staan
  getoetst=$((getoetst + 1))
  if grep -qF -e "$2" "$M/uit"; then
    echo "  ok    $1"
  else
    echo "  ZAKT  $1 — '$2' staat niet in de uitvoer"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

echo "naar_buiten_teller_test — bijt de tellerpoort in naar_buiten.sh?"
echo ""

# --- 1. de echte bladzijden van deze repo: laat door ------------------------
ECHT="$(echte_teller_repo)"
keur     "de echte bladzijden van deze repo: laat door" 0 "$ECHT"
verwacht "  en de tellerwachter meldt hoeveel hij zag" \
         "Alle 161 bladzijden dragen de teller."
verwacht "  en de uitslag staat er in gewone taal" \
         "Alle poorten staan groen. --productie zou hierop niet struikelen."

# --- 2. een blinde bladzij houdt de levering tegen --------------------------
ROOD="$(nep_repo roodrepo 1 \
  "teller-controle - nagemaakte wachter" \
  "ZONDER TELLER (1 van de 1 bladzijden):" \
  "    - oefenboeken/nep/blind.html")"
keur     "een blinde bladzij: HOUDT TEGEN" 1 "$ROOD"
verwacht "  en zegt wat er aan de hand is" \
         "Er gaan bladzijden de deur uit die niemand kan tellen."
verwacht "  en hoe je het repareert" "controleer_tellers.py --repareer"
verwacht "  en noemt de bladzij bij naam" "oefenboeken/nep/blind.html"
verwacht "  en zegt dat productie hier zou stoppen" \
         "poort staat rood. --productie zou hier stoppen."

# --- 3. een wachter die niet eens kon kijken mag niet als groen gelden ------
#     Stilte betekent ongeldig, nooit goed. Afloopcode 3 is "kon niet kijken";
#     als de poort alleen op 1 zou letten, glipt een blinde wachter erdoor.
BLIND="$(nep_repo blindrepo 3 \
  "NIETS GEMETEN - geen enkele .html gevonden onder oefenboeken, werkboeken")"
keur     "een wachter die niets kon meten: HOUDT TEGEN" 1 "$BLIND"
verwacht "  en laat de blindheid zien" "NIETS GEMETEN"
verwacht "  en noemt dat als blindheid, niet als missende teller" \
         "stilte betekent ongeldig, nooit goed"

# --- 4. een wachter die er niet is, mag niet de schuld op de bladzijden leggen
#     Dit is de fout die deze poort bij het schrijven zelf maakte: de wachter
#     stond niet in de proefrepo van plankwacht_test.sh, python kon het bestand
#     niet openen (afloopcode 2), en de poort meldde "er gaan bladzijden de deur
#     uit die niemand kan tellen". Er was niets met de bladzijden. Een verkeerde
#     reden is erger dan geen, want daar handelt iemand naar.
WEG_REPO="$(nep_basis wegrepo)"
# geen controleer_tellers.py neerzetten -> python3 stopt met afloopcode 2
keur     "een wachter die ontbreekt: HOUDT TEGEN" 1 "$WEG_REPO"
verwacht "  en zegt dat het ONGEMETEN is"      "is dus ONGEMETEN"
verwacht "  en wijst naar het ontbrekende script" "controleer_tellers.py er, en draait hij los"
getoetst=$((getoetst + 1))
if grep -qF "Er gaan bladzijden de deur uit" "$M/uit"; then
  echo "  ZAKT    en legt de schuld tóch bij de bladzijden"
  gezakt=$((gezakt + 1))
else
  echo "  ok      en legt de schuld NIET bij de bladzijden"
fi

echo ""
if [ "$gezakt" = "0" ]; then
  echo "$getoetst zaken getoetst, alles groen."
  exit 0
fi
echo "$getoetst zaken getoetst, $gezakt GEZAKT."
exit 1
