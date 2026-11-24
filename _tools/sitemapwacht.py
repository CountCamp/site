#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""sitemapwacht.py — leest een GEBOUWDE site na: staat elke echte bladzij in de
sitemap, met één canonical naar haar eigen adres, en staat er niets anders in?

    python3 _tools/sitemapwacht.py --echt  [--site _site]   # de echte site
    python3 _tools/sitemapwacht.py --spook [--site _site]   # een proefdruk

Wat er geëist wordt
-------------------
  --echt
    sitemap.xml   bestaat, is geldige XML in de sitemap-naamruimte, elk adres
                  staat er één keer in, begint met https://countcamp.org/, en
                  is nooit de vorm …/index.html (dat is het dubbele adres).
    elk adres     wijst naar een bestand dat er staat en een ECHTE bladzij is:
                  geen doorstuurder, geen fragment, geen noindex, geen 404.html.
                  Daarnaast, als tweede bron: geen enkel oud adres uit
                  _tools/doorstuurders.tsv staat erin.
    elke echte    draagt in <head> precies één <link rel="canonical">, en die
    bladzij       wijst naar haar eigen adres (…/-vorm) -- en dan staat ze in de
                  sitemap -- of, als ze in _tools/canoniek_anders.tsv staat,
                  naar het origineel, en dan staat ze er NIET in.
    hreflang      elke <link rel="alternate" hreflang> op een echte bladzij
                  wijst naar een adres dat in de sitemap staat. Google negeert
                  een hreflang naar een adres dat niet het echte is.
    robots.txt    als hij een Sitemap-regel heeft, wijst die naar
                  https://countcamp.org/sitemap.xml (Quarto schrijft hem zo).
  --spook
    Een proefdruk heeft geen sitemap.xml, en geen robots.txt die naar een
    sitemap wijst (Quarto schrijft er ook bij een lege site-url een, naar
    /sitemap.xml -- gemeten 24-11-2026). En geen enkele canonical is relatief
    of wijst buiten https://countcamp.org: dan zou de proefdruk zichzelf als het
    echte adres opgeven.

Een doorstuurder en een fragment worden verder niet gekeurd, maar wel geteld en
genoemd: een uitsluiting die je niet ziet, is een gat.

Twee manieren van lezen, met opzet
----------------------------------
De bouwstap (sitemap_zetten.py) vindt canonicals met reguliere uitdrukkingen
uit sitemapregel.py. Deze wachter gebruikt Python's html.parser, en leest de
sitemap met een XML-ontleder. Zouden ze dezelfde knipregels gebruiken, dan is
een blinde vlek in de bouw ook een blinde vlek in de wachter. Wat ze delen is
alleen de afspraak (sitemapregel.adres, .is_404, de tabel).

Waar hij draait: in publish.yml tussen bouwen en publiceren, in proefdruk.yml
vóór een PR-proefdruk online gaat, en in naar_buiten.sh na de bouw
(blokkerend op --productie, meldend op --lokaal) -- net als de tellerwacht.

Afloopcode (huisafspraak): 0 in orde · 1 fouten gevonden · 3 kon niet kijken
(geen map, of nul .html gezien -- stilte betekent ongeldig, nooit goed).
"""
from __future__ import annotations
import argparse
import os
import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from urllib.parse import unquote, urljoin

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
from tellerregel import soort  # noqa: E402
import sitemapregel as R  # noqa: E402

REPO = os.path.dirname(HIER)
NS = '{http://www.sitemaps.org/schemas/sitemap/0.9}'
TOON = 8
MAX_ADRESSEN = 50000            # sitemaps.org: per bestand
MAX_BYTES = 50 * 1024 * 1024    # idem, onuitgepakt


class Kop(HTMLParser):
    """Wat staat er in <head>, en wat erbuiten? Alleen <link> en <meta> tellen."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.in_head = False
        self.head_gezien = False
        self.canon_kop: list[str] = []
        self.canon_romp: list[str] = []
        self.hreflang: list[tuple[str, str]] = []
        self.noindex = False

    def handle_starttag(self, tag, attrs):
        a = {k.lower(): (v or '') for k, v in attrs}
        if tag == 'head':
            self.in_head = True
            self.head_gezien = True
        elif tag == 'body':
            self.in_head = False
        elif tag == 'link':
            rels = a.get('rel', '').lower().split()
            if 'canonical' in rels:
                (self.canon_kop if self.in_head else self.canon_romp).append(a.get('href', ''))
            if 'alternate' in rels and 'hreflang' in a:
                self.hreflang.append((a['hreflang'], a.get('href', '')))
        elif tag == 'meta':
            if a.get('name', '').lower() in ('robots', 'googlebot') \
                    and 'noindex' in a.get('content', '').lower():
                self.noindex = True

    handle_startendtag = handle_starttag

    def handle_endtag(self, tag):
        if tag == 'head':
            self.in_head = False


def lees_kop(tekst: str) -> Kop:
    k = Kop()
    k.feed(tekst)
    k.close()
    return k


def lees_sitemap(pad: str) -> tuple[list[str], list[str]]:
    """(adressen, fouten). Fouten zijn bevindingen, geen uitzonderingen."""
    fout = []
    grootte = os.path.getsize(pad)
    if grootte > MAX_BYTES:
        fout.append('sitemap.xml is %d bytes (grens %d)' % (grootte, MAX_BYTES))
    try:
        wortel = ET.parse(pad).getroot()
    except ET.ParseError as e:
        return [], ['sitemap.xml is geen geldige XML: %s' % e]
    if wortel.tag != NS + 'urlset':
        fout.append('sitemap.xml begint met <%s>, verwacht <urlset> in %s' % (wortel.tag, NS))
    adressen = []
    for url in wortel:
        loc = url.find(NS + 'loc')
        if url.tag != NS + 'url' or loc is None or not (loc.text or '').strip():
            fout.append('sitemap.xml: een <url> zonder <loc>')
            continue
        adressen.append(loc.text.strip())
    if len(adressen) > MAX_ADRESSEN:
        fout.append('sitemap.xml heeft %d adressen (grens %d)' % (len(adressen), MAX_ADRESSEN))
    return adressen, fout


def oude_adressen() -> set[str]:
    """De oude adressen uit doorstuurders.tsv met besluit `bouwen` -- de tweede bron."""
    from doorstuurders import lees_tabel, TABEL
    return {r['oud'] for r in lees_tabel(os.path.join(REPO, TABEL)) if r.get('besluit') == 'bouwen'}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--echt', dest='profiel', action='store_const', const='echt')
    g.add_argument('--spook', dest='profiel', action='store_const', const='spook')
    ap.add_argument('--site', default=os.path.join(REPO, '_site'), metavar='PAD')
    ap.add_argument('--anders', default=R.ANDERS_TABEL, metavar='PAD',
                    help='de tabel met kopieën (standaard: _tools/canoniek_anders.tsv)')
    args = ap.parse_args()

    site = os.path.abspath(args.site)
    print('sitemapwacht (%s) -- %s' % (args.profiel, site))
    print('gereedschap: os.walk over elke .html; html.parser voor <head>; '
          'xml.etree voor sitemap.xml')
    if not os.path.isdir(site):
        print('\nKON NIET KIJKEN -- %s bestaat niet. Eerst bouwen.' % site)
        return 3

    fouten: dict[str, list[str]] = {}

    def fout(soort_fout: str, wat: str) -> None:
        fouten.setdefault(soort_fout, []).append(wat)

    # 1. elke .html: wat is het, en wat staat er in de kop
    bladen: dict[str, Kop] = {}
    uitgesloten = {'doorstuurder': [], 'fragment': [], 'noindex': [], '404': []}
    gezien = 0
    for dp, dn, fn in os.walk(site):
        dn.sort()
        for f in sorted(fn):
            if not f.endswith('.html'):
                continue
            pad = os.path.join(dp, f)
            rel = R.site_pad(os.path.relpath(pad, site))
            with open(pad, encoding='utf-8', errors='replace') as h:
                tekst = h.read()
            gezien += 1
            s = soort(tekst)
            if s != 'bladzij':
                uitgesloten[s].append(rel)
                continue
            if R.is_404(rel):
                uitgesloten['404'].append(rel)
                continue
            k = lees_kop(tekst)
            if k.noindex:
                uitgesloten['noindex'].append(rel)
                continue
            bladen[rel] = k

    if gezien == 0:
        print('\nKON NIET KIJKEN -- nul .html gezien in %s. Stilte betekent ongeldig, '
              'nooit goed.' % site)
        return 3

    smp = os.path.join(site, 'sitemap.xml')
    rbt = os.path.join(site, 'robots.txt')
    robots = []
    if os.path.isfile(rbt):
        with open(rbt, encoding='utf-8', errors='replace') as h:
            robots = R.robots_sitemaps(h.read())

    # ---------------------------------------------------------------- spook --
    if args.profiel == 'spook':
        if os.path.exists(smp):
            fout('sitemap in een proefdruk', 'sitemap.xml')
        for r_ in robots:
            fout('robots.txt wijst in een proefdruk naar een sitemap', r_)
        alle = 0
        for dp, dn, fn in os.walk(site):
            for f in fn:
                if not f.endswith('.html'):
                    continue
                pad = os.path.join(dp, f)
                rel = R.site_pad(os.path.relpath(pad, site))
                with open(pad, encoding='utf-8', errors='replace') as h:
                    k = lees_kop(h.read())
                for href in k.canon_kop + k.canon_romp:
                    alle += 1
                    if not href.startswith(R.SITE_URL + '/'):
                        fout('canonical die niet naar countcamp.org wijst',
                             '%s  [%s]' % (rel, href or '(leeg)'))
        print('\n%d html gezien; %d canonical(s), allemaal uit de bronnen (een proefdruk '
              'krijgt er geen bij).' % (gezien, alle))
        return rapport(fouten, 'In orde: geen sitemap in deze proefdruk, en geen canonical '
                       'die de proefdruk als het echte adres opgeeft.')

    # ----------------------------------------------------------------- echt --
    try:
        anders = R.lees_anders(args.anders)
    except ValueError as e:
        print('\nFOUT -- %s' % e)
        return 1

    for r_ in robots:
        if r_ != R.SITE_URL + '/sitemap.xml':
            fout('robots.txt wijst naar een andere sitemap', '%s (verwacht %s/sitemap.xml)'
                 % (r_, R.SITE_URL))
    if not os.path.isfile(smp):
        fout('geen sitemap.xml', smp)
        adressen = []
    else:
        adressen, f_sm = lees_sitemap(smp)
        for f_ in f_sm:
            fout('sitemap.xml kapot', f_)

    in_sitemap: dict[str, str] = {}     # unquote(adres) -> adres
    for a in adressen:
        u = unquote(a)
        if u in in_sitemap:
            fout('adres dubbel in de sitemap', a)
        in_sitemap[u] = a
        if not a.startswith(R.SITE_URL + '/'):
            fout('adres niet op countcamp.org', a)
            continue
        if u.endswith('/index.html'):
            fout('adres in de vorm …/index.html (het dubbele adres)', a)
        rel = R.pad_van_adres(a)
        if rel in bladen:
            continue
        if rel in uitgesloten['doorstuurder']:
            fout('doorstuurder in de sitemap', '%s  [%s]' % (a, rel))
        elif rel in uitgesloten['noindex']:
            fout('noindex-bladzij in de sitemap', '%s  [%s]' % (a, rel))
        elif rel in uitgesloten['404']:
            fout('foutbladzij (404) in de sitemap', '%s  [%s]' % (a, rel))
        elif rel in uitgesloten['fragment']:
            fout('fragment in de sitemap', '%s  [%s]' % (a, rel))
        else:
            fout('adres zonder bladzij', '%s  [%s bestaat niet]' % (a, rel))

    for oud in sorted(oude_adressen()):
        if unquote(R.adres(oud)) in in_sitemap:
            fout('oud adres uit doorstuurders.tsv in de sitemap', oud)

    for kopie, doel in sorted(anders.items()):
        if kopie not in bladen:
            fout('canoniek_anders.tsv klopt niet', '%s is geen echte bladzij' % kopie)
        if doel not in bladen or doel in anders:
            fout('canoniek_anders.tsv klopt niet',
                 '%s wijst naar %s, en dat is geen echte bladzij die naar zichzelf wijst'
                 % (kopie, doel))

    per: dict[str, list[int]] = {}      # afdeling -> [bladzijden, in sitemap, canonical goed]
    for rel, k in sorted(bladen.items()):
        r = per.setdefault(R.afdeling(rel), [0, 0, 0])
        r[0] += 1
        eigen = R.adres(rel)
        verwacht = R.adres(anders[rel]) if rel in anders else eigen
        staat = unquote(eigen) in in_sitemap
        if rel in anders:
            if staat:
                fout('kopie in de sitemap', '%s  [wijst naar %s]' % (rel, anders[rel]))
        else:
            if staat:
                r[1] += 1
            else:
                fout('echte bladzij ontbreekt in de sitemap', rel)
        if k.canon_romp:
            fout('canonical buiten <head> (Google leest hem daar niet)',
                 '%s  [%s]' % (rel, k.canon_romp[0]))
        if not k.canon_kop:
            fout('geen canonical', rel)
        elif len(k.canon_kop) > 1:
            fout('meer dan één canonical', '%s  [%dx]' % (rel, len(k.canon_kop)))
        elif not R.gelijk_adres(k.canon_kop[0], verwacht):
            fout('canonical naar het verkeerde adres',
                 '%s  [%s, verwacht %s]' % (rel, k.canon_kop[0], verwacht))
        else:
            r[2] += 1
        for taal, href in k.hreflang:
            if unquote(urljoin(eigen, href)) not in in_sitemap:
                fout('hreflang naar een adres dat niet in de sitemap staat',
                     '%s  [%s -> %s]' % (rel, taal, href))

    print('')
    print('  %-30s %8s %11s %10s' % ('afdeling', 'bladzij', 'in sitemap', 'canonical'))
    tot = [0, 0, 0]
    for k_ in sorted(per):
        b, s_, c = per[k_]
        tot = [tot[0] + b, tot[1] + s_, tot[2] + c]
        vlag = '' if (s_, c) == (b, b) else '   <--'
        print('  %-30s %8d %11d %10d%s' % (k_, b, s_, c, vlag))
    print('  %-30s %8d %11d %10d' % ('TOTAAL', *tot))
    print('\nsitemap.xml: %d adressen. Niet erin, en ook niet gekeurd op canonical: '
          '%d doorstuurders, %d fragment(en), %d noindex, %d foutbladzij(den) (%s); '
          '%d kopie(ën) uit canoniek_anders.tsv.' % (
              len(adressen), len(uitgesloten['doorstuurder']), len(uitgesloten['fragment']),
              len(uitgesloten['noindex']), len(uitgesloten['404']),
              ', '.join(uitgesloten['404']) or '-', len(anders)))
    if uitgesloten['fragment']:
        print('fragment(en): %s' % ', '.join(uitgesloten['fragment']))
    if uitgesloten['noindex']:
        print('noindex: %s' % ', '.join(uitgesloten['noindex'][:TOON]))
    return rapport(fouten, 'In orde: alle %d echte bladzijden staan in de sitemap of wijzen '
                   'naar hun origineel, en dragen precies één canonical in de vorm …/.'
                   % tot[0])


def rapport(fouten: dict[str, list[str]], schoon: str) -> int:
    if fouten:
        n = sum(len(v) for v in fouten.values())
        print('\nFOUT -- %d bevinding(en):' % n)
        for soort_fout in sorted(fouten):
            lijst = fouten[soort_fout]
            print('  %s: %d' % (soort_fout, len(lijst)))
            for regel in lijst[:TOON]:
                print('      %s' % regel)
            if len(lijst) > TOON:
                print('      ... en nog %d' % (len(lijst) - TOON))
        print('\nHerstellen: python3 _tools/sitemap_zetten.py --echt  (of gewoon opnieuw '
              'quarto render; dat draait hem vanzelf)')
        return 1
    print('\n' + schoon)
    return 0


if __name__ == '__main__':
    sys.exit(main())
