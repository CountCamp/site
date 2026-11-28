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
                          bouw_speelkist.py roept pas_toe_los() aan bij het kopiëren,
                          publish_workbook.py na het inlezen van een oefenboek
  de wachtrij             (wachtrij_en.tsv, `#: nl_negeer`) laat deze stukken weg
                          voor hij Nederlands vergelijkt. Die regels rekent
                          `regels` hieronder uit; ze worden nooit met de hand getikt.

    python3 _tools/taalonderdelen.py regels            de nl_negeer-regels voor de wachtrij
    python3 _tools/taalonderdelen.py los               zet de stukken in de losse bladzijden
    python3 _tools/taalonderdelen.py los --controleer  kijk alleen of ze er goed in staan
                                                        (en, sinds 28-11-2026, of beide kanten
                                                        van elk auto- en eigen-paar er staan)
    python3 _tools/taalonderdelen.py ruim <pad> ...     haal ze uit een wees (niet in de tabel)

DE UITZONDERING IS SMAL, en zo is ze bedoeld (Ben, 24-10-2026: het knopje mag op de
Nederlandse bladzijden; "anything else changing in a Dutch page's output still stops
it"). Stijl en balk worden LETTERLIJK weggelaten: één teken anders, en de regel past
niet meer en de wachtrij stopt. Dat is met opzet, want een stijlblok of script draait op
elke Nederlandse bladzij en kan alles: een wijziging daaraan hoort een mens te zien.
Alleen het adres in een link mag variëren, en dan alleen als pad binnen de site (het
knopje) of als adres op countcamp.org (hreflang) — geen ander domein, geen javascript:.
Getoetst in _tools/tests/taalwissel_negeer_test.py, met verminkingen die moeten zakken.

Afloopcodes, huisafspraak: 0 schoon, 1 er is een gat, 2 verkeerd aangeroepen,
3 kon niet kijken (taalparen.tsv is niet te lezen, er staat geen enkele los- of
los-eigen-regel in zodat er niets na te lopen viel, of het gereedschap zelf liep
vast -- bv. een stuk in _tools/taalwissel/ ontbreekt).
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


# EEN REGEL IN PLAATS VAN EEN PAAR (spoor en_boekpers, 25-10-2026). Een regel in
# taalparen.tsv met <n> in beide kolommen, zoals
#     manuscript/h<n>.html	en/book/h<n>.html	los
# staat voor elk paar waarvan de ENGELSE kant in de repo staat, met <n> een getal:
# staat er en/book/h0.html, dan is manuscript/h0.html ↔ en/book/h0.html een paar;
# komt en/book/h1.html erbij, dan dat ook. Waarom: de Engelse hoofdstukken komen één
# voor één uit het lab, en de wachtrij laat een stap _tools/ niet aanraken
# ('#: beschermd site _tools/*'). Met een regel per paar moest elk hoofdstuk deze
# tabel veranderen, en kon geen enkel hoofdstuk door de rij. Met deze regel hoeft
# dat nooit; wat er bij komt is het Engelse bestand zelf.
# Alleen `los` en `los-eigen`: taalwissel.lua leest geen regels (hij vergelijkt
# letterlijk, en "h<n>.html" is nooit een bladzij), dus voor auto/eigen zou zo'n
# regel stil niets doen. Dat weigeren we hier hardop.
REGEL_N = "<n>"


def _uit_regel(nl: str, en: str, wissel: str, nr: int) -> list[dict]:
    if wissel not in ("los", "los-eigen"):
        raise SystemExit(f"FOUT: {PAREN} regel {nr}: een regel met {REGEL_N} kan alleen los of los-eigen zijn "
                         f"(taalwissel.lua leest geen regels), niet {wissel}")
    for kol in (nl, en):
        if kol.count(REGEL_N) != 1 or REGEL_N not in os.path.basename(kol):
            raise SystemExit(f"FOUT: {PAREN} regel {nr}: {REGEL_N} hoort precies één keer in de bestandsnaam "
                             f"van beide kolommen: {kol!r}")
    map_ = os.path.join(REPO, os.path.dirname(en))
    vorm = re.compile(re.escape(os.path.basename(en)).replace(re.escape(REGEL_N), r"(\d+)") + r"\Z")
    namen = sorted(os.listdir(map_)) if os.path.isdir(map_) else []
    getallen = sorted({m.group(1) for m in map(vorm.match, namen) if m}, key=int)
    return [{"nl": nl.replace(REGEL_N, n), "en": en.replace(REGEL_N, n), "wissel": wissel, "regel": nr}
            for n in getallen]


def paren() -> list[dict]:
    """taalparen.tsv, zoals taalwissel.lua hem leest — met elke regel (<n>, zie
    hierboven) uitgeschreven tot de paren die er nu zijn."""
    uit = []
    for nr, regel in enumerate(lees(PAREN).splitlines(), 1):
        if not regel.strip() or regel.lstrip().startswith("#"):
            continue
        v = [x.strip() for x in regel.split("\t")]
        if len(v) < 3 or v[2] not in SOORTEN:
            raise SystemExit(f"FOUT: {PAREN} regel {nr} is geen 'nl<TAB>en<TAB>{'|'.join(SOORTEN)}': {regel!r}")
        if REGEL_N in v[0] or REGEL_N in v[1]:
            uit += _uit_regel(v[0], v[1], v[2], nr)
        else:
            uit.append({"nl": v[0], "en": v[1], "wissel": v[2]})
    # Eén bladzij in twee paren: dan weet geen lezer welk knopje erop hoort.
    gezien = {}
    for p in uit:
        for kant in ("nl", "en"):
            if p[kant] in gezien:
                raise SystemExit(f"FOUT: {PAREN}: {p[kant]} staat in twee paren ({gezien[p[kant]]} en "
                                 f"{p['nl']} ↔ {p['en']})")
            gezien[p[kant]] = f"{p['nl']} ↔ {p['en']}"
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


# WEZEN (spoor taalpers, 21-11-2026). `los` liep tot hier alleen de bladzijden UIT de
# tabel na. Een bladzij die er uit verdween, hield zijn knopje -- naar een tweeling
# die er niet meer is, of naar een Engelse wachtpagina -- en niemand zag het, behalve
# en_bouw.py keur 4b, en die draait alleen in publiceer_en.sh. Met een <n>-regel
# gebeurt het zelfs zonder dat iemand de tabel aanraakt: haal en/book/h1.html weg,
# en manuscript/h1.html valt uit de tabel met zijn knopje erin (tegendraadse
# nakijker, gemeten in een kladsite: "2 nagelopen, 0 gat(en)", afloop 0).
# Daarom ook: elke .html in de repo die een taalstuk draagt, moet in de tabel staan.
# WAT HIJ OVERSLAAT, en waarom precies dat. NIET "elke map met een _": Quarto neemt
# zulke mappen wél mee als ze onder een bijlage-glob vallen (oefenboeken/ts/_common_ts/
# staat live; tweede nakijker, 21-11-2026). Wel: wat met een punt begint (.git,
# .quarto, .claude), de bouwmappen zelf (_site, _site_en, _site_spook, _site_en_werk),
# _freeze en node_modules, en _tools/ in de wortel -- daar staan de stukken zelf.
# Een map die hij niet mag lezen, maakt de doorloop onvolledig: dan "niet gekeken".
_MERKEN = {
    "knopje": '<nav class="taalwissel',
    "taalbalk": "/* taalbalk:",
    "hreflang": '<link rel="alternate" hreflang="',
}


def _niet_live(d: str, in_wortel: bool) -> bool:
    return (d.startswith((".", "_site")) or d in ("_freeze", "node_modules")
            or (in_wortel and d == "_tools"))


def wezen(tabel: list[dict]) -> tuple[int, list[str], list[str]]:
    """(aantal nagelopen .html buiten de tabel, ['<pad>: draagt …'], [mappen die
    niet te lezen waren])."""
    in_tabel = {p[k] for p in tabel for k in ("nl", "en")}
    n, uit, gezien, blind = 0, [], set(), []
    for dp, dirs, fs in os.walk(REPO, followlinks=True, onerror=lambda e: blind.append(f"{e.filename}: {e.strerror}")):
        echt = os.path.realpath(dp)
        if echt in gezien:          # een wegwijzer in een kring
            dirs[:] = []
            continue
        gezien.add(echt)
        wortel = os.path.samefile(dp, REPO)
        dirs[:] = sorted(d for d in dirs if not _niet_live(d, wortel))
        for f in sorted(fs):
            if not f.endswith(".html"):
                continue
            rel = os.path.relpath(os.path.join(dp, f), REPO).replace(os.sep, "/")
            if rel in in_tabel:
                continue
            n += 1
            with open(os.path.join(dp, f), encoding="utf-8", errors="replace") as h:
                t = h.read()
            dragen = [naam for naam, merk in _MERKEN.items() if merk in t]
            if dragen:
                uit.append(f"{rel}: draagt {', '.join(dragen)}, maar staat niet in taalparen.tsv (een wees) — "
                           f"zet het paar terug en draai `los`, of haal de stukken weg met "
                           f"`python3 _tools/taalonderdelen.py ruim {rel}`")
    return n, uit, blind


# DE BLADZIJDEN VAN EEN auto- OF eigen-PAAR BESTAAN (spoor sitemap_hreflang, 28-11-2026).
# taalwissel.lua zet knopje en hreflang op zo'n bladzij zonder te kijken of de tweeling
# er is. Beide kanten bouwt Quarto, dus elk heeft een .qmd -- maar de Action bouwt en/
# niet ("!en/" in _quarto-nl.yml): een kant onder en/ komt als bijlage mee, en staat er
# live alleen als publiceer_en.sh hem bouwde en iemand de .html committe. Op 28-11-2026
# gebeurde dat niet: 4bfecabe zette en/book/index.qmd en het paar met manuscript/index.html
# neer, en manuscript/ wees live met hreflang naar een en/book/ die er niet was. Pas de
# sitemapwacht zag het, na een hele bouw; twee runs rood, de site bleef staan.
# Tot die dag stond dit alleen als zin in taalparen.tsv ("Daarom weigert publiceer_en.sh
# dan"), en die weigert alleen als iemand hem draait.
def quarto_tweelingen(tabel: list[dict]) -> tuple[int, list[str]]:
    """(aantal nagelopen kanten, ['<pad>: …']) voor de auto- en eigen-paren."""
    n, gaten = 0, []
    for p in tabel:
        if p["wissel"] not in ("auto", "eigen"):
            continue
        for kant in ("nl", "en"):
            sitepad = p[kant]
            n += 1
            bron = sitepad[:-len(".html")] + ".qmd" if sitepad.endswith(".html") else None
            if not bron or not os.path.isfile(os.path.join(REPO, bron)):
                gaten.append(f"{sitepad}: er staat geen {bron or 'bron'} om hem uit te bouwen "
                             f"({p['wissel']} = Quarto bouwt hem) — zet de bron neer, of haal het paar "
                             f"uit taalparen.tsv")
            elif sitepad.startswith("en/") and not os.path.isfile(os.path.join(REPO, sitepad)):
                gaten.append(f"{sitepad}: nooit gebouwd — {bron} staat er, maar de Action bouwt en/ "
                             f"niet, en dan wijst {p['nl'] if kant == 'en' else p['en']} met hreflang "
                             f"naar niets. Herstellen: bash _tools/publiceer_en.sh, en commit wat hij in "
                             f"en/ zet")
    return n, gaten


def zonder_alle_stukken(tekst: str) -> str:
    """Alles wat pas_toe_los ooit in een bladzij zet, aan beide kanten, ongeacht een
    paar: voor een wees, die geen paar meer heeft om zonder_stukken mee te vragen."""
    for _naam, r in negeer_regexen():
        tekst = re.sub(r, "", tekst)
    return re.sub(r'<nav class="taalwissel taalwissel-los" aria-label="language">.*?</nav>\n', "", tekst)


def cmd_ruim(a) -> int:
    """Haal de taalstukken uit een wees. Alleen op een bladzij die NIET in de tabel
    staat, en alleen als je hem bij naam noemt: of de tabel of de bladzij achterloopt,
    beslist een mens (tweede nakijker, 21-11-2026: zonder dit gereedschap had een wees
    geen herstel, en hield hij elke pers tegen)."""
    in_tabel = {p[k] for p in paren() for k in ("nl", "en")}
    fout = 0
    for sitepad in a.pad:
        sitepad = sitepad.replace(os.sep, "/")
        pad = os.path.join(REPO, sitepad)
        if sitepad in in_tabel:
            print(f"  {sitepad}: staat in taalparen.tsv — geen wees; niets weggehaald (bedoel je `los`?)")
            fout = 1
            continue
        if not os.path.isfile(pad):
            print(f"  {sitepad}: bestaat niet")
            fout = 1
            continue
        oud = lees(pad)
        nieuw = zonder_alle_stukken(oud)
        if nieuw == oud:
            print(f"  {sitepad}: droeg geen taalstukken (die ik herken) — niets weggehaald")
            fout = 1
            continue
        with open(pad, "w", encoding="utf-8") as f:
            f.write(nieuw)
        print(f"  {sitepad}: taalstukken weggehaald ({len(oud) - len(nieuw)} tekens)")
    return fout


def cmd_los(a) -> int:
    # Een tabel die niet te lezen is, is geen gat in een bladzij maar een wachter
    # die niet kon kijken: dan weet niemand welke bladzijden stukken horen te
    # dragen. Daarom 3 en niet 1. Met 1 zei naar_buiten.sh "een bladzij mist zijn
    # taalknopje", en wie dat las zocht in de bladzijden naar een fout die in de
    # tabel zat (spoor taalpers, 21-11-2026).
    try:
        tabel = paren()
    except SystemExit as e:
        print(f"  {e}")
        print("  losse bladzijden: NIET nagelopen — taalparen.tsv is niet te lezen")
        return 3
    # De stukken zelf één keer vooraf. Is er een kapot of weg, dan is dat een fout
    # van het gereedschap (main: afloop 3), en niet van elke bladzij die ze daarna
    # niet kon krijgen -- zo stond het er tot de tweede nakijker (21-11-2026): één
    # byte geen UTF-8 in balk.html gaf "deze bladzij kan de taalstukken niet dragen"
    # op elke bladzij.
    negeer_regexen()
    gaten, n = [], 0
    for p in tabel:
        if p["wissel"] not in ("los", "los-eigen"):
            continue
        for kant in ("nl", "en"):
            pad = os.path.join(REPO, p[kant])
            if not os.path.isfile(pad):
                gaten.append(f"{p[kant]}: bestaat niet")
                continue
            n += 1
            # Geen plek voor de stukken (geen </head>, geen <body> op een eigen
            # regel, geen UTF-8) is een gat in DEZE bladzij, met naam. Tot
            # 21-11-2026 werd het een traceback die de rest van de lijst niet meer
            # liet zien. (UnicodeDecodeError is een ValueError.)
            try:
                oud = lees(pad)
                nieuw = pas_toe_los(oud, p[kant])
            except ValueError as e:
                reden = str(e) if str(e).startswith(p[kant]) else f"{p[kant]}: {e}"
                gaten.append(f"{reden} — deze bladzij kan de taalstukken niet dragen")
                continue
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
    n_q, gaten_q = quarto_tweelingen(tabel)
    print(f"  tweelingen die Quarto bouwt (auto, eigen): {n_q} kant(en) nagelopen, {len(gaten_q)} die er niet staan")
    for g in gaten_q:
        print("    - " + g)
    gaten += gaten_q
    # Ook bij `los` zonder --controleer alleen gemeld, nooit weggehaald: zonder paar
    # weet niemand of de tabel of de bladzij achterloopt. Weghalen is `ruim`.
    n_buiten, wees, blind = wezen(tabel)
    print(f"  buiten de tabel: {n_buiten} .html nagelopen, {len(wees)} met een taalstuk")
    for w in wees:
        print("    - " + w)
    gaten += wees
    if gaten:
        return 1
    if blind:
        for b in blind:
            print(f"  NIET te lezen: {b}")
        print("  buiten de tabel: NIET volledig nagelopen — een map was niet te lezen")
        return 3
    if n == 0:
        # Niets nagelopen is niet "in orde". Het is ook geen kale bladzij, dus geen 1.
        print("  (geen enkele los- of los-eigen-regel in taalparen.tsv — niets om naar te kijken)")
        return 3
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("regels")
    lo = sub.add_parser("los")
    lo.add_argument("--controleer", action="store_true")
    ru = sub.add_parser("ruim", help="haal de taalstukken uit een wees (een bladzij die niet in de tabel staat)")
    ru.add_argument("pad", nargs="+", help="sitepad, bv. oefenboeken/ts/06_oud/06_oud.html")
    a = ap.parse_args()
    # Een fout die niemand voorzag, eindigt in Python op afloop 1, en 1 betekent
    # hier "er is een gat in een bladzij". Dan stuurt naar_buiten.sh je naar de
    # bladzijden met een herstel dat op dezelfde fout vastloopt (gemeten 21-11-2026,
    # spoor taalpers: een ontbrekend _tools/taalwissel/stijl_knop_los.html gaf
    # "mist zijn taalknopje"). Dus: niet gekeken, met de fout erbij.
    try:
        return {"regels": cmd_regels, "los": cmd_los, "ruim": cmd_ruim}[a.cmd](a)
    except Exception as e:  # noqa: BLE001
        print(f"  taalonderdelen.py liep vast: {type(e).__name__}: {e}")
        print("  NIET nagelopen — dit zegt niets over de bladzijden")
        return 3


if __name__ == "__main__":
    sys.exit(main())
