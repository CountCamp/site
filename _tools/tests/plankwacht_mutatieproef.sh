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
pad, paren = sys.argv[1], sys.argv[2]
s = open(pad, encoding="utf-8").read()
# Meerdere vervangingen in één mutatie, gescheiden door '&&&': nodig waar twee
# beschermingen elkaar dekken en er pas iets misgaat als ze allebei weg zijn.
for oud_nieuw in paren.split("&&&"):
    oud, nieuw = oud_nieuw.split("|||")
    if oud not in s:
        sys.exit(f"mutatie niet gevonden: {oud!r}")
    s = s.replace(oud, nieuw, 1)
open(pad, "w", encoding="utf-8").write(s)
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
  '            if inhoud.returncode != 0 or soort(tekst) != "doorstuurder":|||            if inhoud.returncode != 0:'
proef "een verwijderde bladzij wordt niet nagekeken" \
  '"D": [commit + "^"]}|||"D": []}'
# De crash van 1-10 (een PNG als tekst gelezen). Twee beschermingen dekken
# elkaar -- alleen .html lezen, en als bytes lezen -- dus pas als ze allebei
# weg zijn, valt de wachter om. Eén van beide weghalen blijft terecht groen.
proef "een figuur wordt als tekst gelezen (beide beschermingen weg)" \
  '        if not bestand.endswith(".html"):
            return False
|||&&&                cwd=wortel, capture_output=True)
            tekst = inhoud.stdout.decode("utf-8", errors="replace")|||                cwd=wortel, capture_output=True, text=True)
            tekst = inhoud.stdout'
proef "bij een wijziging telt de oude versie niet" \
  '{"A": [commit], "M": [commit + "^", commit]|||{"A": [commit], "M": [commit]'
proef "doorstuur-overslag wordt niet meer gemeld" \
  '                if doorgestuurd:|||                if False:'
proef "doorstuurmap telt als thema" \
  '        and not alleen_doorstuurders(os.path.join(vol, d))|||'
proef "elke map telt als doorstuurmap" \
  '            if soort(f.read()) != "doorstuurder":|||            if False:'
# Hoofdstukken en bijlagen (28-10-2026). Het advies zei "twee bijlagen" waar het
# boek er drie had; elke verslapping hieronder laat zo'n getal weer onbewaakt.
proef "hoofdstukken en bijlagen worden nooit vergeleken" \
  'if len(gevonden) != TELWOORDEN[woord.lower()]:|||if False:'
proef "een bijlage wordt niet als bijlage herkend" \
  'if any(t.lower().startswith("bijlage") for t in labels[d])]|||if False]'
proef "hoofdstukken en bijlagen zijn nooit een belofte" \
  '            if kaal.group(1).lower() in TELWOORDEN
        ]|||            if False
        ]'
proef "een map telt mee ook als het boek er niet naar linkt" \
  'mappen = sorted(d for d in labels if os.path.isdir(os.path.join(vol, d)))|||mappen = sorted(d for d in os.listdir(vol) if re.match(r"\d{2}_", d) and os.path.isdir(os.path.join(vol, d)))
    labels = {d: labels.get(d, []) for d in mappen}'
# De spiegel (14-11-2026). Op 12-11 ontbrak Toetsende Statistiek twee dagen op de
# Engelse plank zonder dat iets het zei; elke verslapping hieronder laat dat weer toe.
proef "de spiegel wordt helemaal niet meegeteld" \
  '    bevindingen += gespiegeld|||    pass'
proef "een boek dat op de Engelse plank ontbreekt, telt niet" \
  '        if d not in en_doel:|||        if False:'
proef "de volgorde telt niet" \
  '    if gedeeld_nl != gedeeld_en:|||    if False:'
proef "de thuiskaart wordt niet nagekeken" \
  '            if d not in links:|||            if False:'
proef "een kaart in een commentaar telt als kaart" \
  '        regels = zonder_commentaar(f.read()).splitlines()|||        regels = f.read().splitlines()'
proef "geen Engelse plank telt als niets ontbreekt" \
  '    if not os.path.isfile(os.path.join(wortel, en_plank)):|||    if False:'
proef "geen thuiskaart telt als goed" \
  '        if reden:
            uit.append(Bevinding("blind"|||        if reden and False:
            uit.append(Bevinding("blind"'
# De bijwerkregel (24-11-2026). Ben: "alleen een wanneer was laatste update en een
# zin". Elke verslapping hieronder laat de lijst van 67 woorden weer door, of
# maakt de datum zelf onbewaakt.
proef "een lange bijwerkregel wordt nooit afgekeurd" \
  'if n_zinnen <= MAX_ZINNEN and woorden <= MAX_WOORDEN:|||if True:'
proef "alleen het woordental telt (drie korte zinnen mogen)" \
  'if n_zinnen <= MAX_ZINNEN and woorden <= MAX_WOORDEN:|||if woorden <= MAX_WOORDEN:'
proef "alleen het zinnental telt (één lange lijstzin mag)" \
  'if n_zinnen <= MAX_ZINNEN and woorden <= MAX_WOORDEN:|||if n_zinnen <= MAX_ZINNEN:'
proef "de cursieve datum wordt niet herkend (de vorm van voor 24-11)" \
  'r"\bBijgewerkt[\s:,]+(\d{1,2})|||r"\*\*Bijgewerkt\s+(\d{1,2})&&&(\d{4})", re.IGNORECASE
)|||(\d{4})\*\*", re.IGNORECASE
)'
proef "een dubbele punt achter Bijgewerkt verbergt de datum" \
  'Bijgewerkt[\s:,]+(\d{1,2})|||Bijgewerkt\s+(\d{1,2})'
proef "een commentaar telt als bijwerkregel" \
  'tekst = zonder_voorwerk(zonder_commentaar(f.read()))|||tekst = zonder_voorwerk(f.read())'
proef "de YAML-kop telt als bijwerkregel" \
  'tekst = zonder_voorwerk(zonder_commentaar(f.read()))|||tekst = zonder_commentaar(f.read())'
proef "de bijwerkregel loopt door na een lege regel" \
  'if not r2.strip() or r2.lstrip().startswith((":::", "#")):|||if r2.lstrip().startswith((":::", "#")):'
proef "elke punt met witruimte erna is een zinseinde" \
  'if volgend[:1].isupper() or volgend[:1].isdigit():|||if True:'
proef "Eerste versie is geen bijwerkregel" \
  '|eerste\s+versie|||'
proef "een Engelse maand wordt niet herkend" \
  'if maand not in MAANDEN and maand not in MAANDEN_EN:|||if maand not in MAANDEN:'
proef "de Engelse plank wordt niet op bijwerkregels gelezen" \
  '[args.plank, args.en_plank, args.thuis, args.en_thuis]|||[args.plank, args.thuis, args.en_thuis]'
proef "de Nederlandse thuispagina wordt niet op bijwerkregels gelezen" \
  '[args.plank, args.en_plank, args.thuis, args.en_thuis]|||[args.plank, args.en_plank, args.en_thuis]'
proef "de Engelse thuispagina wordt niet op bijwerkregels gelezen" \
  '[args.plank, args.en_plank, args.thuis, args.en_thuis]|||[args.plank, args.en_plank, args.thuis]'
rm -rf "$M"
[ "$SLECHT" -eq 0 ] || { echo "mutatieproef: $SLECHT proef/proeven zonder uitslag of zonder beet"; exit 1; }
