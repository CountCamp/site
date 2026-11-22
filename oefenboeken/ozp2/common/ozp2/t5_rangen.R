# Thema 5 (Kruskal-Wallis): rangen, H, epsilon-kwadraat, Dunn en de nagebouwde
# SPSS-uitvoer. Eigen helper van thema 5 (prefix t5_), los van thema 2.
#
# Wat hier staat volgt het formuleblad OP 2 2025-26 (Eq. 53-57):
#   H     = 12 / (N(N+1)) * som(R_i^2 / n_i) - 3(N+1)          Eq. 53
#   df    = I - 1                                               Eq. 54
#   z_ij  = (Rbar_i - Rbar_j) / SE_ij                           Eq. 55
#   SE_ij = sqrt( N(N+1)/12 * (1/n_i + 1/n_j) )                 Eq. 56
#   eps2  = (H - I + 1) / (N - I)                               Eq. 57
# Daarnaast wat SPSS extra doet en het formuleblad niet: de knopencorrectie.
#   H_knopen  = H / (1 - som(t^3 - t) / (N^3 - N))   (t = grootte van elke knoop)
#   SE_knopen = sqrt( (N(N+1)/12 - som(t^3 - t) / (12(N-1))) * (1/n_i + 1/n_j) )
# Zonder knopen zijn beide gelijk aan het formuleblad. Getoetst onderaan tegen de
# SPSS-getallen op college 5 (2026-27), dia 38 en 42: H = 16.855 en SE = 3.936
# bij N = 30 met twee knopen van twee (het formuleblad geeft daar 16.85 en 3.937).
#
# Vereist: spss_uitvoer.R (spss_tabel, kc, spss_getal, spss_p) is al gesourced.

t5_rang <- function(x) rank(x, ties.method = "average")

# Alles wat de Kruskal-Wallis-toets oplevert, uit scores y en groep g.
t5_kw <- function(y, g) {
  g <- factor(g, levels = unique(g))
  y <- as.numeric(y)
  N <- length(y); I <- nlevels(g)
  rk <- t5_rang(y)
  R  <- tapply(rk, g, sum)
  ni <- as.numeric(table(g))
  names(ni) <- levels(g)
  somR2n <- sum(R^2 / ni)
  H  <- 12 / (N * (N + 1)) * somR2n - 3 * (N + 1)
  tt <- table(rk); knopen <- as.numeric(tt[tt > 1])
  C  <- 1 - sum(knopen^3 - knopen) / (N^3 - N)
  H_knopen <- H / C
  list(
    N = N, I = I, ni = ni, R = R, Rbar = R / ni, somR2n = somR2n,
    factor = 12 / (N * (N + 1)), aftrek = 3 * (N + 1),
    H = H, df = I - 1, p = pchisq(H, I - 1, lower.tail = FALSE),
    knopen = knopen, C = C, H_knopen = H_knopen,
    p_knopen = pchisq(H_knopen, I - 1, lower.tail = FALSE),
    eps2 = (H - I + 1) / (N - I),
    rk = rk, y = y, g = g,
    mediaan = tapply(y, g, median), gem = tapply(y, g, mean), sd = tapply(y, g, sd)
  )
}

# Dunn: alle paren. knopen = TRUE geeft de SE die SPSS gebruikt.
t5_dunn <- function(kw, knopen = FALSE) {
  N <- kw$N; ni <- kw$ni; Rbar <- kw$Rbar; niv <- names(ni)
  corr <- if (knopen) sum(kw$knopen^3 - kw$knopen) / (12 * (N - 1)) else 0
  paren <- combn(seq_along(niv), 2)
  k <- ncol(paren)
  uit <- do.call(rbind, lapply(seq_len(k), function(m) {
    i <- paren[1, m]; j <- paren[2, m]
    se <- sqrt((N * (N + 1) / 12 - corr) * (1 / ni[i] + 1 / ni[j]))
    z  <- (Rbar[i] - Rbar[j]) / se
    p  <- 2 * pnorm(-abs(z))
    data.frame(i = niv[i], j = niv[j], verschil = Rbar[i] - Rbar[j], se = se, z = z,
               p = p, p_bonf = pmin(1, p * k), stringsAsFactors = FALSE)
  }))
  uit$k <- k
  uit$alpha_bonf <- .05 / k
  uit
}

# Tabel A (standaardnormaal) zoals de student hem leest: de kans links van z,
# op vier decimalen, met z op twee decimalen. Tweezijdig: 2 * (1 - die kans).
t5_tabel_a <- function(z) round(pnorm(round(abs(z), 2)), 4)
t5_p_tabel_a <- function(z) 2 * (1 - t5_tabel_a(z))

# Tussen welke twee kolommen van Tabel F (chi-kwadraat) valt H? Dezelfde
# staartkansen als Tabel D, zoals thema 1 die gebruikt. Zakt als H te dicht bij
# een grens ligt om nog veilig af te lezen, of buiten de tabel valt.
t5_kolommen <- c(.25, .20, .15, .10, .05, .025, .02, .01, .005, .0025, .001, .0005)
t5_chi_grens <- function(p, df) round(qchisq(1 - p, df), 2)
t5_klem_chi <- function(H, df, marge = .05) {
  v <- t5_chi_grens(t5_kolommen, df)
  stopifnot("H ligt op de rand van een kolom van Tabel F" = all(abs(H - v) > marge))
  i <- sum(v < H)
  if (i == 0) return(c(hoog = NA, laag = t5_kolommen[1], H_hoog = v[1], H_laag = NA))
  stopifnot("H valt voorbij de laatste kolom" = i < length(v))
  c(hoog = t5_kolommen[i], laag = t5_kolommen[i + 1], H_laag = v[i], H_hoog = v[i + 1])
}

# ---- SPSS-vorm (Nonparametric Tests > Independent Samples, Model Viewer) -------
t5_spss_kw <- function(kw) {
  spss_tabel(
    "Independent-Samples Kruskal-Wallis Test Summary",
    list(),
    list(c("Total N", as.character(kw$N)),
         c("Test Statistic", paste0(spss_getal(kw$H_knopen, 3), "ᵃ")),
         c("Degree Of Freedom", as.character(kw$df)),
         c("Asymptotic Sig.(2-sided test)", spss_p(kw$p_knopen))),
    voetnoten = "a. The test statistic is adjusted for ties.",
    links = 1)
}

# Paarsgewijze vergelijkingen zoals SPSS ze drukt: gesorteerd op gemiddelde rang
# (laag naar hoog), Sample 1 is steeds de groep met de laagste gemiddelde rang,
# en Test Statistic is Rbar(Sample 1) - Rbar(Sample 2). Die volgorde en dat
# teken zijn NIET tegen echte SPSS-uitvoer gelegd (zie _voor_meesterknecht.md);
# de grootte van elk getal wel (college 5, dia 42).
t5_spss_paren <- function(kw, groepnaam, labels = names(kw$ni)) {
  d <- t5_dunn(kw, knopen = TRUE)
  volg <- names(sort(kw$Rbar))
  rijen <- lapply(combn(volg, 2, simplify = FALSE), function(pr) {
    r <- d[(d$i == pr[1] & d$j == pr[2]) | (d$i == pr[2] & d$j == pr[1]), ]
    teken <- if (r$i == pr[1]) 1 else -1
    naam <- function(x) labels[match(x, names(kw$ni))]
    c(paste(naam(pr[1]), naam(pr[2]), sep = "-"),
      spss_getal(teken * r$verschil, 3), spss_getal(r$se, 3), spss_getal(teken * r$z, 3),
      spss_p(r$p), spss_p(r$p_bonf))
  })
  spss_tabel(
    paste("Pairwise Comparisons of", groepnaam),
    list(list(kc("Sample 1-Sample 2"), kc("Test Statistic"), kc("Std. Error"),
              kc("Std. Test Statistic"), kc("Sig."), kc("Adj. Sig.ᵃ"))),
    rijen,
    voetnoten = c("Each row tests the null hypothesis that the Sample 1 and Sample 2 distributions are the same.",
                  "Asymptotic significances (2-sided tests) are displayed. The significance level is .050.",
                  "a. Significance values have been adjusted by the Bonferroni correction for multiple tests."),
    links = 1)
}

# ---- toets tegen college 5 (2026-27), dia 35-42: de replicastudie ------------
# Scores afgelezen van dia 34 (als beeld), N = 30, drie groepen van tien.
# Rangsommen op dia 35: geen 70.5, team 231.5, individueel 163. H op dia 36:
# 16.85. SPSS op dia 38: 16.855 (adjusted for ties). Dia 41: SE = 3.937 met de
# hand; SPSS op dia 42: 3.936, z = 2.350 voor individueel - geen.
local({
  geen  <- c(0.3, 0.8, 1.0, 1.5, 1.6, 1.7, 2.0, 2.2, 2.7, 4.0)
  team  <- c(3.2, 3.5, 3.6, 3.8, 4.0, 4.3, 4.6, 4.8, 5.2, 5.7, 6.2, 6.3)
  indiv <- c(1.4, 1.9, 2.1, 2.3, 2.8, 2.9, 3.4, 3.4)
  # dia 34 kleurt de cellen; welke score bij welke groep hoort is daar deels
  # alleen uit de kleur te halen, en die lezing geeft hier 10/12/8. De
  # rangsommen van dia 35 (70.5 / 231.5 / 163) zijn wel hard: daarop toetsen we.
  # Met de rangsommen van de dia en n = 10 per groep:
  N <- 30; R <- c(geen = 70.5, team = 231.5, indiv = 163); ni <- c(10, 10, 10)
  H <- 12 / (N * (N + 1)) * sum(R^2 / ni) - 3 * (N + 1)
  knopen <- c(2, 2)                       # 3.4 twee keer, 4.0 twee keer (dia 34)
  C <- 1 - sum(knopen^3 - knopen) / (N^3 - N)
  se_fb <- sqrt(N * (N + 1) / 12 * (1 / 10 + 1 / 10))
  se_kn <- sqrt((N * (N + 1) / 12 - sum(knopen^3 - knopen) / (12 * (N - 1))) * (2 / 10))
  stopifnot(
    "H wijkt af van dia 36" = formatC(H, format = "f", digits = 2) == "16.85",
    "H met knopencorrectie wijkt af van SPSS (dia 38)" = formatC(H / C, format = "f", digits = 3) == "16.855",
    "SE formuleblad wijkt af van dia 41" = formatC(se_fb, format = "f", digits = 3) == "3.937",
    "SE met knopencorrectie wijkt af van SPSS (dia 42)" = formatC(se_kn, format = "f", digits = 3) == "3.936",
    "z wijkt af van dia 41" = formatC((163 / 10 - 70.5 / 10) / se_fb, format = "f", digits = 3) == "2.350",
    "Bonferroni-p wijkt af van SPSS (dia 42)" =
      formatC(min(1, 3 * 2 * pnorm(-(163 / 10 - 70.5 / 10) / se_kn)), format = "f", digits = 3) == "0.056"
  )
})
