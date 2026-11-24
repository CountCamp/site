#!/usr/bin/env bash
# ============================================================
# namenwacht_test.sh — bijtproef voor _tools/namenwacht.py en zijn bedrading.
#
#   bash _tools/tests/namenwacht_test.sh
#   GEREEDSCHAP=<map met een kreupele namenwacht.py> bash _tools/tests/namenwacht_test.sh
#   NAAR_BUITEN=<kreupele naar_buiten.sh> bash _tools/tests/namenwacht_test.sh
#   PUBLISH=<kreupele publish.yml>  PROEFDRUK=<kreupele proefdruk.yml>
#                                         (die vier gebruikt namenwacht_mutatieproef.sh)
#
# Ben, 23-11-2026: "Site + speeltjes schoonmaken" -- geen voornaam van een
# testlezer in een bestand van deze openbare repo, en een wachter erop. Wat deze
# toets eist, in vijf delen:
#
#   A. DE WACHTER BIJT. In een wegwerprepo (git init in /tmp) wordt een naam
#      geplant op elke plek waar hij zich kan verstoppen: in hoofdletters, midden
#      in een woord, in een bestandsnaam, in een zip, in een gzip (zo zit een
#      .RData in elkaar), in een pdf-stroom en in een png-tekststuk. Elke keer
#      moet de wacht afloop 1 geven. En zijn uitvoer mag de naam NIET noemen
#      (hij draait in de openbare logboeken van de Actions).
#   B. HIJ ZEGT NIET "SCHOON" ALS HIJ NIET KEEK. Geen git, nul bestanden, een
#      bestand dat git kent maar dat weg is, een kapotte zip, een uitzondering
#      zonder reden of zonder lijst: afloop 3, nooit 0.
#   C. DE UITZONDERINGEN DOEN PRECIES WAT ZE ZEGGEN. Een map dekt wat eronder
#      staat en niets ernaast; een uitzondering waar niets onder valt, noemt hij.
#   D. DE PROEF "ALLEEN COMMENTAAR". `vergelijk` geeft 0 als alleen commentaar
#      veranderde en 1 bij een veranderde regel code, CSS, zichtbare tekst of
#      Python.
#   E. DE BEDRADING. publish.yml en proefdruk.yml draaien hem vóór de bouw;
#      naar_buiten.sh --nakijken en --productie houden tegen, en dat is ook echt
#      geproefd: --nakijken in een nagemaakte repo met een geplante naam is rood.
#
# De namen staan hier, net als in de wachter, in ROT13 -- en met opzet in een
# EIGEN kopie: haalt iemand een naam uit de lijst van de wachter, dan merkt deze
# toets dat (een toets die zijn namen uit de wachter leest, merkt het nooit).
# Afloop: 0 alles goed, 1 minstens één zaak zakt.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
REPO="$(pwd)"
GEREEDSCHAP="${GEREEDSCHAP:-_tools}"
NAAR_BUITEN="${NAAR_BUITEN:-_tools/naar_buiten.sh}"
PUBLISH="${PUBLISH:-.github/workflows/publish.yml}"
PROEFDRUK="${PROEFDRUK:-.github/workflows/proefdruk.yml}"
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
gezakt=0
getoetst=0

N1="$(python3 -c 'import codecs; print(codecs.decode("wrnaar", "rot13"))')"
N2="$(python3 -c 'import codecs; print(codecs.decode("zvpuryyr", "rot13"))')"
export N1 N2

zaak() {  # $1 = naam, $2 = verwachte afloopcode, $3.. = commando
  local naam="$1" verwacht="$2"; shift 2
  getoetst=$((getoetst + 1))
  "$@" > "$M/uit" 2>&1
  local echt=$?
  if [ "$echt" = "$verwacht" ]; then
    echo "  ok    $naam (afloopcode $echt)"
  else
    echo "  ZAKT  $naam — verwacht afloopcode $verwacht, kreeg $echt"
    sed 's/^/          /' "$M/uit" | tail -15
    gezakt=$((gezakt + 1))
  fi
}

in_uitvoer() {  # $1 = naam, $2 = tekst die in de laatste `zaak`-uitvoer moet staan
  getoetst=$((getoetst + 1))
  if command grep -qF -- "$2" "$M/uit"; then
    echo "  ok    $1"
  else
    echo "  ZAKT  $1 — '$2' staat niet in de uitvoer"
    sed 's/^/          /' "$M/uit" | tail -10
    gezakt=$((gezakt + 1))
  fi
}

niet_in_uitvoer_naam() {  # $1 = naam van de zaak; geen van de twee namen in de uitvoer
  getoetst=$((getoetst + 1))
  if command grep -qi -e "$N1" -e "$N2" "$M/uit"; then
    echo "  ZAKT  $1 — de uitvoer noemt de naam"
    gezakt=$((gezakt + 1))
  else
    echo "  ok    $1"
  fi
}

waar() {  # $1 = naam, $2.. = commando dat 0 moet geven
  local naam="$1"; shift
  getoetst=$((getoetst + 1))
  if "$@" > "$M/waar" 2>&1; then
    echo "  ok    $naam"
  else
    echo "  ZAKT  $naam"
    sed 's/^/          /' "$M/waar" | tail -10
    gezakt=$((gezakt + 1))
  fi
}

# Een wegwerprepo: _tools/ met de wachter (uit GEREEDSCHAP) en een lege
# uitzonderingenlijst, één schoon bestand, alles gecommit.
G() { git -C "$1" -c user.name=toets -c user.email=toets@voorbeeld -c core.hooksPath=/dev/null -c commit.gpgsign=false "${@:2}"; }
proefrepo() {  # $1 = naam -> pad
  local r="$M/$1"
  mkdir -p "$r/_tools"
  cp "$GEREEDSCHAP/namenwacht.py" "$r/_tools/"
  printf '# leeg\n' > "$r/_tools/namenwacht_uitzonderingen.tsv"
  printf 'een gewone bladzij, met een testlezer erin\n' > "$r/index.md"
  git init -q "$r"
  G "$r" add -A && G "$r" commit -q -m begin
  echo "$r"
}
plant() {  # $1 = repo, $2 = pad, $3 = soort (tekst|zip|gzip|pdf|png), $4 = tekst ($N1/$N2 erin)
  python3 - "$1/$2" "$3" "$4" <<'PY'
import gzip, io, os, sys, zipfile, zlib
pad, soort, tekst = sys.argv[1], sys.argv[2], sys.argv[3].encode()
os.makedirs(os.path.dirname(pad), exist_ok=True)
if soort == "tekst":
    b = tekst
elif soort == "zip":
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("data/lees.txt", tekst * 3)
    b = buf.getvalue()
elif soort == "gzip":
    b = gzip.compress(b"RDX3\n" + tekst * 3)
elif soort in ("pdf-stroom", "pdf-tekst"):
    # Een echte, kleine pdf (pdftotext moet hem kunnen lezen, anders is hij terecht
    # BLIND). pdf-stroom: de naam staat alleen in een losse gecomprimeerde stroom die
    # niet op de bladzij komt (alleen het uitpakken van stromen ziet hem).
    # pdf-tekst: de naam staat op de bladzij, maar als hex-tekst (<4A65...>), dus niet
    # in de ruwe bytes en niet in de uitgepakte stroom -- alleen pdftotext ziet hem.
    zichtbaar = tekst if soort == "pdf-tekst" else b"een gewone bladzij"
    inhoud = zlib.compress(b"BT /F1 12 Tf 10 50 Td <" + zichtbaar.hex().encode() + b"> Tj ET")
    objecten = [b"<< /Type /Catalog /Pages 2 0 R >>",
                b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
                b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 400 100] /Contents 4 0 R "
                b"/Resources << /Font << /F1 5 0 R >> >> >>",
                b"<< /Length %d /Filter /FlateDecode >>\nstream\n" % len(inhoud) + inhoud + b"\nendstream",
                b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"]
    if soort == "pdf-stroom":
        los = zlib.compress(b"bijlage: " + tekst)
        objecten.append(b"<< /Length %d /Filter /FlateDecode >>\nstream\n" % len(los) + los + b"\nendstream")
    b = b"%PDF-1.4\n"
    plekken = []
    for i, o in enumerate(objecten, 1):
        plekken.append(len(b))
        b += b"%d 0 obj\n" % i + o + b"\nendobj\n"
    xref = len(b)
    b += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objecten) + 1)
    b += b"".join(b"%010d 00000 n \n" % p for p in plekken)
    b += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objecten) + 1, xref)
elif soort == "entiteit":
    # De naam op de plek van @, met zijn tweede letter als HTML-entiteit (&#NN;):
    # zo stond hij in de kop van de wachter zelf (nakijker, 24-11).
    naam = os.environ["N1"].encode()
    b = tekst.replace(b"@", naam[:1] + b"&#%d;" % naam[1] + naam[2:])
elif soort == "base64":
    import base64
    svg = b"<svg xmlns='http://www.w3.org/2000/svg'><!-- " + tekst + b" --></svg>"
    b = b"<img src=\"data:image/svg+xml;base64," + base64.b64encode(svg) + b"\">\n"
elif soort == "gzipgzip":
    b = gzip.compress(gzip.compress(b"binnenste laag: " + tekst))
elif soort == "png":
    def stuk(s, d):
        return len(d).to_bytes(4, "big") + s + d + zlib.crc32(s + d).to_bytes(4, "big")
    b = (b"\x89PNG\r\n\x1a\n" + stuk(b"IHDR", bytes(13))
         + stuk(b"zTXt", b"Comment\x00\x00" + zlib.compress(tekst)) + stuk(b"IEND", b""))
else:
    sys.exit("onbekende soort " + soort)
if soort != "tekst":
    for n in (os.environ["N1"], os.environ["N2"]):
        assert n.lower().encode() not in b.lower(), "de naam staat ook rauw in het %s-bestand" % soort
open(pad, "wb").write(b)
PY
  # Een plantje dat niet lukt, is een toets die niets meet: hardop zakken, niet
  # verder met een repo waarin niets geplant staat (zo bleef A7 eerst groen-ogend).
  if [ $? -ne 0 ]; then
    echo "  ZAKT  plantje $2 ($3) lukte niet -- de zaak hierna meet niets"
    gezakt=$((gezakt + 1)); return 1
  fi
  G "$1" add -A && G "$1" commit -q -m "plant $2"
}
wacht() { python3 -B "$1/_tools/namenwacht.py" "${@:2}"; }

echo "namenwacht_test — bijt de namenwacht, en is hij bedraad?"

# ---------------------------------------------------------------- A ----
echo "== A. de wachter bijt"
R="$(proefrepo schoon)"
zaak "A1 een schone repo: schoon" 0 wacht "$R"
in_uitvoer "A1 en hij zegt hoeveel hij las (3 bestanden)" "3 bestanden gelezen"
in_uitvoer "A1 en hij noemt het oordeel" "SCHOON"

for geval in \
  "A2 de naam gewoon, in een notitie|notitie.md|tekst|Volgens $N1 was dit onduidelijk." \
  "A3 de naam in hoofdletters|LEESMIJ.txt|tekst|$(printf '%s' "$N2" | tr a-z A-Z) LAS HET ANDERS" \
  "A4 de naam midden in een woord|code.js|tekst|var x = 1; // zie ronde_${N1}_2" \
  "A5 de naam in een zip (een gegevensbestand)|data/bron.zip|zip|leesronde: $N2 zag het" \
  "A6 de naam in een gzip (zo zit een .RData in elkaar)|data/slaap.RData|gzip|label $N1" \
  "A7 de naam in een losse pdf-stroom|tabellen/blad.pdf|pdf-stroom|met dank aan $N2" \
  "A7b de naam als tekst op een pdf-bladzij (alleen pdftotext ziet hem)|tabellen/tekst.pdf|pdf-tekst|met dank aan $N1" \
  "A8 de naam in een png-tekststuk|images/kiek.png|png|schermafdruk van $N1" \
  "A12 de naam met een letter als HTML-entiteit|speeltjes/s.html|entiteit|<!-- ronde 2: @ las het anders -->" \
  "A13 de naam in een ingebakken svg (base64)|speeltjes/b.html|base64|lezersronde: $N2" \
  "A14 de naam in een gzip in een gzip|data/dubbel.gz|gzipgzip|$N1"
do
  IFS='|' read -r naam pad soort tekst <<< "$geval"
  R="$(proefrepo "a$getoetst")"
  plant "$R" "$pad" "$soort" "$tekst"
  zaak "$naam: rood" 1 wacht "$R"
  niet_in_uitvoer_naam "$naam: en de uitvoer noemt de naam niet"
done
R="$(proefrepo pad)"
plant "$R" "verslagen/ronde_${N2}.md" tekst "niets bijzonders"
zaak "A9 de naam in een bestandsnaam: rood" 1 wacht "$R"
niet_in_uitvoer_naam "A9 en de uitvoer noemt hem niet, ook niet in het pad"
in_uitvoer "A9 en hij wijst de regel aan, gemaskeerd" "<naam2>"
zaak "A10 met --toon staat de naam er wel (alleen hier op de machine)" 1 wacht "$R" --toon
in_uitvoer "A10 en dan voluit" "$N2"
R="$(proefrepo nietingit)"
printf 'kladje van %s\n' "$N1" > "$R/kladje.txt"
printf 'kladje.txt\n' > "$R/.gitignore"; G "$R" add .gitignore && G "$R" commit -q -m ignore
zaak "A11 een naam in een bestand dat git niet kent, telt niet (niet openbaar)" 0 wacht "$R"

# ---------------------------------------------------------------- B ----
echo "== B. niet gekeken is niet schoon"
mkdir -p "$M/geengit/_tools"; cp "$GEREEDSCHAP/namenwacht.py" "$M/geengit/_tools/"
printf '# leeg\n' > "$M/geengit/_tools/namenwacht_uitzonderingen.tsv"
zaak "B1 geen git-repo: blind" 3 wacht "$M/geengit"
mkdir -p "$M/leeg/_tools"; cp "$GEREEDSCHAP/namenwacht.py" "$M/leeg/_tools/"
printf '# leeg\n' > "$M/leeg/_tools/namenwacht_uitzonderingen.tsv"; git init -q "$M/leeg"
zaak "B2 git kent nul bestanden: blind" 3 wacht "$M/leeg"
R="$(proefrepo weg)"; rm "$R/index.md"
zaak "B3 een bestand dat git kent, is weg van schijf: blind" 3 wacht "$R"
in_uitvoer "B3 en hij noemt het" "index.md"
R="$(proefrepo kapotzip)"; printf 'PK\003\004 dit is geen zip' > "$R/kapot.zip"
G "$R" add -A && G "$R" commit -q -m kapot
zaak "B4 een zip die niet open gaat: blind" 3 wacht "$R"
R="$(proefrepo zonderreden)"; printf 'map/\ttijdelijk\t\n' > "$R/_tools/namenwacht_uitzonderingen.tsv"
zaak "B5 een uitzondering zonder reden: blind" 3 wacht "$R"
R="$(proefrepo kortereden)"; printf 'map/\ttijdelijk\tmag\n' > "$R/_tools/namenwacht_uitzonderingen.tsv"
zaak "B6 een uitzondering met een reden van één woord: blind" 3 wacht "$R"
R="$(proefrepo verkeerdesoort)"
printf 'map/\taltijd\tdit is een reden van voldoende lengte\n' > "$R/_tools/namenwacht_uitzonderingen.tsv"
zaak "B7 een uitzondering met een onbekende soort: blind" 3 wacht "$R"
R="$(proefrepo geenlijst)"; rm "$R/_tools/namenwacht_uitzonderingen.tsv"
zaak "B8 geen uitzonderingenlijst: blind" 3 wacht "$R"
# Een BLIND-melding noemt het pad, en dat pad kan de naam dragen. Hier houdt alleen
# de buitenste laag van het masker (zeg() in de wachter) hem tegen.
R="$(proefrepo blindpad)"
plant "$R" "verslagen/${N1}_ronde2.md" tekst "niets bijzonders"; rm "$R/verslagen/${N1}_ronde2.md"
zaak "B9 een bestand met de naam in zijn pad is weg van schijf: blind" 3 wacht "$R"
niet_in_uitvoer_naam "B9 en de BLIND-melding noemt de naam niet"
# Zonder pdftotext kan hij de tekst van een pdf niet lezen: dan is dat niet gekeken.
# (Zo is het op de GitHub-runner, tenzij de workflow hem eerst installeert.)
R="$(proefrepo zonderpdftotext)"
plant "$R" "tabellen/blad.pdf" pdf-tekst "een gewone tabel"
# Een PATH met alleen git erin (git kan in dezelfde map staan als pdftotext).
PY_VOL="$(command -v python3)"; mkdir -p "$M/alleen_git"; ln -sf "$(command -v git)" "$M/alleen_git/git"
zaak "B10 een pdf in de repo en geen pdftotext: blind" 3 \
  env PATH="$M/alleen_git:/usr/bin:/bin" "$PY_VOL" -B "$R/_tools/namenwacht.py"
in_uitvoer "B10 en hij zegt waarom" "pdftotext ontbreekt"
zaak "B10 dezelfde repo mét pdftotext: schoon (het lag dus aan pdftotext)" 0 wacht "$R"
# Een Turkse İ in de naam, naast een gewone treffer op dezelfde regel: het masker
# mag niet afbreken (zo brak het op 24-11: .lower() maakt van İ twee tekens).
R="$(proefrepo turks)"
TURKS="$(python3 -c 'import os; n=os.environ["N2"]; print(n[:1].upper() + "İ" + n[2:].upper())')"
plant "$R" "notitie.md" tekst "$N2 en $TURKS lazen het allebei"
zaak "B11 een Turkse İ naast een echte treffer: rood, niet afgebroken" 1 wacht "$R"
niet_in_uitvoer_naam "B11 en de naam staat er niet in"
getoetst=$((getoetst + 1))
if command grep -q "Traceback" "$M/uit"; then
  echo "  ZAKT  B11 het masker brak af (Traceback)"; gezakt=$((gezakt + 1))
else
  echo "  ok    B11 zonder Traceback"
fi

# ---------------------------------------------------------------- C ----
echo "== C. de uitzonderingen"
R="$(proefrepo uitz)"
plant "$R" "boeken/ts/thema.css" tekst "/* $N1 zag het */"
plant "$R" "boeken/tsx/thema.css" tekst "/* $N2 zag het */"
printf 'boeken/ts/\ttijdelijk\teen ander spoor perst deze map nu; daarna schoonmaken\nleeg/\tblijvend\tdeze map bestaat niet, dus hier valt niets onder\n' \
  > "$R/_tools/namenwacht_uitzonderingen.tsv"
zaak "C1 een naam naast de uitgezonderde map (boeken/tsx/ naast boeken/ts/): rood" 1 wacht "$R"
in_uitvoer "C1 en de map zelf staat als toegestaan, met hoe vaak" "toegestaan (tijdelijk, uitzondering r1): boeken/ts/"
in_uitvoer "C2 een uitzondering waar niets onder valt, noemt hij" "UITZONDERING ZONDER TREFFER (r2, mag weg): leeg/"
G "$R" rm -q boeken/tsx/thema.css && G "$R" commit -q -m weg
zaak "C3 alleen nog de naam onder de uitzondering: schoon" 0 wacht "$R"
printf 'boeken/ts/thema.css\tblijvend\tprecies dit ene bestand, en verder niets eronder\n' \
  > "$R/_tools/namenwacht_uitzonderingen.tsv"
plant "$R" "boeken/ts/thema.css.bak" tekst "$N2"
zaak "C4 een uitzondering op één bestand dekt geen bestand dat met dezelfde naam begint" 1 wacht "$R"

# ---------------------------------------------------------------- D ----
echo "== D. vergelijk: alleen commentaar veranderd?"
R="$(proefrepo vgl)"
plant "$R" "s.html" tekst "$(printf '<p>zichtbaar</p>\n<!-- %s las dit -->\n<script>\n// %s zag het\nvar a = 1; /* x */\n</script>\n<style>\n/* %s */\np { color: red; }\n</style>\n' "$N1" "$N2" "$N1")"
plant "$R" "s.py" tekst "$(printf '"""kop met %s"""\n# %s\nx = 1  # staart\n' "$N1" "$N2")"
plant "$R" "s.md" tekst "$N1 vond het"
python3 - "$R" <<'PY'
import os, sys
r = sys.argv[1]
def zet(p, oud, nieuw):
    s = open(os.path.join(r, p), encoding="utf-8").read()
    assert s.count(oud) == 1, (p, oud)
    open(os.path.join(r, p), "w", encoding="utf-8").write(s.replace(oud, nieuw))
n1, n2 = os.environ["N1"], os.environ["N2"]
zet("s.html", "<!-- %s las dit -->" % n1, "<!-- een testlezer las dit -->")
zet("s.html", "// %s zag het" % n2, "// een testlezer zag het")
zet("s.html", "/* %s */" % n1, "/* een testlezer */")
zet("s.py", '"""kop met %s"""' % n1, '"""kop met een testlezer"""')
zet("s.py", "# %s" % n2, "# een testlezer")
zet("s.md", n1, "Een testlezer")
PY
zaak "D1 alleen commentaar, docstring en notitie veranderd: 0" 0 wacht "$R" vergelijk HEAD
in_uitvoer "D1 en hij zegt het" "ALLEEN COMMENTAAR"
for geval in \
  "D2 een regel JavaScript|s.html|var a = 1;|var a = 2;" \
  "D3 een CSS-regel|s.html|color: red;|color: blue;" \
  "D4 zichtbare tekst|s.html|<p>zichtbaar</p>|<p>anders</p>" \
  "D5 Python-code|s.py|x = 1|x = 2" \
  "D6 code naast commentaar op één regel|s.html|var a = 1; /* x */|var a = 3; /* y */"
do
  IFS='|' read -r naam pad oud nieuw <<< "$geval"
  cp "$R/$pad" "$M/bewaar"
  python3 - "$R/$pad" "$oud" "$nieuw" <<'PY'
import sys
p, oud, nieuw = sys.argv[1:4]
s = open(p, encoding="utf-8").read(); assert s.count(oud) == 1, oud
open(p, "w", encoding="utf-8").write(s.replace(oud, nieuw))
PY
  zaak "$naam veranderd: 1" 1 wacht "$R" vergelijk HEAD
  cp "$M/bewaar" "$R/$pad"
done
# Binaire bestanden: een nieuw plaatje is geen codewijziging en mag de vergelijking
# niet laten crashen (zo crashte hij op 24-11 op een png uit de ts_pers-merge); een
# VERANDERD binair bestand kan hij niet vergelijken, en dat is blind, niet "code".
printf '\211PNG\r\n\032\n\000\000\000\000IEND\256B`\202\377\376' > "$R/nieuw.png"; G "$R" add nieuw.png
zaak "D7 een nieuw binair bestand erbij: nog steeds alleen commentaar" 0 wacht "$R" vergelijk HEAD
G "$R" commit -q -m "plaatje" -- nieuw.png
printf '\211PNG\r\n\032\n\000\001\377\376 anders' > "$R/nieuw.png"
zaak "D8 een veranderd binair bestand: niet te vergelijken, dus blind" 3 wacht "$R" vergelijk HEAD
G "$R" checkout -q -- nieuw.png
cp "$R/s.html" "$M/bewaar"
python3 - "$R/s.html" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(s.replace("var a = 1;", "var a = 9;"))
PY
zaak "D9 met paden: alleen die bestanden (s.html met een codewijziging valt erbuiten)" 0 wacht "$R" vergelijk HEAD s.md s.py
zaak "D9 en zonder paden ziet hij die codewijziging wel" 1 wacht "$R" vergelijk HEAD
cp "$M/bewaar" "$R/s.html"

# ---------------------------------------------------------------- E ----
echo "== E. de bedrading"
zaak "E1 deze repo zelf: schoon (op de uitzonderingen na)" 0 python3 -B "$GEREEDSCHAP/namenwacht.py" --repo "$REPO"
waar "E2 publish.yml: Namenwacht vóór Render, en hij draait de wachter" python3 - "$PUBLISH" <<'PY'
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
namen = re.findall(r"^      - name: (.+)$", t, re.M)
if "Namenwacht" not in namen or "Render" not in namen:
    sys.exit("stappen: %s" % namen)
if not namen.index("Namenwacht") < namen.index("Render"):
    sys.exit("volgorde: %s" % namen)
blok = t.split("- name: Namenwacht", 1)[1].split("- name:", 1)[0]
if not re.search(r"^        run: python3 _tools/namenwacht\.py\s*$", blok, re.M):
    sys.exit("de stap draait de wachter niet (of met een vlag): %r" % blok[-200:])
if "continue-on-error" in blok:
    sys.exit("continue-on-error: dan houdt hij niets tegen")
# pdftotext moet er zijn vóór de wacht, anders is elke pdf blind (en de wacht rood).
pdf = next((i for i, n in enumerate(namen) if "pdftotext" in n), None)
if pdf is None or not pdf < namen.index("Namenwacht") or "poppler-utils" not in t.split("- name: " + namen[pdf], 1)[1].split("- name:", 1)[0]:
    sys.exit("geen stap die pdftotext (poppler-utils) installeert vóór de Namenwacht: %s" % namen)
PY
waar "E3 proefdruk.yml: Namenwacht vóór het bouwen" python3 - "$PROEFDRUK" <<'PY'
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
namen = re.findall(r"^      - name: (.+)$", t, re.M)
bouw = next((i for i, n in enumerate(namen) if n.startswith("Bouwen")), None)
if "Namenwacht" not in namen or bouw is None or not namen.index("Namenwacht") < bouw:
    sys.exit("stappen: %s" % namen)
blok = t.split("- name: Namenwacht", 1)[1].split("- name:", 1)[0]
if not re.search(r"^        run: python3 _tools/namenwacht\.py\s*$", blok, re.M) or "continue-on-error" in blok:
    sys.exit("de stap draait de wachter niet, of laat hem niet tegenhouden")
pdf = next((i for i, n in enumerate(namen) if "pdftotext" in n), None)
if pdf is None or not pdf < namen.index("Namenwacht") or "poppler-utils" not in t.split("- name: " + namen[pdf], 1)[1].split("- name:", 1)[0]:
    sys.exit("geen stap die pdftotext (poppler-utils) installeert vóór de Namenwacht: %s" % namen)
PY
waar "E4 naar_buiten.sh: --nakijken en --productie blokkerend (vóór de push), --lokaal en --proefdruk meldend" \
  python3 - "$NAAR_BUITEN" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
def tak(naam):
    m = re.search(r"^%s\)\n(.*?)^  ;;" % re.escape(naam), s, re.S | re.M)
    return m.group(1) if m else ""
fout = []
prod = tak("--productie")
a, b = prod.find("namen_nakijken blokkerend origin/main..main"), prod.find("doe git push origin main")
f_ = prod.find("git fetch --quiet origin main")
if a < 0 or b < 0 or a > b:
    fout.append("--productie: wacht (met de berichten origin/main..main) op %d, push op %d" % (a, b))
elif "exit 1" not in prod[a:prod.find("\n", a)]:
    fout.append("--productie stopt niet als de namenpoort rood is")
elif f_ < 0 or f_ > a:
    fout.append("--productie: de namenpoort draait vóór de fetch, dus op een oude origin/main")
nak = tak("--nakijken")
if not re.search(r'namen_nakijken\s+blokkerend "\$\(nog_te_pushen\)" \|\| code=1', nak):
    fout.append("--nakijken roept de namenpoort niet blokkerend aan (met de berichten)")
for t in ("--lokaal", "--proefdruk"):
    if 'namen_nakijken melden "$(nog_te_pushen)"' not in tak(t):
        fout.append("%s roept de namenpoort niet (meldend) aan" % t)
f = s.split("namen_nakijken() {", 1)[-1].split("\n}\n", 1)[0]
if 'if [ "$streng" = blokkerend ]; then return 1; fi' not in f:
    fout.append("de namenpoort houdt nooit tegen")
if 'namenwacht.py" --bereik "$bereik"' not in f:
    fout.append("de namenpoort leest de commitberichten niet")
sys.exit("; ".join(fout) if fout else 0)
PY

# En echt geproefd: --nakijken in een nagemaakte repo, met de vier andere poorten
# nagemaakt en groen (die hebben hun eigen toetsen), en de echte namenwacht.
nep_pers() {  # $1 = naam -> een proefrepo met naar_buiten.sh erbij
  local r; r="$(proefrepo "$1")"
  cp "$NAAR_BUITEN" "$r/_tools/naar_buiten.sh"
  printf 'print("plankwacht - nagemaakt, alles in orde")\n'    > "$r/_tools/plankwacht.py"
  printf 'print("tellers - nagemaakt, alles in orde")\n'       > "$r/_tools/controleer_tellers.py"
  printf 'print("doorstuurders - nagemaakt, alles in orde")\n' > "$r/_tools/doorstuurders.py"
  printf 'print("  losse bladzijden: 0 nagelopen, 0 gat(en) - nagemaakt")\n' > "$r/_tools/taalonderdelen.py"
  G "$r" add -A && G "$r" commit -q -m pers
  echo "$r"
}
R="$(nep_pers persgroen)"
zaak "E5 naar_buiten.sh --nakijken, geen naam: groen" 0 bash "$R/_tools/naar_buiten.sh" --nakijken
in_uitvoer "E5 en de namenpoort liep echt" "SCHOON"
in_uitvoer "E5 en zonder origin/main zegt hij dat berichten en tussenversies niet gelezen zijn" "niet nagelezen, alleen de bestanden"
R="$(nep_pers persrood)"
plant "$R" "speeltjes/ding.html" tekst "<script>// $N1, ronde 2</script>"
zaak "E6 naar_buiten.sh --nakijken, een naam in een speeltje: rood" 1 bash "$R/_tools/naar_buiten.sh" --nakijken
in_uitvoer "E6 en hij zegt waarom" "Er staat een testlezer-naam in een bestand van deze openbare repo."
niet_in_uitvoer_naam "E6 en ook de pers noemt de naam niet"

# Commitberichten: openbaar zodra ze gepusht zijn.
R="$(proefrepo berichten)"
G "$R" commit -q --allow-empty -m "oud: $N1 las het (staat al op GitHub)"
G "$R" update-ref refs/remotes/origin/main HEAD
G "$R" commit -q --allow-empty -m "nieuw werk" -m "lezersronde 2: $N2 struikelde"
zaak "E7 een naam in een commitbericht dat nog gepusht moet worden: rood" 1 wacht "$R" --bereik origin/main..HEAD
in_uitvoer "E7 en hij wijst het bericht aan, gemaskeerd" "commitbericht"
niet_in_uitvoer_naam "E7 en noemt de naam niet"
zaak "E8 de naam in een bericht dat al op origin/main staat, telt niet (geschiedenis)" 0 \
  wacht "$R" --bereik origin/main..origin/main
zaak "E9 een bereik dat git niet kent: blind" 3 wacht "$R" --bereik bestaatniet..HEAD
R="$(nep_pers persbericht)"
G "$R" update-ref refs/remotes/origin/main HEAD
G "$R" commit -q --allow-empty -m "speeltje bijgewerkt na $N1"
zaak "E10 naar_buiten.sh --nakijken, een naam in een nog niet gepusht bericht: rood" 1 bash "$R/_tools/naar_buiten.sh" --nakijken
niet_in_uitvoer_naam "E10 en de pers noemt de naam niet"

# Tussenversies: een push publiceert elke commit, niet alleen de top. Een naam die
# op de tak in een tussenversie stond en daarna weer weg is, gaat bij een gewone
# merge tóch mee (zo stond hij op 24-11 in een tussenversie van namenwacht.py zelf).
R="$(proefrepo tussenversie)"
G "$R" update-ref refs/remotes/origin/main HEAD
plant "$R" "speeltjes/ding.html" tekst "<script>// $N2, ronde 2</script>"
plant "$R" "speeltjes/ding.html" tekst "<script>// een testlezer, lezersronde 2</script>"
zaak "E11 de top is schoon, zonder bereik: schoon" 0 wacht "$R"
zaak "E11 maar met het bereik: de tussenversie gaat mee met de push, rood" 1 wacht "$R" --bereik origin/main..HEAD
in_uitvoer "E11 en hij zegt dat het een tussenversie is, en wat je dan doet" "squash-merge"
niet_in_uitvoer_naam "E11 en noemt de naam niet"
G "$R" update-ref refs/remotes/origin/main HEAD
zaak "E12 staat die tussenversie al op origin/main (geschiedenis): telt niet" 0 wacht "$R" --bereik origin/main..HEAD
# Een squash-merge brengt alleen de eindstand mee.
R="$(proefrepo squash)"
G "$R" update-ref refs/remotes/origin/main HEAD
G "$R" checkout -q -b werk
plant "$R" "speeltjes/ding.html" tekst "<script>// $N1, ronde 2</script>"
plant "$R" "speeltjes/ding.html" tekst "<script>// een testlezer, lezersronde 2</script>"
G "$R" checkout -q -B lever origin/main
G "$R" merge -q --squash werk > /dev/null && G "$R" commit -q -m "werk, in één commit"
zaak "E13 dezelfde tak als squash-merge: schoon" 0 wacht "$R" --bereik origin/main..HEAD

echo
echo "$getoetst zaken, $gezakt gezakt"
[ "$gezakt" -eq 0 ]
