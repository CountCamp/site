#!/usr/bin/env python3
"""Rekent elke regel van elke uitgelijnde som op de Solomon-bladzijden na: klopt elke stap van een som met de vorige?

Waarom. De getallen in de sommen komen uit de data van het speeltje, maar de vorm van een som ("(52 + 2 + 1) −
(50 + 2)") is met de hand samengesteld. Een plusje te veel of een verkeerde haak geeft dan een regel die er goed
uitziet en niet klopt. Op 23-11-2026 rekenden vier lezers alle sommen met de hand na; dat doet deze toets nu bij elke
wijziging.

Hoe. De bladzij gaat open in headless Chrome (--dump-dom, alle uitklappers open). In elke tabel van de klasse "som"
(ook de lopende som van groep I, klasse "som lopend")
hoort bij elke linkerkant een rij rechterkanten, elk achter een "=". Elke rechterkant die alleen uit getallen en
+ − × / ( ) bestaat, wordt uitgerekend, en alle uitkomsten bij dezelfde linkerkant moeten gelijk zijn. Een
rechterkant met woorden erin ("startniveau + H/M") telt niet mee, en dat wordt geteld en gemeld.

Wat hij niet ziet: de sommen zoals ze na het schuiven op het speelbord staan; alleen de begintoestand.

Gebruik: solomon_sommen_test.py [bladzij.html ...]   (zonder argument: beide talen)
Afloop: 0 alles klopt, 1 een som klopt niet, 3 kon niet kijken (geen Chrome, geen sommen gevonden).
"""
import html
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

WERK = Path(__file__).resolve().parents[2]
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OPEN = """<script>window.addEventListener('load',function(){[].forEach.call(document.querySelectorAll('details'),
function(d){d.open=true;});var p=document.createElement('pre');p.id='klaar';document.body.appendChild(p);});</script>"""
REKEN = re.compile(r"^[0-9.+\-*/() ]+$")


def dump(bron):
    t = bron.read_text(encoding="utf-8")
    t = re.sub(r'\s*<script data-goatcounter[^>]*></script>', '', t).replace("</body>", OPEN + "</body>", 1)
    kopie = bron.parent / ("._sommen_" + bron.name)
    kopie.write_text(t, encoding="utf-8")
    uit = Path(tempfile.mkdtemp(prefix="solomon_sommen_")) / "dom.html"
    try:
        with open(uit, "w") as f:
            p = subprocess.Popen([CHROME, "--headless=new", "--disable-gpu", "--user-data-dir=" + str(uit.parent / "profiel"),
                                  "--virtual-time-budget=6000", "--window-size=1200,2000", "--dump-dom", kopie.as_uri()],
                                 stdout=f, stderr=subprocess.DEVNULL)
            for _ in range(120):
                time.sleep(0.5)
                if "</html>" in uit.read_text(encoding="utf-8", errors="replace") or p.poll() is not None:
                    time.sleep(0.3)
                    break
            p.kill()
            p.wait()
    finally:
        kopie.unlink()
    return uit.read_text(encoding="utf-8", errors="replace")


def tekst(cel):
    return html.unescape(re.sub(r"<[^>]+>", "", cel)).replace(" ", " ").strip()


def waarde(s):
    s = s.replace("−", "-").replace("×", "*")
    if not REKEN.match(s):
        return None
    return eval(s, {"__builtins__": {}})   # alleen cijfers en + - * / ( ), getoetst met REKEN hierboven


def toets(bron):
    dom = dump(bron)
    if 'id="klaar"' not in dom:
        print("KON NIET KIJKEN: %s gaf geen volledige bladzij" % bron.name)
        return None
    # de broncode van som() en somBlok() staat zelf in de DOM, met de tabelkop als tekenreeks: scripts eerst eruit.
    # Ook de lopende som van groep I ("geen-apa som lopend") telt mee; tot de nakijker het zag (23-11) viel hij erbuiten.
    dom = re.sub(r"<script\b.*?</script>", "", dom, flags=re.S)
    tabellen = re.findall(r'<table class="geen-apa som(?: lopend)?">(.*?)</table>', dom, re.S)
    fouten, regels, gerekend, woorden = [], 0, 0, 0
    for tab in tabellen:
        reeks = {}
        for rij in re.findall(r"<tr>(.*?)</tr>", tab, re.S):
            l = re.search(r'<td class="l">(.*?)</td>', rij, re.S)
            r = re.search(r'<td class="r">(.*?)</td>', rij, re.S)
            if not (l and r):
                continue
            regels += 1
            links, rechts = tekst(l.group(1)), tekst(r.group(1))
            v = waarde(rechts)
            if v is None:
                woorden += 1
                continue
            gerekend += 1
            if links in reeks and abs(reeks[links][1] - v) > 1e-9:
                fouten.append("%s = %s geeft %g, maar de regel ervoor (%s) gaf %g" % (links, rechts, v, reeks[links][0], reeks[links][1]))
            reeks.setdefault(links, (rechts, v))
    print("%-18s %2d sommen, %3d regels: %3d uitgerekend, %2d met woorden (niet te rekenen), %d fout" %
          (bron.name, len(tabellen), regels, gerekend, woorden, len(fouten)))
    for f in fouten:
        print("   FOUT:", f)
    if not tabellen or not gerekend:
        print("KON NIET KIJKEN: geen sommen gevonden in", bron.name)
        return None
    return not fouten


paden = [Path(a).resolve() for a in sys.argv[1:]] or [WERK / "speeltjes" / "solomon.html", WERK / "speeltjes" / "solomon-en.html"]
uitslag = [toets(p) if p.exists() else None for p in paden]
if None in uitslag:
    sys.exit(3)
if not all(uitslag):
    sys.exit(1)
print("ok: elke regel van elke som geeft hetzelfde als de regel ervoor")
