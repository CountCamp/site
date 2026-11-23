#!/usr/bin/env bash
# ============================================================
# commentaar_test.sh — bijtproef voor het commentaarfilter en de commentaarwacht.
#
#   bash _tools/tests/commentaar_test.sh
#   GEREEDSCHAP=<kreupele kopie van _tools> bash _tools/tests/commentaar_test.sh   # mutatieproef
#
# Ben, 23-11-2026: HTML-commentaar "uit de pagina halen vóór publiceren (alle
# boeken)". Wat deze toets eist, in vier delen:
#
#   A. EEN WEGWERPBOUW. Een klein Quarto-project in /tmp dat zijn post-render en
#      zijn strip-comments OVERNEEMT UIT DE ECHTE _quarto.yml -- haalt iemand het
#      filter daar weg, dan zakt deel A vanzelf. Erin geplant: een
#      <!-- MIEKE: … --> in de .qmd, een <!-- bron: hand-out college 4 --> in een
#      ```{=html}-blok (daar komt strip-comments niet bij, gemeten op 1.9.38, dus
#      alleen het filter kan hem vangen), en dezelfde twee in een kant-en-klare
#      bijlage zoals een boekbladzij binnenkomt. Moet blijven: een "<!--" in een
#      <script>, een codeblok dat een commentaar TOONT, de boekstempel, en de
#      teller (de tellerwacht moet erna groen staan).
#   B. DE WACHTER BIJT. In een kopie van die bouw wordt NA de bouw geplant -- het
#      filter ziet het dus niet -- en de wachter moet rood worden, met bestand,
#      regel en de eerste 80 tekens. Ook diep in een boekmap en in search.json.
#      Leeg of onleesbaar is afloop 3, nooit 0.
#   C. ECHTE BLADZIJDEN. manuscript/h4.html en speeltjes/solomon.html uit deze
#      repo door het filter: de commentaren weg, en volgens html.parser (een
#      ándere ontleder) verder geen enkel verschil. Een tweede run: geen byte.
#   D. DE BEDRADING. publish.yml draait de wachter na de bouw en vóór het
#      publiceren, proefdruk.yml ook, naar_buiten.sh --productie vóór de push.
#
# Plus de ontleder geval voor geval: _tools/tests/commentaarregel_test.py.
# Afloop: 0 alles goed, 1 minstens één zaak zakt, 3 kon niet bouwen (geen quarto).
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
REPO="$(pwd)"
GEREEDSCHAP="${GEREEDSCHAP:-_tools}"
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
gezakt=0
getoetst=0

zaak() {  # $1 = naam, $2 = verwachte afloopcode, $3.. = commando
  local naam="$1" verwacht="$2"; shift 2
  getoetst=$((getoetst + 1))
  "$@" > "$M/uit" 2>&1
  local echt=$?
  if [ "$echt" = "$verwacht" ]; then
    echo "  ok    $naam (afloopcode $echt)"
  else
    echo "  ZAKT  $naam — verwacht afloopcode $verwacht, kreeg $echt"
    sed 's/^/          /' "$M/uit" | tail -25
    gezakt=$((gezakt + 1))
  fi
}

waar() {  # $1 = naam, $2.. = commando dat 0 moet geven; uitvoer bij zakken
  local naam="$1"; shift
  getoetst=$((getoetst + 1))
  if "$@" > "$M/waar" 2>&1; then
    echo "  ok    $naam"
  else
    echo "  ZAKT  $naam"
    sed 's/^/          /' "$M/waar" | tail -15
    gezakt=$((gezakt + 1))
  fi
}

in_uitvoer() {  # $1 = naam, $2 = tekst die in de laatste `zaak`-uitvoer moet staan
  getoetst=$((getoetst + 1))
  if command grep -qF -- "$2" "$M/uit"; then
    echo "  ok    $1"
  else
    echo "  ZAKT  $1 — '$2' staat niet in de uitvoer"
    gezakt=$((gezakt + 1))
  fi
}

heeft()     { command grep -qF -- "$2" "$1"; }          # bestand bevat tekst
heeft_niet() { ! command grep -qF -- "$2" "$1"; }

# Het gereedschap gaat mee, zodat de mutatieproef een kreupele kopie kan geven
# zonder het echte aan te raken.
G="$M/proef/_tools"
mkdir -p "$G"
cp "$GEREEDSCHAP"/*.py "$GEREEDSCHAP"/teller.html "$GEREEDSCHAP"/taalparen.tsv "$G/"
[ -d "$GEREEDSCHAP/taalwissel" ] && cp -R "$GEREEDSCHAP/taalwissel" "$G/"
wacht() { python3 -B "$G/commentaarwacht.py" "$@"; }
weg()   { python3 -B "$G/commentaar_weg.py" "$@"; }

echo "== 0. de ontleder, geval voor geval"
zaak "commentaarregel_test.py, op het gereedschap van deze proef" 0 \
  env GEREEDSCHAP="$G" python3 -B _tools/tests/commentaarregel_test.py

# ---------------------------------------------------------------- A ----
echo "== A. een wegwerpbouw, met de post-render en strip-comments uit de echte _quarto.yml"
python3 - "$REPO/_quarto.yml" "$M/proef/_quarto.yml" <<'PY'
import re, sys
echt = open(sys.argv[1], encoding="utf-8").read().splitlines()
# de post-render-lijst onder project:, regel voor regel zoals hij er staat
pr, i = [], next((k for k, r in enumerate(echt) if r.strip() == "post-render:"), None)
if i is not None:
    for r in echt[i + 1:]:
        if r.strip().startswith("#"):
            continue
        m = re.match(r"\s+-\s+(\S+)\s*$", r)
        if not m:
            break
        pr.append(m.group(1))
strip = [r.split(":", 1)[1].strip() for r in echt if r.strip().startswith("strip-comments:")]
print("uit de echte _quarto.yml: post-render %s, strip-comments %s" % (pr, strip or "(niet gezet)"))
regels = ["project:", "  type: website", "  output-dir: _site", "  render:", '    - "*.qmd"',
          "  resources:", '    - "boek/**"', "  post-render:"] + ["    - %s" % p for p in pr]
if strip:
    regels += ["format:", "  html:", "    strip-comments: %s" % strip[0]]
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(regels) + "\n")
PY
# Quarto weigert een profielbestand met alleen commentaar; dit doet verder niets.
printf 'website:\n  site-url: "https://example.org"\n' > "$M/proef/_quarto-echt.yml"

cat > "$M/proef/index.qmd" <<'QMD'
---
title: "Proef"
---

Tekst voor.

<!-- MIEKE: klopt deze vertaling nog? -->

```{=html}
<!-- bron: hand-out college 4 (2026-27), Leidens 4.0c -->
<script>var bewaar = "<!-- blijf in het script -->";</script>
```

```html
<!-- toon dit in het codeblok -->
```

Tekst na.
QMD

mkdir -p "$M/proef/boek"
HASH="$(printf 'proef' | shasum -a 256 | cut -d' ' -f1)"
STEMPEL="<!-- countcamp-publicatie H1 bron-hash=$HASH geleverd=2026-11-23T10:00:00 -->"
cat > "$M/proef/boek/h1.html" <<HTML
<!doctype html>
<html lang="nl"><head><meta charset="utf-8"><title>h1</title></head>
<body>
<!-- MIEKE: in een bijlage, zoals een boekbladzij binnenkomt -->
<p>Een bijlage.</p>
<!-- bron: hand-out college 4 -->
</body>
</html>
$STEMPEL
HTML

if ! command -v quarto >/dev/null 2>&1; then
  echo "  KON NIET BOUWEN — quarto staat niet op het pad"; exit 3
fi
( cd "$M/proef" && LANG=en_US.UTF-8 QUARTO_PROFILE=echt quarto render ) > "$M/bouw.log" 2>&1
code=$?
getoetst=$((getoetst + 1))
if [ "$code" = 0 ] && [ -f "$M/proef/_site/index.html" ]; then
  echo "  ok    de wegwerpbouw slaagt (quarto $(quarto --version))"
else
  echo "  ZAKT  de wegwerpbouw (afloop $code):"; tail -15 "$M/bouw.log" | sed 's/^/          /'
  gezakt=$((gezakt + 1))
fi
S="$M/proef/_site"
command grep -h 'commentaar_weg:' "$M/bouw.log" | sed 's/^/        bouw: /'

waar "de MIEKE-notitie uit de .qmd is weg"                 heeft_niet "$S/index.html" "MIEKE"
waar "de bron in het {=html}-blok is weg (alleen het filter kan dat)" heeft_niet "$S/index.html" "hand-out college 4"
waar "het <!-- in het <script> staat er nog"               heeft "$S/index.html" '"<!-- blijf in het script -->"'
waar "het codeblok toont het commentaar nog"              heeft "$S/index.html" "toon dit in het codeblok"
waar "de MIEKE-notitie in de bijlage is weg"               heeft_niet "$S/boek/h1.html" "MIEKE"
waar "de bron in de bijlage is weg"                        heeft_niet "$S/boek/h1.html" "hand-out college 4"
waar "de boekstempel in de bijlage staat er nog, letterlijk" heeft "$S/boek/h1.html" "$STEMPEL"
waar "de teller staat in de bijlage, mét zijn merktekens"  heeft "$S/boek/h1.html" "<!-- teller:eind -->"
zaak "de wachter op de wegwerpbouw: schoon" 0 wacht --site "$S"
in_uitvoer "de wachter noemt wat hij toestond"  "lab-stempel"
zaak "de tellerwacht op de wegwerpbouw: groen (het filter liet de teller heel)" 0 \
  python3 -B "$G/tellerwacht.py" --echt --site "$S" --teller "$G/teller.html"
find "$S" -type f -exec shasum {} + | sort > "$M/voor.sha"
zaak "het filter nog eens over de bouw" 0 weg --site "$S"
in_uitvoer "de tweede ronde haalt niets meer weg" "0 commentaar/commentaren weg uit 0 bestand(en)"
find "$S" -type f -exec shasum {} + | sort > "$M/na.sha"
waar "na de tweede ronde is geen byte veranderd (idempotent)" cmp -s "$M/voor.sha" "$M/na.sha"

# ---------------------------------------------------------------- B ----
echo "== B. de wachter bijt op wat er NA de bouw in komt"
verse_kopie() { rm -rf "$M/geplant"; cp -R "$S" "$M/geplant"; }

verse_kopie
LANG_COMMENTAAR="<!-- MIEKE: geplant na de bouw $(printf 'x%.0s' $(seq 1 120)) -->"
python3 - "$M/geplant/index.html" "$LANG_COMMENTAAR" <<'PY'
import sys
p, c = sys.argv[1], sys.argv[2]
t = open(p, encoding="utf-8").read()
i = t.rfind("</body>")
open(p, "w", encoding="utf-8").write(t[:i] + c + "\n" + t[i:])
PY
REGEL="$(command grep -n -F 'MIEKE: geplant' "$M/geplant/index.html" | cut -d: -f1)"
zaak "geplant in index.html -> rood" 1 wacht --site "$M/geplant"
in_uitvoer "de vondst noemt bestand en regel" "index.html:$REGEL:"
in_uitvoer "de vondst toont de eerste 80 tekens" "$(printf '%s' "$LANG_COMMENTAAR" | cut -c1-80)"
getoetst=$((getoetst + 1))
if command grep -qF -- "$(printf '%s' "$LANG_COMMENTAAR" | cut -c1-81)" "$M/uit"; then
  echo "  ZAKT  de vondst toont meer dan 80 tekens"; gezakt=$((gezakt + 1))
else
  echo "  ok    de vondst toont niet meer dan 80 tekens"
fi

verse_kopie
mkdir -p "$M/geplant/oefenboeken/ts/05_effect"
printf '<!doctype html><html><head><meta charset="utf-8"></head><body>\n<p>x</p>\n<!-- bron: hand-out college 4 -->\n</body></html>\n' \
  > "$M/oefen.html"
cp "$M/oefen.html" "$M/geplant/oefenboeken/ts/05_effect/05_effect.html"
zaak "geplant diep in een boekmap -> rood" 1 wacht --site "$M/geplant"
in_uitvoer "de vondst noemt het pad in het boek" "oefenboeken/ts/05_effect/05_effect.html:3:"

verse_kopie
python3 - "$M/geplant/search.json" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
d.append({"objectID": "geplant", "href": "geplant.html", "title": "x",
          "text": "tekst <!-- MIEKE: in de zoekindex --> tekst"})
json.dump(d, open(p, "w", encoding="utf-8"))
PY
zaak "geplant in search.json -> rood" 1 wacht --site "$M/geplant"
in_uitvoer "de vondst noemt de zoekindex" "COMMENTAAR IN EEN ZOEKINDEX"

verse_kopie
python3 - "$M/geplant/index.html" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
i = t.rfind("</body>")
open(p, "w", encoding="utf-8").write(t[:i] + '<script>var y = "<!-- in een script, mag -->";</script>\n' + t[i:])
PY
zaak "een <!-- in een <script> -> schoon" 0 wacht --site "$M/geplant"
in_uitvoer "en de wachter zegt dat hij hem oversloeg" "in script"

verse_kopie
printf '\n<!-- countcamp-publicatie H1 bron-hash=abc geleverd=gisteren -->\n' >> "$M/geplant/boek/h1.html"
zaak "een HALVE stempel -> rood (alleen de precieze vorm mag)" 1 wacht --site "$M/geplant"

verse_kopie
printf '<p>\xff\xfe geen utf-8</p>\n' > "$M/geplant/kapot.html"
zaak "een bladzij die geen UTF-8 is -> kon niet kijken" 3 wacht --site "$M/geplant"

mkdir -p "$M/leeg"
zaak "een lege map -> kon niet kijken" 3 wacht --site "$M/leeg"
zaak "een map die niet bestaat -> kon niet kijken" 3 wacht --site "$M/bestaat-niet"
zaak "het filter op een lege map -> niets gezien" 3 weg --site "$M/leeg"

# ---------------------------------------------------------------- C ----
echo "== C. echte bladzijden uit deze repo"
mkdir -p "$M/echt_voor/manuscript" "$M/echt_voor/speeltjes"
cp manuscript/h4.html "$M/echt_voor/manuscript/"
cp speeltjes/solomon.html "$M/echt_voor/speeltjes/"
cp -R "$M/echt_voor" "$M/echt_na"
zaak "het filter over h4.html en solomon.html" 0 weg --site "$M/echt_na"
N_WEG="$(sed -n 's/.* -- \([0-9]*\) commentaar.*/\1/p' "$M/uit")"
getoetst=$((getoetst + 1))
if [ -n "$N_WEG" ] && [ "$N_WEG" -gt 0 ]; then
  echo "  ok    er ging echt iets weg ($N_WEG commentaren)"
else
  echo "  ZAKT  er ging niets weg -- dan toetst deel C niets"; gezakt=$((gezakt + 1))
fi
zaak "html.parser ziet buiten het commentaar geen enkel verschil" 0 \
  python3 -B _tools/tests/commentaar_gelijk.py "$M/echt_voor" "$M/echt_na"
zaak "de wachter op die twee: schoon" 0 wacht --site "$M/echt_na"

# ---------------------------------------------------------------- D ----
echo "== D. de bedrading"
waar "publish.yml: commentaarwacht na Render en Tellerwacht, vóór Publish" python3 - <<'PY'
import re, sys
t = open(".github/workflows/publish.yml", encoding="utf-8").read()
namen = re.findall(r"^      - name: (.+)$", t, re.M)
stap = {n: i for i, n in enumerate(namen)}
nodig = ["Render", "Tellerwacht", "Commentaarwacht"]
pub = next((i for n, i in stap.items() if n.startswith("Publish")), None)
if any(n not in stap for n in nodig) or pub is None:
    sys.exit("stappen in publish.yml: %s" % namen)
blok = t.split("- name: Commentaarwacht", 1)[1].split("- name:", 1)[0]
if "python3 _tools/commentaarwacht.py" not in blok:
    sys.exit("de stap Commentaarwacht draait de wachter niet")
if not (stap["Render"] < stap["Tellerwacht"] < stap["Commentaarwacht"] < pub):
    sys.exit("volgorde klopt niet: %s" % namen)
PY
waar "proefdruk.yml: draait de wachter" command grep -qF "python3 _tools/commentaarwacht.py" .github/workflows/proefdruk.yml
waar "naar_buiten.sh: --productie na de bouw blokkerend en vóór de push, --lokaal meldend" \
  python3 - "${NAAR_BUITEN:-_tools/naar_buiten.sh}" <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
def tak(naam):
    m = re.search(r"^%s\)\n(.*?)^  ;;" % re.escape(naam), s, re.S | re.M)
    return m.group(1) if m else ""
prod, lok = tak("--productie"), tak("--lokaal")
BOUW = "_tools/schone_bouw.py --uit _site -- render"
fout = []
r, a, b = prod.find(BOUW), prod.find("gebouwd_commentaar_nakijken blokkerend"), prod.find("doe git push origin main")
if a < 0 or r < 0 or b < 0 or not (r < a < b):
    fout.append("--productie: bouw op %d, wacht op %d, push op %d" % (r, a, b))
elif "exit 1" not in prod[a:prod.find("\n", a)]:
    # op DEZE regel; zie zaak 5g in naar_buiten_teller_test.sh voor waarom
    fout.append("--productie stopt niet als de commentaarpoort rood is")
r, a = lok.find(BOUW), lok.find("gebouwd_commentaar_nakijken melden")
if a < 0 or r < 0 or a < r:
    fout.append("--lokaal roept de commentaarpoort niet (meldend) na de bouw aan")
if "if [ \"$streng\" = blokkerend ]; then return 1; fi" not in s.split("gebouwd_commentaar_nakijken() {", 1)[-1].split("\n}\n", 1)[0]:
    fout.append("de commentaarpoort houdt nooit tegen")
sys.exit("; ".join(fout) if fout else 0)
PY

echo
echo "$getoetst zaken, $gezakt gezakt"
[ "$gezakt" -eq 0 ]
