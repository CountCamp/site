#!/usr/bin/env bash
# ============================================================
# en_boek_lab_mutatieproef.sh — meet de TOETS, niet de keuring.
#
# `en_boek_lab_test.py` staat groen. Dat is een bewering, geen bewijs: een toets
# die nooit rood kán worden, staat ook groen. Deze proef maakt telkens één
# bescherming kapot — in het geheugen van de toets (PROEF_MUTATIE), het bestand
# zelf blijft heel — en eist dat de toets dat merkt. Per mutatie draait alleen
# het deel dat erop hoort te bijten.
#
#   bash _tools/tests/en_boek_lab_mutatieproef.sh
#
# Deel C vraagt een gebouwde site met een bladzij uit het lab (zie de toets);
# zonder die bouw is een mutatie op C "kon niet kijken", en dat telt hier als
# MISLUKT, niet als gevangen.
#
# Afloop: 0 elke mutatie gevangen, 1 minstens één niet (of sloeg niet aan).
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 3
TOETS=_tools/tests/en_boek_lab_test.py
UIT=_site_en_werk/mutatieproef_en_boek_lab
mkdir -p "$UIT"
SLECHT=0; N=0

proef() {  # $1 = naam, $2 = deel/delen, $3 = "bestand|||oud|||nieuw"
  local log="$UIT/$(echo "$1" | tr -c 'a-z0-9' '_').log"
  N=$((N + 1))
  PROEF_MUTATIE="$3" python3 "$TOETS" $2 > "$log" 2>&1
  case $? in
    0) echo "  ZORGELIJK  $1 -- de toets bleef GROEN (deel $2)"; SLECHT=$((SLECHT + 1)) ;;
    1) if grep -q '^FOUT' "$log" && ! grep -q '^Traceback' "$log"; then
         echo "  ok         $1 -- de toets wordt rood (deel $2)"
         grep '^FOUT' "$log" | head -2 | cut -c1-150 | sed 's/^/             /'
       else
         # Afloop 1 zonder FOUT-regel is een crash, geen beet (zo ging het in de eerste ronde).
         echo "  MISLUKT    $1 -- afloop 1 maar geen FOUT-regel: de toets crashte; dit is geen uitslag (zie $log)"
         SLECHT=$((SLECHT + 1))
       fi ;;
    2) echo "  MISLUKT    $1 -- de mutatie sloeg niet aan; dit is geen uitslag"
       grep 'MUTATIE' "$log" | sed 's/^/             /'; SLECHT=$((SLECHT + 1)) ;;
    *) echo "  MISLUKT    $1 -- de toets kon niet kijken; dit is geen uitslag (zie $log)"; SLECHT=$((SLECHT + 1)) ;;
  esac
}

EB=_tools/en_bouw.py
TO=_tools/taalonderdelen.py
echo "mutatieproef — maakt één bescherming kapot en kijkt of de toets dat merkt"
# de stempel zelf
proef "elke lengte hash is goed" "A C" \
  "$EB|||bron-hash=[0-9a-f]{64} \"|||bron-hash=[0-9a-f]+ \""
proef "de stempel hoeft niet bij deze bladzij te horen" "A C" \
  "$EB|||    if lab_doelnaam(naam) != os.path.basename(p):|||    if False:"
proef "een stempel telt overal onder en/" "A" \
  "$EB|||    if os.path.dirname(p) != LAB_MAP:|||    if False:"
proef "een stempel midden in de bladzij telt ook" "A" \
  "$EB|||    if eind < 0 or not regels or LAB_MERK in tekst[:eind]:|||    if eind < 0 or not regels:"
proef "rommel na de stempel mag (alleen de stempelregels tellen)" "A" \
  "$EB|||    for r in regels:
        if not LAB_STEMPEL.fullmatch(r):|||    regels = [r for r in regels if LAB_STEMPEL.fullmatch(r)] or regels
    for r in regels:
        if not LAB_STEMPEL.fullmatch(r):"
proef "een stempel die niet klopt is een gewone bladzij in plaats van een gat" "C" \
  "$EB|||        elif reden:
            fout_st.append(reden)|||        elif False:
            fout_st.append(reden)"
# wat de stempel vrijstelt
proef "elke bladzij onder en/book/ is vrijgesteld van de wees-keuring" "C" \
  "$EB|||        if p.startswith(LIBS_NAAR + \"/\") or p in lab:|||        if p.startswith(LIBS_NAAR + \"/\") or p.startswith(LAB_MAP + \"/\"):"
proef "de lab-bladzij in de spooksite krijgt de proefdrukmerken weer (zoals vóór de port)" "C" \
  "$EB|||        if a.soort == \"echt\" or p in lab:|||        if a.soort == \"echt\":"
proef "noindex op de lab-bladzij in de spooksite mag" "C" \
  "$EB|||            if m[\"noindex\"]: fout_merk.append(f\"{p}: draagt noindex {waar}\")|||            if m[\"noindex\"] and a.soort == \"echt\": fout_merk.append(f\"{p}: draagt noindex {waar}\")"
proef "de teller op de lab-bladzij wordt in de spooksite niet nagekeken (zoals het voorstel)" "C" \
  "$EB|||            if m[\"teller\"] != \"geteld\": fout_merk.append(f\"{p}: bezoekersteller {m['teller']} {waar}\")|||            if m[\"teller\"] != \"geteld\" and a.soort == \"echt\": fout_merk.append(f\"{p}: bezoekersteller {m['teller']} {waar}\")"
proef "de zijbalk van een lab-bladzij wordt niet nagekeken" "C" \
  "$EB|||            if not os.path.isfile(os.path.join(site, os.path.dirname(p), f)):|||            if False:"
proef "een zijbalk zonder hoofdstukken telt als nagekeken" "C" \
  "$EB|||        if not doelen:
            fout_zb.append(|||        if False:
            fout_zb.append("
proef "rekeningnummers weer in data:-adressen zoeken" "C" \
  "$EB|||    zonder_data = lambda t: re.sub(r\"data:[^\\\"')\\s]*\", \"\", t)  # noqa: E731|||    zonder_data = lambda t: t  # noqa: E731"
# de regel in taalparen.tsv
proef "de regel sorteert als tekst (h10 vóór h2)" "B" \
  "$TO|||    getallen = sorted({m.group(1) for m in map(vorm.match, namen) if m}, key=int)|||    getallen = sorted({m.group(1) for m in map(vorm.match, namen) if m})"
proef "de regel vangt ook h5.html.bak" "B" \
  "$TO|||.replace(re.escape(REGEL_N), r\"(\\d+)\") + r\"\\Z\")|||.replace(re.escape(REGEL_N), r\"(\\d+)\"))"
proef "een regel met auto mag" "B" \
  "$TO|||    if wissel not in (\"los\", \"los-eigen\"):|||    if False:"
proef "een bladzij mag in twee paren" "B" \
  "$TO|||            if p[kant] in gezien:|||            if False:"
proef "de knop op de Nederlandse kant valt buiten wat de wachtrij weglaat" "B" \
  "$TO|||'<a href=\"{relatief(paar[\"nl\"], paar[\"en\"])}\" hreflang=\"en\" lang=\"en\" '|||'<a href=\"{relatief(paar[\"nl\"], paar[\"en\"])}\" hreflang=\"en\" lang=\"en\" data-x=\"1\" '"

[ "$SLECHT" -eq 0 ] || { echo "mutatieproef: $SLECHT van $N proef/proeven zonder uitslag of zonder beet"; exit 1; }
echo "mutatieproef: alle $N mutaties gevangen (logboeken: $UIT/)"
