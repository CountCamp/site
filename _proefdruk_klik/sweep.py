#!/usr/bin/env python3
"""
Breedte-controle voor spoor "klik": staat hetzelfde patroon elders?

Zoekt op elke live bladzij álle koppen (h1-h4) die een link naar elders zijn,
en meet met elementFromPoint of een klik midden op de titeltekst die link ook
werkelijk raakt. Geen .cc-boek-aanname: dit vangt ook kaarten en lijsten met
een ander jasje.
"""
import json, subprocess, sys, pathlib, re, urllib.request

HIER = pathlib.Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

BLADZIJDEN = [
    ("homepage",   "https://countcamp.org/"),
    ("speelkist",  "https://countcamp.org/speeltjes/"),
    ("tabellen",   "https://countcamp.org/tabellen/"),
    ("broertjes",  "https://countcamp.org/oefenboeken/broertjes/"),
    ("diensten",   "https://countcamp.org/diensten.html"),
    ("over",       "https://countcamp.org/over.html"),
    ("archief",    "https://countcamp.org/archief/"),
]

MEETSCRIPT = r"""
<script>
window.addEventListener("load", function () {
  setTimeout(function () {
    var uit = [];
    document.querySelectorAll("h1, h2, h3, h4").forEach(function (h) {
      var echt = h.querySelector("a:not(.anchorjs-link):not(.anchor-section)");
      if (!echt) return;
      var href = echt.getAttribute("href") || "";
      if (href.charAt(0) === "#") return;          // deeplink, geen bladzij-link
      var r = echt.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) return;
      var el = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
      var doel = el && el.closest ? (el.closest("a") || el) : el;
      var naam = doel ? (doel.tagName.toLowerCase() +
        (typeof doel.className === "string" && doel.className.trim()
         ? "." + doel.className.trim().split(/\s+/).join(".") : "")) : "BUITEN BEELD";
      uit.push({
        titel: echt.textContent.trim().slice(0, 38),
        href: href,
        ankers: h.querySelectorAll("a.anchorjs-link, a.anchor-section").length,
        raakt: naam,
        goed: doel === echt
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


def meet(naam, url):
    html = urllib.request.urlopen(url).read().decode("utf-8", "replace")
    basis = url if url.endswith("/") else url.rsplit("/", 1)[0] + "/"
    html = re.sub(r"(<head[^>]*>)", r'\1\n<base href="%s">' % basis, html, count=1)
    html = html.replace("</body>", MEETSCRIPT + "\n</body>")
    pad = HIER / ("sweep_%s.html" % naam)
    pad.write_text(html, encoding="utf-8")
    r = subprocess.run(
        [CHROME, "--headless=new", "--disable-gpu", "--no-first-run",
         "--window-size=1400,4200", "--virtual-time-budget=9000",
         "--dump-dom", "file://%s" % pad],
        capture_output=True, text=True, timeout=180)
    m = re.search(r"@@(\[.*?\])@@", r.stdout, re.S)
    return json.loads(m.group(1)) if m else None


for naam, url in BLADZIJDEN:
    try:
        rijen = meet(naam, url)
    except Exception as e:
        print("\n=== %s === FOUT: %s" % (naam, e))
        continue
    print("\n=== %s (%s) ===" % (naam, url))
    if rijen is None:
        print("  geen uitslag")
        continue
    if not rijen:
        print("  geen koppen-die-link-zijn op deze bladzij")
        continue
    stuk = 0
    for r in rijen:
        vlag = "OK " if r["goed"] else "STUK"
        if not r["goed"]:
            stuk += 1
        print("  %s  %-40s ankers=%d  raakt %s" %
              (vlag, r["titel"], r["ankers"], r["raakt"]))
    print("  --> %d van de %d koppen stuk" % (stuk, len(rijen)))
