# b2_waar.R -- twee figuren bij een regressie met een dummy en een interactie,
# lm(y ~ x * z) met z = 0/1. Gebouwd voor thema 7 (test bias), 17-10-2026, na
# vraag 40 van de sommendag: studenten zagen niet waarom het gewicht van de
# dummy ruw niet en gecentreerd wel significant is.
#
#   figuur_b2_waar()  waar meet b2? Twee panelen, ruw en gecentreerd, met
#                     dezelfde punten en dezelfde twee groepslijnen. Bij x = 0
#                     een maatstreep van lijn tot lijn: dat is b2.
#   figuur_gat()      het gat tussen de twee groepslijnen als één lijn,
#                     b2 + b3 x, met zijn betrouwbaarheidsband. b2 is zijn
#                     hoogte bij x = 0, b3 zijn helling.
#
# Zelfde beeldtaal als de figuur bij vraag 40 (_naar_pum/sommendag_2026-10-16/
# R/items_t7.R, t7_twee_nulpunten(), stand van lab-main e85b4759). Die is in
# base R; dit is ggplot, omdat thema 7 zijn figuren in ggplot tekent. Wat er
# van daar is overgenomen, en waarom:
#   - dunne lijnen: binnen de data lwd 1.6, erbuiten 1.4 (ggplot: 0.56 en
#     0.49). Ben, 17-10 15:15: "mogen de lijnen ietsjes dunner, ik denk dan net
#     iets beter te onderscheiden". De b2-streep moet het eerst opvallen.
#   - b2 als maatstreep |--| van lijn tot lijn, met platte dwarsstreepjes die
#     precies op de twee lijnen zitten, en een dunne steel. Eerst was het een
#     pijl met een dikke steel, en kort werd die een vlek: "het lijkt meer tofu,
#     juist daar wat scherpte" (Ben, 17-10 15:18). Hij valt op door zijn kleur
#     (inkt tussen blauw en oranje), niet door zijn dikte.
#   - een wit randje onder de steel, zodat hij loskomt van de punten.
#   - onder het gecentreerde paneel beide schalen, het gemiddelde vet onder de
#     0, en een astitel die zelf zegt dat 0 het gemiddelde is (jeanne en
#     michelle moesten die brug eerst zelf slaan, 17-10).
#   - beide panelen even breed en met dezelfde stap (gelijke_assen.R; Ben,
#     13-10: "zodat duidelijk is dat helling (ruw) niet veranderd").
# Wat van thema 7 is en NIET van vraag 40: de kleuren, en de lijnsoort per
# groep (de eerste groep doorgetrokken, de tweede gestreept, zoals in elke
# figuur van thema 7). Waar een groep geen scores heeft, wordt haar lijn dun
# gestippeld doorgetrokken; vraag 40 streept daar, maar in thema 7 is
# gestreept al de tweede groep. Het grijze vlak markeert waar niemand scoort.
#
# Draaien: source("../_common/R/gelijke_assen.R") eerst; ggplot2 en patchwork.

# ggplot meet lijndikte in eenheden van 0.75 mm; base R in 1/96 inch. Eén
# lwd in base R is dus 1 / ggplot2::.pt in ggplot.
lwd_gg <- function(lwd) lwd / ggplot2::.pt

#   d        data.frame
#   x, y, z  kolomnamen: voorspeller (ruw), criterium, dummy (0/1)
#   namen    c(`0` = "wild", `1` = "tam"): de groepsnamen, in de volgorde 0, 1
#   kleur, vorm  benoemde vectoren met die namen (uit het thema)
#   xlab, ylab   astitels
#   thema    een ggplot-thema (thema_fig uit het thema)
#   dec      de getalzetter van het thema (minteken, decimalen)
#   d_b2     decimalen voor het label bij de streep; d_gem voor het gemiddelde
#   leeg     tekst in het grijze vlak
# Geeft het patchwork-object terug, met als attribuut "b2" de twee getekende
# b2's (ruw, gecentreerd), zodat het thema kan nagaan dat ze gelijk zijn aan
# de uitvoer.
figuur_b2_waar <- function(d, x, y, z, namen, kleur, vorm, xlab, ylab, thema, dec,
                           d_b2 = 2, d_gem = 2, leeg = "hier\nscoort\nniemand",
                           inkt = "#33322E", grijs = "#6c7a89", grijs_licht = "#8d98a4",
                           vlak = "#eef0f2") {
  stopifnot(requireNamespace("patchwork", quietly = TRUE), exists("gelijke_assen"))
  gem <- mean(d[[x]])
  d$.x_ruw <- d[[x]]; d$.x_c <- d[[x]] - gem; d$.y <- d[[y]]; d$.z <- d[[z]]
  d$.groep <- factor(namen[as.character(d$.z)], levels = namen)
  m_ruw <- lm(.y ~ .x_ruw * .z, data = d)
  m_c   <- lm(.y ~ .x_c * .z, data = d)
  stopifnot("b3 hangt niet af van centreren" =
              isTRUE(all.equal(coef(m_ruw)[[4]], coef(m_c)[[4]])))

  assen <- gelijke_assen(list(c(0, max(d$.x_ruw)), c(0, max(d$.x_ruw)) - gem), anker = "onder")
  bereik_g <- lapply(split(d$.x_ruw, d$.z), range)      # per groep: waar zit ze?

  # De lijnen per groep, in ruwe punten; voor het gecentreerde paneel verschoven.
  # Uit het ruwe model: dat het gecentreerde dezelfde lijnen geeft, toetst de
  # stopifnot hieronder.
  y_bij <- function(xr, g) unname(predict(m_ruw, data.frame(.x_ruw = xr, .z = g)))
  stopifnot("ruw en gecentreerd zijn dezelfde lijnen" = all(vapply(0:1, function(g) {
    xs <- seq(min(d$.x_ruw), max(d$.x_ruw), length.out = 5)
    isTRUE(all.equal(y_bij(xs, g), unname(predict(m_c, data.frame(.x_c = xs - gem, .z = g)))))
  }, logical(1))))
  lijn <- function(g, van, tot, deel) {
    xs <- seq(van, tot, length.out = 2)
    data.frame(xr = xs, y = y_bij(xs, g), groep = factor(namen[[g + 1]], levels = namen),
               deel = deel, id = paste(g, deel, van))
  }
  rand <- max(assen$limieten[[1]])     # rechts tot de hoogste score van allemaal, niet verder
  stukken <- do.call(rbind, lapply(0:1, function(g) {
    r <- bereik_g[[as.character(g)]]
    rbind(lijn(g, min(assen$zichtbaar[[1]]), r[1], "buiten"), lijn(g, r[1], r[2], "binnen"),
          lijn(g, r[2], rand, "buiten"))
  }))

  y_as <- range(c(d$.y, y_bij(0, 0), y_bij(0, 1)))
  y_as <- y_as + c(-1, 1) * 0.04 * diff(y_as)
  laagste <- min(d$.x_ruw)

  paneel <- function(verschuif, limieten, titel, xtitel) {
    # verschuif: wat er van de ruwe X af gaat (0 links, het gemiddelde rechts).
    # X = 0 in dit paneel ligt dus bij een ruwe score van `verschuif`.
    y0 <- y_bij(verschuif, 0); y1 <- y_bij(verschuif, 1)
    p <- ggplot() +
      annotate("rect", xmin = -Inf, xmax = laagste - verschuif, ymin = -Inf, ymax = Inf, fill = vlak) +
      annotate("text", x = (min(limieten) + laagste - verschuif) / 2, y = max(y_as), label = leeg,
               colour = grijs, size = 2.8, vjust = 1, lineheight = 0.9) +
      geom_vline(xintercept = 0, colour = "#a3acb5", linewidth = lwd_gg(1)) +
      geom_point(data = d, aes(.x_ruw - verschuif, .y, colour = .groep, shape = .groep),
                 size = 1.2, alpha = 0.4) +
      geom_line(data = stukken[stukken$deel == "binnen", ],
                aes(xr - verschuif, y, colour = groep, linetype = groep, group = id),
                linewidth = lwd_gg(1.6)) +
      geom_line(data = stukken[stukken$deel == "buiten", ],
                aes(xr - verschuif, y, colour = groep, group = id),
                linewidth = lwd_gg(1.4), linetype = "dotted", show.legend = FALSE) +
      # b2: eerst het witte randje, dan de maatstreep met platte uiteinden
      annotate("segment", x = 0, xend = 0, y = y0, yend = y1, colour = "white",
               linewidth = lwd_gg(6), lineend = "butt") +
      annotate("segment", x = 0, xend = 0, y = y0, yend = y1, colour = inkt,
               linewidth = lwd_gg(2), lineend = "butt",
               arrow = grid::arrow(angle = 90, ends = "both", length = grid::unit(1.4, "mm"))) +
      scale_colour_manual(values = kleur, name = NULL) +
      scale_shape_manual(values = vorm, name = NULL) +
      scale_linetype_manual(values = setNames(c("solid", "dashed"), namen), name = NULL) +
      coord_cartesian(xlim = limieten, ylim = y_as, clip = "off") +
      labs(title = titel, x = xtitel, y = ylab) +
      thema
    # Het label: in het lege vlak rechts naast de streep, daar zit niets; in de
    # wolk linksboven de bovenste lijn, waar die stijgende lijn niet meer loopt
    # (beeldverteller, 17-10: naast de streep lag het eerst op 16 tamme panda's).
    lab <- paste0("italic(b)[2] == '", dec(y1 - y0, d_b2), "'")
    # adjustcolor() en niet alpha(): in een R-sessie waarin psych geladen is
    # (thema 2), is alpha() Cronbachs alfa, en dan breekt dit met "Data must
    # either be a data frame or a matrix". Gemeten 17-10-2026 met
    # _toets_waarschuwingen.R, die alle thema's in één sessie knit.
    wit <- grDevices::adjustcolor("white", alpha.f = 0.85)
    # In het lege vlak naast de streep: halverwege, tenzij de streep lang is en de
    # onderste lijn naar rechts steiler oploopt. Dan loopt die lijn dwars door een
    # label op halve hoogte (beeldverteller, 17-10: bij de pissebedden liep de
    # blauwe stippellijn door "20.91"), en komt het label vlak onder de bovenste
    # lijn, waar de onderste pas ver naar rechts aankomt.
    hel <- c(coef(m_ruw)[[2]], coef(m_ruw)[[2]] + coef(m_ruw)[[4]])   # helling groep 0, groep 1
    onder_steiler <- if (y0 < y1) hel[1] > hel[2] else hel[2] > hel[1]
    y_lab <- if (abs(y1 - y0) > 0.15 * diff(y_as) && onder_steiler) {
      max(y0, y1) - 0.15 * abs(y1 - y0)
    } else (y0 + y1) / 2
    etiket <- if (verschuif < laagste) {
      annotate("label", x = 0, y = y_lab, label = lab, parse = TRUE, hjust = -0.15,
               size = 3.4, colour = inkt, border.colour = NA, fill = wit)
    } else {
      annotate("label", x = 0, y = max(y0, y1) + 0.03 * diff(y_as), label = lab, parse = TRUE,
               hjust = 1.06, vjust = 0, size = 3.4, colour = inkt, border.colour = NA, fill = wit)
    }
    p + etiket
  }

  br_ruw <- assen$breaks[[1]]; br_c <- assen$breaks[[2]]
  # Geen streepje onder het gecentreerde paneel waar de ruwe score onder 0 zou
  # komen: zo'n score bestaat niet (eerste proef: "-60 (-3.7)").
  br_c <- br_c[br_c + gem >= 0]
  links <- paneel(0, assen$limieten[[1]], "ruw", xlab) +
    scale_x_continuous(breaks = br_ruw, labels = function(b) dec(b, 0))
  # Onder het gecentreerde paneel beide schalen: de gecentreerde als gewone
  # streepjes, en daaronder in grijs de ruwe score die op die plek staat, onder
  # de 0 vet het gemiddelde. Precies onder elk streepje, dus met het gemiddelde
  # erin (16.33, niet 16), zodat niemand hoeft te raden welk getal bij welk
  # streepje hoort.
  onder <- data.frame(x = br_c, lab = dec(br_c + gem, d_gem), vet = abs(br_c) < 1e-9)
  rechts <- paneel(gem, assen$limieten[[2]], "gecentreerd",
                   paste0(xlab, ", gecentreerd (0 = het gemiddelde)\nin grijs eronder: de ruwe score")) +
    scale_x_continuous(breaks = br_c, labels = function(b) dec(b, 0)) +
    annotate("text", x = onder$x[!onder$vet], y = -Inf, label = onder$lab[!onder$vet],
             vjust = 3.5, size = 2.9, colour = grijs_licht) +
    annotate("text", x = 0, y = -Inf, label = onder$lab[onder$vet], vjust = 3.5, size = 2.9,
             colour = inkt, fontface = "bold") +
    theme(axis.title.x = element_text(margin = margin(t = 17)))
  uit <- (links + theme(legend.position = "none")) + rechts +
    patchwork::plot_layout(guides = "collect") & theme(legend.position = "top")
  attr(uit, "b2") <- c(ruw = coef(m_ruw)[[3]], gecentreerd = coef(m_c)[[3]])
  uit
}

# figuur_gat() -- het gat tussen de twee groepslijnen (groep 1 min groep 0), bij
# elke ruwe X, met het 95%-betrouwbaarheidsinterval eromheen. Dit is één lijn:
# b2 + b3 X. b2 is zijn hoogte waar X = 0 is; b3 is zijn helling. Centreren
# verplaatst alleen de plek die "0" heet: de lijn en zijn helling blijven.
# Het interval is smal waar de data zitten en waaiert uit waar niemand zit;
# daarom heeft b2 ruw een veel grotere standaardfout dan gecentreerd.
#   namen  c(`0` = ..., `1` = ...): geef je die, dan krijgt het stuk van de as
#          waar maar één groep zit een eigen, lichter vlak met "alleen <groep>"
#          (michelle, 17-10: het bijschrift noemde de laagste tamme panda, en
#          dat was in het plaatje niet na te kijken).
figuur_gat <- function(d, x, y, z, xlab, ylab, thema, dec, d_b2 = 2, namen = NULL,
                       leeg = "hier\nscoort\nniemand", inkt = "#33322E", grijs = "#6c7a89",
                       band = "#c9ced4", vlak = "#eef0f2") {
  gem <- mean(d[[x]])
  d$.x <- d[[x]]; d$.y <- d[[y]]; d$.z <- d[[z]]
  m <- lm(.y ~ .x * .z, data = d)
  V <- vcov(m); b <- coef(m); df <- m$df.residual
  xs <- seq(0, max(d$.x) * 1.02, length.out = 300)
  gat <- function(x0) b[[3]] + b[[4]] * x0
  se  <- function(x0) sqrt(V[3, 3] + x0^2 * V[4, 4] + 2 * x0 * V[3, 4])
  k <- qt(.975, df)
  g <- data.frame(x = xs, gat = gat(xs), lo = gat(xs) - k * se(xs), hi = gat(xs) + k * se(xs))
  punten <- data.frame(x = c(0, gem), gat = gat(c(0, gem)), se = se(c(0, gem)))
  # `==` zet zelf al spaties; geen `~` erachter (APA-lens, 17-10: dubbele spatie).
  punten$label <- paste0("italic(b)[2]~'", c("ruw", "gecentreerd"), "'=='", dec(punten$gat, d_b2),
                         "'*','~italic(SE)=='", dec(punten$se, d_b2), "'")   # één spatie na de komma
  laagste <- min(d$.x)
  mins <- tapply(d$.x, d$.z, min)
  p0 <- ggplot(g, aes(x)) +
    annotate("rect", xmin = -Inf, xmax = laagste, ymin = -Inf, ymax = Inf, fill = vlak)
  if (!is.null(namen) && max(mins) > laagste) {
    eerst <- namen[[names(which.min(mins))]]
    p0 <- p0 +
      annotate("rect", xmin = laagste, xmax = max(mins), ymin = -Inf, ymax = Inf, fill = "#f6f7f8") +
      annotate("text", x = (laagste + max(mins)) / 2, y = max(g$hi), label = paste0("alleen\n", eerst),
               colour = grijs, size = 2.8, vjust = 1, lineheight = 0.9)
  }
  p0 +
    geom_hline(yintercept = 0, colour = grijs, linewidth = lwd_gg(1)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), fill = band, alpha = 0.7) +
    geom_line(aes(y = gat), colour = inkt, linewidth = lwd_gg(2)) +
    # Het interval als kale lijn, zónder dwarsstreepjes: in figuur_b2_waar() is een
    # streep met platte uiteinden b2 zelf, en dezelfde vorm hier als foutbalk liet
    # jeanne terugbladeren ("dezelfde vorm, twee betekenissen", 17-10).
    geom_linerange(data = punten, aes(x = x, ymin = gat - k * se, ymax = gat + k * se),
                   colour = inkt, linewidth = lwd_gg(1.6), inherit.aes = FALSE) +
    geom_point(data = punten, aes(x, gat), size = 2.4, colour = inkt) +
    # Labels van de lijn en de nullijn af (beeldverteller, 17-10): het ruwe label
    # boven zijn stip; het gecentreerde linksonder zijn balkje, in het lege stuk
    # onder de band. Rechts boven de stip legde het een wit vlak over de rand van
    # de band, en dat las jeanne als een vouw (17-10, tweede lezing).
    # Half doorzichtig: dit label ligt midden in de band, en een dekkend wit vlak
    # las de beeldverteller als een gat in die band (17-10).
    geom_label(data = punten[1, ], aes(x, gat, label = label), parse = TRUE, hjust = -0.04, vjust = -0.5,
               size = 3.2, colour = inkt, border.colour = NA,
               fill = grDevices::adjustcolor("white", alpha.f = 0.55)) +
    geom_label(data = transform(punten[2, ], y_lab = gat - k * se - 0.06 * diff(range(c(g$lo, g$hi)))),
               aes(x - 1, y_lab, label = label), parse = TRUE, hjust = 1, vjust = 1,
               size = 3.2, colour = inkt, border.colour = NA, fill = "white") +
    annotate("text", x = laagste / 2, y = max(g$hi), label = leeg,
             colour = grijs, size = 2.8, vjust = 1, lineheight = 0.9) +
    scale_x_continuous(breaks = pretty(c(0, max(d$.x))), labels = function(v) dec(v, 0)) +
    scale_y_continuous(labels = function(v) dec(v, 0)) +
    labs(x = xlab, y = ylab) +
    thema
}
