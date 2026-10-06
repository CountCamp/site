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
# Stijl: gt_apa() uit functions/gt_apa.R — alleen horizontale lijnen.

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

  fmt_F  <- function(x) sprintf("%.2f", x)
  fmt_p  <- function(x) ifelse(x < .001, "< .001", sub("^0\\.", ".", sprintf("%.3f", x)))
  fmt_es <- function(x) sub("^0\\.", ".", sprintf("%.2f", x))
  fmt_C  <- function(x) sprintf("%.2f", x)

  row_F <- function(label, term) {
    F_val <- an[term, "F value"]
    p_val <- an[term, "Pr(>F)"]
    df1   <- an[term, "Df"]
    df2   <- an["Residuals", "Df"]
    eta_p <- es[term, "eta.sq.part"]
    sprintf("%s: F(%d, %d) = %s, p = %s, eta^2_p = %s",
            label, df1, df2, fmt_F(F_val), fmt_p(p_val), fmt_es(eta_p))
  }

  cov_row <- row_F(covariate_label, cov)
  fac_row <- row_F(factor_label, fac)

  # Tabel opbouwen.
  show_df <- data.frame(
    level = per_group$level,
    n     = per_group$n,
    C     = sprintf("%.2f", per_group$C_bar),
    Y     = sprintf("%.2f", per_group$Y_bar),
    Yadj  = sprintf("%.2f", per_group$emmean),
    stringsAsFactors = FALSE
  )

  source_path <- file.path("functions", "gt_apa.R")
  if (file.exists(source_path)) source(source_path)

  tab <- gt(show_df) |>
    cols_label(
      level = .cap_first_anc(factor_label),
      n     = md("*n*"),
      C     = md(paste0("M~", covariate_label, "~")),
      Y     = md(paste0("M~", dependent_label, ", ruw~")),
      Yadj  = md(paste0("M~", dependent_label, ", adjusted~"))
    ) |>
    cols_align(align = "center", columns = c(n, C, Y, Yadj)) |>
    cols_align(align = "left",   columns = level) |>
    gt_apa() |>
    # PDF-safe: longtable in plaats van table-float, want gt's default
    # \begin{table}-float crasht binnen Quarto's callout (tcolorbox).
    tab_options(latex.use_longtable = TRUE)

  # Caption komt als source_note (footnote-stijl) — niet als tab_header.
  # Reden: gt's tab_header rendert in PDF als \caption*, en \caption* binnen
  # een callout-omgeving (tcolorbox) crasht xelatex met "Not in outer par mode".
  cap_prefix <- if (!is.null(caption)) paste0("*", caption, ".* ") else ""

  note_text <- paste0(
    cap_prefix,
    "*M*~", dependent_label, ", adjusted~ = estimated marginal mean ",
    "voor ", dependent_label, " bij gemiddelde ", covariate_label, " ",
    "(", sprintf("%.2f", grand_C), "). Pooled-within slope *b*~w~ = ",
    sprintf("%.2f", b_w), ". ", cov_row, "; ", fac_row, "."
  )

  tab <- tab |>
    tab_footnote_apa(note_text)

  tab
}
