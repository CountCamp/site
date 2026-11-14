#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""teller_zetten.py — na elke bouw: precies één bezoekersteller per bladzij, of geen.

Draait vanzelf. `_quarto.yml` noemt dit script onder `project: post-render`, dus
het loopt mee met elke `quarto render` -- hier, op broodje, in de GitHub Action
van de echte site en in die van de PR-proefdruk. Los draaien kan ook:

    python3 _tools/teller_zetten.py --echt  [--site _site]
    python3 _tools/teller_zetten.py --spook [--site _site]

Wat het doet, per gebouwde .html
--------------------------------
Eerst gaat ELKE teller eruit, in welke schrijfwijze ook (zie `tellerregel.py`).
Daarna, afhankelijk van het bouwprofiel:

  echt   elke bladzij krijgt het blok uit `_tools/teller.html`, één keer, vlak
         voor </head>.
  spook  geen teller. Wel krijgt elke bladzij de proefdruk-balk en `noindex`,
         als hij die nog niet had.

Een doorstuurder (meta-refresh naar een nieuw adres) krijgt nooit een teller:
die zou één bezoek twee keer boeken. Een fragment zonder <head> -- het
Google-verificatiebestand -- wordt niet aangeraakt.

Waarom de bouw dit doet en niet de bronnen
------------------------------------------
Vóór dit script kwam de teller langs vijf wegen in de site: `_quarto-echt.yml`
voor de bladzijden die Quarto zelf rendert, en voor de rest een kopie die in
elke bron-bladzij zelf stond (oefenboeken, het boek, de handleiding, de
speeltjes, en/). Gevolg één: de teller veranderen betekende vijf plekken plus
twee repo's. Gevolg twee: het spookprofiel haalde de teller alleen uit wat
Quarto zelf rendert. Gemeten op 8-10-2026: in een proefdruk telden 201 van de
213 bladzijden gewoon mee, zonder balk en zonder noindex -- ook in
PR-proefdruk 1, die op 6-10 op countcamp.org/pr-preview/pr-1/ stond. Opnieuw
gemeten op 14-11-2026 (spoor site_wegen): 224 van de 243 in de proefdruk van
publiceer_en.sh. Ontworpen op 8-10 (spoor teller), op main sinds 14-11
(spoor teller2).

Waarom het profiel uit QUARTO_PROFILE komt en niet uit een argument: Quarto zet
die variabele voor elk post-render-script op ALLE actieve profielen, ook die hij
zelf als standaard van een groep koos. Nagemeten op 14-11-2026 met quarto 1.9.38
en de profielgroepen uit _quarto.yml ([echt, spook] en [nl, en]):
    quarto render                         -> "echt,nl"
    QUARTO_PROFILE=spook quarto render    -> "spook,nl"
    quarto render --profile en            -> "en,echt"
    quarto render --profile en,spook      -> "en,spook"
Er staat dus altijd precies één van `echt` en `spook` in, en de taal doet hier
niet ter zake: de Engelse bouw krijgt dezelfde teller als de Nederlandse. Een
lijst met geen van beide is een fout: dan weet niemand of dit de echte site is
of een proefdruk, en dan bouwen we liever niet.
De uitvoermap komt uit QUARTO_PROJECT_OUTPUT_DIR (zelfde meting: een absoluut
pad, ook bij --output-dir _site_spook en bij de Engelse bouw naar _site_en).

Afloopcode: 0 klaar, 1 weigert (onbekend profiel, geen balk, bladzij zonder
</head>), 3 niets gezien.
"""
from __future__ import annotations
import argparse
import os
import sys

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
from tellerregel import canoniek, met_blok, soort, zonder_tellers  # noqa: E402

REPO = os.path.dirname(HIER)
BALK = os.path.join(REPO, '_spooksite', 'banner.html')
# Dezelfde regel als in _quarto-spook.yml; die zet hem in de Quarto-bladzijden,
# dit script in de rest.
NOINDEX = '<meta name="robots" content="noindex, nofollow, noarchive">\n'


def profiel_uit_omgeving() -> str | None:
    """`echt` of `spook` uit QUARTO_PROFILE, of None als dat niet te zeggen is.

    Staan ze er allebei in (dat kan Quarto niet maken, want ze zitten in één
    groep, maar wel iemand die de variabele met de hand zet), dan wint `spook`:
    een proefdruk die ten onrechte niet telt kost niets, een die wel telt
    vervuilt Bens cijfers.
    """
    profielen = [p.strip() for p in os.environ.get('QUARTO_PROFILE', '').split(',') if p.strip()]
    if 'spook' in profielen:
        return 'spook'
    if 'echt' in profielen:
        return 'echt'
    return None


def met_balk(tekst: str, balk: str) -> tuple[str, list[str]]:
    """Balk direct na <body ...>, noindex vlak voor </head> -- alleen wat ontbreekt."""
    import re
    gedaan = []
    if 'name="robots" content="noindex' not in tekst:
        m = re.search(r'</head\s*>', tekst, re.I)
        if m:
            tekst = tekst[:m.start()] + NOINDEX + tekst[m.start():]
            gedaan.append('noindex')
    if 'class="spookbalk"' not in tekst:
        m = re.search(r'<body\b[^>]*>', tekst, re.I)
        if m:
            tekst = tekst[:m.end()] + '\n' + balk + tekst[m.end():]
            gedaan.append('balk')
    return tekst, gedaan


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group()
    g.add_argument('--echt', dest='profiel', action='store_const', const='echt')
    g.add_argument('--spook', dest='profiel', action='store_const', const='spook')
    ap.add_argument('--site', default=os.environ.get('QUARTO_PROJECT_OUTPUT_DIR')
                    or os.path.join(REPO, '_site'))
    args = ap.parse_args()

    profiel = args.profiel or profiel_uit_omgeving()
    if profiel is None:
        print('teller_zetten: WEIGER -- QUARTO_PROFILE is %r. Ik ken alleen `echt` en '
              '`spook`, en zonder dat te weten kan ik niet zeggen of hier een teller '
              'in hoort of juist niet.' % os.environ.get('QUARTO_PROFILE'))
        return 1

    blok = canoniek()
    balk = None
    if profiel == 'spook':
        if not os.path.isfile(BALK):
            print('teller_zetten: WEIGER -- %s bestaat niet. Een proefdruk zonder balk '
                  'mag niet bestaan; draai eerst _spooksite/maak_banner.sh.' % BALK)
            return 1
        balk = open(BALK, encoding='utf-8').read()

    site = os.path.abspath(args.site)
    gezien = 0
    veranderd = 0
    per_soort = {'bladzij': 0, 'doorstuurder': 0, 'fragment': 0}
    zonder_head = []
    for dp, _dn, fn in os.walk(site):
        for f in sorted(fn):
            if not f.endswith('.html'):
                continue
            pad = os.path.join(dp, f)
            with open(pad, encoding='utf-8', errors='surrogateescape') as h:
                oud = h.read()
            gezien += 1
            s = soort(oud)
            per_soort[s] += 1
            if s == 'fragment':
                continue
            if s == 'doorstuurder':
                nieuw, _n = zonder_tellers(oud)
            elif profiel == 'echt':
                nieuw, wat = met_blok(oud, blok)
                if wat == 'geen_head':
                    zonder_head.append(os.path.relpath(pad, site))
                    continue
            else:
                nieuw, _n = zonder_tellers(oud)
                nieuw, _gedaan = met_balk(nieuw, balk)
                if 'class="spookbalk"' not in nieuw or 'content="noindex' not in nieuw:
                    zonder_head.append(os.path.relpath(pad, site))
                    continue
            if nieuw != oud:
                with open(pad, 'w', encoding='utf-8', errors='surrogateescape') as h:
                    h.write(nieuw)
                veranderd += 1

    print('teller_zetten (%s): %d html in %s -- %d bladzijden, %d doorstuurders, '
          '%d fragmenten; %d bestanden bijgewerkt' % (
              profiel, gezien, os.path.relpath(site, REPO), per_soort['bladzij'],
              per_soort['doorstuurder'], per_soort['fragment'], veranderd))
    if gezien == 0:
        print('teller_zetten: NIETS GEZIEN in %s -- dat is geen schone bouw maar een '
              'blinde.' % site)
        return 3
    if zonder_head:
        print('teller_zetten: WEIGER -- %d bladzij(den) zonder </head> of <body>; daar '
              'kan de %s niet in:' % (len(zonder_head),
                                      'teller' if profiel == 'echt' else 'balk'))
        for rel in zonder_head:
            print('    %s' % rel)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
