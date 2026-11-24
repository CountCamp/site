#!/usr/bin/env bash
# ============================================================
# namenwacht_mutatieproef.sh — meet de TOETS, niet de wachter.
#
#   bash _tools/tests/namenwacht_mutatieproef.sh
#
# `namenwacht_test.sh` groen is een bewering: een toets die nooit rood kán
# worden, staat ook groen. Hier wordt telkens één plek kreupel gemaakt -- in de
# wachter, in naar_buiten.sh of in een van de twee Actions, altijd in een kopie --
# en de toets moet dat merken. Blijft hij groen, dan was die plek versiering.
# Afloop: 0 elke mutatie opgemerkt, 1 minstens één versiering of mislukte mutatie.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
zorgelijk=0
getal=0

verminkt() {  # $1 = bron, $2 = uit, $3 = oud, $4 = nieuw  (oud moet er precies één keer in staan)
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import sys
bron, uit, oud, nieuw = sys.argv[1:5]
s = open(bron, encoding="utf-8").read()
if s.count(oud) != 1:
    sys.exit("mutatie niet toepasbaar: %r staat er %d keer in" % (oud[:70], s.count(oud)))
open(uit, "w", encoding="utf-8").write(s.replace(oud, nieuw))
PY
}

proef() {  # $1 = naam, $2 = soort (wachter|pers|publish|proefdruk), $3 = oud, $4 = nieuw
  local naam="$1" soort="$2" bron env
  getal=$((getal + 1))
  rm -rf "$M/k"; mkdir -p "$M/k"
  cp _tools/namenwacht.py "$M/k/"
  case "$soort" in
    wachter)   bron=_tools/namenwacht.py;            env="GEREEDSCHAP=$M/k" ;;
    pers)      bron=_tools/naar_buiten.sh;           env="NAAR_BUITEN=$M/k/naar_buiten.sh" ;;
    publish)   bron=.github/workflows/publish.yml;   env="PUBLISH=$M/k/publish.yml" ;;
    proefdruk) bron=.github/workflows/proefdruk.yml; env="PROEFDRUK=$M/k/proefdruk.yml" ;;
  esac
  if ! verminkt "$bron" "$M/k/$(basename "$bron")" "$3" "$4"; then
    echo "  MISLUKT    $naam -- de mutatie paste niet meer op de code"
    zorgelijk=$((zorgelijk + 1)); return
  fi
  # Een mutant die geen geldige code meer is, valt altijd op -- om de verkeerde reden.
  # Zo telde op 24-11 een syntaxfout als "opgemerkt" (37 zaken rood, A1 voorop), en de
  # mutant erna draaide nooit: twee regels in dit bestand waren aan elkaar geplakt.
  local geldig=0
  case "$bron" in
    *.py) python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' "$M/k/$(basename "$bron")" 2>"$M/syntax" || geldig=1 ;;
    *.sh) bash -n "$M/k/$(basename "$bron")" 2>"$M/syntax" || geldig=1 ;;
  esac
  if [ "$geldig" -ne 0 ]; then
    echo "  MISLUKT    $naam -- de mutant is geen geldige code meer: $(head -1 "$M/syntax")"
    zorgelijk=$((zorgelijk + 1)); return
  fi
  if env "$env" bash _tools/tests/namenwacht_test.sh > "$M/uit" 2>&1; then
    echo "  VERSIERING $naam -- de toets bleef groen"
    zorgelijk=$((zorgelijk + 1))
  else
    echo "  opgemerkt  $naam -- $(command grep -c '^  ZAKT' "$M/uit") zaak/zaken zakten, bv.:"
    command grep -m1 '^  ZAKT' "$M/uit" | sed 's/^  ZAKT  /               /'
  fi
}

echo "nulmeting: het echte gereedschap"
if bash _tools/tests/namenwacht_test.sh > "$M/uit" 2>&1; then
  echo "  ok         $(tail -1 "$M/uit")"
else
  echo "  MISLUKT    de toets staat al rood met het echte gereedschap; dit is geen uitslag"
  tail -8 "$M/uit"; exit 1
fi

echo "mutaties in de wachter"
proef "een van de twee namen vergeten" wachter \
  '_GECODEERD = ("wrnaar", "zvpuryyr")' '_GECODEERD = ("wrnaar",)'
proef "hoofdletters tellen weer" wachter \
  'NAAM_RX = re.compile("|".join(re.escape(n) for n in NAMEN).encode(), re.I)' \
  'NAAM_RX = re.compile("|".join(re.escape(n) for n in NAMEN).encode())'
proef "alleen hele woorden" wachter \
  'NAAM_RX = re.compile("|".join(re.escape(n) for n in NAMEN).encode(), re.I)' \
  'NAAM_RX = re.compile(("\\b(" + "|".join(re.escape(n) for n in NAMEN) + ")\\b").encode(), re.I)'
proef "een zip niet meer openmaken" wachter \
  '    if b[:4] == b"PK\x03\x04" or laag.endswith(".zip"):' '    if False:'
proef "gzip (.RData) niet meer uitpakken" wachter \
  '    for magie, pakker, soort in ((b"\x1f\x8b", gzip.decompress, "gzip"),' \
  '    for magie, pakker, soort in ((b"\x00\x00nooit", gzip.decompress, "gzip"),'
proef "pdf-stromen niet meer uitpakken" wachter \
  '                uit.append(("pdf-stroom %d" % n, zlib.decompress(m.group(1)), "pdf-stroom"))' \
  '                pass'
proef "png-tekststukken niet meer lezen" wachter \
  '            if soort == b"zTXt":' '            if False:'
proef "bestandsnamen niet meer lezen" wachter \
  '        if rx.search(pad.encode()):' '        if False:'
proef "uitzondering te ruim (een voorvoegsel dekt alles wat erop lijkt)" wachter \
  '    return pad.startswith(patroon) if patroon.endswith("/") else pad == patroon' \
  '    return pad.startswith(patroon.rstrip("/"))'
proef "een reden van één woord is genoeg" wachter \
  '            if len(reden) < 20:' '            if False:'
proef "een onbekende soort uitzondering mag" wachter \
  '            if soort not in SOORTEN:' '            if False:'
proef "een bestand dat weg is, telt als schoon" wachter \
  '            blind.append("%s: niet te lezen (%s)" % (pad, e.strerror or e))' '            pass'
proef "een kapotte zip telt als schoon" wachter \
  '            blind.append("%s: niet uit te pakken (%s: %s)" % (pad, type(e).__name__, e))' '            pass'
proef "nul bestanden telt als schoon" wachter \
  '    if not bronnen:
        zeg("KON NIET KIJKEN -- git kent nul' \
  '    if False:
        zeg("KON NIET KIJKEN -- git kent nul'
proef "wacht keurt niets af" wachter \
  '    if fout or in_berichten:' '    if False:'
proef "de buitenste laag van het masker staat uit (zeg print rauw)" wachter \
  '    print(masker(tekst, TOON))' '    print(tekst)'
proef "het masker doet niets (de naam komt in het openbare logboek)" wachter \
  '    if toon:
        return tekst
    # Per naam apart' '    if True:
        return tekst
    # Per naam apart'
proef "het oude masker (NAMEN.index: breekt af op een Turkse İ)" wachter \
  '    for i, n in enumerate(NAMEN):
        tekst = re.sub(re.escape(n), "<naam%d>" % (i + 1), tekst, flags=re.I)
    return tekst' \
  '    return re.sub("|".join(re.escape(n) for n in NAMEN),
                  lambda m: "<naam%d>" % (NAMEN.index(m.group(0).lower()) + 1), tekst, flags=re.I)'
proef "een pdf zonder pdftotext telt als gelezen" wachter \
  '            uit.append(("pdftotext ontbreekt: de tekst van deze pdf is niet gelezen", None, "blind"))' \
  '            pass'
proef "pdftotext draait, maar zijn tekst wordt niet gelezen" wachter \
  '        uit.append(("pdftotext", r.stdout, "pdftotext"))' '        pass'
proef "HTML-entiteiten niet meer terugzetten" wachter \
  '            if b"&" in bb:' '            if False:'
proef "base64-ladingen niet meer uitpakken" wachter \
  '    if b"base64," in b:' '    if False:'
proef "gzip maar één laag uitpakken" wachter \
  '            for deel, bb, manier in uitpakken(naam, inhoud, diepte + 1):
                uit.append(("uitgepakt (%s)' \
  '            for deel, bb, manier in [("", inhoud, "rauw")]:
                uit.append(("uitgepakt (%s)'
proef "commitberichten niet meer lezen" wachter \
  '            n_commits, in_berichten = berichten(repo, bereik)' '            n_commits, in_berichten = 0, []'
proef "een onbekend bereik telt als schoon" wachter \
  '            blind.append("het bereik %s (%s)" % (bereik, e))' '            pass'
proef "tussenversies niet meer lezen (alleen de top)" wachter \
  '            versies = nieuwe_versies(repo, bereik)' '            versies = []'
proef "vergelijk opent een nieuw bestand weer (de crash op een png)" wachter \
  '        if st.startswith("A"):
            zeg("  %-60s nieuw bestand" % pad)
            continue
        oud_b' '        oud_b'
proef "vergelijk telt een veranderd binair bestand als code" wachter \
  '                % (pad, type(e).__name__))
            blind += 1' '                % (pad, type(e).__name__))
            code += 1'
proef "vergelijk negeert de paden" wachter \
  '"--", *paden],' '"--"],'
proef "vergelijk ziet een codewijziging niet" wachter \
  '        if any(x[:1] in "+-" for x in d):
            code += 1' '        if False:
            code += 1'

echo "mutaties in naar_buiten.sh"
proef "--productie stopt niet als de namenpoort rood is" pers \
  '  namen_nakijken blokkerend origin/main..main || { echo "  Niet geleverd."; exit 1; }' \
  '  namen_nakijken blokkerend origin/main..main'
proef "--nakijken roept de namenpoort niet aan" pers \
  '  namen_nakijken       blokkerend "$(nog_te_pushen)" || code=1
' ''
proef "--lokaal roept de namenpoort niet aan" pers \
  '  namen_nakijken melden "$(nog_te_pushen)"
  doe bash _spooksite' '  doe bash _spooksite'
proef "de namenpoort houdt nooit tegen" pers \
  '       echo "  Staat _tools/namenwacht.py er, en draait hij los?" ;;
  esac
  if [ "$streng" = blokkerend ]; then return 1; fi' \
  '       echo "  Staat _tools/namenwacht.py er, en draait hij los?" ;;
  esac'
proef "de namenpoort draait de wachter niet (met berichten)" pers \
  '    python3 "$HIER/_tools/namenwacht.py" --bereik "$bereik" | sed '"'"'s/^/  /'"'"' || code=$?' '    code=0'
proef "--productie leest de commitberichten niet" pers \
  '  namen_nakijken blokkerend origin/main..main ||' '  namen_nakijken blokkerend ||'
proef "--nakijken krijgt nooit een bereik (berichten nooit gelezen)" pers \
  'nog_te_pushen() { git rev-parse --verify --quiet origin/main >/dev/null && echo "origin/main..HEAD" || true; }' \
  'nog_te_pushen() { true; }'

echo "mutaties in de Actions"
proef "publish.yml: de stap draait niet" publish \
  '        run: python3 _tools/namenwacht.py' '        run: echo overgeslagen'
proef "publish.yml: de stap mag falen" publish \
  '        run: python3 _tools/namenwacht.py' '        continue-on-error: true
        run: python3 _tools/namenwacht.py'
proef "proefdruk.yml: de stap draait niet" proefdruk \
  '        run: python3 _tools/namenwacht.py' '        run: echo overgeslagen'
proef "publish.yml: pdftotext wordt niet geïnstalleerd" publish \
  '        run: sudo apt-get update -q && sudo apt-get install -y -q --no-install-recommends poppler-utils' \
  '        run: echo geen'
proef "proefdruk.yml: pdftotext wordt niet geïnstalleerd" proefdruk \
  '        run: sudo apt-get update -q && sudo apt-get install -y -q --no-install-recommends poppler-utils' \
  '        run: echo geen'

echo
if [ "$zorgelijk" -eq 0 ]; then
  echo "elke mutatie werd opgemerkt ($getal van $getal)"
else
  echo "$zorgelijk van $getal mutatie(s) NIET opgemerkt of niet toepasbaar"
fi
[ "$zorgelijk" -eq 0 ]
