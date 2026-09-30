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
De teller staat op drie manieren in de site, en dat is geen slordigheid maar
het gevolg van drie verschillende bouwwegen:

  * de site zelf zet hem in `<head>` via `_quarto-echt.yml`
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
import re

# De regel zoals hij op de thuispagina staat. Dit is wat we INVOEGEN; wat we
# ERKENNEN is ruimer (zie de merken hieronder).
REGEL = ('<script data-goatcounter="https://countcamp.goatcounter.com/count" '
         'async src="//gc.zgo.at/count.js"></script>')

# De twee merken. Beide moeten aanwezig zijn. Ze bevatten met opzet geen
# witruimte, want de vorm in `<head>` loopt over twee regels.
MERK_SITECODE = 'data-goatcounter="https://countcamp.goatcounter.com/count"'
MERK_SCRIPT = 'gc.zgo.at/count.js'

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
