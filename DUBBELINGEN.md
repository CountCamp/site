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
| **kopie 5** | `countcamp_site/manuscript/h3_grabbel.html` — waar hoofdstuk 3 naartoe linkt |
| **handeling** | bron wijzigen → `python3 countcamp_site/_tools/bouw_speelkist.py` → `python3 countcamp_lab/boek/04_speeltjes/_proef_kopieen.py` → `rm -rf _site && quarto render --to html` → committen en pushen → `curl` op de live-URL |

Het script doet **alle vijf de bestemmingen** in één keer, inclusief de losse
adressen hieronder en de drie broertjes-mappen. Het controleert per bestand of de
teller er nog in zit en meldt wat er in een doelmap staat zonder bron. Ververs je
er één met de hand, dan lopen de andere vier stil uit de pas — dat is op 9-8-2026
bijna gebeurd met de tabellen.

**Wat 10-8-2026 leerde: kopie 5 stond er niet in.** `manuscript/h3.html` linkt met
`<a href="h3_grabbel.html">` naar zijn eigen kopie van de grabbelton, en die kopie
kende het bouwscript niet. Hij liep dus stil achter — 25006 bytes tegen 25990 in
de bron. Wie in het boek op *"Open de grabbelton"* klikte, kreeg een oudere
grabbelton dan wie hem uit de speelkist pakte. Geen 404, geen klacht, geen alarm:
precies de fout die een register moet vangen en die dit register miste omdat de
bestemming er niet in stond. Nu wél, en `_proef_kopieen.py` leest alle
vierendertig kopieën terug en vergelijkt ze teken voor teken met de bron.

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

## 3b. De weg terug naar het hoofdstuk

| | |
|---|---|
| **bron** | de voet van elk speeltje: `<p class="foot">De regressieve ruggengraat · <a>Hoofdstuk N — titel</a> · …` |
| **gezet door** | `countcamp_lab/boek/04_speeltjes/_zet_hoofdstukvoeten.py` (kaart van speeltje → hoofdstuk staat bovenin dat script) |
| **handeling** | hernummert of hertitelt het boek → script opnieuw draaien → `bouw_speelkist.py` → publiceren |

Het script **tikt de hoofdstuktitels niet over**: het leest ze uit
`manuscript/hN.html` (`<title>`). Een volgende rotatie hoeft hier dus niet nog
een keer met de hand te landen — alleen het script opnieuw draaien.

De link is **absoluut** (`https://countcamp.org/manuscript/hN.html`). Dat moet
wel: hetzelfde bestand staat op vijf dieptes tegelijk, en één relatief pad kan
daar niet op alle vijf kloppen.

`s2_schud_tabel.html` krijgt bewust **geen** link: het hoort bij schil-eenheid S2
(kruistabel en χ²) en die staat niet in het boek. Liever geen link dan een
verzonnen link.

De **W-nummers** in diezelfde voet zijn iets anders en roteren niet mee met het
boek — zie `oefenboeken/broertjes/OPDRACHT_MAP.md`.

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


## 8. De oefenboek-beschrijvingen staan op twee bladzijden

| | |
|---|---|
| **bron** | `oefenboeken/index.qmd` — de volledige plank: R, JASP, SPSS, GGZ-VS, OZP 1, MVDA, JASP-handleiding |
| **kopie 1** | `manuscript/index.qmd` — onderaan de boekpagina, **alleen de drie broertjes** (R, JASP, SPSS) |
| **bewaakt door** | `python3 _tools/vergelijk_broertjes.py` (ná een render) — leest de drie alinea's uit beide gerenderde bladzijden; exit 1 bij verschil, exit 2 als hij ze niet kán vinden |

Ben, 10-8-2026: *"de broertjes kunnen gewoon blijven, dan is het overzichtelijk
genoeg en wordt het niet te veel op een pagina."* Bewuste keuze: wie onderaan het
boek is beland moet meteen zien wáár hij verder kan, zonder eerst een tussenpagina.

**Van vier naar drie (11-8-2026).** Het GGZ-VS/JASP-werkboek is van de boekpagina
áf en staat voortaan op **één** plek: de oefenboeken-bladzij. Reden: de broertjes
zijn de werkarm van dít boek — dezelfde hoofdstukken, dezelfde volgorde, dezelfde
nummers. Het GGZ-VS-werkboek doet iets anders (je leest en beoordeelt andermans
analyse; dat hoort bij een opleiding). Praktisch scheelt het ook het meeste: die
beschrijving was de langste van de vier en dus de tekst die het makkelijkst uit de
pas loopt. Er is nu **drie** in plaats van vier om synchroon te houden, en van de
GGZ-VS-tekst bestaat maar één exemplaar — die kan dus niet meer uit de pas lopen.
De boekpagina wijst voor de rest in één regel naar de oefenboeken-bladzij.

**Waar het misgaat.** Op 10-8 waren de twee kopieën al uit elkaar gelopen — de
boekpagina zei *"een oefenboek-schil"* waar de andere *"een oefenboek"* zei, en
*"in drie regels"* tegen *"in een paar regels"*. Toen gelijkgetrokken, maar alleen
per zinsnede: de R- en JASP-beschrijving op de boekpagina waren nog steeds
kortere, eigen samenvattingen. Sinds 11-8 zijn het **letterlijk** dezelfde drie
alinea's, en dat is nu ook te meten in plaats van te geloven — draai
`_tools/vergelijk_broertjes.py` na een render. **Verandert er iets aan een
oefenboek-beschrijving, verander het op béíde bladzijden.**

De uitweg als dit blijft schuiven: één bron maken en de tegels genereren, zoals
de sectie-overzichten uit `genereer_secties.py` komen. Nu niet gedaan omdat drie
tegels dat nog niet waard zijn — en omdat de vergelijker het stil houden nu
onmogelijk maakt.

## 9. De vorm van de boekenplank

| | |
|---|---|
| **bron** | `oefenboeken/vorm.js` (`VORM_STANDAARD`) — één woord, `"rug"` of `"kaart"` |
| **gebruikt door** | `oefenboeken/index.qmd`, `oefenboeken/broertjes/index.html`, en sinds 11-8 ook `manuscript/index.qmd` (voet van de boekpagina) |
| **opmaak** | `styles.css`, blok "De boekenplank in twee vormen" (`.cc-plank` / `.cc-boek` / `.cc-chip`), plus de eigen `<style>` in `broertjes/index.html` |

De drie bladzijden laden hetzelfde scriptje met een relatief pad
(`vorm.js`, `../vorm.js`, `../oefenboeken/vorm.js`). Wie de vorm omzet, zet 'm
dus voor alle drie tegelijk om. Bouw je een vierde lijst met boeken: gebruik
`.cc-plank`/`.cc-boek` en laad `vorm.js` — geen eigen variant, anders spreekt de
site weer twee talen. Zonder JavaScript geldt de rug-vorm.
