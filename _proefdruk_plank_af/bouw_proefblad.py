#!/usr/bin/env python3
"""Zet oefenboeken/index.qmd om in een los proefblad dat hier wél bouwt.

Waarom dit bestaat: Quarto rendert geen enkel invoerbestand vanuit een
worktree onder `.claude/`. Gemeten op 10-9-2026 met `quarto inspect`: het
project wordt gevonden, en het aantal invoerbestanden is 0 -- de bouw
levert alleen robots.txt en sitemap.xml op. De enige verborgen schakel in
het pad is de map `.claude` zelf.

Het proefblad krijgt dezelfde cascade als de echte bladzij (`theme: cosmo`
plus `styles.css`, zie het format-blok in `_quarto.yml`), zodat wat je hier
meet ook op de site geldt. Wat het NIET heeft is de navbar en de voet.

De romp wordt AFGELEID uit het echte bestand en niet overgetikt: zo kan het
proefblad niet uit de pas gaan lopen met wat er straks gepubliceerd wordt.
"""
from pathlib import Path
import re
import shutil

wortel = Path(__file__).resolve().parents[1]
hier = Path(__file__).resolve().parent
bron = wortel / "oefenboeken" / "index.qmd"

tekst = bron.read_text(encoding="utf-8")

# de YAML-kop eraf: van de eerste `---` tot en met de tweede op een eigen regel
m = re.match(r"^---\n.*?\n---\n", tekst, flags=re.S)
if not m:
    raise SystemExit(f"FOUT: geen YAML-kop gevonden in {bron}")
romp = tekst[m.end():]

kop = """---
title: "Oefenboeken"
toc: false
format:
  html:
    theme: cosmo
    css: styles.css
include-in-header:
  text: |
    <script src="vorm.js"></script>
---
"""

uit = hier / "proefblad.qmd"
uit.write_text(kop + romp, encoding="utf-8")

# de opmaak en de vormschakelaar ernaast, zodat de verwijzingen kloppen
shutil.copyfile(wortel / "styles.css", hier / "styles.css")
shutil.copyfile(wortel / "oefenboeken" / "vorm.js", hier / "vorm.js")

print(f"proefblad geschreven: {uit}")
print(f"romp uit {bron}: {len(romp.splitlines())} regels")
