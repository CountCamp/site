# ============================================================
# genereer_nazorg_therapietrouw_terugval.R — synthetische data bij
# het blok "De mediatie — een pad via een tussenliggende variabele"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN — MAAR HIER OOK: ANKER FICTIEF.
# Net als bij ANOVA en interactie is er voor MEDIATIE geen
# echte-studie-anker in dit werkboek (zie DESIGNS_EN_UITKOMSTEN.md).
# Deze dataset is daarom DESIGN-BASED en FICTIEF-MAAR-PLAUSIBEL: een
# klinisch alledaags mediatiepad — een nazorgprogramma bij
# terugkerende depressie verhoogt de therapietrouw, en juist die
# hogere therapietrouw leidt tot meer symptoomdaling. Het pad is
# plausibel, de getallen zijn didactisch gekozen; geen enkel getal
# reproduceert een gerapporteerde uitkomst. Er is nooit clientdata
# aangeraakt — lesmateriaal doet dat niet (doelbinding, en
# geanonimiseerd is niet anoniem bij kleine N).
#
# Design (drie variabelen, N = 120):
#   nazorg        : 0 = gebruikelijke zorg, 1 = intensief nazorgprogramma
#   therapietrouw : mediator, 0-100-schaal (hoger = trouwer aan de
#                   behandelafspraken), continu
#   symptoomdaling: uitkomst, daling in depressie-ernst over 6 maanden
#                   (hoger = meer verbetering), continu
#
# Didactische kern: het effect van nazorg op symptoomdaling loopt
# GROTENDEELS VIA de therapietrouw (fors indirect effect a*b), met
# maar een klein resterend direct effect (c'). Zo is de mediatie
# zichtbaar: c krimpt sterk naar c' zodra de mediator in het model komt.
#
# Generatief model (waaruit de doel-paden volgen):
#   therapietrouw  = 52 + 12 * nazorg + ruis(SD 9)
#   symptoomdaling = -12 + 0.5 * therapietrouw + 1.5 * nazorg + ruis(SD 5)
# -> pad a ~ 12 · pad b ~ 0.5 · direct c' ~ 1.5 · indirect a*b ~ 6
#    totaal c ~ 7.5 · aandeel indirect ~ 80%
#
# Werkwijze: de paden zijn ingebouwd via het generatieve model; door
# de ruis komen de geschatte coefficienten dicht bij — maar niet exact
# op — de doelwaarden. Alle mediatie-getallen (c, a, b, c', a*b, het
# percentage indirect, en een bootstrap-BI om a*b) worden onderaan uit
# de dataset zelf berekend, niet overgetikt.
#
# Draaien:  Rscript genereer_nazorg_therapietrouw_terugval.R
# ============================================================
set.seed(1147)

n <- 120
nazorg <- rep(c(0, 1), each = n / 2)

therapietrouw  <- 52 + 12 * nazorg + rnorm(n, 0, 9)
symptoomdaling <- -12 + 0.5 * therapietrouw + 1.5 * nazorg + rnorm(n, 0, 5)

med <- data.frame(
  id             = sprintf("p%03d", 1:n),
  nazorg         = nazorg,
  therapietrouw  = round(therapietrouw, 1),
  symptoomdaling = round(symptoomdaling, 1)
)
med <- med[sample(n), ]                 # door elkaar husselen
med$id <- sprintf("p%03d", 1:n)
rownames(med) <- NULL

write.csv(med, "nazorg_therapietrouw_terugval.csv",
          row.names = FALSE, quote = FALSE)

# ============================================================
# controle — de drie regressies van de klassieke mediatie-analyse
# ============================================================
m_c  <- lm(symptoomdaling ~ nazorg, data = med)                  # totaal effect c
m_a  <- lm(therapietrouw  ~ nazorg, data = med)                  # pad a
m_bc <- lm(symptoomdaling ~ nazorg + therapietrouw, data = med)  # b + direct c'

c_tot <- coef(m_c)["nazorg"]
a     <- coef(m_a)["nazorg"]
b     <- coef(m_bc)["therapietrouw"]
c_dir <- coef(m_bc)["nazorg"]
ab    <- a * b
prop  <- ab / c_tot

cat("\n== beschrijving ==\n")
cat("n per groep:", table(med$nazorg), "\n")
cat(sprintf("therapietrouw : M0=%.2f M1=%.2f (SD=%.2f)\n",
    mean(med$therapietrouw[med$nazorg == 0]),
    mean(med$therapietrouw[med$nazorg == 1]),
    sd(med$therapietrouw)))
cat(sprintf("symptoomdaling: M0=%.2f M1=%.2f (SD=%.2f)\n",
    mean(med$symptoomdaling[med$nazorg == 0]),
    mean(med$symptoomdaling[med$nazorg == 1]),
    sd(med$symptoomdaling)))

cat("\n== de drie regressies ==\n")
cat(sprintf("totaal effect  c  (nazorg -> symptoomdaling)        : %.3f  p=%s\n",
    c_tot, format.pval(summary(m_c)$coefficients["nazorg", 4], digits = 3)))
cat(sprintf("pad a          a  (nazorg -> therapietrouw)         : %.3f  p=%s\n",
    a, format.pval(summary(m_a)$coefficients["nazorg", 4], digits = 3)))
cat(sprintf("pad b          b  (therapietrouw -> sympt. | nazorg): %.3f  p=%s\n",
    b, format.pval(summary(m_bc)$coefficients["therapietrouw", 4], digits = 3)))
cat(sprintf("direct effect  c' (nazorg -> sympt. | therapietrouw): %.3f  p=%s\n",
    c_dir, format.pval(summary(m_bc)$coefficients["nazorg", 4], digits = 3)))

cat("\n== mediatie ==\n")
cat(sprintf("indirect effect a*b            : %.3f\n", ab))
cat(sprintf("controle c' + a*b (= c)        : %.3f  (totaal c = %.3f)\n",
    c_dir + ab, c_tot))
cat(sprintf("aandeel indirect (a*b / c)     : %.1f%%\n", 100 * prop))

# ---- bootstrap-BI om het indirecte effect a*b (percentiel, 5000x) ----
set.seed(99)
B  <- 5000
ab_boot <- replicate(B, {
  i  <- sample(n, n, replace = TRUE)
  d  <- med[i, ]
  aa <- coef(lm(therapietrouw ~ nazorg, data = d))["nazorg"]
  bb <- coef(lm(symptoomdaling ~ nazorg + therapietrouw, data = d))["therapietrouw"]
  aa * bb
})
ci <- quantile(ab_boot, c(.025, .975))
cat(sprintf("bootstrap 95%% BI a*b (percentiel, %d resamples): [%.3f, %.3f]\n",
    B, ci[1], ci[2]))
cat(sprintf("BI ligt %s boven nul\n",
    if (ci[1] > 0) "VOLLEDIG" else "NIET volledig"))
