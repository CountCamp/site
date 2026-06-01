## OZP1 SPSS-speeldata — drie .sav-bestanden die de werkboek-voorbeelden dekken.
suppressMessages({library(haven); library(labelled)})
set.seed(42)
OUT <- "/Users/benjamintelkamp/Documents/Ben_OS/countcamp_lab/uni_leiden/pedagogiek/ozp1_werkboek/2526_werkboek/_common/data"
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

## ---- 1. egels.sav : pienterheid (n=25, mean=106, sd=15) + leeftijd/lengte (r~.5, slope~1.5) ----
n <- 25
pient <- rnorm(n); pient <- round((pient - mean(pient))/sd(pient) * 15 + 106)   # ~mean 106, sd 15
leeftijd <- round(runif(n, 3, 22))                                              # maanden
lengte <- round(14 + 1.5 * leeftijd + rnorm(n, 0, 11), 1)                        # cm, slope ~1,5
egels <- data.frame(egel = 1:n, pienterheid = pient, leeftijd = leeftijd, lengte = lengte)
var_label(egels$egel)        <- "Egel-nummer (ID)"
var_label(egels$pienterheid) <- "Pienterheid (IQ-achtige schaal)"
var_label(egels$leeftijd)    <- "Leeftijd in maanden"
var_label(egels$lengte)      <- "Lengte in cm"
write_sav(egels, file.path(OUT, "egels.sav"))

## ---- 2. roken_geslacht.sav : 2x2 = 40/160 (man) en 20/180 (vrouw) ----
geslacht <- c(rep(1, 200), rep(2, 200))
rookt    <- c(rep(1, 40), rep(0, 160), rep(1, 20), rep(0, 180))
rk <- data.frame(geslacht = geslacht, rookt = rookt)
val_labels(rk$geslacht) <- c(man = 1, vrouw = 2)
val_labels(rk$rookt)    <- c("rookt niet" = 0, "rookt" = 1)
var_label(rk$geslacht)  <- "Geslacht"
var_label(rk$rookt)     <- "Rookt (ja/nee)"
write_sav(rk, file.path(OUT, "roken_geslacht.sav"))

## ---- 3. egel_pelskleur.sav : GOF 40 bruin / 30 grijs / 20 zwart (n=90) ----
pels <- data.frame(pelskleur = c(rep(1, 40), rep(2, 30), rep(3, 20)))
val_labels(pels$pelskleur) <- c(bruin = 1, grijs = 2, zwart = 3)
var_label(pels$pelskleur)  <- "Pelskleur van de egel"
write_sav(pels, file.path(OUT, "egel_pelskleur.sav"))

## controle
cat("egels.sav   : n =", nrow(egels), "| mean pient =", round(mean(egels$pienterheid),2),
    "sd =", round(sd(egels$pienterheid),2), "| cor(leeftijd,lengte) =", round(cor(egels$leeftijd, egels$lengte),2), "\n")
cat("roken       : man rookt", sum(rk$geslacht==1 & rk$rookt==1), "/ vrouw rookt", sum(rk$geslacht==2 & rk$rookt==1), "\n")
cat("pelskleur   : 40/30/20 ->", paste(table(pels$pelskleur), collapse="/"), "\n")
cat("geschreven naar:", OUT, "\n")
