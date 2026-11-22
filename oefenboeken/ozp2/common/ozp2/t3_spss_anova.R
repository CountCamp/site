# Nagebouwde SPSS-uitvoer van One-Way ANOVA, voor thema 3 en 4 van het
# oefenboek OZP 2. Bouwt voort op spss_uitvoer.R (spss_tabel, spss_getal,
# spss_p, spss_toon, spss_noot); laad dat bestand eerst.
#
# Wat erin zit:
#   anova_eenweg(y, g)         rekent alles uit: Descriptives, de ANOVA-tabel,
#                              de vier effectgroottes van SPSS mét 95%-BI, de
#                              post-hoc-tabel (LSD en Bonferroni) en, op verzoek,
#                              een contrast
#   spss_descriptives(r, ...)  de tabel "Descriptives"
#   spss_anova(r, ...)         de tabel "ANOVA"
#   spss_effect(r, ...)        de tabel "ANOVA Effect Sizes"
#   spss_posthoc(r, ...)       de tabel "Multiple Comparisons" (LSD + Bonferroni)
#   spss_contrast(r, a, ...)   "Contrast Coefficients" en "Contrast Tests"
#   tabel_E(df1, df2)          de kritische F-waarden van Tabel E (MMC) op twee
#                              decimalen, en klemF() dat een F ertussen zet
#
# GETOETST TEGEN ECHTE SPSS-UITVOER (18-11-2026), onderaan dit bestand, bij
# elk laden. College 4 van OZP 2 (2026-27) toont SPSS-tabellen van het
# scouting-voorbeeld (negen kinderen, drie groepen van drie, gemiddelden 2, 5 en
# 5, elke s = 1) en van het sportvoorbeeld (vijftien kinderen, drie groepen van
# vijf). Daaruit komen exact terug:
#   - dia 7:  ANOVA 18.000 / 2 / 9.000 / 9.000 / .016 en 6.000 / 6 / 1.000
#   - dia 8:  Eta-squared .750 [.053, .850], Epsilon-squared .667 [-.263, .801],
#             Omega-squared Fixed .640 [-.227, .781], Random .471 [-.102, .641]
#   - dia 43: Eta .843 [.533, .900], Epsilon .816 [.455, .884], Omega fixed
#             .806 [.438, .877], Omega random .675 [.281, .780]; F 32.133
#   - dia 16: Contrast Tests: Value 3.0000, Std. Error .70711, t 4.243, df 6,
#             Sig. (2-tailed) .005, 95% BI 1.2698 tot 4.7302
#   - dia 32: Multiple Comparisons, LSD: -3.00000, .81650, .010, -4.9979, -1.0021;
#             Bonferroni: .031, -5.6842, -.3158
#   - dia 44: LSD sport 3.40000 / .77460 / <.001 / 1.7123 / 5.0877 en
#             Bonferroni .003 / 1.2470 / 5.5530
# Wat NIET is nagemeten: de rij "Omega-squared Random-effect" volgt een formule
# die op beide dia's exact uitkomt (24 getallen) maar die ik niet in de
# SPSS-documentatie heb nagelezen; de kolom Minimum/Maximum van Descriptives
# en de decimalen daarvan; de volgorde van de rijen bij meer dan drie groepen.

# ---- rekenen ----------------------------------------------------------------
anova_eenweg <- function(y, g, niveau = .95) {
  g <- factor(g); I <- nlevels(g); N <- length(y)
  n <- as.vector(table(g)); m <- as.vector(tapply(y, g, mean)); s <- as.vector(tapply(y, g, sd))
  xb <- mean(y)
  # SSE via de scores zelf, niet via (n-1)s^2: bij hele scores blijft dat exact
  # (sd() trekt een wortel en die komt gekwadrateerd niet precies terug)
  SSG <- sum(n * (m - xb)^2); SSE <- sum((y - m[as.integer(g)])^2); SST <- sum((y - xb)^2)
  DFG <- I - 1; DFE <- N - I; DFT <- N - 1
  MSG <- SSG / DFG; MSE <- SSE / DFE; F <- MSG / MSE
  p <- pf(F, DFG, DFE, lower.tail = FALSE)
  sp <- sqrt(MSE)
  a <- (1 - niveau) / 2
  # Descriptives: per groep en totaal
  tk <- qt(1 - a, n - 1)
  se <- s / sqrt(n)
  desc <- data.frame(groep = levels(g), n = n, m = m, s = s, se = se,
                     lo = m - tk * se, hi = m + tk * se,
                     min = as.vector(tapply(y, g, min)), max = as.vector(tapply(y, g, max)))
  tot <- data.frame(groep = "Total", n = N, m = xb, s = sd(y), se = sd(y) / sqrt(N),
                    lo = xb - qt(1 - a, DFT) * sd(y) / sqrt(N), hi = xb + qt(1 - a, DFT) * sd(y) / sqrt(N),
                    min = min(y), max = max(y))
  # effectgroottes zoals SPSS ze drukt (getoetst tegen college 4, dia 8 en 43)
  eta <- SSG / SST
  f <- function(ncp, pp) suppressWarnings(pf(F, DFG, DFE, ncp)) - pp
  ncp_lo <- if (f(0, 1 - a) > 0) uniroot(f, c(0, 1e4), pp = 1 - a, tol = 1e-10)$root else 0
  ncp_hi <- uniroot(f, c(0, 1e4), pp = a, tol = 1e-10)$root
  eta_b <- c(ncp_lo, ncp_hi) / (c(ncp_lo, ncp_hi) + N)
  F_b <- (eta_b / DFG) / ((1 - eta_b) / DFE)
  eff <- rbind(
    eta   = c(eta, eta_b),
    eps   = c((SSG - DFG * MSE) / SST, 1 - (1 - eta_b) * DFT / DFE),
    omf   = c((SSG - DFG * MSE) / (SST + MSE), (F_b * DFG - DFG) / (F_b * DFG + DFE + 1)),
    omr   = c((SSG - DFG * MSE) / (SST + (N + 1) * MSE), (F_b * DFG - DFG) / (F_b * DFG + DFE + N + 1))
  )
  colnames(eff) <- c("punt", "lo", "hi")
  # post hoc: alle paren, beide richtingen (zoals SPSS), LSD en Bonferroni
  k <- I * (I - 1) / 2
  paren <- expand.grid(i = seq_len(I), j = seq_len(I)); paren <- paren[paren$i != paren$j, ]
  paren <- paren[order(paren$i, paren$j), ]
  ph <- do.call(rbind, lapply(seq_len(nrow(paren)), function(r) {
    i <- paren$i[r]; j <- paren$j[r]
    d <- m[i] - m[j]; se_ij <- sp * sqrt(1 / n[i] + 1 / n[j]); t <- d / se_ij
    p2 <- 2 * pt(-abs(t), DFE)
    data.frame(i = i, j = j, verschil = d, se = se_ij, t = t,
               p_lsd = p2, lo_lsd = d - qt(1 - a, DFE) * se_ij, hi_lsd = d + qt(1 - a, DFE) * se_ij,
               p_bon = min(1, k * p2), lo_bon = d - qt(1 - a / k, DFE) * se_ij, hi_bon = d + qt(1 - a / k, DFE) * se_ij)
  }))
  list(I = I, N = N, n = n, m = m, s = s, xb = xb, groepen = levels(g),
       SSG = SSG, SSE = SSE, SST = SST, DFG = DFG, DFE = DFE, DFT = DFT,
       MSG = MSG, MSE = MSE, F = F, p = p, sp = sp, eta = eta, eff = eff,
       desc = desc, tot = tot, posthoc = ph, k = k, niveau = niveau)
}

# Een contrast met gewichten a (som 0): c, SE_c, t, df = DFE, tweezijdige p, BI.
contrast_eenweg <- function(r, a, niveau = .95) {
  stopifnot(length(a) == r$I, abs(sum(a)) < 1e-12)
  cc <- sum(a * r$m); se_c <- r$sp * sqrt(sum(a^2 / r$n)); t <- cc / se_c
  tk <- qt(1 - (1 - niveau) / 2, r$DFE)
  list(a = a, c = cc, se = se_c, t = t, df = r$DFE, p2 = 2 * pt(-abs(t), r$DFE),
       p1 = pt(-abs(t), r$DFE), lo = cc - tk * se_c, hi = cc + tk * se_c)
}

# ---- Tabel E (Moore, McCabe & Craig): kritische F-waarden -----------------------
kolommen_E <- c(.100, .050, .025, .010, .001)
tabel_E <- function(df1, df2) round(qf(1 - kolommen_E, df1, df2), 2)
# Een kolomkop van Tabel E zoals de tabel hem drukt: altijd drie decimalen
# (.100, .050, .025, .010, .001 -- zo staat hij op de foto van college 3, dia 47).
# Anders dan kol() uit getallen.R, die voor Tabel D nullen wegstreept (.05).
kolE <- function(p) vapply(p, function(q) sub("^0", "", formatC(q, format = "f", digits = 3)), "", USE.NAMES = FALSE)
# Tussen welke twee kolommen ligt F? Geeft de (eenzijdige, dat is bij F de
# enige) p-range. Zakt als F zo dicht bij een tabelwaarde ligt dat afronden de
# kolom kan verwisselen.
klemF <- function(F, df1, df2) {
  v <- tabel_E(df1, df2)
  stopifnot("F ligt op de rand van een tabelkolom" = all(abs(F - v) > .03))
  i <- sum(v < F)
  if (i == 0) return(c(hoog = NA, laag = kolommen_E[1], F_hoog = v[1], F_laag = NA))
  if (i == length(v)) return(c(hoog = kolommen_E[i], laag = NA, F_hoog = NA, F_laag = v[i]))
  c(hoog = kolommen_E[i], laag = kolommen_E[i + 1], F_hoog = v[i + 1], F_laag = v[i])
}

# ---- Tabel D (Moore, McCabe & Craig): kritische t-waarden -----------------------
# Dezelfde klem als in thema 1 (daar in de qmd zelf); hier gedeeld, omdat thema 4
# hem voor elke post-hoc t en elk contrast nodig heeft. Geeft de EENZIJDIGE
# p-range; tweezijdig is x2 (Pippi).
kolommen_D <- c(.25, .20, .15, .10, .05, .025, .02, .01, .005, .0025, .001, .0005)
tabel_D <- function(df) round(qt(1 - kolommen_D, df), 3)
klemD <- function(t, df) {
  a <- abs(t); v <- tabel_D(df)
  stopifnot("t ligt op de rand van een tabelkolom" = all(abs(a - v) > .004))
  i <- sum(v < a)
  if (i == length(v)) return(c(hoog = kolommen_D[i], laag = NA, t_hoog = NA, t_laag = v[i]))
  stopifnot("t valt buiten de tabel" = i >= 1)
  c(hoog = kolommen_D[i], laag = kolommen_D[i + 1], t_hoog = v[i + 1], t_laag = v[i])
}

# ---- tekenen ------------------------------------------------------------------
spss_descriptives <- function(r, uitkomst, md = 2, d = 3) {
  rij <- function(x) c(x$groep, x$n, spss_getal(x$m, md), spss_getal(x$s, d), spss_getal(x$se, d),
                       spss_getal(x$lo, md), spss_getal(x$hi, md), spss_getal(x$min, md), spss_getal(x$max, md))
  rijen <- c(lapply(seq_len(nrow(r$desc)), function(i) rij(r$desc[i, ])), list(rij(r$tot)))
  spss_tabel(
    "Descriptives",
    list(list(kc(uitkomst, cols = 9)),
         list(kc("", rows = 2), kc("N", rows = 2), kc("Mean", rows = 2), kc("Std. Deviation", rows = 2),
              kc("Std. Error", rows = 2), kc("95% Confidence Interval for Mean", cols = 2),
              kc("Minimum", rows = 2), kc("Maximum", rows = 2)),
         list(kc("Lower Bound"), kc("Upper Bound"))),
    rijen, links = 1)
}

spss_anova <- function(r, uitkomst, d = 3) {
  spss_tabel(
    "ANOVA",
    list(list(kc(uitkomst, cols = 6)),
         list(kc(""), kc("Sum of Squares"), kc("df"), kc("Mean Square"), kc("F"), kc("Sig."))),
    list(c("Between Groups", spss_getal(r$SSG, d), r$DFG, spss_getal(r$MSG, d), spss_getal(r$F, d), spss_p(r$p)),
         c("Within Groups", spss_getal(r$SSE, d), r$DFE, spss_getal(r$MSE, d), "", ""),
         c("Total", spss_getal(r$SST, d), r$DFT, "", "", "")),
    links = 1)
}

spss_effect <- function(r, uitkomst) {
  e <- r$eff
  rij <- function(naam, k, eerste = "") c(eerste, naam, spss_getal(e[k, "punt"], 3), spss_getal(e[k, "lo"], 3), spss_getal(e[k, "hi"], 3))
  spss_tabel(
    "ANOVA Effect Sizesᵃ,ᵇ",
    list(list(kc("", rows = 2), kc("", rows = 2), kc("Point Estimate", rows = 2), kc("95% Confidence Interval", cols = 2)),
         list(kc("Lower"), kc("Upper"))),
    list(rij("Eta-squared", "eta", uitkomst), rij("Epsilon-squared", "eps"),
         rij("Omega-squared Fixed-effect", "omf"), rij("Omega-squared Random-effect", "omr")),
    voetnoten = c("a. Eta-squared and Epsilon-squared are estimated based on the fixed-effect model.",
                  "b. Negative but less biased estimates are retained, not rounded to zero."),
    links = 2)
}

# Multiple Comparisons: LSD en Bonferroni onder elkaar, zoals SPSS het drukt als
# je allebei aanvinkt. Een significant verschil krijgt het sterretje van SPSS.
spss_posthoc <- function(r, uitkomst, namen = r$groepen, welke = c("LSD", "Bonferroni"), d = 5) {
  ph <- r$posthoc
  ster <- function(x, p) paste0(spss_getal(x, d), if (p < .05) "*" else "")
  rijen <- list()
  for (w in welke) {
    for (q in seq_len(nrow(ph))) {
      i <- ph$i[q]; j <- ph$j[q]
      eerste <- if (q == 1) w else ""
      naam_i <- if (q == 1 || ph$i[q - 1] != i) namen[i] else ""
      if (w == "LSD") {
        rijen[[length(rijen) + 1]] <- c(eerste, naam_i, namen[j], ster(ph$verschil[q], ph$p_lsd[q]),
          spss_getal(ph$se[q], d), spss_p(ph$p_lsd[q]), spss_getal(ph$lo_lsd[q], 4), spss_getal(ph$hi_lsd[q], 4))
      } else {
        rijen[[length(rijen) + 1]] <- c(eerste, naam_i, namen[j], ster(ph$verschil[q], ph$p_bon[q]),
          spss_getal(ph$se[q], d), spss_p(ph$p_bon[q]), spss_getal(ph$lo_bon[q], 4), spss_getal(ph$hi_bon[q], 4))
      }
    }
  }
  spss_tabel(
    "Multiple Comparisons",
    list(list(kc(paste("Dependent Variable:", uitkomst), cols = 8)),
         list(kc("", rows = 2), kc("(I) Groep", rows = 2), kc("(J) Groep", rows = 2),
              kc("Mean Difference (I-J)", rows = 2), kc("Std. Error", rows = 2), kc("Sig.", rows = 2),
              kc("95% Confidence Interval", cols = 2)),
         list(kc("Lower Bound"), kc("Upper Bound"))),
    rijen,
    voetnoten = "*. The mean difference is significant at the 0.05 level.",
    links = 3)
}

spss_contrast <- function(r, ct, uitkomst, namen = r$groepen) {
  coef <- spss_tabel(
    "Contrast Coefficients",
    list(list(kc("", rows = 2), kc("Groep", cols = r$I)),
         lapply(namen, kc)),
    list(c("1", vapply(ct$a, function(x) sub("^(-?)0[.]", "\\1.", formatC(x, format = "g")), ""))),
    links = 1)
  tests <- spss_tabel(
    "Contrast Tests",
    list(list(kc(""), kc(""), kc("Contrast"), kc("Value of Contrast"), kc("Std. Error"), kc("t"), kc("df"),
              kc("Sig. (2-tailed)"), kc("95% Confidence Interval", cols = 2)),
         list(kc("", cols = 8), kc("Lower"), kc("Upper"))),
    list(c(uitkomst, "Assumes equal variances", "1", spss_getal(ct$c, 4), spss_getal(ct$se, 5),
           spss_getal(ct$t, 3), ct$df, spss_p(ct$p2), spss_getal(ct$lo, 4), spss_getal(ct$hi, 4))),
    links = 3)
  paste0(coef, tests)
}

# ---- toets tegen echte SPSS-uitvoer (college 4, 2026-27) -------------------------
local({
  # dia 4/7/8/16/32: de negen scoutingkinderen (college 3, dia 29)
  y <- c(1, 2, 3, 6, 5, 4, 5, 6, 4); g <- rep(1:3, each = 3)
  r <- anova_eenweg(y, g)
  e <- r$eff
  stopifnot(
    "ANOVA-tabel wijkt af van dia 7" = spss_getal(r$SSG, 3) == "18.000" && r$DFG == 2 &&
      spss_getal(r$MSG, 3) == "9.000" && spss_getal(r$F, 3) == "9.000" && spss_p(r$p) == ".016" &&
      spss_getal(r$SSE, 3) == "6.000" && r$DFE == 6 && spss_getal(r$MSE, 3) == "1.000",
    "Eta-squared wijkt af van dia 8" = all(spss_getal(e["eta", ], 3) == c(".750", ".053", ".850")),
    "Epsilon-squared wijkt af van dia 8" = all(spss_getal(e["eps", ], 3) == c(".667", "-.263", ".801")),
    "Omega fixed wijkt af van dia 8" = all(spss_getal(e["omf", ], 3) == c(".640", "-.227", ".781")),
    "Omega random wijkt af van dia 8" = all(spss_getal(e["omr", ], 3) == c(".471", "-.102", ".641"))
  )
  ct <- contrast_eenweg(r, c(-1, .5, .5))
  stopifnot(
    "Contrast Tests wijkt af van dia 16" = spss_getal(ct$c, 4) == "3.0000" && spss_getal(ct$se, 5) == ".70711" &&
      spss_getal(ct$t, 3) == "4.243" && ct$df == 6 && spss_p(ct$p2) == ".005" &&
      spss_getal(ct$lo, 4) == "1.2698" && spss_getal(ct$hi, 4) == "4.7302"
  )
  ph <- r$posthoc; rw <- ph[ph$i == 1 & ph$j == 2, ]
  stopifnot(
    "LSD rakkers-welpen wijkt af van dia 32" = spss_getal(rw$verschil, 5) == "-3.00000" &&
      spss_getal(rw$se, 5) == ".81650" && spss_p(rw$p_lsd) == ".010" &&
      spss_getal(rw$lo_lsd, 4) == "-4.9979" && spss_getal(rw$hi_lsd, 4) == "-1.0021",
    "Bonferroni rakkers-welpen wijkt af van dia 32" = spss_p(rw$p_bon) == ".031" &&
      spss_getal(rw$lo_bon, 4) == "-5.6842" && spss_getal(rw$hi_bon, 4) == "-.3158"
  )
  # dia 37/43/44: het sportvoorbeeld (vijftien kinderen, drie groepen van vijf)
  y2 <- c(10, 12, 11, 14, 13, 9, 8, 7, 10, 9, 15, 16, 14, 15, 14); g2 <- rep(1:3, each = 5)
  r2 <- anova_eenweg(y2, g2); e2 <- r2$eff
  stopifnot(
    "ANOVA sport wijkt af van dia 43" = spss_getal(r2$SSG, 3) == "96.400" && spss_getal(r2$MSE, 3) == "1.500" &&
      spss_getal(r2$F, 3) == "32.133" && spss_p(r2$p) == "<.001",
    "Effectgroottes sport wijken af van dia 43" =
      all(spss_getal(e2["eta", ], 3) == c(".843", ".533", ".900")) &&
      all(spss_getal(e2["eps", ], 3) == c(".816", ".455", ".884")) &&
      all(spss_getal(e2["omf", ], 3) == c(".806", ".438", ".877")) &&
      all(spss_getal(e2["omr", ], 3) == c(".675", ".281", ".780"))
  )
  ph2 <- r2$posthoc; rw2 <- ph2[ph2$i == 1 & ph2$j == 2, ]
  stopifnot(
    "LSD sport 1-2 wijkt af van dia 44" = spss_getal(rw2$verschil, 5) == "3.40000" &&
      spss_getal(rw2$se, 5) == ".77460" && spss_p(rw2$p_lsd) == "<.001" &&
      spss_getal(rw2$lo_lsd, 4) == "1.7123" && spss_getal(rw2$hi_lsd, 4) == "5.0877",
    "Bonferroni sport 1-2 wijkt af van dia 44" = spss_p(rw2$p_bon) == ".003" &&
      spss_getal(rw2$lo_bon, 4) == "1.2470" && spss_getal(rw2$hi_bon, 4) == "5.5530",
    # Tabel E: de waarden die college 3 (dia 47) uit het boek fotografeert, df 2 en 6
    "Tabel E wijkt af van de foto op dia 47" = all(tabel_E(2, 6) == c(3.46, 5.14, 7.26, 10.92, 27.00))
  )
})
