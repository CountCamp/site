#!/usr/bin/env bash
# ============================================================
# plankwacht_mutatieproef.sh — meet de TOETS, niet de wachter.
#
# `plankwacht_test.sh` staat groen. Dat is een bewering, geen bewijs: een toets
# die nooit rood kán worden, staat ook groen. Deze proef maakt de wachter
# telkens op één plek kreupel en eist dat de toets dat merkt.
#
# Blijft de toets groen bij een kreupele wachter, dan is die zaak versiering.
#
#   bash _tools/tests/plankwacht_mutatieproef.sh
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
# Tot 30-9-2026 eindigde deze proef altijd met afloopcode 0, ook na een
# ZORGELIJK. Wie alleen de afloopcode las, zag dan groen bij een toets die niet
# bijt -- tellers_mutatieproef.sh deed het al wel goed.
SLECHT=0
# De wachter haalt de tellerregel uit het bestand naast zich. Zonder dit
# bestand valt elke kreupele kopie om bij het inlezen -- en dan wordt de toets
# rood om de verkeerde reden, dus meet elke proef hieronder niets.
cp _tools/tellerregel.py "$M/"

proef() {  # $1 = naam, $2 = sed-uitdrukking die de wachter kreupel maakt
  cp _tools/plankwacht.py "$M/kreupel.py"
  # Een mutatie die niet aanslaat, mag niet als uitslag tellen -- dan meet de
  # proef zichzelf in plaats van de wachter.
  if ! python3 - "$M/kreupel.py" "$2" <<'PY'
import sys
pad, oud_nieuw = sys.argv[1], sys.argv[2]
oud, nieuw = oud_nieuw.split("|||")
s = open(pad, encoding="utf-8").read()
if oud not in s:
    sys.exit(f"mutatie niet gevonden: {oud!r}")
open(pad, "w", encoding="utf-8").write(s.replace(oud, nieuw, 1))
PY
  then
    echo "  MISLUKT    $1 -- de mutatie sloeg niet aan; dit is geen uitslag"
    SLECHT=$((SLECHT + 1))
    return
  fi
  if PLANKWACHT="$M/kreupel.py" bash _tools/tests/plankwacht_test.sh >"$M/uit" 2>&1; then
    echo "  ZORGELIJK  $1 -- de toets bleef GROEN terwijl de wachter kreupel is"
    SLECHT=$((SLECHT + 1))
  else
    echo "  ok         $1 -- de toets wordt rood"
    grep -c 'ZAKT' "$M/uit" | sed 's/^/             gezakte zaken: /'
  fi
}

echo "mutatieproef — maakt de wachter kreupel en kijkt of de toets dat merkt"
proef "datumvergelijking uitgezet"    'if echt != beweerd:|||if False:'
proef "thema-telling uitgezet"        'if len(gepubliceerd) != beweerd:|||if False:'
proef "blind telt voortaan als goed"  '    if blind:|||    if False and blind:'
proef "niets gemeten telt als goed"   '    if getoetst == 0:|||    if False and getoetst == 0:'
proef "verweesde map wordt genegeerd" 'if verweesd:|||if False:'
proef "stopt bij de eerste treffer"   'if kaal.group(1).lower() in TELWOORDEN:|||if True:'
# De tellercommit-uitzondering (30-9-2026). Elke verslapping hieronder is een
# manier waarop echte boekwijzigingen onzichtbaar kunnen worden.
proef "elke commit mét tellerregel wordt overgeslagen" \
  '    toegevoegd = 0|||    if REGEL in uit.stdout:
        return True
    toegevoegd = 0'
proef "andere toegevoegde regels tellen niet" \
  '            if regel[1:].strip() != REGEL:|||            if False:'
proef "weggehaalde regels tellen niet" \
  '        # Alles wat hier nog komt|||        continue
        # Alles wat hier nog komt'
proef "overslag wordt niet meer gemeld" \
  '    for b in overgeslagen:|||    for b in []:'
proef "uitzondering helemaal uitgezet" \
  '        if alleen_teller:|||        if False:'
# De doorstuurcommit-uitzondering (1-10-2026). Dezelfde vraag: welke
# verslapping laat een echte boekwijziging onzichtbaar worden, en welke laat de
# wachter weer om een doorstuurder zeuren?
proef "doorstuur-uitzondering helemaal uitgezet" \
  '        if alleen_doorstuur:|||        if False:'
proef "doorstuurcommit kijkt niet naar de inhoud" \
  '            if inhoud.returncode != 0 or soort(inhoud.stdout) != "doorstuurder":|||            if inhoud.returncode != 0:'
proef "bij een wijziging telt de oude versie niet" \
  '{"A": [commit], "M": [commit + "^", commit]|||{"A": [commit], "M": [commit]'
proef "doorstuur-overslag wordt niet meer gemeld" \
  '                if doorgestuurd:|||                if False:'
proef "doorstuurmap telt als thema" \
  '        and not alleen_doorstuurders(os.path.join(vol, d))|||'
proef "elke map telt als doorstuurmap" \
  '            if soort(f.read()) != "doorstuurder":|||            if False:'
rm -rf "$M"
[ "$SLECHT" -eq 0 ] || { echo "mutatieproef: $SLECHT proef/proeven zonder uitslag of zonder beet"; exit 1; }
