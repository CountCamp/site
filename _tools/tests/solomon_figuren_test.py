#!/usr/bin/env python3
"""Toetst de figuren van speeltjes/solomon.html bij extreme getallen: staat er tekst op tekst, tekst op een balk
of op de nullijn, tekst buiten de figuur, of een gestippelde lijn?

Waarom. Ben, 8-10-2026, met de schuifjes op H/M = -1: de y-as hield op bij de onderkant van de balk, en het getal
"-1" stond óp het etiket "H/M" eronder; geen van beide was te lezen. Een schermafdruk laat zoiets zien als je
toevallig die stand kiest. Dit meet het bij elke stand uit de lijst, en meet het opnieuw bij elke wijziging.

Hoe. Een kopie van de bladzij met een meetscript erin gaat open in headless Chrome (--dump-dom). Het meetscript
neemt van elke zichtbare tekst in een figuur het vak op het scherm (getBoundingClientRect) en legt het naast de
andere teksten, de balken en de lijnen. Twee soorten runs:
  1. de bladzij zoals hij is: de trap op het speelbord bij elke schuifstand uit SCHUIFSTANDEN, en daarna alle
     figuren van de ladder (het zwaard voor en na het klieven);
  2. de bladzij met andere getypte getallen (GETALLEN_PROEF), waarin stukjes negatief zijn: de trappen in de
     ladder en de twee regressieplaatjes tekenen met dezelfde functie als het speelbord. Het zwaard en de
     verschil-in-verschil-balken doen in deze run niet mee: die tekenen alleen de getypte getallen, en
     solomon_getallen_test.py eist dat de stukjes daarvan positief zijn.

Wat het niet ziet: kleur en contrast (licht en donker), en of een figuur iets zegt dat klopt. Daarvoor zijn de
schermafdrukken en solomon_getallen_test.py.

Afloopcodes volgens huisafspraak: 0 schoon, 1 er staat iets over elkaar, 3 kon niet kijken.
"""
import html
import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HIER = Path(__file__).resolve().parent
PAGINA = HIER.parent.parent / "speeltjes" / "solomon.html"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# De schuifjes: voormeting I, voormeting II, nameting I, II, III, IV. De stukjes erachter staan erbij; ze volgen
# uit de zes getallen (H/M = nameting IV - geleende voormeting, X = nameting III - nameting IV, enzovoort) en
# worden hieronder in stukjes() nagerekend, zodat een verkeerd uitgerekend geval de toets zelf laat zakken.
SCHUIFSTANDEN = [
    ("de ladder",                    [50, 50, 65, 53, 60, 52], {"HM": 2, "X": 8, "T": 1, "S": 4}),
    ("H/M negatief (Bens geval)",    [50, 50, 62, 50, 57, 49], {"HM": -1, "X": 8, "T": 1, "S": 4}),
    ("X negatief",                   [50, 50, 49, 53, 44, 52], {"HM": 2, "X": -8, "T": 1, "S": 4}),
    ("T negatief",                   [50, 50, 61, 49, 60, 52], {"HM": 2, "X": 8, "T": -3, "S": 4}),
    ("S negatief",                   [50, 50, 57, 53, 60, 52], {"HM": 2, "X": 8, "T": 1, "S": -4}),
    ("H/M en X negatief",            [50, 50, 42, 46, 37, 45], {"HM": -5, "X": -8, "T": 1, "S": 4}),
    ("alle vier negatief",           [50, 50, 35, 47, 40, 48], {"HM": -2, "X": -8, "T": -1, "S": -4}),
    ("alles nul",                    [50, 50, 50, 50, 50, 50], {"HM": 0, "X": 0, "T": 0, "S": 0}),
    ("grootste positieve",           [0, 0, 100, 50, 50, 25],  {"HM": 25, "X": 25, "T": 25, "S": 25}),
    ("grootste negatieve",           [100, 100, 0, 50, 50, 75], {"HM": -25, "X": -25, "T": -25, "S": -25}),
    ("wijdste bereik",               [0, 100, 100, 0, 0, 100], {"HM": 50, "X": -100, "T": -150, "S": 300}),
    # een stijgende balk die vlak onder nul eindigt: zijn getal erboven zou op de nullijn vallen
    ("vlak onder nul",               [50, 50, 98, 41, 47, 40], {"HM": -10, "X": 7, "T": 1, "S": 50}),
]
# andere getypte getallen voor run 2 (zelfde volgorde als GETALLEN in de bladzij)
SLEUTELS = ["voorI", "voorII", "naI", "naII", "naIII", "naIV"]
GETALLEN_PROEF = ["H/M negatief (Bens geval)", "H/M en X negatief", "grootste negatieve", "wijdste bereik"]


def stukjes(z):
    voorI, voorII, naI, naII, naIII, naIV = z
    leen = (voorI + voorII) / 2
    HM = naIV - leen
    X = naIII - naIV
    T = (naII - voorII) - HM
    S = (naI - voorI) - HM - X - T
    return {"HM": HM, "X": X, "T": T, "S": S}


MEETSCRIPT = r"""
<style>.zwaard *{transition:none!important}</style>
<script>
(function(){
  var STANDEN = %(standen)s, LADDER = %(ladder)s, ZONDER = %(zonder)s;
  var uit = {metingen: [], fouten: []};
  function zichtbaar(e){ return e.checkVisibility({opacityProperty:true, visibilityProperty:true}); }
  function vak(e){ var r = e.getBoundingClientRect(); return {l:r.left, r:r.right, t:r.top, b:r.bottom}; }
  // een tekstvak is het hele letterkorps; de cijfers zelf vullen het middenstuk. Tegen tekst meten we
  // bijna het hele korps (ook rakelings is te krap), tegen balken en lijnen alleen het middenstuk.
  function krimp(v, f){ var h = v.b - v.t; return {l:v.l, r:v.r, t:v.t + f * h, b:v.b - f * h}; }
  function snijdt(a, b, tol){ return Math.min(a.r, b.r) - Math.max(a.l, b.l) > tol && Math.min(a.b, b.b) - Math.max(a.t, b.t) > tol; }
  function naam(e){ return "'" + (e.textContent || '').trim() + "'"; }
  function meet(svg, wie){
    var tekst = [].filter.call(svg.querySelectorAll('text'), zichtbaar);
    var balken = [].filter.call(svg.querySelectorAll('rect'), zichtbaar);
    var lijnen = [].filter.call(svg.querySelectorAll('line'), function(l){ return zichtbaar(l) && !l.closest('.kling'); });
    var sv = vak(svg), mag_uitsteken = getComputedStyle(svg).overflow === 'visible';
    // het getal bij een balk staat binnen het plotvlak: niet onder het laagste streepje van de as, waar
    // de etiketten beginnen (Bens geval: "−1" stond onder de as, óp "H/M")
    var as = svg.querySelector('line.as-y'), vloer = as ? vak(as).b : null;
    uit.metingen.push({wie:wie, teksten:tekst.length, balken:balken.length, lijnen:lijnen.length, as:!!as});
    // een trap zonder herkenbare as of zonder getallen kan deze meting niet doen: dat is niet "goed"
    if (svg.matches('#waterval, .mini-wv') && (!as || !svg.querySelector('text.waarde')))
      uit.fouten.push(wie + ': trap zonder line.as-y of zonder text.waarde, de plotvlak-meting kon niet kijken');
    if (vloer !== null) tekst.forEach(function(a){
      if (a.matches('.waarde') && krimp(vak(a), .2).b > vloer + .5) uit.fouten.push(wie + ': getal ' + naam(a) + ' staat onder de as, bij de etiketten');
    });
    tekst.forEach(function(a, i){
      var va = vak(a), glyf = krimp(va, .2);
      if (!mag_uitsteken && (va.l < sv.l - 1 || va.r > sv.r + 1 || va.t < sv.t - 1 || va.b > sv.b + 1))
        uit.fouten.push(wie + ': tekst ' + naam(a) + ' valt buiten de figuur');
      tekst.slice(i + 1).forEach(function(b){
        if (snijdt(krimp(va, .08), krimp(vak(b), .08), .5)) uit.fouten.push(wie + ': tekst ' + naam(a) + ' op tekst ' + naam(b));
      });
      balken.forEach(function(r){
        if (snijdt(glyf, vak(r), .5)) uit.fouten.push(wie + ': tekst ' + naam(a) + ' op een balk (' + r.getAttribute('class') + ')');
      });
      lijnen.forEach(function(l){
        var vl = vak(l); vl = {l:vl.l - .5, r:vl.r + .5, t:vl.t - .5, b:vl.b + .5};
        if (snijdt(glyf, vl, 0)) uit.fouten.push(wie + ': tekst ' + naam(a) + ' op een lijn (' + l.getAttribute('class') + ')');
      });
    });
    // geen stippen, geen stippellijnen. Een streepjespatroon met één streep die langer is dan de lijn zelf
    // tekent een doorgetrokken lijn (zo schuift de snede in het zwaard erin); dat telt niet als gestippeld.
    [].forEach.call(svg.querySelectorAll('line,path,rect,polyline,circle'), function(e){
      if (!zichtbaar(e)) return;
      var d = getComputedStyle(e).strokeDasharray;
      if (!d || d === 'none') return;
      var eerste = parseFloat(d), lengte = e.getTotalLength ? e.getTotalLength() : Infinity;
      if (!(eerste >= lengte - .01)) uit.fouten.push(wie + ': gestippelde lijn (' + d + ') op ' + e.tagName + '.' + e.getAttribute('class'));
    });
  }
  // 1. het speelbord, stand voor stand
  STANDEN.forEach(function(st){
    ['voorI','voorII','naI','naII','naIII','naIV'].forEach(function(k, i){
      var s = document.getElementById('s-' + k); s.value = st[1][i];
      s.dispatchEvent(new Event('input', {bubbles:true}));
    });
    meet(document.getElementById('waterval'), 'speelbord, ' + st[0]);
  });
  // 2. de ladder, met alle uitwerkingen open
  if (LADDER){
    [].forEach.call(document.querySelectorAll('details'), function(d){ d.open = true; });
    [].forEach.call(document.querySelectorAll('#ladder figure svg'), function(svg){
      var trede = svg.closest('.trede'), wat = svg.getAttribute('class') || 'svg';
      var wie = 'ladder ' + trede.id + ' ' + wat + (svg.getAttribute('data-tot') ? ' (' + svg.getAttribute('data-tot') + ' stukjes)' : '');
      if (ZONDER.some(function(z){ return svg.matches(z); })) return;
      if (svg.matches('.zwaard-svg')){
        meet(svg, wie + ' voor het klieven');
        trede.classList.add('gekliefd'); meet(svg, wie + ' na het klieven'); trede.classList.remove('gekliefd');
      } else meet(svg, wie);
    });
  }
  var pre = document.createElement('pre'); pre.id = 'figuurtoets'; pre.textContent = JSON.stringify(uit);
  document.body.appendChild(pre);
})();
</script>
"""


def draai_chrome(pad, werkmap):
    """Open pad in headless Chrome en geef de DOM terug. Chrome sluit op broodje na --dump-dom niet altijd af
    (gemeten 8-10-2026), dus we wachten tot de uitslag er staat en schieten hem dan af."""
    uitvoer = werkmap / (pad.stem + ".dom.html")
    profiel = tempfile.mkdtemp(dir=werkmap)
    with open(uitvoer, "w") as f:
        p = subprocess.Popen([CHROME, "--headless=new", "--disable-gpu", "--user-data-dir=" + profiel,
                              "--virtual-time-budget=8000", "--window-size=1200,2000", "--dump-dom",
                              pad.as_uri()], stdout=f, stderr=subprocess.DEVNULL)
        for _ in range(120):
            time.sleep(0.5)
            if "</html>" in uitvoer.read_text(encoding="utf-8", errors="replace"):
                time.sleep(0.3)
                break
            if p.poll() is not None:
                break
        p.kill()
        p.wait()
    return uitvoer.read_text(encoding="utf-8", errors="replace")


def maak_kopie(bron, werkmap, naam, standen, ladder, zonder, getallen=None):
    t = re.sub(r'\s*<script data-goatcounter[^>]*></script>', '', bron)   # anders zoekt Chrome file://gc.zgo.at
    if getallen is not None:
        nieuw = "var GETALLEN = {" + ", ".join("%s:%g" % (k, v) for k, v in zip(SLEUTELS, getallen)) + "};"
        t, n = re.subn(r"var GETALLEN = \{[^}]*\};", nieuw, t)
        if n != 1:
            return None
    script = MEETSCRIPT % {"standen": json.dumps(standen), "ladder": "true" if ladder else "false",
                           "zonder": json.dumps(zonder)}
    pad = werkmap / (naam + ".html")
    pad.write_text(t.replace("</body>", script + "</body>", 1), encoding="utf-8")
    return pad


def lees_uitslag(dom):
    m = re.search(r'<pre id="figuurtoets">(.*?)</pre>', dom, re.S)
    return json.loads(html.unescape(m.group(1))) if m else None


def main():
    global PAGINA
    if len(sys.argv) > 1:          # een andere kopie meten, bijvoorbeeld voor een mutatieproef
        PAGINA = Path(sys.argv[1]).resolve()
    if not PAGINA.exists():
        print("KON NIET KIJKEN: %s bestaat niet" % PAGINA)
        return 3
    if not Path(CHROME).exists():
        print("KON NIET KIJKEN: geen Chrome op %s" % CHROME)
        return 3
    fout_in_lijst = []
    for naam, z, verwacht in SCHUIFSTANDEN:
        st = stukjes(z)
        if any(abs(st[k] - verwacht[k]) > 1e-9 for k in verwacht):
            fout_in_lijst.append("%s: de schuifjes geven %s, niet %s" % (naam, st, verwacht))
        if not all(0 <= v <= 100 for v in z):
            fout_in_lijst.append("%s: een schuifje staat buiten 0-100" % naam)
    if fout_in_lijst:
        for f in fout_in_lijst:
            print("FOUT IN DE TOETS ZELF: " + f)
        return 3
    bron = PAGINA.read_text(encoding="utf-8")
    werkmap = Path(tempfile.mkdtemp(prefix="solomon_figuren_"))
    runs = [("bladzij", maak_kopie(bron, werkmap, "bladzij", [[n, z] for n, z, _ in SCHUIFSTANDEN], True, []))]
    for naam in GETALLEN_PROEF:
        z = next(z for n, z, _ in SCHUIFSTANDEN if n == naam)
        slug = re.sub(r"\W+", "_", naam).strip("_").lower()
        runs.append(("getypt: " + naam, maak_kopie(bron, werkmap, "getypt_" + slug, [], True,
                                                   [".zwaard-svg", ".did-svg"], getallen=z)))
    fouten, metingen, blind = [], 0, []
    for wie, pad in runs:
        if pad is None:
            blind.append("%s: 'var GETALLEN = {...};' niet precies één keer gevonden" % wie)
            continue
        uitslag = lees_uitslag(draai_chrome(pad, werkmap))
        if uitslag is None:
            blind.append("%s: geen uitslag uit Chrome (%s)" % (wie, pad))
            continue
        leeg = [m["wie"] for m in uitslag["metingen"] if m["teksten"] == 0]
        if leeg:
            blind.append("%s: figuren zonder één zichtbare tekst: %s" % (wie, "; ".join(leeg)))
        metingen += len(uitslag["metingen"])
        print("%-36s %2d figuren gemeten, %3d teksten, %2d keer iets over elkaar" % (
            wie, len(uitslag["metingen"]), sum(m["teksten"] for m in uitslag["metingen"]), len(uitslag["fouten"])))
        fouten += ["[%s] %s" % (wie, f) for f in uitslag["fouten"]]
    for b in blind:
        print("KON NIET KIJKEN: " + b)
    for f in fouten:
        print("FOUT: " + f)
    if blind:
        return 3
    if fouten:
        return 1
    print("ok: %d figuurmetingen, geen tekst op tekst, balk of nullijn, niets buiten de figuur, geen stippellijn" % metingen)
    return 0


if __name__ == "__main__":
    sys.exit(main())
