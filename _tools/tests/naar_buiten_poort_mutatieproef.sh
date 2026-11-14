#!/usr/bin/env bash
# ============================================================
# naar_buiten_poort_mutatieproef.sh — meet de TOETS van de poort op de gebouwde
# site (`gebouwde_tellers_nakijken` in naar_buiten.sh), niet de poort zelf.
#
#   bash _tools/tests/naar_buiten_poort_mutatieproef.sh
#
# `naar_buiten_teller_test.sh` groen is een bewering: een toets die nooit rood
# kán worden, staat ook groen. Hier wordt een KOPIE van naar_buiten.sh telkens op
# één plek verminkt, en de toets krijgt die kopie (NAAR_BUITEN=...). Hij moet
# rood worden, en met de zaak die erbij hoort -- een verminking die om een andere
# reden rood wordt, bewijst niets. Het echte bestand wordt nooit aangeraakt.
#
# Ontstaan 14-11-2026 (spoor teller2). De eerste ronde, met de hand, liet zien
# waarom de tweede eis er staat: een verminking met een verkeerd aanhalingsteken
# brak de regel in plaats van afloop 3 door te laten, en werd "gevangen" door
# zaak 5a in plaats van 5e.
#
# Afloop: 0 elke mutatie gevangen door de verwachte zaak, 1 niet.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 3
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
slecht=0

proef() {  # $1 = naam, $2 = zaak die moet zakken (begin van de ZAKT-regel), $3 = python over s
  python3 - _tools/naar_buiten.sh "$M/kreupel.sh" "$3" <<'PY'
import sys
bron, uit, expr = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(bron, encoding="utf-8").read()
n = eval(expr)
if n == s:
    sys.exit("mutatie veranderde niets")
open(uit, "w", encoding="utf-8").write(n)
PY
  if [ $? -ne 0 ]; then
    echo "  MISLUKT    $1 -- de mutatie paste niet meer op de code"
    slecht=$((slecht + 1)); return
  fi
  if NAAR_BUITEN="$M/kreupel.sh" bash _tools/tests/naar_buiten_teller_test.sh > "$M/uit" 2>&1; then
    echo "  VERSIERING $1 -- de toets bleef groen"
    slecht=$((slecht + 1)); return
  fi
  if grep -q "^  ZAKT  $2" "$M/uit"; then
    echo "  opgemerkt  $1 -- door zaak $2"
  else
    echo "  MISLUKT    $1 -- rood, maar niet door zaak $2:"
    grep '^  ZAKT' "$M/uit" | head -3 | sed 's/^/               /'
    slecht=$((slecht + 1))
  fi
}

# Elke uitdrukking hieronder werkt op s, de tekst van naar_buiten.sh.
# `in_poort(oud, nieuw)` vervangt alleen binnen gebouwde_tellers_nakijken: dezelfde
# regels staan ook in de drie oudere poorten.
IN_POORT='(lambda oud, nieuw: (lambda i: s[:i] + s[i:].replace(oud, nieuw, 1))(s.index("gebouwde_tellers_nakijken() {")))'

echo "mutatieproef -- verminkt een kopie van naar_buiten.sh en kijkt of de toets dat merkt"
proef "--productie stopt niet als de poort rood is" "5g" \
  's.replace("gebouwde_tellers_nakijken echt blokkerend || { echo \"  Niet geleverd.\"; exit 1; }", "gebouwde_tellers_nakijken echt blokkerend")'
proef "--productie roept de poort alleen meldend aan" "5g" \
  's.replace("gebouwde_tellers_nakijken echt blokkerend", "gebouwde_tellers_nakijken echt melden")'
proef "--lokaal roept de poort niet aan" "5g" \
  's.replace("    gebouwde_tellers_nakijken spook melden\n", "")'
proef "de poort houdt nooit tegen" "5b" \
  "$IN_POORT"'("  if [ \"$streng\" = blokkerend ]; then return 1; fi\n", "")'
proef "de poort ziet een blinde wachter (afloop 3) als groen" "5e" \
  "$IN_POORT"'("if [ \"$code\" -eq 0 ]; then return 0; fi", "if [ \"$code\" -eq 0 ] || [ \"$code\" -eq 3 ]; then return 0; fi")'
proef "de poort keurt de echte bouw als proefdruk" "5a" \
  "$IN_POORT"'("\"--$profiel\"", "--spook")'

echo
if [ "$slecht" -eq 0 ]; then
  echo "Alle mutaties opgemerkt, elk door de zaak die erbij hoort."
else
  echo "$slecht mutatie(s) niet opgemerkt, of om de verkeerde reden."
fi
[ "$slecht" -eq 0 ]
