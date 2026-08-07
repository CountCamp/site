# ============================================================
# genereer_verschilscore_mra.R — synthetische data bij het blok
# "Meervoudige regressie / multiple regression" (W8)
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (een groep jongeren,
# SDQ-totaalscore vlak voor en vlak na een VR-interventie, geen
# controlegroep) komt uit de opzet van een echt GGZ-onderzoek; de
# rijen zijn gegenereerd. Er is nooit clientdata aangeraakt.
#
# DIT COHORT IS HETZELFDE als in het t-toets-blok: de kolommen
# tds_t0/tds_t1 worden ingelezen uit sdq_toekomstkamer.csv, niet
# opnieuw getrokken. Een vio die W6 deed, ziet dezelfde 24 jongeren
# terug -- alleen nu met een andere vraag erop.
#
# Toegevoegd: leeftijd, geslacht (18 vrouw / 6 man) en diagnose
# (7 categorieen, n = 8/6/5/2/1/1/1). Die diagnose zit er met opzet
# in: het blok laat zien wat er gebeurt als je zes dummy's voor
# categorieen met n = 1 aan een model op 24 mensen toevoegt.
#
# Anker (echt gerapporteerd, Tabel 7 van de studie, N = 24):
#   verbetering ~ baseline_c + leeftijd_c + geslacht
#   F(3,20) = 1.55  p = .232  R2 = .19
#   baseline_c  b = 0.38  SE = 0.19  p = .055
#   leeftijd_c en geslacht niet significant
# Wat deze rijen geven (seed 756, hieronder nagerekend): F(3,20) = 1.58,
# p = .225, R2 = .192, baseline b = 0.377 SE = 0.194 p = .066. Het
# patroon is dus het patroon van het anker -- model als geheel niet
# significant, baseline randsignificant, R2 rond .19 -- met p iets
# hoger. AFWIJKING VAN HET ANKER, bewust: tds_t0/tds_t1 liggen al vast
# in het cohort, dus baseline en verbetering zijn niet meer vrij; alleen
# leeftijd, geslacht en diagnose zijn dat. De seed is gekozen op het
# patroon, niet op de derde decimaal.
#
# Twee dingen die vanzelf goed gaan en het vermelden waard zijn:
#   - b voor baseline komt op 0.38 uit zonder dat we daaraan gedraaid
#     hebben. Dat IS regressie naar het gemiddelde: wie hoog begint,
#     heeft meer ruimte om te dalen.
#   - in het overladen model (9 predictoren op 24 mensen) wordt juist
#     die baseline "significant" (p = .018) terwijl het model als geheel
#     niets verklaart (F(9,14) = 1.27, p = .330). Dat is de les van dit
#     blok, en hij komt uit de data, niet uit een verhaal.
#
# Draaien:  Rscript genereer_verschilscore_mra.R
# ============================================================
set.seed(756)

sdq <- read.csv("sdq_toekomstkamer.csv")
N <- nrow(sdq)

DIAGNOSES <- rep(
  c("depressief", "ASS", "PTSS", "ADHD",
    "vermijdende PS", "borderline PS", "sociale angst"),
  c(8, 6, 5, 2, 1, 1, 1)
)

leeftijd <- pmin(pmax(round(rnorm(N, 16.2, 1.8)), 14), 22)
geslacht <- sample(rep(c("vrouw", "man"), c(18, 6)))
diagnose <- sample(DIAGNOSES)

dat <- data.frame(
  id          = sdq$id,
  tds_t0      = sdq$tds_t0,
  tds_t1      = sdq$tds_t1,
  verbetering = sdq$tds_t0 - sdq$tds_t1,   # + = minder klachten na afloop
  leeftijd    = leeftijd,
  geslacht    = geslacht,
  diagnose    = diagnose
)

write.csv(dat, "verschilscore_mra.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk getal uit het blok na op deze rijen
# ============================================================
dat$baseline_c <- dat$tds_t0 - mean(dat$tds_t0)
dat$leeftijd_c <- dat$leeftijd - mean(dat$leeftijd)

m3 <- lm(verbetering ~ baseline_c + leeftijd_c + geslacht, data = dat)
m9 <- lm(verbetering ~ baseline_c + leeftijd_c + geslacht + diagnose, data = dat)
s3 <- summary(m3); s9 <- summary(m9)

regel <- function(s) sprintf("R2 = %.3f   adj R2 = %.3f   F(%d,%d) = %.2f   p = %.3f",
  s$r.squared, s$adj.r.squared, s$fstatistic[2], s$fstatistic[3], s$fstatistic[1],
  pf(s$fstatistic[1], s$fstatistic[2], s$fstatistic[3], lower.tail = FALSE))

cat("\n== cohort ==\n")
cat(sprintf("N = %d   verbetering: M = %.2f  SD = %.2f\n",
            N, mean(dat$verbetering), sd(dat$verbetering)))
cat(sprintf("baseline TDS: M = %.2f  SD = %.2f\n", mean(dat$tds_t0), sd(dat$tds_t0)))
cat(sprintf("leeftijd: M = %.2f  SD = %.2f  (%d-%d)\n",
            mean(dat$leeftijd), sd(dat$leeftijd), min(dat$leeftijd), max(dat$leeftijd)))
cat(sprintf("geslacht: %s\n", paste(names(table(dat$geslacht)), table(dat$geslacht), collapse = " / ")))

cat("\n== model 1 - drie predictoren ==\n")
print(round(coef(s3), 3)); cat(regel(s3), "\n")
cat("95% CI baseline_c: [", paste(sprintf("%.3f", confint(m3)["baseline_c", ]), collapse = ", "), "]\n")

cat("\n== model 2 - negen predictoren (diagnose erbij) ==\n")
print(round(coef(s9), 3)); cat(regel(s9), "\n")
cat("95% CI baseline_c: [", paste(sprintf("%.3f", confint(m9)["baseline_c", ]), collapse = ", "), "]\n")

cat("\n== enkelvoudig, ter vergelijking ==\n")
s1 <- summary(lm(verbetering ~ baseline_c, data = dat))
print(round(coef(s1), 3)); cat(regel(s1), "\n")
