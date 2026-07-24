# ============================================================
# genereer_slaap_ernst.R — synthetische data bij het blok
# "De correlatie r en de scatterplot / correlation and scatterplot"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (dwarsdoorsnede bij
# ambulante patienten: klachtenernst versus slaapkwaliteit) is een
# plausibele klinische opzet; de rijen zijn gegenereerd. Er is nooit
# clientdata aangeraakt — lesmateriaal doet dat niet (doelbinding,
# en geanonimiseerd is niet anoniem bij kleine N).
#
# De data reproduceren de getallen uit het voorbeeldfragment
# (afgerond zoals daar gerapporteerd):
#   N = 68
#   ernst          : klachtenernst, schaal 0-40 (hoger = ernstiger)
#   slaapkwaliteit : schaal 0-100 (hoger = beter geslapen)
#   r rond -.45, negatief: slechter slapen gaat samen met meer klachten
#
# Werkwijze: trek twee gestandaardiseerde variabelen en zet hun
# correlatie EXACT op de doelwaarde door de ruis loodrecht op x te
# maken (residualiseren). Herschaal daarna naar de klinische schalen
# en rond naar gehele scores; de exacte r hieronder is de r NA
# afronding, uit deze rijen berekend — niet overgetikt.
#
# Draaien:  Rscript genereer_slaap_ernst.R
# ============================================================
set.seed(2607)

N <- 68
r_doel <- -0.45

x <- rnorm(N); x <- (x - mean(x)) / sd(x)          # ernst-kern, gestand.
e <- rnorm(N)
e <- residuals(lm(e ~ x))                          # loodrecht op x
e <- (e - mean(e)) / sd(e)
y <- r_doel * x + sqrt(1 - r_doel^2) * e           # cor(x, y) == r_doel exact

# herschaal naar klinische schalen, rond naar gehele scores + clamp
ernst          <- pmin(pmax(round(18 + 7  * x), 0), 40)
slaapkwaliteit <- pmin(pmax(round(55 + 18 * y), 0), 100)

slaap <- data.frame(
  id             = sprintf("p%03d", 1:N),
  ernst          = ernst,
  slaapkwaliteit = slaapkwaliteit
)

write.csv(slaap, "slaap_ernst.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk fragmentgetal na op deze rijen
# ============================================================
ct <- cor.test(slaap$ernst, slaap$slaapkwaliteit)
cat("\n== controle ==\n")
cat(sprintf("N = %d\n", N))
cat(sprintf("ernst          : M = %.2f  SD = %.2f  (min %d, max %d)\n",
            mean(ernst), sd(ernst), min(ernst), max(ernst)))
cat(sprintf("slaapkwaliteit : M = %.2f  SD = %.2f  (min %d, max %d)\n",
            mean(slaapkwaliteit), sd(slaapkwaliteit), min(slaapkwaliteit), max(slaapkwaliteit)))
cat(sprintf("r        = %.3f\n", ct$estimate))
cat(sprintf("r-kwadraat = %.3f\n", ct$estimate^2))
cat(sprintf("t(%d)     = %.2f\n", ct$parameter, ct$statistic))
cat(sprintf("p        = %.4f\n", ct$p.value))
cat(sprintf("95%% CI   : [%.3f, %.3f]\n", ct$conf.int[1], ct$conf.int[2]))
