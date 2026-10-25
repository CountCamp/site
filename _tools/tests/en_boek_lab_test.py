#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""en_boek_lab_test.py — herkent de keuring een boekbladzij uit het lab, en alleen die?

    python3 _tools/tests/en_boek_lab_test.py               A, B en C
    python3 _tools/tests/en_boek_lab_test.py A B           alleen deze delen

WAAROM (spoor en_boekpers, 25-10-2026). De Engelse boekbladzijden komen kant-en-klaar
uit het lab (countcamp_lab/boek/publiceer.sh --en) en staan onder en/book/ zonder bron
in deze repo. en_bouw.py laat ze door als bijlage — geen wees, en in de spooksite
gekeurd als de echte site — op grond van één ding: de stempel die de lab-pers als
laatste regel zet. Een uitzondering die op een stempel rust, is zo sterk als de
toets op die stempel. Deze toets eist dat een goede stempel doorkomt en dat elke
halve, verschoven of vreemde stempel een GAT is, met de goede reden.

DRIE DELEN
  A. uit_het_lab() op losse teksten — geen bouw nodig. Goede stempels (H0, H12,
     dankwoord, twee stempels zoals lever.sh ze kan stapelen) komen door; een korte
     hash, 63 of 65 tekens, hoofdletters, geen tijd, een stempel vóór </html>, rommel
     erachter, de stempel van een ander hoofdstuk, een stempel buiten en/book/:
     allemaal een gat.
  B. de regel in _tools/taalparen.tsv (manuscript/h<n>.html ↔ en/book/h<n>.html) op
     een nep-repo: alleen bestaande Engelse hoofdstukken, op getal gesorteerd, geen
     h5.html.bak; een regel met auto, met <n> twee keer of in de map: geweigerd; een
     bladzij in twee paren: geweigerd. En op de ECHTE manuscript/h0.html: de stukken
     die taalonderdelen.py erin zet, zijn precies wat de wachtrij weglaat (nl_negeer)
     — erin en weer eruit geeft byte voor byte het origineel.
  C. en_bouw.py keur op de gebouwde site (_site en _site_spook, zoals
     publiceer_en.sh ze achterlaat) met een échte bladzij uit het lab erin: groen
     zoals hij is, en rood — met de goede reden — bij een losse Quarto-bladzij zonder
     stempel onder en/book/ (die blijft een wees), een korte of verkeerde stempel, of
     een lab-bladzij die in de spooksite noindex draagt of zijn teller mist.
     Zonder zo'n gebouwde site kan C niet kijken, en dan zegt hij dat (afloop 3).

DE MUTATIEPROEF. PROEF_MUTATIE="bestand|||oud|||nieuw" verandert vóór de toets één
stuk tekst in _tools/en_bouw.py of _tools/taalonderdelen.py — in het geheugen, het
bestand blijft heel. Staat `oud` er niet precies één keer in, dan is dat afloop 2.
Zie en_boek_lab_mutatieproef.sh.

Afloop: 0 alles goed · 1 minstens één fout · 2 de mutatie sloeg niet aan · 3 kon niet kijken.
"""
from __future__ import annotations

import argparse
import contextlib
import hashlib
import io
import os
import re
import shutil
import sys
import tempfile
import types

HIER = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HIER)
REPO = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)


def lees(p: str) -> str:
    with open(p, encoding="utf-8") as f:
        return f.read()


# --------------------------------------------- de modules, eventueel gemuteerd ----
def mutatie() -> tuple[str, str, str] | None:
    m = os.environ.get("PROEF_MUTATIE")
    if not m:
        return None
    delen = m.split("|||")
    if len(delen) != 3:
        print(f"MUTATIE sloeg niet aan: PROEF_MUTATIE heeft niet de vorm bestand|||oud|||nieuw: {m[:80]!r}")
        sys.exit(2)
    return delen[0], delen[1], delen[2]


def laad(naam: str, rel: str, mut) -> types.ModuleType:
    pad = os.path.join(REPO, rel)
    tekst = lees(pad)
    if mut and mut[0] == rel:
        n = tekst.count(mut[1])
        if n != 1:
            print(f"MUTATIE sloeg niet aan: {mut[1]!r} staat {n} keer in {rel} (moet 1)")
            sys.exit(2)
        tekst = tekst.replace(mut[1], mut[2])
        print(f"MUTATIE in {rel}: {mut[1].strip()[:70]!r} -> {mut[2].strip()[:70]!r}")
    mod = types.ModuleType(naam)
    mod.__file__ = pad
    sys.modules[naam] = mod
    exec(compile(tekst, pad, "exec"), mod.__dict__)
    return mod


MUT = mutatie()
if MUT and MUT[0] not in ("_tools/en_bouw.py", "_tools/taalonderdelen.py"):
    print(f"MUTATIE sloeg niet aan: deze toets muteert alleen en_bouw.py en taalonderdelen.py, niet {MUT[0]}")
    sys.exit(2)
TO = laad("taalonderdelen", "_tools/taalonderdelen.py", MUT)
EB = laad("en_bouw", "_tools/en_bouw.py", MUT)

goed = fout = 0


def uitslag(ok: bool, wat: str, waarom: str = "") -> None:
    global goed, fout
    if ok:
        goed += 1
        print(f"ok    {wat}")
    else:
        fout += 1
        print(f"FOUT  {wat}" + (f" — {waarom}" if waarom else ""))


# ------------------------------------------------------------------ deel A ----
HASH = hashlib.sha256(b"countcamp").hexdigest()
KOP = ('<!DOCTYPE html>\n<html lang="en-GB"><head>\n<meta name="generator" content="quarto-1.9.38">\n'
       '<title>t</title>\n</head>\n<body>\n<p>tekst</p>\n</body></html>\n')


def stempel(naam: str = "H0", h: str = HASH, t: str = "geleverd=2026-10-25T05:12:00") -> str:
    """Precies wat pub_stempel_zet in het lab schrijft: printf '\\n<!-- %s %s bron-hash=%s geleverd=%s -->\\n'."""
    return f"\n<!-- countcamp-publicatie {naam} bron-hash={h} {t} -->\n"


def deel_a() -> None:
    print("\nA. uit_het_lab() op losse teksten")
    # (wat, sitepad, tekst, verwacht): True = bijlage uit het lab, "" = gewone bladzij,
    # anders een stukje van de reden die er moet staan.
    gevallen = [
        ("een goede stempel op h0", "en/book/h0.html", KOP + stempel(), True),
        ("H12 op h12", "en/book/h12.html", KOP + stempel("H12"), True),
        ("een losse bladzij (dankwoord)", "en/book/dankwoord.html", KOP + stempel("dankwoord"), True),
        ("twee stempels, zoals lever.sh er een bij kan zetten", "en/book/h0.html",
         KOP + stempel(h="0" * 64) + stempel(), True),
        ("geen stempel: een gewone bladzij", "en/book/h0.html", KOP, ""),
        ("korte hash (7 tekens)", "en/book/h0.html", KOP + stempel(h=HASH[:7]), "vorm van de pers"),
        ("63 hextekens", "en/book/h0.html", KOP + stempel(h=HASH[:63]), "vorm van de pers"),
        ("65 hextekens", "en/book/h0.html", KOP + stempel(h=HASH + "a"), "vorm van de pers"),
        ("hoofdletters in de hash", "en/book/h0.html", KOP + stempel(h=HASH.upper()), "vorm van de pers"),
        ("geen tijd", "en/book/h0.html", KOP + stempel(t=""), "vorm van de pers"),
        ("een halve tijd", "en/book/h0.html", KOP + stempel(t="geleverd=2026-10-25"), "vorm van de pers"),
        ("rommel na de stempel", "en/book/h0.html", KOP + stempel() + "<script>iets()</script>\n",
         "vorm van de pers"),
        ("de stempel vóór </html> in plaats van erna", "en/book/h0.html",
         KOP.replace("</body>", stempel() + "</body>"), "na de laatste </html>"),
        ("een goede stempel erna, en nog een in de tekst", "en/book/h0.html",
         KOP.replace("<p>tekst</p>", "<p>tekst</p>" + stempel()) + stempel(), "na de laatste </html>"),
        ("geen </html> in de bladzij", "en/book/h0.html", KOP.replace("</html>", "") + stempel(),
         "na de laatste </html>"),
        ("de stempel van H3 op h0", "en/book/h0.html", KOP + stempel("H3"), "hoort bij en/book/h3.html"),
        ("H00 op h0", "en/book/h0.html", KOP + stempel("H00"), "hoort bij"),
        ("een goede stempel, maar direct onder en/", "en/h0.html", KOP + stempel(), "niet direct onder en/book/"),
        ("een goede stempel, maar in een submap van en/book/", "en/book/oud/h0.html", KOP + stempel(),
         "niet direct onder en/book/"),
    ]
    for wat, p, tekst, verwacht in gevallen:
        ja, reden = EB.uit_het_lab(p, tekst)
        if verwacht is True:
            uitslag(ja and not reden, wat, f"kreeg ({ja}, {reden!r})")
        elif verwacht == "":
            uitslag(not ja and not reden, wat, f"kreeg ({ja}, {reden!r})")
        else:
            uitslag(not ja and verwacht in reden, wat, f"kreeg ({ja}, {reden!r}), verwacht een reden met {verwacht!r}")


# ------------------------------------------------------------------ deel B ----
@contextlib.contextmanager
def nep_repo(tabel: str, bestanden: list[str]):
    """Een nep-repo met deze en/book-bestanden en deze taalparen.tsv. TO.REPO en
    TO.PAREN wijzen er even heen; daarna weer terug."""
    d = tempfile.mkdtemp(prefix="en_boek_lab_")
    oud = TO.REPO, TO.PAREN
    try:
        for b in bestanden:
            os.makedirs(os.path.dirname(os.path.join(d, b)), exist_ok=True)
            open(os.path.join(d, b), "w").close()
        with open(os.path.join(d, "taalparen.tsv"), "w", encoding="utf-8") as f:
            f.write(tabel)
        TO.REPO, TO.PAREN = d, os.path.join(d, "taalparen.tsv")
        yield d
    finally:
        TO.REPO, TO.PAREN = oud
        shutil.rmtree(d, ignore_errors=True)


REGEL = "manuscript/h<n>.html\ten/book/h<n>.html\tlos\n"


def geweigerd(tabel: str, bestanden: list[str]) -> str:
    with nep_repo(tabel, bestanden):
        try:
            TO.paren()
        except SystemExit as e:
            return str(e)
    return ""


def deel_b() -> None:
    print("\nB. de regel in taalparen.tsv (h<n>)")
    hoofdstukken = ["en/book/h0.html", "en/book/h1.html", "en/book/h2.html", "en/book/h10.html"]
    ruis = ["en/book/hx.html", "en/book/h2_oud.html", "en/book/H3.html", "en/book/h4.htm",
            "en/book/h5.html.bak", "en/h6.html", "en/book/sub/h7.html"]
    with nep_repo(REGEL, hoofdstukken + ruis):
        p = TO.paren()
    gezien = [x["en"] for x in p]
    uitslag(gezien == hoofdstukken and all(x["nl"] == x["en"].replace("en/book/", "manuscript/") for x in p)
            and all(x["wissel"] == "los" for x in p),
            f"alleen de bestaande hoofdstukken, op getal: {', '.join(os.path.basename(g) for g in gezien)}",
            f"kreeg {gezien}")
    with nep_repo(REGEL, []):
        p = TO.paren()
    uitslag(p == [], "geen en/book/: de regel geeft nul paren, en geen fout", f"kreeg {p}")
    r = geweigerd(REGEL.replace("\tlos", "\tauto"), hoofdstukken)
    uitslag("alleen los of los-eigen" in r, "een regel met auto wordt geweigerd", r or "niet geweigerd")
    r = geweigerd("manuscript/h<n>.html\ten/book/h<n>_<n>.html\tlos\n", hoofdstukken)
    uitslag("precies één keer" in r, "<n> twee keer in een kolom wordt geweigerd", r or "niet geweigerd")
    r = geweigerd("manuscript/h<n>.html\ten/<n>/h.html\tlos\n", hoofdstukken)
    uitslag("bestandsnaam" in r, "<n> in de map in plaats van de bestandsnaam wordt geweigerd", r or "niet geweigerd")
    r = geweigerd("manuscript/h0.html\ten/book/h0.html\tlos\n" + REGEL, hoofdstukken)
    uitslag("twee paren" in r, "een bladzij in twee paren wordt geweigerd", r or "niet geweigerd")

    # De echte tabel: één regel, en de lezer verslikt zich er niet in.
    try:
        TO.paren()
        echt = lees(os.path.join(TOOLS, "taalparen.tsv"))
        n = sum(1 for r in echt.splitlines() if not r.startswith("#") and "<n>" in r)
        uitslag(n == 1, f"_tools/taalparen.tsv leest, en draagt {n} regel met <n> (moet 1)")
    except SystemExit as e:
        uitslag(False, "_tools/taalparen.tsv leest", str(e))

    # Op de ECHTE Nederlandse h0: wat taalonderdelen.py erin zet, haalt de wachtrij er
    # precies weer uit. Dat is de belofte "de rij laat alleen het knopje door".
    nl_pad = os.path.join(REPO, "manuscript", "h0.html")
    if not os.path.isfile(nl_pad):
        uitslag(False, "manuscript/h0.html bestaat", "kon de echte Nederlandse h0 niet lezen")
        return
    def zonder(t: str) -> tuple[str, int]:
        weg = 0
        for _n, r in TO.negeer_regexen():
            weg += sum(len(m.group(0)) for m in re.finditer(r, t))
            t = re.sub(r, "", t)
        return t, weg

    # Op schijf kan hij de stukken al dragen (na `taalonderdelen.py los`); kaal is
    # hem zonder, zoals de Nederlandse pers hem aflevert.
    op_schijf = lees(nl_pad)
    kaal, al = zonder(op_schijf)
    with nep_repo(REGEL, ["en/book/h0.html"]):
        nl = TO.pas_toe_los(kaal, "manuscript/h0.html")
        nl2 = TO.pas_toe_los(nl, "manuscript/h0.html")
        en_lab = TO.pas_toe_los(KOP + stempel(), "en/book/h0.html")
    stukken = {naam: len(re.findall(r, nl)) for naam, r in TO.negeer_regexen()}
    verwacht = {"hreflang": 3, "knop": 1, "stijl_knop": 0, "stijl_knop_los": 1, "balk": 1}
    uitslag(stukken == verwacht, f"manuscript/h0.html krijgt precies {verwacht}", f"kreeg {stukken}")
    terug, weg = zonder(nl)
    uitslag(terug == kaal, f"de regels van de wachtrij halen er precies dat weer uit ({weg} tekens), "
            f"byte voor byte wat de Nederlandse pers afleverde", "er blijft verschil over")
    uitslag(weg <= 4096, f"onder de grens van de wachtrij (4096 tekens per bladzij): {weg}")
    uitslag(nl2 == nl, "twee keer toepassen geeft hetzelfde als één keer")
    if al:
        uitslag(nl == op_schijf, f"de stukken die er op schijf al in stonden ({al} tekens) zijn precies deze",
                "op schijf staat een andere versie van de stukken")
    ja, reden = EB.uit_het_lab("en/book/h0.html", en_lab)
    uitslag(ja and 'aria-label="language"' in en_lab and "/* taalbalk:" not in en_lab,
            "de Engelse kant krijgt het knopje, geen balk, en zijn stempel klopt daarna nog",
            f"uit_het_lab gaf ({ja}, {reden!r})")


# ------------------------------------------------------------------ deel C ----
def keur(site: str, soort: str) -> tuple[int, str]:
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = EB.cmd_keur(argparse.Namespace(site=site, soort=soort))
    return code, buf.getvalue()


def kopie(van: str, naar: str) -> None:
    """Harde links: snel, en een te breken bestand wordt eerst losgeknipt."""
    if os.path.isdir(naar):
        shutil.rmtree(naar)  # onze eigen kopie onder _site_en_werk/ (gitignored)
    shutil.copytree(van, naar, copy_function=os.link, ignore=shutil.ignore_patterns(".claude"))


def schrijf_los(p: str, tekst: str) -> None:
    if os.path.exists(p):
        os.remove(p)
    with open(p, "w", encoding="utf-8") as f:
        f.write(tekst)


def lab_bladzijden(site: str) -> list[str]:
    uit = []
    for p in EB.engelse_bladzijden(site):
        if EB.uit_het_lab(p, lees(os.path.join(site, p)))[0]:
            uit.append(p)
    return uit


def deel_c() -> bool:
    """False als er niet gekeken kon worden."""
    print("\nC. en_bouw.py keur op de gebouwde site, met een echte bladzij uit het lab")
    echt, spook = os.path.join(REPO, "_site"), os.path.join(REPO, "_site_spook")
    for s in (echt, spook):
        if not os.path.isfile(os.path.join(s, "index.html")):
            print(f"KON NIET KIJKEN: {os.path.relpath(s, REPO)}/ is niet gebouwd — draai eerst bash _tools/publiceer_en.sh")
            return False
    lab = lab_bladzijden(echt)
    if not lab or lab != lab_bladzijden(spook):
        print(f"KON NIET KIJKEN: geen (of niet dezelfde) bladzij uit het lab in _site en _site_spook "
              f"(_site: {lab}) — eerst de lab-pers, dan publiceer_en.sh")
        return False
    doel = lab[0]
    print(f"  bladzij uit het lab: {doel} (van {len(lab)})")
    werk = os.path.join(REPO, "_site_en_werk", "toets_lab")
    k_echt, k_spook = os.path.join(werk, "echt"), os.path.join(werk, "spook")
    kopie(echt, k_echt)
    kopie(spook, k_spook)

    nul = True
    for soort, site in (("echt", k_echt), ("spook", k_spook)):
        code, uit = keur(site, soort)
        nul = nul and code == 0
        uitslag(code == 0, f"{soort} zoals hij is" + (", mét de lab-bladzij zonder proefdrukmerken"
                                                     if soort == "spook" else "") + f": afloop {code} (moet 0)",
                " | ".join(r.strip() for r in uit.splitlines() if r.strip().startswith("- "))[:400])
    if not nul:
        print("      zonder een groene nulmeting bewijzen de rode uitslagen hieronder niets")
        return True

    orig = lees(os.path.join(k_echt, doel))
    m = re.search(r"bron-hash=([0-9a-f]{64})", orig[orig.rfind("</html>"):])
    naam = re.search(r"countcamp-publicatie (\S+) bron-hash", orig[orig.rfind("</html>"):]).group(1)
    ander = "H9" if naam != "H9" else "H8"
    # Een losse Quarto-bladzij zonder stempel onder en/book/: zelfde kop, zelfde
    # teller, zelfde taal als de lab-bladzij — alleen de stempel weg en een andere naam.
    zwerver = orig[:orig.rfind("</html>") + len("</html>")] + "\n"
    stray = os.path.join(os.path.dirname(doel), "zwerver.html")
    mutaties = [
        # (wat, soort, bestand, nieuwe tekst, reden die er moet staan)
        ("een losse Quarto-bladzij zonder stempel onder en/book/ (echt)", "echt", stray, zwerver,
         f"{stray}: gebouwd door Quarto"),
        ("diezelfde zwerver in de spooksite", "spook", stray, zwerver, f"{stray}: gebouwd door Quarto"),
        ("de stempel weg van de lab-bladzij (echt): dan is hij een wees", "echt", doel, zwerver,
         f"{doel}: gebouwd door Quarto"),
        ("de stempel weg in de spooksite: dan gelden de proefdrukmerken", "spook", doel, zwerver,
         f"{doel}: proefdruk zonder noindex"),
        ("een korte hash (7 tekens)", "echt", doel, orig.replace(m.group(1), m.group(1)[:7]), "vorm van de pers"),
        ("een korte hash in de spooksite", "spook", doel, orig.replace(m.group(1), m.group(1)[:7]),
         "vorm van de pers"),
        (f"de stempel van {ander} op {os.path.basename(doel)}", "echt", doel,
         orig.replace(f"countcamp-publicatie {naam} ", f"countcamp-publicatie {ander} "), "hoort bij"),
        ("de lab-bladzij met noindex in de spooksite", "spook", doel,
         orig.replace("</head>", '<meta name="robots" content="noindex">\n</head>', 1), "draagt noindex in de spooksite"),
        ("de lab-bladzij zonder teller in de spooksite", "spook", doel,
         orig.replace("gc.zgo.at/count.js", "gc.zgo.at/weg.js"), "bezoekersteller"),
        ("de lab-bladzij met de proefdrukbalk in de spooksite", "spook", doel,
         orig.replace("<body", '<div class="spookbalk">proef</div>\n<body', 1), "proefdrukbalk in de spooksite"),
    ]
    for wat, soort, rel, tekst, reden in mutaties:
        site = k_echt if soort == "echt" else k_spook
        p = os.path.join(site, rel)
        was = lees(p) if os.path.exists(p) else None
        if tekst == was:
            uitslag(False, wat, "de verminking veranderde niets — de toets zelf klopt niet meer")
            continue
        schrijf_los(p, tekst)
        code, uit = keur(site, soort)
        if was is None:
            os.remove(p)
        else:
            schrijf_los(p, was)
        uitslag(code == 1 and reden in uit, f"{wat}: afloop {code}",
                "" if reden in uit else f"reden NIET genoemd ({reden})")

    for soort, site in (("echt", k_echt), ("spook", k_spook)):
        code, _ = keur(site, soort)
        uitslag(code == 0, f"{soort} na het terugzetten: afloop {code} (moet 0; anders lekte een verminking door)")
    shutil.rmtree(werk)
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("delen", nargs="*", default=["A", "B", "C"], choices=["A", "B", "C"])
    a = ap.parse_args()
    gekeken = True
    if "A" in a.delen:
        deel_a()
    if "B" in a.delen:
        deel_b()
    if "C" in a.delen:
        gekeken = deel_c()
    n = goed + fout
    print(f"\n{goed} van {n} goed" + (f" — {fout} FOUT" if fout else "")
          + ("" if gekeken else " — deel C KON NIET KIJKEN, dus dit is geen groene uitslag"))
    if fout:
        return 1
    return 0 if gekeken else 3


if __name__ == "__main__":
    # Een crash is geen rode uitslag maar een blinde: Python eindigt dan óók op 1, en
    # de mutatieproef zou hem als "gevangen" tellen (zo ging het bij de eerste ronde).
    try:
        sys.exit(main())
    except Exception as e:  # noqa: BLE001
        import traceback
        traceback.print_exc()
        print(f"\nKON NIET KIJKEN: de toets zelf liep vast ({type(e).__name__}: {e}) — dit is geen uitslag")
        sys.exit(3)
