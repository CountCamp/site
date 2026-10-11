# KAAPA ("Kick Ass APA") -- de tabelhuisstijl van Ben, de maker van dit
# oefenboek.
#
# Dit bestand is geen tabelhelper maar een wegwijzer ernaar. Het laadt
# gt_apa(), tab_footnote_apa() en de fmt_*-functies. Heb je de ZIP van de
# voorpagina uitgepakt, dan hoef je hier niets voor te doen.
#
# Het zoekt de helper op twee plekken, in deze volgorde:
#
#   1. De ene vaste helper op de computer waar dit oefenboek gemaakt wordt.
#      Alle CountCamp-oefenboeken gebruiken diezelfde helper; een verbetering
#      hoeft dan maar op één plek, en geen boek loopt achter. Bij jou bestaat
#      deze plek niet, en dat is goed.
#   2. `_common/R/gt_apa_uit_zip.R`: een kopie van diezelfde helper, die alleen
#      in de ZIP zit. Hij is gemaakt op hetzelfde moment als de website, dus het
#      is precies de helper waarmee de tabellen online gemaakt zijn. Deze plek
#      gebruik jij.
#
# Er is bewust geen derde plek om op terug te vallen: een losse kopie die
# niemand bijhoudt, veroudert zonder dat iemand het merkt. Is geen van beide
# er, dan stopt de render met een melding die zegt waar dit bestand gezocht
# heeft.
#
# Het pad naar plek 2 is relatief aan de map van het hoofdstuk: elk thema
# draait met `execute-dir: file` (zie _quarto.yml), net als de
# `source("../_common/R/kaapa.R")` waarmee het dit bestand laadt.
kaapa_helper  <- path.expand("~/Documents/Ben_OS/03_shared_assets/apa_helpers/gt_apa.R")
kaapa_zipkopie <- file.path("..", "_common", "R", "gt_apa_uit_zip.R")

if (file.exists(kaapa_helper)) {
  source(kaapa_helper, encoding = "UTF-8")
} else if (file.exists(kaapa_zipkopie)) {
  source(kaapa_zipkopie, encoding = "UTF-8")
} else {
  stop("De tabelhelper is niet gevonden. Hij hoort in de ZIP van de voorpagina ",
       "te zitten, hier:\n  ",
       # De map bestaat (dit bestand staat erin), het bestand niet: dus de map
       # absoluut maken en de naam erachter, anders blijft het pad relatief.
       file.path(normalizePath(dirname(kaapa_zipkopie), mustWork = FALSE),
                 basename(kaapa_zipkopie)),
       "\nPak de ZIP opnieuw uit, in een lege map. Helpt dat niet, dan ligt het ",
       "niet aan jou: mail dan naar vragen@countcamp.org.\n",
       "(De andere plek waar gezocht is, bestaat alleen op de computer waar dit ",
       "oefenboek gemaakt wordt: ", kaapa_helper, ")",
       call. = FALSE)
}
