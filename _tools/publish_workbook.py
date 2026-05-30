#!/usr/bin/env python3
"""
publish_workbook.py — ingest een gerenderd Quarto-werkboek in de CountCamp-site.

Waarom dit script bestaat
-------------------------
Een Quarto-werkboek (bv. OZP 1) wordt los gerenderd naar zijn eigen `_site/`.
Dat kunnen we niet 1-op-1 in de countcamp_site-repo plakken, om drie redenen:

  1. Quarto negeert mappen die met `_` beginnen (`_common/`) en de map `site_libs/`
     wordt niet als project-bron meegekopieerd. → hernoemen naar `common/` en `libs/`
     en alle verwijzingen herschrijven.
  2. De werkboek-render bevat per hoofdstuk één REDUNDANTE, gigantische
     `<link href="data:text/html,...">` tag (een volledig HTML-document
     url-encoded ingebakken; ballast die cumulatief groeit tot ~70 MB/hoofdstuk).
     Dit is een Quarto-artefact (oorzaak: geneste per-hoofdstuk `_quarto.yml`).
     De echte inhoud staat er los van en overleeft verwijdering volledig.
     → strippen. Zie ROOT-CAUSE-notitie in _HEROPSTART.md.
  3. De map moet als project-resource in `_quarto.yml` staan, anders kopieert
     `quarto render` van de site 'm niet naar `_site/`.
     (`resources: - "werkboeken/<naam>/**"`)

Dit script doet 1 en 2 deterministisch + valideert dat geen enkele asset breekt.
Punt 3 is een eenmalige config-regel en wordt hier alleen gecontroleerd.

Gebruik
-------
    python3 _tools/publish_workbook.py \
        --src  "<pad naar werkboek>/_site" \
        --name ozp1

Daarna in countcamp_site:  quarto render  &&  git add/commit/push.

Veilig: leest alleen uit --src, schrijft alleen naar werkboeken/<name>/ in de
site-repo. Raakt de werkboek-bron NIET aan.
"""

from __future__ import annotations
import argparse, os, re, shutil, sys, html

SITE_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Mappen die hernoemd moeten worden: Quarto negeert ze anders.
RENAMES = {"_common": "common", "site_libs": "libs"}


def log(msg: str) -> None:
    print(msg, flush=True)


def strip_data_html_links(text: str) -> tuple[str, int]:
    """Verwijder elke `<link ...data:text/html...>` tag (redundante ballast).

    Werkt met string-find i.p.v. regex: de payload is megabytes url-encoded
    en bevat geen '>' (die is %3E), dus de eerste '>' ná de tag-start is
    betrouwbaar het einde van de tag.
    """
    n = 0
    needle = "data:text/html"
    while True:
        pos = text.find(needle)
        if pos == -1:
            break
        start = text.rfind("<", 0, pos)
        end = text.find(">", pos)
        if start == -1 or end == -1:
            break
        # veiligheidscheck: het moet een <link of <a-achtige losse tag zijn,
        # geen gigantisch toevallig blok. We eisen dat tussen start en de
        # payload geen tweede '<' zit (anders zitten we midden in iets).
        if "<" in text[start + 1:pos]:
            # geen schone tag-start; sla deze voorkomende over door 'm te
            # neutraliseren zodat de loop niet vastloopt.
            text = text[:pos] + "data-stripped" + text[pos + len(needle):]
            continue
        text = text[:start] + text[end + 1:]
        n += 1
    return text, n


def strip_other_formats(text: str) -> tuple[str, int]:
    """Verwijder het 'Other Formats'-blok (de PDF-downloadlink in de margin).

    Quarto genereert per hoofdstuk een `<h2 ...>Other Formats</h2>` gevolgd door
    `<nav class="quarto-other-links">...PDF...</nav>`, maar de bijbehorende PDF's
    worden niet meegerenderd → dode link. Downloads zijn (nu) niet nodig, dus we
    halen het hele blokje weg. De onschuldige "Print to PDF"-knop (href="#",
    browser-print) blijft staan.
    """
    n = 0
    # 1) de <nav class="quarto-other-links"> ... </nav>
    while True:
        i = text.find('<nav class="quarto-other-links"')
        if i == -1:
            break
        end = text.find("</nav>", i)
        if end == -1:
            break
        text = text[:i] + text[end + len("</nav>"):]
        n += 1
    # 2) de bijbehorende <h2 ...>Other Formats</h2>
    while True:
        i = text.find('quarto-other-links-text')
        if i == -1:
            break
        h2start = text.rfind("<h2", 0, i)
        h2end = text.find("</h2>", i)
        if h2start == -1 or h2end == -1:
            break
        text = text[:h2start] + text[h2end + len("</h2>"):]
    return text, n


def rewrite_refs(text: str) -> str:
    for old, new in RENAMES.items():
        text = text.replace(old + "/", new + "/")
    return text


def validate_assets(dst: str) -> list[str]:
    """Controleer dat elke lokale href/src in elke .html bestaat. Geeft lijst
    met (bestand -> ontbrekende ref). Leeg = alles compleet."""
    problems: list[str] = []
    for root, _dirs, files in os.walk(dst):
        for fn in files:
            if not fn.endswith(".html"):
                continue
            f = os.path.join(root, fn)
            h = open(f, encoding="utf-8", errors="ignore").read()
            refs = set(re.findall(r'(?:href|src)="([^"]+)"', h))
            for r in refs:
                if r.startswith(("http://", "https://", "#", "mailto:",
                                 "data:", "//", "javascript:")):
                    continue
                clean = html.unescape(r.split("#")[0].split("?")[0])
                if not clean:
                    continue
                target = os.path.normpath(os.path.join(os.path.dirname(f), clean))
                if not os.path.exists(target):
                    rel = os.path.relpath(f, dst)
                    problems.append(f"{rel}  ->  {r}")
    return problems


def human(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}TB"


def dirsize(path: str) -> int:
    total = 0
    for root, _d, files in os.walk(path):
        for fn in files:
            total += os.path.getsize(os.path.join(root, fn))
    return total


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--src", required=True, help="pad naar werkboek-_site")
    ap.add_argument("--name", required=True, help="doelnaam onder werkboeken/")
    ap.add_argument("--dry-run", action="store_true",
                    help="alleen rapporteren, niets wegschrijven")
    args = ap.parse_args()

    src = os.path.abspath(args.src)
    if not os.path.isfile(os.path.join(src, "index.html")):
        log(f"FOUT: {src} bevat geen index.html — is dit een gerenderd _site?")
        return 2

    dst = os.path.join(SITE_ROOT, "werkboeken", args.name)
    log(f"bron : {src}  ({human(dirsize(src))})")
    log(f"doel : {dst}")

    if args.dry_run:
        log("[dry-run] zou kopiëren + strippen + valideren; stop hier.")
        return 0

    # 1) verse kopie
    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(src, dst)

    # 2) mappen hernoemen
    for old, new in RENAMES.items():
        o = os.path.join(dst, old)
        if os.path.isdir(o):
            shutil.move(o, os.path.join(dst, new))
            log(f"  hernoemd: {old}/ -> {new}/")

    # 2b) bron-_common méékopiëren (R-helpers, filters, ...).
    #     De werkboek-render kopieert alleen _common/styles naar _site, maar de
    #     HTML linkt ook naar bv. _common/R/figuren.R ("bekijk de code"). Door de
    #     bron-_common te mergen in common/ resolven die links — leerzaam voor
    #     studenten. workbook-root = de map boven _site.
    if os.path.basename(src) == "_site":
        src_common = os.path.join(os.path.dirname(src), "_common")
        if os.path.isdir(src_common):
            dst_common = os.path.join(dst, "common")
            os.makedirs(dst_common, exist_ok=True)
            merged = 0
            for root, _d, files in os.walk(src_common):
                rel = os.path.relpath(root, src_common)
                tgt = os.path.join(dst_common, rel) if rel != "." else dst_common
                os.makedirs(tgt, exist_ok=True)
                for fn in files:
                    s = os.path.join(root, fn)
                    t = os.path.join(tgt, fn)
                    if not os.path.exists(t):
                        shutil.copy2(s, t)
                        merged += 1
            log(f"  bron-_common gemerged in common/: {merged} bestand(en)")

    # 3) per .html/.css/.json: strip data:text/html + herschrijf refs
    stripped_total = 0
    formats_total = 0
    for root, _d, files in os.walk(dst):
        for fn in files:
            if not fn.endswith((".html", ".css", ".json")):
                continue
            f = os.path.join(root, fn)
            s = open(f, encoding="utf-8", errors="ignore").read()
            orig = len(s)
            if fn.endswith(".html"):
                s, n = strip_data_html_links(s)
                stripped_total += n
                s, m = strip_other_formats(s)
                formats_total += m
            s = rewrite_refs(s)
            if len(s) != orig or fn.endswith((".css", ".json")):
                open(f, "w", encoding="utf-8").write(s)
    log(f"  gestripte data:text/html-tags: {stripped_total}")
    log(f"  gestripte 'Other Formats'-blokken: {formats_total}")

    # 4) validatie
    problems = validate_assets(dst)
    log(f"  ontbrekende assets: {len(problems)}")
    for p in problems[:20]:
        log("    MIST: " + p)

    log(f"resultaat: {human(dirsize(dst))}")
    # grootste 5 html's
    sizes = []
    for root, _d, files in os.walk(dst):
        for fn in files:
            if fn.endswith(".html"):
                p = os.path.join(root, fn)
                sizes.append((os.path.getsize(p), os.path.relpath(p, dst)))
    sizes.sort(reverse=True)
    log("  grootste html's:")
    for sz, rel in sizes[:5]:
        log(f"    {human(sz):>8}  {rel}")

    if problems:
        log("\n⚠️  Er ontbreken assets — NIET publiceren tot opgelost.")
        return 1
    log("\n✅ Compleet en gevalideerd. Volgende stap: quarto render + git push.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
