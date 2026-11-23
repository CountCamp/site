#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""taallabel_browser_test.py — landt een klik op het EN-label in het Engels, en
een klik op de rest van de rij nog in het Nederlands? In een echte browser.

    python3 _tools/tests/taallabel_browser_test.py [--site _site] [--foto <map>]

Vooraf nodig: een gebouwde site (`quarto render`) en Google Chrome. Zonder Chrome
of zonder plank met een label kan deze toets niet kijken en zegt hij dat
(afloop 3): niet gemeten is niet groen.

WAAROM IN EEN BROWSER. Het label is de tweede <a> in de kop van een boek, en de
titellink spant met een onzichtbare laag over de hele rij (styles.css, "de hele
regel/kaart klikbaar"). Op 11-8-2026 ving zo'n tweede <a> elke klik op de rij,
en de rij bleef muisdood terwijl de link zelf werkte. In de HTML is dat niet te
zien, alleen in wat de browser op een punt van het scherm aanwijst
(document.elementFromPoint).

WAT HET EIST, per boek met een label, op 390 en 1200 pixels breed, in de vorm rug
en de vorm kaart:
  midden op het label       het label (naar het Engelse boek)
  net naast het rechthoekje  ook het label: het klikvlak is groter dan wat je ziet
  midden in de tekst        de titellink (naar het Nederlandse boek)
  midden op de titel        de titellink
  geen tweede merk          het ::before-merk van de Engelse plank staat er niet bij
  binnen de kaart           het label steekt niet buiten zijn boek uit
  contrast                  letters >= 4,5:1 tegen het vlak (WCAG 2.x, kleine letters)
En op een boek zonder label wijst het midden van de tekst nog naar de titel.

--foto <map> zet er schermafdrukken bij (390 pixels, beide vormen), voor een
testlezer.

Afloop: 0 groen, 1 gezakt, 3 kon niet kijken.
"""
from __future__ import annotations

import argparse
import functools
import html
import http.server
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
PLANK = "oefenboeken/index.html"
ZONDER = re.compile(r' ?<a class="cc-taal" [^>]*>EN</a>')
TELLER = re.compile(r'<script data-goatcounter="[^"]*"\s+async src="//gc\.zgo\.at/count\.js"></script>\s*')

PROEF = r"""
<script>
(function () {
  function kleur(s) { var m = s.match(/[\d.]+/g); return m ? m.slice(0, 3).map(Number) : null; }
  function aan(x, y) { var e = document.elementFromPoint(x, y); var a = e && e.closest("a"); return a ? a.getAttribute("href").replace(location.origin, "") : null; }
  function meet() {
    var uit = {breedte: window.innerWidth, vorm: document.documentElement.getAttribute("data-vorm") || "rug", boeken: []};
    document.querySelectorAll("section.cc-boek").forEach(function (s) {
      var titel = s.querySelector("h3 > a:not(.cc-taal):not(.anchorjs-link)");
      if (!titel) return;
      var lab = s.querySelector("h3 > a.cc-taal");
      s.scrollIntoView({block: "center"});
      var b = {titel: titel.getAttribute("href").replace(location.origin, ""),
               label: lab ? lab.getAttribute("href").replace(location.origin, "") : null};
      var p = s.querySelector("p");
      if (p) { var r = p.getBoundingClientRect(); b.tekst = aan(r.left + r.width / 2, r.top + Math.min(r.height / 2, 10)); }
      var t = titel.getBoundingClientRect();
      b.op_titel = aan(t.left + Math.min(t.width / 2, 40), t.top + t.height / 2);
      if (lab) {
        var l = lab.getBoundingClientRect(), k = s.getBoundingClientRect(), cs = getComputedStyle(lab);
        b.maat = [Math.round(l.width), Math.round(l.height)];
        b.midden = aan(l.left + l.width / 2, l.top + l.height / 2);
        b.naast = aan(l.left - 3, l.top + l.height / 2);
        b.boven = aan(l.left + l.width / 2, l.top - 3);
        b.merk = getComputedStyle(lab, "::before").content;
        b.binnen = l.left >= k.left && l.right <= k.right + 0.5;
        var h = lab.parentElement; b.kop_past = h.scrollWidth <= h.clientWidth + 1;
        b.letter = kleur(cs.color); b.vlak = kleur(cs.backgroundColor);
        b.tekst_label = lab.textContent;
      }
      uit.boeken.push(b);
    });
    window.scrollTo(0, 0);
    // Breder dan het scherm? Ter informatie, met het breedste element erbij: dit
    // hoeft niet aan het label te liggen.
    var d = document.documentElement; uit.overloop = d.scrollWidth - d.clientWidth;
    if (uit.overloop > 0) {
      var w = null; document.querySelectorAll("main *").forEach(function (e) {
        var r = e.getBoundingClientRect(); if (r.right > d.clientWidth + 1 && (!w || r.right > w.r))
          w = {r: Math.round(r.right), e: e.tagName.toLowerCase() + (e.className ? "." + String(e.className).split(" ").join(".") : "")}; });
      uit.breedste = w;
    }
    // In een raampje (390 pixels, zie RAAM) gaat de meting naar de bladzij eromheen.
    var doc = window.parent !== window ? window.parent.document : document;
    var pre = doc.createElement("pre"); pre.id = "PROEF"; pre.textContent = JSON.stringify(uit);
    doc.body.appendChild(pre);
  }
  window.addEventListener("load", function () { setTimeout(meet, 500); });
})();
</script>
"""

# HEADLESS CHROME GAAT NIET SMALLER DAN 500 PIXELS: --window-size=390,900 gaf een
# venster van 500 (gemeten 23-11-2026; de eerste versie van deze toets zag dat aan
# window.innerWidth en zakte). Daarom staat de plank voor de smalle maat in een raampje
# (iframe) van precies die breedte: daarbinnen is de bladzij 390 pixels breed, en
# gelden de media-queries van een telefoon.
RAAM = ('<!doctype html><html><head><meta charset="utf-8"><style>body{{margin:0}}'
        'iframe{{border:0;display:block;width:{b}px;height:{h}px}}</style></head>'
        '<body><iframe src="{src}"></iframe></body></html>')

# Voor de foto: naar het eerste boek met een label, met en zonder label op hetzelfde boek.
NAAR = r"""
<script>
window.addEventListener("load", function () { setTimeout(function () {
  // het hoeveelste boek: Quarto maakt van een href een vol adres, dus op href zoeken mist
  var s = document.querySelectorAll("section.cc-boek")[__NR__]; if (!s) return;
  window.scrollTo(0, s.getBoundingClientRect().top + window.scrollY - 70);
}, 400); });
</script>
"""


def lum(c):
    s = 0.0
    for v, g in zip(c[:3], (0.2126, 0.7152, 0.0722)):
        v = v / 255
        v = v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
        s += g * v
    return s


def contrast(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


class Stil(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--site", default=os.path.join(REPO, "_site"))
    ap.add_argument("--foto", help="map voor schermafdrukken op 390 pixels")
    a = ap.parse_args()
    site = os.path.abspath(a.site)
    if not os.path.isfile(CHROME):
        print(f"KON NIET KIJKEN: Chrome staat niet op {CHROME} (zet CHROME=<pad>)")
        return 3
    bron = os.path.join(site, PLANK)
    if not os.path.isfile(bron):
        print(f"KON NIET KIJKEN: {bron} bestaat niet -- eerst quarto render")
        return 3
    plank = TELLER.sub("", open(bron, encoding="utf-8").read())
    if 'class="cc-taal"' not in plank:
        print(f"KON NIET KIJKEN: geen enkel EN-label op {PLANK} -- draaide _tools/taallabel.py?")
        return 3

    werk = tempfile.mkdtemp(prefix="taallabel_browser_")
    kopie = os.path.join(werk, "site")
    shutil.copytree(site, kopie, copy_function=os.link)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Stil, directory=kopie))
    poort = server.server_address[1]
    threading.Thread(target=server.serve_forever, daemon=True).start()
    n = [0]

    def chrome(extra: str, breedte: int, vorm: str, *opties: str, hoogte: int = 900):
        n[0] += 1
        proef = f"oefenboeken/index__proef{n[0]}.html"
        with open(os.path.join(kopie, proef), "w", encoding="utf-8") as f:
            f.write(plank.replace("</body>", extra + "</body>", 1))
        adres = f"/{proef}?vorm={vorm}"
        venster = breedte
        if breedte < 500:
            raam = f"oefenboeken/raam{n[0]}.html"
            with open(os.path.join(kopie, raam), "w", encoding="utf-8") as f:
                f.write(RAAM.format(b=breedte, h=hoogte, src=adres))
            adres, venster = f"/{raam}", 500
        return subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-sandbox", "--no-first-run",
                               f"--user-data-dir={os.path.join(werk, f'profiel{n[0]}')}", "--hide-scrollbars",
                               "--host-resolver-rules=MAP * ~NOTFOUND , EXCLUDE 127.0.0.1",
                               f"--window-size={venster},{hoogte}", "--virtual-time-budget=6000", *opties,
                               f"http://127.0.0.1:{poort}{adres}"],
                              capture_output=True, text=True, timeout=120)

    goed = gezakt = 0

    def eis(ok, wat):
        nonlocal goed, gezakt
        goed += bool(ok)
        gezakt += not ok
        print(f"  {'ok  ' if ok else 'ZAKT'}  {wat}")

    try:
        for breedte in (390, 1200):
            for vorm in ("rug", "kaart"):
                r = chrome(PROEF, breedte, vorm, "--dump-dom")
                m = re.search(r'<pre id="PROEF">(.*?)</pre>', r.stdout, re.S)
                if not m:
                    print(f"KON NIET KIJKEN: geen meting op {breedte} px, {vorm}: {(r.stderr or '')[-300:]}")
                    return 3
                u = json.loads(html.unescape(m.group(1)))
                print(f"\n{breedte} pixels, vorm {u['vorm']} (gevraagd: {vorm}), {len(u['boeken'])} boeken met een link")
                eis(u["vorm"] == vorm and u["breedte"] == breedte, f"de browser gaf {u['breedte']} px en vorm {u['vorm']}")
                # Dezelfde plank zonder label, om te zien of het label de bladzij breder maakt.
                oud = plank
                plank = ZONDER.sub("", plank)
                r0 = chrome(PROEF, breedte, vorm, "--dump-dom")
                plank = oud
                m0 = re.search(r'<pre id="PROEF">(.*?)</pre>', r0.stdout, re.S)
                u0 = json.loads(html.unescape(m0.group(1))) if m0 else {}
                eis(m0 and u["overloop"] <= u0["overloop"],
                    f"het label maakt de bladzij niet breder: {u['overloop']} px te breed met, "
                    f"{u0.get('overloop')} px zonder" + (f" (breedste zonder label: {u0.get('breedste')})"
                                                         if u0.get("overloop") else ""))
                met = [b for b in u["boeken"] if b["label"]]
                eis(met, f"{len(met)} boek(en) met een label")
                for b in met:
                    naam = b["titel"]
                    eis(b["midden"] == b["label"], f"{naam}: midden op het label -> {b['midden']}")
                    eis(b["naast"] == b["label"] and b["boven"] == b["label"],
                        f"{naam}: 3 px naast en boven het rechthoekje ({b['maat'][0]} x {b['maat'][1]} px) -> "
                        f"{b['naast']} / {b['boven']}")
                    eis(b.get("tekst") == naam, f"{naam}: midden in de tekst -> {b.get('tekst')}")
                    eis(b["op_titel"] == naam, f"{naam}: op de titel -> {b['op_titel']}")
                    eis(b["merk"] in ("none", "normal"), f"{naam}: geen tweede merk ervoor (::before {b['merk']})")
                    eis(b["binnen"], f"{naam}: het label blijft binnen zijn boek")
                    eis(b["kop_past"], f"{naam}: de kop met het label past in zijn breedte")
                    eis(b["tekst_label"] == "EN", f"{naam}: er staat {b['tekst_label']!r}")
                    c = contrast(b["letter"], b["vlak"]) if b["letter"] and b["vlak"] else 0
                    eis(c >= 4.5, f"{naam}: contrast {c:.1f}:1 (letter {b['letter']}, vlak {b['vlak']})")
                zonder = [b for b in u["boeken"] if not b["label"] and "tekst" in b]
                fout = [b["titel"] for b in zonder if b["tekst"] != b["titel"]]
                eis(zonder and not fout, f"{len(zonder)} boek(en) zonder label: de tekst wijst naar de eigen titel"
                    + (f" -- NIET bij {fout}" if fout else ""))
        if a.foto:
            os.makedirs(a.foto, exist_ok=True)
            boeken = re.findall(r'<section\b[^>]*\bcc-boek\b[^>]*>\s*<h3[^\n]*', plank)
            nr = next(i for i, b in enumerate(boeken) if 'class="cc-taal"' in b)
            naar = NAAR.replace("__NR__", str(nr))
            for vorm in ("rug", "kaart"):
                for soort, tekst in (("met", plank), ("zonder", ZONDER.sub("", plank))):
                    pad = os.path.abspath(os.path.join(a.foto, f"plank_390_{vorm}_{soort}_label.png"))
                    oud = plank
                    plank = tekst
                    chrome(naar, 390, vorm, f"--screenshot={pad}", "--force-device-scale-factor=2")
                    plank = oud
                    print(f"  foto: {pad}" + ("" if os.path.isfile(pad) else "  (NIET gemaakt)"))
    finally:
        server.shutdown()
        shutil.rmtree(werk, ignore_errors=True)

    print(f"\n{goed} goed, {gezakt} gezakt")
    return 1 if gezakt else 0


if __name__ == "__main__":
    sys.exit(main())
