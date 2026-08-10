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
    # Hoofdstuk 3 linkt naar zijn eigen kopie: manuscript/h3.html heeft
    # <a href="h3_grabbel.html">. Die kopie stond hier tot 10-8-2026 NIET in,
    # en liep dus stil achter -- 25006 bytes tegen 25990 in de bron. Wie op
    # "Open de grabbelton" klikte in het boek, kreeg een oudere grabbelton dan
    # wie hem uit de speelkist pakte. Geen 404, geen klacht, geen alarm.
    # De terugknop hoeft hier niet omgeschreven: de bron wijst al naar
    # /manuscript/, en dat is precies waar deze kopie staat.
    "h3_grabbel.html":          "manuscript/h3_grabbel.html",
}

BROERTJES = ["r", "jasp", "spss"]

TERUG = re.compile(
    r'(<a\b[^>]*?)href="[^"]*"([^>]*>)\s*(?:&larr;|←)\s*Terug naar CountCamp\s*</a>'
)

fout = 0
veranderd = []          # welke doelen liepen achter en zijn nu bijgewerkt

def lees(naam):
    global fout
    b = BRON / naam
    if not b.exists():
        print("ONTBREEKT   %s" % naam); fout += 1; return None
    t = b.read_text()
    if "goatcounter" not in t:
        print("GEEN TELLER %s — voeg de GoatCounter-regel toe in <head>" % naam); fout += 1
    return t

def schrijf(doel, t):
    """Schrijft en onthoudt of er iets veranderde.

    Zonder deze boekhouding meldt het script "7 bestanden ververst" of de
    kopieën nou al bij waren of zeven weken achterliepen — en dat is precies
    wat er tot 10-8-2026 gebeurde: alle 21 broertjes-kopieën stonden achter,
    18 daarvan zonder GoatCounter-regel, en de uitvoer zag er schoon uit. Een
    run die zijn eigen stilte niet kan onderscheiden van succes, bewaakt niets.
    """
    oud = doel.read_text() if doel.exists() else None
    if oud == t:
        return False
    doel.write_text(t)
    veranderd.append(str(doel.relative_to(HIER)))
    return True

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
        nieuw = schrijf(kist / doel, t)
        print("   %-26s -> speeltjes/%-24s %s%s" % (
            bron, doel, "terugknop om" if n else "terugknop ongewijzigd",
            "  BIJGEWERKT" if nieuw else ""))

    print("— losse adressen —")
    for bron, doel in sorted(LOSSE_ADRESSEN.items()):
        t = lees(bron)
        if t is None: continue
        d = HIER / doel
        if not d.parent.is_dir():
            print("   MAP BESTAAT NIET: %s" % d.parent); fout += 1; continue
        nieuw = schrijf(d, t)
        print("   %-26s -> %-30s %s" % (bron, doel, "BIJGEWERKT" if nieuw else ""))

    print("— de broertjes —")
    for tak in BROERTJES:
        map_ = HIER / "oefenboeken" / "broertjes" / tak / "speeltjes"
        if not map_.is_dir():
            print("   map ontbreekt: %s" % map_); fout += 1; continue
        n_bij = 0
        for f in sorted(map_.glob("*.html")):
            t = lees(f.name)
            if t is None:
                print("   %s/%s heeft geen bron meer" % (tak, f.name)); continue
            if schrijf(f, t):
                n_bij += 1
        totaal = len(list(map_.glob("*.html")))
        print("   %-4s %d bestanden, waarvan %d bijgewerkt" % (tak, totaal, n_bij))

    verwacht = set(KIST.values()) | {"index.qmd", "_LEESMIJ.md"}
    for o in sorted(p.name for p in kist.iterdir() if p.name not in verwacht):
        print("ONBEKEND IN DE KIST: %s (staat niet in de lijst van dit script)" % o)

    if veranderd:
        print("\n%d van de %d kopieën liepen achter en zijn bijgewerkt:" % (
            len(veranderd), len(KIST) + len(LOSSE_ADRESSEN) + 7 * len(BROERTJES)))
        for v in veranderd:
            print("   %s" % v)
    else:
        print("\nAlle kopieën waren al gelijk aan de bron.")

    if fout:
        sys.exit("\n%d probleem(en) — niet publiceren zonder dit op te lossen." % fout)
    print("\nKlaar. Nu: rm -rf _site && quarto render --to html, dan committen en pushen.")

if __name__ == "__main__":
    main()
