# ============================================================
# genereer_terugval_nazorg.R — synthetische data bij het blok
# "De kruistabel en chi-kwadraat / crosstab and chi-square"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (een dossieronderzoek:
# kregen patienten geen, standaard of intensieve nazorg, en hadden
# ze binnen een jaar een terugval) is een plausibele observationele
# opzet; de rijen zijn gegenereerd. Er is nooit clientdata aangeraakt
# — lesmateriaal doet dat niet (doelbinding, en geanonimiseerd is
# niet anoniem bij kleine N).
#
# LET OP: dit is OBSERVATIONELE dossierdata, geen gerandomiseerd
# experiment. Dat is didactisch met opzet zo (zie "wat het niet
# zegt": de samenhang is geen causaal effect van nazorg).
#
# De data reproduceren de celtellingen uit het voorbeeldfragment
# EXACT (de tabel IS de bron; de rijen zijn de tabel uitgeschreven):
#
#                 terugval ja   terugval nee   n
#   geen nazorg        28            22        50
#   standaard          20            30        50
#   intensief          12            38        50
#   ------------------------------------------------
#   totaal             60            90       150
#
# chi-kwadraat(2) rond 10.67, p rond .005, Cramers V rond .27.
#
# Draaien:  Rscript genereer_terugval_nazorg.R
# ============================================================
set.seed(2607)

# celtellingen (rij = nazorg, kolom = terugval)
cellen <- rbind(
  geen      = c(ja = 28, nee = 22),
  standaard = c(ja = 20, nee = 30),
  intensief = c(ja = 12, nee = 38)
)

# schrijf elke cel uit naar losse rijen (de tabel -> patientregels)
rijen <- do.call(rbind, lapply(rownames(cellen), function(g)
  do.call(rbind, lapply(colnames(cellen), function(t)
    if (cellen[g, t] > 0)
      data.frame(nazorg = g, terugval = t,
                 stringsAsFactors = FALSE)[rep(1, cellen[g, t]), ]
  ))
))
rijen <- rijen[sample(nrow(rijen)), ]                 # door elkaar husselen
rijen$id <- sprintf("d%03d", seq_len(nrow(rijen)))
dossier <- rijen[, c("id", "nazorg", "terugval")]
rownames(dossier) <- NULL

write.csv(dossier, "terugval_nazorg.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk fragmentgetal na op deze rijen
# ============================================================
tab <- table(dossier$nazorg, dossier$terugval)
tab <- tab[c("geen", "standaard", "intensief"), c("ja", "nee")]
cs  <- chisq.test(tab, correct = FALSE)
V   <- sqrt(as.numeric(cs$statistic) / (sum(tab) * (min(dim(tab)) - 1)))

cat("\n== controle ==\n")
cat("kruistabel (rij = nazorg, kolom = terugval):\n"); print(tab)
cat("\nrij-percentages terugval 'ja':\n")
print(round(100 * tab[, "ja"] / rowSums(tab), 1))
cat(sprintf("\nchi-kwadraat(%d) = %.2f\n", cs$parameter, cs$statistic))
cat(sprintf("p               = %.4f\n", cs$p.value))
cat(sprintf("Cramers V       = %.3f\n", V))
cat("\nverwachte aantallen (onder onafhankelijkheid):\n"); print(round(cs$expected, 1))
cat("\ngestandaardiseerde residuen (Pearson, (O-E)/sqrt(E)):\n"); print(round(cs$residuals, 2))
cat("\ngecorrigeerde gestandaardiseerde residuen (adjusted, z-schaal):\n"); print(round(cs$stdres, 2))
