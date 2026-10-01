#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""doorstuurders.py — een oude bladwijzer komt uit waar dezelfde inhoud nu staat.

    python3 _tools/doorstuurders.py              # nakijken: klopt elke doorstuurder?
    python3 _tools/doorstuurders.py --bouw       # schrijf de doorstuurders uit de tabel
    python3 _tools/doorstuurders.py --afleiden   # leid de tabel opnieuw af uit gh-pages

Waarom dit bestaat
------------------
De inventaris van 30-9-2026 vond 190 adressen die ooit live stonden en nu een
404 geven. De scherpste: OZP 1-thema 3 en 4 wisselden op 19-9 van nummer, en
`oefenboeken/ozp1/03_normaalverdeling_z/…` stond daarvóór zes weken online,
midden in het vak. Een student met die bladwijzer liep vast, en de herkansing
was op 1 oktober.

GitHub Pages kent geen doorverwijzing op de server. Daarom staat er op het oude
adres een klein HTML-bestand dat meteen doorstuurt, precies zoals de acht
onder `werkboeken/` al sinds 7-8-2026 doen: meta-refresh, canonical, noindex,
een gewone link voor wie geen refresh krijgt, en GEEN teller -- anders telt één
bezoek twee keer.

Op inhoud, niet op nummer
-------------------------
`--afleiden` koppelt elk dood adres aan een huidige bladzij via drie regels
(hetzelfde pad onder `oefenboeken/`, dezelfde onderwerp-stam zonder nummer,
dezelfde titel zonder nummer) en toetst die keuze daarna op de TEKST: de oude
versie uit de gh-pages-geschiedenis moet op het gekozen doel het meest lijken
van alle bladzijden in dat boek. Oneens, of geen kandidaat: dan wordt er niets
gebouwd en staat de rij als `niet` in de tabel, met de reden erbij. Een
doorstuurder naar de verkeerde bladzij is erger dan een 404: de 404 zegt
tenminste eerlijk dat hij het niet weet.

Wie ze kan wissen
-----------------
`publish_workbook.py` gooit `oefenboeken/<boek>/` eerst helemaal weg. Twee
doorstuurders staan daar (de oude OZP 1-nummers), dus die zet dat script via
`bouw()` terug. `publiceer_oefenboeken.sh` in het lab spiegelt met
`rsync --delete` naar `oefenboeken/broertjes/*` en `oefenboeken/ggz_vs`; daar
staat er nu geen. Komt er ooit een, of wist iets anders er een: het nakijken
hieronder zegt het bij naam.

Wat het nakijken toetst
-----------------------
  * elke `bouwen`-rij heeft zijn bestand, en dat is byte voor byte wat `--bouw`
    zou schrijven (dus ook: het wijst naar het doel uit de tabel);
  * elk doel bestaat als echte bladzij (geen doorstuurder: een ketting van
    twee refreshes is traag en verbergt waar het eindigt);
  * geen oud adres is intussen weer een echte bladzij -- dan hoort de rij weg;
  * ook de doorstuurders die NIET uit deze tabel komen (de acht onder
    `werkboeken/`, de vijftien onder `manuscript/werkplaats/`) wijzen naar iets
    dat bestaat.
Wat het NIET toetst: of de live site het al heeft (dat is de pers), of een
`#anker` in het oude adres op de nieuwe bladzij nog bestaat (een meta-refresh
neemt het anker niet mee), en of de koppeling inhoudelijk klopt -- dat deed
`--afleiden`, en het bewijs staat per rij in de tabel.

Afloopcodes (huisafspraak): 0 in orde · 1 er klopt iets niet · 3 kon niet kijken.
"""
from __future__ import annotations

import argparse
import html
import os
import re
import subprocess
import sys
import traceback
import unicodedata
from urllib.parse import quote, unquote, urlparse

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tellerregel import soort  # noqa: E402

SITE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TABEL = os.path.join('_tools', 'doorstuurders.tsv')
KOLOMMEN = ['oud', 'nieuw', 'besluit', 'grond', 'stond', 'oude_titel', 'nieuwe_titel']
# Mappen waar Quarto niets uit publiceert (`_` of `.` vooraan) en bouw-uitvoer.
OVERSLAAN = {'_site', '.quarto', '.git', 'site_libs', 'libs', '.claude'}

# Zelfde vorm als werkboeken/index.html (7-8-2026), plus één regel commentaar
# die zegt waar hij vandaan komt -- wie hem opent, moet niet met de hand gaan
# repareren wat bij de volgende `--bouw` weer terugkomt.
MERK = 'doorstuurder: gemaakt door _tools/doorstuurders.py'
SJABLOON = '''<!doctype html>
<!-- ''' + MERK + ''' uit _tools/doorstuurders.tsv; niet met de hand bewerken -->
<html lang="nl"><head><meta charset="utf-8">
<title>Verhuisd naar {zicht_pad}</title>
<link rel="canonical" href="https://countcamp.org{url}">
<meta name="robots" content="noindex">
<meta http-equiv="refresh" content="0; url={url}">
</head><body style="font-family:Georgia,serif;padding:3rem;max-width:36rem;margin:auto">
<p>Deze pagina heet nu <a href="{url}">countcamp.org{zicht_pad}</a>.
Je wordt doorgestuurd; gebeurt dat niet, klik dan op de link.</p>
</body></html>
'''


def doel_url(nieuw: str) -> str:
    """`oefenboeken/ozp1/index.html` -> `/oefenboeken/ozp1/`; tekens buiten ASCII
    (de ĳ in handleiding-hoofdstuk 1) worden procent-gecodeerd."""
    if nieuw.endswith('/index.html'):
        nieuw = nieuw[:-len('index.html')]
    return '/' + quote(nieuw, safe='/')


def stub(nieuw: str) -> str:
    url = doel_url(nieuw)
    return SJABLOON.format(url=html.escape(url, quote=True),
                           zicht_pad=html.escape(unquote(url)))


# ---------------------------------------------------------------- de tabel --
def lees_tabel(pad: str) -> list[dict]:
    rijen = []
    with open(pad, encoding='utf-8') as f:
        kop = None
        for r in f:
            r = r.rstrip('\n')
            if not r or r.startswith('#'):
                continue
            velden = r.split('\t')
            if kop is None:
                kop = velden
                if kop[:3] != KOLOMMEN[:3]:
                    raise ValueError(f'{pad}: onverwachte kop {kop[:3]}')
                continue
            if len(velden) < 3:
                raise ValueError(f'{pad}: rij met {len(velden)} velden: {r!r}')
            rijen.append(dict(zip(kop, velden)))
    return rijen


def lees(pad: str) -> str:
    with open(pad, encoding='utf-8', errors='ignore') as f:
        return f.read()


# ----------------------------------------------------------------- bouwen --
def bouw(site: str = SITE, onder: str | None = None) -> tuple[list, list, list, list]:
    """Schrijf de doorstuurders. Geeft (nieuw, ververst, ongewijzigd, geweigerd).

    `onder` beperkt tot één map (relatief aan de site), voor publish_workbook.py.
    Een echte bladzij wordt NOOIT overschreven: staat er op het oude adres weer
    inhoud, dan is de rij achterhaald en moet een mens hem weghalen.
    """
    nieuw_, ververst, zelfde, geweigerd = [], [], [], []
    for rij in lees_tabel(os.path.join(site, TABEL)):
        if rij['besluit'] != 'bouwen':
            continue
        oud = rij['oud']
        if onder and not (oud + '/').startswith(onder.rstrip('/') + '/'):
            continue
        pad = os.path.join(site, oud)
        wil = stub(rij['nieuw'])
        if os.path.exists(pad):
            staat = lees(pad)
            if soort(staat) != 'doorstuurder':
                geweigerd.append((oud, 'daar staat een echte bladzij'))
                continue
            if staat == wil:
                zelfde.append(oud)
                continue
            ververst.append(oud)
        else:
            nieuw_.append(oud)
        os.makedirs(os.path.dirname(pad), exist_ok=True)
        with open(pad, 'w', encoding='utf-8') as f:
            f.write(wil)
    return nieuw_, ververst, zelfde, geweigerd


# ------------------------------------------------------------- nakijken --
RE_REFRESH_URL = re.compile(
    r'<meta[^>]*http-equiv\s*=\s*["\']?refresh["\']?[^>]*content\s*=\s*["\'][^"\']*?url\s*=\s*([^"\'>\s]+)',
    re.I)


def doel_van_refresh(site: str, bestand: str, tekst: str) -> str | None:
    """Het bestand in deze repo waar een doorstuurder naartoe wijst, of None."""
    m = RE_REFRESH_URL.search(tekst)
    if not m:
        return None
    u = urlparse(html.unescape(m.group(1)))
    if u.netloc and u.netloc not in ('countcamp.org', 'www.countcamp.org'):
        return None                      # buiten de site: niet de onze om te meten
    p = unquote(u.path)
    if p.startswith('/'):
        rel = p.lstrip('/')
    else:
        rel = os.path.normpath(os.path.join(os.path.dirname(bestand), p))
    if rel == '' or rel.endswith('/'):
        rel += 'index.html'
    elif os.path.isdir(os.path.join(site, rel)):
        rel = rel + '/index.html'
    return rel


# Wat Quarto hier tot bladzij maakt. Moet gelijk lopen met `project: render:`
# in _quarto.yml, en dat is sinds 1-10-2026 alleen "*.qmd": daarvoor werd elk
# .md een openbare bladzij (DUBBELINGEN, LICENSE, werkplaats/LEESMIJ). Stond
# '.md' hier nog, dan hield deze wachter een adres als DUBBELINGEN.html voor
# levend terwijl het van de site verdwijnt.
BRONNEN = ('.qmd',)


def wordt_bladzij(site: str, rel: str) -> str | None:
    """Wat er op de site op `rel` komt te staan: 'bestand' (staat er al als html),
    'gerenderd' (Quarto maakt hem uit een bron ernaast) of None (niets).

    `oefenboeken/index.html` bestaat in de repo niet -- hij komt uit
    `oefenboeken/index.qmd`. Wie alleen naar het html-bestand kijkt, verklaart de
    plank dood; zo begon het eerste nakijken hier met drie vals alarmen.

    Letter voor letter: macOS vindt `OEFENBOEKEN/OZP1/INDEX.HTML` gewoon, GitHub
    Pages geeft daar een 404 (nakijker, 1-10-2026). Dus elk stuk van het pad moet
    precies zo in zijn map staan."""
    if bestaat_exact(site, rel):
        return 'bestand'
    romp = os.path.splitext(rel)[0]
    if not os.path.basename(romp).startswith('_'):
        for ext in BRONNEN:
            if bestaat_exact(site, romp + ext):
                return 'gerenderd'
    return None


def bestaat_exact(site: str, rel: str) -> bool:
    """Bestaat `rel` als bestand, met precies deze hoofd- en kleine letters?
    Namen worden in NFC vergeleken: de ĳ komt uit git anders binnen dan uit de
    schijf, en dat is geen verschil dat een webserver ziet."""
    if not os.path.isfile(os.path.join(site, rel)):
        return False
    map_ = site
    for deel in rel.split('/'):
        try:
            namen = {unicodedata.normalize('NFC', n) for n in os.listdir(map_)}
        except OSError:
            return False
        if unicodedata.normalize('NFC', deel) not in namen:
            return False
        map_ = os.path.join(map_, deel)
    return True


def alle_doorstuurders(site: str):
    for dp, dn, fn in os.walk(site):
        dn[:] = sorted(d for d in dn if d not in OVERSLAAN
                       and not (dp == site and d.startswith(('_', '.'))))
        for f in sorted(fn):
            if f.endswith('.html'):
                p = os.path.join(dp, f)
                t = lees(p)
                if soort(t) == 'doorstuurder':
                    yield os.path.relpath(p, site), t


def nakijken(site: str) -> int:
    tabel = os.path.join(site, TABEL)
    print('doorstuurders — nakijken')
    print('wortel     : %s' % site)
    print('gereedschap: os.walk + tellerregel.soort() (dezelfde herkenning als de tellerwachter)')
    if not os.path.isfile(tabel):
        print('\nNIETS GEMETEN — %s bestaat niet. Dat is geen schone uitslag maar een blinde.' % TABEL)
        return 3
    rijen = lees_tabel(tabel)
    bouwen = [r for r in rijen if r['besluit'] == 'bouwen']
    if not bouwen:
        print('\nNIETS GEMETEN — de tabel heeft geen enkele rij om te bouwen.')
        return 3

    fouten: list[str] = []
    per_map: dict[str, int] = {}
    for r in bouwen:
        oud, nieuw = r['oud'], r['nieuw']
        k = '/'.join(oud.split('/')[:2])
        per_map[k] = per_map.get(k, 0) + 1
        p = os.path.join(site, oud)
        if not os.path.isfile(p):
            fouten.append('ONTBREEKT   %s  (hoort naar %s te sturen; weggeveegd? '
                          'herstel: python3 _tools/doorstuurders.py --bouw)' % (oud, nieuw))
        else:
            t = lees(p)
            if soort(t) != 'doorstuurder':
                fouten.append('ECHTE BLADZIJ  %s  staat weer als bladzij in de repo; '
                              'haal de rij uit de tabel' % oud)
            elif t != stub(nieuw):
                fouten.append('WIJKT AF    %s  is niet wat de tabel zegt (doel %s); '
                              'herstel: python3 _tools/doorstuurders.py --bouw' % (oud, nieuw))
        wordt = wordt_bladzij(site, nieuw)
        if wordt is None:
            fouten.append('DOEL WEG    %s -> %s  bestaat niet (meer); zoek waar die inhoud nu '
                          'staat en draai --afleiden' % (oud, nieuw))
        elif wordt == 'bestand' and soort(lees(os.path.join(site, nieuw))) != 'bladzij':
            fouten.append('DOEL IS GEEN BLADZIJ  %s -> %s' % (oud, nieuw))

    # de doorstuurders die niet uit deze tabel komen
    uit_tabel = {r['oud'] for r in bouwen}
    anderen = 0
    for rel, t in alle_doorstuurders(site):
        if rel in uit_tabel:
            continue
        anderen += 1
        d = doel_van_refresh(site, rel, t)
        if d is None:
            fouten.append('ONLEESBAAR  %s  (geen refresh-adres binnen countcamp.org gevonden)' % rel)
        elif wordt_bladzij(site, d) is None:
            fouten.append('DOEL WEG    %s -> %s  bestaat niet in de repo, ook niet als bron' % (rel, d))

    print('')
    print('  %-34s %8s' % ('map (uit de tabel)', 'aantal'))
    for k in sorted(per_map):
        print('  %-34s %8d' % (k, per_map[k]))
    print('  %-34s %8d' % ('TOTAAL uit de tabel', len(bouwen)))
    print('  %-34s %8d' % ('andere doorstuurders in de repo', anderen))
    print('  %-34s %8d' % ('rijen die bewust NIET gebouwd zijn', len(rijen) - len(bouwen)))
    voorbeeld = next((r for r in bouwen if 'ozp1' in r['oud']), bouwen[0])
    print('\n  voorbeeld: %s\n          -> %s\n          (%s)' % (voorbeeld['oud'], voorbeeld['nieuw'], voorbeeld['grond']))
    if fouten:
        print('\nKLOPT NIET (%d):' % len(fouten))
        for f in fouten:
            print('    ' + f)
        return 1
    print('\nAlle %d doorstuurders uit de tabel staan er en wijzen naar een bestaande bladzij; '
          'de %d andere ook.' % (len(bouwen), anderen))
    return 0


# ------------------------------------------------------------- afleiden --
def git(site: str, *a: str) -> str:
    return subprocess.run(['git', '-C', site, '-c', 'core.quotepath=off'] + list(a),
                          capture_output=True, text=True, check=True).stdout


def titel(t: str) -> str:
    m = re.search(r'(?s)<title>(.*?)</title>', t)
    return re.sub(r'\s+', ' ', html.unescape(m.group(1))).strip() if m else ''


def kern(t: str) -> str:
    """De titel zonder boeknaam en zonder nummer: 'Thema 3 · Normaalverdeling &
    z-scores – Werkboek OZP 1' en 'Thema 4 · Normaalverdeling & z-scores –
    Oefenboek OZP 1' hebben dezelfde kern. Precies daarom mag het nummer niet
    meetellen: het is wat er veranderde."""
    t = re.split(r' [–|] ', t)[0]
    t = re.sub(r'^\d+\s+(?=Hoofdstuk)', '', t)
    t = re.sub(r'^(Thema|Deel|Oefening|Hoofdstuk|Opdracht)\s+[\d.]+\s*[·\-–]\s*', '', t)
    t = re.sub(r'^\d+\.\s*', '', t)
    return t.strip().lower()


def stam(bestandsnaam: str) -> str:
    s = os.path.splitext(bestandsnaam)[0]
    s = re.sub(r'^\d+[_-]', '', s)
    s = re.sub(r'^(blok_|r_|jasp_|spss_)', '', s)
    return s


def boek_van(pad: str) -> str | None:
    """In welk boek hoort dit (oude of nieuwe) adres thuis?"""
    p = re.sub(r'^werkboeken/', 'oefenboeken/', pad)
    p = p.replace('broertjes/r_preview/', 'broertjes/r/')
    m = re.match(r'oefenboeken/broertjes/(r|jasp|spss)_[^/]+\.html$', p)   # 24-7: plat
    if m:
        return 'oefenboeken/broertjes/' + m.group(1)
    for b in ('oefenboeken/broertjes/r', 'oefenboeken/broertjes/jasp', 'oefenboeken/broertjes/spss',
              'oefenboeken/ozp1', 'oefenboeken/mvda', 'oefenboeken/ggz_vs',
              'oefenboeken/psychometrie', 'manuscript/handleiding'):
        if p.startswith(b + '/'):
            return b
    return None


def woorden(t: str) -> set[str]:
    t = re.sub(r'data:[^"\')\s]+', ' ', t)                     # ingebakken ballast
    t = re.sub(r'(?s)<(script|style|nav|header|footer)\b[^>]*>.*?</\1>', ' ', t)
    m = re.search(r'(?s)<main\b[^>]*>(.*?)</main>', t)
    t = m.group(1) if m else t
    t = html.unescape(re.sub(r'<[^>]+>', ' ', t))
    return {w.lower() for w in re.findall(r'\w{4,}', t)}


def lijkt(a: set[str], b: set[str]) -> float:
    return len(a & b) / max(1, len(a | b))


# Onder deze marge tussen doel en tweede kandidaat heet een koppeling KRAP.
# Gekozen op de verdeling van 1-10-2026: wat eronder viel was een bladzij die
# sindsdien gesplitst is (meervoudige regressie / confounding) of een preview
# van één dag die nog anders heette. KRAP bouwt wél, maar zegt het hardop.
KRAP = 0.05


# Een besluit dat niet uit de regels volgt, staat HIER -- met datum en wie --
# en niet als handwerk in de tabel, want die wordt bij --afleiden herschreven.
# (besluit, doel, reden). Bij 'niet' blijft het doel leeg; bij 'bouwen' moet het
# doel een bestaande bladzij zijn, anders weigert --afleiden.
HANDMATIG: dict[str, tuple[str, str, str]] = {
    # 'werkboeken/broertjes/s2_schud_tabel.html':
    #     ('bouwen', 'speeltjes/schud-tabel.html', 'Ben 1-10: naar de speelkist'),
    # 'werkboeken/broertjes/r_preview/installatie.html':
    #     ('niet', '', 'Ben 1-10: preview van één dag, laat maar'),
}


def afleiden(site: str, uit: str) -> int:
    # pr-preview/ is de proefdruk (--proefdruk schrijft naar dezelfde tak): nooit
    # een adres voor een lezer, dus nooit een doorstuurder waard.
    ooit = {p for p in git(site, 'log', 'origin/gh-pages', '--no-renames', '--format=',
                           '--name-only', '--diff-filter=A').splitlines()
            if p.endswith('.html') and not re.search(r'(^|/)(site_libs|libs)/', p)
            and not p.startswith('pr-preview/')}
    # --no-renames is geen versiering: zonder die vlag ziet git een hernummerd
    # hoofdstuk als een HERNOEMING, en dan heet het nieuwe bestand niet
    # "toegevoegd". Gemeten 1-10-2026: 303 in plaats van 430 bladzijden.
    nu_live = {p for p in git(site, 'ls-tree', '-r', '--name-only', 'origin/gh-pages').splitlines()}
    gh = git(site, 'rev-parse', '--short', 'origin/gh-pages').strip()

    huidig: dict[str, tuple[str, set[str]]] = {}
    for dp, dn, fn in os.walk(site):
        dn[:] = [d for d in dn if d not in OVERSLAAN and not (dp == site and d.startswith(('_', '.')))]
        for f in fn:
            if f.endswith('.html'):
                p = os.path.join(dp, f)
                t = lees(p)
                if soort(t) == 'bladzij':
                    huidig[os.path.relpath(p, site)] = (titel(t), woorden(t))

    # Dood = er staat in DEZE repo geen echte bladzij meer, en er wordt er ook
    # geen gerenderd. Bewust niet "staat niet op gh-pages": zodra de
    # doorstuurders live staan, zou een volgende --afleiden ze dan voor levend
    # aanzien, ze uit de tabel laten vallen -- en dan zet publish_workbook.py ze
    # na zijn rmtree niet meer terug.
    # Een doorstuurder die NIET van ons is (de acht onder werkboeken/, de
    # vijftien onder manuscript/werkplaats/) telt als "hier geregeld": die heeft
    # al een eigenaar, en wij gaan er niet overheen schrijven.
    def echt_hier(p: str) -> bool:
        pad = os.path.join(site, p)
        if os.path.isfile(pad):
            t = lees(pad)
            return soort(t) != 'doorstuurder' or MERK not in t
        return wordt_bladzij(site, p) == 'gerenderd'

    def van_ons(p: str) -> bool:
        pad = os.path.join(site, p)
        return os.path.isfile(pad) and MERK in lees(pad)

    dood = sorted(p for p in ooit if not echt_hier(p))
    # De tweede telling, langs een andere weg: wat nu NIET live staat. Onze eigen
    # doorstuurders staan na publicatie wél live, en tellen hier dus als dood
    # mee -- anders loeit deze controle bij elke run met 181 regels (nakijker,
    # 1-10-2026), en een alarm dat altijd loeit leer je negeren.
    ter_controle = sorted(p for p in ooit
                          if (p not in nu_live or van_ons(p)) and p not in huidig)
    print('ooit op gh-pages: %d html · nu live (%s): %d · dood: %d (langs gh-pages: %d)'
          % (len(ooit), gh, len([p for p in nu_live if p.endswith('.html')]), len(dood), len(ter_controle)))
    if set(dood) ^ set(ter_controle):
        print('  LET OP: de twee tellingen verschillen in: %s'
              % ', '.join(sorted(set(dood) ^ set(ter_controle))))

    rijen = []
    for oud in dood:
        log = [r.split() for r in git(site, 'log', 'origin/gh-pages', '--no-renames',
                                      '--format=%h %cs', '--', oud).splitlines()]
        van = log[-1][1]
        # De laatste versie die een ECHTE bladzij was. Niet "de ouder van de
        # nieuwste commit": staat onze doorstuurder eenmaal live, dan is de
        # nieuwste commit op dit pad die doorstuurder zelf.
        oude_tekst, weg_datum = None, '?'
        for i, (h, _d) in enumerate(log):
            t = subprocess.run(['git', '-C', site, '-c', 'core.quotepath=off', 'show', h + ':' + oud],
                               capture_output=True, text=True)
            if t.returncode == 0 and soort(t.stdout) == 'bladzij':
                oude_tekst = t.stdout
                weg_datum = log[i - 1][1] if i > 0 else '?'
                break
        if oude_tekst is None:
            rijen.append([oud, '', 'niet', 'geen enkele versie op gh-pages was een echte bladzij',
                          '%s..?' % van, '', ''])
            continue
        ot = titel(oude_tekst)
        ow = woorden(oude_tekst)
        boek = boek_van(oud)
        in_boek = [h for h in huidig if boek and h.startswith(boek + '/')]

        kand: dict[str, str] = {}
        p = re.sub(r'^werkboeken/', 'oefenboeken/', oud).replace('broertjes/r_preview/', 'broertjes/r/')
        if p in huidig:
            kand['pad'] = p
        st = [h for h in in_boek if stam(h.split('/')[-1]) == stam(oud.split('/')[-1])]
        if len(st) == 1:
            kand['stam'] = st[0]
        tk = [h for h in in_boek if kern(huidig[h][0]) == kern(ot) and kern(ot)]
        if len(tk) == 1:
            kand['titel'] = tk[0]

        stond = '%s..%s' % (van, weg_datum)
        doelen = set(kand.values())
        if oud in HANDMATIG:
            besluit, nieuw, grond = HANDMATIG[oud]
            grond = 'HANDMATIG: ' + grond
            if besluit == 'bouwen' and wordt_bladzij(site, nieuw) != 'bestand':
                raise ValueError('HANDMATIG %s -> %r: dat doel bestaat niet als bladzij' % (oud, nieuw))
            if besluit == 'niet':
                nieuw = ''
        elif not boek:
            # Zonder boek in het pad zoeken we over de hele site -- niet om te
            # bouwen, maar om de reden eerlijk te maken: "er zijn er vier" is
            # een andere reden dan "er is er geen".
            s = stam(oud.split('/')[-1])
            overal = sorted(h for h in huidig
                            if stam(h.split('/')[-1]).replace('-', '_') == s.replace('-', '_')
                            or (kern(ot) and kern(huidig[h][0]) == kern(ot)))
            besluit, nieuw = 'niet', ''
            if overal:
                grond = ('geen boek in het pad, en %d kopieën van dezelfde bladzij: %s -- welke '
                         'bedoeld is, is een keuze' % (len(overal), ', '.join(overal)))
            else:
                grond = 'geen boek in het pad en nergens op de site een opvolger (op stam of titel)'
        elif not doelen:
            besluit, nieuw, grond = 'niet', '', 'geen kandidaat op pad, stam of titel in %s' % boek
        elif len(doelen) > 1:
            besluit, nieuw, grond = 'niet', '', 'regels oneens: ' + ', '.join('%s=%s' % kv for kv in kand.items())
        else:
            nieuw = doelen.pop()
            score = {h: lijkt(ow, huidig[h][1]) for h in in_boek}
            beste = max(score, key=score.get)
            tweede = max((h for h in score if h != nieuw), key=score.get, default=None)
            regels = '+'.join(kand)
            if beste != nieuw:
                besluit = 'niet'
                grond = ('%s zegt %s, maar de tekst lijkt meer op %s (%.2f tegen %.2f)'
                         % (regels, nieuw, beste, score[beste], score[nieuw]))
                nieuw = ''
            else:
                besluit = 'bouwen'
                marge = score[nieuw] - (score[tweede] if tweede else 0.0)
                # KRAP: het doel wint wel, maar nipt. Meestal is de oude bladzij
                # sindsdien in tweeën gesplitst (meervoudige regressie en
                # confounding). Wel gebouwd -- hetzelfde bestand is de opvolger --
                # maar met de tweede kandidaat bij naam, zodat iemand kan kijken.
                grond = ('%s; woordoverlap %.2f, beste andere: %s %.2f%s'
                         % (regels, score[nieuw], tweede.split('/')[-1] if tweede else '-',
                            score[tweede] if tweede else 0.0,
                            '; KRAP (marge %.2f)' % marge if marge < KRAP else ''))
        rijen.append([oud, nieuw, besluit, grond, stond, ot, huidig.get(nieuw, ('',))[0] if nieuw else ''])

    with open(uit, 'w', encoding='utf-8') as f:
        f.write('# Afgeleid door `python3 _tools/doorstuurders.py --afleiden` uit gh-pages %s.\n' % gh)
        f.write('# Niet met de hand bewerken: een besluit dat niet uit de regels volgt hoort in\n')
        f.write('# HANDMATIG in doorstuurders.py, met datum en wie.\n')
        f.write('# woordoverlap = gedeelde woorden (4+ letters) / alle woorden, oude tekst tegen doel.\n')
        f.write('\t'.join(KOLOMMEN) + '\n')
        for r in rijen:
            f.write('\t'.join(c.replace('\t', ' ') for c in r) + '\n')
    b = sum(1 for r in rijen if r[2] == 'bouwen')
    print('geschreven: %s — %d rijen, %d bouwen, %d niet' % (os.path.relpath(uit, site), len(rijen), b, len(rijen) - b))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group()
    g.add_argument('--bouw', action='store_true', help='schrijf de doorstuurders uit de tabel')
    g.add_argument('--afleiden', action='store_true', help='leid de tabel opnieuw af uit gh-pages')
    ap.add_argument('--site', default=SITE, metavar='PAD', help='reporoot (standaard: deze repo; voor de toets)')
    ap.add_argument('--onder', metavar='MAP', help='bij --bouw: alleen deze map')
    a = ap.parse_args()
    site = os.path.abspath(a.site)
    # Een wachter die omvalt heeft niets gemeten. Zonder dit vangnet eindigt een
    # crash met afloopcode 1 -- en 1 betekent hier "er klopt iets niet", dus
    # naar_buiten.sh gaf dan de doorstuurders de schuld (nakijker, 1-10-2026).
    try:
        if a.afleiden:
            return afleiden(site, os.path.join(site, TABEL))
        if a.bouw:
            n, v, z, w = bouw(site, a.onder)
            print('doorstuurders gebouwd: %d nieuw, %d ververst, %d ongewijzigd, %d geweigerd'
                  % (len(n), len(v), len(z), len(w)))
            for oud, reden in w:
                print('    GEWEIGERD %s — %s' % (oud, reden))
            return 1 if w else 0
        return nakijken(site)
    except Exception:
        print('\nLIEP VAST — de doorstuurwachter viel om; wat hij had moeten meten is '
              'ONGEMETEN, dit zegt niets over de doorstuurders zelf:')
        traceback.print_exc(file=sys.stdout)
        return 3


if __name__ == '__main__':
    sys.exit(main())
