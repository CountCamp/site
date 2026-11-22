# Data voor thema 6 (meerweg-ANOVA) van het oefenboek OZP 2.
#
# Draaien vanuit de boekmap:  Rscript _common/data/maak_data_t6.R
# Schrijft twee .sav-bestanden naast dit script. Het hoofdstuk leest dié
# bestanden in en rekent er alles uit; niets wordt overgetikt.
#
# Achterwaarts ontworpen (feedback_didactische_getallen, zoals maak_data_t1.R):
# eerst de doelgetallen die de lezer zelf narekent, dan kleine data met hele
# scores die er precies op uitkomen. De stopifnot's zakken zodra een doelgetal
# niet meer klopt.

suppressMessages(library(haven))
hier <- local({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "_common/data"
})

# ---- 1. otters_zwemles.sav (de rode draad: een 2 x 2) ---------------------------
# Twintig jonge otters, vijf per cel. Factor A = water (kalm meertje / snelle
# beek), factor B = zwemles (geen / wel). Uitkomst: visjes gevangen in een uur.
#
# Doelen (celgemiddelden):          geen les   wel les
#                        kalm         12         14      -> rand 13
#                        beek          4         10      -> rand  7
#                        rand          8         12      -> totaal 10
#
# Zo is het "verschil in verschil" precies 4: zwemles levert in de beek
# 10 - 4 = 6 visjes op en in het meertje 14 - 12 = 2, en 6 - 2 = 4. Vanaf de
# andere kant hetzelfde: (10 - 14) - (4 - 12) = 4. De kwadratensommen komen
# dan rond uit: SSA = 180, SSB = 80, SSAB = 20 (= n * 4^2 / 4), en de spreiding
# binnen de cellen is zo gekozen dat SSE = 40 (MSE = 2.5): twee cellen met een
# kwadratensom van 8, twee met 12. Dan is F_AB = 20 / 2.5 = 8.00, en dat ligt bij
# df = (1, 16) ruim tussen de kolommen .025 (6.12) en .010 (8.53) van Tabel E:
# .010 < p < .025, exact p = .012. Geen enkele F valt op de rand van een
# tabelkolom (zie de stopifnot's in het hoofdstuk).
kalm_geen <- c(10, 12, 12, 12, 14)   # afwijkingen -2 0 0 0 2  -> SS 8
kalm_les  <- c(12, 13, 15, 15, 15)   # afwijkingen -2 -1 1 1 1 -> SS 8
beek_geen <- c(1, 4, 5, 5, 5)        # afwijkingen -3 0 1 1 1  -> SS 12
beek_les  <- c(9, 9, 9, 10, 13)      # afwijkingen -1 -1 -1 0 3 -> SS 12
stopifnot(
  mean(kalm_geen) == 12, mean(kalm_les) == 14, mean(beek_geen) == 4, mean(beek_les) == 10,
  sum((kalm_geen - 12)^2) == 8, sum((kalm_les - 14)^2) == 8,
  sum((beek_geen - 4)^2) == 12, sum((beek_les - 10)^2) == 12,
  all(c(kalm_geen, kalm_les, beek_geen, beek_les) >= 0)
)
otters <- data.frame(
  otter   = labelled(1:20, label = "Otter"),
  water   = labelled(rep(1:2, each = 10), labels = c(kalm = 1, beek = 2),
                     label = "Water: kalm meertje of snelle beek"),
  zwemles = labelled(rep(rep(1:2, each = 5), 2), labels = c(geen = 1, wel = 2),
                     label = "Zwemles gehad"),
  visjes  = labelled(c(kalm_geen, kalm_les, beek_geen, beek_les),
                     label = "Visjes gevangen in een uur")
)
write_sav(otters, file.path(hier, "otters_zwemles.sav"))

# ---- 2. eekhoorns_winterles.sav (opgave T6.5: uitvoer lezen, een 2 x 3) ----------
# Zesendertig jonge eekhoorns, zes per cel. Factor A = boom (eik / beuk / den),
# factor B = winterles (geen / wel). Uitkomst: noten verstopt op een dag.
# Het patroon is dat van Bens eigen STAT3-aantekening (Bib:
# diagram-interactie-wel-niet-celtabellen-plots, rijen 30 40 30 / 20 10 20):
# de boom heeft (bijna) geen hoofdeffect, de les wel, en de interactie is groot.
# De bijna: de kolomranden zijn 25.5, 26.0 en 25.0 en niet alle drie 25, want
# F = .000 en Sig. = 1.000 in de uitvoer leest als een drukfout. Geen ronde
# doelgetallen verder: dit is uitvoer om te lezen, niet om na te rekenen.
# Gevonden met set.seed(6) en willekeurig trekken tot de celgemiddelden klopten
# en geen F op de rand van een tabelkolom lag.
cel_mu <- c(eik_wel = 30, beuk_wel = 41, den_wel = 31, eik_geen = 21, beuk_geen = 11, den_geen = 19)
set.seed(6)
trek <- function(mu) {
  # zes hele scores met precies gemiddelde mu en een spreiding rond 3
  repeat {
    x <- round(rnorm(6, mu, 3))
    if (mean(x) == mu && sd(x) > 2 && sd(x) < 4.5 && all(x >= 0)) return(x)
  }
}
cellen <- lapply(cel_mu, trek)
stopifnot(all(vapply(cellen, mean, 1) == cel_mu))
eekhoorns <- data.frame(
  eekhoorn  = labelled(1:36, label = "Eekhoorn"),
  boom      = labelled(rep(rep(1:3, each = 6), 2), labels = c(eik = 1, beuk = 2, den = 3),
                       label = "Boomsoort in het territorium"),
  winterles = labelled(rep(2:1, each = 18), labels = c(geen = 1, wel = 2),
                       label = "Winterles gehad"),
  noten     = labelled(unlist(cellen, use.names = FALSE), label = "Noten verstopt op een dag")
)
write_sav(eekhoorns, file.path(hier, "eekhoorns_winterles.sav"))

cat("geschreven in", hier, ": otters_zwemles.sav, eekhoorns_winterles.sav\n")
