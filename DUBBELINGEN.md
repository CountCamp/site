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
| **handeling** | bron wijzigen → `python3 countcamp_site/_tools/bouw_speelkist.py` (doet kopie 1, controleert de teller) → de drie broertjes-mappen **met de hand** verversen → `rm -rf _site && quarto render --to html` → committen en pushen → `curl` op de live-URL |

**Nog niet geautomatiseerd:** de drie broertjes-kopieën. Zolang dat zo is, staat
hier het risico: een speeltje dat op de speelkist klopt en in het oefenboek nog
de oude versie is. Wie hier langskomt met tijd: breid `bouw_speelkist.py` uit.

## 2. Tabellen aflezen — Nederlands en Engels

| | |
|---|---|
| **bron** | `countcamp_lab/boek/04_speeltjes/tabellen_aflezen.html` (NL) en `tabellen_aflezen_en.html` (EN) |
| **live** | `/tabellen/index.html` en `/tables/index.html` |
| **beschreven in** | de tegel op de homepage (`index.qmd`) én de kaart in de speelkist (`speeltjes/index.qmd`) |
| **handeling** | een inhoudelijke wijziging in de NL-versie hoort **altijd** ook in de EN-versie; daarna beide kaartteksten nalopen |

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

## 7. De diamantjes

`countcamp_lab/boek/oefenboeken/broertjes/r/10_data/diamantjes.csv` wordt gemaakt
door `genereer_diamantjes.R` in dezelfde map, en de getallen eruit staan in de
uitleg van meerdere blokken én in Boekie. Verandert de dataset, dan verandert elk
getal dat eruit is overgeschreven. Herrekenen, niet bijwerken op het oog.
