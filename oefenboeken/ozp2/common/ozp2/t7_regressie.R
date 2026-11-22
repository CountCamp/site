# Regressie voor het oefenboek OZP 2 (thema 7 en 8): rekenen, nagebouwde
# SPSS-uitvoer, en de tabellen D (t) en E (F).
#
# Verwacht dat getallen.R en spss_uitvoer.R al geladen zijn (spss_tabel(), kc(),
# spss_getal(), spss_p(), nr()). Hoe en waarom de uitvoer nagebouwd is, staat in
# de kop van spss_uitvoer.R: SPSS draait op broodje niet zonder scherm.
#
# Wat er wel en niet is nagemeten tegen echte SPSS-uitvoer. De vorm en de
# decimalen volgen de Linear Regression-uitvoer op dia 42 van college 8
# (2026-27), als beeld bekeken op 18-11-2026: R, R Square en Adjusted R Square
# op drie decimalen zonder voorloopnul; Std. Error of the Estimate op vijf;
# kwadratensommen, Mean Square, B, Std. Error, t op drie; Beta op drie zonder
# voorloopnul; df heel; Sig. op drie, en onder .001 als "<.001" (de vorm van
# SPSS 28 en later, zoals de werkgroepuitvoer van 2026-27; die dia uit college 8
# komt van een oudere versie en drukt ".000"). Die dia is het enige echte
# SPSS-scherm dat we naast deze helper hebben gelegd; de getallen daarvan
# (R^2 .786, F 106.206, b1 35.336, SE 3.429, t 10.306) zijn niet na te rekenen
# zonder de data en zijn dus niet getoetst. De kolommen voor het
# betrouwbaarheidsinterval en de collineariteitsmaten verschijnen in SPSS alleen
# als je ze bij Statistics aanvinkt; de koppen zijn overgenomen zoals SPSS ze
# drukt ("95.0% Confidence Interval for B", "Collinearity Statistics").

# ---- rekenen ----------------------------------------------------------------
# reg_fit(y, X, namen): alles wat de uitvoer en de bladzijde nodig hebben, uit
# lm(). X is een data.frame of matrix met de voorspellers in de volgorde van
# `namen`. Geen letter t of F als objectnaam: die zijn in R al bezet.
reg_fit <- function(y, X, namen = colnames(X)) {
  X <- as.matrix(X); colnames(X) <- namen
  n <- length(y); p <- ncol(X)
  fit <- lm(y ~ X)
  b <- unname(coef(fit)); se <- unname(sqrt(diag(vcov(fit))))
  tval <- b / se; dfE <- n - p - 1
  p2 <- 2 * pt(-abs(tval), dfE)
  yh <- unname(fitted(fit)); e <- unname(resid(fit))
  SST <- sum((y - mean(y))^2); SSM <- sum((yh - mean(y))^2); SSE <- sum(e^2)
  MSM <- SSM / p; MSE <- SSE / dfE
  Fval <- MSM / MSE; pF <- pf(Fval, p, dfE, lower.tail = FALSE)
  R2 <- SSM / SST
  beta <- b[-1] * apply(X, 2, sd) / sd(y)
  tk <- qt(.975, dfE)
  tol <- if (p == 1) 1 else vapply(seq_len(p), function(j) {
    1 - summary(lm(X[, j] ~ X[, -j, drop = FALSE]))$r.squared
  }, 1)
  stopifnot(abs(SST - SSM - SSE) < 1e-8 * SST)
  list(
    n = n, p = p, namen = namen, b = b, se = se, t = tval, p2 = p2,
    lo = b - tk * se, hi = b + tk * se, tk = tk, beta = beta,
    yh = yh, e = e, SST = SST, SSM = SSM, SSE = SSE,
    dfM = p, dfE = dfE, dfT = n - 1, MSM = MSM, MSE = MSE,
    Fv = Fval, pF = pF, R2 = R2, R = sqrt(R2),
    R2adj = 1 - (1 - R2) * (n - 1) / dfE, s = sqrt(MSE),
    tol = tol, vif = 1 / tol, cor = cor(cbind(y, X))
  )
}

# ---- tekenen: de drie tabellen van Linear Regression -----------------------
# Elke functie neemt één fit of een lijst van fits (hiërarchisch: Model 1, 2, ...).
als_lijst <- function(fits) if (!is.null(fits$n)) list(fits) else fits
pred_noot <- function(fits) {
  fits <- als_lijst(fits)
  vapply(seq_along(fits), function(i) {
    sprintf("%s. Predictors: (Constant), %s", letters[i], paste(fits[[i]]$namen, collapse = ", "))
  }, "")
}

spss_model_summary <- function(fits, afh) {
  fits <- als_lijst(fits)
  rijen <- lapply(seq_along(fits), function(i) {
    f <- fits[[i]]
    c(i, paste0(spss_getal(f$R, 3), letters[i]), spss_getal(f$R2, 3),
      spss_getal(f$R2adj, 3), spss_getal(f$s, 5))
  })
  spss_tabel("Model Summary",
             list(list(kc("Model"), kc("R"), kc("R Square"), kc("Adjusted R Square"),
                       kc("Std. Error of the Estimate"))),
             rijen, voetnoten = pred_noot(fits), links = 1)
}

spss_anova_reg <- function(fits, afh) {
  fits <- als_lijst(fits)
  rijen <- list()
  for (i in seq_along(fits)) {
    f <- fits[[i]]
    rijen[[length(rijen) + 1]] <- c(i, "Regression", spss_getal(f$SSM, 3), f$dfM,
                                    spss_getal(f$MSM, 3), spss_getal(f$Fv, 3),
                                    paste0(spss_p(f$pF), letters[i + 1]))
    rijen[[length(rijen) + 1]] <- c("", "Residual", spss_getal(f$SSE, 3), f$dfE,
                                    spss_getal(f$MSE, 3), "", "")
    rijen[[length(rijen) + 1]] <- c("", "Total", spss_getal(f$SST, 3), f$dfT, "", "", "")
  }
  noot <- c(sprintf("a. Dependent Variable: %s", afh),
            sub("^([a-z])[.]", "", pred_noot(fits)))
  noot <- c(noot[1], paste0(letters[seq_along(fits) + 1], ".", noot[-1]))
  spss_tabel("ANOVAᵃ",
             list(list(kc("Model", cols = 2), kc("Sum of Squares"), kc("df"),
                       kc("Mean Square"), kc("F"), kc("Sig."))),
             rijen, voetnoten = noot, links = 2)
}

spss_coef <- function(fits, afh, ci = FALSE, collin = FALSE) {
  fits <- als_lijst(fits)
  rijen <- list()
  for (i in seq_along(fits)) {
    f <- fits[[i]]
    for (j in seq_along(f$b)) {
      naam <- if (j == 1) "(Constant)" else f$namen[j - 1]
      rij <- c(if (j == 1) i else "", naam, spss_getal(f$b[j], 3), spss_getal(f$se[j], 3),
               if (j == 1) "" else spss_getal(f$beta[j - 1], 3),
               spss_getal(f$t[j], 3), spss_p(f$p2[j]))
      if (ci) rij <- c(rij, spss_getal(f$lo[j], 3), spss_getal(f$hi[j], 3))
      if (collin) rij <- c(rij, if (j == 1) "" else spss_getal(f$tol[j - 1], 3),
                           if (j == 1) "" else spss_getal(f$vif[j - 1], 3))
      rijen[[length(rijen) + 1]] <- rij
    }
  }
  kop1 <- list(kc("Model", cols = 2, rows = 2), kc("Unstandardized Coefficients", cols = 2),
               kc("Standardized Coefficients", rows = 1), kc("t", rows = 2), kc("Sig.", rows = 2))
  kop2 <- list(kc("B"), kc("Std. Error"), kc("Beta"))
  if (ci) {
    kop1 <- c(kop1, list(kc("95.0% Confidence Interval for B", cols = 2)))
    kop2 <- c(kop2, list(kc("Lower Bound"), kc("Upper Bound")))
  }
  if (collin) {
    kop1 <- c(kop1, list(kc("Collinearity Statistics", cols = 2)))
    kop2 <- c(kop2, list(kc("Tolerance"), kc("VIF")))
  }
  spss_tabel("Coefficientsᵃ", list(kop1, kop2), rijen,
             voetnoten = sprintf("a. Dependent Variable: %s", afh), links = 2)
}

# De tabel van Analyze > Correlate > Bivariate: per variabele drie rijen.
# SPSS zet sterretjes bij significante correlaties; die laten we weg, de
# p-waarde staat er al.
spss_correlaties <- function(d, namen = colnames(d)) {
  d <- as.data.frame(d); k <- ncol(d); n <- nrow(d)
  cm <- cor(d)
  rijen <- list()
  for (i in seq_len(k)) {
    pr <- vapply(seq_len(k), function(j) {
      if (i == j) return("")
      ct <- cor.test(d[[i]], d[[j]]); spss_p(ct$p.value)
    }, "")
    rijen[[length(rijen) + 1]] <- c(namen[i], "Pearson Correlation",
                                    vapply(seq_len(k), function(j) {
                                      if (i == j) "1" else spss_getal(cm[i, j], 3)
                                    }, ""))
    rijen[[length(rijen) + 1]] <- c("", "Sig. (2-tailed)", pr)
    rijen[[length(rijen) + 1]] <- c("", "N", rep(n, k))
  }
  spss_tabel("Correlations",
             list(c(list(kc("", cols = 2)), lapply(namen, kc))),
             rijen, links = 2)
}

# ---- Tabel D (t) en Tabel E (F) --------------------------------------------
# Tabel D zoals thema 1 hem leest (dezelfde twaalf kolommen en dezelfde
# klem()); hier gekopieerd omdat thema 1 hem in zijn eigen bladzijde zet.
# Kandidaat voor getallen.R.
kolommen_D <- c(.25, .20, .15, .10, .05, .025, .02, .01, .005, .0025, .001, .0005)
tw <- function(p, df) round(qt(1 - p, df), 3)
klem <- function(t, df) {
  a <- abs(t); v <- tw(kolommen_D, df)
  stopifnot("t ligt op de rand van een tabelkolom" = all(abs(a - v) > .004))
  i <- sum(v < a)
  stopifnot("t valt buiten de tabel" = i >= 1, i < length(kolommen_D))
  c(hoog = kolommen_D[i], laag = kolommen_D[i + 1], t_hoog = v[i + 1], t_laag = v[i])
}

# Tabel E (Moore, McCabe & Craig): per (df1, df2) de kritieke F bij vijf
# staartkansen, op twee decimalen zoals de tabel hem drukt. Let op de vorm van
# die tabel: de teller-df staan als KOLOMMEN, en binnen elk blok van een
# noemer-df staan de vijf kansen als RIJEN (.100, .050, .025, .010, .001). Op de
# bladzijde heet een kans dus een regel van Tabel E, niet een kolom (testlezer
# Jeanne, 18-11-2026). Een F-toets is altijd rechtseenzijdig: de range is
# meteen de p (geen keer twee).
kansen_E <- c(.100, .050, .025, .010, .001)
fw <- function(p, df1, df2) round(qf(1 - p, df1, df2), 2)
klemF <- function(Fv, df1, df2) {
  v <- fw(kansen_E, df1, df2)
  stopifnot("F ligt op de rand van een regel van Tabel E" = all(abs(Fv - v) > .03))
  i <- sum(v < Fv)
  stopifnot("F valt onder .100 of voorbij .001: geen range uit Tabel E" = i >= 1, i < length(kansen_E))
  c(hoog = kansen_E[i], laag = kansen_E[i + 1], F_hoog = v[i + 1], F_laag = v[i])
}
# Het blok van Tabel E voor één (df1, df2) als markdown, met de gevonden F op
# zijn plek tussen de regels; zoals het stukje Tabel D in thema 1 en 7.
strook_E <- function(Fv, df1, df2) {
  v <- fw(kansen_E, df1, df2)
  plek <- sum(v < Fv)
  k <- sub("^0", "", formatC(kansen_E, format = "f", digits = 3))
  rijen <- c(sprintf("| %s | %s |", k[seq_len(plek)], nr(v[seq_len(plek)], 2)),
             sprintf("| | **%s** ← jouw *F* |", nr(Fv, 2)),
             if (plek < length(v)) sprintf("| %s | %s |", k[(plek + 1):length(v)], nr(v[(plek + 1):length(v)], 2)))
  paste(c(sprintf("| staartkans | $F^*$ bij $df = (%d, %d)$ |", df1, df2), "|:-:|:-:|", rijen), collapse = "\n")
}

# ---- zelftoets --------------------------------------------------------------
# Op de uilen van thema 7 (doelgetallen uit _common/data/maak_data_t7.R):
# b1 = 4, SE 1.0607, t(8) = 3.771, R^2 = .64, F(1, 8) = 14.22, en hetzelfde
# model via reg_fit() en via lm() rechtstreeks. En Tabel D/E op bekende
# waarden: t*(df 8, .025) = 2.306; F*(1, 8, .05) = 5.32.
local({
  x <- c(1, 1, 2, 2, 3, 3, 4, 4, 5, 5); y <- c(34, 30, 41, 31, 43, 37, 50, 38, 52, 44)
  f <- reg_fit(y, data.frame(x = x), "x")
  stopifnot(
    abs(f$b[2] - 4) < 1e-12, nr(f$se[2], 4) == "1.0607", nr(f$t[2], 3) == "3.771",
    abs(f$R2 - .64) < 1e-12, nr(f$Fv, 2) == "14.22", f$dfE == 8,
    abs(f$Fv - f$t[2]^2) < 1e-9, abs(f$beta - .8) < 1e-12, f$tol == 1,
    tw(.025, 8) == 2.306, fw(.05, 1, 8) == 5.32,
    klem(3.771, 8)[["hoog"]] == .005, klem(3.771, 8)[["laag"]] == .0025,
    klemF(14.22, 1, 8)[["hoog"]] == .010, klemF(14.22, 1, 8)[["laag"]] == .001,
    # de strook zet de F tussen de regels .010 en .001
    grepl("\\| .010 \\| 11.26 \\|\n\\| \\| \\*\\*14.22\\*\\* ← jouw \\*F\\* \\|\n\\| .001 \\| 25.41 \\|$",
          strook_E(14.22, 1, 8))
  )
})
