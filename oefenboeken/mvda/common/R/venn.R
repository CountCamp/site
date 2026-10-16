# venn_plakjes() -- tekent een Venn-plaatje waarin één cirkel (alle variatie
# in Y) een plak krijgt van elk van een paar andere cirkels, met oppervlakken
# die kloppen. Thema 2 gebruikt hem voor eta-kwadraat.
#
# Dit bestand is geen tekenaar maar een wegwijzer ernaar, net als kaapa.R. Heb
# je de ZIP van de voorpagina uitgepakt, dan hoef je hier niets voor te doen.
#
# Het zoekt de tekenaar op twee plekken, in deze volgorde:
#
#   1. De ene vaste tekenaar in het Oefenboek Psychometrie, dat naast dit
#      oefenboek gemaakt wordt en hem ook gebruikt. Een verbetering hoeft dan
#      maar op één plek, en geen boek loopt achter. Bij jou bestaat deze plek
#      niet, en dat is goed.
#   2. `_common/R/venn_plakjes_uit_zip.R`: een kopie van diezelfde tekenaar, die
#      alleen in de ZIP zit. Hij is gemaakt op hetzelfde moment als de website,
#      dus het is precies de tekenaar waarmee de plaatjes online gemaakt zijn.
#      Deze plek gebruik jij.
#
# Er is bewust geen derde plek, om dezelfde reden als in kaapa.R: een losse
# kopie die niemand bijhoudt, veroudert zonder dat iemand het merkt. Is geen van
# beide er, dan stopt de render met een melding die zegt waar gezocht is.
#
# Beide paden zijn relatief aan de map van het hoofdstuk: elk thema draait met
# `execute-dir: file` (zie _quarto.yml).
venn_helper   <- file.path("..", "..", "..", "Psychometrie", "2526_r_practicals",
                           "_common", "R", "venn_plakjes.R")
venn_zipkopie <- file.path("..", "_common", "R", "venn_plakjes_uit_zip.R")

if (file.exists(venn_helper)) {
  source(venn_helper, encoding = "UTF-8")
} else if (file.exists(venn_zipkopie)) {
  source(venn_zipkopie, encoding = "UTF-8")
} else {
  stop("De tekenaar van de Venn-plaatjes is niet gevonden. Hij hoort in de ZIP ",
       "van de voorpagina te zitten, hier:\n  ",
       file.path(normalizePath(dirname(venn_zipkopie), mustWork = FALSE),
                 basename(venn_zipkopie)),
       "\nPak de ZIP opnieuw uit, in een lege map. Helpt dat niet, dan ligt het ",
       "niet aan jou: mail dan naar vragen@countcamp.org.\n",
       "(De andere plek waar gezocht is, bestaat alleen op de computer waar dit ",
       "oefenboek gemaakt wordt: ",
       file.path(normalizePath(file.path("..", "..", ".."), mustWork = FALSE),
                 "Psychometrie", "2526_r_practicals", "_common", "R", "venn_plakjes.R"),
       ")", call. = FALSE)
}
