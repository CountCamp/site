# ============================================================
# genereer_zelfmanagement.R — synthetische data bij het blok
# "De p-waarde / p value"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (gerandomiseerd, een door
# een verpleegkundig specialist geleid zelfmanagementprogramma bij
# terugkerende depressie versus gebruikelijke zorg, met somberheid en
# piekeren als uitkomsten na acht weken) volgt de opzet van echt
# VS-onderzoek; de rijen zijn gegenereerd. Er is nooit cliëntdata
# aangeraakt — lesmateriaal doet dat niet (doelbinding, en
# geanonimiseerd is niet anoniem bij kleine N).
#
# Didactische keuze: twee uitkomsten met vrijwel dezelfde effectgrootte,
# waarvan de ene nét onder .05 valt en de andere nét erboven. Doel:
#   somberheid : interv. M = 12.3, SD = 4.9 (n = 41)
#                contr.  M = 14.6, SD = 5.1 (n = 38)
#                t(77) = -2.04 · p = .045 · d = -0.46 · BI [-4.5, -0.1]
#   piekeren   : interv. M = 48.3, SD = 9.7 (n = 41)
#                contr.  M = 52.5, SD = 9.4 (n = 38)
#                t(77) = -1.95 · p = .055 · d = -0.44 · BI [-8.5, 0.1]
#
# Werkwijze: trek gecorreleerde ruis (somberheid en piekeren hangen in
# het echt samen), en herschaal daarna elke kolom per groep exact naar
# het gevraagde gemiddelde en de gevraagde SD. Zo is het geen benadering.
#
# Draaien:  Rscript genereer_zelfmanagement.R
# ============================================================
set.seed(4108)

maak2 <- function(n, m1, s1, m2, s2, r = .45) {
  z1 <- rnorm(n)
  z2 <- r * z1 + sqrt(1 - r^2) * rnorm(n)
  z1 <- (z1 - mean(z1)) / sd(z1)      # exact 0 en 1
  z2 <- (z2 - mean(z2)) / sd(z2)
  data.frame(som = round(m1 + s1 * z1, 1),   # score op één decimaal
             pk  = round(m2 + s2 * z2, 1))
}

interv <- maak2(41, 12.3, 4.9, 48.3, 9.7)
contr  <- maak2(38, 14.6, 5.1, 52.5, 9.4)

zelfmanagement <- data.frame(
  id          = sprintf("p%03d", 1:79),
  groep       = rep(c("interventie", "controle"), c(41, 38)),
  somber_8w   = c(interv$som, contr$som),
  piekeren_8w = c(interv$pk,  contr$pk)
)

write.csv(zelfmanagement, "zelfmanagement.csv", row.names = FALSE,
          quote = FALSE)

# ---- controle: komen de fragmentgetallen er echt uit? ----
rapport <- function(uitkomst) {
  f  <- reformulate("groep", uitkomst)
  tt <- t.test(f, data = zelfmanagement, var.equal = TRUE)
  d  <- zelfmanagement[[uitkomst]]
  g  <- zelfmanagement$groep
  sp <- sqrt(((sum(g == "controle") - 1) * var(d[g == "controle"]) +
              (sum(g == "interventie") - 1) * var(d[g == "interventie"])) /
             (length(d) - 2))
  cat("\n--", uitkomst, "--\n")
  print(round(tapply(d, g, function(v)
    c(M = mean(v), SD = sd(v), n = length(v))) |> simplify2array(), 3))
  # t.test zet 'controle' voorop (alfabetisch); fragment is interv - contr
  cat("verschil (interv - contr):",
      round(-diff(rev(tt$estimate)), 3), "\n")
  cat("t(", tt$parameter, ") = ", round(-tt$statistic, 3),
      "   p = ", format.pval(tt$p.value, digits = 3), "\n", sep = "")
  cat("95% BI   : [", paste(round(-rev(tt$conf.int), 3), collapse = ", "),
      "]\n")
  cat("Cohens d : ", round((mean(d[g == "interventie"]) -
                            mean(d[g == "controle"])) / sp, 3), "\n", sep = "")
}
rapport("somber_8w")
rapport("piekeren_8w")
cat("\ncorrelatie somber x piekeren:",
    round(cor(zelfmanagement$somber_8w, zelfmanagement$piekeren_8w), 2), "\n")
cat("bereik somber:", paste(range(zelfmanagement$somber_8w), collapse = " - "),
    "  (schaal 0-27)\n")
cat("bereik piekeren:", paste(range(zelfmanagement$piekeren_8w),
    collapse = " - "), "  (schaal 16-80)\n")
