# Rangtoetsen (Wilcoxon) voor thema 2 van het oefenboek OZP 2: rekenen zoals
# het formuleblad (Eq. 45-52), rekenen zoals SPSS, en de uitvoer van SPSS
# nabouwen. Hoort bij spss_uitvoer.R (tekent de tabellen) en getallen.R.
#
# Twee rekenwijzen staan hier bewust naast elkaar:
#   - het formuleblad: sigma_W en sigma_W+ uit n alleen, zonder correctie voor
#     knopen (gelijke scores). Zo rekent het college, en zo rekent de student.
#   - SPSS: dezelfde formule, maar met een aftrek voor knopen onder de wortel.
#     Daardoor drukt SPSS een iets kleinere Standard Error en een iets grotere
#     |Z| dan de hand. Bij data zonder knopen zijn de twee gelijk.
#
# Getoetst tegen echte SPSS-uitvoer (18-11-2026): de twee schermen in college 2
# van 2026-27. Dia 44 (Mann-Whitney, N = 6, data op dia 37): Standard Error
# 2.258, Standardized Test Statistic -1.771, Asymptotic Sig. .077. Dia 65
# (Signed Rank, N = 8, data op dia 57): Test Statistic 4.000, Standard Error
# 7.106, Standardized Test Statistic -1.970, Asymptotic Sig. .049. Deze
# rekenwijze geeft exact die getallen terug; de toets staat onderaan en draait
# bij elk laden.
#
# Wat NIET is nagemeten in SPSS zelf:
#   - de regel die SPSS in de tabel Test Statistics van de legacy-procedure
#     gebruikt om "Wilcoxon W" te kiezen als de kleinste groep níét de kleinste
#     rangsom heeft. Elke dataset in dit thema is zo gekozen dat die twee
#     samenvallen (stopifnot in spss_rangsom()).
#   - de rij Exact Sig. in de legacy-uitvoer: weggelaten, de tabel zegt het.
#   - het aantal decimalen per kolom: Mean Rank en Sum of Ranks twee, Z drie,
#     Sig. drie, zoals in Bens bijles van 2025 (Les 8, deel 3) te zien was.

# ---- Tabel A, zoals de tabel hem drukt --------------------------------------
# Tabel A (Moore, McCabe & Craig) geeft het stuk LINKS van z, op vier decimalen.
tabA <- function(z) round(pnorm(z), 4)
# De staart voorbij |z|, zoals je hem uit Tabel A haalt: bij een negatieve z
# staat hij er meteen, bij een positieve z is het 1 min de tabelwaarde.
staart <- function(z) tabA(-abs(round(z, 2)))
# Een stukje van Tabel A: de rij van z (eerste decimaal), alle tien kolommen,
# met de cel van z vet. Geeft markdown terug.
tabelA_rij <- function(z) {
  z2 <- round(z, 2)
  rij <- floor(abs(z2) * 10 + 1e-9) / 10 * sign(z2)
  if (z2 == 0) rij <- 0
  kols <- seq(0, 0.09, by = 0.01)
  zs <- if (z2 < 0) rij - kols else rij + kols
  cel <- round(abs(z2 - rij) * 100)
  waarden <- formatC(tabA(zs), format = "f", digits = 4)
  waarden <- sub("^0", "", waarden)
  waarden[cel + 1] <- paste0("**", waarden[cel + 1], "**")
  kop <- c("$z$", sub("^0", "", formatC(kols, format = "f", digits = 2)))
  rij_tekst <- sub("^-", MIN, formatC(rij, format = "f", digits = 1))   # echt minteken
  paste0(
    "| ", paste(kop, collapse = " | "), " |\n",
    "|", paste(rep(":-:", length(kop)), collapse = "|"), "|\n",
    "| ", rij_tekst, " | ", paste(waarden, collapse = " | "), " |\n"
  )
}
# Zakt als |Z| zo dicht bij een afrondgrens ligt dat de tweede decimaal kan
# wisselen -- dan geeft Tabel A een andere cel dan de uitvoer suggereert.
z_veilig <- function(z) {
  stopifnot("Z ligt op een afrondgrens" = abs(z * 100 - round(z * 100)) < 0.35)
  invisible(TRUE)
}

# ---- rekenen ----------------------------------------------------------------
# Knopencorrectie: som over alle groepjes gelijke waarden van t^3 - t.
knopen_som <- function(x) { t <- table(x); sum(t^3 - t) }

# Rangtekentoets: verschil = eerste min tweede (zoals het hoofdstuk rekent:
# vóór min na). Nulverschillen gaan eruit; rangen van |d| met gemiddelde rang
# bij knopen; W+ en W- allebei (Bens controle).
rangteken <- function(x1, x2) {
  stopifnot(length(x1) == length(x2))
  d <- x1 - x2
  nul <- d == 0
  dd <- d[!nul]; n <- length(dd)
  rk <- rank(abs(dd))
  wp <- sum(rk[dd > 0]); wm <- sum(rk[dd < 0])
  mu <- n * (n + 1) / 4
  sg <- sqrt(n * (n + 1) * (2 * n + 1) / 24)
  sg_tc <- sqrt(n * (n + 1) * (2 * n + 1) / 24 - knopen_som(abs(dd)) / 48)
  z <- (wp - mu) / sg
  z_tc <- (wp - mu) / sg_tc
  list(
    d = d, n_paren = length(d), n_nul = sum(nul), n = n,
    dd = dd, rk = rk, wp = wp, wm = wm, mu = mu, sg = sg, sg_tc = sg_tc,
    z = z, z_tc = z_tc,
    p1 = staart(z), p2 = 2 * staart(z),                 # via Tabel A, zoals met de hand
    p2_exact = 2 * pnorm(-abs(z)), p2_tc = 2 * pnorm(-abs(z_tc)),
    md1 = median(x1), md2 = median(x2),
    # zoals SPSS het ziet: tweede min eerste
    pos_N = sum(dd < 0), neg_N = sum(dd > 0),
    pos_som = wm, neg_som = wp,
    pos_gem = if (any(dd < 0)) mean(rk[dd < 0]) else NA,
    neg_gem = if (any(dd > 0)) mean(rk[dd > 0]) else NA
  )
}

# Rangsomtoets: W is de rangsom van groep 1 (Eq. 45); alle scores samen
# gerangschikt, gemiddelde rang bij knopen.
rangsom <- function(y1, y2) {
  n1 <- length(y1); n2 <- length(y2); N <- n1 + n2
  rk <- rank(c(y1, y2))
  w1 <- sum(rk[seq_len(n1)]); w2 <- sum(rk[-seq_len(n1)])
  mu <- n1 * (N + 1) / 2
  sg <- sqrt(n1 * n2 * (N + 1) / 12)
  sg_tc <- sqrt(n1 * n2 / 12 * ((N + 1) - knopen_som(c(y1, y2)) / (N * (N - 1))))
  z <- (w1 - mu) / sg
  z_tc <- (w1 - mu) / sg_tc
  u1 <- w1 - n1 * (n1 + 1) / 2; u2 <- w2 - n2 * (n2 + 1) / 2
  list(
    n1 = n1, n2 = n2, N = N, rk = rk, rk1 = rk[seq_len(n1)], rk2 = rk[-seq_len(n1)],
    w1 = w1, w2 = w2, gem1 = w1 / n1, gem2 = w2 / n2,
    mu = mu, sg = sg, sg_tc = sg_tc, z = z, z_tc = z_tc,
    p1 = staart(z), p2 = 2 * staart(z),
    p2_exact = 2 * pnorm(-abs(z)), p2_tc = 2 * pnorm(-abs(z_tc)),
    u1 = u1, u2 = u2, u = min(u1, u2),
    md1 = median(y1), md2 = median(y2)
  )
}

# ---- SPSS-uitvoer nabouwen --------------------------------------------------
# De legacy-procedure (Analyze > Nonparametric Tests > Legacy Dialogs). Dat is
# de weg die Bens bijles van 2025 laat zien; de Ranks-tabel daarvan is het
# handwerk cel voor cel. Z komt uit de kleinste rangsom en is daarom nooit
# positief; de knopencorrectie zit in de noemer.
spss_rangteken_legacy <- function(r, naam1, naam2) {
  paar <- paste(naam2, "-", naam1)   # SPSS trekt de eerste van de tweede af
  klein_pos <- r$pos_som <= r$neg_som
  z_spss <- (min(r$pos_som, r$neg_som) - r$mu) / r$sg_tc
  p_spss <- 2 * pnorm(-abs(z_spss))
  list(
    ranks = spss_tabel(
      "Ranks",
      list(list(kc(""), kc(""), kc("N"), kc("Mean Rank"), kc("Sum of Ranks"))),
      list(c(paar, "Negative Ranks", paste0(r$neg_N, "ᵃ"), spss_getal(r$neg_gem, 2), spss_getal(r$neg_som, 2)),
           c("", "Positive Ranks", paste0(r$pos_N, "ᵇ"), spss_getal(r$pos_gem, 2), spss_getal(r$pos_som, 2)),
           c("", "Ties", paste0(r$n_nul, "ᶜ"), "", ""),
           c("", "Total", r$n_paren, "", "")),
      voetnoten = c(paste0("a. ", naam2, " < ", naam1), paste0("b. ", naam2, " > ", naam1),
                    paste0("c. ", naam2, " = ", naam1)),
      links = 2),
    test = spss_tabel(
      "Test Statisticsᵃ",
      list(list(kc(""), kc(paar))),
      list(c("Z", paste0(spss_getal(z_spss, 3), "ᵇ")),
           c("Asymp. Sig. (2-tailed)", spss_p(p_spss))),
      voetnoten = c("a. Wilcoxon Signed Ranks Test",
                    if (klein_pos) "b. Based on positive ranks." else "b. Based on negative ranks."),
      links = 1),
    z = z_spss, p = p_spss, klein_pos = klein_pos
  )
}

# De nieuwere procedure (Analyze > Nonparametric Tests > Related Samples), het
# scherm dat college 2 toont (dia 65). Test Statistic = de som van de
# positieve rangen van (tweede min eerste); het teken van de Z blijft staan.
spss_rangteken_nieuw <- function(r) {
  z_spss <- (r$pos_som - r$mu) / r$sg_tc
  p_spss <- 2 * pnorm(-abs(z_spss))
  list(
    tabel = spss_tabel(
      "Related-Samples Wilcoxon Signed Rank Test Summary",
      list(),
      list(c("Total N", r$n_paren),
           c("Test Statistic", spss_getal(r$pos_som, 3)),
           c("Standard Error", spss_getal(r$sg_tc, 3)),
           c("Standardized Test Statistic", spss_getal(z_spss, 3)),
           c("Asymptotic Sig.(2-sided test)", spss_p(p_spss))),
      links = 1),
    z = z_spss, p = p_spss
  )
}

# Legacy Mann-Whitney: Ranks (per groep N, Mean Rank, Sum of Ranks) en Test
# Statistics (U, W, Z, Asymp. Sig.). U is de kleinste van U1 en U2; W is de
# rangsom van de kleinste groep, die in dit thema ook de kleinste rangsom
# heeft (stopifnot). De rij Exact Sig. is weggelaten.
spss_rangsom_legacy <- function(r, uitkomst, groepnaam, groep1, groep2) {
  stopifnot("kleinste groep moet ook de kleinste rangsom hebben (anders is W dubbelzinnig)" =
              (r$n1 <= r$n2 && r$w1 <= r$w2) || (r$n2 < r$n1 && r$w2 < r$w1))
  w_spss <- if (r$n1 <= r$n2) r$w1 else r$w2
  z_spss <- (r$u - r$n1 * r$n2 / 2) / r$sg_tc
  p_spss <- 2 * pnorm(-abs(z_spss))
  list(
    ranks = spss_tabel(
      "Ranks",
      list(list(kc(""), kc(groepnaam), kc("N"), kc("Mean Rank"), kc("Sum of Ranks"))),
      list(c(uitkomst, groep1, r$n1, spss_getal(r$gem1, 2), spss_getal(r$w1, 2)),
           c("", groep2, r$n2, spss_getal(r$gem2, 2), spss_getal(r$w2, 2)),
           c("", "Total", r$N, "", "")),
      links = 2),
    test = spss_tabel(
      "Test Statisticsᵃ",
      list(list(kc(""), kc(uitkomst))),
      list(c("Mann-Whitney U", spss_getal(r$u, 3)),
           c("Wilcoxon W", spss_getal(w_spss, 3)),
           c("Z", spss_getal(z_spss, 3)),
           c("Asymp. Sig. (2-tailed)", spss_p(p_spss))),
      voetnoten = c(paste0("a. Grouping Variable: ", groepnaam),
                    "(De rij Exact Sig. is hier weggelaten.)"),
      links = 1),
    w = w_spss, z = z_spss, p = p_spss
  )
}

# ---- toets tegen echte SPSS-uitvoer (college 2, 2026-27) --------------------
local({
  # dia 37/44: wel OP1 gevolgd .70 .80 .85, niet .30 .50 .70
  r <- rangsom(c(.70, .80, .85), c(.30, .50, .70))
  stopifnot(
    "W van de hand (dia 38) wijkt af" = r$w1 == 14.5 && r$w2 == 6.5,
    "mu_W (dia 40) wijkt af" = r$mu == 10.5,
    "sigma_W (dia 40) wijkt af" = spss_getal(r$sg, 2) == "2.29",
    "Z van de hand (dia 40) wijkt af" = spss_getal(r$z, 2) == "1.75",
    "Standard Error wijkt af van SPSS (dia 44)" = spss_getal(r$sg_tc, 3) == "2.258",
    "Standardized Test Statistic wijkt af van SPSS (dia 44)" =
      spss_getal((r$u2 - r$n1 * r$n2 / 2) / r$sg_tc, 3) == "-1.771",
    "Asymptotic Sig. wijkt af van SPSS (dia 44)" = spss_p(2 * pnorm(-1.7713)) == ".077",
    "Mann-Whitney U wijkt af van SPSS (dia 44)" = spss_getal(r$u, 3) == ".500"
  )
  # dia 57/65: voormeting 85 70 40 65 80 75 55 20, nameting 75 50 50 40 20 65 40 25
  s <- rangteken(c(85, 70, 40, 65, 80, 75, 55, 20), c(75, 50, 50, 40, 20, 65, 40, 25))
  stopifnot(
    "mu_W+ (dia 61) wijkt af" = s$mu == 18,
    "sigma_W+ (dia 61) wijkt af" = spss_getal(s$sg, 2) == "7.14",
    "som van de positieve rangen van na - voor (dia 59/65) wijkt af" = s$pos_som == 4,
    "Standard Error wijkt af van SPSS (dia 65)" = spss_getal(s$sg_tc, 3) == "7.106",
    "Standardized Test Statistic wijkt af van SPSS (dia 65)" =
      spss_getal((s$pos_som - s$mu) / s$sg_tc, 3) == "-1.970",
    "Asymptotic Sig. wijkt af van SPSS (dia 65)" = spss_p(2 * pnorm((s$pos_som - s$mu) / s$sg_tc)) == ".049",
    # en het handwerk van het college met voor - na: W+ = 32, Z = +1.96
    "W+ met voor - na wijkt af" = s$wp == 32 && spss_getal(s$z, 2) == "1.96"
  )
  # Tabel A: de twee aflezingen van het college
  stopifnot(staart(1.75) == .0401, staart(-1.96) == .0250)
})
