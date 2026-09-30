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
rm -f "$PROEFSITE/_tools/doorstuurders.py" "$PROEFSITE/_tools/doorstuurders.tsv"

echo ""
if [ "$gezakt" = "0" ]; then
  echo "$getoetst zaken getoetst, alles groen."
  exit 0
fi
echo "$getoetst zaken getoetst, $gezakt GEZAKT."
exit 1
