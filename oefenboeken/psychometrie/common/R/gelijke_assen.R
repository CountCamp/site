# gelijke_assen() -- panelen naast elkaar die je met elkaar vergelijkt, krijgen
# per as een venster van dezelfde breedte en streepjes met dezelfde stap.
#
# Waarom: Ben, 13-10-2026, "als we grafieken naast elkaar zetten, zorg dan dat
# de assen gelijke range hebben en gelijke stappen hebben, zodat duidelijk is
# dat helling (ruw) niet veranderd". In thema 7 stonden de ruwe en de
# gecentreerde wolk naast elkaar, allebei 87 punt breed, maar ggplot koos links
# een stap van 25 en rechts van 20: dezelfde helling zag er rechts steiler uit.
# ggplot kiest zijn stap mede op grond van waar het venster ligt; deze functie
# kiest hem alleen op grond van de breedte, en dus voor elk paneel dezelfde.
#
#   bereiken  per paneel de data (of het bereik) die erin moeten; range() wordt
#             genomen, dus ruwe data mag ook.
#   n         ongeveer hoeveel streepjes, zoals in pretty().
#   rek       de marge per kant, als deel van de breedte: 0.05 voor ggplot,
#             0.04 voor base R (xaxs = "r"). De streepjes komen over het
#             venster dat je echt ziet.
#   anker     waar een smaller paneel in de gezamenlijke breedte komt:
#             "midden", "onder" (eigen onderkant houden) of "boven".
#   stap      een vaste stap opgeven; NULL laat pretty() hem kiezen.
#
# Geeft list(limieten, breaks, zichtbaar, stap, breedte). limieten[[i]] gaat
# naar coord_cartesian(xlim = ...) of plot(xlim = ...), breaks[[i]] naar
# scale_x_continuous(breaks = ...) of axis(1, at = ...).
#
# Bij facet_wrap() en facet_grid() met scales = "fixed" (de standaard) is dit
# niet nodig: die delen bereik en streepjes al. Het is voor losse plots naast
# elkaar (patchwork, par(mfrow)) waarvan de data op verschillende plekken
# liggen, zoals ruw en gecentreerd.
#
# Getoetst op de twee vensters van thema 7 (0..87 en -56.33..30.67): stap 20 in
# beide, streepjes 0..80 en -60..20.
gelijke_assen <- function(bereiken, n = 5, rek = 0.05,
                          anker = c("midden", "onder", "boven"), stap = NULL) {
  anker <- match.arg(anker)
  bereiken <- lapply(bereiken, function(r) range(r, na.rm = TRUE))
  breedte <- max(vapply(bereiken, diff, numeric(1)))
  if (!is.finite(breedte) || breedte <= 0) stop("gelijke_assen(): geen bereik met een breedte boven 0")
  limieten <- lapply(bereiken, function(r) {
    extra <- breedte - diff(r)
    switch(anker,
           midden = r + c(-1, 1) * extra / 2,
           onder  = c(r[1], r[1] + breedte),
           boven  = c(r[2] - breedte, r[2]))
  })
  zichtbaar <- lapply(limieten, function(l) l + c(-1, 1) * rek * breedte)
  # De stap hangt alleen van de breedte af, nooit van waar het venster ligt.
  if (is.null(stap)) stap <- diff(pretty(c(0, breedte * (1 + 2 * rek)), n = n))[1]
  breaks <- lapply(zichtbaar, function(z) {
    b <- seq(ceiling(z[1] / stap - 1e-9), floor(z[2] / stap + 1e-9)) * stap
    b[abs(b) < stap * 1e-9] <- 0          # geen "-0"
    b
  })
  stopifnot(
    "gelijke_assen: de vensters zijn niet even breed" =
      diff(range(vapply(limieten, diff, numeric(1)))) < 1e-9 * breedte,
    "gelijke_assen: een paneel krijgt minder dan drie streepjes" =
      all(lengths(breaks) >= 3),
    "gelijke_assen: de stappen verschillen" =
      all(vapply(breaks, function(b) all(abs(diff(b) - stap) < 1e-9 * stap), logical(1))))
  list(limieten = limieten, breaks = breaks, zichtbaar = zichtbaar,
       stap = stap, breedte = breedte)
}
