# ============================================================
# genereer_tempo_meting.R — synthetische data bij het blok
# "De steekproevenverdeling en de standaardfout (SE)" (W3),
# met een non-respons-les erbij
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design is GEINSPIREERD op een
# echte RCT-opzet (TEMPO, EMDR vs. wachtlijst; baseline N = 159, met
# de OQ-45 klachtenmaat, 0-180 hoger = meer klachten). De STRUCTUUR
# is echt; de rijen en de non-respons-twist zijn DIDACTISCH gekozen
# en expliciet fictief — deze dataset reproduceert GEEN gerapporteerd
# resultaat uit dat onderzoek. Er is nooit clientdata aangeraakt.
#
# DOEL VAN HET BLOK:
#  (1) steekproevenverdeling / SE: een grotere N (159), een continue
#      uitkomst met een M en SD, en de standaardfout SE = SD / sqrt(N)
#      als maat voor hoe precies het gemiddelde geschat is.
#  (2) non-respons: niet iedereen levert de nameting in. De
#      non-responders zitten hier SYSTEMATISCH hoger (meer klachten
#      = eerder afgehaakt). Wie alleen naar de responders kijkt,
#      onderschat het gemiddelde klachtenniveau -> selectiebias.
#
# GEREALISEERDE KENGETALLEN (uit deze rijen, zie controle onderaan):
#   N = 159
#   oq45_score : OQ-45 baseline, plausibel bereik ~30-150
#     hele groep   M ~ 88, SD ~ 20  ->  SE = SD / sqrt(159)
#   respons (ja/nee) : ~70% ja
#     responders liggen LAGER, non-responders HOGER op oq45_score
#
# Werkwijze: trek de OQ-45 rond het beoogde gemiddelde; laat de kans
# op respons dalen naarmate de score hoger is (logistisch), zodat
# non-respons met klachtenniveau samenhangt. Alle getallen in de
# controle zijn uit de rijen berekend, niet overgetikt.
#
# Draaien:  Rscript genereer_tempo_meting.R
# ============================================================
set.seed(15909)

N <- 159

# OQ-45 baseline: continu, herschaald naar exact M en SD, dan afgerond
z  <- rnorm(N); z <- (z - mean(z)) / sd(z)
oq45_score <- round(88 + 20 * z)
oq45_score <- pmin(pmax(oq45_score, 20), 160)   # binnen 0-180, plausibel bereik

# respons: kans daalt met hogere klachtenscore (non-respons hangt samen
# met klachtenniveau -> systematische selectie, geen toeval)
lin  <- 3.6 - 0.030 * oq45_score          # hogere score -> lagere logit
pkans <- 1 / (1 + exp(-lin))
respons <- ifelse(runif(N) < pkans, "ja", "nee")

tempo <- data.frame(
  id         = sprintf("t%03d", 1:N),
  oq45_score = oq45_score,
  respons    = respons
)

write.csv(tempo, "tempo_meting.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk kengetal na op deze rijen
# ============================================================
x  <- tempo$oq45_score
se <- sd(x) / sqrt(length(x))

cat("\n== controle tempo_meting ==\n")
cat(sprintf("N = %d\n", N))
cat(sprintf("oq45_score (hele groep) : M = %.2f  SD = %.2f  range %d-%d\n",
            mean(x), sd(x), min(x), max(x)))
cat(sprintf("  SE = SD / sqrt(N) = %.2f / %.3f = %.3f\n", sd(x), sqrt(N), se))

cat("\nrespons:\n"); print(table(tempo$respons))
cat(sprintf("  respons-percentage 'ja' : %.1f%%\n",
            100 * mean(tempo$respons == "ja")))

mj <- mean(x[tempo$respons == "ja"])
mn <- mean(x[tempo$respons == "nee"])
cat("\noq45_score naar respons (non-respons-les):\n")
cat(sprintf("  responders (ja)    : n = %d  M = %.2f  SD = %.2f\n",
            sum(tempo$respons=="ja"),  mj, sd(x[tempo$respons=="ja"])))
cat(sprintf("  non-responders(nee): n = %d  M = %.2f  SD = %.2f\n",
            sum(tempo$respons=="nee"), mn, sd(x[tempo$respons=="nee"])))
cat(sprintf("  verschil (nee - ja) = %.2f punt  (non-responders hoger)\n", mn - mj))
tt <- t.test(x ~ tempo$respons)
cat(sprintf("  onafh. t(%.1f) = %.2f  p = %.4f\n",
            tt$parameter, tt$statistic, tt$p.value))
cat(sprintf("  M alleen responders = %.2f  vs  M hele groep = %.2f  (onderschatting)\n",
            mj, mean(x)))
