# ============================================================
# genereer_diamantjes.R — de twaalf diamantjes uit het boek als
# databestand, zodat ze in R geladen kunnen worden.
# ------------------------------------------------------------
# GEEN synthetische data: dit ZIJN de getallen uit Boekie, letterlijk
# overgenomen uit de schetsen (H1 karaat/glans, H8 gladheid, H9 merk).
# Bron van waarheid blijft het boek; dit bestand is een kopie in
# csv-vorm, geen tweede werkelijkheid. Verandert het boek een getal,
# dan verandert het hier ook -- en nergens anders.
#
# Waarom dit bestaat (7-8-2026, voor de PUM-startweek): Ben legt uit
# met de diamantjes en laat studenten werken in het R-oefenboek. Zonder
# dit bestand lopen er twee datasets door de week -- zijn verhaal op het
# bord, en pinguins/Titanic op hun scherm. Met dit bestand kan elke
# analyse van de week op dezelfde twaalf steentjes.
#
# Wat er in zit, en waar het in het boek voor dient:
#   naam, karaat, glans   H1  gemiddelde, spreiding
#                         H4  correlatie, de lijn, residuen
#   gladheid              H8  meervoudige regressie, confounding
#                             (Kees: veel karaat, slecht geslepen)
#   merk (golfje/ster)    H9  dummy-codering, groepsverschil
#   mooi (0/1)            H12 logistische regressie, kruistabel
#   D, DxG                H10 moderatie (product van twee kolommen)
#
# Draaien:  Rscript genereer_diamantjes.R
# ============================================================

diamantjes <- data.frame(
  naam     = c("Anna","Bram","Cees","Dora","Else","Faas",
               "Geer","Hans","Ida","Joop","Kees","Leen"),
  # Karaat is op 9-8-2026 met 0,6 opgehoogd. Het gemiddelde was 1,00 en dat is
  # didactisch onhandig: centreren wordt dan aftrekken van 1, wat je niet ziet
  # gebeuren. Nu is M = 1,60 en wordt de ruwe intercept negatief -- een steen
  # van nul karaat zou negatieve glans hebben. Dat is geen adres waar niemand
  # woont, dat is een adres dat niet bestaat, en precies de reden om te
  # centreren. Een verschuiving verandert alleen de intercept: helling, r, R2,
  # p, SD en alle andere analyses blijven exact gelijk (nagerekend 9-8).
  karaat   = c(1.0, 1.1, 1.1, 1.3, 1.6, 1.6, 1.7, 1.8, 1.9, 1.9, 2.1, 2.1),
  glans    = c( 20,  30,  30,  30,  50,  70,  80,  60,  70,  80,  30,  50),
  gladheid = c(  1,   2,   3,   4,   6,   6,   8,   7,   7,   7,   2,   7),
  merk     = c("golfje","sterretje","golfje","golfje","golfje","sterretje",
               "sterretje","golfje","sterretje","sterretje","sterretje","golfje")
)
diamantjes$D    <- ifelse(diamantjes$merk == "sterretje", 1, 0)
diamantjes$DxG  <- diamantjes$D * diamantjes$gladheid
# mooi = ja/nee-uitkomst voor het logistische blok (glans boven de 50).
# Staat als kolom in het bestand zodat JASP en SPSS hem niet eerst hoeven te
# berekenen; het R-oefenboek laat juist zien hoe je hem zelf maakt.
diamantjes$mooi <- as.integer(diamantjes$glans > 50)

write.csv(diamantjes, "diamantjes.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — de getallen die in het boek staan, hier nagerekend
# ============================================================
cat("\n== beschrijvend (H1) ==\n")
cat(sprintf("n = %d\n", nrow(diamantjes)))
cat(sprintf("karaat : M = %.2f  SD = %.2f\n", mean(diamantjes$karaat), sd(diamantjes$karaat)))
cat(sprintf("glans  : M = %.2f  SD = %.2f\n", mean(diamantjes$glans),  sd(diamantjes$glans)))

cat("\n== samenhang en de lijn (H4) ==\n")
r <- cor(diamantjes$karaat, diamantjes$glans)
fit1 <- lm(glans ~ karaat, diamantjes)
cat(sprintf("r = %.3f   r2 = %.3f\n", r, r^2))
cat(sprintf("glans = %.1f + %.1f * karaat\n", coef(fit1)[1], coef(fit1)[2]))
cat(sprintf("p (helling) = %.3f\n", summary(fit1)$coefficients[2, 4]))

cat("\n== meer dan een voorspeller (H8) ==\n")
fit2 <- lm(glans ~ karaat + gladheid, diamantjes)
print(round(coef(summary(fit2)), 3))
cat(sprintf("R2 = %.3f (enkelvoudig was %.3f)\n", summary(fit2)$r.squared, summary(fit1)$r.squared))

cat("\n== groepen zijn ook getallen (H9) ==\n")
print(round(coef(summary(lm(glans ~ D, diamantjes))), 3))

cat("\n== verschil in verschil (H10) ==\n")
print(round(coef(summary(lm(glans ~ gladheid * D, diamantjes))), 3))
