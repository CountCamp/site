#!/usr/bin/env python3
"""
plankwacht.py — toetst de beloftes op de plank tegen wat er echt staat.

Waarom dit script bestaat
-------------------------
Elk kaartje op `oefenboeken/index.qmd` doet beweringen die iemand met de hand
moet bijhouden. Twee daarvan logen binnen twee dagen:

  21-9-2026  het Psychometrie-kaartje zei "Twee van de zeven thema's staan
             online" terwijl er vier stonden. Commit 6ac10da had thema 3 en 4
             gepubliceerd en het kaartje niet aangeraakt.
  22-9-2026  het OZP 1-kaartje zei "Bijgewerkt 10 september 2026" terwijl de
             gepubliceerde map op 19 september voor het laatst was ververst.

Allebei dezelfde vorm: het boek beweegt, het kaartje blijft staan. Niemand
merkt dat, want een verouderd kaartje ziet er precies zo uit als een kloppend
kaartje. Deze wachter rekent beide beloftes na uit de bestanden.

Wat hij toetst
--------------
  1. "**Bijgewerkt <dag> <maand> <jaar>**"
     tegen de laatste commit die de boekmap van dat kaartje raakte.
  2. "<telwoord> van de <telwoord> thema's staan online" (Psychometrie) en de
     kale vorm "<telwoord> thema's" (MVDA), tegen het aantal thema-mappen dat
     er staat én vanuit het boek zelf gelinkt is.

     De NOEMER blijft handwerk: "van de zeven" is een plan, en een plan staat
     niet op schijf. Wat hier nagerekend wordt is de teller. Zeg dat erbij als
     iemand vraagt hoeveel de wachter dekt -- anders lijkt het kaartje
     helemaal bewaakt.

Welke boekmap bij welk kaartje hoort, wordt NIET ergens bijgehouden: het staat
al in het kaartje zelf, in de link van de kop. Een tweede lijstje zou precies
zo verouderen als de getallen die we hier repareren.

Welke git-geschiedenis
----------------------
Die van DEZE repo, niet die van countcamp_lab. Het kaartje belooft iets aan een
lezer, en een lezer leest de site. De gerenderde boeken worden door
`publish_workbook.py` in deze repo gezet en meegecommit, dus een commit op
`oefenboeken/<boek>/` ís de publicatie. Zou de wachter op het lab kijken, dan
eiste hij een datum voor werk dat nog nergens staat -- dan liegt het kaartje de
andere kant op. Bijkomend: het lab hoeft hier niet uitgecheckt te staan.

Waar hij draait
---------------
Lokaal, in `naar_buiten.sh`. Niet in de GitHub Action: die checkt uit met
`actions/checkout@v4` zónder `fetch-depth`, dus met een geschiedenis van één
commit. `git log` op een boekmap geeft daar niets -- en niets is hier geen
antwoord maar blindheid.

Afloopcodes (huisafspraak, zoals bordwacht)
-------------------------------------------
  0  alle beloftes kloppen
  1  een belofte klopt niet -- het kaartje noemt zichzelf, met wat er hoort te staan
  3  kon niet kijken (geen geschiedenis, map weg, geen enkele belofte gevonden)

Afloopcode 3 is met opzet géén 0. Een wachter die niets gemeten heeft, geeft
hetzelfde beeld als een wachter die niets gevonden heeft; alleen een aparte
code houdt die twee uit elkaar.

Gebruik
-------
    python3 _tools/plankwacht.py                  # toetst oefenboeken/index.qmd
    python3 _tools/plankwacht.py --plank <pad>    # een andere plank (voor de toets)
    python3 _tools/plankwacht.py --stil           # alleen bij fouten iets zeggen
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys

# ------------------------------------------------------------------
# Nederlandse telwoorden en maanden. Alleen wat we echt tegenkomen --
# een lijst die verder reikt dan de plank suggereert dekking die er niet is.
# ------------------------------------------------------------------
TELWOORDEN = {
    "geen": 0, "nul": 0,
    "een": 1, "één": 1, "twee": 2, "drie": 3, "vier": 4, "vijf": 5,
    "zes": 6, "zeven": 7, "acht": 8, "negen": 9, "tien": 10,
    "elf": 11, "twaalf": 12, "dertien": 13, "veertien": 14, "vijftien": 15,
    "zestien": 16, "zeventien": 17, "achttien": 18, "negentien": 19,
    "twintig": 20,
}

MAANDEN = {
    "januari": 1, "februari": 2, "maart": 3, "april": 4, "mei": 5, "juni": 6,
    "juli": 7, "augustus": 8, "september": 9, "oktober": 10,
    "november": 11, "december": 12,
}

# "**Bijgewerkt 10 september 2026**"
RE_BIJGEWERKT = re.compile(
    r"\*\*Bijgewerkt\s+(\d{1,2})\s+([a-zA-Zé]+)\s+(\d{4})\*\*", re.IGNORECASE
)

# "**Vier van de zeven thema's staan online:**" -- het sterretje mag ook ontbreken.
# De noemer ("van de zeven") is met opzet GEEN belofte over bestanden: dat is
# een plan, en plannen staan niet op schijf. Alleen de teller wordt nagerekend.
RE_THEMATELLING = re.compile(
    r"([A-Za-zé]+)\s+van\s+de\s+([A-Za-zé]+)\s+thema[''`]s\s+staan\s+online",
    re.IGNORECASE,
)

# "Een opfris plus zeven thema's: meervoudige regressie, ..." -- de kale vorm.
# Hij wordt pas gezocht nadat de vorm hierboven uit de tekst is geknipt, anders
# zou "Vier van de zeven thema's" hier als "zeven" tellen en vals alarm geven.
RE_THEMAS_KAAL = re.compile(r"([A-Za-zé]+)\s+thema[''`]s", re.IGNORECASE)

# de kop van een kaartje: "### [Oefenboek OZP 1 →](ozp1/index.html) [SPSS]{.cc-chip}"
RE_KOP_MET_LINK = re.compile(r"^#{2,4}\s*\[(?P<titel>[^\]]*?)\s*→?\s*\]\((?P<href>[^)]+)\)")
RE_KOP_KAAL = re.compile(r"^#{2,4}\s*(?P<titel>.+?)\s*(?:\[[^\]]*\]\{[^}]*\}\s*)*$")

# Een thema-map: twee cijfers, liggend streepje, naam -- maar pas vanaf 01.
# `00_` is in dit huis de opstap en geen thema (00_opfris bij MVDA,
# 00_fundament bij OZP 1). Daardoor werken beide kaartjes met dezelfde regel:
# MVDA belooft "een opfris plus zeven thema's" en heeft 00_opfris + 01 t/m 07,
# Psychometrie belooft er vier en heeft 01 t/m 04.
RE_THEMAMAP = re.compile(r"^(?!00_)\d{2}_")


class Kaartje:
    """Eén `::: {.cc-boek}`-blok uit de plank."""

    def __init__(self, titel: str, href: str | None, regel: int):
        self.titel = titel
        self.href = href
        self.regel = regel          # 1-geteld, waar het blok begint
        self.tekst: list[str] = []

    @property
    def body(self) -> str:
        return "\n".join(self.tekst)

    def __repr__(self) -> str:
        return f"<Kaartje {self.titel!r} r{self.regel}>"


def lees_kaartjes(plank_pad: str) -> list[Kaartje]:
    """Haal de kaartjes uit de plank.

    Een kaartje begint met `::: {.cc-boek` en loopt tot de eerstvolgende regel
    die alleen uit dubbele punten bestaat. Kaartjes nestelen niet -- ze staan
    wél in een `::: {.cc-plank}`, maar dragen zelf geen geneste blokken.
    """
    with open(plank_pad, encoding="utf-8") as f:
        regels = f.read().splitlines()

    kaartjes: list[Kaartje] = []
    i = 0
    while i < len(regels):
        if not regels[i].lstrip().startswith("::: {.cc-boek"):
            i += 1
            continue
        start = i
        i += 1
        lijf: list[str] = []
        while i < len(regels) and not re.fullmatch(r":{3,}\s*", regels[i]):
            lijf.append(regels[i])
            i += 1
        i += 1  # de sluitregel zelf

        titel, href = "(kop niet gevonden)", None
        for r in lijf:
            m = RE_KOP_MET_LINK.match(r.strip())
            if m:
                titel, href = m.group("titel").strip(), m.group("href").strip()
                break
            m = RE_KOP_KAAL.match(r.strip()) if r.strip().startswith("#") else None
            if m:
                titel = m.group("titel").strip()
                break

        k = Kaartje(titel, href, start + 1)
        k.tekst = lijf
        kaartjes.append(k)
    return kaartjes


def boekmap(plank_pad: str, href: str) -> str:
    """Van de link in de kop naar de map, relatief aan de reporoot.

    `ozp1/index.html` naast `oefenboeken/index.qmd` wordt `oefenboeken/ozp1`;
    `../manuscript/handleiding/index.html` wordt `manuscript/handleiding`.
    """
    plank_map = os.path.dirname(plank_pad) or "."
    doel = os.path.normpath(os.path.join(plank_map, href))
    return os.path.dirname(doel)


def laatste_commitdatum(wortel: str, pad: str) -> tuple[str | None, str]:
    """(datum als JJJJ-MM-DD, toelichting). Datum None = kon niet kijken."""
    vol = os.path.join(wortel, pad)
    if not os.path.isdir(vol):
        return None, f"de map {pad}/ bestaat niet"
    try:
        uit = subprocess.run(
            ["git", "log", "-1", "--format=%ad%x09%h%x09%s", "--date=short", "--", pad + "/"],
            cwd=wortel, capture_output=True, text=True, check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        return None, f"git gaf geen antwoord op {pad}/ ({e})"
    if not uit.stdout.strip():
        return None, (
            f"geen enkele commit raakt {pad}/ -- is dit een ondiepe kloon "
            f"(actions/checkout zonder fetch-depth)?"
        )
    datum, kort, onderwerp = (uit.stdout.strip().split("\t", 2) + ["", ""])[:3]
    return datum, f"{kort} {onderwerp}"


def gepubliceerde_themas(wortel: str, pad: str) -> tuple[list[str], list[str], str | None]:
    """(gepubliceerd, wel-map-niet-gelinkt, reden-om-niet-te-kunnen-kijken).

    Een thema geldt als gepubliceerd wanneer zijn map er staat én het boek er
    vanaf zijn eigen index naar linkt. Een map zonder link is geen bladzij die
    een lezer ooit bereikt; een link zonder map is een dode link. Allebei komen
    met naam terug.
    """
    vol = os.path.join(wortel, pad)
    if not os.path.isdir(vol):
        return [], [], f"de map {pad}/ bestaat niet"
    mappen = sorted(
        d for d in os.listdir(vol)
        if RE_THEMAMAP.match(d) and os.path.isdir(os.path.join(vol, d))
    )
    index = os.path.join(vol, "index.html")
    if not os.path.isfile(index):
        return [], [], f"{pad}/index.html bestaat niet, dus er valt niets te linken"
    with open(index, encoding="utf-8", errors="ignore") as f:
        html = f.read()
    gelinkt = set(re.findall(r'href="\.?/?(\d{2}_[a-z0-9_]+)/', html))
    gepubliceerd = [d for d in mappen if d in gelinkt]
    verweesd = [d for d in mappen if d not in gelinkt]
    return gepubliceerd, verweesd, None


class Bevinding:
    def __init__(self, soort: str, kaartje: Kaartje, regel: str):
        self.soort = soort        # "fout" of "blind"
        self.kaartje = kaartje
        self.regel = regel


def toets(wortel: str, plank_pad: str) -> tuple[list[Bevinding], int, int]:
    """(bevindingen, aantal kaartjes, aantal getoetste beloftes)."""
    kaartjes = lees_kaartjes(os.path.join(wortel, plank_pad))
    bevindingen: list[Bevinding] = []
    getoetst = 0

    for k in kaartjes:
        heeft_datum = RE_BIJGEWERKT.search(k.body)

        # Eerst de vorm "X van de Y thema's staan online", daarna -- in wat er
        # van de tekst overblijft -- de kale vorm "X thema's". Andersom zou de
        # kale vorm de noemer oppikken en een kaartje beschuldigen dat klopt.
        heeft_telling = RE_THEMATELLING.search(k.body)
        if heeft_telling:
            woord_online, woord_totaal = heeft_telling.groups()
            citaat = f"{woord_online} van de {woord_totaal} thema's staan online"
        else:
            rest = RE_THEMATELLING.sub(" ", k.body)
            # ALLE voorkomens aflopen, niet alleen het eerste. Het MVDA-kaartje
            # opent met "er komen nog thema's bij" en noemt de telling pas in de
            # zin daarna; wie bij de eerste treffer stopt, vindt "nog", ziet dat
            # dat geen getal is, en concludeert dat er geen belofte staat.
            woord_online = citaat = None
            for kaal in RE_THEMAS_KAAL.finditer(rest):
                if kaal.group(1).lower() in TELWOORDEN:
                    woord_online = kaal.group(1)
                    citaat = f"{woord_online} thema's"
                    heeft_telling = kaal
                    break

        if not (heeft_datum or heeft_telling):
            continue

        if not k.href:
            bevindingen.append(Bevinding(
                "blind", k,
                "doet een belofte maar heeft geen link in zijn kop, "
                "dus er is geen map om tegen na te rekenen",
            ))
            continue

        pad = boekmap(plank_pad, k.href)

        # ---- 1. de Bijgewerkt-datum ----------------------------------
        if heeft_datum:
            dag, maandwoord, jaar = heeft_datum.groups()
            maand = MAANDEN.get(maandwoord.lower())
            if maand is None:
                bevindingen.append(Bevinding(
                    "blind", k, f"noemt de maand {maandwoord!r}, en die ken ik niet"))
            else:
                beweerd = f"{int(jaar):04d}-{maand:02d}-{int(dag):02d}"
                echt, waaruit = laatste_commitdatum(wortel, pad)
                if echt is None:
                    bevindingen.append(Bevinding("blind", k, waaruit))
                else:
                    getoetst += 1
                    if echt != beweerd:
                        bevindingen.append(Bevinding(
                            "fout", k,
                            f"zegt 'Bijgewerkt {dag} {maandwoord} {jaar}' ({beweerd}), "
                            f"maar {pad}/ is voor het laatst veranderd op {echt} "
                            f"-- {waaruit}",
                        ))

        # ---- 2. de thema-telling -------------------------------------
        if heeft_telling:
            beweerd = TELWOORDEN.get(woord_online.lower())
            if beweerd is None:
                bevindingen.append(Bevinding(
                    "blind", k,
                    f"telt zijn thema's als {woord_online!r}, en dat woord is voor mij geen getal"))
            else:
                gepubliceerd, verweesd, reden = gepubliceerde_themas(wortel, pad)
                if reden:
                    bevindingen.append(Bevinding("blind", k, reden))
                else:
                    getoetst += 1
                    if len(gepubliceerd) != beweerd:
                        namen = ", ".join(gepubliceerd) or "geen enkele"
                        bevindingen.append(Bevinding(
                            "fout", k,
                            f"zegt '{citaat}', maar er staan er {len(gepubliceerd)} "
                            f"in {pad}/: {namen}",
                        ))
                    if verweesd:
                        bevindingen.append(Bevinding(
                            "fout", k,
                            f"heeft in {pad}/ een thema-map waar het boek zelf niet naar "
                            f"linkt: {', '.join(verweesd)} -- die bereikt geen lezer",
                        ))

    return bevindingen, len(kaartjes), getoetst


def main() -> int:
    ap = argparse.ArgumentParser(description="toetst de beloftes op de plank")
    ap.add_argument("--plank", default="oefenboeken/index.qmd",
                    help="pad naar de plank, relatief aan de reporoot")
    ap.add_argument("--wortel", default=None, help="reporoot (standaard: die van dit script)")
    ap.add_argument("--stil", action="store_true", help="alleen iets zeggen als er iets mis is")
    args = ap.parse_args()

    wortel = args.wortel or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    plank = os.path.join(wortel, args.plank)
    if not os.path.isfile(plank):
        print(f"plankwacht: {args.plank} bestaat niet -- niets gemeten")
        return 3

    bevindingen, aantal_kaartjes, getoetst = toets(wortel, args.plank)
    fouten = [b for b in bevindingen if b.soort == "fout"]
    blind = [b for b in bevindingen if b.soort == "blind"]

    if fouten or blind or not args.stil:
        print(f"plankwacht: {aantal_kaartjes} kaartjes, {getoetst} belofte(s) nagerekend "
              f"tegen de bestanden")

    for b in fouten:
        print(f"  FOUT  {b.kaartje.titel} (regel {b.kaartje.regel}): {b.regel}")
    for b in blind:
        print(f"  BLIND {b.kaartje.titel} (regel {b.kaartje.regel}): {b.regel}")

    if fouten:
        return 1
    if blind:
        return 3
    if getoetst == 0:
        # Geen fouten, maar ook niets gemeten. Dat is geen schone plank.
        print("  BLIND geen enkele belofte herkend -- is de formulering veranderd?")
        return 3
    if not args.stil:
        print("  alle nagerekende beloftes kloppen")
    return 0


if __name__ == "__main__":
    sys.exit(main())
