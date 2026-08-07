# gt_apa() — APA 7 tabelstijl voor HTML-output
#
# Regels afgeleid van JK Article II (20260312):
#   - Dikke lijn boven (2.25 pt) en onder tabel (2.25 pt)
#   - Dunne lijn (0.5 pt) onder kolomhoofden
#   - Geen verticale lijnen, geen interne rasterlijnen
#   - Statistisch symbool in kolomnamen: italic via md() of html()
#   - Geen bold in tabelcellen (APA 7)
#   - Note. voetnoot in kleinere tekst, links uitgelijnd
#
# Gebruik:
#   library(gt)
#
#   mijn_df |>
#     gt() |>
#     gt_apa(title = "Tabel 1", subtitle = "Steekproefkenmerken")
#
#   # Met voetnoot:
#   ... |> gt_apa() |> tab_footnote_apa("Waarden zijn M (SD).")
#
#   # Italic in kolomnamen:
#   gt(col_labels = list(b = md("*b*"), SE = md("*SE*~b~"), t = md("*t*"), p = md("*p*")))

library(gt)

gt_apa <- function(gt_tbl,
                   title        = NULL,
                   subtitle     = NULL,
                   table_number = NULL,   # APA 7: "Table N" op aparte regel boven italic titel.
                                          # Mag integer (1) of string ("1a") zijn.
                   full_width   = FALSE) {

  out <- gt_tbl |>
    # --- Typografie ---
    opt_table_font(font = "Times New Roman") |>
    tab_options(
      # Titel zweeft boven de tabel: geen rand om de tabel zelf bovenaan
      table.border.top.style    = "none",
      table.border.bottom.style = "none",

      # Dikke lijn bovenaan kolomhoofden (= bovenkant tabel in APA)
      column_labels.border.top.style = "solid",
      column_labels.border.top.width = px(2),
      column_labels.border.top.color = "black",

      # Dunne lijn onder kolomhoofden
      column_labels.border.bottom.style = "solid",
      column_labels.border.bottom.width = px(1),
      column_labels.border.bottom.color = "black",

      # Dikke lijn onder data (boven Note.)
      table_body.border.bottom.style = "solid",
      table_body.border.bottom.width = px(2),
      table_body.border.bottom.color = "black",

      # Geen interne lijnen
      table_body.hlines.style         = "none",
      table_body.border.top.style     = "none",
      row.striping.include_table_body = FALSE,

      # Geen verticale lijnen
      column_labels.border.lr.style = "none",

      # Geen LR-rand om heading. heading.border.bottom.style bewust niet op
      # "none": dat onderdrukt de per-cel stroke (cells_title) in typst-output.
      heading.border.lr.style     = "none",

      # Achtergrond
      table.background.color = "white",

      # Padding
      data_row.padding         = px(4),
      column_labels.padding    = px(4),
      heading.padding          = px(2),

      # Titel en subtitel
      heading.align              = "left",
      heading.title.font.size    = pct(100),
      heading.subtitle.font.size = pct(100),

      # Source note (APA "Note.")
      source_notes.font.size           = pct(85),
      source_notes.padding             = px(2),
      source_notes.border.bottom.style = "none",

      # Tabel-breedte:
      #   full_width = TRUE  -> 100% van containerbreedte (voor brede
      #                          descriptive-tabellen met spanners die over
      #                          de hele pagina willen lopen, bv. Tabel 1)
      #   full_width = FALSE -> auto-breedte op basis van inhoud
      #                          (smalle tabellen klemmen netjes dicht op
      #                          hun kolominhoud, geen witruimte tussen kolommen)
      table.width = if (full_width) pct(100) else "auto"
    ) |>
    # Geen rij-strepen
    opt_row_striping(row_striping = FALSE)

  # APA 7 alignment-policy (KAAPA-convention 2026-05-27):
  # gt_apa() forceert GEEN alignment meer (was: cols_align(center) +
  # cols_align(left, col=1)). Reden: gt's eigen defaults zijn al
  # APA-conform — character/factor → left, numeric → right. Voor
  # character-getalstrings (na sprintf/fmt_r/fmt_b/fmt_p) moet de
  # gebruiker expliciet `cols_align("right", columns = c(...))` toepassen
  # vóór gt_apa(). De oude alles-center default overschreef beide en
  # leverde onleesbare multi-line tekst-kolommen op (Elly Tabel 2,
  # 2026-05-27).

  # APA 7 §7.10 header — drie varianten:
  #   1. Alleen title (en/of subtitle): italic, één of twee regels.
  #   2. table_number + title: "Table N" non-italic op eerste regel,
  #      italic title op tweede regel, optioneel subtitle op derde regel.
  #   3. Alleen table_number (geen title): alleen "Table N" non-italic.
  if (!is.null(table_number)) {
    # APA 7 §7.10: tabel-nummer is bold, titel daaronder italic.
    # Inline style op de span wint van gt's scoped `#id .gt_title { font-weight: normal }`
    # zonder dat we specificity-oorlog hoeven te voeren.
    parts <- c(paste0(
      "<span style=\"font-weight:bold;\">Table ", table_number, "</span>"))
    if (!is.null(title))    parts <- c(parts, paste0("<em>", title,    "</em>"))
    if (!is.null(subtitle)) parts <- c(parts, paste0("<em>", subtitle, "</em>"))
    out <- out |>
      tab_header(title = gt::html(paste(parts, collapse = "<br>")))
  } else if (!is.null(title) || !is.null(subtitle)) {
    out <- out |>
      tab_header(
        title    = if (!is.null(title)) md(paste0("*", title, "*")) else "",
        subtitle = if (!is.null(subtitle)) md(paste0("*", subtitle, "*")) else NULL
      )
  }

  # Drie horizontale lijnen voor PDF (typst): tab_options met px() worden
  # door gt niet vertaald naar typst-stroke; cell_borders() wel.
  # HTML krijgt ze via tab_options hierboven, dus alleen voor non-HTML.
  if (!isTRUE(knitr::is_html_output())) {
    n_rows <- nrow(gt_tbl[["_data"]])
    # Bovenste dikke lijn = bottom-border van subtitle (val terug op title).
    # Locatie moet in een list() staan, anders wordt cells_title niet
    # doorgegeven aan typst-stroke (gt 1.1.0).
    top_loc <- if (!is.null(subtitle)) {
      list(cells_title(groups = "subtitle"))
    } else if (!is.null(title)) {
      list(cells_title(groups = "title"))
    } else {
      list(cells_column_labels())
    }
    out <- out |>
      tab_style(
        style     = cell_borders(sides = "bottom", weight = px(2.5), color = "black"),
        locations = top_loc
      ) |>
      tab_style(
        style     = cell_borders(sides = "bottom", weight = px(0.8), color = "black"),
        locations = cells_column_labels()
      ) |>
      tab_style(
        style     = cell_borders(sides = "bottom", weight = px(2.5), color = "black"),
        locations = cells_body(rows = n_rows)
      )
  }

  # CSS
  out |> opt_css("
    /* Container krimpt tot tabel-inhoud — voorkomt dat een lange Note. de
       tabel breed uitrekt (was visueel slecht leesbaar). Note wrapt dan
       binnen de natuurlijke tabel-breedte. NB: GEEN width op .gt_table
       zelf — gt zet daar inline-style 'width:Npx' op via tab_options(),
       die mogen we niet overrulen anders verliest de title-cell met
       colspan=ncol zijn volle breedte. */
    .gt_table_container {
      width: fit-content !important;
      max-width: 100% !important;
    }
    /* Titel en ondertitel beide italic — elk op eigen regel boven dikke lijn */
    .gt_heading {
      padding-top: 0 !important;
      padding-bottom: 0 !important;
      border-bottom: none !important;
    }
    /* NB: GEEN display: block — dat haalt de cel uit de table-layout
       waardoor colspan=ncol niet meer werkt en titel krimpt naar
       eerste-kolom-breedte. Laat het default table-cell-gedrag staan.
       Cel zelf is non-italic; italic ontstaat alleen waar <em>…</em>
       staat (via markdown `*...*` of expliciete <em>-tags). Dat maakt
       de table_number-modus mogelijk: 'Table 1' blijft non-italic, de
       beschrijvende titel daaronder is wel italic. */
    .gt_title {
      text-align: left !important;
      font-size: 1em !important;
      font-weight: normal !important;
      font-style: normal !important;
      white-space: normal !important;
      padding-top: 4px !important;
      padding-bottom: 6px !important;
      line-height: 1.4 !important;
    }
    .gt_title em {
      font-style: italic !important;
    }
    .gt_title strong {
      font-weight: bold !important;
    }
    .gt_subtitle {
      text-align: left !important;
      font-size: 1em !important;
      font-weight: normal !important;
      font-style: normal !important;
      white-space: normal !important;
      padding-top: 1px !important;
      padding-bottom: 4px !important;
      border-top: none !important;
    }
    .gt_subtitle em {
      font-style: italic !important;
    }

    /* Note. links uitgelijnd; wrapt binnen tabel-breedte i.p.v. deze
       uit te rekken. APA 7 §7.14: tabel-notes double-spaced. */
    .gt_sourcenotes, .gt_sourcenote {
      text-align: left !important;
      white-space: normal !important;
      word-wrap: break-word;
      overflow-wrap: break-word;
      line-height: 2 !important;
      padding-top: 6px !important;
    }

    /* Tabular figures voor gelijke cijferbreedte */
    .gt_row {
      font-variant-numeric: tabular-nums;
    }
    /* Sticky kolom-header — bij scrollen blijft de header bovenaan zichtbaar.
       Plus white-space: nowrap zodat headers nooit op streepjes/spaties
       wrappen ('BC-SMD' niet als 'BC-/SMD'). auto_width_apa() rekent
       met ruimere char-breedte voor headers, zodat de kolom breed genoeg is. */
    .gt_col_heading {
      position: sticky !important;
      top: 0 !important;
      background-color: #FFFFFF !important;
      z-index: 2;
      white-space: nowrap !important;
    }
  ")
}

# Voeg APA-stijl voetnoot(en) toe. Altijd met expliciete "Note." prefix.
# Als note_text het stars_note-fragment bevat, wordt dat afgesplitst en op
# een eigen regel geplaatst. Bij meerdere notes wordt elke note genummerd
# ("Note 1." / "Note 2.") zodat het voor de lezer zichtbaar gescheiden blokken
# zijn. Bij één enkele note: alleen "Note.".
tab_footnote_apa <- function(gt_tbl, note_text) {
  stars_pos <- regexpr(stars_note, note_text, fixed = TRUE)

  if (stars_pos > 0) {
    main_note <- trimws(substr(note_text, 1, stars_pos - 1))
    if (nzchar(main_note)) {
      # Twee notes: nummeren
      gt_tbl |>
        tab_source_note(source_note = md(paste0("*Note 1.* ", main_note))) |>
        tab_source_note(source_note = md(paste0("*Note 2.* ", stars_note)))
    } else {
      # Alleen stars: één note met "Note." prefix
      gt_tbl |>
        tab_source_note(source_note = md(paste0("*Note.* ", stars_note)))
    }
  } else {
    # Eén note zonder stars: prefix "Note."
    gt_tbl |>
      tab_source_note(source_note = md(paste0("*Note.* ", note_text)))
  }
}

# Significantiesterren als aparte kolom (optie B: decimalen perfect uitgelijnd)
fmt_stars <- function(p.value) {
  dplyr::case_when(
    is.na(p.value) ~ "",
    p.value < .001 ~ "***",
    p.value < .01  ~ "**",
    p.value < .05  ~ "*",
    TRUE           ~ ""
  )
}

# ----------------------------------------------------------------
# APA afrondingshelpers — gebruik in inline R en in tabellen
# ----------------------------------------------------------------

# p-waarde APA-stijl, gesplitst in tabel- en tekst-variant.
#
# Waarom twee functies? In tabellen wil je een rustige cel zonder operator
# (de kolomheader '*p*' zegt al wat er staat), in lopende tekst APA-7 wel
# met operator: "*p* < .001" of "*p* = .045". Eén functie die beide moet
# leveren wordt of inconsistent of vol met argumenten.

# Tabelvariant — zonder operator. "  .045" of "< .001" (de prefix-spaties
# houden de tabel-cel rustig naast de "<"-rij). Voor HTML wordt "<" als
# "&lt;" geleverd, omdat anders de browser "< .001" als HTML-tag-start ziet
# en de cel visueel leeg lijkt.
fmt_p <- function(p) {
  if (is.na(p)) return("n.b.")
  lt <- if (knitr::is_html_output()) "&lt; .001" else "< .001"
  if (p < .001) return(lt)
  digits <- if (p < .10) 3L else 2L
  paste0("  ", formatC(p, digits = digits, format = "f") |> sub("^0", "", x = _))
}

# Tekstvariant — APA-7 inline: "*p* `r fmt_p_text(...)`" levert
# "*p* < .001" of "*p* = .045". Geen extra "=" zelf in de tekst zetten.
fmt_p_text <- function(p) {
  if (is.na(p)) return("n.b.")
  lt <- if (knitr::is_html_output()) "&lt; .001" else "< .001"
  if (p < .001) return(lt)
  digits <- if (p < .10) 3L else 2L
  paste0("= ", formatC(p, digits = digits, format = "f") |> sub("^0", "", x = _))
}

# Met leading zero (b, SE, t, M, SD, schattingen op grotere schaal)
fmt_b  <- function(x) formatC(x, digits = 2, format = "f")
fmt_se <- function(x) formatC(x, digits = 2, format = "f")
fmt_t  <- function(x) formatC(x, digits = 2, format = "f")
fmt_ci <- function(lo, hi) paste0("[", fmt_b(lo), ", ", fmt_b(hi), "]")

# Degrees of freedom: 1 decimaal (Satterthwaite-df is meestal niet-integer)
fmt_df <- function(x) formatC(x, digits = 1, format = "f")

# Zonder leading zero (proporties / bounded 0-1)
fmt_r   <- function(x) formatC(x, digits = 2, format = "f") |> sub("^0", "", x = _)
fmt_r2  <- function(x) formatC(x, digits = 2, format = "f") |> sub("^0", "", x = _)
fmt_icc <- function(x) formatC(x, digits = 2, format = "f") |> sub("^0", "", x = _)

# Percentages
fmt_pct <- function(x, digits = 1) formatC(x, digits = digits, format = "f")

# Veelgebruikte voetnoot
stars_note <- "\\* *p* < .05. \\*\\* *p* < .01. \\*\\*\\* *p* < .001."

# ----------------------------------------------------------------
# apa_style_estimates(): Maaike's tabel-styling toepassen
#
# Verwacht een gt-object met kolommen `b`, `stars`, `std.error`, `statistic`,
# `p.value` en `CI`. Voegt:
#   - tab_spanner met label boven de cijfer-kolommen
#   - vaste breedtes (CI 130 px, stars 12 px)
#   - APA-stijl via gt_apa()
#   - b rechts uitgelijnd, stars links uitgelijnd
#   - kleine font (67%) voor sterren
#   - voetnoot via tab_footnote_apa()
#   - CSS-padding-fix voor sterren-kolom
# ----------------------------------------------------------------
apa_style_estimates <- function(gt_obj,
                                spanner,
                                title,
                                subtitle,
                                footnote = stars_note) {
  gt_obj |>
    tab_spanner(
      label   = spanner,
      columns = c(b, stars, std.error, statistic, p.value, CI)
    ) |>
    cols_width(CI ~ px(150), stars ~ px(8)) |>
    gt_apa(title = title, subtitle = subtitle) |>
    cols_align("right", columns = b) |>
    cols_align("left",  columns = stars) |>
    tab_style(
      style     = cell_text(size = pct(67), v_align = "top", align = "left"),
      locations = cells_body(columns = stars)
    ) |>
    tab_style(
      style     = cell_text(whitespace = "nowrap"),
      locations = list(cells_body(columns = CI), cells_column_labels(columns = CI))
    ) |>
    tab_footnote_apa(footnote) |>
    # Globale ruimte-en-rust regels:
    #   - sterretjes-kolom (3) extreem smal, geen padding
    #   - b-kolom (2) minimale padding rechts zodat b en sterretjes elkaar raken
    #   - CI-kolom (laatste) altijd op één regel, geen breekkans
    opt_css("
      td:nth-child(3), th:nth-child(3) {
        padding-left: 0 !important;
        padding-right: 0 !important;
      }
      td:nth-child(2) {
        padding-right: 1px !important;
      }
      td:last-child, th:last-child {
        white-space: nowrap !important;
      }
    ")
}
