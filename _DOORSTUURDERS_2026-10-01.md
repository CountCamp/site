# Doorstuurders voor dode adressen — 1 oktober 2026

Spoor `doorstuur`, tak `worktree-doorstuur`, stand `ac8ebda`. **Er is niets gepubliceerd en niets gepusht.** Elk getal hieronder is uitgerekend: uit `_tools/doorstuurders.tsv`, uit git, of uit een poort die voor dit verslag opnieuw gedraaid is. Die tabel is zelf afgeleid uit de gh-pages-geschiedenis (`f8a5885`) met `python3 _tools/doorstuurders.py --afleiden`. Dit verslag, de lokale bouw en de klikproef komen uit de scripts in `~/Documents/Ben_OS/_logs/doorstuur_2026-10-01_werk/` (op broodje).

## In één alinea

Van de 190 adressen die ooit live stonden en nu een 404 geven, krijgen er **181** een doorstuurder. Dat is een klein bestand op het oude adres dat de lezer meteen doorstuurt naar de bladzij waar dezelfde inhoud nu staat. **9** krijgen er bewust geen, met de reden erbij. De koppeling is gemaakt op inhoud, niet op nummer. De oude tekst uit de gh-pages-geschiedenis moet het meest lijken op het gekozen doel, van alle bladzijden in dat boek. Voor OZP 1 thema 3 en 4 (gewisseld op 19-9) is dat verschil groot: de oude bladzijden lijken voor 0,98 tot 1,00 op hun nieuwe doel, en voor 0,18 op de bladzij die nu hun oude nummer draagt.

| groep | doorstuurders |
|---|---:|
| broertjes (R, JASP, SPSS) | 75 |
| GGZ-VS | 27 |
| broertjes, de R-preview van 2-8 | 25 |
| OZP 1 | 16 |
| broertjes, de platte adressen van 24-7 | 16 |
| MVDA | 16 |
| Handleiding (bookdown, 2021) | 6 |
| **totaal** | **181** |

**Wat er nodig is voor één "ja":** de tak `worktree-doorstuur` in `main` halen en `naar_buiten.sh --productie` draaien. Er hoeft geen boek opnieuw gerenderd te worden. De doorstuurders zijn losse bestanden die de site onveranderd meeneemt, net als de acht onder `werkboeken/` sinds 7-8. **Haal de tak in zijn geheel binnen, niet alleen de doorstuurders.** Twee ervan staan ín `oefenboeken/ozp1/`, en zonder de aangepaste plankwacht eist die dan "Bijgewerkt 1 oktober" op het OZP 1-kaartje en stopt `--productie`. Dat is op deze tak gemeten vóór de aanpassing (afloop 1).

## OZP 1 — de reden voor vannacht

Woordoverlap is het aantal gedeelde woorden (vier letters of meer) gedeeld door alle woorden, oude tekst tegen doel. "Beste andere" is de bladzij in hetzelfde boek die daarna het meest lijkt.

| oud adres | stond live | oude titel | → nieuw adres | nieuwe titel | overlap | beste andere |
|---|---|---|---|---|---:|---|
| `oefenboeken/ozp1/03_normaalverdeling_z/03_normaalverdeling_z.html` | 7-8 t/m 19-9 | Thema 3 · Normaalverdeling & z-scores | `oefenboeken/ozp1/04_normaalverdeling_z/04_normaalverdeling_z.html` | Thema 4 · Normaalverdeling & z-scores | 0,99 | 07_steekproevenverdeling_ci.html 0,25 |
| `oefenboeken/ozp1/04_discrete_kansvariabelen/04_discrete_kansvariabelen.html` | 7-8 t/m 19-9 | Thema 4 · Discrete kansvariabelen | `oefenboeken/ozp1/03_discrete_kansvariabelen/03_discrete_kansvariabelen.html` | Thema 3 · Discrete kansvariabelen | 1,00 | 01_gemiddelde_spreiding.html 0,21 |
| `werkboeken/ozp1/00_fundament/00_fundament.html` | 30-5 t/m 7-8 | Deel 0 · Fundament | `oefenboeken/ozp1/00_fundament/00_fundament.html` | Deel 0 · Fundament | 1,00 | 14_analysekeuze.html 0,20 |
| `werkboeken/ozp1/01_gemiddelde_spreiding/01_gemiddelde_spreiding.html` | 30-5 t/m 7-8 | Thema 1 · Gemiddelde & spreiding | `oefenboeken/ozp1/01_gemiddelde_spreiding/01_gemiddelde_spreiding.html` | Thema 1 · Gemiddelde & spreiding | 0,95 | 06_regressie.html 0,24 |
| `werkboeken/ozp1/02_verdelingen_bekijken/02_verdelingen_bekijken.html` | 30-5 t/m 7-8 | Thema 2 · Verdelingen bekijken | `oefenboeken/ozp1/02_verdelingen_bekijken/02_verdelingen_bekijken.html` | Thema 2 · Verdelingen bekijken | 0,89 | 07_steekproevenverdeling_ci.html 0,23 |
| `werkboeken/ozp1/03_normaalverdeling_z/03_normaalverdeling_z.html` | 30-5 t/m 7-8 | Thema 3 · Normaalverdeling & z-scores | `oefenboeken/ozp1/04_normaalverdeling_z/04_normaalverdeling_z.html` | Thema 4 · Normaalverdeling & z-scores | 0,98 | 07_steekproevenverdeling_ci.html 0,25 |
| `werkboeken/ozp1/04_discrete_kansvariabelen/04_discrete_kansvariabelen.html` | 30-5 t/m 7-8 | Thema 4 · Discrete kansvariabelen | `oefenboeken/ozp1/03_discrete_kansvariabelen/03_discrete_kansvariabelen.html` | Thema 3 · Discrete kansvariabelen | 0,99 | 01_gemiddelde_spreiding.html 0,21 |
| `werkboeken/ozp1/05_correlatie/05_correlatie.html` | 30-5 t/m 7-8 | Thema 5 · Correlatie | `oefenboeken/ozp1/05_correlatie/05_correlatie.html` | Thema 5 · Correlatie | 0,83 | 06_regressie.html 0,27 |
| `werkboeken/ozp1/06_regressie/06_regressie.html` | 30-5 t/m 7-8 | Thema 6 · Regressie | `oefenboeken/ozp1/06_regressie/06_regressie.html` | Thema 6 · Regressie | 1,00 | 05_correlatie.html 0,27 |
| `werkboeken/ozp1/07_steekproevenverdeling_ci/07_steekproevenverdeling_ci.html` | 30-5 t/m 7-8 | Thema 7 · Steekproevenverdeling & betrouwbaarheidsinterval | `oefenboeken/ozp1/07_steekproevenverdeling_ci/07_steekproevenverdeling_ci.html` | Thema 7 · Steekproevenverdeling & betrouwbaarheidsinterval | 0,74 | 09_t_toets.html 0,26 |
| `werkboeken/ozp1/08_toetsgevoel_ztoets/08_toetsgevoel_ztoets.html` | 30-5 t/m 7-8 | Thema 8 · Toetsgevoel & z-toets | `oefenboeken/ozp1/08_toetsgevoel_ztoets/08_toetsgevoel_ztoets.html` | Thema 8 · Toetsgevoel & z-toets | 0,66 | 09_t_toets.html 0,29 |
| `werkboeken/ozp1/09_t_toets/09_t_toets.html` | 30-5 t/m 7-8 | Thema 9 · t-toets | `oefenboeken/ozp1/09_t_toets/09_t_toets.html` | Thema 9 · t-toets | 0,68 | 08_toetsgevoel_ztoets.html 0,28 |
| `werkboeken/ozp1/10_power/10_power.html` | 30-5 t/m 7-8 | Thema 10 · Power | `oefenboeken/ozp1/10_power/10_power.html` | Thema 10 · Power | 0,85 | 08_toetsgevoel_ztoets.html 0,25 |
| `werkboeken/ozp1/11_chi_kwadraat/11_chi_kwadraat.html` | 30-5 t/m 7-8 | Thema 11 · Chi-kwadraat & Simpson | `oefenboeken/ozp1/11_chi_kwadraat/11_chi_kwadraat.html` | Thema 11 · Chi-kwadraat & Simpson | 0,74 | 09_t_toets.html 0,25 |
| `werkboeken/ozp1/12_tabellen/12_tabellen.html` | 13-6 t/m 7-8 | Bijlage · Kansverdeling-tabellen | `oefenboeken/ozp1/12_tabellen/12_tabellen.html` | Bijlage · Kansverdeling-tabellen | 0,98 | 09_t_toets.html 0,06 |
| `werkboeken/ozp1/woordenlijst.html` | 10-7 t/m 7-8 | Woordenlijst | `oefenboeken/ozp1/woordenlijst.html` | Woordenlijst | 0,67 | 15_formuleblad.html 0,17 |

**De wissel, apart nagemeten.** Hoe had het uitgepakt als we op nummer hadden gekoppeld?

| oud adres | overlap met het gekozen doel | overlap met wat nu dat nummer draagt |
|---|---:|---:|
| `oefenboeken/ozp1/03_normaalverdeling_z/03_normaalverdeling_z.html` | 0,99 (`04_normaalverdeling_z.html`) | 0,18 (`03_discrete_kansvariabelen.html`) |
| `oefenboeken/ozp1/04_discrete_kansvariabelen/04_discrete_kansvariabelen.html` | 1,00 (`03_discrete_kansvariabelen.html`) | 0,18 (`04_normaalverdeling_z.html`) |
| `werkboeken/ozp1/03_normaalverdeling_z/03_normaalverdeling_z.html` | 0,98 (`04_normaalverdeling_z.html`) | 0,18 (`03_discrete_kansvariabelen.html`) |
| `werkboeken/ozp1/04_discrete_kansvariabelen/04_discrete_kansvariabelen.html` | 0,99 (`03_discrete_kansvariabelen.html`) | 0,18 (`04_normaalverdeling_z.html`) |

De twee regels met `oefenboeken/ozp1/…` zijn de scherpste. Die adressen stonden van 7-8 t/m 19-9 live, dus midden in het vak. De veertien met `werkboeken/ozp1/…` stonden er eerder, tot 7-8.

## Krap — gebouwd, maar kijk even mee

Hier wint het doel, maar met een marge van minder dan 0,05. Het doel is steeds hetzelfde bestand onder een nieuw pad. De marge is klein omdat de oude bladzij sindsdien in tweeën is gesplitst (meervoudige regressie en confounding), of omdat hij in de R-preview van 2-8 nog anders heette. Wil je een van deze liever niet: zet hem in `HANDMATIG` in `doorstuurders.py` en draai `--afleiden` en `--bouw`.

| oud adres | → nieuw adres | overlap | beste andere |
|---|---|---:|---|
| `werkboeken/broertjes/jasp/20_blokken/blok_meervoudige_regressie.html` | `oefenboeken/broertjes/jasp/20_blokken/blok_meervoudige_regressie.html` | 0,31 | blok_confounding_partiele_correlatie.html 0,28 |
| `werkboeken/broertjes/r/20_blokken/blok_meervoudige_regressie.html` | `oefenboeken/broertjes/r/20_blokken/blok_meervoudige_regressie.html` | 0,27 | blok_confounding_partiele_correlatie.html 0,26 |
| `werkboeken/broertjes/r_preview/20_blokken/blok_interactie.html` | `oefenboeken/broertjes/r/20_blokken/blok_interactie.html` | 0,23 | blok_t_toets.html 0,19 |
| `werkboeken/broertjes/r_preview/20_blokken/blok_meervoudige_regressie.html` | `oefenboeken/broertjes/r/20_blokken/blok_meervoudige_regressie.html` | 0,23 | blok_confounding_partiele_correlatie.html 0,21 |
| `werkboeken/broertjes/r_preview/installatie.html` | `oefenboeken/broertjes/r/installatie.html` | 0,15 | index.html 0,14 |
| `werkboeken/broertjes/spss/20_blokken/blok_meervoudige_regressie.html` | `oefenboeken/broertjes/spss/20_blokken/blok_meervoudige_regressie.html` | 0,30 | blok_anova.html 0,27 |

## Niet gebouwd — alleen op de lijst

| oud adres | stond live | titel | waarom niet |
|---|---|---|---|
| `HEROPSTART.html` | 30-5 | heropstart | geen boek in het pad en nergens op de site een opvolger (op stam of titel) |
| `oefenboeken/broertjes/r/10_data/LEESMIJ_GETALLEN.html` | 9-8 t/m 10-8 | leesmij_getallen | geen kandidaat op pad, stam of titel in oefenboeken/broertjes/r |
| `oefenboeken/broertjes/r/OPDRACHT_TIDYVERSE_EN_BASISHANDELINGEN.html` | 8-8 t/m 10-8 | opdracht_tidyverse_en_basishandelingen | geen kandidaat op pad, stam of titel in oefenboeken/broertjes/r |
| `werkboeken/broertjes/s2_schud_tabel.html` | 24-7 | Schud de tabel — chi-kwadraat | geen boek in het pad, en vier kopieën van dezelfde bladzij: JASP, R, SPSS, speelkist (`speeltjes/schud-tabel.html`). Welke bedoeld is, is een keuze |
| `werkboeken/broertjes/speeltje_schud_correlatie.html` | 24-7 | Schud het — correlatie | geen boek in het pad, en vier kopieën van dezelfde bladzij: JASP, R, SPSS, speelkist (`speeltjes/schud-correlatie.html`). Welke bedoeld is, is een keuze |
| `werkboeken/broertjes/w12_schud_odds.html` | 24-7 | Schud de odds — odds ratio | geen boek in het pad, en vier kopieën van dezelfde bladzij: JASP, R, SPSS, speelkist (`speeltjes/schud-odds.html`). Welke bedoeld is, is een keuze |
| `werkboeken/broertjes/w6_p_planten.html` | 24-7 | Schud de labels — de p-waarde is geteld toeval | geen boek in het pad, en vier kopieën van dezelfde bladzij: JASP, R, SPSS, speelkist (`speeltjes/schud-labels.html`). Welke bedoeld is, is een keuze |
| `werkboeken/broertjes/w6_schud_verschil.html` | 24-7 | Schud het — verschil | geen boek in het pad, en vier kopieën van dezelfde bladzij: JASP, R, SPSS, speelkist (`speeltjes/schud-verschil.html`). Welke bedoeld is, is een keuze |
| `werkboeken/broertjes/w6_trek_interval.html` | 24-7 | Trek opnieuw — het betrouwbaarheidsinterval | geen boek in het pad, en vier kopieën van dezelfde bladzij: JASP, R, SPSS, speelkist (`speeltjes/trek-opnieuw.html`). Welke bedoeld is, is een keuze |

De drie bovenste waren interne stukken die even per ongeluk online stonden (een heropstartnotitie, een leesmij bij de data, een opdracht). Daar hoort een 404. De zes speeltjes stonden op 24-7 één dag onder `werkboeken/broertjes/` zonder boeknaam. Er zijn nu vier kopieën van elk, en kiezen is aan jou. Wil je ze toch doorsturen, bijvoorbeeld naar de speelkist, dan is dat per speeltje één regel in `HANDMATIG` in `doorstuurders.py` (er staat een voorbeeld), en daarna `--afleiden` en `--bouw`.

## Alle overige koppelingen

Per groep het aantal, de spreiding van de overlap en één voorbeeld. De volledige lijst, met bewijs per rij, staat in `_tools/doorstuurders.tsv`.

- **broertjes (R, JASP, SPSS)** (75): overlap 0,27 tot 1,00, mediaan 0,59. Voorbeeld: `werkboeken/broertjes/jasp/20_blokken/blok_anova.html` → `oefenboeken/broertjes/jasp/20_blokken/blok_anova.html` ("Oefening 9.3 · ANOVA en η²" → "Oefening 9.4 · Eenweg ANOVA en η²").
- **GGZ-VS** (27): overlap 0,42 tot 1,00, mediaan 0,99. Voorbeeld: `werkboeken/ggz_vs/20_blokken/00_parkeerkaart.html` → `oefenboeken/ggz_vs/20_blokken/00_parkeerkaart.html` ("De parkeerkaart" → "De parkeerkaart").
- **broertjes, de R-preview van 2-8** (25): overlap 0,15 tot 1,00, mediaan 0,43. Voorbeeld: `werkboeken/broertjes/r_preview/20_blokken/blok_anova.html` → `oefenboeken/broertjes/r/20_blokken/blok_anova.html` ("Hoofdstuk 9 · ANOVA en η²" → "Oefening 9.4 · Eenweg ANOVA en η²").
- **broertjes, de platte adressen van 24-7** (16): overlap 0,29 tot 0,65, mediaan 0,45. Voorbeeld: `werkboeken/broertjes/jasp_betrouwbaarheidsinterval.html` → `oefenboeken/broertjes/jasp/20_blokken/blok_betrouwbaarheidsinterval.html` ("Het betrouwbaarheidsinterval" → "Oefening 5.1 · Het betrouwbaarheidsinterval").
- **MVDA** (16): overlap 0,99 tot 1,00, mediaan 1,00. Voorbeeld: `werkboeken/mvda/00_opfris.html` → `oefenboeken/mvda/00_opfris/00_opfris.html` ("0. Opfris — enkelvoudige regressie vóór het echte werk" → "0. Opfris — enkelvoudige regressie vóór het echte werk").
- **Handleiding (bookdown, 2021)** (6): overlap 0,99 tot 1,00, mediaan 1,00. Voorbeeld: `manuscript/handleiding/01-descriptive-statistics.html` → `manuscript/handleiding/hoofdstuk-1---het-beschrĳven-van-data-aan-de-hand-van-statistieken-descriptive-statistics..html` ("Hoofdstuk 1 - Het beschrĳven van data aan de hand van statistieken, Descriptive Statistics." → "1 Hoofdstuk 1 - Het beschrĳven van data aan de hand van statistieken, Descriptive Statistics.").

## Wat er aan het gereedschap verandert, en waarom

Alle vier de wijzigingen hebben een eigen commit, zodat ze los te bekijken zijn.

1. **`_tools/doorstuurders.py`** (nieuw). Het script heeft drie standen:
   - `--afleiden` maakt de tabel uit de gh-pages-geschiedenis;
   - `--bouw` schrijft de doorstuurders uit de tabel;
   - zonder vlag kijkt het na.

   De doorstuurders hebben dezelfde vorm als `werkboeken/index.html`: meta-refresh, canonical, noindex, een gewone link en geen teller. Er komt één regel commentaar bij die zegt waar ze vandaan komen. `tellerregel.soort()` herkent ze als doorstuurder, dus de tellerwachter slaat ze over en noemt ze bij naam. Ze vallen onder `resources` in `_quarto.yml` en komen daardoor niet in de sitemap.
2. **`plankwacht.py`** slaat een commit over die binnen een boekmap alleen doorstuurders neerzet. Het is dezelfde vorm als jouw besluit over de tellercommit van 30-9. Streng op de inhoud: een echte bladzij die door een doorstuurder wordt vervangen, telt wél als wijziging. Een themamap met alleen een doorstuurder erin is geen thema. **Dit is een keuze over wat "Bijgewerkt" betekent, en die is van jou.** Ik heb hem gemaakt naar het voorbeeld van 30-9; wil je het anders, dan kan die commit er los uit.
3. **`publish_workbook.py`** zet na zijn `rmtree` van `oefenboeken/<boek>/` de doorstuurders in die map terug. Zonder die stap waren de twee OZP 1-doorstuurders bij de eerstvolgende OZP 1-publicatie stil verdwenen.
4. **`naar_buiten.sh`** heeft een derde poort naast de plank en de teller: het nakijken van de doorstuurders. Die poort blokkeert op `--nakijken` en `--productie`, en meldt alleen op de proefwegen. Hij vangt een doorstuurder die verdwenen is, en een doel dat verhuisd is waardoor de doorstuurder naar een 404 wijst. Van de 23 doorstuurders die al bestonden kijkt hij **alleen of hun doel bestaat, niet of het het goede doel is**. Dat is geen theorie: de inventaris vond al dat `werkplaats/h3.html` en `h4.html` naar elkaars hoofdstuk wijzen, en de nakijker zag dat de werkplaats-doorstuurders een nummer opschuiven (h7 → h8, h8 → h9, h9 → h10, h10 → h12). Of dat klopt, heeft niemand op inhoud nagemeten; ze komen uit `_cascade_stubs.py` in het lab en vallen buiten dit spoor.

Waarom de koppeling alleen binnen hetzelfde boek zoekt: op tekst alleen lijkt een oud R-blok vaak meer op het huidige JASP-blok dan op het huidige R-blok (de nakijker: `blok_anova` 0,288 tegen 0,231, in zijn eigen maat). Het pad zegt welk boek het was; de tekst zegt alleen welke bladzij daarbinnen.

`publiceer_oefenboeken.sh` in het lab spiegelt met `rsync --delete` naar `oefenboeken/broertjes/*` en `oefenboeken/ggz_vs`. Daar staat bewust geen doorstuurder: alle oude broertjes- en GGZ-VS-adressen liggen onder `werkboeken/`, en daar schrijft geen enkel script.

## Poorten — opnieuw gedraaid voor dit verslag, op stand `ac8ebda`

`bash _tools/naar_buiten.sh --nakijken` → afloopcode **0**. De kernregels, letterlijk:

```
plankwacht: 10 kaartjes, 3 belofte(s) nagerekend tegen de bestanden
NB    Oefenboek OZP 1 (regel 122): 1 tellercommit(s) overgeslagen in oefenboeken/ozp1/: b9fd33a -- die zetten alleen de bezoekersteller erin
NB    Oefenboek OZP 1 (regel 122): 1 doorstuurcommit(s) overgeslagen in oefenboeken/ozp1/: 557d7e8 -- die zetten alleen doorstuurders op oude adressen, geen boektekst
uitgesloten (183) — geen bladzij, dus geen teller:
Alle 161 bladzijden dragen de teller.
Alle 181 doorstuurders uit de tabel staan er en wijzen naar een bestaande bladzij; de 23 andere ook.
Alle poorten staan groen. --productie zou hierop niet struikelen.
```

| toets | afloop | laatste regel |
|---|---:|---|
| `doorstuurders_test.sh` | 0 | 27 zaken getoetst, alles groen. |
| `doorstuurders_mutatieproef.sh` | 0 | 15 mutaties bijten, 0 niet |
| `plankwacht_test.sh` | 0 | goed: 27   gezakt: 0 |
| `plankwacht_mutatieproef.sh` | 0 | 19 mutaties bijten, 0 niet |
| `publish_teller_test.sh` | 0 | 23 zaken getoetst, alles groen. |
| `naar_buiten_teller_test.sh` | 0 | 15 zaken getoetst, alles groen. |
| `tellers_test.sh` | 0 | 24 zaken getoetst, alles groen. |
| `tellers_mutatieproef.sh` | 0 | 16 mutaties bijten, 0 niet |

## Lokale bouw en klikproef

`naar_buiten.sh --lokaal` **in de werkkopie zelf levert een lege site op.** `quarto inspect` ziet daar 0 invoerbestanden, en `_site/` bevat alleen `robots.txt` en een lege `sitemap.xml`. De werkkopie staat onder `.claude/worktrees/`, en Quarto slaat kennelijk alles over wat onder een map met een punt vooraan ligt. Daarom is de gecommitte stand (`git archive`, stand `ac8ebda`) in een tijdelijke map buiten `.claude/` gezet, en daar draaide `naar_buiten.sh --lokaal` wel (15 bronnen gerenderd, afloop 0, 4 seconden). Tegen die bouw liep een echte HTTP-server, en daartegen draaide curl:

```

== klikproef met curl (3 doorstuurders, elk twee stappen: oud adres, dan waar hij heen wijst)
  curl /werkboeken/ozp1/03_normaalverdeling_z/03_normaalverdeling_z.html
     -> HTTP 200, refresh naar /oefenboeken/ozp1/04_normaalverdeling_z/04_normaalverdeling_z.html, teller in doorstuurder: False
     -> curl doel: HTTP 200, titel: Thema 4 · Normaalverdeling & z-scores – Oefenboek OZP 1
  curl /oefenboeken/ozp1/04_discrete_kansvariabelen/04_discrete_kansvariabelen.html
     -> HTTP 200, refresh naar /oefenboeken/ozp1/03_discrete_kansvariabelen/03_discrete_kansvariabelen.html, teller in doorstuurder: False
     -> curl doel: HTTP 200, titel: Thema 3 · Discrete kansvariabelen – Oefenboek OZP 1
  curl /manuscript/handleiding/01-descriptive-statistics.html
     -> HTTP 200, refresh naar /manuscript/handleiding/hoofdstuk-1---het-beschr%C4%B3ven-van-data-aan-de-hand-van-statistieken-descriptive-statistics..html, teller in doorstuurder: False
     -> curl doel: HTTP 200, titel: 1 Hoofdstuk 1 - Het beschrĳven van data aan de hand van statistieken, Descriptive Statistics. | Handleiding Statistiek met JASP

== controle over ALLE rijen, in de gebouwde _site
  rijen om te bouwen: 181
  doorstuurder ontbreekt in _site: 0 []
  niet byte-gelijk aan de repo:    0 []
  met een teller erin:             0 []
  doel ontbreekt in _site:         0 []
  bewust niet gebouwd: 9, daarvan toch in _site: 0 []

== sitemap
  adressen in sitemap: 14
  daarvan werkboeken/ of een doorstuurder uit de tabel: 0
```

**Niet in een browser geproefd.** curl volgt geen meta-refresh; het bewijst dat het oude adres een 200 geeft en naar het goede doel wijst, en dat dat doel bestaat. Headless Chrome bleef hier drie keer 60 seconden hangen (de inventaris van 30-9 liep daar ook op vast). Dat een browser de refresh volgt, rust dus op de vorm. Die is gelijk aan die van de acht doorstuurders die sinds 7-8 live staan onder `werkboeken/`.

## Een tweede paar ogen

Voor het afmelden heeft een onafhankelijke nakijker (agent `nakijker`) de tak doorgelicht. Hij draaide de poorten en toetsen zelf, rekende alle 181 koppelingen na met een eigen overlapmaat (reeksen van drie woorden), en opende er 16 met de hand, waaronder de vier van de wissel. **Geen enkele doorstuurder wees verkeerd.** Wel vond hij acht punten, en alle acht zijn op deze tak opgelost: zeven in het gereedschap, elk met een toetszaak en een mutatie erbij, en één in dit verslag.

- **Ernstig, en een fout van mij:** de eerste versie van de plankwacht-uitzondering viel om op een commit met alleen een figuur (een PNG als tekst gelezen). `naar_buiten.sh` las die crash als "werk het kaartje bij", en `--productie` zat dan vast met een verkeerde reden. Vóór deze tak ging dat gewoon goed. Gerepareerd (`1711ea1`), en zaak 14d bootst het na.
- Na publicatie zou `--afleiden` bij elke run 181 regels alarm geven. De telling zelf bleef goed; alleen de controle loeide.
- Een crash van de doorstuurwachter kreeg afloopcode 1 ("klopt niet") in plaats van 3 ("kon niet kijken").
- Hoofdletters: macOS vindt een doel met verkeerde hoofdletters, GitHub Pages niet.
- `pr-preview/` (de proefdruk) zou na de eerste `--proefdruk` als honderden dode lezersadressen meetellen.
- `HANDMATIG` kon geen doel vastleggen.
- Een verwijderde echte bladzij werd door geen enkele plankwacht-zaak bewaakt.

Het achtste punt zat in dit verslag: bij een even aantal nam de mediaan de bovenste van de twee middelste waarden. Die wordt nu goed uitgerekend.

## Wat niet gemeten is

- **Of een browser de refresh volgt**: zie hierboven.
- **De live site.** Er is niets gepubliceerd. Of countcamp.org na publicatie een 200 geeft op de oude adressen, is pas daarna te meten, bijvoorbeeld met de kruiper uit de inventaris.
- **Ankers.** Een meta-refresh neemt het `#anker` uit een bladwijzer niet mee. Wie op `…/03_normaalverdeling_z.html#opgave-3-2` stond, komt bovenaan thema 4 uit. Voor OZP 1 is dat eerlijker dan het lijkt: door de wissel veranderden de opgavenummers ook.
- **Een proefdruk op internet** (`--proefdruk`). De doorstuurders wijzen met een pad vanaf de wortel (`/oefenboeken/…`). Op `countcamp.org/pr-preview/pr-N/` sturen ze je dus naar de echte site, niet naar de proefdruk. Dat doen de acht bestaande ook.

## Verrassingen

1. **De plankwacht zou de doorstuurders hebben tegengehouden, of een onware datum hebben afgedwongen.** De twee OZP 1-doorstuurders zijn een commit in `oefenboeken/ozp1/`. De plankwacht las dat als een boekwijziging en eiste "Bijgewerkt 1 oktober". Wie op de dag van de herkansing snel wil publiceren, past dan het kaartje aan in plaats van de wachter, en dan liegt de plank. Hersteld op deze tak; zie de keuze onder punt 2 hierboven.
2. **`publish_workbook.py` zou ze bij de volgende OZP 1-publicatie stil hebben gewist.** Het script gooit de hele boekmap weg voor het kopieert. Niets had dat gemeld. Hersteld, en getoetst: met de oude versie van het script zakken er 3 zaken.
3. **`git log --diff-filter=A` mist 127 van de 430 ooit gepubliceerde bladzijden.** Over de gh-pages-geschiedenis gaf het 303 bladzijden, en met `--no-renames` erbij 430. Git ziet een nieuw bestand dat genoeg op een verdwenen bestand lijkt als een *hernoeming*, en een hernoemd bestand heet dan niet "toegevoegd". Voorbeeld: `manuscript/h12.html` verscheen op 22-7 (`a698042`), maar git las dat als `h5.html` → `h12.html` (62%% gelijk), en `git log --diff-filter=A` over de hele tak noemt h12 nergens. Het is een nieuwe gedaante van "zoeken is niet gevonden hebben": leeg, geen fout, en het leest als "bestond niet". Het raakt iedereen die met git uitzoekt wat er ooit online stond.
4. **In een werkkopie van een zetter bouwt `naar_buiten.sh --lokaal` een lege site.** Quarto ziet onder `.claude/worktrees/` 0 invoerbestanden. De controle in de pers zegt het tenminste hardop ("_site/index.html is niet gebouwd"). Maar elke zetter die in zijn eigen werkkopie een lokale proefdruk wil, krijgt niets. `git archive` naar een map buiten `.claude/` werkt wel (4 seconden, zie hierboven).
5. **De uitvoer van de tellerpoort wordt lang.** `controleer_tellers.py` noemt elke uitgesloten doorstuurder bij naam. Dat waren er 8 en nu 183, dus `--nakijken` geeft zo'n 200 regels, en de paar regels die ertoe doen verdwijnen daartussen. Ik heb dat niet veranderd, omdat "een uitsluiting die je niet ziet, is een gat" een ontwerpkeuze van die wachter is. Per map tellen, met één voorbeeld, zou het leesbaar houden.

