# ============================================================
# getallen_register.R — welk getal uit de diamantjes staat waar
# ------------------------------------------------------------
# Elk getal dat uit `diamantjes.csv` volgt en in de tekst wordt
# geciteerd, krijgt hier een naam en wordt hier berekend. Nooit
# overtikken: wie een getal nodig heeft, haalt het hier.
#
# Het register wordt weggeschreven als getallen_register.tsv en is
# de invoer voor `boek/_tools/getallen_kaart.py`, die de hele
# tekst afzoekt en per getal laat zien wáár het terugkomt.
#
# Draaien:  Rscript getallen_register.R
# ============================================================

d <- read.csv("diamantjes.csv")

reg <- list()
zet <- function(naam, waarde, waarvoor)
  reg[[length(reg) + 1]] <<- data.frame(naam = naam, waarde = waarde, waarvoor = waarvoor)

# --- H1: beschrijvend ---
zet("M_karaat",  mean(d$karaat), "H1 gemiddelde karaat")
zet("SD_karaat", sd(d$karaat),   "H1 spreiding karaat")
zet("M_glans",   mean(d$glans),  "H1 gemiddelde glans")
zet("SD_glans",  sd(d$glans),    "H1 spreiding glans")

# --- H4: samenhang en de lijn ---
f1 <- lm(glans ~ karaat, d)
zet("r_karaat_glans", cor(d$karaat, d$glans),          "H4 correlatie")
zet("r2_enkelvoudig", summary(f1)$r.squared,           "H4 verklaarde variantie")
zet("b0_enkelvoudig", coef(f1)[1],                     "H4 intercept — het lege adres")
zet("b1_karaat",      coef(f1)[2],                     "H4 helling per karaat")
zet("p_helling",      summary(f1)$coefficients[2, 4],  "H4 p van de helling")

# --- H8: meer dan een voorspeller ---
f2 <- lm(glans ~ karaat + gladheid, d)
zet("b0_mra",       coef(f2)[1],            "H8 intercept met twee voorspellers")
zet("b_karaat_mra", coef(f2)[2],            "H8 karaat na correctie voor gladheid")
zet("b_gladheid",   coef(f2)[3],            "H8 helling gladheid")
zet("r2_mra",       summary(f2)$r.squared,  "H8 verklaarde variantie")

# --- H9: groepen ---
f3 <- lm(glans ~ D, d)
zet("b0_merk", coef(f3)[1], "H9 gemiddelde glans golfje")
zet("b_merk",  coef(f3)[2], "H9 verschil sterretje - golfje")

# --- H10: interactie ---
f4 <- lm(glans ~ gladheid * D, d)
zet("b_interactie", coef(f4)[4],                    "H10 interactie gladheid x merk")
zet("p_interactie", summary(f4)$coefficients[4, 4], "H10 p van de interactie")

# --- H12: logistisch ---
f5 <- glm(mooi ~ karaat, binomial(), d)
zet("b0_logit",   coef(f5)[1],        "H12 logit-intercept")
zet("b_logit",    coef(f5)[2],        "H12 logit-helling karaat")
zet("or_karaat",  exp(coef(f5)[2]),   "H12 odds ratio per karaat")

# --- de steentjes zelf ---
for (i in seq_len(nrow(d))) {
  zet(paste0("karaat_", d$naam[i]), d$karaat[i], paste("karaat van", d$naam[i]))
  zet(paste0("glans_",  d$naam[i]), d$glans[i],  paste("glans van",  d$naam[i]))
}

register <- do.call(rbind, reg)
register$waarde <- round(register$waarde, 4)
write.table(register, "getallen_register.tsv", sep = "\t", row.names = FALSE, quote = FALSE)

cat(sprintf("%-18s %10s   %s\n", "naam", "waarde", "waarvoor"))
for (i in seq_len(nrow(register)))
  cat(sprintf("%-18s %10.4f   %s\n", register$naam[i], register$waarde[i], register$waarvoor[i]))
cat(sprintf("\n%d getallen weggeschreven naar getallen_register.tsv\n", nrow(register)))
