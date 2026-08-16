#!/usr/bin/env python3
"""Meet de FEITELIJKE kleuren van de callout-kop op de gerenderde diensten.html.

Werkwijze: we plakken een meet-scriptje achter in een KOPIE van de gerenderde
pagina, laten Chrome die kopie laden, en lezen de uitkomst uit de DOM-dump.
Zo meten we wat de cascade oplevert, niet wat het stylesheet belooft.

Twee dingen mengen mee in de kleur die iemand echt ziet, en de tweede is de
valkuil: alfa in de kleur zelf (rgba), en `opacity` op het element of een
voorouder. `opacity` is GROEPS-doorzichtigheid -- het element wordt eerst
compleet getekend (achtergrond plus letters) en dan als geheel over wat eronder
ligt gelegd. Quarto zet `opacity: 85%` op .callout-header; wie dat overslaat
meet een kleur die niemand op het scherm heeft.
"""
import subprocess
import sys
import os
import re
import html

BRON = "diensten.html"
KOPIE = "_meting_diensten.html"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

PROBE = r"""
<script>
function rgb(s){
  var m = s.match(/rgba?\(([^)]+)\)/);
  if(!m) return null;
  var p = m[1].split(/[,\s\/]+/).filter(function(x){ return x.length; }).map(parseFloat);
  return {r:p[0], g:p[1], b:p[2], a: p.length>3 ? p[3] : 1};
}
function hex(c){
  function h(v){ var s = Math.round(v).toString(16); return s.length<2 ? '0'+s : s; }
  return '#'+h(c.r)+h(c.g)+h(c.b);
}
function meng(voor, achter, a){
  return {r: voor.r*a + achter.r*(1-a),
          g: voor.g*a + achter.g*(1-a),
          b: voor.b*a + achter.b*(1-a)};
}
function naam(el){
  return el.tagName.toLowerCase() +
         (el.className ? '.'+String(el.className).trim().split(/\s+/).join('.') : '');
}
/* Tekent de keten van <html> omlaag tot en met `el` op wit papier.
   Geeft terug wat er op het scherm staat als achtergrond ACHTER de letters
   van `el`, en wat er van de letterkleur zelf overblijft. */
function schilder(el, fgRaw){
  var keten = [];
  for(var n = el; n; n = n.parentElement){ keten.unshift(n); }

  var canvas = {r:255, g:255, b:255};   // wit papier onder alles
  var backdrops = [], preOpacity = [], opacities = [], spoor = [];

  keten.forEach(function(n){
    var cs = getComputedStyle(n);
    var bg = rgb(cs.backgroundColor);
    var op = parseFloat(cs.opacity);
    var backdrop = canvas;
    var vlak = canvas;
    if(bg && bg.a > 0){ vlak = meng(bg, canvas, bg.a); }
    backdrops.push(backdrop);
    preOpacity.push(vlak);
    opacities.push(op);
    if(op < 1){ vlak = meng(vlak, backdrop, op); }
    if((bg && bg.a > 0) || op < 1){
      spoor.push(naam(n) + '  bg=' + cs.backgroundColor + (op < 1 ? '  opacity=' + op : ''));
    }
    canvas = vlak;
  });

  // de letters: eerst op het vlak van `el` zelf (vóór diens eigen opacity),
  // daarna alle groeps-opacity's van binnen naar buiten eroverheen.
  var i = keten.length - 1;
  var tekst = meng(fgRaw, preOpacity[i], fgRaw.a);
  for(; i >= 0; i--){
    if(opacities[i] < 1){ tekst = meng(tekst, backdrops[i], opacities[i]); }
  }
  return {bg: canvas, tekst: tekst, spoor: spoor};
}
function lum(c){
  function ch(v){ v = v/255; return v <= 0.03928 ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4); }
  return 0.2126*ch(c.r) + 0.7152*ch(c.g) + 0.0722*ch(c.b);
}
function ratio(a,b){
  var l1 = lum(a), l2 = lum(b);
  var hi = Math.max(l1,l2), lo = Math.min(l1,l2);
  return (hi+0.05)/(lo+0.05);
}
var doelen = [
  ['.callout .callout-title-container', 'callout-KOP (de gemeten regel)'],
  ['.callout .callout-body p',          'callout-body ter vergelijking']
];
var out = [];
doelen.forEach(function(t){
  var el = document.querySelector(t[0]);
  if(!el){ out.push('--- ' + t[1] + ': NIET GEVONDEN (' + t[0] + ')'); return; }
  var cs = getComputedStyle(el);
  var s = schilder(el, rgb(cs.color));
  out.push('--- ' + t[1] + '   (' + t[0] + ')');
  out.push('  tekst: color=' + cs.color + '  font=' + cs.fontSize + '/' + cs.fontWeight);
  out.push('  lagen (papier -> boven): ' + s.spoor.join('   |   '));
  out.push('  OP HET SCHERM   tekst ' + hex(s.tekst) + '   op   ' + hex(s.bg));
  out.push('  exact           tekst ' + JSON.stringify(s.tekst) + ' bg ' + JSON.stringify(s.bg));
  out.push('  CONTRAST        ' + ratio(s.tekst, s.bg).toFixed(4) + ' : 1');
});
var pre = document.createElement('pre');
pre.id = 'METING';
pre.textContent = out.join('\n');
document.body.insertBefore(pre, document.body.firstChild);
</script>
"""


def main():
    src = open(BRON, encoding="utf-8").read()
    assert "</body>" in src, "geen </body> in de gerenderde pagina"
    open(KOPIE, "w", encoding="utf-8").write(src.replace("</body>", PROBE + "\n</body>"))

    url = "file://" + os.path.abspath(KOPIE)
    res = subprocess.run(
        [CHROME, "--headless=new", "--disable-gpu", "--no-sandbox",
         "--virtual-time-budget=6000", "--allow-file-access-from-files",
         "--dump-dom", url],
        capture_output=True, text=True, timeout=180,
    )
    m = re.search(r'<pre id="METING">(.*?)</pre>', res.stdout, re.S)
    if not m:
        sys.stderr.write(res.stderr[-3000:])
        sys.exit("METING-blok niet gevonden in de DOM-dump")
    print(html.unescape(m.group(1)))


if __name__ == "__main__":
    main()
