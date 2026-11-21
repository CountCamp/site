## OZP1 SPSS-speeldata — reproduceert exact de OEFEN-opgaven (T1.2/1.3, T2.2, T2.3, T7.2, T11.1).
## Hergebruikt waar mogelijk bestaande .sav's (egels.sav, leesvaardigheid.sav, egels_pienterheid.sav).
suppressMessages({library(haven); library(labelled)})
## OUT stond hier tot 28-9-2026 als een vast pad onder /Users/benjamintelkamp/, en dat
## bestaat op broodje niet — het script kon daar dus helemaal niet draaien. Nu: de map
## waarin dit script zelf staat, met een omweg te overschrijven voor een proefrun.
##   Rscript maak_sav_opgaven.R            -> schrijft naast dit script
##   OZP1_DATA_UIT=/tmp/x Rscript ...      -> schrijft daar
OUT <- Sys.getenv("OZP1_DATA_UIT", unset = NA)
if (is.na(OUT)) {
  arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  OUT <- if (length(arg)) dirname(normalizePath(sub("^--file=", "", arg[1]))) else getwd()
}
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
cat("schrijft naar:", OUT, "\n")

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

## ---- T11.1 : egel-kruistabel (n=120) : woonplek x voerbakje ----
## 2x2: dorp/bos tegen wel/niet uit een voerbakje gegeten.
##        at uit bakje   at niet   rij
##   dorp      16           24      40
##   bos       14           66      80
##   kolom     30           90     120
## Alle vier de verwachte aantallen zijn heel (10 / 30 / 20 / 60) en elke
## celbijdrage komt op één decimaal uit, dus chi2 = 7,20 exact en de som van de
## afgeronde bijdragen is hetzelfde getal. Uitgeklapt (1 rij per egel), dus
## Crosstabs werkt zonder Data -> Weight Cases.
## Verving op 28-9-2026 egel_hok.sav (100 egels, drie hokken, goodness-of-fit).
## Reden: Leiden toetst chi-kwadraat alleen als kruistabel, en die opgave had
## E = 100/3 en dus een afrondingsval. Dat bestand is die dag verwijderd; niets
## in het werkboek verwees er nog naar.
vb <- data.frame(
  woonplek  = c(rep(1, 40),  rep(2, 80)),
  voerbakje = c(rep(1, 16), rep(0, 24),  rep(1, 14), rep(0, 66))
)
val_labels(vb$woonplek)  <- c(dorp = 1, bos = 2)
val_labels(vb$voerbakje) <- c("at niet uit een bakje" = 0, "at uit een bakje" = 1)
var_label(vb$woonplek)  <- "Waar de egel gevangen is"
var_label(vb$voerbakje) <- "At weleens uit een voerbakje"
write_sav(vb, file.path(OUT, "egel_voerbakje.sav"))

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
cat("== T11.1 kruistabel woonplek x voerbakje ==\n")
tb <- table(woonplek = vb$woonplek, voerbakje = vb$voerbakje)
print(addmargins(tb))
E <- outer(rowSums(tb), colSums(tb)) / sum(tb)
cat("  E:", E, "(alle heel:", all(E == round(E)), ")\n")
cs <- chisq.test(tb, correct = FALSE)
cat("  chi2", round(cs$statistic, 3), "df", cs$parameter, "p", round(cs$p.value, 5), "\n")
cat("  bijdragen:", (tb - E)^2 / E, "| som van de AFGERONDE bijdragen:",
    sum(round((tb - E)^2 / E, 2)), "\n")
## De .sav moet exact de tabel uit het werkboek geven — anders leest de student
## in SPSS iets anders dan in zijn eigen uitwerking.
stopifnot(identical(as.vector(tb), c(24L, 66L, 16L, 14L)),   # kolom 0 dan kolom 1
          all(E == round(E)),
          abs(cs$statistic - 7.2) < 1e-9,
          abs(sum(round((tb - E)^2 / E, 2)) - 7.2) < 1e-9)
cat("  OK — de .sav reproduceert T11.1\n")
