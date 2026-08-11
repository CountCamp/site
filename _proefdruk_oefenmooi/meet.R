# Nameting op de gerenderde oefenboeken-bladzij (spoor oefenmooi).
# Meet kaartbreedtes, kaart-tot-kaart-afstanden en de afstand kop->plank.
library(chromote)
b <- ChromoteSession$new(width = 1440, height = 1000)
b$Page$navigate("file:///Users/ben/Documents/Ben_OS/countcamp_site/_site/oefenboeken/index.html")
Sys.sleep(3)
js <- '
(() => {
  const px2mm = px => (px / 96 * 25.4).toFixed(1);
  const r = el => el.getBoundingClientRect();
  const uit = [];
  const planken = [...document.querySelectorAll(".cc-plank")];
  planken.forEach((p, pi) => {
    const boeken = [...p.querySelectorAll(".cc-boek")];
    boeken.forEach((bk, bi) => {
      const rb = r(bk);
      uit.push(`plank${pi+1} kaart${bi+1}: breed ${rb.width.toFixed(0)}px, hoog ${rb.height.toFixed(0)}px`);
      if (bi > 0) {
        const vorige = r(boeken[bi-1]);
        uit.push(`  gat naar vorige kaart: ${(rb.top - vorige.bottom).toFixed(0)}px = ${px2mm(rb.top - vorige.bottom)}mm`);
      }
    });
    const kop = p.previousElementSibling;
  });
  // afstand sectiekop -> eerste kaart, en intro-alinea -> plank
  const secties = [...document.querySelectorAll("main h3")].filter(h => !h.closest(".cc-boek"));
  secties.forEach(h => {
    const sec = h.parentElement;
    const plank = sec.querySelector(".cc-plank");
    if (plank) {
      const laatsteP = [...sec.children].filter(c => c.tagName === "P" && c.compareDocumentPosition(plank) & 4).pop();
      if (laatsteP) uit.push(`"${h.textContent.trim()}": alinea -> plank ${(r(plank).top - r(laatsteP).bottom).toFixed(0)}px = ${px2mm(r(plank).top - r(laatsteP).bottom)}mm`);
    }
  });
  // binnen een kaart: titel -> eerste alinea
  const k1 = document.querySelector(".cc-boek");
  const t1 = k1.querySelector("h3"), p1 = k1.querySelector("p");
  uit.push(`in kaart 1: titel -> tekst ${(r(p1).top - r(t1).bottom).toFixed(0)}px = ${px2mm(r(p1).top - r(t1).bottom)}mm`);
  // chip-positie
  const chip = k1.querySelector(".cc-chip"), kop1 = k1.querySelector("h3 a");
  uit.push(`kaart 1: chip rechts op ${(r(k1).right - r(chip).right).toFixed(0)}px van de kaartrand, kop links op ${(r(kop1).left - r(k1).left).toFixed(0)}px`);
  // leeskolom
  const main = document.querySelector("main#quarto-document-content");
  uit.push(`leeskolom: ${r(main).width.toFixed(0)}px breed`);
  return uit.join("\\n");
})()
'
cat(b$Runtime$evaluate(js)$result$value, "\n")
b$close()
