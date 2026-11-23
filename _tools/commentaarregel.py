#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""commentaarregel.py — één plek die weet wat een HTML-commentaar is, en welke mag blijven.

Waarom dit bestaat (23-11-2026, spoor pers_commentaar)
------------------------------------------------------
Quarto zet een `<!-- ... -->` uit een .qmd onveranderd in de gebouwde bladzij. Wat
de lezer ziet blijft netjes, maar wie de paginabron opent leest mee: in het
Oefenboek TS stonden zo bronnotities als 'hand-out college 4 (2026-27)' en
'Leidens 4.0c' live (gevonden door spoor ts_vaktermen, 13-11). Ben, 23-11-2026:
"uit de pagina halen vóór publiceren (alle boeken); redenen in ONTWERP.md, qmd
houdt korte verwijzing".

Drie dingen moeten hier hetzelfde onder een commentaar verstaan, en zodra ze het
ieder voor zich doen lopen ze uiteen zonder dat iemand het merkt:

  1. `commentaar_weg.py`  — haalt ze na elke bouw uit de bladzij (post-render)
  2. `commentaarwacht.py` — leest de gebouwde site na vóór er iets live gaat
  3. de bijtproef         — `tests/commentaar_test.sh`

Wat een commentaar is: wat de BROWSER er een vindt
--------------------------------------------------
Geen reguliere expressie over de hele bladzij, maar een kleine ontleder die de
HTML5-regels volgt waar het hier om draait. Het verschil doet ertoe:

  * in `<script>` en `<style>` (en `<textarea>`, `<title>`, `<xmp>`, `<iframe>`,
    `<noembed>`, `<noframes>`) is `<!--` gewone tekst. Een JavaScript-string
    `'<!-- x -->'` is geen commentaar, en wie hem wegknipt breekt het script.
    Die inhoud blijft dus byte voor byte staan;
  * in een attribuutwaarde (`title="<!-- x -->"`) is het ook tekst;
  * in `<pre>` en `<code>` is `<!--` WEL een commentaar: de browser verbergt het.
    Wat een codeblok TOONT, staat er als `&lt;!--`, en dat raakt deze ontleder
    nooit aan. Een commentaar in een codeblok weghalen verandert dus niets aan
    wat de lezer ziet; alleen de regel eromheen laten we dan staan (zie
    `zonder_commentaar`), want in `<pre>` telt elke regelovergang;
  * een commentaar eindigt bij de eerste `-->` of `--!>`; `<!-->` en `<!--->`
    zijn lege commentaren (HTML5, "abrupt closing of empty comment").

Waarom geen `html.parser` uit de standaardbibliotheek: die verandert van gedrag
tussen Python-versies (de commentaarregels zijn in 2025 bijgesteld), en de
GitHub Action draait een andere Python dan broodje. Een ontleder van honderd
regels die we zelf toetsen, gedraagt zich overal hetzelfde.

WAT DIT NIET DEKT. Inline SVG of MathML (foreign content): daar is `<style>` geen
rauwe tekst en een commentaar erin een echt commentaar, maar deze ontleder laat
het staan alsof het CSS is. Een `<!--<script>`-truc binnen een script (het
"double escaped"-geval van HTML5) volgen we niet: het script eindigt hier bij de
eerste `</script`. Allebei komen in de gebouwde site niet voor (gemeten
23-11-2026 op gh-pages 048af1d, zie het rapport van spoor pers_commentaar); de
wachter zou er niets van zien, net zo min als dit filter.

De toegestane lijst — kort, en elk met een reden
------------------------------------------------
Alleen wat een MACHINE terugleest mag blijven staan. Een commentaar dat niemand
leest maar ook geen kwaad doet (Quarto zet er een paar neer) gaat gewoon mee
weg: weghalen kost niets, toestaan is een regel die iemand moet bijhouden.
Elke vorm hieronder wordt gehaald waar hij gemaakt wordt, nooit overgetikt.
"""
from __future__ import annotations
import os
import re
import sys
from dataclasses import dataclass

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
from tellerregel import canoniek  # noqa: E402
from en_bouw import LAB_STEMPEL, WERKBOEK_STEMPEL  # noqa: E402

# Elementen waarvan de inhoud voor de browser tekst is, geen HTML. `plaintext`
# loopt tot het eind van het bestand.
RAUW = frozenset({'script', 'style', 'textarea', 'title', 'xmp', 'iframe',
                  'noembed', 'noframes', 'plaintext'})
_NAAM_EIND = re.compile(r'[\t\n\f\r />]')
_SPATIE = ' \t\n\f\r'


def _teller_merken() -> tuple[str, str]:
    """De twee merktekens uit `_tools/teller.html`: de eerste en de laatste regel.

    Gelezen uit het bestand zelf (via `tellerregel.canoniek`, die al weigert als
    het blok niet precies één begin en één eind heeft), zodat een nieuwe tekst
    in het merkteken hier vanzelf meekomt.
    """
    regels = canoniek().strip().splitlines()
    return regels[0].strip(), regels[-1].strip()


TELLER_BEGIN, TELLER_EIND = _teller_merken()

# INGETROKKEN (23-11-2026, nakijker van spoor pers_commentaar): een vierde recht,
# 'conditioneel', voor IE-commentaren (`<!--[if lt IE 9]> ... <![endif]-->`). De
# toets liet ALLES tussen `]>` en `<![endif]` door: `<!--[if IE]> MIEKE: geheim
# <![endif]-->` gaf afloop 0 en bleef staan. Geen machine leest die vorm terug,
# en hij stond 0 keer op de site (live en nieuw) -- dus geen recht, gewoon weg.

# (naam, wie leest het terug, toets op de hele `<!-- ... -->`)
TOEGESTAAN = (
    ('teller',
     'de merktekens rond de bezoekersteller (_tools/teller.html); tellerregel.py '
     'herkent het blok eraan, tellerwacht.py eist het blok letterlijk',
     lambda c: c in (TELLER_BEGIN, TELLER_EIND)),
    ('lab-stempel',
     'de stempel van de boekpers in het lab (pub_stempel_zet); lever.sh --push '
     'zoekt hem op de LIVE bladzij, en en_bouw.py keur leest hem in de bouw '
     '(LAB_STEMPEL)',
     lambda c: bool(LAB_STEMPEL.fullmatch(c))),
    ('oefenboek-stempel',
     'de stempel van publish_workbook.py; en_bouw.py keur leest hem in de bouw '
     '(WERKBOEK_STEMPEL)',
     lambda c: bool(WERKBOEK_STEMPEL.fullmatch(c))),
)


def toegestaan(c: str) -> str | None:
    """De naam uit TOEGESTAAN waaronder dit commentaar mag blijven, of None."""
    for naam, _reden, toets in TOEGESTAAN:
        if toets(c):
            return naam
    return None


@dataclass
class Commentaar:
    begin: int            # plek in de tekst (tekens, niet bytes)
    eind: int             # net voorbij de afsluitende >
    tekst: str            # het hele commentaar, <!-- en --> erbij
    regel: int            # regelnummer van het begin, vanaf 1
    in_pre: bool          # staat het in <pre> (dan telt de regel eromheen)
    toegestaan: str | None


@dataclass
class Lezing:
    commentaren: list[Commentaar]
    # Elke `<!--` die GEEN commentaar is, met waar hij staat. Alleen om te tonen
    # wat er overgeslagen is en waarom -- een uitsluiting die je niet ziet is een gat.
    overgeslagen: list[tuple[str, int]]   # (in welk element / 'attribuut', regel)


def _einde_commentaar(t: str, i: int) -> int:
    """`t[i:]` begint met `<!--`; geef de plek net voorbij het einde."""
    j = i + 4
    if t.startswith('>', j):
        return j + 1                       # <!-->
    if t.startswith('->', j):
        return j + 2                       # <!--->
    a = t.find('-->', j)
    b = t.find('--!>', j)
    kandidaten = [k + 3 for k in (a,) if k >= 0] + [k + 4 for k in (b,) if k >= 0]
    return min(kandidaten) if kandidaten else len(t)


def _einde_tag(t: str, i: int, n_attr: list[int]) -> int:
    """`t[i]` staat net na de tagnaam; loop de attributen af tot en met `>`.
    Telt in `n_attr` hoe vaak er `<!--` in een attribuutwaarde stond."""
    n = len(t)
    while i < n:
        c = t[i]
        if c == '>':
            return i + 1
        if c in _SPATIE or c == '/':
            i += 1
            continue
        # attribuutnaam
        while i < n and t[i] not in _SPATIE and t[i] not in '/>=':
            i += 1
        while i < n and t[i] in _SPATIE:
            i += 1
        if i < n and t[i] == '=':
            i += 1
            while i < n and t[i] in _SPATIE:
                i += 1
            if i < n and t[i] in '"\'':
                q = t[i]
                e = t.find(q, i + 1)
                e = n if e < 0 else e
                n_attr[0] += t.count('<!--', i, e)
                i = e + 1
            else:
                s = i
                while i < n and t[i] not in _SPATIE and t[i] != '>':
                    i += 1
                n_attr[0] += t.count('<!--', s, i)
    return n


def lees(t: str) -> Lezing:
    """Loop de bladzij één keer af en geef elk echt commentaar, met wat er
    overgeslagen werd."""
    n = len(t)
    i = 0
    pre = 0
    commentaren: list[Commentaar] = []
    overgeslagen: list[tuple[str, int]] = []
    # Regelnummers lopend bijhouden: de plekken komen op volgorde langs, dus elke
    # \n wordt maar één keer geteld (een bladzij van het boek is 0,5 MB).
    stand = [0, 1]   # [plek, regel op die plek]

    def regel(p: int) -> int:
        if p < stand[0]:
            return t.count('\n', 0, p) + 1
        stand[1] += t.count('\n', stand[0], p)
        stand[0] = p
        return stand[1]

    while True:
        i = t.find('<', i)
        if i < 0 or i >= n:
            break
        if t.startswith('<!--', i):
            e = _einde_commentaar(t, i)
            c = t[i:e]
            commentaren.append(Commentaar(i, e, c, regel(i), pre > 0, toegestaan(c)))
            i = e
            continue
        if t.startswith('<![CDATA[', i):
            e = t.find(']]>', i)
            e = n if e < 0 else e + 3
            for _ in range(t.count('<!--', i, e)):
                overgeslagen.append(('cdata', regel(i)))
            i = e
            continue
        if t.startswith('<!', i) or t.startswith('<?', i):
            # doctype of "bogus comment": tot de eerste >
            e = t.find('>', i)
            e = n if e < 0 else e + 1
            for _ in range(t.count('<!--', i, e)):
                overgeslagen.append(('bogus', regel(i)))
            i = e
            continue
        eind_tag = t.startswith('</', i)
        s = i + 2 if eind_tag else i + 1
        if s >= n or not t[s].isascii() or not t[s].isalpha():
            i += 1
            continue
        m = _NAAM_EIND.search(t, s)
        k = m.start() if m else n
        naam = t[s:k].lower()
        n_attr = [0]
        e = _einde_tag(t, k, n_attr)
        for _ in range(n_attr[0]):
            overgeslagen.append(('attribuut', regel(i)))
        if eind_tag:
            if naam == 'pre':
                pre = max(0, pre - 1)
            i = e
            continue
        if naam == 'pre':
            pre += 1
        if naam in RAUW:
            if naam == 'plaintext':
                slot = n
            else:
                ms = re.compile(r'</' + naam + r'[\t\n\f\r />]', re.I).search(t, e)
                slot = ms.start() if ms else n
            for _ in range(t.count('<!--', e, slot)):
                overgeslagen.append((naam, regel(e)))
            i = slot
            continue
        i = e
    return Lezing(commentaren, overgeslagen)


def _een_ronde(t: str) -> tuple[str, list[Commentaar], list[Commentaar]]:
    lz = lees(t)
    weg = [c for c in lz.commentaren if c.toegestaan is None]
    bewaard = [c for c in lz.commentaren if c.toegestaan is not None]
    if not weg:
        return t, [], bewaard
    stukken = []
    p = 0
    for c in weg:
        b, e = c.begin, c.eind
        if not c.in_pre:
            # Staat het commentaar alleen op zijn regel(s), dan gaat de hele regel
            # mee: anders blijft er een lege regel staan waar het stond.
            lb = t.rfind('\n', 0, b) + 1
            le = t.find('\n', e)
            le = len(t) if le < 0 else le
            if t[lb:b].strip(' \t') == '' and t[e:le].strip(' \t\r') == '' and lb >= p:
                b = lb
                e = le + 1 if le < len(t) else le
        stukken.append(t[p:b])
        p = e
    stukken.append(t[p:])
    return ''.join(stukken), weg, bewaard


def zonder_commentaar(t: str) -> tuple[str, list[Commentaar], list[Commentaar]]:
    """Geef (nieuwe tekst, weggehaald, bewaard). Idempotent: draai je hem op zijn
    eigen uitkomst, dan komt die byte voor byte terug.

    Eén ronde, en dan WEIGEREN als weghalen een nieuw commentaar maakte. In een
    zeldzaam geval plakt het weghalen twee stukken tekst tot een nieuw `<!--`:
    `3 <<!-- x -->!-- zichtbaar` wordt `3 <!-- zichtbaar`. De browser toonde daar
    `<!-- zichtbaar` als tekst. Tot 23-11 haalde een tweede ronde dat ook weg, en
    dan verdween zichtbare tekst -- bij een `<!--` dat nooit sluit de rest van de
    bladzij -- terwijl de wachter daarna 'schoon' zei (de nakijker van dit spoor
    mat het). Nu stopt de bouw (RuntimeError; commentaar_weg.py geeft afloop 3)
    en kijkt een mens. Op de echte site kwam het 0 keer voor: pandoc schrijft een
    losse `<` als `&lt;`.
    """
    t, weg, bewaard = _een_ronde(t)
    _nog, nieuw, _b = _een_ronde(t)
    if nieuw:
        raise RuntimeError('commentaarregel: weghalen maakte een nieuw commentaar (%s, regel %d) -- '
                           'daar stond zichtbare tekst; kijk er met de hand naar'
                           % (kort(nieuw[0].tekst, 60), nieuw[0].regel))
    return t, weg, bewaard


def kort(c: str, breed: int = 80) -> str:
    """De eerste `breed` tekens van een commentaar, op één regel."""
    return re.sub(r'\s+', ' ', c)[:breed]
