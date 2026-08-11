# Proefdruk — spoor plankvorm (11-8-2026)

Ben koos variant 3 (het ruggengraatje) met een oplichter, en wilde het
generiek: *"dat ik ook aan Mechteld kan vragen wat ze mooier vindt, zodat we
het later makkelijk kunnen aanpakken."* Dat ligt er nu. PNG's in `na/`.

## Hoe je wisselt — de ene zin voor Ben

**Open `oefenboeken/vorm.js` en verander het woord `"rug"` in `"kaart"` (of
terug) op de regel `VORM_STANDAARD = "rug"` — dat is alles, voor beide
bladzijden tegelijk.**

En voor Mech, twee links, niets installeren:

- ruggengraatje: `https://countcamp.org/oefenboeken/?vorm=rug`
- boekenplank: `https://countcamp.org/oefenboeken/?vorm=kaart`

(Zelfde truc werkt op de broertjes-pagina:
`https://countcamp.org/oefenboeken/broertjes/?vorm=kaart`.)

## Hoe het mechanisme werkt

`vorm.js` (nieuw, in `oefenboeken/`) zet bij het laden een attribuut
`data-vorm="rug"` of `"kaart"` op het `<html>`-element: de URL-parameter
`?vorm=` wint, anders geldt `VORM_STANDAARD`. Beide CSS-vormen staan
volledig in de stylesheet en hangen aan dat attribuut. Zonder JavaScript
komt er geen attribuut en geldt de rug-vorm (gemeten met scripts uit:
attribuut ontbreekt, bladzij toont het ruggengraatje). Het script staat in
de `<head>`, dus er is geen flits van de verkeerde vorm.

- `oefenboeken/index.qmd` — laadt `vorm.js` via de kop; **de lopende tekst
  is onaangeraakt** (dubbeling met de boekpagina blijft heel).
- `styles.css` — het blok "De boekenplank" is nu "De boekenplank in twee
  vormen": gedeelde basis, dan `html:not([data-vorm="kaart"])` (rug) en
  `html[data-vorm="kaart"]` (kaart, pixel voor pixel de plank van 10-8).
- `oefenboeken/broertjes/index.html` — zelfde splitsing in de eigen
  `<style>`, zelfde `vorm.js`.

## De rug-vorm, en wat de oplichter doet

- De boeken hangen aan een dunne lijn van **2 px** die per sectie kleurt:
  blauw (#2A79A7) bij het boek, paars (#6A6EAF) op maat, groen (#4D8962)
  losse vakken. Daarmee is Bens bezwaar van gisteren — de sectiekleur
  verdween in variant 3 — opgelost: de kleur zit weer op de rug, net als
  bij de kaarten.
- **Hover/focus licht de hele regel op** in de zachte sectietint (de
  bestaande callout-achtergronden): #DFEBF2 blauw, #E9E9F3 paars, #E4EDE7
  groen. Geen schaduw, geen beweging; de titel krijgt een onderstreping en
  de chip wisselt naar wit zodat hij niet in dezelfde tint verdrinkt — de
  kleur verhuist van chip naar regelvlak (`na/hover_rug_boek1.png`).
- **Toetsenbord**: Tab geeft dezelfde regel-oplichting (:focus-within) plus
  een zichtbare focusring, 2 px effen blauw om de titel, gemeten met echte
  Tab-toetsen (`na/focus_rug_boek1.png`).
- **prefers-reduced-motion**: overgangen uit, en in de kaartvorm ook de
  lift; de oplichter zelf blijft (kleur is geen beweging).

## Nameting oplichter (computed styles, echte muis via CDP)

| meting | waarde |
|---|---|
| rustachtergrond regel | transparant (papier #fdfcf9) |
| hovertint bij-het-boek | rgb(223,235,242) = #DFEBF2 |
| hovertint op-maat | rgb(233,233,243) = #E9E9F3 |
| hovertint losse-vakken | rgb(228,237,231) = #E4EDE7 |
| contrast tint ↔ papier | 1,18 / 1,17 / 1,17 — zacht, zoals gevraagd |
| lopende tekst #4a4a4a op de tinten | 7,3–7,4 (ruim boven AA 4,5) |
| hover-titelblauw #2A79A7 op #DFEBF2 | 3,9 (AA voor grote/vette tekst, plus onderstreping) |
| koptekst #1a3a5c op #DFEBF2 | 9,6 |
| lijn | 2 px, sectiekleur |
| focusring | 2 px solid #2A79A7, offset 4 px |

De oplichter-tint is bewust een tint die je nét ziet (1,17–1,18 : 1 tegen
het papier) — hetzelfde #DFEBF2 dat de wervels-lijst op de boekpagina al
als hover gebruikt, dus site-bekend gedrag.

## Schoten (na/)

- `rug_oefenboeken.png` / `kaart_oefenboeken.png` — beide vormen, 1440 px
- `rug_broertjes.png` / `kaart_broertjes.png` — broertjes in beide vormen
- `rug_mobiel_390.png` / `rug_broertjes_mobiel_390.png` — mobiel
- `hover_rug_boek1.png` / `focus_rug_boek1.png` — de oplichter met muis en
  met Tab

## Voor de pers

Te committen: `oefenboeken/vorm.js` (nieuw), `oefenboeken/index.qmd`,
`styles.css`, `oefenboeken/broertjes/index.html`. `_site` is bijgewerkt
(render + handkopie broertjes/styles/vorm.js zoals gisteren). Deze map
(`_proefdruk_plankvorm/`) is proefdruk-gereedschap, hoeft niet mee.

Opruimpunt: in `_site/oefenboeken/` liggen nog `var1.qmd`/`var2.qmd`/
`var3.qmd` van de proefdruk van gisteravond. `_site` staat in .gitignore,
maar als de publicatie de map integraal meeneemt, staan die bron-bestanden
straks op countcamp.org. Even weggooien vóór de volgende publicatie.

## Verrassingen

1. **De var-bestanden van gisteravond liggen nog in `_site/oefenboeken/`**
   (var1/2/3.qmd). Onschuldig op schijf, maar ze liften mee naar de
   openbare site als publicatie de hele map kopieert — opruimen dus.
2. **Zonder JavaScript is er geen kaartvorm meer mogelijk, en dat is een
   keuze.** De rug-vorm is de terugval (netjes, bewust), maar wie met
   scripts-uit surft ziet altijd het ruggengraatje, ook als Ben de
   standaard ooit op "kaart" zet. Voor deze site prima; het moet alleen
   niemand verbazen.
3. Klein: de eerdere tab-meting leek links over te slaan, maar dat bleek
   een race in mijn eigen meetscript (checken sneller dan de focus
   landde) — met 150 ms rust landt Tab keurig op *Het R-oefenboek*. De
   bladzij zelf deed niets geks.
