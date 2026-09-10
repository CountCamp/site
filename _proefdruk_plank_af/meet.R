# Nameting spoor plank, 10-9-2026 -- de plank na taak 1 en taak 2.
#
# Wat dit moet uitwijzen:
#   1. Staat de dubbele plaatsbepaling er echt uit, en staat het jaar er nog?
#   2. Zien de drie groepjes (Leiden/Psychologie, Leiden/Pedagogiek,
#      Erasmus/Psychologie) er in BEIDE vormen hetzelfde uit? Erasmus heeft
#      maar een boek en Leiden er vier; als de opmaak aan buurschap hangt
#      valt dat hier door de mand.
#   3. Tonen OZP 2 en STAT 3 hun "nog niet af" op precies dezelfde manier?
#   4. Oogt een kop met een ongelinkt boek eronder niet als een storing?
#
# De vorm gaat via ?vorm= en NIET door zelf data-vorm te zetten: vorm.js
# staat in de <head>, draait na zo'n ingreep en zet hem terug. Dat zag er
# vorige keer uit als "de kaart-vorm verandert hier niets". Het script
# toetst daarom hardop welke vorm er op stond toen het mat.
library(chromote)
library(jsonlite)

blad <- normalizePath("_proefdruk_plank_af/proefblad.html")
uit  <- "_proefdruk_plank_af/na"
dir.create(uit, showWarnings = FALSE)

js <- function(b, code) b$Runtime$evaluate(code, returnByValue = TRUE)$result$value
jsjson <- function(b, code) fromJSON(js(b, paste0("JSON.stringify(", code, ")")))

open_vorm <- function(vorm) {
  b <- ChromoteSession$new(width = 1440, height = 1200)
  b$Page$navigate(paste0("file://", blad, "?vorm=", vorm))
  Sys.sleep(2.5)
  gemeten <- js(b, 'document.documentElement.getAttribute("data-vorm")')
  if (!identical(gemeten, vorm)) {
    stop(sprintf("VORM KLOPT NIET: gevraagd '%s', op de bladzij staat '%s'", vorm, gemeten))
  }
  cat(sprintf("\n===== vorm op de bladzij: %s (gevraagd: %s) =====\n", gemeten, vorm))
  b
}

# ---- de groepjes, opgehaald uit de bladzij zelf (niet ingetikt) -------
groepjes_js <- '
(() => Array.from(document.querySelectorAll(".cc-plank-groep")).map(p => {
  const cs = getComputedStyle(p);
  return {
    naam: p.getAttribute("aria-label"),
    boeken: p.querySelectorAll(".cc-boek").length,
    links: p.querySelectorAll("h3 a:not(.anchorjs-link)").length,
    marge_boven: cs.marginTop,
    marge_onder: cs.marginBottom,
    display: cs.display
  };
}))()'

labels_js <- '
(() => {
  const uit = [];
  document.querySelectorAll(".cc-instelling, .cc-opleiding").forEach(e => {
    const cs = getComputedStyle(e);
    uit.push({
      soort: e.className,
      tekst: e.textContent.trim(),
      marge_boven: cs.marginTop,
      marge_onder: cs.marginBottom,
      lijn_onder: cs.borderBottomWidth + " " + cs.borderBottomStyle,
      lettertype: cs.fontStyle + " " + Math.round(parseFloat(cs.fontSize)*100)/100 + "px",
      kleur: cs.color
    });
  });
  return uit;
})()'

# de twee boeken die er nog niet zijn, plus een boek dat er wel is
straks_js <- '
(() => {
  const pak = (el) => {
    const cs = getComputedStyle(el);
    const h3 = el.querySelector("h3");
    const chip = el.querySelector(".cc-chip-straks");
    return {
      titel: h3.textContent.replace(/\\s+/g, " ").trim(),
      klassen: el.className,
      links_in_titel: h3.querySelectorAll("a:not(.anchorjs-link)").length,
      rand_links: cs.borderLeftWidth + " " + cs.borderLeftStyle,
      rand_rondom: cs.borderTopWidth + " " + cs.borderTopStyle,
      achtergrond: cs.backgroundColor,
      titelkleur: getComputedStyle(h3).color,
      chip_rand: chip ? getComputedStyle(chip).borderTopWidth + " " + getComputedStyle(chip).borderTopStyle : "geen chip",
      chip_vlak: chip ? getComputedStyle(chip).backgroundColor : "geen chip",
      chip_woord: chip ? chip.textContent.trim() : "geen chip"
    };
  };
  return Array.from(document.querySelectorAll(".cc-boek-straks")).map(pak);
})()'

meet <- function(vorm) {
  b <- open_vorm(vorm)

  cat("\n-- de drie groepjes --\n")
  print(jsjson(b, groepjes_js))

  cat("\n-- de labels --\n")
  print(jsjson(b, labels_js))

  cat("\n-- de boeken die er nog niet zijn --\n")
  print(jsjson(b, straks_js))

  # zweven: reageert een ongelinkt boek, en reageert een gelinkt boek wel?
  zweef <- function(sel) {
    b$Runtime$evaluate(sprintf('document.querySelector("%s").scrollIntoView({block:"center"})', sel))
    Sys.sleep(0.4)
    r <- jsjson(b, sprintf('(() => { const r = document.querySelector("%s").getBoundingClientRect();
      return {x: r.x + r.width/2, y: r.y + r.height/2}; })()', sel))
    voor <- js(b, sprintf('getComputedStyle(document.querySelector("%s")).backgroundColor', sel))
    b$Input$dispatchMouseEvent(type = "mouseMoved", x = r$x, y = r$y)
    Sys.sleep(0.8)   # .cc-boek heeft een overgang van 0,15 s -- niet te vroeg lezen
    na <- js(b, sprintf('getComputedStyle(document.querySelector("%s")).backgroundColor', sel))
    tr <- js(b, sprintf('getComputedStyle(document.querySelector("%s")).transform', sel))
    b$Input$dispatchMouseEvent(type = "mouseMoved", x = 5, y = 5)
    Sys.sleep(0.4)
    cat(sprintf("  %-46s rust %-22s zweef %-22s transform %s\n", sel, voor, na, tr))
  }
  # OZP 2 en STAT 3 staan in verschillende planken, dus niet als buren te
  # pakken; ik nummer ze op volgorde van voorkomen.
  cat("\n-- zweven --\n")
  zweef(".cc-boek-straks:nth-of-type(2)")                    # OZP 2
  zweef(".cc-plank-groep:last-of-type .cc-boek-straks")      # STAT 3
  zweef(".cc-plank-groep .cc-boek:not(.cc-boek-straks)")     # een boek dat er wel is

  # de plank van Erasmus apart: een kop met een ongelinkt boek eronder
  laatste <- jsjson(b, '(() => {
    const p = Array.from(document.querySelectorAll(".cc-plank-groep")).pop();
    const r = p.getBoundingClientRect();
    return {naam: p.getAttribute("aria-label"), hoogte: Math.round(r.height*10)/10,
            breedte: Math.round(r.width*10)/10, boeken: p.querySelectorAll(".cc-boek").length};
  })()')
  cat("\n-- de laatste plank --\n"); print(laatste)

  # schot van de hele sectie "Voor losse vakken"
  b$Runtime$evaluate('document.querySelector(".cc-instelling").scrollIntoView({block:"start"})')
  Sys.sleep(0.6)
  b$Runtime$evaluate('window.scrollBy(0, -80)')
  Sys.sleep(0.4)
  b$screenshot(file.path(uit, paste0("losse_vakken_", vorm, ".png")))

  b$close()
}

# ---- contrast: de kleuren komen UIT de bladzij, niet uit mijn hoofd ----
# Chrome geeft ze als "rgb(r, g, b)"; de vergelijking is die van WCAG.
lum <- function(rgb) {
  v <- as.numeric(regmatches(rgb, gregexpr("[0-9]+", rgb))[[1]])[1:3] / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  sum(v * c(0.2126, 0.7152, 0.0722))
}
cr <- function(a, b) { la <- lum(a); lb <- lum(b); (max(la,lb) + 0.05) / (min(la,lb) + 0.05) }

contrast <- function(vorm) {
  b <- open_vorm(vorm)
  paren <- jsjson(b, '(() => {
    const papier = getComputedStyle(document.body).backgroundColor;
    const uit = [];
    document.querySelectorAll(".cc-boek-straks").forEach(el => {
      const h3 = el.querySelector("h3");
      const chip = el.querySelector(".cc-chip-straks");
      const vlak = getComputedStyle(el).backgroundColor;
      const achter = (vlak === "rgba(0, 0, 0, 0)") ? papier : vlak;
      uit.push({wat: "gedempte titel: " + h3.textContent.replace(/\\s+/g," ").trim(),
                voor: getComputedStyle(h3).color, achter: achter});
      uit.push({wat: "woord in de chip",  voor: getComputedStyle(chip).color, achter: achter});
      uit.push({wat: "rand van de chip",  voor: getComputedStyle(chip).borderTopColor, achter: achter});
    });
    return uit;
  })()')
  cat("\n-- contrast, uitgerekend uit de gemeten kleuren --\n")
  for (i in seq_len(nrow(paren))) {
    cat(sprintf("  %-46s %-18s op %-18s = %.2f\n", paren[i,"wat"],
                paren[i,"voor"], paren[i,"achter"],
                cr(paren[i,"voor"], paren[i,"achter"])))
  }
  b$close()
}

meet("rug")
meet("kaart")
contrast("rug")
contrast("kaart")
