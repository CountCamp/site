#!/usr/bin/env bash
# ============================================================
# variabelenwacht_test.sh — bijtproef voor _tools/variabelenwacht.py en zijn bedrading.
#
#   bash _tools/tests/variabelenwacht_test.sh
#   GEREEDSCHAP=<map met een kreupele variabelenwacht.py> bash _tools/tests/variabelenwacht_test.sh
#   NAAR_BUITEN=<kreupele naar_buiten.sh> bash _tools/tests/variabelenwacht_test.sh
#
# Wat de wachter moet vangen (27-11-2026, spoor site_steun): de Stripe-link of het
# KvK-nummer verandert in _variables.yml, de Nederlandse kant bouwt de Action vers,
# en de Engelse kant staat gebouwd in de repo en blijft op de oude waarde. Wat
# deze toets eist, in vier delen:
#
#   A. SCHOON IS SCHOON. De echte repo, en een nagemaakte en/ waarin de gebouwde
#      bladzij de waarde draagt (ook met &amp; erin, en een sleutel die twee keer
#      gevraagd wordt): afloop 0. Een en/ zonder {{< var >}}: 0, en dat zegt hij.
#   B. HIJ BIJT. Een nieuwe waarde in _variables.yml terwijl de bladzij de oude
#      draagt; een bladzij die de waarde één keer draagt waar de bron hem twee keer
#      vraagt; een gebouwde bladzij die ontbreekt; een sleutel die niet bestaat; een
#      bladzij met Quarto's "?var:": afloop 1, en hij noemt de bladzij.
#   C. HIJ ZEGT NIET "SCHOON" ALS HIJ NIET KEEK. Geen en/; _variables.yml weg
#      terwijl een bron hem vraagt; een vorm die hij niet leest (een lijst, een
#      waarde zonder aanhalingstekens, een tab): afloop 3, nooit 0.
#   D. DE BEDRADING. naar_buiten.sh roept hem blokkerend aan op --nakijken en
#      --productie (vóór de push) en meldend op --lokaal en --proefdruk.
#
# Afloop: 0 alles goed, 1 minstens één zaak zakt.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
GEREEDSCHAP="${GEREEDSCHAP:-_tools}"
NAAR_BUITEN="${NAAR_BUITEN:-_tools/naar_buiten.sh}"
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
    sed 's/^/          /' "$M/uit" | tail -12
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

wacht() { python3 "$GEREEDSCHAP/variabelenwacht.py" --wortel "$1"; }

# Een nagemaakte wortel: _variables.yml zoals de echte (twee geneste waarden),
# en/support.qmd die ze allebei vraagt, en/support.html die ze allebei draagt.
nep() {  # $1 = naam -> pad
  local r="$M/$1"
  mkdir -p "$r/en"
  cat > "$r/_variables.yml" <<'YML'
# commentaar bovenaan
steun:
  # commentaar binnenin
  stripe: "https://buy.stripe.com/voorbeeld"
  kvk: "28111063"
YML
  printf -- '---\ntitle: x\n---\n[Geef]({{< var steun.stripe >}}){.cc-steun-knop}\n\nKvK {{< var steun.kvk >}}\n' > "$r/en/support.qmd"
  printf '<a href="https://buy.stripe.com/voorbeeld" class="cc-steun-knop">Geef</a><p>KvK 28111063</p>\n' > "$r/en/support.html"
  echo "$r"
}

echo "== A. schoon is schoon"
zaak "A1 de echte repo" 0 wacht .
R="$(nep schoon)"
zaak "A2 nagemaakte en/, waarde gedragen" 0 wacht "$R"
in_uitvoer "A2 en hij zegt wat hij nakeek" "2 sleutel(s) per bladzij in orde"
R="$(nep amp)"
printf 'steun:\n  stripe: "https://buy.stripe.com/a?b=1&c=2"\n  kvk: "28111063"\n' > "$R/_variables.yml"
printf '<a href="https://buy.stripe.com/a?b=1&amp;c=2" class="cc-steun-knop">Geef</a><p>KvK 28111063</p>\n' > "$R/en/support.html"
zaak "A3 een & in de waarde, &amp; in de HTML" 0 wacht "$R"
R="$(nep twee)"
printf '\n{{< var steun.kvk >}}\n' >> "$R/en/support.qmd"
printf '<p>nogmaals 28111063</p>\n' >> "$R/en/support.html"
zaak "A4 twee keer gevraagd, twee keer gedragen" 0 wacht "$R"
R="$M/zondervar"; mkdir -p "$R/en"; printf -- '---\ntitle: x\n---\ntekst\n' > "$R/en/a.qmd"
zaak "A5 geen enkele {{< var >}}: niets na te kijken" 0 wacht "$R"
in_uitvoer "A5 en dat zegt hij" "niets na te kijken"

echo "== B. hij bijt"
R="$(nep nieuw)"
sed -i.bak 's#buy.stripe.com/voorbeeld#buy.stripe.com/NIEUW#' "$R/_variables.yml"
zaak "B1 nieuwe Stripe-link, de Engelse bladzij draagt de oude" 1 wacht "$R"
in_uitvoer "B1 en hij noemt de bladzij en wat te doen" "en/support.html: draagt steun.stripe"
in_uitvoer "B1 en de reparatie" "publiceer_en.sh"
R="$(nep plaatshouder)"
printf '<a href="#stripe-link-volgt" class="cc-steun-knop">Geef</a><p>KvK 28111063</p>\n' > "$R/en/support.html"
zaak "B2 de Engelse knop staat nog op de plaatshouder" 1 wacht "$R"
R="$(nep telling)"
printf '\n{{< var steun.kvk >}}\n' >> "$R/en/support.qmd"
zaak "B3 twee keer gevraagd, één keer gedragen" 1 wacht "$R"
in_uitvoer "B3 en hij telt" "1 keer, en/support.qmd vraagt hem 2 keer"
R="$(nep zonderhtml)"; rm "$R/en/support.html"
zaak "B4 de gebouwde bladzij ontbreekt" 1 wacht "$R"
R="$(nep onbekend)"
printf '\n{{< var steun.iban >}}\n' >> "$R/en/support.qmd"
zaak "B5 een sleutel die niet in _variables.yml staat" 1 wacht "$R"
in_uitvoer "B5 en hij noemt de sleutel" "steun.iban"
R="$(nep vraagteken)"
printf '<p>?var:steun.kvk</p>\n' >> "$R/en/support.html"
zaak "B6 Quarto schreef ?var: in de bladzij" 1 wacht "$R"

echo "== C. niet gekeken is niet schoon"
zaak "C1 geen map en/" 3 wacht "$M/leeg_niets"
R="$(nep geenvars)"; rm "$R/_variables.yml"
zaak "C2 _variables.yml weg terwijl een bron hem vraagt" 3 wacht "$R"
R="$(nep lijst)"; printf 'steun:\n  - "a"\n' > "$R/_variables.yml"
zaak "C3 een lijst: onleesbaar voor deze wachter" 3 wacht "$R"
R="$(nep kaal)"; printf 'steun:\n  kvk: 28111063\n' > "$R/_variables.yml"
zaak "C4 een waarde zonder aanhalingstekens: onleesbaar" 3 wacht "$R"
R="$(nep tab)"; printf 'steun:\n\tkvk: "28111063"\n' > "$R/_variables.yml"
zaak "C5 een tab als inspringing: onleesbaar" 3 wacht "$R"

echo "== D. de bedrading in naar_buiten.sh"
getoetst=$((getoetst + 1))
if python3 - "$NAAR_BUITEN" > "$M/uit" 2>&1 <<'PY'
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
def tak(naam):
    m = re.search(r"^%s\)\n(.*?)^  ;;" % re.escape(naam), s, re.S | re.M)
    return m.group(1) if m else ""
fout = []
f = s.split("variabelen_nakijken() {", 1)[-1].split("\n}\n", 1)[0] if "variabelen_nakijken() {" in s else ""
if 'variabelenwacht.py"' not in f:
    fout.append("er is geen functie variabelen_nakijken die variabelenwacht.py draait")
if 'if [ "$streng" = blokkerend ]; then return 1; fi' not in f:
    fout.append("variabelen_nakijken houdt nooit tegen")
if not re.search(r"^\s*variabelen_nakijken\s+blokkerend \|\| code=1\s*$", tak("--nakijken"), re.M):
    fout.append("--nakijken roept hem niet blokkerend aan")
prod = tak("--productie")
a, b = prod.find("variabelen_nakijken blokkerend"), prod.find("doe git push origin main")
if a < 0 or b < 0 or a > b or "exit 1" not in prod[a:prod.find("\n", a)]:
    fout.append("--productie houdt niet tegen vóór de push (wacht op %d, push op %d)" % (a, b))
for t in ("--lokaal", "--proefdruk"):
    if not re.search(r"^\s*variabelen_nakijken melden\s*$", tak(t), re.M):
        fout.append("%s roept hem niet (meldend) aan" % t)
sys.exit("; ".join(fout) if fout else 0)
PY
then
  echo "  ok    D1 naar_buiten.sh: --nakijken en --productie blokkerend (vóór de push), --lokaal en --proefdruk meldend"
else
  echo "  ZAKT  D1 naar_buiten.sh: $(cat "$M/uit")"
  gezakt=$((gezakt + 1))
fi

echo
echo "$getoetst zaken, $gezakt gezakt"
[ "$gezakt" -eq 0 ]
