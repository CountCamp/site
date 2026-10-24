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
        contactgegevens, verweesde bladzijden, werkbriefjes.

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
import subprocess
import sys
import urllib.parse

HIER = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HIER)
sys.path.insert(0, HIER)
from tellerregel import tellerstand  # noqa: E402

PAREN = os.path.join(HIER, "taalparen.tsv")
BASIS = "https://countcamp.org/"
LIBS_VAN = "site_libs"      # zo noemt Quarto ze in _site_en/
LIBS_NAAR = "en/libs"       # zo staan ze op de site; Quarto negeert site_libs als bijlage
# Engelse bladzijden die NIET onder en/ staan, maar wel bij de Engelse site horen:
# de cv (staat al lang op /cv-en.html) en de twee Engelse speeltjes uit het menu.
# Hun links worden net zo streng gekeurd, want het Engelse menu wijst ernaar.
ENGELS_BUITEN_EN = ["cv-en.html", "tables/index.html", "speeltjes/solomon-en.html"]


def zeg(regel: str = "") -> None:
    print(regel, flush=True)


def lees(pad: str) -> str:
    with open(pad, encoding="utf-8", errors="replace") as f:
        return f.read()


def paren() -> list[dict]:
    """De tabel, zoals taalwissel.lua hem leest."""
    uit = []
    for nr, regel in enumerate(lees(PAREN).splitlines(), 1):
        if not regel.strip() or regel.lstrip().startswith("#"):
            continue
        v = [x.strip() for x in regel.split("\t")]
        if len(v) < 3 or v[2] not in ("auto", "eigen"):
            raise SystemExit(f"FOUT: {PAREN} regel {nr} is geen 'nl<TAB>en<TAB>auto|eigen': {regel!r}")
        uit.append({"nl": v[0], "en": v[1], "wissel": v[2]})
    return uit


def vol_adres(sitepad: str) -> str:
    return BASIS + re.sub(r"index\.html$", "", sitepad)


# ---------------------------------------------------------------- bouw ----
def cmd_bouw(a) -> int:
    profiel = "en" if a.soort == "echt" else "en,spook"
    if shutil.which("quarto") is None:
        zeg("FOUT: quarto staat niet op het pad — kon niet bouwen")
        return 3
    doel = os.path.join(REPO, "_site_en")
    if os.path.isdir(doel):
        shutil.rmtree(doel)  # bouw-uitvoer, staat in .gitignore; altijd vers
    zeg(f"  $ quarto render --profile {profiel}")
    r = subprocess.run(["quarto", "render", "--profile", profiel], cwd=REPO,
                       capture_output=True, text=True)
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
    for dp, _d, fs in os.walk(os.path.join(site, "en")):
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

    # 1. links — elke href en src
    te_keuren = sorted(set(en_bladz + buiten + [p for p in nl_tweelingen if os.path.isfile(os.path.join(site, p))]))
    lgaten, n, vb = keur_links(site, te_keuren)
    zeg(f"  links: {n} lokale verwijzing(en) op {len(te_keuren)} bladzijde(n) + en/libs-css, "
        f"{len(lgaten)} komen nergens uit" + (f" — bv. {vb}" if vb else ""))
    gaten += lgaten

    # 2. merktekens: is een proefdruk een proefdruk en de echte site de echte?
    # Op de Engelse bladzijden onder en/ — die maakt deze bouw. De rest maakt de
    # Nederlandse ronde, en daar kijkt naar_buiten.sh naar.
    fout_merk = []
    for p in en_bladz:
        m = merken(lees(os.path.join(site, p)))
        if a.soort == "echt":
            if m["noindex"]: fout_merk.append(f"{p}: draagt noindex op de echte site")
            if m["balk"]: fout_merk.append(f"{p}: draagt de proefdrukbalk op de echte site")
            if m["teller"] != "geteld": fout_merk.append(f"{p}: bezoekersteller {m['teller']}")
        else:
            if not m["noindex"]: fout_merk.append(f"{p}: proefdruk zonder noindex")
            if not m["balk"]: fout_merk.append(f"{p}: proefdruk zonder balk")
            if m["teller"] != "geen": fout_merk.append(f"{p}: proefdruk met bezoekersteller ({m['teller']})")
    zeg(f"  merktekens ({a.soort}): {len(en_bladz)} bladzijde(n), {len(fout_merk)} fout")
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
            if p["wissel"] == "auto":
                knop = re.search(r'<nav class="taalwissel"[^>]*>.*?</nav>', t, re.S)
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

    # 5. contactgegevens: elk mailadres en elke IBAN op een Engelse bladzij staat
    #    ook op zijn Nederlandse tweeling. Een tikfout in een rekeningnummer is
    #    het soort fout dat niemand ziet tot het geld nergens aankomt.
    fout_c, n_c = [], 0
    # IBAN: landcode, twee cijfers, dan groepjes van hooguit vier (de laatste mag
    # korter: "… 1306 05"). Een te krappe vorm zou het staartje missen, en een
    # tikfout zit net zo goed in het staartje.
    iban = re.compile(r"\b[A-Z]{2}\d{2}(?: ?[A-Z0-9]{1,4}){2,8}\b")
    for p in tabel:
        en_p, nl_p = os.path.join(site, p["en"]), os.path.join(site, p["nl"])
        if not (os.path.isfile(en_p) and os.path.isfile(nl_p)):
            continue
        t_en, t_nl = lees(en_p), lees(nl_p)
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
    wees = []
    for p in en_bladz:
        if p.startswith(LIBS_NAAR + "/"):
            continue
        t = lees(os.path.join(site, p))
        if 'name="generator" content="quarto' in t and not os.path.isfile(os.path.join(REPO, p[:-5] + ".qmd")):
            wees.append(f"{p}: gebouwd door Quarto, maar {p[:-5]}.qmd bestaat niet meer — haal hem weg of zet de bron terug")
    zeg(f"  verweesd: {len(wees)} Quarto-bladzij(den) onder en/ zonder bron")
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
    for dp, dn, fs in os.walk(site):
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
    a = ap.parse_args()
    return {"bouw": cmd_bouw, "zet": cmd_zet, "keur": cmd_keur, "bronnen": cmd_bronnen,
            "foto": cmd_foto, "vergelijk": cmd_vergelijk, "gelijk": cmd_gelijk}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
