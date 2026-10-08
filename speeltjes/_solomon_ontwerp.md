# Solomon, ontleed het design — ontwerpnotitie (stuk 1 van 3, 8-10-2026)

Speeltje: `speeltjes/solomon.html`. Eén zelfstandig HTML-bestand, geen internet nodig.
Tegel: `speeltjes/index.qmd`, nieuwe rubriek *Ontleden*. Register: `~/Ben_OS_brain/shared_assets/speeltjes/SPEELTJES_REGISTER.md`.

**Let op, de bron.** Alle andere speeltjes hebben hun bron in `countcamp_lab/boek/04_speeltjes/`; deze kist
is een kopie (`_tools/bouw_speelkist.py`). Dit speeltje is gebouwd in de kist zelf, omdat de opdracht dat
vroeg en een zetter niet in `countcamp_lab` mag schrijven. `bouw_speelkist.py` meldt het daarom als
`ONBEKEND IN DE KIST`. Wordt het geaccepteerd: kopieer het naar `countcamp_lab/boek/04_speeltjes/solomon.html`
en zet `"solomon.html": "solomon.html"` in `KIST`.

## Waar het op rust

Bens methode, in zijn woorden (30-9 en 6/8-10-2026, `BEN_SOLOMON_METHODE.md`): *"voor 3 en 4 voormeting deed
ik het gemiddelde van 1 en 2. dan S + T + H/M + X = 1Na − 1Voor. T + H/M = 2Na − 2Voor en zo voort en dan
van beneden naar boven."* De getallen zijn die van zijn oefentoets (Bib-item `opg-tent-leiden-mt-20151026-q39`,
`auteur: Ben`): voormeting I en II 8, nameting 15 / 10 / 11 / 8. Het speeltje typt alleen die zes getallen;
al het andere rekent het uit.

## Hoe anderen het doen

Door een hulpagent opgezocht (21 zoekvragen, ±27 bladzijden gelezen).

| bron | wat goed is | wat minder is |
|---|---|---|
| Solomon (1949), *Psychological Bulletin, 46*(2) | Bens methode ís die van Solomon: de voormeting van III en IV is ½(a₁ + a₂), de interactie is d₁ − (d₂ + d₃ − d₄) | zijn groepen waren niet geloot |
| Campbell & Stanley (1963), pp. 24–25 | noemen T en S apart: *main effects of testing* en *interaction of testing and X* | wijzen Solomons rekenwijze af **als toets** en raden een 2×2-variantieanalyse op de nametingen aan |
| Dimitrov & Rumrill (2003), *Work, 20* | dezelfde stukjes per groep | hun interactieformule mist de term + D₄; zo staat het gedrukt (nagelezen door de hulpagent; hoe vaak het geciteerd is, is niet nagetrokken) |
| Open Universiteit, *OpenMenS* hfst. 7 | de enige die Bens aanname hardop zegt: de voormeting van de andere groepen schatten uit de gemeten | nummert de groepen anders (hun 2 is onze III) |
| Roose (UGent), hfst. 8 | echt voorbeeld, lijngrafieken | gooit testeffect en sensitisatie op één hoop |

Een interactief hulpmiddel voor dit ontwerp is niet gevonden (twee gerichte zoekrondes; dat bewijst niet dat
er geen bestaat). Wat het speeltje hiervan overnam: de rekenwijze hardop van Solomon laten zijn, en eerlijk
melden dat je S toetst op de nametingen (uitklapper onderaan).

## De ladder

Negen stapjes, allemaal op Bens getallen. Elke stap: de tabel opnieuw, één vraag, een dichtgeklapte hint en
een dichtgeklapte uitwerking die begint met *"Welke som heb je nodig?"*. Vanaf stap 4 eindigt elke uitwerking
met *Je vergelijkt / Je neemt aan* (precies de kolommen van de kaart) en met de trap van groep I, die per stap
een stukje verder is ingekleurd.

| stap | vraagt | de som | hint wijst naar |
|---|---|---|---|
| 1 Wie deed de voormeting? | welke groepen | geen, aflezen | de kolom voormeting |
| 2 Leen een voormeting | het startpunt van III en IV | (8 + 8) / 2 = 8 | het lot: gemiddeld gelijk begonnen |
| 3 Welke stukjes zitten in welke groep? | vinkjes groep × stukje | geen, de boekhouding | tijd voor iedereen; X waar training; T waar voormeting; S waar allebei |
| 4 Groep IV: H/M | H/M | 8 − 8 = 0 | IV kreeg niets, dus alleen de tijd |
| 5 Groep III: X | X | (11 − 8) − 0 = 3 | H/M ken je al |
| 6 Groep II: T | T | (10 − 8) − 0 = 2 | II heeft een echte voormeting |
| 7 Groep I: S | S | (15 − 8) − 2 − 0 − 3 = 2 | drie van de vier ken je al |
| 8 Verschil in verschil | (I − II) − (III − IV) | (7 − 2) − (3 − 0) = 2 | schrijf I − II uit in stukjes |
| 9 De vraag uit 2015 | meerkeuze 2 / 3 / 4 / 5 | stap 7 of 8 | sensitisatie is S; elk fout antwoord is een vergeten stukje |

Bij stap 9 zegt het speeltje van elk fout antwoord waar het vandaan komt, uitgerekend: 3 is X, 4 is 7 − 3
(T en H/M niet afgetrokken), 5 is I − II (daar zit X nog in).

## Keuzes, en waarvan ze afwijken

- **De context "training en toets" is van mij,** niet van Ben: zijn tentamen heeft alleen getallen. Zonder
  uitkomstvariabele kon *"het effect van de training **op de toetsscore**"* niet (taalgids: het object staat
  er altijd bij).
- **De titel** volgt de opdracht (*design*); in de tekst staat *ontwerp*, Bens eigen woord uit 2015 en de
  Germaans-Hollandse keuze. Vraag aan Ben welke hij in de titel wil.
- **De kaart** heeft de vier kolommen uit de opdracht (effect / groepen / som / aanname), niet de vijf uit
  Bens methode (onbekende / waar verstopt / wat lost het op / som / aanname).
- **De aannametabel staat ná de ladder,** met vooraf één zin over het lot. Michelle haakte af op de tabel
  vóór de ladder: twee begrippen erin (*substitutie*, *S*) kwamen pas later aan bod.
- **De andere namen staan in een uitklapper onderaan,** niet in stap 3. Michelle en Jeanne struikelden allebei
  over *"sommige boeken noemen T pretest-sensitisatie"* midden in de ladder.
- **De letters H/M, X, T, S staan rechtop.** De APA-lens adviseerde dat: het zijn namen van ontwerponderdelen,
  geen statistieken, en X en R zijn bij Campbell & Stanley ook rechtop. Elke letter heeft een vaste
  kleurstreep (kleurenblind-veilig nagemeten); de tekst zelf blijft inkt.
- **Decimaalteken is de punt** (taalgids 20-7). De andere speeltjes gebruiken soms de komma in hun tegeltekst.
- **H/M** is Bens notatie. De APA-lens waarschuwde dat het in een som op "H gedeeld door M" lijkt; de
  kleurstreep houdt het bij elkaar, en stap 3 zegt "twee letters, één stukje". Vraag aan Ben of dat genoeg is.

## Wat de testlezers zeiden, en wat er veranderde

- **Jeanne** (en los van haar de APA-lens): met deze getallen zijn **T en S allebei 2**. Wie bij stap 7 of 9
  T uitrekent, kreeg "Klopt." om de verkeerde reden. Nu zegt het nakijken: *"Klopt. Let op: T is hier toevallig
  óók 2."* En de uitwerking van stap 9 laat zien wat er gebeurt als nameting II 11 is (T 3, S 1).
- Jeanne: waar de 5 in stap 7 vandaan kwam stond nergens; nu staat er S + X = 2 + 3 = 5.
- Jeanne: bij een foute vinkjesmatrix stond alleen "2 van de 4 rijen kloppen"; nu staat er welke groepen.
- Jeanne: de Campbell-en-Stanley-alinea las als "wat je net leerde is fout". Nu zegt hij dat de rekenwijze
  klopt om S te vinden, en dat het om het toetsen gaat.
- Michelle: de trap hoort bij de ladder, niet erna. Nu kleurt hij per stap in.
- Michelle: stap 8 voelde als paniek ("waarom nog een keer?"). Nu staat erboven dat het een tweede weg naar
  hetzelfde getal is, die narekent of je goed zat.
- Niet veranderd: de voetregel *"De regressieve ruggengraat"* (Jeanne kende hem niet). Het is de vaste
  voetregel van alle speeltjes.

## Open vragen voor Ben

1. Titel: *design* of *ontwerp*?
2. H/M in de sommen: genoeg zo, of een ander teken?
3. De bron: mag het speeltje naar `countcamp_lab/boek/04_speeltjes/`, zodat het bouwscript het meeneemt?
4. Bens getallen laten T en S samenvallen (allebei 2). Het speeltje waarschuwt nu. Wil je voor de ladder
   liever getallen waarin ze verschillen, met de oefentoets alleen in stap 9?
