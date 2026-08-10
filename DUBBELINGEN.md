# Wat op meer dan één plek staat

Afspraak van Ben, 9-8-2026: *"hou onze acties genoteerd, dus als we iets
veranderen, dat het bij beide of meer plekken mee verandert."*

Dit is die lijst. Alles hieronder bestaat **meer dan één keer**. Verander je er
één, dan is het werk pas af als de andere mee zijn. Elke regel noemt daarom niet
alleen de plekken maar ook de **handeling**.

Regel bij twijfel: de kolom *bron* is de waarheid. De rest zijn kopieën, en
kopieën repareer je nooit ter plekke — je verandert de bron en kopieert opnieuw.

---

## 1. De speeltjes

| | |
|---|---|
| **bron** | `countcamp_lab/boek/04_speeltjes/*.html` (twaalf stuks) |
| **kopie 1** | `countcamp_site/speeltjes/*.html` — de speelkist, met een terugknop naar `/speeltjes/` |
| **kopie 2–4** | `countcamp_site/oefenboeken/broertjes/{r,jasp,spss}/speeltjes/` — zeven per oefenboek, aangeroepen vanuit de hoofdstukken |
| **handeling** | bron wijzigen → `python3 countcamp_site/_tools/bouw_speelkist.py` → `rm -rf _site && quarto render --to html` → committen en pushen → `curl` op de live-URL |

Het script doet **alle vier de bestemmingen** in één keer, inclusief de losse
adressen hieronder en de drie broertjes-mappen. Het controleert per bestand of de
teller er nog in zit en meldt wat er in een doelmap staat zonder bron. Ververs je
er één met de hand, dan lopen de andere drie stil uit de pas — dat is op 9-8-2026
bijna gebeurd met de tabellen.

## 2. Tabellen aflezen — Nederlands en Engels

| | |
|---|---|
| **bron** | `countcamp_lab/boek/04_speeltjes/tabellen_aflezen.html` (NL) en `tabellen_aflezen_en.html` (EN) |
| **live** | `/tabellen/index.html` en `/tables/index.html` |
| **beschreven in** | de tegel op de homepage (`index.qmd`) én de kaart in de speelkist (`speeltjes/index.qmd`) |
| **handeling** | `bouw_speelkist.py` kopieert beide; een inhoudelijke wijziging in de NL-versie hoort **altijd** ook in de EN-versie, en daarna loop je beide kaartteksten na |

De adressen `/tabellen/` en `/tables/` zijn eerder gedeeld met studenten en
verhuizen niet. De speelkist linkt ernaartoe in plaats van een eigen kopie te
maken.

## 3. Power

| | |
|---|---|
| **bron** | `countcamp_lab/boek/04_speeltjes/power_speeltje.html` |
| **live** | `/power/index.html` |
| **beschreven in** | de kaart in de speelkist |

## 4. De tekst van een speeltje staat op drie plekken

De titel en de omschrijving van elk speeltje leven in het speeltje zelf (`<h1>`
en de lede), in de kaart in de speelkist, en soms in een homepage-tegel.
Verander je de toon of de belofte van een speeltje, loop dan alle drie na.

## 5. GoatCounter

De teller zit **per bestand** in elk los speeltje (`<script data-goatcounter…>`
in de `<head>`) én centraal in `_quarto.yml` voor alle Quarto-pagina's. Een nieuw
speeltje zonder die regel telt niet mee; `bouw_speelkist.py` klaagt erover.

## 6. Huisstijl van de broertjes

`countcamp_lab/boek/oefenboeken/broertjes/_huisstijl/werkboek.css` is de bron;
`uitrol.sh` kopieert hem naar de drie oefenboeken en `uitrol.sh --check` meldt
drift (exit 1). Nooit een van de drie kopieën met de hand bijwerken.

## 7. De diamantjes — de dataset staat op zeven plekken

| | |
|---|---|
| **bron** | `countcamp_lab/boek/oefenboeken/broertjes/r/10_data/genereer_diamantjes.R` → `diamantjes.csv` |
| **kopie 1** | `boek/01_schetsen/_waarheid_getallen.R` — het waarheidsscript van het boek, met een eigen `data.frame` |
| **kopie 2–6** | `boek/02_figuren/_bouw_figuren.R`, `_bouw_decompositie.R`, `_bouw_h8_wegrekenen.R`, `_bouw_h11_muur.R`, `_bouw_h12.R` — elk met de karaatreeks hardgecodeerd |
| **en verder** | elk getal dat eruit volgt staat overgeschreven in Boekie (H1, H4, H5, H8, H9, H11, H12) en in de drie broertjes |
| **handeling** | bron wijzigen → alle kopieën na → `Rscript _waarheid_getallen.R` → de vijf figuur-scripts draaien → `python3 boek/_tools/getallen_kaart.py --oud <oud register>` tot hij leeg is → renderen en publiceren |

**Hoe je weet dat je klaar bent.** `getallen_register.R` rekent elk gepubliceerd
getal opnieuw uit; `getallen_kaart.py` zoekt ze op in de hele tekst en meldt met
`--oud` welke regels nog naar de vorige werkelijkheid wijzen. Zolang die lijst
niet leeg is, ben je niet klaar. Regels die terecht blijven staan — afwijkingen
als 0,5 en −0,6 veranderen niet bij een verschuiving — staan met reden in
`boek/_tools/getallen_uitzonderingen.tsv`, zodat het alarm niet blijft loeien.

**Wat 9-8-2026 leerde.** De karaatwaarden gingen met 0,6 omhoog. De tekst was
binnen een uur bij, maar de **figuren** logen nog: de centroïde stond op (1, 50)
hardgecodeerd en de regressielijn kwam uit `_waarheid.rds`, dat niemand opnieuw
had gedraaid. De grafiek zag er volkomen normaal uit — alleen lag de lijn er
naast. Sindsdien rekenen de figuren hun eigen gemiddelden uit in plaats van ze te
onthouden.


## De oefenboek-tegels staan op twee bladzijden

| | |
|---|---|
| **kopie 1** | `manuscript/index.qmd` — onderaan de boekpagina, vier tegels (R, JASP, SPSS, GGZ-VS) |
| **kopie 2** | `oefenboeken/index.qmd` — dezelfde vier, plus OZP 1, MVDA en de JASP-handleiding |
| **bewaakt door** | niets — met de hand |

Ben, 10-8-2026: *"de broertjes kunnen gewoon blijven, dan is het overzichtelijk
genoeg en wordt het niet te veel op een pagina."* Bewuste keuze: wie onderaan het
boek is beland moet meteen zien wáár hij verder kan, zonder eerst een tussenpagina.

**Waar het misgaat.** Op 10-8 waren de twee kopieën al uit elkaar gelopen — de
boekpagina zei *"een oefenboek-schil"* waar de andere *"een oefenboek"* zei, en
*"in drie regels"* tegen *"in een paar regels"*. Toen gelijkgetrokken. Dat is de
enige waarschuwing die dit register kan geven: **verandert er iets aan een
oefenboek-beschrijving, verander het op béíde bladzijden.**

De uitweg als dit blijft schuiven: één bron maken en de tegels genereren, zoals
de sectie-overzichten uit `genereer_secties.py` komen. Nu niet gedaan omdat vier
tegels dat nog niet waard zijn.
