#!/usr/bin/env python3
"""
Meetbank voor spoor "klik".

Waarom zo: de Chrome-extensie gaf geen toestemming, dus meten we met
Chrome-zonder-venster (--headless --dump-dom). Dump-dom kan geen JS in een
externe bladzij injecteren, dus we zetten de LIVE bladzij lokaal neer met een
<base>-tag: alle CSS/JS komt nog steeds van countcamp.org, alleen het
meet-scriptje is van ons. De live styles.css is byte-voor-byte gelijk aan de
lokale (nagemeten), dus wat we hier meten is wat Ben in de trein zag.

Per rij meten we document.elementFromPoint op:
  - het midden van de TITELTEKST  (waar Ben klikt)
  - het midden van de hele RIJ/KAART (de "hele regel klikbaar"-belofte)
en we kijken of dat de echte titellink is.
"""
import json, subprocess, sys, pathlib, re

HIER = pathlib.Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

MEETSCRIPT = r"""
<script>
window.addEventListener("load", function () {
  setTimeout(function () {
    var uit = [];
    document.querySelectorAll(".cc-boek").forEach(function (boek, i) {
      var h3 = boek.querySelector("h3");
      var echt = h3 ? h3.querySelector("a:not(.anchorjs-link)") : null;
      if (!echt) { uit.push({rij: i, fout: "geen titellink gevonden"}); return; }

      function raak(x, y) {
        var el = document.elementFromPoint(x, y);
        if (!el) return {noem: "BUITEN BEELD", isTitel: false};
        // de klik landt op het element; ga omhoog tot de dichtstbijzijnde <a>
        var a = el.closest ? el.closest("a") : null;
        var doel = a || el;
        var naam = doel.tagName.toLowerCase()
                 + (doel.className && typeof doel.className === "string"
                    ? "." + doel.className.trim().split(/\s+/).join(".") : "");
        return {
          noem: naam,
          href: doel.getAttribute ? (doel.getAttribute("href") || "") : "",
          isTitel: doel === echt
        };
      }

      var rt = echt.getBoundingClientRect();
      var rb = boek.getBoundingClientRect();
      // hoe groot is het ankertje zélf, en hoe groot is zijn ::after-laag?
      var ank = h3.querySelector("a.anchorjs-link");
      var ankmaat = "-";
      if (ank) {
        var ra = ank.getBoundingClientRect();
        var na = getComputedStyle(ank, "::after");
        ankmaat = Math.round(ra.width) + "x" + Math.round(ra.height)
                + " ::after content=" + na.content
                + " pos=" + na.position;
      }
      uit.push({
        anker: ankmaat,
        rij_breed: Math.round(rb.width) + "x" + Math.round(rb.height),
        rij: i,
        titel: echt.textContent.trim().slice(0, 42),
        href: echt.getAttribute("href"),
        ankers_in_h3: h3.querySelectorAll("a.anchorjs-link").length,
        anker_zichtbaar: h3.querySelector("a.anchorjs-link")
          ? getComputedStyle(h3.querySelector("a.anchorjs-link")).display : "-",
        op_titel: raak(rt.left + rt.width / 2, rt.top + rt.height / 2),
        op_rij:   raak(rb.left + rb.width / 2, rb.top + rb.height / 2)
      });
    });
    var pre = document.createElement("pre");
    pre.id = "MEETUITSLAG";
    pre.textContent = "@@" + JSON.stringify(uit) + "@@";
    document.body.appendChild(pre);
  }, 600);
});
</script>
"""


def bouw(bronbestand, basis, extra_css, doelbestand):
    html = (HIER / bronbestand).read_text(encoding="utf-8")
    # <base> moet zo vroeg mogelijk, vóór de eerste relatieve verwijzing
    html = re.sub(r"(<head[^>]*>)", r'\1\n<base href="%s">' % basis, html, count=1)
    if extra_css:
        # helemaal achteraan in de <head>: zo overstemt de LOKALE styles.css de
        # live versie regel voor regel, en meten we het bestand dat ik echt heb
        # aangepast — geen overgetikt fragment
        html = html.replace("</head>", "<style>\n%s\n</style>\n</head>" % extra_css, 1)
    html = html.replace("</body>", MEETSCRIPT + "\n</body>")
    (HIER / doelbestand).write_text(html, encoding="utf-8")
    return HIER / doelbestand


def meet(pad, vorm):
    url = "file://%s?vorm=%s" % (pad, vorm)
    r = subprocess.run(
        [CHROME, "--headless=new", "--disable-gpu", "--no-first-run",
         "--allow-file-access-from-files",
         "--window-size=1400,4200", "--virtual-time-budget=9000",
         "--dump-dom", url],
        capture_output=True, text=True, timeout=180)
    m = re.search(r"@@(\[.*?\])@@", r.stdout, re.S)
    if not m:
        print("GEEN UITSLAG voor", url, file=sys.stderr)
        print(r.stderr[-1500:], file=sys.stderr)
        return None
    return json.loads(m.group(1))


def toon(kop, rijen):
    print("\n=== %s ===" % kop)
    if not rijen:
        print("  (niets gemeten)")
        return 0, 0
    goed_t = goed_r = 0
    for r in rijen:
        if "fout" in r:
            print("  rij %d: %s" % (r["rij"], r["fout"]))
            continue
        t, b = r["op_titel"], r["op_rij"]
        goed_t += 1 if t["isTitel"] else 0
        goed_r += 1 if b["isTitel"] else 0
        print("  rij %d  %-44s ankers=%d(%s)" %
              (r["rij"], r["titel"], r["ankers_in_h3"], r["anker_zichtbaar"]))
        print("         rij is %s px; ankertje %s" % (r["rij_breed"], r["anker"]))
        print("         klik op titel -> %-34s %s" %
              (t["noem"], "TITEL ✓" if t["isTitel"] else "MIS ✗"))
        print("         klik op rij   -> %-34s %s" %
              (b["noem"], "TITEL ✓" if b["isTitel"] else "MIS ✗"))
    print("  --> titel goed: %d/%d   rij goed: %d/%d"
          % (goed_t, len(rijen), goed_r, len(rijen)))
    return goed_t, len(rijen)


if __name__ == "__main__":
    # met "na" leggen we de LOKALE styles.css over de live bladzij heen
    label = sys.argv[1] if len(sys.argv) > 1 else "meting"
    extra = ((HIER.parent / "styles.css").read_text(encoding="utf-8")
             if label.lower().startswith("na") else "")
    for bron, basis, naam in [
        ("live_oefenboeken.html", "https://countcamp.org/oefenboeken/", "oefenboeken"),
        # de live boekpagina heeft de plank nog niet; deze komt uit de lokale
        # _site-render van d815657, met de CSS/JS nog steeds van countcamp.org
        ("live_boekpagina.html",  "https://countcamp.org/manuscript/",  "boekpagina(lokale render)"),
    ]:
        pad = bouw(bron, basis, extra, "meet_%s.html" % naam)
        for vorm in ("rug", "kaart"):
            toon("%s — %s — vorm %s" % (label, naam, vorm), meet(pad, vorm))
