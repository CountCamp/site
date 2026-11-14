#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""tellerregel.py — één plek die weet hoe de bezoekersteller eruitziet.

Waarom dit een eigen bestandje is
---------------------------------
Drie dingen moeten hetzelfde meten, en zodra ze het ieder voor zich doen lopen
ze uiteen zonder dat iemand het merkt:

  1. `publish_workbook.py`  — zet de teller erin bij het inlezen van een werkboek
  2. `controleer_tellers.py`— loopt de hele site na
  3. de mutatieproef        — moet rood worden als één van beide verslapt

Wat hier gemeten is en waarom het zo moet
-----------------------------------------
De teller stond op drie manieren in de BRONNEN, en dat is geen slordigheid maar
het gevolg van drie verschillende bouwwegen (zo staat hij er nog steeds; op de
gebouwde site vervangt `teller_zetten.py` ze sinds 14-11-2026 alle drie door
het ene blok uit `teller.html` -- zie het tweede deel van dit bestand):

  * de site zelf zette hem tot 14-11-2026 in `<head>` via `_quarto-echt.yml`
    (`include-in-header`), en Quarto knipt die regel over TWEE regels:
        <script data-goatcounter="https://countcamp.goatcounter.com/count"
                async src="//gc.zgo.at/count.js"></script>
  * de broertjes en ggz_vs zetten hem onderaan de `<body>`
    (`include-after-body` in hun eigen `_quarto.yml`)
  * Quarto schrijft `async` soms als `async=""`

Daarom toetsen we NIET op de letterlijke regel. Zoeken naar één schrijfwijze van
iets dat er drie heeft, is precies de val uit huisregel 5(c): de zoekopdracht
komt leeg terug en dat leest als "er staat niets".

We toetsen op TWEE merken die alle drie de vormen gemeen hebben, en we eisen ze
BEIDE. Eén ervan alleen is erger dan geen teller: `data-goatcounter` zonder het
script doet niets en ziet er toch uit als een teller, en `count.js` zonder de
sitecode telt naar niemand. Zo'n halve teller heet hier `half` en wordt hardop
gemeld, nooit stilzwijgend als geteld geboekt.
"""
from __future__ import annotations
import os
import re

# LET OP: REGEL en de twee merken hieronder gaan over de BRONNEN in deze repo,
# en over hoe de teller er vóór de tellerfix uitzag (ontworpen 8-10-2026, spoor
# teller; op main sinds 14-11-2026, spoor teller2). Wat er op de SITE komt, staat
# sindsdien in `_tools/teller.html` en wordt na elke bouw door
# `_tools/teller_zetten.py` in elke bladzij gezet -- zie het tweede deel van dit
# bestand. Een teller in een bron doet daardoor niets meer: de bouw haalt hem
# eruit en zet de ene echte ervoor in de plaats.
# REGEL blijft bestaan omdat `plankwacht.py` er de tellercommit van 30-9 (b9fd33a)
# aan herkent, en omdat `publish_workbook.py` en `controleer_tellers.py --repareer`
# hem nog in bronnen zetten. Verander hem dus niet om de site bij te werken; dat
# doe je in `_tools/teller.html`.
#
# De regel zoals hij op de thuispagina staat. Dit is wat we INVOEGEN; wat we
# ERKENNEN is ruimer (zie de merken hieronder).
REGEL = ('<script data-goatcounter="https://countcamp.goatcounter.com/count" '
         'async src="//gc.zgo.at/count.js"></script>')

# De twee merken. Beide moeten aanwezig zijn. Ze bevatten met opzet geen
# witruimte, want de vorm in `<head>` loopt over twee regels.
MERK_SITECODE = 'data-goatcounter="https://countcamp.goatcounter.com/count"'
MERK_SCRIPT = 'gc.zgo.at/count.js'
# Het eindpunt zonder attribuutnaam: zo staat de sitecode in het blok uit
# `teller.html`. Alleen BINNEN een blok telt dit als merk (zie `tellerstand`).
EINDPUNT = 'https://countcamp.goatcounter.com/count'

# Een doorstuurder is geen bladzij maar machinerie: een meta-refresh die de
# bezoeker meteen verder duwt. Zie de uitleg bij `soort()`.
_REFRESH = re.compile(r'<meta[^>]*http-equiv\s*=\s*["\']?refresh', re.I)
_HEAD_EIND = re.compile(r'</head\s*>', re.I)
_HEAD_START = re.compile(r'<head[\s>]', re.I)


def tellerstand(tekst: str) -> str:
    """`geteld` | `half` | `geen` — wat draagt deze pagina?

    `half` bestaat omdat een halve teller niets telt en er toch uitziet als een
    teller. Wie alleen op `goatcounter` zou zoeken (zoals `bouw_speelkist.py`
    doet) boekt zo'n pagina als in orde.
    """
    sitecode = MERK_SITECODE in tekst
    script = MERK_SCRIPT in tekst
    # Het blok uit `teller.html` (zie het tweede deel van dit bestand) draagt de
    # sitecode NIET als attribuut: de hostwacht zet hem pas met setAttribute,
    # en alleen op countcamp.org. Binnen een blok volstaat daarom het eindpunt.
    # Zonder deze regel heette elke bladzij die de bouw al had nabewerkt `half`
    # -- en dat zijn precies de Engelse bladzijden die `publiceer_en.sh` uit
    # een gebouwde site in en/ zet (`en_bouw.py` eist daar `geteld`).
    for b in _BLOK.findall(tekst):
        sitecode = sitecode or EINDPUNT in b
        script = script or MERK_SCRIPT in b
    if sitecode and script:
        return 'geteld'
    if sitecode or script:
        return 'half'
    return 'geen'


def soort(tekst: str) -> str:
    """`bladzij` | `doorstuurder` | `fragment` — moet hier een teller in?

    `fragment`     — geen `<head>`. Dan is het geen bladzij maar een stuk HTML
                     dat ergens ingeladen wordt; er is geen plek voor een script
                     en een bezoek eraan bestaat niet.
    `doorstuurder` — een `<meta http-equiv="refresh">`. Die pagina's staan onder
                     `werkboeken/`: het oude adres, dat de bezoeker binnen nul
                     seconden naar `/oefenboeken/...` stuurt. Een teller hier zou
                     ÉÉN bezoek TWEE keer boeken (oude pad plus nieuwe pad) en
                     daarmee Bens cijfers vervuilen. Ze zijn bovendien `noindex`.
                     Uitgesloten, maar altijd bij naam genoemd in de uitvoer —
                     een uitsluiting die je niet ziet, is een gat.
    `bladzij`      — al het andere: hier hoort de teller in.
    """
    if not _HEAD_START.search(tekst):
        return 'fragment'
    if _REFRESH.search(tekst):
        return 'doorstuurder'
    return 'bladzij'


def met_teller(tekst: str) -> tuple[str, str]:
    """Geef (nieuwe tekst, wat er gebeurde).

    Uitslagen: `al_goed` · `toegevoegd` · `geen_head` · `half_gevonden`.

    Twee keer invoegen kan niet: staat de teller er al, dan komt de tekst
    onveranderd terug. Een HALVE teller repareren we hier met opzet NIET — dan
    zou het script een kapotte regel stilletijd naast een goede zetten. Dat moet
    iemand zien.
    """
    stand = tellerstand(tekst)
    if stand == 'geteld':
        return tekst, 'al_goed'
    if stand == 'half':
        return tekst, 'half_gevonden'
    m = _HEAD_EIND.search(tekst)
    if not m:
        return tekst, 'geen_head'
    return tekst[:m.start()] + '  ' + REGEL + '\n' + tekst[m.start():], 'toegevoegd'


# ======================================================================
# De gebouwde site — ontworpen 8-10-2026 (spoor teller), op main sinds
# 14-11-2026 (spoor teller2, met de hand overgezet op de main van die dag)
# ----------------------------------------------------------------------
# Wat er op countcamp.org komt, staat in ÉÉN bestand: `_tools/teller.html`.
# Sitecode, script en instellingen veranderen dus op één plek, en de bouw
# (`teller_zetten.py`, een post-render-stap in `_quarto.yml`) zet het na elke
# render in elke bladzij. De wachter (`tellerwacht.py`) leest de gebouwde
# bladzijden na. Beide halen hun kennis hier vandaan.
#
# Waarom de teller in een blok tussen twee merktekens staat
# (`<!-- teller:begin` ... `<!-- teller:eind -->`): zo kan de bouw een OUDE
# versie van het blok herkennen en vervangen. Zonder merktekens zou een nieuwe
# teller naast de vorige komen te staan, en dan telt elk bezoek twee keer.
# ======================================================================

TELLERBESTAND = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'teller.html')
BEGIN = '<!-- teller:begin'
EIND = '<!-- teller:eind -->'

_BLOK = re.compile(r'[ \t]*<!-- teller:begin.*?<!-- teller:eind -->[ \t]*\n?', re.S)
# Een <script>-element, of een commentaar. Het commentaar staat erin zodat een
# bron die de oude regel in een toelichting citeert (manuscript/dankwoord.html
# doet zoiets) niet half wordt weggeknipt: commentaar wordt overgeslagen, niet
# doorzocht.
_SCRIPT = re.compile(r'<!--.*?-->|(?P<s>[ \t]*<script\b[^>]*>.*?</script\s*>[ \t]*\n?)',
                     re.S | re.I)
# Waaraan een teller BUITEN het blok te herkennen is. Met opzet ruim: elke
# schrijfwijze die in deze repo voorkomt (async, async="", data-external="1",
# over twee regels) en ook een count.js die pandoc IN de bladzij heeft gelijfd
# -- die draagt het attribuut nog wel, maar zijn src niet meer.
_LOS_MERK = re.compile(r'data-goatcounter|gc\.zgo\.at', re.I)
# Wat de wachter telt, los van de knipregels hierboven: elke keer dat deze
# woorden ERGENS in de bladzij staan. Bewust dommer dan de knipper, zodat een
# blinde vlek in de knipper niet ook een blinde vlek in de wachter is.
# Het derde merk vangt ook een teller zonder script: GoatCounter biedt een
# <noscript>-pixel aan (<img src="https://….goatcounter.com/count?p=…">), en die
# draagt de eerste twee niet.
RUWE_MERKEN = ('gc.zgo.at', 'data-goatcounter', 'goatcounter.com/count')


def canoniek(pad: str = TELLERBESTAND) -> str:
    """Het blok uit `teller.html`, zoals het in elke bladzij hoort te staan.

    Weigert luid als het bestand niet precies één blok bevat: een teller die
    zijn eigen merktekens mist, kan de bouw bij de volgende render niet meer
    terugvinden, en dan komt de nieuwe ernaast te staan.
    """
    with open(pad, encoding='utf-8') as f:
        tekst = f.read().strip() + '\n'
    if (tekst.count(BEGIN) != 1 or tekst.count(EIND) != 1
            or not tekst.startswith(BEGIN) or not tekst.rstrip().endswith(EIND)):
        raise ValueError('%s moet precies één blok zijn: beginnen met "%s" en '
                         'eindigen met "%s"' % (pad, BEGIN, EIND))
    for merk in RUWE_MERKEN:
        if tekst.count(merk) != 1:
            raise ValueError('%s moet "%s" precies één keer dragen (nu %d) -- de '
                             'wachter telt daarop' % (pad, merk, tekst.count(merk)))
    return tekst


def _losse(tekst: str) -> list[str]:
    """Elke teller BUITEN een blok: een <script> met een GoatCounter-merk."""
    return [m.group('s') for m in _SCRIPT.finditer(_BLOK.sub('', tekst))
            if m.group('s') and _LOS_MERK.search(m.group('s'))]


def ruwe_telling(tekst: str) -> dict[str, int]:
    """Hoe vaak staan de twee merken ergens in de bladzij -- zonder iets te begrijpen."""
    return {merk: tekst.count(merk) for merk in RUWE_MERKEN}


def tellers(tekst: str, blok: str) -> dict[str, int]:
    """Wat draagt deze gebouwde bladzij? Drie getallen, en alleen de eerste mag 1 zijn.

    `goed`       — blokken die letterlijk gelijk zijn aan `teller.html`
    `verouderd`  — blokken met de merktekens, maar een andere inhoud: een
                   vorige versie van de teller, of een met de hand aangepaste
    `los`        — tellers buiten een blok. Die hebben de hostwacht niet, dus
                   op een proefdruk tellen ze gewoon mee.
    """
    blokken = [b.strip() + '\n' for b in _BLOK.findall(tekst)]
    goed = sum(1 for b in blokken if b == blok)
    return {'goed': goed, 'verouderd': len(blokken) - goed, 'los': len(_losse(tekst))}


def zonder_tellers(tekst: str) -> tuple[str, int]:
    """Haal ELKE teller eruit -- blok of los, in welke schrijfwijze ook."""
    tekst, n_blok = _BLOK.subn('', tekst)
    n_los = 0

    def weg(m: re.Match) -> str:
        nonlocal n_los
        if m.group('s') and _LOS_MERK.search(m.group('s')):
            n_los += 1
            return ''
        return m.group(0)

    tekst = _SCRIPT.sub(weg, tekst)
    return tekst, n_blok + n_los


_HEAD_OPEN = re.compile(r'<head\b[^>]*>[ \t]*\n?', re.I)
_CHARSET = re.compile(r'[ \t]*<meta\s+charset\s*=\s*["\']?[\w-]+["\']?\s*/?>[ \t]*\n?', re.I)


def kopplek(tekst: str) -> int | None:
    """Waar de bouw iets in <head> zet: VOORAAN, direct na <meta charset> (of na
    <head> als die er niet is). None als er geen <head> ... </head> is.

    Waarom vooraan en niet vlak voor </head> (14-11-2026, spoor teller2): vlak
    voor </head> zet `taalonderdelen.py` de hreflang-regels en de taalbalk van
    een losse tweeling (tabellen/, solomon, de boekhoofdstukken), en
    `en_bouw.py` eist dat die er "staan zoals taalonderdelen.py ze maakt":
    opnieuw toepassen mag niets veranderen. Met de teller daar tussen schoof de
    volgorde, en zakten 15 van de 16 losse tweelingen (gemeten in
    publiceer_en.sh --alleen-spook). Na <meta charset> en niet ervóór, omdat een
    browser de tekenset alleen in de eerste 1024 bytes zoekt; het blok is
    groter dan dat.
    """
    m = _HEAD_OPEN.search(tekst)
    e = _HEAD_EIND.search(tekst)
    if not m or not e or e.start() < m.end():
        return None
    c = _CHARSET.match(tekst, m.end())
    if not c:
        # de tekenset staat niet als eerste in <head>: zoek hem in de hele kop
        c = _CHARSET.search(tekst, m.end(), e.start())
    return c.end() if c else m.end()


def met_blok(tekst: str, blok: str) -> tuple[str, str]:
    """Haal elke teller eruit en zet het blok er één keer in, vooraan in <head>
    (zie `kopplek`).

    Uitslagen: `al_goed` · `gezet` · `geen_head`. Idempotent: een bladzij die
    al precies het ene goede blok draagt, komt byte voor byte terug.
    """
    t = tellers(tekst, blok)
    if t == {'goed': 1, 'verouderd': 0, 'los': 0}:
        return tekst, 'al_goed'
    kaal, _n = zonder_tellers(tekst)
    plek = kopplek(kaal)
    if plek is None:
        return tekst, 'geen_head'
    return kaal[:plek] + blok + kaal[plek:], 'gezet'
