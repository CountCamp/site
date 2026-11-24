#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""commentaarwacht.py — leest een GEBOUWDE site na: staat er ergens nog een HTML-commentaar?

    python3 _tools/commentaarwacht.py                 # _site/
    python3 _tools/commentaarwacht.py --site <map>    # een andere bouw, of een kopie van gh-pages

Wat er geëist wordt
-------------------
Geen enkel `<!-- ... -->` in een .html, op welke diepte ook (dus ook in elk boek
en oefenboek dat als bijlage binnenkomt), behalve wat op de toegestane lijst in
`commentaarregel.py` staat -- en die lijst wordt hieronder bij elke run bij naam
genoemd, met hoe vaak en één voorbeeld. Daarnaast: geen `<!--` in de tekst van
een zoekindex (`search.json`), want die is net zo openbaar als de bladzij.

Wat NIET meetelt, en ook bij naam genoemd wordt: `<!--` in `<script>`, `<style>`
en de andere elementen waar het voor de browser gewone tekst is, en in een
attribuutwaarde. Zie de kop van `commentaarregel.py` voor waarom.

Waarom deze wachter de gebouwde site leest en niet de bronnen
-------------------------------------------------------------
Een commentaar komt langs vijf wegen in een bladzij: de .qmd van de site, de
.qmd van een boek in het lab, een include-bestand (_teller.html, _afterbody.html
in het lab), een Lua-filter, en de hand (de speeltjes). Wat er de deur uitgaat is
`_site/`, en dat is de enige plek waar ze alle vijf samenkomen.

Waar hij draait (23-11-2026, spoor pers_commentaar): in `publish.yml` tussen
bouwen en publiceren, in `proefdruk.yml` vóór een PR-proefdruk online gaat, en in
`naar_buiten.sh` na de bouw (blokkerend op --productie, meldend op --lokaal).
De bouw zelf haalt ze weg (`commentaar_weg.py`, post-render); deze wachter kijkt
of dat gelukt is, met dezelfde ontleder -- maar vóór die ontleder telt hij ook
dom: elke `<!--` in het bestand moet ergens verantwoord zijn (weg, toegestaan,
of overgeslagen met een reden). Klopt die som niet, dan heeft de ontleder een
blinde vlek, en dan zegt de wachter dat hij niet kon kijken.

Tweede eis: het woord dat weg is (24-11-2026, spoor boekvoorpagina_korter)
-----------------------------------------------------------------------
Ben, 24-11-2026: "En we doen geen werk notities meer, alleen maar hier twijfel ik
enzo". Voor een bezoeker heten ze alleen nog "✎ waar ik twijfel" / "✎ where I
have doubts". Dus nergens in wat een bezoeker ziet "werknotitie(s)", "work
note(s)" of "working note(s)" (VERBODEN_ZICHTBAAR, in elke schrijfwijze met
spatie, streepje of zacht afbreekstreepje). Zichtbaar telt hier:
    tekst      tekst in de bladzij (ook <title>), na het terugzetten van entiteiten
    attribuut  title, alt, placeholder, aria-label, aria-description en content
               (de beschrijving in zoekresultaten staat in <meta content>)
    script     een tekenreeks in <script> die op lezerstekst lijkt: hij bevat een
               spatie of een ✎. Zo telt '✎ toon werknotities (' (een knoplabel)
               wél en 'cc-werknotities' of 'meta[name="cc-werknotities"]' (namen
               waar het script mee zoekt) niet. Commentaar in het script telt niet.
    css        een content: "…" in <style> (CSS-commentaar telt niet)
    zoekindex  elke tekst in search.json behalve href en objectID
Interne namen mogen blijven: bestandsnamen, CSS-klassen, meta-namen, namen in een
script, en HTML-commentaar (dat haalt de bouw toch weg). Wat dit NIET ziet: tekst
die een script uit stukjes aan elkaar plakt ('werk' + 'notities'), en een woord in
een plaatje of een pdf. Getoetst in tests/commentaar_test.sh (de zaken "woord").

Afloopcode (huisafspraak): 0 schoon · 1 commentaar of een verboden woord gevonden ·
3 kon niet kijken (geen map, nul .html, een bestand dat niet te lezen is, of een som
die niet klopt -- stilte betekent ongeldig, nooit goed).
"""
from __future__ import annotations
import argparse
import html as htmlmod
import json
import os
import re
import sys

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
try:
    # commentaarregel leest bij het laden _tools/teller.html en de stempels uit
    # en_bouw.py; is daar iets stuk, dan breekt het HIER, en dat is blind (3).
    from commentaarregel import TOEGESTAAN, kort, lees  # noqa: E402
    from tellerwacht import vak  # noqa: E402
except Exception as _e:  # noqa: BLE001
    print('KON NIET KIJKEN -- de ontleder laat zich niet laden: %s: %s' % (type(_e).__name__, _e))
    sys.exit(3)

REPO = os.path.dirname(HIER)
OVERSLAAN = {'.claude', '.git'}   # werkkopieën van zetters; nooit site (zie en_bouw.py, keuring 0)


def json_teksten(x, pad=''):
    """Elke tekenreeks in een JSON-boom, met waar hij staat."""
    if isinstance(x, str):
        yield pad, x
    elif isinstance(x, dict):
        for k, v in x.items():
            yield from json_teksten(v, '%s.%s' % (pad, k) if pad else k)
    elif isinstance(x, list):
        for i, v in enumerate(x):
            yield from json_teksten(v, '%s[%d]' % (pad, i))


# ------------------------------------------------- het woord dat weg is ----
# Ben, 24-11-2026: "En we doen geen werk notities meer, alleen maar hier twijfel ik
# enzo." Zie de kop van dit bestand voor wat hier "zichtbaar" heet.
VERBODEN_ZICHTBAAR = re.compile(r'werk[\s\-­]*notitie|work(?:ing)?[\s\-­]+notes?\b', re.I)
_ZICHTBARE_ATTR = re.compile(
    r'''\s(title|alt|placeholder|aria-label|aria-description|content)\s*=\s*("([^"]*)"|'([^']*)')''', re.I)
_RAUW_BLOK = re.compile(r'(<(script|style)\b[^>]*>)(.*?)(</\2\s*>)', re.I | re.S)
_CSS_CONTENT = re.compile(r'''content\s*:\s*("([^"]*)"|'([^']*)')''', re.I)
ZOEKINDEX_INTERN = {'href', 'objectID'}


def _blank(t: str, b: int, e: int) -> str:
    """Vervang t[b:e] door spaties, met de regelovergangen erin: plekken en
    regelnummers blijven kloppen."""
    return t[:b] + ''.join('\n' if c == '\n' else ' ' for c in t[b:e]) + t[e:]


def js_tekenreeksen(js: str):
    """(plek, inhoud) van elke tekenreeks in een script; commentaar (// en /* */)
    slaat hij over. Een kleine lezer, geen volledige JavaScript-ontleder: een
    reguliere expressie (/…/) ziet hij als code, wat voor deze vraag volstaat."""
    i, n = 0, len(js)
    while i < n:
        c = js[i]
        if js.startswith('//', i):
            e = js.find('\n', i)
            i = n if e < 0 else e
        elif js.startswith('/*', i):
            e = js.find('*/', i + 2)
            i = n if e < 0 else e + 2
        elif c in '"\'`':
            j = i + 1
            while j < n and js[j] != c and not (c != '`' and js[j] == '\n'):
                j += 2 if js[j] == '\\' else 1
            yield i, js[i + 1:j]
            i = j + 1
        else:
            i += 1


def verboden_in_zicht(tekst: str, lz) -> list[tuple[int, str, str]]:
    """(regel, soort, stukje) voor elk zichtbaar voorkomen van VERBODEN_ZICHTBAAR.
    `lz` is de lezing van commentaarregel.lees(tekst): zijn commentaren tellen niet."""
    t = tekst
    for c in lz.commentaren:
        t = _blank(t, c.begin, c.eind)
    uit: list[tuple[int, str, str]] = []

    def meld(plek: int, soort: str, s: str):
        m = VERBODEN_ZICHTBAAR.search(s)
        if m:
            a = max(0, m.start() - 30)
            uit.append((t.count('\n', 0, plek) + 1, soort, ' '.join(s[a:m.end() + 30].split())))

    for m in list(_RAUW_BLOK.finditer(t)):
        b = m.start(3)
        if m.group(2).lower() == 'script':
            for p, s in js_tekenreeksen(m.group(3)):
                if (any(ch.isspace() for ch in s) or '✎' in s) and VERBODEN_ZICHTBAAR.search(s):
                    meld(b + p, 'script', s)
        else:
            css = re.sub(r'/\*.*?\*/', lambda k: ' ' * len(k.group(0)), m.group(3), flags=re.S)
            for k in _CSS_CONTENT.finditer(css):
                meld(b + k.start(), 'css', k.group(2) if k.group(2) is not None else k.group(3))
        t = _blank(t, m.start(3), m.end(3))
    for m in re.finditer(r'<[A-Za-z][^>]*>', t):
        for a in _ZICHTBARE_ATTR.finditer(m.group(0)):
            waarde = a.group(3) if a.group(3) is not None else a.group(4)
            meld(m.start(), 'attribuut ' + a.group(1).lower(), htmlmod.unescape(waarde))
    t = re.sub(r'<[^>]*>', lambda k: ' ' * len(k.group(0)), t)
    plek = 0
    for r in t.split('\n'):
        if VERBODEN_ZICHTBAAR.search(htmlmod.unescape(r)):
            meld(plek, 'tekst', htmlmod.unescape(r))
        plek += len(r) + 1
    return uit


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--site', default=os.path.join(REPO, '_site'), metavar='PAD')
    args = ap.parse_args()
    site = os.path.abspath(args.site)

    print('commentaarwacht -- %s' % site)
    print('gereedschap: os.walk over elke .html en elke search.json; de ontleder uit '
          '_tools/commentaarregel.py (dezelfde als de bouw), plus een domme telling van "<!--"')
    if not os.path.isdir(site):
        print('\nKON NIET KIJKEN -- %s bestaat niet. Eerst bouwen.' % site)
        return 3

    per_vak: dict[str, list[int]] = {}      # vak -> [html, met commentaar, commentaren]
    vondsten: list[str] = []
    toegestaan_n: dict[str, int] = {n: 0 for n, _r, _t in TOEGESTAAN}
    toegestaan_vb: dict[str, str] = {}
    overgeslagen_n: dict[str, int] = {}
    overgeslagen_vb: dict[str, str] = {}
    onleesbaar: list[str] = []
    som_fout: list[str] = []
    zoekindex: list[str] = []
    woorden: list[str] = []     # VERBODEN_ZICHTBAAR in wat een bezoeker ziet
    n_html = n_json = 0

    for dp, dn, fn in os.walk(site):
        dn[:] = sorted(d for d in dn if d not in OVERSLAAN)
        for f in sorted(fn):
            pad = os.path.join(dp, f)
            rel = os.path.relpath(pad, site)
            if f == 'search.json':
                n_json += 1
                try:
                    with open(pad, encoding='utf-8') as h:
                        data = json.load(h)
                except (OSError, ValueError) as e:
                    onleesbaar.append('%s (%s)' % (rel, e))
                    continue
                for waar, s in json_teksten(data):
                    if '<!--' in s:
                        p = s.find('<!--')
                        zoekindex.append('%s: %s: %s' % (rel, waar, kort(s[p:])))
                    m = VERBODEN_ZICHTBAAR.search(s)
                    if m and waar.rsplit('.', 1)[-1] not in ZOEKINDEX_INTERN:
                        a = max(0, m.start() - 30)
                        woorden.append('%s: zoekindex %s: %s' % (rel, waar, ' '.join(s[a:m.end() + 30].split())))
                continue
            if not f.endswith('.html'):
                continue
            n_html += 1
            try:
                with open(pad, encoding='utf-8', errors='strict') as h:
                    tekst = h.read()
            except (OSError, UnicodeDecodeError) as e:
                onleesbaar.append('%s (%s)' % (rel, e))
                continue
            r = per_vak.setdefault(vak(rel), [0, 0, 0])
            r[0] += 1
            lz = lees(tekst)
            for regel, soort, stuk in verboden_in_zicht(tekst, lz):
                woorden.append('%s:%d: %s: %s' % (rel, regel, soort, stuk))
            weg = [c for c in lz.commentaren if c.toegestaan is None]
            for c in lz.commentaren:
                if c.toegestaan:
                    toegestaan_n[c.toegestaan] += 1
                    toegestaan_vb.setdefault(c.toegestaan, '%s:%d: %s' % (rel, c.regel, kort(c.tekst)))
            for soort, regel in lz.overgeslagen:
                overgeslagen_n[soort] = overgeslagen_n.get(soort, 0) + 1
                overgeslagen_vb.setdefault(soort, '%s:%d' % (rel, regel))
            if weg:
                r[1] += 1
                r[2] += len(weg)
                for c in weg:
                    vondsten.append('%s:%d: %s' % (rel, c.regel, kort(c.tekst)))
            # De domme telling: elke "<!--" in het bestand is óf het begin van een
            # commentaar dat de ontleder zag, óf overgeslagen met een reden, óf
            # staat BINNEN een commentaar ("<!-- a <!-- b -->"). Anders is er een
            # "<!--" die de ontleder niet zag -- en dan zegt deze wachter niets.
            binnen = sum(c.tekst.count('<!--', 1) for c in lz.commentaren)
            verantwoord = len(lz.commentaren) + len(lz.overgeslagen) + binnen
            ruw = tekst.count('<!--')
            if ruw != verantwoord:
                som_fout.append('%s: %d keer "<!--" in het bestand, de ontleder verantwoordt er %d'
                                % (rel, ruw, verantwoord))

    if n_html == 0:
        print('\nKON NIET KIJKEN -- nul .html gezien in %s. Stilte betekent ongeldig, '
              'nooit goed.' % site)
        return 3

    if vondsten:
        print('\nCOMMENTAAR IN DE BLADZIJ (%d):' % len(vondsten))
        for v in vondsten:
            print('  ' + v)
    if zoekindex:
        print('\nCOMMENTAAR IN EEN ZOEKINDEX (%d):' % len(zoekindex))
        for v in zoekindex:
            print('  ' + v)
    if woorden:
        print('\nVERBODEN WOORD IN ZICHT (%d) -- "werknotities" / "work notes" heet voor een '
              'bezoeker "waar ik twijfel" / "where I have doubts" (Ben, 24-11-2026):' % len(woorden))
        for v in woorden:
            print('  ' + v)

    print('')
    print('  %-28s %6s %16s %12s' % ('map', 'html', 'met commentaar', 'commentaren'))
    tot = [0, 0, 0]
    for k in sorted(per_vak):
        a, b, c = per_vak[k]
        tot = [tot[0] + a, tot[1] + b, tot[2] + c]
        print('  %-28s %6d %16d %12d%s' % (k, a, b, c, '   <--' if c else ''))
    print('  %-28s %6d %16d %12d' % ('TOTAAL', *tot))
    print('  zoekindexen (search.json) gelezen: %d, met commentaar: %d' % (n_json, len(zoekindex)))

    print('\ntoegestaan (commentaarregel.TOEGESTAAN) -- blijft staan:')
    for naam, reden, _t in TOEGESTAAN:
        print('  %-18s %5dx   %s' % (naam, toegestaan_n[naam], reden))
        if naam in toegestaan_vb:
            print('  %-18s          bv. %s' % ('', toegestaan_vb[naam]))
    if overgeslagen_n:
        print('niet meegeteld, want daar is "<!--" voor de browser tekst:')
        for s in sorted(overgeslagen_n):
            print('  in %-15s %5dx   bv. %s' % (s, overgeslagen_n[s], overgeslagen_vb[s]))

    if onleesbaar:
        print('\nNIET TE LEZEN (%d) -- daarover zegt deze wachter niets:' % len(onleesbaar))
        for o in onleesbaar:
            print('  ' + o)
    if som_fout:
        print('\nSOM KLOPT NIET (%d) -- de ontleder zag hier een "<!--" niet:' % len(som_fout))
        for o in som_fout:
            print('  ' + o)

    print('verboden woord in zicht (werknotitie / work note / working note): %d keer' % len(woorden))
    if woorden:
        print('\nFOUT -- %d keer een verboden woord in zicht. Herstellen in de BRON, niet in '
              '_site/: een .qmd van de site, of in het lab (een knoplabel staat in de afterbody '
              'van het boek). Een interne naam (bestand, klasse, scriptnaam) mag blijven; '
              'zie de kop van _tools/commentaarwacht.py. Staat de vondst onder en/ en is de '
              'en/*.qmd al schoon, dan is de gecommitte Engelse bouw ouder dan zijn bron: '
              'bash _tools/publiceer_en.sh bouwt hem opnieuw.' % len(woorden))
    if vondsten or zoekindex:
        print('\nFOUT -- %d commentaar/commentaren op %d bladzij(den), %d in een zoekindex. '
              'Herstellen: python3 _tools/commentaar_weg.py --site <map> (of gewoon opnieuw '
              'quarto render; dat draait hem vanzelf). Moet er een bij op de toegestane lijst, '
              'zet hem dan in _tools/commentaarregel.py, met wie hem terugleest.'
              % (len(vondsten), tot[1], len(zoekindex)))
        return 1
    if woorden:
        return 1
    if onleesbaar or som_fout:
        print('\nKON NIET (HELEMAAL) KIJKEN -- zie hierboven.')
        return 3
    print('\nSchoon: geen commentaar in %d bladzijden en %d zoekindex(en), op de toegestane '
          'lijst na, en geen verboden woord in zicht.' % (tot[0], n_json))
    return 0


if __name__ == '__main__':
    # Een wachter die breekt, heeft niet gekeken: afloop 3, niet 1. Python's eigen
    # afloop bij een traceback is 1, en die las naar_buiten.sh als "commentaar
    # gevonden" (nakijker 23-11). Zelfde vorm als doorstuurders.py.
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except BaseException as e:  # noqa: BLE001 -- juist alles: elke breuk is blind
        print('KON NIET KIJKEN -- de wachter brak af: %s: %s' % (type(e).__name__, e))
        import traceback
        traceback.print_exc()
        sys.exit(3)
