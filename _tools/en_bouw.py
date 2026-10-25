#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""en_bouw.py — de machinekamer onder _tools/publiceer_en.sh.

Elke stap is een los subcommando, zodat publiceer_en.sh ze in de goede
volgorde kan zetten en een toets ze één voor één kan proeven:

    python3 _tools/en_bouw.py bouw --soort echt|spook
        quarto render --profile en[,spook] -> _site_en/

    python3 _tools/en_bouw.py zet --naar <map>
        zet de Engelse bouw uit _site_en/ neer als <map>/en/ (+ en/libs/).
        <map> is _site, _site_spook, of "." (de repo zelf). Schrijft NIETS
        buiten <map>/en/.

    python3 _tools/en_bouw.py keur --site <map> --soort echt|spook
        alle keuringen op een gebouwde site: links, merktekens, tweelingen,
        contactgegevens, verweesde bladzijden, werkbriefjes, en de stempel van
        de bijlagen uit het lab (en/book/, zie LAB_STEMPEL).

    python3 _tools/en_bouw.py bronnen
        de nl_bron-stempels in en/*.qmd: bestaat het pad, bestaat de commit,
        en is het Nederlands sindsdien verschoven?

    python3 _tools/en_bouw.py foto --site <map> --uit <bestand>
        een vingerafdruk (sha256 per bestand) van de NEDERLANDSE site: alles
        behalve en/.
    python3 _tools/en_bouw.py vergelijk <foto-voor> <foto-na>
        afloop 0 als ze byte voor byte gelijk zijn, 1 met de lijst als niet.

    python3 _tools/en_bouw.py gelijk --site <map>
        is <map>/en/ (wat de bouw nakeek) gelijk aan en/ in de repo (wat er
        gecommit wordt)? Zo kan de pers niet iets anders leveren dan er
        gekeurd is.

    python3 _tools/en_bouw.py bewaar --naar <map>
    python3 _tools/en_bouw.py herstel --van <map>
        en/, het manifest en git status vóór een run vastleggen, en bij een
        mislukte run precies zo terugzetten — en nameten dat het klopt.

Afloopcodes, huisafspraak: 0 schoon, 1 er is een gat, 2 verkeerd aangeroepen,
3 kon niet kijken. Stilte betekent nooit "goed": elke keuring meldt hoeveel
hij bekeek, met één voorbeeld, ook als alles klopt.
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import urllib.parse

HIER = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HIER)
sys.path.insert(0, HIER)
from tellerregel import tellerstand  # noqa: E402
# De tabel en de stukken van de taalwissel lezen we op één plek, zodat keuring,
# filter en wachtrij nooit twee lezingen van dezelfde tabel hebben.
from taalonderdelen import paren, vol_adres, stuk, pas_toe_los, BASIS  # noqa: E402
LIBS_VAN = "site_libs"      # zo noemt Quarto ze in _site_en/
LIBS_NAAR = "en/libs"       # zo staan ze op de site; Quarto negeert site_libs als bijlage
# Engelse bladzijden die NIET onder en/ staan, maar wel bij de Engelse site horen:
# de cv (staat al lang op /cv-en.html) en de twee Engelse speeltjes uit het menu.
# Hun links worden net zo streng gekeurd, want het Engelse menu wijst ernaar.
ENGELS_BUITEN_EN = ["cv-en.html", "tables/index.html", "speeltjes/solomon-en.html"]
# De werkkopieën van zetters (`claude --worktree`) staan onder .claude/worktrees/,
# elk een volledige kopie van de repo. Geen bron en nooit site: keuring 0 zegt
# het hardop als er toch een in een bouwmap staat, en verder loopt geen keuring
# of vingerafdruk erdoorheen (25-10-2026).
WERKRUIMTE = ".claude"
MANIFEST = os.path.join(REPO, "_tools", "en_manifest.txt")


def zeg(regel: str = "") -> None:
    print(regel, flush=True)


def lees(pad: str) -> str:
    with open(pad, encoding="utf-8", errors="replace") as f:
        return f.read()


def loop(wortel: str):
    """os.walk, maar een map .claude/ gaat hij op geen enkele diepte in. Wie de
    lijst met mappen verder inkort (zoals foto met en/), doet dat op dezelfde lijst."""
    for dp, dn, fs in os.walk(wortel):
        dn[:] = [d for d in dn if d != WERKRUIMTE]
        yield dp, dn, fs


# ---------------------------------------------------- bewaar / herstel ----
# WAAROM. Quarto bouwt een bladzij NAAST zijn bron en verplaatst hem daarna naar
# de uitvoermap. Voor en/about.qmd betekent dat: de gecommitte en/about.html wordt
# overschreven en daarna weggehaald, naar _site_en/en/. Gemeten 25-10-2026:
# na `quarto render --profile en,spook` gaf git status " D en/about.html" en drie
# meer. Tot dan zette stap 4 van publiceer_en.sh ze toevallig terug; viel de run
# eerder om, dan bleven ze weg — en het script beloofde het tegendeel.
# Daarom bewaart de bouw en/ vooraf en zet hem daarna precies terug, en doet
# publiceer_en.sh hetzelfde voor de hele run (met het manifest erbij).
#
# Wat terugzetten betekent: elk bestand dat er bij het bewaren stond, staat er
# weer met dezelfde inhoud (en dezelfde tijd); wat er sindsdien bij kwam, gaat
# weg — dat maakte deze run zelf, want bij het bewaren stond het er niet.
# Een kopie die niet heel is, wordt NIET gebruikt: dan haalt herstel niets weg en
# zet niets terug, en zegt dat (afloop 3). Liever een rommelige repo dan een die
# is "hersteld" vanaf een halve kopie.
BEWAAR_LIJST = "bewaard.json"


def _bestanden(wortel: str) -> dict[str, str]:
    uit = {}
    for dp, _dn, fs in os.walk(wortel):
        for f in fs:
            p = os.path.join(dp, f)
            uit[os.path.relpath(p, wortel)] = p
    return uit


def _sha(p: str) -> str:
    with open(p, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def _git_status() -> list[str] | None:
    r = subprocess.run(["git", "status", "--porcelain=v1", "--untracked-files=all"],
                       cwd=REPO, capture_output=True, text=True)
    return r.stdout.splitlines() if r.returncode == 0 else None


def bewaar(map_: str, met_run: bool) -> dict:
    """Een echte kopie van en/ naar <map_>/en — geen harde link, want Quarto
    schrijft IN het bestand voor hij het verplaatst. Met met_run ook het manifest
    en git status. De lijst (met sha256) wordt als laatste geschreven: zonder
    lijst geen herstel."""
    if os.path.isdir(map_):
        shutil.rmtree(map_)  # onze eigen werkmap onder _site_en_werk/ (gitignored)
    os.makedirs(map_)
    bron = os.path.join(REPO, "en")
    shutil.copytree(bron, os.path.join(map_, "en"), copy_function=shutil.copy2, symlinks=True)
    lijst = {"en": {rel: _sha(p) for rel, p in _bestanden(os.path.join(map_, "en")).items()},
             "manifest": None, "status": None}
    for rel, p in _bestanden(bron).items():   # is de kopie gelijk aan het origineel?
        if lijst["en"].get(rel) != _sha(p):
            raise OSError(f"de kopie van en/{rel} is niet gelijk aan het origineel")
    if met_run:
        if os.path.isfile(MANIFEST):
            shutil.copy2(MANIFEST, os.path.join(map_, "en_manifest.txt"))
            lijst["manifest"] = _sha(os.path.join(map_, "en_manifest.txt"))
        lijst["status"] = _git_status()
    with open(os.path.join(map_, BEWAAR_LIJST), "w", encoding="utf-8") as f:
        json.dump(lijst, f, indent=0, sort_keys=True)
    return lijst


def herstel(map_: str) -> tuple[int, list[str]]:
    """Zet en/ (en, als het bewaard is, het manifest) terug zoals in <map_>, en
    meet na. Geeft (afloop, regels om te zeggen): 0 alles weer zoals het was,
    1 git status verschilt buiten wat hier teruggezet wordt, 3 kon niet."""
    lijst_pad = os.path.join(map_, BEWAAR_LIJST)
    if not os.path.isfile(lijst_pad):
        return 3, [f"FOUT: geen {BEWAAR_LIJST} in {map_} — er is niets bewaard; niets teruggezet, niets weggehaald"]
    lijst = json.load(open(lijst_pad, encoding="utf-8"))
    bewaard, en = os.path.join(map_, "en"), os.path.join(REPO, "en")
    oud = _bestanden(bewaard)
    if {r: _sha(p) for r, p in oud.items()} != lijst["en"]:
        return 3, [f"FOUT: de bewaarde kopie in {map_} is niet heel — niets teruggezet, niets weggehaald"]
    nu = _bestanden(en)
    terug, weg = [], []
    for rel, src in sorted(oud.items()):
        dst = os.path.join(en, rel)
        if rel not in nu or _sha(dst) != lijst["en"][rel]:
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(src, dst)
            terug.append("en/" + rel)
    for rel in sorted(set(nu) - set(oud)):
        os.remove(os.path.join(en, rel))
        weg.append("en/" + rel)
    for dp, _dn, _fs in os.walk(en, topdown=False):
        if dp != en and not os.listdir(dp) and not os.path.isdir(os.path.join(bewaard, os.path.relpath(dp, en))):
            os.rmdir(dp)
    if lijst["manifest"] and (not os.path.isfile(MANIFEST) or _sha(MANIFEST) != lijst["manifest"]):
        shutil.copy2(os.path.join(map_, "en_manifest.txt"), MANIFEST)
        terug.append(os.path.relpath(MANIFEST, REPO))
    # de nameting: niet geloven dat het gelukt is, kijken
    na = {r: _sha(p) for r, p in _bestanden(en).items()}
    anders = ["en/" + r for r in sorted(set(lijst["en"]) ^ set(na))] \
        + ["en/" + r for r in sorted(set(na) & set(lijst["en"])) if na[r] != lijst["en"][r]]
    if lijst["manifest"] and _sha(MANIFEST) != lijst["manifest"]:
        anders.append(os.path.relpath(MANIFEST, REPO))
    regels = [f"{len(terug)} teruggezet, {len(weg)} weggehaald (die maakte deze run zelf); "
              f"nagemeten: {len(na)} bestand(en) onder en/"
              + (" en het manifest" if lijst["manifest"] else "") + f", {len(anders)} anders"]
    regels += [f"  teruggezet: {r}" for r in terug[:10]] + [f"  weggehaald: {r}" for r in weg[:10]]
    if anders:
        return 3, regels + [f"FOUT: na het terugzetten nog anders: {r}" for r in anders[:20]]
    if lijst["status"] is not None:
        nu_status = _git_status()
        if nu_status is None:
            return 3, regels + ["FOUT: git status liep vast — kon niet nameten of de rest van de repo ongemoeid bleef"]
        if nu_status != lijst["status"]:
            bij = [s for s in nu_status if s not in lijst["status"]]
            af = [s for s in lijst["status"] if s not in nu_status]
            return 1, regels + ["LET OP: git status is NIET meer zoals vóór de run — buiten en/ en het manifest, "
                                "dus niet door dit herstel terug te zetten (door deze run, of door iemand anders "
                                "die tegelijk in deze map werkte):"] \
                + [f"  nu wel:  {s}" for s in bij[:20]] + [f"  nu niet: {s}" for s in af[:20]]
        regels.append(f"git status gelijk aan vóór de run ({len(nu_status)} regel(s))")
    return 0, regels


def cmd_bewaar(a) -> int:
    try:
        lijst = bewaar(os.path.abspath(a.naar), met_run=True)
    except OSError as e:
        zeg(f"  FOUT: kon de repo niet bewaren ({e}) — dan kan een mislukte run hem ook niet terugzetten")
        return 3
    zeg(f"  bewaard vóór de run: {len(lijst['en'])} bestand(en) onder en/, "
        + ("het manifest, " if lijst["manifest"] else "geen manifest, ")
        + (f"git status ({len(lijst['status'])} regel(s))" if lijst["status"] is not None else "git status: KON NIET KIJKEN")
        + f" -> {os.path.relpath(os.path.abspath(a.naar), REPO)}")
    return 0 if lijst["status"] is not None else 3


def cmd_herstel(a) -> int:
    code, regels = herstel(os.path.abspath(a.van))
    for r in regels:
        zeg("  " + r)
    return code


# ---------------------------------------------------------------- bouw ----
def cmd_bouw(a) -> int:
    profiel = "en" if a.soort == "echt" else "en,spook"
    if shutil.which("quarto") is None:
        zeg("FOUT: quarto staat niet op het pad — kon niet bouwen")
        return 3
    doel = os.path.join(REPO, "_site_en")
    if os.path.isdir(doel):
        shutil.rmtree(doel)  # bouw-uitvoer, staat in .gitignore; altijd vers
    # Quarto verplaatst wat hij naast de bron bouwt (zie bewaar/herstel hierboven):
    # en/ eerst bewaren, en wat er ook gebeurt daarna precies terugzetten.
    voor_bouw = os.path.join(REPO, "_site_en_werk", "en_voor_bouw")
    try:
        bewaar(voor_bouw, met_run=False)
    except OSError as e:
        zeg(f"  FOUT: kon en/ niet bewaren vóór de bouw ({e}) — niet gebouwd, want Quarto zou hem verplaatsen")
        return 3
    zeg(f"  $ quarto render --profile {profiel}")
    try:
        r = subprocess.run(["quarto", "render", "--profile", profiel], cwd=REPO,
                           capture_output=True, text=True)
    finally:
        h_code, h_regels = herstel(voor_bouw)
        zeg("  en/ in de repo terug zoals vóór de bouw: " + h_regels[0])
        for regel in h_regels[1:]:
            zeg("  " + regel)
    if h_code != 0:
        zeg("  FOUT: en/ in de repo is niet terug zoals vóór de bouw (zie hierboven)")
        return 3
    log = os.path.join(doel, "_bouwlog.txt")
    os.makedirs(doel, exist_ok=True)
    with open(log, "w", encoding="utf-8") as f:
        f.write(r.stdout + "\n" + r.stderr)
    waarsch = [l for l in (r.stdout + r.stderr).splitlines()
               if re.search(r"WARN|ERROR|Unable to resolve", l)]
    if r.returncode != 0:
        zeg(f"  FOUT: de Engelse bouw liep vast (afloop {r.returncode}); log: {log}")
        for l in (r.stderr or r.stdout).splitlines()[-15:]:
            zeg("    " + l)
        return 1
    bladz = sorted(os.path.relpath(os.path.join(dp, f), doel)
                   for dp, _d, fs in os.walk(os.path.join(doel, "en")) for f in fs if f.endswith(".html"))
    zeg(f"  gebouwd: {len(bladz)} Engelse bladzijde(n) onder en/ — bv. {bladz[0] if bladz else '(geen)'}")
    if waarsch:
        # Een waarschuwing van Quarto is hier geen ruis: "Invalid 'lang' value '../en'"
        # en "Unable to resolve link target" waren allebei echte fouten met afloop 0.
        zeg(f"  FOUT: Quarto gaf {len(waarsch)} waarschuwing(en); bij afloop 0 is dat precies de stille soort:")
        for l in waarsch[:10]:
            zeg("    " + l)
        return 1
    if not bladz:
        zeg("  FOUT: geen enkele bladzij onder _site_en/en/ — een lege bouw is geen bouw")
        return 1
    return 0


# ----------------------------------------------------------------- zet ----
def gegenereerd_in_repo(wortel: str = REPO) -> list[str]:
    """Welke bestanden onder <wortel>/en/ maakt deze bouw? Elke .html waarvan in
    de REPO een .qmd naast staat, plus alles onder en/libs/. Niets anders: een
    losse Engelse HTML die een later spoor in en/ zet (een speeltje, een
    hoofdstuk), is niet van ons — die blijft staan, in de repo én in een bouwmap.
    <wortel> is de repo of een gebouwde site (_site, _site_spook); de bronnen
    staan altijd in de repo, dus daar wordt gekeken of er een .qmd is."""
    uit = []
    for dp, _d, fs in os.walk(os.path.join(wortel, "en")):
        rel_dp = os.path.relpath(dp, wortel)
        if rel_dp == LIBS_NAAR or rel_dp.startswith(LIBS_NAAR + os.sep):
            uit += [os.path.join(rel_dp, f) for f in fs]
            continue
        for f in fs:
            if f.endswith(".html") and os.path.exists(os.path.join(REPO, rel_dp, f[:-5] + ".qmd")):
                uit.append(os.path.join(rel_dp, f))
    return sorted(uit)


def cmd_zet(a) -> int:
    bron = os.path.join(REPO, "_site_en")
    if not os.path.isdir(os.path.join(bron, "en")):
        zeg("FOUT: _site_en/en/ bestaat niet — eerst `en_bouw.py bouw`")
        return 2
    naar = os.path.abspath(a.naar)
    if not os.path.isdir(naar):
        zeg(f"FOUT: {naar} bestaat niet — eerst de Nederlandse bouw")
        return 2
    in_repo = os.path.samefile(naar, REPO)
    if not in_repo and not os.path.isfile(os.path.join(naar, "index.html")):
        zeg(f"FOUT: {naar} is geen gebouwde site en niet de repo — eerst de Nederlandse bouw")
        return 2
    doel_en = os.path.join(naar, "en")

    # 1. weg wat de vorige keer door deze bouw gemaakt is, en alleen dat — in de
    #    repo en in een bouwmap op dezelfde manier. Eerst werd een bouwmap hier
    #    helemaal geleegd, en dan verdween een losse Engelse bladzij die een later
    #    spoor onder en/ zet (hij komt als bijlage uit de repo) uit de site die
    #    gekeurd werd: zijn links leken dood, of hij werd niet gekeurd.
    oud = gegenereerd_in_repo(naar)
    for rel in oud:
        os.remove(os.path.join(naar, rel))
    libs = os.path.join(naar, LIBS_NAAR)
    if os.path.isdir(libs):
        shutil.rmtree(libs)
    waar = "repo" if in_repo else os.path.relpath(naar, REPO)
    zeg(f"  {waar}: {len(oud)} oude gegenereerde bestanden onder en/ weggehaald "
        f"(bronnen en losse Engelse bladzijden blijven)")

    # 2. de bladzijden, met hun verwijzingen naar site_libs omgezet
    n_bladz = n_refs = 0
    for dp, _d, fs in os.walk(os.path.join(bron, "en")):
        for f in fs:
            src = os.path.join(dp, f)
            rel = os.path.relpath(src, bron)            # en/...
            dst = os.path.join(naar, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            if f.endswith(".html"):
                s = lees(src)
                # vanaf en/x.html is site_libs "../site_libs/"; vanaf en/a/x.html "../../site_libs/"
                diepte = rel.count("/")                  # en/x.html -> 1
                oud_pref = "../" * diepte + LIBS_VAN + "/"
                nieuw_pref = "../" * (diepte - 1) + "libs/"
                n_refs += s.count(oud_pref)
                s = s.replace(oud_pref, nieuw_pref)
                with open(dst, "w", encoding="utf-8") as g:
                    g.write(s)
                n_bladz += 1
            else:
                shutil.copy2(src, dst)
    # 3. de bibliotheken
    shutil.copytree(os.path.join(bron, LIBS_VAN), os.path.join(naar, LIBS_NAAR))
    n_libs = sum(len(fs) for _dp, _d, fs in os.walk(os.path.join(naar, LIBS_NAAR)))
    zeg(f"  neergezet in {os.path.relpath(naar, REPO) or '.'}/en/: {n_bladz} bladzijde(n), "
        f"{n_refs} verwijzing(en) site_libs → libs, {n_libs} bibliotheekbestand(en)")
    if n_bladz == 0:
        zeg("  FOUT: niets neergezet")
        return 1
    return 0


# ---------------------------------------------------------------- keur ----
REF = re.compile(r'\b(?:href|src)\s*=\s*"([^"]*)"', re.I)
CSS_URL = re.compile(r'url\(\s*["\']?([^"\')]+)["\']?\s*\)', re.I)


def los_op(site: str, pagina: str, ref: str) -> tuple[str, str | None]:
    """Waar komt `ref` op `pagina` uit? Geeft (soort, pad-in-site of None).
    soort: extern | anker | lokaal"""
    r = html.unescape(ref.strip())
    if not r or r.startswith("#"):
        return "anker", None
    if r.startswith(("mailto:", "tel:", "javascript:", "data:")):
        return "extern", None
    if r.startswith(BASIS) or r == BASIS.rstrip("/"):
        r = "/" + r[len(BASIS):]           # een vol countcamp.org-adres moet hier bestaan
    elif re.match(r"^[a-z][a-z0-9+.-]*:", r, re.I) or r.startswith("//"):
        return "extern", None
    r = urllib.parse.unquote(r.split("#")[0].split("?")[0])
    if r.startswith("/"):
        doel = r.lstrip("/")
    else:
        doel = os.path.normpath(os.path.join(os.path.dirname(pagina), r))
    if doel == ".":
        doel = ""
    if doel.startswith(".."):
        return "lokaal", "<buiten de site>/" + doel
    # Een map (ook de wortel, "" — https://countcamp.org/) wordt zijn index.html.
    if doel == "" or r.endswith("/") or os.path.isdir(os.path.join(site, doel)):
        doel = os.path.join(doel, "index.html") if doel else "index.html"
    return "lokaal", doel


def engelse_bladzijden(site: str) -> list[str]:
    uit = []
    for dp, _d, fs in loop(os.path.join(site, "en")):
        for f in fs:
            if f.endswith(".html"):
                uit.append(os.path.relpath(os.path.join(dp, f), site))
    return sorted(uit)


def keur_links(site: str, bladzijden: list[str]) -> tuple[list[str], int, str]:
    gaten, n, voorbeeld = [], 0, ""
    for p in bladzijden:
        tekst = lees(os.path.join(site, p))
        for ref in sorted(set(REF.findall(tekst))):
            soort, doel = los_op(site, p, ref)
            if soort != "lokaal":
                continue
            n += 1
            if not os.path.isfile(os.path.join(site, doel)):
                gaten.append(f"{p}  ->  {ref}  (zoekt {doel})")
            elif not voorbeeld:
                voorbeeld = f"{p} -> {ref}"
    # en de css onder en/libs: lettertypes en plaatjes die de stijlbladen laden
    for dp, _d, fs in os.walk(os.path.join(site, LIBS_NAAR)):
        for f in fs:
            if not f.endswith(".css"):
                continue
            css = os.path.relpath(os.path.join(dp, f), site)
            for ref in sorted(set(CSS_URL.findall(lees(os.path.join(site, css))))):
                soort, doel = los_op(site, css, ref)
                if soort != "lokaal":
                    continue
                n += 1
                if not os.path.isfile(os.path.join(site, doel)):
                    gaten.append(f"{css}  ->  url({ref})  (zoekt {doel})")
    return gaten, n, voorbeeld


# ------------------------------------------------ bijlagen uit het lab ----
# De Engelse boekbladzijden worden in countcamp_lab gedrukt (boek/publiceer.sh
# --en) en komen hier als BIJLAGE onder en/book/, precies zoals de Nederlandse
# onder manuscript/: een kant-en-klare html, met de bezoekersteller erin en zonder
# bron in deze repo. Voorgesteld door spoor en_h0 (countcamp_lab/boek/en/
# VOORSTEL_site_en_bouw.patch), met de hand overgezet door spoor en_boekpers
# (25-10-2026), want deze code was sindsdien veranderd.
#
# Herkenbaar aan de stempel die alleen de pers van het lab zet, als laatste regel
# (pub_stempel_zet in boek/_tools/publicatie/_gemeenschappelijk.sh):
#     <!-- countcamp-publicatie H0 bron-hash=<sha256> geleverd=2026-10-25T05:12:00 -->
# Zo'n bladzij is geen wees (zijn bron staat in het lab), en hij staat in de
# spooksite ZOALS HIJ LIVE KOMT. Hij krijgt daarom in beide soorten de merken van
# de echte site: teller, geen noindex, geen balk -- net als manuscript/h0.html in
# de Nederlandse spooksite. Links, taal, tweelingen en werkbriefjes: gewoon gekeurd.
#
# STRENG, met opzet. Een stempel is een bewering, en deze keuring kan de bron niet
# zien. Wat hij wel kan zien, eist hij allemaal:
#   * de bladzij staat direct onder en/book/ -- alleen daar zet de lab-pers iets neer;
#   * na de laatste </html> staan alleen stempelregels, en ervóór geen enkele;
#   * elke stempelregel heeft precies de vorm hierboven: 64 hextekens en een tijd;
#   * de laatste is van déze bladzij: H0 hoort bij h0.html, dankwoord bij dankwoord.html.
# Wie iets draagt dat op een stempel lijkt en niet klopt, is een GAT -- geen
# gewone bladzij. Anders zou een halve stempel op de echte site alleen de
# wees-keuring missen, en verder overal doorkomen. Of de hash ook bij de bron in
# het lab hoort, ziet pas wie het lab erbij heeft: dat rekent
# _tools/pers_en_boek.sh na, met pub_bron_hash van het lab zelf.
# Gemeten 25-10-2026 op de veertien gestempelde Nederlandse boekbladzijden onder
# manuscript/: elk precies één stempel, na </html>, en geen ervóór.
LAB_MAP = "en/book"
LAB_MERK = "countcamp-publicatie"
LAB_STEMPEL = re.compile(r"<!-- countcamp-publicatie (?P<naam>[A-Za-z0-9_]+) bron-hash=[0-9a-f]{64} "
                         r"geleverd=\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d -->")


def lab_doelnaam(naam: str) -> str:
    """De bladzij bij een stempelnaam: H0 -> h0.html, dankwoord -> dankwoord.html.
    Dezelfde regel als pub_doelnaam in het lab."""
    return (naam.lower() if re.fullmatch(r"H\d{1,2}", naam) else naam) + ".html"


def uit_het_lab(p: str, tekst: str) -> tuple[bool, str]:
    """Is <p> (sitepad) een bijlage uit het lab? (True, "") als de stempel klopt;
    (False, "") als er geen stempel is -- dan is het een gewone bladzij; en
    (False, reden) als er iets staat dat op een stempel lijkt en niet klopt."""
    if LAB_MERK not in tekst:
        return False, ""
    wat = f"{p}: draagt een stempel van de lab-pers"
    if os.path.dirname(p) != LAB_MAP:
        return False, f"{wat}, maar staat niet direct onder {LAB_MAP}/ — alleen daar zet de lab-pers bladzijden neer"
    eind = tekst.rfind("</html>")
    regels = [r.strip() for r in tekst[eind + len("</html>"):].splitlines() if r.strip()] if eind >= 0 else []
    if eind < 0 or not regels or LAB_MERK in tekst[:eind]:
        return False, f"{wat} die niet (alleen) na de laatste </html> staat, waar de pers hem zet"
    for r in regels:
        if not LAB_STEMPEL.fullmatch(r):
            return False, f"{wat} die niet de vorm van de pers heeft (64 hextekens, een tijd): {r[:100]}"
    naam = LAB_STEMPEL.fullmatch(regels[-1]).group("naam")
    if lab_doelnaam(naam) != os.path.basename(p):
        return False, f"{wat} voor {naam}, en die hoort bij {LAB_MAP}/{lab_doelnaam(naam)}"
    return True, ""


def merken(tekst: str) -> dict:
    return {
        "noindex": bool(re.search(r'name="robots"\s+content="noindex', tekst)),
        "balk": "spookbalk" in tekst,
        "teller": tellerstand(tekst),
    }


def cmd_keur(a) -> int:
    site = os.path.abspath(a.site)
    if not os.path.isfile(os.path.join(site, "index.html")):
        zeg(f"FOUT: {site} is geen gebouwde site (geen index.html) — kon niet kijken")
        return 3
    gaten: list[str] = []
    en_bladz = engelse_bladzijden(site)
    tabel = paren()
    nl_tweelingen = [p["nl"] for p in tabel]
    buiten = [p for p in ENGELS_BUITEN_EN if os.path.isfile(os.path.join(site, p))]
    for p in ENGELS_BUITEN_EN:
        if p not in buiten:
            gaten.append(f"Engelse bladzij buiten en/ ontbreekt: {p}")
    zeg(f"  bekeken: {len(en_bladz)} bladzijde(n) onder en/, {len(buiten)} Engelse daarbuiten, "
        f"{len(nl_tweelingen)} Nederlandse met tweeling")
    if not en_bladz:
        gaten.append("geen enkele Engelse bladzij onder en/")

    # 0. werkruimte: een werkkopie van een zetter (.claude/) hoort nooit in een
    #    site. Eén gat per map, met een voorbeeld, en verder loopt geen keuring
    #    erdoorheen. Op 25-10-2026 kwam hij er via de bijlage-globs in, en toen
    #    leek het op dertien losse taalbalkfouten in bladzijden die niet van deze
    #    site waren — de echte oorzaak stond nergens.
    werk = []
    for dp, dn, _fs in os.walk(site):
        if WERKRUIMTE in dn:
            w = os.path.join(dp, WERKRUIMTE)
            inhoud = sorted(os.path.relpath(os.path.join(a, f), site) for a, _b, fs in os.walk(w) for f in fs)
            werk.append(f"werkruimte in de site: {os.path.relpath(w, site)}/ met {len(inhoud)} bestand(en)"
                        + (f", bv. {inhoud[0]}" if inhoud else "")
                        + ' — werkkopieën van zetters horen in geen enkele bouw (_quarto-nl.yml: "!.claude/**")')
            dn.remove(WERKRUIMTE)
    zeg(f"  werkruimte: {len(werk)} map(pen) {WERKRUIMTE}/ in de site"
        + (f" — {werk[0].split(': ', 1)[1].split(' —')[0]}" if werk else " (moet 0)"))
    gaten += werk

    # 1. links — elke href en src
    te_keuren = sorted(set(en_bladz + buiten + [p for p in nl_tweelingen if os.path.isfile(os.path.join(site, p))]))
    lgaten, n, vb = keur_links(site, te_keuren)
    zeg(f"  links: {n} lokale verwijzing(en) op {len(te_keuren)} bladzijde(n) + en/libs-css, "
        f"{len(lgaten)} komen nergens uit" + (f" — bv. {vb}" if vb else ""))
    gaten += lgaten

    # 1b. bijlagen uit het lab (zie LAB_STEMPEL): welke bladzijden onder en/book/
    #     komen kant-en-klaar uit de pers van het lab, en draagt iemand een stempel
    #     die niet klopt?
    lab, fout_st = [], []
    for p in en_bladz:
        ja, reden = uit_het_lab(p, lees(os.path.join(site, p)))
        if ja:
            lab.append(p)
        elif reden:
            fout_st.append(reden)
    zeg(f"  uit het lab: {len(lab)} bladzij(den) met de stempel van de lab-pers, {len(fout_st)} met een stempel "
        f"die niet klopt" + (f" — bv. {lab[0]}" if lab else f" (gezocht onder {LAB_MAP}/)"))
    gaten += fout_st
    #     De zijbalk van een lab-bladzij noemt zijn hoofdstukken in JavaScript
    #     ({ f: "h0.html", ... } in de lijst CH, uit het lab: boek/en/_maak_afterbody_en.py),
    #     en de linkkeuring hieronder leest alleen href= en src=. Een zijbalk die naar
    #     een hoofdstuk wijst dat hier (nog) niet staat — het lab heeft H1_en.qmd al,
    #     de site h1.html nog niet — zou dus zonder één gat live gaan (gemeten
    #     25-10-2026 op en/book/h0.html: nul statische links naar een ander hoofdstuk).
    #     Geen enkele regel in de lijst is óók een gat: dan kan niemand het nakijken.
    fout_zb, n_zb = [], 0
    for p in lab:
        doelen = re.findall(r'\{\s*f:\s*"([^"]+)"', lees(os.path.join(site, p)))
        n_zb += len(doelen)
        if not doelen:
            fout_zb.append(f"{p}: de zijbalk noemt geen enkel hoofdstuk ({{ f: \"…\" }}) — niet na te kijken; "
                           f"veranderde de zijbalk in het lab (boek/en/_maak_afterbody_en.py)?")
        for f in doelen:
            if not os.path.isfile(os.path.join(site, os.path.dirname(p), f)):
                fout_zb.append(f"{p}: de zijbalk wijst naar {f}, en die staat niet in {LAB_MAP}/ — "
                               f"pers dat hoofdstuk mee, of pers dit opnieuw zonder")
    if lab:
        zeg(f"  zijbalk uit het lab: {n_zb} hoofdstukverwijzing(en) op {len(lab)} bladzij(den), "
            f"{len(fout_zb)} fout")
    gaten += fout_zb

    # 2. merktekens: is een proefdruk een proefdruk en de echte site de echte?
    # Op de Engelse bladzijden onder en/ — die maakt deze bouw. De rest maakt de
    # Nederlandse ronde, en daar kijkt naar_buiten.sh naar.
    # Een bijlage uit het lab staat in de spooksite zoals hij live komt (zie
    # LAB_STEMPEL), dus die krijgt in BEIDE soorten de merken van de echte site.
    fout_merk = []
    for p in en_bladz:
        m = merken(lees(os.path.join(site, p)))
        if a.soort == "echt" or p in lab:
            waar = "op de echte site" if a.soort == "echt" else \
                "in de spooksite, als bijlage uit het lab die er moet staan zoals hij live komt"
            if m["noindex"]: fout_merk.append(f"{p}: draagt noindex {waar}")
            if m["balk"]: fout_merk.append(f"{p}: draagt de proefdrukbalk {waar}")
            if m["teller"] != "geteld": fout_merk.append(f"{p}: bezoekersteller {m['teller']} {waar}")
        else:
            if not m["noindex"]: fout_merk.append(f"{p}: proefdruk zonder noindex")
            if not m["balk"]: fout_merk.append(f"{p}: proefdruk zonder balk")
            if m["teller"] != "geen": fout_merk.append(f"{p}: proefdruk met bezoekersteller ({m['teller']})")
    zeg(f"  merktekens ({a.soort}): {len(en_bladz)} bladzijde(n), {len(fout_merk)} fout"
        + (f"; {len(lab)} uit het lab gekeurd als echte site, zoals het Nederlandse boek — bv. {lab[0]}"
           if lab and a.soort == "spook" else ""))
    gaten += fout_merk

    # 3. taal: <html lang> op elke Engelse bladzij
    fout_lang = []
    for p in en_bladz + buiten:
        m = re.search(r'<html[^>]*\blang="([^"]*)"', lees(os.path.join(site, p)))
        if not m or not m.group(1).startswith("en"):
            fout_lang.append(f"{p}: <html lang=\"{m.group(1) if m else '?'}\">")
    zeg(f"  taal: {len(en_bladz) + len(buiten)} Engelse bladzijde(n), {len(fout_lang)} zonder lang=\"en…\"")
    gaten += fout_lang

    # 4. tweelingen: beide kanten bestaan, dragen dezelfde hreflang-set, en het knopje wijst naar de ander
    fout_tw = []
    for p in tabel:
        for kant, ander in (("nl", "en"), ("en", "nl")):
            pad = os.path.join(site, p[kant])
            if not os.path.isfile(pad):
                fout_tw.append(f"tweeling {p['nl']} ↔ {p['en']}: {p[kant]} bestaat niet")
                continue
            t = lees(pad)
            verwacht = {("nl", vol_adres(p["nl"])), ("en", vol_adres(p["en"])), ("x-default", vol_adres(p["nl"]))}
            gevonden = set(re.findall(r'<link rel="alternate" hreflang="([^"]+)" href="([^"]+)"', t))
            if gevonden != verwacht:
                fout_tw.append(f"{p[kant]}: hreflang {sorted(gevonden)} in plaats van {sorted(verwacht)}")
            if p["wissel"] in ("auto", "los"):
                knop = re.search(r'<nav class="taalwissel[^"]*"[^>]*>.*?</nav>', t, re.S)
                if not knop:
                    fout_tw.append(f"{p[kant]}: geen taalknopje")
                else:
                    hrefs = re.findall(r'href="([^"]+)"', knop.group(0))
                    doelen = [los_op(site, p[kant], h)[1] for h in hrefs]
                    if doelen != [p[ander]]:
                        fout_tw.append(f"{p[kant]}: taalknopje wijst naar {doelen}, verwacht [{p[ander]}]")
    zeg(f"  tweelingen: {len(tabel)} paar uit taalparen.tsv, {len(fout_tw)} fout"
        + (f" — bv. {tabel[0]['nl']} ↔ {tabel[0]['en']}" if tabel else ""))
    gaten += fout_tw

    # 4b. de taalbalk (24-10-2026): op ELKE Nederlandse bladzij met een tweeling
    #     precies één keer, en op geen enkele andere bladzij van de site — ook niet
    #     op een Engelse. Waarom dat tweede: de wachtrij laat de balk, het knopje en
    #     hreflang op elke Nederlandse bladzij weg voor ze vergelijkt (nl_negeer); ze
    #     ziet dus niet of ze op een bladzij ZONDER tweeling verschijnen. Dat kan
    #     alleen hier, waar de tabel bekend is. Op elke .html van de site.
    balk = stuk("balk.html")
    merken_taal = ("/* taalbalk:", 'class="taalwissel', 'rel="alternate" hreflang=')
    nl_kant = {p["nl"] for p in tabel}
    in_tabel = nl_kant | {p["en"] for p in tabel}
    fout_b, n_b, n_html = [], 0, 0
    for dp, _d, fs in loop(site):
        for f in fs:
            if not f.endswith(".html"):
                continue
            rel = os.path.relpath(os.path.join(dp, f), site)
            if rel.startswith(LIBS_NAAR + os.sep):
                continue
            n_html += 1
            t = lees(os.path.join(dp, f))
            k = t.count(balk)
            if rel in nl_kant:
                n_b += k == 1
                if k != 1:
                    fout_b.append(f"{rel}: Nederlandse tweeling met de taalbalk {k} keer (hoort 1)"
                                  + (" — een ANDERE versie van de balk?" if k == 0 and "/* taalbalk:" in t else ""))
            elif k or "/* taalbalk:" in t:
                fout_b.append(f"{rel}: draagt de taalbalk maar is geen Nederlandse bladzij met tweeling")
            elif rel not in in_tabel and not rel.startswith("en" + os.sep):
                gevonden = [m for m in merken_taal if m in t]
                if gevonden:
                    fout_b.append(f"{rel}: geen tweeling in taalparen.tsv, maar draagt {gevonden[0]!r}")
    zeg(f"  taalbalk: {n_html} .html-bladzijde(n) nagelopen, {n_b} van de {len(nl_kant)} Nederlandse tweelingen "
        f"dragen hem, {len(fout_b)} fout" + (f" — bv. {sorted(nl_kant)[0]}" if nl_kant else ""))
    gaten += fout_b

    # 4c. de losse bladzijden (tabellen/, tables/, solomon) staan in de site zoals
    #     taalonderdelen.py ze maakt — anders draagt de kopie uit het lab haar
    #     knopje niet, of een oude versie van de balk.
    fout_l, n_l = [], 0
    for p in tabel:
        if p["wissel"] not in ("los", "los-eigen"):
            continue
        n_l += 1
        for kant in ("nl", "en"):
            pad = os.path.join(site, p[kant])
            if os.path.isfile(pad) and pas_toe_los(lees(pad), p[kant]) != lees(pad):
                fout_l.append(f"{p[kant]}: de taalstukken staan er niet (goed) in — python3 _tools/taalonderdelen.py los")
    zeg(f"  losse tweelingen: {n_l} paar, {len(fout_l)} fout")
    gaten += fout_l

    # 5. contactgegevens: elk mailadres en elke IBAN op een Engelse bladzij staat
    #    ook op zijn Nederlandse tweeling. Een tikfout in een rekeningnummer is
    #    het soort fout dat niemand ziet tot het geld nergens aankomt.
    fout_c, n_c = [], 0
    # IBAN: landcode, twee cijfers, dan groepjes van hooguit vier (de laatste mag
    # korter: "… 1306 05"). Een te krappe vorm zou het staartje missen, en een
    # tikfout zit net zo goed in het staartje.
    iban = re.compile(r"\b[A-Z]{2}\d{2}(?: ?[A-Z0-9]{1,4}){2,8}\b")
    # NIET in data:-adressen zoeken (25-10-2026, spoor en_boekpers). Een bladzij uit
    # het lab sluit zijn figuren en lettertypes in als base64 (embed-resources), en
    # daarin vond dit patroon op en/book/h0.html vijf "rekeningnummers", alle vijf in
    # een data:-adres. Drie kwamen door omdat hetzelfde lettertype ook in de
    # Nederlandse h0 zit; "ZJ11OT" en "JP38UR0" zaten in de Engelse figuur en
    # werden twee gaten die er niet waren. Een rekeningnummer staat in de tekst.
    zonder_data = lambda t: re.sub(r"data:[^\"')\s]*", "", t)  # noqa: E731
    for p in tabel:
        en_p, nl_p = os.path.join(site, p["en"]), os.path.join(site, p["nl"])
        if not (os.path.isfile(en_p) and os.path.isfile(nl_p)):
            continue
        t_en, t_nl = zonder_data(lees(en_p)), zonder_data(lees(nl_p))
        for adres in set(re.findall(r'mailto:([^"?]+)', t_en)):
            n_c += 1
            if adres not in t_nl:
                fout_c.append(f"{p['en']}: mailadres {adres} staat niet op {p['nl']}")
        for nr in set(iban.findall(t_en)):
            n_c += 1
            if nr not in t_nl:
                fout_c.append(f"{p['en']}: rekeningnummer {nr} staat niet op {p['nl']}")
    zeg(f"  contactgegevens: {n_c} mailadres(sen)/IBAN(s) nagelopen tegen de Nederlandse tweeling, {len(fout_c)} wijken af")
    gaten += fout_c

    # 6. werkbriefjes: geen MIEKE:/BEN:-regel op de echte of de proef-site
    fout_w = [p for p in en_bladz if re.search(r"<!--\s*(MIEKE|BEN:|Vertaling van)", lees(os.path.join(site, p)))]
    zeg(f"  werkbriefjes: {len(en_bladz)} bladzijde(n), {len(fout_w)} met een MIEKE-/BEN-notitie in de HTML")
    gaten += [f"{p}: werkbriefje in de gepubliceerde HTML" for p in fout_w]

    # 6b. de Nederlandse zoekindex: het knopje mag er niet in. Gemeten 24-10-2026:
    #     stond het als eerste blok, dan werd de zoektekst van index.html "NL·EN"
    #     in plaats van de tagline. taalwissel.lua zet het daarom ná het eerste
    #     blok; deze keuring merkt het als dat ooit niet meer lukt.
    zj = os.path.join(site, "search.json")
    if os.path.isfile(zj):
        try:
            idx = json.load(open(zj, encoding="utf-8"))
        except ValueError:
            idx = None
            gaten.append("search.json is geen leesbare JSON — kon de zoekindex niet nakijken")
        if idx is not None:
            lek = sorted({d.get("href", "?") for d in idx if re.search(r"NL\s*·\s*EN", d.get("text", ""))})
            zeg(f"  zoekindex: {len(idx)} item(s) in search.json, {len(lek)} met het taalknopje erin"
                + (f" — bv. {lek[0]}" if lek else ""))
            gaten += [f"search.json: het taalknopje staat in de zoektekst van {h}" for h in lek]
    else:
        zeg("  zoekindex: geen search.json in deze site — niet nagekeken")

    # 7. verweesd: een door Quarto gebouwde bladzij onder en/ zonder bron. Die
    #    haalt dit script niet zelf weg (huisregel 9: weghalen is niet aan een
    #    zetter); hij weigert en zegt welke het is.
    #    Een bijlage uit het lab heeft zijn bron daar, niet hier (zie LAB_STEMPEL).
    wees = []
    for p in en_bladz:
        if p.startswith(LIBS_NAAR + "/") or p in lab:
            continue
        t = lees(os.path.join(site, p))
        if 'name="generator" content="quarto' in t and not os.path.isfile(os.path.join(REPO, p[:-5] + ".qmd")):
            wees.append(f"{p}: gebouwd door Quarto, maar {p[:-5]}.qmd bestaat niet meer — haal hem weg of zet de bron terug")
    zeg(f"  verweesd: {len(wees)} Quarto-bladzij(den) onder en/ zonder bron"
        + (f" ({len(lab)} uit het lab niet meegeteld: hun bron staat daar)" if lab else ""))
    gaten += wees

    zeg()
    if gaten:
        zeg(f"  {len(gaten)} GAT(EN):")
        for g in gaten:
            zeg("    - " + g)
        return 1
    zeg("  geen gaten")
    return 0


# ------------------------------------------------------------- bronnen ----
def cmd_bronnen(a) -> int:
    """nl_bron: <pad>@<commit> in de kop van elke en/*.qmd."""
    fout, verschoven, n = [], [], 0
    bronnen = sorted(os.path.join(dp, f) for dp, _d, fs in os.walk(os.path.join(REPO, "en"))
                     for f in fs if f.endswith(".qmd"))
    for q in bronnen:
        rel = os.path.relpath(q, REPO)
        kop = lees(q).split("\n---", 1)[0]
        m = re.search(r"^nl_bron:\s*(\S+)@([0-9a-f]{7,40})\s*$", kop, re.M)
        if not m:
            fout.append(f"{rel}: geen nl_bron: <pad>@<commit> in de kop")
            continue
        n += 1
        pad, c = m.group(1), m.group(2)
        if not os.path.isfile(os.path.join(REPO, pad)):
            fout.append(f"{rel}: nl_bron {pad} bestaat niet")
            continue
        r = subprocess.run(["git", "cat-file", "-e", f"{c}^{{commit}}"], cwd=REPO, capture_output=True)
        if r.returncode != 0:
            fout.append(f"{rel}: nl_bron-commit {c} bestaat niet in deze repo")
            continue
        r = subprocess.run(["git", "log", "--format=%h %ad %s", "--date=short", f"{c}..HEAD", "--", pad],
                           cwd=REPO, capture_output=True, text=True)
        if r.returncode != 0:
            fout.append(f"{rel}: git log op {pad} liep vast — kon niet kijken")
            continue
        if r.stdout.strip():
            regels = r.stdout.strip().splitlines()
            verschoven.append(f"{rel}: {pad} veranderde {len(regels)} keer na {c} — laatste: {regels[0]}")
    zeg(f"  nl_bron: {len(bronnen)} Engelse bron(nen), {n} met stempel, {len(fout)} fout, "
        f"{len(verschoven)} waarvan het Nederlands sindsdien bewoog")
    for f in fout:
        zeg("    FOUT: " + f)
    for v in verschoven:
        # Geen weigering: een vertaling van gisteren is beter dan geen. Wel hardop,
        # want de lezer van de Engelse bladzij leest dan iets wat het Nederlands niet meer zegt.
        zeg("    BIJ TE WERKEN: " + v)
    return 1 if fout else 0


# ---------------------------------------------------- foto / vergelijk ----
def cmd_foto(a) -> int:
    site = os.path.abspath(a.site)
    if not os.path.isfile(os.path.join(site, "index.html")):
        zeg(f"FOUT: {site} is geen gebouwde site — kon niet kijken")
        return 3
    m = {}
    # zonder .claude/: een werkkopie van een ander spoor kan tussen voor en na
    # veranderen, en keuring 0 houdt hem al tegen
    for dp, dn, fs in loop(site):
        rel_dp = os.path.relpath(dp, site)
        if rel_dp == "en" or rel_dp.startswith("en" + os.sep):
            dn[:] = []
            continue
        for f in fs:
            p = os.path.join(dp, f)
            with open(p, "rb") as g:
                m[os.path.relpath(p, site)] = hashlib.sha256(g.read()).hexdigest()
    with open(a.uit, "w", encoding="utf-8") as f:
        json.dump(m, f, indent=0, sort_keys=True)
    zeg(f"  foto: {len(m)} Nederlandse bestanden (alles behalve en/) -> {os.path.relpath(a.uit, REPO)}")
    return 0 if m else 3


def cmd_vergelijk(a) -> int:
    A, B = json.load(open(a.voor)), json.load(open(a.na))
    weg = sorted(set(A) - set(B))
    bij = sorted(set(B) - set(A))
    anders = sorted(k for k in set(A) & set(B) if A[k] != B[k])
    zeg(f"  nederlands ongemoeid: voor {len(A)}, na {len(B)} bestanden — "
        f"{len(weg)} weg, {len(bij)} bij, {len(anders)} anders")
    for k in weg[:20]: zeg(f"    weg:    {k}")
    for k in bij[:20]: zeg(f"    bij:    {k}")
    for k in anders[:20]: zeg(f"    anders: {k}")
    return 1 if (weg or bij or anders) else 0


def cmd_gelijk(a) -> int:
    site = os.path.abspath(a.site)
    ongelijk, n = [], 0
    for rel in gegenereerd_in_repo():
        n += 1
        x, y = os.path.join(REPO, rel), os.path.join(site, rel)
        if not os.path.isfile(y):
            ongelijk.append(f"{rel}: staat in de repo maar niet in {os.path.relpath(site, REPO)}")
            continue
        with open(x, "rb") as f1, open(y, "rb") as f2:
            if f1.read() != f2.read():
                ongelijk.append(f"{rel}: repo en {os.path.relpath(site, REPO)} verschillen")
    for p in engelse_bladzijden(site):
        if not os.path.isfile(os.path.join(REPO, p)):
            ongelijk.append(f"{p}: gekeurd in {os.path.relpath(site, REPO)}, maar staat niet in de repo")
    zeg(f"  gekeurd = geleverd: {n} gegenereerde bestanden in en/ vergeleken met {os.path.relpath(site, REPO)}/en, {len(ongelijk)} verschil(len)")
    for o in ongelijk[:20]:
        zeg("    " + o)
    return 1 if (ongelijk or n == 0) else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("bouw"); b.add_argument("--soort", choices=["echt", "spook"], required=True)
    z = sub.add_parser("zet"); z.add_argument("--naar", required=True)
    k = sub.add_parser("keur"); k.add_argument("--site", required=True); k.add_argument("--soort", choices=["echt", "spook"], required=True)
    sub.add_parser("bronnen")
    f = sub.add_parser("foto"); f.add_argument("--site", required=True); f.add_argument("--uit", required=True)
    v = sub.add_parser("vergelijk"); v.add_argument("voor"); v.add_argument("na")
    g = sub.add_parser("gelijk"); g.add_argument("--site", required=True)
    bw = sub.add_parser("bewaar"); bw.add_argument("--naar", required=True)
    hs = sub.add_parser("herstel"); hs.add_argument("--van", required=True)
    a = ap.parse_args()
    # Afgeschoten (TERM, HUP) wordt een gewone afloop, zodat `finally` in de bouw
    # en/ nog terugzet. Zonder dit stopt Python meteen en blijft en/ weg.
    for sig in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, lambda nr, _f: sys.exit(128 + nr))
    return {"bouw": cmd_bouw, "zet": cmd_zet, "keur": cmd_keur, "bronnen": cmd_bronnen,
            "foto": cmd_foto, "vergelijk": cmd_vergelijk, "gelijk": cmd_gelijk,
            "bewaar": cmd_bewaar, "herstel": cmd_herstel}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
