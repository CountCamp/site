#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kopieert de speeltjes uit het lab naar countcamp_site/speeltjes/.

De bron is countcamp_lab/boek/04_speeltjes/. Hier staan kopieen, want de site
is een eigen repo. Draai dit na elke wijziging aan een speeltje:

    python3 _tools/bouw_speelkist.py

Wat er onderweg gebeurt:
  1. de terugknop bovenaan gaat naar /speeltjes/ in plaats van naar de voordeur
  2. er wordt gecontroleerd of elk bestand een GoatCounter-teller heeft
  3. wat in de kist staat maar niet in de lijst hieronder, wordt gemeld

De hub zelf (index.qmd) wordt NIET overschreven — die is handwerk.
"""
import re
import sys
from pathlib import Path

HIER = Path(__file__).resolve().parent.parent
BRON = HIER.parent / "countcamp_lab" / "boek" / "04_speeltjes"
DOEL = HIER / "speeltjes"

KOPIE = {
    "h3_grabbel.html":          "grabbelton.html",
    "w6_trek_interval.html":    "trek-opnieuw.html",
    "w4_schud_correlatie.html": "schud-correlatie.html",
    "w6_schud_verschil.html":   "schud-verschil.html",
    "w6_p_planten.html":        "schud-labels.html",
    "s2_schud_tabel.html":      "schud-tabel.html",
    "w12_schud_odds.html":      "schud-odds.html",
    "olifantengeheugen.html":   "olifantengeheugen.html",
    "casino_kleine_n.html":     "casino.html",
}

TERUG = re.compile(
    r'(<a\b[^>]*?)href="[^"]*"([^>]*>)\s*(?:&larr;|←)\s*Terug naar CountCamp\s*</a>'
)

def main():
    if not BRON.is_dir():
        sys.exit("bron niet gevonden: %s" % BRON)
    DOEL.mkdir(parents=True, exist_ok=True)
    fout = 0

    for bron, doel in sorted(KOPIE.items()):
        b = BRON / bron
        if not b.exists():
            print("ONTBREEKT   %s" % bron); fout += 1; continue
        t = b.read_text()
        if "goatcounter" not in t:
            print("GEEN TELLER %s — voeg de GoatCounter-regel toe in <head>" % bron)
            fout += 1
        t, n = TERUG.subn(
            lambda m: m.group(1) + 'href="/speeltjes/"' + m.group(2)
                      + "← Terug naar de speelkist</a>", t)
        (DOEL / doel).write_text(t)
        print("%-26s -> %-24s %s" % (bron, doel, "terugknop omgezet" if n else "terugknop stond al goed"))

    verwacht = set(KOPIE.values()) | {"index.qmd", "_LEESMIJ.md"}
    overig = sorted(p.name for p in DOEL.iterdir() if p.name not in verwacht)
    for o in overig:
        print("ONBEKEND IN DE KIST: %s (staat niet in de lijst van dit script)" % o)

    if fout:
        sys.exit("\n%d probleem(en) — niet gepubliceerd zonder dit op te lossen." % fout)
    print("\nKlaar. Nu: rm -rf _site && quarto render --to html, dan committen en pushen.")

if __name__ == "__main__":
    main()
