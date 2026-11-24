#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""sitemap_zetten.py — na elke bouw: een sitemap met élke echte bladzij, en in
elke echte bladzij één canonical naar haar eigen adres.

Draait vanzelf. `_quarto.yml` noemt dit script onder `project: post-render`, dus
het loopt mee met elke `quarto render`. Los draaien kan ook:

    python3 _tools/sitemap_zetten.py --echt  [--site _site]
    python3 _tools/sitemap_zetten.py --spook [--site _site]

Wat het doet
------------
  echt   Leest elke gebouwde .html. Een ECHTE bladzij is een bladzij (geen
         doorstuurder, geen fragment -- zie tellerregel.soort), zonder noindex,
         en geen 404.html. Elke echte bladzij krijgt precies één
         <link rel="canonical"> naar haar eigen adres in de vorm `…/` (zie
         sitemapregel.adres), vooraan in <head>; en sitemap.xml wordt opnieuw
         geschreven met precies die adressen, op volgorde. Quarto's eigen
         sitemap (11 adressen, in de vorm …/index.html) wordt daarmee vervangen.
         Uitzondering: een bladzij in `_tools/canoniek_anders.tsv` wijst naar
         een ander adres en komt zelf niet in de sitemap.
  spook  Een proefdruk heeft geen sitemap: die wordt weggehaald als Quarto er
         een schreef (dat doet hij ook bij een lege site-url), en zijn
         robots.txt die ernaar wijst ook -- maar alleen als die precies is wat
         Quarto schrijft. Er komt geen canonical bij; wat een bron zelf meebrengt,
         blijft staan (dat wijst naar countcamp.org, en dat is voor een
         proefdruk het goede adres).
  en     De Engelse ronde (`--profile en`, naar _site_en/) zet de canonicals,
         net als bij echt, maar schrijft geen sitemap: uit die bouw neemt
         en_bouw.py alleen en/ mee, en de sitemap van de hele site, en/ incluis,
         schrijft de Nederlandse bouw. Waarom dan wel de canonicals: en_bouw.py
         gelijk eist dat elke Engelse bladzij die deze ronde bouwt, in de
         Nederlandse bouw byte voor byte terugkomt. Draagt hij zijn canonical al
         uit de Engelse ronde, dan vindt de Nederlandse bouw hem goed en laat hem
         staan -- zo gaat het met de teller ook. Zonder canonical zette de
         Nederlandse bouw er een bij, en dan zakte elke run van publiceer_en.sh
         op stap 5 (gevonden 24-11-2026, vóór het in gebruik was).
         Een Engelse proefdruk (`--profile en,spook`) doet niets.

De canonical is ook de GoatCounter-reparatie
--------------------------------------------
Ben, 14-11-2026: GoatCounter moet `…/index.html` tellen als `…/`. Dat doet
deze canonical, zonder dat _tools/teller.html verandert: count.js neemt het pad
uit de eerste <link rel="canonical"> als die op dezelfde host staat, en valt
alleen zonder canonical terug op location.pathname. Nagelezen op 24-11-2026 in
de bron (gc.zgo.at/count.js, gelijk aan public/count.js in arp242/goatcounter,
functie get_path) en in de handleiding (goatcounter.com/help/js: "Default is
the value of <link rel="canonical"> if it exists"). De server haalt daarna de
schuine streep aan het eind weg (hit.go, cleanPath), dus `/oefenboeken/` en
`/oefenboeken/index.html` worden allebei de bestaande rij `/oefenboeken`. Oude
bezoeken onder `…/index.html` blijven een eigen rij; die schuift dit niet om.
Een tweede canonical zou dit breken: count.js neemt de eerste, Google negeert
ze dan allemaal. Daarom vervangt dit script een canonical, en zet het er nooit
een naast.

Waar het in <head> komt, en waarom
----------------------------------
Vooraan, direct na <meta charset> (tellerregel.kopplek), net als de teller. Vlak
voor </head> zet taalonderdelen.py de hreflang-regels van een losse tweeling, en
en_bouw.py eist dat opnieuw toepassen daar niets verandert; een teller op die
plek liet op 14-11-2026 15 van de 16 losse tweelingen zakken (zie kopplek).

Weigeren (afloop 1)
-------------------
  * een bladzij draagt een canonical naar een ANDERE bladzij, en staat niet in
    canoniek_anders.tsv -- dan zegt een bron iets wat de site niet besloot;
  * een regel in canoniek_anders.tsv wijst naar iets dat geen echte bladzij is,
    of naar een bladzij die zelf een kopie is (een ketting);
  * een echte bladzij zonder <head> ... </head>.
Niets gezien (afloop 3): nul .html in de uitvoermap.

Wat het NIET doet: `lastmod`. Quarto zette de wijzigingstijd van het bestand,
en in de GitHub Action is dat voor elk bestand het moment van uitchecken -- een
datum die niets zegt. Google gebruikt lastmod alleen als hij "consistently and
verifiably accurate" is; een datum die bij elke publicatie voor alle bladzijden
verspringt, leert hem het veld te negeren. Liever geen dan een verkeerde.
Ook geen hreflang in de sitemap: elke tweeling draagt die al in <head>
(taalwissel.lua, taalonderdelen.py), en een tweede opgave kan alleen uiteenlopen
met de eerste. sitemapwacht.py toetst wel dat elke hreflang naar een adres in
de sitemap wijst.
En niet Quarto's eigen `canonical-url: true` (sinds 1.4, voor index-bladzijden
pas goed sinds 1.5): dat bereikt alleen wat Quarto zelf rendert, 12 van de 276
bladzijden, en zou naast deze stap een tweede bron van canonicals zijn.

Afloopcode: 0 klaar, 1 weigert, 3 niets gezien.
"""
from __future__ import annotations
import argparse
import os
import sys
from xml.sax.saxutils import escape

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
from tellerregel import kopplek, soort  # noqa: E402
from teller_zetten import profiel_uit_omgeving  # noqa: E402
import sitemapregel as R  # noqa: E402

REPO = os.path.dirname(HIER)
TOON = 8


def taal_uit_omgeving() -> str:
    """`en` als dit de Engelse ronde is, anders `nl` (zie de kop van teller_zetten.py
    voor wat Quarto in QUARTO_PROFILE zet)."""
    profielen = [p.strip() for p in os.environ.get('QUARTO_PROFILE', '').split(',') if p.strip()]
    return 'en' if 'en' in profielen else 'nl'


def sitemap_xml(adressen: list[str]) -> str:
    regels = ['<?xml version="1.0" encoding="UTF-8"?>',
              '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for a in adressen:
        regels.append('  <url><loc>%s</loc></url>' % escape(a))
    regels.append('</urlset>')
    return '\n'.join(regels) + '\n'


def lees(pad: str) -> str:
    with open(pad, encoding='utf-8', errors='surrogateescape') as h:
        return h.read()


def schrijf(pad: str, tekst: str) -> None:
    with open(pad, 'w', encoding='utf-8', errors='surrogateescape') as h:
        h.write(tekst)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group()
    g.add_argument('--echt', dest='profiel', action='store_const', const='echt')
    g.add_argument('--spook', dest='profiel', action='store_const', const='spook')
    ap.add_argument('--site', default=os.environ.get('QUARTO_PROJECT_OUTPUT_DIR')
                    or os.path.join(REPO, '_site'))
    ap.add_argument('--anders', default=R.ANDERS_TABEL, metavar='PAD',
                    help='de tabel met kopieën (standaard: _tools/canoniek_anders.tsv)')
    args = ap.parse_args()

    site = os.path.abspath(args.site)
    engels = args.profiel is None and taal_uit_omgeving() == 'en'
    profiel = args.profiel or profiel_uit_omgeving()
    if engels and profiel == 'spook':
        print('sitemap_zetten: Engelse proefdruk -- niets gedaan (geen sitemap, geen '
              'canonical; en_bouw.py neemt hier alleen en/ uit mee).')
        return 0
    if profiel is None:
        print('sitemap_zetten: WEIGER -- QUARTO_PROFILE is %r. Ik ken alleen `echt` en '
              '`spook`, en zonder dat te weten kan ik niet zeggen of hier een sitemap '
              'in hoort of juist niet.' % os.environ.get('QUARTO_PROFILE'))
        return 1

    smp = os.path.join(site, 'sitemap.xml')
    bladen: dict[str, str] = {}          # sitepad -> tekst, alleen echte bladzijden
    soorten = {'bladzij': 0, 'doorstuurder': 0, 'fragment': 0, 'noindex': 0, '404': 0}
    gezien = 0
    for dp, dn, fn in os.walk(site):
        dn.sort()
        for f in sorted(fn):
            if not f.endswith('.html'):
                continue
            pad = os.path.join(dp, f)
            rel = R.site_pad(os.path.relpath(pad, site))
            tekst = lees(pad)
            gezien += 1
            s = soort(tekst)
            if s != 'bladzij':
                soorten[s] += 1
            elif R.is_404(rel):
                soorten['404'] += 1
            elif R.noindex(tekst):
                soorten['noindex'] += 1
            else:
                soorten['bladzij'] += 1
                bladen[rel] = tekst

    if gezien == 0:
        print('sitemap_zetten: NIETS GEZIEN in %s -- dat is geen schone bouw maar een '
              'blinde.' % site)
        return 3

    if profiel == 'spook':
        # Quarto schrijft ook met een lege site-url een sitemap (gemeten 24-11-2026,
        # 1.9.38: adressen als /index.html), en een robots.txt die ernaar wijst. Die
        # robots.txt gaat alleen weg als hij precies is wat Quarto schrijft: één
        # Sitemap-regel. Een eigen robots.txt blijft staan, en wordt genoemd.
        weg = []
        if os.path.isfile(smp):
            os.remove(smp)
            weg.append('sitemap.xml')
        rbt = os.path.join(site, 'robots.txt')
        if os.path.isfile(rbt):
            if R.is_quarto_robots(lees(rbt)):
                os.remove(rbt)
                weg.append('robots.txt')
            else:
                print('sitemap_zetten (spook): robots.txt is niet die van Quarto en blijft '
                      'staan -- kijk of hij naar een sitemap wijst.')
        print('sitemap_zetten (spook): %d html in %s; een proefdruk heeft geen sitemap%s, '
              'en krijgt geen canonical.' % (
                  gezien, os.path.relpath(site, REPO),
                  (' (weggehaald wat Quarto schreef: %s)' % ', '.join(weg)) if weg else ''))
        return 0

    try:
        anders = R.lees_anders(args.anders)
    except ValueError as e:
        print('sitemap_zetten: WEIGER -- %s' % e)
        return 1

    weiger: list[str] = []
    # De Engelse ronde ziet alleen en/: de tabel nakijken kan alleen de Nederlandse
    # bouw, die de hele site ziet. Hier geldt een regel alleen voor wat er staat.
    for kopie, doel in sorted(anders.items()) if not engels else []:
        if kopie not in bladen:
            weiger.append('%s staat in %s, maar is geen echte bladzij van deze bouw'
                          % (kopie, os.path.basename(args.anders)))
        if doel not in bladen:
            weiger.append('%s wijst naar %s, en dat is geen echte bladzij van deze bouw'
                          % (kopie, doel))
        elif doel in anders:
            weiger.append('%s wijst naar %s, en die is zelf een kopie (ketting)' % (kopie, doel))

    nieuw: dict[str, str] = {}
    for rel, tekst in bladen.items():
        doel = R.adres(anders.get(rel, rel))
        bestaand = R.canonicals(tekst)
        # Naar zichzelf of naar het doel uit de tabel: dat vervangt de bouw. Al het
        # andere zegt iets wat de site niet besloot.
        vreemd = [h for h in bestaand
                  if not (R.gelijk_adres(h, doel) or R.gelijk_adres(h, R.adres(rel)))]
        if vreemd:
            weiger.append('%s draagt al een canonical naar %s, en verwacht is %s. Staat dat '
                          'zo in de bron, zet de bladzij dan in canoniek_anders.tsv of haal '
                          'het uit de bron.' % (rel, vreemd[0], doel))
            continue
        if bestaand == [doel]:
            continue
        kaal = R.zonder_canonicals(tekst)
        plek = kopplek(kaal)
        if plek is None:
            weiger.append('%s heeft geen <head> ... </head>; daar kan geen canonical in' % rel)
            continue
        nieuw[rel] = kaal[:plek] + R.canonical_regel(doel) + kaal[plek:]

    if weiger:
        print('sitemap_zetten: WEIGER -- %d probleem/problemen; er is niets geschreven:'
              % len(weiger))
        for w in weiger[:TOON * 3]:
            print('    %s' % w)
        if len(weiger) > TOON * 3:
            print('    ... en nog %d' % (len(weiger) - TOON * 3))
        return 1

    for rel, tekst in nieuw.items():
        schrijf(os.path.join(site, rel), tekst)

    if engels:
        print('sitemap_zetten (Engelse ronde): %d html in %s -- canonical gezet in %d van de '
              '%d echte bladzijden, %d hadden hem al goed. Geen sitemap: die schrijft de '
              'Nederlandse bouw voor de hele site, en/ incluis.' % (
                  gezien, os.path.relpath(site, REPO), len(nieuw), len(bladen),
                  len(bladen) - len(nieuw)))
        return 0

    adressen = sorted(R.adres(rel) for rel in bladen if rel not in anders)
    xml = sitemap_xml(adressen)
    oud = lees(smp) if os.path.isfile(smp) else None
    if oud != xml:
        schrijf(smp, xml)

    per: dict[str, int] = {}
    for rel in bladen:
        if rel not in anders:
            per[R.afdeling(rel)] = per.get(R.afdeling(rel), 0) + 1
    print('sitemap_zetten (echt): %d html in %s -- %d echte bladzijden; buiten de sitemap: '
          '%d doorstuurders, %d fragmenten, %d noindex, %d foutbladzijden (404), %d kopieën '
          '(canoniek_anders.tsv)' % (
              gezien, os.path.relpath(site, REPO), soorten['bladzij'], soorten['doorstuurder'],
              soorten['fragment'], soorten['noindex'], soorten['404'], len(anders)))
    print('sitemap_zetten: sitemap.xml %s met %d adressen; canonical gezet in %d bladzijden, '
          '%d hadden hem al goed' % ('geschreven' if oud != xml else 'ongewijzigd',
                                     len(adressen), len(nieuw), len(bladen) - len(nieuw)))
    print('sitemap_zetten: per afdeling: %s' % ', '.join(
        '%s %d' % (k, per[k]) for k in sorted(per)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
