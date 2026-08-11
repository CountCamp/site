# Proefdruk-schoten voor spoor boekvoet (11-8-2026).
# De voet van de boekpagina: de drie broertjes aan het ruggengraatje.
# Gebruik: Rscript _proefdruk_boekvoet/schiet.R
library(chromote)
library(jsonlite)

WORTEL <- "/Users/ben/Documents/Ben_OS/countcamp_site"
BOEK <- paste0("file://", WORTEL, "/_site/manuscript/index.html")
UIT <- file.path(WORTEL, "_proefdruk_boekvoet", "na")
dir.create(UIT, showWarnings = FALSE, recursive = TRUE)

paginarect <- function(b, sel) fromJSON(b$Runtime$evaluate(sprintf(
  '(() => { const r = document.querySelector("%s").getBoundingClientRect();
     return JSON.stringify({x: r.x + window.scrollX, y: r.y + window.scrollY,
                            w: r.width, h: r.height,
                            vx: r.x + r.width/2, vy: r.y + r.height/2}); })()', sel))$result$value)

# de voet: van het kopje "De oefenboeken" tot en met de doorverwijzing eronder
voetrect <- function(b) fromJSON(b$Runtime$evaluate(
  '(() => { const kop = document.querySelector("#de-oefenboeken");
     const r = kop.getBoundingClientRect();
     return JSON.stringify({x: r.x + window.scrollX, y: r.y + window.scrollY,
                            w: r.width, h: r.height}); })()')$result$value)

# Knippen in PAGINA-coordinaten (niet het venster verhogen: dan reflowt de
# bladzij en loopt de scrollpositie weg -- dat kostte de eerste ronde).
schiet_voet <- function(breed, naam, vraagtekens = "") {
  b <- ChromoteSession$new(width = breed, height = 1000)
  b$Emulation$setDeviceMetricsOverride(width = breed, height = 1000,
                                       deviceScaleFactor = 1, mobile = breed < 700)
  b$Page$navigate(paste0(BOEK, vraagtekens))
  Sys.sleep(3)
  r <- voetrect(b)
  b$screenshot(file.path(UIT, paste0(naam, ".png")),
               cliprect = c(max(0, r$x - 40), max(0, r$y - 30), r$w + 80, r$h + 60))
  vorm <- b$Runtime$evaluate('document.documentElement.getAttribute("data-vorm")')$result$value
  cat("geschoten:", naam, "| breed", breed, "| data-vorm =",
      if (is.null(vorm)) "(geen)" else vorm, "| voethoogte", round(r$h), "px\n")
  b$close()
}

schiet_voet(1440, "boekvoet_rug_1440")
schiet_voet(1440, "boekvoet_kaart_1440", "?vorm=kaart")
schiet_voet(390, "boekvoet_rug_mobiel_390")

# --- de oplichter: muis en Tab, op de plank onderaan het boek ---
b <- ChromoteSession$new(width = 1440, height = 1000)
b$Page$navigate(BOEK)
Sys.sleep(3)
b$Runtime$evaluate('document.querySelector(".cc-plank").scrollIntoView({block: "center"})')
Sys.sleep(0.5)
p <- paginarect(b, ".cc-boek")
b$Input$dispatchMouseEvent(type = "mouseMoved", x = p$vx, y = p$vy)
Sys.sleep(0.6)
tint <- b$Runtime$evaluate(
  'getComputedStyle(document.querySelector(".cc-boek")).backgroundColor')$result$value
cat("hovertint eerste boek:", tint, "\n")
r <- paginarect(b, ".cc-plank")
b$screenshot(file.path(UIT, "boekvoet_hover.png"),
             cliprect = c(r$x - 40, r$y - 25, r$w + 80, r$h + 50))

b$Input$dispatchMouseEvent(type = "mouseMoved", x = 5, y = 5)
b$Runtime$evaluate('window.scrollTo(0,0)')
Sys.sleep(0.3)
for (i in 1:200) {
  b$Input$dispatchKeyEvent(type = "keyDown", key = "Tab", code = "Tab",
                           windowsVirtualKeyCode = 9L, nativeVirtualKeyCode = 9L)
  b$Input$dispatchKeyEvent(type = "keyUp", key = "Tab", code = "Tab",
                           windowsVirtualKeyCode = 9L, nativeVirtualKeyCode = 9L)
  Sys.sleep(0.05)
  if (isTRUE(b$Runtime$evaluate('document.activeElement.closest(".cc-boek") !== null')$result$value)) break
}
cat("focus landde op:", b$Runtime$evaluate('document.activeElement.textContent.trim()')$result$value,
    "na", i, "keer Tab\n")
b$Runtime$evaluate('document.activeElement.closest(".cc-plank").scrollIntoView({block: "center"})')
Sys.sleep(0.4)
r <- fromJSON(b$Runtime$evaluate(
  '(() => { const r = document.activeElement.closest(".cc-plank").getBoundingClientRect();
     return JSON.stringify({x: r.x + window.scrollX, y: r.y + window.scrollY,
                            w: r.width, h: r.height}); })()')$result$value)
b$screenshot(file.path(UIT, "boekvoet_focus.png"),
             cliprect = c(r$x - 40, r$y - 25, r$w + 80, r$h + 50))
cat("focus-schot klaar\n")
b$close()
