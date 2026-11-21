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
     tegen de laatste commit die de boekmap van dat kaartje raakte -- met
     uitzondering van commits die daar alleen de bezoekersteller toevoegden
     (zie `is_tellercommit`). Die worden altijd bij naam genoemd.
  2. "<telwoord> van de <telwoord> thema's staan online" (Psychometrie) en de
     kale vorm "<telwoord> thema's" (MVDA), tegen het aantal thema-mappen dat
     er staat én vanuit het boek zelf gelinkt is.

     De NOEMER blijft handwerk: "van de zeven" is een plan, en een plan staat
     niet op schijf. Wat hier nagerekend wordt is de teller. Zeg dat erbij als
     iemand vraagt hoeveel de wachter dekt -- anders lijkt het kaartje
     helemaal bewaakt.
  3. "<telwoord> hoofdstukken" en "<telwoord> bijlagen" (OZP 1, sinds
     28-10-2026), tegen de mappen waar het boek vanaf zijn index naar linkt.
     Een map is een bijlage als een link ernaar "Bijlage" als label draagt --
     zo noemt de zijbalk ze zelf ("Bijlage · Je formuleblad"); de rest is een
     hoofdstuk, `00_` incluis, want het kaartje telt "fundament" mee.
     Aanleiding: het advies voor die zin zei "twee bijlagen", het boek had er
     drie, en "Dertien hoofdstukken" stond er al maanden zonder dat iets het
     narekende. Een woord dat geen telwoord is ("Alle hoofdstukken") is geen
     belofte en wordt overgeslagen, zoals bij de kale thema-vorm.
  4. De spiegel (sinds 14-11-2026, zie `spiegel`): elk kaartje met een link
     staat ook op de Engelse plank (`en/workbooks/index.qmd`), in dezelfde
     volgorde, en elk vak-kaartje wordt gelinkt vanaf de kaart "Oefenboeken" op
     `index.qmd` -- en elk Engels vak-kaartje vanaf "Practice books" op
     `en/index.qmd`. Dat zijn geen getallen maar plekken die met de plank mee
     moeten; Ben besliste op 14-11 dat ze dat doen. Ze tellen niet mee in
     "belofte(s) nagerekend": de spiegel meldt zijn eigen telling.

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
    python3 _tools/plankwacht.py --en-plank <pad> --thuis <pad> --en-thuis <pad>
                                                  # de spiegel tegen andere bestanden
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys

# De tellerregel komt uit het ene bestand dat weet hoe hij eruitziet, niet
# overgetikt: een tweede schrijfwijze hier zou stil uiteenlopen met de eerste.
# Zonder bytecode: de wachter draait in `naar_buiten.sh` vóór de toets op
# ongecommit werk, en een verse `_tools/__pycache__/` liet die toets in een repo
# zonder .gitignore-regel vallen (plankwacht_test.sh, zaak 8). Een wachter mag
# de werkkopie die hij bewaakt niet vuil maken.
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tellerregel import REGEL, soort  # noqa: E402

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

# "Dertien hoofdstukken: ..." en "Achterin drie bijlagen: ..." (OZP 1).
RE_HOOFDSTUKKEN = re.compile(r"([A-Za-zé]+)\s+hoofdstukken\b", re.IGNORECASE)
RE_BIJLAGEN = re.compile(r"([A-Za-zé]+)\s+bijlagen\b", re.IGNORECASE)

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
        self.vak = False            # draagt het blok .cc-boek-vak (een kaartje voor één vak)?
        self.kop = ""               # de kopregel met de link, zoals hij in de .qmd staat

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
        regels = zonder_commentaar(f.read()).splitlines()

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

        titel, href, kop = "(kop niet gevonden)", None, ""
        for r in lijf:
            m = RE_KOP_MET_LINK.match(r.strip())
            if m:
                titel, href, kop = m.group("titel").strip(), m.group("href").strip(), r.strip()
                break
            m = RE_KOP_KAAL.match(r.strip()) if r.strip().startswith("#") else None
            if m:
                titel = m.group("titel").strip()
                break

        k = Kaartje(titel, href, start + 1)
        k.kop = kop
        k.tekst = lijf
        k.vak = ".cc-boek-vak" in regels[start]
        kaartjes.append(k)
    return kaartjes


def zonder_commentaar(tekst: str) -> str:
    """Elk `<!-- ... -->` leeg, met zijn regelovergangen bewaard.

    Een commentaar is geen kaartje en geen belofte aan een lezer. Op de Engelse
    plank staat een voorbeeldkaart in een BEN-notitie ("WANNEER EEN ENGELS
    OEFENBOEK LANDT"), ingesprongen. Gemeten 14-11-2026: zonder dit las de
    wachter hem als het kaartje "Psychometrics Practice Book" met een link, en
    omdat de ingesprongen sluitregel niet telt, slikte hij de echte kaart
    erna ("The R practice book") in. De regelovergangen blijven staan, zodat
    elk regelnummer in een melding nog klopt.
    """
    return re.sub(r"<!--.*?-->", lambda m: "\n" * m.group(0).count("\n"), tekst, flags=re.S)


def boekmap(plank_pad: str, href: str) -> str:
    """Van de link in de kop naar de map, relatief aan de reporoot.

    `ozp1/index.html` naast `oefenboeken/index.qmd` wordt `oefenboeken/ozp1`;
    `../manuscript/handleiding/index.html` wordt `manuscript/handleiding`.
    """
    plank_map = os.path.dirname(plank_pad) or "."
    doel = os.path.normpath(os.path.join(plank_map, href))
    return os.path.dirname(doel)


def is_tellercommit(wortel: str, commit: str, pad: str) -> bool:
    """Deed deze commit binnen `pad/` NIETS anders dan de teller toevoegen?

    Waarom dit bestaat: op 30-9-2026 kreeg elke oefenboek-bladzij de onzichtbare
    GoatCounter-regel (commit b9fd33a). Daarmee werd dát de laatste verandering
    aan `oefenboeken/ozp1/`, en eiste de wachter "Bijgewerkt 30 september" --
    voor een regel die geen lezer ooit ziet. Ben koos 30-9: leer de wachter zo'n
    commit over te slaan, in plaats van een datum op het kaartje te zetten die
    niets over het boek zegt.

    Beslist wordt op de ECHTE diff, nooit op de commitboodschap: een boodschap
    is een bewering. Streng, per bestand:
      * geen enkele weggehaalde regel,
      * elke toegevoegde regel is (op inspringing na) precies `tellerregel.REGEL`,
      * geen nieuw, verwijderd, hernoemd of binair bestand, geen modewissel.
    Eén afwijking en de commit telt gewoon mee -- een commit die de teller
    toevoegt ÉN iets anders verandert, is een echte verandering.

    Bij een merge wordt tegen de eerste ouder vergeleken: dat is wat er op deze
    lijn binnenkwam.
    """
    uit = subprocess.run(
        ["git", "show", "-U0", "--format=", "--no-renames", "--no-color",
         "--no-ext-diff", "--diff-merges=first-parent", commit, "--", pad + "/"],
        cwd=wortel, capture_output=True, text=True, check=True,
    )
    toegevoegd = 0
    for regel in uit.stdout.splitlines():
        if regel.startswith(("diff --git ", "index ", "--- a/", "+++ b/", "@@ ")):
            continue
        if regel.startswith("+"):
            if regel[1:].strip() != REGEL:
                return False
            toegevoegd += 1
            continue
        # Alles wat hier nog komt -- een '-'-regel, "new file mode",
        # "deleted file mode", "Binary files ...", "--- /dev/null",
        # "\ No newline at end of file" -- is meer dan de teller erbij zetten.
        return False
    # Een lege diff (niets binnen pad/) is geen tellercommit maar een raadsel;
    # die laten we meetellen in plaats van hem stil weg te poetsen.
    return toegevoegd > 0


def is_doorstuurcommit(wortel: str, commit: str, pad: str) -> bool:
    """Zette deze commit binnen `pad/` NIETS anders neer dan doorstuurders?

    Waarom dit bestaat: op 1-10-2026 kregen de oude adressen van OZP 1-thema 3
    en 4 (gewisseld op 19-9) een doorstuurder, en die staan nu eenmaal ÍN
    `oefenboeken/ozp1/`. Zonder deze uitzondering eiste de wachter daarna
    "Bijgewerkt 1 oktober" -- voor een bestand dat geen lezer ooit leest, want
    het stuurt hem binnen nul seconden door. Dat is dezelfde vorm als de
    tellercommit van 30-9, en Ben koos daar voor overslaan.

    Streng, per bestand, op de INHOUD en niet op de naam of de boodschap:
      * een toegevoegd bestand is een doorstuurder
        (`tellerregel.soort`: een `<head>` met een meta-refresh);
      * een gewijzigd bestand was een doorstuurder én is er een -- een echte
        bladzij die door een doorstuurder wordt VERVANGEN is een boekwijziging:
        die inhoud staat daar niet meer;
      * een verwijderd bestand wás een doorstuurder;
      * alleen `.html` kan een doorstuurder zijn: een figuur, css of data in
        dezelfde commit is een echte wijziging, en wordt dus nooit gelezen --
        de eerste versie las een PNG als tekst en viel om (nakijker, 1-10-2026);
      * geen hernoeming, geen bestand dat niet te lezen is.
    Eén echte bladzij erbij, weg of anders, en de commit telt gewoon mee.
    """
    uit = subprocess.run(
        ["git", "-c", "core.quotepath=off", "show", "--format=", "--name-status",
         "--no-renames", "--diff-merges=first-parent", commit, "--", pad + "/"],
        cwd=wortel, capture_output=True, text=True, check=True,
    )
    regels = [r for r in uit.stdout.splitlines() if r.strip()]
    if not regels:
        return False
    for r in regels:
        status, _, bestand = r.partition("\t")
        if not bestand.endswith(".html"):
            return False
        versies = {"A": [commit], "M": [commit + "^", commit], "D": [commit + "^"]}.get(status)
        if versies is None:
            return False
        for versie in versies:
            inhoud = subprocess.run(
                ["git", "-c", "core.quotepath=off", "show", f"{versie}:{bestand}"],
                cwd=wortel, capture_output=True)
            tekst = inhoud.stdout.decode("utf-8", errors="replace")
            if inhoud.returncode != 0 or soort(tekst) != "doorstuurder":
                return False
    return True


def laatste_commitdatum(wortel: str, pad: str) -> tuple[str | None, str, list[str], list[str]]:
    """(datum als JJJJ-MM-DD, toelichting, overgeslagen tellercommits,
    overgeslagen doorstuurcommits).

    Datum None = kon niet kijken. Beide lijsten overgeslagen commits gaan altijd
    mee naar buiten: een overslag die je niet ziet, is een gat.
    """
    vol = os.path.join(wortel, pad)
    if not os.path.isdir(vol):
        return None, f"de map {pad}/ bestaat niet", [], []
    try:
        uit = subprocess.run(
            ["git", "log", "--format=%h%x09%ad%x09%s", "--date=short", "--", pad + "/"],
            cwd=wortel, capture_output=True, text=True, check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        return None, f"git gaf geen antwoord op {pad}/ ({e})", [], []
    if not uit.stdout.strip():
        return None, (
            f"geen enkele commit raakt {pad}/ -- is dit een ondiepe kloon "
            f"(actions/checkout zonder fetch-depth)?"
        ), [], []
    overgeslagen: list[str] = []
    doorgestuurd: list[str] = []
    for r in uit.stdout.strip().splitlines():
        kort, datum, onderwerp = (r.split("\t", 2) + ["", ""])[:3]
        try:
            alleen_teller = is_tellercommit(wortel, kort, pad)
            alleen_doorstuur = (not alleen_teller) and is_doorstuurcommit(wortel, kort, pad)
        except subprocess.CalledProcessError as e:
            return None, f"git show {kort} gaf geen antwoord op {pad}/ ({e})", overgeslagen, doorgestuurd
        if alleen_teller:
            overgeslagen.append(kort)
            continue
        if alleen_doorstuur:
            doorgestuurd.append(kort)
            continue
        return datum, f"{kort} {onderwerp}", overgeslagen, doorgestuurd
    return None, (
        f"elke commit op {pad}/ zette alleen de teller of een doorstuurder erin "
        f"({len(overgeslagen) + len(doorgestuurd)} stuks) -- dan is er geen boekdatum "
        f"om na te rekenen"
    ), overgeslagen, doorgestuurd


def alleen_doorstuurders(map_: str) -> bool:
    """Staat er in deze map minstens één html, en is elke html een doorstuurder?

    `oefenboeken/ozp1/03_normaalverdeling_z/` is sinds 1-10-2026 zo'n map: het
    oude adres van wat nu thema 4 is. Dat is geen thema en ook geen verweesde
    bladzij, maar een wegwijzer. Een lege map telt NIET als doorstuurmap -- die
    blijft gewoon een (verweesd) thema, zodat een halve publicatie niet
    stilletjes uit beeld verdwijnt.
    """
    htmls = []
    for dp, _dn, fn in os.walk(map_):
        htmls += [os.path.join(dp, f) for f in fn if f.endswith(".html")]
    if not htmls:
        return False
    for p in htmls:
        with open(p, encoding="utf-8", errors="ignore") as f:
            if soort(f.read()) != "doorstuurder":
                return False
    return True


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
        and not alleen_doorstuurders(os.path.join(vol, d))
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


def hoofdstukken_en_bijlagen(wortel: str, pad: str) -> tuple[list[str], list[str], str | None]:
    """(hoofdstukken, bijlagen, reden-om-niet-te-kunnen-kijken).

    Telt, net als `gepubliceerde_themas`, alleen mappen die er staan én waar de
    index naar linkt. Anders dan daar telt `00_` wél mee: "Dertien
    hoofdstukken: van fundament ..." rekent Deel 0 erbij. Een doorstuurmap
    wordt hier niet apart weggefilterd: het boek linkt niet naar zijn eigen
    oude adressen, en doet het dat ooit wel, dan klopt de telling niet meer en
    zegt de wachter dat hardop -- dat is de goede kant om fout te gaan.
    Een map is een bijlage zodra één link ernaar een label heeft dat met
    "Bijlage" begint. Dat label staat in de zijbalk die Quarto uit het boek
    zelf bouwt -- geen tweede lijstje dat hier kan verouderen.
    """
    vol = os.path.join(wortel, pad)
    if not os.path.isdir(vol):
        return [], [], f"de map {pad}/ bestaat niet"
    index = os.path.join(vol, "index.html")
    if not os.path.isfile(index):
        return [], [], f"{pad}/index.html bestaat niet, dus er valt niets te tellen"
    with open(index, encoding="utf-8", errors="ignore") as f:
        html = f.read()
    labels: dict[str, list[str]] = {}
    for m in re.finditer(r'<a\s[^>]*href="\.?/?(\d{2}_[A-Za-z0-9_]+)/[^"]*"[^>]*>(.*?)</a>', html, re.S):
        tekst = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", m.group(2))).strip()
        labels.setdefault(m.group(1), []).append(tekst)
    mappen = sorted(d for d in labels if os.path.isdir(os.path.join(vol, d)))
    bijlagen = [d for d in mappen if any(t.lower().startswith("bijlage") for t in labels[d])]
    hoofdstukken = [d for d in mappen if d not in bijlagen]
    return hoofdstukken, bijlagen, None


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

        # "Dertien hoofdstukken", "drie bijlagen": alleen waar het woord een
        # telwoord is. Elk voorkomen telt, niet alleen het eerste.
        delen = [
            (soort_deel, kaal.group(1))
            for soort_deel, patroon in (("hoofdstukken", RE_HOOFDSTUKKEN),
                                        ("bijlagen", RE_BIJLAGEN))
            for kaal in patroon.finditer(k.body)
            if kaal.group(1).lower() in TELWOORDEN
        ]

        if not (heeft_datum or heeft_telling or delen):
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
                echt, waaruit, overgeslagen, doorgestuurd = laatste_commitdatum(wortel, pad)
                if overgeslagen:
                    bevindingen.append(Bevinding(
                        "overgeslagen", k,
                        f"{len(overgeslagen)} tellercommit(s) overgeslagen in {pad}/: "
                        f"{', '.join(overgeslagen)} -- die zetten alleen de "
                        f"bezoekersteller erin",
                    ))
                if doorgestuurd:
                    bevindingen.append(Bevinding(
                        "overgeslagen", k,
                        f"{len(doorgestuurd)} doorstuurcommit(s) overgeslagen in {pad}/: "
                        f"{', '.join(doorgestuurd)} -- die zetten alleen doorstuurders "
                        f"op oude adressen, geen boektekst",
                    ))
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

        # ---- 3. hoofdstukken en bijlagen -----------------------------
        if delen:
            hoofdstukken, bijlagen, reden = hoofdstukken_en_bijlagen(wortel, pad)
            if reden:
                bevindingen.append(Bevinding("blind", k, reden))
            else:
                echt = {"hoofdstukken": hoofdstukken, "bijlagen": bijlagen}
                for soort_deel, woord in delen:
                    getoetst += 1
                    gevonden = echt[soort_deel]
                    if len(gevonden) != TELWOORDEN[woord.lower()]:
                        bevindingen.append(Bevinding(
                            "fout", k,
                            f"zegt '{woord} {soort_deel}', maar er staan er "
                            f"{len(gevonden)} in {pad}/: {', '.join(gevonden) or 'geen enkele'}",
                        ))

    return bevindingen, len(kaartjes), getoetst


# ------------------------------------------------------------------
# De spiegel (14-11-2026): staat elk boek ook waar de lezer het zoekt?
# ------------------------------------------------------------------
# Drie plekken lopen met de Nederlandse plank mee, en geen van de drie werd
# nagerekend. Op 12-11 kwam Toetsende Statistiek op de Nederlandse plank, en
# twee dagen lang stond hij niet op de Engelse; niets zei het (site_wegen,
# 14-11). Ben besliste die dag: de vakken bovenaan, Engels in dezelfde
# volgorde, en de thuiskaart noemt de vakken.
#   a. elk kaartje met een link op de Nederlandse plank staat ook op de
#      Engelse, en in dezelfde volgorde -- vergeleken op het DOEL van de link,
#      niet op de titel, want die is daar Engels;
#   b. elk vak-kaartje (.cc-boek-vak) met een link op de Nederlandse plank wordt
#      gelinkt vanaf de kaart "Oefenboeken" op de Nederlandse thuispagina;
#   c. idem voor de Engelse plank en de kaart "Practice books" op en/index.qmd;
#   d. het taalmerk (21-11-2026, Ben: "Ja, taalmerk erop"). Het EN- of NL-merk
#      vóór een titel staat niet in de tekst; styles.css maakt het uit het
#      hreflang van de link. Een link zonder hreflang verliest zijn merk dus
#      zonder dat iemand het ziet, en een verkeerd hreflang laat het merk
#      liegen. Daarom: elk kaartje met een link op de Engelse plank, en elke link
#      naar een boek op de Engelse thuiskaart, draagt hreflang; dat is "en" als
#      de link in en/ uitkomt en anders "nl"; en "(in Dutch)" staat in de titel
#      als en alleen als het "nl" is.
# Wat hij NIET ziet: of de tekst op de twee planken hetzelfde zegt, en
# kaartjes zonder link (OZP 2, STAT 3 -- die mogen in het Engels wegblijven).
# Een Engels kaartje dat naar een Engels boek wijst, is voor (a) geen
# afwijking: het staat er naast het Nederlandse, niet in plaats ervan.
EN_PLANK = "en/workbooks/index.qmd"
THUIS = "index.qmd"
EN_THUIS = "en/index.qmd"
THUISKAART = "cc-card-werkboeken"
RE_MD_LINK = re.compile(r"\]\(([^)\s]+)[^)]*\)")


def doel_van(van: str, href: str) -> str | None:
    """Een link, zoals hij in `van` staat, als pad vanaf de reporoot.

    `ts/index.html` in `oefenboeken/index.qmd` en `../../oefenboeken/ts/index.html`
    in `en/workbooks/index.qmd` worden allebei `oefenboeken/ts/index.html`. Een
    link naar een `.qmd` telt als zijn `.html`, en een map als zijn index.
    Adressen buiten de site (mailto:, https:) geven None.
    """
    href = href.split("#", 1)[0].split("?", 1)[0]
    if not href or re.match(r"^[a-z][a-z0-9+.-]*:", href) or href.startswith("//"):
        return None
    if href.endswith("/"):
        href += "index.html"
    pad = os.path.normpath(os.path.join(os.path.dirname(van), href))
    return pad[:-4] + ".html" if pad.endswith(".qmd") else pad


def thuiskaart_links(wortel: str, thuis: str) -> tuple[set[str], str | None]:
    """(doelen van de links in de kaart THUISKAART, reden-om-niet-te-kunnen-kijken)."""
    vol = os.path.join(wortel, thuis)
    if not os.path.isfile(vol):
        return set(), f"{thuis} bestaat niet"
    with open(vol, encoding="utf-8") as f:
        regels = zonder_commentaar(f.read()).splitlines()
    for i, r in enumerate(regels):
        if r.lstrip().startswith("::: {.cc-card") and THUISKAART in r:
            blok = []
            for r2 in regels[i + 1:]:
                if re.fullmatch(r":{3,}\s*", r2):
                    break
                blok.append(r2)
            doelen = {doel_van(thuis, h) for h in RE_MD_LINK.findall("\n".join(blok))}
            return doelen - {None}, None
    return set(), f"{thuis} heeft geen kaart {{.{THUISKAART}}}"


# een link met wat erachter staat: "[titel](href){hreflang="nl"}"
RE_MD_LINK_VOL = re.compile(r"\[(?P<tekst>[^\]]*)\]\((?P<href>[^)\s]+)[^)]*\)(?P<attr>\{[^}]*\})?")
RE_HREFLANG = re.compile(r'\bhreflang="([^"]*)"')


def taal_van(doel: str) -> str:
    """De taal van een bladzij op de site, uit haar pad: alles onder en/ is Engels."""
    return "en" if doel.startswith("en/") else "nl"


def taalmerk_fouten(titel: str, attr: str, doel: str) -> str | None:
    """Wat er mis is met het taalmerk van één link, of None."""
    m = RE_HREFLANG.search(attr or "")
    wil = taal_van(doel)
    if not m:
        return (f"heeft geen hreflang, dus geen taalmerk vóór de titel (styles.css maakt het "
                f"daaruit). Zet {{hreflang=\"{wil}\"}} direct achter de link")
    if m.group(1) != wil:
        return (f"draagt hreflang=\"{m.group(1)}\", maar wijst naar {doel}, en dat is \"{wil}\": "
                f"het taalmerk zou dan liegen")
    if wil == "nl" and "(in Dutch)" not in titel:
        return (f"wijst naar een Nederlandse bladzij ({doel}), maar de titel zegt geen "
                f"\"(in Dutch)\" (Ben, 21-11-2026: \"Ja, taalmerk erop\")")
    if wil == "en" and "(in Dutch)" in titel:
        return f"zegt \"(in Dutch)\", maar wijst naar een Engelse bladzij ({doel})"
    return None


def thuiskaart_taal(wortel: str, thuis: str) -> list[tuple[str, str, str, int]]:
    """(linktekst, href, attributen, regelnummer) van elke link in de kaart THUISKAART."""
    with open(os.path.join(wortel, thuis), encoding="utf-8") as f:
        regels = zonder_commentaar(f.read()).splitlines()
    uit = []
    for i, r in enumerate(regels):
        if r.lstrip().startswith("::: {.cc-card") and THUISKAART in r:
            for j, r2 in enumerate(regels[i + 1:], i + 2):
                if re.fullmatch(r":{3,}\s*", r2):
                    break
                for m in RE_MD_LINK_VOL.finditer(r2):
                    uit.append((m.group("tekst"), m.group("href"), m.group("attr") or "", j))
            break
    return uit


def spiegel(wortel: str, plank: str, en_plank: str, thuis: str, en_thuis: str
            ) -> tuple[list[Bevinding], str]:
    """(bevindingen, één regel met wat er gemeten is)."""
    uit: list[Bevinding] = []
    nl = [k for k in lees_kaartjes(os.path.join(wortel, plank)) if k.href]
    nl_doel = [doel_van(plank, k.href) for k in nl]
    if not nl:
        # Niets om te spiegelen is geen schone spiegel.
        return [Bevinding("blind", Kaartje(plank, None, 1),
                          "geen enkel kaartje met een link -- niets om te spiegelen")], ""
    if not os.path.isfile(os.path.join(wortel, en_plank)):
        return [Bevinding("blind", Kaartje(en_plank, None, 1),
                          f"bestaat niet, dus niet na te gaan of de {len(nl)} boeken van {plank} "
                          f"er ook staan")], ""
    en = [k for k in lees_kaartjes(os.path.join(wortel, en_plank)) if k.href]
    en_doel = [doel_van(en_plank, k.href) for k in en]

    # a. elk boek ook op de Engelse plank, en in dezelfde volgorde
    for k, d in zip(nl, nl_doel):
        if d not in en_doel:
            uit.append(Bevinding("fout", k,
                f"staat niet op {en_plank} -- geen enkel kaartje daar linkt naar {d}. "
                f"Zet er een kaart bij, met \"(in Dutch)\" in de titel en hreflang=\"nl\""))
    # Elk doel één keer, op de plek waar het voor het eerst staat.
    gedeeld_nl = [d for i, d in enumerate(nl_doel) if d in en_doel and d not in nl_doel[:i]]
    gedeeld_en = [d for i, d in enumerate(en_doel) if d in nl_doel and d not in en_doel[:i]]
    if gedeeld_nl != gedeeld_en:
        # Zelfde verzameling, dus zelfde lengte: er is een eerste plek die verschilt.
        p = next(i for i, (x, y) in enumerate(zip(gedeeld_nl, gedeeld_en)) if x != y)
        titel_nl = nl[nl_doel.index(gedeeld_nl[p])].titel
        uit.append(Bevinding("fout", en[en_doel.index(gedeeld_en[p])],
            f"staat in de verkeerde volgorde: van de {len(gedeeld_nl)} boeken die op allebei "
            f"staan, is dit nummer {p + 1} op {en_plank}, en op {plank} is nummer {p + 1} "
            f"'{titel_nl}' -- de Engelse plank volgt de Nederlandse in dezelfde volgorde "
            f"(Ben, 14-11-2026)"))

    # b en c. elk vak ook op de thuiskaart
    gemeten = []
    for plank_pad, kaartjes, doelen, thuispad in ((plank, nl, nl_doel, thuis),
                                                  (en_plank, en, en_doel, en_thuis)):
        vakken = [(k, d) for k, d in zip(kaartjes, doelen) if k.vak]
        links, reden = thuiskaart_links(wortel, thuispad)
        if reden:
            uit.append(Bevinding("blind", Kaartje(thuispad, None, 1),
                                 f"{reden}, dus niet na te gaan of de thuiskaart de "
                                 f"{len(vakken)} vakken van {plank_pad} noemt"))
            continue
        for k, d in vakken:
            if d not in links:
                uit.append(Bevinding("fout", k,
                    f"is een vak op {plank_pad}, maar de kaart {{.{THUISKAART}}} op {thuispad} "
                    f"linkt niet naar {d} -- de thuiskaart noemt elk vak (Ben, 14-11-2026)"))
        gemeten.append(f"{len(vakken)} vak(ken) van {plank_pad} op {thuispad}")

    # d. het taalmerk: op de Engelse plank elk kaartje met een link, op de
    #    Engelse thuiskaart elke link die naar een boek van een van de planken wijst
    #    (de kop "Practice books" en een link naar de plank zelf zijn geen boek).
    merk_plank = 0
    for k, d in zip(en, en_doel):
        m = RE_MD_LINK_VOL.search(k.kop)
        attr = (m.group("attr") or "") if m else ""
        fout = taalmerk_fouten(k.titel, attr, d)
        merk_plank += 1
        if fout:
            uit.append(Bevinding("fout", k, f"{fout} (taalmerk)"))
    boeken = set(nl_doel) | set(en_doel)
    merk_thuis = 0
    if os.path.isfile(os.path.join(wortel, en_thuis)):
        for tekst, href, attr, regelnr in thuiskaart_taal(wortel, en_thuis):
            d = doel_van(en_thuis, href)
            if d not in boeken:
                continue
            merk_thuis += 1
            fout = taalmerk_fouten(tekst, attr, d)
            if fout:
                uit.append(Bevinding("fout", Kaartje(f"{en_thuis}: [{tekst}]", href, regelnr),
                                     f"{fout} (taalmerk)"))
    merkregel = f"taalmerk nagelopen: {merk_plank} titel(s) op {en_plank}, {merk_thuis} op {en_thuis}"

    regel = (f"spiegel: {len(nl)} boek(en) met een link op {plank}, "
             f"{len(gedeeld_nl)} daarvan ook op {en_plank}"
             + (", in dezelfde volgorde" if gedeeld_nl == gedeeld_en else "")
             + (f"; nagelopen: {' en '.join(gemeten)}" if gemeten else "")
             + f"; {merkregel}")
    return uit, regel


def main() -> int:
    ap = argparse.ArgumentParser(description="toetst de beloftes op de plank")
    ap.add_argument("--plank", default="oefenboeken/index.qmd",
                    help="pad naar de plank, relatief aan de reporoot")
    ap.add_argument("--wortel", default=None, help="reporoot (standaard: die van dit script)")
    ap.add_argument("--stil", action="store_true", help="alleen iets zeggen als er iets mis is")
    ap.add_argument("--en-plank", default=EN_PLANK, help="de Engelse plank (voor de spiegel)")
    ap.add_argument("--thuis", default=THUIS, help="de Nederlandse thuispagina (voor de spiegel)")
    ap.add_argument("--en-thuis", default=EN_THUIS, help="de Engelse thuispagina (voor de spiegel)")
    args = ap.parse_args()

    wortel = args.wortel or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    plank = os.path.join(wortel, args.plank)
    if not os.path.isfile(plank):
        print(f"plankwacht: {args.plank} bestaat niet -- niets gemeten")
        return 3

    bevindingen, aantal_kaartjes, getoetst = toets(wortel, args.plank)
    gespiegeld, spiegelregel = spiegel(wortel, args.plank, args.en_plank, args.thuis, args.en_thuis)
    bevindingen += gespiegeld
    fouten = [b for b in bevindingen if b.soort == "fout"]
    blind = [b for b in bevindingen if b.soort == "blind"]
    overgeslagen = [b for b in bevindingen if b.soort == "overgeslagen"]

    # Een overgeslagen tellercommit wordt ALTIJD genoemd, ook met --stil: de
    # wachter kijkt dan bewust langs een commit heen, en dat moet je kunnen zien.
    if fouten or blind or overgeslagen or not args.stil:
        print(f"plankwacht: {aantal_kaartjes} kaartjes, {getoetst} belofte(s) nagerekend "
              f"tegen de bestanden")

    # De spiegel zegt altijd hoeveel hij zag, ook als alles klopt: een spiegel
    # die nul boeken vergeleek, mag niet lezen als een spiegel die er nul miste.
    if spiegelregel and (fouten or blind or overgeslagen or not args.stil):
        print(f"  {spiegelregel}")
    for b in overgeslagen:
        print(f"  NB    {b.kaartje.titel} (regel {b.kaartje.regel}): {b.regel}")
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
