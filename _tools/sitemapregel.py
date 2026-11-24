#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""sitemapregel.py — één plek die weet welk adres een bladzij heeft, en welke
bladzij in de sitemap hoort.

Twee scripts moeten hetzelfde meten, en zodra ze het ieder voor zich doen lopen
ze uiteen zonder dat iemand het merkt:

  1. `sitemap_zetten.py`  — de bouwstap: schrijft sitemap.xml en zet in elke
                            echte bladzij een <link rel="canonical">
  2. `sitemapwacht.py`    — de wachter: leest de gebouwde site na

De wachter leest de bladzijden wél op een eigen manier (met een HTML-ontleder,
niet met de reguliere uitdrukkingen hieronder), zodat een blinde vlek in de
bouwstap niet ook een blinde vlek in de wachter is. Wat ze delen is alleen de
AFSPRAAK: welk adres, welke bladzij telt.

Waarom dit bestaat (24-11-2026, spoor sitemap_canoniek)
-------------------------------------------------------
Quarto schrijft zelf een sitemap.xml, maar alleen met de bladzijden die hij uit
een .qmd bouwt: 11 adressen, terwijl de site er 276 heeft -- het boek, de
oefenboeken, de handleiding, de speeltjes en en/ komen als bijlage binnen en
zag hij niet. En hij schreef ze als `…/index.html`, terwijl elke link en elke
hreflang-verwijzing op de site `…/` zegt. Google zag zo twee adressen voor één
bladzij ("Duplicate without user-selected canonical", Search Console) en
GoatCounter telde `/manuscript/` en `/manuscript/index.html` als twee paden.
"""
from __future__ import annotations
import os
import re
from urllib.parse import quote, unquote, urlsplit

# Het adres van de echte site. Staat ook in `_quarto.yml` en `_quarto-echt.yml`
# (site-url) en in `CNAME`; `_tools/tests/sitemapwacht_test.sh` eist dat ze
# overeenkomen, zodat er niet stil een tweede waarheid ontstaat.
SITE_URL = 'https://countcamp.org'

# Een bladzij die naar een ANDERE bladzij wijst als "het echte adres van deze
# inhoud". Staat er niets in, dan wijst elke bladzij naar zichzelf. Zie de kop
# van het bestand.
ANDERS_TABEL = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            'canoniek_anders.tsv')

_ROBOTS = re.compile(r'<meta\b[^>]*\bname\s*=\s*["\']?(?:robots|googlebot)["\']?[^>]*>', re.I)
_CANON = re.compile(r'[ \t]*<link\b[^>]*\brel\s*=\s*["\']?canonical(?=["\'\s/>])[^>]*>[ \t]*\n?', re.I)
_HREF = re.compile(r'\bhref\s*=\s*(?:"([^"]*)"|\'([^\']*)\'|([^\s>]+))', re.I)


def site_pad(rel: str) -> str:
    """Pad binnen de uitvoermap, altijd met `/` (ook op een machine met `\\`)."""
    return rel.replace(os.sep, '/')


def adres(rel: str) -> str:
    """Het ene adres van een gebouwde bladzij, zoals het in de sitemap en in de
    canonical komt.

        index.html                          -> https://countcamp.org/
        oefenboeken/index.html              -> https://countcamp.org/oefenboeken/
        speeltjes/solomon.html              -> https://countcamp.org/speeltjes/solomon.html
        manuscript/handleiding/hoofdstuk-1---het-beschrĳven-….html
                                            -> …/hoofdstuk-1---het-beschr%C4%B3ven-….html

    `…/` en niet `…/index.html`: zo staat het in elke link op de site, in de
    hreflang-verwijzingen (taalwissel.lua, taalonderdelen.py) en in de
    doorstuurders (doorstuurders.py, doel_url). Tekens buiten ASCII worden
    procent-gecodeerd, zoals een sitemap eist.
    """
    p = site_pad(rel)
    if p == 'index.html':
        p = ''
    elif p.endswith('/index.html'):
        p = p[:-len('index.html')]
    return SITE_URL + '/' + quote(p, safe='/')


def pad_van_adres(url: str) -> str | None:
    """Omgekeerd: van een adres op deze site naar het bestand in de uitvoermap.
    None als het adres niet op deze site ligt."""
    d = urlsplit(url)
    if (d.scheme + '://' + d.netloc) != SITE_URL:
        return None
    p = unquote(d.path).lstrip('/')
    if p == '' or p.endswith('/'):
        p += 'index.html'
    return p


def gelijk_adres(a: str, b: str) -> bool:
    """Twee schrijfwijzen van hetzelfde adres? (`%C4%B3` tegen `ĳ`.)"""
    return unquote(a) == unquote(b)


def is_404(rel: str) -> bool:
    """Een foutbladzij: die staat op elk adres dat niet bestaat, en heeft er dus
    zelf geen. Quarto laat zijn eigen 404.html ook uit de sitemap; de
    handleiding (bookdown) heeft er een tweede."""
    return os.path.basename(site_pad(rel)) == '404.html'


_QUARTO_ROBOTS = re.compile(r'\s*Sitemap:\s*\S*sitemap\.xml\s*', re.I)


def is_quarto_robots(tekst: str) -> bool:
    """Is dit de robots.txt die Quarto zelf schrijft als het project er geen heeft?
    Dat is precies één regel: `Sitemap: <site-url>sitemap.xml`."""
    return bool(_QUARTO_ROBOTS.fullmatch(tekst))


def robots_sitemaps(tekst: str) -> list[str]:
    """Elke `Sitemap:`-regel in een robots.txt."""
    return [r.split(':', 1)[1].strip() for r in tekst.splitlines()
            if r.strip().lower().startswith('sitemap:')]


def noindex(tekst: str) -> bool:
    """Draagt de bladzij `<meta name="robots" content="…noindex…">` (of googlebot)?"""
    return any('noindex' in m.group(0).lower() for m in _ROBOTS.finditer(tekst))


def canonicals(tekst: str) -> list[str]:
    """De href van elke <link rel="canonical"> in de bladzij, in volgorde."""
    uit = []
    for m in _CANON.finditer(tekst):
        h = _HREF.search(m.group(0))
        uit.append(next(g for g in h.groups() if g is not None) if h else '')
    return uit


def zonder_canonicals(tekst: str) -> str:
    return _CANON.sub('', tekst)


def canonical_regel(url: str) -> str:
    return '<link rel="canonical" href="%s">\n' % url.replace('&', '&amp;').replace('"', '&quot;')


def lees_anders(pad: str = ANDERS_TABEL) -> dict[str, str]:
    """`canoniek_anders.tsv`: sitepad -> sitepad van de bladzij waarnaar hij wijst.

    Weigert luid bij een kapotte regel: een tabel die half gelezen wordt, is een
    sitemap die half klopt.
    """
    uit: dict[str, str] = {}
    if not os.path.isfile(pad):
        return uit
    kop = None
    with open(pad, encoding='utf-8') as f:
        for nr, r in enumerate(f, 1):
            r = r.rstrip('\n')
            if not r.strip() or r.startswith('#'):
                continue
            velden = r.split('\t')
            if kop is None:
                kop = velden
                if kop[:2] != ['bladzij', 'wijst_naar']:
                    raise ValueError('%s:%d: kop moet beginnen met "bladzij<TAB>wijst_naar", '
                                     'staat er: %r' % (pad, nr, r))
                continue
            if len(velden) < 2 or not velden[0] or not velden[1]:
                raise ValueError('%s:%d: regel zonder twee kolommen: %r' % (pad, nr, r))
            if velden[0] in uit:
                raise ValueError('%s:%d: %s staat er twee keer in' % (pad, nr, velden[0]))
            if velden[0] == velden[1]:
                raise ValueError('%s:%d: %s wijst naar zichzelf; dat is de standaard en '
                                 'hoort hier niet' % (pad, nr, velden[0]))
            uit[velden[0]] = velden[1]
    return uit


_LOC = re.compile(r'<loc>\s*(.*?)\s*</loc>', re.S)


def sitemap_zonder_engels(tekst: str) -> str:
    """De sitemap zoals de Nederlandse kant hem ziet: elk adres BEHALVE die onder
    /en/, gesorteerd, één per regel. Voor de vingerafdruk van en_bouw.py
    ("Nederlands ongemoeid"): een Engelse bladzij erbij of eraf verandert de
    sitemap, en dat is geen Nederlands bestand dat veranderde. Verandert er een
    Nederlands adres, dan verandert dit wel."""
    eng = SITE_URL + '/en/'
    return '\n'.join(sorted(a for a in _LOC.findall(tekst) if not a.startswith(eng))) + '\n'


def afdeling(rel: str) -> str:
    """Voor de telling per afdeling: `oefenboeken/ozp1/…` -> `oefenboeken/ozp1`,
    `en/book/h0.html` -> `en/book`, `index.html` -> `(wortel)`."""
    deel = site_pad(rel).split('/')
    if len(deel) == 1:
        return '(wortel)'
    if deel[0] == 'oefenboeken' and len(deel) > 3 and deel[1] == 'broertjes':
        return '/'.join(deel[:3])
    if deel[0] in ('oefenboeken', 'manuscript', 'en') and len(deel) > 2:
        return '/'.join(deel[:2])
    return deel[0]
