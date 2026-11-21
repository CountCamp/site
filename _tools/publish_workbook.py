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
  3. De map moet als project-resource in `_quarto-nl.yml` staan (tot
     24-10-2026 in `_quarto.yml`; zie daar het blok "Twee talen"), anders
     kopieert `quarto render` van de site 'm niet naar `_site/`.
     (`resources: - "oefenboeken/<naam>/**"`)
  4. Een werkboek-render brengt zijn eigen `<head>` mee en wordt daarna als
     RESOURCE overgenomen, niet opnieuw gerenderd. De bezoekersteller die de
     site toen in `_quarto-echt.yml` had, bereikte zo'n bladzij dus nooit: hij
     moest uit de werkboek-bron komen. Dat ging stil mis — gemeten op 30-9-2026
     was het hele psychometrie-oefenboek blind (0 van 6), OZP1 op 2 van 18 en
     MVDA op 1 van 9, en niets zei er iets over. → hier invoegen en anders
     weigeren. (Sinds 14-11-2026 zet de bouw zelf in elke bladzij het blok uit
     `_tools/teller.html` en vervangt hij deze regel; zie teller_zetten.py.
     Hij blijft er toch in, omdat controleer_tellers.py hem in de bron eist.)

  5. Een ENGELS oefenboek (`--section en/workbooks`) komt onder en/ te staan, en
     daar keurt `_tools/en_bouw.py` elke door Quarto gebouwde bladzij zonder .qmd
     ernaast af als wees -- terecht voor een vergeten bladzij, onterecht voor een
     oefenboek uit het lab. → elke bladzij krijgt als laatste regel een stempel
     die het oefenboek en de commit van het lab noemt (WERKBOEK_STEMPEL in
     en_bouw.py), en alleen als de bron op die commit schoon is. Het Nederlands
     (`--section oefenboeken`) krijgt geen stempel: dat verandert hier niet.
  6. Een bladzij met een tweeling in de andere taal (`_tools/taalparen.tsv`, `los`)
     draagt knopje NL · EN, hreflang en op de Nederlandse kant de taalbalk. Stap 1
     gooit de map weg en daarmee die stukken; tot 21-11-2026 moest daarna iemand
     met de hand `taalonderdelen.py los` draaien, en wie het vergat merkte niets
     (Oefenboek TS: 9 Nederlandse bladzijden kaal na de pers, en naar_buiten.sh
     --nakijken bleef groen). → hier terugzetten, met taalonderdelen.py zelf; en
     vóór het weggooien nagaan of de nieuwe render ze kan dragen (stap 0b).
     Geldt voor elk oefenboek met een rij in de tabel, Nederlands of Engels, maar
     alleen voor de kant die deze pers neerzet: de tweeling aan de overkant ligt
     buiten zijn map, en daar schrijft hij niet. Mist die zijn stukken (een nieuw
     paar), dan zegt hij dat (OVERKANT, LET OP). Een oefenboek zonder tweeling
     krijgt alleen de regel "0 bladzij(den)".

Dit script doet 1, 2, 4, 5 en 6 deterministisch + valideert dat geen enkele asset
breekt. Punt 3 is een eenmalige config-regel en wordt hier alleen gecontroleerd.

Gebruik
-------
    python3 _tools/publish_workbook.py \
        --src  "<pad naar werkboek>/_site" \
        --name ozp1

Daarna in countcamp_site:  bash _tools/naar_buiten.sh --nakijken, committen, en leveren
met naar_buiten.sh --productie -- niet rechtstreeks naar GitHub: dat loopt om de poorten heen.

Een Engels oefenboek:
    python3 _tools/publish_workbook.py --src "<lab>/…/en/_site" --section en/workbooks --name mvda
Daarna NIET meteen pushen: bash _tools/publiceer_en.sh keurt en/ (stempel, links,
taal, merken, werkbriefjes) en schrijft het manifest. Zie de kop daarvan, punt d3.

Veilig: leest alleen uit --src (en, voor een Engels oefenboek, git in het lab),
schrijft alleen naar <section>/<name>/ in de site-repo. Raakt de werkboek-bron NIET aan.
"""

from __future__ import annotations
import argparse, os, re, shutil, subprocess, sys, html
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tellerregel import met_teller, soort  # noqa: E402

# Waar een Engels oefenboek landt (punt 5). Dezelfde map als WERKBOEK_MAP in
# en_bouw.py; stap 0 eist dat ze gelijk zijn. De keuring op de stempel staat daar,
# en wordt pas geladen als er een Engels oefenboek komt: het Nederlandse pad heeft
# en_bouw.py niet nodig, en publish_teller_test.sh draait dit script in een
# proefsite met alleen tellerregel.py ernaast.
EN_WERKBOEKEN = "en/workbooks"

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
    """Verwijder het 'Andere formaten'-blok (de PDF-downloadlink in de margin).

    Quarto 1.8 genereert per hoofdstuk:
        <div class="quarto-alternate-formats"><h2>Andere formaten</h2>
         <ul><li><a href="06_regressie.pdf">...PDF</a></li></ul></div>
    maar die PDF's worden niet meegerenderd → dode link. Downloads zijn (nu)
    niet nodig, dus we halen het hele div-blok weg.
    """
    n = 0
    marker = 'class="quarto-alternate-formats"'
    while True:
        i = text.find(marker)
        if i == -1:
            break
        start = text.rfind("<div", 0, i)
        if start == -1:
            break
        # vind de bijbehorende </div> met diepte-telling vanaf de open-div
        depth = 0
        j = start
        end = -1
        while j < len(text):
            nxt_open = text.find("<div", j)
            nxt_close = text.find("</div>", j)
            if nxt_close == -1:
                break
            if nxt_open != -1 and nxt_open < nxt_close:
                depth += 1
                j = nxt_open + 4
            else:
                depth -= 1
                j = nxt_close + 6
                if depth == 0:
                    end = j
                    break
        if end == -1:
            break
        text = text[:start] + text[end:]
        n += 1
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


def zorg_voor_tellers(dst: str) -> tuple[list[str], list[str], list[tuple[str, str]]]:
    """Zet de bezoekersteller in elke bladzij onder `dst`.

    Geeft (al_goed, toegevoegd, overgeslagen). `overgeslagen` bevat per bestand
    de reden, en die wordt hardop gemeld: een uitsluiting die je niet ziet, is
    een gat. Wie de teller er al heeft, krijgt hem niet twee keer.
    """
    al_goed: list[str] = []
    bij: list[str] = []
    over: list[tuple[str, str]] = []
    for root, _d, files in os.walk(dst):
        for fn in sorted(files):
            if not fn.endswith(".html"):
                continue
            f = os.path.join(root, fn)
            rel = os.path.relpath(f, dst)
            s = open(f, encoding="utf-8", errors="ignore").read()
            k = soort(s)
            if k != "bladzij":
                over.append((rel, k))
                continue
            nieuw, wat = met_teller(s)
            if wat == "al_goed":
                al_goed.append(rel)
            elif wat == "toegevoegd":
                open(f, "w", encoding="utf-8").write(nieuw)
                bij.append(rel)
            else:
                over.append((rel, wat))
    return al_goed, bij, over


def taal_bladzijden(dst: str) -> tuple[str, dict[str, bool]]:
    """De bladzijden onder `dst` met een losse tweeling in _tools/taalparen.tsv
    (`los` of `los-eigen`): (voorvoegsel, {sitepad: volgt_de_bestanden}).

    `volgt_de_bestanden` is waar voor de Engelse kant van een <n>-regel (REGEL_N in
    taalonderdelen.py). Zo'n regel telt de Engelse bladzijden die er staan; een
    Engelse render met een hoofdstuk minder maakt de lijst dus korter, en dat is
    voor DEZE pers geen reden om te weigeren -- zijn eigen map is dan gewoon af. Het
    Nederlandse hoofdstuk dat zo zijn tweeling verliest, houdt wel zijn knopje: een
    wees, en die meldt overkant_zonder_stukken (LET OP) en houdt naar_buiten.sh tegen.
    Voor elke andere bladzij is "de render maakt hem niet" wel een weigering: dan
    wijst het knopje op de andere kant naar niets.
    """
    from taalonderdelen import paren  # noqa: E402
    voor = os.path.relpath(dst, SITE_ROOT).replace(os.sep, "/") + "/"
    hier: dict[str, bool] = {}
    for p in paren():
        if p["wissel"] not in ("los", "los-eigen"):
            continue
        for k in ("nl", "en"):
            if p[k].startswith(voor):
                hier[p[k]] = k == "en" and "regel" in p
    return voor, hier


def _taalstukken_op(f: str, sitepad: str) -> tuple[str, str]:
    """(oud, nieuw) voor één bladzij; ValueError als hij de stukken niet kan dragen
    (geen </head>, geen <body> op een eigen regel, geen UTF-8)."""
    from taalonderdelen import pas_toe_los  # noqa: E402
    with open(f, encoding="utf-8") as h:
        s = h.read()
    return s, pas_toe_los(s, sitepad)


def voorproef_taalstukken(src: str, dst: str) -> tuple[int, list[tuple[str, str]]]:
    """Kan de nieuwe render in `src` de taalstukken dragen? Vóór er iets wordt
    weggegooid, net als voorproef_stempels: elke bladzij met een tweeling moet in
    de render staan en een plek hebben voor de stukken. Anders weigert de
    publicatie terwijl het vorige oefenboek er nog staat, mét zijn knopjes, in
    plaats van daarna met een half neergezet boek. Geeft (aantal, (bladzij, reden)).
    De bron is de render vóór teller en herschrijven; die raken <head>-einde en
    <body>-regel niet, dus wat hier past, past straks ook.
    WAT HIJ NIET DEKT: een <n>-regel met zijn Engelse kant onder `dst`. Die regel
    rekent taalonderdelen.py uit tegen de bestanden die NU op de site staan, en na
    het kopiëren opnieuw; een nieuw hoofdstuk in de render ziet de voorproef dus
    niet (tweede nakijker, 21-11-2026). Geen enkele <n>-regel wijst vandaag onder een
    map van deze pers; main() zegt het hardop als dat ooit zo is.
    """
    voor, hier = taal_bladzijden(dst)
    fout: list[tuple[str, str]] = []
    for sitepad, volgt in sorted(hier.items()):
        rel = sitepad[len(voor):]
        f = os.path.join(src, rel)
        if not os.path.isfile(f):
            if not volgt:
                fout.append((rel, "staat in _tools/taalparen.tsv, maar de nieuwe render maakt hem niet (meer)"))
            continue
        try:
            _taalstukken_op(f, sitepad)
        except ValueError as e:
            fout.append((rel, str(e)))
    return len(hier), fout


def zet_taalstukken(dst: str) -> tuple[int, list[str], list[tuple[str, str]]]:
    """Zet knopje, hreflang en taalbalk in elke bladzij onder `dst` die in
    _tools/taalparen.tsv een losse tweeling heeft (`los` of `los-eigen`).

    Geeft (aantal tweelingen onder dst, bijgezet, fout). Een rij in de tabel
    waarvan dit oefenboek de bladzij niet (meer) maakt, is een fout: dan wijst het
    knopje op de andere kant naar niets. Dezelfde aanroep als bouw_speelkist.py
    (pas_toe_los bij het kopiëren); de stukken zelf staan alleen in taalonderdelen.py.
    """
    voor, hier = taal_bladzijden(dst)
    bij: list[str] = []
    fout: list[tuple[str, str]] = []
    for sitepad in sorted(hier):
        f = os.path.join(SITE_ROOT, sitepad)
        rel = sitepad[len(voor):]
        if not os.path.isfile(f):
            fout.append((rel, "staat in _tools/taalparen.tsv, maar dit oefenboek maakt hem niet (meer)"))
            continue
        try:
            s, t = _taalstukken_op(f, sitepad)
        except ValueError as e:
            fout.append((rel, str(e)))
            continue
        if t != s:
            with open(f, "w", encoding="utf-8") as h:
                h.write(t)
            bij.append(rel)
    return len(hier), bij, fout


def overkant_zonder_stukken(dst: str) -> list[str]:
    """De tweelingen BUITEN `dst` van bladzijden onder `dst` die hun taalstukken
    missen, of er niet zijn. Deze pers schrijft daar niet -- dat is een ander boek
    of de andere taal, en de kop belooft "schrijft alleen naar <section>/<name>/" --
    maar hij zegt het wel. Bij een NIEUW paar is de overkant kaal tot iemand
    taalonderdelen.py los draait (tegendraadse nakijker, 21-11-2026: een Engelse
    pers voor een boek waarvan de Nederlandse kant al live staat, meldde ✅ terwijl
    die Nederlandse kant geen knopje had).
    En elke WEES in de repo: een bladzij met taalstukken die niet (meer) in de tabel
    staat. Die kan deze pers net gemaakt hebben -- een Engelse week die wachtpagina
    werd, een <n>-hoofdstuk dat wegviel -- en dan wijst er een knopje naar niets
    (tweede nakijker, 21-11-2026: twee keer ✅ op precies dat geval)."""
    from taalonderdelen import paren, pas_toe_los, wezen  # noqa: E402
    voor = os.path.relpath(dst, SITE_ROOT).replace(os.sep, "/") + "/"
    uit: list[str] = []
    tabel = paren()
    for p in tabel:
        if p["wissel"] not in ("los", "los-eigen"):
            continue
        hier = [k for k in ("nl", "en") if p[k].startswith(voor)]
        if len(hier) != 1:
            continue
        ander = p["en" if hier[0] == "nl" else "nl"]
        f = os.path.join(SITE_ROOT, ander)
        if not os.path.isfile(f):
            uit.append(f"{ander}: bestaat niet (het knopje hier wijst naar niets) — draai de pers van die kant, of haal de rij uit _tools/taalparen.tsv")
            continue
        try:
            with open(f, encoding="utf-8") as h:
                s = h.read()
            if pas_toe_los(s, ander) != s:
                uit.append(f"{ander}: mist zijn taalstukken — herstel: python3 _tools/taalonderdelen.py los")
        except ValueError as e:
            uit.append(f"{ander}: {e}")
    _n, wees, blind = wezen(tabel)
    uit += wees
    uit += [f"(niet volledig nagelopen: {b})" for b in blind]
    return uit


def _git(map_: str, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", map_, *args], capture_output=True, text=True)


def _tijd(t: float) -> str:
    return datetime.fromtimestamp(t).strftime("%d-%m %H:%M:%S")


def lab_bron(src: str) -> tuple[str | None, str]:
    """De commit van het lab waaruit <src> gerenderd is: (commit, "") of (None, reden).

    Een stempel is een bewering: "deze bladzijden zijn de render van commit X". Dat
    volgt niet uit "de bron is nu schoon" (nagekeken 28-10-2026: renderen op A, een
    commit B erbij, niet opnieuw renderen -- schoon, en toch niet de render van B).
    Daarom vier eisen, en anders geen stempel:
      1. het project (de map boven _site/, met een _quarto.yml) staat in git, met
         bijgehouden bestanden -- een render in een genegeerde map van een ándere
         repo kreeg anders diens commit;
      2. elke wegwijzer (symlink) die git in het project kent, wijst binnen dezelfde
         repo -- daar leest de render ook uit (mvda_werkboek/en/_common -> ../_common,
         en/00_opfris/data -> ../../00_opfris/data), en dat telt dus als bron;
      3. geen ongecommit werk in het project en in die doelen (de render zelf niet
         meegeteld, nieuwe bestanden wél, wat de git-instellingen van het lab ook zeggen);
      4. geen bijgehouden bestand van de bron is nieuwer dan de oudste bladzij van de
         render. Een commit verandert geen wijzigtijd; wie na de render iets aanpast,
         terugzet (stash, checkout) of een rebase doet, wel.
    Wat dit NIET ziet: invoer die git niet kent (een genegeerde dataset), een
    wijzigtijd die met opzet is teruggezet, en of de commit later nog op een tak
    staat (na een rebase niet meer).
    """
    project, render = os.path.dirname(src), os.path.basename(src)
    r = _git(project, "rev-parse", "HEAD")
    if r.returncode != 0:
        return None, (f"{project} staat niet in een git-repo ({r.stderr.strip()[:120]}) — "
                      f"er is geen commit van het lab om in de stempel te zetten")
    commit = r.stdout.strip()
    if not os.path.isfile(os.path.join(project, "_quarto.yml")):
        return None, f"{project} heeft geen _quarto.yml — is de map boven {render}/ wel het Quarto-project?"
    top = _git(project, "rev-parse", "--show-toplevel").stdout.strip()
    r = _git(project, "ls-files", "-s", "-z", "--", ".", f":(exclude){render}")
    if r.returncode != 0 or not r.stdout.strip("\0").strip():
        return None, (f"geen enkel bestand van {project} staat in git ({r.stderr.strip()[:120] or 'ls-files: leeg'}) "
                      f"— commit {commit[:7]} zegt dan niets over deze render")
    plekken = ["."]
    for regel in filter(None, r.stdout.split("\0")):
        kop, pad = regel.split("\t", 1)
        if not kop.startswith("120000"):
            continue
        doel = os.path.realpath(os.path.join(project, pad))
        if not top or os.path.commonpath([doel, os.path.realpath(top)]) != os.path.realpath(top):
            return None, (f"de wegwijzer {pad} wijst buiten de repo ({doel}) — commit {commit[:7]} dekt niet "
                          f"wat de render daar las")
        plekken.append(os.path.relpath(doel, os.path.realpath(project)))
    spec = ["--", *plekken, f":(exclude){render}"]
    r = _git(project, "status", "--porcelain", "--untracked-files=all", "--ignore-submodules=none", *spec)
    if r.returncode != 0:
        return None, f"git status in {project} liep vast ({r.stderr.strip()[:120]}) — kon niet kijken of de bron schoon is"
    vuil = r.stdout.splitlines()
    if vuil:
        return None, (f"ongecommit werk in de bron ({len(vuil)} regel(s) in git status, bv. {vuil[0].strip()}) — "
                      f"de stempel zou commit {commit[:7]} noemen, en deze render is daar niet (alleen) van; "
                      f"commit eerst in het lab en render opnieuw")
    bladz = [os.path.getmtime(os.path.join(dp, f)) for dp, _d, fs in os.walk(src) for f in fs if f.endswith(".html")]
    if not bladz:
        return None, f"geen enkele .html in {src} — niets om de tijd van de render aan af te lezen"
    oudste = min(bladz)
    r = _git(project, "ls-files", "-z", *spec)
    if r.returncode != 0:
        return None, f"git ls-files in {project} liep vast — kon de bron niet naast de render leggen"
    nieuwer = []
    for pad in filter(None, r.stdout.split("\0")):
        p = os.path.join(project, pad)
        if os.path.lexists(p) and os.lstat(p).st_mtime > oudste:
            nieuwer.append((os.lstat(p).st_mtime, pad))
    if nieuwer:
        t, pad = max(nieuwer)
        return None, (f"{len(nieuwer)} bestand(en) van de bron zijn nieuwer dan de render (bv. {pad}, {_tijd(t)}; "
                      f"de oudste bladzij is van {_tijd(oudste)}) — dan is dit niet de render van commit "
                      f"{commit[:7]}; render het oefenboek opnieuw, helemaal, en publiceer dan")
    return commit, ""


def stempelregel(naam: str, commit: str, geleverd: str) -> str:
    return f"<!-- countcamp-oefenboek {naam} lab-commit={commit} geleverd={geleverd} -->"


def _staart(data: bytes, regel: str) -> bytes:
    """Wat er achter de bladzij komt: een regelovergang als die er nog niet is, dan de stempel."""
    return (b"" if data.endswith(b"\n") else b"\n") + regel.encode("utf-8") + b"\n"


def voorproef_stempels(src: str, naam: str, regel: str, keur) -> list[tuple[str, str]]:
    """Zou elke bladzij in <src> met deze stempel door de keuring komen? Vóór er iets
    wordt weggegooid: een bladzij zonder </html>, of een die al een stempel draagt
    (--src wijst naar een gepubliceerde kopie), houdt de publicatie dan tegen terwijl
    het vorige oefenboek er nog staat. Geeft (bladzij, reden) per bladzij die zakt."""
    fout = []
    for root, _d, files in os.walk(src):
        for fn in sorted(files):
            if fn.endswith(".html"):
                rel = os.path.relpath(os.path.join(root, fn), src)
                data = open(os.path.join(root, fn), "rb").read()
                tekst = (data + _staart(data, regel)).decode("utf-8", errors="replace")
                ja, reden = keur(f"{EN_WERKBOEKEN}/{naam}/{rel.replace(os.sep, '/')}", tekst)
                if not ja:
                    fout.append((rel, reden or "de keuring herkent de stempel niet"))
    return fout


def zet_werkboek_stempels(dst: str, regel: str, keur) -> tuple[list[str], list[tuple[str, str]]]:
    """Zet de stempel als laatste regel in elke .html onder `dst`, en keur hem meteen
    met `keur` (en_bouw.uit_een_werkboek): de vorm staat hier, de keuring daar, en zo
    kunnen die twee het niet oneens zijn zonder dat deze publicatie stopt. Erachter
    geplakt in bytes, zodat de bladzij zelf byte voor byte blijft wat hij was.
    Geeft (gestempeld, (bladzij, reden) die niet door de keuring kwam)."""
    goed: list[str] = []
    fout: list[tuple[str, str]] = []
    for root, _d, files in os.walk(dst):
        for fn in sorted(files):
            if not fn.endswith(".html"):
                continue
            f = os.path.join(root, fn)
            data = open(f, "rb").read()
            with open(f, "ab") as uit:
                uit.write(_staart(data, regel))
            site_pad = os.path.relpath(f, SITE_ROOT).replace(os.sep, "/")
            ja, reden = keur(site_pad, open(f, "rb").read().decode("utf-8", errors="replace"))
            if ja:
                goed.append(os.path.relpath(f, dst))
            else:
                fout.append((os.path.relpath(f, dst), reden or "de keuring herkent de stempel niet"))
    return goed, fout


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
    ap.add_argument("--src", required=True, help="pad naar gerenderd _site/ of _book/")
    ap.add_argument("--name", required=True, help="doelnaam onder de sectie-map")
    ap.add_argument("--section", default="oefenboeken",
                    help="sectie-map in de site-repo (default: oefenboeken; bv. manuscript, "
                         "of en/workbooks voor een Engels oefenboek: dan met stempel)")
    ap.add_argument("--dry-run", action="store_true",
                    help="alleen rapporteren, niets wegschrijven")
    args = ap.parse_args()

    src = os.path.abspath(args.src)
    if not os.path.isfile(os.path.join(src, "index.html")):
        log(f"FOUT: {src} bevat geen index.html — is dit een gerenderd _site?")
        return 2

    dst = os.path.join(SITE_ROOT, args.section, args.name)
    log(f"bron : {src}  ({human(dirsize(src))})")
    log(f"doel : {dst}")

    # 0) een Engels oefenboek krijgt een stempel (punt 5 hierboven). Eerst kijken of
    #    dat kan, vóór er iets weggegooid wordt: kan het niet, dan blijft de site
    #    zoals hij was, in plaats van een oefenboek dat en_bouw.py als wees weigert.
    lab_commit = keur = regel = None
    if os.path.normpath(args.section) == EN_WERKBOEKEN:
        try:
            import en_bouw  # noqa: E402
        except Exception as e:  # noqa: BLE001
            log(f"FOUT: _tools/en_bouw.py niet te laden ({type(e).__name__}: {e}) — zonder die keuring "
                f"kan de stempel niet nagekeken worden. Niets aangeraakt.")
            return 3
        if en_bouw.WERKBOEK_MAP != EN_WERKBOEKEN:
            log(f"FOUT: en_bouw.py zoekt oefenboeken onder {en_bouw.WERKBOEK_MAP}/, dit script zet ze onder "
                f"{EN_WERKBOEKEN}/ — maak die twee gelijk. Niets aangeraakt.")
            return 2
        keur = en_bouw.uit_een_werkboek
        if not re.fullmatch(r"[a-z0-9_-]+", args.name):
            log(f"FOUT: --name {args.name!r} past niet in de stempel van een Engels oefenboek "
                f"(alleen a-z, 0-9, _ en -) — niets aangeraakt")
            return 2
        lab_commit, reden = lab_bron(src)
        if lab_commit is None:
            log(f"FOUT: geen stempel mogelijk: {reden}")
            log(f"  Zonder stempel weigert _tools/en_bouw.py elke bladzij onder {EN_WERKBOEKEN}/{args.name}/ "
                f"als wees. Niets aangeraakt.")
            return 1
        regel = stempelregel(args.name, lab_commit, datetime.now().strftime("%Y-%m-%dT%H:%M:%S"))
        zakt = voorproef_stempels(src, args.name, regel, keur)
        if zakt:
            log(f"FOUT: {len(zakt)} bladzij(den) in de bron kunnen de stempel niet dragen — niets aangeraakt:")
            for rel, reden in zakt[:20]:
                log(f"    {rel} — {reden}")
            return 1
        log(f"stempel: countcamp-oefenboek {args.name}, lab-commit {lab_commit[:12]} "
            f"(bron schoon, niet nieuwer dan de render)")

    # 0b) de taalstukken (punt 6): kan de nieuwe render ze dragen? Ook dit vóór er
    #     iets weggegooid wordt, om dezelfde reden als de stempel. Een week met een
    #     nieuwe naam liet anders eerst het boek neerzetten en meldde pas daarna dat
    #     het knopje op de Engelse kant nergens meer heen wees.
    #     Zonder taalparen.tsv geen tweelingen, en dat wordt gezegd (stap 5b); is de
    #     tabel er wel en kan hij niet gelezen worden, dan is dat niet gekeken (3).
    taal_aan = os.path.isfile(os.path.join(SITE_ROOT, "_tools", "taalparen.tsv"))
    if taal_aan:
        try:
            n_taal, zakt = voorproef_taalstukken(src, dst)
        except (Exception, SystemExit) as e:  # noqa: BLE001 -- paren() stopt met SystemExit op een kapotte tabel
            log(f"FOUT: de taalstukken zijn niet na te kijken: taalonderdelen.py liep vast "
                f"({type(e).__name__}: {e}). Niets aangeraakt.")
            return 3
        if zakt:
            log(f"FOUT: {len(zakt)} bladzij(den) met een tweeling in _tools/taalparen.tsv kunnen hun "
                f"taalstukken niet krijgen — niets aangeraakt:")
            for rel, reden in zakt:
                log(f"    TAALSTUKKEN: {rel} — {reden}")
            log("  Heeft een bladzij een andere naam gekregen, werk dan eerst _tools/taalparen.tsv bij.")
            return 1
        log(f"taalstukken: {n_taal} bladzij(den) met een losse tweeling; de nieuwe render kan ze "
            f"allemaal dragen")
        if any(volgt for volgt in taal_bladzijden(dst)[1].values()):
            log("  NB: een <n>-regel heeft zijn Engelse kant in deze map; een NIEUW hoofdstuk in de render "
                "ziet deze voorproef niet (zie voorproef_taalstukken). Gaat het daarna mis, dan staat het "
                "boek er al half.")

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

    # 4) de bezoekersteller — elke bladzij, of het gaat niet door
    al_goed, bijgezet, overgeslagen = zorg_voor_tellers(dst)
    log(f"  teller: {len(al_goed)} bladzij(den) had hem al, "
        f"{len(bijgezet)} erbij gezet, {len(overgeslagen)} overgeslagen")
    for rel in bijgezet:
        log(f"    + teller in {rel}")
    for rel, reden in overgeslagen:
        log(f"    overgeslagen ({reden}): {rel}")
    # De weigering staat hieronder bij `problems`, zodat één run álles meldt in
    # plaats van bij het eerste bezwaar te stoppen. Een half rapport laat je
    # twee keer draaien om twee dingen te zien.
    zonder_teller = [rel for rel, reden in overgeslagen
                     if reden in ("geen_head", "half_gevonden")]

    # 4b) de stempel -- alleen een Engels oefenboek (stap 0). Na de teller en het
    #     herschrijven, want hij hoort de laatste regel te zijn. De voorproef in stap
    #     0 zag de bron; dit keurt wat er na het kopiëren en herschrijven echt staat.
    stempel_fout: list[tuple[str, str]] = []
    if regel:
        gestempeld, stempel_fout = zet_werkboek_stempels(dst, regel, keur)
        log(f"  stempel: {len(gestempeld)} bladzij(den) gestempeld en door en_bouw.py herkend, "
            f"{len(stempel_fout)} niet" + (f" — bv. {gestempeld[0]}" if gestempeld else ""))
        for rel, reden in stempel_fout:
            log(f"    NIET HERKEND: {rel} — {reden}")

    # 5) validatie
    problems = validate_assets(dst)
    log(f"  ontbrekende assets: {len(problems)}")
    for p in problems[:20]:
        log("    MIST: " + p)

    # 5b) de taalstukken (punt 6 hierboven). Na teller, stempel en validatie: de
    #     volgorde waarin ze tot 21-11-2026 met de hand kwamen, en dezelfde bytes
    #     (nagemeten op het Engelse TS-boek: 9 van 9 gelijk). De stempel blijft de
    #     laatste regel; pas_toe_los raakt alleen <head> en de regel na <body>.
    #     Niet vóór de validatie: dan telt die de link van het knopje naar de
    #     tweeling mee, en in een weggooisite (naar_site_en.sh --weggooisite) staat
    #     die tweeling er niet -- 9 keer MIST, gemeten 21-11. Of de tweeling er
    #     is, toetst taalonderdelen.py los --controleer (naar_buiten.sh).
    #     Zonder taalparen.tsv geen tweelingen, en dat wordt gezegd; is de tabel
    #     er wel en het gereedschap niet, dan heeft stap 0b al geweigerd. Een fout
    #     hier is dus iets wat de voorproef niet zag, en die wordt nog steeds gemeld.
    taal_fout: list[tuple[str, str]] = []
    if not taal_aan:
        log("  taalstukken: geen _tools/taalparen.tsv in deze site -- geen tweelingen, niets gezet")
    else:
        try:
            n_taal, taal_bij, taal_fout = zet_taalstukken(dst)
        except (Exception, SystemExit) as e:  # noqa: BLE001 -- paren() stopt met SystemExit op een kapotte tabel
            n_taal, taal_bij = 0, []
            taal_fout = [("(alle)", f"taalonderdelen.py liep vast ({type(e).__name__}: {e})")]
        log(f"  taalstukken: {n_taal} bladzij(den) met een losse tweeling in taalparen.tsv, "
            f"{len(taal_bij)} bijgezet, {len(taal_fout)} fout")
        for rel, reden in taal_fout:
            log(f"    TAALSTUKKEN: {rel} — {reden}")
    # De overkant: geen weigering (deze map is af), wel hardop, en onderaan nog eens.
    overkant: list[str] = []
    if taal_aan:
        try:
            overkant = overkant_zonder_stukken(dst)
        except (Exception, SystemExit) as e:  # noqa: BLE001
            overkant = [f"(niet nagekeken: {type(e).__name__}: {e})"]
        log(f"  taalstukken aan de overkant (buiten deze map): {len(overkant)} niet in orde")
        for wat in overkant[:5]:
            log(f"    OVERKANT: {wat}")
        if len(overkant) > 5:
            log(f"    … en nog {len(overkant) - 5}")

    # 6) de doorstuurders op oude adressen BINNEN deze map terugzetten.
    #    Stap 1 gooide de hele map weg. Daar stonden sinds 1-10-2026 twee
    #    doorstuurders (de oude OZP 1-nummers 3 en 4, gewisseld op 19-9), en
    #    zonder deze stap waren die bij elke publicatie van OZP 1 stil verdwenen
    #    -- met de studenten die ze nog in een bladwijzer hebben erachteraan.
    #    Pas NA de validatie: die kent geen links die met `/` beginnen, en een
    #    doorstuurder heeft er precies zo een.
    doorstuur_rel = os.path.relpath(dst, SITE_ROOT)
    if not os.path.isfile(os.path.join(SITE_ROOT, "_tools", "doorstuurders.tsv")):
        log("  doorstuurders: geen _tools/doorstuurders.tsv in deze site -- niets teruggezet")
    else:
        try:
            from doorstuurders import bouw as doorstuurders_bouw  # noqa: E402
        except ImportError as e:
            log(f"  doorstuurders: _tools/doorstuurders.py niet te laden ({e}) -- "
                f"NIETS teruggezet; draai python3 _tools/doorstuurders.py --bouw")
        else:
            # Valt het terugzetten om, dan staat het boek er al (stap 1-5 zijn
            # gedaan). Dan luid melden en de slotcontrole hieronder wél laten
            # printen; de doorstuurpoort in naar_buiten.sh ziet het gat daarna.
            try:
                nw, vv, zelfde, geweigerd = doorstuurders_bouw(SITE_ROOT, doorstuur_rel)
            except Exception as e:  # noqa: BLE001
                nw, vv, zelfde, geweigerd = [], [], [], []
                log(f"  doorstuurders: LIEP VAST ({type(e).__name__}: {e}) -- NIETS "
                    f"teruggezet; draai python3 _tools/doorstuurders.py --bouw")
            log(f"  doorstuurders onder {doorstuur_rel}/: {len(nw)} teruggezet, "
                f"{len(vv)} ververst, {len(zelfde)} stonden er nog")
            for oud, reden in geweigerd:
                # Geen weigering van de publicatie: de lezer krijgt hier een
                # echte bladzij, en dat is beter dan een doorstuurder. Maar de
                # rij in de tabel is achterhaald, en dat moet iemand zien.
                log(f"    NIET teruggezet: {oud} -- {reden}; haal die rij uit "
                    f"_tools/doorstuurders.tsv (of draai --afleiden)")

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

    fout = False
    if problems:
        log("\n⚠️  Er ontbreken assets — NIET publiceren tot opgelost.")
        fout = True
    if zonder_teller:
        log(f"\n⚠️  {len(zonder_teller)} bladzij(den) dragen de bezoekersteller "
            f"niet en konden hem ook niet krijgen — NIET publiceren tot opgelost:")
        for rel in zonder_teller:
            log("    GEEN TELLER: " + rel)
        log("    Een halve teller telt niets en ziet er toch uit als een teller;"
            " een bladzij zonder </head> heeft geen plek om hem te zetten.")
        fout = True
    if stempel_fout:
        log(f"\n⚠️  {len(stempel_fout)} bladzij(den) dragen een stempel die _tools/en_bouw.py "
            f"niet herkent — NIET publiceren tot opgelost (zie NIET HERKEND hierboven).")
        fout = True
    if taal_fout:
        log(f"\n⚠️  {len(taal_fout)} bladzij(den) met een tweeling missen hun taalstukken "
            f"— NIET publiceren tot opgelost (zie TAALSTUKKEN hierboven).")
        fout = True
    if fout:
        return 1
    if overkant:
        log(f"\n⚠️  LET OP: {len(overkant)} bladzij(den) BUITEN deze map zijn niet in orde (zie OVERKANT "
            f"hierboven, elk met zijn herstel). Deze map is af; daar schrijft deze pers niet.")
        log("    Tot dat hersteld is, houden naar_buiten.sh en de Action de levering tegen.")
    if regel:
        # Onder en/ keurt alleen publiceer_en.sh (via en_bouw.py keur) de stempel, de
        # links, de taal, de merken en de werkbriefjes; de Action doet dat niet, en
        # `quarto render` ook niet: die kopieert en/** gewoon mee als bijlage.
        log("\n✅ Compleet en gevalideerd. Volgende stap: bash _tools/publiceer_en.sh (keurt en/ en "
            "schrijft het manifest), en pas bij afloop 0 leveren.")
    else:
        # Niet meer "quarto render + git push" (tot 21-11-2026): een kale push loopt
        # om elke poort in naar_buiten.sh heen.
        log("\n✅ Compleet en gevalideerd. Volgende stap: bash _tools/naar_buiten.sh --nakijken, "
            "dan committen en leveren met --productie.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
