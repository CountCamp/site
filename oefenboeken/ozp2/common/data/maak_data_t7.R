# Data voor thema 7 (correlatie en enkelvoudige regressie) en thema 8
# (meervoudige regressie) van het oefenboek OZP 2.
#
# Draaien vanuit de boekmap:  Rscript _common/data/maak_data_t7.R
# Schrijft twee .sav-bestanden naast dit script. De hoofdstukken lezen dié
# bestanden in en rekenen er alles uit; niets wordt overgetikt.
#
# Achterwaarts ontworpen (feedback_didactische_getallen): eerst de doelgetallen
# die de lezer zelf narekent, dan kleine data met hele scores die er precies op
# uitkomen. De stopifnot's hieronder zakken zodra een doelgetal niet meer klopt.

suppressMessages(library(haven))
hier <- local({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "_common/data"
})

# ---- 1. t7_uilen_woorden.sav -------------------------------------------------
# Tien jonge uilen. Per uil: hoeveel verhalen de ouders per week voorlezen
# (1 tot 5, elke waarde twee keer), hoeveel woorden het kuiken kent, en zijn
# leeftijd in weken. Doelen voor thema 7 (woorden op voorlezen): gemiddelden 3
# en 40, SS_x = 20, SS_xy = 80, dus b1 = 4 en b0 = 28; SST = 500 = 320 + 180,
# dus R^2 = .64 en r = .80; s = sqrt(22.5), SE van b1 = 1.0607, t(8) = 3.771 --
# ruim tussen de kolommen .005 en .0025 van Tabel D. De residuen zijn per
# voorleeswaarde +a en -a (a = 2, 5, 3, 6, 4), zodat ze optellen tot nul en
# loodrecht op x staan; SSE = 2 * (4 + 25 + 9 + 36 + 16) = 180.
# Doelen voor thema 8 (leeftijd erbij): gemiddelde leeftijd 8, r(voorlezen,
# leeftijd) = .60, R^2 = .883 en dus Delta R^2 = .243; b1 krimpt van 4.00 naar
# 2.17, b2 = 1.67, beide significant bij df = 7, en beta(leeftijd) > beta(voorlezen).
# Binnen elk voorleespaar is de oudere uil de uil met het positieve residu, zodat
# leeftijd precies verklaart wat voorlezen liet liggen. Gezocht met
# 07_regressie_enkelvoudig/_werk/zoek_data.R (18-11-2026): 4 kandidaten; deze
# is de enige met een heel gemiddelde.
voorlezen <- c(1, 1, 2, 2, 3, 3, 4, 4, 5, 5)
woorden   <- c(34, 30, 41, 31, 43, 37, 50, 38, 52, 44)
leeftijd  <- c(9, 4, 7, 4, 10, 8, 11, 6, 12, 9)
m1 <- lm(woorden ~ voorlezen)
m2 <- lm(woorden ~ voorlezen + leeftijd)
stopifnot(
  mean(voorlezen) == 3, mean(woorden) == 40, mean(leeftijd) == 8,
  sum((voorlezen - 3)^2) == 20, sum((voorlezen - 3) * (woorden - 40)) == 80,
  sum((woorden - 40)^2) == 500,
  abs(coef(m1)[["voorlezen"]] - 4) < 1e-12, abs(coef(m1)[["(Intercept)"]] - 28) < 1e-12,
  abs(sum(resid(m1)^2) - 180) < 1e-9, abs(cor(voorlezen, woorden) - .8) < 1e-12,
  abs(summary(m1)$coefficients["voorlezen", "t value"] - 3.771) < 5e-4,
  abs(cor(voorlezen, leeftijd) - .5966) < 5e-4,
  abs(summary(m2)$r.squared - .8833) < 5e-4,
  abs(coef(m2)[["voorlezen"]] - 13 / 6) < 1e-9, abs(coef(m2)[["leeftijd"]] - 5 / 3) < 1e-9,
  all(summary(m2)$coefficients[2:3, "Pr(>|t|)"] < .05),
  # de oudere uil van elk paar is de uil boven de lijn
  all(leeftijd[c(1, 3, 5, 7, 9)] > leeftijd[c(2, 4, 6, 8, 10)]),
  all(resid(m1)[c(1, 3, 5, 7, 9)] > 0)
)
uilen <- data.frame(
  uil       = labelled(1:10, label = "Uil"),
  voorlezen = labelled(voorlezen, label = "Voorgelezen verhalen per week"),
  woorden   = labelled(woorden, label = "Woordenschat (aantal woorden)"),
  leeftijd  = labelled(leeftijd, label = "Leeftijd in weken")
)
write_sav(uilen, file.path(hier, "t7_uilen_woorden.sav"))

# ---- 2. t7_egels_tobben.sav (opgave T7.6, alleen uitvoer lezen) ----------------
# Vierentwintig jonge egels: uren buitenspelen per dag en hoe tobberig ze zijn
# (een score van 0 tot 40 die de ouders invullen). Hier moet de helling
# negatief en significant zijn, met een p tussen .001 en .05, een R^2 tussen
# .20 en .45, en een t die niet op de rand van een kolom van Tabel D valt. Geen
# ronde doelgetallen: dit is uitvoer om te lezen, niet om na te rekenen.
# Gevonden door seeds 1 tot 5000 af te lopen (07_regressie_enkelvoudig/_werk/
# zoek_seed_egels.R): seed 5 was de eerste die voldeed, maar gaf |t| = 3.771 --
# precies het getal van de uilen hierboven, en een p van .00105, op de rand.
# Seed 6 is de eerstvolgende: t(22) = -3.39, p = .003, R^2 = .34.
set.seed(6)
buiten <- round(runif(24, 0.5, 4.5), 1)
tobben <- round(28 - 2.4 * buiten + rnorm(24, 0, 4))
tobben <- pmin(pmax(tobben, 0), 40)
me <- lm(tobben ~ buiten)
se_me <- summary(me)$coefficients
stopifnot(
  se_me["buiten", "Estimate"] < 0,
  se_me["buiten", "Pr(>|t|)"] > .001, se_me["buiten", "Pr(>|t|)"] < .05,
  summary(me)$r.squared > .20, summary(me)$r.squared < .45,
  # niet op de rand van een kolom van Tabel D (df = 22)
  min(abs(abs(se_me["buiten", "t value"]) -
          qt(1 - c(.25, .20, .15, .10, .05, .025, .02, .01, .005, .0025, .001, .0005), 22))) > .02
)
egels <- data.frame(
  egel   = labelled(1:24, label = "Egel"),
  buiten = labelled(buiten, label = "Buitenspelen, uren per dag"),
  tobben = labelled(tobben, label = "Tobberigheid (0-40)")
)
write_sav(egels, file.path(hier, "t7_egels_tobben.sav"))

cat("geschreven in", hier, ": t7_uilen_woorden.sav, t7_egels_tobben.sav\n")
