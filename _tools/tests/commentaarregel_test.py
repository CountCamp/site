#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""commentaarregel_test.py — de ontleder uit _tools/commentaarregel.py, geval voor geval.

    python3 _tools/tests/commentaarregel_test.py

Elk geval is iets wat de browser op een bepaalde manier leest, en wat het filter
dus precies zo moet lezen: weghalen wat de browser een commentaar vindt, laten
staan wat voor de browser tekst is. Bij elk geval staat waarom het erin zit.
En bij elk geval de toets dat een tweede ronde niets meer verandert (idempotent).

Afloop: 0 alles goed, 1 minstens één geval zakt.
"""
from __future__ import annotations
import os
import sys

sys.dont_write_bytecode = True
# GEREEDSCHAP: een kopie van _tools/ om te proeven (commentaar_mutatieproef.sh
# geeft een kreupele). Zonder: de echte, naast deze map.
TOOLS = os.path.abspath(os.environ.get('GEREEDSCHAP')
                        or os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, TOOLS)
from commentaarregel import (TELLER_BEGIN, TELLER_EIND, lees,  # noqa: E402
                             zonder_commentaar)

STEMPEL_BOEK = ('<!-- countcamp-publicatie H4 bron-hash=' + 'a' * 64
                + ' geleverd=2026-11-23T10:00:00 -->')
STEMPEL_OEFENBOEK = ('<!-- countcamp-oefenboek mvda lab-commit=' + 'b' * 40
                     + ' geleverd=2026-11-23T10:00:00 -->')

WEIGERT = object()   # verwacht: zonder_commentaar weigert (RuntimeError)

# (naam, invoer, verwachte uitvoer, waarom)
GEVALLEN = [
    ('eigen regel', 'a\n  <!-- MIEKE: weg -->\nb', 'a\nb',
     'een commentaar op zijn eigen regel neemt die regel mee, anders blijft er een lege regel'),
    ('midden in tekst', 'a <!-- x --> b', 'a  b',
     'midden in een zin gaat alleen het commentaar weg; twee spaties toont de browser als één'),
    ('over regels', 'a\n<!-- bron: hand-out\ncollege 4 -->\nb', 'a\nb',
     'een commentaar over meer regels gaat in zijn geheel'),
    ('script', '<script>var s = "<!-- blijf -->";</script>', None,
     'in <script> is <!-- tekst: wegknippen breekt het script'),
    ('style', '<style>/* <!-- */ p{color:red}</style>', None,
     'in <style> idem'),
    ('script hoofdletters', '<SCRIPT type="x">a <!-- b --> c</SCRIPT><p><!-- weg --></p>',
     '<SCRIPT type="x">a <!-- b --> c</SCRIPT><p></p>',
     'tagnamen zijn hoofdletterongevoelig, en na het script telt het weer'),
    ('attribuut', '<a title="<!-- blijf -->" href=x>t</a>', None,
     'in een attribuutwaarde is <!-- tekst'),
    ('pre', '<pre>x\n<!-- weg -->\ny</pre>', '<pre>x\n\ny</pre>',
     'in <pre> is het een echt (onzichtbaar) commentaar; de regel blijft, want daar telt elke regelovergang'),
    ('codeblok toont', '<pre><code>&lt;!-- toon --&gt;</code></pre>', None,
     'wat een codeblok TOONT staat er als &lt;!-- en wordt nooit aangeraakt'),
    ('conditioneel', 'a<!--[if IE]> MIEKE: geheim <![endif]-->b', 'ab',
     'een IE-commentaar is sinds 23-11 geen recht meer: het liet elke tekst door, en niemand leest het terug'),
    ('leeg', 'a<!-->b<!--->c<!---->d', 'abcd',
     'HTML5: <!--> en <!---> zijn al afgesloten lege commentaren'),
    ('--!>', 'a<!-- x --!>b', 'ab',
     'HTML5: --!> sluit een commentaar ook'),
    ('teller', TELLER_BEGIN + '\n<script>x</script>\n' + TELLER_EIND + '\n', None,
     'de merktekens van de bezoekersteller leest tellerregel.py terug'),
    ('boekstempel', '</html>\n' + STEMPEL_BOEK + '\n', None,
     'lever.sh --push zoekt deze stempel op de live bladzij'),
    ('oefenboekstempel', '</html>\n' + STEMPEL_OEFENBOEK + '\n', None,
     'en_bouw.py keur leest deze stempel in de bouw'),
    ('halve stempel', '</html>\n<!-- countcamp-publicatie H4 bron-hash=abc -->\n', '</html>\n',
     'alleen de precieze vorm mag blijven; een halve stempel is een notitie'),
    ('verouderde teller', '<!-- teller:begin oud -->\n', '',
     'alleen het merkteken uit _tools/teller.html zelf mag blijven'),
    ('puzzel', 'a<<!-- x -->!-- y -->b', WEIGERT,
     'weghalen kan een nieuw commentaar maken (a<!-- y -->b) waar de browser tekst toonde: weigeren, niet doorknippen'),
    ('puzzel open', '<p>3 <<!-- x -->!-- zichtbaar</p><p>de rest</p>', WEIGERT,
     'idem met een <!-- dat nooit sluit: een tweede ronde wiste hier de rest van de bladzij (nakijker 23-11)'),
    ('bogus', 'a<!<!-- x -->b', None,
     'HTML5: <! zonder -- is een "bogus comment" tot de eerste > -- de browser ziet hier geen <!-- x -->'),
    ('nooit dicht', 'a <!-- nooit dicht', 'a ',
     'HTML5: een commentaar dat nooit sluit loopt tot het eind van het bestand'),
    ('title', '<title>a <!-- b --> c</title><p><!-- weg --></p>',
     '<title>a <!-- b --> c</title><p></p>',
     'in <title> is <!-- tekst (en die tekst staat in het tabblad)'),
    ('doctype', '<!DOCTYPE html>\n<!-- weg -->\n<html>', '<!DOCTYPE html>\n<html>',
     '<!DOCTYPE is geen commentaar'),
    ('twee op een regel', '<p>\n<!-- a --> <!-- b -->\n</p>', '<p>\n \n</p>',
     'twee op één regel: allebei weg, de regel blijft (geen regel eromheen weggeknipt die niet van één commentaar is)'),
    ('kleiner-dan', 'a < b <!-- weg --> en 3<4', 'a < b  en 3<4',
     'een losse < is geen tag'),
]


def main() -> int:
    zak = 0
    for naam, invoer, verwacht, waarom in GEVALLEN:
        if verwacht is WEIGERT:
            try:
                uit = zonder_commentaar(invoer)[0]
            except RuntimeError:
                print('ok    %-20s %s' % (naam, waarom))
                continue
            zak += 1
            print('ZAKT  %-20s %s' % (naam, waarom))
            print('        invoer:    %r' % invoer)
            print('        verwacht:  weigering (RuntimeError)')
            print('        kreeg:     %r' % uit)
            continue
        verwacht = invoer if verwacht is None else verwacht
        uit, _weg, _bewaard = zonder_commentaar(invoer)
        nog_eens, weg2, _ = zonder_commentaar(uit)
        ok = uit == verwacht and nog_eens == uit and not weg2
        if not ok:
            zak += 1
        print('%s  %-20s %s' % ('ok  ' if ok else 'ZAKT', naam, waarom))
        if not ok:
            print('        invoer:    %r' % invoer)
            print('        verwacht:  %r' % verwacht)
            print('        kreeg:     %r' % uit)
            if nog_eens != uit:
                print('        2e ronde:  %r  (niet idempotent)' % nog_eens)

    # Wat overgeslagen wordt, wordt ook GENOEMD (anders is een uitsluiting een gat).
    lz = lees('<script>"<!--"</script><a title="<!--">x</a><style><!--</style>')
    soorten = sorted(s for s, _r in lz.overgeslagen)
    ok = soorten == ['attribuut', 'script', 'style'] and not lz.commentaren
    if not ok:
        zak += 1
    print('%s  %-20s %s' % ('ok  ' if ok else 'ZAKT', 'overgeslagen',
                            'elke <!-- die geen commentaar is, wordt bij naam geteld: %s' % soorten))

    # Regelnummers kloppen (de wachter print ze).
    lz = lees('a\nb\n<!-- x -->\n<script>\n"<!--"\n</script>\n<!-- y -->')
    regels = [c.regel for c in lz.commentaren]
    ok = regels == [3, 7]
    if not ok:
        zak += 1
    print('%s  %-20s %s' % ('ok  ' if ok else 'ZAKT', 'regelnummers', 'verwacht [3, 7], kreeg %s' % regels))

    n = len(GEVALLEN) + 2
    print('\n%d gevallen, %d zakt' % (n, zak))
    return 1 if zak else 0


if __name__ == '__main__':
    sys.exit(main())
