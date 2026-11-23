#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""commentaar_gelijk.py — is er buiten het commentaar NIETS veranderd? Met een ándere ontleder.

    python3 _tools/tests/commentaar_gelijk.py <voor-map> <na-map>

Leest elke .html in beide mappen met `html.parser` uit de standaardbibliotheek --
dus níét met `commentaarregel.py`, die het filter zelf gebruikt -- en vergelijkt
alles wat de browser bouwt: elke tag met zijn attributen, elk stuk tekst, en de
inhoud van elk <script> en <style> letterlijk. Commentaar telt niet mee; dat is
precies wat weg mocht. Witruimte buiten <pre>, <textarea>, <script> en <style>
wordt samengevat tot één spatie, want een weggehaalde regel laat daar een
regelovergang minder achter en de browser toont die toch als één spatie. Binnen
die vier elementen telt elke spatie.

Waarom een andere ontleder: zou deze toets ook commentaarregel.py gebruiken, dan
is een blinde vlek in het filter ook een blinde vlek hier -- zelfde reden als de
domme telling in tellerwacht.py.

Afloop: 0 gelijk, 1 verschil (met de eerste afwijking per bladzij), 3 niets vergeleken.
"""
from __future__ import annotations
import os
import re
import sys
from html.parser import HTMLParser

LETTERLIJK = {'pre', 'textarea', 'script', 'style'}


class Gebeurtenissen(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=False)
        self.uit: list[tuple] = []
        self.diep = 0          # in een letterlijk element
        self.commentaren = 0

    def _tekst(self, s: str) -> None:
        # Aangrenzende tekst wordt één stuk (een weggehaald commentaar laat twee
        # stukken aan elkaar), en buiten de letterlijke elementen wordt elke reeks
        # witruimte één spatie. Witruimte valt nooit weg: "a</b> <i>" en
        # "a</b><i>" blijven verschillend.
        if self.uit and self.uit[-1][0] == 'tekst' and self.uit[-1][2] == self.diep:
            s = self.uit.pop()[1] + s
        if not self.diep:
            s = re.sub(r'\s+', ' ', s)
        self.uit.append(('tekst', s, self.diep))

    def handle_starttag(self, tag, attrs):
        self.uit.append(('<', tag, tuple(attrs)))
        if tag in LETTERLIJK:
            self.diep += 1

    def handle_startendtag(self, tag, attrs):
        self.uit.append(('<', tag, tuple(attrs), '/'))

    def handle_endtag(self, tag):
        if tag in LETTERLIJK and self.diep:
            self.diep -= 1
        self.uit.append(('>', tag))

    def handle_data(self, data):
        self._tekst(data)

    def handle_entityref(self, name):
        self._tekst('&%s;' % name)

    def handle_charref(self, name):
        self._tekst('&#%s;' % name)

    def handle_comment(self, data):
        self.commentaren += 1   # telt niet mee: dat mocht weg

    def handle_decl(self, decl):
        self.uit.append(('!', decl))

    def handle_pi(self, data):
        self.uit.append(('?', data))

    def unknown_decl(self, data):
        self.uit.append(('![', data))


def lees(pad: str) -> tuple[list[tuple], int]:
    with open(pad, encoding='utf-8', errors='surrogateescape', newline='') as h:
        p = Gebeurtenissen()
        p.feed(h.read())
        p.close()
    return p.uit, p.commentaren


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 3
    voor, na = (os.path.abspath(a) for a in sys.argv[1:3])
    n = 0
    verschil = []
    weg = 0
    for dp, _dn, fn in os.walk(voor):
        for f in sorted(fn):
            if not f.endswith('.html'):
                continue
            a = os.path.join(dp, f)
            rel = os.path.relpath(a, voor)
            b = os.path.join(na, rel)
            if not os.path.isfile(b):
                verschil.append('%s: staat niet in de na-map' % rel)
                continue
            n += 1
            ga, ca = lees(a)
            gb, cb = lees(b)
            weg += ca - cb
            if ga != gb:
                i = next((k for k, (x, y) in enumerate(zip(ga, gb)) if x != y), min(len(ga), len(gb)))
                verschil.append('%s: eerste verschil bij gebeurtenis %d: voor %r / na %r'
                                % (rel, i, ga[i] if i < len(ga) else None, gb[i] if i < len(gb) else None))
    print('commentaar_gelijk: %d bladzijden vergeleken met html.parser (Python %s); %d commentaar '
          'minder na het filter; %d bladzij(den) met een ander verschil'
          % (n, sys.version.split()[0], weg, len(verschil)))
    for v in verschil[:20]:
        print('  ' + v[:300])
    if n == 0:
        return 3
    return 1 if verschil else 0


if __name__ == '__main__':
    sys.exit(main())
