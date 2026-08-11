#!/usr/bin/env python3
"""Toets de dubbeling uit DUBBELINGEN.md: staan de drie broertjes-teksten
op de boekpagina LETTERLIJK gelijk aan die op de oefenboeken-bladzij?

Vergelijkt de gerenderde alinea's (niet de bron), want dat is wat de lezer
ziet -- en het vangt ook verschillen die pas bij het renderen ontstaan.

Draai 'm NA een render (hij leest _site, niet de bron).
Gebruik:  python3 _tools/vergelijk_broertjes.py
Exit 0 = gelijk, 1 = uit de pas gelopen, 2 = niets om te vergelijken.
"""
import os
import re
import sys

WORTEL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Optioneel een andere _site-map meegeven -- handig om de vergelijker zelf te
# beproeven op een geknoeide kopie (doe ik na elke wijziging: een toets die
# nooit rood is geweest, weet je niet of hij rood kan worden).
SITE = sys.argv[1] if len(sys.argv) > 1 else os.path.join(WORTEL, "_site")
IDS = ["het-r-oefenboek-r", "het-jasp-oefenboek-jasp", "het-spss-oefenboek-spss"]


def alineas(pad, ids):
    html = open(pad, encoding="utf-8").read()
    uit = {}
    for i in ids:
        m = re.search(r'<section id="%s"[^>]*>(.*?)</section>' % re.escape(i), html, re.S)
        if not m:
            uit[i] = None
            continue
        uit[i] = "\n".join(p.strip() for p in re.findall(r"<p>(.*?)</p>", m.group(1), re.S))
    return uit


a = alineas(os.path.join(SITE, "oefenboeken", "index.html"), IDS)
b = alineas(os.path.join(SITE, "manuscript", "index.html"), IDS)

# Twee keer niets is geen bewijs van gelijkheid: leeg = ongeldig, niet "goed".
leeg = [i for i in IDS if not a[i] or not b[i]]
if leeg:
    for i in leeg:
        print("NIETS GEVONDEN  " + i +
              "  (oefenboeken=%s, manuscript=%s)" % (bool(a[i]), bool(b[i])))
    print("\nNiets om te vergelijken -- is er wel gerenderd, en heet het blok nog zo?")
    sys.exit(2)

goed = True
for i in IDS:
    gelijk = a[i] == b[i]
    goed = goed and gelijk
    print(("IDENTIEK  " if gelijk else "VERSCHIL  ") + i)
    if not gelijk:
        print("  oefenboeken:", repr(a[i])[:500])
        print("  manuscript :", repr(b[i])[:500])

print()
print("alle drie letterlijk gelijk:", goed)
sys.exit(0 if goed else 1)
