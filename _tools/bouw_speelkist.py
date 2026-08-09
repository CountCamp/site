#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kopieert de speeltjes uit het lab naar alle plekken waar ze staan.

De bron is countcamp_lab/boek/04_speeltjes/. Draai dit na elke wijziging:

    python3 _tools/bouw_speelkist.py

Er zijn vier bestemmingen, en ze raken alle vier verouderd als je er maar een
ververst — zie DUBBELINGEN.md:

  1. speeltjes/                          de speelkist (terugknop naar /speeltjes/)
  2. tabellen/ tables/ power/            de losse adressen die al gedeeld zijn
  3. oefenboeken/broertjes/{r,jasp,spss}/speeltjes/
                                         de kopieen die de hoofdstukken aanroepen

Onderweg wordt gecontroleerd of elk bestand een GoatCounter-teller heeft, en
gemeld wat er in een doelmap staat zonder bron. De hub (speeltjes/index.qmd) is
handwerk en wordt niet aangeraakt.
"""
import re
import sys
from pathlib import Path

HIER = Path(__file__).resolve().parent.parent
BRON = HIER.parent / "countcamp_lab" / "boek" / "04_speeltjes"

KIST = {
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

LOSSE_ADRESSEN = {
    "tabellen_aflezen.html":    "tabellen/index.html",
    "tabellen_aflezen_en.html": "tables/index.html",
    "power_speeltje.html":      "power/index.html",
}

BROERTJES = ["r", "jasp", "spss"]

TERUG = re.compile(
    r'(<a\b[^>]*?)href="[^"]*"([^>]*>)\s*(?:&larr;|←)\s*Terug naar CountCamp\s*</a>'
)

fout = 0

def lees(naam):
    global fout
    b = BRON / naam
    if not b.exists():
        print("ONTBREEKT   %s" % naam); fout += 1; return None
    t = b.read_text()
    if "goatcounter" not in t:
        print("GEEN TELLER %s — voeg de GoatCounter-regel toe in <head>" % naam); fout += 1
    return t

def main():
    global fout
    if not BRON.is_dir():
        sys.exit("bron niet gevonden: %s" % BRON)

    print("— de speelkist —")
    kist = HIER / "speeltjes"
    kist.mkdir(parents=True, exist_ok=True)
    for bron, doel in sorted(KIST.items()):
        t = lees(bron)
        if t is None: continue
        t, n = TERUG.subn(
            lambda m: m.group(1) + 'href="/speeltjes/"' + m.group(2)
                      + "← Terug naar de speelkist</a>", t)
        (kist / doel).write_text(t)
        print("   %-26s -> speeltjes/%-24s %s" % (bron, doel, "terugknop om" if n else "ongewijzigd"))

    print("— losse adressen —")
    for bron, doel in sorted(LOSSE_ADRESSEN.items()):
        t = lees(bron)
        if t is None: continue
        d = HIER / doel
        if not d.parent.is_dir():
            print("   MAP BESTAAT NIET: %s" % d.parent); fout += 1; continue
        d.write_text(t)
        print("   %-26s -> %s" % (bron, doel))

    print("— de broertjes —")
    for tak in BROERTJES:
        map_ = HIER / "oefenboeken" / "broertjes" / tak / "speeltjes"
        if not map_.is_dir():
            print("   map ontbreekt: %s" % map_); fout += 1; continue
        for f in sorted(map_.glob("*.html")):
            t = lees(f.name)
            if t is None:
                print("   %s/%s heeft geen bron meer" % (tak, f.name)); continue
            f.write_text(t)
        print("   %-4s %d bestanden ververst" % (tak, len(list(map_.glob("*.html")))))

    verwacht = set(KIST.values()) | {"index.qmd", "_LEESMIJ.md"}
    for o in sorted(p.name for p in kist.iterdir() if p.name not in verwacht):
        print("ONBEKEND IN DE KIST: %s (staat niet in de lijst van dit script)" % o)

    if fout:
        sys.exit("\n%d probleem(en) — niet publiceren zonder dit op te lossen." % fout)
    print("\nKlaar. Nu: rm -rf _site && quarto render --to html, dan committen en pushen.")

if __name__ == "__main__":
    main()
