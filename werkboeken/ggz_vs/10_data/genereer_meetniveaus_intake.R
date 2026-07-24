# ============================================================
# genereer_meetniveaus_intake.R — synthetische data bij het blok
# "Meetniveaus / de uitkomstmaat" (W0)
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (een intake-registratie
# bij een ambulante GGZ-poli: per patient een handvol kenmerken die
# bewust op verschillende meetniveaus staan) is een plausibele
# klinische opzet. Deze dataset is NIET aan een echte studie geijkt —
# er is geen truth-anchor; de getallen zijn DIDACTISCH gekozen om de
# meetniveaus goed voelbaar te maken en zijn expliciet fictief. Er is
# nooit clientdata aangeraakt — lesmateriaal doet dat niet
# (doelbinding, en geanonimiseerd is niet anoniem bij kleine N).
#
# DOEL VAN HET BLOK: de lezer laten oefenen met "welk meetniveau
# heeft deze variabele?". Elke kolom is bewust een ander niveau:
#
#   id              : label (naamgeving, geen meetniveau)
#   geslacht        : NOMINAAL   (man / vrouw / anders)
#   diagnose        : NOMINAAL   (5 categorieen, geen ordening)
#   opleiding       : ORDINAAL   (vmbo < mbo < hbo < wo)
#   ernst_categorie : ORDINAAL   (licht < matig < ernstig)
#   leeftijd        : RATIO      (jaren, absoluut nulpunt)
#   aantal_sessies  : RATIO      (telling, absoluut nulpunt)
#   bdi_score       : INTERVAL-achtig (BDI-II somscore 0-63)
#
# Interne consistentie (realisme, geen toets): ernst_categorie is
# afgeleid van de BDI-II-band (0-19 licht, 20-28 matig, 29+ ernstig),
# zodat de ordinale label en de interval-score bij elkaar passen.
# Geen kernstatistiek nodig; wel realistische verdelingen.
#
# Draaien:  Rscript genereer_meetniveaus_intake.R
# ============================================================
set.seed(240724)

N <- 60

# --- NOMINAAL: geslacht (man/vrouw/anders), scheve verdeling zoals in de GGZ ---
geslacht <- sample(c("man", "vrouw", "anders"), N, replace = TRUE,
                   prob = c(0.38, 0.58, 0.04))

# --- NOMINAAL: diagnose (5 categorieen, geen ordening) ---
diagnose <- sample(
  c("depressie", "angststoornis", "PTSS", "persoonlijkheidsstoornis", "ADHD"),
  N, replace = TRUE, prob = c(0.34, 0.28, 0.14, 0.14, 0.10))

# --- ORDINAAL: opleiding (geordend, ongelijke afstanden) ---
opleiding <- sample(c("vmbo", "mbo", "hbo", "wo"), N, replace = TRUE,
                    prob = c(0.20, 0.40, 0.28, 0.12))

# --- RATIO: leeftijd (jaren) ---
leeftijd <- round(rnorm(N, mean = 38, sd = 12))
leeftijd <- pmin(pmax(leeftijd, 18), 74)

# --- RATIO: aantal_sessies tot nu toe (telling, veel lage waarden) ---
aantal_sessies <- rpois(N, lambda = 6)

# --- INTERVAL: BDI-II somscore 0-63 (hoger = ernstiger) ---
bdi_score <- round(rnorm(N, mean = 24, sd = 11))
bdi_score <- pmin(pmax(bdi_score, 0), 63)

# --- ORDINAAL afgeleid van BDI-II-band (interne consistentie) ---
ernst_categorie <- cut(bdi_score, breaks = c(-1, 19, 28, 63),
                       labels = c("licht", "matig", "ernstig"))

intake <- data.frame(
  id              = sprintf("i%03d", 1:N),
  geslacht        = geslacht,
  diagnose        = diagnose,
  opleiding       = opleiding,
  ernst_categorie = as.character(ernst_categorie),
  leeftijd        = leeftijd,
  aantal_sessies  = aantal_sessies,
  bdi_score       = bdi_score,
  stringsAsFactors = FALSE
)

write.csv(intake, "meetniveaus_intake.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — beschrijf elke kolom kort (verdelingen, geen toets)
# ============================================================
cat("\n== controle meetniveaus_intake ==\n")
cat(sprintf("N = %d rijen, %d kolommen\n\n", nrow(intake), ncol(intake)))

cat("geslacht (nominaal):\n");        print(table(intake$geslacht))
cat("\ndiagnose (nominaal):\n");      print(table(intake$diagnose))
cat("\nopleiding (ordinaal):\n")
print(table(factor(intake$opleiding, levels = c("vmbo","mbo","hbo","wo"))))
cat("\nernst_categorie (ordinaal):\n")
print(table(factor(intake$ernst_categorie, levels = c("licht","matig","ernstig"))))
cat(sprintf("\nleeftijd (ratio)       : M = %.1f  SD = %.1f  range %d-%d\n",
            mean(leeftijd), sd(leeftijd), min(leeftijd), max(leeftijd)))
cat(sprintf("aantal_sessies (ratio) : M = %.1f  mediaan = %g  range %d-%d\n",
            mean(aantal_sessies), median(aantal_sessies),
            min(aantal_sessies), max(aantal_sessies)))
cat(sprintf("bdi_score (interval)   : M = %.1f  SD = %.1f  range %d-%d\n",
            mean(bdi_score), sd(bdi_score), min(bdi_score), max(bdi_score)))
cat("\nkruis ernst_categorie x bdi-band (moet perfect diagonaal zijn):\n")
print(table(intake$ernst_categorie,
            cut(intake$bdi_score, c(-1,19,28,63), labels=c("licht","matig","ernstig"))))
