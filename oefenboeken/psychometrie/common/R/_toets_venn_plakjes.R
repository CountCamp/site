# _toets_venn_plakjes.R -- toetst _common/R/venn_plakjes.R, los van elk thema.
# Draai vanuit de wortel van het oefenboek: Rscript _common/R/_toets_venn_plakjes.R
# Afloopcode 0 = alles goed, 1 = een toets zakt.
#
# Vijf dingen die de helper belooft, en die elk een plaatje zouden laten liegen
# als ze niet waar waren:
#   1. elk getekend plakje heeft het oppervlak dat gevraagd werd
#   2. de buitencirkels raken elkaar niet
#   3. een setje dat niet past wordt GEWEIGERD, niet stilletjes verkeerd getekend
#   4. de helper verzet de toevalsstroom van zijn aanroeper niet
#   5. een plakje van nul tekent een cirkel die de doelcirkel net raakt
# Plus een bijtproef: met een opzettelijk verkeerde afstand moet toets 1 zakken,
# anders meet hij niets.

pad <- file.path("_common", "R", "venn_plakjes.R")
if (!file.exists(pad)) {
  cat("KAN NIET TOETSEN: ", pad, " staat er niet -- draai vanuit de wortel van het oefenboek\n", sep = "")
  quit(status = 3)
}
source(pad)

gezakt <- 0
toets <- function(naam, ok) {
  cat(if (isTRUE(ok)) "ok     " else "GEZAKT ", naam, "\n", sep = "")
  if (!isTRUE(ok)) gezakt <<- gezakt + 1
}

gevallen <- list(
  "een plakje (r^2 = .25)"              = c(Y = .25),
  "a3 uit thema 4 (varimax)"            = c(RC1 = .0466, RC2 = .0511, RC3 = .5347),
  "drie gelijke plakjes"                = c(A = .15, B = .15, C = .15),
  "ongeroteerd, u2 uit thema 4"         = c(PC1 = .405, PC2 = .249, PC3 = .052),
  "vier kleintjes"                      = c(A = .05, B = .08, C = .03, D = .10),
  # Bij gelijke afstanden raken B en C elkaar hier (gemeten: -0.13 straal); de
  # helper moet zelf een stand zoeken. Zo wordt ook die weg getoetst.
  "past alleen na zoeken"               = c(A = .40, B = .30, C = .01)
)
for (nm in names(gevallen)) {
  v <- venn_plakjes(gevallen[[nm]])
  toets(paste0("1. oppervlak klopt -- ", nm),
        max(abs(v$controle$gemeten - gevallen[[nm]])) < 1e-3)
  toets(paste0("2. buitencirkels raken elkaar niet -- ", nm),
        v$controle$ruimte >= 0.05 - 1e-9)
}

# 3. Twee plakjes van .45: elk vraagt een buitencirkel die bijna over het midden
#    valt, dus ze raken elkaar altijd. Moet een fout geven, geen plaatje.
weigert <- tryCatch({ venn_plakjes(c(A = .45, B = .45)); FALSE },
                    error = function(e) grepl("passen niet", conditionMessage(e)))
toets("3. een setje dat niet past wordt geweigerd", weigert)

# 4. De toevalsstroom. Draai een geval dat de zoektocht nodig heeft (zie
#    "past alleen na zoeken" hierboven) en een dat hem niet nodig heeft, en kijk
#    of het volgende toevalsgetal gelijk blijft.
set.seed(2026); verwacht <- runif(1)
set.seed(2026)
invisible(venn_plakjes(c(A = .40, B = .30, C = .01)))
invisible(venn_plakjes(c(A = .30, B = .20, C = .12)))
gekregen <- runif(1)
toets("4. de toevalsstroom van de aanroeper blijft staan", identical(verwacht, gekregen))

# 5. Een plakje van nul.
v0 <- venn_plakjes(c(A = .5, B = 0, C = .05))
toets("5. een plakje van nul raakt de doelcirkel net",
      abs(v0$cirkels$afstand[v0$cirkels$naam == "B"] - 2 * v0$straal) < 1e-12 &&
        v0$controle$gemeten[["B"]] == 0)

# Bijtproef op toets 1: verschuif één buitencirkel een fractie en meet opnieuw
# met dezelfde schoenveterformule. Een toets die dit niet ziet, ziet niets.
v <- venn_plakjes(c(RC1 = .0466, RC2 = .0511, RC3 = .5347))
r <- v$straal
fout_d <- v$cirkels$afstand[v$cirkels$naam == "RC3"] * 1.05
a <- acos(fout_d / (2 * r)); h <- v$cirkels$hoek[v$cirkels$naam == "RC3"] * pi / 180
h1 <- seq(h - a, h + a, length.out = 180); h2 <- seq(h + pi - a, h + pi + a, length.out = 180)
p <- data.frame(x = c(r * cos(h1), fout_d * cos(h) + r * cos(h2)),
                y = c(r * sin(h1), fout_d * sin(h) + r * sin(h2)))
fout_opp <- abs(sum(p$x * c(p$y[-1], p$y[1]) - c(p$x[-1], p$x[1]) * p$y)) / 2
toets("bijtproef: 5% te ver weg geeft een plakje dat toets 1 laat zakken",
      abs(fout_opp - .5347) >= 1e-3)

cat("\n", gezakt, " toets(en) gezakt.\n", sep = "")
quit(status = if (gezakt > 0) 1 else 0)
