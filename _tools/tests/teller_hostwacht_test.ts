// ============================================================
// teller_hostwacht_test.ts — draait de hostwacht uit _tools/teller.html echt.
//
//   quarto run _tools/tests/teller_hostwacht_test.ts
//
// (Quarto heeft zijn eigen JavaScript-motor bij zich, Deno; `quarto run` is de
// deur ernaartoe. Er hoeft dus niets bij geïnstalleerd te worden.)
//
// Wat dit WEL bewijst: dat het script uit teller.html, letterlijk zoals de
// bouw het in elke bladzij zet, count.js alleen ophaalt op countcamp.org en
// nergens anders. Het script wordt uit het bestand gelezen, niet overgetikt.
//
// Wat dit NIET bewijst: wat een echte browser doet. `location` en `document`
// zijn hier nagebootst. Of GoatCounter het bezoek daarna ook echt boekt, zie
// je alleen in het dashboard; zie de proef in het rapport van 8-10-2026.
// ============================================================

const pad = new URL("../teller.html", import.meta.url);
const html = await Deno.readTextFile(pad);
const m = html.match(/<script>([\s\S]*?)<\/script>/);
if (!m) {
  console.log("ZAKT  geen <script> gevonden in teller.html");
  Deno.exit(1);
}
const code = m[1];

type Uitslag = { geladen: boolean; src?: string; endpoint?: string | null };

function draai(url: string): Uitslag {
  const u = new URL(url);
  const toegevoegd: Array<Record<string, unknown>> = [];
  const location = { hostname: u.hostname, pathname: u.pathname, protocol: u.protocol, host: u.host };
  const document = {
    createElement(_tag: string) {
      const attrs: Record<string, string> = {};
      return {
        async: false,
        src: "",
        setAttribute(k: string, v: string) { attrs[k] = v; },
        getAttribute(k: string) { return attrs[k] ?? null; },
      };
    },
    head: { appendChild(el: Record<string, unknown>) { toegevoegd.push(el); } },
  };
  new Function("location", "document", code)(location, document);
  if (toegevoegd.length === 0) return { geladen: false };
  const el = toegevoegd[0] as { src: string; getAttribute(k: string): string | null };
  return { geladen: true, src: el.src, endpoint: el.getAttribute("data-goatcounter") };
}

// [adres, hoort te tellen?] — elk adres staat voor een plek waar een bladzij
// van ons echt geopend wordt of kan worden.
const zaken: Array<[string, boolean]> = [
  ["https://countcamp.org/", true],
  ["https://countcamp.org/oefenboeken/ozp1/index.html", true],
  ["https://www.countcamp.org/manuscript/h4.html", true],
  ["https://countcamp.org/pr-preview/pr-1/manuscript/h4.html", false],   // PR-proefdruk, zelfde host
  ["https://countcamp.org/pr-preview/", false],
  ["http://broodje:8788/teller/index.html", false],                      // de spooksite
  ["http://100.101.102.103:8788/teller/", false],                        // Tailscale-adres
  ["http://broodje.tail1234.ts.net:8788/x/", false],                     // MagicDNS-naam
  ["http://localhost:4200/", false],                                     // quarto preview
  ["http://127.0.0.1:8000/", false],
  ["file:///Users/ben/Documents/Ben_OS/countcamp_site/_site/index.html", false],
  ["https://countcamp.github.io/site/", false],                          // GitHub-adres zonder eigen domein
  ["https://countcamp.org.evil.example/", false],                        // lijkt erop, is het niet
  ["https://notcountcamp.org/", false],
  ["https://countcamp.org/pr-previewx/", true],                          // alleen de map /pr-preview/ is proef
];

let gezakt = 0;
for (const [url, moet] of zaken) {
  const r = draai(url);
  const ok = r.geladen === moet &&
    (!r.geladen || (r.src === "https://gc.zgo.at/count.js" &&
                    r.endpoint === "https://countcamp.goatcounter.com/count"));
  console.log(`  ${ok ? "ok  " : "ZAKT"}  ${moet ? "telt     " : "telt niet"}  ${url}` +
              (r.geladen ? `  -> ${r.src} (${r.endpoint})` : ""));
  if (!ok) gezakt++;
}
console.log(`\n${zaken.length - gezakt} ok, ${gezakt} gezakt (van ${zaken.length})`);
Deno.exit(gezakt ? 1 : 0);
