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
# Zaak 5 (sinds 14-11-2026) proeft de poort die pas NA de bouw draait
# (`gebouwde_tellers_nakijken`, de tellerwacht op _site/); die zit niet in
# --nakijken, dus daar haalt de toets de functie letterlijk uit het script.
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
# Welk naar_buiten.sh er geproefd wordt. Standaard het echte; de mutatieproef
# (naar_buiten_poort_mutatieproef.sh) geeft een verminkte kopie mee, zodat hij
# het echte bestand nooit hoeft aan te raken.
NAAR_BUITEN="${NAAR_BUITEN:-_tools/naar_buiten.sh}"
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
  cp "$NAAR_BUITEN" "$r/_tools/naar_buiten.sh"
  printf 'print("plankwacht - nagemaakt, alles in orde")\n' > "$r/_tools/plankwacht.py"
  # Sinds 1-10-2026 draait er een DERDE poort: de doorstuurwachter. Zelfde
  # reden als bij de plankwacht hierboven -- deze toets meet de tellerpoort, en
  # de doorstuurpoort heeft zijn eigen toets (doorstuurders_test.sh).
  printf 'print("doorstuurders - nagemaakt, alles in orde")\n' > "$r/_tools/doorstuurders.py"
  # Sinds 21-11-2026 een VIERDE: de taalstukkenwachter. Zelfde reden; zijn eigen
  # zaken staan onder 6.
  printf 'print("  losse bladzijden: 0 nagelopen, 0 gat(en) - nagemaakt")\n' > "$r/_tools/taalonderdelen.py"
  # Sinds 24-11-2026 een VIJFDE: de namenwacht. Zelfde reden; zijn eigen toets is
  # namenwacht_test.sh (die proeft hem ook via --nakijken).
  printf 'print("namenwacht - nagemaakt, alles in orde")\n' > "$r/_tools/namenwacht.py"
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
  # Sinds 25-10-2026 kijkt de wachter ook in en/ (spoor en_voorpagina).
  ln -s "$PWD/en"          "$r/en"
  # Sinds 14-11-2026 ook in de andere bijlagen (spoor site_wegen). Zonder deze
  # wegwijzers bleef de toets groen -- een map die er niet is houdt de levering
  # niet tegen -- maar dan proefde hij een kleinere poort dan de echte.
  local m
  for m in manuscript speeltjes tabellen tables power; do
    ln -s "$PWD/$m" "$r/$m"
  done
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
# HOEVEEL bladzijden er zijn, rekent deze toets zelf uit -- het stond hier tot
# 24-10-2026 met de hand als 161, en de repo had er toen al 163. Dan zakt de
# toets niet omdat de wachter iets mist, maar omdat er een bladzij bij kwam, en
# een toets die rood wordt van groei leer je negeren (spoor en_schil).
# Met `find` en niet met os.walk zoals de wachter zelf, zodat dit een tweede
# telling is en geen kopie van de eerste; wat een "bladzij" is (geen
# doorstuurder, geen fragment) komt uit tellerregel.py, de ene plek die dat weet.
# Dezelfde mappen als de wachter overslaat: _site, .quarto, .git, site_libs.
tel_bladzijden() {
  local mappen=() m
  for m in oefenboeken werkboeken en manuscript speeltjes tabellen tables power; do
    [ -d "$m" ] && mappen+=("$m/")
  done
  [ "${#mappen[@]}" -gt 0 ] || { echo 0; return; }
  find "${mappen[@]}" \( -name _site -o -name .quarto -o -name .git -o -name site_libs \) -prune \
       -o -name '*.html' -print0 \
    | python3 -c '
import sys
sys.path.insert(0, "_tools")
from tellerregel import soort
paden = [p for p in sys.stdin.buffer.read().decode("utf-8").split("\0") if p]
print(sum(soort(open(p, encoding="utf-8", errors="ignore").read()) == "bladzij" for p in paden))'
}
N_BLADZ="$(tel_bladzijden)"
ECHT="$(echte_teller_repo)"
keur     "de echte bladzijden van deze repo: laat door" 0 "$ECHT"
if [[ "${N_BLADZ:-}" =~ ^[1-9][0-9]*$ ]]; then
  verwacht "  en de tellerwachter meldt hoeveel hij zag ($N_BLADZ, met find nageteld)" \
           "Alle $N_BLADZ bladzijden dragen de teller."
else
  getoetst=$((getoetst + 1))
  echo "  ZAKT  kon het aantal bladzijden niet natellen (find gaf '${N_BLADZ:-}') -- niet gemeten is niet groen"
  gezakt=$((gezakt + 1))
fi
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

# --- 5. de poort op de GEBOUWDE site (ontworpen 9-10-2026, spoor teller; ----
#     op main sinds 14-11-2026, spoor teller2)
#     `gebouwde_tellers_nakijken` draait alleen na een bouw: blokkerend op
#     --productie, meldend op --lokaal. Geen van beide is hier te proeven -- de
#     een duwt main, de ander rendert de hele site. Daarom haalt deze toets de
#     functie LETTERLIJK uit naar_buiten.sh en voert hem een nagemaakte _site/
#     met de echte tellerwacht. Zaak 5g kijkt daarna of beide wegen hem ook
#     echt aanroepen; zonder die zaak bewijst de rest alleen dat de functie
#     bestaat.
POORT="$(sed -n '/^gebouwde_tellers_nakijken() {/,/^}/p' "$NAAR_BUITEN")"
getoetst=$((getoetst + 1))
if [ "$(printf '%s\n' "$POORT" | wc -l | tr -d ' ')" -gt 5 ]; then
  echo "  ok    5  de functie staat in naar_buiten.sh ($(printf '%s\n' "$POORT" | wc -l | tr -d ' ') regels)"
else
  # Zoeken is niet gevonden: een lege uitsnede zou alle zaken hieronder laten
  # zakken om de verkeerde reden, of erger, laten slagen.
  echo "  ZAKT  5  gebouwde_tellers_nakijken niet gevonden in naar_buiten.sh"
  gezakt=$((gezakt + 1))
fi

site_repo() {  # $1 = naam -> repo met de echte wachter en een _site/ met één goede bladzij
  local r="$M/$1"
  mkdir -p "$r/_tools" "$r/_site"
  cp _tools/tellerwacht.py _tools/tellerregel.py _tools/teller.html "$r/_tools/"
  { printf '<!DOCTYPE html>\n<html><head>\n<title>x</title>\n'
    cat _tools/teller.html
    printf '</head><body><p>x</p></body></html>\n'
  } > "$r/_site/index.html"
  echo "$r"
}

poort() {  # $1 = naam, $2 = verwachte afloopcode, $3 = reporoot, $4 = echt|spook, $5 = blokkerend|melden
  getoetst=$((getoetst + 1))
  ( HIER="$3"; eval "$POORT"; gebouwde_tellers_nakijken "$4" "$5" ) > "$M/uit" 2>&1
  local echt=$?
  if [ "$echt" = "$2" ]; then
    echo "  ok    $1 (afloopcode $echt)"
  else
    echo "  ZAKT  $1 — verwacht $2, kreeg $echt"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

GOED="$(site_repo goedesite)"
poort    "5a een gebouwde site met precies één teller: laat door" 0 "$GOED" echt blokkerend
verwacht "  en de wachter zegt hoeveel hij las" "alle 1 bladzijden dragen precies één teller"

KAAL="$(site_repo kalesite)"
printf '<!DOCTYPE html>\n<html><head><title>kaal</title></head><body></body></html>\n' \
  > "$KAAL/_site/kaal.html"
poort    "5b een gebouwde bladzij zonder teller: HOUDT TEGEN" 1 "$KAAL" echt blokkerend
verwacht "  en noemt de bladzij bij naam" "kaal.html  [geen teller]"
verwacht "  en zegt het in gewone taal" "telt niet precies één keer per bladzij"
poort    "5c dezelfde site op een proefweg (melden): laat door" 0 "$KAAL" echt melden
verwacht "  maar zegt het wel hardop" "op een proefweg houdt dit je niet tegen"
poort    "5d de echte bouw als proefdruk gekeurd: HOUDT TEGEN" 1 "$GOED" spook blokkerend
verwacht "  want de teller telt dan mee" "teller in een proefdruk"

LEEG="$(site_repo leegsite)"
rm -f "$LEEG/_site/index.html"
poort    "5e een lege _site/: HOUDT TEGEN, als blinde" 1 "$LEEG" echt blokkerend
verwacht "  en noemt dat blindheid" "stilte betekent ongeldig, nooit goed"

ZONDER="$(site_repo zonderwacht)"
rm -f "$ZONDER/_tools/tellerwacht.py"
poort    "5f geen tellerwacht: HOUDT TEGEN" 1 "$ZONDER" echt blokkerend
verwacht "  en zegt dat het ONGEMETEN is" "is dus ONGEMETEN"
getoetst=$((getoetst + 1))
if grep -qF "telt niet precies" "$M/uit"; then
  echo "  ZAKT    en legt de schuld tóch bij de bladzijden"
  gezakt=$((gezakt + 1))
else
  echo "  ok      en legt de schuld NIET bij de bladzijden"
fi

# Roepen --productie en --lokaal de poort ook aan, en op --productie NA de bouw?
# Een poort die bestaat maar nergens hangt, is precies de faalvorm van
# akkoord_hek.py, dat zes dagen nergens bedraad stond.
getoetst=$((getoetst + 1))
BEDRADING="$(python3 - "$NAAR_BUITEN" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
def tak(naam):
    m = re.search(r"^%s\)\n(.*?)^  ;;" % re.escape(naam), s, re.S | re.M)
    return m.group(1) if m else ""
prod, lok = tak("--productie"), tak("--lokaal")
fout = []
# De bouw is sinds 22-11-2026 (spoor pers_nacht) geen kale `quarto render` meer
# maar de schone bouw: een kopie zonder .claude/ (zie _tools/schone_bouw.py).
BOUW = "_tools/schone_bouw.py --uit _site -- render"
r = prod.find(BOUW)
p = prod.find("gebouwde_tellers_nakijken echt blokkerend")
if p < 0:
    fout.append("--productie roept de poort niet blokkerend aan")
elif r < 0 or p < r:
    fout.append("--productie roept de poort niet NA de bouw (%s) aan" % BOUW)
# Op DEZE regel, niet "binnen 120 tekens": sinds 23-11-2026 (spoor
# pers_commentaar) staat de commentaarpoort er direct onder, met zijn eigen
# "Niet geleverd", en dan bleef de mutatie "--productie stopt niet als de poort
# rood is" groen.
elif "Niet geleverd" not in prod[p:prod.find("\n", p)]:
    fout.append("--productie stopt niet als de poort rood is")
r = lok.find(BOUW)
p = lok.find("gebouwde_tellers_nakijken spook melden")
if p < 0 or r < 0 or p < r:
    fout.append("--lokaal roept de poort niet na de bouw aan (spook, melden)")
print("; ".join(fout) if fout else "ok")
PY
)"
if [ "$BEDRADING" = ok ]; then
  echo "  ok    5g --productie (blokkerend) en --lokaal (meldend) roepen hem na de bouw aan"
else
  echo "  ZAKT  5g bedrading: $BEDRADING"
  gezakt=$((gezakt + 1))
fi

# --- 6. de taalstukkenpoort (21-11-2026, spoor ts_pers_beide) ---------------
#     Een pers die een losse tweeling opnieuw neerzet, haalt knopje, hreflang en
#     taalbalk weg. Gemeten die dag: 9 kale Nederlandse TS-bladzijden, en
#     --nakijken zei "Alle poorten staan groen".
# nep_repo en niet nep_basis: die laatste heeft geen tellerwachter, en dan wordt
# de levering om de teller rood in plaats van om de taalstukken (zie zaak 4).
KAAL_TAAL="$(nep_repo kaaltaal 0 "teller-controle - nagemaakt, alles in orde")"
{ printf 'print("  oefenboeken/ts/index.html: in orde")\n'
  printf 'print("  losse bladzijden: 2 nagelopen, 1 gat(en)")\n'
  printf 'print("    - oefenboeken/ts/01_kapstok/01_kapstok.html: de taalstukken staan er niet (goed) in")\n'
  printf 'import sys; sys.exit(1)\n'
} > "$KAAL_TAAL/_tools/taalonderdelen.py"
keur     "6a een tweeling zonder taalstukken: HOUDT TEGEN" 1 "$KAAL_TAAL"
verwacht "  en noemt de bladzij bij naam" "oefenboeken/ts/01_kapstok/01_kapstok.html"
verwacht "  en hoe je het repareert" "python3 _tools/taalonderdelen.py los"
getoetst=$((getoetst + 1))
if grep -qF "oefenboeken/ts/index.html: in orde" "$M/uit"; then
  echo "  ZAKT    en laat de bladzijden die in orde zijn tóch allemaal zien"
  gezakt=$((gezakt + 1))
else
  echo "  ok      en laat alleen zien wat niet in orde is"
fi

ZONDER_TAAL="$(nep_repo zondertaal 0 "teller-controle - nagemaakt, alles in orde")"
rm -f "$ZONDER_TAAL/_tools/taalonderdelen.py"
keur     "6b geen taalonderdelen.py: HOUDT TEGEN" 1 "$ZONDER_TAAL"
verwacht "  en zegt dat het ONGEMETEN is" "is dus ONGEMETEN"
getoetst=$((getoetst + 1))
if grep -qF "mist zijn taalknopje" "$M/uit"; then
  echo "  ZAKT    en legt de schuld tóch bij de bladzijden"
  gezakt=$((gezakt + 1))
else
  echo "  ok      en legt de schuld NIET bij de bladzijden"
fi

# De echte wachter op de echte bladzijden van deze repo: groen, en hij heeft
# gekeken (een telling boven nul). Met wegwijzers, zoals echte_teller_repo.
ECHT_TAAL="$(nep_repo echtetaal 0 "teller-controle - nagemaakt, alles in orde")"
cp _tools/taalonderdelen.py _tools/taalparen.tsv "$ECHT_TAAL/_tools/"
cp -R _tools/taalwissel "$ECHT_TAAL/_tools/taalwissel"
for m in oefenboeken en manuscript speeltjes tabellen tables; do
  [ -e "$m" ] && ln -s "$PWD/$m" "$ECHT_TAAL/$m"
done
keur     "6c de echte taalstukken van deze repo: laat door" 0 "$ECHT_TAAL"
getoetst=$((getoetst + 1))
if grep -qE "losse bladzijden: [1-9][0-9]* nagelopen, 0 gat" "$M/uit"; then
  echo "  ok      en hij heeft echt gekeken ($(grep -oE '[0-9]+ nagelopen' "$M/uit" | head -1))"
else
  echo "  ZAKT    en zegt niet dat hij bladzijden naliep -- niet gekeken is niet groen"
  sed 's/^/          /' "$M/uit"
  gezakt=$((gezakt + 1))
fi
# Sinds 21-11-2026 ook buiten de tabel (wezen). Hier lopen de bladzijden via
# wegwijzers; de wachter moet die volgen, anders kijkt hij in deze toets nergens.
getoetst=$((getoetst + 1))
if grep -qE "buiten de tabel: [1-9][0-9]* \.html nagelopen, 0 met een taalstuk" "$M/uit"; then
  echo "  ok      en ook buiten de tabel ($(grep -oE 'buiten de tabel: [0-9]+' "$M/uit"))"
else
  echo "  ZAKT    en keek niet buiten de tabel, of vond daar een taalstuk"
  grep -F "buiten de tabel" "$M/uit" | sed 's/^/          /'
  gezakt=$((gezakt + 1))
fi

getoetst=$((getoetst + 1))
BEDRADING6="$(python3 - "$NAAR_BUITEN" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
def tak(naam):
    m = re.search(r"^%s\)\n(.*?)^  ;;" % re.escape(naam), s, re.S | re.M)
    return m.group(1) if m else ""
fout = []
for naam, hoe in (("--nakijken", "blokkerend"), ("--productie", "blokkerend"),
                  ("--lokaal", "melden"), ("--proefdruk", "melden")):
    t = tak(naam)
    m = re.search(r"taalstukken_nakijken +%s" % hoe, t)
    if not m:
        fout.append(f"{naam} roept de poort niet {hoe} aan")
    elif naam == "--productie" and "Niet geleverd" not in t[m.start():m.start() + 120]:
        fout.append("--productie stopt niet als de poort rood is")
    elif naam == "--productie" and m.start() > t.find("git push"):
        fout.append("--productie roept de poort pas na de push aan")
print("; ".join(fout) if fout else "ok")
PY
)"
if [ "$BEDRADING6" = ok ]; then
  echo "  ok    6d --nakijken en --productie (blokkerend), --lokaal en --proefdruk (meldend) roepen hem aan"
else
  echo "  ZAKT  6d bedrading: $BEDRADING6"
  gezakt=$((gezakt + 1))
fi

# Sinds 21-11-2026 (spoor taalpers) zegt de wachter het als hij niet kón kijken
# (afloop 3), en noemt hij een bladzij zonder plek voor het knopje bij naam in
# plaats van met een traceback te stoppen. De ECHTE taalonderdelen.py, met een
# eigen tabel en eigen bladzijden.
echte_taal_repo() {  # $1 = naam -> repo met de echte wachter en stukken, zonder tabel
  local r; r="$(nep_repo "$1" 0 "teller-controle - nagemaakt, alles in orde")"
  cp _tools/taalonderdelen.py "$r/_tools/"
  cp -R _tools/taalwissel "$r/_tools/taalwissel"
  echo "$r"
}
KAPOT_TAAL="$(echte_taal_repo kapottaal)"
printf 'oefenboeken/x/a.html\ten/workbooks/x/a.html\n' > "$KAPOT_TAAL/_tools/taalparen.tsv"   # geen derde kolom
keur     "6e een kapotte taalparen.tsv: HOUDT TEGEN" 1 "$KAPOT_TAAL"
verwacht "  en zegt dat hij niet kon kijken" "De taalstukkenwachter kon niet kijken"
verwacht "  en noemt de regel van de tabel" "regel 1 is geen"
getoetst=$((getoetst + 1))
if grep -qF "mist zijn taalknopje" "$M/uit"; then
  echo "  ZAKT    en legt de schuld tóch bij de bladzijden"
  gezakt=$((gezakt + 1))
else
  echo "  ok      en legt de schuld NIET bij de bladzijden"
fi

LEEG_TAAL="$(echte_taal_repo leegtaal)"
printf 'index.html\ten/index.html\tauto\n' > "$LEEG_TAAL/_tools/taalparen.tsv"   # geen enkele losse tweeling
keur     "6f een tabel zonder losse tweeling: HOUDT TEGEN (niets nagelopen is niet groen)" 1 "$LEEG_TAAL"
verwacht "  en zegt dat hij niet kon kijken" "De taalstukkenwachter kon niet kijken"

ZONDER_KOP="$(echte_taal_repo zonderkop)"
printf 'oefenboeken/x/a.html\ten/workbooks/x/a.html\tlos\n' > "$ZONDER_KOP/_tools/taalparen.tsv"
mkdir -p "$ZONDER_KOP/oefenboeken/x" "$ZONDER_KOP/en/workbooks/x"
printf '<html><body>\n<p>geen kop</p></body></html>\n' > "$ZONDER_KOP/oefenboeken/x/a.html"
printf '<html><head><title>a</title>\n</head>\n<body>\n<p>a</p></body></html>\n' > "$ZONDER_KOP/en/workbooks/x/a.html"
python3 "$ZONDER_KOP/_tools/taalonderdelen.py" los > /dev/null 2>&1 || true   # de Engelse kant in orde maken
keur     "6g een tweeling zonder plek voor de stukken: HOUDT TEGEN" 1 "$ZONDER_KOP"
verwacht "  en noemt hem, met de reden" "oefenboeken/x/a.html: geen of meer dan één </head>"
getoetst=$((getoetst + 1))
if grep -qF "Traceback" "$M/uit"; then
  echo "  ZAKT    en stopt met een traceback in plaats van een gat met naam"
  gezakt=$((gezakt + 1))
else
  echo "  ok      zonder traceback"
fi

# Twee gevallen van de tegendraadse nakijker (21-11-2026), die met een kale
# Python-fout op afloop 1 uitkwamen en dus "mist zijn taalknopje" heetten.
GEEN_UTF8="$(echte_taal_repo geenutf8)"
cp "$ZONDER_KOP/_tools/taalparen.tsv" "$GEEN_UTF8/_tools/"
mkdir -p "$GEEN_UTF8/oefenboeken/x" "$GEEN_UTF8/en/workbooks/x"
cp "$ZONDER_KOP/en/workbooks/x/a.html" "$GEEN_UTF8/en/workbooks/x/"
printf '<html><head><title>caf\xe9</title>\n</head>\n<body>\n<p>a</p></body></html>\n' > "$GEEN_UTF8/oefenboeken/x/a.html"
keur     "6h een tweeling die geen UTF-8 is: HOUDT TEGEN, als gat met naam" 1 "$GEEN_UTF8"
verwacht "  en noemt hem" "oefenboeken/x/a.html"
verwacht "  als een bladzij die de stukken niet kan dragen" "kan de taalstukken niet dragen"

ZONDER_STUK="$(echte_taal_repo zonderstuk)"
cp "$ZONDER_KOP/_tools/taalparen.tsv" "$ZONDER_STUK/_tools/"
mkdir -p "$ZONDER_STUK/oefenboeken/x" "$ZONDER_STUK/en/workbooks/x"
cp "$ZONDER_KOP/en/workbooks/x/a.html" "$ZONDER_STUK/en/workbooks/x/"
cp "$ZONDER_KOP/en/workbooks/x/a.html" "$ZONDER_STUK/oefenboeken/x/"
rm -f "$ZONDER_STUK/_tools/taalwissel/stijl_knop_los.html"
keur     "6i een stuk van de wachter zelf ontbreekt: HOUDT TEGEN" 1 "$ZONDER_STUK"
verwacht "  en zegt dat hij niet kon kijken" "De taalstukkenwachter kon niet kijken"
verwacht "  en noemt de fout" "stijl_knop_los.html"
getoetst=$((getoetst + 1))
if grep -qF "mist zijn taalknopje" "$M/uit"; then
  echo "  ZAKT    en legt de schuld tóch bij de bladzijden"
  gezakt=$((gezakt + 1))
else
  echo "  ok      en legt de schuld NIET bij de bladzijden"
fi

# Een bladzij die uit de tabel viel en zijn knopje hield (tegendraadse nakijker,
# 21-11-2026). Met een <n>-regel gebeurt dat zonder dat iemand de tabel aanraakt:
# het Engelse h1 verdwijnt, en daarmee het paar -- het Nederlandse h1 niet.
WEES_TAAL="$(echte_taal_repo weestaal)"
printf 'oefenboeken/x/h<n>.html\ten/workbooks/x/h<n>.html\tlos\n' > "$WEES_TAAL/_tools/taalparen.tsv"
mkdir -p "$WEES_TAAL/oefenboeken/x" "$WEES_TAAL/en/workbooks/x"
for h in h0 h1; do
  printf '<html><head><title>%s</title>\n</head>\n<body>\n<p>%s</p></body></html>\n' "$h" "$h" > "$WEES_TAAL/oefenboeken/x/$h.html"
  cp "$WEES_TAAL/oefenboeken/x/$h.html" "$WEES_TAAL/en/workbooks/x/$h.html"
done
python3 "$WEES_TAAL/_tools/taalonderdelen.py" los > /dev/null 2>&1 || true
keur     "6k vooraf: twee paren uit één <n>-regel, met stukken: laat door" 0 "$WEES_TAAL"
rm -f "$WEES_TAAL/en/workbooks/x/h1.html"
keur     "6k het Engelse h1 weg, het Nederlandse h1 houdt zijn knopje: HOUDT TEGEN" 1 "$WEES_TAAL"
verwacht "  en noemt de wees" "oefenboeken/x/h1.html: draagt knopje"
verwacht "  met een herstel dat bestaat" "taalonderdelen.py ruim oefenboeken/x/h1.html"
# Dat herstel moet ook echt herstellen (tweede nakijker: `los` haalt nooit iets weg,
# dus "Herstellen: los" bij een wees liep in een kring).
getoetst=$((getoetst + 1))
# Afloop alleen is niet genoeg: een `ruim` die niet bestaat, geeft ook geen 0.
if ! python3 "$WEES_TAAL/_tools/taalonderdelen.py" ruim oefenboeken/x/h0.html > "$M/ruim" 2>&1 \
   && grep -qF "staat in taalparen.tsv — geen wees" "$M/ruim" \
   && grep -qF 'aria-label="taal"' "$WEES_TAAL/oefenboeken/x/h0.html"; then
  echo "  ok      ruim weigert een bladzij die in de tabel staat, zegt waarom, en h0 houdt zijn knopje"
else
  echo "  ZAKT    ruim op h0 (in de tabel): weigerde niet, zei niet waarom, of haalde het knopje weg"
  sed 's/^/          /' "$M/ruim"
  gezakt=$((gezakt + 1))
fi
python3 "$WEES_TAAL/_tools/taalonderdelen.py" ruim oefenboeken/x/h1.html > "$M/ruim" 2>&1 || true
keur     "6k na ruim: de wees is weg, en de poort is groen" 0 "$WEES_TAAL"

# Een wees in een map met een _ ervoor: Quarto neemt zo'n map onder een bijlage-glob
# wél mee (oefenboeken/ts/_common_ts/ staat live), dus de wachter ook.
WEES_LAAG="$(echte_taal_repo weeslaag)"
cp "$ZONDER_KOP/_tools/taalparen.tsv" "$WEES_LAAG/_tools/"
mkdir -p "$WEES_LAAG/oefenboeken/x/_extra" "$WEES_LAAG/en/workbooks/x"
cp "$ZONDER_KOP/en/workbooks/x/a.html" "$WEES_LAAG/en/workbooks/x/"
cp "$ZONDER_KOP/en/workbooks/x/a.html" "$WEES_LAAG/oefenboeken/x/"
python3 "$WEES_LAAG/_tools/taalonderdelen.py" los > /dev/null 2>&1 || true
cp "$WEES_LAAG/oefenboeken/x/a.html" "$WEES_LAAG/oefenboeken/x/_extra/w.html"
keur     "6l een wees in oefenboeken/x/_extra/: HOUDT TEGEN" 1 "$WEES_LAAG"
verwacht "  en noemt hem" "oefenboeken/x/_extra/w.html: draagt"

# Een stuk van de wachter zelf dat geen UTF-8 is: een fout van het gereedschap, niet
# van elke bladzij (tweede nakijker: beide bladzijden kregen "kan de taalstukken niet
# dragen").
KAPOT_STUK="$(echte_taal_repo kapotstuk)"
cp "$ZONDER_KOP/_tools/taalparen.tsv" "$KAPOT_STUK/_tools/"
mkdir -p "$KAPOT_STUK/oefenboeken/x" "$KAPOT_STUK/en/workbooks/x"
cp "$ZONDER_KOP/en/workbooks/x/a.html" "$KAPOT_STUK/en/workbooks/x/"
cp "$ZONDER_KOP/en/workbooks/x/a.html" "$KAPOT_STUK/oefenboeken/x/"
printf '\xe9' >> "$KAPOT_STUK/_tools/taalwissel/balk.html"
keur     "6m een stuk van de wachter is geen UTF-8: HOUDT TEGEN" 1 "$KAPOT_STUK"
verwacht "  en zegt dat hij niet kon kijken" "De taalstukkenwachter kon niet kijken"
getoetst=$((getoetst + 1))
if grep -qF "kan de taalstukken niet dragen" "$M/uit"; then
  echo "  ZAKT    en legt de schuld tóch bij de bladzijden"
  gezakt=$((gezakt + 1))
else
  echo "  ok      en legt de schuld NIET bij de bladzijden"
fi

# Een map die hij niet mag lezen: de doorloop is dan onvolledig, en dat is niet groen.
BLINDE_MAP="$(echte_taal_repo blindemap)"
cp "$WEES_TAAL/_tools/taalparen.tsv" "$BLINDE_MAP/_tools/"
cp -R "$WEES_TAAL/oefenboeken" "$WEES_TAAL/en" "$BLINDE_MAP/"
mkdir -p "$BLINDE_MAP/oefenboeken/dicht"
chmod 000 "$BLINDE_MAP/oefenboeken/dicht"
keur     "6n een map die niet te lezen is: HOUDT TEGEN" 1 "$BLINDE_MAP"
chmod 755 "$BLINDE_MAP/oefenboeken/dicht"   # anders kan de opruimer hem niet weghalen
verwacht "  en zegt dat hij niet kon kijken" "De taalstukkenwachter kon niet kijken"
verwacht "  en welke map" "oefenboeken/dicht"

# De Action (21-11-2026, spoor taalpers): naar_buiten.sh leest de werkkopie, en wat
# er naar main gaat kan daarvan afwijken (lever.sh commit alleen zijn eigen
# bladzijden; een rechtstreekse push kan iedereen). Dus staat de wachter ook in
# publish.yml, de enige poort waar elke route langs moet. Hier geëist: een stap die
# hem draait, vóór de publicatiestap, zonder continue-on-error en zonder een `if:`
# (allebei maken hem versiering; de tweede nakijker liet `if: false` groen zien).
# PUBLISH_YML= laat een tegenproef een andere versie geven.
PUBLISH_YML="${PUBLISH_YML:-.github/workflows/publish.yml}"
getoetst=$((getoetst + 1))
ACTIE6="$(python3 - "$PUBLISH_YML" <<'PY'
import re, sys
try:
    s = open(sys.argv[1], encoding="utf-8").read()
except OSError as e:
    print(f"niet te lezen: {e}"); sys.exit()
stappen = re.split(r"^      - name: ", s, flags=re.M)[1:]
namen = [st.split("\n", 1)[0].strip() for st in stappen]
wacht = [i for i, st in enumerate(stappen)
         if re.search(r"^\s+run: python3 _tools/taalonderdelen\.py los --controleer\s*$", st, re.M)]
publ = [i for i, st in enumerate(stappen) if "quarto-actions/publish" in st]
if not wacht:
    print("geen stap draait taalonderdelen.py los --controleer")
elif not publ:
    print("geen publicatiestap gevonden -- kan de volgorde niet toetsen")
elif wacht[0] > publ[0]:
    print(f"de wachter ({namen[wacht[0]]}) staat ná de publicatie ({namen[publ[0]]})")
elif "continue-on-error" in stappen[wacht[0]]:
    print("de wachterstap heeft continue-on-error: rood houdt niets tegen")
elif re.search(r"^\s+if:", stappen[wacht[0]], re.M):
    print("de wachterstap heeft een if: -- dan draait hij misschien niet")
else:
    print("ok")
PY
)"
if [ "$ACTIE6" = ok ]; then
  echo "  ok    6j publish.yml draait de taalstukkenwachter vóór de publicatie, en rood houdt tegen"
else
  echo "  ZAKT  6j publish.yml: $ACTIE6"
  gezakt=$((gezakt + 1))
fi

echo ""
if [ "$gezakt" = "0" ]; then
  echo "$getoetst zaken getoetst, alles groen."
  exit 0
fi
echo "$getoetst zaken getoetst, $gezakt GEZAKT."
exit 1
