#!/usr/bin/env bash
# ============================================================
# doorstuurders_test.sh — bijt de doorstuurwachter, of doet hij maar alsof?
#
#   bash _tools/tests/doorstuurders_test.sh
#
# Elke zaak zet een kleine proefsite in /tmp neer met een kopie van
# `doorstuurders.py` en `tellerregel.py`, een tabel van twee regels en een paar
# bladzijden, en maakt dan precies één ding stuk. Zo wordt rood gemaakt zonder
# de echte site aan te raken -- een toets die de repo moet beschadigen om te
# kunnen meten, wordt niet gedraaid.
#
# De laatste zaken draaien de ECHTE naar_buiten.sh --nakijken op zo'n
# proefsite: een wachter die werkt maar nergens aan hangt, gaat nooit af.
#
# DOORSTUUR= laat de mutatieproef een kreupele kopie doorschuiven.
# Afloopcode 0 = alle zaken goed, 1 = er zakt er een.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
WACHT="${DOORSTUUR:-_tools/doorstuurders.py}"
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
gezakt=0
getoetst=0

TELLER='<script data-goatcounter="https://countcamp.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>'

bladzij() {   # $1 = pad; een echte bladzij met teller
  mkdir -p "$(dirname "$1")"
  printf '<!doctype html>\n<html><head><title>echt</title>\n%s\n</head><body>inhoud</body></html>\n' \
    "$TELLER" > "$1"
}

proefsite() {  # $1 = naam -> een site met twee doorstuurders uit de tabel, groen
  local S="$M/$1"
  mkdir -p "$S/_tools"
  cp "$WACHT" "$S/_tools/doorstuurders.py"
  cp _tools/tellerregel.py "$S/_tools/"
  bladzij "$S/oefenboeken/ozp1/04_normaal/04_normaal.html"
  bladzij "$S/manuscript/handleiding/hoofdstuk-1---beschrĳven.html"
  # Een bladzij die Quarto maakt uit een bron: in de repo staat alleen de .qmd.
  mkdir -p "$S/oefenboeken"; printf -- '---\ntitle: plank\n---\n' > "$S/oefenboeken/index.qmd"
  printf '%s\t%s\t%s\t%s\n' oud nieuw besluit grond \
    oefenboeken/ozp1/03_normaal/03_normaal.html oefenboeken/ozp1/04_normaal/04_normaal.html bouwen proef \
    manuscript/handleiding/01-oud.html 'manuscript/handleiding/hoofdstuk-1---beschrĳven.html' bouwen proef \
    werkboeken/weg.html '' niet 'bewust niet' \
    > "$S/_tools/doorstuurders.tsv"
  python3 "$S/_tools/doorstuurders.py" --site "$S" --bouw > "$M/bouw" 2>&1
  echo "$S"
}

zaak() {  # $1 = naam, $2 = verwachte afloopcode, $3 = tekst die erin moet staan, $4.. = commando
  local naam="$1" wil="$2" moet="$3"; shift 3
  getoetst=$((getoetst + 1))
  "$@" > "$M/uit" 2>&1
  local echt=$?
  if [ "$echt" = "$wil" ] && { [ -z "$moet" ] || grep -qF -- "$moet" "$M/uit"; }; then
    echo "  ok    $naam (afloopcode $echt)"
  else
    echo "  ZAKT  $naam — wilde afloopcode $wil en de tekst '${moet:-<geen>}', kreeg $echt"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

kijk() { python3 "$1/_tools/doorstuurders.py" --site "$1"; }

echo "doorstuurders_test — $WACHT"

# ---- 1. een kloppende site blijft stil, en heeft ook echt iets gemeten ----
S="$(proefsite schoon)"
zaak "1  alles klopt" 0 "Alle 2 doorstuurders uit de tabel" kijk "$S"
zaak "1b de rij die bewust niet gebouwd is, staat er ook niet" 1 "" test -e "$S/werkboeken/weg.html"

# ---- 2. --bouw is herhaalbaar ------------------------------------------
zaak "2  nog een keer bouwen verandert niets" 0 "0 nieuw, 0 ververst, 2 ongewijzigd" \
     python3 "$S/_tools/doorstuurders.py" --site "$S" --bouw

# ---- 3. de ĳ in het doel wordt procent-gecodeerd, en blijft vindbaar ---
zaak "3  een doel met een ĳ wordt gecodeerd" 0 "url=/manuscript/handleiding/hoofdstuk-1---beschr%C4%B3ven.html" \
     cat "$S/manuscript/handleiding/01-oud.html"

# ---- 4. weggeveegd (rsync --delete, rmtree) -----------------------------
S="$(proefsite weg)"; rm "$S/oefenboeken/ozp1/03_normaal/03_normaal.html"
zaak "4  een doorstuurder die weg is" 1 "ONTBREEKT   oefenboeken/ozp1/03_normaal/03_normaal.html" kijk "$S"

# ---- 5. met de hand omgezet naar een ander doel -------------------------
S="$(proefsite omgezet)"
sed -i.bak 's#04_normaal/04_normaal.html#index.html#g' "$S/oefenboeken/ozp1/03_normaal/03_normaal.html"
zaak "5  een doorstuurder die ergens anders heen wijst dan de tabel" 1 "WIJKT AF" kijk "$S"

# ---- 6. het doel is verhuisd (een thema kreeg een nieuw nummer) ---------
S="$(proefsite verhuisd)"; rm "$S/oefenboeken/ozp1/04_normaal/04_normaal.html"
zaak "6  een doel dat niet meer bestaat" 1 "DOEL WEG    oefenboeken/ozp1/03_normaal/03_normaal.html" kijk "$S"

# ---- 6b. hoofdletters: macOS vindt het, GitHub Pages niet ---------------
S="$(proefsite hoofdletters)"
printf '%s\t%s\t%s\t%s\n' oud nieuw besluit grond \
  oefenboeken/ozp1/03_normaal/03_normaal.html oefenboeken/ozp1/04_Normaal/04_normaal.html bouwen proef \
  > "$S/_tools/doorstuurders.tsv"
python3 "$S/_tools/doorstuurders.py" --site "$S" --bouw > /dev/null 2>&1
zaak "6b een doel met andere hoofdletters bestaat live niet" 1 "DOEL WEG    oefenboeken/ozp1/03_normaal/03_normaal.html -> oefenboeken/ozp1/04_Normaal" kijk "$S"

# ---- 7. het doel is zelf een doorstuurder (ketting) ----------------------
S="$(proefsite ketting)"
cp "$S/manuscript/handleiding/01-oud.html" "$S/oefenboeken/ozp1/04_normaal/04_normaal.html"
zaak "7  een doel dat zelf doorstuurt" 1 "DOEL IS GEEN BLADZIJ" kijk "$S"

# ---- 8. op het oude adres staat weer een echte bladzij ------------------
S="$(proefsite terug)"; bladzij "$S/oefenboeken/ozp1/03_normaal/03_normaal.html"
zaak "8  een oud adres dat weer een echte bladzij is" 1 "ECHTE BLADZIJ" kijk "$S"
zaak "8b en --bouw schrijft er niet overheen" 1 "GEWEIGERD oefenboeken/ozp1/03_normaal/03_normaal.html" \
     python3 "$S/_tools/doorstuurders.py" --site "$S" --bouw
zaak "8c de bladzij staat er nog" 0 "inhoud" cat "$S/oefenboeken/ozp1/03_normaal/03_normaal.html"

# ---- 9. doorstuurders die NIET uit de tabel komen ------------------------
S="$(proefsite vreemd)"
mkdir -p "$S/werkboeken/ozp1"
cat > "$S/werkboeken/ozp1/index.html" <<'HTML'
<!doctype html>
<html lang="nl"><head><meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=/oefenboeken/">
</head><body></body></html>
HTML
zaak "9  een vreemde doorstuurder naar een gerenderde bladzij (.qmd) is geen alarm" 0 "de 1 andere ook" kijk "$S"
sed -i.bak 's#url=/oefenboeken/#url=/oefenboeken/bestaat_niet/#' "$S/werkboeken/ozp1/index.html"
zaak "9b een vreemde doorstuurder naar niets wél" 1 "DOEL WEG    werkboeken/ozp1/index.html" kijk "$S"

# ---- 10. blind is niet groen --------------------------------------------
S="$(proefsite geen_tabel)"; rm "$S/_tools/doorstuurders.tsv"
zaak "10 zonder tabel is het blind, niet goed" 3 "NIETS GEMETEN" kijk "$S"
S="$(proefsite lege_tabel)"; printf 'oud\tnieuw\tbesluit\tgrond\n' > "$S/_tools/doorstuurders.tsv"
zaak "10b een tabel zonder één rij om te bouwen is ook blind" 3 "NIETS GEMETEN" kijk "$S"
# 10c: een wachter die omvalt heeft niets gemeten -- afloop 3, niet 1. Met 1
# gaf naar_buiten.sh de doorstuurders de schuld van een kapotte tabel.
S="$(proefsite kapot)"; printf 'kapot\n' > "$S/_tools/doorstuurders.tsv"
zaak "10c een kapotte tabel laat de wachter omvallen: blind, niet 'fout'" 3 "LIEP VAST" kijk "$S"

# ---- 11. de tellerwachter herkent ze als doorstuurder --------------------
#     Anders telt hij ze als bladzij zonder teller, en de enige 'oplossing'
#     die hij voorstelt (--repareer) zet er een teller in: één bezoek, twee keer.
S="$(proefsite teller)"
cp _tools/controleer_tellers.py "$S/_tools/"
zaak "11 controleer_tellers.py sluit ze uit en noemt ze" 0 "doorstuurder   oefenboeken/ozp1/03_normaal/03_normaal.html" \
     python3 "$S/_tools/controleer_tellers.py" --site "$S" --map oefenboeken

# ---- 13. --afleiden: op inhoud, en stabiel nadat de doorstuurders live staan --
#     Een nagemaakte gh-pages-geschiedenis in drie publicaties:
#       A  thema 3 = normaalverdeling, thema 4 = discreet
#       B  de wissel: 03_normaal en 04_discreet weg, 03_discreet en 04_normaal erbij
#       C  (na onze publicatie) de doorstuurders zelf staan op de oude adressen
#     Na B moeten beide oude adressen naar hun INHOUD gekoppeld worden, niet naar
#     hun nummer. Na C moet dezelfde tabel eruit komen, zonder alarm.
thema() {  # $1 = pad, $2 = titel, $3 = tekst
  mkdir -p "$(dirname "$1")"
  printf '<!doctype html>\n<html><head><title>%s – Oefenboek OZP 1</title>\n%s\n</head><body><main><h1>%s</h1><p>%s</p></main></body></html>\n' \
    "$2" "$TELLER" "$2" "$3" > "$1"
}
NORMAAL="de normaalverdeling klokvorm gemiddelde standaardafwijking zscore oppervlakte tabel ruwe score marsmannetje"
DISCREET="discrete kansvariabele dobbelsteen verwachtingswaarde gewogen gemiddelde uitkomsten kansen bosspel"
GH="$M/gh"; mkdir -p "$GH"; git -C "$GH" init -q -b main
git -C "$GH" config user.email toets@countcamp.org; git -C "$GH" config user.name doorstuurtoets
thema "$GH/oefenboeken/ozp1/03_normaal/03_normaal.html"   "Thema 3 · Normaalverdeling" "$NORMAAL"
thema "$GH/oefenboeken/ozp1/04_discreet/04_discreet.html" "Thema 4 · Discreet"         "$DISCREET"
git -C "$GH" add -A; git -C "$GH" commit -qm A
git -C "$GH" rm -rq oefenboeken/ozp1/03_normaal oefenboeken/ozp1/04_discreet
thema "$GH/oefenboeken/ozp1/03_discreet/03_discreet.html" "Thema 3 · Discreet"         "$DISCREET"
thema "$GH/oefenboeken/ozp1/04_normaal/04_normaal.html"   "Thema 4 · Normaalverdeling" "$NORMAAL"
# een proefdruk (--proefdruk schrijft naar dezelfde tak): nooit een lezersadres
thema "$GH/pr-preview/pr-1/oefenboeken/ozp1/05_proef/05_proef.html" "Thema 5 · Proef" "$NORMAAL"
git -C "$GH" add -A; git -C "$GH" commit -qm B

S="$M/afleiden"; mkdir -p "$S/_tools"
cp "$WACHT" "$S/_tools/doorstuurders.py"; cp _tools/tellerregel.py "$S/_tools/"
cp -R "$GH/oefenboeken" "$S/"
git -C "$S" init -q -b main
git -C "$S" fetch -q "$GH" +main:refs/remotes/origin/gh-pages
zaak "13  --afleiden na de wissel" 0 "dood: 2 (langs gh-pages: 2)" \
     python3 "$S/_tools/doorstuurders.py" --site "$S" --afleiden
zaak "13b oud thema 3 (normaalverdeling) gaat naar het nieuwe thema 4, niet naar nummer 3" 0 \
     "oefenboeken/ozp1/03_normaal/03_normaal.html	oefenboeken/ozp1/04_normaal/04_normaal.html	bouwen" \
     cat "$S/_tools/doorstuurders.tsv"
zaak "13c oud thema 4 (discreet) gaat naar het nieuwe thema 3" 0 \
     "oefenboeken/ozp1/04_discreet/04_discreet.html	oefenboeken/ozp1/03_discreet/03_discreet.html	bouwen" \
     cat "$S/_tools/doorstuurders.tsv"
python3 "$S/_tools/doorstuurders.py" --site "$S" --bouw > /dev/null 2>&1
cp "$S/_tools/doorstuurders.tsv" "$M/tabel_voor"
# C: de doorstuurders gepubliceerd
mkdir -p "$GH/oefenboeken/ozp1/03_normaal" "$GH/oefenboeken/ozp1/04_discreet"
cp "$S/oefenboeken/ozp1/03_normaal/03_normaal.html"   "$GH/oefenboeken/ozp1/03_normaal/"
cp "$S/oefenboeken/ozp1/04_discreet/04_discreet.html" "$GH/oefenboeken/ozp1/04_discreet/"
git -C "$GH" add -A; git -C "$GH" commit -qm C
git -C "$S" fetch -q "$GH" +main:refs/remotes/origin/gh-pages
zaak "13d na publicatie van de doorstuurders: nog steeds 2 dood, en geen alarm" 0 "dood: 2 (langs gh-pages: 2)" \
     python3 "$S/_tools/doorstuurders.py" --site "$S" --afleiden
# De kopregel noemt de gh-pages-commit en verandert dus terecht; de rijen niet.
grep -v '^#' "$M/tabel_voor" > "$M/rijen_voor"
grep -v '^#' "$S/_tools/doorstuurders.tsv" > "$M/rijen_na"
zaak "13e en de rijen van de tabel zijn byte voor byte dezelfde" 0 "" \
     cmp "$M/rijen_voor" "$M/rijen_na"

# ---- 12. de bedrading: de echte naar_buiten.sh --nakijken ----------------
bedraad() {  # $1 = naam -> proefsite met de echte pers, en nagemaakte plank- en tellerwachters
  local S; S="$(proefsite "$1")"
  cp _tools/naar_buiten.sh "$S/_tools/"
  printf 'print("plankwacht - nagemaakt, alles in orde")\n'  > "$S/_tools/plankwacht.py"
  printf 'print("tellers - nagemaakt, alles in orde")\n'     > "$S/_tools/controleer_tellers.py"
  echo "$S"
}
S="$(bedraad pers_groen)"
zaak "12 --nakijken laat kloppende doorstuurders door" 0 "Alle poorten staan groen" bash "$S/_tools/naar_buiten.sh" --nakijken
S="$(bedraad pers_rood)"; rm "$S/oefenboeken/ozp1/03_normaal/03_normaal.html"
zaak "12b --nakijken houdt een verdwenen doorstuurder tegen" 1 "Een oude bladwijzer komt niet (meer) uit" \
     bash "$S/_tools/naar_buiten.sh" --nakijken
S="$(bedraad pers_blind)"; rm "$S/_tools/doorstuurders.tsv"
zaak "12c --nakijken noemt een blinde wachter blind" 1 "kon niet kijken" bash "$S/_tools/naar_buiten.sh" --nakijken
S="$(bedraad pers_weg)"; rm "$S/_tools/doorstuurders.py"
zaak "12d --nakijken zonder wachter legt de schuld niet bij de doorstuurders" 1 "ONGEMETEN" \
     bash "$S/_tools/naar_buiten.sh" --nakijken

echo ""
if [ "$gezakt" = "0" ]; then
  echo "$getoetst zaken getoetst, alles groen."
  exit 0
fi
echo "$getoetst zaken getoetst, $gezakt GEZAKT."
exit 1
