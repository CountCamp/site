#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""taallabel_test.py — bijt het EN-label van _tools/taallabel.py waar het moet?

    python3 _tools/tests/taallabel_test.py

Elk geval draait het echte script, als losse aanroep, op een kladsite in een
tijdelijke map: een plank in de vorm die Quarto 1.9.38 bouwt (gemeten
23-11-2026 op _site/oefenboeken/index.html), met of zonder Engelse bladzij
ernaast, en met de echte taalparen.tsv of een kopie met een paar erbij.

WAT HET EIST
  echte tabel       Toetsende Statistiek krijgt één label, naar
                    ../en/workbooks/inferential-statistics/index.html; de rest niet
  geen tweeling     MVDA en Psychometrie (geen paar) krijgen niets
  paar erbij        een kopie van de tabel met een paar voor MVDA, en de Engelse
                    bladzij in de kladsite: MVDA krijgt het label
  buiten de map     een paar voor de handleiding (../manuscript/...): het pad klopt
  paar zonder bladzij  hetzelfde paar, maar de Engelse bladzij staat er niet:
                    geen label, afloop 0, en een LET OP-regel die het paar noemt
  paar weer weg     daarna weer met de echte tabel: het label gaat er ook weer af
  idempotent        een tweede run verandert geen byte
  boek zonder link  STAT 3 krijgt nooit een label
  vorm onbekend     een plank waarin geen enkel boek te herkennen is: afloop 3
  niet in de bouw   geen plank in de uitvoermap (de Engelse ronde): afloop 0, gezegd
  tabel onleesbaar  afloop 3

Daarna de MUTATIEPROEF: dezelfde gevallen tegen vier kreupele kopieën van het
script. Elke kopie moet minstens één geval laten zakken; zakt er geen, dan
bewaakt deze toets dat stuk niet.

Afloop: 0 alles goed, 1 minstens één geval of mutatie zakt.
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
TOETS = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(TOETS)
TABEL = os.path.join(TOOLS, "taalparen.tsv")

TS_EN = "en/workbooks/inferential-statistics/index.html"
MVDA_EN = "en/workbooks/mvda/index.html"
HL_EN = "en/handbook/index.html"

# De vorm van Quarto 1.9.38: elk boek een <section class="level3 cc-boek …">, de kop op één regel.
PLANK = """<main>
<section id="toetsende-statistiek-r-nieuw" class="level3 cc-boek cc-boek-vak">
<h3 class="anchored" data-anchor-id="toetsende-statistiek-r-nieuw"><a href="ts/index.html">Toetsende Statistiek →</a> <span class="cc-chip">R</span> <span class="cc-chip cc-chip-nieuw">nieuw</span></h3>
<p>Een eerstejaarsvak.</p>
</section>
<section id="psychometrie-r-nieuw" class="level3 cc-boek cc-boek-vak">
<h3 class="anchored" data-anchor-id="psychometrie-r-nieuw"><a href="psychometrie/index.html">Psychometrie →</a> <span class="cc-chip">R</span> <span class="cc-chip cc-chip-nieuw">nieuw</span></h3>
</section>
<section id="mvda-multivariate-data-analyse-r" class="level3 cc-boek cc-boek-vak">
<h3 class="anchored" data-anchor-id="mvda-multivariate-data-analyse-r"><a href="mvda/index.html">MVDA — Multivariate Data-analyse →</a> <span class="cc-chip">R</span></h3>
</section>
<section id="stat-3-in-opbouw" class="level3 cc-boek cc-boek-vak cc-boek-straks">
<h3 class="anchored" data-anchor-id="stat-3-in-opbouw">STAT 3 <span class="cc-chip cc-chip-straks">in opbouw</span></h3>
</section>
<section id="handleiding-statistiek-met-jasp-jasp" class="level3 cc-boek">
<h3 class="anchored" data-anchor-id="handleiding-statistiek-met-jasp-jasp"><a href="../manuscript/handleiding/index.html">Handleiding Statistiek met JASP →</a> <span class="cc-chip">JASP</span></h3>
</section>
</main>
"""

LABEL = re.compile(r'<a class="cc-taal" href="([^"]+)" hreflang="en" lang="en" title="[^"]+">EN →</a>')


def kop_van(html: str, href: str) -> str:
    m = re.search(r'<h3[^>]*><a href="' + re.escape(href) + r'">.*?</h3>', html)
    return m.group(0) if m else ""


def labels_in(html: str, href: str) -> list[str]:
    return LABEL.findall(kop_van(html, href))


class Klad:
    """Een kladsite en een kladtabel in een tijdelijke map."""

    def __init__(self, tools: str):
        self.tools = tools
        self.map = tempfile.mkdtemp(prefix="taallabel_")
        self.site = os.path.join(self.map, "_site")
        os.makedirs(os.path.join(self.site, "oefenboeken"))
        self.plank = os.path.join(self.site, "oefenboeken", "index.html")
        self.schrijf_plank(PLANK)
        self.bladzij(TS_EN)

    def schrijf_plank(self, t: str):
        with open(self.plank, "w", encoding="utf-8") as f:
            f.write(t)

    def lees_plank(self) -> str:
        with open(self.plank, encoding="utf-8") as f:
            return f.read()

    def bladzij(self, sitepad: str):
        p = os.path.join(self.site, sitepad)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8") as f:
            f.write("<html></html>\n")

    def tabel_met(self, *regels: str) -> str:
        p = os.path.join(self.map, "taalparen.tsv")
        with open(TABEL, encoding="utf-8") as f:
            t = f.read()
        with open(p, "w", encoding="utf-8") as f:
            f.write(t.rstrip("\n") + "\n" + "".join(r + "\n" for r in regels))
        return p

    def draai(self, paren: str = TABEL, site: str | None = None):
        r = subprocess.run([sys.executable, os.path.join(self.tools, "taallabel.py"),
                            "--site", site or self.site, "--paren", paren],
                           capture_output=True, text=True, env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"})
        return r.returncode, r.stdout + r.stderr

    def weg(self):
        shutil.rmtree(self.map, ignore_errors=True)


def gevallen(tools: str) -> list[tuple[str, bool, str]]:
    """[(naam, goed, toelichting)]"""
    uit = []

    def eis(naam, goed, uitleg):
        uit.append((naam, bool(goed), uitleg))

    k = Klad(tools)
    try:
        code, log = k.draai()
        p = k.lees_plank()
        ts = labels_in(p, "ts/index.html")
        eis("echte tabel", code == 0 and ts == ["../" + TS_EN] and len(LABEL.findall(p)) == 1,
            f"afloop {code}, TS: {ts}, labels op de plank: {len(LABEL.findall(p))} (verwacht 1)")
        eis("geen tweeling", not labels_in(p, "mvda/index.html") and not labels_in(p, "psychometrie/index.html"),
            "MVDA en Psychometrie hebben geen paar in de tabel, dus geen label")
        eis("label achteraan", kop_van(p, "ts/index.html").endswith(
            '<span class="cc-chip cc-chip-nieuw">nieuw</span> <a class="cc-taal" href="../' + TS_EN
            + '" hreflang="en" lang="en" title="The English edition of this book">EN →</a></h3>'),
            "het label staat als laatste in de kop, na de pillen, met één spatie ervoor")

        eerst = p
        k.draai()
        eis("idempotent", k.lees_plank() == eerst, "een tweede run verandert geen byte")

        paar = k.tabel_met(f"oefenboeken/mvda/index.html\t{MVDA_EN}\tlos",
                           f"manuscript/handleiding/index.html\t{HL_EN}\tlos")
        code, log = k.draai(paren=paar)
        p = k.lees_plank()
        eis("paar zonder bladzij", code == 0 and not labels_in(p, "mvda/index.html")
            and f"LET OP oefenboeken/mvda/index.html -> {MVDA_EN}" in log,
            f"afloop {code}; geen label voor MVDA, en de LET OP-regel noemt het paar"
            + ("" if "LET OP" in log else f" -- uitvoer: {log.strip()[:200]}"))

        k.bladzij(MVDA_EN)
        k.bladzij(HL_EN)
        code, log = k.draai(paren=paar)
        p = k.lees_plank()
        eis("paar erbij", code == 0 and labels_in(p, "mvda/index.html") == ["../" + MVDA_EN]
            and labels_in(p, "ts/index.html") == ["../" + TS_EN],
            f"afloop {code}; MVDA: {labels_in(p, 'mvda/index.html')}, TS blijft")
        eis("buiten de map", labels_in(p, "../manuscript/handleiding/index.html") == ["../" + HL_EN],
            f"handleiding: {labels_in(p, '../manuscript/handleiding/index.html')}")
        eis("boek zonder link", "cc-taal" not in re.search(r'<h3[^>]*>STAT 3.*?</h3>', p).group(0),
            "STAT 3 heeft geen titellink en dus geen label")

        code, log = k.draai()
        p = k.lees_plank()
        eis("paar weer weg", not labels_in(p, "mvda/index.html") and len(LABEL.findall(p)) == 1,
            f"terug naar de echte tabel: {len(LABEL.findall(p))} label(s), verwacht alleen TS")

        k.schrijf_plank(PLANK.replace("<section", "<div").replace("</section>", "</div>"))
        voor = k.lees_plank()
        code, log = k.draai()
        eis("vorm onbekend", code == 3 and "NIET gekeken" in log and k.lees_plank() == voor,
            f"afloop {code} (verwacht 3), en de plank blijft zoals hij was")

        leeg = os.path.join(k.map, "leeg")
        os.makedirs(leeg)
        code, log = k.draai(site=leeg)
        eis("niet in de bouw", code == 0 and "niet in deze bouw" in log, f"afloop {code}, en het zegt het")

        code, log = k.draai(paren=os.path.join(k.map, "bestaat_niet.tsv"))
        eis("tabel onleesbaar", code == 3 and "NIET gekeken" in log, f"afloop {code} (verwacht 3)")
    finally:
        k.weg()
    return uit


# (naam, wat er kapot gaat, oud, nieuw)
MUTATIES = [
    ("geen bestaanstoets", "een paar naar een bladzij die er niet staat, krijgt toch een label",
     "if not os.path.isfile(os.path.join(site, en)):", "if False:"),
    ("tabel genegeerd", "elk boek met een link krijgt het label van TS",
     "paar = tweeling.get(nl)", 'paar = tweeling.get("oefenboeken/ts/index.html")'),
    ("oude labels blijven", "een tweede run zet er een tweede label bij",
     'tekst = _LABEL.sub("", tekst)', "tekst = tekst"),
    ("blind is groen", "een plank zonder herkende boeken geeft afloop 0",
     'if t["boeken"] == 0:', "if False:"),
]


def main() -> int:
    zak = 0
    for naam, goed, uitleg in gevallen(TOOLS):
        zak += not goed
        print(f"{'ok  ' if goed else 'ZAKT'}  {naam:<20} {uitleg}")

    print("\nmutatieproef: elke kreupele kopie moet minstens één geval laten zakken")
    for naam, wat, oud, nieuw in MUTATIES:
        kopie = tempfile.mkdtemp(prefix="taallabel_mut_")
        try:
            for f in ("taallabel.py", "taalonderdelen.py"):
                shutil.copy(os.path.join(TOOLS, f), kopie)
            pad = os.path.join(kopie, "taallabel.py")
            with open(pad, encoding="utf-8") as f:
                t = f.read()
            if t.count(oud) != 1:
                zak += 1
                print(f"ZAKT  {naam:<20} de verminking past niet meer op taallabel.py ({t.count(oud)} keer gevonden)"
                      " -- werk MUTATIES bij")
                continue
            with open(pad, "w", encoding="utf-8") as f:
                f.write(t.replace(oud, nieuw))
            gezakt = [g[0] for g in gevallen(kopie) if not g[1]]
            zak += not gezakt
            print(f"{'ok  ' if gezakt else 'ZAKT'}  {naam:<20} {wat} -- "
                  + (f"gevangen door: {', '.join(gezakt)}" if gezakt else "NIET gevangen"))
        finally:
            shutil.rmtree(kopie, ignore_errors=True)

    print(f"\n{zak} zakt")
    return 1 if zak else 0


if __name__ == "__main__":
    sys.exit(main())
