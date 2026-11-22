# Data voor thema 2 (rangtoetsen: Wilcoxon) van het oefenboek OZP 2.
#
# Draaien vanuit de boekmap:  Rscript _common/data/maak_data_t2.R
# Schrijft twee .sav-bestanden naast dit script. Het doorlopende voorbeeld van
# thema 2 gebruikt géén nieuwe data: dat zijn de dassen van thema 1
# (dassen_gepaard.sav en dassen_tussen.sav), zodat de lezer dezelfde vraag ziet
# met rangen in plaats van gemiddelden. De twee bestanden hier zijn voor de
# opgaven T2.3 en T2.4.
#
# Achterwaarts ontworpen (feedback_didactische_getallen): eerst wat de lezer
# moet tegenkomen (een nulverschil dat eruit moet, knopen, een beslissing die
# niet op de rand van alfa valt), dan kleine data met hele scores die dat geven.
# Gevonden met 02_rangtoetsen-zoekscript op 18-11-2026: willekeurige hele scores
# per seed, de eerste seed die aan alle eisen voldeed (kraaien seed 4, vossen
# seed 34). De stopifnot's hieronder zakken zodra een eis niet meer klopt.

suppressMessages(library(haven))
hier <- local({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "_common/data"
})

# Dezelfde rekenregels als het formuleblad (Eq. 49-52 en 45-48); alleen hier,
# om de eisen te toetsen. Het hoofdstuk rekent met _common/ozp2/t2_rang.R.
tabA <- function(z) round(pnorm(z), 4)
veilig <- function(z) abs(z * 100 - round(z * 100)) < 0.35

# ---- 1. t2_kraaien_nee.sav (opgave T2.3, rangtekentoets) --------------------
# Tien jonge kraaien, brutaliteit (vragenlijst van de ouders, 0-20) vóór en na
# de training "Nee is nee". Eisen: precies één paar met verschil 0 (dat moet
# eruit, dus n wordt 9); minstens één knoop in de absolute verschillen; de
# toets verwerpt niet, met een p die ruim van .05 af ligt; de medianen van vóór
# en na verschillen; en geen Z op een afrondgrens.
voor <- c(15, 18, 10, 10, 14, 10, 13, 12, 17, 10)
na   <- c(11, 16,  8,  8, 16,  6, 16, 12, 14, 11)
d    <- voor - na
dd   <- d[d != 0]; n_k <- length(dd); rk <- rank(abs(dd))
wp <- sum(rk[dd > 0]); wm <- sum(rk[dd < 0])
mu <- n_k * (n_k + 1) / 4; sg <- sqrt(n_k * (n_k + 1) * (2 * n_k + 1) / 24)
z  <- (wp - mu) / sg
p2 <- 2 * (1 - tabA(abs(round(z, 2))))
stopifnot(
  sum(d == 0) == 1, n_k == 9,
  max(table(abs(dd))) == 4,            # de knoop van vier (|2| komt vier keer voor)
  wp == 34, wm == 11, wp + wm == n_k * (n_k + 1) / 2,
  mu == 22.5, round(sg, 2) == 8.44,
  veilig(z), p2 > .15, p2 < .60,
  median(voor) != median(na)
)
kraaien <- data.frame(
  kraai = labelled(1:10, label = "Kraai"),
  voor  = labelled(voor, label = "Brutaliteit, voor de training"),
  na    = labelled(na, label = "Brutaliteit, na de training")
)
write_sav(kraaien, file.path(hier, "t2_kraaien_nee.sav"))

# ---- 2. t2_vossen_speelgroep.sav (opgave T2.4, rangsomtoets) ----------------
# Vijftien jonge vossen, score op de taak "samen delen" (0-40): zeven bleven
# thuis (groep 1), acht gingen naar een speelgroep (groep 2). Eisen: ongelijke
# groepen (dan hangt mu_W echt van n1 af); minstens twee knopen, ook één dwars
# door de groepen heen; de toets verwerpt, met een p ruim onder .05; de kleinste
# groep heeft ook de kleinste rangsom (dan is de W die SPSS drukt niet
# dubbelzinnig); en geen Z op een afrondgrens.
thuis <- c(10, 18, 19, 27, 17, 13, 20)
speel <- c(31, 27, 31, 18, 18, 32, 26, 35)
n1 <- length(thuis); n2 <- length(speel); N <- n1 + n2
rk <- rank(c(thuis, speel)); w1 <- sum(rk[1:n1]); w2 <- sum(rk[-(1:n1)])
mu <- n1 * (N + 1) / 2; sg <- sqrt(n1 * n2 * (N + 1) / 12)
z  <- (w1 - mu) / sg
p2 <- 2 * (1 - tabA(abs(round(z, 2))))
tie <- table(c(thuis, speel))
stopifnot(
  n1 == 7, n2 == 8, n1 < n2,
  sum(tie > 1) == 3, 18 %in% thuis, sum(speel == 18) == 2,   # de knoop 18 zit in beide groepen
  w1 == 36.5, w2 == 83.5, w1 + w2 == N * (N + 1) / 2, w1 < w2,
  mu == 56, round(sg, 2) == 8.64,
  veilig(z), p2 > .01, p2 < .04,
  median(thuis) < median(speel)
)
vossen <- data.frame(
  vos = labelled(1:15, label = "Vos"),
  groep = labelled(rep(1:2, c(n1, n2)), labels = c(thuis = 1, speelgroep = 2),
                   label = "Groep"),
  delen = labelled(c(thuis, speel), label = "Samen delen, score op de taak")
)
write_sav(vossen, file.path(hier, "t2_vossen_speelgroep.sav"))

cat("geschreven in", hier, ": t2_kraaien_nee.sav, t2_vossen_speelgroep.sav\n")
