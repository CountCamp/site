#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""taalonderdelen.py — de stukken van de taalwissel, voor wie Python spreekt.

Een bladzij met een tweeling krijgt hooguit vijf stukken, en verder niets:

  hreflang   drie <link rel="alternate" hreflang=…> in <head> (nl, en, x-default)
  knop       het knopje NL · EN, bovenaan de tekst
  stijl      het <style>-blok van dat knopje (_tools/taalwissel/stijl_knop.html,
             of stijl_knop_los.html op een bladzij die Quarto niet bouwt)
  balk       alleen op de NEDERLANDSE kant: de taalbalk (_tools/taalwissel/balk.html)

Drie lezers moeten precies dezelfde bytes zien, en daarom staat elk stuk één keer:
  _tools/taalwissel.lua   de bladzijden die Quarto bouwt (taalparen.tsv: auto, eigen)
  dit bestand             de losse bladzijden (taalparen.tsv: los, los-eigen) —
                          bouw_speelkist.py roept pas_toe_los() aan bij het kopiëren
  de wachtrij             (wachtrij_en.tsv, `#: nl_negeer`) laat deze stukken weg
                          voor hij Nederlands vergelijkt. Die regels rekent
                          `regels` hieronder uit; ze worden nooit met de hand getikt.

    python3 _tools/taalonderdelen.py regels            de nl_negeer-regels voor de wachtrij
    python3 _tools/taalonderdelen.py los               zet de stukken in de losse bladzijden
    python3 _tools/taalonderdelen.py los --controleer  kijk alleen of ze er goed in staan

DE UITZONDERING IS SMAL, en zo is ze bedoeld (Ben, 24-10-2026: het knopje mag op de
Nederlandse bladzijden; "anything else changing in a Dutch page's output still stops
it"). Stijl en balk worden LETTERLIJK weggelaten: één teken anders, en de regel past
niet meer en de wachtrij stopt. Dat is met opzet, want een stijlblok of script draait op
elke Nederlandse bladzij en kan alles: een wijziging daaraan hoort een mens te zien.
Alleen het adres in een link mag variëren, en dan alleen als pad binnen de site (het
knopje) of als adres op countcamp.org (hreflang) — geen ander domein, geen javascript:.
Getoetst in _tools/tests/taalwissel_negeer_test.py, met verminkingen die moeten zakken.

Afloopcodes, huisafspraak: 0 schoon, 1 er is een gat, 2 verkeerd aangeroepen.
"""
from __future__ import annotations

import argparse
import os
import re
import sys

HIER = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HIER)
STUKKEN = os.path.join(HIER, "taalwissel")
PAREN = os.path.join(HIER, "taalparen.tsv")
BASIS = "https://countcamp.org/"
SOORTEN = ("auto", "eigen", "los", "los-eigen")


def lees(pad: str) -> str:
    with open(pad, encoding="utf-8") as f:
        return f.read()


def stuk(naam: str) -> str:
    """Een stuk zoals het in de bladzij komt: witruimte aan het eind telt niet
    (taalwissel.lua doet precies hetzelfde: gsub("%s+$", ""))."""
    return lees(os.path.join(STUKKEN, naam)).rstrip()


def paren() -> list[dict]:
    """taalparen.tsv, zoals taalwissel.lua hem leest."""
    uit = []
    for nr, regel in enumerate(lees(PAREN).splitlines(), 1):
        if not regel.strip() or regel.lstrip().startswith("#"):
            continue
        v = [x.strip() for x in regel.split("\t")]
        if len(v) < 3 or v[2] not in SOORTEN:
            raise SystemExit(f"FOUT: {PAREN} regel {nr} is geen 'nl<TAB>en<TAB>{'|'.join(SOORTEN)}': {regel!r}")
        uit.append({"nl": v[0], "en": v[1], "wissel": v[2]})
    return uit


def vol_adres(sitepad: str) -> str:
    """Vol adres; een index.html wordt het adres van zijn map (countcamp.org/en/)."""
    return BASIS + re.sub(r"index\.html$", "", sitepad)


def relatief(van: str, naar: str) -> str:
    """Relatief pad van de map van `van` naar `naar` (allebei sitepaden). Zelfde
    uitkomst als relatief() in taalwissel.lua."""
    a = van.split("/")[:-1]
    b = naar.split("/")
    i = 0
    while i < len(a) and i < len(b) - 1 and a[i] == b[i]:
        i += 1
    return "/".join([".."] * (len(a) - i) + b[i:])


# ------------------------------------------------------------ de stukken ----
def hreflang(paar: dict) -> str:
    return "\n".join([
        f'<link rel="alternate" hreflang="nl" href="{vol_adres(paar["nl"])}">',
        f'<link rel="alternate" hreflang="en" href="{vol_adres(paar["en"])}">',
        f'<link rel="alternate" hreflang="x-default" href="{vol_adres(paar["nl"])}">',
    ])


def knop(paar: dict, kant: str, los: bool) -> str:
    """Het knopje; dezelfde vorm als in taalwissel.lua, met op een losse bladzij
    een extra klasse voor zijn eigen stijl."""
    klasse = "taalwissel taalwissel-los" if los else "taalwissel"
    if kant == "nl":
        return (f'<nav class="{klasse}" aria-label="taal"><span aria-current="page">NL</span>'
                '<span class="taalwissel-sep" aria-hidden="true">·</span>'
                f'<a href="{relatief(paar["nl"], paar["en"])}" hreflang="en" lang="en" '
                'title="This page in English">EN</a></nav>')
    return (f'<nav class="{klasse}" aria-label="language">'
            f'<a href="{relatief(paar["en"], paar["nl"])}" hreflang="nl" lang="nl" '
            'title="Deze bladzij in het Nederlands">NL</a>'
            '<span class="taalwissel-sep" aria-hidden="true">·</span><span aria-current="page">EN</span></nav>')


# ------------------------------------------------- de regels voor de wachtrij ----
def letterlijk(t: str) -> str:
    """Een regex die precies `t` vindt, op één regel (een TSV-veld mag geen
    regeleinde bevatten). re.escape zet voor een regeleinde een backslash met
    het regeleinde zelf erachter; dat zou het veld breken, dus teken voor teken."""
    return "".join(r"\n" if c == "\n" else re.escape(c) for c in t)


# Een pad binnen de site, zonder schema of domein: en/services.html, ../tables/index.html.
_PAD = r"(?:\.\./)*[A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*(?:\.html|/)"
# Een adres op countcamp.org: https://countcamp.org/, …/en/, …/diensten.html.
_ADRES = r"https://countcamp\.org/(?:[A-Za-z0-9_-]+/)*(?:[A-Za-z0-9_.-]+\.html)?"


def negeer_regexen() -> list[tuple[str, str]]:
    """[(naam, regex)]: wat de wachtrij uit een Nederlandse .html weglaat voor ze
    vergelijkt. Elk stuk mét het regeleinde dat de bouw erachter zet (gemeten in
    de bouw van 24-10-2026: elk stuk staat op eigen regels). Volgorde doet er niet
    toe; ze overlappen niet."""
    return [
        ("hreflang", r'<link rel="alternate" hreflang="(?:nl|en|x-default)" href="' + _ADRES + r'">\n'),
        ("knop", r'<nav class="taalwissel(?: taalwissel-los)?" aria-label="taal"><span aria-current="page">NL</span>'
                 r'<span class="taalwissel-sep" aria-hidden="true">·</span><a href="' + _PAD
                 + r'" hreflang="en" lang="en" title="This page in English">EN</a></nav>\n'),
        ("stijl_knop", letterlijk(stuk("stijl_knop.html")) + r"\n"),
        ("stijl_knop_los", letterlijk(stuk("stijl_knop_los.html")) + r"\n"),
        ("balk", letterlijk(stuk("balk.html")) + r"\n"),
    ]


def cmd_regels(a) -> int:
    rx = negeer_regexen()
    for naam, r in rx:
        if "\t" in r or "\n" in r:
            print(f"FOUT: de regel voor {naam} bevat een tab of regeleinde; dat breekt het rijbestand", file=sys.stderr)
            return 1
        re.compile(r)
    print("# nl_negeer voor wachtrij_en.tsv — uitgerekend door _tools/taalonderdelen.py regels")
    print(f"# uit _tools/taalwissel/*.html; {len(rx)} regels: {', '.join(n for n, _ in rx)}")
    for _naam, r in rx:
        print(f"#: nl_negeer\t{r}")
    return 0


# -------------------------------------------------------- losse bladzijden ----
# De terugknop van een Engelse losse bladzij wees naar de Nederlandse voordeur
# (tables/index.html: "← CountCamp" → https://countcamp.org/). De bron staat in
# het lab (countcamp_lab/boek/04_speeltjes/tabellen_aflezen_en.html); tot die
# daar is aangepast, buigt de kopieerstap hem om naar /en/. Spoor en_schil,
# 24-10-2026; het speeltje zelf is van spoor en_speeltjes.
_TERUG_NL = re.compile(r'(<a class="back" href=")https://countcamp\.org/(")')


def _paar_van(sitepad: str) -> tuple[dict | None, str | None]:
    for p in paren():
        if p["wissel"] not in ("los", "los-eigen"):
            continue
        if p["nl"] == sitepad:
            return p, "nl"
        if p["en"] == sitepad:
            return p, "en"
    return None, None


def zonder_stukken(tekst: str, paar: dict, kant: str) -> str:
    """Haal weg wat pas_toe_los erin zet, zodat opnieuw toepassen niets verdubbelt."""
    for naam, r in negeer_regexen():
        if paar["wissel"] == "los-eigen" and naam != "balk":
            continue        # hreflang en knopje zijn daar van de bladzij zelf
        tekst = re.sub(r, "", tekst)
    if kant == "en" and paar["wissel"] == "los":
        tekst = re.sub(r'<link rel="alternate" hreflang="(?:nl|en|x-default)" href="' + _ADRES + r'">\n', "", tekst)
        tekst = re.sub(r'<nav class="taalwissel taalwissel-los" aria-label="language">.*?</nav>\n', "", tekst)
    return tekst


def pas_toe_los(tekst: str, sitepad: str) -> str:
    """De stukken in een losse bladzij (taalparen.tsv: los of los-eigen). Een
    bladzij die er niet in staat, komt onveranderd terug. Twee keer toepassen
    geeft hetzelfde als één keer."""
    paar, kant = _paar_van(sitepad)
    if not paar:
        return tekst
    t = zonder_stukken(tekst, paar, kant)
    kop = []
    if paar["wissel"] == "los":
        kop += [hreflang(paar), stuk("stijl_knop_los.html")]
    if kant == "nl":
        kop.append(stuk("balk.html"))
    if t.count("</head>") != 1:
        raise ValueError(f"{sitepad}: geen of meer dan één </head>; ik weet niet waar de stukken moeten")
    t = t.replace("</head>", "".join(s + "\n" for s in kop) + "</head>", 1)
    if paar["wissel"] == "los":
        m = re.search(r'<div class="wrap">\n', t) or re.search(r"<body[^>]*>\n", t)
        if not m:
            raise ValueError(f"{sitepad}: geen <div class=\"wrap\"> of <body> op een eigen regel; waar moet het knopje?")
        t = t[:m.end()] + knop(paar, kant, los=True) + "\n" + t[m.end():]
        if kant == "en":
            t = _TERUG_NL.sub(r"\1https://countcamp.org/en/\2", t)
    return t


def cmd_los(a) -> int:
    gaten, n = [], 0
    for p in paren():
        if p["wissel"] not in ("los", "los-eigen"):
            continue
        for kant in ("nl", "en"):
            pad = os.path.join(REPO, p[kant])
            if not os.path.isfile(pad):
                gaten.append(f"{p[kant]}: bestaat niet")
                continue
            n += 1
            oud = lees(pad)
            nieuw = pas_toe_los(oud, p[kant])
            if oud == nieuw:
                print(f"  {p[kant]}: in orde")
            elif a.controleer:
                gaten.append(f"{p[kant]}: de taalstukken staan er niet (goed) in — draai `python3 _tools/taalonderdelen.py los`")
            else:
                with open(pad, "w", encoding="utf-8") as f:
                    f.write(nieuw)
                print(f"  {p[kant]}: bijgewerkt")
    print(f"  losse bladzijden: {n} nagelopen, {len(gaten)} gat(en)")
    for g in gaten:
        print("    - " + g)
    return 1 if gaten or n == 0 else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("regels")
    lo = sub.add_parser("los")
    lo.add_argument("--controleer", action="store_true")
    a = ap.parse_args()
    return {"regels": cmd_regels, "los": cmd_los}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
