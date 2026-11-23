#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""taallabel.py — het EN-label op de Nederlandse oefenboekenplank.

Ben, 23-11-2026 (Regie), op de vraag "Moet de Nederlandse oefenboekenpagina per
boek naar de Engelse versie verwijzen?": "Ja, klein EN-label per boek".

Draait vanzelf. `_quarto.yml` noemt dit script onder `project: post-render`,
VÓÓR teller_zetten.py en commentaar_weg.py, dus het loopt mee met elke
`quarto render`: hier, op broodje, in de GitHub Action en in de proefdruk. Los
draaien kan ook:

    python3 _tools/taallabel.py [--site _site] [--paren <taalparen.tsv>]

Wat het doet
------------
Op de plank (PLANKEN hieronder, nu alleen oefenboeken/index.html) krijgt elk boek
waarvan de titellink naar een bladzij wijst die in taalparen.tsv een Engelse
tweeling heeft, achteraan in zijn kop één link:

    <a class="cc-taal" href="../en/workbooks/…/index.html" hreflang="en" lang="en"
       title="The English edition of this book">EN</a>

Zijn uiterlijk staat in styles.css ("het EN-label"): hetzelfde rechthoekje als
het taalmerk op de Engelse plank, waar het NL- en EN-merk uit het hreflang van de
link komen. Daar zegt het merk in welke taal de titellink landt; hier is het
label zelf de link, en zegt het hetzelfde: klik je erop, dan land je in het
Engels. Daarom staat het rechts bij de pillen en niet links vóór de titel: vóór
een Nederlandse titel zou EN lezen als "dit boek is Engels".

AFGELEID, NIET GETIKT. Welk boek een label krijgt, staat nergens met de hand:
het volgt uit de titellink op de plank en de paren in taalparen.tsv, gelezen met
de parser van taalonderdelen.py (geen tweede). Komt het Engelse MVDA- of
psychometrie-boek online en zet zijn pers het paar voor de voorpagina in de
tabel, dan heeft de volgende bouw het label. Er hoeft hier niets voor te
veranderen, en in oefenboeken/index.qmd ook niet.

LIVE OF GEPLAND. taalparen.tsv kent geen "gepland": een paar betekent dat de
Engelse kant er staat (zijn kop: "Een regel hier ZONDER dat de Engelse bladzij
bestaat, zet op de Nederlandse bladzij een knopje naar niets", en een Engelse
wachtpagina krijgt géén paar). Dit script eist daarbovenop dat de Engelse
bladzij in de UITVOERMAP staat, want daar landt de klik.

EEN PAAR NAAR EEN BLADZIJ DIE ER NIET STAAT: geen label, en een LET OP-regel in
de bouwuitvoer. Bewust geen afgebroken bouw. Een dode link op de Nederlandse
plank is erger dan geen label, en een kapot Engels paar mag de Nederlandse site
niet tegenhouden, bijvoorbeeld een herpublicatie op de dag van een herkansing.
Wie het gat wel tegenhoudt, is de poort: naar_buiten.sh draait
`taalonderdelen.py los --controleer`, en die meldt een los-paar zonder Engelse
kant als "bestaat niet" (afloop 1). Voor een auto-paar doet en_bouw.py dat.

Wat de uitvoer van Quarto moet zijn: een boek is een
<section class="… cc-boek …"> met als eerste een <h3>, en de titellink is het
eerste in die kop (gemeten op Quarto 1.9.38, 23-11-2026). Een boek zonder link
(STAT 3, "in opbouw") krijgt niets. Vindt het script op een plank die er wél
staat GEEN enkel boek, dan is de vorm veranderd en is er niet gekeken: afloop 3,
en dan stopt de bouw. Een plank zonder labels ziet er precies zo uit als een
plank waar niemand ze heeft gevraagd, en dat verschil moet iemand zien.

Idempotent: eerst gaan de labels van een vorige run eruit, dan komen ze terug.

Afloopcodes: 0 klaar (ook als de plank niet in deze bouw zit, zoals in de
Engelse ronde; dat wordt gezegd), 1 een plank niet te lezen of te schrijven,
3 niet gekeken (taalparen.tsv onleesbaar, of geen enkel boek herkend).
Getoetst in _tools/tests/taallabel_test.py, met een mutatieproef.
"""
from __future__ import annotations

import argparse
import os
import posixpath
import re
import sys

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import taalonderdelen  # noqa: E402

REPO = os.path.dirname(HIER)
PLANKEN = ["oefenboeken/index.html"]
TITEL = "The English edition of this book"

_BOEK = re.compile(r'(<section\b[^>]*\bclass="[^"]*\bcc-boek\b[^"]*"[^>]*>\s*<h3\b[^>]*>)(.*?)(</h3>)', re.S)
_TITELLINK = re.compile(r'\s*<a href="([^"]+)"')
_LABEL = re.compile(r' ?<a class="cc-taal" [^>]*>EN</a>')


def label(plank: str, en: str) -> str:
    return (f'<a class="cc-taal" href="{taalonderdelen.relatief(plank, en)}" hreflang="en" lang="en" '
            f'title="{TITEL}">EN</a>')


def doel(plank: str, href: str) -> str | None:
    """Het sitepad waar een link op de plank heen gaat, of None voor een link
    buiten de site (een adres met schema, //, of een absoluut pad)."""
    href = href.split("#", 1)[0].split("?", 1)[0]
    if not href or re.match(r"[a-z][a-z0-9+.-]*:|/", href, re.I):
        return None
    pad = posixpath.normpath(posixpath.join(posixpath.dirname(plank), href))
    if href.endswith("/"):
        pad += "/index.html"
    return None if pad.startswith("..") else pad


def zet(tekst: str, plank: str, tweeling: dict, site: str) -> tuple[str, dict]:
    """De plank met labels, en wat er gezien is. `tweeling`: Nederlands sitepad ->
    zijn paar uit taalparen.tsv."""
    tekst = _LABEL.sub("", tekst)
    telling = {"boeken": 0, "met_link": 0, "label": [], "zonder_pagina": []}

    def per_boek(m: re.Match) -> str:
        telling["boeken"] += 1
        kop = m.group(2)
        t = _TITELLINK.match(kop)
        if not t:
            return m.group(0)
        telling["met_link"] += 1
        nl = doel(plank, t.group(1))
        paar = tweeling.get(nl)
        if not paar:
            return m.group(0)
        en = paar["en"]
        if not os.path.isfile(os.path.join(site, en)):
            telling["zonder_pagina"].append((f"{nl} -> {en}", paar["wissel"]))
            return m.group(0)
        telling["label"].append(f"{nl} -> {en}")
        return m.group(1) + kop + " " + label(plank, en) + m.group(3)

    return _BOEK.sub(per_boek, tekst), telling


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--site", default=os.environ.get("QUARTO_PROJECT_OUTPUT_DIR") or os.path.join(REPO, "_site"))
    ap.add_argument("--paren", help="een andere taalparen.tsv (voor de toets)")
    a = ap.parse_args()
    site = os.path.abspath(a.site)
    if a.paren:
        taalonderdelen.PAREN = os.path.abspath(a.paren)
    try:
        tweeling = {p["nl"]: p for p in taalonderdelen.paren()}
    except (SystemExit, OSError) as e:
        print(f"taallabel: NIET gekeken -- {taalonderdelen.PAREN} is niet te lezen: {e}", file=sys.stderr)
        return 3

    code = 0
    for plank in PLANKEN:
        pad = os.path.join(site, plank)
        if not os.path.isfile(pad):
            print(f"taallabel: {plank} staat niet in {site} -- niet in deze bouw, niets gedaan")
            continue
        try:
            with open(pad, encoding="utf-8", newline="") as f:
                oud = f.read()
            nieuw, t = zet(oud, plank, tweeling, site)
            if nieuw != oud:
                with open(pad, "w", encoding="utf-8", newline="") as f:
                    f.write(nieuw)
        except (OSError, UnicodeError) as e:
            print(f"taallabel: FOUT {plank}: {e}", file=sys.stderr)
            code = max(code, 1)
            continue
        if t["boeken"] == 0:
            print(f"taallabel: NIET gekeken -- geen enkel boek (<section class=\"cc-boek\"> met een <h3>) "
                  f"herkend in {plank}; is de uitvoer van Quarto veranderd?", file=sys.stderr)
            return 3
        print(f"taallabel: {plank} -- {t['boeken']} boeken, {t['met_link']} met een link, "
              f"{len(t['label'])} met EN-label" + (": " + ", ".join(t["label"]) if t["label"] else ""))
        for z, wissel in t["zonder_pagina"]:
            wie = ("taalonderdelen.py los --controleer in naar_buiten.sh" if wissel.startswith("los")
                   else "en_bouw.py in publiceer_en.sh")
            print(f"taallabel: LET OP {z} staat in taalparen.tsv, maar de Engelse bladzij staat niet in "
                  f"{site} -- geen label, want een dode link is erger dan geen label. Tegenhouden doet "
                  f"{wie}", file=sys.stderr)
    return code


if __name__ == "__main__":
    sys.exit(main())
