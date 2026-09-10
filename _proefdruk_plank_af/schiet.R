# Uitsnede van de sectie "Voor losse vakken" in beide vormen.
# Niet scrollen-en-hopen maar een cliprect om de sectie heen, berekend uit
# de bladzij zelf: van de eerste instellingskop tot onder de laatste plank.
library(chromote)
library(jsonlite)

blad <- normalizePath("_proefdruk_plank_af/proefblad.html")
dir.create("_proefdruk_plank_af/na", showWarnings = FALSE)

schiet <- function(vorm) {
  b <- ChromoteSession$new(width = 1440, height = 1000)
  b$Page$navigate(paste0("file://", blad, "?vorm=", vorm))
  Sys.sleep(2.5)
  gemeten <- b$Runtime$evaluate('document.documentElement.getAttribute("data-vorm")')$result$value
  stopifnot(identical(gemeten, vorm))

  # de bladzij helemaal hoog maken, dan is er niets meer te scrollen
  hoogte <- b$Runtime$evaluate('document.documentElement.scrollHeight')$result$value
  b$Emulation$setDeviceMetricsOverride(width = 1440L, height = as.integer(hoogte),
                                       deviceScaleFactor = 2, mobile = FALSE)
  Sys.sleep(1)

  vak <- fromJSON(b$Runtime$evaluate('JSON.stringify((() => {
    const eerste = document.querySelector(".cc-instelling").getBoundingClientRect();
    const planken = document.querySelectorAll(".cc-plank-groep");
    const laatste = planken[planken.length - 1].getBoundingClientRect();
    return {x: eerste.x, y: eerste.y + window.scrollY,
            w: eerste.width, h: (laatste.bottom + window.scrollY) - (eerste.y + window.scrollY)};
  })())')$result$value)

  b$screenshot(sprintf("_proefdruk_plank_af/na/losse_vakken_%s.png", vorm),
               cliprect = c(vak$x - 40, vak$y - 30, vak$w + 80, vak$h + 50))
  cat(sprintf("%s: uitsnede %.0f x %.0f px\n", vorm, vak$w + 80, vak$h + 50))
  b$close()
}

schiet("rug")
schiet("kaart")
