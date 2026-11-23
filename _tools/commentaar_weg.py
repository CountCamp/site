#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""commentaar_weg.py — na elke bouw: geen HTML-commentaar meer in een bladzij.

Draait vanzelf. `_quarto.yml` noemt dit script onder `project: post-render`, NA
`teller_zetten.py`, dus het loopt mee met elke `quarto render` -- hier, op
broodje, in de GitHub Action van de echte site, in die van de PR-proefdruk en in
de Engelse bouw. Los draaien kan ook:

    python3 _tools/commentaar_weg.py [--site _site]

Wat het doet
------------
Elke .html onder de uitvoermap, op elke diepte: elk `<!-- ... -->` eruit, op de
toegestane lijst in `commentaarregel.py` na (de merktekens van de teller en de
twee stempels die een machine terugleest, plus conditionele commentaren). Wat
een commentaar is, beslist `commentaarregel.py`, en dat is wat de browser er een
vindt: niets in `<script>` of `<style>`, niets in een attribuut. Idempotent: een
tweede run verandert geen byte.

Waarom hier, en niet (alleen) in de bronnen
-------------------------------------------
Ben, 23-11-2026: "uit de pagina halen vóór publiceren (alle boeken); redenen in
ONTWERP.md, qmd houdt korte verwijzing". De bron mag haar commentaar houden; de
bladzij niet. En een bladzij krijgt commentaar langs vijf wegen: de .qmd van de
site, de .qmd van een boek in het lab, een include-bestand (`_teller.html`,
`_afterbody.html` in het lab), een Lua-filter, en de hand (de speeltjes). Alleen
de eerste wordt door `strip-comments: true` in `_quarto.yml` gevangen -- gemeten
op Quarto 1.9.38 met een proefbladzij (rapport spoor pers_commentaar,
23-11-2026): een ```{=html}-blok, een include-before-body, een Lua-filter en
Quarto's eigen `<!-- main -->` gaan er ongehinderd langs. En de boeken komen als
bijlage binnen, kant-en-klaar gerenderd: die ziet pandoc hier nooit.
De uitvoermap is de enige plek waar alle wegen samenkomen, en de post-render
draait op elke bouw. Een nieuwe pers die er een boek bij zet, hoeft hier dus
niets voor te doen.

Waarom NA teller_zetten.py: die zet het tellerblok erin, mét zijn merktekens, en
vervangt een verouderd blok uit een bron. Draait dit script eerst, dan haalt het
de merktekens van zo'n oud blok weg en kan teller_zetten het niet meer als blok
herkennen. Na hem staat er alleen nog het ene blok uit `teller.html`, en dat staat
op de lijst.

De uitvoermap komt uit QUARTO_PROJECT_OUTPUT_DIR (zie teller_zetten.py voor de
meting); los gedraaid uit --site of `_site`.

Afloopcode: 0 klaar, 1 een bladzij niet te lezen of te schrijven, 3 niets gezien.
"""
from __future__ import annotations
import argparse
import os
import sys

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
from commentaarregel import TOEGESTAAN, kort, zonder_commentaar  # noqa: E402

REPO = os.path.dirname(HIER)
OVERSLAAN = {'.claude', '.git'}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--site', default=os.environ.get('QUARTO_PROJECT_OUTPUT_DIR')
                    or os.path.join(REPO, '_site'))
    args = ap.parse_args()
    site = os.path.abspath(args.site)

    gezien = veranderd = weg_n = 0
    bewaard = {n: 0 for n, _r, _t in TOEGESTAAN}
    voorbeeld = None
    fout = []
    for dp, dn, fn in os.walk(site):
        dn[:] = sorted(d for d in dn if d not in OVERSLAAN)
        for f in sorted(fn):
            if not f.endswith('.html'):
                continue
            pad = os.path.join(dp, f)
            gezien += 1
            try:
                # surrogateescape: een byte die geen UTF-8 is komt ongeschonden terug
                with open(pad, encoding='utf-8', errors='surrogateescape', newline='') as h:
                    oud = h.read()
                nieuw, weg, bew = zonder_commentaar(oud)
                for c in bew:
                    bewaard[c.toegestaan] += 1
                if nieuw != oud:
                    with open(pad, 'w', encoding='utf-8', errors='surrogateescape', newline='') as h:
                        h.write(nieuw)
                    veranderd += 1
                    weg_n += len(weg)
                    if voorbeeld is None:
                        voorbeeld = '%s:%d: %s' % (os.path.relpath(pad, site), weg[0].regel,
                                                   kort(weg[0].tekst, 60))
            except (OSError, RuntimeError) as e:
                fout.append('%s (%s)' % (os.path.relpath(pad, site), e))

    print('commentaar_weg: %d html in %s -- %d commentaar/commentaren weg uit %d bestand(en); '
          'bewaard: %s' % (gezien, os.path.relpath(site, REPO) if site.startswith(REPO) else site,
                           weg_n, veranderd,
                           ', '.join('%s %d' % (n, k) for n, k in bewaard.items())))
    if voorbeeld:
        print('commentaar_weg: bv. %s' % voorbeeld)
    if gezien == 0:
        print('commentaar_weg: NIETS GEZIEN in %s -- dat is geen schone bouw maar een blinde.' % site)
        return 3
    if fout:
        print('commentaar_weg: WEIGER -- %d bladzij(den) niet te lezen of te schrijven; daar kan '
              'nog commentaar in staan:' % len(fout))
        for f in fout:
            print('    %s' % f)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
