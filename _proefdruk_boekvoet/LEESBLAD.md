# Proefdruk — spoor boekvoet (11-8-2026)

De voet van de boekpagina spreekt nu dezelfde taal als de oefenboeken-bladzij:
het ruggengraatje. En er staan nog drie boeken in plaats van vier.

## Wat er veranderde

`manuscript/index.qmd`, alleen het blok **De oefenboeken** onderaan (plus twee
regels in de kop). Verder is er niets aangeraakt.

1. **De vorm.** De vier callouts zijn de gedeelde plank geworden:
   `::: {.cc-plank}` met drie `::: {.cc-boek}`, kop als `###` met een
   `[R]{.cc-chip}` erachter — precies de opbouw van `oefenboeken/index.qmd`.
   Geen eigen CSS: alles komt uit het blok "De boekenplank in twee vormen" in
   `styles.css`. De bladzij laadt nu ook `../oefenboeken/vorm.js`, dus de
   schakelaar `VORM_STANDAARD` zet **alle drie** de bladzijden tegelijk om
   (oefenboeken, broertjes, boek). Zonder JavaScript geldt de rug-vorm.
2. **De inhoud.** Alleen nog de drie broertjes (R, JASP, SPSS). Het
   GGZ-VS/JASP-werkboek is eraf; de reden staat als comment in de bron, zodat
   niemand het terugzet zonder hem te kennen. Eronder één regel die naar de
   oefenboeken-bladzij wijst voor de rest.
3. **De teksten.** De drie beschrijvingen zijn nu **letterlijk** die van de
   oefenboeken-bladzij (zie hieronder). Daardoor stond de inleidende alinea
   erboven twee keer hetzelfde te zeggen — vier treden, pinguïns/Titanic/Big
   Five/luchtkwaliteit, eindopdracht, "voorlopige preview". Die alinea is
   ingekort tot wat de tegels *niet* zeggen: het losschudden en de datasets.
   Er is geen informatie verdwenen, alleen verhuisd naar de R-tegel.

## Bewijs

**De drie teksten zijn identiek** — gemeten op de gerenderde bladzijden, niet op
de bron, want dat is wat de lezer ziet:

```
$ python3 _tools/vergelijk_broertjes.py
IDENTIEK  het-r-oefenboek-r
IDENTIEK  het-jasp-oefenboek-jasp
IDENTIEK  het-spss-oefenboek-spss
alle drie letterlijk gelijk: True
```

**En de toets kan ook rood worden** — een groene toets die nooit rood is
geweest bewijst niets. Op een geknoeide kopie:

| geknoeid | uitkomst |
|---|---|
| één woord in de JASP-tekst gewijzigd | `VERSCHIL het-jasp-oefenboek-jasp`, exit 1, met beide regels eronder |
| het SPSS-blok weggehaald | `NIETS GEVONDEN`, exit 2 — leeg telt niet als "gelijk" |

**GoatCounter staat er nog in.** De nieuwe `include-in-header` in de kop had de
project-brede teller uit `_quarto.yml` kunnen verdringen; nagemeten in de
gerenderde bladzij staan ze er allebei (`grep -c goatcounter` = 1, plus
`<script src="../oefenboeken/vorm.js">` op regel 76, in de `<head>`, dus geen
flits van de verkeerde vorm).

**Nergens een dode verwijzing.** Niets op de site linkte naar het verdwenen
kopje `#op-maat-voor-een-opleiding` op de boekpagina (gegrepen over de hele
repo buiten `_site`).

## Schoten (na/)

| bestand | wat |
|---|---|
| `boekvoet_rug_1440.png` | de voet in de rug-vorm, 1440 px |
| `boekvoet_kaart_1440.png` | dezelfde voet met `?vorm=kaart` — de schakelaar pakt ook hier |
| `boekvoet_rug_mobiel_390.png` | mobiel, 390 px: chip blijft bij de titel, tekst loopt netjes door |
| `boekvoet_hover.png` | de regel-oplichter met echte muis: tint `rgb(223,235,242)` = #DFEBF2, titel onderstreept, chip wisselt naar wit |
| `boekvoet_focus.png` | met Tab: dezelfde oplichting plus de blauwe focusring om de titel |

Gemaakt met `schiet.R` in deze map (chromote). De hovertint is de computed
`background-color`, niet van een plaatje afgelezen.

## Voor de pers

Te committen: `manuscript/index.qmd`, `DUBBELINGEN.md`,
`_tools/vergelijk_broertjes.py` (nieuw). Deze map is proefdruk-gereedschap.
`_site/manuscript/index.html` is opnieuw gerenderd.

**Niet gedaan, met opzet:** niet gecommit, niet gepusht.

## Verrassingen

1. **De twee bladzijden zijn nooit écht gelijk geweest.** `DUBBELINGEN.md`
   meldt dat ze op 10-8 zijn "gelijkgetrokken", maar dat gold alleen voor twee
   losse zinsneden ("een oefenboek-schil", "in drie regels"). De R- en
   JASP-beschrijving op de boekpagina waren al die tijd eigen, kortere
   samenvattingen. De bewaking was "met de hand", en met de hand betekende in
   de praktijk: niemand heeft ze ooit naast elkaar gelegd. Dat is precies de
   faalklasse uit `CLAUDE.md` — stilte gelezen als "goed". Vandaar de
   vergelijker, die het meet in plaats van het te geloven.
2. **Dit was de enige regel in `DUBBELINGEN.md` zonder bron-kolom**, terwijl
   het document bovenaan zelf de regel stelt: *"de kolom bron is de waarheid.
   De rest zijn kopieën, en kopieën repareer je nooit ter plekke."* Zonder bron
   is er geen richting, en dan repareer je dus altijd ter plekke. Nu staat
   `oefenboeken/index.qmd` als bron aangewezen.
3. **Het GGZ-VS-werkboek is de enige beschrijving die nu nog maar op één plek
   staat** — dat is niet alleen minder werk maar een categorieverschil: die
   tekst *kan* niet meer uit de pas lopen. Als de dubbeling ooit blijft
   schuiven, is dit het model: minder plekken werkt beter dan beter bewaken.
   Van vier gedeelde teksten zijn er drie over, en de langste is weg.
4. **Klein, maar het kostte een ronde:** het venster verhogen om een lange
   bladzij in één schot te vangen werkt niet — de bladzij reflowt en de
   scrollpositie loopt weg, zodat je de kop van de pagina fotografeert in
   plaats van de voet. Knippen in paginacoördinaten (`cliprect` met `scrollY`
   erbij) doet het wel; dat staat nu zo in `schiet.R`.
