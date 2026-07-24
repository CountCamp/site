# ============================================================
# genereer_angst_blended.R — synthetische data bij het blok
# "Het betrouwbaarheidsinterval / confidence interval"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (twee groepen, blended
# care versus gebruikelijke zorg, angstklachten na twaalf weken) komt
# uit de opzet van een echt VS-onderzoek; de rijen zijn gegenereerd.
# Er is nooit cliëntdata aangeraakt — lesmateriaal doet dat niet
# (doelbinding, en geanonimiseerd is niet anoniem bij kleine N).
#
# De data reproduceren EXACT de getallen uit het voorbeeldfragment:
#   blended : M = 8.1,  SD = 4.2,  n = 52
#   usual   : M = 10.5, SD = 4.6,  n = 50
#   verschil = -2.4 · t(100) = -2.75 · p = .007 · 95% BI [-4.13, -0.67]
#
# Werkwijze: trek ruis, en herschaal daarna elke groep naar precies het
# gevraagde gemiddelde en de gevraagde SD. Zo is het geen benadering.
#
# Draaien:  Rscript genereer_angst_blended.R
# ============================================================
set.seed(1207)

maak <- function(n, m, s) {
  x <- rnorm(n)
  x <- (x - mean(x)) / sd(x)      # exact 0 en 1
  round(m + s * x, 1)             # angstscore op één decimaal
}

blended <- maak(52,  8.1, 4.2)
usual   <- maak(50, 10.5, 4.6)

angst <- data.frame(
  id        = sprintf("p%03d", 1:102),
  groep     = rep(c("blended", "usual"), c(52, 50)),
  angst_12w = c(blended, usual)
)

write.csv(angst, "angst_blended.csv", row.names = FALSE, quote = FALSE)

# ---- controle: komen de fragmentgetallen er echt uit? ----
tt <- t.test(angst_12w ~ groep, data = angst, var.equal = TRUE)
cat("\n== controle ==\n")
with(angst, print(round(tapply(angst_12w, groep, function(v)
  c(M = mean(v), SD = sd(v), n = length(v))) |> simplify2array(), 2)))
cat("verschil :", round(diff(rev(tt$estimate)), 3), "\n")
cat("t(", tt$parameter, ") = ", round(tt$statistic, 3),
    "   p = ", format.pval(tt$p.value, digits = 3), "\n", sep = "")
cat("95% BI   : [", paste(round(tt$conf.int, 2), collapse = ", "), "]\n")
cat("99% BI   : [", paste(round(t.test(angst_12w ~ groep, data = angst,
     var.equal = TRUE, conf.level = .99)$conf.int, 2), collapse = ", "), "]\n")
