## OZP1 SPSS-speeldata — reproduceert exact de OEFEN-opgaven (T1.2/1.3, T2.2, T2.3, T7.2, T11.1).
## Hergebruikt waar mogelijk bestaande .sav's (egels.sav, leesvaardigheid.sav, egels_pienterheid.sav).
suppressMessages({library(haven); library(labelled)})
OUT <- "/Users/benjamintelkamp/Documents/Ben_OS/countcamp_lab/uni_leiden/pedagogiek/ozp1_werkboek/2526_werkboek/_common/data"

## ---- T1.2 / T1.3 : kraaien-verzameldrang (n=5) : 3,7,7,8,10 ----
## mean=7, s=2.55, KS=26. T1.3 = transform x_nieuw = 5*x.
kraaien <- data.frame(
  kraai        = 1:5,
  verzameldrang = c(3, 7, 7, 8, 10)
)
var_label(kraaien$kraai) <- "Kraai-nummer (ID)"
var_label(kraaien$verzameldrang) <- "Verzameldrang (schaal 0-20)"
write_sav(kraaien, file.path(OUT, "kraaien.sav"))

## ---- T2.2 : dassen-graaftijd (n=7) : 8,11,12,15,18,22,40 ----
## mediaan 15, Q1 11, Q3 22, IQR 11, das van 40 = uitbijter.
dassen <- data.frame(
  das       = 1:7,
  graaftijd = c(8, 11, 12, 15, 18, 22, 40)
)
var_label(dassen$das) <- "Das-nummer (ID)"
var_label(dassen$graaftijd) <- "Nachtelijke graaftijd (minuten)"
write_sav(dassen, file.path(OUT, "dassen.sav"))

## ---- T2.3 : uilen-waakzaamheid (n=5) : 4,6,7,8,10 ----
## mediaan 7, gemiddelde 7. (Opgave varieert dit met de hand; .sav = de basis-5.)
uilen <- data.frame(
  uil          = 1:5,
  waakzaamheid = c(4, 6, 7, 8, 10)
)
var_label(uilen$uil) <- "Uil-nummer (ID)"
var_label(uilen$waakzaamheid) <- "Nachtelijke waakzaamheid"
write_sav(uilen, file.path(OUT, "uilen.sav"))

## ---- T7.2 : pienterheid-steekproef (n=9), x-bar = 108, s = 15 ----
## Opgave gebruikt sigma BEKEND (z-CI). SPSS Explore geeft een t-CI met s uit de data.
## We zetten mean=108 EN s=15 exact, zodat de puntschatting (108) en SE-grondstof (15)
## kloppen; de student ziet dan dat het t-interval iets breder is dan het z-interval.
set.seed(72)
n7 <- 9
p7 <- rnorm(n7); p7 <- round((p7 - mean(p7))/sd(p7) * 15 + 108, 2)
pient9 <- data.frame(egel = 1:n7, pienterheid = p7)
var_label(pient9$egel) <- "Egel-nummer (ID)"
var_label(pient9$pienterheid) <- "Pienterheid (IQ-achtige schaal)"
write_sav(pient9, file.path(OUT, "egels_pienterheid_n9.sav"))

## ---- T11.1 : egel-hokvoorkeur GOF (n=100) : links 25, midden 50, rechts 25 ----
## Uitgeklapt (1 rij per egel) zodat Nonparametric Chi-Square direct werkt zonder weging.
hok <- data.frame(
  hok = c(rep(1, 25), rep(2, 50), rep(3, 25))
)
val_labels(hok$hok) <- c(links = 1, midden = 2, rechts = 3)
var_label(hok$hok) <- "Gekozen hok"
write_sav(hok, file.path(OUT, "egel_hok.sav"))

## ---- VERIFICATIE ----
cat("== T1.2/1.3 kraaien ==\n")
cat("  mean", mean(kraaien$verzameldrang), "s", round(sd(kraaien$verzameldrang),4),
    "KS", sum((kraaien$verzameldrang - mean(kraaien$verzameldrang))^2),
    "| x5: mean", 5*mean(kraaien$verzameldrang), "s", round(5*sd(kraaien$verzameldrang),4), "\n")
cat("== T2.2 dassen ==\n")
cat("  median", median(dassen$graaftijd),
    "Q1", quantile(dassen$graaftijd, .25, type=6),
    "Q3", quantile(dassen$graaftijd, .75, type=6),
    "mean", round(mean(dassen$graaftijd),2), "\n")
cat("== T2.3 uilen ==\n")
cat("  median", median(uilen$waakzaamheid), "mean", mean(uilen$waakzaamheid), "\n")
cat("== T7.2 pienterheid n=9 ==\n")
cat("  mean", round(mean(pient9$pienterheid),3), "sd", round(sd(pient9$pienterheid),4), "\n")
t9 <- t.test(pient9$pienterheid, mu = 100)
cat("  t-CI 95%:", round(t9$conf.int[1],2), "-", round(t9$conf.int[2],2),
    "| z-CI (opgave): 98,2 - 117,8\n")
cat("== T11.1 hok GOF ==\n")
print(table(hok$hok))
cs <- chisq.test(table(hok$hok))
cat("  chi2", round(cs$statistic,3), "df", cs$parameter, "p", round(cs$p.value,4), "\n")
