# Nagebouwde SPSS-uitvoer voor het oefenboek OZP 2.
#
# Waarom nagebouwd. SPSS draait op broodje niet zonder scherm
# (ozp1_werkboek/2526_werkboek/_common/spss_helpers/README.md: "headless batch
# werkt op deze SPSS-install niet"), en PSPP staat er niet. De werkgroepen van
# OZP 2 vragen wél om output te LEZEN. Dus rekent R hier elke cel uit, en zet
# hij hem in de vorm van een SPSS-tabel. Onder elke tabel staat dat hij
# nagebouwd is (zie spss_noot()).
#
# Getoetst tegen echte SPSS-uitvoer (18-11-2026): Bens aantekening OZP1 2026,
# les 5, p. 11 (Bib: diagram-spss-one-sample-test-output-cijfer-t-2377) heeft
# een One-Sample Test met N = 13, t = 2.377, Std. Deviation 2.28709. Deze
# rekenwijze geeft daaruit exact SPSS' getallen terug: Cohen's d .659 met
# 95%-BI [.045 ; 1.251], Hedges' standardizer 2.44362, puntschatting .617,
# BI [.042 ; 1.171]. De toets daarvan staat onderaan dit bestand en draait bij
# elk laden.
#
# Wat NIET is nagemeten in SPSS zelf: het aantal decimalen per kolom. We volgen
# SPSS' gewoonte bij een variabele met hele getallen (opmaak F8.0): gemiddelde
# twee decimalen, de rest drie. Werkgroep 1 (2026-27) bevestigt dat patroon
# (gemiddelde 25.30, SD van de verschilscore 3.203), maar een tabel uit SPSS
# zelf hebben we niet naast deze gelegd.
#
# Wat er bewust NIET in staat: de rij "Glass's delta" uit de tabel
# Independent Samples Effect Sizes. Welke groep SPSS als controlegroep neemt
# hebben we niet kunnen natrekken; een verkeerde rij is erger dan geen.

# ---- getallen zoals SPSS ze drukt ------------------------------------------
# Punt als decimaalteken, geen voorloopnul tussen -1 en 1 (".634", "-.250").
spss_getal <- function(x, d = 3) {
  s <- formatC(x, format = "f", digits = d)
  sub("^(-?)0[.]", "\\1.", s)
}
spss_p <- function(p) if (p < .001) "<.001" else spss_getal(p, 3)

# ---- rekenen ----------------------------------------------------------------
# Betrouwbaarheidsinterval voor een gestandaardiseerd verschil via de
# niet-centrale t-verdeling: zoek de twee non-centraliteiten waarbij de
# gevonden t op 2,5% en 97,5% ligt. Zo doet SPSS het (getoetst hieronder).
bi_ncp <- function(t_obs, df, niveau = .95) {
  a <- (1 - niveau) / 2
  f <- function(ncp, p) suppressWarnings(pt(t_obs, df, ncp)) - p
  bereik <- c(t_obs - 40, t_obs + 40)
  c(uniroot(f, bereik, p = 1 - a, tol = 1e-10)$root,
    uniroot(f, bereik, p = a, tol = 1e-10)$root)
}
# Hedges' correctiefactor, de exacte vorm met gammafuncties (de benadering
# 1 - 3/(4df - 1) wijkt bij df = 12 al af in de vierde decimaal van de
# standardizer: 2.44303 tegen SPSS' 2.44362).
hedges_j <- function(df) exp(lgamma(df / 2) - log(sqrt(df / 2)) - lgamma((df - 1) / 2))

# Gepaarde t-toets zoals SPSS hem rekent: verschil = eerste min tweede.
t_gepaard <- function(x1, x2, niveau = .95) {
  stopifnot(length(x1) == length(x2))
  n <- length(x1); d <- x1 - x2; df <- n - 1
  md <- mean(d); sdd <- sd(d); se <- sdd / sqrt(n)
  tk <- qt(1 - (1 - niveau) / 2, df)
  t <- md / se
  r <- cor(x1, x2)
  t_r <- r * sqrt(n - 2) / sqrt(1 - r^2)
  ncp <- bi_ncp(t, df, niveau)
  J <- hedges_j(df)
  list(
    n = n, m1 = mean(x1), m2 = mean(x2), s1 = sd(x1), s2 = sd(x2),
    se1 = sd(x1) / sqrt(n), se2 = sd(x2) / sqrt(n),
    r = r, r_p2 = 2 * pt(-abs(t_r), n - 2),
    md = md, sdd = sdd, se = se, lo = md - tk * se, hi = md + tk * se,
    t = t, df = df, p2 = 2 * pt(-abs(t), df), p1 = pt(-abs(t), df),
    d = md / sdd, d_lo = ncp[1] / sqrt(n), d_hi = ncp[2] / sqrt(n),
    g_st = sdd / J, g = md / (sdd / J),
    g_lo = ncp[1] / sqrt(n) * J, g_hi = ncp[2] / sqrt(n) * J
  )
}

# Onafhankelijke t-toets zoals SPSS hem rekent: groep 1 min groep 2, beide
# rijen (gelijke varianties wel / niet aangenomen) en Levene op het gemiddelde.
t_onafh <- function(y1, y2, niveau = .95) {
  n1 <- length(y1); n2 <- length(y2)
  m1 <- mean(y1); m2 <- mean(y2); s1 <- sd(y1); s2 <- sd(y2)
  md <- m1 - m2
  # Levene (SPSS-standaard: afwijkingen van het groepsgemiddelde)
  z <- c(abs(y1 - m1), abs(y2 - m2)); g <- factor(rep(1:2, c(n1, n2)))
  lev <- anova(lm(z ~ g))
  # gelijke varianties aangenomen
  df_p <- n1 + n2 - 2
  sp <- sqrt(((n1 - 1) * s1^2 + (n2 - 1) * s2^2) / df_p)
  se_p <- sp * sqrt(1 / n1 + 1 / n2)
  t_p <- md / se_p
  # niet aangenomen (Welch)
  v1 <- s1^2 / n1; v2 <- s2^2 / n2
  se_w <- sqrt(v1 + v2)
  df_w <- (v1 + v2)^2 / (v1^2 / (n1 - 1) + v2^2 / (n2 - 1))
  t_w <- md / se_w
  a <- (1 - niveau) / 2
  ncp <- bi_ncp(t_p, df_p, niveau)
  schaal <- sqrt(1 / n1 + 1 / n2)
  J <- hedges_j(df_p)
  list(
    n1 = n1, n2 = n2, m1 = m1, m2 = m2, s1 = s1, s2 = s2,
    se1 = s1 / sqrt(n1), se2 = s2 / sqrt(n2),
    lev_F = lev$`F value`[1], lev_p = lev$`Pr(>F)`[1],
    md = md, sp = sp,
    t_p = t_p, df_p = df_p, p2_p = 2 * pt(-abs(t_p), df_p), p1_p = pt(-abs(t_p), df_p),
    se_p = se_p, lo_p = md - qt(1 - a, df_p) * se_p, hi_p = md + qt(1 - a, df_p) * se_p,
    t_w = t_w, df_w = df_w, p2_w = 2 * pt(-abs(t_w), df_w), p1_w = pt(-abs(t_w), df_w),
    se_w = se_w, lo_w = md - qt(1 - a, df_w) * se_w, hi_w = md + qt(1 - a, df_w) * se_w,
    d = md / sp, d_lo = ncp[1] * schaal, d_hi = ncp[2] * schaal,
    g_st = sp / J, g = md / (sp / J), g_lo = ncp[1] * schaal * J, g_hi = ncp[2] * schaal * J
  )
}

# ---- tekenen ----------------------------------------------------------------
# Een kopcel: tekst, en eventueel hoeveel kolommen/rijen hij overspant.
kc <- function(tekst, cols = 1, rows = 1) list(tekst = tekst, cols = cols, rows = rows)

spss_tabel <- function(titel, kop, rijen, voetnoten = NULL, links = 1) {
  esc <- function(x) htmltools::htmlEscape(x)
  kop_html <- vapply(kop, function(rij) {
    cellen <- vapply(rij, function(c) {
      sprintf('<th colspan="%d" rowspan="%d">%s</th>', c$cols, c$rows, esc(c$tekst))
    }, "")
    paste0("<tr>", paste(cellen, collapse = ""), "</tr>")
  }, "")
  lijf_html <- vapply(rijen, function(rij) {
    cellen <- vapply(seq_along(rij), function(i) {
      klasse <- if (i <= links) "spss-rij" else "spss-getal"
      sprintf('<td class="%s">%s</td>', klasse, esc(rij[[i]]))
    }, "")
    paste0("<tr>", paste(cellen, collapse = ""), "</tr>")
  }, "")
  noot_html <- if (length(voetnoten)) {
    paste0('<div class="spss-voetnoot">', paste(esc(voetnoten), collapse = "<br>"), "</div>")
  } else ""
  # Een brede tabel (meer dan acht kolommen) mag de rechterkantlijn in, anders
  # kapt de tekstkolom hem af (gezien op 18-11-2026 bij Independent Samples Test).
  n_kol <- max(vapply(rijen, length, 1L))
  breed <- if (n_kol > 8) " column-body-outset-right spss-breed" else ""
  paste0(
    '<div class="spss-uitvoer', breed, '"><div class="spss-titel">', esc(titel), "</div>",
    '<table class="spss-tabel"><thead>', paste(kop_html, collapse = ""),
    "</thead><tbody>", paste(lijf_html, collapse = ""), "</tbody></table>",
    noot_html, "</div>"
  )
}

# De vaste regel onder een blok nagebouwde uitvoer. Eén zin, overal dezelfde.
spss_noot <- function() {
  '<p class="spss-nagebouwd">Nagebouwd in R met dezelfde data; in SPSS ziet de uitvoer er zo uit.</p>'
}

# Zet een of meer tabellen (en eventueel de noot) op de bladzijde, als ÉÉN
# blok HTML. Twee losse asis-uitvoeren in één codeblok lieten een kale
# "```{=html}" als tekst op de bladzijde staan (gezien op 18-11-2026; de
# render-wachten zagen het niet, de schermafdruk wel).
spss_toon <- function(...) {
  knitr::asis_output(htmltools::HTML(paste0(..., collapse = "")))
}

# ---- de vier tabellen van Paired-Samples T Test ------------------------------
spss_gepaard <- function(r, naam1, naam2, md = 2, d = 3) {
  paar <- paste(naam1, "-", naam2)
  list(
    stat = spss_tabel(
      "Paired Samples Statistics",
      list(list(kc(""), kc(""), kc("Mean"), kc("N"), kc("Std. Deviation"), kc("Std. Error Mean"))),
      list(c("Pair 1", naam1, spss_getal(r$m1, md), r$n, spss_getal(r$s1, d), spss_getal(r$se1, d)),
           c("", naam2, spss_getal(r$m2, md), r$n, spss_getal(r$s2, d), spss_getal(r$se2, d))),
      links = 2),
    cor = spss_tabel(
      "Paired Samples Correlations",
      list(list(kc("", rows = 2), kc("", rows = 2), kc("N", rows = 2), kc("Correlation", rows = 2),
                kc("Significance", cols = 2)),
           list(kc("One-Sided p"), kc("Two-Sided p"))),
      list(c("Pair 1", paar, r$n, spss_getal(r$r, 3), spss_p(r$r_p2 / 2), spss_p(r$r_p2))),
      links = 2),
    test = spss_tabel(
      "Paired Samples Test",
      list(list(kc("", rows = 3), kc("", rows = 3), kc("Paired Differences", cols = 5),
                kc("t", rows = 3), kc("df", rows = 3), kc("Significance", cols = 2)),
           list(kc("Mean", rows = 2), kc("Std. Deviation", rows = 2), kc("Std. Error Mean", rows = 2),
                kc("95% Confidence Interval of the Difference", cols = 2),
                kc("One-Sided p", rows = 2), kc("Two-Sided p", rows = 2)),
           list(kc("Lower"), kc("Upper"))),
      list(c("Pair 1", paar, spss_getal(r$md, d), spss_getal(r$sdd, d), spss_getal(r$se, d),
             spss_getal(r$lo, d), spss_getal(r$hi, d), spss_getal(r$t, 3), r$df,
             spss_p(r$p1), spss_p(r$p2))),
      links = 2),
    eff = spss_tabel(
      "Paired Samples Effect Sizes",
      list(list(kc("", rows = 2), kc("", rows = 2), kc("", rows = 2), kc("Standardizerᵃ", rows = 2),
                kc("Point Estimate", rows = 2), kc("95% Confidence Interval", cols = 2)),
           list(kc("Lower"), kc("Upper"))),
      list(c("Pair 1", paar, "Cohen's d", spss_getal(r$sdd, d), spss_getal(r$d, 3),
             spss_getal(r$d_lo, 3), spss_getal(r$d_hi, 3)),
           c("", "", "Hedges' correction", spss_getal(r$g_st, d), spss_getal(r$g, 3),
             spss_getal(r$g_lo, 3), spss_getal(r$g_hi, 3))),
      voetnoten = c("a. The denominator used in estimating the effect sizes.",
                    "Cohen's d uses the sample standard deviation of the mean difference.",
                    "Hedges' correction uses the sample standard deviation of the mean difference, plus a correction factor."),
      links = 3)
  )
}

# ---- de drie tabellen van Independent-Samples T Test --------------------------
spss_onafh <- function(r, uitkomst, groep1, groep2, md = 2, d = 3) {
  list(
    stat = spss_tabel(
      "Group Statistics",
      list(list(kc(""), kc(""), kc("N"), kc("Mean"), kc("Std. Deviation"), kc("Std. Error Mean"))),
      list(c(uitkomst, groep1, r$n1, spss_getal(r$m1, md), spss_getal(r$s1, d), spss_getal(r$se1, d)),
           c("", groep2, r$n2, spss_getal(r$m2, md), spss_getal(r$s2, d), spss_getal(r$se2, d))),
      links = 2),
    test = spss_tabel(
      "Independent Samples Test",
      list(list(kc("", rows = 3), kc("", rows = 3),
                kc("Levene's Test for Equality of Variances", cols = 2),
                kc("t-test for Equality of Means", cols = 8)),
           list(kc("F", rows = 2), kc("Sig.", rows = 2), kc("t", rows = 2), kc("df", rows = 2),
                kc("Significance", cols = 2), kc("Mean Difference", rows = 2),
                kc("Std. Error Difference", rows = 2),
                kc("95% Confidence Interval of the Difference", cols = 2)),
           list(kc("One-Sided p"), kc("Two-Sided p"), kc("Lower"), kc("Upper"))),
      list(c(uitkomst, "Equal variances assumed", spss_getal(r$lev_F, 3), spss_p(r$lev_p),
             spss_getal(r$t_p, 3), r$df_p, spss_p(r$p1_p), spss_p(r$p2_p),
             spss_getal(r$md, d), spss_getal(r$se_p, d), spss_getal(r$lo_p, d), spss_getal(r$hi_p, d)),
           c("", "Equal variances not assumed", "", "",
             spss_getal(r$t_w, 3), spss_getal(r$df_w, 3), spss_p(r$p1_w), spss_p(r$p2_w),
             spss_getal(r$md, d), spss_getal(r$se_w, d), spss_getal(r$lo_w, d), spss_getal(r$hi_w, d))),
      links = 2),
    eff = spss_tabel(
      "Independent Samples Effect Sizes",
      list(list(kc("", rows = 2), kc("", rows = 2), kc("Standardizerᵃ", rows = 2),
                kc("Point Estimate", rows = 2), kc("95% Confidence Interval", cols = 2)),
           list(kc("Lower"), kc("Upper"))),
      list(c(uitkomst, "Cohen's d", spss_getal(r$sp, d), spss_getal(r$d, 3),
             spss_getal(r$d_lo, 3), spss_getal(r$d_hi, 3)),
           c("", "Hedges' correction", spss_getal(r$g_st, d), spss_getal(r$g, 3),
             spss_getal(r$g_lo, 3), spss_getal(r$g_hi, 3))),
      voetnoten = c("a. The denominator used in estimating the effect sizes.",
                    "Cohen's d uses the pooled standard deviation.",
                    "Hedges' correction uses the pooled standard deviation, plus a correction factor.",
                    "(De rij Glass's delta is hier weggelaten.)"),
      links = 2)
  )
}

# ---- toets tegen echte SPSS-uitvoer ------------------------------------------
# Bens OZP1-aantekening 2026, les 5, p. 11: One-Sample Test, N = 13,
# t = 2.377, Std. Deviation 2.28709, Mean Difference 1.50769.
local({
  n <- 13; df <- 12; s <- 2.28709; t_obs <- 2.377
  ncp <- bi_ncp(t_obs, df)
  J <- hedges_j(df)
  stopifnot(
    "Cohen's d wijkt af van SPSS" = spss_getal(1.50769 / s, 3) == ".659",
    "BI van d wijkt af van SPSS" = spss_getal(ncp[1] / sqrt(n), 3) == ".045" &&
      spss_getal(ncp[2] / sqrt(n), 3) == "1.251",
    "Hedges-standardizer wijkt af van SPSS" = spss_getal(s / J, 5) == "2.44362",
    "Hedges' puntschatting wijkt af van SPSS" = spss_getal(1.50769 / (s / J), 3) == ".617",
    "BI van Hedges wijkt af van SPSS" = spss_getal(ncp[1] / sqrt(n) * J, 3) == ".042" &&
      spss_getal(ncp[2] / sqrt(n) * J, 3) == "1.171"
  )
})
