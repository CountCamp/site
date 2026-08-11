# Proefdruk — spoor oefenmooi (10-8-2026, avond)

Ben, laat op de avond: *"Op zich vind ik dat de oefenboeken ook wel wat mooier
mogen."* Dit blad zegt wat er niet mooi was, wat er nu ligt, en wat ik heb
overwogen en niet genomen. De PNG's staan in `voor/` en `na/`.

## 1. Wat er niet mooi was (voor/voor_oefenboeken_index.png)

**Zeven keer hetzelfde lichtblauwe callout-blok onder elkaar.** De bladzij
codeert nul verschil: het R-oefenboek (het vlaggenschip bij het boek) krijgt
exact hetzelfde blokje als de oude JASP-handleiding. Dat leest als een
formulier — Bens vermoeden klopte. Daarbij:

- De kopregels zijn blauwe linktekst op lichtblauw — weinig contrast, en
  alleen het pijltje zegt dat je ergens heen kunt. Het blok zelf is niet
  klikbaar.
- De homepage (kaarten met kleur-toprand) en de manuscript-inhoudsopgave
  (het ruggengraatje van vanmiddag) hebben inmiddels een eigen verzorgde
  vormentaal; deze bladzij had daar niets van.
- De drie secties — bij het boek / op maat / losse vakken — bestaan alleen
  als tekstkopjes; de vorm doet er niets mee.

## 2. Drie varianten, gerenderd (na/var*.png)

1. **Plank-stapel** (`var1_plank.png`) — klikbare witte kaarten in de taal van
   de homepage-tegels, accentrand *links* als boekrug, sectiekleur op de rug
   (blauw = bij het boek, paars = op maat, groen = losse vakken), en
   rechtsboven een chip met het gereedschap (R / JASP / SPSS).
2. **Drie deuren** (`var2_deuren.png`) — zelfde kaarten, maar de broertjes
   naast elkaar als drie kolommen ("kies er één" als nevenschikking).
3. **Ruggengraatje** (`var3_ruggengraatje.png`) — geen kaarten; de boeken
   hangen aan de dunne zandlijn, zoals de hoofdstukken op de
   manuscript-inhoudsopgave.

## 3. Keuze: de plank-stapel (variant 1)

- **Waarom niet de deuren:** de beschrijvingen mogen niet ingekort (ze staan
  dubbel met de boekpagina, zie DUBBELINGEN.md), en de R-tekst is ruim twee
  keer zo lang als de andere twee. In drie smalle kolommen wordt de R-kaart
  een sliert en breekt zelfs de SPSS-titel. Nevenschikking werkt pas als de
  teksten kort en gelijk zijn — dat is een inhoudsklus voor een andere avond.
- **Waarom niet het ruggengraatje:** heel rustig, maar het leest als een
  inhoudsopgave, niet als een plank waar je een boek van pakt. De TOC-vorm
  hoort bij hoofdstukken-in-volgorde; dit zijn keuzes. En de sectiekleur
  verdwijnt er.
- **De plank** lost precies het probleem op: kaarten nodigen uit
  (homepage-familie, zelfde hover), de rug kleurt per sectie, de chip maakt
  het gereedschap scanbaar zonder te lezen, en de hele kaart is klikbaar.

De broertjes-keuzepagina (`oefenboeken/broertjes/index.html`) had de
kaartvorm al; die kreeg dezelfde chips en dezelfde hover-schaduw, zodat de
twee bladzijden één taal spreken (`na/na_broertjes_index.png`).

## 4. Wat er precies veranderd is

- `oefenboeken/index.qmd` — de zeven `callout-note`-blokken zijn nu
  `.cc-plank`/`.cc-boek`-kaarten met `.cc-chip`-etiketten. **De lopende tekst
  is bewezen letterlijk gelijk** (markup gestript en tekstueel vergeleken:
  identiek) — de dubbeling met de boekpagina staat dus niet onder druk.
- `styles.css` — nieuw blok "De boekenplank" (na het woordherkomst-blok).
  Alle kleuren bestonden al: de ruggen zijn --cc-blue/--cc-purple/--cc-green,
  de chip-tinten zijn de bestaande callout-achtergronden (#DFEBF2, #E9E9F3,
  #E4EDE7). Eén nieuwe tekstkleur: #3b3e6e (donkere tint van --cc-purple,
  voor leesbaarheid op de paarse chip — zelfde maat vrijheid als de zandlijn
  van vanmiddag).
- `oefenboeken/broertjes/index.html` — chips + hover-schaduw, verder niets.
- Smal scherm (390 px, `na/na_mobiel_390_fix.png`): de kaartkoppen kregen
  `text-wrap: balance`, anders viel bij *Het JASP-oefenboek →* de pijl
  alleen op de tweede regel. Puur CSS; de tekst zelf is onaangeraakt.

## 5. Nameting (op de gerenderde bladzij, viewport 1440px)

| maat | waarde |
|---|---|
| leeskolom | 796 px |
| kaartbreedte | 796 px (vol) |
| kaart → kaart binnen een plank | 15 px = 4,0 mm |
| titel → tekst binnen een kaart | 6 px = 1,6 mm |
| kaart-padding | 1,05 rem boven · 1,35 rem zijkanten |
| boekrug | 4 px (zelfde dikte als de homepage-toprand) |
| chips, alle zeven | exact 45 px van de rechterkaartrand (uniform) |

De 4,0 mm kaart-afstand en 1,6 mm titel→tekst rijmen bewust met de maten van
de manuscript-inhoudsopgave van vanmiddag (4,7 mm tussen hoofdstukken, 1,6 mm
titel→onderwerpregel): zelfde ritme, andere bladzij.

## 6. Verrassingen

1. **De Tol-callout-koppen van styles.css zijn site-breed dood.** Regels
   179–188 beloven een donkerblauwe kopbalk met witte tekst, maar Quarto's
   eigen `div.callout-note.callout-style-default>.callout-header` wint op
   specificiteit — elke callout op de site toont al die tijd Quarto-pastel.
   Na deze wijziging gebruikt de oefenboekenbladzij geen callouts meer, maar
   de boekpagina en andere pagina's wel. Beslispunt Ben: alsnog afdwingen,
   of de dode regels opruimen (de pastel is eerlijk gezegd rustiger — past
   bij het besluit van 21-7).
2. **De boekpagina heeft dezelfde vier callout-tegels** (manuscript/index.qmd,
   onderaan). De plank-klassen staan nu site-breed in styles.css, dus die
   bladzij kan in dezelfde taal — kleine ingreep, maar buiten mijn
   werkgebied en dus niet gedaan. Zolang dat niet gebeurt, tonen boek- en
   oefenboekenbladzij de tegels in twee verschillende vormen.

## 7. Voor de pers

Te committen: `oefenboeken/index.qmd`, `styles.css`,
`oefenboeken/broertjes/index.html`. Daarna site renderen (de losse render
staat al in `_site`, plus de handgekopieerde broertjes-index). Deze map
(`_proefdruk_oefenmooi/`) is proefdruk-gereedschap en hoeft niet mee in de
commit.
