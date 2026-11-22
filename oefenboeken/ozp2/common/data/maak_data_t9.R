# Data voor thema 9 (ANCOVA) van het oefenboek OZP 2.
#
# Draaien vanuit de boekmap:  Rscript _common/data/maak_data_t9.R
# Schrijft drie .sav-bestanden naast dit script. Het hoofdstuk leest dié
# bestanden in en rekent er alles uit; niets wordt overgetikt.
#
# Achterwaarts ontworpen (feedback_didactische_getallen): eerst de doelgetallen
# die de lezer zelf narekent, dan data die er precies op uitkomt. De
# stopifnot's zakken zodra een doelgetal niet meer klopt.

suppressMessages(library(haven))
hier <- local({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "_common/data"
})

# Gewone (ongecentreerde) Type-III-toetsen zoals SPSS ze drukt, zonder car:
# kwadratensom van een term = restkwadratensom zonder die kolommen min die mét.
rss <- function(X, y) sum(lm.fit(X, y)$residuals^2)
p_term <- function(y, g, c, interactie = FALSE) {
  G <- model.matrix(~ g, contrasts.arg = list(g = "contr.sum"))[, -1, drop = FALSE]
  X <- cbind(1, G, c)
  if (interactie) X <- cbind(X, G * c)
  kol_g <- 2:(1 + ncol(G)); kol_c <- 2 + ncol(G)
  kol_i <- if (interactie) (3 + ncol(G)):ncol(X) else integer(0)
  vol <- rss(X, y); df_e <- length(y) - ncol(X)
  f <- function(kol) {
    ss <- rss(X[, -kol, drop = FALSE], y) - vol
    F <- (ss / length(kol)) / (vol / df_e)
    pf(F, length(kol), df_e, lower.tail = FALSE)
  }
  c(g = f(kol_g), c = f(kol_c), gc = if (interactie) f(kol_i) else NA)
}
levene_p <- function(y, g) {
  z <- abs(y - ave(y, g)); anova(lm(z ~ g))$`Pr(>F)`[1]
}

# ---- 1. t9_raven_puzzel.sav --------------------------------------------------
# Jonge raven leren puzzeldozen openen: in het oostelijke bos doet een oude raaf
# het voor (methode 1, voordoen), in het westelijke bos prutsen ze zelf
# (methode 2, zelf prutsen). Na drie weken geeft de puzzelmeester elke raaf een
# cijfer (1-10, één decimaal). Vooraf is hun puzzelaanleg gemeten (schaal rond
# de 100). Dit zijn Bens getallen uit de bijles (OZP 2, les 9, 2025): de
# covariaat 100 tegen 120, het grote gemiddelde 110, de cijfers 7 tegen 9, en
# na correctie "nog maar één punt verschil". Doelen:
#   cijfer: oost 7.0, west 9.0           aanleg: oost 100, west 120, samen 110
#   helling binnen de groepen precies 0.05 (oost 0.04, west 0.06, samen 0.05,
#   want beide groepen hebben dezelfde kwadratensom op aanleg)
#   dus gecorrigeerd: 7.0 - 0.05 * (100 - 110) = 7.5 en 9.0 - 0.05 * 10 = 8.5.
# De twee afwijkingspatronen op aanleg sommeren tot 0 en hebben allebei
# kwadratensom 880; dan is de gepoolde helling het gemiddelde van de twee.
c_oost <- c(-15, -10, -9, -5, -3, 0, 0, 3, 5, 9, 10, 15)
c_west <- c(-16, -9, -8, -6, -4, -1, 2, 3, 6, 9, 10, 14)
stopifnot(sum(c_oost) == 0, sum(c_west) == 0, sum(c_oost^2) == 880, sum(c_west^2) == 880)

# Zoekt hele tienden y (cijfer = mu + y/10) met som 0 en kruisproduct precies
# b * 880 * 10, binnen de cijfergrenzen, met een restspreiding rond 0.6.
zoek_y <- function(cc, b, mu10, lo10, hi10, seed, pogingen = 60000) {
  doel <- round(b * sum(cc^2) * 10)
  paren <- list(c(which.max(cc), which.min(cc)))          # groot verschil
  paren[[2]] <- c(which.max(cc), which(cc == 10)[1])      # verschil 4 of 5
  paren[[3]] <- c(which(cc == 10)[1], which(cc == 9)[1])  # verschil 1
  set.seed(seed)
  beste <- NULL
  for (i in seq_len(pogingen)) {
    y <- round(b * cc * 10) + round(rnorm(length(cc), 0, 6))
    y[length(y)] <- y[length(y)] - sum(y)                  # som 0
    # kruisproduct precies op het doel: eenheden verschuiven tussen twee raven
    # (dat laat de som staan en verandert het kruisproduct met hun verschil)
    for (pr in paren) {
      d <- doel - sum(cc * y); stap <- cc[pr[1]] - cc[pr[2]]
      m <- if (identical(pr, paren[[3]])) d else round(d / stap)
      y[pr[1]] <- y[pr[1]] + m; y[pr[2]] <- y[pr[2]] - m
    }
    if (sum(y) != 0 || sum(cc * y) != doel) next
    cijfer10 <- mu10 + y
    if (any(cijfer10 < lo10 | cijfer10 > hi10)) next
    res <- y - b * cc * 10
    if (max(abs(res)) > 12) next
    kand <- list(y = y, res = res, sdres = sd(res))
    if (is.null(beste) || abs(kand$sdres - 6) < abs(beste$sdres - 6)) beste <- kand
  }
  beste
}

raven_ok <- FALSE
for (seed in 1:40) {
  o <- zoek_y(c_oost, 0.04, 70, 50, 90, seed)
  w <- zoek_y(c_west, 0.06, 90, 70, 100, seed + 100)
  if (is.null(o) || is.null(w)) next
  aanleg <- c(100 + c_oost, 120 + c_west)
  cijfer <- c(7 + o$y / 10, 9 + w$y / 10)
  methode <- factor(rep(1:2, each = 12))
  p_int <- p_term(cijfer, methode, aanleg, interactie = TRUE)
  p_anc <- p_term(cijfer, methode, aanleg)
  t_naief <- t.test(cijfer ~ methode, var.equal = TRUE)$p.value
  # Piet (Bens raaf uit de bijles): een raaf in het oosten die ver boven zijn
  # groepsgemiddelde zit zolang je aanleg niet kent, en vlak bij de
  # regressielijn zodra je dat wel doet. Zijn error vóór is y/10, zijn error ná
  # is het residu ten opzichte van de gepoolde lijn (helling 0.05).
  err_voor <- o$y / 10
  err_na   <- o$y / 10 - 0.05 * c_oost
  krimp    <- ifelse(err_voor > 0, err_voor - abs(err_na), -Inf)
  piet     <- which.max(krimp)
  piet_ok  <- sum(krimp == max(krimp)) == 1 && err_voor[piet] >= 0.8 &&
    abs(err_na[piet]) <= 0.25 && c_oost[piet] >= 10
  ok <- p_int[["gc"]] > .25 && p_anc[["g"]] < .03 && p_anc[["c"]] < .01 &&
    levene_p(cijfer, methode) > .15 && t_naief < .001 && piet_ok &&
    abs(cor(o$res, c_oost)) < 1e-9 && abs(cor(w$res, c_west)) < 1e-9
  if (ok) { raven_ok <- TRUE; break }
}
stopifnot("geen ravendata gevonden die aan alle doelen voldoet" = raven_ok)

# de doelgetallen, hardop
oost <- 7 + o$y / 10; west <- 9 + w$y / 10
bw <- function(y, g, c) {                    # gepoolde helling binnen de groepen
  cy <- c - ave(c, g); yy <- y - ave(y, g); sum(cy * yy) / sum(cy^2)
}
stopifnot(
  abs(mean(oost) - 7) < 1e-12, abs(mean(west) - 9) < 1e-12,
  mean(100 + c_oost) == 100, mean(120 + c_west) == 120,
  abs(coef(lm(oost ~ c_oost))[2] - 0.04) < 1e-12,
  abs(coef(lm(west ~ c_west))[2] - 0.06) < 1e-12,
  abs(bw(cijfer, methode, aanleg) - 0.05) < 1e-12,
  all(cijfer >= 1 & cijfer <= 10), all(round(cijfer * 10) == cijfer * 10)
)
raven <- data.frame(
  raaf    = labelled(1:24, label = "Raaf"),
  methode = labelled(rep(1:2, each = 12), labels = c(voordoen = 1, `zelf prutsen` = 2),
                     label = "Leermethode (1 = voordoen, oostelijk bos; 2 = zelf prutsen, westelijk bos)"),
  aanleg  = labelled(aanleg, label = "Puzzelaanleg, gemeten voor de training"),
  cijfer  = labelled(cijfer, label = "Cijfer van de puzzelmeester na drie weken (1-10)")
)
write_sav(raven, file.path(hier, "t9_raven_puzzel.sav"))

# ---- 2. t9_uilen_nestinspectie.sav (opgave T9.3, alleen uitvoer lezen) ---------
# Spiegelt werkgroep 9 (training in risicotaxatie bij jeugdbeschermers,
# gecorrigeerd voor werkervaring) in het bos: boswachter-uilen met en zonder
# een training in nestinspectie beoordelen dezelfde twintig nesten; geteld
# wordt hoe vaak ze adviseren een jong uit het nest te halen. Covariaat: jaren
# ervaring. De getrainde uilen zijn gemiddeld ervarener (de valkuil van WG9,
# begripsvraag a): het ruwe verschil overdrijft het trainingseffect. Doelen:
# interactie niet significant, ervaring en training wel, Levene niet, en het
# gecorrigeerde verschil duidelijk kleiner dan het ruwe.
uilen_ok <- FALSE
for (seed in 1:4000) {
  set.seed(seed)
  n <- 22
  erv_z <- pmin(pmax(round(rnorm(n, 9, 5)), 1), 25)     # zonder training
  erv_m <- pmin(pmax(round(rnorm(n, 14, 5)), 1), 25)    # met training
  ervaring <- c(erv_z, erv_m)
  training <- factor(rep(1:2, each = n))                 # 1 = geen, 2 = wel
  adviezen <- round(13.5 - 0.30 * ervaring - 1.6 * (training == 2) + rnorm(2 * n, 0, 1.8))
  adviezen <- pmin(pmax(adviezen, 0), 20)
  p_int <- p_term(adviezen, training, ervaring, interactie = TRUE)
  p_anc <- p_term(adviezen, training, ervaring)
  ruw <- diff(tapply(adviezen, training, mean))
  b_w <- bw(adviezen, training, ervaring)
  gec <- ruw - b_w * diff(tapply(ervaring, training, mean))
  ok <- p_int[["gc"]] > .30 && p_anc[["g"]] < .04 && p_anc[["c"]] < .005 &&
    levene_p(adviezen, training) > .20 && mean(erv_m) - mean(erv_z) >= 4 &&
    ruw < -2.3 && gec > -1.9 && gec < -1.2 &&
    t.test(ervaring ~ training, var.equal = TRUE)$p.value < .01
  if (ok) { uilen_ok <- TRUE; break }
}
stopifnot("geen uilendata gevonden die aan alle doelen voldoet" = uilen_ok)
uilen <- data.frame(
  uil      = labelled(1:(2 * n), label = "Boswachter-uil"),
  training = labelled(rep(1:2, each = n), labels = c(`geen training` = 1, `training` = 2),
                      label = "Training in nestinspectie gevolgd"),
  ervaring = labelled(ervaring, label = "Jaren ervaring als boswachter"),
  adviezen = labelled(adviezen, label = "Aantal adviezen 'jong uit het nest halen' (van 20 nesten)")
)
write_sav(uilen, file.path(hier, "t9_uilen_nestinspectie.sav"))

# ---- 3. t9_egels_oprollen.sav (tentamenvraag E9.4) -----------------------------
# Jonge egels met en zonder de cursus 'Rustig oprollen'; na afloop geteld hoe
# vaak ze per week schrikken. Covariaat: hoe schrikkerig ze vóór de cursus al
# waren. De cursusgroep was vooraf juist schrikkeriger (de bias werkt hier
# tégen de cursus), zodat het ruwe verschil klein en niet significant is, en
# het gecorrigeerde verschil wél. Dat is de les van college 10, dia 34: "de
# échte relatie is veel sterker dan je zou vinden als je naar de gehele groep
# kijkt".
egels_ok <- FALSE
for (seed in 1:4000) {
  set.seed(seed)
  n <- 15
  voor_g <- pmin(pmax(round(rnorm(n, 16, 5)), 5), 30)   # geen cursus
  voor_c <- pmin(pmax(round(rnorm(n, 21, 5)), 5), 30)   # cursus
  vooraf <- c(voor_g, voor_c)
  cursus <- factor(rep(1:2, each = n))                   # 1 = geen, 2 = cursus
  schrik <- round(1 + 0.5 * vooraf - 3 * (cursus == 2) + rnorm(2 * n, 0, 2))
  schrik <- pmin(pmax(schrik, 0), 25)
  p_int <- p_term(schrik, cursus, vooraf, interactie = TRUE)
  p_anc <- p_term(schrik, cursus, vooraf)
  t_ruw <- t.test(schrik ~ cursus, var.equal = TRUE)$p.value
  ok <- p_int[["gc"]] > .30 && p_anc[["g"]] < .01 && p_anc[["c"]] < .001 &&
    levene_p(schrik, cursus) > .20 && t_ruw > .20 &&
    t.test(vooraf ~ cursus, var.equal = TRUE)$p.value < .05 &&
    diff(tapply(schrik, cursus, mean)) < 0
  if (ok) { egels_ok <- TRUE; break }
}
stopifnot("geen egeldata gevonden die aan alle doelen voldoet" = egels_ok)
egels <- data.frame(
  egel   = labelled(1:(2 * n), label = "Egel"),
  cursus = labelled(rep(1:2, each = n), labels = c(`geen cursus` = 1, `cursus` = 2),
                    label = "Cursus 'Rustig oprollen' gevolgd"),
  vooraf = labelled(vooraf, label = "Schrikkerigheid voor de cursus (score 0-30)"),
  schrik = labelled(schrik, label = "Schrikreacties per week na de cursus")
)
write_sav(egels, file.path(hier, "t9_egels_oprollen.sav"))

cat("geschreven in", hier, ": t9_raven_puzzel.sav, t9_uilen_nestinspectie.sav, t9_egels_oprollen.sav\n")
