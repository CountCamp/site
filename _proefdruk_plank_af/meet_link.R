# Ziet een kop zonder link eruit als een kapotte link?
#
# Michelle kon dit niet beoordelen: zij las de bron en niet de gerenderde
# bladzij. Haar zorg was concreet -- "als de kop dezelfde kleur heeft als
# een link maar niet klikt, dan klik ik erop, er gebeurt niets, en dan denk
# ik: stuk." Dus meet ik kleur, pijl, muisaanwijzer en onderstreping naast
# een kop die wel een link is.
library(chromote)
library(jsonlite)

blad <- normalizePath("_proefdruk_plank_af/proefblad.html")

for (vorm in c("rug", "kaart")) {
  b <- ChromoteSession$new(width = 1440, height = 1000)
  b$Page$navigate(paste0("file://", blad, "?vorm=", vorm))
  Sys.sleep(2.5)
  stopifnot(identical(b$Runtime$evaluate(
    'document.documentElement.getAttribute("data-vorm")')$result$value, vorm))

  tab <- fromJSON(b$Runtime$evaluate('JSON.stringify(
    Array.from(document.querySelectorAll(".cc-plank-groep .cc-boek")).map(el => {
      const h3 = el.querySelector("h3");
      const a  = h3.querySelector("a:not(.anchorjs-link)");
      const doel = a || h3;
      const cs = getComputedStyle(doel);
      const t = h3.textContent.replace(/\\s+/g, " ").trim();
      return {boek: t.slice(0, 30), is_link: a !== null,
              kleur: cs.color, aanwijzer: cs.cursor,
              pijl: t.indexOf("\\u2192") >= 0,
              streep: cs.textDecorationLine};
    }))')$result$value)

  cat(sprintf("\n=== vorm %s ===\n", vorm))
  print(tab, right = FALSE)
  b$close()
}
