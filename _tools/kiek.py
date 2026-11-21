#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""kiek.py — een schermafdruk van een bladzij van deze site, zoals een bezoeker hem ziet.

    python3 _tools/kiek.py <bladzij> <uit.png> [--breed 1280] [--hoog 2400] [--wortel .]

<bladzij> is een pad vanaf de wortel van de site (`en/workbooks/index.html`). De
wortel wordt aangeboden door een eigen http-servertje op 127.0.0.1, zodat de
relatieve paden (`../../styles.css`, `../libs/`) uitkomen zoals op countcamp.org.
Chrome draait zonder scherm en ZONDER internet (`--host-resolver-rules`), net als
in tests/taalbalk_browser_test.py: de bezoekersteller telt dus niets, en wat er
van buiten moet komen (lettertypen van Google, de teller) ontbreekt.

Waarom dit er is (taalmerk, 21-11-2026): spoor en_ts_pers kon niet zien hoe zijn
kaartje eruitzag ("ik had geen browser die ik zonder extra toestemming kon
starten"), en testlezers lazen tot dan een beschrijving van de bladzij in plaats
van de bladzij. Zij kunnen een .png lezen.

Kiest --hoog te klein, dan valt de onderkant weg; het script zegt dan hoe hoog de
bladzij echt is (gemeten in dezelfde Chrome), zodat je het opnieuw kunt doen.

Afloop: 0 gemaakt, 1 Chrome maakte geen afdruk, 3 kon niet kijken (geen Chrome,
bladzij bestaat niet).
"""
from __future__ import annotations

import argparse
import functools
import http.server
import os
import re
import subprocess
import sys
import tempfile
import threading

CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


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


def main() -> int:
    ap = argparse.ArgumentParser(description="schermafdruk van een bladzij, zonder internet")
    ap.add_argument("bladzij")
    ap.add_argument("uit")
    ap.add_argument("--breed", type=int, default=1280)
    ap.add_argument("--hoog", type=int, default=2400)
    ap.add_argument("--wortel", default=REPO)
    a = ap.parse_args()

    if not os.path.isfile(CHROME):
        print(f"KON NIET KIJKEN: Chrome staat niet op {CHROME} (zet CHROME=<pad>)")
        return 3
    if not os.path.isfile(os.path.join(a.wortel, a.bladzij)):
        print(f"KON NIET KIJKEN: {a.bladzij} bestaat niet onder {a.wortel}")
        return 3

    srv = http.server.ThreadingHTTPServer(
        ("127.0.0.1", 0), functools.partial(Stil, directory=os.path.abspath(a.wortel)))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{srv.server_address[1]}/{a.bladzij}"
    uit = os.path.abspath(a.uit)
    try:
        with tempfile.TemporaryDirectory(prefix="kiek_") as werk:
            # Eerst de echte hoogte, in dezelfde Chrome en op dezelfde breedte.
            meet = (f"<script>addEventListener('load',function(){{setTimeout(function(){{"
                    f"var p=document.createElement('pre');p.id='KIEK';"
                    f"p.textContent=document.documentElement.scrollHeight;"
                    f"document.body.appendChild(p)}},500)}})</script>")
            pad = os.path.join(a.wortel, a.bladzij)
            with open(pad, encoding="utf-8") as f:
                t = f.read()
            proef = os.path.join(os.path.dirname(pad), "__kiek__.html")
            with open(proef, "w", encoding="utf-8") as f:
                f.write(t.replace("</body>", meet + "</body>", 1))
            try:
                r = chrome(os.path.join(werk, "p1"), f"--window-size={a.breed},{a.hoog}", "--dump-dom",
                           url.rsplit("/", 1)[0] + "/__kiek__.html")
            finally:
                os.remove(proef)
            m = re.search(r'<pre id="KIEK">(\d+)</pre>', r.stdout)
            hoogte = int(m.group(1)) if m else None

            r = chrome(os.path.join(werk, "p2"), f"--window-size={a.breed},{a.hoog}",
                       f"--screenshot={uit}", url)
    finally:
        srv.shutdown()

    if not os.path.isfile(uit):
        print(f"GEEN AFDRUK: {(r.stderr or '')[-400:]}")
        return 1
    print(f"kiek: {a.bladzij} op {a.breed}×{a.hoog} px -> {a.uit}"
          + (f" (de bladzij is {hoogte} px hoog" + (", dus de onderkant valt weg: kies --hoog "
             f"{hoogte}" if hoogte > a.hoog else ", dus hij staat er helemaal op") + ")"
             if hoogte else " (hoogte niet gemeten)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
