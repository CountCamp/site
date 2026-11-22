# Data voor thema 3 en 4 (eenweg-ANOVA; welke groepen verschillen) van het
# oefenboek OZP 2. Eén dataset draagt beide thema's.
#
# Draaien vanuit de boekmap:  Rscript _common/data/maak_data_t3.R
# Schrijft twee .sav-bestanden naast dit script. De hoofdstukken lezen díe
# bestanden in en rekenen er alles uit; niets wordt overgetikt.
#
# Achterwaarts ontworpen (feedback_didactische_getallen): eerst de doelgetallen
# die de lezer zelf narekent, dan kleine data met hele scores die er precies op
# uitkomen. De stopifnot's hieronder zakken zodra een doelgetal niet meer klopt.

suppressMessages(library(haven))
hier <- local({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else "_common/data"
})

# ---- 1. t3_eekhoorns_nootjes.sav ---------------------------------------------
# Zeventien jonge eekhoorns verstoppen in de herfst elk twintig nootjes. Hoe ze
# dat leerden verschilt: vier zochten het alleen uit (groep 1), zeven kregen het
# voorgedaan door een oudere eekhoorn (groep 2), zes oefenden in een groepje
# leeftijdgenoten (groep 3). In de lente tellen we hoeveel van de twintig ze
# terugvinden.
#
# Doelen (gevonden met een zoektocht over n_i in 4..10, hele groepsgemiddelden
# en een heel groot gemiddelde, 18-11-2026):
#   - groepsgemiddelden 6, 9 en 11; groot gemiddelde precies 9, zodat de
#     voordoen-groep niets bijdraagt aan SSG (een lesdoel: dat kan);
#   - SSG = 60, SSE = 56, dus MSE = 4 en s_p = 2 -- wortel trekken met de hand;
#   - groepsvarianties 6, 3 en 4: ongelijk, zodat poolen iets dóét, en
#     gewogen naar df komt er precies 4 uit;
#   - F(2, 14) = 7.5: ruim tussen de kolommen .010 en .001 van Tabel E;
#   - post hoc met Tabel D (df = 14): alleen-voordoen is significant met LSD
#     en niet met Bonferroni (t = 2.393, tweezijdig .02 < p < .04);
#     alleen-samen allebei (t = 3.873, p < .002); voordoen-samen geen van beide
#     (t = 1.797, .05 < p < .10). Drie paren, drie uitkomsten;
#   - het contrast "alleen tegen de rest" (-1, .5, .5) geeft t = 3.495, dat
#     niet op een tabelkolom valt.
# Met hele scores en een heel groepsgemiddelde is elke kwadratensom per groep
# even; daardoor zijn bij deze n alleen varianties uit {2, 4, 6, ...} (n = 4),
# hele getallen (n = 7) en veelvouden van 0.4 (n = 6) haalbaar. (6, 3, 4) is
# de enige combinatie die ongelijk is, heel blijft en op SSE = 56 uitkomt.
alleen   <- c(3, 5, 8, 8)
voordoen <- c(12, 7, 8, 10, 10, 8, 8)
samen    <- c(14, 9, 10, 12, 12, 9)
ss <- function(x) sum((x - mean(x))^2)
stopifnot(
  mean(alleen) == 6, mean(voordoen) == 9, mean(samen) == 11,
  ss(alleen) == 18, ss(voordoen) == 18, ss(samen) == 20,
  var(alleen) == 6, var(voordoen) == 3, var(samen) == 4,
  all(c(alleen, voordoen, samen) >= 0), all(c(alleen, voordoen, samen) <= 20),
  mean(c(alleen, voordoen, samen)) == 9,
  # SSG = 4*(6-9)^2 + 7*(9-9)^2 + 6*(11-9)^2 = 36 + 0 + 24
  4 * 9 + 7 * 0 + 6 * 4 == 60,
  ss(alleen) + ss(voordoen) + ss(samen) == 56,
  # F = (60/2) / (56/14) = 30 / 4
  (60 / 2) / (56 / 14) == 7.5
)
eekhoorns <- data.frame(
  eekhoorn = labelled(1:17, label = "Eekhoorn"),
  leerwijze = labelled(rep(1:3, c(4, 7, 6)),
                       labels = c(alleen = 1, voordoen = 2, samen = 3),
                       label = "Hoe de eekhoorn leerde verstoppen"),
  nootjes = labelled(c(alleen, voordoen, samen),
                     label = "Teruggevonden nootjes (van 20)")
)
write_sav(eekhoorns, file.path(hier, "t3_eekhoorns_nootjes.sav"))

# ---- 2. t3_bevers_takken.sav (opgaven: uitvoer lezen) -------------------------
# Tweeëndertig jonge bevers in vier bouwploegen, elk met een andere manier van
# aansturen door een oudere bever (ploeg 1 tot 4). Per bever: hoeveel takken hij
# in een uur aansleept. Geen ronde doelgetallen: dit is uitvoer om te lézen, niet
# om na te rekenen. Wel eisen: de omnibus-F significant, en in de post hoc
# minstens één paar dat met LSD wel en met Bonferroni niet significant is, één
# dat met allebei significant is, en één dat met geen van beide is -- zodat de
# lezer alle drie de gevallen in één tabel tegenkomt. Gevonden door seeds 1 tot
# 5000 af te lopen (18-11-2026); seed 136 was de eerste die aan alles voldeed
# met hele takken en een F die niet op een kolom van Tabel E valt. (Het script
# loopt die zoektocht bij elke run opnieuw en zakt als een andere seed de
# eerste wordt -- dan is de data stilletjes veranderd.)
zoek_bevers <- function(seed) {
  set.seed(seed)
  n <- c(7, 8, 8, 9)
  mu <- c(14, 18, 20, 15)
  y <- round(unlist(Map(function(k, m) rnorm(k, m, 3.5), n, mu)))
  g <- factor(rep(1:4, n))
  if (any(y < 0)) return(NULL)
  a <- anova(lm(y ~ g))
  F <- a$`F value`[1]; p <- a$`Pr(>F)`[1]; MSE <- a$`Mean Sq`[2]; DFE <- a$Df[2]
  if (p > .01 || p < .0005) return(NULL)
  # niet dezelfde p als de eekhoorns (.006): een lezer dacht dat hij dubbel las
  if (formatC(p, format = "f", digits = 3) == "0.006") return(NULL)
  # niet op een kolom van Tabel E (2 decimalen)
  if (any(abs(F - round(qf(1 - c(.1, .05, .025, .01, .001), 3, DFE), 2)) < .05)) return(NULL)
  m <- tapply(y, g, mean); sp <- sqrt(MSE)
  # geen gemiddelde dat op een exacte halve eindigt (15.125): SPSS en R ronden
  # zo'n halve verschillend af, en dan drukt de nagebouwde tabel iets anders dan
  # het scherm (APA-lens, 18-11-2026). Groepen van 8 en het totaal van 32 maken
  # achtsten, dus dit kan hier echt voorkomen.
  mm <- c(m, mean(y)) * 1000
  if (any(abs(mm - round(mm)) < 1e-9 & round(mm) %% 10 == 5)) return(NULL)
  paren <- combn(4, 2)
  p2 <- apply(paren, 2, function(ij) {
    t <- (m[ij[1]] - m[ij[2]]) / (sp * sqrt(1 / n[ij[1]] + 1 / n[ij[2]]))
    2 * pt(-abs(t), DFE)
  })
  k <- ncol(paren)
  lsd <- p2 < .05; bon <- p2 * k < .05
  if (!(any(lsd & !bon) && any(bon) && any(!lsd))) return(NULL)
  # geen p die op twee decimalen op .05 of .017 valt (afrondval in de uitleg)
  if (any(abs(p2 - .05) < .004) || any(abs(p2 * k - .05) < .004)) return(NULL)
  list(y = y, g = g, F = F, p = p, p2 = p2)
}
bevers <- NULL
for (s in 1:5000) { bevers <- zoek_bevers(s); if (!is.null(bevers)) { seed_bevers <- s; break } }
cat("bevers: seed", seed_bevers, "\n")
stopifnot(!is.null(bevers), seed_bevers == 136)
bevers_df <- data.frame(
  bever = labelled(seq_along(bevers$y), label = "Bever"),
  ploeg = labelled(as.integer(bevers$g),
                   labels = c(`ploeg 1` = 1, `ploeg 2` = 2, `ploeg 3` = 3, `ploeg 4` = 4),
                   label = "Bouwploeg"),
  takken = labelled(as.numeric(bevers$y), label = "Takken aangesleept per uur")
)
write_sav(bevers_df, file.path(hier, "t3_bevers_takken.sav"))

cat("geschreven in", hier, ": t3_eekhoorns_nootjes.sav, t3_bevers_takken.sav (seed", seed_bevers, ")\n")
