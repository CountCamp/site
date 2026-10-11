# Doorverwijzing -- dit is niet de tabelhelper zelf.
#
# Thema 5 laadt de tabelhelper via dit bestand, met
# `source("../_common/R/gt_apa.R")`. Dit bestand stuurt door naar `kaapa.R`,
# dat de helper echt laadt; bovenin dat bestand staat hoe. De andere thema's
# laden `kaapa.R` rechtstreeks. Voor wat je in de tabellen ziet, maakt het
# geen verschil.
source(file.path("..", "_common", "R", "kaapa.R"), encoding = "UTF-8")
