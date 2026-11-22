# Data voor thema 8 (meervoudige regressie) van het oefenboek OZP 2: de
# uitvoer-opgave met drie voorspellers. Het doorlopende voorbeeld van thema 8
# (de uilen, met leeftijd als tweede voorspeller) staat in maak_data_t7.R.
#
# Draaien vanuit de boekmap:  Rscript _common/data/maak_data_t8.R

suppressMessages(library(haven))
hier <- local({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "_common/data"
})

# ---- t8_vossen_delen.sav (opgave T8.5, alleen uitvoer lezen) ----------------
# Veertig jonge vossen: hoe goed ze hun eten delen (score 0-20), voorspeld uit
# de uren per week in de speelgroep, het aantal nestgenoten en de leeftijd in
# weken. Eisen: speelgroep significant (p < .01), nestgenoten negatief en
# significant met .001 < p < .05, leeftijd niet significant (p > .15); de beta
# van speelgroep minstens .15 boven de tweede; alle VIF onder 2; R^2 tussen .35
# en .55; de F-toets p < .001. Geen ronde doelgetallen: dit is uitvoer om te
# lezen. Gevonden met 08_regressie_meervoudig/_werk/zoek_seed_vossen.R
# (18-11-2026): seeds 48, 58 en 64 voldoen, 48 is de eerste.
set.seed(48)
speelgroep  <- round(runif(40, 0, 10))
nestgenoten <- sample(0:6, 40, replace = TRUE)
leeftijd    <- sample(8:20, 40, replace = TRUE)
delen <- round(7 + 0.5 * speelgroep - 0.6 * nestgenoten + 0.05 * leeftijd + rnorm(40, 0, 3))
delen <- pmin(pmax(delen, 0), 20)
m <- lm(delen ~ speelgroep + nestgenoten + leeftijd)
co <- summary(m)$coefficients
beta <- co[2:4, 1] * apply(cbind(speelgroep, nestgenoten, leeftijd), 2, sd) / sd(delen)
stopifnot(
  co["speelgroep", 4] < .01,
  co["nestgenoten", 4] > .001, co["nestgenoten", 4] < .05, co["nestgenoten", 1] < 0,
  co["leeftijd", 4] > .15,
  abs(beta[1]) - sort(abs(beta), decreasing = TRUE)[2] >= .15,
  summary(m)$r.squared > .35, summary(m)$r.squared < .55,
  pf(summary(m)$fstatistic[1], 3, 36, lower.tail = FALSE) < .001
)
vossen <- data.frame(
  vos         = labelled(1:40, label = "Vos"),
  speelgroep  = labelled(speelgroep, label = "Speelgroep, uren per week"),
  nestgenoten = labelled(nestgenoten, label = "Aantal nestgenoten"),
  leeftijd    = labelled(leeftijd, label = "Leeftijd in weken"),
  delen       = labelled(delen, label = "Delen (0-20)")
)
write_sav(vossen, file.path(hier, "t8_vossen_delen.sav"))
cat("geschreven in", hier, ": t8_vossen_delen.sav\n")
