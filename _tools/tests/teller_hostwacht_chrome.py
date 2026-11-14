#!/usr/bin/env python3
"""teller_hostwacht_chrome.py — de hostwacht uit _tools/teller.html in een ECHTE browser.

    python3 _tools/tests/teller_hostwacht_chrome.py [--site _site]

Waarom naast teller_hostwacht_test.ts: die draait de wacht in Deno met een
nagebootste `location` en `document`. Dat toetst de logica, niet wat een browser
ermee doet. Tot 9-10-2026 stond dat in het rapport van spoor `teller` als
"niet nagemeten: niet in een echte browser". Deze toets opent GEBOUWDE
bladzijden in headless Chrome op acht adressen en kijkt of count.js wordt
opgehaald: op countcamp.org wel, op een proefdruk, een IP-adres, `broodje` of
een los bestand niet.

Twee metingen per adres, met opzet: komt de aanvraag binnen op het NETWERK (de
proefserver hieronder schrijft hem op), en staat het script in de DOM. Allebei
moeten ze kloppen.

BENS CIJFERS BLIJVEN SCHOON. Elke bladzij wordt geserveerd met precies één
verandering: het adres van count.js wordt een proefadres op deze server. De
wachtregels zelf blijven letterlijk staan. Daarnaast stuurt Chrome elke andere
hostnaam naar ~NOTFOUND: ook als die vervanging zou mislukken, gaat er niets
naar gc.zgo.at.

DE BIJTPROEF ZIT ERIN. Daarna draait dezelfde ronde nog eens met de twee
wachtregels weggehaald. Dan MOETEN alle vijf "telt niet"-adressen zakken. Doen
ze dat niet, dan meet deze toets niets, en dan is hij rood.

Afloopcode (huisafspraak): 0 in orde · 1 fout · 3 kon niet kijken (geen
Chrome, geen echte bouw).
"""
import argparse
import http.server
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ECHT = "https://gc.zgo.at/count.js"
REPO = Path(__file__).resolve().parent.parent.parent
# De twee wachtregels uit teller.html. Staan ze er niet precies zo, dan kan de
# bijtproef ze niet weghalen -- en dan zegt hij dat hardop (afloopcode 3).
WACHT = re.compile(r"\n[ \t]*if \(h !== 'countcamp\.org'[^\n]*return;"
                   r"\n[ \t]*if \(p\.indexOf\('/pr-preview/'\) === 0\) return;")


def maak_server(site, proef_hits, wacht_uit):
    class Bediener(http.server.BaseHTTPRequestHandler):
        def log_message(self, *a):
            pass

        def do_GET(self):
            pad = self.path.split("?")[0]
            if pad.startswith("/__telproef.js"):
                proef_hits.append(self.headers.get("Referer", "?"))
                self.send_response(200)
                self.send_header("Content-Type", "text/javascript")
                self.end_headers()
                self.wfile.write(b"/* proef */")
                return
            # /pr-preview/pr-1/x -> x, zoals rossjrw/pr-preview-action het neerzet
            pad = re.sub(r"^/pr-preview/pr-\d+/", "/", pad)
            bestand = site / pad.lstrip("/")
            if bestand.is_dir():
                bestand = bestand / "index.html"
            if not bestand.is_file():
                self.send_response(404)
                self.end_headers()
                return
            data = bestand.read_bytes()
            soort = {".css": "text/css", ".js": "text/javascript"}.get(bestand.suffix,
                                                                       "application/octet-stream")
            if bestand.suffix == ".html":
                data = herschrijf(data.decode("utf-8", errors="surrogateescape"),
                                  self.server.proef, wacht_uit[0]).encode("utf-8", errors="surrogateescape")
                soort = "text/html; charset=utf-8"
            self.send_response(200)
            self.send_header("Content-Type", soort)
            self.end_headers()
            self.wfile.write(data)

    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Bediener)
    srv.proef = "http://127.0.0.1:%d/__telproef.js" % srv.server_port
    return srv


def herschrijf(tekst, proef, wacht_uit):
    if wacht_uit:
        tekst = WACHT.sub("", tekst)
    return tekst.replace(ECHT, proef)


def chrome(url, poort, werk):
    uit = Path(tempfile.mkstemp(dir=werk, suffix=".html")[1])
    regels = ("MAP countcamp.org 127.0.0.1:{p}, MAP www.countcamp.org 127.0.0.1:{p}, "
              "MAP broodje 127.0.0.1:{p}, MAP * ~NOTFOUND, EXCLUDE 127.0.0.1").format(p=poort)
    with open(uit, "w") as f:
        p = subprocess.Popen([CHROME, "--headless=new", "--disable-gpu",
                              "--user-data-dir=" + tempfile.mkdtemp(dir=werk),
                              "--host-resolver-rules=" + regels,
                              "--disable-features=HttpsUpgrades,HttpsFirstBalancedModeAutoEnable",
                              "--virtual-time-budget=5000", "--dump-dom", url],
                             stdout=f, stderr=subprocess.DEVNULL)
        # Chrome sluit op broodje na --dump-dom niet altijd af (gemeten 8-10-2026,
        # solomon_figuren_test.py): wachten tot de DOM er staat, dan afschieten.
        for _ in range(80):
            time.sleep(0.5)
            if "</html>" in uit.read_text(encoding="utf-8", errors="replace"):
                time.sleep(1.0)   # het count-script mag nog even binnenkomen
                break
            if p.poll() is not None:
                break
        p.kill()
        p.wait()
    return uit.read_text(encoding="utf-8", errors="replace")


def ronde(zaken, srv, hits, werk, toon):
    """Geeft per zaak (url, verwacht, opgehaald, in_dom, geladen)."""
    uitslag = []
    for url, moet in zaken:
        voor = len(hits)
        dom = chrome(url, srv.server_port, werk)
        gehaald = len(hits) > voor
        in_dom = re.search(r'<script[^>]+src="%s' % re.escape(srv.proef), dom) is not None
        geladen = "</html>" in dom and len(dom) > 2000
        uitslag.append((url, moet, gehaald, in_dom, geladen))
        if toon:
            goed = geladen and gehaald == moet and in_dom == moet
            print("  %-5s %-48s %-9s netwerk: %-4s DOM: %-4s%s" % (
                "ok" if goed else "ZAKT", url if len(url) < 48 else url[:22] + "…" + url[-25:],
                "telt" if moet else "telt niet", "ja" if gehaald else "nee",
                "ja" if in_dom else "nee", "" if geladen else "   (bladzij NIET geladen)"))
    return uitslag


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--site", default=str(REPO / "_site"))
    site = Path(ap.parse_args().site).resolve()

    print("teller_hostwacht_chrome -- %s" % site)
    if not Path(CHROME).exists():
        print("KON NIET KIJKEN: geen Chrome op %s" % CHROME)
        return 3
    proefbladzij = site / "power" / "index.html"
    if not proefbladzij.is_file():
        print("KON NIET KIJKEN: %s bestaat niet. Eerst bouwen (quarto render)." % proefbladzij)
        return 3
    bron = proefbladzij.read_text(encoding="utf-8")
    if bron.count(ECHT) != 1 or not WACHT.search(bron):
        print("KON NIET KIJKEN: power/index.html draagt het tellerblok niet precies één keer, of de "
              "wachtregels staan er anders dan deze toets ze kent. Is dit een echte bouw (geen proefdruk)?")
        return 3

    hits, wacht_uit = [], [False]
    srv = maak_server(site, hits, wacht_uit)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    werk = tempfile.mkdtemp(prefix="hostwacht_chrome_")
    los = Path(werk) / "los" / "power" / "index.html"   # file:// -- een herschreven kopie op schijf
    los.parent.mkdir(parents=True)
    poort = srv.server_port
    zaken = [
        ("http://countcamp.org/power/", True),
        ("http://www.countcamp.org/oefenboeken/ggz_vs/", True),
        ("http://countcamp.org/speeltjes/solomon.html", True),
        ("http://countcamp.org/pr-preview/pr-1/power/", False),
        ("http://countcamp.org/pr-preview/pr-1/manuscript/h4.html", False),
        ("http://127.0.0.1:%d/power/" % poort, False),
        ("http://broodje/oefenboeken/ggz_vs/", False),
        (los.as_uri(), False),
    ]
    try:
        print("== de wacht zoals hij gebouwd is")
        los.write_text(herschrijf(bron, srv.proef, False), encoding="utf-8")
        echt = ronde(zaken, srv, hits, werk, toon=True)
        print("== bijtproef: dezelfde adressen, de twee wachtregels weggehaald")
        wacht_uit[0] = True
        los.write_text(herschrijf(bron, srv.proef, True), encoding="utf-8")
        kreupel = ronde(zaken, srv, hits, werk, toon=False)
    finally:
        srv.shutdown()
        shutil.rmtree(werk, ignore_errors=True)

    ongeladen = [u for u, _m, _g, _d, gel in echt + kreupel if not gel]
    if ongeladen:
        print("\nKON NIET KIJKEN: %d keer laadde de bladzij niet, bv. %s" % (len(ongeladen), ongeladen[0]))
        return 3
    gezakt = [u for u, moet, g, d, _ in echt if not (g == moet and d == moet)]
    gebeten = [u for u, moet, g, d, _ in kreupel if not moet and g and d]
    n_niet = sum(1 for _u, moet in zaken if not moet)
    print("   %d van de %d 'telt niet'-adressen gingen tellen zodra de wacht eruit was" % (len(gebeten), n_niet))
    print("\n%d ok, %d gezakt (van %d); bijtproef %d/%d" % (
        len(zaken) - len(gezakt), len(gezakt), len(zaken), len(gebeten), n_niet))
    if gezakt:
        return 1
    if len(gebeten) != n_niet:
        print("FOUT: de bijtproef beet niet overal -- dan meet deze toets niet wat hij zegt te meten")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
