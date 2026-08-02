# genereer_penguins.R — échte data, geen synthese.
# Palmer Penguins (Gorman, Williams & Fraser 2014, Palmer Station LTER,
# Antarctica), via het R-pakket palmerpenguins (CC0). Dit script is geen
# generator maar een EXPORT: het schrijft een schone subset naar CSV zodat
# zowel R als JASP dezelfde échte rijen inleest. Geen seed nodig — de data
# ligt vast; elk getal in het blok is hierop nagerekend.
#
# Gedeeld door het R- en het JASP-broertje.

suppressMessages(library(palmerpenguins))

# complete metingen; sekse mag ontbreken (niet elk blok gebruikt 'm).
metingen <- c("bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g")
d <- penguins[complete.cases(penguins[, metingen]), ]

d <- data.frame(
  id            = seq_len(nrow(d)),
  soort         = as.character(d$species),
  sekse         = as.character(d$sex),
  snavellengte  = d$bill_length_mm,      # mm
  snaveldiepte  = d$bill_depth_mm,       # mm
  vinlengte     = d$flipper_length_mm,   # mm
  gewicht       = d$body_mass_g          # gram
)

out <- "penguins.csv"
write.csv(d, out, row.names = FALSE)
cat(sprintf("%d pinguins weggeschreven naar %s\n", nrow(d), out))
