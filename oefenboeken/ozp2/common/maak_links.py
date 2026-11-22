"""Zet de vier gedeelde mappen van het oefenboek OZP1 als symlink in _common/.

Waarom symlinks en geen kopie: de opmaak (styles), het kaderfilter (filters),
de figuurstijl (R) en de motor-kaartjes (img) zijn die van OZP1 en moeten dat
blijven. Een kopie loopt bij de eerste reparatie in OZP1 uit elkaar.

Wat hier NIET gelinkt wordt: data/ (OZP2 heeft eigen .sav-bestanden) en de
controles (die zoeken hun boek via Path(__file__).resolve() en zouden via een
link OZP1 controleren in plaats van OZP2 -- zie _controles/ozp1_wacht.py).

Draaien vanuit de map _common/: python3 maak_links.py
Bestaat een link al en wijst hij goed, dan laat het script hem staan.
"""
import os
import pathlib
import sys

HIER = pathlib.Path(__file__).resolve().parent
DOEL = pathlib.Path("..") / ".." / "ozp1_werkboek" / "2526_werkboek" / "_common"

fout = 0
for naam in ("styles", "filters", "R", "img"):
    link = HIER / naam
    doel = DOEL / naam
    if link.is_symlink():
        if os.readlink(link) == str(doel):
            print(f"staat al: {naam} -> {doel}")
            continue
        print(f"FOUT: {naam} wijst naar {os.readlink(link)}, verwacht {doel}", file=sys.stderr)
        fout += 1
        continue
    if link.exists():
        print(f"FOUT: {naam} bestaat al en is geen link", file=sys.stderr)
        fout += 1
        continue
    os.symlink(doel, link)
    if not (HIER / naam).resolve().is_dir():
        print(f"FOUT: {naam} -> {doel} wijst naar niets", file=sys.stderr)
        fout += 1
    else:
        print(f"gemaakt: {naam} -> {doel}")
sys.exit(1 if fout else 0)
