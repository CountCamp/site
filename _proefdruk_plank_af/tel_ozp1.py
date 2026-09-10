#!/usr/bin/env python3
"""Hoeveel hoofdstukken heeft OZP 1 echt?

De plank zegt "Twaalf hoofdstukken". Dat is een getal dat uit de map volgt,
dus het hoort geteld te worden en niet overgetikt. Ik tel de genummerde
mappen waar de eigen index van het werkboek naartoe linkt, en ik lees hun
eigen titel mee -- want die titel zegt WAT het is: een Deel, een Thema of
een Bijlage. Alleen mappen tellen zou de vraag verkeerd beantwoorden.
"""
import html
import pathlib
import re
from collections import Counter

index = pathlib.Path("oefenboeken/ozp1/index.html")
tekst = index.read_text(encoding="utf-8", errors="replace")

mappen = sorted(set(re.findall(r'href="\.{1,2}/(\d\d_[a-z0-9_]+)/', tekst)))
print(f"genummerde mappen waar de index naar linkt: {len(mappen)}")

soorten = Counter()
for map_ in mappen:
    titel = None
    for staart in re.findall(r'href="\.{1,2}/' + map_ + r'/[^"]*"(.{0,400})', tekst, flags=re.S):
        for kandidaat in re.findall(r'>([^<>]{3,90})<', staart):
            kandidaat = html.unescape(kandidaat).strip()
            if kandidaat and not kandidaat.startswith(("function", "var ", "//")):
                titel = kandidaat
                break
        if titel:
            break
    soort = titel.split("·")[0].strip().split()[0] if titel else "ONBEKEND"
    soorten[soort] += 1
    print(f"  {map_:30s} {titel}")

print()
for soort, aantal in sorted(soorten.items()):
    print(f"  {soort:12s} {aantal}")
