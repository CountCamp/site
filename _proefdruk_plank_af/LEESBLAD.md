# De plank afgemaakt — 10-9-2026

Twee dingen die Ben goedkeurde: de dubbele plaatsbepaling eruit, en een eigen
kop voor Erasmus met STAT 3 eronder. Dit blad zegt wat er gemeten is en waarmee.

## Waarom hier een eigen proefblad staat

Quarto rendert **nul invoerbestanden** vanuit een worktree onder `.claude/`.
Dat ziet er niet uit als een storing: `quarto render` eindigt zonder klacht en
`_site/` bevat netjes `robots.txt` en `sitemap.xml`. Doorgemeten met
`quarto inspect`: het project wórdt gevonden, en het aantal invoerbestanden is
**0**. De enige verborgen schakel in het pad is de map `.claude` zelf.

`bouw_proefblad.py` maakt daarom een los proefblad met dezelfde cascade als de
echte bladzij — `theme: cosmo` plus `styles.css`, precies wat het format-blok in
`_quarto.yml` voorschrijft. De romp wordt **afgeleid** uit
`oefenboeken/index.qmd` en niet overgetikt, zodat het proefblad niet uit de pas
kan gaan lopen. Wat het niet heeft is de navbar en de voet.

```bash
python3 _proefdruk_plank_af/bouw_proefblad.py
quarto render _proefdruk_plank_af/proefblad.qmd
Rscript _proefdruk_plank_af/meet.R          # groepjes, labels, onafe boeken
Rscript _proefdruk_plank_af/meet_afstand.R  # staat de kop nog in beeld?
Rscript _proefdruk_plank_af/meet_link.R     # oogt een kop zonder link als kapot?
Rscript _proefdruk_plank_af/schiet.R        # de uitsneden in na/
python3 _proefdruk_plank_af/tel_ozp1.py     # hoeveel hoofdstukken heeft OZP 1?
```

De vorm gaat via `?vorm=` en niet door zelf `data-vorm` te zetten: `vorm.js`
staat in de `<head>`, draait ná zo'n ingreep en zet hem terug. Dat ziet er
precies zo uit als "de kaart-vorm verandert hier niets". Elk script toetst
daarom hardop welke vorm er op stond toen het mat.

## 1. De drie groepjes — in beide vormen gelijk

| | rug | kaart |
|---|---|---|
| plank Leiden/Psychologie (2 boeken) | 9,35 / 28,9 px | idem, `grid` |
| plank Leiden/Pedagogiek (2 boeken) | 9,35 / 28,9 px | idem, `grid` |
| plank Erasmus/Psychologie (**1** boek) | 9,35 / 28,9 px | idem, `grid` |
| instellingskop | 44,2 px boven, 1 px haarlijn eronder | idem |
| opleidingslabel direct onder een instelling | 14,45 px boven | idem |
| opleidingslabel ná een plank (Pedagogiek) | 25,5 px boven | idem |

Erasmus gedraagt zich dus precies als Leiden, ook al heeft hij één boek tegen
vier. Het verschil van 14,45 tegen 25,5 px is geen storing maar de regel
`.cc-instelling + .cc-opleiding`: een label dat tegen zijn instellingskop
aanligt hoort dichterbij te staan dan een tweede opleiding onder een plank.

## 2. Was de dubbeling ergens tóch nodig?

De opdracht vroeg dit expliciet. Gemeten in een venster van 1440 × 900, met de
titel van elk boek midden in beeld (`meet_afstand.R`):

| boek | afstand tot instelling | tot opleiding | instelling in beeld |
|---|---|---|---|
| Psychometrie | 134 / 145 px | 81 / 92 | **ja** |
| MVDA | 326 / 378 px | 273 / 325 | **ja** |
| OZP 1 | 557 / 635 px | 81 / 92 | nee |
| OZP 2 | 813 / 935 px | 337 / 392 | nee |
| STAT 3 | 134 / 145 px | 81 / 92 | **ja** |

(rug / kaart. Het **opleidingslabel** blijft in alle tien de metingen in beeld.)

Bij OZP 1 en OZP 2 kan de instellingskop dus wegscrollen. Toch is de dubbeling
niet nodig, en dat komt door wélke boeken het zijn: die twee staan onder
**Pedagogiek**, en Pedagogiek bestaat hier maar bij één instelling. Het label
dat wél bij twee instellingen voorkomt is **Psychologie** — en juist de drie
boeken daaronder houden hun instellingskop in beeld (134–145 px). Het dubbele
label en de wegvallende kop treffen elkaar nergens.

De aanname in de opdracht klopte niet: de **rug**-vorm is de krappere van de
twee, niet de ruimere. Kaart zet alles 8 tot 19 % verder uit elkaar
(uitgerekend over de negen afstanden die verschillen; mediaan 14 %).

Michelle (testlezer, Pedagogiek Leiden) las het net zo: *"als ik alleen
'Pedagogiek' boven mijn boeken zie, dan ben ik zelf naar beneden gescrold, dus
ik ben al langs die kop geweest."* Ze struikelde wél kort bij de tweede
`Psychologie`: *"hè, nog een keer Psychologie?"* — en herstelde door omhoog te
kijken, wat de meting voorspelt. Haar waarschuwing voor later: zodra er een
tweede **Pedagogiek** bij komt, wordt dit wél een probleem.

## 3. OZP 2 en STAT 3 — één manier, niet twee

Alle gemeten eigenschappen gelijk, in beide vormen:

| | rug | kaart |
|---|---|---|
| link in de titel | 0 | 0 |
| rug van het boek | 2 px **dashed** | 4 px dashed, rondom dashed |
| achtergrond bij zweven | onveranderd | onveranderd |
| lift bij zweven | geen | geen (`transform: none`) |
| chip | open rand van streepjes, woord "in opbouw" | idem |

Ter vergelijking: een boek dat er wél is reageert wel — in rug licht de regel op
naar `rgb(228, 237, 231)`, in kaart tilt hij `-2 px`.

**Oogt een kop zonder link als een kapotte link?** Michelle kon dat niet
beoordelen uit de bron. Gemeten (`meet_link.R`), en het verschil zit op vier
punten tegelijk, in beide vormen gelijk:

| | boek mét link | boek zonder link |
|---|---|---|
| kleur | `rgb(26, 58, 92)` diepblauw | `rgb(74, 74, 74)` gedempt |
| pijl `→` | ja | nee |
| muisaanwijzer | `pointer` | `auto` |
| reactie bij zweven | ja | nee |

Kleur draagt nergens alléén de betekenis: het woord "in opbouw" staat er
voluit, de vorm is een open rand van streepjes, en de pijl ontbreekt.
Contrast van het gedempte kopje op papier: **8,64** (WCAG AA vraagt 4,5).
De streepjesrand van de chip haalt **2,05** — onder de 3,0 die WCAG voor
niet-tekst vraagt. Dat was vóór vandaag ook al zo; het woord en de kleur dragen
de betekenis, de rand versterkt alleen.

## 4. "Nog niet op de plank" kon helemaal weg

Er stond alleen STAT 3 in. Gezocht met `command grep` (dus niet de ugrep-schil)
over `*.qmd`, `*.md`, `*.yml`, `*.css` en `*.js`: 4 treffers op "In opbouw",
"Nog niet op de plank", "STAT 3" of "skelet", waarvan één de nieuwe regel is,
één een gedateerd meetverslag (`_proefdruk_klik/LEESBLAD.md`, dat de koppen
noemt zoals ze tóén heetten — dat is een meting van toen en blijft staan), en
twee losse notities in `README.md` en `_HEROPSTART.md`.

Let op: de opdracht noemde de sectie "In opbouw". Zo heette hij niet meer —
vanochtend is hij hernoemd naar **"Nog niet op de plank"**, juist omdat "In
opbouw" botste met de chip op OZP 2.

## Wat ik niet kon meten

- De **echte** gebouwde site. Zie hierboven: Quarto bouwt hier niets. Wat ik mat
  is het proefblad met dezelfde cascade, zonder navbar en voet.
- Of een achtergebleven `oefenboeken/index.html` de gerenderde bladzij in
  `_site/` daadwerkelijk overschrijft. Dat vraagt een echte projectbouw. Wat ik
  wél vaststelde staat hieronder.

## Verrassingen

**Een testrender laat een tijdbom achter.** `quarto render oefenboeken/index.qmd`
schrijft `oefenboeken/index.html` náást de bron. Die map staat in `_quarto.yml`
onder `project.resources` (`"oefenboeken/**"`) én bevat **153 getrackte
`.html`-bestanden**, plus zeven `index.html`-broertjes op
`oefenboeken/<werkboek>/index.html`. Een achtergebleven bouwsel valt daar dus
niet op, `git status` toont het tussen normaal ogende buren, en `git add .`
commit hem mee. Ik heb hem meteen weggehaald.

**Er staan drie manieren op de plank om "niet af" te zeggen, niet twee.**
"in opbouw" (niets te lezen — OZP 2, STAT 3), "twee van de zeven thema's staan
online" plus chip "nieuw" (Psychometrie), en "voorlopige versie" (MVDA).
Michelle zag het paar OZP 2/STAT 3 meteen als één categorie, en juist daardoor
viel de rest uit de toon.

**Het OZP 1-werkboek is vanochtend hernoemd en de plank liep achter.** Sinds
`dc070a0` heet het `Handrekenen — bij OZP 1`; daarvóór `Werkboek OZP 1`. De
plank noemt hem nog "Werkboek OZP 1 — Statistiek", dus je klikt op de ene naam
en landt op de andere. Niet veranderd: dat is een naamkeuze.

**Mijn eigen bevinding van vanochtend was fout.** Ik meldde toen *"de plank zegt
Twaalf hoofdstukken en er staan er veertien"*. Ik telde mappen. Uitgeteld naar
soort (`tel_ozp1.py`, uit de index van het werkboek zelf) zijn het
**1 Deel + 12 Thema's + 1 Bijlage**. "Twaalf" klopt dus als hoofdstuk = thema,
en zou dertien moeten zijn als Deel 0 meetelt. Wat wél blijft staan: de
opsomming in die zin eindigt bij chi-kwadraat (thema 11) en noemt thema 13 niet.

**De APA-lens vond dezelfde letter twee keer anders gezet in één zin** (regel
126): `*z*-waarden` cursief naast `z-/t-/χ²-toetsen` kaal. Sectiebreed 4 cursief
tegen 2 kaal. Buiten mijn opdracht, dus niet aangeraakt. Wie het repareert moet
weten dat de `χ²` nú goed staat — Grieks blijft rechtop — ook al oogt
`*z*-/*t*-/χ²-` daardoor scheef.
