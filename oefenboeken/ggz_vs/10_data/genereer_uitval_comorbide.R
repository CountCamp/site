# ============================================================
# genereer_uitval_comorbide.R — synthetische data bij het blok
# "De odds ratio"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design — uitval uit behandeling
# vergeleken tussen patiënten mét en zonder comorbide stoornis in
# middelengebruik — is een klassiek en echt onderzoeksthema in de
# GGZ; comorbide middelengebruik als voorspeller van dropout is
# veelvuldig onderzocht. De celaantallen zijn DIDACTISCH GEKOZEN
# (uitkomst gewoon genoeg om OR en RR zichtbaar uiteen te laten
# lopen: OR = 2.67 tegenover RR = 2.0) en het geciteerde artikel
# bestaat niet; dat staat ook zo in het blok. Er is nooit cliëntdata
# aangeraakt — lesmateriaal doet dat niet (doelbinding, en
# geanonimiseerd is niet anoniem bij kleine N).
#
# De data reproduceren EXACT de getallen uit het voorbeeldfragment:
#   met middelengebruik    : 32 uitval / 48 niet  (n =  80, 40.0%)
#   zonder middelengebruik : 24 uitval / 96 niet  (n = 120, 20.0%)
#   odds 32/48 = 0.667 en 24/96 = 0.25 · OR = 2.67 · RR = 2.0
#   95% BI [1.42, 5.02] (log-methode) · chi-kwadraat(1) = 9.52 · p = .002
#
# Werkwijze: er wordt niets getrokken en er is dus geen seed — bij
# een 2x2 liggen de vier celaantallen de rijen volledig vast. Alle
# toets- en effectgetallen worden onderaan uit de dataset zelf
# berekend, niet overgetikt.
#
# Draaien:  Rscript genereer_uitval_comorbide.R
# ============================================================

uitval_comorbide <- data.frame(
  id              = sprintf("p%03d", 1:200),
  middelengebruik = rep(c("ja", "nee"), c(80, 120)),
  uitval          = c(rep(c("ja", "nee"), c(32, 48)),   # met  middelengebruik
                      rep(c("ja", "nee"), c(24, 96)))   # zonder
)

write.csv(uitval_comorbide, "uitval_comorbide.csv",
          row.names = FALSE, quote = FALSE)

# ---- controle: komen de fragmentgetallen er echt uit? ----
tab <- table(uitval_comorbide$middelengebruik, uitval_comorbide$uitval)
tab <- tab[c("ja", "nee"), c("ja", "nee")]   # uitval-ja links, zoals JASP (alfabetisch)

cat("\n== controle ==\n")
print(tab)

p_ja  <- tab["ja",  "ja"] / sum(tab["ja",  ])   # kans op uitval mét middelengebruik
p_nee <- tab["nee", "ja"] / sum(tab["nee", ])   # kans op uitval zonder
o_ja  <- tab["ja",  "ja"] / tab["ja",  "nee"]   # odds mét
o_nee <- tab["nee", "ja"] / tab["nee", "nee"]   # odds zonder
or    <- o_ja / o_nee
rr    <- p_ja / p_nee

cat("kansen  :", round(p_ja, 3), "en", round(p_nee, 3), "\n")
cat("odds    :", round(o_ja, 3), "en", round(o_nee, 3), "\n")
cat("OR      :", round(or, 3), "  (omgedraaide rijen:", round(1 / or, 3), ")\n")
cat("RR      :", round(rr, 3), "\n")

# 95%-BI om de OR via de log-methode (Woolf)
se_ln <- sqrt(sum(1 / tab))
bi    <- exp(log(or) + c(-1, 1) * qnorm(.975) * se_ln)
cat("SE(ln OR):", round(se_ln, 4), "\n")
cat("95% BI  : [", paste(round(bi, 2), collapse = ", "), "]\n")

# toets: chi-kwadraat zonder continuiteitscorrectie (zoals JASP rapporteert)
ct <- chisq.test(tab, correct = FALSE)
cat("chi2(", ct$parameter, ") = ", round(ct$statistic, 3),
    "   p = ", format.pval(ct$p.value, digits = 2), "\n", sep = "")

# Wald-z op de log-odds-ratio, ter bevestiging
z <- log(or) / se_ln
cat("Wald-z  :", round(z, 2), "  p =",
    format.pval(2 * pnorm(-abs(z)), digits = 2), "\n")

# dezelfde OR uit het logistische model: de helling van de dummy
m <- glm(I(uitval == "ja") ~ I(middelengebruik == "ja"),
         family = binomial, data = uitval_comorbide)
cat("glm     : exp(b1) =", round(exp(coef(m)[2]), 3),
    "  (de groepsvergelijking als helling)\n")
