#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""taalbalk_browser_test.py — verschijnt de taalbalk bij wie hem moet zien, en
alleen daar? In een echte browser, niet in een leesbril op de HTML.

    python3 _tools/tests/taalbalk_browser_test.py [--site _site]

Vooraf nodig: een gebouwde site (gewoon `quarto render`, of na
`bash _tools/publiceer_en.sh`), en Google Chrome. Zonder Chrome kan deze toets
niet kijken en zegt hij dat (afloop 3) — niet gemeten is niet groen.

HOE. De site wordt via een eigen http-servertje op 127.0.0.1 aangeboden (zoals
een bezoeker hem krijgt: localStorage hoort bij een adres, en een map wordt zijn
index.html). Chrome draait zonder scherm met een ingestelde browsertaal (--lang,
--accept-lang) en ZONDER internet (--host-resolver-rules): de bezoekersteller kan
dus niets tellen. In een kopie van de bladzij zit een meetscriptje dat na het laden
opschrijft wat de bezoeker kreeg: welke talen de browser noemde (zodat de toets
zijn eigen uitgangspunt nakijkt), of de balk er staat, waarheen hij wijst, en het
contrast van de letters op de balk (WCAG 2.x, dezelfde formule als _wcag.py).

WAT HET EIST
  nl                  geen balk
  en-GB               balk, en hij wijst naar de Engelse tweeling (vijf soorten
                      bladzijden: thuis, diensten, cv met eigen knopje, de losse
                      tabellen/, solomon)
  en-GB,nl            geen balk (Nederlands staat erin, ook op de tweede plaats)
  en-GB, geen tweeling / Engelse bladzij   geen balk
  wegklikken          weg, en bij het volgende bezoek (zelfde profiel) niet terug
  localStorage dicht  de balk verschijnt toch, het kruisje werkt, geen fout
  contrast            letters >= 4,5:1, rand van het kruisje >= 3:1

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
import urllib.parse

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "_tools"))
from taalonderdelen import stuk  # noqa: E402
CHROME = os.environ.get("CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

goed = gezakt = 0


def zeg(r=""):
    print(r, flush=True)


def ok(wat):
    global goed
    goed += 1
    zeg(f"  ok    {wat}")


def zakt(wat, waarom=""):
    global gezakt
    gezakt += 1
    zeg(f"  ZAKT  {wat}" + (f" — {waarom}" if waarom else ""))


# Het meetscriptje. Wacht tot de bladzij geladen is, en daarna nog even (Quarto
# schuift de bladzij met een ResizeObserver mee), en schrijft dan een <pre id="PROEF">.
PROEF = r"""
<script>
(function () {
  var fouten = window.__FOUTEN__ || ["(foutvanger niet geladen)"];
  function rgb(s) {
    var m = String(s).match(/rgba?\(([^)]+)\)/);
    if (!m) return null;
    var p = m[1].split(/[,\s\/]+/).filter(function (x) { return x.length; }).map(parseFloat);
    return [p[0], p[1], p[2], p.length > 3 ? p[3] : 1];
  }
  function meet() {
    var balk = document.querySelector(".taalbalk");
    var uit = {talen: navigator.languages, taal: navigator.language, balk: !!balk, fouten: fouten};
    if (balk) {
      var a = balk.querySelector("a"), k = balk.querySelector("button");
      uit.tekst = a.textContent;
      uit.href = a.getAttribute("href");
      uit.href_vol = a.href;
      uit.lang = balk.getAttribute("lang");
      uit.ouder = balk.parentNode.id || balk.parentNode.tagName.toLowerCase();
      uit.kleur_letters = rgb(getComputedStyle(a).color);
      uit.kleur_balk = rgb(getComputedStyle(balk).backgroundColor);
      uit.kleur_knop = rgb(getComputedStyle(k).color);
      uit.rand_knop = rgb(getComputedStyle(k).borderTopColor);
      uit.knop_label = k.getAttribute("aria-label");
      var kop = document.getElementById("quarto-header");
      if (kop) {
        uit.kop_hoogte = kop.getBoundingClientRect().height;
        uit.body_padding = parseFloat(document.body.style.paddingTop || "0");
      }
      if (window.__KLIK__) {
        k.click();
        uit.na_klik_balk = !!document.querySelector(".taalbalk");
        try { uit.na_klik_opslag = window.localStorage.getItem("countcamp-taalbalk"); }
        catch (e) { uit.na_klik_opslag = "(niet te lezen: " + e.message + ")"; }
      }
    }
    var pre = document.createElement("pre");
    pre.id = "PROEF";
    pre.textContent = JSON.stringify(uit);
    document.body.appendChild(pre);
  }
  window.addEventListener("load", function () { setTimeout(meet, 700); });
})();
</script>
"""

KLIK = "<script>window.__KLIK__ = true;</script>\n"
# Als allereerste in <head>: vang elke JavaScript-fout, ook die van de balk zelf.
FOUTVANGER = ('<script>window.__FOUTEN__ = []; window.addEventListener("error", '
              'function (e) { window.__FOUTEN__.push({m: String(e.message), f: String(e.filename), '
              'l: e.lineno, s: String(e.error && e.error.stack || "")}); });</script>\n')
# Vóór alles in <head>: localStorage gooit een fout, zoals in een browser met
# opslag uitgezet (Safari privé, strenge instellingen).
OPSLAG_DICHT = ('<script>Object.defineProperty(window, "localStorage", '
                '{get: function () { throw new Error("opslag dicht"); }});</script>\n')

TELLER = re.compile(r'<script data-goatcounter="[^"]*"\s+async src="//gc\.zgo\.at/count\.js"></script>\s*')


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


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--site", default=os.path.join(REPO, "_site"))
    a = ap.parse_args()
    site = os.path.abspath(a.site)
    if not os.path.isfile(CHROME):
        zeg(f"KON NIET KIJKEN: Chrome staat niet op {CHROME} (zet CHROME=<pad>)")
        return 3
    if not os.path.isfile(os.path.join(site, "index.html")):
        zeg(f"KON NIET KIJKEN: {site} is geen gebouwde site")
        return 3

    werk = tempfile.mkdtemp(prefix="taalbalk_")
    kopie = os.path.join(werk, "site")
    shutil.copytree(site, kopie, copy_function=os.link)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Stil, directory=kopie))
    poort = server.server_address[1]
    threading.Thread(target=server.serve_forever, daemon=True).start()
    zeg(f"site {site}\n  aangeboden op http://127.0.0.1:{poort}/ — Chrome zonder internet, teller eruit in de proefkopieën")

    teller = [0]

    def bezoek(pad, talen, profiel=None, klik=False, opslag_dicht=False, vermink=None):
        """Laad een proefkopie van `pad` met deze browsertalen; geeft wat de bezoeker kreeg."""
        teller[0] += 1
        bron = os.path.join(kopie, pad)
        t = open(bron, encoding="utf-8").read()
        t = TELLER.sub("", t)
        vooraan = FOUTVANGER + (OPSLAG_DICHT if opslag_dicht else "")
        t, n = re.subn(r"(<head[^>]*>)", lambda m: m.group(1) + "\n" + vooraan, t, count=1)
        if n != 1:
            return {"_fout": f"geen <head> in {pad}"}
        t = t.replace("</body>", (KLIK if klik else "") + PROEF + "</body>", 1)
        if vermink:
            t2 = vermink(t)
            if t2 == t:
                return {"_fout": "de verminking veranderde niets — de toets is stuk"}
            t = t2
        stam, _ = os.path.splitext(pad)
        proef = f"{stam}__proef{teller[0]}.html"
        with open(os.path.join(kopie, proef), "w", encoding="utf-8") as f:
            f.write(t)
        profiel = profiel or os.path.join(werk, f"profiel{teller[0]}")
        r = subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-sandbox", "--no-first-run",
                            f"--user-data-dir={profiel}", f"--lang={talen.split(',')[0]}", f"--accept-lang={talen}",
                            "--host-resolver-rules=MAP * ~NOTFOUND , EXCLUDE 127.0.0.1",
                            "--virtual-time-budget=6000", "--dump-dom", f"http://127.0.0.1:{poort}/{proef}"],
                           capture_output=True, text=True, timeout=120)
        m = re.search(r'<pre id="PROEF">(.*?)</pre>', r.stdout, re.S)
        if not m:
            return {"_fout": "geen meting in de DOM: " + (r.stderr or "")[-300:]}
        u = json.loads(html.unescape(m.group(1)))
        u["_url"] = f"http://127.0.0.1:{poort}/{proef}"
        # Op welke regels van de proefkopie staat het script van de balk? Een fout
        # op die regels is van de balk; elders is hij van iemand anders (Quarto).
        b = t.find("<style>\n/* taalbalk:")
        e = t.find("</script>", b)
        u["_balk_regels"] = (t.count("\n", 0, b) + 1, t.count("\n", 0, e) + 1) if b >= 0 and e > b else None
        return u

    def fouten_van_balk(u):
        """Een fout is van de balk als de balk ergens in zijn aanroepketen staat.
        Niet alleen de regel van de fout zelf: een localStorage die een fout gooit,
        meldt die op de regel van de GOOIER, niet van wie hem aanriep (gemeten:
        vier fouten van Quarto's eigen scripts stonden allemaal op regel 4)."""
        r = u.get("_balk_regels")
        if not r:
            return []
        uit = []
        for f in (u.get("fouten") or []):
            if not isinstance(f, dict):
                continue
            regels = [f.get("l") or 0] if f.get("f") == u["_url"] else []
            regels += [int(x) for x in re.findall(re.escape(u["_url"]) + r":(\d+):\d+", f.get("s") or "")]
            if any(r[0] <= x <= r[1] for x in regels):
                uit.append(f)
        return uit

    def fouten_elders(u):
        eigen = fouten_van_balk(u)
        return [f for f in (u.get("fouten") or []) if f not in eigen]

    def zonder_index(url):
        return re.sub(r"index\.html$", "", url)

    def talen_kloppen(u, talen):
        verwacht = talen.split(",")
        return list(u.get("talen") or [])[:len(verwacht)] == verwacht

    def eis(naam, u, talen, balk, href=None):
        if "_fout" in u:
            zakt(naam, u["_fout"])
            return
        if not talen_kloppen(u, talen):
            zakt(naam, f"de browser noemde {u.get('talen')} in plaats van {talen} — de toets meet dan iets anders")
            return
        if fouten_van_balk(u):
            zakt(naam, f"JavaScript-fout in de balk: {fouten_van_balk(u)}")
            return
        if u["balk"] != balk:
            zakt(naam, f"balk {'wel' if u['balk'] else 'niet'} getoond, verwacht {'wel' if balk else 'niet'}")
            return
        # Vergelijk waar de link UITKOMT, niet hoe hij geschreven staat: op een echte
        # server zet Quarto (quarto-nav.js) elke link om naar een vol adres zonder
        # index.html. Gemeten: "en/index.html" wordt "http://127.0.0.1:<poort>/en/".
        if balk and href is not None:
            verwacht = zonder_index(urllib.parse.urljoin(u["_url"], href))
            if zonder_index(u.get("href_vol") or "") != verwacht:
                zakt(naam, f"de balk wijst naar {u.get('href_vol')!r}, verwacht {verwacht!r}")
                return
        elders = f"; {len(fouten_elders(u))} fout(en) van andere scripts" if fouten_elders(u) else ""
        ok(f"{naam}: talen {u['talen']}, balk {'getoond → ' + u['href_vol'] if balk else 'niet getoond'}{elders}")

    try:
        zeg()
        zeg("wie ziet de balk:")
        eis("index.html, browser nl", bezoek("index.html", "nl"), "nl", False)
        eis("index.html, browser nl-BE", bezoek("index.html", "nl-BE"), "nl-BE", False)
        u = bezoek("index.html", "en-GB")
        eis("index.html, browser en-GB", u, "en-GB", True, "en/index.html")
        eis("diensten.html, browser en-GB", bezoek("diensten.html", "en-GB"), "en-GB", True, "en/services.html")
        eis("cv.html (eigen knopje), browser en-GB", bezoek("cv.html", "en-GB"), "en-GB", True,
            "https://countcamp.org/cv-en.html")
        eis("tabellen/ (losse bladzij), browser en-GB", bezoek("tabellen/index.html", "en-GB"), "en-GB", True,
            "../tables/index.html")
        eis("speeltjes/solomon.html, browser en-GB", bezoek("speeltjes/solomon.html", "en-GB"), "en-GB", True,
            "solomon-en.html")
        eis("index.html, browser en-GB,nl", bezoek("index.html", "en-GB,nl"), "en-GB,nl", False)
        eis("index.html, browser de-DE,fr", bezoek("index.html", "de-DE,fr"), "de-DE,fr", True, "en/index.html")
        eis("speeltjes/index.html (geen tweeling), browser en-GB", bezoek("speeltjes/index.html", "en-GB"), "en-GB", False)
        eis("archief/index.html (geen tweeling), browser en-GB", bezoek("archief/index.html", "en-GB"), "en-GB", False)
        eis("en/index.html (Engels), browser en-GB", bezoek("en/index.html", "en-GB"), "en-GB", False)

        zeg()
        zeg("hoe hij eruitziet (index.html, en-GB):")
        if u.get("balk"):
            vorm = (u.get("tekst") == "This page is also in English →" and u.get("lang") == "en"
                    and u.get("knop_label") == "Close")
            if vorm:
                ok(f"tekst {u['tekst']!r}, lang=\"en\", kruisje met aria-label \"Close\"")
            else:
                zakt("vorm van de balk", f"tekst {u.get('tekst')!r}, lang {u.get('lang')!r}, label {u.get('knop_label')!r}")
            c1 = contrast(u["kleur_letters"], u["kleur_balk"])
            c2 = contrast(u["kleur_knop"], u["kleur_balk"])
            c3 = contrast(u["rand_knop"], u["kleur_balk"])
            regel = (f"letters {c1:.2f}:1, kruisje {c2:.2f}:1, rand van het kruisje {c3:.2f}:1 "
                     f"(letters rgb{tuple(u['kleur_letters'][:3])} op rgb{tuple(u['kleur_balk'][:3])})")
            if c1 >= 4.5 and c2 >= 4.5 and c3 >= 3:
                ok("contrast WCAG AA: " + regel)
            else:
                zakt("contrast onder WCAG AA", regel)
            if u.get("ouder") == "quarto-header" and abs(u.get("kop_hoogte", 0) - u.get("body_padding", -1)) < 1:
                ok(f"de balk staat in de vaste kop en de bladzij schuift mee "
                   f"(kop {u['kop_hoogte']:.0f}px, padding-top {u['body_padding']:.0f}px): niets eronder verdwijnt")
            else:
                zakt("de bladzij schuift niet mee met de balk",
                     f"ouder {u.get('ouder')}, kop {u.get('kop_hoogte')}, padding {u.get('body_padding')}")
        else:
            zakt("geen balk op index.html bij en-GB; kon de vorm niet meten")

        zeg()
        zeg("wegklikken:")
        profiel = os.path.join(werk, "profiel_blijvend")
        u1 = bezoek("over.html", "en-GB", profiel=profiel, klik=True)
        if u1.get("balk") and u1.get("na_klik_balk") is False and u1.get("na_klik_opslag") == "weg":
            ok("over.html: balk getoond, na het kruisje weg, en onthouden (localStorage = \"weg\")")
        else:
            zakt("wegklikken op over.html", json.dumps({k: u1.get(k) for k in ("balk", "na_klik_balk", "na_klik_opslag", "_fout")}))
        u2 = bezoek("gebruik.html", "en-GB", profiel=profiel)
        eis("volgend bezoek met hetzelfde profiel (gebruik.html): blijft weg", u2, "en-GB", False)

        zeg()
        zeg("localStorage dicht (de bladzij moet het zonder doen):")
        for pad in ("diensten.html", "tabellen/index.html"):
            u3 = bezoek(pad, "en-GB", klik=True, opslag_dicht=True)
            dicht = "opslag dicht" in str(u3.get("na_klik_opslag"))
            if u3.get("balk") and u3.get("na_klik_balk") is False and dicht and not fouten_van_balk(u3):
                ok(f"{pad}: balk getoond, kruisje werkt, geen fout uit de balk (opslag: {u3.get('na_klik_opslag')})")
            else:
                zakt(f"{pad} met localStorage dicht",
                     json.dumps({k: u3.get(k) for k in ("balk", "na_klik_balk", "na_klik_opslag", "_fout")})
                     + f" fouten van de balk: {fouten_van_balk(u3)}")
            elders = fouten_elders(u3)
            if elders:
                bron = sorted({re.sub(r"^.*/", "", x) for f in elders
                               for x in re.findall(r"\((\S+?):\d+:\d+\)", f.get("s") or "")[1:2]})
                zeg(f"          ({len(elders)} fout(en) niet van de balk maar van andere scripts op de bladzij, "
                    f"bv. {bron or elders[0]['m']})")
        # De toets moet ook kunnen zakken: dezelfde balk ZONDER try/catch om
        # localStorage moet een fout opleveren die hij aan de balk toeschrijft.
        oud = 'try { if (window.localStorage.getItem(SLEUTEL) === "weg") return; } catch (e) {}'
        u4 = bezoek("tabellen/index.html", "en-GB", opslag_dicht=True,
                    vermink=lambda t: t.replace(oud, 'if (window.localStorage.getItem(SLEUTEL) === "weg") return;', 1))
        if fouten_van_balk(u4):
            ok(f"verminking: de balk zonder try/catch geeft een fout en de toets ziet dat "
               f"({fouten_van_balk(u4)[0]['m']}, balk {'wel' if u4.get('balk') else 'niet'} getoond)")
        else:
            zakt("verminking: de balk zonder try/catch hoort een fout van de balk te geven",
                 json.dumps({k: u4.get(k) for k in ("balk", "fouten", "_fout")})[:300])
    finally:
        server.shutdown()
        shutil.rmtree(werk, ignore_errors=True)

    zeg()
    zeg(f"{goed + gezakt} zaken getoetst, " + ("alles groen." if not gezakt else f"{gezakt} GEZAKT."))
    return 1 if gezakt else 0


if __name__ == "__main__":
    sys.exit(main())
