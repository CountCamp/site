#!/usr/bin/env bash
# ============================================================
# tellers_mutatieproef.sh — meet de TOETS, niet de wachter.
#
# `tellers_test.sh` staat groen. Dat is een bewering, geen bewijs: een toets die
# nooit rood kán worden, staat ook groen. Deze proef maakt de wachter telkens op
# één plek kreupel en eist dat de toets dat merkt.
#
# Blijft de toets groen bij een kreupele wachter, dan is die zaak versiering.
#
#   bash _tools/tests/tellers_mutatieproef.sh
#
# Zaak 0 is de mutatie die de opdracht vroeg, en hij staat op ECHTE bladzijden:
# een kopie van een compleet oefenboek uit deze repo, waar één bladzij zijn
# teller verliest. Een wachter die alleen op gebouwde proefbladzijden rood wordt,
# heeft nooit bewezen dat hij de site zelf kan lezen.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
zorgelijk=0

# ------------------------------------------------------------------
# Zaak 0 — echte bladzijden, één teller weggehaald.
# ------------------------------------------------------------------
echo "mutatie op echte bladzijden — een kopie van oefenboeken/ggz_vs in /tmp"
ECHT="$M/echt"
mkdir -p "$ECHT/oefenboeken" "$ECHT/werkboeken"
cp -R oefenboeken/ggz_vs "$ECHT/oefenboeken/ggz_vs"

if python3 _tools/controleer_tellers.py --site "$ECHT" --map oefenboeken \
        --map werkboeken > "$M/uit0a" 2>&1; then
  echo "  ok         de onaangeroerde kopie staat groen"
  grep -E '^  TOTAAL' "$M/uit0a" | sed 's/^/             /'
else
  echo "  MISLUKT    de onaangeroerde kopie staat al rood; dit is geen uitslag"
  sed 's/^/             /' "$M/uit0a"
  zorgelijk=$((zorgelijk + 1))
fi

SLACHTOFFER="$ECHT/oefenboeken/ggz_vs/20_blokken/blok_p_waarde.html"
python3 - "$SLACHTOFFER" <<'PY'
import sys
pad = sys.argv[1]
s = open(pad, encoding="utf-8").read()
voor = s.count("gc.zgo.at/count.js")
if voor == 0:
    sys.exit("deze bladzij had al geen teller; de mutatie kan niet aanslaan")
# Haal de hele script-tag weg, niet alleen het merk: een half weggehaalde teller
# zou als `half` gelden en de proef om de verkeerde reden laten slagen.
i = s.find('<script data-goatcounter')
j = s.find("</script>", i) + len("</script>")
open(pad, "w", encoding="utf-8").write(s[:i] + s[j:])
na = open(pad, encoding="utf-8").read().count("gc.zgo.at/count.js")
print("             teller-merken in blok_p_waarde.html: %d -> %d" % (voor, na))
PY

if python3 _tools/controleer_tellers.py --site "$ECHT" --map oefenboeken \
        --map werkboeken > "$M/uit0b" 2>&1; then
  echo "  ZORGELIJK  de wachter bleef GROEN terwijl een echte bladzij zijn teller kwijt is"
  zorgelijk=$((zorgelijk + 1))
else
  echo "  ok         de wachter wordt rood op een echte bladzij"
  grep -E '^  TOTAAL|blok_p_waarde' "$M/uit0b" | sed 's/^/             /'
fi
echo ""

# ------------------------------------------------------------------
# Zaken 1.. — de wachter kreupel maken en kijken of de toets het merkt.
# ------------------------------------------------------------------
proef() {  # $1 = naam, $2 = bestand (wachter|poort|regel), $3 = 'oud|||nieuw'
  local naam="$1" welk="$2" mut="$3"
  local bron dst
  case "$welk" in
    wachter) bron=_tools/controleer_tellers.py; dst="$M/kreupel_wachter.py" ;;
    poort)   bron=_tools/publish_workbook.py;   dst="$M/kreupel_poort.py"   ;;
    regel)   bron=_tools/tellerregel.py;        dst="$M/kreupel_regel.py"   ;;
  esac
  cp "$bron" "$dst"
  # Een mutatie die niet aanslaat mag niet als uitslag tellen -- dan meet de
  # proef zichzelf in plaats van de wachter.
  if ! python3 - "$dst" "$mut" <<'PY'
import sys
pad, oud_nieuw = sys.argv[1], sys.argv[2]
oud, nieuw = oud_nieuw.split("|||")
s = open(pad, encoding="utf-8").read()
if oud not in s:
    sys.exit("mutatie niet gevonden: %r" % oud)
open(pad, "w", encoding="utf-8").write(s.replace(oud, nieuw, 1))
PY
  then
    echo "  MISLUKT    $naam -- de mutatie sloeg niet aan; dit is geen uitslag"
    zorgelijk=$((zorgelijk + 1))
    return
  fi
  local w="_tools/controleer_tellers.py" p="_tools/publish_workbook.py"
  local r="_tools/tellerregel.py"
  [ "$welk" = wachter ] && w="$dst"
  [ "$welk" = poort   ] && p="$dst"
  [ "$welk" = regel   ] && r="$dst"
  # BEIDE toetsen draaien, want ze bewaken verschillende dingen: de wachter
  # loopt de site na, de poort laat een werkboek binnen. `tellerregel.py` zit
  # onder allebei, dus een mutatie daar moet minstens één van de twee rood
  # maken -- en welke, dat zeggen we erbij.
  local rood=""
  WACHTER="$w" REGEL="$r" bash _tools/tests/tellers_test.sh >"$M/uit_w" 2>&1 \
    || rood="$rood wachter"
  POORT="$p"   REGEL="$r" bash _tools/tests/publish_teller_test.sh >"$M/uit_p" 2>&1 \
    || rood="$rood poort"
  if [ -z "$rood" ]; then
    echo "  ZORGELIJK  $naam -- beide toetsen bleven GROEN terwijl de code kreupel is"
    zorgelijk=$((zorgelijk + 1))
  else
    local nw np
    nw=$(grep -c 'ZAKT' "$M/uit_w")
    np=$(grep -c 'ZAKT' "$M/uit_p")
    echo "  ok         $naam -- rood bij:$rood (wachter $nw, poort $np gezakt)"
  fi
}

echo "mutatieproef -- maakt de wachter kreupel en kijkt of de toets dat merkt"
proef "blinde bladzij telt voortaan als goed" wachter \
      'if mist:|||if False:'
proef "niets gemeten telt als schoon"         wachter \
      'if gezien == 0:|||if False and gezien == 0:'
proef "alles heet voortaan een doorstuurder"  wachter \
      "if s != 'bladzij':|||if True:"
proef "uitsluitingen worden niet meer genoemd" wachter \
      'if uitgesloten:|||if False:'
proef "de reparatie voegt niets meer in"      wachter \
      "if wat == 'toegevoegd':|||if False:"
proef "een half merk telt voortaan als hele"  regel \
      'if sitecode and script:|||if sitecode or script:'
proef "alleen het script-merk wordt nog geëist" regel \
      'sitecode = MERK_SITECODE in tekst|||sitecode = True'
proef "een doorstuurder heet voortaan bladzij" regel \
      "return 'doorstuurder'|||return 'bladzij'"
proef "invoegen gebeurt tweemaal (niet meer idempotent)" regel \
      "if stand == 'geteld':|||if False:"
proef "een bladzij zonder </head> heet voortaan goed" regel \
      "return tekst, 'geen_head'|||return tekst, 'al_goed'"
proef "de poort weigert niet meer"             poort \
      'if zonder_teller:|||if False:'
proef "de poort schrijft de teller niet weg"   poort \
      'open(f, "w", encoding="utf-8").write(nieuw)|||pass'
proef "de poort slaat elke bladzij over"       poort \
      'if k != "bladzij":|||if True:'
proef "de poort noemt zijn uitsluitingen niet" poort \
      'for rel, reden in overgeslagen:|||for rel, reden in []:'

echo ""
if [ "$zorgelijk" = "0" ]; then
  echo "elke mutatie werd opgemerkt; de toets meet echt iets."
  exit 0
fi
echo "$zorgelijk mutatie(s) bleven onopgemerkt of sloegen niet aan -- naar kijken."
exit 1
