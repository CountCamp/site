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
# Overgenomen van het Oefenboek Psychometrie, waar deze wegwijzer sinds
# 3-10-2026 staat (`_common/R/kaapa.R` daar). Hier gebeurde dat op 10-10-2026,
# op Bens akkoord op de reparaties uit het brugvoorstel van die dag (punt 20).
# Tot dan stond hier `_common/R/gt_apa.R`, een kopie van 388 regels, terwijl de
# canonieke helper er 485 had. Die kopie miste het echte minteken (U+2212), de
# voorloopnul die ook bij een negatief getal wegvalt (-.42 en niet -0.42),
# `table_label`, `palign()` en `gt_apa_compact_css()`, en de zwarte lijn boven
# een rijgroep. Een kopie verloopt zonder te zeggen dat hij verloopt.
#
# ÉÉN VERSCHIL MET PSYCHOMETRIE: DE BRON-ZIP. Dit oefenboek deelt zijn hele bron
# uit als ZIP (zie de voorpagina), en wie die uitpakt heeft geen
# ~/Documents/Ben_OS. Een kale wegwijzer zou daar elke tabel laten stoppen.
# Daarom legt `_tools/maak_bron_zip.sh` bij ELKE render een momentopname van de
# canonieke helper in de ZIP, als `_common/R/gt_apa_uit_zip.R`. Dat bestand
# staat alleen in de ZIP en nooit in de repo, en het wordt bij elke render
# opnieuw gemaakt -- dezelfde regel als voor de ZIP zelf: een kopie van wat er
# op dat moment is, geen tweede bron om bij te houden.
#
# De volgorde hieronder is dus: eerst de canonieke helper; alleen als die er
# niet is de momentopname uit de ZIP; is geen van beide er, dan STOPT de
# render, met een melding die zegt waar hij zocht. Stil terugvallen op iets
# anders is precies hoe de oude kopie ontstond.
#
# Het pad naar de momentopname is relatief aan de map van het hoofdstuk: elk
# thema draait met `execute-dir: file` (zie _quarto.yml), net als de
# `source("../_common/R/kaapa.R")` waarmee het dit bestand laadt.
kaapa_helper  <- path.expand("~/Documents/Ben_OS/03_shared_assets/apa_helpers/gt_apa.R")
kaapa_zipkopie <- file.path("..", "_common", "R", "gt_apa_uit_zip.R")

if (file.exists(kaapa_helper)) {
  source(kaapa_helper, encoding = "UTF-8")
} else if (file.exists(kaapa_zipkopie)) {
  source(kaapa_zipkopie, encoding = "UTF-8")
} else {
  stop("De KAAPA-tabelhelper is niet gevonden. Gezocht op twee plekken:\n  ",
       kaapa_helper, "\n  ", normalizePath(kaapa_zipkopie, mustWork = FALSE),
       "\nDe eerste is de canonieke helper (alleen op Bens machines); de tweede ",
       "zit in de bron-ZIP van de voorpagina. Dit oefenboek laadt geen andere kopie.",
       call. = FALSE)
}
