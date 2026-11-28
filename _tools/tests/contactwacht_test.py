#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""contactwacht_test.py — leest de contactkeuring alleen wat een bezoeker ziet, en bijt hij nog?

    python3 _tools/tests/contactwacht_test.py              A, B en C
    python3 _tools/tests/contactwacht_test.py A C          alleen deze delen

WAAROM (spoor contactwacht_script, 28-11-2026). De wachtrijstap en_bij_boek_h1 stopte
in de spooksite op één gat: "en/book/h1.html: mailadres ' + ADRES; a.textContent = …
staat niet op manuscript/h1.html". Dat "adres" is het script van de werknotities-knop
in het boek (`a.href = 'mailto:' + ADRES;`), gelezen tot het eerste aanhalingsteken —
zes regels script en commentaar. Lab 72a83989 veranderde dat commentaar, de verse
Engelse h1 en de oudere Nederlandse verschilden daarin, en de keuring zag een
verschillend adres waar er geen was. Sindsdien leest keur_contact() in en_bouw.py aan
de Engelse kant alleen wat een bezoeker ziet: geen <script>, <style> of <!-- -->.

Een keuring die niets meer vindt is ook groen. Deze toets eist dus twee kanten: wat
een bezoeker niet ziet telt niet, en een echt ander adres blijft een gat.

DRIE DELEN, geen bouw nodig
  A. keur_contact() op losse teksten: het script uit het boek, hetzelfde in <style>
     en in commentaar, een echt ander mailadres, een afgeknot adres, een IBAN met
     een tikfout of een cijfer minder, een mailto: in zichtbare tekst, data:-adressen.
  B. op de ECHTE gecommitte en/book/h1.html en manuscript/h1.html: zoals ze zijn, en
     met de verandering van lab 72a83989 aan de Engelse kant (de twee hoeven dus
     niet tegelijk geperst te zijn); en een echte Engelse oefenboekbladzij met een
     ander adres. Staat het script of die zin er niet meer in, dan zegt B dat hij
     niet kon kijken (afloop 3) — anders bewijst hij niets.
  C. de bedrading: `en_bouw.py keur` op een kleine site met die twee tweelingen. De
     regel "contactgegevens:" en de gaten moeten kloppen, niet alleen de functie.

DE MUTATIEPROEF. PROEF_MUTATIE="bestand|||oud|||nieuw" verandert vóór de toets één
stuk tekst in _tools/en_bouw.py — in het geheugen, het bestand blijft heel. Meer
tegelijk: zet ;;; tussen de drietallen. Staat `oud` er niet precies één keer in, dan
is dat afloop 2. Zie contactwacht_mutatieproef.sh.

Afloop: 0 alles goed · 1 minstens één fout · 2 de mutatie sloeg niet aan · 3 kon niet kijken.
"""
from __future__ import annotations

import argparse
import contextlib
import io
import os
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


# ------------------------------------------- de module, eventueel gemuteerd ----
def mutaties() -> list[tuple[str, str, str]]:
    m = os.environ.get("PROEF_MUTATIE")
    if not m:
        return []
    uit = []
    for deel in m.split(";;;"):
        d = deel.split("|||")
        if len(d) != 3:
            print(f"MUTATIE sloeg niet aan: geen bestand|||oud|||nieuw: {deel[:80]!r}")
            sys.exit(2)
        if d[0] != "_tools/en_bouw.py":
            print(f"MUTATIE sloeg niet aan: deze toets muteert alleen _tools/en_bouw.py, niet {d[0]}")
            sys.exit(2)
        uit.append((d[0], d[1], d[2]))
    return uit


def laad(naam: str, rel: str, muts) -> types.ModuleType:
    pad = os.path.join(REPO, rel)
    tekst = lees(pad)
    for _bestand, oud, nieuw in muts:
        n = tekst.count(oud)
        if n != 1:
            print(f"MUTATIE sloeg niet aan: {oud!r} staat {n} keer in {rel} (moet 1)")
            sys.exit(2)
        tekst = tekst.replace(oud, nieuw)
        print(f"MUTATIE in {rel}: {oud.strip()[:70]!r} -> {nieuw.strip()[:70]!r}")
    mod = types.ModuleType(naam)
    mod.__file__ = pad
    sys.modules[naam] = mod
    exec(compile(tekst, pad, "exec"), mod.__dict__)
    return mod


EB = laad("en_bouw", "_tools/en_bouw.py", mutaties())

goed = fout = 0


def uitslag(ok: bool, wat: str, waarom: str = "") -> None:
    global goed, fout
    if ok:
        goed += 1
        print(f"ok    {wat}")
    else:
        fout += 1
        print(f"FOUT  {wat}" + (f" — {waarom}" if waarom else ""))


def bladzij(lijf: str, kop: str = "") -> str:
    return (f'<!DOCTYPE html>\n<html lang="en-GB"><head>\n<title>t</title>\n{kop}</head>\n'
            f"<body>\n{lijf}\n</body></html>\n")


# Het script uit het boek, zoals het in boek/_atelier/_afterbody.html staat: het adres
# wordt pas in de browser in elkaar gezet, en het commentaar eronder draagt een ".
def boekscript(commentaar: str) -> str:
    return ("<script>\n  var ADRES = 'vragen@countcamp.org';\n  function zetRegel() {\n"
            "    var a = document.createElement('a');\n    a.href = 'mailto:' + ADRES;\n"
            "    a.textContent = ADRES;\n    regel.appendChild(a);\n  }\n"
            f"  /* {commentaar} <section class=\"werk-blok\"> */\n</script>")


LINK = '<p>Questions? <a href="mailto:{0}">{0}</a></p>'
IBAN_ZIN = "<p><strong>IBAN {0}</strong></p>"


# ------------------------------------------------------------------ deel A ----
def deel_a() -> None:
    print("\nA. keur_contact() op losse teksten")
    # (wat, Engels, Nederlands, hoeveel nagelopen, wat er moet afwijken)
    gevallen = [
        ("het script uit het boek, met een ander commentaar dan de Nederlandse kant",
         bladzij(boekscript("ná de slotregel")), bladzij(boekscript("ná Bens slotregel")), 0, []),
        ("een mailto: in een script, alleen aan de Engelse kant",
         bladzij('<script>var oud = "mailto:oud@countcamp.org";</script>'), bladzij(""), 0, []),
        ("hetzelfde in <SCRIPT type=...> met hoofdletters",
         bladzij('<SCRIPT type="text/javascript">x = "mailto:oud@countcamp.org";</SCRIPT>'), bladzij(""), 0, []),
        ("een mailto: in een stijlblok",
         bladzij("", '<style>/* zie mailto:oud@countcamp.org */</style>\n'), bladzij(""), 0, []),
        ("een mailto: in HTML-commentaar",
         bladzij("<!-- vroeger: mailto:oud@countcamp.org -->"), bladzij(""), 0, []),
        ("een IBAN in een script",
         bladzij('<script>var r = "NL56 TRIO 0390 1306 50";</script>'), bladzij(""), 0, []),
        ("een echt ander mailadres in een href",
         bladzij(LINK.format("questions@countcamp.org")), bladzij(LINK.format("vragen@countcamp.org")),
         1, [("mailadres", "questions@countcamp.org")]),
        ("een echt ander mailadres naast het boekscript (dat op beide kanten anders is)",
         bladzij(LINK.format("vragen@countcamp.nl") + boekscript("ná de slotregel")),
         bladzij(LINK.format("vragen@countcamp.org") + boekscript("ná Bens slotregel")),
         1, [("mailadres", "vragen@countcamp.nl")]),
        ("hetzelfde mailadres op beide kanten",
         bladzij(LINK.format("vragen@countcamp.org")), bladzij(LINK.format("vragen@countcamp.org")), 1, []),
        ("hetzelfde adres, met ?subject= erachter",
         bladzij('<a href="mailto:vragen@countcamp.org?subject=Book">mail</a>'),
         bladzij(LINK.format("vragen@countcamp.org")), 1, []),
        ("een afgeknot adres (een letter minder aan het eind)",
         bladzij(LINK.format("vragen@countcamp.or")), bladzij(LINK.format("vragen@countcamp.org")),
         1, [("mailadres", "vragen@countcamp.or")]),
        ("een afgeknot adres (een letter minder aan het begin)",
         bladzij(LINK.format("ragen@countcamp.org")), bladzij(LINK.format("vragen@countcamp.org")),
         1, [("mailadres", "ragen@countcamp.org")]),
        ("een mailto: in zichtbare tekst, verderop een aanhalingsteken",
         bladzij('<p><code>mailto:vragen@countcamp.org</code> or <a href="use.html">here</a></p>'),
         bladzij(LINK.format("vragen@countcamp.org")), 1, []),
        ("hetzelfde rekeningnummer op beide kanten",
         bladzij(IBAN_ZIN.format("NL56 TRIO 0390 1306 05")), bladzij(IBAN_ZIN.format("NL56 TRIO 0390 1306 05")),
         1, []),
        ("een tikfout in het rekeningnummer (05 -> 50)",
         bladzij(IBAN_ZIN.format("NL56 TRIO 0390 1306 50")), bladzij(IBAN_ZIN.format("NL56 TRIO 0390 1306 05")),
         1, [("rekeningnummer", "NL56 TRIO 0390 1306 50")]),
        ("een cijfer minder aan het eind van het rekeningnummer",
         bladzij(IBAN_ZIN.format("NL56 TRIO 0390 1306 0")), bladzij(IBAN_ZIN.format("NL56 TRIO 0390 1306 05")),
         1, [("rekeningnummer", "NL56 TRIO 0390 1306 0")]),
        # 25-10-2026: "ZJ11OT" stond in een ingesloten Engelse figuur en werd een gat.
        ("een 'rekeningnummer' in een data:-adres (een ingesloten figuur)",
         bladzij('<img src="data:image/png;base64,iVBORw0KGgo+ZJ11OT/AAAA">'), bladzij(""), 0, []),
    ]
    for wat, en, nl, n_moet, fout_moet in gevallen:
        nagelopen, afwijk, _weg = EB.keur_contact(en, nl)
        ok = len(nagelopen) == n_moet and afwijk == fout_moet
        uitslag(ok, f"{wat}: {len(nagelopen)} nagelopen, {len(afwijk)} wijkt af",
                f"moet {n_moet} nagelopen en {fout_moet}; kreeg {nagelopen} en {afwijk}")
    # en de telling van wat er is overgeslagen: één boekscript = één keer mailto:
    _n, _f, weg = EB.keur_contact(bladzij(boekscript("x") + "<!-- mailto:y@z.nl -->"), bladzij(""))
    uitslag(weg == 2, f"overgeslagen: {weg} keer mailto: in script en commentaar (moet 2)")


# ------------------------------------------------------------------ deel B ----
EN_H1, NL_H1 = "en/book/h1.html", "manuscript/h1.html"
OB_EN = "en/workbooks/inferential-statistics/index.html"
OB_NL = "oefenboeken/ts/index.html"
# De verandering van lab 72a83989 in het commentaar van de after-body, zoals hij in de
# verse Engelse h1 van 28-11-2026 stond (log en_bij_boek_h1, r436-439).
LAB_OUD, LAB_NIEUW = "daardoor ná Bens\n     slotregel", "daardoor ná de\n     slotregel"


def deel_b() -> bool:
    print("\nB. op de echte gecommitte bladzijden")
    paden = [EN_H1, NL_H1, OB_EN, OB_NL]
    weg = [p for p in paden if not os.path.isfile(os.path.join(REPO, p))]
    if weg:
        print(f"KON NIET KIJKEN: {', '.join(weg)} staat niet in deze checkout")
        return False
    en, nl = lees(os.path.join(REPO, EN_H1)), lees(os.path.join(REPO, NL_H1))
    if "'mailto:' + ADRES" not in en or LAB_OUD not in en:
        print(f"KON NIET KIJKEN: {EN_H1} draagt niet meer het script met 'mailto:' + ADRES en de zin "
              f"{LAB_OUD!r} — dan bewijst dit deel niets. Werk de toets bij naar het nieuwe script.")
        return False
    nagelopen, afwijk, n_weg = EB.keur_contact(en, nl)
    uitslag(not afwijk and n_weg >= 1,
            f"{EN_H1} ↔ {NL_H1} zoals gecommit: {len(nagelopen)} nagelopen, {len(afwijk)} wijkt af, "
            f"{n_weg} keer mailto: overgeslagen (moet 0 afwijken, ≥1 overgeslagen)", f"{afwijk}")
    en_vers = en.replace(LAB_OUD, LAB_NIEUW, 1)
    nagelopen, afwijk, _ = EB.keur_contact(en_vers, nl)
    uitslag(not afwijk, f"{EN_H1} met het commentaar van lab 72a83989, {NL_H1} nog niet: "
            f"{len(afwijk)} wijkt af (moet 0)", f"{afwijk}")
    # en het omgekeerde: de Nederlandse kant als eerste geperst
    nagelopen, afwijk, _ = EB.keur_contact(en, nl.replace(LAB_OUD, LAB_NIEUW, 1))
    uitslag(not afwijk, f"andersom: {NL_H1} met het nieuwe commentaar, {EN_H1} nog niet: "
            f"{len(afwijk)} wijkt af (moet 0)", f"{afwijk}")

    ob_en, ob_nl = lees(os.path.join(REPO, OB_EN)), lees(os.path.join(REPO, OB_NL))
    nagelopen, afwijk, _ = EB.keur_contact(ob_en, ob_nl)
    uitslag(("mailadres", "vragen@countcamp.org") in nagelopen and not afwijk,
            f"{OB_EN}: {len(nagelopen)} nagelopen, waaronder vragen@countcamp.org, {len(afwijk)} wijkt af (moet 0)",
            f"{nagelopen} / {afwijk}")
    if "mailto:vragen@countcamp.org" not in ob_en:
        print(f"KON NIET KIJKEN: {OB_EN} draagt mailto:vragen@countcamp.org niet meer")
        return False
    nagelopen, afwijk, _ = EB.keur_contact(ob_en.replace("mailto:vragen@countcamp.org", "mailto:vragen@countcamp.nl"),
                                           ob_nl)
    uitslag(("mailadres", "vragen@countcamp.nl") in afwijk,
            f"{OB_EN} met mailto:vragen@countcamp.nl: {len(afwijk)} wijkt af (moet het .nl-adres zijn)", f"{afwijk}")
    return True


# ------------------------------------------------------------------ deel C ----
def keur(site: str) -> tuple[int, str]:
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = EB.cmd_keur(argparse.Namespace(site=site, soort="spook"))
    return code, buf.getvalue()


def contactregels(uit: str) -> tuple[str, list[str]]:
    regel = next((r.strip() for r in uit.splitlines() if r.strip().startswith("contactgegevens:")), "")
    gaten = [r.strip() for r in uit.splitlines()
             if r.startswith("    - ") and (" mailadres " in r or " rekeningnummer " in r)]
    return regel, gaten


def deel_c() -> bool:
    print("\nC. de bedrading: en_bouw.py keur op een kleine site")
    paden = [EN_H1, NL_H1, OB_EN, OB_NL]
    if any(not os.path.isfile(os.path.join(REPO, p)) for p in paden):
        print("KON NIET KIJKEN: niet alle bladzijden van deel B staan in deze checkout")
        return False
    with tempfile.TemporaryDirectory(prefix="contactwacht_") as site:
        for p in paden:
            os.makedirs(os.path.join(site, os.path.dirname(p)), exist_ok=True)
            shutil.copyfile(os.path.join(REPO, p), os.path.join(site, p))
        with open(os.path.join(site, "index.html"), "w", encoding="utf-8") as f:
            f.write(bladzij(""))
        en_p = os.path.join(site, EN_H1)
        en_vers = lees(en_p).replace(LAB_OUD, LAB_NIEUW, 1)
        with open(en_p, "w", encoding="utf-8") as f:
            f.write(en_vers)
        # Deze kleine site mist bijna alles; andere keuringen zijn er dus rood. Hier
        # telt alleen de regel en de gaten van de contactkeuring.
        _code, uit = keur(site)
        regel, gaten = contactregels(uit)
        uitslag(bool(regel) and " 0 wijken af" in regel and not gaten,
                f"met het nieuwe commentaar in {EN_H1}: {regel or '(geen contactregel)'}",
                f"gaten: {gaten}")
        ob_p = os.path.join(site, OB_EN)
        ob_ander = lees(ob_p).replace("mailto:vragen@countcamp.org", "mailto:vragen@countcamp.nl")
        with open(ob_p, "w", encoding="utf-8") as f:
            f.write(ob_ander)
        code, uit = keur(site)
        regel, gaten = contactregels(uit)
        uitslag(code == 1 and " 1 wijken af" in regel
                and gaten == [f"- {OB_EN}: mailadres vragen@countcamp.nl staat niet op {OB_NL}"],
                f"met een ander adres in {OB_EN}: afloop {code}, {regel or '(geen contactregel)'}",
                f"gaten: {gaten}")
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("delen", nargs="*", default=["A", "B", "C"], choices=["A", "B", "C"])
    a = ap.parse_args()
    gekeken = True
    if "A" in a.delen:
        deel_a()
    if "B" in a.delen:
        gekeken = deel_b() and gekeken
    if "C" in a.delen:
        gekeken = deel_c() and gekeken
    n = goed + fout
    print(f"\n{goed} van {n} goed" + (f" — {fout} FOUT" if fout else "")
          + ("" if gekeken else " — een deel KON NIET KIJKEN, dus dit is geen groene uitslag"))
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
