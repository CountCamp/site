# ============================================================
# genereer_depressie_running.R — synthetische data bij het blok
# "De effectgrootte — Cohens d / effect size"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design — een kleine pilot
# waarin runningtherapie naast de gebruikelijke behandeling wordt
# gezet bij patiënten met depressieve klachten — is typisch voor
# VS-onderzoek; beweeginterventies bij depressie zijn een echt en
# lopend onderzoeksveld in de GGZ. De uitkomstgetallen zijn
# DIDACTISCH GEKOZEN (fors d, breed interval) en het geciteerde
# artikel bestaat niet; dat staat ook zo in het blok. Er is nooit
# cliëntdata aangeraakt — lesmateriaal doet dat niet (doelbinding,
# en geanonimiseerd is niet anoniem bij kleine N).
#
# De data reproduceren EXACT de getallen uit het voorbeeldfragment:
#   running : M = 16.4, SD = 8.9, n = 13   (BDI-II na 12 weken)
#   usual   : M = 24.6, SD = 9.3, n = 12
#   t(23) = -2.25 · p = .034 · Cohen's d = -0.90 · 95% BI [-1.72, -0.07]
#   ruw verschil = -8.2 · 95% BI [-15.73, -0.67]
#
# Werkwijze: trek ruis, herschaal naar exact de gevraagde M en SD,
# en rond dan af op gehele punten (een BDI-II-score is een geheel
# getal). De seed is zo gekozen dat de gehele-punten-scores op één
# decimaal precies de fragment-M/SD's opleveren; alle toets- en
# effectgetallen zijn daarna uit de dataset zelf berekend, niet
# overgetikt.
#
# Het BI rond d is berekend via de noncentrale t-verdeling
# (pivot op de noncentraliteitsparameter, de methode die JASP
# gebruikt bij "Effect size > Confidence interval").
#
# Draaien:  Rscript genereer_depressie_running.R
# ============================================================
set.seed(68)

maak <- function(n, m, s) {
  x <- rnorm(n)
  x <- (x - mean(x)) / sd(x)      # exact 0 en 1
  round(m + s * x)                # BDI-II-score: geheel getal
}

running <- maak(13, 16.4, 8.9)
usual   <- maak(12, 24.6, 9.3)

depressie <- data.frame(
  id      = sprintf("p%03d", 1:25),
  groep   = rep(c("running", "usual"), c(13, 12)),
  bdi_12w = c(running, usual)
)

write.csv(depressie, "depressie_running.csv", row.names = FALSE, quote = FALSE)

# ---- BI rond d via de noncentrale t (zoals JASP) ----
d_ci <- function(t, n1, n2, conf = .95) {
  df <- n1 + n2 - 2
  k  <- sqrt(1/n1 + 1/n2)
  a  <- (1 - conf) / 2
  lo <- uniroot(function(ncp) pt(t, df, ncp) - (1 - a), c(-40, 40))$root
  hi <- uniroot(function(ncp) pt(t, df, ncp) - a,       c(-40, 40))$root
  c(lo, hi) * k
}

# ---- controle: komen de fragmentgetallen er echt uit? ----
tt <- t.test(bdi_12w ~ groep, data = depressie, var.equal = TRUE)
sp <- with(depressie, sqrt(
  ((13 - 1) * var(bdi_12w[groep == "running"]) +
   (12 - 1) * var(bdi_12w[groep == "usual"])) / 23))
d  <- unname(diff(rev(tt$estimate))) / sp
ci <- d_ci(unname(tt$statistic), 13, 12)

cat("\n== controle fragment ==\n")
with(depressie, print(round(tapply(bdi_12w, groep, function(v)
  c(M = mean(v), SD = sd(v), n = length(v))) |> simplify2array(), 2)))
cat("verschil  :", round(diff(rev(tt$estimate)), 3), "\n")
cat("t(", tt$parameter, ") = ", round(tt$statistic, 3),
    "   p = ", format.pval(tt$p.value, digits = 3), "\n", sep = "")
cat("95% BI ruw: [", paste(round(tt$conf.int, 2), collapse = ", "), "]\n")
cat("gepoolde SD:", round(sp, 3), "\n")
cat("Cohen's d :", round(d, 3), "\n")
cat("95% BI d  : [", paste(round(ci, 3), collapse = ", "), "]\n")

# ---- controle: kloppen de verzonnen leesopgave-fragmenten intern? ----
# Studie A (grote trial): n = 200 per groep, d = 0.30
# Studie B (pilot)      : n = 10 per groep,  d = 0.85
cat("\n== controle leesopgave ==\n")
for (s in list(c(200, 200, 0.30), c(10, 10, 0.85))) {
  n1 <- s[1]; n2 <- s[2]; dd <- s[3]
  tv <- dd * sqrt(n1 * n2 / (n1 + n2))
  pv <- 2 * pt(-abs(tv), n1 + n2 - 2)
  civ <- d_ci(tv, n1, n2)
  cat(sprintf("n=%d+%d, d=%.2f : t(%d)=%.3f  p=%.4f  95%% BI d [%.3f, %.3f]\n",
      n1, n2, dd, n1 + n2 - 2, tv, pv, civ[1], civ[2]))
}
