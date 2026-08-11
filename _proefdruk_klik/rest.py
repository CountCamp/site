#!/usr/bin/env python3
"""
Laatste controle: raakt de reparatie alleen de boekblokken?
De échte secties op dezelfde bladzij ("Online", "Bij het boek", ...) moeten hun
ankertje gewoon houden. En de titellink moet nog met Tab bereikbaar zijn.
"""
import json, subprocess, pathlib, re

HIER = pathlib.Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

MEETSCRIPT = r"""
<script>
window.addEventListener("load", function () {
  setTimeout(function () {
    var binnen = [], buiten = [];
    document.querySelectorAll("a.anchorjs-link").forEach(function (a) {
      var d = getComputedStyle(a).display;
      var kop = a.closest("h1,h2,h3,h4,h5,h6");
      var tekst = kop ? kop.textContent.replace(/\s+/g," ").trim().slice(0,30) : "?";
      (a.closest(".cc-boek") ? binnen : buiten).push(tekst + " [" + d + "]");
    });
    // is de titellink nog met Tab te bereiken en te focussen?
    var t = document.querySelector(".cc-boek h3 a:not(.anchorjs-link)");
    t.focus();
    var pre = document.createElement("pre");
    pre.textContent = "@@" + JSON.stringify({
      in_boekblok: binnen, in_echte_secties: buiten,
      titel_focusbaar: document.activeElement === t,
      titel_tabindex: t.tabIndex
    }) + "@@";
    document.body.appendChild(pre);
  }, 600);
});
</script>
"""

def draai(met_patch):
    html = (HIER / "live_oefenboeken.html").read_text(encoding="utf-8")
    html = re.sub(r"(<head[^>]*>)",
                  r'\1\n<base href="https://countcamp.org/oefenboeken/">', html, count=1)
    if met_patch:
        css = (HIER.parent / "styles.css").read_text(encoding="utf-8")
        html = html.replace("</head>", "<style>\n%s\n</style>\n</head>" % css, 1)
    html = html.replace("</body>", MEETSCRIPT + "\n</body>")
    pad = HIER / ("rest_%s.html" % ("na" if met_patch else "voor"))
    pad.write_text(html, encoding="utf-8")
    r = subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-first-run",
                        "--window-size=1400,4200", "--virtual-time-budget=9000",
                        "--dump-dom", "file://%s" % pad],
                       capture_output=True, text=True, timeout=180)
    m = re.search(r"@@(\{.*?\})@@", r.stdout, re.S)
    return json.loads(m.group(1)) if m else None

for wat, p in (("VOOR", False), ("NA", True)):
    d = draai(p)
    print("\n=== %s ===" % wat)
    print("  ankertjes in boekblokken (%d):" % len(d["in_boekblok"]))
    for x in d["in_boekblok"]:
        print("     ", x)
    print("  ankertjes in echte secties (%d):" % len(d["in_echte_secties"]))
    for x in d["in_echte_secties"]:
        print("     ", x)
    print("  titellink focusbaar met toetsenbord:", d["titel_focusbaar"],
          "(tabindex %d)" % d["titel_tabindex"])
