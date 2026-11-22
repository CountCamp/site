# Nagebouwde SPSS-uitvoer van Analyze > General Linear Model > Univariate,
# voor een eenweg-ANCOVA: één factor, één covariaat. Thema 9.
#
# Bouwt voort op spss_uitvoer.R (spss_tabel, kc, spss_getal, spss_p,
# spss_toon, spss_noot); dat bestand moet eerst gesourced zijn.
#
# Wat hier gerekend wordt, en hoe:
#   - Type-III-kwadratensommen zoals SPSS: de kwadratensom van een term is de
#     restkwadratensom van het model zónder de kolommen van die term, min die
#     van het volledige model, met sum-to-zero-codering van de factor en de
#     covariaat NIET gecentreerd (zo doet SPSS het; in het model met interactie
#     gaan de hoofdeffecten daardoor over de covariaat = 0, en daarom zegt het
#     thema: lees in dat model alleen de interactierij).
#   - Parameter Estimates met de laatste categorie als referentie ("set to zero
#     because it is redundant"), zoals SPSS.
#   - Estimated Marginal Means bij het grote gemiddelde van de covariaat, met
#     de standaardfout sqrt(MS_e * (1/n_j + (C_j - C)^2 / SS_C,within)), en de
#     paarsgewijze vergelijking (LSD) met sqrt(MS_e * (1/n_i + 1/n_j +
#     (C_i - C_j)^2 / SS_C,within)).
#   - Levene op het gemiddelde (de rij "Based on Mean" van SPSS 27 en later;
#     de drie andere rijen van die tabel staan er niet), gerekend op de
#     absolute residuen van het model mét de covariaat, per groep. Waarom:
#     SPSS drukt onder die tabel "Design: Intercept + <covariaat> + <factor>",
#     en die voetnoot zegt dat de toets van het model afhangt. Zonder
#     covariaat zijn die residuen gewoon de afstanden tot het groepsgemiddelde
#     (de Levene van thema 3). NIET nagemeten in SPSS zelf (21-11-2026); tot
#     18-11 rekende deze helper op de afstanden tot het groepsgemiddelde, wat
#     bij de raven 0.15 / .70 gaf in plaats van 0.08 / .78.
#
# Getoetst bij het laden tegen car::Anova(type = 3) en emmeans::emmeans als
# die pakketten er zijn (op broodje: ja, 18-11-2026); zie onderaan. Staan ze
# er niet, dan draait de zelftoets niet en zegt hij dat.
#
# Wat NIET is nagemeten in SPSS zelf: het aantal decimalen per kolom. We
# volgen SPSS' gewoonte in GLM: drie decimalen voor kwadratensommen, F,
# schattingen en gemiddelden; Sig. drie; partial eta squared drie.

stopifnot("source eerst _common/ozp2/spss_uitvoer.R" = exists("spss_tabel"))

# ---- rekenen ----------------------------------------------------------------
glm_rss <- function(X, y) sum(lm.fit(X, y)$residuals^2)

# Type-III-tabel voor een model met factor g (sum-to-zero), covariaat c en
# eventueel hun interactie. Geeft per term SS, df, MS, F, p en partial eta^2.
glm_type3 <- function(y, g, c, interactie = FALSE) {
  G <- model.matrix(~ g, contrasts.arg = list(g = "contr.sum"))[, -1, drop = FALSE]
  X <- cbind(1, G, c)
  kol <- list(Intercept = 1, g = 2:(1 + ncol(G)), c = 2 + ncol(G))
  if (interactie) {
    X <- cbind(X, G * c)
    kol$gc <- (3 + ncol(G)):ncol(X)
  }
  vol <- glm_rss(X, y)
  N <- length(y); df_e <- N - ncol(X)
  ss_ct <- sum((y - mean(y))^2)
  rij <- function(ss, df) {
    ms <- ss / df; F <- ms / (vol / df_e)
    c(ss = ss, df = df, ms = ms, F = F, p = pf(F, df, df_e, lower.tail = FALSE),
      eta = ss / (ss + vol))
  }
  uit <- list(model = rij(ss_ct - vol, ncol(X) - 1))
  for (nm in names(kol)) uit[[nm]] <- rij(glm_rss(X[, -kol[[nm]], drop = FALSE], y) - vol,
                                          length(kol[[nm]]))
  uit$error <- c(ss = vol, df = df_e, ms = vol / df_e, F = NA, p = NA, eta = NA)
  uit$total <- c(ss = sum(y^2), df = N, ms = NA, F = NA, p = NA, eta = NA)
  uit$ctotal <- c(ss = ss_ct, df = N - 1, ms = NA, F = NA, p = NA, eta = NA)
  uit$r2 <- 1 - vol / ss_ct
  uit$r2adj <- 1 - (1 - uit$r2) * (N - 1) / df_e
  uit
}

# Alles wat het thema nodig heeft, in één lijst.
glm_ancova <- function(y, g, c, niveau = .95) {
  g <- factor(g)
  lev <- levels(g); I <- length(lev); N <- length(y)
  n_j <- as.vector(table(g))
  ym_j <- as.vector(tapply(y, g, mean)); ys_j <- as.vector(tapply(y, g, sd))
  cm_j <- as.vector(tapply(c, g, mean)); cs_j <- as.vector(tapply(c, g, sd))
  cm <- mean(c); ym <- mean(y)
  # helling binnen de groepen (gepoold) en de correlaties
  cw <- c - ave(c, g); yw <- y - ave(y, g)
  ss_cw <- sum(cw^2)
  b_w <- sum(cw * yw) / ss_cw
  b_j <- vapply(lev, function(l) coef(lm(y[g == l] ~ c[g == l]))[[2]], 0)
  r_tot <- cor(y, c); r_w <- cor(yw, cw)
  # de tabellen
  anc <- glm_type3(y, g, c)
  int <- glm_type3(y, g, c, interactie = TRUE)
  # alleen de factor (de gewone eenweg-ANOVA), ter vergelijking
  ss_g0 <- sum(n_j * (ym_j - ym)^2); ss_e0 <- sum(yw^2)
  anova0 <- list(g = c(ss = ss_g0, df = I - 1, ms = ss_g0 / (I - 1),
                       F = (ss_g0 / (I - 1)) / (ss_e0 / (N - I)),
                       p = pf((ss_g0 / (I - 1)) / (ss_e0 / (N - I)), I - 1, N - I, lower.tail = FALSE),
                       eta = ss_g0 / (ss_g0 + ss_e0)),
                 error = c(ss = ss_e0, df = N - I, ms = ss_e0 / (N - I), F = NA, p = NA, eta = NA))
  # parameterschattingen, laatste categorie als referentie
  # relevel zet de laatste categorie vooraan, en de gewone treatment-codering
  # maakt die dan de referentie; de dummy's die overblijven staan in de
  # oorspronkelijke volgorde g1, ..., g(I-1), zoals SPSS ze drukt
  gt <- relevel(g, ref = lev[I])
  m_tr <- lm(y ~ c + gt)
  co <- summary(m_tr)$coefficients
  stopifnot(nrow(co) == I + 1)
  df_e <- anc$error[["df"]]; tk <- qt(1 - (1 - niveau) / 2, df_e)
  par <- data.frame(B = co[, 1], se = co[, 2], t = co[, 3], p = co[, 4],
                    lo = co[, 1] - tk * co[, 2], hi = co[, 1] + tk * co[, 2],
                    eta = co[, 3]^2 / (co[, 3]^2 + df_e))
  rownames(par) <- c("Intercept", "c", paste0("g", seq_len(I - 1)))
  # gecorrigeerde gemiddelden (EMM)
  ms_e <- anc$error[["ms"]]
  emm <- ym_j - b_w * (cm_j - cm)
  emm_se <- sqrt(ms_e * (1 / n_j + (cm_j - cm)^2 / ss_cw))
  # paarsgewijs (LSD), elke i tegen elke j
  paren <- expand.grid(i = seq_len(I), j = seq_len(I)); paren <- paren[paren$i != paren$j, ]
  pw <- do.call(rbind, lapply(seq_len(nrow(paren)), function(k) {
    i <- paren$i[k]; j <- paren$j[k]
    d <- emm[i] - emm[j]
    se <- sqrt(ms_e * (1 / n_j[i] + 1 / n_j[j] + (cm_j[i] - cm_j[j])^2 / ss_cw))
    data.frame(i = i, j = j, diff = d, se = se, p = 2 * pt(-abs(d / se), df_e),
               lo = d - tk * se, hi = d + tk * se)
  }))
  # Levene op het gemiddelde, op de residuen van het ANCOVA-model (zie boven)
  z <- abs(residuals(lm(y ~ c + g))); lv <- anova(lm(z ~ g))
  list(
    lev = lev, I = I, N = N, n_j = n_j, ym_j = ym_j, ys_j = ys_j, ym = ym, ys = sd(y),
    cm_j = cm_j, cs_j = cs_j, cm = cm, cs = sd(c),
    b_w = b_w, b_j = b_j, ss_cw = ss_cw, r_tot = r_tot, r_w = r_w,
    anc = anc, int = int, anova0 = anova0, par = par,
    emm = emm, emm_se = emm_se, emm_lo = emm - tk * emm_se, emm_hi = emm + tk * emm_se,
    pw = pw, lev_F = lv$`F value`[1], lev_df1 = lv$Df[1], lev_df2 = lv$Df[2], lev_p = lv$`Pr(>F)`[1],
    df_e = df_e, ms_e = ms_e, tk = tk
  )
}

# ---- tekenen (SPSS-vorm) -------------------------------------------------------
# Descriptive Statistics (GLM): Mean, Std. Deviation, N per groep en Total.
spss_glm_descr <- function(r, uitkomst, factor_naam, d = 3) {
  rijen <- lapply(seq_len(r$I), function(j)
    c(r$lev[j], spss_getal(r$ym_j[j], d), spss_getal(r$ys_j[j], d), r$n_j[j]))
  rijen[[r$I + 1]] <- c("Total", spss_getal(r$ym, d), spss_getal(r$ys, d), r$N)
  spss_tabel("Descriptive Statistics",
             list(list(kc(factor_naam), kc("Mean"), kc("Std. Deviation"), kc("N"))),
             rijen, voetnoten = paste0("Dependent Variable: ", uitkomst), links = 1)
}

# Levene's Test of Equality of Error Variances, de rij "Based on Mean".
spss_glm_levene <- function(r, uitkomst, ontwerp) {
  spss_tabel("Levene's Test of Equality of Error Variances",
             list(list(kc(""), kc("Levene Statistic"), kc("df1"), kc("df2"), kc("Sig."))),
             list(c("Based on Mean", spss_getal(r$lev_F, 3), r$lev_df1, r$lev_df2, spss_p(r$lev_p))),
             voetnoten = c("Tests the null hypothesis that the error variance of the dependent variable is equal across groups.",
                           paste0("a. Dependent variable: ", uitkomst),
                           paste0("b. Design: ", ontwerp),
                           "(SPSS 27 en later drukt hieronder nog drie rijen, op de mediaan en het getrimde gemiddelde; die staan hier niet.)"),
             links = 1)
}

# Tests of Between-Subjects Effects. `t` is glm_type3(); `namen` koppelt de
# termen g, c en gc aan hun naam op het scherm.
spss_glm_tests <- function(t, uitkomst, namen, eta = TRUE) {
  rij <- function(naam, x, sup = "") {
    g <- function(v, dd = 3) if (is.na(v)) "" else spss_getal(v, dd)
    c(paste0(naam, sup), g(x[["ss"]]), x[["df"]], g(x[["ms"]]), g(x[["F"]]),
      if (is.na(x[["p"]])) "" else spss_p(x[["p"]]),
      if (eta) (if (is.na(x[["eta"]])) "" else spss_getal(x[["eta"]], 3)))
  }
  volg <- c("model", "Intercept", "c", "g", if (!is.null(t$gc)) "gc", "error", "total", "ctotal")
  lab <- c(model = "Corrected Model", Intercept = "Intercept", c = namen[["c"]], g = namen[["g"]],
           gc = if (!is.null(t$gc)) namen[["gc"]] else "", error = "Error", total = "Total",
           ctotal = "Corrected Total")
  rijen <- lapply(volg, function(k) rij(lab[[k]], t[[k]], if (k == "model") "ᵃ" else ""))
  kop <- list(kc("Source"), kc("Type III Sum of Squares"), kc("df"), kc("Mean Square"), kc("F"), kc("Sig."))
  if (eta) kop <- c(kop, list(kc("Partial Eta Squared")))
  spss_tabel("Tests of Between-Subjects Effects", list(kop), rijen,
             voetnoten = c(paste0("Dependent Variable: ", uitkomst),
                           sprintf("a. R Squared = %s (Adjusted R Squared = %s)",
                                   spss_getal(t$r2, 3), spss_getal(t$r2adj, 3))),
             links = 1)
}

# Parameter Estimates, laatste categorie "set to zero because it is redundant".
spss_glm_param <- function(r, uitkomst, cov_naam, factor_naam, codes = NULL) {
  if (is.null(codes)) codes <- r$lev
  p <- r$par
  rij <- function(naam, k) c(naam, spss_getal(p$B[k], 3), spss_getal(p$se[k], 3), spss_getal(p$t[k], 3),
                              spss_p(p$p[k]), spss_getal(p$lo[k], 3), spss_getal(p$hi[k], 3),
                              spss_getal(p$eta[k], 3))
  rijen <- list(rij("Intercept", 1), rij(cov_naam, 2))
  for (j in seq_len(r$I - 1)) rijen[[length(rijen) + 1]] <- rij(sprintf("[%s=%s]", factor_naam, codes[j]), 2 + j)
  rijen[[length(rijen) + 1]] <- c(sprintf("[%s=%s]", factor_naam, codes[r$I]), "0ᵃ", ".", ".", ".", ".", ".", ".")
  spss_tabel("Parameter Estimates",
             list(list(kc("Parameter", rows = 2), kc("B", rows = 2), kc("Std. Error", rows = 2),
                       kc("t", rows = 2), kc("Sig.", rows = 2), kc("95% Confidence Interval", cols = 2),
                       kc("Partial Eta Squared", rows = 2)),
                  list(kc("Lower Bound"), kc("Upper Bound"))),
             rijen, voetnoten = c(paste0("Dependent Variable: ", uitkomst),
                                  "a. This parameter is set to zero because it is redundant."),
             links = 1)
}

# Estimated Marginal Means voor de factor, met de noot over de covariaat.
spss_glm_emm <- function(r, uitkomst, factor_naam, cov_naam, dc = 2) {
  rijen <- lapply(seq_len(r$I), function(j)
    c(r$lev[j], paste0(spss_getal(r$emm[j], 3), if (j == 1) "ᵃ" else ""), spss_getal(r$emm_se[j], 3),
      spss_getal(r$emm_lo[j], 3), spss_getal(r$emm_hi[j], 3)))
  spss_tabel(paste0("Estimated Marginal Means: ", factor_naam),
             list(list(kc(factor_naam, rows = 2), kc("Mean", rows = 2), kc("Std. Error", rows = 2),
                       kc("95% Confidence Interval", cols = 2)),
                  list(kc("Lower Bound"), kc("Upper Bound"))),
             rijen, voetnoten = c(paste0("Dependent Variable: ", uitkomst),
                                  sprintf("a. Covariates appearing in the model are evaluated at the following values: %s = %s.",
                                          cov_naam, spss_getal(r$cm, dc))),
             links = 1)
}

# Pairwise Comparisons (LSD), zoals "Compare main effects" ze geeft.
spss_glm_pairwise <- function(r, uitkomst, factor_naam) {
  pw <- r$pw
  rijen <- lapply(seq_len(nrow(pw)), function(k)
    c(if (k == 1 || pw$i[k] != pw$i[k - 1]) r$lev[pw$i[k]] else "", r$lev[pw$j[k]],
      paste0(spss_getal(pw$diff[k], 3), if (pw$p[k] < .05) "*" else ""), spss_getal(pw$se[k], 3),
      spss_p(pw$p[k]), spss_getal(pw$lo[k], 3), spss_getal(pw$hi[k], 3)))
  spss_tabel("Pairwise Comparisons",
             list(list(kc(paste0("(I) ", factor_naam), rows = 2), kc(paste0("(J) ", factor_naam), rows = 2),
                       kc("Mean Difference (I-J)", rows = 2), kc("Std. Error", rows = 2), kc("Sig.ᵇ", rows = 2),
                       kc("95% Confidence Interval for Differenceᵇ", cols = 2)),
                  list(kc("Lower Bound"), kc("Upper Bound"))),
             rijen, voetnoten = c(paste0("Dependent Variable: ", uitkomst),
                                  "Based on estimated marginal means",
                                  "*. The mean difference is significant at the .05 level.",
                                  "b. Adjustment for multiple comparisons: Least Significant Difference (equivalent to no adjustments)."),
             links = 2)
}

# ---- zelftoets tegen car en emmeans -----------------------------------------------
# Op een vaste proefset: de Type-III-tabellen (met en zonder interactie) moeten
# die van car::Anova(type = 3) onder contr.sum zijn, en de EMM's en hun
# standaardfouten die van emmeans. Zakt bij het laden als dat niet zo is.
local({
  set.seed(9)
  g <- factor(rep(1:3, c(7, 9, 8))); c <- round(rnorm(24, 50, 10)); y <- round(10 + 0.3 * c + c(0, 2, 5)[g] + rnorm(24, 0, 3), 1)
  r <- glm_ancova(y, g, c)
  if (requireNamespace("car", quietly = TRUE) && requireNamespace("emmeans", quietly = TRUE)) {
    op <- options(contrasts = c("contr.sum", "contr.poly")); on.exit(options(op))
    a3 <- car::Anova(lm(y ~ g + c), type = 3); a3i <- car::Anova(lm(y ~ g * c), type = 3)
    em <- as.data.frame(summary(emmeans::emmeans(lm(y ~ g + c), ~ g)))
    stopifnot(
      "Type III (zonder interactie) wijkt af van car" =
        all(abs(c(r$anc$Intercept[["ss"]], r$anc$g[["ss"]], r$anc$c[["ss"]], r$anc$error[["ss"]]) -
                  a3[c("(Intercept)", "g", "c", "Residuals"), "Sum Sq"]) < 1e-8),
      "Type III (met interactie) wijkt af van car" =
        all(abs(c(r$int$g[["ss"]], r$int$c[["ss"]], r$int$gc[["ss"]], r$int$error[["ss"]]) -
                  a3i[c("g", "c", "g:c", "Residuals"), "Sum Sq"]) < 1e-8),
      "EMM wijkt af van emmeans" = all(abs(r$emm - em$emmean) < 1e-8),
      "SE van EMM wijkt af van emmeans" = all(abs(r$emm_se - em$SE) < 1e-8)
    )
    assign("glm_zelftoets", "car en emmeans: gelijk", envir = globalenv())
  } else {
    assign("glm_zelftoets", "car of emmeans ontbreekt: niet getoetst", envir = globalenv())
  }
  # wat altijd moet kloppen, ook zonder die pakketten: de EMM-formule, en de
  # parameterschattingen als regressievergelijking (dummy = gecorrigeerd
  # verschil met de referentiegroep; intercept = de referentiegroep bij c = 0)
  stopifnot(all(abs(r$emm - (r$ym_j - r$b_w * (r$cm_j - r$cm))) < 1e-12),
            abs(sum(r$pw$diff[r$pw$i == 1 & r$pw$j == 2] + r$emm[2] - r$emm[1])) < 1e-12,
            abs(r$par$B[3] - (r$emm[1] - r$emm[3])) < 1e-8,
            abs(r$par$B[4] - (r$emm[2] - r$emm[3])) < 1e-8,
            abs(r$par$B[2] - r$b_w) < 1e-12,
            abs(r$par$B[1] - (r$emm[3] - r$b_w * r$cm)) < 1e-8)
  # Levene: op de residuen van het model met de covariaat, en dus niet op de
  # afstanden tot het groepsgemiddelde (dat zou de covariaat negeren)
  z_mod <- abs(residuals(lm(y ~ c + g))); z_gem <- abs(y - ave(y, g))
  stopifnot(abs(r$lev_F - anova(lm(z_mod ~ g))$`F value`[1]) < 1e-10,
            abs(r$lev_F - anova(lm(z_gem ~ g))$`F value`[1]) > 1e-6,
            r$lev_df1 == r$I - 1, r$lev_df2 == r$N - r$I)
})
