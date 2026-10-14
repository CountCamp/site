# maand_nl(): de maand in het Nederlands, voor de versieregel onder elk thema.
#
# format(Sys.Date(), "%B") volgt de taal van de machine die rendert, en op
# broodje is dat Engels. Gemeten 11-10-2026 op de render van die dag: thema 1
# tot en met 5 droegen "Versie: October 2026", thema 6 en 7 "oktober 2026" --
# die twee hadden deze functie al, elk als eigen kopie (diagnose van 3-10-2026
# in de setup van thema 6). Hier staat hij één keer, zodat een nieuw thema hem
# niet opnieuw hoeft te verzinnen.
maand_nl <- function(d = Sys.Date()) paste(
  c("januari", "februari", "maart", "april", "mei", "juni", "juli", "augustus",
    "september", "oktober", "november", "december")[as.integer(format(d, "%m"))],
  format(d, "%Y"))
