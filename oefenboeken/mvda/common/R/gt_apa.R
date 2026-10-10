# TIJDELIJKE DOORVERWIJZING -- niet meer de tabelhelper zelf.
#
# Tot 10-10-2026 stond hier een verouderde kopie van de KAAPA-tabelhelper (388
# regels). Die is vervangen door `kaapa.R`, de wegwijzer naar de ene canonieke
# helper; daar staat waarom.
#
# Dit bestand bestaat nog om één reden: thema 5 laadt het met
# `source("../_common/R/gt_apa.R")`, en thema 5 lag op 10-10 bij een andere
# zetter (`fix_mvda05`). Om niet in zijn bestand te schrijven verwijst deze naam
# door. Zodra dat werk binnen is: zet in thema 5 `kaapa.R` op die regel en
# gooi dit bestand weg. Alle andere thema's laden `kaapa.R` al rechtstreeks.
source(file.path("..", "_common", "R", "kaapa.R"), encoding = "UTF-8")
