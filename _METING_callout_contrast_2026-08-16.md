# Meting: is de callout-kop op diensten.html leesbaar?

**16-8-2026, spoor `diensten`. Uitkomst: ja — 10,10 : 1, de eis is 4,5 : 1.**

De bordvraag `stijlschoon` meldde de kop van de callout op `diensten.html` als
wit-op-bijna-wit. Commit `806cf85` (12-8) haalde de regels weg die dat deden.
Wat nog nooit gebeurd was, is het resultaat *meten*. Dit is die meting.

## Wat er gemeten is

De kop is de regel **"Even sparren of iets afspreken?"** in de note-callout
onderaan `diensten.qmd` (regel 41–46), in de DOM het element
`.callout .callout-title-container`.

| | waarde |
|---|---|
| tekst op het scherm | `#38393a` |
| achtergrond op het scherm | `#e8f1fb` |
| contrastverhouding | **10,10 : 1** |
| lettergrootte / -gewicht | 15,3 px / 600 |
| toegepaste eis | **4,5 : 1** (gewone tekst) |
| oordeel | ruim voldoende — haalt ook AAA (7 : 1) |

**Waarom 4,5 en niet 3.** De soepeler eis van 3 : 1 geldt alleen voor *grote
tekst*: 24 px, of 18,66 px als hij vet is. Deze kop is 15,3 px. Gewicht 600 helpt
niet — hij blijft ruim onder de grens, dus de gewone eis van 4,5 : 1 geldt.

Ter vergelijking, met dezelfde methode: de lopende tekst ín de callout haalt
14,34 : 1, en de weggehaalde regel `color: #fff` zou op deze kopbalk **1,11 : 1**
hebben opgeleverd. Dat laatste getal is wat `stijlschoon` zag. Het is nu weg.

## Hoe die kleuren tot stand komen

Geen van beide staat als zodanig in een stylesheet; ze zijn het resultaat van
drie lagen over elkaar. Van onder naar boven:

1. `body` — `rgb(253, 252, 249)`, het papier van de site.
2. `div.callout.callout-note` — `#dfebf2`, de zachte tint uit `styles.css:204`.
3. `div.callout-header` — `rgb(233.4, 242.3, 252.2)` uit Quarto's eigen
   cosmo-bundel, **plus `opacity: 85%`** op datzelfde element.

Die `opacity` is de valkuil. Het is *groeps*-doorzichtigheid: de kopbalk wordt
eerst compleet getekend, achtergrond én letters, en dat geheel gaat daarna voor
85% over de baktint eronder. Dus geen van beide kleuren is wat de regel zegt:

* letters `#1a1a1a` (de `--cc-ink` uit `styles.css:13`) → 0,85 × `#1a1a1a` +
  0,15 × `#dfebf2` = **`#38393a`**
* balk `#e9f2fc` → 0,85 × `#e9f2fc` + 0,15 × `#dfebf2` = **`#e8f1fb`**

Wie de `opacity` overslaat en `#1a1a1a` op `#e9f2fc` narekent, komt op 15,39 : 1
uit. Dat is 5 punten te hoog en het is een kleur die niemand op het scherm heeft.
De eerste meetronde hier deed precies dat; het is gecorrigeerd.

Nergens in `styles.css` of in de cosmo-bundel staat nog een `color` op
`.callout-header` — nagekeken in beide bestanden. De kop erft `--cc-ink`.

## Hoe het gemeten is, en waarom zo

- `_meet_contrast.py` plakt een meet-scriptje achter in een **kopie** van de
  gerenderde pagina, laat Chrome die laden (`--headless=new --dump-dom`) en leest
  `getComputedStyle` uit. Dus: wat de cascade oplevert, niet wat een stylesheet
  in zijn eentje belooft.
- `_wcag.py` rekent dezelfde verhouding nog eens na in Python, met de *exacte*
  kanaalwaarden. Op hex afgerond komt er 10,14 : 1 uit in plaats van 10,10 — dat
  verschil is de afronding, niet een meetfout. Wie het natoetst met een
  hex-invoerveld ziet dus 10,14 en dat klopt.
- Gecontroleerd tegen de **live** site: `https://countcamp.org/styles.css` is
  byte-voor-byte gelijk aan die in de repo, de callout-markup is dezelfde, en de
  regel `div.callout-note.callout-style-default>.callout-header` staat in de live
  cosmo-bundel met exact dezelfde `rgb(233.4, 242.3, 252.2)`. De meting hier
  beschrijft dus de pagina zoals hij nu online staat.

## `_meetconfig.yml` — waarom die er is

Quarto ziet het project niet zolang de werkkopie onder een map staat die met een
punt begint (`.claude/worktrees/…`). Zonder projectconfig valt `theme: cosmo` en
`css: styles.css` weg en meet je een kale bootstrap-pagina. `_meetconfig.yml` is
een handmatige kopie van het `format`-blok uit `_quarto.yml` en wordt meegegeven
met `--metadata-file`:

```
quarto render diensten.qmd --metadata-file _meetconfig.yml
python3 _meet_contrast.py
python3 _wcag.py
```

Dat het aan de punt-map ligt is gemeten, niet aangenomen: hetzelfde
mini-project rendert in `/tmp/qprobe3` mét projectconfig (`lang="nl"`, uitvoer in
`_uit/`) en hier zonder (`lang="en"`, uitvoer naast de bron).
