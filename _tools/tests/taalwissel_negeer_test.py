#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""taalwissel_negeer_test.py — laat de uitzondering van de wachtrij het knopje
door, en verder NIETS?

    python3 _tools/tests/taalwissel_negeer_test.py
        bouwt main en HEAD elk in een losse kloon (gewoon `quarto render`, zoals
        de wachtrij en de GitHub Action) en vergelijkt
    python3 _tools/tests/taalwissel_negeer_test.py --voor-site A --na-site B
        vergelijkt twee sites die al gebouwd zijn (sneller, voor tijdens het werk)
    ... --wachtrij <pad/naar/wachtrij.py>
        gebruikt de ECHTE nl_verschil van de wachtrij in plaats van de spiegel
        hieronder (ook via de omgevingsvariabele WACHTRIJ_PY)

WAAROM. De wachtrij (drukkerij/wachtrij/wachtrij.py, nl_controle) weigert een stap
als er één Nederlands bestand in de site-uitvoer verandert. Ben, 24-10-2026: het
knopje NL · EN mag op de Nederlandse bladzijden ("EN die knop, ja graag denk ik?"),
met precies één smalle, getoetste uitzondering: "the switch and the hreflang link.
Anything else changing in a Dutch page's output still stops it." Die uitzondering is
`#: nl_negeer` in wachtrij_en.tsv; de regels rekent _tools/taalonderdelen.py uit.

WAT DIT BEWIJST
  1. zonder uitzondering veranderen precies de Nederlandse tweelingen uit
     taalparen.tsv, en geen enkel ander Nederlands bestand;
  2. met de uitzondering verandert er niets meer;
  3. per tweeling verdwijnt precies wat er hoort (bv. index.html: 3× hreflang,
     het knopje, zijn stijl en de balk), en nergens meer dan de grens van de
     wachtrij (4096 tekens per bladzij);
  4. elke verminking die geen taalknop is, zakt: een woord in de tekst, één teken
     in het script van de balk, het knopje naar een ander domein, tekst erbij in
     het knopje, een script achter de balk, een nieuwe Nederlandse bladzij, ...
  5. het gat dat de wachtrij NIET kan zien (de stukken op een bladzij zonder
     tweeling: die laat ze óók weg) wordt door en_bouw.py keur gevangen.

DE SPIEGEL. Zonder --wachtrij vergelijkt deze toets met een kopie van nl_inhoud en
nl_verschil uit wachtrij.py (regels 712-756 op tak worktree-wachtrij_en, 24-10-2026):
eerst elke regex weg (re.subn, op volgorde), dan byte voor byte. Een kopie kan
uiteenlopen met het origineel; daarom bestaat --wachtrij, en het rapport zegt welke
van de twee er gebruikt is.

Afloop: 0 groen, 1 gezakt, 3 kon niet kijken (geen quarto, bouw liep vast).
"""
from __future__ import annotations

import argparse
import fnmatch
import importlib.util
import os
import re
import shutil
import subprocess
import sys
import tempfile

HIER = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HIER)
REPO = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import taalonderdelen as TO  # noqa: E402

# Zoals wachtrij_en.tsv ze zet (#: engels, #: gedeeld), plus tables/*: de Engelse
# tabellen staan niet onder en/ en heten niet *-en.html. Zonder dat patroon telt
# de wachtrij tables/index.html als NEDERLANDS (zie het rapport van en_schil).
ENGELS = ["en/*", "*/en/*", "*-en.html", "*-en_files/*", "tables/*"]
GEDEELD = ["sitemap.xml", "search.json"]
NEGEER_MAX_TEKENS = 4096        # wachtrij.py, regel 128

goed = gezakt = 0


def zeg(r=""):
    print(r, flush=True)


def ok(wat):
    global goed
    goed += 1
    zeg(f"  ok    {wat}")


def zakt(wat, waarom=""):
    global gezakt
    gezakt += 1
    zeg(f"  ZAKT  {wat}" + (f" — {waarom}" if waarom else ""))


# ---------------------------------------------------------- de spiegel ----
class Stop(Exception):
    pass


def bestanden(map_):
    uit = {}
    for wortel, _, namen in os.walk(map_):
        for n in namen:
            vol = os.path.join(wortel, n)
            uit[os.path.relpath(vol, map_)] = vol
    return uit


def spiegel_nl_verschil(voor, na, instel):
    regexen = [re.compile(r) for r in instel["nl_negeer"]]

    def inhoud(vol, rel, teller):
        with open(vol, "rb") as f:
            b = f.read()
        if not regexen or not rel.endswith(".html"):
            return b
        t = b.decode("utf-8", "replace")
        weg = 0
        for rx in regexen:
            for m in rx.finditer(t):
                weg += len(m.group(0))
            t, n = rx.subn("", t)
            teller[0] += n
        if weg > NEGEER_MAX_TEKENS:
            raise Stop(f"nl_negeer haalt op {rel} {weg} tekens weg (grens {NEGEER_MAX_TEKENS})")
        return t.encode("utf-8")

    a, b = bestanden(voor), bestanden(na)
    uit, teller = [], [0]
    for rel in sorted(set(a) | set(b)):
        if any(fnmatch.fnmatchcase(rel, p) for p in instel["engels"] + instel["gedeeld"]):
            continue
        if rel not in a:
            uit.append((rel, "nieuw"))
        elif rel not in b:
            uit.append((rel, "weg"))
        elif inhoud(a[rel], rel, teller) != inhoud(b[rel], rel, teller):
            uit.append((rel, "anders"))
    return uit, teller[0]


def laad_wachtrij(pad):
    spec = importlib.util.spec_from_file_location("wachtrij_echt", pad)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# ------------------------------------------------------------- bouwen ----
def bouw(commit, doel):
    # Eerst de commit opzoeken in DEZE repo: in een verse kloon is "main" geen
    # lokale tak, en `checkout --detach main` faalt daar (gemeten 24-10-2026).
    r = subprocess.run(["git", "-C", REPO, "rev-parse", "--verify", "--quiet", commit + "^{commit}"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        zeg(f"  {commit} is geen commit in deze repo — kon niet kijken")
        return None
    sha = r.stdout.strip()
    for cmd in (["git", "clone", "--quiet", "--shared", "--no-checkout", REPO, doel],
                ["git", "-C", doel, "checkout", "--quiet", "--detach", sha]):
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            zeg(f"  {' '.join(cmd[:4])} gaf {r.returncode}: {r.stderr.strip()[:200]} — kon niet kijken")
            return None
    zeg(f"  {commit} = {sha[:8]}")
    env = dict(os.environ)
    env.pop("QUARTO_PROFILE", None)
    r = subprocess.run(["quarto", "render"], cwd=doel, capture_output=True, text=True, env=env)
    if r.returncode != 0:
        zeg(f"  de bouw van {commit} liep vast (afloop {r.returncode}):")
        for regel in (r.stderr or r.stdout).splitlines()[-10:]:
            zeg("    " + regel)
        return None
    return os.path.join(doel, "_site")


# ------------------------------------------------------------ de toets ----
def verwacht_per_stuk(soort):
    """Wat er op de NEDERLANDSE kant van een paar bij komt, per stuk."""
    return {
        "auto": {"hreflang": 3, "knop": 1, "stijl_knop": 1, "balk": 1},
        "eigen": {"hreflang": 3, "balk": 1},
        "los": {"hreflang": 3, "knop": 1, "stijl_knop_los": 1, "balk": 1},
        "los-eigen": {"balk": 1},     # hreflang en knopje stonden er al, in de bron
    }[soort]


def tel_stukken(tekst):
    return {naam: len(re.findall(r, tekst)) for naam, r in TO.negeer_regexen()}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--voor", default="main", help="commit van wat er live staat (standaard main)")
    ap.add_argument("--na", default="HEAD", help="commit van wat er live zou komen (standaard HEAD)")
    ap.add_argument("--voor-site")
    ap.add_argument("--na-site")
    ap.add_argument("--wachtrij", default=os.environ.get("WACHTRIJ_PY"))
    a = ap.parse_args()

    werk = tempfile.mkdtemp(prefix="taalwissel_negeer_")
    try:
        if a.voor_site and a.na_site:
            voor, na = os.path.abspath(a.voor_site), os.path.abspath(a.na_site)
            zeg(f"vergelijkt twee gebouwde sites:\n  voor {voor}\n  na   {na}")
        else:
            if shutil.which("quarto") is None:
                zeg("quarto staat niet op het pad — kon niet kijken")
                return 3
            zeg(f"bouwt {a.voor} en {a.na} in losse klonen (gewoon `quarto render`)")
            voor = bouw(a.voor, os.path.join(werk, "voor"))
            na = bouw(a.na, os.path.join(werk, "na"))
            if not voor or not na:
                return 3
        for s in (voor, na):
            if not os.path.isfile(os.path.join(s, "index.html")):
                zeg(f"{s} is geen gebouwde site — kon niet kijken")
                return 3

        if a.wachtrij:
            mod = laad_wachtrij(a.wachtrij)
            nl_verschil, StopKlasse = mod.nl_verschil, mod.Stop
            zeg(f"vergelijker: de ECHTE nl_verschil uit {a.wachtrij}")
        else:
            nl_verschil, StopKlasse = spiegel_nl_verschil, Stop
            zeg("vergelijker: de spiegel van nl_verschil in deze toets (--wachtrij voor de echte)")
        regels = [r for _n, r in TO.negeer_regexen()]
        met = {"engels": ENGELS, "gedeeld": GEDEELD, "nl_negeer": regels}
        zonder = dict(met, nl_negeer=[])
        tabel = TO.paren()
        tweelingen = sorted(p["nl"] for p in tabel)
        zeg(f"{len(regels)} nl_negeer-regels, {len(tweelingen)} Nederlandse tweelingen in taalparen.tsv, "
            f"{len(bestanden(voor))} bestanden voor, {len(bestanden(na))} na")
        zeg()

        # 1. zonder uitzondering: precies de tweelingen
        v0, _ = nl_verschil(voor, na, zonder)
        anders0 = sorted(r for r, s in v0)
        if anders0 == tweelingen and all(s == "anders" for _r, s in v0):
            ok(f"zonder uitzondering veranderen precies de {len(tweelingen)} Nederlandse tweelingen, bv. {tweelingen[0]}")
        else:
            zakt("zonder uitzondering hoort precies de lijst tweelingen te veranderen",
                 f"veranderd: {v0[:8]}; verwacht: {tweelingen}")

        # 2. met uitzondering: niets
        try:
            v1, n1 = nl_verschil(voor, na, met)
            if not v1:
                ok(f"met de uitzondering verandert er geen Nederlands bestand meer ({n1} keer iets weggelaten)")
            else:
                zakt("met de uitzondering blijft er Nederlands verschil over", str(v1[:8]))
        except StopKlasse as e:
            zakt("de wachtrij stopte op de grens", str(e))

        # 3. per tweeling: precies de verwachte stukken, en onder de grens
        grootst = (0, "")
        for p in tabel:
            t_na = open(os.path.join(na, p["nl"]), encoding="utf-8").read()
            t_voor = open(os.path.join(voor, p["nl"]), encoding="utf-8").read()
            c_na, c_voor = tel_stukken(t_na), tel_stukken(t_voor)
            erbij = {k: c_na[k] - c_voor[k] for k in c_na if c_na[k] - c_voor[k]}
            weg = sum(len(m.group(0)) for _n, r in TO.negeer_regexen() for m in re.finditer(r, t_na))
            grootst = max(grootst, (weg, p["nl"]))
            if erbij == verwacht_per_stuk(p["wissel"]):
                ok(f"{p['nl']} ({p['wissel']}): erbij {erbij}, {weg} tekens weg te laten")
            else:
                zakt(f"{p['nl']} ({p['wissel']})", f"erbij {erbij}, verwacht {verwacht_per_stuk(p['wissel'])}")
        if grootst[0] <= NEGEER_MAX_TEKENS:
            ok(f"grootste weglating {grootst[0]} tekens ({grootst[1]}), onder de grens van {NEGEER_MAX_TEKENS}")
        else:
            zakt("weglating boven de grens van de wachtrij", f"{grootst[0]} tekens op {grootst[1]}")

        # 4. verminkingen: elk moet de wachtrij laten stoppen
        zeg()
        zeg("verminkingen — elk hoort de wachtrij te laten stoppen:")
        kopie = os.path.join(werk, "verminkt")

        def verminkt(naam, pad, functie, nieuw=False):
            if os.path.exists(kopie):
                shutil.rmtree(kopie)
            shutil.copytree(na, kopie)
            doel = os.path.join(kopie, pad)
            if nieuw:
                with open(doel, "w", encoding="utf-8") as f:
                    f.write(functie(""))
            else:
                t = open(doel, encoding="utf-8").read()
                t2 = functie(t)
                if t2 == t:
                    zakt(naam, "de verminking veranderde niets — de toets is stuk, niet de wachtrij")
                    return
                with open(doel, "w", encoding="utf-8") as f:
                    f.write(t2)
            try:
                v, _n = nl_verschil(voor, kopie, met)
            except StopKlasse as e:
                ok(f"{naam}: de wachtrij stopt ({str(e)[:90]})")
                return
            if v:
                ok(f"{naam}: de wachtrij stopt ({v[0][1]}: {v[0][0]})")
            else:
                zakt(naam, "de uitzondering liet het door")

        def eerste(oud, nieuw):
            return lambda t: t.replace(oud, nieuw, 1)

        verminkt("een woord in de tekst van diensten.html", "diensten.html",
                 lambda t: re.sub(r"(<p>[^<]{3,}?)\b(\w{4,})\b", r"\1XXXX", t, count=1))
        verminkt("één teken in het script van de balk (index.html)", "index.html",
                 eerste('=== "weg"', '=== "wag"'))
        verminkt("een kleur in de stijl van de balk (over.html)", "over.html",
                 eerste("background:#dfebf2", "background:#ffffff"))
        verminkt("het knopje naar een ander domein (gebruik.html)", "gebruik.html",
                 eerste('<a href="en/use.html" hreflang="en"', '<a href="https://example.com/x.html" hreflang="en"'))
        verminkt("tekst erbij in het knopje (diensten.html)", "diensten.html",
                 eerste('title="This page in English">EN</a></nav>',
                        'title="This page in English">EN</a> · Koop nu</nav>'))
        verminkt("een hreflang naar een ander domein (cv.html)", "cv.html",
                 eerste('hreflang="en" href="https://countcamp.org/cv-en.html"', 'hreflang="en" href="https://example.com/cv-en.html"'))
        verminkt("een script direct achter de balk (tabellen/index.html)", "tabellen/index.html",
                 eerste("})();\n</script>\n", "})();\n</script>\n<script>document.title='x'</script>\n"))
        verminkt("de balk drie keer op één bladzij (index.html)", "index.html",
                 lambda t: t.replace(TO.stuk("balk.html") + "\n", (TO.stuk("balk.html") + "\n") * 3, 1))
        verminkt("de stijl van het knopje anders (index.html)", "index.html",
                 eerste("color:#6c757d;}", "color:#6c757d;display:none}"))
        verminkt("een nieuwe Nederlandse bladzij", "nieuw-nl.html",
                 lambda _t: "<!DOCTYPE html><html lang=\"nl\"><body>nieuw</body></html>\n", nieuw=True)

        # 5. het gat dat de wachtrij niet kan zien: de stukken op een bladzij zonder
        #    tweeling. De wachtrij laat ze daar óók weg; en_bouw.py keur moet hem vangen.
        zeg()
        zeg("wat de wachtrij niet kan zien, en en_bouw.py keur wel:")
        if os.path.exists(kopie):
            shutil.rmtree(kopie)
        shutil.copytree(na, kopie)
        # Tot 25-10-2026 speeltjes/index.html; die heeft sindsdien een Engelse tweeling
        # (en/toys/index.html, spoor en_speeltjes). Daarna archief/index.html, en die kreeg
        # dezelfde dag ook een tweeling (en/archive/, spoor en_voorpagina). De woordenbladzij
        # van het boek heeft er geen, en het Engelse boek heeft geen eigen inhoudsopgave of
        # woordenlijst om er een te worden.
        zonder_tweeling = "manuscript/woorden.html"
        pad = os.path.join(kopie, zonder_tweeling)
        t = open(pad, encoding="utf-8").read()
        with open(pad, "w", encoding="utf-8") as f:
            f.write(t.replace("</head>", TO.stuk("balk.html") + "\n</head>", 1))
        v, _n = nl_verschil(voor, kopie, met)
        if not v:
            ok(f"de balk op {zonder_tweeling} (geen tweeling): de wachtrij ziet het NIET — zoals verwacht")
        else:
            zakt("de wachtrij hoort de balk op elke Nederlandse bladzij weg te laten", str(v[:3]))
        r = subprocess.run([sys.executable, os.path.join(TOOLS, "en_bouw.py"), "keur", "--site", kopie, "--soort", "echt"],
                           capture_output=True, text=True)
        regel = next((x.strip() for x in r.stdout.splitlines() if zonder_tweeling in x and "taalbalk" in x), "")
        if r.returncode == 1 and regel:
            ok(f"en_bouw.py keur vangt hem: {regel}")
        else:
            zakt("en_bouw.py keur hoort de balk op een bladzij zonder tweeling te vangen",
                 f"afloop {r.returncode}; " + " | ".join(r.stdout.splitlines()[-6:]))
    finally:
        shutil.rmtree(werk, ignore_errors=True)

    zeg()
    zeg(f"{goed + gezakt} zaken getoetst, " + ("alles groen." if not gezakt else f"{gezakt} GEZAKT."))
    return 1 if gezakt else 0


if __name__ == "__main__":
    sys.exit(main())
