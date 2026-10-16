# venn_plakjes() -- één doelcirkel, en een paar buitencirkels die er elk een
# eigen plakje uit snijden ZONDER elkaar te raken. De oppervlakken kloppen: elke
# cirkel heeft oppervlak 1 (een gestandaardiseerde variabele, variantie 1), en
# het plakje dat buitencirkel k uit de doelcirkel snijdt heeft oppervlak
# plakjes[k]. Die getallen geef je mee; de afstanden worden eruit uitgerekend.
#
# Waar het voor is: r^2 tussen twee variabelen (één plakje), de communaliteit
# van een item bij ongecorreleerde componenten (een plakje per component), R^2
# bij voorspellers die onderling niet correleren. Gebouwd voor het Venn-kader
# bij de communaliteit in thema 4 (spoor pca_venn, 16-10-2026).
#
# Waar het NIET voor is, en dat is met opzet: buitencirkels die elkaar
# overlappen. Correleren de componenten of de voorspellers, dan delen ze ook
# onderling variantie, en dan is er geen eerlijk plaatje meer waarin elk stukje
# van één cirkel is. Zo'n plaatje laat deze functie dus niet toe: hij houdt de
# buitencirkels uit elkaar en controleert dat.
#
# Waarom even grote cirkels en niet "mooi passend". Ben, 16-10-2026, bij zijn
# bordschets: "IK WEET NIET OF DE TEKENING PRECIES KLOPT". Een Venn-plaatje dat
# klopt, laat de oppervlakken het werk doen, en dan moet elke variabele even
# groot zijn: allemaal variantie 1. Dezelfde keuze als het R^2-plaatje in thema
# 0 van het MVDA-oefenboek ("Elke cirkel is op 1 gezet, want het gaat hier om
# aandelen").
#
# DE GRENS DIE DAARUIT VOLGT. Met even grote cirkels past niet elk setje
# plakjes. Twee plakjes van .45 vragen elk een buitencirkel die bijna over het
# midden van de doelcirkel valt, en dan raken die twee elkaar, hoe je ze ook
# draait. Gemeten op thema 4: na varimax passen alle twaalf items (één groot
# plakje en twee kleintjes), en ongeroteerd ook. Past het niet, dan stopt deze
# functie met een melding -- liever geen plaatje dan een plaatje dat liegt.
#
#   plakjes   benoemde vector met oppervlakken tussen 0 en 1; samen hooguit 1.
#   start     de richting (in graden, 0 = rechts, tegen de klok in) waarin het
#             GROOTSTE plakje komt te liggen. De rest volgt op gelijke afstanden.
#   marge     de kleinste ruimte die tussen twee buitencirkels moet blijven, als
#             deel van de straal. Nul betekent: mogen elkaar net raken.
#   n         punten per halve boog; bepaalt alleen hoe glad het plaatje is.
#
# Geeft een lijst:
#   straal    de straal van elke cirkel (oppervlak 1, dus 1/sqrt(pi))
#   cirkels   naam, x, y, plakje en afstand van elke cirkel; de doelcirkel heet
#             ".doel" en staat in (0, 0)
#   randen    de omtrek van elke cirkel als punten (naam, x, y), voor geom_path
#             of geom_polygon met group = naam
#   lenzen    elk plakje als veelhoek (naam, x, y), voor geom_polygon
#   plekken   per buitencirkel zijn richting (`hoek`, om de naam de goede kant op
#             uit te lijnen: een naam die op het punt van zijn eigen cirkel
#             gecentreerd staat, valt met een halve regel over de rand), een
#             plek voor de naam (net buiten zijn verre rand), een plek voor het
#             getal (in het plakje als dat breed genoeg
#             is, anders er net buiten, mét het punt waar een streepje heen kan)
#   rest      één plek in het witte deel van de doelcirkel, zo ver mogelijk van
#             elke rand -- ook de plek voor de naam van de doelcirkel -- met
#             `ruimte`: de afstand tot de dichtstbijzijnde rand, in stralen
#   controle  het gemeten oppervlak van elk getekend plakje, en de kleinste
#             ruimte tussen twee buitencirkels -- zodat wie het plaatje gebruikt
#             het kan nameten in plaats van geloven
venn_lens_opp <- function(d, r) {
  # Het oppervlak van de overlap van twee even grote cirkels op afstand d.
  if (d >= 2 * r) return(0)
  if (d <= 0) return(pi * r^2)
  2 * r^2 * acos(d / (2 * r)) - (d / 2) * sqrt(4 * r^2 - d^2)
}

venn_afstand <- function(f, r) {
  # Omgekeerd: op welke afstand overlappen twee even grote cirkels precies f?
  if (f <= 0) return(2 * r)
  if (f >= pi * r^2) return(0)
  uniroot(function(d) venn_lens_opp(d, r) - f, c(0, 2 * r), tol = 1e-13)$root
}

venn_plakjes <- function(plakjes, start = 180, marge = 0.05, n = 180) {
  stopifnot(
    "venn_plakjes: geef de plakjes een naam" =
      !is.null(names(plakjes)) && all(nzchar(names(plakjes))),
    "venn_plakjes: een plakje ligt tussen 0 en 1" =
      all(is.finite(plakjes)) && all(plakjes >= 0) && all(plakjes <= 1),
    "venn_plakjes: de plakjes samen kunnen niet meer dan de hele cirkel zijn" =
      sum(plakjes) <= 1 + 1e-12)

  r <- 1 / sqrt(pi)                        # oppervlak 1
  k <- length(plakjes)
  d <- vapply(plakjes, venn_afstand, numeric(1), r = r)

  # De richtingen: het grootste plakje op `start`, en de rest zo dat de
  # KLEINSTE ruimte tussen twee buitencirkels zo groot mogelijk is. Vanaf drie
  # cirkels wordt daar altijd naar gezocht, niet alleen als gelijke hoeken niet
  # passen. Reden: op de proef van 16-10 pasten gelijke hoeken wel, maar stonden
  # alertheid en uitstelgedrag zo dicht op elkaar (0.22 straal) dat testlezer
  # Michelle twee keer moest kijken of ze elkaar raakten -- en dat ze elkaar níét
  # raken is de hele pointe van het plaatje. Bij één of twee cirkels is gelijke
  # afstand al het beste.
  ruimte <- function(hoeken) {
    if (k < 2) return(Inf)
    x <- d * cos(hoeken * pi / 180); y <- d * sin(hoeken * pi / 180)
    paren <- utils::combn(k, 2)
    min(sqrt((x[paren[1, ]] - x[paren[2, ]])^2 +
             (y[paren[1, ]] - y[paren[2, ]])^2)) - 2 * r
  }
  volgorde <- order(plakjes, decreasing = TRUE)
  hoeken <- numeric(k)
  hoeken[volgorde] <- start + (seq_len(k) - 1) * 360 / k
  if (k >= 3) {
    beste <- hoeken                        # gelijke hoeken doen ook mee
    # Vijftig startstanden, zonder toeval. Geen set.seed() hier: deze functie
    # wordt in een setup-chunk aangeroepen tussen seeds die vastleggen wat er op
    # de bladzijde staat (parallel analysis in thema 4), en een helper die de
    # toevalsstroom van zijn aanroeper verzet, verandert getallen ver van hier.
    for (poging in 1:50) {
      schuif <- ((poging * 0.6180340 + seq_len(k - 1) * 0.4142136) %% 1 - 0.5) * 120
      begin <- hoeken[-volgorde[1]] + schuif
      uit <- stats::optim(begin, function(h) {
        alle <- numeric(k); alle[volgorde[1]] <- start; alle[-volgorde[1]] <- h
        -ruimte(alle)
      })
      kandidaat <- numeric(k); kandidaat[volgorde[1]] <- start
      kandidaat[-volgorde[1]] <- uit$par
      if (ruimte(kandidaat) > ruimte(beste) + 1e-9) beste <- kandidaat
    }
    # Op een tiende graad, zodat een render op een andere machine niet om een
    # rekenrestje een ander plaatje geeft.
    hoeken <- round(beste, 1)
  }
  if (ruimte(hoeken) < marge * r) {
    stop("venn_plakjes: deze plakjes passen niet met even grote cirkels zonder ",
         "dat twee buitencirkels elkaar raken (kleinste ruimte ",
         signif(ruimte(hoeken) / r, 3), " straal, gevraagd ", marge, "). ",
         "Dat is een grens van het plaatje, geen fout in de getallen.", call. = FALSE)
  }
  hoek_rad <- hoeken * pi / 180
  cx <- d * cos(hoek_rad); cy <- d * sin(hoek_rad)

  cirkels <- data.frame(naam = c(".doel", names(plakjes)),
                        x = c(0, cx), y = c(0, cy),
                        plakje = c(NA, unname(plakjes)),
                        afstand = c(0, unname(d)), hoek = c(NA, hoeken),
                        row.names = NULL)

  rondje <- seq(0, 2 * pi, length.out = 4 * n + 1)
  randen <- do.call(rbind, lapply(seq_len(nrow(cirkels)), function(i) {
    data.frame(naam = cirkels$naam[i],
               x = cirkels$x[i] + r * cos(rondje),
               y = cirkels$y[i] + r * sin(rondje))
  }))

  # Een plakje: de boog van de doelcirkel die binnen de buitencirkel valt, en
  # dan terug langs de boog van de buitencirkel die binnen de doelcirkel valt.
  # Bij even grote cirkels zijn die twee bogen even lang (halve hoek a).
  lens <- function(i) {
    if (plakjes[i] <= 0) return(NULL)
    a <- acos(d[i] / (2 * r))
    h1 <- seq(hoek_rad[i] - a, hoek_rad[i] + a, length.out = n)
    h2 <- seq(hoek_rad[i] + pi - a, hoek_rad[i] + pi + a, length.out = n)
    data.frame(naam = names(plakjes)[i],
               x = c(r * cos(h1), cx[i] + r * cos(h2)),
               y = c(r * sin(h1), cy[i] + r * sin(h2)))
  }
  lenzen <- do.call(rbind, lapply(seq_len(k), lens))

  # Nameten wat er getekend is (schoenveterformule), in plaats van te geloven dat
  # de afstand goed was. Een veelhoek met 2n punten mist een klein randje van de
  # echte boog; bij n = 180 is dat ruim onder de duizendste van een plakje.
  opp <- function(p) abs(sum(p$x * c(p$y[-1], p$y[1]) - c(p$x[-1], p$x[1]) * p$y)) / 2
  gemeten <- vapply(names(plakjes), function(nm) {
    p <- lenzen[lenzen$naam == nm, ]
    if (nrow(p) == 0) 0 else opp(p)
  }, numeric(1))

  # Plekken voor de woorden. Het getal van een plakje staat in het plakje zelf
  # als dat breed genoeg is; anders net buiten de doelcirkel, in de eigen
  # buitencirkel, met het midden van het plakje als punt voor een streepje.
  breed_genoeg <- function(i) (2 * r - d[i]) > 0.55 * r
  plekken <- do.call(rbind, lapply(seq_len(k), function(i) {
    ux <- cos(hoek_rad[i]); uy <- sin(hoek_rad[i])
    midden <- d[i] / 2                     # het plakje loopt langs de as van d - r tot r
    binnen <- breed_genoeg(i)
    getal_afstand <- if (binnen) midden else r + 0.30 * r
    data.frame(naam = names(plakjes)[i], hoek = hoeken[i] %% 360,
               naam_x = (d[i] + r * 1.12) * ux, naam_y = (d[i] + r * 1.12) * uy,
               getal_x = getal_afstand * ux, getal_y = getal_afstand * uy,
               wijs_x = midden * ux, wijs_y = midden * uy,
               getal_binnen = binnen)
  }))

  # Eén plek in het witte deel van de doelcirkel: het punt dat het verst van
  # alle randen af ligt -- van de buitencirkels én van de rand van de
  # doelcirkel zelf. Alleen de buitencirkels meetellen zette het woord op de
  # proef van 16-10 dwars over de rand van de doelcirkel. Gezocht op een raster,
  # want het witte deel heeft geen nette vorm.
  raster <- expand.grid(x = seq(-r, r, length.out = 81), y = seq(-r, r, length.out = 81))
  raster <- raster[raster$x^2 + raster$y^2 <= r^2, ]
  vrij <- vapply(seq_len(nrow(raster)), function(j) {
    min(sqrt((raster$x[j] - cx)^2 + (raster$y[j] - cy)^2) - r,
        r - sqrt(raster$x[j]^2 + raster$y[j]^2))
  }, numeric(1))
  rest <- raster[which.max(vrij), ]

  # Geen aparte plek voor de naam van de doelcirkel. Die stond hier een ronde
  # lang ("net buiten de rand, in de grootste opening tussen de buitencirkels"),
  # en zette op de proef van 16-10 de naam onder de grote buitencirkel: een
  # cirkel die dicht bij het midden ligt laat een opening die groot lijkt en het
  # niet is. Zet de naam in het wit, bij `rest`.

  # `ruimte` bij rest: hoe ver dat punt van de dichtstbijzijnde rand ligt, in
  # stralen. Een woord dat daar staat mag hooguit zo half-breed zijn. Toegevoegd
  # op 16-10 na de beeldverteller: het item werd gekozen op zichtbare plakjes,
  # en niets toetste of het woord in het wit past -- bij acht van de twaalf items
  # in thema 4 had het over een rand gestaan.
  list(straal = r, cirkels = cirkels, randen = randen, lenzen = lenzen,
       plekken = plekken,
       rest = data.frame(x = rest$x, y = rest$y, ruimte = max(vrij) / r),
       controle = list(gevraagd = plakjes, gemeten = gemeten,
                       ruimte = ruimte(hoeken) / r))
}
