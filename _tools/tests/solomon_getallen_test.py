#!/usr/bin/env python3
"""Toetst de zes getypte getallen van speeltjes/solomon.html.

Waarom. Het speeltje typt zes metingen (twee voormetingen, vier nametingen) en rekent
de vier stukjes H/M, T, X en S daaruit. Of die getallen goed *leren*, hangt van iets af
dat je niet ziet aan de getallen zelf: dat elke som van stukjes een eigen getal geeft.
Dan verraadt een fout antwoord op de slotvraag precies welk stukje vergeten is. Met de
eerste getallen (2015) vielen T en S samen, en met de tweede proef (8-10-2026, H/M 2,
T 1, X 6, S 3) vielen H/M + T en S samen (allebei 3) en X en H/M + T + S (allebei 6).
Dat zie je pas als je het narekent -- dus rekent dit het na, bij elke bouw.

Afloopcodes volgens huisafspraak: 0 schoon, 1 er is iets mis, 3 kon niet kijken.
"""
import re
import sys
from itertools import combinations
from pathlib import Path

HIER = Path(__file__).resolve().parent
# De Nederlandse bladzij en haar Engelse tweeling (stuk 2, 8-10-2026). Allebei dragen ze hun eigen GETALLEN,
# en die moeten gelijk zijn: anders rekent de ene bladzij een andere ladder voor dan de andere.
PAGINAS = [HIER.parent.parent / "speeltjes" / "solomon.html", HIER.parent.parent / "speeltjes" / "solomon-en.html"]


def lees_getallen(tekst):
    m = re.search(r"var GETALLEN = \{([^}]*)\}", tekst)
    if not m:
        return None
    d = {}
    for k, v in re.findall(r"(\w+):\s*(-?\d+(?:\.\d+)?)", m.group(1)):
        d[k] = float(v)
    return d


def los(d):
    leen = (d["voorI"] + d["voorII"]) / 2
    vI, vII = d["naI"] - d["voorI"], d["naII"] - d["voorII"]
    vIII, vIV = d["naIII"] - leen, d["naIV"] - leen
    HM = vIV
    X = vIII - HM
    T = vII - HM
    S = vI - T - HM - X
    return {"H/M": HM, "T": T, "X": X, "S": S}


def main():
    gelezen = {}
    for pagina in PAGINAS:
        if not pagina.exists():
            print("KON NIET KIJKEN: %s bestaat niet" % pagina)
            return 3
        d = lees_getallen(pagina.read_text(encoding="utf-8"))
        if not d or len(d) != 6:
            print("KON NIET KIJKEN: 'var GETALLEN = {...}' met zes getallen niet gevonden in %s" % pagina)
            return 3
        gelezen[pagina.name] = d
    namen = [p.name for p in PAGINAS]
    d = gelezen[namen[0]]
    st = los(d)
    fouten = []
    for naam in namen[1:]:
        if gelezen[naam] != d:
            fouten.append("%s heeft andere getallen dan %s: %s tegen %s" % (naam, namen[0], gelezen[naam], d))
    for k, v in d.items():
        if not 0 <= v <= 100:
            fouten.append("%s = %g valt buiten de schaal 0-100" % (k, v))
    for naam, v in st.items():
        if abs(v) < 1e-9:
            fouten.append("stukje %s is 0: dan zie je het in geen enkele som" % naam)
        elif v < 0:
            # De ladder rekent op groei: het zwaard klieft één balk in vier delen, de verschil-in-verschil-
            # figuur zegt "wat uitsteekt is S", de knop "De voormeting maakt de therapie zwakker" draait S om.
            # Die tekenen alleen deze getallen, niet de schuifjes; een negatief stukje kunnen ze niet laten
            # zien (stuk 1d, 8-10-2026). Het speelbord kan het wel: zie solomon_figuren_test.py.
            fouten.append("stukje %s is %g: het zwaard en de verschil-in-verschil-balken tekenen alleen positieve stukjes" % (naam, v))
    # stap 9 rekent S uit de kale tabel zonder lenen: (naI - naII) - (naIII - naIV). Dat is alleen S als de
    # twee echte voormetingen gelijk zijn; anders zit hun verschil erin en liegt de uitwerking.
    if abs(d["voorI"] - d["voorII"]) > 1e-9:
        fouten.append("voormeting I (%g) en II (%g) verschillen: de som zonder lenen in stap 9 geeft dan niet S" % (d["voorI"], d["voorII"]))
    sommen = {}
    for n in range(1, 5):
        for c in combinations(st, n):
            sommen.setdefault(round(sum(st[x] for x in c), 9), []).append(" + ".join(c))
    for s, wie in sorted(sommen.items()):
        if len(wie) > 1:
            fouten.append("deelsom %g komt %d keer voor: %s" % (s, len(wie), " en ".join(wie)))
    print("bladzijden: " + ", ".join(namen) + " (dezelfde zes getallen)" if not any("andere getallen" in f for f in fouten) else "bladzijden: " + ", ".join(namen))
    print("getallen  : " + ", ".join("%s %g" % kv for kv in d.items()))
    print("stukjes   : " + ", ".join("%s %g" % kv for kv in st.items()))
    print("deelsommen: %d, waarvan %d uniek" % (len(sommen), sum(1 for w in sommen.values() if len(w) == 1)))
    if fouten:
        for f in fouten:
            print("FOUT: " + f)
        return 1
    print("ok: elke som van stukjes geeft een eigen getal, elk stukje is groter dan 0, alles tussen 0 en 100")
    return 0


if __name__ == "__main__":
    sys.exit(main())
