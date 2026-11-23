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
       title="The English edition of this book">EN →</a>

Zijn uiterlijk en het waarom daarvan staan in styles.css ("het EN-label"). Het
staat rechts bij de pillen en niet links vóór de titel, zoals het taalmerk op de
Engelse plank: dat merk zegt in welke taal de titellink landt, en vóór een
Nederlandse titel zou EN lezen als "dit boek is Engels". Hier is het label zelf
de link.

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
Wie het gat wel tegenhoudt, hangt van het soort paar af. Een los-paar (alle
oefenboeken) zonder Engelse kant meldt `taalonderdelen.py los --controleer` als
"bestaat niet" (afloop 1), en dat houdt naar_buiten.sh --productie en de Action
tegen. Een auto- of eigen-paar houdt alleen en_bouw.py tegen, en dat draait
alleen in publiceer_en.sh: daar blijft het bij de LET OP-regel (nakijker,
23-11-2026). Op 23-11 heeft geen boek op de plank zo'n paar.

Wat de uitvoer van Quarto moet zijn: een boek is een
<section class="… cc-boek …"> met als eerste een <h3>, en de titellink is het
eerste in die kop (gemeten op Quarto 1.9.38, 23-11-2026). Een boek zonder link
(STAT 3, "in opbouw") krijgt niets. Herkent het script op een plank die er wél
staat GEEN enkel boek, of één boek niet (een element met de klasse cc-boek dat
geen <section> met een <h3> is, of een kop waarin de link niet vooraan staat),
dan is er niet (helemaal) gekeken: afloop 3, en dan stopt de bouw. Een plank
zonder labels ziet er precies zo uit als een plank waar niemand ze heeft
gevraagd, en dat verschil moet iemand zien.

NIET GEDEKT (nakijker, 23-11-2026): de wachtrij van de Engelse vertalers
vergelijkt Nederlandse bladzijden voor en na een stap, met uitzonderingen uit
`taalonderdelen.py regels`. Het label staat daar niet tussen. Een stap die een
paar voor een boek op de plank toevoegt, zou de plank dus veranderen en
tegengehouden worden. Nu kan dat niet: taalparen.tsv staat in _tools/, en de
rij raakt _tools/ niet aan. Of het label een uitzondering krijgt, beslist Ben.

Idempotent: eerst gaan de labels van een vorige run eruit, dan komen ze terug.

Afloopcodes: 0 klaar (ook als de plank niet in deze bouw zit, zoals in de
Engelse ronde; dat wordt gezegd), 1 een plank niet te lezen of te schrijven,
3 niet gekeken (taalparen.tsv onleesbaar, of een boek niet herkend). Let op:
Quarto maakt van elke afloop van een post-render-stap een 1 en slaat de stappen
erna over; een mislukte run laat een _site zonder teller en mét commentaar
achter (nakijker, 23-11-2026, gemeten). De Action en naar_buiten.sh laten die
niet door.
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
# De pijl is die van de titels op de plank: "hier ga je naar binnen". Zonder pijl lazen
# beide testlezers het label als sticker, naast de pil "nieuw" (zie styles.css, "het EN-label").
TEKST = "EN →"

_BOEK = re.compile(r'(<section\b[^>]*\bclass="[^"]*\bcc-boek\b[^"]*"[^>]*>\s*<h3\b[^>]*>)(.*?)(</h3>)', re.S)
_TITELLINK = re.compile(r'\s*<a href="([^"]+)"')
_KLASSE = re.compile(r'<[a-zA-Z][a-zA-Z0-9]*\b[^>]*\bclass="([^"]*)"')
_LABEL = re.compile(r' ?<a class="cc-taal" [^>]*>[^<]*</a>')


def label(plank: str, en: str) -> str:
    return (f'<a class="cc-taal" href="{taalonderdelen.relatief(plank, en)}" hreflang="en" lang="en" '
            f'title="{TITEL}">{TEKST}</a>')


def doel(plank: str, href: str) -> str | None:
    """Het sitepad waar een link op de plank heen gaat, of None voor een link
    buiten de site. Binnen de site zijn: een relatief pad (ts/index.html,
    ../manuscript/…), een pad vanaf de wortel (/oefenboeken/ts/) en een vol adres
    op countcamp.org. Een map (eindigt op /) wordt zijn index.html. Een #anker of
    ?vraag doet niet mee. Buiten: elk ander schema (https://elders, mailto:), //,
    en een pad dat boven de wortel uitkomt."""
    href = href.split("#", 1)[0].split("?", 1)[0]
    m = re.match(r"https?://(?:www\.)?countcamp\.org(/.*)?\Z", href, re.I)
    if m:
        href = m.group(1) or "/"
    if not href or re.match(r"[a-z][a-z0-9+.-]*:|//", href, re.I):
        return None
    basis = "" if href.startswith("/") else posixpath.dirname(plank)
    pad = posixpath.normpath(posixpath.join(basis, href.lstrip("/")))
    if href.endswith("/"):
        pad = "index.html" if pad == "." else pad + "/index.html"
    return None if pad == ".." or pad.startswith("../") else pad


def zet(tekst: str, plank: str, tweeling: dict, site: str) -> tuple[str, dict]:
    """De plank met labels, en wat er gezien is. `tweeling`: Nederlands sitepad ->
    zijn paar uit taalparen.tsv."""
    tekst = _LABEL.sub("", tekst)
    telling = {"boeken": 0, "met_link": 0, "label": [], "zonder_pagina": [], "onbekend": []}

    # ELK BOEK MOET HERKEND WORDEN, niet alleen één. Een element met de klasse
    # cc-boek dat geen <section> met een <h3> is (Quarto maakt er een <div> van zodra
    # er iets vóór de ### staat), of een kop met een link die niet vooraan staat
    # (<strong><a>, een pil ervoor, <a class=… href=…>), zou anders stil zonder
    # label blijven, met afloop 0 (nakijker, 23-11-2026, gemeten).
    elementen = [m.group(0)[:90] for m in _KLASSE.finditer(tekst) if "cc-boek" in m.group(1).split()]

    def per_boek(m: re.Match) -> str:
        telling["boeken"] += 1
        kop = m.group(2)
        t = _TITELLINK.match(kop)
        if not t:
            if "<a " in kop:
                telling["onbekend"].append("een link die niet vooraan in de kop staat: " + kop.strip()[:90])
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

    uit = _BOEK.sub(per_boek, tekst)
    if len(elementen) != telling["boeken"]:
        telling["onbekend"].append(f"{len(elementen)} element(en) met de klasse cc-boek, maar {telling['boeken']} "
                                   f"als <section> met een <h3> herkend; het eerste: {elementen[0] if elementen else '-'}")
    return uit, telling


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
    except (SystemExit, OSError, UnicodeError) as e:
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
        if t["onbekend"]:
            print(f"taallabel: NIET (helemaal) gekeken -- {plank} heeft een boek in een vorm die ik niet ken, en dat "
                  f"boek zou stil zonder label blijven:", file=sys.stderr)
            for o in t["onbekend"]:
                print(f"    - {o}", file=sys.stderr)
            print("  Zet de kaart in oefenboeken/index.qmd terug in de vorm ::: {.cc-boek} / ### [titel](pad) / "
                  "tekst, of leer dit script de nieuwe vorm.", file=sys.stderr)
            return 3
        print(f"taallabel: {plank} -- {t['boeken']} boeken, {t['met_link']} met een link, "
              f"{len(t['label'])} met EN-label" + (": " + ", ".join(t["label"]) if t["label"] else ""))
        for z, wissel in t["zonder_pagina"]:
            wie = ("Tegenhouden doen taalonderdelen.py los --controleer in naar_buiten.sh en de Action"
                   if wissel.startswith("los") else
                   "Tegenhouden doet alleen en_bouw.py in publiceer_en.sh; de Action en naar_buiten.sh NIET")
            print(f"taallabel: LET OP {z} staat in taalparen.tsv, maar de Engelse bladzij staat niet in "
                  f"{site} -- geen label, want een dode link is erger dan geen label. {wie}.", file=sys.stderr)
    return code


if __name__ == "__main__":
    sys.exit(main())
