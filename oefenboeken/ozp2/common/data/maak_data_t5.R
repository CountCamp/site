# Data voor thema 5 (Kruskal-Wallis) van het oefenboek OZP 2.
# Draai met: Rscript maak_data_t5.R   (vanuit _common/data/)
#
# Alle getallen zijn achterwaarts ontworpen: eerst de rangen, dan pas de
# minuten. De zoektocht staat in 05_kruskal_wallis/_zoek_ontwerp.R.
#
# 1. t5_otters.sav -- het doorlopende voorbeeld. Vijftien jonge otters, drie
#    manieren om te leren zwemmen (1 = zelf uitzoeken, 2 = met moeder,
#    3 = met de hele familie), en hoeveel minuten het duurde tot het jong voor
#    het eerst op eigen kracht de beek overzwom.
#    Eisen waaraan de getallen voldoen (allemaal getoetst hieronder):
#    - N = 15, dus 12 / (N(N+1)) = 0.05 en 3(N+1) = 48: handrekenbaar;
#    - geen knopen, zodat SPSS precies de H van het formuleblad drukt;
#    - rangsommen 67 / 42 / 11 geven H = 8.56, ruim tussen de kolommen .02
#      en .01 van Tabel F (df = 2): geen afrondval;
#    - de hoogste score (95 minuten) zit in de middengroep: één otter trekt
#      het gemiddelde van 'met moeder' tot boven dat van 'zelf', terwijl de
#      rangen (en de medianen) de groep in het midden houden;
#    - post-hoc: alleen zelf tegenover familie is significant na Bonferroni.
# 2. t5_kraaien.sav -- T5.3, met de hand, mét knopen. Twaalf jonge kraaien,
#    drie soorten nest, aantal nachten dat ze om hulp riepen. Niet significant.
# 3. t5_hazen.sav -- T5.5, alleen uitvoer lezen. Dertig jonge hazen, drie
#    trainingsvormen, seconden stil blijven zitten; scheef, met knopen.

suppressMessages(library(haven))

# ---- 1. de otters ---------------------------------------------------------
otters <- data.frame(
  les = c(rep(1, 6), rep(2, 5), rep(3, 4)),
  minuten = c(17, 19, 26, 31, 38, 47,     # zelf uitzoeken    rangen 8 9 11 12 13 14
              9, 12, 14, 22, 95,          # met moeder        rangen 4 6 7 10 15
              4, 6, 7, 10)                # met de familie    rangen 1 2 3 5
)
rk <- rank(otters$minuten)
R  <- tapply(rk, otters$les, sum); ni <- as.numeric(table(otters$les)); N <- nrow(otters)
H  <- 12 / (N * (N + 1)) * sum(R^2 / ni) - 3 * (N + 1)
stopifnot(
  N == 15, all(ni == c(6, 5, 4)),
  length(unique(otters$minuten)) == N,                   # geen knopen
  all(R == c(67, 42, 11)),
  abs(H - 8.561) < 5e-4,
  which.max(otters$minuten) == 11,                       # de 95 zit bij 'met moeder'
  mean(otters$minuten[otters$les == 2]) > mean(otters$minuten[otters$les == 1]),
  median(otters$minuten[otters$les == 2]) < median(otters$minuten[otters$les == 1]),
  # met de hand: alle rangsommen heel, en de controle N(N+1)/2 klopt
  sum(R) == N * (N + 1) / 2
)
otters$les <- labelled(otters$les, c("zelf uitzoeken" = 1, "met moeder" = 2, "met de familie" = 3))
attr(otters$les, "label") <- "Manier van leren zwemmen"
attr(otters$minuten, "label") <- "Minuten tot de eerste overtocht op eigen kracht"
write_sav(otters, "t5_otters.sav")

# ---- 2. de kraaien (T5.3) -------------------------------------------------
# Aantal nachten (van veertien) dat een jonge kraai om hulp riep. Drie
# nesten: 1 = hoog in de boom, 2 = halverwege, 3 = laag. Twee knopen (een 3
# en een 6 komen twee keer voor), H klein: geen post-hoc.
kraaien <- data.frame(
  nest = rep(1:3, each = 4),
  nachten = c(2, 6, 8, 9,      # hoog         rangen 2 7.5 10 11
              3, 5, 7, 11,     # halverwege   rangen 3.5 6 9 12
              1, 3, 4, 6)      # laag         rangen 1 3.5 5 7.5
)
rk2 <- rank(kraaien$nachten); R2 <- tapply(rk2, kraaien$nest, sum); N2 <- nrow(kraaien)
H2 <- 12 / (N2 * (N2 + 1)) * sum(R2^2 / 4) - 3 * (N2 + 1)
tt <- table(rk2); kn <- as.numeric(tt[tt > 1])
stopifnot(
  N2 == 12, length(kn) == 2, all(kn == 2),               # precies twee knopen van twee
  sum(R2) == N2 * (N2 + 1) / 2,
  H2 < qchisq(.75, 2),                                   # H kleiner dan de eerste kolom (.25): p > .25
  all(abs(R2 * 2 - round(R2 * 2)) < 1e-9)                # rangsommen op halven
)
kraaien$nest <- labelled(kraaien$nest, c("hoog" = 1, "halverwege" = 2, "laag" = 3))
attr(kraaien$nest, "label") <- "Hoogte van het nest"
attr(kraaien$nachten, "label") <- "Nachten met hulproepen (van veertien)"
write_sav(kraaien, "t5_kraaien.sav")

# ---- 3. de hazen (T5.5) ---------------------------------------------------
# Seconden die een jonge haas stil blijft zitten als er een schaduw overheen
# glijdt. Drie trainingsvormen (1 = geen, 2 = met de ouders, 3 = met de hele
# groep). Scheef naar rechts (lognormaal), op hele seconden, dus met knopen.
# De seed is de eerste (vanaf 1) waarbij de trekking aan de eisen hieronder
# voldoet; zo is het bestand reproduceerbaar én ontworpen.
maak_hazen <- function(seed) {
  set.seed(seed)
  data.frame(
    training = rep(1:3, each = 10),
    seconden = round(c(rlnorm(10, log(8), 0.6), rlnorm(10, log(14), 0.6), rlnorm(10, log(26), 0.6)))
  )
}
toets_hazen <- function(hazen) {
  rk3 <- rank(hazen$seconden); R3 <- tapply(rk3, hazen$training, sum); N3 <- nrow(hazen)
  H3 <- 12 / (N3 * (N3 + 1)) * sum(R3^2 / 10) - 3 * (N3 + 1)
  tt3 <- table(rk3); kn3 <- as.numeric(tt3[tt3 > 1])
  C3 <- 1 - sum(kn3^3 - kn3) / (N3^3 - N3)
  Rb <- R3 / 10; se <- sqrt((N3 * (N3 + 1) / 12 - sum(kn3^3 - kn3) / (12 * (N3 - 1))) * (2 / 10))
  pb <- function(i, j) min(1, 3 * 2 * pnorm(-abs(Rb[i] - Rb[j]) / se))
  list(ok = N3 == 30 && length(kn3) >= 1 &&                      # er zijn knopen: SPSS wijkt af van de hand
         pchisq(H3 / C3, 2, lower.tail = FALSE) < .01 &&         # duidelijk significant
         pb(1, 3) < .05 && pb(2, 3) < .05 && pb(1, 2) > .10 &&   # twee paren wel, één duidelijk niet
         max(hazen$seconden) / median(hazen$seconden) > 3 &&     # echt scheef: een flinke uitschieter
         all(hazen$seconden >= 1),
       H3 = H3, C3 = C3, R3 = R3, kn3 = kn3, pb = c(pb(1, 2), pb(1, 3), pb(2, 3)))
}
seed_hazen <- NA
for (s in 1:2000) { if (toets_hazen(maak_hazen(s))$ok) { seed_hazen <- s; break } }
stopifnot(!is.na(seed_hazen))
hazen <- maak_hazen(seed_hazen)
th <- toets_hazen(hazen); stopifnot(th$ok)
H3 <- th$H3; C3 <- th$C3; R3 <- th$R3; kn3 <- th$kn3; pb <- function(i, j) th$pb[c("12" = 1, "13" = 2, "23" = 3)[paste0(i, j)]]
hazen$training <- labelled(hazen$training, c("geen" = 1, "met de ouders" = 2, "met de groep" = 3))
attr(hazen$training, "label") <- "Trainingsvorm"
attr(hazen$seconden, "label") <- "Seconden stil bij een schaduw"
write_sav(hazen, "t5_hazen.sav")

cat("otters: H =", round(H, 4), " rangsommen", R, "\n")
cat("kraaien: H =", round(H2, 4), " rangsommen", R2, " knopen", kn, "\n")
cat("hazen (seed", seed_hazen, "): H =", round(H3, 4), " met knopen", round(H3 / C3, 4), " rangsommen", R3,
    " p_bonf", round(th$pb, 4), "\n")
