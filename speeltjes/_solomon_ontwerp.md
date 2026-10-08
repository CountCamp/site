# Het oordeel van Solomon — ontwerpnotitie (stuk 1, 1b, 1c, 1d en 2, 8-10-2026)

**De titel** is sinds stuk 1c *Het oordeel van Solomon* (Ben bedoelde het salomonsoordeel: het zwaard dat eerlijk
verdeelt). Stuk 1b heette *Het zwaard van Solomon*; dat is ingetrokken. Het zwaardje als beeld in stap 7 blijft.

Speeltje: `speeltjes/solomon.html`. Eén zelfstandig HTML-bestand, geen internet nodig.
Proefdruk (sinds stuk 1): `QUARTO_PROFILE=spook quarto render` in de werkkopie, de kopie in `_site/` de drie
merktekens geven (`.quarto/kladje_solomon/spook1d.sh` doet beide), en dan
`bash ~/Documents/Ben_OS/tools/spook.sh zet solomon <werkkopie>/_site speeltjes/solomon.html`. De spooksite
(`~/spooksite`, poort 8788) serveert een rsync-kopie, geen koppeling naar `_site/`: zonder `zet` blijft de vorige
proefdruk staan terwijl `_site/` al nieuw is (zo stond stuk 1b er op 8-10 nog drie kwartier na de render van 1c).
Tegel: `speeltjes/index.qmd`, rubriek *Ontleden*. Register: `~/Ben_OS_brain/shared_assets/speeltjes/SPEELTJES_REGISTER.md`.
Toets op de getallen: `_tools/tests/solomon_getallen_test.py` (zie *De getallen*). Toets op de figuren (sinds stuk
1d): `_tools/tests/solomon_figuren_test.py`, headless Chrome, zie *Stuk 1d*.

**Let op, de bron.** Alle andere speeltjes hebben hun bron in `countcamp_lab/boek/04_speeltjes/`; deze kist
is een kopie (`_tools/bouw_speelkist.py`). Dit speeltje is gebouwd in de kist zelf, omdat de opdracht dat
vroeg en een zetter niet in `countcamp_lab` mag schrijven. `bouw_speelkist.py` meldt het daarom als
`ONBEKEND IN DE KIST`. Ben (8-10): het verhuizen is perswerk, niet zetterswerk. Wordt het geaccepteerd:
kopieer het naar `countcamp_lab/boek/04_speeltjes/solomon.html` en zet `"solomon.html": "solomon.html"` in `KIST`.

## Waar het op rust

Bens methode, in zijn woorden (30-9 en 6/8-10-2026, `BEN_SOLOMON_METHODE.md`): *"voor 3 en 4 voormeting deed
ik het gemiddelde van 1 en 2. dan S + T + H/M + X = 1Na − 1Voor. T + H/M = 2Na − 2Voor en zo voort en dan
van beneden naar boven."*

**De context is sinds stuk 1b een therapie die de kwaliteit van leven moet verbeteren** (Ben, 8-10: *"Maakt het
het verhaal makkelijker als we in stijgingen denken? dus therapie om QOL te verbeteren?"*). Score 0–100, hoger is
beter; verandering = nameting − voormeting = verbetering. In stuk 1 was het "een training en een toets"; dat was
mijn context, niet Bens, en hij is vervangen. De stukjes in de nieuwe context: H/M = wat vanzelf beter wordt
(tijd, herstel, rijping); T = wat de voormeting zelf doet; X = wat de therapie doet; S = de voormeting maakt de
therapie sterker of zwakker.

**Het speeltje staat op zichzelf** (Ben, 8-10: *"dat tentamen hoeft niet genoemd te worden hoor, wat we maken moet
op zichzelf staan"*; *"bib is altijd alleen maar inspiratie, nooit iets meer"*). Op de bladzij en de tegel staat dus
geen tentamen, geen jaartal, geen Bib-id. Alleen hier, voor de geschiedenis: stuk 1 gebruikte de getallen van
Bens oefentoets uit 2015 (Bib-item `opg-tent-leiden-mt-20151026-q39`, `auteur: Ben`): voormeting 8 en 8,
nameting 15 / 10 / 11 / 8. Daarin vielen T en S samen (allebei 2) en was H/M 0.

## De getallen

Zes getypte getallen, alles verder uitgerekend: voormeting I en II 50, nameting I 65, II 53, III 60, IV 52.
Daaruit: H/M = 2, T = 1, X = 8, S = 4; verbeteringen 15 / 3 / 10 / 2.

Ben stelde op 8-10 voor: H/M 2, T 1, X 6, S 3 (nametingen 62 / 53 / 58 / 52), met de opdracht *"if you find a
reason these numbers teach worse (e.g. a step where two pieces still coincide), pick better ones and say why."*
Nagerekend (`.kladje/getallen.py`, nu `_tools/tests/solomon_getallen_test.py`): met 2/1/6/3 vallen drie sommen
van stukjes samen:

| getal | is tegelijk | gevolg |
|---|---|---|
| 3 | S én H/M + T (de verbetering van groep II) | wie bij de slotvraag "verbetering II" kiest, heeft S goed om de verkeerde reden |
| 6 | X én H/M + T + S | "je haalde X eraf en vergat de rest" geeft hetzelfde getal als X zelf |
| 9 | X + S én H/M + T + X | twee verschillende vergissingen, één getal |

Met 2/1/8/4 — machten van twee — is elke som van stukjes een eigen getal: 1 tot en met 15 komen elk precies één
keer voor. Daardoor verraadt elk fout antwoord op de slotvraag precies welk stukje vergeten is, en kan de bladzij
dat uitrekenen in plaats van opschrijven (`duiding()` probeert alle vijftien sommen). Ben wilde H/M klein, T klein,
X groot, S ertussen; dat is zo gebleven. De toets draait op de bladzij zelf (leest `var GETALLEN` uit de HTML) en
zakt op Bens voorstel (mutatieproef gedaan op 8-10: afloopcode 1, de drie botsingen hierboven).

## Hoe anderen het doen

Door een hulpagent opgezocht in stuk 1 (21 zoekvragen, ±27 bladzijden gelezen).

| bron | wat goed is | wat minder is |
|---|---|---|
| Solomon (1949), *Psychological Bulletin, 46*(2) | Bens methode ís die van Solomon: de voormeting van III en IV is ½(a₁ + a₂), de interactie is d₁ − (d₂ + d₃ − d₄) | zijn groepen waren niet geloot |
| Campbell & Stanley (1963), pp. 24–25 | noemen T en S apart: *main effects of testing* en *interaction of testing and X* | wijzen Solomons rekenwijze af **als toets** en raden een 2×2-variantieanalyse op de nametingen aan |
| Dimitrov & Rumrill (2003), *Work, 20* | dezelfde stukjes per groep | hun interactieformule mist de term + D₄; zo staat het gedrukt (twee hulpagenten, 8-10, lazen het allebei zo) |
| Open Universiteit, *OpenMenS* hfst. 7 | de enige die Bens aanname hardop zegt: de voormeting van de andere groepen schatten uit de gemeten | nummert de groepen anders (hun 2 is onze III) |
| Roose (UGent), hfst. 8 | echt voorbeeld, lijngrafieken | gooit testeffect en sensitisatie op één hoop |

**Stuk 1b, de regressie** (tweede hulpagent, 8-10, 4–8 zoekvragen): hoe anderen een 2×2 als regressie met
interactie schrijven.

- Notatie: psychologieboeken schrijven *b* met *b*₀ als intercept (Field: *b*₀ + *b*₁Gender + *b*₂Alcohol +
  *b*₃Interaction; Williams & Newman 1982, de enige Solomon-specifieke regressiebron: Y = b0 + b1X1 + b2X2 + e, product
  als X1.X3). Webpagina's vaker β (Trochim, Xiang Ao). Het product staat als juxtapositie (AB, Z₁Z₂), met een
  punt, of als aparte variabele; **niemand schrijft A×B in de vergelijking**. Overgenomen: cursieve *b* met
  index, intercept *b*₀, product V·X met de middenstip (Bens eigen notatie in de briefing). Het ×-teken is in de
  taalgids gereserveerd voor interacties in lopende tekst; in de vergelijking volg ik de boeken.
- De interpretatietabel (Xiang Ao, 2017; UCLA OARC): celgemiddelden β₀, β₀+β₁, β₀+β₂, β₀+β₁+β₂+β₁₂, en
  *"the coefficient on the interaction term is actually the difference in difference"*. Dat is de tabel
  "Vul de nullen en enen in" in stap 10.
- Solomon als 2×2 op de nametingen: Williams & Newman (1982) noemen de interactie *pretest-treatment interaction*;
  García Pérez e.a. (1999, *Psicothema*) geven Braver & Bravers stroomschema: interactie significant → *efecto de
  sensibilización*. Een bron die de verandering als uitkomst neemt en zegt wat het intercept dan betekent, is
  niet gevonden (Dimitrov & Rumrill definiëren wel D₁–D₄ voor alle vier de groepen, maar zeggen niet hoe D₃ en D₄
  zonder voormeting berekend worden). Dat b₀ = H/M bij de verbetering en b₀ = startniveau + H/M bij de nameting
  is dus Bens eigen didactische vondst, en zo staat het in stap 10 en 11.
- Verrassingen van die zoekronde: Xiang Ao's vergelijking heeft geen intercept terwijl zijn tabel eronder met β₀
  begint; Trochim schrijft β in de formule en b3 in de tekst; de Cambridge CBU-wiki noemt de interactie op de
  nametingen een *time by treatment interaction* (er is daar geen tijdfactor); Williams & Newmans eigen voorbeeld
  heeft een interactie van precies 0.

Een interactief hulpmiddel voor dit ontwerp is niet gevonden (twee gerichte zoekrondes in stuk 1; dat bewijst niet
dat er geen bestaat).

## De ladder (sinds stuk 1c: Bens ruggengraat)

Ben, 8-10, hoe hij het altijd gaf: *"ik begon altijd zo dacht ik voor I: O1 − O0 = X + T + S + HM. En omdat de twee
metingen bekend zijn weten we ook hoeveel de effecten samen opgeteld zijn, maar alleen dit weet je niks
afzonderlijks. Om HM te krijgen moet je eerst dat gemiddelde uitrekenen als beste gok voor O0 van III en IV;
aangezien alleen IV alleen HM bevat, beginnen we daar. Enzovoort, en ik vulde ook gewoon langzaam telkens de eerste
formule verder in totdat S overbleef. En die rekenden we dan uit."*

Dat is sinds stuk 1c de ruggengraat. De som van groep I staat vooraan als de vraag; elke gevonden trede wordt erin
ingevuld (`lopend(k)` in de bron), recht onder de vorige regel, tot alleen S overblijft; dan valt het zwaard. De
treden heten in de bron op naam (`VOLGORDE`, `ST`), en elke verwijzing *"stap N"* in de tekst wordt uitgerekend
(`stap('leen')`), want in stuk 1b stonden zestien met de hand getikte stapnummers en die zouden nu allemaal liegen.

| stap | vraagt | de som | hint wijst naar |
|---|---|---|---|
| 1 Groep I: de hele som | verbetering I | 65 − 50 = 15, en dan 15 = H/M + X + T + S: totaal bekend, stukjes niet | nameting min voormeting |
| 2 Welke stukjes zitten in welke groep? | vinkjes groep × stukje | geen, de boekhouding | vanzelf beter overal; X waar therapie; T waar voormeting; S waar allebei |
| 3 Leen een voormeting | het startpunt van III en IV | (50 + 50) / 2 = 50 | het lot: gemiddeld gelijk begonnen |
| 4 Groep IV: H/M | H/M | 52 − 50 = 2, dan 15 = 2 + X + T + S | IV kreeg niets |
| 5 Groep III: X | X | (60 − 50) − 2 = 8, dan 15 = 2 + 8 + T + S | H/M ken je al |
| 6 Groep II: T | T | (53 − 50) − 2 = 1, dan 15 = 2 + 8 + 1 + S | II heeft een echte voormeting |
| 7 Groep I: S | S | 15 = 11 + S; S = 15 − 11; S = 4 | de lopende som: wat moet S zijn om op 15 te komen; **hier valt het zwaard** |
| 8 Verschil in verschil | (I − II) − (III − IV) | (15 − 3) − (10 − 2) = 4 | schrijf I − II uit in stukjes |
| 9 De proef op de som: de kale tabel | meerkeuze 1 / 4 / 8 / 12 / 13 / 15 (uitgerekend en gesorteerd) | stap 7 of 8 | elk fout antwoord is een vergeten stukje |
| 10 Toegift, regressie: de nameting | *b*₀ | nameting IV = 52 = startniveau + H/M | groep IV houdt alleen *b*₀ over |
| 11 Toegift, regressie: de verbetering | *b*₃ | 15 − 2 − 1 − 8 = 4 | van onder naar boven, net als stap 10 |

**Volgorde van stap 2 en 3.** Ben noemt lenen vóór de boekhouding; hier staat de boekhouding eerst, omdat die de
reden levert om bij IV te beginnen (*"alleen IV bevat alleen H/M"*), en IV levert dan de reden om te lenen (IV heeft
geen voormeting). Zo trekt elke stap de volgende aan. Het oude stapje *"Wie deed de voormeting?"* (aflezen) is in de
leen-stap opgegaan. De oude ladder (stuk 1b: aflezen, lenen, boekhouding, IV, III, II, I) is daarmee ingetrokken.

**De regressiestappen** (Bens toevoeging c; sinds 1c met de schakelaars voluit). *Y* = *b*₀ + *b*₁·voormeting +
*b*₂·therapie + *b*₃·voormeting·therapie, met voormeting en therapie elk 0 of 1. Stap 10 neemt de nameting als *Y*:
dezelfde vier sommen als stap 4–7, alleen heten de stukjes nu *b*; *b*₂ = X, *b*₁ = T, *b*₃ = S (de interactie ís de
sensitisatie), maar *b*₀ = 52 = startniveau 50 + H/M 2. Stap 11 neemt de verbetering als *Y* (met de geleende
voormeting): nu is *b*₀ = H/M, de rest blijft. Een kleine APA-tabel zet het naast elkaar (nameting: startniveau +
H/M, nee; verbetering: H/M, ja). Op het speelbord rekenen beide regressies live mee met de schuifjes; bij ongelijke
voormetingen van I en II zegt een noot dat de regressie op de nameting dat verschil in *b*₁ en *b*₃ stopt. Bens
woord *startgetal* voor het intercept komt uit de Bib (`berekening-regressie-aapjes-slope-intercept-voorspellen`,
`auteur: Ben`: *"De b0 noem ik vanaf nu het startgetal of intercept"*); *startniveau* is zijn woord uit de briefing
van 8-10.

**De schakelaars in woorden** (Ben, 8-10: *"Bij regressie kunnen we toch ook experiment of manipulatie of therapie
uitgeschreven?"*). In stuk 1b heetten ze *V* en *X*, en die *X* botste met het stukje X van 8 punten (Jeanne en
Michelle, allebei). Met woorden is er nog één X: het stukje. De woorden staan rechtop (namen van schakelaars, geen
symbolen), *b* en *Y* cursief, het product met Bens middenstip. Wat anderen doen (hulpagent, 8-10, 14 zoekvragen):
Field (2016) schrijft *Attractiveness*ᵢ = (*b*₀ + *b*₁Genderᵢ + *b*₂Alcoholᵢ + *b*₃Interactionᵢ) + εᵢ, de woorden
rechtop en het product als een benoemde variabele *Interaction*; OpenMenS (OU) schrijft *b*₄(exercise * coffee) en
elders 0.07 · IQ; Trochim en Statology alleen symbolen; Van Engelenburg (1999, Twente), de enige Solomon-specifieke
bron met sprekende letters, schrijft *b*<sub>T</sub>*T* + *b*<sub>P</sub>*P* + *b*<sub>TP</sub>*TP*. Niemand schrijft
*b*₃·voormeting·therapie met middenstippen tussen woorden; dat is dus onze eigen schrijfwijze, en Bens.

**De volgorde: slotvraag vóór de regressie.** Ben schreef "stap 9 wordt een gewone slotvraag" en "voeg de regressie
toe ná de oplossing van beneden naar boven". Beide passen in twee volgordes; gekozen is 9 = slotvraag (de proef op
de som van de handmethode, met de kale tabel), 10–11 = regressie als sluitstuk ("en dit was al die tijd een
regressie"). Het alternatief — regressie als 9–10, slotvraag als 11 — is een kleine verschuiving in `stappen`.
Wat de testlezers ervan vonden staat hieronder.

## Het zwaard

Ben (8-10): *"laten we een Solomon's zwaard … of iets leuks weer, zo'n iniminie dingetje wel leuk"*, *"moet wel
meerwaarde hebben, ik wil geen overkill."* Titel *Het zwaard van Solomon*, ondertitel *ontleed het ontwerp*. In stap
7 ligt de verbetering van groep I als één balk (15 punten, "nog in één stuk"); zodra het antwoord S goedgekeurd is,
krijgt de trede de klasse `gekliefd`: een zwaard uit vier lijnen (kling, pareerstang, greep, knop) zakt op de
eerste snede, drie dunne sneden tekenen zich, de vier stukken kleuren in en krijgen hun etiket (H/M 2, X 8, T 1,
S 4, dezelfde volgorde als de trap). Alleen CSS en SVG; `prefers-reduced-motion` zet de overgangen uit; in print
geen overgangen. Eén zin van omlijsting in het bijschrift: *"Salomo liet een zwaard halen om eerlijk te verdelen;
hier verdeelt het de verbetering van groep I in haar vier stukjes."* De woordspeling is bewust: het ontwerp is van
Richard L. Solomon (1949), het zwaard van koning Salomo.

Op de eerste proefdruk stond het zwaard op de laatste snede, dwars door het etiket "T 1" (T is het smalste stuk);
het staat nu op de eerste snede en leunt naar rechts boven X.

## Keuzes, en waarvan ze afwijken

- **Rust boven elke trede** (Ben, 8-10: *"echt meer witruimte boven een nieuwe trede, ik wil echt het gevoel krijgen
  dat iets klaar is, die rust wil ik zien"*): 130 px boven elke trede na de eerste, 48 px in print; de eerste trede
  volgt gewoon op de inleiding. Stapkop 20 px halfvet, de vraag 17 px.
- **Verbindingslijntjes in de trap zijn niet meer gestippeld** (huisstijl: dunne lijnen, geen stippellijnen). In
  stuk 1 stonden ze als `stroke-dasharray 2 3`.
- **De letters H/M, X, T, S staan rechtop**; *b* en *Y* cursief. De APA-lens van stuk 1 adviseerde rechtop voor de
  ontwerpletters; zie het APA-oordeel hieronder voor stuk 1b.
- **De letter X heeft in de regressie geen twee gezichten meer** (stuk 1c): de schakelaars heten voormeting en
  therapie, voluit. In stuk 1b was de schakelaar een cursieve *X* naast het rechtopstaande stukje X, met een
  onzichtbare woordvoeger (U+2060) om `kl()` tegen te houden; dat is weg. Ingetrokken: de keuze van 1b.
- **Eén "=" per regel, overal** (Ben, 8-10: *"Liefst vergelijkingen altijd onder elkaar en het liefst maar 1 = teken
  per regel … Niet doorbreien."*). Elke som op de bladzij, ook wat JavaScript maakt, staat onder elkaar met het
  =-teken in één kolom en de linkerkant herhaald; de ingevulde kaart heeft per cel twee regels (*H/M = 52 − 50* /
  *H/M = 2*). Getoetst met `~/Ben_OS_brain/shared_assets/html_tabellen/som_wacht.py` op de gerenderde DOM: 0
  treffers, en een mutatieproef (één doorgebreide som erin) geeft 1 treffer en afloopcode 1.
- **De namen staan in de eerste alinea** (Ben, 8-10: *"ook voor zoekmachines, maar ook dat mensen meteen zien wat
  ze zochten"*): Solomon-vier-groepen-ontwerp, history en maturation (H/M), de interventie (X), het testeffect
  (testing, T), de sensitisatie (pretest sensitization, S); dezelfde woorden in `<meta name="description">`. De
  Nederlandse naam: Ben schrijft zelf *"Solomon vier groepen ontwerp"* (Bib, `auteur: Ben`); Quené & Van den Bergh
  (UU) *Solomon-vier-groepen-ontwerp*, Roose (UGent) *Solomon vier-groepen-ontwerp*, de Open Universiteit *Solomon
  vier-groependesign* (hulpagent, 8-10). Gekozen: de UU-vorm, het dichtst bij Bens eigen woorden en bij *ontwerp*.
  *Testeffect* is in alle Nederlandse bronnen het woord; voor S gebruikt de OU-familie *voormetingsensitisatie*
  (staat nu in de uitklapper *andere namen*). De Bib heeft over H/M, T en S niets in Bens stem (`history`,
  `testeffect`, `sensitisatie`: AFWEZIG; `maturation`: 4 items, alle over een ander ontwerp of van Leiden), dus de
  omschrijvingen van de stukjes zijn van ons.
- **Presets op het speelbord worden teruggerekend uit de stukjes** (`maak()`), niet getypt: "Alleen de tijd" is H/M
  uit de ladder met T, X, S op 0, enzovoort. Verandert GETALLEN, dan veranderen ze mee.
- **De titel** volgt Ben (*zwaard*); in de tekst staat *ontwerp*, zijn eigen woord en de Germaans-Hollandse keuze.
- **De kaart** heeft de vier kolommen uit de opdracht (effect / groepen / som / aanname), niet de vijf uit Bens
  methode (onbekende / waar verstopt / wat lost het op / som / aanname). Open punt uit stuk 1, nog niet beantwoord.
- **Decimaalteken is de punt** (taalgids 20-7).
- **H/M** is Bens notatie; hij hield hem (8-10) met de kleurstreep en de zin "twee letters, één stukje".
- **De aannametabel staat ná de ladder** en de andere namen staan in een uitklapper onderaan (stuk 1, na Michelle en
  Jeanne).

## Stuk 1d — de trap met negatieve stukjes (8-10-2026)

**Aanleiding.** Ben, met de schuifjes op H/M = −1: de y-as hield op bij de onderkant van de balk en "−1" stond óp
het etiket "H/M" eronder. *"kan ook negatief zien, misschien langere y-as aan onderkant."* Zijn schermafdruk was
van stuk 1 (bijschrift "De verandering van groep I", gestippelde verbindingslijntjes); die lijntjes zijn sinds 1b
al doorgetrokken (`stroke-width:.8`, kleur `--vaag`). Het overlappen zat er in 1c nog wel in, en erger dan hij zag.

**Wat er veranderde, alles in `waterval()`** (die tekent de trap op het speelbord, de trap per stap in de ladder
en de twee regressieplaatjes):

- Zakt de trap onder nul (onder de vloer), dan loopt de as minstens één vak verder dan de laagste balk. Hangt er
  een getal onder een balk, dan loopt hij door tot dat getal 22 eenheden boven de onderkant van de as staat.
- De as tikt in hoogstens acht vakken (stappen 1, 2, 5, 10, 20, 25, 50, 100). Tot 1c tikte hij bij elk bereik
  boven 20 per 5: bij de stand met S = 300 liep de as van −200 tot 100, 61 getallen over elkaar. De ladder (bereik 15)
  houdt stap 2.
- De as schuift naar rechts als zijn getallen lang worden ("−200" raakte de astitel).
- Zou het getal van een balk op de nullijn vallen (een stijgende balk die vlak onder nul eindigt), dan staat het
  aan de andere kant van de balk. Het vraagteken van een nog onbekend stukje staat aan de kant zonder nullijn.
- *b*₀ in stap 10 stond midden in het verbindingslijntje (ook met de getallen van de ladder); hij staat er nu
  boven, en onder als H/M daalt.

**Wat bewust niet veranderde.** Het zwaard en de verschil-in-verschil-balken tekenen alleen de zes getypte
getallen, niet de schuifjes, en kunnen een negatief stukje niet laten zien: een balk die in vier delen valt heeft
geen negatief deel, en "wat uitsteekt is S" steekt bij een negatieve S niet uit. In plaats van ze om te bouwen
eist `solomon_getallen_test.py` nu dat elk stukje groter is dan 0, met die reden erbij. Dat was al een stille
aanname van de ladder (de knop *De voormeting maakt de therapie zwakker* draait S om).

**De toets.** `solomon_figuren_test.py` zet de schuifjes op dertien standen (elk stukje om de beurt negatief, twee
en vier tegelijk, alles nul, de grootste positieve en negatieve, het wijdste bereik, vlak onder nul, terug tot
nul) en tekent de ladder ook met vier andere getypte getallen. Hij meet met `getBoundingClientRect` tekst op
tekst, tekst op een balk of lijn, tekst buiten de figuur, een getal onder de as, en stippellijnen. De stukjes bij
elke stand rekent hij zelf na uit de zes schuifjes. Zeven mutaties (elke reparatie apart terug, plus gestippelde
lijntjes) laten hem alle zeven zakken; zonder het extra vak meldt hij letterlijk Bens geval: *getal '−1' staat
onder de as, bij de etiketten*. Wat hij niet ziet: kleur, contrast, en of een figuur iets zegt dat klopt.

## Stuk 2 — een eigen tegel op de voordeur, en de Engelse tweeling (8-10-2026)

**Aanleiding.** Ben, 8-10: *"ik vind die solomon zo leuk dat ik wil dat er een aparte tegel voor komt op de site. En
sterker nog, ik wil deze ook in het Engels."* En: *"moet er een menuutje in ook in de solomon? denk het wel."*

**De tegel** (`index.qmd`, in het `.cc-cards`-blok, klasse `.cc-card-solomon` in `styles.css` met dezelfde kleur als de
rubriek *Ontleden* in de speelkist): titel *Het oordeel van Solomon*, één zin wat je er doet, en `([in English](…))`
aan het eind, precies zoals de Tabellen-tegel zijn Engelse tweeling noemt. De speelkist-tegel houdt zijn plek en
kreeg hetzelfde `([in English](solomon-en.html))`; de speelkist telt nog dertien tegels (`bouw_speelkist.py` telt
het na en vond "Dertien" op beide plekken kloppen).

**De Engelse tweeling** `speeltjes/solomon-en.html`: dezelfde code, dezelfde zes getallen, alleen de lezerstekst
vertaald. De code-commentaren staan met opzet in het Nederlands, net als in de bron, zodat een diff van de twee
bestanden alleen vertaalde tekst laat zien (nagemeten: CSS gelijk, script-skelet zonder tekenreeksen 434 regels
gelijk, html-tags gelijk op de taalschakelaar, drie cursiveringen en `lang="nl"` na). Wie de code in de ene wijzigt,
wijzigt hem ook in de andere; `solomon_getallen_test.py` leest sindsdien beide bladzijden en eist dezelfde zes
getallen (mutatieproef: andere getallen in de Engelse → afloop 1).

Woordenlijst NL → EN, met de bron van de Engelse term:

| NL | EN | waarom |
|---|---|---|
| Solomon-vier-groepen-ontwerp | Solomon four-group design | Campbell & Stanley (1963), p. 24 |
| voormeting, nameting | pretest, posttest | APA-spelling zonder streepje |
| history en maturation (H/M), wat vanzelf beter wordt | history and maturation (H/M), what gets better by itself | C&S |
| testeffect (T) | testing effect (T) | C&S: *testing* |
| therapie, de interventie (X) | therapy, the treatment (X) | C&S: X |
| sensitisatie (S) | pretest sensitization (S); in de tabel *andere namen* ook *interaction of testing and treatment* | Lana (1959); C&S: *interaction of testing and X* |
| het lot (R) | random assignment (R) | "the lot" bestaat niet in deze betekenis |
| geleende voormeting | borrowed pretest | eigen term, net als in het Nederlands |
| substitutie | substitution | Bens woord; de testlezer zou *imputation* verwachten, maar dat is een ander begrip (schatten uit een model) |
| stukje | piece | |
| de som (van groep I) | the equation (for group I); "Welke som heb je nodig?" → "Which calculation do you need?" | testlezer: *sum* leest in het Engels als *totaal*, en 15 ís het totaal |
| de trap, trede | the staircase, bar | testlezer: *step* was al de trede van de ladder |
| toegift | encore | |
| uitwerking | worked solution | |
| Kijk na | Check | |
| verschil in verschil | difference in differences | de gangbare Engelse term |
| regressiegewicht | regression weight (één keer: *the regression coefficient*) | Bens woord; de testlezer kent *coefficient* |
| de schakelaars | the switches (één keer: *dummy variables, in textbook words*) | Bens beeld; de testlezer kent *dummy variables* |
| eraf halen | take away | testlezer: *take off* is Brits-informeel en leest voor een Amerikaan als *verwijderen* |
| afspraak | convention | testlezer: *agreement* vraagt *tussen wie* |
| Het oordeel van Solomon — ontleed het ontwerp | The judgement of Solomon — dissect the design | de opdracht |

Spelling: Brits met Oxford-*ize* (*judgement* uit de opdracht, *sensitization* uit de literatuur). Decimaalteken de punt,
cursieve *b* en *Y*, rechtop de letters H/M, X, T, S en de schakelaarwoorden, net als in het Nederlands.

**Eén bewuste afwijking van de Nederlandse tekst:** de eerste alinea noemt *Richard L. Solomon, 1949*. De Engelse
testlezer hield het ontwerp tot stap 7 voor een ontwerp van koning Salomo (de uitleg stond alleen in het bijschrift
van het zwaard; Michelle las in 1c hetzelfde). In het Nederlands staat het jaartal niet in de eerste alinea; aan Ben
of dat daar ook moet.

**De koppeling van de twee talen.** Opgezocht (Google Search Central, *Tell Google about localized versions of your
page*; W3C i18n, *Indicating the language of a link destination*): op elke versie dezelfde set
`<link rel="alternate" hreflang="…">` met volledige URL's, inclusief zichzelf, en `x-default` voor wie geen van de
talen spreekt; hier is dat de Nederlandse, de oorspronkelijke. Op de zichtbare schakelaar `hreflang` voor de taal van
de bestemming en `lang` op de linktekst. Overgenomen, plus een `canonical` zoals de Tabellen-bladzijden al hadden.
De schakelaar *NL · EN* staat in de kopregel naast de thema-knop; de eigen taal is geen link. Het huis had vóór
stuk 2 nergens `hreflang` (nagemeten met `command grep -rl hreflang`, buiten `_site`: alleen een meegeleverde
mermaid-bibliotheek). De Engelse bladzij linkt naar het Nederlandse boek met *(Dutch)* erbij en `lang="nl"` op de
titel; de terugknop zegt *Back to the toy box (in Dutch)*, want de speelkist is Nederlands.

**Het stappenmenu**, op beide bladzijden, volgens het patroon van 8-10 van een andere bladzij: op een scherm van
1300 px of breder een vaste lijst links van de tekst (210 px breed; de tekst van 860 px begint op 50% − 410 px, het
menu staat daar 18 px links van), op een smaller scherm een plakkende uitklapbalk *Stappen* bovenaan die dichtklapt
zodra je een stap kiest. De lijst wordt uit de treden zelf gevuld (`menuHTML()` leest `stappen`), dus een hernoemde
of verschoven trede staat meteen goed; eromheen de vaste delen (ontwerp, ladder, aannames, kaart, speelbord, eigen
onderzoek) en *naar boven*. Vloeiend scrollen met `prefers-reduced-motion` gerespecteerd, `scroll-margin-top` op de
treden en de koppen, verborgen in print. De id's van de treden (`stap-1` …) bestonden al op de `<section>`; de
`scroll-margin` staat daar, niet op de `<h3>`.

**Wat de Engelse testlezer zei** (een Engelstalige master-student psychologie die de Nederlandse bladzij nooit zag;
`general-purpose`-agent, las de gerenderde DOM met alle uitklappers open), en wat er veranderde:

- *Sum* leest als *totaal* — en 15 is het totaal. Overal *equation* / *calculation* (zie de woordenlijst).
- *An agreement, not a measurement*: "tussen wie?" Nu *convention*.
- *Twice the effect of the therapy* las als "dubbel"; ze zocht een 16. Nu *taken two times, once with and once without
  a pretest*.
- *Only: group IV has no pretest* is geen Engels; nu *But group IV …*. *Did no pretest* → *had no pretest*, *did the
  pretest* → *took the pretest*, *divides over* → *into*, *the way you meet it in a paper* → *find*, *Pull on the
  numbers yourself* → *Play with the numbers yourself*, *The numbers cross the ladder for a moment* → *The subscripts
  do not follow the order of the ladder*, *it also works without, with the sum of step 8 but with posttests* → *the
  calculation of step 8, but with posttests instead of improvements*.
- *Switches* zonder *dummy variables*, *weight* zonder *coefficient*: elk één keer genoemd, Bens woorden blijven.
- *The sensitization* met lidwoord klonk als iets wat iemand overkwam; nu *pretest sensitization*.
- *Step* betekende twee dingen (trede van de ladder én trede van de trap); de trap heeft nu *bars*.
- De titel: tot stap 7 dacht ze aan koning Salomo. Zie de afwijking hierboven.
- *Back to the toy box* zonder dat je weet dat de kist Nederlands is; nu *(in Dutch)* erbij.
- **Niet veranderd, wel gemeld:** *Nine steps, and then an encore of two* tegen *Step 1 of 11* (ook zo in het
  Nederlands); *Every group got better* terwijl III en IV een streepje hebben (lost op in stap 3; ook zo in het
  Nederlands); *H/M* leest als een deling (Ben hield hem in 1b); *substitution* (Bens woord); de tabeltitel *Mean
  quality of life per group* blijft staan als de tabel kolommen bijkrijgt (ook in het Nederlands); *testing effect*
  betekent in een geheugencursus iets anders (de waarschuwing staat onderaan in *andere namen*, Jeanne wilde hem in 1c
  niet midden in de ladder); de regel over het hoofdeffect in de laatste uitklapper is voor een SPSS-student de
  nuttigste zin van de bladzij en staat op de plek waar ze al gestopt was.
- Ze rekende twintig getallen na en vond er geen fout; haar twee examenzinnen over sensitisatie klopten.

**Wat de APA-lens zei** (`apa`-agent, dezelfde DOM-dump plus de bron):

- **Strikt, en verholpen in beide talen:** de voetregel is als geheel cursief (`.foot{font-style:italic}`), dus het
  cursief van *Psychological Bulletin, 46* en van de boektitel was onzichtbaar; een bronvermelding is een voorbeeld dat
  iemand overneemt. De twee bronregels staan nu rechtop in een `<span class="ref">`. Dezelfde regel staat in alle
  andere speeltjes van de kist; die zijn niet van dit spoor (zie verrassingen in het verslag).
- Alle getallen nagerekend, geen fout; 92 echte mintekens, nul koppeltekens tussen cijfers; geen decimale komma's;
  cursief van *b* en *Y* in tekst, tabel en SVG in orde; de bronvermeldingen kloppen met Crossref en Open Library.
- Smaak, al in 1b besloten en niet veranderd: geen tabel- en figuurnummers, getalkolommen rechts, de cursieve
  tabeltitel met *b*₀ erin, de cursieve geleende voormeting, de cursieve terugmelding.
- Buiten haar bril: *judgement* (Brits) naast *sensitization* (Oxford/Amerikaans) — zie de spellingkeuze hierboven.

**De =-wacht op de Engelse tekst.** `som_wacht.py` kent alleen Nederlandse voegwoorden (*en, of, maar, want, met,
dan*) en gevolgwoorden (*dus, daarom, zodat*). Op de Engelse bladzij beet hij daardoor op *with a pretest (X + S = 12)
and without (X = 8)* — twee losse feiten die in het Nederlands door *en* gescheiden worden en in het Engels niet. Het
bijschrift gebruikt nu komma's, die hij wel als grens leest. De andere kant is ernstiger: een Engelse ketting met *so*
of *therefore* ziet hij niet. Gemeld als verrassing; de wacht is van het huis, niet van dit spoor.

## Wat de testlezers en de APA-lens zeiden in stuk 1c, en wat er veranderde

Alle drie lazen de gerenderde bladzij met alle uitklappers open (`.quarto/kladje_solomon/dom1c.html`), Jeanne en de
lens ook de bron. Michelle las tot en met stap 10 zonder uit te vallen (stap 11 gokte ze goed), Jeanne liep nergens
weg, de lens rekende alle getallen na en vond er geen fout.

- **Alle drie, onafhankelijk: er stond kapotte tekst op de bladzij.** In de uitklapper *"hoe toets je of S echt van
  nul verschilt"* toonde de browser letterlijk *"en niet de X">8 van b₂"*. Oorzaak: `kl()` liep over de `innerHTML`
  van elke `.kl`-alinea en ving ook de X in het attribuut `data-r="X"`. Dat zat al in de proefdruk van 1b. Nu loopt
  de streep-pas alleen over tekstknopen (`createTreeWalker`), en de lens merkte terecht op dat dit een klasse was,
  geen incident: elke toekomstige attribuutwaarde met een losse X, T of S zou stil hetzelfde doen.
- **Michelle en Jeanne, allebei: de ruggengraat stond verstopt.** De lopende som stond alleen in de dichtgeklapte
  uitwerkingen; wie alles goed had en nooit een uitwerking opende, zag de som van groep I na stap 1 nooit meer, en
  de hint van stap 7 verwees er wél naar. Nu staat de stapel-tot-nu-toe zichtbaar in de trede, tussen de tabel en
  de vraag (*"Zo staat de som van groep I nu:"*), en toont de uitwerking alleen de vorige regel en de nieuwe
  (`lopend(k, van)`). Michelle sloeg de herhaalde bovenregels toch al over.
- **Michelle en Jeanne, allebei: de stukjes-tabel vóór de eerste vraag was een drempel.** Vier omschrijvingen zonder
  getal, nog voor er iets gerekend was; Michelle zakte weg bij *"H voor wat er in de wereld gebeurt"*, Jeanne gleed
  eroverheen en moest bij de vinkjes terug. De tabel staat nu in stap 2, waar hij nodig is; stap 1 is alleen
  65 − 50 (Michelle: *"in drie seconden goed, dus ik ben terug"*).
- **Michelle: het bijschrift zei "samen 15" en de lege trap liet geen 15 zien.** Het grijze totaalblok staat nu in
  elke trap, ook als hij nog niet af is, zodat je het gat ziet slinken; het verbindingslijntje komt pas bij de laatste
  trede.
- **Michelle: het vinkjesrooster liep I → IV en de boekhouding IV → I.** Jeanne zag hetzelfde in stap 10 (de tabel
  met nullen en enen I → IV, *"wat het model zegt"* IV → I). Beide tabellen staan nu I → IV, net als elke andere
  tabel op de bladzij; *"van onder naar boven"* klopt dan letterlijk met de tabel.
- **Michelle: "Solomon" in de titel, "Salomo" in het bijschrift las als een tikfout**, en in het verhaal snijdt het
  zwaard juist niet. Het bijschrift noemt nu de twee naamgenoten (Richard Solomon bedacht het ontwerp, koning Salomo
  liet een zwaard halen). Dat het oordeel eigenlijk is dat de snede uitblijft, staat er niet; de titel is Bens keuze.
- **Jeanne: "groep IV geeft b₀, groep III geeft b₂, groep II geeft b₁, en groep I geeft b₃" las als een tikfout**
  (0, 2, 1, 3). Er staat nu bij waarom de nummers de ladder kruisen: in het model staat voormeting vóór therapie,
  dus T kreeg *b*₁ en X *b*₂, terwijl de ladder eerst X vindt. Bens volgorde van het model is gehouden.
- **Jeanne: "voormeting = 0" in de hint las als de score 0.** Nu: *"de schakelaar voormeting op 0"*. Haar grotere
  punt blijft staan: *voormeting* is in stap 10 een schakelaar (0/1), een score (50) én heet ook *startniveau*. De
  X-botsing is weg; een kleinere voormeting-botsing is ervoor in de plaats gekomen, en de zin die hem uitlegt staat
  er eerlijk bij.
- **Jeanne en de lens: de tabelkop "therapie (X)" en het hokje "X" in de tijdlijn droegen nog een tweede X**, de
  gebeurtenis naast het stukje. De kop heet nu *therapie*, het hokje in de tijdlijn zegt *therapie*. De enige X op
  de bladzij is nu het stukje.
- **Jeanne: "voormeting III en IV" als naam van één getal** las als "voormeting III, en IV". Nu heet dat getal
  overal *geleende voormeting*, en stap 3 zegt dat hardop.
- **Jeanne: "want groep I kreeg alles" is een bewering, geen reden** waarom de vier optellen. Stap 1 zegt nu dat het
  een afspraak is: wat er in groep I overblijft als je de andere drie eraf haalt, noem je S.
- **De lens: de zwaard-etiketten "T 1" lazen als T1, een meetmoment.** Nu *T = 1*, net als het bijschrift; het eerste
  etiket begint bij de linkerrand, weg van het zwaard. En: een streepje in een tabel zonder noot (de kale tabel van
  stap 9 *"zoals je hem in een artikel tegenkomt"*); elke tabel zonder geleende voormeting draagt nu *"Een streepje:
  die groep deed geen voormeting."*
- **De lens over de woorden in het model: rechtop is goed** (APA 7 §6.44 cursiveert letters als symbool, geen
  woorden; ISO 80000-2 zet meerletterige namen rechtop), de middenstip is goed en consequent, cursief bij de
  introductie en daarna rechtop is APA 7 §6.22. Haakjes om het product zijn geen regel; een keuze voor Ben. Een
  getal links van het =-teken in de lopende som mag en is hier juist, zolang de keten omdraait zodra S wordt
  opgelost; dat doet hij. Bewust niet veranderd: getalkolommen rechts in plaats van gecentreerd (al in 1b besloten),
  tabellen zonder nummer (huisconventie in de speeltjes), en de stip in plaats van × als naam van de interactieterm
  (één teken over de hele bladzij).
- **Niet veranderd, wel gemeld.** Michelle: stap 8 vraagt drie berekeningen voor één invulvak (bestond al). Michelle:
  bij de hint van stap 7 zou de zwaardbalk al drie sneden mogen hebben (2 | 8 | 1 | ?) zodat S van het plaatje te
  lezen is; nu is de balk vóór het antwoord één stuk, zoals Ben het zwaard vroeg. Jeanne: de waarschuwing dat sommige
  boeken T *pretest-sensitisatie* noemen staat ná de ladder; Michelle wilde hem in stuk 1 juist niet in de ladder.
  Jeanne: *"15 − 2 − 8 − 1"* (stap 7, kaart) tegen *"15 − 2 − 1 − 8"* (stap 11, in *b*-volgorde).

## Wat de testlezers en de APA-lens zeiden in stuk 1b, en wat er veranderde

Alle drie lazen de gerenderde bladzij met alle uitklappers open (`.kladje/dom.html`), Jeanne en de lens ook de bron.

- **Michelle stopte na stap 9**, om twee aanwijsbare redenen: de titel *"Tot slot"* terwijl er nog twee treden
  volgden (*"een kers werkt alleen als ik weet dat de taart al af is"*), en de vraag naar *b*₃ in stap 10 direct
  na de formule (*"ik kan geen regressie uit mijn hoofd draaien"*) terwijl de zin die het slot eraf haalt —
  dezelfde vier sommen als stap 4–7 — pas in de uitwerking stond. Nu: stap 9 heet *De proef op de som: de kale
  tabel* en sluit af met *"Hiermee is de ladder af. Wat volgt is een toegift"*; de inleiding zegt *"Negen stapjes,
  en daarna een toegift van twee"* (geteld); stap 10 en 11 dragen *Toegift ·* in hun kop; de zin over dezelfde vier
  sommen staat vóór de vraag; en stap 10 vraagt nu het makkelijke (*b*₀ aflezen), stap 11 de ketting (*b*₃).
- **Michelle, de grootste verrassing: vier volgordes voor dezelfde vier stukjes.** Kolom *bevat* zei S + T + H/M + X
  (Bens eigen notatie uit zijn methode), de trap en het zwaard H/M, X, T, S, de som van stap 7 T, H/M, X, het
  zwaardbijschrift H/M, T, X, S (Jeanne en de APA-lens zagen die laatste ook). Nu staat overal de volgorde waarin
  de ladder ze vindt: H/M, X, T, S, ook in de sommen (*"verbetering I − H/M − X − T"*). **Dat wijkt af van Bens
  geschreven volgorde** S + T + H/M + X; de reden is dat de lezer de som op het plaatje moet kunnen leggen.
- **Michelle en Jeanne, allebei: *startgetal* naast *startniveau*.** Twee woorden die op elkaar lijken voor twee
  dingen (*b*₀ = 52 en de geleende voormeting 50). *Startgetal* (Bens Bib-woord voor het intercept) is van de
  bladzij; *startniveau* (zijn woord uit de briefing) blijft, met de omschrijving *"waar iedereen gemiddeld begon"*,
  en 50 + 2 = 52 staat nu als som onder elkaar, niet tussen komma's in proza.
- **Jeanne en de APA-lens: de letter X deed twee dingen, en de kleurstreep stond onder de verkeerde.** *kl()*
  streept elke losse X; in het model stond de schakelaar X (0/1) dus met de streep van het stukje X (8 punten), en
  V zonder. De lens: in een model zijn *V* en *X* variabelen, dus cursief (huis-ijkpunt Hayes' ω = a(b₁ + b₃V),
  alles cursief); het stukje X blijft rechtop met zijn streep. Zo gedaan: *V* en *X* cursief in model, tabelkoppen
  en hint, zonder streep (een onzichtbare woordvoeger U+2060 achter de schakelaar-X houdt *kl()* tegen), en stap 10
  zegt het hardop: *"die schuine X is een schakelaar, niet het stukje X van 8 punten."*
- **Jeanne: stap 9 beloofde de kale tabel en verwees terug naar de geleende voormeting**; hoe je S uit alleen de
  vier nametingen haalt stond nergens, en de natuurlijkste fout uit een kale tabel — nameting I − nameting IV = 13
  (= X + T + S) — zat niet bij de keuzes; 12 kan ook via nameting I − nameting II, wat de uitleg niet noemde. Nu:
  de uitwerking rekent (65 − 53) − (60 − 52) = 4 voor, met de reden waarom lenen daar wegvalt; 13 staat bij de
  keuzes; en `duiding()` noemt naast de vergeten stukjes ook elke rechttoe-rechtaan weg door de tabel die op dat
  getal uitkomt (uitgerekend uit een lijst van nameting-verschillen). Het toetsscript eist nu ook dat de twee
  echte voormetingen gelijk zijn, anders klopt die som niet.
- **Jeanne: *"dezelfde vier sommen"* en dan andere sommen** (stap 5: (60 − 50) − 2; stap 10: 60 − 52). Nu staat
  erbij waarom: de 50 en de 2 zitten samen in *b*₀ = 52.
- **Jeanne: *"factor"* zonder uitleg** in de uitklapper, en haar paniek-verrassing dat een echte tweeweg-analyse een
  hoofdeffect therapie van (12 + 8) / 2 = 10 geeft en geen 8. Allebei toegevoegd, de getallen uitgerekend.
- **Michelle: stap 8 herhaalde de slotzin van stap 7** en had geen beeld. De herhaling is weg; er staat nu een
  figuurtje met twee balken (therapie mét voormeting 12, zonder 8; wat uitsteekt is S), en het woord *interactie*
  valt daar voor het eerst. *Sensitisatie* valt nu al in stap 3 (de stukjestabel) in plaats van pas in stap 9.
- **Michelle: stap 10 en 11 zonder beeld.** Stap 10 heeft nu de trap met de vloer op 50 (de eerste trede eindigt
  op 52: dat is *b*₀, en daarom zit H/M erin verstopt); stap 11 dezelfde trap met *b*₀, *b*₂, *b*₁, *b*₃ onder de
  treden. De tabel "wat het model per groep zegt" heeft de boekhouding van stap 3 ernaast, zodat de paren *b*₂–X,
  *b*₁–T, *b*₃–S te zien zijn.
- **Michelle: de som van stap 7 ging sneller dan zij** (15 − 1 − 2 − 8 → 4). Nu één aftrekking per regel.
- **De APA-lens, verder:** *b* in *"heten de stukjes nu b"* stond plat (nu cursief); H/M en de andere letters stonden
  kaal overal waar tekst niet door *kl()* ging (aannametabel, lege kaart naast de gestreepte ingevulde, "Hier en
  elders", speelbord-oordeel, "En in je eigen onderzoek?"): nu streept een `.kl`-pas ook de vaste tekst; het streepje
  "–" betekende in één tabel *niet gemeten* én *nee* (nu *nee*); de caption in gebiedende vorm is een naamwoordgroep
  geworden. Bewust niet veranderd: numerieke kolommen staan rechts uitgelijnd (de huisregel voor rapportagetabellen
  zegt centreren; hier zijn het hele getallen met tabular-nums), en de kolomkop *"H/M los te zien?"* blijft een
  vraag. De lens rekende alle getallen na en vond er geen fout; de middenstip als vermenigvuldigingsteken is in
  orde, × niet (APA reserveert dat voor 2 × 2).
- **Niet veranderd, wel gemeld.** Michelle leest de aannametabel niet en zakt weg in stap 3 (drie tabellen vóór het
  eerste vinkje); de kaart en de schuifjes, waar zij het liefst mee speelt, staan ná de treden die zij overslaat.
  Jeanne opent de uitklapper *"andere namen"* niet uit zichzelf, dus de waarschuwing dat sommige boeken T
  pretest-sensitisatie noemen bereikt haar niet; midden in de ladder wil ze hem ook niet (stuk 1). Beide zijn
  ontwerpkeuzes voor Ben.

## Wat de testlezers zeiden in stuk 1, en wat er veranderde

- **Jeanne** (en los van haar de APA-lens): met de getallen van 2015 waren T en S allebei 2. Nu zijn ze 1 en 4; de
  waarschuwing "T is hier toevallig óók …" staat nog in de code en gaat alleen af als ze weer samenvallen.
- Jeanne: waar de 5 in stap 7 vandaan kwam stond nergens; nu staat er S + X = 4 + 8 = 12.
- Jeanne: bij een foute vinkjesmatrix stond alleen "2 van de 4 rijen kloppen"; nu staat er welke groepen.
- Jeanne: de Campbell-en-Stanley-alinea las als "wat je net leerde is fout". Nu zegt hij dat de rekenwijze klopt om
  S te vinden, dat het om het toetsen gaat, en dat de toets op de nametingen de regressie van stap 10 is.
- Michelle: de trap hoort bij de ladder, niet erna. Nu kleurt hij per stap in.
- Michelle: stap 8 voelde als paniek ("waarom nog een keer?"). Nu staat erboven dat het een tweede weg naar
  hetzelfde getal is, die narekent of je goed zat.
- Niet veranderd: de voetregel *"De regressieve ruggengraat"* (Jeanne kende hem niet). Het is de vaste voetregel van
  alle speeltjes.

## Open vragen voor Ben

1. De kaart: vier kolommen (opdracht, en in 1c bevestigd door de meesterknecht) of vijf (zijn methode)? Open sinds
   stuk 1; de bladzij heeft er vier.
2. ~~De volgorde slotvraag → regressie, of regressie → slotvraag?~~ Beslist in 1c (meesterknecht): ladder → slotvraag
   → regressie als aangekondigde toegift. Ingetrokken als open vraag.
3. De bron naar `countcamp_lab/boek/04_speeltjes/` en `KIST` in `bouw_speelkist.py`: perswerk.
4. De volgorde van stap 2 en 3 (boekhouding vóór lenen) wijkt af van Bens eigen volgorde (lenen eerst); zie *De
   ladder*. Als hij zijn volgorde wil, is het één verwisseling in `VOLGORDE`.
5. **De leen-stap valt met 50 en 50 niet te toetsen** (Michelle én Jeanne, 1c): het gemiddelde van 50 en 50 is 50,
   of je nu middelt of overschrijft, dus "(50 + 50) / 2 = 50" ziet eruit als een som om niets. Ongelijke voormetingen
   (bijvoorbeeld 48 en 52) zouden het lenen echt laten zien, maar dan klopt de weg zonder lenen in stap 9 niet meer
   (dat eist `solomon_getallen_test.py` ook). Twee goede dingen die elkaar bijten; aan Ben welke wint. Nu wint stap 9.
6. Haakjes om het product in het model, *b*₃·(voormeting·therapie)? De lens: geen regel, een keuze; het is één
   constante (`MODEL`), dus hij geldt dan meteen op alle drie de plekken.
