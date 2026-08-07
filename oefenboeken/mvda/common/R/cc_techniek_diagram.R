#' CountCamp techniek-diagram — sets met pijlen ertussen
#'
#' Tekent een ggplot-diagram met rechthoeken (sets variabelen) en pijlen
#' (technieken / relaties). Voor consistent overzicht per MVDA-thema:
#' MRA / ANOVA / ANCOVA / LRA / MANOVA / DDA / RMA / Mediation.
#'
#' Gebaseerd op Bens handgeschreven set-pijl-stijl (aantekeningen pagina 9):
#' meetniveau bovenin het blok, set-naam in vet, variabele-namen daaronder,
#' aantal als footnote. Pijl met techniek-label tussen blokken.
#'
#' @param blocks Lijst met per blok een named list met velden:
#'   - id: unieke string-identifier (gebruikt voor arrow-from/to)
#'   - label: hoofdtekst (bv. "sociale_status")
#'   - vars: variabel-namen of toelichting (bv. "alpha / mid / outsider")
#'   - level: "nominaal" / "ordinaal" / "interval" / "afgeleid interval"
#'   - note: footer-tekst (bv. "3 groepen")
#'   - x, y: positie midden van het blok
#'   - width, height: optioneel, standaard 3.0 en 1.7
#' @param arrows data.frame met kolommen `from`, `to`, `label`
#' @param title Optioneel: titel boven het diagram
#'
#' @return Een ggplot-object
cc_techniek_diagram <- function(blocks, arrows, title = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is nodig voor cc_techniek_diagram()")
  }

  # Tol-Vibrant-achtige pastel-kleuren per meetniveau
  level_colors <- c(
    "nominaal"          = "#FFE0B3",
    "ordinaal"          = "#FFF2B3",
    "interval"          = "#CCE5FF",
    "afgeleid interval" = "#E5CCFF"
  )

  # Blocks omzetten naar data.frame
  bf <- do.call(rbind, lapply(blocks, function(b) {
    data.frame(
      id     = b$id,
      label  = b$label,
      vars   = if (is.null(b$vars)) "" else b$vars,
      level  = b$level,
      note   = if (is.null(b$note)) "" else b$note,
      x      = b$x,
      y      = b$y,
      width  = if (is.null(b$width)) 3.0 else b$width,
      height = if (is.null(b$height)) 1.7 else b$height,
      stringsAsFactors = FALSE
    )
  }))

  bf$xmin <- bf$x - bf$width / 2
  bf$xmax <- bf$x + bf$width / 2
  bf$ymin <- bf$y - bf$height / 2
  bf$ymax <- bf$y + bf$height / 2
  bf$fill <- unname(level_colors[bf$level])

  # Pijlen — koppel via match()
  af <- arrows
  af$x_start <- bf$xmax[match(af$from, bf$id)]
  af$x_end   <- bf$xmin[match(af$to,   bf$id)]
  af$y_start <- bf$y[match(af$from, bf$id)]
  af$y_end   <- bf$y[match(af$to,   bf$id)]
  af$x_mid   <- (af$x_start + af$x_end) / 2
  af$y_mid   <- (af$y_start + af$y_end) / 2

  ggplot2::ggplot() +
    # Blokken (rechthoeken)
    ggplot2::geom_rect(
      data = bf,
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill),
      color = "black", linewidth = 0.6
    ) +
    # Meetniveau-label (bovenin, italic)
    ggplot2::geom_text(
      data = bf,
      ggplot2::aes(x = x, y = y + height * 0.34, label = level),
      size = 3.4, fontface = "italic", color = "gray30"
    ) +
    # Hoofdtekst (vet, midden-boven)
    ggplot2::geom_text(
      data = bf,
      ggplot2::aes(x = x, y = y + height * 0.10, label = label),
      size = 4.2, fontface = "bold"
    ) +
    # Variabele-namen
    ggplot2::geom_text(
      data = bf,
      ggplot2::aes(x = x, y = y - height * 0.13, label = vars),
      size = 3.4
    ) +
    # Footnote
    ggplot2::geom_text(
      data = bf,
      ggplot2::aes(x = x, y = y - height * 0.36, label = note),
      size = 3.0, fontface = "italic", color = "gray40"
    ) +
    # Pijlen
    ggplot2::geom_segment(
      data = af,
      ggplot2::aes(x = x_start, xend = x_end, y = y_start, yend = y_end),
      arrow = ggplot2::arrow(length = ggplot2::unit(0.4, "cm"), type = "closed"),
      linewidth = 1
    ) +
    # Pijl-labels
    ggplot2::geom_label(
      data = af,
      ggplot2::aes(x = x_mid, y = y_mid + 0.28, label = label),
      size = 3.6, fontface = "bold", fill = "white", label.size = 0,
      label.padding = ggplot2::unit(0.18, "lines")
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::coord_fixed(clip = "off") +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.margin = ggplot2::margin(15, 15, 15, 15),
      plot.title = ggplot2::element_text(hjust = 0.5, size = 13, face = "bold")
    ) +
    {if (!is.null(title)) ggplot2::ggtitle(title) else NULL}
}
