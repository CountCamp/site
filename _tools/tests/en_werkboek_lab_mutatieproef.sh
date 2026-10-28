#!/usr/bin/env bash
# ============================================================
# en_werkboek_lab_mutatieproef.sh — meet de TOETS, niet de keuring.
#
# `en_werkboek_lab_test.py` staat groen. Dat is een bewering, geen bewijs: een
# toets die nooit rood kán worden, staat ook groen. Deze proef maakt telkens één
# bescherming kapot — in het geheugen van de toets of in de kopie in zijn proefsite
# (PROEF_MUTATIE); het bestand in de repo blijft heel — en eist dat de toets dat
# merkt. Per mutatie draait alleen het deel dat erop hoort te bijten.
#
#   bash _tools/tests/en_werkboek_lab_mutatieproef.sh
#
# Deel C vraagt een gebouwde site (bash _tools/publiceer_en.sh --alleen-spook);
# zonder die bouw is een mutatie op C "kon niet kijken", en dat telt hier als
# MISLUKT, niet als gevangen.
#
# Afloop: 0 elke mutatie gevangen, 1 minstens één niet (of sloeg niet aan).
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 3
TOETS=_tools/tests/en_werkboek_lab_test.py
UIT=_site_en_werk/mutatieproef_en_werkboek_lab
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
PW=_tools/publish_workbook.py
echo "mutatieproef — maakt één bescherming kapot en kijkt of de toets dat merkt"
# de stempel zelf (en_bouw.py)
proef "elke lengte commit is goed" "A C" \
  "$EB|||lab-commit=[0-9a-f]{40} \"|||lab-commit=[0-9a-f]+ \""
proef "de naam in de stempel hoeft niet bij de map te passen" "A C" \
  "$EB|||    if naam != delen[2]:|||    if False:"
proef "een stempel telt overal, ook buiten en/workbooks/<naam>/" "A C" \
  "$EB|||    if len(delen) < 4 or \"/\".join(delen[:2]) != WERKBOEK_MAP:|||    if False:"
proef "een stempel midden in de bladzij telt ook" "A" \
  "$EB|||    if eind < 0 or not regels or WERKBOEK_MERK in tekst[:eind]:|||    if eind < 0 or not regels:"
proef "na de stempel mag meer staan (twee stempels, rommel)" "A" \
  "$EB|||    if len(regels) != 1 or not WERKBOEK_STEMPEL.fullmatch(regels[0]):|||    if not WERKBOEK_STEMPEL.fullmatch(regels[0]):"
# wat de keuring met de stempel doet (en_bouw.py cmd_keur)
proef "een stempel die niet klopt is een gewone bladzij in plaats van een gat" "C" \
  "$EB|||        elif reden:
            fout_wb.append(reden)|||        elif False:
            fout_wb.append(reden)"
proef "elke bladzij onder en/workbooks/ is vrijgesteld van de wees-keuring" "C" \
  "$EB|||        if p.startswith(LIBS_NAAR + \"/\") or p in lab or p in werkboek:|||        if p.startswith(LIBS_NAAR + \"/\") or p in lab or p.startswith(WERKBOEK_MAP + \"/\"):"
proef "het oefenboek krijgt in de spooksite de proefdrukmerken (zoals vóór 28-10)" "C" \
  "$EB|||        if a.soort == \"echt\" or p in lab or p in kist or p in werkboek:|||        if a.soort == \"echt\" or p in lab or p in kist:"
proef "het oude advies voor een wees verdwijnt" "C" \
  "$EB|||bestaat niet meer — haal hem weg of zet de bron terug\"|||bestaat niet meer — publiceer hem opnieuw\""
# wie de stempel zet (publish_workbook.py)
proef "de stempel ook met ongecommit werk in de bron" "B" \
  "$PW|||    if vuil:
        return None|||    if False:
        return None"
proef "een render in een genegeerde map van een andere repo krijgt diens commit" "B" \
  "$PW|||    if r.returncode != 0 or not r.stdout.strip():|||    if r.returncode != 0:"
# (lab_commit = "" en niet pass: met None valt de regel erna om, en een crash met
# afloop 1 leek in de eerste ronde precies op een weigering.)
proef "zonder stempel toch publiceren (en het oude oefenboek weggooien)" "B" \
  "$PW|||            return 1
        log(f\"stempel: countcamp-oefenboek|||            lab_commit = \"\"
        log(f\"stempel: countcamp-oefenboek"
proef "ook het Nederlands krijgt een stempel" "B" \
  "$PW|||    if os.path.normpath(args.section) == EN_WERKBOEKEN:|||    if True:"
proef "de schrijver zet een andere vorm dan de lezer kent" "B" \
  "$PW|||lab-commit={commit} geleverd|||lab-commit={commit[:12]} geleverd"
proef "de schrijver keurt zijn eigen stempel niet na" "B" \
  "$PW|||            ja, reden = keur(site_pad, s)|||            ja, reden = True, \"\""

[ "$SLECHT" -eq 0 ] || { echo "mutatieproef: $SLECHT van $N proef/proeven zonder uitslag of zonder beet"; exit 1; }
echo "mutatieproef: alle $N mutaties gevangen (logboeken: $UIT/)"
