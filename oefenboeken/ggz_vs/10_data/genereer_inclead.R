# ============================================================
# genereer_inclead.R — synthetische data bij het blok
# "Cronbachs alpha / Cronbach's alpha"
# ------------------------------------------------------------
# VERHAAL ECHT, RIJEN VERZONNEN. Het design (een inclusief-
# leiderschapsvragenlijst, INCLEAD-achtig, 34 items op een
# 7-punts Likert, ingevuld door leidinggevenden die zichzelf
# beoordelen) komt uit de opzet van een echt hbo-onderzoek; de
# rijen zijn gegenereerd. Er is nooit client- of respondentdata
# aangeraakt — lesmateriaal doet dat niet (doelbinding, en
# geanonimiseerd is niet anoniem bij kleine N).
#
# De data reproduceren de getallen uit het voorbeeldfragment
# (afgerond zoals daar gerapporteerd):
#   N = 46 leidinggevenden, 34 items, schaal 1-7
#   Cronbachs alpha (34 items, totaal)      : rond .92
#   alpha subschaal "Erbij laten horen" (21): rond .95
#   alpha subschaal "Waardering" (7 items)  : rond .87
#   item 22 (participatieve besluitvorming) : gecorrigeerde
#                                             item-restcorrelatie
#                                             vrijwel nul
#
# Werkwijze: een algemene leiderschapsfactor stuurt de meeste
# items; item 22 hangt er los bij (ruis), en een handvol items
# meet zwak mee. Zo ontstaat een hoge totale alpha die een
# rammelend item verhult — precies de didactische pointe.
#
# Draaien:  Rscript genereer_inclead.R
# ============================================================
set.seed(2607)

N  <- 46
K  <- 34

# --- ladingen op de algemene factor per item -----------------
# Sterke kern (subschaal S1, items 1-21), een zwakkere subschaal
# (S3, items 24-30), en een paar losse/zwakke items. Item 22 is
# het dode item: lading 0, en wordt hieronder deterministisch
# orthogonaal aan de rest getrokken (zie item-22-blok).
lambda <- numeric(K)
lambda[1:21]  <- seq(0.90, 0.62, length.out = 21)   # S1, sterk
lambda[15]    <- 0.40                                # zwak (Mokken-unscaled)
lambda[17]    <- 0.42                                # zwak (Mokken-unscaled)
lambda[22]    <- 0.00                                # DOOD item (zie onder)
lambda[23]    <- 0.42                                # zwak
lambda[24:30] <- c(0.80, 0.76, 0.78, 0.72, 0.66, 0.70, 0.62)  # S3
lambda[31]    <- 0.40                                # zwak
lambda[32]    <- 0.42                                # zwak
lambda[33]    <- 0.40                                # zwak
lambda[34]    <- 0.52

# --- item-gemiddelden: leidinggevenden scoren zichzelf hoog ---
set.seed(2607)
mu <- runif(K, 5.2, 5.9)

# --- genereer op continue schaal, dan naar 7-punts Likert ----
g <- rnorm(N)                                   # algemene factor
maak_item <- function(lam, m) {
  resid_sd <- sqrt(max(1 - lam^2, 0.05))
  c_score  <- m + lam * g + rnorm(N, 0, resid_sd)
  pmin(pmax(round(c_score), 1), 7)              # clamp op 1..7
}
items <- mapply(maak_item, lambda, mu)          # N x K matrix
colnames(items) <- sprintf("item%02d", 1:K)

# --- item 22 deterministisch bijna-orthogonaal aan de rest ----
# We willen dat dit item het schoolvoorbeeld is: een gecorrigeerde
# item-restcorrelatie vrijwel nul, terwijl de totale alpha hoog
# blijft. Bij N=46 doet een lading-0 item dat niet vanzelf (ruis
# geeft toevallige correlatie). Daarom trekken we voor item 22 een
# reeks kandidaat-ruisvectoren en houden die met de correlatie het
# dichtst bij nul. Volledig reproduceerbaar (vaste kandidaat-seeds).
restsom <- rowSums(items[, -22, drop = FALSE])
beste <- NULL; beste_abs <- Inf
for (s in 1:500) {
  set.seed(s)
  kand <- pmin(pmax(round(mu[22] + rnorm(N, 0, 1)), 1), 7)
  r <- suppressWarnings(cor(kand, restsom))
  if (!is.na(r) && abs(r) < beste_abs) { beste_abs <- abs(r); beste <- kand }
}
items[, 22] <- beste

lead <- data.frame(
  id = sprintf("l%02d", 1:N),
  items,
  check.names = FALSE
)

write.csv(lead, "inclead_leiders.csv", row.names = FALSE, quote = FALSE)

# ============================================================
# controle — reken elk fragmentgetal na op deze rijen
# ============================================================
cronbach <- function(M) {
  k  <- ncol(M)
  vi <- sum(apply(M, 2, var))
  vt <- var(rowSums(M))
  (k / (k - 1)) * (1 - vi / vt)
}
item_rest <- function(M) {
  sapply(seq_len(ncol(M)), function(j)
    cor(M[, j], rowSums(M[, -j, drop = FALSE])))
}

M   <- as.matrix(items)
S1  <- M[, 1:21]
S3  <- M[, 24:30]

cat("\n== controle ==\n")
cat("N =", N, " items =", K, "\n")
cat("alpha totaal (34) :", round(cronbach(M),  3), "\n")
cat("alpha S1 (21)     :", round(cronbach(S1), 3), "\n")
cat("alpha S3 (7)      :", round(cronbach(S3), 3), "\n\n")

ir <- item_rest(M)
cat("gecorrigeerde item-restcorrelaties:\n")
print(round(setNames(ir, colnames(M)), 3))

cat("\nitem 22 item-rest :", round(ir[22], 3), "\n")
cat("laagste 5 items   :\n")
print(round(sort(ir)[1:5], 3))

sc <- rowMeans(M)                                # schaalscore = gemiddelde
cat("\nschaalscore (gemiddelde over 34 items):\n")
cat("M =", round(mean(sc), 2), " SD =", round(sd(sc), 2), "\n")
