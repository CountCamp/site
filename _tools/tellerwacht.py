#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""tellerwacht.py — leest een GEBOUWDE site na: telt elke bladzij precies één keer?

    python3 _tools/tellerwacht.py --echt  [--site _site]   # de echte site
    python3 _tools/tellerwacht.py --spook [--site _site]   # een proefdruk

Wat er geëist wordt
-------------------
  --echt   elke bladzij draagt precies één teller, en dat is letterlijk het
           blok uit `_tools/teller.html` -- dus mét de hostwacht. Geen tweede,
           geen losse (een losse teller heeft die wacht niet en telt op een
           proefdruk gewoon mee), geen verouderde. En geen proefdruk-balk.
  --spook  geen enkele teller, in geen enkele vorm; op elke bladzij precies één
           proefdruk-balk en een `noindex`.

  Een doorstuurder mag in beide gevallen geen teller dragen (één bezoek, twee
  tellingen). Een fragment zonder <head> wordt niet gekeurd. Beide worden bij
  naam genoemd: een uitsluiting die je niet ziet, is een gat.

Waarom deze wachter de gebouwde site leest en niet de bronnen
-------------------------------------------------------------
Wat er de deur uitgaat is `_site/`, niet de repo. De andere wachters kijken naar
één bladzij in `_site` (`naar_buiten.sh`: index.html) of naar de bronnen van de
bijlagen (`controleer_tellers.py`). Allebei zagen ze daardoor niet dat een
proefdruk op 201 bladzijden gewoon meetelde (8-10-2026; op 14-11 224 van de 243).

Waar hij draait (14-11-2026, spoor teller2): in `publish.yml` tussen bouwen en
publiceren, in `proefdruk.yml` vóór een PR-proefdruk online gaat, en in
`naar_buiten.sh` na de bouw (blokkerend op --productie, meldend op --lokaal).

Twee tellingen, met opzet
-------------------------
De wachter telt ÉN begrijpend (blokken en <script>-elementen, met de regels uit
`tellerregel.py` die ook de bouw gebruikt) ÉN dom: hoe vaak `gc.zgo.at` en
`data-goatcounter` ergens in de bladzij staan. Zouden ze allebei de regels van
de bouw gebruiken, dan is een blinde vlek in de bouw ook een blinde vlek in de
wachter -- en dan staat hij groen op precies de bladzij die fout is.

Afloopcode (huisafspraak): 0 in orde · 1 fouten gevonden · 3 kon niet kijken
(geen map, of nul .html gezien -- stilte betekent ongeldig, nooit goed).
"""
from __future__ import annotations
import argparse
import hashlib
import os
import sys

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
from tellerregel import (TELLERBESTAND, canoniek, ruwe_telling,  # noqa: E402
                         soort, tellers)

REPO = os.path.dirname(HIER)
TOON = 8   # zoveel voorbeelden per soort fout; de rest als aantal


def vak(rel: str) -> str:
    """`oefenboeken/ozp1/03_x/a.html` -> `oefenboeken/ozp1`; `index.html` -> `(wortel)`."""
    deel = rel.split(os.sep)
    if len(deel) == 1:
        return '(wortel)'
    if deel[0] in ('oefenboeken', 'werkboeken', 'manuscript', 'en') and len(deel) > 2:
        return os.sep.join(deel[:2])
    return deel[0]


def keur(tekst: str, s: str, profiel: str, blok: str) -> list[str]:
    """Wat er mis is met één bladzij, in gewone taal. Leeg = in orde."""
    ruw = ruwe_telling(tekst)
    n_ruw = max(ruw.values())
    fout = []
    if s == 'doorstuurder':
        if n_ruw:
            fout.append('doorstuurder met teller -- één bezoek wordt twee keer geteld')
        return fout
    balken = tekst.count('class="spookbalk"')
    if profiel == 'spook':
        if n_ruw:
            fout.append('teller in een proefdruk (%s)' % ', '.join(
                '%s %dx' % (k, v) for k, v in ruw.items() if v))
        if balken != 1:
            fout.append('proefdruk-balk %dx (moet 1x)' % balken)
        if 'name="robots" content="noindex' not in tekst:
            fout.append('geen noindex')
        return fout
    t = tellers(tekst, blok)
    if t['los']:
        fout.append('losse teller zonder hostwacht (%dx) -- telt ook op een proefdruk' % t['los'])
    if t['verouderd']:
        fout.append('verouderde teller (%dx) -- niet gelijk aan _tools/teller.html' % t['verouderd'])
    if t['goed'] == 0 and not t['los'] and not t['verouderd']:
        fout.append('geen teller')
    if t['goed'] > 1:
        fout.append('teller %dx -- elk bezoek telt dubbel' % t['goed'])
    # De domme telling: één goed blok draagt elk merk precies één keer. Staat er
    # meer, dan staat er een teller die de knipregels niet herkennen.
    if not fout and any(v != 1 for v in ruw.values()):
        fout.append('onbekende teller: %s (verwacht 1x elk)' % ', '.join(
            '%s %dx' % (k, v) for k, v in ruw.items()))
    if balken:
        fout.append('proefdruk-balk op de echte site')
    return fout


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--echt', dest='profiel', action='store_const', const='echt')
    g.add_argument('--spook', dest='profiel', action='store_const', const='spook')
    ap.add_argument('--site', default=os.path.join(REPO, '_site'), metavar='PAD')
    ap.add_argument('--teller', default=TELLERBESTAND, metavar='PAD',
                    help='het tellerblok (standaard: _tools/teller.html)')
    args = ap.parse_args()

    site = os.path.abspath(args.site)
    blok = canoniek(args.teller)
    print('tellerwacht (%s) -- %s' % (args.profiel, site))
    print('gereedschap: os.walk over elke .html; tellerblok %s (sha1 %s)' % (
        os.path.relpath(args.teller, REPO), hashlib.sha1(blok.encode()).hexdigest()[:10]))

    if not os.path.isdir(site):
        print('\nKON NIET KIJKEN -- %s bestaat niet. Eerst bouwen.' % site)
        return 3

    # per vak: [bladzij, in orde, doorstuurder, fragment]
    telling: dict[str, list[int]] = {}
    fouten: dict[str, list[str]] = {}
    fragmenten: list[str] = []
    gezien = 0
    for dp, dn, fn in os.walk(site):
        dn.sort()
        for f in sorted(fn):
            if not f.endswith('.html'):
                continue
            pad = os.path.join(dp, f)
            rel = os.path.relpath(pad, site)
            with open(pad, encoding='utf-8', errors='replace') as h:
                tekst = h.read()
            gezien += 1
            s = soort(tekst)
            r = telling.setdefault(vak(rel), [0, 0, 0, 0])
            if s == 'fragment':
                r[3] += 1
                fragmenten.append(rel)
                continue
            if s == 'doorstuurder':
                r[2] += 1
            else:
                r[0] += 1
            mis = keur(tekst, s, args.profiel, blok)
            if not mis and s == 'bladzij':
                r[1] += 1
            for m in mis:
                fouten.setdefault(m.split(' (')[0].split(' --')[0], []).append(
                    '%s  [%s]' % (rel, m))

    if gezien == 0:
        print('\nKON NIET KIJKEN -- nul .html gezien in %s. Stilte betekent ongeldig, '
              'nooit goed.' % site)
        return 3

    print('')
    print('  %-28s %8s %9s %13s %9s' % ('map', 'bladzij', 'in orde', 'doorstuurder', 'fragment'))
    tot = [0, 0, 0, 0]
    for k in sorted(telling):
        b, g_, d, fr = telling[k]
        tot = [tot[0] + b, tot[1] + g_, tot[2] + d, tot[3] + fr]
        vlag = '' if g_ == b else '   <-- %d FOUT' % (b - g_)
        print('  %-28s %8d %9d %13d %9d%s' % (k, b, g_, d, fr, vlag))
    print('  %-28s %8d %9d %13d %9d' % ('TOTAAL', *tot))

    if fragmenten:
        print('\nniet gekeurd, want geen <head> (fragment): %s' % ', '.join(fragmenten))
    if tot[2]:
        print('doorstuurders (%d) alleen gekeurd op: géén teller.' % tot[2])

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
        if args.profiel == 'echt':
            print('\nHerstellen: python3 _tools/teller_zetten.py --echt  (of gewoon '
                  'opnieuw quarto render; dat draait hem vanzelf)')
        else:
            print('\nHerstellen: bash _spooksite/maak_banner.sh "<wat>" && '
                  'quarto render --profile spook')
        return 1

    if args.profiel == 'echt':
        print('\nIn orde: alle %d bladzijden dragen precies één teller, en het is de '
              'ene uit _tools/teller.html.' % tot[0])
    else:
        print('\nIn orde: geen enkele teller in deze proefdruk; alle %d bladzijden '
              'dragen de balk en noindex.' % tot[0])
    return 0


if __name__ == '__main__':
    sys.exit(main())
