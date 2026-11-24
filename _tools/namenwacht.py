#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""namenwacht.py — geen voornaam van een testlezer in een bestand van deze repo.

    python3 _tools/namenwacht.py                  de wacht: afloop 1 bij een naam buiten
                                                  de uitzonderingen
    python3 _tools/namenwacht.py inventaris       elke treffer, per bestand, met waar hij
                                                  staat (commentaar, notitie, zichtbaar ...)
    python3 _tools/namenwacht.py inventaris --rev <rev>
                                                  hetzelfde op een eerdere stand (de telling
                                                  "voor"), uit git gelezen, niet uit de map
    python3 _tools/namenwacht.py --bereik <bereik>
                                                  de wacht, en ook alles wat een push van
                                                  <bereik> nieuw openbaar maakt: de
                                                  commitberichten en elke tussenversie van een
                                                  bestand (bv. origin/main..HEAD)
    python3 _tools/namenwacht.py vergelijk <rev> [pad ...]
                                                  de proef "alleen commentaar veranderd": elk
                                                  bestand dat sinds <rev> veranderde, oud en
                                                  nieuw zonder commentaar, naast elkaar
    python3 _tools/namenwacht.py --repo <map> ... alles hierboven op een andere git-werkkopie
                                                  (de bijtproef: een wegwerprepo)
    --toon                                        de namen voluit in de uitvoer (alleen hier
                                                  op de machine; zie DE UITVOER)

Getoetst door _tools/tests/namenwacht_test.sh en _tools/tests/namenwacht_mutatieproef.sh.

WAAROM. Deze repo is openbaar (github.com/CountCamp/site). De testlezer-agenten van
het huis dragen de voornaam van echte mensen. Ben, 23-11-2026, op de vraag wat er met
die namen in de site-repo moest gebeuren: "Site + speeltjes schoonmaken" -- de namen
uit elk openbaar bestand, de spoorverslagen in _logs/ naar een plek die niet openbaar
is, en een wachter erop. Wat al in de git-geschiedenis staat, blijft daar (ook Bens
keuze: niet herschrijven). Zie _logs/ in .gitignore.

DE NAMEN STAAN HIER NIET LEESBAAR. Ze staan hieronder in ROT13 (elke letter dertien
plaatsen verschoven) en worden bij het starten teruggezet. Dat is geen geheim -- wie
het wil, zet ze in een seconde terug -- maar het houdt het woord zelf uit deze
openbare repo, uit de zoekmachines en uit de wachter zijn eigen telling. Zonder dat
zou dit bestand zelf op de uitzonderingenlijst moeten, en de toetsen erbij: drie
openbare bestanden met precies de namen die er niet in mogen.

WAT EEN TREFFER IS. Elk voorkomen van een van de namen, in welke schrijfwijze van
hoofd- en kleine letters ook, ook midden in een woord ("...ronde2", een bestandsnaam,
een id). Ook in het PAD van een bestand. Geen woordgrens: een woordgrens zou
"<naam>_ronde2" laten lopen, want _ telt als letter.

WAT HIJ LEEST. Elk bestand dat git kent (`git ls-files`), zoals het nu in de
werkkopie staat -- of met --rev zoals het in die commit stond. Een bestand dat git
kent maar dat er niet staat, of dat niet te openen is, is BLIND (afloop 3): niet
gekeken is geen schoon. Per soort:
    zip            elk lid uitgepakt en gelezen (en een zip in een zip ook)
    gzip/bz2/xz    uitgepakt, ook laag na laag (zo zitten .RData-bestanden in elkaar)
    pdf            de ruwe bytes, elke FlateDecode-stroom uitgepakt, en de tekst
                   zoals die op de bladzij staat (pdftotext). Staat er een pdf in de
                   repo en ontbreekt pdftotext, dan is dat BLIND: zonder kan hij de
                   tekst van een gewone pdf niet lezen (gemeten 24-11: in
                   archief/handleiding-statistiek-2018.pdf staat de tekst in
                   tekenopdrachten die geen enkel woord heel laten). De Actions
                   installeren hem daarom eerst (poppler-utils).
    png            de ruwe bytes en elk zTXt-/iTXt-stuk uitgepakt
    base64         elke "base64,..."-lading (een plaatje, script of svg dat in een
                   bladzij is ingebakken) uitgepakt en net zo gelezen
    de rest        de ruwe bytes
En in elke tekst ook na het terugzetten van HTML-entiteiten (een letter als
&#NN; of &naam; geschreven). Elke run noemt per soort hoeveel stukken hij las.

WAT EEN PUSH NIEUW OPENBAAR MAAKT. Een push publiceert niet alleen de top, maar elke
commit erin: zijn bericht (dat staat in de Actions ook als titel boven elke run) en
elke tussenversie van elk bestand. Met --bereik <bereik> (bv. origin/main..HEAD) leest
hij die ook: de berichten, en elke bestandsversie die vanuit de top bereikbaar is en
vanuit de basis niet. naar_buiten.sh doet dat vóór elke push. Een bereik dat git niet
kent, is BLIND. Wat al op origin/main staat, leest hij niet: dat is de geschiedenis
(zie WAAROM). Gevolg: staat een naam in een tussenversie op een tak, dan is die tak
alleen nog met een squash-merge (één commit) te leveren -- of na het herschrijven van
die tak, vóór hij ooit gepusht is.

WAT HIJ NIET DEKT, en dat staat hier zodat niemand het aanneemt:
  * een naam in de pixels van een plaatje (een schermafdruk van een bladzij);
  * een naam die anders gespeld of in stukken geknipt is (een <span> midden in het
    woord, een Turkse ı in plaats van een i, een pdf die het woord over twee
    tekststukken verdeelt);
  * andere namen dan deze twee. Andere personen in dit huis bewaakt hij niet.
  * de git-geschiedenis, de andere takken op GitHub en de gh-pages-tak: daar staat
    wat er al stond.

DE UITZONDERINGEN staan in _tools/namenwacht_uitzonderingen.tsv, één per regel, elk
met een soort (tijdelijk | blijvend) en een reden. Een regel zonder reden maakt de
wacht BLIND (3): een uitzondering die zich niet kan verantwoorden is een gat. Een
uitzondering die nergens meer op slaat, noemt hij bij elke run ("mag weg").

DE UITVOER. Bij de wacht (en bij inventaris zonder --toon) staat er in plaats van de
naam <naam1> of <naam2>. Reden: deze wachter draait ook in de GitHub Actions van een
openbare repo, en die logboeken zijn openbaar. Een wachter die de naam in zijn
foutmelding herhaalt, publiceert hem zelf.

Afloop (huisafspraak): 0 schoon · 1 een naam gevonden · 3 kon niet kijken.
"""
from __future__ import annotations

import ast
import binascii
import bz2
import codecs
import difflib
import gzip
import html
import io
import lzma
import os
import re
import shutil
import subprocess
import sys
import tokenize
import zipfile
import zlib

sys.dont_write_bytecode = True
HIER = os.path.dirname(os.path.realpath(__file__))
REPO = os.path.dirname(HIER)

# ROT13 van de twee voornamen; zie de kop.
_GECODEERD = ("wrnaar", "zvpuryyr")
NAMEN = tuple(codecs.decode(n, "rot13") for n in _GECODEERD)
NAAM_RX = re.compile("|".join(re.escape(n) for n in NAMEN).encode(), re.I)
# "testlezer" telt in de inventaris mee (met een oordeel), niet in de wacht: het is
# het neutrale woord waar een naam door vervangen wordt.
TESTLEZER_RX = re.compile(rb"test-?lezers?", re.I)

UITZONDERINGEN = os.path.join(HIER, "namenwacht_uitzonderingen.tsv")
SOORTEN = ("tijdelijk", "blijvend")


def zeg(tekst: str = "") -> None:
    """print, maar altijd door het masker (tenzij --toon). Elke uitvoerregel van de
    wacht, de inventaris en de vergelijking gaat hierlangs, ook paden en
    foutmeldingen: een naam kan in een bestandsnaam staan, en dan noemde een losse
    print hem in het openbare logboek van de Actions (gevonden door de bijtproef,
    zaak A9). Een veld dat wordt afgekapt (een regel op 140 tekens) gaat daarnaast
    vóór het afkappen door masker(): anders kon een half afgekapte naam erdoor."""
    print(masker(tekst, TOON))


TOON = False


def masker(tekst: str, toon: bool) -> str:
    """De namen in tekst vervangen door <naam1>/<naam2>, tenzij --toon."""
    if toon:
        return tekst
    # Per naam apart, en niet met NAMEN.index(gevonden.lower()): een hoofdletter als de
    # Turkse İ past wel op het patroon maar wordt bij .lower() iets anders, en dan
    # brak het masker af midden in een foutmelding (nakijker, 24-11).
    for i, n in enumerate(NAMEN):
        tekst = re.sub(re.escape(n), "<naam%d>" % (i + 1), tekst, flags=re.I)
    return tekst


# ---------------------------------------------------------------------------
# Lezen: wat staat er in een bestand, als een lijst (deel, bytes). "deel" is ""
# voor het bestand zelf en bv. "lid data/x.sav" voor wat er in een zip zit.
# ---------------------------------------------------------------------------
def uitpakken(naam: str, b: bytes, diepte: int = 0):
    """[(deel, bytes, manier)] -- het bestand zelf, plus wat erin verpakt zit."""
    uit = [("", b, "rauw")]
    if diepte > 2:
        return uit
    laag = naam.lower()
    if b[:4] == b"PK\x03\x04" or laag.endswith(".zip"):
        with zipfile.ZipFile(io.BytesIO(b)) as z:   # een kapotte zip is een fout: blind
            for lid in z.infolist():
                if lid.is_dir():
                    continue
                inhoud = z.read(lid)
                for deel, bb, manier in uitpakken(lid.filename, inhoud, diepte + 1):
                    uit.append(("lid %s%s" % (lid.filename, (" · " + deel) if deel else ""), bb,
                                "zip" if manier == "rauw" else manier))
        return uit
    for magie, pakker, soort in ((b"\x1f\x8b", gzip.decompress, "gzip"),
                                 (b"BZh", bz2.decompress, "bz2"),
                                 (b"\xfd7zXZ", lzma.decompress, "xz")):
        if b.startswith(magie):
            inhoud = pakker(b)                     # kapot = fout = blind
            # Laag na laag: wat eruit komt kan zelf weer verpakt zijn (een gzip in
            # een gzip, een zip in een .gz).
            for deel, bb, manier in uitpakken(naam, inhoud, diepte + 1):
                uit.append(("uitgepakt (%s)%s" % (soort, (" · " + deel) if deel else ""), bb,
                            soort if manier == "rauw" else manier))
            return uit
    if b.startswith(b"%PDF"):
        n = 0
        for m in re.finditer(rb"stream\r?\n(.*?)\r?\nendstream", b, re.S):
            try:
                uit.append(("pdf-stroom %d" % n, zlib.decompress(m.group(1)), "pdf-stroom"))
            except zlib.error:
                pass                               # niet elke stroom is Flate; de rauwe telt al mee
            n += 1
        if not shutil.which("pdftotext"):
            # Zonder pdftotext is de tekst van een gewone pdf niet te lezen: die staat
            # in tekenopdrachten, met de letters los of in een eigen codering. Dan is
            # dit niet gekeken, en dat zegt de scan hardop (deel zonder bytes = blind).
            uit.append(("pdftotext ontbreekt: de tekst van deze pdf is niet gelezen", None, "blind"))
            return uit
        r = subprocess.run(["pdftotext", "-q", "-", "-"], input=b, capture_output=True)
        if r.returncode != 0:
            uit.append(("pdftotext kon deze pdf niet lezen (afloop %d)" % r.returncode, None, "blind"))
            return uit
        uit.append(("pdftotext", r.stdout, "pdftotext"))
        return uit
    if b.startswith(b"\x89PNG\r\n\x1a\n"):
        i = 8
        while i + 8 <= len(b):
            lengte = int.from_bytes(b[i:i + 4], "big")
            soort = b[i + 4:i + 8]
            data = b[i + 8:i + 8 + lengte]
            if soort == b"zTXt":
                k = data.find(b"\0")
                uit.append(("png zTXt", zlib.decompress(data[k + 2:]), "png-tekst"))
            elif soort == b"iTXt":
                k = data.find(b"\0")
                if data[k + 1:k + 2] == b"\x01":
                    rest = data[k + 3:]
                    for _ in range(2):             # taalcode en vertaald sleutelwoord
                        rest = rest[rest.find(b"\0") + 1:]
                    uit.append(("png iTXt", zlib.decompress(rest), "png-tekst"))
            i += 12 + lengte
        return uit
    if b"base64," in b:
        # Ingebakken plaatjes, scripts en svg's ("data:...;base64,..."): uitpakken en
        # net zo lezen. In search.json staat de / als \/ (JSON), vandaar de \\.
        n = 0
        for m in re.finditer(rb"base64,([A-Za-z0-9+/\\]{16,}={0,2})", b):
            lading = m.group(1).replace(b"\\", b"")
            try:
                inhoud = binascii.a2b_base64(lading + b"=" * (-len(lading) % 4))
            except binascii.Error:
                uit.append(("base64-lading %d" % n, None, "blind"))
                n += 1
                continue
            for deel, bb, manier in uitpakken("lading", inhoud, diepte + 1):
                uit.append(("base64-lading %d%s" % (n, (" · " + deel) if deel else ""), bb,
                            "base64" if manier == "rauw" else manier))
            n += 1
    return uit


def bestanden_nu(repo: str):
    """[(pad, lezer)] voor elk bestand dat git kent, uit de werkkopie."""
    r = subprocess.run(["git", "-C", repo, "ls-files", "-z"], capture_output=True)
    if r.returncode != 0:
        raise RuntimeError("git ls-files: " + r.stderr.decode(errors="replace").strip())
    paden = [p.decode() for p in r.stdout.split(b"\0") if p]

    def lezer(p):
        vol = os.path.join(repo, p)
        if os.path.islink(vol):
            return os.readlink(vol).encode()      # wat git bewaart: het doel, als tekst
        with open(vol, "rb") as f:
            return f.read()
    return [(p, lezer) for p in paden]


def bestanden_op(repo: str, rev: str):
    """[(pad, lezer)] voor elk bestand in commit <rev>, uit git zelf."""
    r = subprocess.run(["git", "-C", repo, "ls-tree", "-r", "-z", "--full-tree", rev],
                       capture_output=True)
    if r.returncode != 0:
        raise RuntimeError("git ls-tree %s: %s" % (rev, r.stderr.decode(errors="replace").strip()))
    blobs = []
    for regel in r.stdout.split(b"\0"):
        if not regel:
            continue
        kop, pad = regel.split(b"\t", 1)
        modus, soort, sha = kop.split()
        if soort == b"blob":
            blobs.append((pad.decode(), sha.decode()))
    inhoud = {}
    if blobs:
        r = subprocess.run(["git", "-C", repo, "cat-file", "--batch"],
                           input="".join(sha + "\n" for _, sha in blobs).encode(),
                           capture_output=True)
        if r.returncode != 0:
            raise RuntimeError("git cat-file: " + r.stderr.decode(errors="replace").strip())
        uit, i = r.stdout, 0
        for _, sha in blobs:
            eind = uit.index(b"\n", i)
            lengte = int(uit[i:eind].split()[2])
            inhoud[sha] = uit[eind + 1:eind + 1 + lengte]
            i = eind + 1 + lengte + 1
    return [(p, (lambda _p, s=sha: inhoud[s])) for p, sha in blobs]


# ---------------------------------------------------------------------------
# Waar staat een treffer? Commentaar vinden per soort bestand. De drie lezers voor
# JavaScript, CSS en HTML zijn overgenomen uit countcamp_lab/boek/_tools/
# persbron_namen.py (23-11-2026), met hun zelfcontrole: elk stuk dat als
# commentaar telt, moet met een opener beginnen, anders liegt de meting.
# ---------------------------------------------------------------------------
REGEX_VOOR = set("(,=:[!&|?{};+-*%<>~^")
REGEX_WOORDEN = {"return", "typeof", "case", "in", "of", "delete", "void", "throw", "new", "else"}


def js_commentaar(s: str, i: int, eind: int):
    """Commentaar in JavaScript tussen i en eind. Kent strings ('…', "…", `…`) en
    regex-letterlijken (/…/vlag), zodat 'https://…' niet als commentaar telt."""
    uit = []
    vorige = ""
    woord = ""
    while i < eind:
        c = s[i]
        if c in "'\"`":
            j = i + 1
            while j < eind and s[j] != c:
                j += 2 if s[j] == "\\" else 1
            i = j + 1
            vorige, woord = c, ""
            continue
        if s.startswith("//", i):
            j = s.find("\n", i, eind)
            j = eind if j < 0 else j
            uit.append((i, j))
            i = j
            continue
        if s.startswith("/*", i):
            j = s.find("*/", i + 2, eind)
            j = eind if j < 0 else j + 2
            uit.append((i, j))
            i = j
            continue
        if c == "/" and (vorige == "" or vorige in REGEX_VOOR or woord in REGEX_WOORDEN):
            j, in_klasse = i + 1, False
            while j < eind and s[j] != "\n":
                if s[j] == "\\":
                    j += 2
                    continue
                if s[j] == "[":
                    in_klasse = True
                elif s[j] == "]":
                    in_klasse = False
                elif s[j] == "/" and not in_klasse:
                    break
                j += 1
            j += 1
            while j < eind and s[j].isalpha():
                j += 1
            i = j
            vorige, woord = "/", ""
            continue
        if not c.isspace():
            if c.isalnum() or c in "_$":
                woord = woord + c if (vorige.isalnum() or vorige in "_$") else c
            else:
                woord = ""
            vorige = c
        i += 1
    return uit


def css_commentaar(s: str, i: int, eind: int):
    uit = []
    while i < eind:
        c = s[i]
        if c in "'\"":
            j = i + 1
            while j < eind and s[j] != c and s[j] != "\n":
                j += 2 if s[j] == "\\" else 1
            i = j + 1
            continue
        if s.startswith("/*", i):
            j = s.find("*/", i + 2, eind)
            j = eind if j < 0 else j + 2
            uit.append((i, j))
            i = j
            continue
        i += 1
    return uit


def html_commentaar(s: str):
    """HTML-commentaar buiten <script>/<style>, plus het commentaar daarbinnen."""
    uit, i, n = [], 0, len(s)
    laag = s.lower()
    while i < n:
        if s.startswith("<!--", i):
            j = s.find("-->", i + 4)
            j = n if j < 0 else j + 3
            uit.append((i, j))
            i = j
            continue
        for tag, lezer in (("script", js_commentaar), ("style", css_commentaar)):
            if laag.startswith("<" + tag, i) and i + 1 + len(tag) < n \
                    and not laag[i + 1 + len(tag)].isalnum():
                open_eind = s.find(">", i)
                sluit = laag.find("</" + tag, open_eind)
                sluit = n if sluit < 0 else sluit
                uit += lezer(s, open_eind + 1, sluit)
                i = sluit
                break
        else:
            i += 1
    return uit


def regel_commentaar(s: str, teken: str):
    """Regels die (na witruimte) met `teken` beginnen: #-commentaar in shell, YAML,
    R, TSV; -- in Lua. Bewust alleen hele regels: een `#` achter code kan net zo goed
    in een string of in ${#x} staan, en een stuk dat ten onrechte als commentaar
    telt, zou in `vergelijk` een codewijziging verbergen. Zo'n regel valt nu als
    code op, en dan kijk je hem na."""
    uit, pos = [], 0
    for r in s.splitlines(keepends=True):
        kaal = r.lstrip()
        if kaal.startswith(teken) and not (pos == 0 and kaal.startswith("#!")):
            a = pos + len(r) - len(kaal)
            uit.append((a, pos + len(r.rstrip("\r\n"))))
        pos += len(r)
    return uit


def qmd_commentaar(s: str):
    """<!-- … --> overal, en in een codeblok ```{r}/```{python} de regels die met #
    beginnen (maar niet #| : dat zijn blokopties, en die doen iets). Een # buiten een
    codeblok is een kop in de lezerstekst, geen commentaar."""
    uit = []
    i = 0
    while True:
        a = s.find("<!--", i)
        if a < 0:
            break
        b = s.find("-->", a + 4)
        b = len(s) if b < 0 else b + 3
        uit.append((a, b))
        i = b
    pos, in_blok = 0, False
    for r in s.splitlines(keepends=True):
        kaal = r.strip()
        if kaal.startswith("```"):
            in_blok = (not in_blok) and kaal.startswith("```{")
        elif in_blok and kaal.startswith("#") and not kaal.startswith("#|"):
            a = pos + len(r) - len(r.lstrip())
            if not any(x <= a < y for x, y in uit):
                uit.append((a, pos + len(r.rstrip("\r\n"))))
        pos += len(r)
    return sorted(uit)


def py_commentaar(s: str):
    """#-commentaar en docstrings van een Python-script (via tokenize)."""
    uit = []
    regels = s.splitlines(keepends=True)
    begin = [0]
    for r in regels:
        begin.append(begin[-1] + len(r))
    vorige = tokenize.NEWLINE
    for tok in tokenize.generate_tokens(io.StringIO(s).readline):
        a = begin[tok.start[0] - 1] + tok.start[1]
        b = begin[tok.end[0] - 1] + tok.end[1]
        if tok.type == tokenize.COMMENT:
            uit.append((a, b))
        elif tok.type == tokenize.STRING and vorige in (tokenize.NEWLINE, tokenize.INDENT,
                                                        tokenize.DEDENT, tokenize.NL):
            uit.append((a, b))                    # een losse string als opdracht: docstring
        if tok.type not in (tokenize.COMMENT, tokenize.NL):
            vorige = tok.type
    return uit


OPENERS = ("/*", "//", "<!--", "#", "--", '"', "'")


def gecontroleerd(s: str, stukken):
    """Elk stuk moet met een opener beginnen; zo niet, dan heeft een lezer hierboven
    zich vergist, en dan zou `vergelijk` code kunnen verbergen. Dat is geen treffer
    maar een kapotte meting."""
    for a, b in stukken:
        if not s.startswith(OPENERS, a) and not re.match(r"[rRbBuUfF]{1,2}['\"]", s[a:a + 3]):
            raise ValueError("stuk op regel %d begint niet met een commentaar-opener: %r"
                             % (s.count("\n", 0, a) + 1, s[a:a + 40]))
    return stukken


SOORT_PER_EXT = {
    ".html": "html", ".htm": "html", ".css": "css", ".js": "js", ".ts": "js",
    ".py": "py", ".qmd": "qmd", ".sh": "regel#", ".yml": "regel#", ".yaml": "regel#",
    ".r": "regel#", ".tsv": "regel#", ".gitignore": "regel#", ".worktreeinclude": "regel#",
    ".lua": "regel--", ".md": "notitie", ".txt": "notitie", ".patch": "notitie",
}


def soort_van(pad: str) -> str:
    naam = os.path.basename(pad).lower()
    ext = os.path.splitext(naam)[1] or (naam if naam.startswith(".") else "")
    return SOORT_PER_EXT.get(ext, "")


def commentaar(pad: str, s: str):
    """Commentaarstukken [(a, b)] van een tekstbestand, of None als dit soort
    bestand geen commentaar kent (een notitie is helemaal tekst)."""
    soort = soort_van(pad)
    if soort == "html":
        return gecontroleerd(s, html_commentaar(s))
    if soort == "css":
        return gecontroleerd(s, css_commentaar(s, 0, len(s)))
    if soort == "js":
        return gecontroleerd(s, js_commentaar(s, 0, len(s)))
    if soort == "py":
        return gecontroleerd(s, py_commentaar(s))
    if soort == "qmd":
        return gecontroleerd(s, qmd_commentaar(s))
    if soort == "regel#":
        return gecontroleerd(s, regel_commentaar(s, "#"))
    if soort == "regel--":
        return gecontroleerd(s, regel_commentaar(s, "--"))
    return None


# ---------------------------------------------------------------------------
# Uitzonderingen
# ---------------------------------------------------------------------------
def lees_uitzonderingen(pad: str):
    """[(patroon, soort, reden, regelnr)]. Een kapotte regel is een ValueError."""
    uit = []
    with open(pad, encoding="utf-8") as f:
        for nr, r in enumerate(f, 1):
            r = r.rstrip("\n")
            if not r.strip() or r.lstrip().startswith("#"):
                continue
            delen = r.split("\t")
            if len(delen) != 3 or not all(d.strip() for d in delen):
                raise ValueError("regel %d: drie kolommen (pad, soort, reden), alle drie gevuld: %r"
                                 % (nr, r))
            patroon, soort, reden = (d.strip() for d in delen)
            if soort not in SOORTEN:
                raise ValueError("regel %d: soort %r, moet %s zijn" % (nr, soort, " of ".join(SOORTEN)))
            if len(reden) < 20:
                raise ValueError("regel %d: reden %r is geen reden" % (nr, reden))
            uit.append((patroon, soort, reden, nr))
    return uit


def valt_onder(pad: str, patroon: str) -> bool:
    """Een patroon met / aan het eind is een map (alles eronder); anders één pad."""
    return pad.startswith(patroon) if patroon.endswith("/") else pad == patroon


# ---------------------------------------------------------------------------
# De scan
# ---------------------------------------------------------------------------
def regel_bij(tekst: str, pos: int):
    nr = tekst.count("\n", 0, pos) + 1
    a = tekst.rfind("\n", 0, pos) + 1
    b = tekst.find("\n", pos)
    return nr, tekst[a:b if b >= 0 else len(tekst)].strip()


def plek(pad: str, tekst: str, pos: int, stukken) -> str:
    """Waar een treffer staat: commentaar, notitie, of iets dat een mens moet nakijken."""
    if stukken is None:
        return "notitie" if soort_van(pad) == "notitie" else "elders"
    for a, b in stukken:
        if a <= pos < b:
            return "commentaar"
    return "geen commentaar"


def scan(bronnen, rx=NAAM_RX, met_plek=False):
    """(treffers, dekking, blind). Een treffer: (pad, deel, regel, plek, regeltekst, gevonden)."""
    treffers, blind = [], []
    dekking = {}
    for pad, lezer in bronnen:
        if rx.search(pad.encode()):
            treffers.append((pad, "pad", 0, "bestandsnaam", pad, rx.search(pad.encode()).group(0).decode()))
        try:
            b = lezer(pad)
        except OSError as e:
            blind.append("%s: niet te lezen (%s)" % (pad, e.strerror or e))
            continue
        try:
            delen = uitpakken(pad, b)
        except Exception as e:  # noqa: BLE001 -- een kapotte verpakking is niet gekeken
            blind.append("%s: niet uit te pakken (%s: %s)" % (pad, type(e).__name__, e))
            continue
        for deel, bb, manier in delen:
            dekking[manier] = dekking.get(manier, 0) + 1
            if bb is None:                        # een stuk dat niet te lezen was (zie uitpakken)
                blind.append("%s: %s" % (pad, deel))
                continue
            if b"&" in bb:
                # Een letter als HTML-entiteit (&#101; of &eacute;) laat het woord voor
                # een zoekopdracht verdwijnen, maar een mens leest het gewoon. Per regel
                # terugzetten; alleen wat er dán bij komt, telt extra (nakijker, 24-11:
                # zo stond er een naam in de kop van deze wachter zelf).
                ruw = bb.decode("utf-8", errors="replace")
                for nr, regel in enumerate(ruw.split("\n"), 1):
                    if "&" not in regel:
                        continue
                    terug = html.unescape(regel)
                    extra = len(rx.findall(terug.encode())) - len(rx.findall(regel.encode()))
                    for _ in range(max(extra, 0)):
                        treffers.append((pad, (deel + " · " if deel else "") + "na HTML-entiteiten", nr,
                                         "na HTML-entiteiten", terug.strip(), ""))
            if not rx.search(bb):
                continue
            tekst = bb.decode("utf-8", errors="replace")
            stukken = None
            if met_plek and not deel:
                try:
                    stukken = commentaar(pad, tekst)
                except (ValueError, tokenize.TokenError, IndentationError, SyntaxError):
                    stukken = "onleesbaar"
            for m in rx.finditer(bb):
                pos = len(bb[:m.start()].decode("utf-8", errors="replace"))
                nr, lijn = regel_bij(tekst, pos)
                if deel:
                    waar = "in " + deel
                elif stukken == "onleesbaar":
                    waar = "onbekend"
                else:
                    waar = plek(pad, tekst, pos, stukken)
                treffers.append((pad, deel, nr, waar, lijn, m.group(0).decode(errors="replace")))
    return treffers, dekking, blind


def dekking_regel(n_bestanden: int, dekking: dict) -> str:
    extra = ", ".join("%s %d" % kv for kv in sorted(dekking.items()) if kv[0] != "rauw")
    pdf = "ja" if shutil.which("pdftotext") else "NEE (een pdf in de repo is dan BLIND)"
    return ("%d bestanden gelezen (rauw %d%s); pdftotext: %s"
            % (n_bestanden, dekking.get("rauw", 0), (", uitgepakt: " + extra) if extra else "", pdf))


# ---------------------------------------------------------------------------
# De wacht
# ---------------------------------------------------------------------------
def berichten(repo: str, bereik: str):
    """(aantal commits, [(sha, regelnr, regel)]) voor de berichten in <bereik>."""
    r = subprocess.run(["git", "-C", repo, "log", "--format=%H%x00%B%x01", bereik, "--"],
                       capture_output=True)
    if r.returncode != 0:
        raise RuntimeError("git log %s: %s" % (bereik, r.stderr.decode(errors="replace").strip()))
    n, uit = 0, []
    for blok in r.stdout.split(b"\x01"):
        blok = blok.strip(b"\n")
        if not blok:
            continue
        sha, _, tekst = blok.partition(b"\0")
        n += 1
        for nr, regel in enumerate(tekst.split(b"\n"), 1):
            for _ in NAAM_RX.finditer(regel):
                uit.append((sha.decode()[:9], nr, regel.decode("utf-8", errors="replace").strip()))
    return n, uit


def blob_inhoud(repo: str, shas):
    """{sha: bytes} voor deze blobs, in één keer uit git cat-file --batch."""
    shas = list(dict.fromkeys(shas))
    if not shas:
        return {}
    r = subprocess.run(["git", "-C", repo, "cat-file", "--batch"],
                       input="".join(s + "\n" for s in shas).encode(), capture_output=True)
    if r.returncode != 0:
        raise RuntimeError("git cat-file: " + r.stderr.decode(errors="replace").strip())
    inhoud, uit, i = {}, r.stdout, 0
    for s in shas:
        eind = uit.index(b"\n", i)
        kop = uit[i:eind].split()
        if len(kop) < 3:
            raise RuntimeError("git cat-file: geen inhoud voor %s (%r)" % (s, uit[i:eind][:60]))
        lengte = int(kop[2])
        inhoud[s] = uit[eind + 1:eind + 1 + lengte]
        i = eind + 1 + lengte + 1
    return inhoud


def nieuwe_versies(repo: str, bereik: str):
    """[(pad, sha)]: elke bestandsversie die een push van <bereik> nieuw openbaar maakt.
    Dat is precies wat `git rev-list --objects <bereik>` noemt -- bereikbaar vanuit de
    top, niet vanuit de basis -- en daarvan alleen de blobs. Wat nu in de index staat,
    leest de wacht al als bestand; dat telt hier niet nog eens.
    Waarom: de wacht las eerst alleen de top. Een naam die op de tak in een tussenversie
    stond en later weer weg is, gaat bij een gewone merge en push tóch mee de openbare
    geschiedenis in (nakijker, 24-11: "--productie toetst alleen de top maar pusht alles";
    op deze tak zelf gebeurde het, in een tussenversie van dit bestand)."""
    r = subprocess.run(["git", "-C", repo, "rev-list", "--objects", bereik, "--"], capture_output=True)
    if r.returncode != 0:
        raise RuntimeError("git rev-list %s: %s" % (bereik, r.stderr.decode(errors="replace").strip()))
    paden = {}
    for regel in r.stdout.decode("utf-8", errors="replace").splitlines():
        sha, _, pad = regel.partition(" ")
        if pad:
            paden.setdefault(sha, pad)
    if not paden:
        return []
    b = subprocess.run(["git", "-C", repo, "cat-file", "--batch-check=%(objecttype) %(objectname)"],
                       input="".join(s + "\n" for s in paden).encode(), capture_output=True)
    if b.returncode != 0:
        raise RuntimeError("git cat-file --batch-check: " + b.stderr.decode(errors="replace").strip())
    blobs = {s for typ, s in (l.split() for l in b.stdout.decode().splitlines() if l.strip()) if typ == "blob"}
    ix = subprocess.run(["git", "-C", repo, "ls-files", "-s", "-z"], capture_output=True)
    if ix.returncode != 0:
        raise RuntimeError("git ls-files -s: " + ix.stderr.decode(errors="replace").strip())
    in_index = {r_.split(b" ")[1].decode() for r_ in ix.stdout.split(b"\0") if r_}
    return sorted((paden[s], s) for s in blobs if s not in in_index)


def wacht(repo: str, toon: bool, bereik: str | None = None) -> int:
    global UITZONDERINGEN
    zeg("namenwacht: elk bestand dat git kent, op de voornamen van de testlezers")
    try:
        bronnen = bestanden_nu(repo)
    except RuntimeError as e:
        zeg("  BLIND: %s" % e)
        zeg("KON NIET KIJKEN -- geen git-werkkopie; stilte betekent ongeldig, nooit schoon.")
        return 3
    if not bronnen:
        zeg("KON NIET KIJKEN -- git kent nul bestanden; dat is niet gekeken, niet schoon.")
        return 3
    try:
        regels = lees_uitzonderingen(UITZONDERINGEN)
    except (OSError, ValueError) as e:
        zeg("  BLIND: de uitzonderingen (%s): %s" % (os.path.relpath(UITZONDERINGEN, repo), e))
        zeg("KON NIET KIJKEN -- zonder een leesbare uitzonderingenlijst weet de wacht niet wat mag.")
        return 3
    treffers, dekking, blind = scan(bronnen)
    zeg("  " + dekking_regel(len(bronnen), dekking))
    in_berichten = []
    if bereik is not None:
        try:
            n_commits, in_berichten = berichten(repo, bereik)
            versies = nieuwe_versies(repo, bereik)
            inhoud = blob_inhoud(repo, [s for _, s in versies])
            for pad, sha in versies:
                tv, _, bv = scan([(pad, lambda _p, s=sha: inhoud[s])])
                blind += ["%s (versie %s)" % (x, sha[:9]) for x in bv]
                treffers += [(t[0], "versie %s, nog niet op GitHub%s" % (sha[:9], (" · " + t[1]) if t[1] else ""),
                              *t[2:]) for t in tv]
            zeg("  in %s: %d commitbericht(en) en %d bestandsversie(s) die de push nieuw openbaar "
                "maakt, gelezen" % (bereik, n_commits, len(versies)))
        except RuntimeError as e:
            blind.append("het bereik %s (%s)" % (bereik, e))

    toegestaan = {r[0]: [] for r in regels}
    fout = []
    for t in treffers:
        regel = next((r for r in regels if valt_onder(t[0], r[0])), None)
        (toegestaan[regel[0]] if regel else fout).append(t)
    for patroon, soort, reden, nr in regels:
        n = len(toegestaan[patroon])
        if n:
            zeg("  toegestaan (%s, uitzondering r%d): %-40s %3d treffer(s) in %d bestand(en) -- %s"
                  % (soort, nr, patroon, n, len({t[0] for t in toegestaan[patroon]}), reden))
        else:
            zeg("  UITZONDERING ZONDER TREFFER (r%d, mag weg): %s" % (nr, patroon))
    for b in blind:
        zeg("  BLIND: " + b)
    per_regel = {}                                # één uitvoerregel per regel, met hoe vaak
    for pad, deel, nr, waar, lijn, _ in fout:
        per_regel.setdefault((pad, deel, nr, lijn), 0)
        per_regel[(pad, deel, nr, lijn)] += 1
    for (pad, deel, nr, lijn), n in per_regel.items():
        # Ook het pad door het masker: een naam kan in een bestandsnaam staan (of in
        # de naam van een lid van een zip), en dan zou de wacht hem hier noemen.
        plaats = masker("%s%s:%d" % (pad, (" [%s]" % deel) if deel else "", nr), toon)
        zeg("  NAAM  %s%s  | %s" % (plaats, (" (%dx)" % n) if n > 1 else "", masker(lijn, toon)[:140]))
    for sha, nr, regel in in_berichten:
        zeg("  NAAM  commitbericht %s, regel %d  | %s" % (sha, nr, masker(regel, toon)[:140]))
    if blind:
        zeg("KON NIET KIJKEN -- %d stuk(ken) niet gelezen; dit is geen schoon." % len(blind))
        return 3
    if fout or in_berichten:
        if fout:
            zeg("GEZAKT -- %d keer een testlezer-naam in %d bestand(en) buiten de uitzonderingen. "
                "Schrijf hem neutraal ('een testlezer', 'lezersronde 2'); zie de kop van "
                "_tools/namenwacht.py." % (len(fout), len({t[0] for t in fout})))
            if any(t[1].startswith("versie ") for t in fout):
                zeg("  Een of meer staan alleen in een TUSSENVERSIE op deze tak (nu al weg uit het "
                    "bestand). Een gewone merge en push publiceert die toch; lever de tak met een "
                    "squash-merge (één commit), dan gaat alleen de eindstand mee.")
        if in_berichten:
            zeg("GEZAKT -- %d keer een testlezer-naam in een commitbericht dat nog niet gepusht is. "
                "Schrijf het bericht opnieuw (git commit --amend, of een nieuwe tak) vóór je "
                "pusht: na de push is het openbaar." % len(in_berichten))
        return 1
    zeg("SCHOON -- %d bestanden, 0 testlezer-namen buiten de uitzonderingen." % len(bronnen))
    return 0


# ---------------------------------------------------------------------------
# De inventaris
# ---------------------------------------------------------------------------
TS_PERS = ("oefenboeken/ts/", "en/workbooks/inferential-statistics/",
           "_tools/taalparen.tsv", "_tools/en_manifest.txt")


def oordeel(pad: str, waar: str) -> str:
    if pad.startswith("_logs/"):
        return "gaat uit git (stap 3)"
    if any(valt_onder(pad, p) for p in TS_PERS):
        return "na ts_pers (niet aanraken)"
    if waar in ("commentaar", "notitie"):
        return "herschrijven"
    return "NAKIJKEN: " + waar


def inventaris(repo: str, rev: str | None, toon: bool) -> int:
    try:
        bronnen = bestanden_op(repo, rev) if rev else bestanden_nu(repo)
    except (RuntimeError, OSError) as e:
        zeg("BLIND: %s" % e)
        return 3
    stand = rev or "de werkkopie"
    zeg("namenwacht inventaris -- %s" % stand)
    alle = {}
    for naam, rx in (("naam", NAAM_RX), ("testlezer", TESTLEZER_RX)):
        treffers, dekking, blind = scan(bronnen, rx, met_plek=True)
        alle[naam] = treffers
        for b in blind:
            zeg("  BLIND: " + b)
        if blind:
            return 3
    zeg("  " + dekking_regel(len(bronnen), dekking))
    per_bestand = {}
    for t in alle["naam"]:
        per_bestand.setdefault(t[0], []).append(t)
    zeg("\n  per bestand (namen):")
    for pad in sorted(per_bestand, key=lambda p: (-len(per_bestand[p]), p)):
        ts = per_bestand[pad]
        waar = {}
        for t in ts:
            waar[t[3]] = waar.get(t[3], 0) + 1
        zeg("  %4d  %-70s %s" % (len(ts), pad, ", ".join("%s %d" % kv for kv in sorted(waar.items()))))
    zeg("\n  elke treffer (namen), met oordeel:")
    for pad, deel, nr, waar, lijn, _ in sorted(alle["naam"]):
        zeg("  %-26s %s:%d%s  | %s" % (oordeel(pad, waar), pad, nr, (" [%s]" % deel) if deel else "",
                                         masker(lijn, toon)[:160]))
    tl = alle["testlezer"]
    zeg("\n  'testlezer' (geen naam; het neutrale woord):")
    per = {}
    for t in tl:
        per.setdefault(t[0], []).append(t)
    for pad in sorted(per, key=lambda p: (-len(per[p]), p)):
        met_naam = sum(1 for t in per[pad] if NAAM_RX.search(t[4].encode()))
        zeg("  %4d  %-70s %s" % (len(per[pad]), pad,
                                   ("waarvan %d op een regel mét naam" % met_naam) if met_naam else
                                   "blijft: geen naam erbij"))
    n_naam = len(alle["naam"])
    zeg("\n  TELLING (%s): namen %d in %d bestand(en) · testlezer %d in %d bestand(en)"
          % (stand, n_naam, len(per_bestand), len(tl), len(per)))
    per_oordeel = {}
    for t in alle["naam"]:
        k = oordeel(t[0], t[3])
        per_oordeel[k] = per_oordeel.get(k, 0) + 1
    zeg("  per oordeel: " + " · ".join("%s %d" % kv for kv in sorted(per_oordeel.items())))
    return 0


# ---------------------------------------------------------------------------
# De proef "alleen commentaar veranderd"
# ---------------------------------------------------------------------------
def zonder_commentaar(pad: str, s: str):
    """De tekst zonder commentaar, regels die daardoor leeg werden weg, witruimte aan
    het eind weg. Voor Python: de AST zonder docstrings (vormgeving telt niet, code
    wel). None als dit soort bestand geen commentaar kent."""
    if soort_van(pad) == "py":
        boom = ast.parse(s)
        for knoop in ast.walk(boom):
            lijf = getattr(knoop, "body", None)
            if isinstance(lijf, list) and lijf and isinstance(lijf[0], ast.Expr) \
                    and isinstance(getattr(lijf[0], "value", None), ast.Constant) \
                    and isinstance(lijf[0].value.value, str):
                knoop.body = lijf[1:] or [ast.Pass()]
        return ast.dump(boom, indent=1) + "\n"
    stukken = commentaar(pad, s)
    if stukken is None:
        return None
    uit, vorig = [], 0
    for a, b in sorted(stukken):
        uit.append(s[vorig:a])
        vorig = b
    uit.append(s[vorig:])
    regels = [r.rstrip() for r in "".join(uit).splitlines()]
    return "\n".join(r for r in regels if r.strip()) + "\n"


def vergelijk(repo: str, rev: str, paden=()) -> int:
    """Alleen commentaar veranderd sinds <rev>? Met paden: alleen die bestanden (een
    tak die ook bewust code verandert -- een wachter, een workflow -- kan zo zijn
    inhoudsbestanden apart laten nakijken)."""
    r = subprocess.run(["git", "-C", repo, "diff", "--name-status", "-z", rev, "--", *paden],
                       capture_output=True)
    if r.returncode != 0:
        zeg("BLIND: git diff %s: %s" % (rev, r.stderr.decode(errors="replace").strip()))
        return 3
    velden = [v.decode() for v in r.stdout.split(b"\0") if v]
    paren, i = [], 0
    while i < len(velden):
        st = velden[i]
        if st[:1] in "RC":
            paren.append((st, velden[i + 1], velden[i + 2]))
            i += 3
        else:
            paren.append((st, velden[i + 1], velden[i + 1]))
            i += 2
    code = tekst = blind = 0
    zeg("namenwacht vergelijk %s -- %d bestand(en) veranderd" % (rev, len(paren)))
    for st, oud_pad, pad in paren:
        # Eerst de soort verandering, dan pas openen: een nieuw of verdwenen bestand
        # hoeft niet gelezen te worden, en kan binair zijn (nakijker, 24-11: een
        # nieuwe png liet de vergelijking hier crashen met afloop 1).
        if st.startswith("D"):
            zeg("  %-60s weg uit git" % pad)
            continue
        if st.startswith("A"):
            zeg("  %-60s nieuw bestand" % pad)
            continue
        oud_b = subprocess.run(["git", "-C", repo, "show", "%s:%s" % (rev, oud_pad)],
                               capture_output=True).stdout
        try:
            with open(os.path.join(repo, pad), "rb") as f:
                nieuw = f.read().decode("utf-8")
            oud = oud_b.decode("utf-8")
        except (OSError, UnicodeDecodeError) as e:
            zeg("  %-60s BLIND: niet als tekst te lezen (%s), dus niet te vergelijken"
                % (pad, type(e).__name__))
            blind += 1
            continue
        ruw = sum(1 for x in difflib.unified_diff(oud.splitlines(), nieuw.splitlines(), lineterm="", n=0)
                  if x[:1] in "+-" and x[:3] not in ("+++", "---"))
        try:
            a, b = zonder_commentaar(oud_pad, oud), zonder_commentaar(pad, nieuw)
        except (ValueError, SyntaxError, tokenize.TokenError) as e:
            zeg("  %-60s BLIND: %s" % (pad, e))
            blind += 1
            continue
        if a is None:
            zeg("  %-60s %4d regels anders -- notitie: alles is tekst" % (pad, ruw))
            tekst += 1
            continue
        d = [x for x in difflib.unified_diff(a.splitlines(), b.splitlines(), lineterm="", n=0)
             if x[:3] not in ("+++", "---")]
        zeg("  %-60s %4d regels anders · zonder commentaar %d" % (pad, ruw, len([x for x in d if x[:1] in "+-"])))
        for x in d[:20]:
            zeg("      " + masker(x, False)[:150])
        if any(x[:1] in "+-" for x in d):
            code += 1
    if blind:
        zeg("ONBETROUWBAAR -- %d bestand(en) niet vergeleken." % blind)
        return 3
    if code:
        zeg("NIET ALLEEN COMMENTAAR -- %d bestand(en) verschillen ook zonder commentaar; "
              "kijk ze na (lezerstekst of code)." % code)
        return 1
    zeg("ALLEEN COMMENTAAR -- zonder commentaar gelijk aan %s (%d notitie(s) zijn helemaal tekst)."
          % (rev, tekst))
    return 0


def main(argv) -> int:
    global UITZONDERINGEN, TOON
    repo = REPO
    toon = TOON = "--toon" in argv
    argv = [a for a in argv if a != "--toon"]
    if argv[:1] == ["--repo"]:
        if len(argv) < 2:
            print("gebruik: namenwacht.py --repo <map> [...]")
            return 3
        repo = os.path.realpath(argv[1])
        UITZONDERINGEN = os.path.join(repo, "_tools", "namenwacht_uitzonderingen.tsv")
        argv = argv[2:]
    if argv[:1] == ["inventaris"]:
        rev = None
        if argv[1:2] == ["--rev"]:
            if len(argv) < 3:
                print("gebruik: namenwacht.py inventaris --rev <rev>")
                return 3
            rev = argv[2]
        return inventaris(repo, rev, toon)
    if argv[:1] == ["vergelijk"]:
        if len(argv) < 2:
            print("gebruik: namenwacht.py vergelijk <rev> [pad ...]")
            return 3
        return vergelijk(repo, argv[1], argv[2:])
    bereik = None
    if argv[:1] == ["--bereik"]:
        if len(argv) != 2:
            print("gebruik: namenwacht.py --bereik <bereik>   (bv. origin/main..HEAD)")
            return 3
        bereik, argv = argv[1], []
    if argv:
        print("onbekend: %s (zie de kop van dit script)" % " ".join(argv))
        return 3
    return wacht(repo, toon, bereik)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
