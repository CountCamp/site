#!/usr/bin/env bash
# ============================================================
# contactwacht_mutatieproef.sh — meet de TOETS, niet de keuring.
#
# `contactwacht_test.py` staat groen. Dat is een bewering, geen bewijs: een toets
# die nooit rood kán worden, staat ook groen. Deze proef maakt telkens één
# bescherming van keur_contact() kapot — in het geheugen van de toets
# (PROEF_MUTATIE), _tools/en_bouw.py zelf blijft heel — en eist dat de toets dat
# merkt. Geen bouw nodig; het hele rondje duurt een paar seconden.
#
#   bash _tools/tests/contactwacht_mutatieproef.sh
#
# Afloop: 0 elke mutatie gevangen, 1 minstens één niet (of sloeg niet aan).
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 3
TOETS=_tools/tests/contactwacht_test.py
UIT=_site_en_werk/mutatieproef_contactwacht
mkdir -p "$UIT"
SLECHT=0; N=0

proef() {  # $1 = naam, $2 = deel/delen, $3 = "bestand|||oud|||nieuw[;;;...]"
  local log="$UIT/$(echo "$1" | tr -c 'a-z0-9' '_').log"
  N=$((N + 1))
  PROEF_MUTATIE="$3" python3 "$TOETS" $2 > "$log" 2>&1
  case $? in
    0) echo "  ZORGELIJK  $1 -- de toets bleef GROEN (deel $2)"; SLECHT=$((SLECHT + 1)) ;;
    1) if grep -q '^FOUT' "$log" && ! grep -q '^Traceback' "$log"; then
         echo "  ok         $1 -- de toets wordt rood (deel $2, $(grep -c '^FOUT' "$log") FOUT)"
         grep '^FOUT' "$log" | head -2 | cut -c1-150 | sed 's/^/             /'
       else
         # Afloop 1 zonder FOUT-regel is een crash, geen beet.
         echo "  MISLUKT    $1 -- afloop 1 maar geen FOUT-regel: de toets crashte; dit is geen uitslag (zie $log)"
         SLECHT=$((SLECHT + 1))
       fi ;;
    2) echo "  MISLUKT    $1 -- de mutatie sloeg niet aan; dit is geen uitslag"
       grep 'MUTATIE' "$log" | sed 's/^/             /'; SLECHT=$((SLECHT + 1)) ;;
    *) echo "  MISLUKT    $1 -- de toets kon niet kijken; dit is geen uitslag (zie $log)"; SLECHT=$((SLECHT + 1)) ;;
  esac
}

EB=_tools/en_bouw.py
# de stukken van de reparatie van 28-11-2026, zoals ze er nu staan
ZICHTBAAR="$EB|||    zichtbaar = zonder_data(ONZICHTBAAR.sub(\" \", t_en))|||    zichtbaar = zonder_data(t_en)"
MAILTO_OUD="$EB|||MAILTO = re.compile(r\"mailto:([^\\\"'?<>\\s]+)\")|||MAILTO = re.compile(r'mailto:([^\"?]+)')"
HEEL_OUD="$EB|||    return re.search(r\"(?<![\\w.+%-])\" + re.escape(ding) + r\"(?![\\w-]|\\.\\w)\", tekst) is not None|||    return ding in tekst"

echo "mutatieproef — maakt één bescherming kapot en kijkt of de toets dat merkt"
# De hele reparatie terug: zo las de keuring vóór 28-11-2026. Dit is de mutatie die
# de opdracht vraagt -- en de enige waarbij het boekscript zelf weer een gat wordt.
proef "de reparatie van 28-11 helemaal terug (de keuring van vóór die dag)" "A B C" \
  "$ZICHTBAAR;;;$MAILTO_OUD;;;$HEEL_OUD"
# Elk stuk los. Het afsluiten van een adres bij ' vangt 'mailto:' + ADRES al op
# zichzelf; daarom moet het weghalen van script en commentaar op een ANDER geval
# bijten (een mailto: met een echt adres in een script), anders kan het ongemerkt weg.
proef "script, stijl en commentaar weer meelezen" "A" "$ZICHTBAAR"
proef "alleen script weer meelezen" "A" \
  "$EB|||ONZICHTBAAR = re.compile(r\"<(script|style)\\b|||ONZICHTBAAR = re.compile(r\"<(style)\\b"
proef "alleen stijl weer meelezen" "A" \
  "$EB|||ONZICHTBAAR = re.compile(r\"<(script|style)\\b|||ONZICHTBAAR = re.compile(r\"<(script)\\b"
proef "alleen HTML-commentaar weer meelezen" "A" \
  "$EB|||[^>]*>.*?</\\1\\s*>|<!--.*?-->\", re.S | re.I)|||[^>]*>.*?</\\1\\s*>\", re.S | re.I)"
proef "<SCRIPT> met hoofdletters telt weer" "A" \
  "$EB|||[^>]*>.*?</\\1\\s*>|<!--.*?-->\", re.S | re.I)|||[^>]*>.*?</\\1\\s*>|<!--.*?-->\", re.S)"
proef "een mailadres loopt weer door tot het volgende aanhalingsteken" "A" "$MAILTO_OUD"
proef "een stukje van een adres telt weer als het adres (gewone in)" "A" "$HEEL_OUD"
proef "rekeningnummers weer in data:-adressen zoeken" "A" \
  "$EB|||    zonder_data = lambda t: re.sub(r\"data:[^\\\"')\\s]*\", \"\", t)  # noqa: E731|||    zonder_data = lambda t: t  # noqa: E731"
proef "geen rekeningnummers meer nagelopen" "A B C" \
  "$EB|||                            (\"rekeningnummer\", IBAN.findall(zichtbaar))):|||                            (\"rekeningnummer\", [])):"
# de bedrading in cmd_keur
proef "de keuring rekent, maar zijn gaten gaan nergens heen" "C" \
  "$EB|||    gaten += fout_c|||    gaten += []"

[ "$SLECHT" -eq 0 ] || { echo "mutatieproef: $SLECHT van $N proef/proeven zonder uitslag of zonder beet"; exit 1; }
echo "mutatieproef: alle $N mutaties gevangen (logboeken: $UIT/)"
