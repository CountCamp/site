# Proefdruk-screenshots voor spoor plankvorm (11-8-2026).
# Als oefenmooi/schiet.R, maar met een breedte-kolom per regel.
# Gebruik: Rscript schiet.R <urls_bestand> <uitdir>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2)
regels <- read.delim(args[1], header = FALSE,
                     col.names = c("naam", "breed", "url"),
                     stringsAsFactors = FALSE)
dir.create(args[2], showWarnings = FALSE, recursive = TRUE)
library(chromote)
b <- ChromoteSession$new(width = 1440, height = 1000)
for (i in seq_len(nrow(regels))) {
  uit <- file.path(args[2], paste0(regels$naam[i], ".png"))
  w <- as.integer(regels$breed[i])
  b$Emulation$setDeviceMetricsOverride(width = w, height = 1000,
                                       deviceScaleFactor = 1, mobile = w < 700)
  b$Page$navigate(regels$url[i])
  Sys.sleep(3)  # fonts laten landen
  h <- b$Runtime$evaluate("document.documentElement.scrollHeight")$result$value
  h <- min(as.numeric(h), 12000)
  b$Emulation$setDeviceMetricsOverride(width = w, height = as.integer(h),
                                       deviceScaleFactor = 1, mobile = w < 700)
  Sys.sleep(1)
  b$screenshot(uit, cliprect = c(0, 0, w, h))
  cat("geschoten:", uit, h, "px hoog\n")
}
b$close()
