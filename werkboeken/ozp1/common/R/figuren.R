# Gedeelde figuur-stijl voor Werkboek OZP 1
# Eén bron voor alle ggplot-figuren; pas hier aan om de stijl overal te wijzigen.
# - echte assen (axis.line), lichte major-grid, geen minor-grid
# - pastel + kleurenblindvriendelijk (Ben is rood-groen kleurenblind → blauw/oranje, geen rood/groen)
suppressMessages(library(ggplot2))

# Kleuren — colorblind-safe (Okabe-Ito-achtig, pastel)
ozp <- list(
  blauw  = "#33558b",  # positief / hoofdkleur
  oranje = "#c07a2b",  # negatief / contrast
  grijs  = "#9a9a9a",  # neutraal / draagt niet bij
  donker = "#33425a",  # losse puntenwolk (één kleur)
  groen  = "#3d7a5a",
  paars  = "#6a5a9a",
  arcering = "#9fb3d1" # gearceerd staart-gebied normaalcurve
)

theme_ozp <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      axis.line        = element_line(colour = "grey35", linewidth = 0.45),
      axis.ticks       = element_line(colour = "grey35", linewidth = 0.45),
      axis.ticks.length = unit(3, "pt"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey92", linewidth = 0.3),
      legend.position  = "top",
      plot.margin      = margin(8, 12, 8, 8)
    )
}
