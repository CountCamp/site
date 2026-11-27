#!/usr/bin/env python3
"""variabelenwacht.py — draagt elke gebouwde Engelse bladzij de waarden die nu in
_variables.yml staan?

    python3 _tools/variabelenwacht.py               de repo waarin dit script staat
    python3 _tools/variabelenwacht.py --wortel <map> een andere map (voor de toets)

WAAROM (27-11-2026, spoor site_steun). _variables.yml houdt waarden die op meer
dan één bladzij staan op één plek: de betaallink van Stripe en het KvK-nummer op
steun.qmd en en/support.qmd. Een .qmd leest zo'n waarde met {{< var steun.stripe >}}.
Maar de twee talen worden niet op dezelfde manier gebouwd. De Nederlandse
bladzijden bouwt de Action vers, bij elke push, dus die lezen altijd de waarde
van nu. De Engelse bladzijden staan GEBOUWD in de repo (en/*.html, neergezet door
_tools/publiceer_en.sh) en gaan als bijlage onveranderd mee. Wie de Stripe-link
invult en publiceer_en.sh vergeet, levert dus een echte knop in het Nederlands en
een dode in het Engels -- en tot vandaag zag geen enkele poort dat: naar_buiten.sh
--productie en publish.yml draaien de Engelse keuring (en_bouw.py keur) niet, en
de melding "ACHTER OP ZIJN BRON" van publiceer_en.sh kijkt niet naar _variables.yml
(en draait alleen als iemand publiceer_en.sh al draait).

WAT HIJ DOET. Voor elke en/**/*.qmd: elke {{< var sleutel >}} erin opzoeken in
_variables.yml, en eisen dat de gebouwde en/**/*.html ernaast die waarde minstens
zo vaak draagt als de .qmd hem vraagt. Zo valt een verouderde bladzij op: na een
nieuwe waarde draagt hij de nieuwe nul keer. Geen bouw nodig; hij leest de repo.
De Nederlandse kant kijkt hij niet na: die wordt bij elke levering vers gebouwd.

DE YAML. Er staat hier geen PyYAML (gemeten 27-11-2026 op broodje: ModuleNotFoundError),
en de Action installeert hem niet. Deze wachter leest dus zelf, en ALLEEN de vorm
die _variables.yml nu heeft: geneste sleutels met twee spaties inspringing en een
waarde tussen dubbele aanhalingstekens, plus commentaar en lege regels. Al het
andere (een lijst, een waarde zonder aanhalingstekens, een waarde over meer
regels) is voor hem onleesbaar, en dan zegt hij dat (afloop 3) in plaats van
het te raden.

AFLOOP (huisafspraak): 0 schoon · 1 een bladzij draagt een waarde niet (of de
sleutel bestaat niet, of de gebouwde bladzij ontbreekt) · 3 kon niet kijken
(geen en/-map, _variables.yml onleesbaar of weg terwijl een bladzij hem vraagt).

WAT DIT NIET DEKT. Een waarde die toevallig ook elders op de bladzij staat, telt
mee; daarom telt hij en kijkt hij niet alleen of hij er is. Een losse Engelse
bladzij die niet uit een .qmd komt (het boek, de oefenboeken, de speeltjes) leest
geen _variables.yml en kijkt hij niet na. En of de waarde zelf klopt (bestaat die
Stripe-link?) weet hij niet.
Getoetst door _tools/tests/variabelenwacht_test.sh.
"""
from __future__ import annotations

import argparse
import html
import os
import re
import sys

VAR = re.compile(r"\{\{<\s*var\s+([A-Za-z0-9_.-]+)\s*>\}\}")
# Wat Quarto schrijft als hij een sleutel niet vindt (gemeten op 1.9.38: "?var:sleutel").
ONBEKEND = re.compile(r"\?var:[A-Za-z0-9_.-]+")


class Onleesbaar(Exception):
    pass


def lees_variabelen(pad: str) -> dict[str, str]:
    """Geneste `sleutel:` / `sleutel: "waarde"` met twee spaties per niveau -> {"a.b": "waarde"}."""
    uit: dict[str, str] = {}
    pad_nu: list[str] = []
    for nr, regel in enumerate(open(pad, encoding="utf-8"), 1):
        kaal = regel.rstrip("\n")
        if not kaal.strip() or kaal.lstrip().startswith("#"):
            continue
        inspring = len(kaal) - len(kaal.lstrip(" "))
        if "\t" in kaal[:inspring + 1] or inspring % 2:
            raise Onleesbaar(f"regel {nr}: inspringing van {inspring} spatie(s) of een tab")
        niveau = inspring // 2
        if niveau > len(pad_nu):
            raise Onleesbaar(f"regel {nr}: springt dieper in dan de sleutel erboven")
        m = re.fullmatch(r'([A-Za-z0-9_-]+):(?:\s+"((?:[^"\\]|\\.)*)")?\s*(?:#.*)?', kaal.strip())
        if not m:
            raise Onleesbaar(f"regel {nr}: geen 'sleutel:' of 'sleutel: \"waarde\"': {kaal.strip()[:60]!r}")
        pad_nu = pad_nu[:niveau] + [m.group(1)]
        if m.group(2) is not None:
            uit[".".join(pad_nu)] = m.group(2).replace('\\"', '"').replace("\\\\", "\\")
    return uit


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--wortel", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    a = ap.parse_args()
    wortel = os.path.abspath(a.wortel)
    en = os.path.join(wortel, "en")
    print(f"variabelenwacht: gebouwde Engelse bladzijden tegen _variables.yml ({wortel})")
    if not os.path.isdir(en):
        print("  KON NIET KIJKEN: geen map en/")
        return 3

    bronnen = sorted(os.path.join(dp, f) for dp, _d, fs in os.walk(en) for f in fs if f.endswith(".qmd"))
    vragen = {}
    for q in bronnen:
        sleutels = VAR.findall(open(q, encoding="utf-8").read())
        if sleutels:
            vragen[q] = sleutels
    n_var = sum(len(s) for s in vragen.values())
    print(f"  {len(bronnen)} Engelse bron(nen) gelezen, {len(vragen)} met een {{{{< var >}}}}, samen {n_var} keer")
    if not vragen:
        print("  niets na te kijken: geen enkele Engelse bron vraagt een waarde uit _variables.yml")
        return 0

    vpad = os.path.join(wortel, "_variables.yml")
    try:
        waarden = lees_variabelen(vpad)
    except FileNotFoundError:
        print(f"  KON NIET KIJKEN: {len(vragen)} bron(nen) vragen een waarde, maar _variables.yml bestaat niet")
        return 3
    except Onleesbaar as e:
        print(f"  KON NIET KIJKEN: _variables.yml is in een vorm die deze wachter niet leest -- {e}")
        print("  (zie de kop van _tools/variabelenwacht.py: alleen geneste sleutels met \"waarde\")")
        return 3
    print(f"  _variables.yml: {len(waarden)} waarde(n) -- bv. {next(iter(waarden), '(geen)')}")

    gaten, n_ok, voorbeeld = [], 0, None
    for q, sleutels in vragen.items():
        rel = os.path.relpath(q, wortel)
        h = q[:-4] + ".html"
        hrel = os.path.relpath(h, wortel)
        if not os.path.isfile(h):
            gaten.append(f"{hrel}: bestaat niet, maar {rel} vraagt {len(sleutels)} waarde(n) -- bash _tools/publiceer_en.sh")
            continue
        t = open(h, encoding="utf-8").read()
        for m in ONBEKEND.findall(t):
            gaten.append(f"{hrel}: Quarto vond de sleutel niet en schreef {m!r}")
        for s in sorted(set(sleutels)):
            if s not in waarden:
                gaten.append(f"{rel}: vraagt {s}, maar die sleutel staat niet in _variables.yml")
                continue
            w = waarden[s]
            nodig = sleutels.count(s)
            # Zoals hij in de HTML staat: in tekst met &amp; en &lt;, in een attribuut ook &quot;.
            vormen = {w, html.escape(w, quote=False), html.escape(w, quote=True)}
            heeft = max(t.count(v) for v in vormen)
            if heeft < nodig:
                gaten.append(f"{hrel}: draagt {s} = {w!r} {heeft} keer, {rel} vraagt hem {nodig} keer "
                             f"-- de bladzij is ouder dan _variables.yml; bash _tools/publiceer_en.sh")
            else:
                n_ok += 1
                voorbeeld = voorbeeld or f"{hrel} draagt {s} = {w!r} {heeft} keer"
    print(f"  {n_ok} sleutel(s) per bladzij in orde" + (f" -- bv. {voorbeeld}" if voorbeeld else "")
          + f", {len(gaten)} gat(en)")
    for g in gaten:
        print("    - " + g)
    return 1 if gaten else 0


if __name__ == "__main__":
    sys.exit(main())
