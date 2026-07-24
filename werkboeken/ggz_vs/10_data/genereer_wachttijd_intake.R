# ============================================================
# genereer_wachttijd_intake.R — synthetische data bij het blok
# "Mediaan, kwartielen en scheefheid" (W2)
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (een aanmeldregistratie:
# hoeveel dagen zaten patienten tussen aanmelding en intakegesprek)
# is een plausibele klinische opzet; wachttijden in de GGZ zijn een
# echt en beladen thema. Deze dataset is NIET aan een echte studie
# geijkt — geen truth-anchor; de getallen zijn DIDACTISCH gekozen om
# een duidelijk RECHTS-SCHEVE verdeling te laten zien en zijn
# expliciet fictief. Er is nooit clientdata aangeraakt.
#
# DOEL VAN HET BLOK: laten voelen waarom bij een scheve verdeling de
# MEDIAAN het midden beter beschrijft dan het GEMIDDELDE. De staart
# (een handvol mensen die maanden wachtten) trekt het gemiddelde
# omhoog, weg van waar de meeste mensen zitten.
#
# GEREALISEERDE KENGETALLEN (uit deze rijen, zie controle onderaan):
#   N = 80
#   wachttijd_dagen : rechts-scheef, gemiddelde ruim BOVEN de mediaan
#     streefbeeld  M ~ 45, mediaan ~ 30, een paar uitschieters > 120
#   leeftijd        : ratio, ter context (geen samenhang bedoeld)
#
# Werkwijze: trek uit een lognormale verdeling (van nature rechts-
# scheef), rond naar hele dagen met een realistische ondergrens.
# De seed is zo gekozen dat het streefbeeld goed benaderd wordt; de
# getallen in de controle zijn uit de rijen berekend, niet overgetikt.
#
# Draaien:  Rscript genereer_wachttijd_intake.R
# ============================================================
set.seed(23)

N <- 80

# lognormaal: mediaan = exp(meanlog); scheefheid via sdlog
meanlog <- log(30)      # mediaan rond 30 dagen
sdlog   <- 1.0          # flinke rechter staart

wachttijd_dagen <- round(exp(rnorm(N, meanlog, sdlog)))
wachttijd_dagen <- pmax(wachttijd_dagen, 3)     # minstens een paar dagen

# leeftijd ter context (los van wachttijd)
leeftijd <- round(rnorm(N, 40, 13))
leeftijd <- pmin(pmax(leeftijd, 18), 78)

wacht <- data.frame(
  id              = sprintf("a%03d", 1:N),
  wachttijd_dagen = wachttijd_dagen,
  leeftijd        = leeftijd
)

write.csv(wacht, "wachttijd_intake.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk streefgetal na op deze rijen
# ============================================================
# scheefheid (Fisher-Pearson, zoals JASP "Skewness")
skew <- function(x) {
  n <- length(x); m <- mean(x); s <- sd(x)
  (n / ((n - 1) * (n - 2))) * sum(((x - m) / s)^3)
}
w <- wacht$wachttijd_dagen
q <- quantile(w, c(.25, .5, .75))

cat("\n== controle wachttijd_intake ==\n")
cat(sprintf("N = %d\n", N))
cat(sprintf("wachttijd_dagen : M = %.1f  mediaan = %.0f\n", mean(w), median(w)))
cat(sprintf("  M - mediaan   = %.1f  (positief -> gemiddelde ligt boven mediaan)\n",
            mean(w) - median(w)))
cat(sprintf("  Q1 = %.0f   Q3 = %.0f   IQR = %.0f\n", q[1], q[3], q[3]-q[1]))
cat(sprintf("  min = %d   max = %d\n", min(w), max(w)))
cat(sprintf("  aantal uitschieters > 120 dagen : %d\n", sum(w > 120)))
cat(sprintf("  scheefheid (skewness) = %.2f  (> 0 -> rechts-scheef)\n", skew(w)))
cat(sprintf("leeftijd        : M = %.1f  SD = %.1f  range %d-%d\n",
            mean(leeftijd), sd(leeftijd), min(leeftijd), max(leeftijd)))
