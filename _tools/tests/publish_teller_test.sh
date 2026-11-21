#!/usr/bin/env bash
# ============================================================
# publish_teller_test.sh — draait `publish_workbook.py` echt, in /tmp.
#
#   bash _tools/tests/publish_teller_test.sh
#
# Dit is de poort die de opdracht vroeg: na het inlezen van een werkboek moet
# ELKE bladzij de bezoekersteller dragen, en anders moet het script luid falen.
#
# Waarom in /tmp en niet hier: `publish_workbook.py` leidt zijn doelmap af uit
# zijn EIGEN plek (`SITE_ROOT = de map boven _tools/`). Draaien we het uit deze
# repo, dan schrijft het in deze repo. Door een kopie van het script in
# `$M/proefsite/_tools/` te zetten, verhuist SITE_ROOT mee naar /tmp en blijft de
# echte site onaangeroerd. Dat is dezelfde regel als bij de wachter: een toets
# die niet rood kan worden zonder schade, wordt niet gedraaid.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
gezakt=0
getoetst=0

# POORT= en REGEL= laten de mutatieproef een kreupele kopie doorschuiven.
POORT="${POORT:-_tools/publish_workbook.py}"
REGEL="${REGEL:-_tools/tellerregel.py}"

PROEFSITE="$M/proefsite"
mkdir -p "$PROEFSITE/_tools"
cp "$POORT" "$PROEFSITE/_tools/publish_workbook.py"
cp "$REGEL" "$PROEFSITE/_tools/tellerregel.py"

TELLER='<script data-goatcounter="https://countcamp.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>'

bouw_bron() {  # zet een nagemaakt gerenderd _site/ neer in $M/bron
  rm -rf "$M/bron"
  mkdir -p "$M/bron/00_thema"
  # index.html draagt de teller al -- zo staat het er bij ozp1 en mvda echt.
  cat > "$M/bron/index.html" <<HTML
<!doctype html>
<html lang="nl"><head><meta charset="utf-8"><title>Werkboek</title>
$TELLER
</head><body><p><a href="00_thema/00_thema.html">thema</a></p></body></html>
HTML
  # het thema-hoofdstuk niet -- dat is de submap-_metadata.yml-val.
  cat > "$M/bron/00_thema/00_thema.html" <<'HTML'
<!doctype html>
<html lang="nl"><head><meta charset="utf-8"><title>Thema</title>
</head><body><p>inhoud van het thema</p></body></html>
HTML
}

zaak() {  # $1 = naam, $2 = verwachte afloopcode
  getoetst=$((getoetst + 1))
  python3 "$PROEFSITE/_tools/publish_workbook.py" \
      --src "$M/bron" --name proefboek > "$M/uit" 2>&1
  local echt=$?
  if [ "$echt" = "$2" ]; then
    echo "  ok    $1 (afloopcode $echt)"
  else
    echo "  ZAKT  $1 — verwacht afloopcode $2, kreeg $echt"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

verwacht() {  # $1 = naam, $2 = tekst die in de uitvoer moet staan
  getoetst=$((getoetst + 1))
  if grep -qF "$2" "$M/uit"; then
    echo "  ok    $1"
  else
    echo "  ZAKT  $1 — '$2' staat niet in de uitvoer"
    sed 's/^/          /' "$M/uit"
    gezakt=$((gezakt + 1))
  fi
}

echo "publish_teller_test — $POORT op een proefsite in /tmp (regel: $REGEL)"
echo ""

# === 1. de blinde bladzij krijgt zijn teller bij het inlezen ================
bouw_bron
zaak    "een werkboek met één blinde bladzij komt schoon binnen" 0
verwacht "  en meldt wat het invoegde"        "+ teller in 00_thema/00_thema.html"
verwacht "  en dat index.html hem al had"    "1 bladzij(den) had hem al, 1 erbij gezet"

getoetst=$((getoetst + 1))
n_thema=$(grep -cF 'gc.zgo.at/count.js' "$PROEFSITE/oefenboeken/proefboek/00_thema/00_thema.html")
n_index=$(grep -cF 'gc.zgo.at/count.js' "$PROEFSITE/oefenboeken/proefboek/index.html")
if [ "$n_thema" = "1" ] && [ "$n_index" = "1" ]; then
  echo "  ok    beide bladzijden dragen de teller precies één keer (thema $n_thema, index $n_index)"
else
  echo "  ZAKT  thema $n_thema, index $n_index — beide moeten 1"
  gezakt=$((gezakt + 1))
fi

# === 2. twee keer inlezen zet hem niet twee keer =============================
#     publish_workbook.py gooit de doelmap weg en kopieert opnieuw, dus de tweede
#     ronde begint weer bij de blinde bron. Dit proeft dat het invoegen ook op
#     een bron die hem AL heeft niet verdubbelt.
bouw_bron
python3 - "$M/bron/00_thema/00_thema.html" "$TELLER" <<'PY'
import sys
pad, teller = sys.argv[1], sys.argv[2]
s = open(pad, encoding="utf-8").read()
open(pad, "w", encoding="utf-8").write(s.replace("</head>", teller + "\n</head>"))
PY
zaak    "een bron die de teller al heeft, komt ook schoon binnen" 0
verwacht "  en er wordt niets meer bijgezet" "2 bladzij(den) had hem al, 0 erbij gezet"
getoetst=$((getoetst + 1))
n=$(grep -cF 'gc.zgo.at/count.js' "$PROEFSITE/oefenboeken/proefboek/00_thema/00_thema.html")
if [ "$n" = "1" ]; then
  echo "  ok    de teller staat er nog precies één keer in"
else
  echo "  ZAKT  de teller staat er $n keer in — moet 1"
  gezakt=$((gezakt + 1))
fi

# === 3. een HALVE teller wordt niet gerepareerd maar geweigerd ===============
#     Repareren zou een kapotte regel naast een goede zetten; dat moet iemand zien.
bouw_bron
python3 - "$M/bron/00_thema/00_thema.html" <<'PY'
import sys
pad = sys.argv[1]
s = open(pad, encoding="utf-8").read()
half = '<script data-goatcounter="https://countcamp.goatcounter.com/count"></script>'
open(pad, "w", encoding="utf-8").write(s.replace("</head>", half + "\n</head>"))
PY
zaak    "een halve teller laat het script WEIGEREN" 1
verwacht "  en noemt de bladzij bij naam" "GEEN TELLER: 00_thema/00_thema.html"
verwacht "  en zegt waarom het niet door mag" "NIET publiceren tot opgelost"

# === 4. een fragment zonder <head> wordt overgeslagen, niet stil genegeerd ===
bouw_bron
printf '<div class="brok"><p>losse brok</p></div>\n' > "$M/bron/brok.html"
zaak    "een fragment breekt het inlezen niet" 0
verwacht "  en staat bij naam in de uitsluitingen" "overgeslagen (fragment): brok.html"

# === 5. een bladzij MET <head> maar ZONDER </head> is geen fragment ==========
#     Zo'n bladzij heeft wel een bezoek maar geen plek om de teller te zetten.
#     Overslaan mag, stil overslaan niet: dan publiceer je een blinde bladzij
#     met een schone uitslag erboven. Dit is de enige zaak waar `geen_head`
#     zichtbaar wordt -- de wachter blijft er hoe dan ook rood op, dus zonder
#     deze zaak zou het onderscheid nergens gemeten zijn.
bouw_bron
cat > "$M/bron/scheef.html" <<'HTML'
<!doctype html>
<html lang="nl"><head><meta charset="utf-8"><title>Scheef</title>
<body><p>een bladzij zonder sluitende head-tag</p></body></html>
HTML
zaak    "een bladzij zonder sluitende head-tag laat het script WEIGEREN" 1
verwacht "  en noemt hem bij naam" "GEEN TELLER: scheef.html"

# === 6. doorstuurders in de boekmap overleven de verse kopie (1-10-2026) =====
#     publish_workbook.py gooit oefenboeken/<naam>/ eerst weg. Stond daar een
#     doorstuurder op een oud adres (zoals oefenboeken/ozp1/03_normaalverdeling_z/),
#     dan moet hij na afloop weer staan -- anders verdwijnt hij bij elke
#     publicatie stil. De ECHTE doorstuurders.py doet het werk, met een eigen tabel.
cp _tools/doorstuurders.py "$PROEFSITE/_tools/"
printf '%s\t%s\t%s\t%s\n' oud nieuw besluit grond \
  oefenboeken/proefboek/03_oud/03_oud.html oefenboeken/proefboek/00_thema/00_thema.html bouwen proef \
  oefenboeken/ander/weg.html oefenboeken/proefboek/index.html bouwen 'buiten deze map' \
  > "$PROEFSITE/_tools/doorstuurders.tsv"
bouw_bron
zaak    "een doorstuurder in de boekmap komt na de verse kopie terug" 0
verwacht "  en het script zegt dat hij teruggezet is" "doorstuurders onder oefenboeken/proefboek/: 1 teruggezet"
getoetst=$((getoetst + 1))
if grep -qF 'url=/oefenboeken/proefboek/00_thema/00_thema.html' \
     "$PROEFSITE/oefenboeken/proefboek/03_oud/03_oud.html" 2>&1; then
  echo "  ok    de doorstuurder staat er en wijst naar het doel uit de tabel"
else
  echo "  ZAKT  oefenboeken/proefboek/03_oud/03_oud.html ontbreekt of wijst verkeerd"
  gezakt=$((gezakt + 1))
fi
getoetst=$((getoetst + 1))
if [ ! -e "$PROEFSITE/oefenboeken/ander/weg.html" ]; then
  echo "  ok    een doorstuurder BUITEN de boekmap wordt niet aangeraakt"
else
  echo "  ZAKT  publish_workbook.py schreef buiten oefenboeken/proefboek/"
  gezakt=$((gezakt + 1))
fi
# 6b: rendert het boek nu zelf een echte bladzij op dat oude adres, dan wint
#     de bladzij -- en het script zegt dat de rij in de tabel achterhaald is.
bouw_bron
mkdir -p "$M/bron/03_oud"
printf '<!doctype html>\n<html><head><title>echt</title>\n%s\n</head><body>echt</body></html>\n' \
  "$TELLER" > "$M/bron/03_oud/03_oud.html"
zaak    "een echte bladzij op een oud adres wordt niet overschreven" 0
verwacht "  en de achterhaalde rij wordt genoemd" "NIET teruggezet: oefenboeken/proefboek/03_oud/03_oud.html"
# 6c: een kapotte tabel laat het terugzetten omvallen. Het boek staat er dan al;
#     de publicatie moet het luid zeggen en de slotcontrole tóch printen.
printf 'kapot\n' > "$PROEFSITE/_tools/doorstuurders.tsv"
bouw_bron
zaak    "een kapotte doorstuurtabel laat de publicatie niet stil omvallen" 0
verwacht "  en zegt dat het terugzetten vastliep" "doorstuurders: LIEP VAST"
verwacht "  en de slotcontrole komt er nog steeds" "Compleet en gevalideerd"
rm -f "$PROEFSITE/_tools/doorstuurders.py" "$PROEFSITE/_tools/doorstuurders.tsv"

# === 7. taalstukken op een tweeling (21-11-2026, spoor ts_pers_beide) ========
#     publish_workbook.py gooit oefenboeken/<naam>/ eerst weg, en daarmee knopje,
#     hreflang en taalbalk die taalonderdelen.py er na de vorige publicatie in
#     zette. Het Oefenboek TS stond na zijn pers met 9 kale Nederlandse
#     bladzijden, en geen poort zei iets. De ECHTE taalonderdelen.py en stukken,
#     met een eigen tabel.
bouw_bron
zaak    "7a zonder taalparen.tsv: geen tweelingen, en dat wordt gezegd" 0
verwacht "  en zegt het" "geen _tools/taalparen.tsv in deze site"

cp _tools/taalonderdelen.py "$PROEFSITE/_tools/"
cp -R _tools/taalwissel "$PROEFSITE/_tools/taalwissel"
printf '%s\t%s\t%s\n' oefenboeken/proefboek/00_thema/00_thema.html \
  en/workbooks/proefboek/00_thema/00_thema.html los > "$PROEFSITE/_tools/taalparen.tsv"
bouw_thema_met_body() {  # pas_toe_los zet het knopje na een <body> op een eigen regel
  printf '<!doctype html>\n<html lang="nl"><head><meta charset="utf-8"><title>Thema</title>\n</head>\n<body>\n<p>inhoud</p></body></html>\n' \
    > "$M/bron/00_thema/00_thema.html"
}
bouw_bron; bouw_thema_met_body
zaak    "7b een tweeling krijgt zijn taalstukken bij het inlezen" 0
verwacht "  en zegt wat hij zette" \
         "taalstukken: 1 bladzij(den) met een losse tweeling in taalparen.tsv, 1 bijgezet, 0 fout"
getoetst=$((getoetst + 1))
T="$PROEFSITE/oefenboeken/proefboek/00_thema/00_thema.html"
n_knop=$(grep -cF 'aria-label="taal"' "$T")
n_href=$(grep -cF 'hreflang="en" href="https://countcamp.org/en/workbooks/proefboek/00_thema/00_thema.html"' "$T")
n_balk=$(grep -cF '/* taalbalk:' "$T")
n_idx=$(grep -cF 'aria-label="taal"' "$PROEFSITE/oefenboeken/proefboek/index.html")
if [ "$n_knop" = 1 ] && [ "$n_href" = 1 ] && [ "$n_balk" -ge 1 ] && [ "$n_idx" = 0 ]; then
  echo "  ok    knopje 1x, hreflang naar de tweeling 1x, taalbalk erin; index.html (geen tweeling) niets"
else
  echo "  ZAKT  knopje $n_knop, hreflang $n_href, balk $n_balk, knopje op index.html $n_idx"
  gezakt=$((gezakt + 1))
fi
getoetst=$((getoetst + 1))
# Eerst opvangen, dan zoeken: de afloop is hier 1 (de Engelse kant bestaat in de
# proefsite niet), en met pipefail zou die de grep overstemmen.
CONTROLE="$(python3 "$PROEFSITE/_tools/taalonderdelen.py" los --controleer 2>&1)"
if printf '%s\n' "$CONTROLE" | grep -qF "oefenboeken/proefboek/00_thema/00_thema.html: in orde"; then
  echo "  ok    en taalonderdelen.py los --controleer vindt de Nederlandse kant in orde"
else
  echo "  ZAKT  taalonderdelen.py los --controleer vindt de Nederlandse kant NIET in orde"
  gezakt=$((gezakt + 1))
fi

# Vanaf hier weigert de pers, en sinds 21-11-2026 (spoor taalpers) doet hij dat
# VÓÓR hij de oude map weggooit (stap 0b). Bewijs dat er niets is aangeraakt: het
# boek van 7b, mét zijn taalstukken, staat er na elke weigering byte voor byte nog.
VORIG="$(shasum -a 256 "$T" | cut -d' ' -f1)"
onaangeraakt() {  # $1 = naam
  getoetst=$((getoetst + 1))
  if [ -f "$T" ] && [ "$(shasum -a 256 "$T" | cut -d' ' -f1)" = "$VORIG" ]; then
    echo "  ok    $1"
  else
    echo "  ZAKT  $1 — het vorige boek is weg of veranderd"
    gezakt=$((gezakt + 1))
  fi
}

bouw_bron   # de gewone thema-bladzij: <body> en de tekst op één regel
zaak    "7c een tweeling zonder plek voor het knopje laat het script WEIGEREN" 1
verwacht "  en noemt hem bij naam" "TAALSTUKKEN: 00_thema/00_thema.html"
verwacht "  en zegt dat hij niets aanraakte" "kunnen hun taalstukken niet krijgen — niets aangeraakt"
onaangeraakt "  en het vorige boek staat er nog, met zijn knopje"

printf '%s\t%s\t%s\n' oefenboeken/proefboek/09_weg/09_weg.html \
  en/workbooks/proefboek/09_weg/09_weg.html los >> "$PROEFSITE/_tools/taalparen.tsv"
bouw_bron; bouw_thema_met_body
zaak    "7d een rij voor een bladzij die het boek niet (meer) maakt: WEIGEREN" 1
verwacht "  en noemt hem" "TAALSTUKKEN: 09_weg/09_weg.html — staat in _tools/taalparen.tsv, maar de nieuwe render maakt hem niet (meer)"
verwacht "  en zegt wat je eerst doet" "werk dan eerst _tools/taalparen.tsv bij"
onaangeraakt "  en het vorige boek staat er nog"

# Een oefenboek zonder tweeling (OZP 1, MVDA, Psychometrie) naast een tabel die
# tweelingen van een ander boek noemt: gewoon door, en dat zegt hij ook.
getoetst=$((getoetst + 1))
bouw_bron
python3 "$PROEFSITE/_tools/publish_workbook.py" --src "$M/bron" --name anderboek > "$M/uit" 2>&1
code_ander=$?
if [ "$code_ander" = 0 ] && grep -qF "taalstukken: 0 bladzij(den) met een losse tweeling in taalparen.tsv, 0 bijgezet, 0 fout" "$M/uit"; then
  echo "  ok    7e een oefenboek zonder tweeling: door, met '0 bladzij(den)' (afloopcode 0)"
else
  echo "  ZAKT  7e een oefenboek zonder tweeling — afloop $code_ander"
  sed 's/^/          /' "$M/uit"
  gezakt=$((gezakt + 1))
fi

# Een tabel die niet te lezen is: dan weet de pers niet welke bladzijden een
# tweeling hebben. Niet gekeken (3), en niets aangeraakt.
cp "$PROEFSITE/_tools/taalparen.tsv" "$M/taalparen.goed"
printf 'oefenboeken/proefboek/kapot.html\tzonder-derde-kolom\n' >> "$PROEFSITE/_tools/taalparen.tsv"
bouw_bron; bouw_thema_met_body
zaak    "7f een kapotte taalparen.tsv: NIET GEKEKEN, niet doorgaan" 3
verwacht "  en noemt de regel van de tabel" "regel 3 is geen"
onaangeraakt "  en het vorige boek staat er nog"
cp "$M/taalparen.goed" "$PROEFSITE/_tools/taalparen.tsv"

rm -f "$PROEFSITE/_tools/taalonderdelen.py"
bouw_bron; bouw_thema_met_body
zaak    "7g wel een tabel, geen taalonderdelen.py: WEIGEREN, niet stil overslaan" 3
verwacht "  en zegt dat het gereedschap vastliep" "taalonderdelen.py liep vast"
verwacht "  en dat hij niets aanraakte" "Niets aangeraakt"
onaangeraakt "  en het vorige boek staat er nog"

echo ""
if [ "$gezakt" = "0" ]; then
  echo "$getoetst zaken getoetst, alles groen."
  exit 0
fi
echo "$getoetst zaken getoetst, $gezakt GEZAKT."
exit 1
