# ============================================================
# genereer_groep_tijd_das.R — synthetische data bij het blok
# "De interactie / moderatie — twee factoren en hun samenspel"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN — MAAR HIER OOK: ANKER FICTIEF.
# Het design leunt op de imke-studie (partnerrelatie-interventie bij
# stellen waarin de patient een bipolaire stoornis heeft, Altrecht),
# maar die studie is VOORSTEL-FASE: er is nog geen verzamelde data en
# er zijn GEEN gerapporteerde uitkomsten (zie DESIGNS_EN_UITKOMSTEN.md,
# waarschuwing 2). Deze dataset is daarom DESIGN-BASED en
# FICTIEF-MAAR-PLAUSIBEL: het design/structuur (rol x meetmoment op de
# Dyadic Adjustment Scale) is geleend, de celgetallen zijn didactisch
# gekozen; geen enkel getal reproduceert een gerapporteerde uitkomst.
# Er is nooit clientdata aangeraakt — lesmateriaal doet dat niet
# (doelbinding, en geanonimiseerd is niet anoniem bij kleine N).
#
# Design: 2 x 2. Factor rol (patient / partner) x factor meetmoment
# (T0 voormeting / T1 nameting) op das_score (relatiekwaliteit,
# DAS-achtig, hoger = beter, plausibel bereik ~70-130). Long format:
# EEN rij per meting. koppel_id koppelt de patient en de partner
# binnen hetzelfde stel (zo kan een docent desgewenst ook gepaard /
# repeated-measures rekenen; de basis-oefening is de factoriele ANOVA).
#
# Didactische kern: er zit een ECHTE interactie in. De patienten
# verbeteren fors over de tijd; de partners nauwelijks. Het effect van
# tijd HANGT DUS AF van de rol — dat is precies wat een interactie is.
#
# Doel-celgemiddelden (streef; exact volgt uit de rijen onderaan):
#   patient  T0 ~ 94    patient  T1 ~ 109   (winst ~ +15)
#   partner  T0 ~ 108   partner  T1 ~ 108   (winst ~   0)
#   -> verschil-in-verschillen (interactie) ~ 15
#   SD ~ 16 per cel, n = 30 per cel (30 koppels), N = 120 metingen
#   interactie-p ~ .01
#
# Werkwijze: trek ruis, herschaal per cel exact naar de gevraagde M en
# SD, rond op gehele punten (een DAS-somscore is geheel). Alle toets-
# en effectgetallen worden onderaan uit de dataset zelf berekend.
#
# Draaien:  Rscript genereer_groep_tijd_das.R
# ============================================================
set.seed(4229)

n_kop <- 30                          # aantal koppels

maak <- function(n, m, s) {
  x <- rnorm(n)
  x <- (x - mean(x)) / sd(x)         # exact 0 en 1
  round(m + s * x)                   # DAS-somscore: geheel getal
}

cel_pat_t0 <- maak(n_kop,  94, 16)
cel_pat_t1 <- maak(n_kop, 109, 16)
cel_par_t0 <- maak(n_kop, 108, 16)
cel_par_t1 <- maak(n_kop, 108, 16)

koppel <- sprintf("k%02d", 1:n_kop)

das <- data.frame(
  id         = sprintf("m%03d", 1:(4 * n_kop)),
  koppel_id  = rep(koppel, 4),
  rol        = rep(c("patient", "partner"), each = 2 * n_kop),
  meetmoment = rep(rep(c("T0", "T1"), each = n_kop), 2),
  das_score  = c(cel_pat_t0, cel_pat_t1, cel_par_t0, cel_par_t1),
  stringsAsFactors = FALSE
)

write.csv(das, "groep_tijd_das.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk kengetal na op deze rijen
# ============================================================
cat("\n== celgemiddelden (M) ==\n")
print(round(tapply(das$das_score, list(das$rol, das$meetmoment), mean), 2))
cat("\n== cel-SD ==\n")
print(round(tapply(das$das_score, list(das$rol, das$meetmoment), sd), 2))

m <- tapply(das$das_score, list(das$rol, das$meetmoment), mean)
dd <- (m["patient", "T1"] - m["patient", "T0"]) -
      (m["partner", "T1"] - m["partner", "T0"])
cat(sprintf("\nwinst patient (T1-T0): %.2f\n", m["patient","T1"] - m["patient","T0"]))
cat(sprintf("winst partner (T1-T0): %.2f\n", m["partner","T1"] - m["partner","T0"]))
cat(sprintf("verschil-in-verschillen (interactie): %.2f\n", dd))

cat("\n== factoriele ANOVA (rol x meetmoment) ==\n")
fit <- aov(das_score ~ rol * meetmoment, data = das)
print(summary(fit))

s <- summary(fit)[[1]]
cat("\n== interactie apart ==\n")
cat(sprintf("F(%d, %d) = %.3f   p = %s\n",
    s["rol:meetmoment", "Df"], s["Residuals", "Df"],
    s["rol:meetmoment", "F value"],
    format.pval(s["rol:meetmoment", "Pr(>F)"], digits = 3)))
cat(sprintf("partiele eta-kwadraat (interactie) = %.3f\n",
    s["rol:meetmoment","Sum Sq"] /
    (s["rol:meetmoment","Sum Sq"] + s["Residuals","Sum Sq"])))

cat("\n== marginale gemiddelden ==\n")
cat("rij (rol):        ", round(rowMeans(m), 2), "\n")
cat("kolom (meetmoment):", round(colMeans(m), 2), "\n")

cat("\n== zelfde interactie via de regressiehelling (dummy's) ==\n")
lm_fit <- lm(das_score ~ rol * meetmoment, data = das)
print(round(summary(lm_fit)$coefficients, 4))
