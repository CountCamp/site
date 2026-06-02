## OZP1 SPSS-speeldata — reproduceert exact de werkboek-voorbeelden.
suppressMessages({library(haven); library(labelled)})
set.seed(42)
OUT <- "/Users/benjamintelkamp/Documents/Ben_OS/countcamp_lab/uni_leiden/pedagogiek/ozp1_werkboek/2526_werkboek/_common/data"
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

## 1. egels.sav : doorlopend groepje (n=9). Exact T1 (lengte) + T5/T6 (leeftijd/lengte).
egels <- data.frame(
  egel     = 1:9,
  leeftijd = c(2, 2, 3, 3, 4, 5, 5, 6, 6),
  lengte   = c(11, 20, 14, 23, 20, 26, 29, 17, 20)
)
var_label(egels$egel) <- "Egel-nummer (ID)"
var_label(egels$leeftijd) <- "Leeftijd in maanden"
var_label(egels$lengte) <- "Lengte in cm"
write_sav(egels, file.path(OUT, "egels.sav"))

## 2. egels_pienterheid.sav : steekproef (n=25, mean=106, sd=15). T3/T7/T9.
n <- 25
pient <- rnorm(n); pient <- round((pient - mean(pient))/sd(pient) * 15 + 106)
steek <- data.frame(egel = 1:n, pienterheid = pient)
var_label(steek$egel) <- "Egel-nummer (ID)"
var_label(steek$pienterheid) <- "Pienterheid (IQ-achtige schaal)"
write_sav(steek, file.path(OUT, "egels_pienterheid.sav"))

## 3. roken_geslacht.sav : 2x2. T11.
rk <- data.frame(geslacht = c(rep(1,200), rep(2,200)),
                 rookt    = c(rep(1,40), rep(0,160), rep(1,20), rep(0,180)))
val_labels(rk$geslacht) <- c(man = 1, vrouw = 2)
val_labels(rk$rookt) <- c("rookt niet" = 0, "rookt" = 1)
var_label(rk$geslacht) <- "Geslacht"; var_label(rk$rookt) <- "Rookt (ja/nee)"
write_sav(rk, file.path(OUT, "roken_geslacht.sav"))

## 4. egel_pelskleur.sav : GOF (n=90). T11.
pels <- data.frame(pelskleur = c(rep(1,40), rep(2,30), rep(3,20)))
val_labels(pels$pelskleur) <- c(bruin = 1, grijs = 2, zwart = 3)
var_label(pels$pelskleur) <- "Pelskleur van de egel"
write_sav(pels, file.path(OUT, "egel_pelskleur.sav"))

cat("egels(n=9): mean lengte", mean(egels$lengte), "s", round(sd(egels$lengte),2),
    "| mean leeftijd", mean(egels$leeftijd), "cor", round(cor(egels$leeftijd, egels$lengte),2), "\n")
cat("pienterheid(n=25): mean", round(mean(steek$pienterheid),1), "sd", round(sd(steek$pienterheid),2), "\n")
