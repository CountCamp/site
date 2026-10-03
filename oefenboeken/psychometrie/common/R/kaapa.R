# KAAPA -- Bens tabelhuisstijl ("Kick Ass APA") -- voor dit oefenboek.
#
# Dit bestand is GEEN kopie van de helper maar een wegwijzer ernaar. Het laadt
# gt_apa(), tab_footnote_apa() en de fmt_*-zetters uit de ene canonieke bron:
#
#     ~/Documents/Ben_OS/03_shared_assets/apa_helpers/gt_apa.R
#
# (`03_shared_assets` is op broodje en op maccie een wegwijzer naar
# ~/Ben_OS_brain/shared_assets/, de map die de brein-sync tussen de twee
# machines gelijk houdt.)
#
# Waarom een wegwijzer en geen kopie. Tot 3-10-2026 stond hier
# `_common/R/gt_apa.R`, een kopie van 388 regels, terwijl de canonieke helper
# er 485 had. Die kopie miste vier maanden aan KAAPA-werk: het echte minteken
# (U+2212) en de voorloopnul die ook bij een negatief getal wegvalt (-.42 en
# niet -0.42), `table_label`, `palign()`, `gt_apa_compact_css()`. Niemand zag
# het, want een kopie verloopt zonder te zeggen dat hij verloopt. Ben, 3-10:
# "Waarom doen we eigenlijk onze tabellen niet in onze huisstijl?" Huisregel:
# canoniek eerst, en nooit een tweede set die stil uit elkaar gaat lopen.
#
# Ontbreekt de helper, dan STOPT de render, met een melding die zegt waar hij
# zocht. Stil terugvallen op iets anders is precies hoe de kopie ontstond.
#
# Een wachter houdt dit vast: `_toets_kaapa.R` (draait in _alle_wachters.sh)
# gaat af op een `kable(` in een thema, op een `source()` van een gt_apa.R
# die niet de canonieke is, en op een functie die na het laden van dit bestand
# uit een ander bestand blijkt te komen.
kaapa_helper <- path.expand("~/Documents/Ben_OS/03_shared_assets/apa_helpers/gt_apa.R")
if (!file.exists(kaapa_helper)) {
  stop("De canonieke KAAPA-helper staat niet waar dit oefenboek hem zoekt:\n  ",
       kaapa_helper, "\nDit oefenboek laadt geen kopie. Herstel de wegwijzer ",
       "~/Documents/Ben_OS/03_shared_assets of pas het pad in _common/R/kaapa.R aan.",
       call. = FALSE)
}
source(kaapa_helper, encoding = "UTF-8")
