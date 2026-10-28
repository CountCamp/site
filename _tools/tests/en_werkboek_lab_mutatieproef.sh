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
proef "twee publicaties door elkaar in één oefenboek mogen" "C" \
  "$EB|||        if len(stempels) > 1:|||        if False:"
# wie de stempel zet (publish_workbook.py)
proef "het oordeel van lab_bron telt niet (een verzonnen commit)" "B" \
  "$PW|||        lab_commit, reden = lab_bron(src)|||        lab_commit, reden = (lab_bron(src)[0] or \"0\" * 40), \"\""
proef "de stempel ook met ongecommit werk in de bron" "B" \
  "$PW|||    if vuil:
        return None|||    if False:
        return None"
proef "wat achter een wegwijzer staat, telt niet als bron" "B" \
  "$PW|||        plekken.append(os.path.relpath(doel, os.path.realpath(project)))|||        pass"
proef "een wegwijzer naar buiten de repo mag" "B" \
  "$PW|||        if not top or os.path.commonpath([doel, os.path.realpath(top)]) != os.path.realpath(top):|||        if False:"
proef "nieuwe bestanden ziet git status alleen als het lab dat wil" "B" \
  "$PW|||\"--untracked-files=all\", |||"
proef "de render zelf telt als ongecommit werk" "B" \
  "$PW|||    spec = [\"--\", *plekken, f\":(exclude){render}\"]|||    spec = [\"--\", *plekken]"
proef "een commit na de render: schoon is genoeg" "B" \
  "$PW|||    if nieuwer:
        t, pad = max(nieuwer)|||    if False:
        t, pad = max(nieuwer)"
proef "geen _quarto.yml nodig boven de render" "B" \
  "$PW|||    if not os.path.isfile(os.path.join(project, \"_quarto.yml\")):|||    if False:"
proef "een render in een genegeerde map van een andere repo krijgt diens commit" "B" \
  "$PW|||    if r.returncode != 0 or not r.stdout.strip(\"\\0\").strip():|||    if r.returncode != 0:"
proef "de voorproef keurt niet (pas ná het weggooien merkt iemand het)" "B" \
  "$PW|||                if not ja:
                    fout.append((rel, reden or|||                if False:
                    fout.append((rel, reden or"
proef "een naam die niet in de stempel past, mag" "B" \
  "$PW|||        if not re.fullmatch(r\"[a-z0-9_-]+\", args.name):|||        if False:"
proef "ook het Nederlands krijgt een stempel" "B" \
  "$PW|||    if os.path.normpath(args.section) == EN_WERKBOEKEN:|||    if True:"
proef "de schrijver zet een andere vorm dan de lezer kent" "B" \
  "$PW|||lab-commit={commit} geleverd|||lab-commit={commit[:12]} geleverd"
proef "de succesmelding stuurt een Engels oefenboek meteen naar push" "B" \
  "$PW|||    if regel:
        # Onder en/ keurt|||    if False:
        # Onder en/ keurt"
# NIET opgenomen, met reden: de nakeuring ná het kopiëren (keur in zet_werkboek_stempels).
# Die is een tweede slot achter de voorproef; geen bron komt door de voorproef en zakt
# daarna, dus een mutatie die alleen dat slot weghaalt kan niet bijten. Wie hem toch
# kapotmaakt, merkt het pas als de voorproef ook stuk is (zie de mutatie hierboven).

[ "$SLECHT" -eq 0 ] || { echo "mutatieproef: $SLECHT van $N proef/proeven zonder uitslag of zonder beet"; exit 1; }
echo "mutatieproef: alle $N mutaties gevangen (logboeken: $UIT/)"
