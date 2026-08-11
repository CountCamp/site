#!/usr/bin/env python3
"""
Neveneffect-controle: het ankertje was een flex-item in de h3, ná de chip.
Verdwijnt het, dan schuift de chip op. Hoeveel? Meet de afstand tussen de
rechterrand van de chip en de rechterrand van de kop, voor en na.
"""
import json, subprocess, sys, pathlib, re

HIER = pathlib.Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

MEETSCRIPT = r"""
<script>
window.addEventListener("load", function () {
  setTimeout(function () {
    var uit = [];
    document.querySelectorAll(".cc-boek h3").forEach(function (h, i) {
      var chip = h.querySelector(".cc-chip");
      if (!chip) return;
      var rh = h.getBoundingClientRect(), rc = chip.getBoundingClientRect();
      uit.push({rij: i, gat_rechts: Math.round((rh.right - rc.right) * 10) / 10,
                kop_hoog: Math.round(rh.height * 10) / 10});
    });
    var pre = document.createElement("pre");
    pre.textContent = "@@" + JSON.stringify(uit) + "@@";
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
    pad = HIER / ("chip_%s.html" % ("na" if met_patch else "voor"))
    pad.write_text(html, encoding="utf-8")
    r = subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-first-run",
                        "--window-size=1400,4200", "--virtual-time-budget=9000",
                        "--dump-dom", "file://%s" % pad],
                       capture_output=True, text=True, timeout=180)
    m = re.search(r"@@(\[.*?\])@@", r.stdout, re.S)
    return json.loads(m.group(1)) if m else []

voor, na = draai(False), draai(True)
print("rij  gat chip->rand VOOR   NA    verschil   kophoogte voor/na")
for a, b in zip(voor, na):
    print("%3d %14.1f %7.1f %9.1f      %.1f / %.1f"
          % (a["rij"], a["gat_rechts"], b["gat_rechts"],
             b["gat_rechts"] - a["gat_rechts"], a["kop_hoog"], b["kop_hoog"]))
