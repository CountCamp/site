# De getallen van de diamantjes — hoe ze gekoppeld blijven

**Aanleiding (Ben, 9-8-2026):** het gemiddelde karaat was 1,00, en dat is
didactisch onhandig — centreren wordt dan aftrekken van 1, wat je niet ziet
gebeuren. Alle karaatwaarden zijn met **0,6** opgehoogd. Daarmee is *M* = 1,60 en
wordt de ruwe intercept **negatief**: een steen van nul karaat zou negatieve glans
hebben. Geen adres waar niemand woont, maar een adres dat niet bestaat.

Bij die keuze hoorde een tweede vraag: *"dat raakt wel heel veel, dus hier ook
iets moois voor bedenken dat alles, ook in tekst, gekoppeld blijft."* Dat is dit.

## Hoe het werkt

1. **`genereer_diamantjes.R`** maakt `diamantjes.csv`. Dit zijn Bens eigen getallen
   uit Boekie, geen simulatie.
2. **`getallen_register.R`** berekent élk getal dat in de tekst geciteerd wordt —
   gemiddelden, hellingen, intercepts, *r*, *R*², *p*, en de karaat en glans van
   alle twaalf steentjes — en schrijft ze weg als `getallen_register.tsv`, met een
   naam en waar het getal voor dient. **Nooit overtikken: wie een getal nodig
   heeft, haalt het hier.**
3. **`boek/_tools/getallen_kaart.py`** zoekt elk registergetal op in Boekie, de
   drie broertjes en het GGZ-VS-werkboek, en laat zien wáár het terugkomt:

   ```
   python3 _tools/getallen_kaart.py
   ```

   Hij zoekt op alle schrijfwijzen (punt en komma, nul tot twee decimalen, *p* op
   drie) en eist context: een 0,5 telt alleen als de regel ook over karaat gaat.
   Anders is elke alinea een treffer.

4. **Verandert de dataset**, dan bewaar je het oude register en draai je:

   ```
   cp getallen_register.tsv getallen_register_oud.tsv    # vóór de wijziging
   python3 _tools/getallen_kaart.py --oud .../getallen_register_oud.tsv
   ```

   Dat vergelijkt beide registers, houdt alleen de getallen over die écht
   veranderd zijn, en toont per stuk elke regel in elk bestand die nog naar de
   oude werkelijkheid verwijst. **Die lijst is af als hij leeg is.**

## Waarom niet automatisch vervangen

Omdat het stuk gaat. Op één regel in H1 staat *"Voor Kees: 1,5 − 1,0 = 0,5"* —
daar is 1,5 een karaat, 1,0 het gemiddelde en 0,5 een **afwijking**. Een blinde
vervanging maakt van die 0,5 een karaatwaarde en niemand die het merkt. De kaart
wijst de regels aan; het oordeel blijft mensenwerk.

Prettige bijvangst van deze wijziging: alle afwijkingen blijven exact gelijk,
want een verschuiving verandert niet hoe ver iets van het gemiddelde ligt. Dus
*SD*, *r*, *R*², *p*, alle hellingen en de hele som-van-kwadraten-berekening in H1
blijven staan zoals ze stonden. Alleen het gemiddelde en de intercepts schuiven.

## Stand 9-8-2026

De dataset **is** omgehoogd; de tekst nog **niet**. `--oud` meldt op dit moment
15 getallen op 141 regels, verspreid over H1, H4, H6, H8, H9, H11 en H12 van
Boekie en de drie broertjes. Zolang die lijst niet leeg is: **niet publiceren**.
