# Is de kop nog in beeld als je de beschrijving leest?
#
# De opdracht vraagt dit expliciet: als de instellingskop in de rug-vorm
# verder van de beschrijving af staat, is een stukje herhaling juist nuttig
# en mag de plaatsbepaling niet weg. Dus niet naar het plaatje kijken maar
# meten: zet de titel van elk boek midden in het venster en kijk of zijn
# instellingskop en zijn opleidingslabel dan nog zichtbaar zijn.
#
# Venster 1440x900: een gewoon laptopscherm met een browserbalk erboven.
library(chromote)
library(jsonlite)

blad <- normalizePath("_proefdruk_plank_af/proefblad.html")

meet <- function(vorm, vh = 900L) {
  b <- ChromoteSession$new(width = 1440, height = vh)
  b$Page$navigate(paste0("file://", blad, "?vorm=", vorm))
  Sys.sleep(2.5)
  stopifnot(identical(b$Runtime$evaluate(
    'document.documentElement.getAttribute("data-vorm")')$result$value, vorm))

  tab <- fromJSON(b$Runtime$evaluate(sprintf('JSON.stringify((() => {
    const vh = %d;
    const uit = [];
    // Quarto sluit de sectie zodra de eerste boektitel (h3) langskomt, dus
    // label en plank zijn geen buren. querySelectorAll geeft wel gewoon
    // leesvolgorde, ongeacht de nesting -- dus loop ik die af.
    const rij = document.querySelectorAll(".cc-instelling, .cc-opleiding, .cc-plank-groep");
    let inst = null, opl = null;
    rij.forEach(el => {
      if (el.classList.contains("cc-instelling")) { inst = el; return; }
      if (el.classList.contains("cc-opleiding"))  { opl  = el; return; }
      const plank = el;
      plank.querySelectorAll(".cc-boek").forEach(boek => {
        const h3 = boek.querySelector("h3");
        const y = h3.getBoundingClientRect().top + window.scrollY;
        // titel midden in het venster
        const scroll = Math.max(0, y - vh/2);
        const zichtbaar = (e) => {
          const t = e.getBoundingClientRect().top + window.scrollY - scroll;
          return t > 0 && t < vh;
        };
        uit.push({
          boek: h3.textContent.replace(/\\s+/g," ").trim(),
          instelling: inst.textContent.trim(),
          opleiding: opl.textContent.trim(),
          afstand_tot_instelling: Math.round(y - (inst.getBoundingClientRect().top + window.scrollY)),
          afstand_tot_opleiding: Math.round(y - (opl.getBoundingClientRect().top + window.scrollY)),
          instelling_in_beeld: zichtbaar(inst),
          opleiding_in_beeld: zichtbaar(opl)
        });
      });
    });
    return uit;
  })())', vh))$result$value)

  cat(sprintf("\n=== vorm %s, venster 1440x%d ===\n", vorm, vh))
  print(tab, right = FALSE)
  b$close()
  invisible(tab)
}

meet("rug")
meet("kaart")
