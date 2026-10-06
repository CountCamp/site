# apa_factorial.R — herbruikbare bouwstenen voor factorial-ANOVA-didactiek
#
# CONVENTIE — A = rij-factor, B = kolom-factor.
#   factor_A is de RIJ-factor: zijn niveaus verschijnen als rijen in de tabel
#     en als gekleurde lijnen in de profile plot (één lijn per A-niveau).
#   factor_B is de KOLOM-factor: zijn niveaus verschijnen als kolommen in de
#     tabel en als x-as-niveaus in de profile plot.
#   Marginalen volgen direct uit A=rij, B=kolom:
#     - de kolom 'Marginaal B' rechts toont rij-marginalen van A
#       (gemiddeld over B);
#     - de rij 'Marginaal A' onderaan toont kolom-marginalen van B
#       (gemiddeld over A);
#     - rechts-onder staat de grand mean.
#
# Twee functies:
#
#   apa_marginals_table(model, factor_A, factor_B, data, ...)
#       2D-tabel (gt) met cel-`M (SD, n)` en EMM-marginalen aan rand;
#       grand mean rechts-onder; drie F/p-regels in een tab_footnote-blok.
#       APA 7: alleen horizontale lijnen, GEEN verticale tussen kolommen.
#       Marginal-blok herkenbaar via vetdruk + zachte achtergrondkleur,
#       niet via lijnen.
#
#   profile_plot_with_marginals(model, factor_A, factor_B, data, ...)
#       ggplot van cel-EMM's, met marginale-A-waarden als horizontale
#       referentielijntjes, marginale-B-waarden in de caption en de drie
#       F/p-regels in de subtitle. Tol-Vibrant kleuren.
#
# Beide functies trekken de F-waarden uit car::Anova(model, type = 3) en
# de EMM's uit emmeans. Werkt met lm()- of aov()-objecten met formule
# Y ~ A * B.
#
# Vereiste pakketten: gt, emmeans, car, dplyr, ggplot2.
# Stijl: opent met source("functions/gt_apa.R") in het hoofd-document, want
# we hergebruiken gt_apa(), tab_footnote_apa() en de fmt_*-helpers.

suppressPackageStartupMessages({
  library(gt)
  library(emmeans)
  library(car)
  library(dplyr)
  library(ggplot2)
  library(rlang)   # voor !!! splice in cols_label()
})

# Tol-Vibrant kleuren — synchroon met _thema_checklist.md.
.tol_vibrant <- c(
  "#0077BB", # blue
  "#EE7733", # orange
  "#009988", # teal
  "#CC3311", # red
  "#33BBEE", # cyan
  "#EE3377", # magenta
  "#BBBBBB"  # grey
)

# Title-case-helper: maak van "ondiep" een "Ondiep" en van
# "licht briesje" een "Licht briesje" (alleen eerste letter hoofdletter,
# rest blijft staan — geen R-style ALL CAPS, geen Title Case Per Word).
.cap_first <- function(x) {
  x <- as.character(x)
  ifelse(
    is.na(x) | nchar(x) == 0L,
    x,
    paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x)))
  )
}

# ----------------------------------------------------------------
# Interne helper: haal alles wat tabel + plot nodig hebben
# ----------------------------------------------------------------
.factorial_summary <- function(model, factor_A, factor_B, data) {

  fA <- as.character(factor_A)
  fB <- as.character(factor_B)

  # Y-naam uit de modelformule.
  y_name <- as.character(formula(model)[[2]])

  # Cel-statistieken (gewogen descriptives — alleen voor M, SD, n in de cellen).
  cell_stats <- data |>
    dplyr::filter(!is.na(.data[[y_name]])) |>
    dplyr::group_by(.data[[fA]], .data[[fB]]) |>
    dplyr::summarise(
      M  = mean(.data[[y_name]]),
      SD = stats::sd(.data[[y_name]]),
      n  = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::rename(A = !!fA, B = !!fB)

  # Cel-EMM's (ongewogen modelvoorspellingen per cel).
  # emmeans waarschuwt bij hoofdeffecten in een interactie-model — bewust
  # gevraagd in deze didactische context, dus suppress.
  emm_cells <- suppressMessages(as.data.frame(
    emmeans::emmeans(model, stats::as.formula(paste0("~ ", fA, " * ", fB)))
  )) |>
    dplyr::rename(A = !!fA, B = !!fB, emm = emmean)

  # Marginale EMM's voor A (rij-marginalen) en B (kolom-marginalen).
  emm_A <- suppressMessages(as.data.frame(
    emmeans::emmeans(model, stats::as.formula(paste0("~ ", fA)))
  )) |>
    dplyr::rename(A = !!fA, M = emmean)

  emm_B <- suppressMessages(as.data.frame(
    emmeans::emmeans(model, stats::as.formula(paste0("~ ", fB)))
  )) |>
    dplyr::rename(B = !!fB, M = emmean)

  # Grand mean: ongewogen gemiddelde over alle cel-EMM's.
  grand_mean <- mean(emm_cells$emm)

  # Type III ANOVA-tabel.
  aov_tab <- car::Anova(model, type = 3)

  pick <- function(term) {
    idx <- which(rownames(aov_tab) == term)
    if (length(idx) == 0L) {
      return(list(F = NA_real_, df1 = NA_real_, df2 = NA_real_, p = NA_real_))
    }
    list(
      F   = aov_tab[idx, "F value"],
      df1 = aov_tab[idx, "Df"],
      df2 = aov_tab[which(rownames(aov_tab) == "Residuals"), "Df"],
      p   = aov_tab[idx, "Pr(>F)"]
    )
  }

  list(
    fA          = fA,
    fB          = fB,
    y_name      = y_name,
    levels_A    = levels(droplevels(data[[fA]])),
    levels_B    = levels(droplevels(data[[fB]])),
    cell_stats  = cell_stats,
    emm_cells   = emm_cells,
    emm_A       = emm_A,
    emm_B       = emm_B,
    grand_mean  = grand_mean,
    F_A         = pick(fA),
    F_B         = pick(fB),
    F_AB        = pick(paste0(fA, ":", fB))
  )
}

# Compacte F/p-regel: "F(1, 231) = 4.47, p = .036" met italic.
.fmt_Fp <- function(F_, df1, df2, p) {
  if (is.na(F_)) return("—")
  paste0("*F*(", df1, ", ", df2, ") = ",
         formatC(F_, digits = 2, format = "f"),
         ", *p* ", fmt_p(p))
}

# ----------------------------------------------------------------
# apa_marginals_table()
# ----------------------------------------------------------------
apa_marginals_table <- function(model,
                                factor_A,
                                factor_B,
                                data,
                                dependent_label = "Y",
                                factor_A_label  = NULL,
                                factor_B_label  = NULL,
                                caption         = NULL) {

  S <- .factorial_summary(model, factor_A, factor_B, data)

  if (is.null(factor_A_label)) factor_A_label <- S$fA
  if (is.null(factor_B_label)) factor_B_label <- S$fB

  # Welke factor heeft 2 niveaus? Bepaalt of we een verschilrij (A=2)
  # of verschilkolom (B=2) toevoegen. Bij beide >2 of beide =2:
  #   - Beide =2 (klassiek 2x2): verschilrij voor de A-factor.
  #   - Beide >2 (3x3 of groter): geen verschillen — te veel paren.
  #   - A=2, B>2: verschilrij (Δ over A binnen elk B-niveau).
  #   - A>2, B=2: verschilkolom (Δ over B binnen elk A-niveau).
  add_diff_row <- length(S$levels_A) == 2L
  add_diff_col <- length(S$levels_B) == 2L && length(S$levels_A) > 2L

  # Cel-cellen formatteren als "M (SD, n)".
  cell_txt <- S$cell_stats |>
    dplyr::mutate(
      txt = paste0(
        formatC(M,  digits = 2, format = "f"), " (",
        formatC(SD, digits = 2, format = "f"), ", ",
        n, ")"
      )
    ) |>
    dplyr::select(A, B, txt)

  # Wide formaat: rijen = A-niveaus, kolommen = B-niveaus.
  # `A` als character (kapitalisatie volgt later, na bind_rows met marg/diff).
  wide <- tidyr::pivot_wider(cell_txt, names_from = B, values_from = txt) |>
    dplyr::mutate(A = as.character(A))

  # Marginaal-B kolom (rij-marginaal van A — gemiddeld over B).
  # Naam zonder spatie zodat make.names() hem niet verminkt; we hernoemen
  # later via cols_label() voor weergave.
  marg_A_lookup <- S$emm_A |>
    dplyr::mutate(txt = formatC(M, digits = 2, format = "f"))
  wide[["margB"]] <- marg_A_lookup$txt[
    match(wide$A, as.character(marg_A_lookup$A))
  ]

  # Verschilkolom (B=2 én A>2): Δ B_1 − B_2 binnen elk A-niveau.
  # Berekend uit cel-EMM's, niet uit gewogen descriptives.
  diff_col_label <- NULL
  if (add_diff_col) {
    b1 <- S$levels_B[1]
    b2 <- S$levels_B[2]
    diff_lookup <- S$emm_cells |>
      dplyr::filter(B %in% c(b1, b2)) |>
      dplyr::group_by(A) |>
      dplyr::summarise(
        d = emm[B == b1] - emm[B == b2],
        .groups = "drop"
      ) |>
      dplyr::mutate(txt = formatC(d, digits = 2, format = "f"))
    wide[["diffB"]] <- diff_lookup$txt[
      match(wide$A, as.character(diff_lookup$A))
    ]
    diff_col_label <- paste0(
      "&Delta; ", .cap_first(b1), " &minus; ", .cap_first(b2)
    )
  }

  # Marginaal-A rij (kolom-marginaal van B — gemiddeld over A).
  marg_B_lookup <- S$emm_B |>
    dplyr::mutate(txt = formatC(M, digits = 2, format = "f"))
  marg_row <- data.frame(A = "Marginaal A", stringsAsFactors = FALSE)
  for (lvl in S$levels_B) {
    marg_row[[lvl]] <- marg_B_lookup$txt[
      match(lvl, as.character(marg_B_lookup$B))
    ]
  }
  marg_row[["margB"]] <- formatC(S$grand_mean, digits = 2, format = "f")
  if (add_diff_col) marg_row[["diffB"]] <- "—"

  # Verschilrij (A=2): Δ A_1 − A_2 binnen elk B-niveau, uit cel-EMM's.
  diff_row_label <- NULL
  if (add_diff_row) {
    a1 <- S$levels_A[1]
    a2 <- S$levels_A[2]
    diff_row_label <- paste0(
      "Δ ", .cap_first(a1), " − ", .cap_first(a2)
    )
    diff_lookup_A <- S$emm_cells |>
      dplyr::filter(A %in% c(a1, a2)) |>
      dplyr::group_by(B) |>
      dplyr::summarise(
        d = emm[A == a1] - emm[A == a2],
        .groups = "drop"
      ) |>
      dplyr::mutate(txt = formatC(d, digits = 2, format = "f"))
    diff_row <- data.frame(A = diff_row_label, stringsAsFactors = FALSE)
    for (lvl in S$levels_B) {
      diff_row[[lvl]] <- diff_lookup_A$txt[
        match(lvl, as.character(diff_lookup_A$B))
      ]
    }
    diff_row[["margB"]] <- "—"
    if (add_diff_col) diff_row[["diffB"]] <- "—"
    # Volgorde: A_1-rij, verschilrij (tussen A_1 en A_2), A_2-rij, marginaal-rij.
    # Visueel logisch: het verschil zit tussen de twee niveaus, niet eronder.
    wide <- dplyr::bind_rows(wide[1, ], diff_row, wide[2, ], marg_row)
  } else {
    wide <- dplyr::bind_rows(wide, marg_row)
  }

  # Kolomvolgorde voor de verschilkolom (B=2, A>2):
  # plaats `diffB` tussen B_1 en B_2 i.p.v. rechts vóór `margB`.
  # Visueel logisch: het verschil zit tussen de twee niveaus, niet ernaast.
  if (add_diff_col) {
    b1 <- S$levels_B[1]
    b2 <- S$levels_B[2]
    # Stub-kolom 'A' blijft eerste; daarna B_1, diffB, B_2, margB.
    wide <- wide[, c("A", b1, "diffB", b2, "margB"), drop = FALSE]
  }

  # Capitaliseer cel-rij-headers in de stub: alleen de raw-level-rijen,
  # de marginaal- en verschilrij hebben al een cap-first label.
  is_cell_row <- wide$A %in% S$levels_A
  wide$A[is_cell_row] <- .cap_first(wide$A[is_cell_row])

  # Display-labels voor kolommen: kapitaliseer B-niveau-namen, en
  # geef margB / diffB hun bold-label.
  col_labels <- setNames(as.list(.cap_first(S$levels_B)), S$levels_B)
  col_labels[["margB"]] <- gt::md("**Marginaal B**")
  if (add_diff_col) {
    col_labels[["diffB"]] <- gt::md(paste0("**", diff_col_label, "**"))
  }

  # Marginal-rij-label en diff-rij-label voor matching in tab_style.
  marg_row_id <- "Marginaal A"

  # gt-tabel.
  # NB: caption komt als source_note (footnote-stijl) — niet als tab_header.
  # Reden: gt's tab_header rendert in PDF als \caption*, en \caption* binnen
  # een callout-omgeving (tcolorbox) crasht xelatex met "Not in outer par mode".
  # Een source_note werkt veilig in beide outputs.
  #
  # APA 7-stijl: GEEN verticale lijnen tussen kolommen. De marginal-kolom
  # 'Marginaal B' krijgt visueel onderscheid via vetdruk, een zachte
  # achtergrondkleur (Tol-Vibrant grijs-tint, lichte alpha) en iets ruimere
  # padding — niet via een lijn. Hetzelfde geldt voor de marginal-rij.
  marg_tint <- "#F2F2F2"   # zacht grijs, kleurenblindvriendelijk
  diff_tint <- "#E6F0F7"   # zachte tint van Tol-Vibrant blue (#0077BB), accent
  # Spanner-kolommen: B-niveaus, en als de verschilkolom tussen B_1 en B_2
  # zit moet diffB ook onder de B-spanner vallen (anders is de spanner
  # niet aaneengesloten en breekt gt).
  spanner_cols <- if (add_diff_col) {
    c(S$levels_B[1], "diffB", S$levels_B[2])
  } else {
    S$levels_B
  }

  tbl <- gt::gt(wide, rowname_col = "A") |>
    gt::tab_stubhead(label = factor_A_label) |>
    gt::tab_spanner(
      label   = factor_B_label,
      columns = dplyr::all_of(spanner_cols)
    ) |>
    gt::cols_label(!!!col_labels) |>
    gt_apa() |>
    # PDF-safe: longtable in plaats van table-float, want gt's default
    # \begin{table}-float crasht binnen Quarto's callout (tcolorbox).
    gt::tab_options(latex.use_longtable = TRUE) |>
    # Marginal-rij: vetdruk + zachte achtergrond.
    gt::tab_style(
      style     = list(
        gt::cell_text(weight = "bold"),
        gt::cell_fill(color = marg_tint)
      ),
      locations = gt::cells_body(rows = wide$A == marg_row_id)
    ) |>
    gt::tab_style(
      style     = gt::cell_text(weight = "bold"),
      locations = gt::cells_stub(rows = wide$A == marg_row_id)
    ) |>
    # Marginal-kolom: vetdruk + zachte achtergrond.
    gt::tab_style(
      style     = list(
        gt::cell_text(weight = "bold"),
        gt::cell_fill(color = marg_tint)
      ),
      locations = gt::cells_body(columns = "margB")
    ) |>
    gt::tab_style(
      style     = gt::cell_text(weight = "bold"),
      locations = gt::cells_column_labels(columns = "margB")
    )

  # Verschilrij: vetdruk + zachte blauwe accent-tint.
  if (add_diff_row) {
    tbl <- tbl |>
      gt::tab_style(
        style     = list(
          gt::cell_text(weight = "bold"),
          gt::cell_fill(color = diff_tint)
        ),
        locations = gt::cells_body(rows = wide$A == diff_row_label)
      ) |>
      gt::tab_style(
        style     = list(
          gt::cell_text(weight = "bold"),
          gt::cell_fill(color = diff_tint)
        ),
        locations = gt::cells_stub(rows = wide$A == diff_row_label)
      )
  }

  # Verschilkolom: vetdruk + zachte blauwe accent-tint.
  if (add_diff_col) {
    tbl <- tbl |>
      gt::tab_style(
        style     = list(
          gt::cell_text(weight = "bold"),
          gt::cell_fill(color = diff_tint)
        ),
        locations = gt::cells_body(columns = "diffB")
      ) |>
      gt::tab_style(
        style     = list(
          gt::cell_text(weight = "bold"),
          gt::cell_fill(color = diff_tint)
        ),
        locations = gt::cells_column_labels(columns = "diffB")
      )
  }

  # Drie F/p-regels onder de tabel.
  # Math-notatie in HTML-compatibele vorm (Unicode μ + <sub>), geen $...$,
  # zodat gt geen katex nodig heeft. In PDF blijft dit ook leesbaar.
  H0_A  <- "*H*~0~: alle rij-marginalen gelijk (&mu;<sub>A&sdot;</sub>'s gelijk)"
  H0_B  <- "*H*~0~: alle kolom-marginalen gelijk (&mu;<sub>&sdot;B</sub>'s gelijk)"
  H0_AB <- "*H*~0~: cel-patronen additief (geen interactie)"

  note <- paste0(
    if (!is.null(caption)) paste0(caption, ". ") else "",
    "Cellen tonen *M* (*SD*, *n*) op basis van ", dependent_label,
    "; rij- en kolom-marginalen zijn ongewogen estimated marginal means ",
    "(EMM); rechtsonder de grand mean. ",
    "Hoofdeffect ", factor_A_label, ": ",
    .fmt_Fp(S$F_A$F, S$F_A$df1, S$F_A$df2, S$F_A$p),
    " — ", H0_A, ". ",
    "Hoofdeffect ", factor_B_label, ": ",
    .fmt_Fp(S$F_B$F, S$F_B$df1, S$F_B$df2, S$F_B$p),
    " — ", H0_B, ". ",
    "Interactie ", factor_A_label, " &times; ", factor_B_label, ": ",
    .fmt_Fp(S$F_AB$F, S$F_AB$df1, S$F_AB$df2, S$F_AB$p),
    " — ", H0_AB, "."
  )

  tab_footnote_apa(tbl, note)
}

# ----------------------------------------------------------------
# profile_plot_with_marginals()
# ----------------------------------------------------------------
profile_plot_with_marginals <- function(model,
                                        factor_A,
                                        factor_B,
                                        data,
                                        dependent_label  = "Y",
                                        dependent_symbol = "Y",
                                        factor_A_label   = NULL,
                                        factor_B_label   = NULL) {

  S <- .factorial_summary(model, factor_A, factor_B, data)

  if (is.null(factor_A_label)) factor_A_label <- S$fA
  if (is.null(factor_B_label)) factor_B_label <- S$fB

  cells <- S$emm_cells |>
    dplyr::mutate(
      A = factor(A, levels = S$levels_A),
      B = factor(B, levels = S$levels_B)
    )

  marg_A <- S$emm_A |>
    dplyr::mutate(A = factor(A, levels = S$levels_A))

  # Kleuren — één per A-niveau (Tol-Vibrant).
  pal <- setNames(
    .tol_vibrant[seq_along(S$levels_A)],
    S$levels_A
  )

  # Subtitle met de drie F/p-regels.
  subtitle_txt <- paste0(
    factor_A_label,    ": ",
      .fmt_Fp(S$F_A$F,  S$F_A$df1,  S$F_A$df2,  S$F_A$p),  "\n",
    factor_B_label,    ": ",
      .fmt_Fp(S$F_B$F,  S$F_B$df1,  S$F_B$df2,  S$F_B$p),  "\n",
    factor_A_label, " × ", factor_B_label, ": ",
      .fmt_Fp(S$F_AB$F, S$F_AB$df1, S$F_AB$df2, S$F_AB$p)
  ) |>
    # ggplot toont geen markdown, dus strip italic-* en sub-tildes.
    gsub("\\*", "", x = _) |>
    gsub("~", "",  x = _)

  # Caption met marginale B-waarden — kapitaliseer de B-niveau-namen.
  marg_B_txt <- paste(
    paste0(.cap_first(S$emm_B$B), " = ",
           formatC(S$emm_B$M, digits = 2, format = "f")),
    collapse = "; "
  )
  caption_txt <- paste0("Marginaal ", factor_B_label, ": ", marg_B_txt,
                        ". Grand mean = ",
                        formatC(S$grand_mean, digits = 2, format = "f"), ".")

  # Mappings voor leesbare niveau-labels (eerste letter hoofdletter,
  # zonder de onderliggende factor-levels in de data te wijzigen).
  labels_A <- setNames(.cap_first(S$levels_A), S$levels_A)
  labels_B <- setNames(.cap_first(S$levels_B), S$levels_B)

  ggplot(cells, aes(x = B, y = emm, group = A, colour = A)) +
    # Marginaal-A als horizontale referentielijn (één per A-niveau).
    geom_hline(
      data = marg_A,
      aes(yintercept = M, colour = A),
      linetype = "dotted", alpha = 0.55
    ) +
    geom_line(linewidth = 0.7) +
    geom_point(size = 2.4) +
    # Marginaal-A label rechts in de plot, op de hoogte van de lijn.
    geom_text(
      data = marg_A,
      aes(x = length(S$levels_B) + 0.35,
          y = M,
          label = paste0("M[", factor_A_label, "] = ",
                         formatC(M, digits = 2, format = "f")),
          colour = A),
      hjust = 0, size = 3, show.legend = FALSE
    ) +
    scale_colour_manual(values = pal, name = factor_A_label,
                        labels = labels_A) +
    scale_x_discrete(labels = labels_B,
                     expand = expansion(mult = c(0.05, 0.30))) +
    labs(
      x        = factor_B_label,
      # Y-as: \hat{symbool} naast langere display-label.
      # `dependent_symbol` blijft kort (bv. "Y" of "graaftempo") zodat
      # hat(.) er netjes uitziet; `dependent_label` mag de volledige
      # leesbare naam zijn (bv. "graaftempo (cm/uur)").
      y        = bquote(hat(.(as.name(dependent_symbol))) ~ " — " ~ .(dependent_label)),
      title    = paste0("Profile plot: cel-EMM's met rij-marginalen"),
      subtitle = subtitle_txt,
      caption  = caption_txt
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.subtitle = element_text(size = 9, lineheight = 1.15,
                                   family = "mono"),
      plot.caption  = element_text(size = 8, hjust = 0),
      panel.grid.minor = element_blank(),
      legend.position  = "top"
    )
}
