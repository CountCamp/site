# Data voor thema 1 (t-toetsen) van het oefenboek OZP 2.
#
# Draaien vanuit de boekmap:  Rscript _common/data/maak_data_t1.R
# Schrijft drie .sav-bestanden naast dit script. Het hoofdstuk leest dié
# bestanden in en rekent er alles uit; niets wordt overgetikt.
#
# Achterwaarts ontworpen (feedback_didactische_getallen, update 29-10-2026):
# eerst de doelgetallen die de lezer zelf narekent, dan kleine data met hele
# scores die er precies op uitkomen. De stopifnot's hieronder zakken zodra een
# doelgetal niet meer klopt.

suppressMessages(library(haven))
hier <- local({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "_common/data"
})

# ---- 1. dassen_gepaard.sav ------------------------------------------------
# Acht jonge dassen, hoe vaak per week ze 's avonds nog uit het hol sluipen,
# vóór en na de cursus van hun ouders. Verschil = voor - na (positief = minder
# vaak). Doelen: gemiddeld verschil 3, SD van de verschillen 2 (dus met de hand
# te doen), beide metingen even veel spreiding (SD = wortel 8 = 2,83) en een
# correlatie van precies .75 tussen voor en na. Bij die correlatie geeft de
# effectgrootte van het formuleblad 1,06 en die van SPSS 1,50: het verschil
# tussen die twee is een lesdoel. Bij r = .5 zouden ze samenvallen.
# Gevonden door alle 5040 toewijzingen van de verschillen aan de dassen af te
# lopen (18-11-2026); 438 voldeden, dit is de eerste met één das die erger werd.
voor <- c(12, 9, 5, 11, 8, 12, 5, 10)
na   <- c(10, 7, 6, 6, 3, 8, 1, 7)
d    <- voor - na
stopifnot(
  mean(voor) == 9, mean(na) == 6,
  mean(d) == 3, sd(d) == 2,
  abs(sd(voor) - sqrt(8)) < 1e-12, abs(sd(na) - sqrt(8)) < 1e-12,
  abs(cor(voor, na) - .75) < 1e-12,
  sum(d < 0) == 1
)
gepaard <- data.frame(
  das  = labelled(1:8, label = "Das"),
  voor = labelled(voor, label = "Uitsluipen per week, voor de cursus"),
  na   = labelled(na, label = "Uitsluipen per week, na de cursus")
)
write_sav(gepaard, file.path(hier, "dassen_gepaard.sav"))

# ---- 2. dassen_tussen.sav -------------------------------------------------
# Dezelfde vraag, maar opgezet met ANDERE dassen: negen in de cursus, elf op
# de wachtlijst. Zelfde verschil in gemiddelde (9 - 6 = 3), nu tussen twee
# groepen. Doelen: cursus M = 6, SD = 3; wachtlijst M = 9, SD = 4. Met hele
# scores kan een SD van 3 bij n = 8 niet (de kwadratensom moet even zijn en
# 7 x 9 = 63 is oneven), vandaar n = 9 voor de cursus. En elf op de wachtlijst,
# niet tien: bij tien komt de t van het formuleblad op 1,8605 en de tabel
# (df = 8, kolom .05) op 1,860 -- op twee decimalen niet uit elkaar te houden.
# Bij elf wordt het 1,915, duidelijk tussen twee kolommen (zie de stopifnot).
# Beide gevonden met set.seed(18112026) en willekeurig trekken tot het precies
# klopte.
cursus     <- c(9, 8, 1, 5, 10, 6, 6, 7, 2)
wachtlijst <- c(9, 11, 7, 15, 9, 4, 4, 11, 7, 16, 6)
stopifnot(
  mean(cursus) == 6, sd(cursus) == 3,
  mean(wachtlijst) == 9, sd(wachtlijst) == 4,
  # de t van het formuleblad ligt ruim tussen de kolommen .05 en .025 (df = 8)
  local({ t <- 3 / sqrt(3^2 / 9 + 4^2 / 11)
          t - qt(.95, 8) > .03 && qt(.975, 8) - t > .03 })
)
tussen <- data.frame(
  das = labelled(1:20, label = "Das"),
  groep = labelled(rep(1:2, c(9, 11)), labels = c(cursus = 1, wachtlijst = 2),
                   label = "Groep"),
  uitsluipen = labelled(c(cursus, wachtlijst), label = "Uitsluipen per week, na afloop")
)
write_sav(tussen, file.path(hier, "dassen_tussen.sav"))

# ---- 3. uilen_knuffel.sav (opgave T1.5) --------------------------------------
# Veertien jonge uilen mét en zestien zónder een knuffel in het nest; hoe vaak
# per week ze 's nachts angstig roepen. Hier moet Levene significant zijn, zodat
# de lezer de onderste rij leest, en de twee rijen moeten in hun conclusie
# overeenkomen. Geen ronde doelgetallen: dit is uitvoer om te lezen, niet om
# na te rekenen. Gevonden door seeds 1 tot 4000 af te lopen; seed 200 was de
# eerste met Levene p < .01, beide rijen p < .05, en een tabelvergelijking
# (df = 13) die niet op de rand van een kolom valt.
set.seed(200)
knuffel <- round(rnorm(14, 12, 2))
zonder  <- round(rnorm(16, 16.5, 6))
stopifnot(mean(knuffel) == 12, mean(zonder) == 16)
uilen <- data.frame(
  uil = labelled(1:30, label = "Uil"),
  knuffel = labelled(rep(1:2, c(14, 16)), labels = c(met = 1, zonder = 2),
                     label = "Knuffel in het nest"),
  roepen = labelled(c(knuffel, zonder), label = "Angstig roepen per week")
)
write_sav(uilen, file.path(hier, "uilen_knuffel.sav"))

cat("geschreven in", hier, ": dassen_gepaard.sav, dassen_tussen.sav, uilen_knuffel.sav\n")
