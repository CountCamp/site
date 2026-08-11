# Proefdruk-screenshots voor spoor oefenmooi (10-8-2026).
# Volle bladzij: eerst scrollHeight meten, dan viewport daarop zetten.
# Gebruik: Rscript schiet.R <urls_bestand> <uitdir>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2)
regels <- read.delim(args[1], header = FALSE, col.names = c("naam", "url"),
                     stringsAsFactors = FALSE)
dir.create(args[2], showWarnings = FALSE, recursive = TRUE)
library(chromote)
b <- ChromoteSession$new(width = 1440, height = 1000)
for (i in seq_len(nrow(regels))) {
  uit <- file.path(args[2], paste0(regels$naam[i], ".png"))
  b$Emulation$setDeviceMetricsOverride(width = 1440, height = 1000,
                                       deviceScaleFactor = 1, mobile = FALSE)
  b$Page$navigate(regels$url[i])
  Sys.sleep(3)  # fonts en webfonts laten landen
  h <- b$Runtime$evaluate("document.documentElement.scrollHeight")$result$value
  h <- min(as.numeric(h), 12000)
  b$Emulation$setDeviceMetricsOverride(width = 1440, height = as.integer(h),
                                       deviceScaleFactor = 1, mobile = FALSE)
  Sys.sleep(1)
  b$screenshot(uit, cliprect = c(0, 0, 1440, h))
  cat("geschoten:", uit, h, "px hoog\n")
}
b$close()
