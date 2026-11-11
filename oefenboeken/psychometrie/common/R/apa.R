# apa(): een getal dat niet boven de 1 kan komen (een correlatie, een lading
# die een correlatie is -- ongeroteerd of varimax --, een alfa, een proportie)
# zoals APA het zet -- twee decimalen en geen nul voor de punt. Eén definitie
# voor het hele oefenboek.
#
# Waarom hier en niet per thema. Tot 28-10-2026 stond apa() los in thema 1, 2,
# 3 en 4 (en in de Engelse kopie van thema 1). Alleen thema 3 had de
# afrondstap hieronder: thema 1, 2 en 4 rondden met een kale sprintf(). Dezelfde
# fout bleef zo staan op de plekken waar hij toevallig niet zichtbaar was.
# Besluit C, 28-10-2026 (V057), onder Bens volmacht van die dag: één apa() in
# _common/R, met de afronding van thema 3, en elk thema laadt hem.
#
# Gebruik:  source("../_common/R/apa.R")   in de setup-chunk van een thema.
#
# Wat hier NIET in hoort: een getal dat wél boven de 1 kan komen, zoals een
# eigenwaarde, een score, een RMSEA, een r* na correctie voor attenuatie, of een
# patroonlading (oblimin, een regressiegewicht) en wat daaruit volgt. Die houden
# hun nul. Thema 3 heeft daarvoor score() en rster(), thema 4 lam() en patroon()
# (sinds 28-10-2026, P2-6).

# rond_half_van_nul_af(): afronden zoals de conventie het wil, ook als de
# binaire weergave een haartje afwijkt. sprintf() rondt op wat er in het
# geheugen staat, en dat is voor een exacte helft niet altijd die helft.
# Gemeten 21-9-2026: PPV bij de dassen is 29/40 = exact .725, maar als double
# 0.72499999999999998, en `sprintf("%.2f", 29/40)` geeft dus `.72` waar `.73`
# hoort. De 1e-8 verandert alleen iets voor waarden die op een haartje na een
# exacte helft zijn; .7249 blijft gewoon naar beneden gaan. Getoetst, mét
# bijtproef, in 03_validity/_proef_afronden.R.
rond_half_van_nul_af <- function(x, d = 2) {
  f <- 10^d
  sign(x) * floor(abs(x) * f + 0.5 + 1e-8) / f
}

apa <- function(x, d = 2) {
  sub("^(-?)0[.]", "\\1.",
      sprintf(paste0("%.", d, "f"), rond_half_van_nul_af(x, d)))
}

# tussen(): een tussenuitkomst van een berekening, MET de nul voor de punt. Het
# besluit van 10-9-2026 (thema 2, de standaardmeetfout; _BESLUITEN.md): "een
# gerapporteerde statistiek die niet boven 1 kan krijgt een kale punt (α, r, p);
# een tussenuitkomst van een berekening krijgt een voorloopnul." Dus in
# h² = .72² + (−.35)² = 0.5184 + 0.1225 = .6409 gaan de twee kwadraten door
# tussen() en de communaliteit aan het eind door apa(). Staat hier sinds
# 28-10-2026 (P3-2, P3-4): thema 4 en thema 1 gebruiken hem, en score() in
# thema 3, die precies hetzelfde deed, roept hem nu aan.
tussen <- function(x, d = 2) {
  sprintf(paste0("%.", d, "f"), rond_half_van_nul_af(x, d))
}

# ongeveer(): "=" als het getal op d decimalen precies uitkomt (68/100 = .68),
# anders "\approx" (68/86 is .7907...). Dan staat er geen golfje voor een getal
# dat exact is, en geen "=" voor een getal dat is afgerond. x mag ook meer
# getallen tegelijk zijn: "=" alleen als ze allemaal exact zijn (een stap die een
# teller én een noemer invult). Geef d mee zoals het getal NA het teken gedrukt
# wordt: de vraag is of de lezer, die de som natikt, precies dat getal krijgt
# (TAALGIDS, "Een som die je vóórdoet, moet uitkomen").
#
# Stond tot 28-10-2026 alleen in thema 3 (sinds 11-10-2026). Verhuisd naar hier
# bij P3-2, toen thema 4 hem ook nodig had: twee kopieën van één regel is de
# faalklasse die V057 voor apa() repareerde.
ongeveer <- function(x, d = 2) if (all(abs(x - round(x, d)) < 1e-9)) "=" else "\\approx"
