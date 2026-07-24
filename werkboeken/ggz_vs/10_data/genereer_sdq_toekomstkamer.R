# ============================================================
# genereer_sdq_toekomstkamer.R — synthetische data bij het blok
# "De t-toets: gepaard en onafhankelijk / paired and independent"
# (het GEPAARDE deel; het onafhankelijke deel gebruikt
#  angst_blended.csv uit het BI-blok)
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (een groep jongeren,
# SDQ-totaalscore vlak voor en vlak na een VR-interventie, geen
# controlegroep) komt uit de opzet van een echt GGZ-onderzoek; de
# rijen zijn gegenereerd. Er is nooit clientdata aangeraakt —
# lesmateriaal doet dat niet (doelbinding, en geanonimiseerd is niet
# anoniem bij kleine N).
#
# De data reproduceren de gerapporteerde geaggregeerde kengetallen
# (afgerond zoals gerapporteerd):
#   N = 24, gepaard (elke jongere twee keer gemeten)
#   SDQ totale probleemscore (0-40, lager = minder klachten)
#     T0 : M = 20.50  SD = 4.45
#     T1 : M = 19.33  SD = 4.57
#   gepaarde t(23) rond 1.43, p rond .165 (niet significant), dz rond 0.29
#
# Werkwijze: een gepaarde t hangt af van het GEMIDDELDE verschil en
# de SPREIDING van de verschilscores, en die spreiding wordt bepaald
# door de correlatie tussen T0 en T1. We zetten die correlatie
# daarom exact (r = .55 -> SD_verschil rond 4.2 -> t rond 1.40),
# herschalen naar de gerapporteerde marges en ronden naar gehele
# SDQ-punten. De t hieronder is de t NA afronding, uit deze rijen
# berekend — niet overgetikt.
#
# Draaien:  Rscript genereer_sdq_toekomstkamer.R
# ============================================================
set.seed(2607)

N <- 24
r_t0t1 <- 0.55           # test-hertest-samenhang -> SD verschil -> t

z1 <- rnorm(N); z1 <- (z1 - mean(z1)) / sd(z1)          # T0-kern, gestand.
z2 <- rnorm(N); z2 <- residuals(lm(z2 ~ z1))            # loodrecht op z1
z2 <- (z2 - mean(z2)) / sd(z2)
t1core <- r_t0t1 * z1 + sqrt(1 - r_t0t1^2) * z2         # cor(z1,.) == r exact

tds_t0 <- pmin(pmax(round(20.50 + 4.45 * z1),     0), 40)
tds_t1 <- pmin(pmax(round(19.33 + 4.57 * t1core), 0), 40)

sdq <- data.frame(
  id     = sprintf("j%02d", 1:N),
  tds_t0 = tds_t0,
  tds_t1 = tds_t1
)

write.csv(sdq, "sdq_toekomstkamer.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk fragmentgetal na op deze rijen
# ============================================================
tt <- t.test(sdq$tds_t0, sdq$tds_t1, paired = TRUE)
d  <- sdq$tds_t0 - sdq$tds_t1
cat("\n== controle ==\n")
cat(sprintf("N = %d (gepaard)\n", N))
cat(sprintf("T0 : M = %.2f  SD = %.2f\n", mean(tds_t0), sd(tds_t0)))
cat(sprintf("T1 : M = %.2f  SD = %.2f\n", mean(tds_t1), sd(tds_t1)))
cat(sprintf("cor(T0,T1)      = %.3f\n", cor(tds_t0, tds_t1)))
cat(sprintf("gemiddeld verschil (T0-T1) = %.2f  SD_verschil = %.2f\n",
            mean(d), sd(d)))
cat(sprintf("t(%d) = %.2f\n", tt$parameter, tt$statistic))
cat(sprintf("p    = %.4f\n", tt$p.value))
cat(sprintf("95%% CI (verschil) : [%.2f, %.2f]\n", tt$conf.int[1], tt$conf.int[2]))
cat(sprintf("dz   = %.2f\n", mean(d) / sd(d)))
