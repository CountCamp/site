# ============================================================
# genereer_drie_behandelingen.R — synthetische data bij het blok
# "De variantieanalyse — ANOVA / dummy's / eta-kwadraat"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN — MAAR HIER OOK: ANKER FICTIEF.
# Anders dan bij de t-toets- en kruistabel-datasets is er voor de
# ANOVA GEEN echte-studie-anker in dit werkboek (de VS-onderzoeken
# die de andere blokken voeden gebruiken mixed models / LRT, geen
# klassieke F-toets tussen drie groepen — zie DESIGNS_EN_UITKOMSTEN.md,
# waarschuwing 1). Deze dataset is daarom DESIGN-BASED en
# FICTIEF-MAAR-PLAUSIBEL: drie behandelcondities bij terugkerende
# depressie (CGT, runningtherapie, wachtlijst), depressie-ernst
# (BDI-II) na 12 weken. Het design is klinisch alledaags, de
# celgetallen zijn didactisch gekozen; geen enkel getal reproduceert
# een gerapporteerde uitkomst. Er is nooit clientdata aangeraakt —
# lesmateriaal doet dat niet (doelbinding, en geanonimiseerd is niet
# anoniem bij kleine N).
#
# Didactische keuze: de twee actieve condities liggen laag en dicht
# bijeen; de wachtlijst ligt duidelijk hoger. Zo geeft de F-toets een
# helder effect, en laat de post-hoc (Tukey) een schoon patroon zien:
#   CGT vs wachtlijst    -> verschilt
#   running vs wachtlijst -> verschilt
#   CGT vs running        -> verschilt NIET (twee werkzame armen)
#
# Doel-kengetallen (streef; exact volgt uit de rijen onderaan):
#   CGT        : M ~ 16, SD ~ 8, n = 28   (BDI-II na 12 weken)
#   running    : M ~ 18, SD ~ 8, n = 28
#   wachtlijst : M ~ 24, SD ~ 8, n = 28
#   F(2, 81) ~ 7.5 · p ~ .001 · eta-kwadraat ~ .16
#
# Werkwijze: trek ruis, herschaal per groep exact naar de gevraagde
# M en SD, en rond dan af op gehele punten (een BDI-II-score is een
# geheel getal). Alle toets- en effectgetallen worden onderaan uit
# de dataset zelf berekend, niet overgetikt.
#
# Draaien:  Rscript genereer_drie_behandelingen.R
# ============================================================
set.seed(913)

maak <- function(n, m, s) {
  x <- rnorm(n)
  x <- (x - mean(x)) / sd(x)      # exact 0 en 1
  round(m + s * x)                # BDI-II-score: geheel getal
}

cgt        <- maak(28, 16, 8)
running    <- maak(28, 18, 8)
wachtlijst <- maak(28, 24, 8)

drie <- data.frame(
  id       = sprintf("p%03d", 1:84),
  conditie = rep(c("CGT", "running", "wachtlijst"), each = 28),
  bdi_12w  = c(cgt, running, wachtlijst)
)

write.csv(drie, "drie_behandelingen.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk kengetal na op deze rijen
# ============================================================
cat("\n== groepsbeschrijving ==\n")
print(round(with(drie, tapply(bdi_12w, conditie, function(v)
  c(M = mean(v), SD = sd(v), n = length(v))) |> simplify2array()), 2))

aov_fit <- aov(bdi_12w ~ conditie, data = drie)
s <- summary(aov_fit)[[1]]
ss_between <- s["conditie", "Sum Sq"]
ss_within  <- s["Residuals", "Sum Sq"]
eta2 <- ss_between / (ss_between + ss_within)

cat("\n== ANOVA ==\n")
print(s)
cat(sprintf("\nF(%d, %d) = %.3f   p = %s\n",
    s["conditie", "Df"], s["Residuals", "Df"],
    s["conditie", "F value"],
    format.pval(s["conditie", "Pr(>F)"], digits = 3)))
cat(sprintf("SS_tussen = %.1f   SS_binnen = %.1f\n", ss_between, ss_within))
cat(sprintf("eta-kwadraat = %.3f\n", eta2))
cat(sprintf("omega-kwadraat = %.3f\n",
    (ss_between - s["conditie","Df"] * (ss_within / s["Residuals","Df"])) /
    (ss_between + ss_within + (ss_within / s["Residuals","Df"]))))

cat("\n== Tukey HSD post-hoc ==\n")
print(round(TukeyHSD(aov_fit)$conditie, 3))
