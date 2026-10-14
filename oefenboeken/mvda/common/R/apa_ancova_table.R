# apa_ancova_table.R — adjusted-means-tabel voor het ANCOVA-thema
#
# Deze tabel toont per niveau van de factor:
#   - C-bar_j (covariaat-mean per groep)
#   - Y-bar_j (raw uitkomst-mean per groep)
#   - Y-bar*_j (adjusted mean / EMM, na correctie voor de covariaat)
#   - n per groep
#
# Onder de tabel: grand mean covariaat, b_w (pooled-within slope op de
# covariaat), en de F/p/eta^2_p-regels voor covariaat en factor.
#
# Werkt op een lm()-object met formule  Y ~ covariaat + factor.
# (Dus ANCOVA-model zonder interactie.)
#
# Vereiste pakketten: gt, emmeans, car, lsr.
# Stijl: gt_apa() uit de canonieke KAAPA-helper — alleen horizontale lijnen.
# Het hoofdstuk laadt die vooraf met source("../_common/R/kaapa.R").

suppressPackageStartupMessages({
  library(gt)
  library(emmeans)
  library(car)
  library(lsr)
})

# Title-case helper, alleen eerste letter.
.cap_first_anc <- function(x) {
  x <- as.character(x)
  ifelse(
    is.na(x) | nchar(x) == 0L, x,
    paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x)))
  )
}

apa_ancova_table <- function(model,
                             factor,
                             covariate,
                             data,
                             dependent_label    = NULL,
                             factor_label       = NULL,
                             covariate_label    = NULL,
                             caption            = NULL) {

  fac <- as.character(factor)
  cov <- as.character(covariate)

  y_name <- as.character(formula(model)[[2]])
  if (is.null(dependent_label))  dependent_label <- y_name
  if (is.null(factor_label))     factor_label    <- fac
  if (is.null(covariate_label))  covariate_label <- cov

  # Per-groep statistieken.
  fac_levels <- levels(data[[fac]])
  if (is.null(fac_levels)) fac_levels <- sort(unique(as.character(data[[fac]])))

  per_group <- do.call(rbind, lapply(fac_levels, function(lv) {
    sub <- data[data[[fac]] == lv, , drop = FALSE]
    data.frame(
      level = .cap_first_anc(lv),
      n     = nrow(sub),
      C_bar = mean(sub[[cov]],  na.rm = TRUE),
      Y_bar = mean(sub[[y_name]], na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))

  # Adjusted means via emmeans.
  emm <- as.data.frame(emmeans(model, specs = stats::as.formula(paste("~", fac))))
  emm$level <- .cap_first_anc(as.character(emm[[fac]]))
  per_group <- merge(per_group, emm[, c("level", "emmean")], by = "level",
                     sort = FALSE, all.x = TRUE)

  # Bewaar de levels-volgorde.
  per_group <- per_group[match(.cap_first_anc(fac_levels), per_group$level), ]
  rownames(per_group) <- NULL

  # Grand mean covariaat + b_w (slope op covariaat in het ANCOVA-model).
  grand_C <- mean(data[[cov]], na.rm = TRUE)
  b_w     <- unname(coef(model)[cov])

  # F-regels uit Anova(., type = 3).
  an <- car::Anova(model, type = 3)
  # eta^2_p uit lsr::etaSquared (kolom eta.sq.part).
  es <- lsr::etaSquared(model)
  rn_an <- rownames(an)
  rn_es <- rownames(es)

  # Getallen via de functies van de KAAPA-helper (fmt_t, fmt_p_text, fmt_r2,
  # fmt_b): echt minteken, geen voorloopnul waar een getal niet boven de 1 kan,
  # en fmt_p_text() zet zelf "=" of "<" voor de p, dus nooit "p = < .001".
  # Binnen een statistiek vaste spaties (U+00A0), zodat de noot nooit breekt
  # tussen "p <" en ".001" of tussen "F(1," en "74)".
  vast <- function(s) gsub(" ", " ", s, fixed = TRUE)
  row_F <- function(label, term) {
    F_val <- an[term, "F value"]
    p_val <- an[term, "Pr(>F)"]
    df1   <- an[term, "Df"]
    df2   <- an["Residuals", "Df"]
    eta_p <- es[term, "eta.sq.part"]
    paste0(label, ": ",
           vast(sprintf("*F*(%d, %d) = %s, *p* %s,", df1, df2, fmt_t(F_val), fmt_p_text(p_val))),
           " $\\eta^2_p$ = ", fmt_r2(eta_p))
  }

  cov_row <- row_F(covariate_label, cov)
  fac_row <- row_F(factor_label, fac)

  # Tabel opbouwen.
  show_df <- data.frame(
    level = per_group$level,
    n     = per_group$n,
    C     = fmt_b(per_group$C_bar),
    Y     = fmt_b(per_group$Y_bar),
    Yadj  = fmt_b(per_group$emmean),
    stringsAsFactors = FALSE
  )

  # *M* met de naam van de variabele eronder. Met HTML en niet met de
  # markdown-tilde: pandoc maakt van M~a, b~ geen subscript zodra er een
  # spatie in staat, en dan stonden de tildes gewoon op de bladzijde.
  M_sub <- function(label) paste0("*M*<sub>", label, "</sub>")

  # gt_apa() komt altijd uit kaapa.R en nooit uit een losse kopie ergens
  # anders: een kopie die niemand bijhoudt, loopt stilletjes achter (zie de
  # uitleg bovenin kaapa.R).
  tab <- gt(show_df) |>
    cols_label(
      level = .cap_first_anc(factor_label),
      n     = md("*n*"),
      C     = md(M_sub(covariate_label)),
      Y     = md(M_sub(paste0(dependent_label, ", ruw"))),
      Yadj  = md(M_sub(paste0(dependent_label, ", adjusted")))
    ) |>
    # Getallen rechts, zodat de decimalen onder elkaar staan (KAAPA).
    cols_align(align = "right", columns = c(n, C, Y, Yadj)) |>
    cols_align(align = "left",  columns = level) |>
    # De caption is de titel, boven de tabel, zoals KAAPA en APA 7 §7.10 het
    # willen. In een PDF-render binnen een callout laat tab_header() xelatex
    # crashen; dit oefenboek rendert alleen HTML (zie _quarto.yml), dus dat
    # speelt hier niet.
    gt_apa(title = caption) |>
    # PDF-safe: longtable in plaats van table-float, want gt's default
    # \begin{table}-float crasht binnen Quarto's callout (tcolorbox).
    tab_options(latex.use_longtable = TRUE)

  note_text <- paste0(
    M_sub(paste0(dependent_label, ", adjusted")), " = estimated marginal mean ",
    "voor ", dependent_label, " bij gemiddelde ", covariate_label, " ",
    "(", fmt_b(grand_C), "). Pooled-within slope *b*~w~ = ",
    fmt_b(b_w), "; $\\eta^2_p$ = partiële eta-kwadraat. ", cov_row, "; ", fac_row, "."
  )

  tab <- tab |>
    tab_footnote_apa(note_text)

  tab
}
