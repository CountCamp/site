#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""en_werkboek_lab_test.py — is een Engels oefenboek uit het lab een bijlage, en een vergeten bladzij nog steeds een wees?

    python3 _tools/tests/en_werkboek_lab_test.py               A, B en C
    python3 _tools/tests/en_werkboek_lab_test.py A B           alleen deze delen

WAAROM (spoor vb_site2, 28-10-2026). Een Engels oefenboek wordt in het lab gerenderd
en landt onder en/workbooks/<naam>/ (besloten adres: en/workbooks/mvda/). Dat zijn
door Quarto gebouwde bladzijden zonder .qmd in deze repo, en de wees-keuring van
en_bouw.py weigerde ze, met het advies "haal hem weg of zet de bron terug" — terwijl
de bron in het lab staat. Nu zet publish_workbook.py --section en/workbooks een
stempel (oefenboek + commit van het lab), en en_bouw.py laat zo'n bladzij door als
bijlage. Een uitzondering die op een stempel rust, is zo sterk als de toets op die
stempel — en een vergeten bladzij moet een wees blijven, mét het oude advies.

DRIE DELEN
  A. uit_een_werkboek() op losse teksten — geen bouw nodig. Een goede stempel op elke
     diepte in een oefenboek komt door; een korte commit, hoofdletters, geen tijd, twee
     stempels, een stempel vóór </html>, rommel erachter, de naam van een ander
     oefenboek, een stempel buiten en/workbooks/<naam>/: allemaal een gat.
  B. publish_workbook.py écht gedraaid, in een proefsite en een proeflab (een eigen
     git-repo) onder _site_en_werk/ — de echte site blijft onaangeroerd. Schone bron:
     elke bladzij gestempeld met de commit van het proeflab, en en_bouw.py herkent
     elke stempel, en de bladzij zelf blijft byte voor byte wat hij was. Geweigerd,
     en een eerder gepubliceerd oefenboek blijft byte voor byte staan: ongecommit werk
     in het project, of achter een wegwijzer (_common -> ../../gedeeld), of een nieuw
     bestand terwijl het lab die in git status verbergt; een commit ná de render
     zonder opnieuw te renderen (schoon, en toch niet de render van HEAD); een
     wegwijzer naar buiten de repo; geen _quarto.yml boven de render; een bron buiten
     git, of in een genegeerde map van een ándere repo; een bladzij in de bron waar de
     stempel niet op past (geen </html>, of al gestempeld) — vóór er iets weggaat. Een
     render die git niet negeert, telt niet als ongecommit. Het Nederlands (--section
     oefenboeken): geen stempel, en byte voor byte wat publish_workbook.py van 4e28ed8
     neerzette. Een naam die niet in de stempel past: afloop 2.
  C. en_bouw.py keur op de gebouwde site (_site en _site_spook, zoals
     publiceer_en.sh ze achterlaat), met een gestempeld oefenboek erin dat gemaakt is
     uit de gebouwde en/workbooks/index.html (een échte Quarto-bladzij, één en twee
     mappen dieper gezet): groen in beide soorten, en rood — met de goede reden — bij
     een losse bladzij zonder stempel in dat oefenboek (één wees, met het oude advies),
     de stempel weg, de naam van een ander oefenboek, een gestempelde bladzij direct
     onder en/workbooks/, twee publicaties door elkaar (elke bladzij klopt, de
     stempels verschillen), en in de spooksite noindex, de balk of geen teller.
     Zonder zo'n gebouwde site kan C niet kijken, en dan zegt hij dat (afloop 3).

DE MUTATIEPROEF. PROEF_MUTATIE="bestand|||oud|||nieuw" verandert vóór de toets één
stuk tekst in _tools/en_bouw.py of _tools/publish_workbook.py — in het geheugen (A, C)
of in de kopie in de proefsite (B); het bestand in de repo blijft heel. Staat `oud` er
niet precies één keer in, dan is dat afloop 2. Zie en_werkboek_lab_mutatieproef.sh.

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
import subprocess
import sys
import tempfile
import types

HIER = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HIER)
REPO = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
WERK = os.path.join(REPO, "_site_en_werk", "toets_werkboek")   # gitignored


def lees(p: str) -> str:
    with open(p, encoding="utf-8") as f:
        return f.read()


def schrijf(p: str, tekst: str) -> None:
    os.makedirs(os.path.dirname(p), exist_ok=True)
    if os.path.exists(p):
        os.remove(p)   # een harde link wordt eerst losgeknipt
    with open(p, "w", encoding="utf-8") as f:
        f.write(tekst)


# --------------------------------------------- de bronnen, eventueel gemuteerd ----
GEMUTEERD = ("_tools/en_bouw.py", "_tools/publish_workbook.py")


def bronnen() -> dict[str, str]:
    m = os.environ.get("PROEF_MUTATIE")
    tekst = {rel: lees(os.path.join(REPO, rel)) for rel in GEMUTEERD}
    if not m:
        return tekst
    delen = m.split("|||")
    if len(delen) != 3:
        print(f"MUTATIE sloeg niet aan: PROEF_MUTATIE heeft niet de vorm bestand|||oud|||nieuw: {m[:80]!r}")
        sys.exit(2)
    rel, oud, nieuw = delen
    if rel not in tekst:
        print(f"MUTATIE sloeg niet aan: deze toets muteert alleen {' en '.join(GEMUTEERD)}, niet {rel}")
        sys.exit(2)
    n = tekst[rel].count(oud)
    if n != 1:
        print(f"MUTATIE sloeg niet aan: {oud!r} staat {n} keer in {rel} (moet 1)")
        sys.exit(2)
    tekst[rel] = tekst[rel].replace(oud, nieuw)
    print(f"MUTATIE in {rel}: {oud.strip()[:70]!r} -> {nieuw.strip()[:70]!r}")
    return tekst


BRON = bronnen()


def laad(naam: str, rel: str) -> types.ModuleType:
    mod = types.ModuleType(naam)
    mod.__file__ = os.path.join(REPO, rel)
    sys.modules[naam] = mod
    exec(compile(BRON[rel], mod.__file__, "exec"), mod.__dict__)
    return mod


EB = laad("en_bouw", "_tools/en_bouw.py")

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
COMMIT = hashlib.sha1(b"countcamp").hexdigest()     # 40 hextekens, zoals git rev-parse HEAD
KOP = ('<!DOCTYPE html>\n<html lang="en-GB"><head>\n<meta name="generator" content="quarto-1.9.38">\n'
       '<title>t</title>\n</head>\n<body>\n<p>text</p>\n</body></html>\n')


def stempel(naam: str = "mvda", c: str = COMMIT, t: str = "geleverd=2026-10-28T16:40:00") -> str:
    """Precies wat publish_workbook.py schrijft (zet_werkboek_stempels)."""
    return f"<!-- countcamp-oefenboek {naam} lab-commit={c} {t} -->\n"


def deel_a() -> None:
    print("\nA. uit_een_werkboek() op losse teksten")
    # (wat, sitepad, tekst, verwacht): True = oefenboek uit het lab, "" = gewone bladzij,
    # anders een stukje van de reden die er moet staan.
    gevallen = [
        ("de voorpagina van een oefenboek", "en/workbooks/mvda/index.html", KOP + stempel(), True),
        ("een thema, een map dieper", "en/workbooks/mvda/00_opfris/00_opfris.html", KOP + stempel(), True),
        ("twee mappen dieper", "en/workbooks/mvda/a/b/c.html", KOP + stempel(), True),
        ("psychometrics in zijn eigen map", "en/workbooks/psychometrics/index.html",
         KOP + stempel("psychometrics"), True),
        ("geen stempel: een gewone bladzij", "en/workbooks/mvda/index.html", KOP, ""),
        ("een korte commit (7 tekens)", "en/workbooks/mvda/index.html", KOP + stempel(c=COMMIT[:7]),
         "vorm van publish_workbook.py"),
        ("39 hextekens", "en/workbooks/mvda/index.html", KOP + stempel(c=COMMIT[:39]), "vorm van publish_workbook.py"),
        ("hoofdletters in de commit", "en/workbooks/mvda/index.html", KOP + stempel(c=COMMIT.upper()),
         "vorm van publish_workbook.py"),
        ("geen tijd", "en/workbooks/mvda/index.html", KOP + stempel(t=""), "vorm van publish_workbook.py"),
        ("een hoofdletter in de naam", "en/workbooks/MVDA/index.html", KOP + stempel("MVDA"),
         "vorm van publish_workbook.py"),
        ("twee stempels: twee publicaties door elkaar", "en/workbooks/mvda/index.html",
         KOP + stempel() + stempel(), "precies één regel"),
        ("rommel na de stempel", "en/workbooks/mvda/index.html", KOP + stempel() + "<script>x()</script>\n",
         "precies één regel"),
        ("de stempel vóór </html>", "en/workbooks/mvda/index.html",
         KOP.replace("</body>", stempel() + "</body>"), "na de laatste </html>"),
        ("een goede stempel erna, en nog een in de tekst", "en/workbooks/mvda/index.html",
         KOP.replace("<p>text</p>", "<p>text</p>" + stempel()) + stempel(), "na de laatste </html>"),
        ("geen </html> in de bladzij", "en/workbooks/mvda/index.html", KOP.replace("</html>", "") + stempel(),
         "na de laatste </html>"),
        ("de stempel van psychometrics in de map mvda", "en/workbooks/mvda/index.html",
         KOP + stempel("psychometrics"), "hoort in en/workbooks/psychometrics/"),
        ("een goede stempel, direct onder en/workbooks/ (de plank zelf)", "en/workbooks/index.html",
         KOP + stempel(), "niet in een oefenboek onder en/workbooks/<naam>/"),
        ("een goede stempel, onder en/book/", "en/book/mvda/index.html", KOP + stempel(),
         "niet in een oefenboek"),
        ("een goede stempel, in het Nederlandse oefenboek", "oefenboeken/mvda/index.html", KOP + stempel(),
         "niet in een oefenboek onder en/workbooks/"),
    ]
    for wat, p, tekst, verwacht in gevallen:
        ja, reden = EB.uit_een_werkboek(p, tekst)
        if verwacht is True:
            uitslag(ja and not reden, wat, f"kreeg ({ja}, {reden!r})")
        elif verwacht == "":
            uitslag(not ja and not reden, wat, f"kreeg ({ja}, {reden!r})")
        else:
            uitslag(not ja and verwacht in reden, wat, f"kreeg ({ja}, {reden!r}), verwacht een reden met {verwacht!r}")


# ------------------------------------------------------------------ deel B ----
TELLER = '<script data-goatcounter="https://countcamp.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>'


def git(map_: str, *args: str) -> subprocess.CompletedProcess:
    # Eigen naam en geen haken: dit is een wegwerprepo, en de haken van wie de
    # toets draait horen er niet in te grijpen.
    return subprocess.run(["git", "-C", map_, "-c", "user.name=toets", "-c", "user.email=toets@countcamp.invalid",
                           "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", *args],
                          capture_output=True, text=True)


def proeflab(wortel: str) -> str:
    """Een nep-lab: een git-repo met een project <wortel>/werkboek/en/ (eigen _quarto.yml,
    een wegwijzer _common -> ../../gedeeld zoals mvda_werkboek/en/_common) en een
    gerenderde _site/ erin (index + een thema één map dieper). Geeft het pad naar _site."""
    project = os.path.join(wortel, "werkboek", "en")
    site = os.path.join(project, "_site")
    schrijf(os.path.join(wortel, "gedeeld", "helper.R"), "helper <- function() 1\n")
    schrijf(os.path.join(project, "_quarto.yml"), "project:\n  type: website\nlang: en-GB\n")
    schrijf(os.path.join(project, "index.qmd"), "---\ntitle: Practice book\n---\n")
    schrijf(os.path.join(project, ".gitignore"), "/_site/\n")
    os.symlink("../../gedeeld", os.path.join(project, "_common"))
    schrijf(os.path.join(site, "index.html"),
            '<!DOCTYPE html>\n<html lang="en-GB"><head><meta charset="utf-8">'
            '<meta name="generator" content="quarto-1.9.38">\n<title>Practice book</title>\n'
            f'{TELLER}\n</head><body><p><a href="00_opfris/00_opfris.html">topic 0</a></p></body></html>\n')
    schrijf(os.path.join(site, "00_opfris", "00_opfris.html"),
            '<!DOCTYPE html>\n<html lang="en-GB"><head><meta charset="utf-8">'
            '<meta name="generator" content="quarto-1.9.38">\n<title>Topic 0</title>\n'
            '</head><body><p><a href="../index.html">back</a></p></body></html>')   # geen teller, geen \n op het eind
    for args in (("init", "-q"), ("add", "-A"), ("commit", "-q", "-m", "proeflab")):
        r = git(wortel, *args)
        if r.returncode != 0:
            raise RuntimeError(f"git {' '.join(args)} in het proeflab: {r.stderr.strip()}")
    her_render(site)
    return site


def her_render(site: str) -> None:
    """Doen alsof er opnieuw gerenderd is: elke bladzij krijgt de tijd van nu. Na een
    terugzetting (checkout) is de bron anders nieuwer dan de render, en terecht geweigerd."""
    for dp, _d, fs in os.walk(site):
        for f in fs:
            os.utime(os.path.join(dp, f), None)


def commit_alles(lab: str, boodschap: str) -> None:
    for args in (("add", "-A"), ("commit", "-q", "-m", boodschap)):
        r = git(lab, *args)
        if r.returncode != 0:
            raise RuntimeError(f"git {' '.join(args)} in het proeflab: {r.stderr.strip()}")


def bytes_onder(map_: str) -> dict[str, bytes]:
    uit = {}
    for dp, _d, fs in os.walk(map_):
        for f in fs:
            uit[os.path.relpath(os.path.join(dp, f), map_)] = open(os.path.join(dp, f), "rb").read()
    return uit


def proefsite(wortel: str) -> str:
    """Een nep-site met de (eventueel gemuteerde) scripts in _tools/. publish_workbook.py
    leidt zijn doelmap af uit zijn eigen plek, dus hij schrijft hier en niet in de repo."""
    for rel in ("_tools/publish_workbook.py", "_tools/en_bouw.py"):
        schrijf(os.path.join(wortel, rel), BRON[rel])
    for rel in ("_tools/tellerregel.py", "_tools/taalonderdelen.py"):
        shutil.copy2(os.path.join(REPO, rel), os.path.join(wortel, rel))
    return os.path.join(wortel, "_tools", "publish_workbook.py")


def publiceer(script: str, src: str, *extra: str) -> tuple[int, str]:
    r = subprocess.run([sys.executable, script, "--src", src, *extra], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def html_onder(map_: str) -> dict[str, str]:
    uit = {}
    for dp, _d, fs in os.walk(map_):
        for f in fs:
            if f.endswith(".html"):
                uit[os.path.relpath(os.path.join(dp, f), map_)] = lees(os.path.join(dp, f))
    return uit


def deel_b() -> bool:
    """False als er niet gekeken kon worden (het Nederlands van vóór 28-10 niet te lezen)."""
    print("\nB. publish_workbook.py écht gedraaid, in een proefsite en een proeflab")
    if os.path.isdir(WERK):
        shutil.rmtree(WERK)   # onze eigen werkmap (gitignored)
    lab, site = os.path.join(WERK, "lab"), os.path.join(WERK, "site")
    project = os.path.join(lab, "werkboek", "en")
    src = proeflab(lab)
    script = proefsite(site)
    doel = os.path.join(site, "en", "workbooks", "proefboek")
    EN = ("--section", "en/workbooks", "--name", "proefboek")

    def head() -> str:
        return git(lab, "rev-parse", "HEAD").stdout.strip()

    code, uit = publiceer(script, src, *EN)
    bladz = html_onder(doel)
    uitslag(code == 0, f"schone bron, en/workbooks: afloop {code} (moet 0)", uit.strip().splitlines()[-1] if uit else "")
    uitslag(len(bladz) == 2, f"twee bladzijden neergezet ({', '.join(sorted(bladz))})", f"kreeg {sorted(bladz)}")
    for rel, t in sorted(bladz.items()):
        sitepad = f"en/workbooks/proefboek/{rel}"
        ja, reden = EB.uit_een_werkboek(sitepad, t)
        staart = [r for r in t[t.rfind("</html>") + 7:].splitlines() if r.strip()]
        uitslag(ja and len(staart) == 1 and f"lab-commit={head()} " in staart[0],
                f"{sitepad}: één stempel, met de commit van het proeflab ({head()[:7]}), en en_bouw.py herkent hem",
                f"uit_een_werkboek gaf ({ja}, {reden!r}); staart {staart}")
    uitslag("stempel: 2 bladzij(den) gestempeld en door en_bouw.py herkend, 0 niet" in uit,
            "het script zegt hoeveel het stempelde, en dat de keuring ze allemaal herkende", uit[-300:])
    uitslag("bash _tools/publiceer_en.sh" in uit and "git push" not in uit,
            "en de volgende stap is de Engelse keuring, niet meteen pushen", uit[-200:])
    src_zonder = open(os.path.join(src, "00_opfris", "00_opfris.html"), "rb").read()
    p_na = os.path.join(doel, "00_opfris", "00_opfris.html")
    na_stempel = open(p_na, "rb").read() if os.path.isfile(p_na) else b""
    uitslag(bool(na_stempel) and na_stempel.startswith(src_zonder.replace(b"</head>", b"  " + TELLER.encode() + b"\n</head>", 1)),
            "de bladzij zelf blijft byte voor byte wat hij was (teller erin, stempel erachter)",
            "" if na_stempel else "de bladzij is niet neergezet")
    voor = bytes_onder(doel)

    def geweigerd(wat: str, reden: str) -> None:
        code, uit = publiceer(script, src, *EN)
        uitslag(code == 1 and reden in uit, f"{wat}: afloop {code} (moet 1), met de reden ({reden!r})", uit[-300:])
        uitslag(bytes_onder(doel) == voor, "  en het eerder gepubliceerde oefenboek staat er byte voor byte nog")

    # 1. Ongecommit werk in het project.
    with open(os.path.join(project, "index.qmd"), "a", encoding="utf-8") as f:
        f.write("\nnog niet gecommit\n")
    geweigerd("ongecommit werk in het project", "ongecommit werk in de bron")
    git(lab, "checkout", "-q", "--", ".")
    her_render(src)

    # 2. Ongecommit werk achter een wegwijzer: _common -> ../../gedeeld.
    with open(os.path.join(lab, "gedeeld", "helper.R"), "a", encoding="utf-8") as f:
        f.write("helper2 <- function() 2\n")
    geweigerd("ongecommit werk achter de wegwijzer _common", "ongecommit werk in de bron")
    git(lab, "checkout", "-q", "--", ".")
    her_render(src)

    # 3. Een nieuw hoofdstuk dat git nog niet kent, en het lab laat nieuwe bestanden
    #    in git status weg (status.showUntrackedFiles=no).
    git(lab, "config", "status.showUntrackedFiles", "no")
    schrijf(os.path.join(project, "02_nieuw.qmd"), "---\ntitle: nieuw\n---\n")
    geweigerd("een nieuw bestand, met status.showUntrackedFiles=no in het lab", "ongecommit werk in de bron")
    os.remove(os.path.join(project, "02_nieuw.qmd"))
    git(lab, "config", "--unset", "status.showUntrackedFiles")

    # 4. Gecommit ná de render: de bron is schoon, en toch is dit niet de render van HEAD.
    with open(os.path.join(project, "index.qmd"), "a", encoding="utf-8") as f:
        f.write("\nna de render\n")
    commit_alles(lab, "na de render")
    geweigerd("een commit na de render, zonder opnieuw te renderen", "nieuwer dan de render")
    her_render(src)
    code, uit = publiceer(script, src, *EN)
    p_voor = os.path.join(doel, "index.html")
    t = lees(p_voor) if os.path.isfile(p_voor) else ""
    uitslag(code == 0 and f"lab-commit={head()} " in t,
            f"opnieuw gerenderd: afloop {code}, en de stempel noemt de nieuwe commit ({head()[:7]})", uit[-300:])
    voor = bytes_onder(doel)

    # 5. Een wegwijzer naar buiten de repo: die commit dekt niet wat de render daar las.
    with tempfile.TemporaryDirectory(prefix="werkboek_buiten_") as buiten:
        os.symlink(buiten, os.path.join(project, "buiten"))
        commit_alles(lab, "wegwijzer naar buiten")
        her_render(src)
        geweigerd("een wegwijzer die buiten de repo wijst", "wijst buiten de repo")
        git(lab, "rm", "-q", "werkboek/en/buiten")
        commit_alles(lab, "wegwijzer weg")
        her_render(src)

    # 5b. Een map boven _site/ zonder _quarto.yml: dan is het niet het project dat we denken.
    qy = os.path.join(project, "_quarto.yml")
    qy_tekst = lees(qy)
    os.remove(qy)
    commit_alles(lab, "_quarto.yml weg")
    her_render(src)
    geweigerd("geen _quarto.yml boven de render", "geen _quarto.yml")
    schrijf(qy, qy_tekst)
    commit_alles(lab, "_quarto.yml terug")
    her_render(src)

    # 6. Een render buiten git: geen commit om te noemen. In /tmp, want alles onder
    #    deze repo staat in een git-repo (deze).
    with tempfile.TemporaryDirectory(prefix="werkboek_los_") as tmp:
        los = os.path.join(tmp, "en", "_site")
        shutil.copytree(src, los)
        code, uit = publiceer(script, los, *EN)
    uitslag(code == 1 and "niet in een git-repo" in uit, f"een bron buiten git: afloop {code} (moet 1), met de reden",
            uit[-300:])
    # 7. Een render in een genegeerde map van een ándere repo (hier: _site_en_werk/ van
    #    deze site). git rev-parse geeft dan een commit -- van de verkeerde repo.
    los = os.path.join(WERK, "los", "en")
    shutil.copytree(project, los, symlinks=True)
    code, uit = publiceer(script, os.path.join(los, "_site"), *EN)
    uitslag(code == 1 and "staat in git" in uit,
            f"een bron in een genegeerde map van een andere repo: afloop {code} (moet 1), met de reden", uit[-300:])
    uitslag(bytes_onder(doel) == voor, "  en het eerder gepubliceerde oefenboek staat er byte voor byte nog")

    # 8. Bladzijden in de bron waar de stempel niet op kan: geweigerd vóór er iets
    #    weggegooid wordt (de voorproef), niet erna.
    kapot = os.path.join(src, "kapot.html")
    schrijf(kapot, '<!DOCTYPE html>\n<html lang="en-GB"><head><title>k</title></head><body>x</body>\n')
    geweigerd("een bladzij zonder </html> in de bron", "kapot.html")
    os.remove(kapot)
    al = os.path.join(src, "al_gestempeld.html")
    schrijf(al, KOP + stempel("proefboek"))
    geweigerd("een bladzij die al een stempel draagt (--src naar een gepubliceerde kopie?)", "al_gestempeld.html")
    os.remove(al)

    # 9. Een render die git niet negeert: die telt niet als ongecommit werk.
    schrijf(os.path.join(project, ".gitignore"), "# _site/ niet genegeerd\n")
    commit_alles(lab, "render niet meer genegeerd")
    her_render(src)
    code, uit = publiceer(script, src, *EN)
    uitslag(code == 0, f"een render die git niet negeert (?? _site/): afloop {code} (moet 0)", uit[-300:])

    # 10. Het Nederlands verandert niet: geen stempel onder oefenboeken/, en byte voor
    #     byte wat publish_workbook.py van vóór deze wijziging (4e28ed8) neerzet.
    code, uit = publiceer(script, src, "--name", "proefboek")
    nl = bytes_onder(os.path.join(site, "oefenboeken", "proefboek"))
    uitslag(code == 0 and sum(k.endswith(".html") for k in nl) == 2 and not any(b"countcamp-oefenboek" in v for v in nl.values()),
            f"--section oefenboeken (Nederlands): afloop {code}, 2 bladzijden, geen stempel", uit[-300:])
    r = subprocess.run(["git", "-C", REPO, "show", "4e28ed8:_tools/publish_workbook.py"], capture_output=True, text=True)
    if r.returncode != 0:
        print(f"KON NIET KIJKEN: publish_workbook.py van 4e28ed8 niet te lezen ({r.stderr.strip()[:100]}) — "
              f"of het Nederlands byte voor byte gelijk bleef, is niet gemeten")
        return False
    oud = os.path.join(WERK, "site_oud")
    schrijf(os.path.join(oud, "_tools", "publish_workbook.py"), r.stdout)
    shutil.copy2(os.path.join(REPO, "_tools", "tellerregel.py"), os.path.join(oud, "_tools", "tellerregel.py"))
    code_oud, _ = publiceer(os.path.join(oud, "_tools", "publish_workbook.py"), src, "--name", "proefboek")
    nl_oud = bytes_onder(os.path.join(oud, "oefenboeken", "proefboek"))
    uitslag(code_oud == 0 and nl == nl_oud,
            f"en byte voor byte gelijk aan publish_workbook.py van 4e28ed8 ({len(nl)} bestanden)",
            f"afloop oud {code_oud}; verschil in {sorted(set(nl) ^ set(nl_oud)) or [k for k in nl if nl[k] != nl_oud.get(k)]}")

    # 11. Een naam die niet in de stempel past.
    code, uit = publiceer(script, src, "--section", "en/workbooks", "--name", "Proef Boek")
    uitslag(code == 2 and not os.path.exists(os.path.join(site, "en", "workbooks", "Proef Boek")),
            f"een naam met een hoofdletter en een spatie: afloop {code} (moet 2), niets neergezet", uit[-200:])
    return True


# ------------------------------------------------------------------ deel C ----
def keur(site: str, soort: str) -> tuple[int, str]:
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = EB.cmd_keur(argparse.Namespace(site=site, soort=soort))
    return code, buf.getvalue()


def kopie(van: str, naar: str) -> None:
    """Harde links: snel, en een te breken bestand wordt eerst losgeknipt (schrijf)."""
    if os.path.isdir(naar):
        shutil.rmtree(naar)  # onze eigen kopie onder _site_en_werk/ (gitignored)
    shutil.copytree(van, naar, copy_function=os.link, ignore=shutil.ignore_patterns(".claude"))


RELATIEF = re.compile(r'(\b(?:href|src)\s*=\s*")(?![a-zA-Z][a-zA-Z0-9+.-]*:|/|#)')


def dieper(t: str) -> str:
    """Dezelfde bladzij, één map dieper: elke relatieve href en src krijgt ../ ervoor."""
    return RELATIEF.sub(r"\1../", t)


def deel_c() -> bool:
    """False als er niet gekeken kon worden."""
    print("\nC. en_bouw.py keur op de gebouwde site, met een gestempeld oefenboek erin")
    echt, spook = os.path.join(REPO, "_site"), os.path.join(REPO, "_site_spook")
    for s in (echt, spook):
        if not os.path.isfile(os.path.join(s, "index.html")):
            print(f"KON NIET KIJKEN: {os.path.relpath(s, REPO)}/ is niet gebouwd — draai eerst "
                  f"bash _tools/publiceer_en.sh --alleen-spook")
            return False
    plank = os.path.join(echt, "en", "workbooks", "index.html")
    if not os.path.isfile(plank) or 'name="generator" content="quarto' not in lees(plank) \
            or EB.tellerstand(lees(plank)) != "geteld":
        print("KON NIET KIJKEN: _site/en/workbooks/index.html ontbreekt, of is geen Quarto-bladzij met teller "
              "— daar maakt deze toets zijn oefenboek van")
        return False
    werk = os.path.join(WERK, "keur")
    k_echt, k_spook = os.path.join(werk, "echt"), os.path.join(werk, "spook")
    kopie(echt, k_echt)
    kopie(spook, k_spook)

    # Het oefenboek: de echte plank (Quarto, teller, en-GB) één en twee mappen dieper,
    # gestempeld zoals publish_workbook.py het doet. In de spooksite staat hij net zo:
    # een bijlage komt kant-en-klaar, met teller.
    orig = lees(plank)
    voor = "en/workbooks/proefboek/index.html"
    thema = "en/workbooks/proefboek/00_opfris/00_opfris.html"
    boek = {voor: dieper(orig) + stempel("proefboek"), thema: dieper(dieper(orig)) + stempel("proefboek")}
    for site in (k_echt, k_spook):
        for rel, t in boek.items():
            schrijf(os.path.join(site, rel), t)

    nul = True
    for soort, site in (("echt", k_echt), ("spook", k_spook)):
        code, uit = keur(site, soort)
        nul = nul and code == 0
        uitslag(code == 0 and "verweesd: 0 " in uit and "uit een oefenboek: 2 bladzij(den)" in uit,
                f"{soort} met het gestempelde oefenboek: afloop {code} (moet 0), 0 wezen, 2 bladzijden herkend",
                " | ".join(r.strip() for r in uit.splitlines()
                           if r.strip().startswith(("- ", "verweesd", "uit een oefenboek")))[:500])
    if not nul:
        print("      zonder een groene nulmeting bewijzen de rode uitslagen hieronder niets")
        return True

    zwerver = "en/workbooks/proefboek/zwerver.html"
    kaal = boek[voor][:boek[voor].rfind("</html>") + len("</html>")] + "\n"
    kaal_thema = boek[thema][:boek[thema].rfind("</html>") + len("</html>")] + "\n"
    mutaties = [
        # (wat, soort, bestand, nieuwe tekst, reden die er moet staan, aantal wezen dat er moet staan of None)
        ("een losse bladzij zonder stempel in het oefenboek (echt): één wees, met het oude advies", "echt",
         zwerver, kaal, "haal hem weg of zet de bron terug", 1),
        ("diezelfde zwerver in de spooksite: ook daar een wees", "spook", zwerver, kaal,
         "haal hem weg of zet de bron terug", 1),
        ("twee publicaties door elkaar: elke bladzij klopt, maar het thema draagt een andere commit", "echt",
         thema, kaal_thema + stempel("proefboek", c=hashlib.sha1(b"ander").hexdigest(), t="geleverd=2026-10-29T09:00:00"),
         "2 verschillende stempels", 0),
        ("de stempel weg van de voorpagina (echt): dan is hij een wees", "echt", voor, kaal,
         f"{voor}: gebouwd door Quarto", 1),
        ("de stempel weg in de spooksite: dan gelden de proefdrukmerken", "spook", voor, kaal,
         f"{voor}: proefdruk zonder noindex", None),
        ("de stempel van een ander oefenboek", "echt", voor, kaal + stempel("mvda"),
         "hoort in en/workbooks/mvda/", None),
        ("een korte commit", "echt", thema, kaal + stempel("proefboek", c=COMMIT[:7]),
         "vorm van publish_workbook.py", None),
        ("een gestempelde bladzij direct onder en/workbooks/", "echt", "en/workbooks/los.html",
         orig + stempel("proefboek"), "niet in een oefenboek onder en/workbooks/<naam>/", None),
        ("het oefenboek met noindex in de spooksite", "spook", voor,
         boek[voor].replace("</head>", '<meta name="robots" content="noindex">\n</head>', 1),
         "draagt noindex in de spooksite", None),
        ("het oefenboek zonder teller in de spooksite", "spook", voor,
         boek[voor].replace("gc.zgo.at/count.js", "gc.zgo.at/weg.js"), "bezoekersteller", None),
        ("het oefenboek met de proefdrukbalk in de spooksite", "spook", voor,
         boek[voor].replace("<body", '<div class="spookbalk">proef</div>\n<body', 1),
         "proefdrukbalk in de spooksite", None),
    ]
    for wat, soort, rel, tekst, reden, n_wees in mutaties:
        site = k_echt if soort == "echt" else k_spook
        p = os.path.join(site, rel)
        was = lees(p) if os.path.exists(p) else None
        if tekst == was:
            uitslag(False, wat, "de verminking veranderde niets — de toets zelf klopt niet meer")
            continue
        schrijf(p, tekst)
        code, uit = keur(site, soort)
        if was is None:
            os.remove(p)
        else:
            schrijf(p, was)
        m = re.search(r"verweesd: (\d+) ", uit)
        wezen = int(m.group(1)) if m else -1
        uitslag(code == 1 and reden in uit and (n_wees is None or wezen == n_wees),
                f"{wat}: afloop {code}" + (f", {wezen} wees" if n_wees is not None else ""),
                ("" if reden in uit else f"reden NIET genoemd ({reden})")
                + ("" if n_wees is None or wezen == n_wees else f" {wezen} wezen in plaats van {n_wees}"))

    for soort, site in (("echt", k_echt), ("spook", k_spook)):
        code, _ = keur(site, soort)
        uitslag(code == 0, f"{soort} na het terugzetten: afloop {code} (moet 0; anders lekte een verminking door)")
    shutil.rmtree(werk)
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("delen", nargs="*", default=["A", "B", "C"], choices=["A", "B", "C"])
    a = ap.parse_args()
    blind = []
    if "A" in a.delen:
        deel_a()
    if "B" in a.delen and not deel_b():
        blind.append("B")
    if "C" in a.delen and not deel_c():
        blind.append("C")
    gekeken = not blind
    n = goed + fout
    print(f"\n{goed} van {n} goed" + (f" — {fout} FOUT" if fout else "")
          + ("" if gekeken else f" — deel {' en '.join(blind)} KON NIET KIJKEN, dus dit is geen groene uitslag"))
    if fout:
        return 1
    return 0 if gekeken else 3


if __name__ == "__main__":
    # Een crash is geen rode uitslag maar een blinde: Python eindigt dan óók op 1, en
    # de mutatieproef zou hem als "gevangen" tellen.
    try:
        sys.exit(main())
    except Exception as e:  # noqa: BLE001
        import traceback
        traceback.print_exc()
        print(f"\nKON NIET KIJKEN: de toets zelf liep vast ({type(e).__name__}: {e}) — dit is geen uitslag")
        sys.exit(3)
