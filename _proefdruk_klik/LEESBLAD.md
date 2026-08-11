# Proefdruk — spoor klik (11-8-2026)

De links naar de oefenboeken deden niets als je erop klikte. Dat klopte, en het
was erger dan het leek: **niet alleen de titel, de hele regel was muisdood.**
Gerepareerd in `styles.css`, twee regels. Niet gecommit, niet gepusht.

## Wat er aan de hand was

Niet wat je zou denken. Het ankertje van Quarto stond niet "in de weg" — het is
**7 bij 0 pixels groot en onzichtbaar**. Toch ving het élke klik op een blok van
796 bij 191 pixels. De dader is onze eigen truc:

```css
.cc-boek h3 a::after { content: ""; position: absolute; inset: 0; }
```

Die regel is bedoeld voor één link: de titel spant een onzichtbaar vel over de
hele rij, zodat je overal kunt klikken. Maar hij zegt `a`, niet "de titel". En
sinds de plank van gisteren (3c9c2f3) zijn deze blokken `h3`-koppen — en achter
elke kop plakt Quarto een tweede `<a>`: het anker-icoontje. Dus kreeg **dat**
ook een vel over de hele rij, en omdat het later in de DOM staat, lag het
bovenop. Elke klik landde op een leeg ankertje dat naar `#het-r-oefenboek` wees.

Vandaar het rare beeld dat je zag: de href klopt, `a.click()` navigeert netjes,
alle doelen geven 200 — alleen de muis komt er niet bij.

## Wat ik heb veranderd — `styles.css`, regels 357-371

```css
.cc-boek h3 a.anchorjs-link { display: none; }
...
.cc-boek h3 a:not(.anchorjs-link)::after { content: ""; position: absolute; inset: 0; }
```

**Waarom `display: none` en niet `pointer-events: none`.** Deze koppen zijn geen
secties maar linkkaarten naar een ándere bladzij; naar "Het R-oefenboek →"
deeplinken heeft geen betekenis. Het icoontje heeft hier dus geen functie, ook
niet als het niet in de weg zat. `pointer-events: none` laat het staan: nog
steeds een zichtbaar `#` bij hover naast een titel die al een link is, en nog
steeds een tabstop voor toetsenbordgebruikers. Weg is netter dan onaanraakbaar.

**Waarom óók de `:not()`.** Die is niet dubbelop. `display: none` haalt dit ene
ankertje weg; de `:not()` repareert de regel zelf. Zoals hij stond, brak elke
tweede `<a>` in zo'n kop de hele rij — ankertje of niet. Zet er ooit iemand een
klein "(nieuw)"-linkje of een tweede verwijzing in de titel, dan is de rij weer
dood en zoek je opnieuw een avond. Nu kan alleen de titel de rij overspannen.

**Waarom in de CSS en niet `anchor-sections: false` in de bladzij.** Dat staat al
op de homepage en de speelkist, en het werkt (nul ankertjes daar, nagemeten).
Maar het is per bladzij en het is te grof: op de oefenboeken-bladzij zijn
"Online", "Bij het boek", "Voor losse vakken" wél echte secties, waar een anker
gewoon hoort. Bovendien zou elke nieuwe bladzij met een plank het opnieuw moeten
onthouden. De CSS hangt aan `.cc-boek` en reist dus automatisch mee — ook naar de
boekpagina waar het boekvoet-spoor de plank nu neerzet.

## De meting — 20 rijen, voor en na

De Chrome-extensie gaf geen toestemming, dus gemeten met Chrome-zonder-venster.
De live bladzij lokaal neergezet met een `<base>`-tag, zodat CSS en JS nog steeds
van countcamp.org komen; alleen het meetscriptje is van mij. De live `styles.css`
is byte-voor-byte gelijk aan de lokale (`diff`, nagemeten) — dus dit is wat jij in
de trein zag. Voor de nameting leg ik de héle lokale `styles.css` erover, geen
overgetikt fragment.

Per rij `document.elementFromPoint` op twee punten: het midden van de
**titeltekst**, en het midden van de **hele rij** (de "hele regel klikbaar"-belofte).

| bladzij | vorm | rijen | titel raak — voor | na | hele rij raak — voor | na |
|---|---|---|---|---|---|---|
| oefenboeken | rug | 7 | 0/7 | **7/7** | 0/7 | **7/7** |
| oefenboeken | kaart | 7 | 0/7 | **7/7** | 0/7 | **7/7** |
| boekpagina¹ | rug | 3 | 0/3 | **3/3** | 0/3 | **3/3** |
| boekpagina¹ | kaart | 3 | 0/3 | **3/3** | 0/3 | **3/3** |
| | | **20** | **0/20** | **20/20** | **0/20** | **20/20** |

Voor de wijziging raakte alle 20 keer `a.anchorjs-link`; na de wijziging alle 20
keer de echte titellink.

¹ De **live** boekpagina heeft de plank nog niet (`cc-boek` komt er 0× voor in de
gepubliceerde HTML) — d815657 staat dus nog niet online. Gemeten op de lokale
`_site`-render van d815657, met CSS en JS van live. Zodra die bladzij wél
gepubliceerd wordt, zou hij precies dezelfde storing hebben gehad.

## Wat het niet stukmaakt — ook nagemeten

- **Echte secties houden hun ankertje.** Op dezelfde bladzij: 7 ankertjes in
  boekblokken gaan van `block` naar `none`; de 6 in echte secties ("Online",
  "Bij het boek", "Op maat voor een opleiding", "Voor losse vakken", "In opbouw",
  "Hoe te gebruiken") blijven `inline`, onaangeraakt.
- **Toetsenbord blijft werken.** De titellink is nog steeds focusbaar
  (`tabindex 0`, `document.activeElement` klopt na `.focus()`). Er is zelfs één
  zinloze tabstop minder, want het ankertje viel weg.
- **De regelhoogte verandert niet** (22,7 px voor én na).

## Eén zichtbaar neveneffect — kijk hier even naar

De chip (R / JASP / SPSS) **schuift 20,5 px naar rechts**, in alle zeven rijen.
`schot_voor.png` en `schot_na.png` staan ernaast.

Dat komt zo: de `h3` is een flexregel, de chip wordt met `margin-left: auto` naar
rechts geduwd — en het ankertje was daar het láátste flex-item. Die 7 px plus de
`gap` van 0,6rem hielden de chip 20,5 px van de rand. Nu staat hij gelijk met de
rechterrand van de lopende tekst eronder, wat `margin-left: auto` altijd al
bedoelde. Ik vind het netter zo, maar het is jouw bladzij: wil je de oude lucht
terug, dan is dat `margin-right: 20px` op `.cc-chip` — zeg het maar.

## De breedte-controle

Alle bladzijden nagelopen op hetzelfde patroon: een kop die tegelijk een link
naar elders is. Gemeten, niet gelezen (`sweep.py`, `document.elementFromPoint`
op het midden van elke titel).

| bladzij | koppen-die-link-zijn | stuk |
|---|---|---|
| homepage | 7 | 0 — géén ankertjes (`anchor-sections: false`), en geen overlay-truc |
| speelkist | 12 | 0 — idem |
| tabellen / broertjes / diensten / over / archief | 0 | — |

De broertjes-bladzij doet het trouwens op de eerlijke manier: `<a class="kaart">`
om de hele kaart heen, geen kop-met-link, geen onzichtbaar vel. Dat patroon kan
per definitie niet stuk.

`.cc-boek` is de **enige** plek in de hele `styles.css` met een
`position: absolute; inset: 0`-overlay (nagemeten: één treffer). Er staat dus
verder niets van dit type klaar om om te vallen.

## Wat hier ligt

- `styles.css` — de reparatie (regels 357-371). **Niet gecommit.**
- `meet.py` — de hoofdmeting, 20 rijen, `python3 meet.py VOOR` of `... NA`
- `sweep.py` — de breedte-controle over de andere bladzijden
- `rest.py` — echte secties + toetsenbordcontrole
- `chip.py` / `schot.py` — het chip-neveneffect, in getallen en in beeld
- `live_oefenboeken.html`, `live_boekpagina.html` — de gemeten bronnen
