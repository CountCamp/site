#!/usr/bin/env bash
# ============================================================
# boek_inhoud_en_mutatieproef.sh — meet de TOETS, niet het filter.
#
#   bash _tools/tests/boek_inhoud_en_mutatieproef.sh
#
# boek_inhoud_en_test.sh groen is een bewering: een toets die nooit rood kán
# worden, staat ook groen. Hier wordt telkens één plek in een KOPIE van
# _tools/boek_inhoud_en.lua kreupel gemaakt, en de toets moet dat merken. Blijft
# hij groen, dan was die plek versiering.
# Afloop: 0 elke mutatie opgemerkt, 1 minstens één versiering of mislukte mutatie.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
zorgelijk=0
getal=0

verminkt() {  # $1 = uit, $2 = oud, $3 = nieuw  (oud moet er precies één keer in staan)
  python3 - _tools/boek_inhoud_en.lua "$1" "$2" "$3" <<'PY'
import sys
bron, uit, oud, nieuw = sys.argv[1:5]
s = open(bron, encoding="utf-8").read()
if s.count(oud) != 1:
    sys.exit("mutatie niet toepasbaar: %r staat er %d keer in" % (oud[:70], s.count(oud)))
open(uit, "w", encoding="utf-8").write(s.replace(oud, nieuw))
PY
}

proef() {  # $1 = naam, $2 = oud, $3 = nieuw
  getal=$((getal + 1))
  local k="$M/mutant_$getal.lua"
  if ! verminkt "$k" "$2" "$3"; then
    echo "  MISLUKT    $1 -- de mutatie paste niet meer op de code"
    zorgelijk=$((zorgelijk + 1)); return
  fi
  if BOEK_INHOUD_LUA="$k" BOEK_INHOUD_PROEF_ACHTER="_mutant" bash _tools/tests/boek_inhoud_en_test.sh > "$M/uit" 2>&1; then
    echo "  VERSIERING $1 -- de toets bleef groen"
    zorgelijk=$((zorgelijk + 1))
  else
    echo "  opgemerkt  $1 -- $(grep -c '^FOUT' "$M/uit") zaak/zaken rood, bv. $(grep -m1 '^FOUT' "$M/uit" | cut -c7-90)"
  fi
}

# De les van 28-11: error() stopt Quarto 1.9.38 niet. Terug naar error() moet zakken.
proef "fout() met error() in plaats van os.exit(1)" \
  '  io.stderr:flush()
  os.exit(1)' \
  '  error(tekst, 0)'
# Het hart: wat Engels is, wordt uitgelezen. Doet hij alsof er niets Engels is, dan zakt hij.
proef "en/book/h<n>.html niet meer uitlezen (alles grijs)" \
  'local en = en_pad[n] and blad(wortel, en_pad[n], "en", n) or nil' \
  'local en = nil'
# Een veranderd Nederlands mag niet stil blijven.
proef "een veranderde Nederlandse regel niet meer melden" \
  'if plat(r.nl) ~= plat(nl.sub or "") then' \
  'if false then'
# Een overbodige rij ook niet.
proef "een overbodige tabelrij niet meer melden" \
  '      if rijen[n] then
        meld(' \
  '      if false then
        meld('
# De grijze rij hoort naar het Nederlands te wijzen.
proef "grijze rij zonder link naar het Nederlands" \
  "<a class=\"cc-toc-kop\" href=\"../../%s\" hreflang=\"nl\">" \
  "<a class=\"cc-toc-kop\" href=\"%s\">"
# Een getal in de kop dat niet bij de bestandsnaam hoort.
proef "de kop niet meer tegen de bestandsnaam houden" \
  'if tonumber(m) ~= n then' \
  'if false then'

echo
echo "$getal mutatie(s), $((getal - zorgelijk)) opgemerkt, $zorgelijk versiering of mislukt"
[ "$zorgelijk" -eq 0 ] && exit 0 || exit 1
