#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""kiek.py — een schermafdruk van een bladzij van deze site, zoals een bezoeker hem ziet.

    python3 _tools/kiek.py <bladzij> <uit.png> [--breed 1280] [--hoog <px>] [--stuk <px>] [--wortel .]

<bladzij> is een pad vanaf de wortel van de site (`en/workbooks/index.html`). De
wortel wordt aangeboden door een eigen http-servertje op 127.0.0.1, zodat de
relatieve paden (`../../styles.css`, `../libs/`) uitkomen zoals op countcamp.org.
Chrome draait zonder scherm en ZONDER internet (`--host-resolver-rules`), net als
in tests/taalbalk_browser_test.py: de bezoekersteller telt dus niets, en wat er
van buiten moet komen (lettertypen van Google, de teller) ontbreekt.

Zonder --hoog meet het script eerst hoe hoog de bladzij op die breedte is, en
maakt dan een afdruk van de hele bladzij.

TELEFOONBREEDTE. Gemeten 21-11-2026: Chrome zonder scherm maakt zijn venster
nooit smaller dan ongeveer 500 px. Vraag je 390, dan wordt de bladzij op die
grotere breedte opgemaakt en daarna op 390 afgesneden: elke regel mist zijn
rechterkant, en de chips rechts vallen weg. Twee testlezers lazen dat als een
kapotte telefoonbladzij. Daarom zet dit script een bladzij smaller dan
IFRAME_ONDER in een iframe van precies die breedte, links in het venster; Chrome
snijdt de afdruk dan af op de rand van het iframe. Binnen het iframe is de
breedte echt 390, en gelden de @media-regels voor een telefoon.

Waarom dit er is (taalmerk, 21-11-2026): spoor en_ts_pers kon niet zien hoe zijn
kaartje eruitzag ("ik had geen browser die ik zonder extra toestemming kon
starten"), en testlezers lazen tot dan een beschrijving van de bladzij in plaats
van de bladzij. Zij kunnen een .png lezen.

Afloop: 0 gemaakt, 1 Chrome maakte geen afdruk of de hoogte was niet te meten,
3 kon niet kijken (geen Chrome, bladzij bestaat niet).
"""
from __future__ import annotations

import argparse
import functools
import http.server
import json
import os
import re
import subprocess
import sys
import tempfile
import threading

CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IFRAME_ONDER = 600   # smaller dan dit: via een iframe (zie TELEFOONBREEDTE)
OMHULSEL = "__kiek__.html"
OVERLAP = 80         # px die opeenvolgende stukken delen (zie --stuk)


class Stil(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):  # het servertje praat niet mee
        pass


def chrome(profiel: str, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [CHROME, "--headless=new", "--disable-gpu", "--no-sandbox", "--no-first-run",
         f"--user-data-dir={profiel}", "--lang=en-GB", "--accept-lang=en-GB,en",
         "--host-resolver-rules=MAP * ~NOTFOUND , EXCLUDE 127.0.0.1",
         "--hide-scrollbars", "--force-device-scale-factor=1",
         "--virtual-time-budget=4000", *args],
        capture_output=True, text=True, timeout=120)


def omhulsel(bladzij: str, breed: int, hoog: int, vanaf: int = 0) -> str:
    """Een bladzij die de echte bladzij in een iframe van `breed` × `hoog` px toont,
    daarin gescrold naar `vanaf` px van boven, en na het laden in <pre id="KIEK">
    opschrijft hoe hoog die bladzij is.

    Gescrold, niet verschoven: een iframe zo hoog als de hele bladzij met een
    negatieve marge gaf op 21-11-2026 in Chrome zonder scherm twee lagen tekst
    over elkaar onderin elk stuk."""
    return f"""<!doctype html><html><head><meta charset="utf-8"></head>
<body style="margin:0;background:#fff;overflow:hidden">
<iframe id="v" src="/{bladzij}" style="border:0;display:block;width:{breed}px;height:{hoog}px"></iframe>
<script>
document.getElementById('v').addEventListener('load', function () {{
  var f = this;
  f.contentWindow.scrollTo({{top: {vanaf}, behavior: 'instant'}});
  setTimeout(function () {{
    f.contentWindow.scrollTo({{top: {vanaf}, behavior: 'instant'}});
    var p = document.createElement('pre'); p.id = 'KIEK';
    p.textContent = JSON.stringify({{hoog: f.contentDocument.documentElement.scrollHeight,
                                     breed: f.contentDocument.documentElement.clientWidth}});
    document.body.appendChild(p);
  }}, 600);
}});
</script></body></html>"""


def main() -> int:
    ap = argparse.ArgumentParser(description="schermafdruk van een bladzij, zonder internet")
    ap.add_argument("bladzij")
    ap.add_argument("uit")
    ap.add_argument("--breed", type=int, default=1280)
    ap.add_argument("--hoog", type=int, default=None, help="standaard: de hele bladzij")
    ap.add_argument("--wortel", default=REPO)
    ap.add_argument("--stuk", type=int, default=None,
                    help="knip de bladzij in afdrukken van hooguit zoveel px (<uit>_1.png, _2, ...); "
                         "een lange telefoonbladzij wordt anders bij het lezen zo verkleind dat er "
                         "niets meer van te lezen is")
    a = ap.parse_args()

    if not os.path.isfile(CHROME):
        print(f"KON NIET KIJKEN: Chrome staat niet op {CHROME} (zet CHROME=<pad>)")
        return 3
    wortel = os.path.abspath(a.wortel)
    if not os.path.isfile(os.path.join(wortel, a.bladzij)):
        print(f"KON NIET KIJKEN: {a.bladzij} bestaat niet onder {wortel}")
        return 3

    srv = http.server.ThreadingHTTPServer(
        ("127.0.0.1", 0), functools.partial(Stil, directory=wortel))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    basis = f"http://127.0.0.1:{srv.server_address[1]}"
    uit = os.path.abspath(a.uit)
    # Een oude afdruk weg, anders telt hij als gelukt. Met --stuk niet: dan maakt
    # het script <uit>_1.png enz. en blijft <uit> zelf onaangeroerd (21-11-2026:
    # de eerste versie gooide hier zo een gecommitte afdruk weg).
    if not a.stuk and os.path.exists(uit):
        os.remove(uit)
    hulsel = os.path.join(wortel, OMHULSEL)
    try:
        with tempfile.TemporaryDirectory(prefix="kiek_") as werk:
            # 1. meten: hoe hoog is de bladzij op deze breedte, en is de breedte echt?
            with open(hulsel, "w", encoding="utf-8") as f:
                f.write(omhulsel(a.bladzij, a.breed, 800))
            r = chrome(os.path.join(werk, "p1"), f"--window-size={max(a.breed, 800)},800",
                       "--dump-dom", f"{basis}/{OMHULSEL}")
            m = re.search(r'<pre id="KIEK">(.*?)</pre>', r.stdout, re.S)
            if not m:
                print(f"GEEN MAAT: de hoogte van {a.bladzij} was niet te meten. {(r.stderr or '')[-300:]}")
                return 1
            maat = json.loads(m.group(1).replace("&quot;", '"'))
            hoog = a.hoog or maat["hoog"]

            # 2. de afdruk, of met --stuk een reeks afdrukken onder elkaar
            if a.stuk:
                stam, ext = os.path.splitext(uit)
                stukken = []
                # Elk stuk begint OVERLAP px vóór het eind van het vorige: op een telefoon
                # schuift Quarto's menubalk mee naar beneden en dekt bovenin elk stuk
                # zo'n 70 px af (gemeten 21-11-2026). Zo valt er geen regel weg.
                stap = max(a.stuk - OVERLAP, 100)
                vanafs = list(range(0, max(hoog - a.stuk, 0) + 1, stap))
                if vanafs[-1] + a.stuk < hoog:
                    vanafs.append(hoog - a.stuk)
                for i, vanaf in enumerate(vanafs, 1):
                    h = min(a.stuk, hoog - vanaf)
                    with open(hulsel, "w", encoding="utf-8") as f:
                        f.write(omhulsel(a.bladzij, a.breed, h, vanaf))
                    pad = f"{stam}_{i}{ext}"
                    if os.path.exists(pad):
                        os.remove(pad)
                    r = chrome(os.path.join(werk, f"s{i}"), f"--window-size={a.breed},{h}",
                               f"--screenshot={pad}", f"{basis}/{OMHULSEL}")
                    if not os.path.isfile(pad):
                        print(f"GEEN AFDRUK van stuk {i}: {(r.stderr or '')[-400:]}")
                        return 1
                    stukken.append(os.path.relpath(pad))
                print(f"kiek: {a.bladzij} op {a.breed} px breed, {hoog} px hoog, in {len(stukken)} "
                      f"stukken van hooguit {a.stuk} px: {', '.join(stukken)}")
                return 0
            if a.breed < IFRAME_ONDER:
                with open(hulsel, "w", encoding="utf-8") as f:
                    f.write(omhulsel(a.bladzij, a.breed, hoog))
                doel = f"{basis}/{OMHULSEL}"
            else:
                doel = f"{basis}/{a.bladzij}"
            r = chrome(os.path.join(werk, "p2"), f"--window-size={a.breed},{hoog}",
                       f"--screenshot={uit}", doel)
    finally:
        if os.path.exists(hulsel):
            os.remove(hulsel)
        srv.shutdown()

    if not os.path.isfile(uit):
        print(f"GEEN AFDRUK: {(r.stderr or '')[-400:]}")
        return 1
    print(f"kiek: {a.bladzij} op {a.breed}×{hoog} px -> {a.uit}"
          f" (bladzij gemeten: {maat['hoog']} px hoog, {maat['breed']} px breed binnen het venster"
          + (f"; LET OP: --hoog {a.hoog} snijdt de onderkant af" if a.hoog and a.hoog < maat["hoog"] else "")
          + (f"; LET OP: opgemaakt op {maat['breed']} in plaats van {a.breed}" if abs(maat["breed"] - a.breed) > 20 else "")
          + ")")
    return 0


if __name__ == "__main__":
    sys.exit(main())
