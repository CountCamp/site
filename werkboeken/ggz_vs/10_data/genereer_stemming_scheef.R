# ============================================================
# genereer_stemming_scheef.R — synthetische data bij het blok
# "Non-parametrisch: de Mann-Whitney-toets" (S3)
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (bij twee groepen
# patienten het aantal paniekaanvallen in de afgelopen week tellen:
# een wachtlijstgroep versus een groep die exposure-behandeling
# kreeg) is een plausibele klinische opzet. Deze dataset is NIET aan
# een echte studie geijkt — geen truth-anchor; de getallen zijn
# DIDACTISCH gekozen om een scheve uitkomst met een vloereffect te
# laten zien en zijn expliciet fictief. Er is nooit clientdata
# aangeraakt.
#
# DOEL VAN HET BLOK: laten zien wanneer je NIET de gewone t-toets
# gebruikt maar de Mann-Whitney. De uitkomst (paniekaanvallen per
# week) heeft een VLOEREFFECT: veel mensen zitten op 0 of laag, met
# een rechter staart. Zo'n telling is niet normaal verdeeld, dus
# vergelijk je de groepen op RANGORDE / MEDIAAN in plaats van op het
# gemiddelde.
#
# GEREALISEERDE KENGETALLEN (uit deze rijen, zie controle onderaan):
#   N = 70 (35 per groep)
#   paniek_week : aantal paniekaanvallen afgelopen week, vloer op 0,
#                 rechts-scheef in beide groepen
#   groep       : "wachtlijst"  (hogere rangen, meer aanvallen)
#                 "exposure"    (lagere rangen, minder aanvallen)
#   mediaanverschil tussen de groepen; Mann-Whitney significant
#
# Werkwijze: trek per groep uit een negatief-binomiale verdeling
# (telling met overdispersie -> vloer op 0 + rechter staart). De
# exposure-groep heeft een lager gemiddelde. Alle getallen in de
# controle zijn uit de rijen berekend, niet overgetikt.
#
# Draaien:  Rscript genereer_stemming_scheef.R
# ============================================================
set.seed(7024)

n_per <- 35

# negatief-binomiaal: mu = gemiddelde telling, size = dispersie (klein = scheef)
wachtlijst <- rnbinom(n_per, mu = 5.0, size = 1.2)
exposure   <- rnbinom(n_per, mu = 2.0, size = 1.0)

stemming <- data.frame(
  id          = sprintf("s%03d", 1:(2 * n_per)),
  groep       = rep(c("wachtlijst", "exposure"), each = n_per),
  paniek_week = c(wachtlijst, exposure)
)
# door elkaar husselen zodat de groepen niet blok-gesorteerd staan
stemming <- stemming[sample(nrow(stemming)), ]
stemming$id <- sprintf("s%03d", seq_len(nrow(stemming)))
rownames(stemming) <- NULL

write.csv(stemming, "stemming_scheef.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk kengetal na op deze rijen
# ============================================================
skew <- function(x) {
  n <- length(x); m <- mean(x); s <- sd(x)
  (n / ((n - 1) * (n - 2))) * sum(((x - m) / s)^3)
}
w <- stemming$paniek_week[stemming$groep == "wachtlijst"]
e <- stemming$paniek_week[stemming$groep == "exposure"]

cat("\n== controle stemming_scheef ==\n")
cat(sprintf("N = %d (%d per groep)\n\n", nrow(stemming), n_per))

cat("verdeling paniek_week (hele groep):\n")
print(table(stemming$paniek_week))
cat(sprintf("  aandeel op 0 (vloereffect) : %.1f%%\n",
            100 * mean(stemming$paniek_week == 0)))
cat(sprintf("  scheefheid (hele groep) = %.2f  (> 0 -> rechts-scheef)\n\n",
            skew(stemming$paniek_week)))

cat(sprintf("wachtlijst : n=%d  mediaan=%g  M=%.2f  SD=%.2f  scheefheid=%.2f\n",
            length(w), median(w), mean(w), sd(w), skew(w)))
cat(sprintf("exposure   : n=%d  mediaan=%g  M=%.2f  SD=%.2f  scheefheid=%.2f\n",
            length(e), median(e), mean(e), sd(e), skew(e)))
cat(sprintf("mediaanverschil (wachtlijst - exposure) = %g\n\n",
            median(w) - median(e)))

mw <- wilcox.test(paniek_week ~ groep, data = stemming, exact = FALSE)
cat("Mann-Whitney (Wilcoxon rank-sum):\n")
cat(sprintf("  W = %.1f   p = %.4f\n", mw$statistic, mw$p.value))
# rank-biserial effectgrootte
n1 <- length(w); n2 <- length(e)
U  <- mw$statistic
cat(sprintf("  rank-biserial r = %.3f\n", 1 - 2 * U / (n1 * n2)))
