#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""en_schil_test.py — bijt de keuring van de Engelse schil echt?

    python3 _tools/tests/en_schil_test.py

Vooraf nodig: een gebouwde _site/ met de Engelse kant erin, zoals
`bash _tools/publiceer_en.sh` hem achterlaat (afloop 0). Zonder die bouw kan
deze toets niet kijken en zegt hij dat (afloop 3).

WAAROM. Een keuring die op een schone site "geen gaten" zegt, bewijst niets: dat
zegt een keuring die nergens naar kijkt ook. Deze toets maakt een kopie van de
site, breekt er telkens één ding in — precies het soort fout waarvoor de keuring
bestaat — en eist dat `en_bouw.py keur` dan rood wordt, met de goede reden. Plus
één keer de kopie onaangeroerd: die moet groen zijn, anders bewijzen de rode
uitslagen niets.

De kopie bestaat uit harde links (snel, geen 200 MB kopiëren). Een te breken
bestand wordt eerst losgeknipt en dan opnieuw geschreven, zodat het origineel in
_site/ nooit verandert.

Afloop: 0 alles bijt, 1 minstens één mutatie werd niet gevangen, 3 kon niet kijken.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SITE = os.path.join(REPO, "_site")
KOPIE = os.path.join(REPO, "_site_en_werk", "toets_site")
BOUW = os.path.join(REPO, "_tools", "en_bouw.py")


def keur(site: str, soort: str = "echt") -> tuple[int, str]:
    r = subprocess.run([sys.executable, BOUW, "keur", "--site", site, "--soort", soort],
                       capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def lees(p: str) -> str:
    with open(p, encoding="utf-8") as f:
        return f.read()


def schrijf_los(p: str, tekst: str) -> None:
    """Knip de harde link los en schrijf opnieuw: het origineel blijft heel."""
    os.remove(p)
    with open(p, "w", encoding="utf-8") as f:
        f.write(tekst)


# (naam, bestand in de site, functie tekst->tekst, wat er in de uitvoer moet staan)
MUTATIES = [
    ("teller weg op een Engelse bladzij", "en/about.html",
     lambda t: t.replace("gc.zgo.at/count.js", "gc.zgo.at/weg.js"),
     "bezoekersteller"),
    ("dode link op de Engelse thuispagina", "en/index.html",
     lambda t: t.replace('href="../cv-en.html"', 'href="../cv-en-bestaat-niet.html"', 1),
     "cv-en-bestaat-niet.html"),
    ("hreflang naar het Engels weg op een Nederlandse tweeling", "diensten.html",
     lambda t: re.sub(r'<link rel="alternate" hreflang="en"[^>]*>\n?', "", t),
     "diensten.html: hreflang"),
    ("taalknopje weg op een Engelse bladzij", "en/use.html",
     lambda t: re.sub(r'<nav class="taalwissel".*?</nav>', "", t, flags=re.S),
     "en/use.html: geen taalknopje"),
    ("tikfout in het rekeningnummer", "en/use.html",
     lambda t: t.replace("1306 05", "1306 50"),
     "rekeningnummer"),
    ("tikfout in een mailadres", "en/about.html",
     lambda t: t.replace("mailto:inzichtelijk@gmail.com", "mailto:inzichtelyk@gmail.com"),
     "mailadres"),
    ("werkbriefje in de gepubliceerde HTML", "en/index.html",
     lambda t: t.replace("<main", "<!-- MIEKE: vergeten -->\n<main", 1),
     "werkbriefje"),
    ("verkeerde taal op een Engelse bladzij", "en/services.html",
     lambda t: re.sub(r'lang="en-GB"', 'lang="nl"', t),
     "zonder lang"),
    ("noindex op de echte Engelse site", "en/index.html",
     lambda t: t.replace("</head>", '<meta name="robots" content="noindex">\n</head>', 1),
     "noindex"),
    ("het taalknopje in de Nederlandse zoekindex", "search.json",
     lambda t: json.dumps([dict(d, text=("NL·EN\n" + d["text"]) if d.get("href") == "over.html" else d["text"])
                           for d in json.loads(t)]),
     "zoektekst van over.html"),
]


def main() -> int:
    if not os.path.isfile(os.path.join(SITE, "en", "index.html")):
        print("KON NIET KIJKEN: _site/en/index.html ontbreekt. Draai eerst bash _tools/publiceer_en.sh")
        return 3
    if os.path.isdir(KOPIE):
        shutil.rmtree(KOPIE)
    shutil.copytree(SITE, KOPIE, copy_function=os.link)

    fout = 0
    code, uit = keur(KOPIE)
    schoon = code == 0
    print(f"{'ok  ' if schoon else 'FOUT'}  onaangeroerde kopie: afloop {code} (moet 0 zijn)")
    if not schoon:
        print("      zonder een groene nulmeting bewijzen de rode uitslagen hieronder niets:")
        print("\n".join("      " + r for r in uit.splitlines()[-12:]))
        return 1

    # een mutatie in een bestand dat losstaat van de keuring zelf: de vergelijking
    for naam, rel, mut, verwacht in MUTATIES:
        p = os.path.join(KOPIE, rel)
        orig = lees(p)
        nieuw = mut(orig)
        if nieuw == orig:
            print(f"FOUT  {naam}: de mutatie veranderde niets aan {rel} — de toets zelf klopt niet meer")
            fout += 1
            continue
        schrijf_los(p, nieuw)
        code, uit = keur(KOPIE)
        schrijf_los(p, orig)
        gevangen = code == 1 and verwacht in uit
        print(f"{'ok  ' if gevangen else 'FOUT'}  {naam}: afloop {code}, "
              f"{'reden genoemd' if verwacht in uit else 'reden NIET genoemd (' + verwacht + ')'}")
        if not gevangen:
            fout += 1

    # de vergelijking van de Nederlandse vingerafdruk: één byte anders moet rood zijn
    voor = os.path.join(REPO, "_site_en_werk", "toets_voor.json")
    na = os.path.join(REPO, "_site_en_werk", "toets_na.json")
    subprocess.run([sys.executable, BOUW, "foto", "--site", KOPIE, "--uit", voor], capture_output=True)
    p = os.path.join(KOPIE, "archief", "index.html")
    orig = lees(p)
    schrijf_los(p, orig.replace("</body>", " </body>", 1))
    subprocess.run([sys.executable, BOUW, "foto", "--site", KOPIE, "--uit", na], capture_output=True)
    schrijf_los(p, orig)
    r = subprocess.run([sys.executable, BOUW, "vergelijk", voor, na], capture_output=True, text=True)
    gevangen = r.returncode == 1 and "archief/index.html" in r.stdout
    print(f"{'ok  ' if gevangen else 'FOUT'}  één spatie erbij in een Nederlandse bladzij zonder tweeling: "
          f"afloop {r.returncode}{', archief/index.html genoemd' if 'archief/index.html' in r.stdout else ''}")
    fout += 0 if gevangen else 1

    # en na alles: is de kopie weer groen? (anders lekte een mutatie door)
    code, _ = keur(KOPIE)
    print(f"{'ok  ' if code == 0 else 'FOUT'}  kopie na het terugzetten: afloop {code} (moet 0 zijn)")
    fout += 0 if code == 0 else 1

    # Een losse Engelse bladzij onder en/ (een speeltje, een hoofdstuk van een later
    # spoor) moet het neerzetten overleven. Tot 24-10-2026 leegde `zet` een bouwmap
    # eerst helemaal, en dan verdween zo'n bladzij uit de site die gekeurd werd.
    los = os.path.join(KOPIE, "en", "los_speeltje.html")
    with open(los, "w", encoding="utf-8") as f:
        f.write('<!DOCTYPE html><html lang="en"><head><title>los</title></head><body>los</body></html>')
    gegen = os.path.join(KOPIE, "en", "index.html")
    schrijf_los(gegen, lees(gegen) + "\n<!-- oud -->\n")      # een 'oude' gegenereerde bladzij
    r = subprocess.run([sys.executable, BOUW, "zet", "--naar", KOPIE], capture_output=True, text=True)
    bleef = os.path.isfile(los)
    ververst = "<!-- oud -->" not in lees(gegen)
    goed = r.returncode == 0 and bleef and ververst
    print(f"{'ok  ' if goed else 'FOUT'}  neerzetten: losse Engelse bladzij blijft staan ({'ja' if bleef else 'NEE'}), "
          f"gegenereerde bladzij ververst ({'ja' if ververst else 'NEE'}), afloop {r.returncode}")
    fout += 0 if goed else 1
    shutil.rmtree(KOPIE)

    n = len(MUTATIES) + 4
    print(f"\n{n - fout} van {n} toetsen goed" + ("" if fout == 0 else f" — {fout} FOUT"))
    return 0 if fout == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
