# Tweeweg-ANOVA voor thema 6 van het oefenboek OZP 2: rekenen, en de uitvoer van
# Analyze > General Linear Model > Univariate nabouwen in SPSS-vorm.
#
# Hoort NA ../_common/ozp2/spss_uitvoer.R geladen te worden: de tabellen gaan
# via spss_tabel(), kc(), spss_getal() en spss_p() uit dat bestand.
#
#   tweeweg(y, A, B)             rekent alles uit: celgemiddelden, randen,
#                                kwadratensommen (Type III, zoals SPSS), df, MS,
#                                F, p, partial eta-kwadraat, R-kwadraat.
#   spss_factoren(r, ...)        de tabel Between-Subjects Factors
#   spss_descr(r, ...)           de tabel Descriptive Statistics
#   spss_tbse(r, ...)            de tabel Tests of Between-Subjects Effects
#   kritF(p, df1, df2)           een kritische F zoals Tabel E hem drukt
#   klemF(F, df1, df2)           tussen welke twee kolommen van Tabel E ligt F?
#
# Type III. SPSS drukt "Type III Sum of Squares". Bij een gebalanceerd design
# (evenveel waarnemingen per cel) is dat hetzelfde als de gewone opsplitsing
# SST = SSA + SSB + SSAB + SSE, en de zelftoets onderaan eist dat ook. Bij een
# ongebalanceerd design tellen de Type III-kwadratensommen niet meer op tot SST;
# tweeweg() rekent ze dan uit via som-tot-nul-contrasten en drop1(), de weg die
# R zonder extra pakket biedt.
#
# Decimalen. In de uitvoer van Univariate drukt SPSS het gemiddelde met vier
# decimalen en de standaardafwijking met vijf (afgelezen van twee echte
# SPSS-tabellen op de collegedia's 25 en 38 van college 6, 2026-27); in de
# ANOVA-tabel staan kwadratensommen, MS, F, Sig. en Partial Eta Squared alle
# met drie. Dat volgen we; een tabel uit SPSS zelf hebben we er niet naast
# gelegd.

stopifnot("laad eerst spss_uitvoer.R" = exists("spss_tabel"))

tweeweg <- function(y, A, B) {
  y <- as.numeric(y)
  A <- if (is.factor(A)) A else factor(A)
  B <- if (is.factor(B)) B else factor(B)
  stopifnot(length(y) == length(A), length(A) == length(B), !anyNA(y))
  I <- nlevels(A); J <- nlevels(B); N <- length(y)
  n_cel <- table(A, B)
  stopifnot("elke cel heeft minstens twee waarnemingen" = all(n_cel >= 2))
  m_cel <- tapply(y, list(A, B), mean)
  s_cel <- tapply(y, list(A, B), sd)
  m_A <- tapply(y, A, mean); s_A <- tapply(y, A, sd); n_A <- table(A)
  m_B <- tapply(y, B, mean); s_B <- tapply(y, B, sd); n_B <- table(B)
  m_tot <- mean(y); s_tot <- sd(y)

  # Type III via som-tot-nul-contrasten en drop1 (elke term eruit uit het volle
  # model). Bij een gebalanceerd design gelijk aan anova(), en dat wordt
  # onderaan getoetst.
  mod <- lm(y ~ A * B, contrasts = list(A = contr.sum, B = contr.sum))
  d1 <- drop1(mod, scope = ~ A + B + A:B, test = "F")
  ss <- c(A = d1["A", "Sum of Sq"], B = d1["B", "Sum of Sq"], AB = d1["A:B", "Sum of Sq"],
          E = deviance(mod))
  ss["T"] <- sum((y - m_tot)^2)
  ss["model"] <- ss["T"] - ss["E"]          # Corrected Model
  ss["intercept"] <- N * m_tot^2
  ss["totaal_ongecorrigeerd"] <- sum(y^2)    # de rij Total in SPSS
  df <- c(A = I - 1, B = J - 1, AB = (I - 1) * (J - 1), E = N - I * J,
          T = N - 1, model = I * J - 1, intercept = 1, totaal_ongecorrigeerd = N)
  ms <- ss[c("A", "B", "AB", "E", "model", "intercept")] / df[c("A", "B", "AB", "E", "model", "intercept")]
  F_ <- ms[c("A", "B", "AB", "model", "intercept")] / ms["E"]
  p <- pf(F_, df[names(F_)], df["E"], lower.tail = FALSE)
  peta <- ss[c("A", "B", "AB", "model", "intercept")] /
    (ss[c("A", "B", "AB", "model", "intercept")] + ss["E"])
  R2 <- ss["model"] / ss["T"]
  R2adj <- 1 - (1 - R2) * (N - 1) / (N - I * J)
  # eta-kwadraat (niet partieel), ter vergelijking: SS_effect / SS_T
  eta <- ss[c("A", "B", "AB")] / ss["T"]
  list(
    I = I, J = J, N = N, niveaus_A = levels(A), niveaus_B = levels(B),
    n_cel = n_cel, m_cel = m_cel, s_cel = s_cel,
    m_A = m_A, s_A = s_A, n_A = n_A, m_B = m_B, s_B = s_B, n_B = n_B,
    m_tot = m_tot, s_tot = s_tot,
    ss = ss, df = df, ms = ms, F = F_, p = p, peta = peta, eta = eta,
    R2 = unname(R2), R2adj = unname(R2adj),
    gebalanceerd = length(unique(as.vector(n_cel))) == 1
  )
}

# ---- Tabel E (de F-tabel van Moore, McCabe & Craig) ----------------------------
# Kolommen: de staartkans p. De tabel drukt de kritische F met twee decimalen.
kolommenF <- c(.100, .050, .025, .010, .001)
# De rijen (noemer-df) die de gedrukte tabel heeft. Uit het hoofd van testlezer
# Jeanne (18-11-2026: "de rijen gaan 28, 29, 30, 40, 50"), NIET nagemeten tegen
# het blad zelf -- er staat geen exemplaar in het huis. Tot dat gebeurd is,
# weigeren kritF() en klemF() elke andere rij: een eerdere versie drukte
# "kolom .05 geeft 3.22" voor df = (2, 42), een rij die op papier niet bestaat.
rijen_tabel_E <- c(1:30, 40, 50)
kritF <- function(p, df1, df2) {
  stopifnot("de F-tabel (Tabel E) heeft deze noemer-df niet als rij (zie rijen_tabel_E)" = df2 %in% rijen_tabel_E)
  round(qf(1 - p, df1, df2), 2)
}
# Tussen welke twee kolommen ligt F? Geeft de p-range terug. Zakt als F zo dicht
# bij een tabelwaarde ligt dat afronden de kolom kan verwisselen, en als F links
# van de eerste kolom valt (dan is p > .100 en zeg je dat zo).
klemF <- function(F, df1, df2) {
  v <- kritF(kolommenF, df1, df2)
  stopifnot("F ligt op de rand van een tabelkolom" = all(abs(F - v) > .02))
  i <- sum(v < F)
  if (i == 0) return(c(hoog = 1, laag = .100, F_laag = NA, F_hoog = v[1]))
  if (i == length(kolommenF)) return(c(hoog = .001, laag = 0, F_laag = v[i], F_hoog = NA))
  c(hoog = kolommenF[i], laag = kolommenF[i + 1], F_laag = v[i], F_hoog = v[i + 1])
}

# ---- de tabellen van Univariate --------------------------------------------------
# Between-Subjects Factors: per factor de codes, hun label en N.
spss_factoren <- function(r, naam_A, naam_B, codes_A = seq_len(r$I), codes_B = seq_len(r$J)) {
  rijen <- c(
    lapply(seq_len(r$I), function(i) c(if (i == 1) naam_A else "", codes_A[i],
                                       r$niveaus_A[i], as.integer(r$n_A[i]))),
    lapply(seq_len(r$J), function(j) c(if (j == 1) naam_B else "", codes_B[j],
                                       r$niveaus_B[j], as.integer(r$n_B[j])))
  )
  spss_tabel("Between-Subjects Factors",
             list(list(kc(""), kc(""), kc("Value Label"), kc("N"))),
             rijen, links = 3)
}

# Descriptive Statistics: per niveau van A alle niveaus van B plus Total, dan
# het Total-blok. Dependent Variable staat erboven zoals SPSS het drukt.
spss_descr <- function(r, uitkomst, naam_A, naam_B, md = 4, sd_d = 5) {
  rij <- function(a, b, m, s, n) c(a, b, spss_getal(m, md), spss_getal(s, sd_d), as.integer(n))
  rijen <- list()
  for (i in seq_len(r$I)) {
    for (j in seq_len(r$J)) {
      rijen[[length(rijen) + 1]] <- rij(if (j == 1) r$niveaus_A[i] else "", r$niveaus_B[j],
                                        r$m_cel[i, j], r$s_cel[i, j], r$n_cel[i, j])
    }
    rijen[[length(rijen) + 1]] <- rij("", "Total", r$m_A[i], r$s_A[i], r$n_A[i])
  }
  for (j in seq_len(r$J)) {
    rijen[[length(rijen) + 1]] <- rij(if (j == 1) "Total" else "", r$niveaus_B[j],
                                      r$m_B[j], r$s_B[j], r$n_B[j])
  }
  rijen[[length(rijen) + 1]] <- rij("", "Total", r$m_tot, r$s_tot, r$N)
  spss_tabel("Descriptive Statistics",
             list(list(kc(paste("Dependent Variable:", uitkomst), cols = 5)),
                  list(kc(naam_A), kc(naam_B), kc("Mean"), kc("Std. Deviation"), kc("N"))),
             rijen, links = 2)
}

# Tests of Between-Subjects Effects, mét de kolom Partial Eta Squared (die
# verschijnt in SPSS als je bij Options "Estimates of effect size" aanvinkt).
spss_tbse <- function(r, uitkomst, naam_A, naam_B, peta = TRUE) {
  g <- function(x, d = 3) spss_getal(x, d)
  rij <- function(bron, k) {
    c(bron, g(r$ss[k]), as.integer(r$df[k]),
      if (k %in% names(r$ms)) g(r$ms[k]) else "",
      if (k %in% names(r$F)) g(r$F[k]) else "",
      if (k %in% names(r$p)) spss_p(r$p[k]) else "",
      if (peta) (if (k %in% names(r$peta)) g(r$peta[k]) else "") else NULL)
  }
  rijen <- list(
    rij("Corrected Model", "model"), rij("Intercept", "intercept"),
    rij(naam_A, "A"), rij(naam_B, "B"), rij(paste(naam_A, "*", naam_B), "AB"),
    rij("Error", "E"), rij("Total", "totaal_ongecorrigeerd"), rij("Corrected Total", "T")
  )
  rijen[[1]][2] <- paste0(rijen[[1]][2], "ᵃ")   # het voetnootletter a
  kop <- list(kc("Source"), kc("Type III Sum of Squares"), kc("df"), kc("Mean Square"),
              kc("F"), kc("Sig."))
  if (peta) kop <- c(kop, list(kc("Partial Eta Squared")))
  spss_tabel("Tests of Between-Subjects Effects",
             list(list(kc(paste("Dependent Variable:", uitkomst), cols = length(kop))), kop),
             rijen,
             voetnoten = sprintf("a. R Squared = %s (Adjusted R Squared = %s)",
                                 g(r$R2), g(r$R2adj)),
             links = 1)
}

# ---- zelftoets --------------------------------------------------------------------
# Een gebalanceerd 2 x 2 met bekende antwoorden (het tentamen OZP 2 van 2023,
# opgave 4: celgemiddelden 10, 22, 15, 19 bij n = 5 per cel geven MSAB = 80).
# Plus: de Type III-weg geeft bij balans dezelfde kwadratensommen als anova(),
# en de drie effect-kwadratensommen plus de error tellen op tot SST.
local({
  mu <- c(10, 22, 15, 19)
  y <- as.vector(sapply(mu, function(m) m + c(-2, -1, 0, 1, 2)))
  A <- rep(c("hoog", "hoog", "laag", "laag"), each = 5)
  B <- rep(c("placebo", "middel"), each = 5, times = 2)
  r <- tweeweg(y, A, B)
  a <- anova(lm(y ~ factor(A) * factor(B)))
  stopifnot(
    abs(r$ms["AB"] - 80) < 1e-9,
    abs(r$ss["A"] - a["factor(A)", "Sum Sq"]) < 1e-9,
    abs(r$ss["B"] - a["factor(B)", "Sum Sq"]) < 1e-9,
    abs(r$ss["AB"] - a["factor(A):factor(B)", "Sum Sq"]) < 1e-9,
    abs(sum(r$ss[c("A", "B", "AB", "E")]) - r$ss["T"]) < 1e-9,
    r$df["E"] == 16, r$gebalanceerd,
    # Tabel E: F(1, 16) bij .05 is 4.49, bij .01 is 8.53 (Moore, McCabe & Craig)
    kritF(.05, 1, 16) == 4.49, kritF(.01, 1, 16) == 8.53,
    klemF(8, 1, 16)[["hoog"]] == .025, klemF(8, 1, 16)[["laag"]] == .010,
    # een rij die de tabel niet heeft, wordt geweigerd
    inherits(try(kritF(.05, 2, 42), silent = TRUE), "try-error")
  )
})
