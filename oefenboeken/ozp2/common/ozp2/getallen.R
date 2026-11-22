# Getal-opmaak voor het oefenboek OZP 2 -- één plek in plaats van per thema.
#
# Dit boek rekent met de decimaalPUNT, niet met de komma van OZP 1: het
# OZP 2-college, de werkgroepen, het formuleblad en SPSS schrijven allemaal een
# punt, en de taalgids ook (20-7-2026). Zie ONTWERP.md, "Getallen".
#
#   nr(x, d)     getal met d decimalen, half naar boven: 4.2426 -> "4.24".
#                Een negatief getal krijgt een echt minteken (U+2212), geen
#                koppelteken (APA-lens, 18-11-2026: 19 regels met een
#                koppelteken tegen 4 met een minteken). SPSS-schermen houden
#                hun koppelteken: die lopen via spss_getal().
#   pw(x, d)     grootheid die niet boven 1 kan (r, een kans), zonder
#                voorloopnul: 0.0320 -> ".032", -0.42 -> "−.42"
#   pa(p)        p zoals APA hem rapporteert, met de huisregel (taalgids 9-8):
#                drie decimalen onder .100, twee erboven: .0038 -> ".004",
#                .2291 -> ".23", .0002 -> "< .001" (zonder "=").
#   pz(p)        hetzelfde mét het teken ervoor: "= .004", "= .23", "< .001"
#   kol(p)       een kolomkop of grens uit Tabel D zoals de tabel hem drukt:
#                minstens twee decimalen, geen nullen erachter: .005 -> ".005",
#                .0025 -> ".0025", .3 -> ".30", .05 -> ".05"
#   omhoog(x,d)  half naar boven afronden zoals met de hand (round() maakt van
#                104.935 binair 104.93; zie thema 8 van OZP 1)
#   route(...)   bewaakt een voorgedane som: rekent hem opnieuw met de
#                AFGEDRUKTE tussengetallen en eist hetzelfde afgedrukte
#                antwoord (APA-lens 18-11-2026: vijf sommen kwamen niet uit).

MIN <- "−"

omhoog <- function(x, d = 2) sign(x) * floor(abs(x) * 10^d + 0.5 + 1e-8) / 10^d

nr <- function(x, d = 2) {
  s <- formatC(omhoog(x, d), format = "f", digits = d)
  sub("^-", MIN, s)
}

pw <- function(x, d = 3) sub("^(−?)0[.]", "\\1.", nr(x, d))

pa <- function(p) if (p < .001) "< .001" else if (omhoog(p, 3) < .100) pw(p, 3) else pw(p, 2)

pz <- function(p) if (p < .001) "< .001" else paste("=", pa(p))

kol <- function(p) {
  vapply(p, function(q) {
    s <- sub("0+$", "", formatC(q, format = "f", digits = 4))
    if (nchar(sub("^.*[.]", "", s)) < 2) s <- formatC(q, format = "f", digits = 2)
    sub("^0", "", s)
  }, "", USE.NAMES = FALSE)
}

# route(antwoord_afgedrukt, som_met_afgedrukte_getallen, d): zakt als de som
# met de afgedrukte tussengetallen niet op het afgedrukte antwoord uitkomt.
route <- function(afgedrukt, opnieuw, d = 3, wat = "") {
  if (nr(opnieuw, d) != afgedrukt) {
    stop("route komt niet uit", if (nzchar(wat)) paste0(" (", wat, ")"), ": afgedrukt ",
         afgedrukt, ", met de afgedrukte tussengetallen ", nr(opnieuw, d), call. = FALSE)
  }
  invisible(TRUE)
}

# Zelftoets: zakt bij het laden als een van de helpers iets anders doet.
stopifnot(
  nr(4.242641) == "4.24",
  nr(104.935) == "104.94",          # half naar boven, niet binair omlaag
  nr(-1.8605, 3) == "−1.861",
  pw(0.0320) == ".032",
  pw(-0.42, 2) == "−.42",
  pa(0.0038) == ".004", pa(0.2291) == ".23", pa(0.0995) == ".10",
  pa(0.0794) == ".079", pz(0.0004) == "< .001",
  kol(.005) == ".005", kol(.0025) == ".0025", kol(.3) == ".30", kol(.05) == ".05",
  kol(.25) == ".25", kol(.001) == ".001"
)
