# Het oordeel van Solomon — ontwerpnotitie (stuk 1, 1b, 1c, 1d en 2, 8-10-2026; stuk 3, 23-11-2026)

**De titel** is sinds stuk 1c *Het oordeel van Solomon* (Ben bedoelde het salomonsoordeel: het zwaard dat eerlijk
verdeelt). Stuk 1b heette *Het zwaard van Solomon*; dat is ingetrokken. Het zwaardje als beeld in stap 7 blijft.

**De testlezers.** In de meeste rondes lazen twee Nederlandstalige testlezers mee, hier *testlezer A*
en *testlezer B*; per ronde staat erbij wie er las. A leest zoals een student die bang is voor het
tentamen: ze struikelt over beloften en over zinnen die elkaar tegenspreken. B haakt af bij dichte
tekst en lange routes, en leeft op bij korte winst. Daarnaast las *de Engelse lezer* de Engelse
versie; in de woordenlijst NL → EN bij *De Engelse tweeling* heet die *de testlezer*. Tot 24-11-2026
stonden hier de voornamen van A en B; die horen niet in een openbare repo.

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

Zes getypte getallen, alles verder uitgerekend: **sinds stuk 3 (23-11-2026)** voormeting I 48, II 52, nameting I 63,
II 55, III 60, IV 52. Daaruit: geleende voormeting 50, H/M = 2, T = 1, X = 8, S = 4; verbeteringen 15 / 3 / 10 / 2.
De stukjes en de verbeteringen zijn dezelfde als in stuk 1–2; alleen de voormetingen en de nametingen van I en II
veranderden (zie *Stuk 3*). Tot 23-11 stonden er voormeting I en II 50, nameting I 65 en II 53: ingetrokken.

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
| 1 Groep I: de hele som | verbetering I | 63 − 48 = 15, en dan 15 = H/M + X + T + S: totaal bekend, stukjes niet | nameting min voormeting |
| 2 Welke stukjes zitten in welke groep? | vinkjes groep × stukje | geen, de boekhouding | vanzelf beter overal; X waar therapie; T waar voormeting; S waar allebei |
| 3 Leen een voormeting | het startpunt van III en IV | (48 + 52) / 2 = 50; wie 48 of 52 invult krijgt te horen waarom die niet beter is dan de andere | het lot: gemiddeld gelijk begonnen |
| 4 Groep IV: H/M | H/M | 52 − 50 = 2, dan 15 = 2 + X + T + S | IV kreeg niets |
| 5 Groep III: X | X | (60 − 50) − 2 = 8, dan 15 = 2 + 8 + T + S | H/M ken je al |
| 6 Groep II: T | T | (55 − 52) − 2 = 1, dan 15 = 2 + 8 + 1 + S | II heeft een echte voormeting |
| 7 Groep I: S | S | 15 = 11 + S; S = 15 − 11; S = 4 | de lopende som: wat moet S zijn om op 15 te komen; **hier valt het zwaard** |
| 8 Verschil in verschil | (I − II) − (III − IV) | (15 − 3) − (10 − 2) = 4 | schrijf I − II uit in stukjes |
| 9 De proef op de som: de kale tabel | meerkeuze 0 / 1 / 4 / 8 / 12 / 15 (uitgerekend en gesorteerd) | stap 7 of 8; de som met alleen nametingen geeft (63 − 55) − (60 − 52) = 0 = S + (48 − 52) | elk fout antwoord is een vergeten stukje, of de som met alleen nametingen |
| 10 Toegift, regressie: de nameting | *b*₀ | nameting IV = 52 = startniveau + H/M; uitwerking: *b*₁ = 3 = T + (52 − 50), *b*₃ = 0 = S + (48 − 52) | groep IV houdt alleen *b*₀ over |
| 11 Toegift, regressie: de verbetering | *b*₃ | 15 − 2 − 1 − 8 = 4 | van onder naar boven, net als stap 10 |

(De getallen in deze tabel zijn die van stuk 3. Tot 23-11: 65 − 50 in stap 1, (50 + 50) / 2 in stap 3, (53 − 50) − 2
in stap 6, keuzes 1 / 4 / 8 / 12 / 13 / 15 in stap 9; ingetrokken.)

**Volgorde van stap 2 en 3.** Ben noemt lenen vóór de boekhouding; hier staat de boekhouding eerst, omdat die de
reden levert om bij IV te beginnen (*"alleen IV bevat alleen H/M"*), en IV levert dan de reden om te lenen (IV heeft
geen voormeting). Zo trekt elke stap de volgende aan. Het oude stapje *"Wie deed de voormeting?"* (aflezen) is in de
leen-stap opgegaan. De oude ladder (stuk 1b: aflezen, lenen, boekhouding, IV, III, II, I) is daarmee ingetrokken.
**Ben, 23-11-2026: "(2) volgorde zo"** — de boekhouding blijft vóór het lenen; de open vraag hierover is gesloten.

**De regressiestappen** (Bens toevoeging c; sinds 1c met de schakelaars voluit). *Y* = *b*₀ + *b*₁·voormeting +
*b*₂·therapie + *b*₃·(voormeting·therapie), met voormeting en therapie elk 0 of 1; de haakjes om het product sinds
stuk 3 (Ben, 23-11: *"haakjes erom"*), op alle drie de plekken tegelijk omdat het model één constante is (`MODEL`).
Stap 10 neemt de nameting als *Y*, en lost op zoals stap 4–7, van onder naar boven. *b*₀ = 52 = startniveau 50 + H/M 2
en *b*₂ = 8 = X, maar **sinds stuk 3 zijn *b*₁ en *b*₃ op de nameting niet T en S**: *b*₁ = 3 = T + (voormeting II −
geleende voormeting), *b*₃ = 0 = S + (voormeting I − voormeting II). De uitwerking rekent dat voor, en de trap van de
nameting tekent nu de gewichten (zie *Stuk 3*). Tot 23-11 stond hier *"b₂ = X, b₁ = T, b₃ = S (de interactie ís de
sensitisatie)"* voor de nameting; dat gold alleen bij gelijke voormetingen en is ingetrokken. Stap 11 neemt de
verbetering als *Y* (met de geleende voormeting): nu is *b*₀ = H/M en zijn *b*₁, *b*₂, *b*₃ weer T, X, S. Een kleine
APA-tabel zet het naast elkaar, sinds stuk 3 met een vierde kolom (*b*₁ en *b*₃ zijn T en S? nameting: nee (3 en 0);
verbetering: ja (1 en 4)). Op het speelbord rekenen beide regressies live mee met de schuifjes; bij ongelijke
voormetingen van I en II zegt een noot dat de regressie op de nameting dat verschil in *b*₁ en *b*₃ stopt (sinds
stuk 3 is dat de stand waarmee het speelbord opent). Bens
woord *startgetal* voor het intercept komt uit de Bib (`berekening-regressie-aapjes-slope-intercept-voorspellen`,
`auteur: Ben`: *"De b0 noem ik vanaf nu het startgetal of intercept"*); *startniveau* is zijn woord uit de briefing
van 8-10.

**De schakelaars in woorden** (Ben, 8-10: *"Bij regressie kunnen we toch ook experiment of manipulatie of therapie
uitgeschreven?"*). In stuk 1b heetten ze *V* en *X*, en die *X* botste met het stukje X van 8 punten (testlezers A en
B, allebei). Met woorden is er nog één X: het stukje. De woorden staan rechtop (namen van schakelaars, geen
symbolen), *b* en *Y* cursief, het product met Bens middenstip. Wat anderen doen (hulpagent, 8-10, 14 zoekvragen):
Field (2016) schrijft *Attractiveness*ᵢ = (*b*₀ + *b*₁Genderᵢ + *b*₂Alcoholᵢ + *b*₃Interactionᵢ) + εᵢ, de woorden
rechtop en het product als een benoemde variabele *Interaction*; OpenMenS (OU) schrijft *b*₄(exercise * coffee) en
elders 0.07 · IQ; Trochim en Statology alleen symbolen; Van Engelenburg (1999, Twente), de enige Solomon-specifieke
bron met sprekende letters, schrijft *b*<sub>T</sub>*T* + *b*<sub>P</sub>*P* + *b*<sub>TP</sub>*TP*. Niemand schrijft
*b*₃·voormeting·therapie met middenstippen tussen woorden; dat is dus onze eigen schrijfwijze, en Bens. *(Ingetrokken
23-11-2026 voor de vorm zonder haakjes: sinds Bens "haakjes erom" staat het model als *b*₃·(voormeting·therapie), zie
Stuk 3. OpenMenS schreef al haakjes om het product, b₄(exercise * coffee). De middenstippen tussen woorden blijven
onze schrijfwijze.)*

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
- **De aannametabel staat ná de ladder** en de andere namen staan in een uitklapper onderaan (stuk 1, na testlezers B en
  A).

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
van het zwaard; testlezer B las in 1c hetzelfde). In het Nederlands staat het jaartal niet in de eerste alinea; aan Ben
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
  betekent in een geheugencursus iets anders (de waarschuwing staat onderaan in *andere namen*, testlezer A wilde hem in 1c
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

## Stuk 3 — voormetingen 48 en 52, haakjes om het product (23-11-2026)

**Aanleiding.** Drie open vragen (hieronder 4, 5 en 6), op het bord beantwoord door Ben, 23-11-2026: *"(1)
voormetingen ongelijk, 48/52, zodat stap 3 het lenen echt leert; (2) volgorde zo; (3) haakjes erom"*. Zetter
`solomon_lenen`, op de tak `worktree-solomon_lenen`, vanaf 210a5ed. De oudere tak `worktree-solomon` (b7a91d1, stuk
2b) is niet gebruikt.

**Welke voormeting is 48.** Groep I en II hebben een voormeting. Gekozen: I = 48, II = 52, in Bens volgorde. De
stukjes bleven 2/8/1/4, dus nameting I = 48 + 15 = 63 en nameting II = 52 + 3 = 55 (teruggerekend zoals `maak()` het
doet; III en IV veranderden niet). De omgekeerde keuze (I = 52, II = 48) is nagerekend en afgewezen: dan geeft de som
met alleen nametingen (67 − 51) − (60 − 52) = 8, precies X, en kan stap 9 een student die de voormetingen oversloeg
niet meer onderscheiden van een die X vergat. Met 48/52 komt die som op 0, en 0 is geen som van stukjes. De keuze
staat als vraag voor Ben op het bord, met 48/52 als standaard.

**Wat 48/52 raakt — meer dan stap 3 en stap 9.** Ongelijke voormetingen veranderen niet alleen de weg met alleen nametingen (tot 23-11 hier "de weg zonder lenen"
genoemd; waarom die naam niet klopt, zie hieronder).
Alles wat op de nametingen rust zonder de voormetingen te gebruiken, krijgt het verschil tussen voormeting I en II
erbij:

| plek | met 50/50 | met 48/52 | wat er nu staat |
|---|---|---|---|
| stap 3 | (50 + 50) / 2 = 50, een som om niets | (48 + 52) / 2 = 50 | eigen terugmelding bij 48 of 52; *"het midden is je beste gok"* (Bens woorden, 8-10: *"dat gemiddelde uitrekenen als beste gok voor O0 van III en IV"*) |
| stap 9, som met alleen nametingen | (65 − 53) − (60 − 52) = 4 = S | (63 − 55) − (60 − 52) = 0 = S + (48 − 52) | voorgerekend waarom het 0 is; 0 is een keuze (vervangt X + T + S, zie hieronder) |
| stap 10, *b*₁ en *b*₃ op de nameting | 1 en 4: T en S | 3 en 0 | voorgerekend: *b*₁ = T + (52 − 50), *b*₃ = S + (48 − 52) |
| stap 10, de trap van de nameting | 50 + 2 + 8 + 1 + 4 = 65 = nameting I | zou op 65 eindigen, nameting I is 63 | tekent nu de gewichten: 52, +8, +3 (grijs), 0 (grijs, plat), eind 63 |
| stap 11, "de andere twee bleven wat ze waren" | waar | *b*₁ was 3, is nu 1 | uitgerekend; tabel met vierde kolom |
| uitklapper, hoofdeffect | (12 + 8) / 2 = 10, "in zo'n analyse" (op de nametingen) | op de nametingen (8 + 8) / 2 = 8 | een som op de nametingen: met voormeting 63 − 55 = 8, zonder 60 − 52 = 8, hoofdeffect (8 + 8) / 2 = 8 (sinds ronde 2 van C; tot dan *"met de verbeteringen (12 + 8) / 2 = 10"*, ingetrokken, zie *Ronde 2 van C*) |
| uitklapper, "de interactie daarin is S" | waar | 0 | "S plus het verschil tussen voormeting I en II: met deze getallen 0" |
| `duiding()`, wegen door de kale tabel | elke weg meet zijn stukjes | nameting I − nameting II = 8, en dat is niet X | een weg telt alleen mee als hij met deze getallen echt zijn stukjes meet |

**Wat het lenen wel en niet doet — de belangrijkste vondst.** De hulpagent die de literatuur las (zie hieronder) zag
het als eerste, en het is nagerekend: de geleende voormeting valt uit S en uit X altijd weg, want III en IV krijgen
dezelfde. Met 40, 50 of 70 als geleende voormeting blijft X = 8 en S = 4; alleen H/M (12, 2, −18) en T (−9, 1, 21)
schuiven. Wat S redt bij 48/52 is dus niet het lenen, maar dat I en II hun **eigen** voormeting aftrekken. Bens
premisse *"zodat stap 3 het lenen echt leert"* klopt voor stap 3 zelf en voor H/M en T; voor S heeft het lenen nooit
iets uitgemaakt. Daarom heet de weg die breekt op de bladzij **"alleen nametingen"** en niet "zonder lenen", zegt de
hint van stap 9 *"de voormetingen van I en II staan er wél: sla ze niet over"*, en zegt de uitwerking hardop: *"En de
geleende voormeting? Die valt uit S altijd weg ... Je had hem nodig voor H/M en T, niet voor S."* Die laatste zin is
van mij (C), niet uit de Bib.

**Keuze 13 eruit, 0 erin.** Stap 9 bood X + T + S = 13 aan omdat nameting I − nameting IV daar uitkwam (testlezer A, 8-10:
de natuurlijkste fout uit een kale tabel). Met 48/52 komt die weg op 11 uit, dus 13 had geen weg meer achter zich.
De som met alleen nametingen (0) is nu de natuurlijkste fout en staat ervoor in de plaats; de keuzes worden
uitgerekend en ontdubbeld. 11 staat er niet bij: wie nameting I − nameting IV rekent, vindt zijn getal niet en moet
opnieuw kijken.

**Een vijfde aanname, die er altijd al was.** De sommen met verbeteringen nemen aan dat een groep die vooraf een punt
hoger zat, achteraf ook precies een punt hoger zit (de helling van nameting op voormeting is 1). Bij 50/50 deed dat
er voor S niet toe; bij 48/52 is het precies het verschil tussen 4 (de sommen) en 0 (de nametingen). De getallen van
het speeltje zijn zo gemaakt (elke nameting is de eigen voormeting plus de stukjes), maar in echte data is de helling
meestal kleiner dan 1 (Senn, 2006, p. 4339: zij is in de praktijk de correlatie, dus kleiner dan 1). Daarom staat er
nu een vijfde rij in de aannametabel (het aantal in het bijschrift wordt geteld, niet getikt) en een alinea *"Welke
van de twee klopt?"* in de uitklapper over toetsen, met van Engelenburg (1999) in de voetregel. Dat is een toevoeging
die Ben niet vroeg; zonder haar zei de bladzij stilzwijgend dat de toets op de nametingen, die Campbell en Stanley
aanraden, fout is.

**Hoe de literatuur ongelijke voormetingen behandelt** (hulpagent, 23-11, ±60 zoekacties; per bron gezegd wat
zelf gelezen is en wat uit tweede hand komt):

- **Solomon (1949)** — artikel achter een betaalmuur; alleen uit tweede hand (de documentatie van het R-pakket
  `solomonR`, J. Uhalt): de voormeting van de groepen zonder voormeting is ½(a₁ + a₂) (p. 141), de interactie
  d₁ − (d₂ + d₃ − d₄) (p. 147, tabel V). Dat is Bens methode en die van het speeltje. Zijn eigen voormetingen
  verschilden ook (3.2 tegen 2.8; 5.4 tegen 6.0) en hij middelde toch; of hij gewogen middelde, valt uit zijn tabellen
  niet op te maken (bij 8 en 9 leerlingen geven beide 5.7). Zijn groepen waren niet geloot.
- **Campbell & Stanley (1963), p. 25** — zelf gelezen (gescand boek): *"The asymmetries of the design rule out the
  analysis of variance of gain scores. (Solomon's suggestions concerning these are judged unacceptable.) ... one can
  treat the posttest scores with a simple 2 × 2 analysis of variance design ... If the main and interactive effects of
  pretesting are negligible, it may be desirable to perform an analysis of covariance of O4 versus O2, pretest scores
  being the covariate."* Op dezelfde bladzij lenen ze zelf de voormetingen om history en maturation te schatten.
- **Braver & Braver (1988)** — artikel niet bereikbaar (403); uit tweede hand (Sawilowsky & Markman, ERIC ED316556):
  eerst een 2 × 2-variantieanalyse op de nametingen (test A); daarna onder meer een covariantieanalyse op groep 1 en 2
  met de voormeting als covariaat, en een meta-analytische combinatie. Hun toets op sensitisatie gebruikt alleen de
  nametingen en zou met de getallen van het speeltje S = 0 geven.
- **van Engelenburg (1999)** — zelf gelezen (ERIC ED435692): vergelijking 21 (p. 11) corrigeert de interactie op de
  nametingen voor het verschil in voormeting, met een geschatte helling; p. 16: *"since sampling fluctuations can play
  a role, it is advisable to correct for pre-experimental differences if possible."* Dat de sommen van het speeltje
  hetzelfde zijn met de helling vast op 1, staat niet bij hem: dat is een afleiding van de hulpagent (en klopt: met
  helling 1 geeft vgl. 21 precies 0 − (48 − 52) = 4).
- **Senn (2006)**, *Statistics in Medicine, 25*, 4334–4344 — zelf gelezen: de verschilscore is ΔY − ΔX, de
  covariantieanalyse ΔY − β̂ΔX, en β̂ is in de praktijk kleiner dan 1. (Het nummer van het tijdschrift, 24, is niet
  van de pdf zelf gehaald; nog na te kijken als hij ooit in een bronvermelding komt.)
- **Dimitrov & Rumrill (2003), p. 160** — opnieuw zelf gelezen: hun formule mist + D₄ (zie de tabel hierboven).

**Oordeel.** Het lenen zoals het speeltje het doet is Solomons eigen rekenwijze (volgens tweede hand), en Campbell en
Stanley lenen zelf ook voor H/M. Het is niet hoe de latere literatuur S toetst bij ongelijke voormetingen: die toetst
op de nametingen (en accepteert het verschil als toeval), of corrigeert met een geschatte helling. Dat staat nu op de
bladzij, in de uitklapper en in de aannametabel, niet in de ladder zelf.

**Ook in dit stuk, niet gevraagd:** op een echt scherm van 390 px was de bladzij 696 px breed, door de tabel *"wat er
per groep van het model overblijft"* in de uitwerking van stap 10, die niet in een schuifvak stond. Dat was al zo
vóór stuk 3 (op 210a5ed dezelfde 54 uitstekende elementen). Nu staat hij in een `.tabelvak`, net als de nieuwe tabel
van stap 11. Gemeten met de bladzij in een iframe van 390 px, want headless Chrome maakt een venster nooit smaller dan
500 px (`--window-size=390` gaf `innerWidth` 500); de schermafdrukken van eerdere stukken "op telefoonbreedte" waren
dus waarschijnlijk 500 px breed.

**De toetsen.** `solomon_getallen_test.py` eist nu ongelijke voormetingen (tot 23-11 eiste hij gelijke; ingetrokken)
en dat de som met alleen nametingen geen som van stukjes is; hij neemt paden als argument voor een mutatieproef.
Mutaties: de oude 50/50 → *"voormeting I en II zijn allebei 50"* en *"de som met alleen nametingen is 4, en dat is ook
S"*; 52/48 → *"is 8, en dat is ook X"*; allebei afloop 1. `solomon_figuren_test.py` leest de stand *de ladder* uit de
bladzij (hij stond er als [50, 50, 65, 53, 60, 52] getikt), noemt de stand met 50.5 nu *geleende voormeting 50.5*
(heette *ongelijke voormetingen*), en rekent bij elke trap na waar hij eindigt: nameting I voor de trap van de
nameting, verbetering I voor de andere, en op het speelbord bij elke stand. Mutatie: de oude trap van de nameting
terug → *"de trap eindigt op 65, moet 63 zijn"*, afloop 1 (en in de proefrun *wijdste bereik*, waar de voormetingen
0 en 100 zijn, *"eindigt op 150, moet 100 zijn"*: die trap loog daar al vóór stuk 3).

## Wat de testlezers zeiden in stuk 3, en wat er veranderde

Testlezers B en A lazen de gerenderde Nederlandse bladzij (alle uitklappers open, als tekst, plus schermafdrukken op
echte 390 px), een Engelstalige master-student (`general-purpose`-agent die de Nederlandse bladzij nooit zag) de
Engelse. Alle drie rekenden de getallen na en vonden geen fout. Ronde 1:

- **Testlezer A en de Engelse lezer, allebei: "Welke van de twee klopt?" liet ze onzeker achter.** Stap 9 zegt dat 0 fout
  is, de uitklapper dat Campbell en Stanley precies die toets aanraden. Testlezer A: *"het goede antwoord staat niet op
  deze bladzij"*; de Engelse lezer wilde één zin: hier is S door de constructie 4, met echte data doe je iets anders.
  Nu zegt de alinea eerst wat hier geldt (*"In dit speeltje de sommen, want de getallen zijn zo gemaakt"*), dan dat
  de ladder de boekhouding is en niet de toets, en dan wat je in echte data doet (2 × 2-variantieanalyse op de
  nametingen, of een covariantieanalyse op I en II).
- **Testlezer A: de bladzij sprak zichzelf tegen** (stap 9: *"rekent alsof I en II gelijk begonnen"*; uitklapper: *"de
  nametingen alleen nemen niets aan"*). Nu zegt de uitklapper ook dat de variantieanalyse op de nametingen rekent
  alsof I en II gelijk begonnen, en dat dat door het lot gemiddeld klopt.
- **Testlezer A: drie getallen voor het effect van de therapie (8, 10, 12)**, en de zin over het hoofdeffect als
  "alles hiervoor was fout". Nu zegt hij dat er met een interactie geen één getal meer is, en dat 10 een
  samenvatting van twee is, geen nieuw stukje. (De 10 zelf is in ronde 2 van C geschrapt; de zin *"geen nieuw stukje,
  alleen een samenvatting van twee"* bleef. Zie *Ronde 2 van C*.)
- **Testlezers B en A: *"S + (voormeting I − voormeting II)"* viel uit de lucht** (testlezer A: *"konijn uit een
  hoed"*). Stap 9 rekent het nu met getallen voor: een nameting is voormeting plus verbetering,
  (48 + 15) − (52 + 3) = (48 − 52) + (15 − 3) = −4 + 12, en (50 + 10) − (50 + 2) = 10 − 2, zodat je de 50 ziet
  wegvallen. Stap 10 rekent *b*₁ zo: (52 + 2 + 1) − (50 + 2) = (52 − 50) + 1.
- **Testlezer B: *"En de geleende voormeting? Die valt uit S altijd weg"* kon ze niet nakijken.** Die alinea is weg; de
  som van III en IV hierboven laat het zien, en één zin zegt waar je hem wél voor nodig had (H/M en T).
- **Testlezer B: in stap 10 kwam de uitleg vóór het plaatje.** Nu: de vier sommen, de trap, dan *b*₀, dan *b*₁ en *b*₃.
- **Testlezer B: bij "covariantieanalyse" in de aannametabel klapte ze dicht**, en *"meestal minder dan één"* zonder
  waarom. De rij zegt het nu met de eigen getallen (*"I en II begonnen 4 punten uit elkaar"*), met de reden
  (*"een deel van een verschil vooraf is toeval van die ene meting"*, regressie naar het midden); de vakterm staat
  alleen nog in de uitklapper.
- **Testlezer A en de Engelse lezer: *"zet de voormetingen gelijk"* liet S naar 0 springen** (de nametingen blijven staan,
  dus verbetering I wordt 13): testlezer A dacht het speeltje kapot te hebben gemaakt. Nu: *"schuif aan voormeting I of II:
  de regressie van de nameting verandert dan niet, want die kijkt niet naar de voormetingen; T en S in de sommen
  wel"*. Dat is de les van stap 10, zichtbaar gemaakt.
- **De Engelse lezer: *"the regression on the posttest"* maakt in het Engels de nameting tot voorspeller.** Dat geldt
  in het Nederlands ook (huisregel *regressie ván Y óp X*, TAALGIDS, *Richting*), en het stond al vóór stuk 3 op de
  bladzij. Nu overal *de regressie van de nameting* / *the regression with the posttest as outcome*; *op de
  nametingen* blijft alleen in *toets op de nametingen*, waar het geen regressierichting is.
- **Testlezer A: waarom niet 48 voor III, omdat III net als I de therapie kreeg?** Stap 3 zegt nu: de voormeting kwam vóór
  de therapie, dus de therapie kan niet bepalen waar iemand begon.
- **De Engelse lezer: wie via nameting I − nameting II op 8 kwam, las "dat is X (bijvoorbeeld nameting III −
  nameting IV)"**. `duiding()` voegt nu bij een weg die met deze getallen toevallig op een keuze uitkomt een eigen zin
  toe: *"Kwam je er via nameting I − nameting II, dan is dat toeval: daarin zit X + S, plus het verschil in
  voormeting."*
- **Alle drie: op 390 px stond in de tabel "wat er per groep van het model overblijft" alleen het rijtje nullen en
  enen in beeld**; de twee kolommen waar het om gaat stonden er rechts buiten. Op een smal scherm vallen de nullen en
  enen nu weg (ze staan al in de tabel boven de vraag), en de tabel staat iets kleiner; op 390 px past hij helemaal.
- **Engelse lezer, taal in tekst van dit stuk:** *"I started"* las als het voornaamwoord (nu *group I started*);
  *"random assignment put the groups together"* las als samenvoegen (nu *formed the groups*, ook op twee oudere
  plekken); *"sat one point higher"* (nu *scored one point higher at pretest*); *"swallows S"* (nu *cancels S out*).

**Ronde 2** (dezelfde drie lezers en de APA-lens, op de stand na ronde 1; hun uitslagen staan in het transcript van
de eerste zetter, niet in een bestand). Alle vier rekenden de nieuwe sommen na en vonden geen rekenfout. De Engelse
lezer vond twee problemen die ronde 1 zelf had gemaakt: de nieuwe zin in stap 3 en een *"They"* in stap 10 dat na het
verschuiven van de trap naar de figuur wees. Verwerkt door de tweede en derde zetter (23-11, `patch_r3.py`,
`patch_r4.py` in `.quarto/kladje_lenen/`):

- **Stap 3** (Engelse lezer): *"En niet 48 voor III omdat ..."* las ook als *"het is niet 48, en de reden is de
  therapie"*; Engels *"like I"* als *"zoals ik"*. Nu *"En geef III niet de 48 van groep I omdat ze allebei de therapie
  kregen: ..."*.
- **Stap 9 op 390 px** (testlezer B, testlezer A): precies de twee regels die het werk doen, *"(48 + 15) − (52 + 3)"* en
  *"(48 − 52) + (15 − 3)"*, vielen buiten beeld, omdat het label *"nameting I − nameting II"* zo breed was. Nu
  *"nameting I − II"* en *"nameting III − IV"*. De hint van stap 9 is een zin korter.
- **Stap 10** (Engelse lezer): *"Ze zien er iets anders uit"* wees naar de figuur; nu *"De sommen hierboven ..."*. Twee
  keer 52 (*b*₁ = 55 − 52 en verbetering II = 55 − 52, cijfer voor cijfer gelijk): nu één zin die het toeval noemt,
  alleen als voormeting II en *b*₀ gelijk zijn (uitgerekend met `gelijk()`).
- **Stap 10, *b*₃** (testlezer A: *"heb ik zelf moeten nagaan"*; testlezer B: *"het enige stuk dat daar nog in de oude stijl
  staat"*): *b*₃ kreeg een formule aangereikt, *"S + (voormeting I − voormeting II)"*, terwijl *b*₁ erboven uit de
  getallen werd opgebouwd. Nu net zo: nameting I is 48 + 2 + 1 + 8 + 4, *b*₀ en *b*₁ samen zijn nameting II, dus
  *b*₃ = (48 + 2 + 1 + 8 + 4) − (52 + 2 + 1 + 8) = (48 − 52) + 4 = 0, en *"H/M, T en X vallen weg"*. Deze vorm is
  van mij (C), niet uit de Bib; testlezer B stelde iets vergelijkbaars voor.
- **Speelbord, *"Probeer ook"*** (testlezer A: H/M schuift ook mee; testlezer B: *"de twee"* las als de twee rijen van de
  tabel): nu *"H/M, T en S in de sommen wel"*, en wat het eens wordt met wat: *"de som voor T hetzelfde als b₁ ...,
  en de som voor S hetzelfde als b₃: met deze nametingen 0"*, dat getal uitgerekend (`data-r="kaal"`).
- **Uitklapper** (testlezer A, Engelse lezer): *"of er een maken"* las niet als *"een S die er niet is"*; nu staat dat
  erbij. *"variantieanalyse op de nametingen"* naast *"de regressie van de nameting"* las als twee richtingen voor één
  ding; nu twee keer *"van"* (*toets op de nametingen* bleef, dat is geen regressierichting). Engels: *"In real data,
  the ladder is just the bookkeeping"*, *"use it to adjust the difference"*, *"is no longer a single number"*,
  *"the encore's regression with the posttest as outcome"*; in de aannamerij *"over and above what the pieces do"*
  en *"does not recur at posttest"*; stap 8 *"Here the letter I stands for"*.
- **APA-lens, ronde 2:** één fout, de bron van van Engelenburg noemde ERIC niet (nu *"(Research Report No. 99-06;
  ED435692). University of Twente, ...; ERIC."*); zweefteksten van de trap met *b*₀..*b*₃ in Unicode en met
  *"="*; *Van Engelenburg* met hoofdletter in Nederlandse lopende tekst zonder voornaam (Nederlandse spellingregel;
  de Engelse bladzij houdt *van*); harde spaties binnen *"(12 + 8)"* en rond *"2 × 2"*. Bewust niet veranderd: de
  bronnen op rol in plaats van op alfabet, en de cursieve geleende voormeting *"(50)"*.
- **Op smalle schermen** iets minder ruimte rond *"="* in de sommen (`.45em` → `.3em`), want de nieuwe som voor
  *b*₃ was op echte 390 px 6 px te breed. Gemeten met de bladzij in een iframe van 390 px (`smal.py`); de oudere
  lange sommen in stap 3 en stap 9 schuiven nog steeds, zoals vóór stuk 3.

**Een toets erbij: `solomon_sommen_test.py`.** De getallen in de sommen kwamen al uit de data, maar de vorm van een
som (*"(52 + 2 + 1) − (50 + 2)"*) is met de hand samengesteld, en tot nu toe rekenden alleen de lezers die na. De
toets opent beide bladzijden in headless Chrome en rekent in elke som elke regel na tegen de regel ervoor. Eerste
versie: 20 sommen, 86 regels. De nakijker zag dat hij de 9 lopende sommen van groep I (klasse `som lopend`) liet
liggen en 2 tabelkoppen uit de scripttekst als som telde; gerepareerd. Nu per taal 27 sommen, 112 regels, waarvan 61
alleen uit getallen bestaan en uitgerekend worden; de 51 met woorden, zoals *"startniveau + H/M"*, telt hij en slaat
hij over. Bijtproeven: een *"+ 1"* extra in de som voor *b*₁ geeft drie foutmeldingen, *S* + 1 in de lopende som geeft
*"S = 5 geeft 5, maar de regel ervoor (15 − 11) gaf 4"*; allebei afloop 1. Wat hij niet ziet: de sommen na het schuiven
op het speelbord.

**Ronde 3** (23-11, derde zetter; testlezers B en A op de Nederlandse tekst, een Engelse lezer, de APA-lens en een
nakijker, alle vijf op de stand na ronde 2). Geen van de vijf vond een rekenfout; de nakijker rekende alles na in R en
vond geen getikt getal in lezerstekst (Python-scan van alle tekenreeksen met cijfers, 20 per bladzij, allemaal
structureel, zoals *"1 is ja, 0 is nee"*). De nieuwe opbouw van *b*₃ landde bij alle drie de lezers (testlezer B: *"ik lees
hem niet, ik herken hem"*; testlezer A: *"op de tweede keer lezen"*). Verwerkt (`patch_r5.py`):

- **Een zin uit de tijd van 50/50** (Engelse lezer, nakijker): de opzet van stap 10 zei *"alleen heten de stukjes nu
  b"*, en twee schermen later is *b*₁ = 3 terwijl T = 1. Nu *"alleen heet wat je zoekt nu b"*. Ook de beschrijving
  bovenin (`<meta name="description">`) zei nog *"dezelfde sommen als regressie"*; nu *"dezelfde ladder"*.
- **Stap 3** (testlezer A, Engelse lezer): *"omdat ze allebei de therapie kregen"* las nog als de reden om het niet te doen.
  Nu *"En leen voor III niet de 48 van groep I, alleen omdat ze allebei de therapie kregen"*.
- **Stap 10:** de zin *"Het model weet alleen óf er een voormeting was, niet hoe hoog die was"* opent nu een eigen
  alinea (testlezer B: *"die staat begraven midden in de dichtste alinea"*). Bij *b*₃ staat de 52 bij naam, *"(voormeting
  II, H/M, T)"*, want testlezer A en de Engelse lezer lazen (52 + 2 + 1 + 8) als *b*₀ + *b*₁ + *b*₂, wat ook op 63 uitkomt.
  Het bijschrift zegt *"niet alleen T en S"* (testlezer A: *"niet"* was sterker dan de uitleg eronder).
- **Speelbord** (testlezer B: geen werkwoord; testlezer A en de Engelse lezer: wel het getal voor S, niet voor T): nu
  *"veranderen wel"* en *"met de nametingen van de ladder 3 en 0"*, allebei uitgerekend (`naB1`, `kaal`). *"Van de
  ladder"*, omdat die getallen bij het laden één keer worden gezet en niet meeschuiven (APA-lens).
- **Geen zin begint meer met een symbool** in de veranderde tekst (APA-lens, nakijker): *"Het gewicht b₂ is X"*,
  *"Hier is b₁ gelijk aan T"*, *"Dan vallen H/M, T en X weg"*. Harde spaties in de sommen in lopende tekst van stap 10
  (10 per taal).
- **Het object bij het hoofdeffect** (nakijker): *"het hoofdeffect van de therapie op de kwaliteit van leven"*.
- **Alleen Engels:** *"Note that"* (*"Mind you"* leidt een tegenwerping in), *"That is where you get stuck"*, *"Then the
  ladder is just the bookkeeping"* (twee zinnen achter elkaar begonnen met *"In real data"*), *"they are still 4 points
  apart"*, *"with these numbers, 0"*.
- **Commentaar uit de tijd van 50/50** (nakijker): *"(65 − 50)"*, de oude volgorde *"dan lenen, dan IV"*, en de
  paren *"b2 bij X, b1 bij T, b3 bij S"*, die op de nameting sinds 48/52 niet meer gelden.

**Ronde 2 van C: het hoofdeffect** (23-11, vierde zetter, tak `worktree-solomon_lenen`). Tot deze ronde stond het
hieronder bij *Niet veranderd, wel gemeld*: de uitklapper noemde *"(12 + 8) / 2 = 10"* het hoofdeffect *"met de
verbeteringen"*, maar een variantieanalyse van verbeteringen kun je in echte data niet draaien (III en IV hebben geen
verbetering per persoon, zegt dezelfde uitklapper; Campbell & Stanley, 1963, p. 25: *"The asymmetries of the design rule
out the analysis of variance of gain scores"*), en de variantieanalyse van de nametingen die de uitklapper aanraadt,
geeft (8 + 8) / 2 = 8. Wie het advies volgde, kreeg 8 en dacht een fout te hebben gemaakt. Besluit van C
(meesterknecht): niet laten staan; de 10 alleen houden met een duidelijk etiket, en zeggen dat de aangeraden analyse 8
geeft, uitgerekend en via de sommentoets, of de 10 schrappen als dat schoner is.

*Voor* (stand 0a2473d):

> Let wel: met een interactie heeft het effect van de therapie op de kwaliteit van leven geen één getal meer. Zonder
> voormeting is het 8, het gewicht *b*₂; met voormeting 12 (X + S). Een variantieanalyse noemt het gemiddelde van die
> twee het hoofdeffect van de therapie op de kwaliteit van leven, met de verbeteringen (12 + 8) / 2 = 10. Dat is geen
> nieuw stukje, alleen een samenvatting van twee.

*Na* (stand f76030b):

> Let wel: met een interactie heeft het effect van de therapie op de kwaliteit van leven niet meer één getal. Zonder
> voormeting is het 8 (X), met voormeting 12 (X + S). Toch kun je die twee samenvatten in één getal, het hoofdeffect
> van de therapie op de kwaliteit van leven: hun gemiddelde. Dat is geen nieuw stukje, alleen een samenvatting van
> twee.
>
> Met de sommen van dit speeltje is dat:
> hoofdeffect met de sommen = (12 + 8) / 2 = 10
>
> Die som kun je uitrekenen uit een tabel met gemiddelden, zoals Solomon deed. Campbell en Stanley vonden dat je hem
> niet met één variantieanalyse van de verbeteringen kunt toetsen, want III en IV hebben geen eigen voormeting;
> daarvoor is een omweg nodig.
>
> De variantieanalyse van de nametingen, de toets die ze wel aanraadden, toetst een ander getal. Die analyse rekent
> het effect van de therapie met voormeting alleen uit de nametingen, als nameting I − II, en het effect zonder
> voormeting als nameting III − IV:
> nameting I − II = 63 − 55 = 8
> nameting III − IV = 60 − 52 = 8
> hoofdeffect op de nametingen = (8 + 8) / 2 = 8
>
> Draai je die analyse, dan krijg je dus 8, en dan deed je niets fout. Alleen ziet die analyse voor het effect van de
> therapie met voormeting 8 en niet 12, want I begon 4 punten lager dan II (stap 9). Daardoor is haar hoofdeffect hier
> 8 en niet 10, en haar interactie 0 en niet 4: twee keer dezelfde vergissing.

(Op de bladzij staan de sommen uitgelijnd op "=", met één "=" per regel; hier zijn ze ingekort tot één regel. Elk
getal komt uit `GETALLEN`, ook "4 punten" en "stap 9". Bij gelijke voormetingen valt de slotzin na "niets fout" weg,
en zegt de zin ervoor "toetst hier hetzelfde getal".)

**Hoe het zo werd: vier keer bijgesteld, telkens door een lezer.**

1. **Geschrapt** (2ea9802). De reden was de klacht van testlezer A uit ronde 1 (*"8, 10 en 12"*): een vierde getal leek die
   klacht te herhalen. Twee lezers vielen daar los van elkaar over. De Engelse lezer: *"'The two' can only be 8 and
   12, so I work out 10 before I reach"* de som, en *"Here S really is 4, and 0 is the mistake"* tegen *"not a mistake
   on your part"*: *"I'm left asking whether the 8 is right or wrong"*. Testlezer A: *"Nu heb ik 10 in mijn hoofd en 8 op
   papier, en de tekst noemt mijn 10 nergens"*. De zin die de 10 bij de lezer laat ontstaan, *"het gemiddelde van die
   twee"*, kan niet weg zonder het begrip hoofdeffect weg te halen.
2. **Terug, als eigen som** (2fd2fdb), met het etiket *"Die som kun je in echte data niet maken"*. Dat bleek onwaar.
   De Engelse lezer en testlezer A zagen allebei dat je de 10 gewoon uit een tabel met gemiddelden haalt (15 − 3 = 12,
   60 − 52 = 8), zoals stap 9 en Solomon zelf doen.
3. **"Uitrekenen kan, maar niet toetsen"** (a1803bc). Ook dat was onwaar. De nakijker rekende het na in R: als contrast
   is de 10 te toetsen, want de geleende voormeting valt uit X weg. Zonder echt effect verwierp die toets in zijn
   simulatie .049 tot .051 van de keren (vier runs van 20000 herhalingen, *n* = 30 en 100 per groep), precies het
   niveau van .05.
4. **"Met één variantieanalyse toetsen kan niet, daarvoor heb je een omweg nodig, zoals de covariantieanalyse
   hierboven"** (1eb1df3). Weer te stellig, op twee punten (nakijker). Stap 11 is zelf één analyse van de
   verbeteringen. En de covariantieanalyse hierboven dekt alleen I tegen II, met een geschat gewicht dat volgens de
   uitklapper zelf meestal kleiner is dan 1, en komt dan niet op 10. Nu staat er alleen wat Campbell en Stanley
   (p. 25) uitsluiten: *"The asymmetries of the design rule out the analysis of variance of gain scores."*

Het patroon: elke keer dat ik de 10 een etiket gaf, schreef ik iets sterkers op dan klopte, en een lezer ving het.
Het eind is het smalste dat waar is, met de bron erbij.

**Verder in deze ronde:**

- **Etiketten.** De som van de analyse heet *"nameting I − II"*, *"nameting III − IV"* en *"hoofdeffect op de
  nametingen"*. In 2ea9802 stond er *"met voormeting = 8"*, vier regels onder *"met voormeting 12"* (testlezer A: *"zelfde
  etiket, twee getallen, in één adem"*; de Engelse lezer hetzelfde). De zin ervoor zegt *"toetst een ander getal"* en
  *"alleen uit de nametingen"*, zodat je weet dat er iets anders dan 12 komt (testlezer A zat er eerst negen regels mee).
- **"(X)" in plaats van "het gewicht *b*₂".** De 8 stond in *b*'s en de 12 in stukjes (testlezer A, Engelse lezer). Het
  verschil was ook inhoudelijk: in de regressie van de nameting, die volgens de alinea erboven deze variantieanalyse
  ís, is het effect met voormeting *b*₂ + *b*₃ = 8 + 0 = 8, niet 12.
- **De vaste alinea schrijft de 10 niet meer toe aan "een variantieanalyse"** (nakijker): *"Toch kun je die twee
  samenvatten"*.
- **Wie of wat.** *"die analyse"* (testlezer A las *"neemt ze"* eerst als Campbell en Stanley); *"de toets die ze wel
  aanraadden"* (eerst *"de nametingen die Campbell en Stanley aanraadden"*, dubbelzinnig); *"Die analyse rekent"*
  (anders twee keer *"ze"* voor twee dingen achter elkaar); *"lager dan II"* (nakijker); *"niet meer één getal"*
  (testlezer A las *"geen één"* als *"geen enkel"*); *"dan deed je niets fout"* (was *"rekende je goed"*: SPSS rekent,
  niet jij).
- **Het object, half.** *"het effect van de therapie met voormeting"* (nakijker: zonder *"van de therapie"* kon het
  als T lezen, het testeffect). *"op de kwaliteit van leven"* staat er bij die twee vermeldingen niet bij. **Bewuste
  afwijking** van de huisregel *het object staat er altijd bij*: het staat voluit in de eerste en de derde zin van de
  alinea, en elke vermelding daarna langer maken weegt in een alinea die testlezer A al vol vond.
- **Engels:** *"boils the two down to one number"*, *"a summary of the two"*, *"uses ... for"* (was *"takes ...
  from"*, dat als aftrekken leest), *"on this page"*, *"main effect from the calculations"*, *"8, not 12"* (was een
  vertaling van *"en niet"*), *"no pretest of their own"* (stap 11 geeft III en IV wél een verbetering, met de
  geleende voormeting), *"the test they did recommend"*.
- **Harde spaties.** *"(X + S)"* heeft er nu (APA-lens: hij kon over twee regels breken). In de nieuwe zinnen staan ze
  als `\u00a0` in de bron, zoals in de rest van het script. In 2ea9802 stond het teken zelf erin, en wie op `\u00a0`
  zoekt vindt ze dan niet (APA-lens).
- **De getallen en de toets.** Alle getallen komen uit `GETALLEN` (`echt` en `hoofd` in het blok na `var AFGELEID`),
  en `AFGELEID.hoofd` is weg. Beide sommen staan uitgelijnd, zodat `solomon_sommen_test.py` ze narekent: per taal 29
  sommen (was 27).
- **De sommentoets kijkt nu ook de route na** (c4c286f, 1eb1df3; voorstel van de nakijker). De oude 10 was namelijk
  wél uitgerekend en klopte als som, alleen langs de stukjes, (X + S + X) / 2, terwijl de zin hem *"een
  variantieanalyse"* noemde. *"Uitrekenen, niet tikken"* beschermde hier dus niet. Een som met een etiket uit `ROUTE`
  heeft nu een vaste uitkomst, uitgerekend uit de `GETALLEN` van de bladzij. Per taal lopen 15 sommen langs zo'n route,
  ook die van stap 9. De twee etiketten die stap 9 en de uitklapper delen, moeten in minstens twee sommen staan.
  Bijtproeven, alle afloop 1 tenzij anders gezegd:
  - de oude fout consistent nagebootst (*"(12 + 8) / 2"* en *"10"* onder *"hoofdeffect op de nametingen"*) geeft
    *"... maar langs de route van dat etiket, ((naI - naII) + (naIII - naIV)) / 2, is het 8"*;
  - de 10 fout (`echt` + 1) geeft *"hoofdeffect met de sommen = 11 geeft 11, maar de regel ervoor ((12 + 8) / 2) gaf
    10"*;
  - een koppelteken in het gedeelde etiket plus een foute som geeft *"in 1 som(men), moet in minstens 2"*;
  - het etiket weg geeft *"de routetoets keek dus niet"*;
  - `GETALLEN` zonder `naI` geeft afloop 3, *"kon niet kijken"* (was een crash met afloop 1).

  Wat de toets niet ziet: het minimum van twee staat vast. Komt er ooit een derde som met hetzelfde etiket bij, dan
  moet dat getal mee (nakijker).

**Wat de Bib zei** (`bib_query.sh hoofdeffect`): geen getagde items, 69 op inhoud. Het naaste dat van Ben zelf is
(auteur: Ben, bijles-transcript): hoofdeffecten horen bij de marginale gemiddelden, de rij- en kolomgemiddelden. Hier
zijn dat (63 + 60) / 2 = 61.5 met therapie en (55 + 52) / 2 = 53.5 zonder. Dat verschil van 8 is wat SPSS toont. Niet op
de bladzij gezet: het zijn twee getallen erbij in een slotzin die er al zeven heeft (Engelse lezer: *"I would not add
a sentence to the last line"*). De vorm *"het gemiddelde van het effect met en zonder voormeting"* (dezelfde 8, langs
de enkelvoudige effecten) is van C, niet uit de Bib, en sluit aan op de *"8 en 12"* van de zin ervoor. Ook
*"hoofdeffect met de sommen"*, *"op de nametingen"* en *"twee keer dezelfde vergissing"* zijn van C. Testlezer A en de
Engelse lezer zijn er twee keer overheen geweest.

**Lezers in deze ronde:** de Engelse lezer (drie keer), testlezer A (drie keer), de nakijker (drie keer) en de APA-lens
(twee keer; geen fout, twee twijfels, allebei verwerkt). Geen van hen vond een rekenfout.

**Niet veranderd, wel gemeld** (buiten deze opdracht, of een keuze voor Ben):

- **Ronde 2 van C, de openingsalinea van dezelfde uitklapper** (nakijker): *"Daar loop je vast, want groep III en IV
  hebben geen eigen voormeting, dus ook geen verbetering per persoon"*, bij de vraag hoe je S toetst. Voor S geldt
  hetzelfde als voor de 10: als contrast is S per persoon te toetsen, en bij even grote groepen is de regressie van
  stap 11, per persoon gedraaid, die toets al. Het is niet de gangbare route in de literatuur: Braver en Braver
  (1988) combineren een covariantieanalyse van I tegen II met een *t*-toets van III tegen IV, en Sawilowsky e.a.
  (1994) bekritiseren daarbij de kans op een onterechte verwerping. Die twee kent de nakijker uit zoekresultaten, hij
  heeft ze niet gelezen. Een keuze voor Ben.
- **Ronde 2 van C, Campbell en Stanley over Solomon** (nakijker, p. 25 zelf gelezen). Direct na het citaat over gain
  scores staat *"(Solomon's suggestions concerning these are judged unacceptable.)"*. De bladzij rekent met
  Solomons methode en zegt alleen dat Campbell en Stanley *"een andere weg aanraadden"*. Ook raden zij de
  covariantieanalyse van O4 tegen O2 alleen aan *"if the main and interactive effects of pretesting are negligible"*;
  in dit speeltje zijn ze dat niet (T = 1, S = 4).
- **Ronde 2 van C, de tentamenvraag van testlezer A:** *"SPSS → 8, tabel → 10 ... ik weet niet welke de docent wil."* Een
  didactische keuze voor Ben, geen zin om hier te repareren.
- **Ronde 2 van C, de toegift in SPSS** (Engelse lezer, met de hand afgeleid, niet in SPSS gedraaid). Met
  voormeting en therapie als 0/1 neemt SPSS UNIANOVA standaard de hoogste code als referentie. De schattingen worden
  dan 63, −3, −8 en 0, waar de toegift 52, 3, 8 en 0 geeft. Wie de toegift in SPSS naloopt, ziet andere tekens.
- **Ronde 2 van C, "twee keer dezelfde vergissing" kost niet twee keer evenveel** (nakijker, Engelse lezer): het
  hoofdeffect zakt 2, de interactie 4, omdat het hoofdeffect het verschil in voormeting maar half meeneemt. De
  bladzij zegt niet waarom. Niet toegevoegd: de slotzin heeft al zeven getallen.
- **Ronde 2 van C, waar de omweg uitkomt** (testlezer A: *"de enige zin in dit stuk zonder getal"*). Corrigeer je
  I − II met een geschatte helling *b*, dan is het hoofdeffect ((63 − 55) − *b*·(48 − 52) + (60 − 52)) / 2: 10 bij
  *b* = 1, 9.2 bij *b* = .6, 8 bij *b* = 0 (nakijker, in R). Niet gebouwd: dat is een nieuwe bewering die eerst
  langs de lezers moet.
- **Ronde 2 van C, sommen in een zin elders op de bladzij** (APA-lens; buiten deze alinea): het bijschrift met
  *"(X + S = 12)"* (gewone spaties, kan breken), de tabelcel *"(50 + 2 = 52)"* en *"S = 4"* in stap 9 (die twee met
  harde spaties).
- **Ronde 2 van C, de alinea "Welke van de twee klopt?" bij gelijke voormetingen** (nakijker, beredeneerd): *"Hier is
  S dus echt 4, en is 4 de vergissing"*. Dat kan niet voorkomen zolang `solomon_getallen_test.py` ongelijke
  voormetingen eist, maar de zin heeft zelf geen voorwaarde.
- **Ronde 3, een brug tussen de twee antwoorden** (Engelse lezer): noem de helling van nameting op voormeting *w*; dan
  is de gecorrigeerde interactie (63 − 55) + *w*·(52 − 48) − (60 − 52) = 4*w*. *w* = 1 geeft de 4 van de ladder, *w* = 0
  de 0 van de variantieanalyse van de nametingen, en *"meestal minder dan één"* legt echte data ertussen. Nagerekend,
  klopt; niet gebouwd, want het is nieuwe uitleg die eerst langs de lezers moet. Een idee voor Ben.
- **Ronde 3, de dubbele 52 en de dubbele 2 zijn één toeval** (Engelse lezer): *b*₁ = verbetering II zodra H/M de
  helft van het verschil in voormeting is, hier 2 = (52 − 48) / 2. Het volgt uit 48/52 en de stukjes 2/8/1/4; de
  bladzij noemt het nu. Wil Ben het weg, dan moeten de getallen veranderen, niet de tekst.
- **Ronde 3, de knop "Geen sensitisatie" op het speelbord geeft *b*₃ = −4** in de regressie van de nameting, en
  *"Alleen de tijd"* *b*₁ = 2 en *b*₃ = −4 (nakijker, in R). Klopt met 48/52, en de noot onder de tabel legt het uit,
  maar Ben zou het één keer moeten zien.
- **Ronde 3, de volgorde H/M, T, X, S** in de opbouw van *b*₃ wijkt af van H/M, X, T, S elders (testlezer B, testlezer A,
  nakijker). Met opzet: zo staan 2, 1, 8 aan beide kanten op dezelfde plek en zie je ze wegvallen. Testlezer B: *"laten
  staan"*; het staat nu hier, niet op de bladzij.
- **Ronde 3, kleiner:** de hint van stap 9 heeft nu een puntkomma, en dat is voor testlezer B een uitvalplek (in ronde 2
  was hij haar te lang); links van *"="* staat in de sommen twee keer zoveel ruimte als rechts (APA-lens, al zo vóór
  stuk 3); *"<voorAfstand> punten"* zou bij een verschil van 1 *"1 punten"* geven (nakijker; met 48/52 is het 4);
  `solomon_figuren_test.py` toetst zonder argument alleen de Nederlandse bladzij (nakijker; ik draaide hem met beide
  paden, afloop 0).
- **Ronde 3, het beeld van testlezer B:** in stap 9 twee staven naast die van stap 8, nu met nametingen: 8 en 8, niets steekt
  uit, en onder de I−II-staaf hangt een stuk van −4, zodat je ziet dat de 12 op een vloer vier lager begon. Niet
  gebouwd (een nieuwe figuur gaat eerst langs de beeldverteller).

- Testlezer B: stap 9 heeft als enige rekenstap geen figuur, en juist daar zit de kern. Haar voorstel: vier staven van
  voormeting naar nameting (I 48 → 63, II 52 → 55, III en IV 50 → 60 en 52); *alleen nametingen* is dan alleen naar
  de bovenkanten kijken, *verbetering* naar de lengtes. Niet gebouwd (een nieuwe figuur hoort eerst langs de
  beeldverteller); een idee voor Ben.
- Testlezer B: *"Je vergelijkt / Je neemt aan"* stopt na stap 7; in stap 10 had hij het punt gemaakt (*"je neemt aan:
  niets over waar II begon"*).
- Testlezer B en de Engelse lezer: lange sommen (stap 3, stap 9) lopen op 390 px het schuifvak uit zonder zichtbaar
  teken dat het vak schuift. Zo was het al vóór stuk 3.
- De Engelse lezer: drie keer 52 (voormeting II, nameting IV en *b*₀). Dat volgt uit 48/52 en de stukjes en is niet
  weg te kiezen; *b*₁ = (52 + 2 + 1) − (50 + 2) in stap 10 houdt ze nu uit elkaar.
- De Engelse lezer, oudere vertaalkeuzes uit stuk 2 die hij als on-Engels las: *sit* voor *zitten*, *take away*,
  *staircase*, *encore*, *bare table*, *substitution* (hij verwacht *imputation*), geen samentrekkingen; en twee
  inhoudelijke: *head start* (de voorzet van de twijfelaar bij S) betekent in het Engels juist een betere
  startpositie, en *"koning Salomo liet een zwaard halen om eerlijk te verdelen"* klopt niet met het verhaal (het
  zwaard was een list om de echte moeder te vinden).
- Testlezer A: onder de letter S in de ingevulde kaart staat klein *"de therapie werkte alleen dankzij de vragenlijst"*;
  haar oog koppelt dat aan de betekenis van S, terwijl het de twijfel is.

## Wat de testlezers en de APA-lens zeiden in stuk 1c, en wat er veranderde

Alle drie lazen de gerenderde bladzij met alle uitklappers open (`.quarto/kladje_solomon/dom1c.html`), testlezer A en de
lens ook de bron. Testlezer B las tot en met stap 10 zonder uit te vallen (stap 11 gokte ze goed), testlezer A liep nergens
weg, de lens rekende alle getallen na en vond er geen fout.

- **Alle drie, onafhankelijk: er stond kapotte tekst op de bladzij.** In de uitklapper *"hoe toets je of S echt van
  nul verschilt"* toonde de browser letterlijk *"en niet de X">8 van b₂"*. Oorzaak: `kl()` liep over de `innerHTML`
  van elke `.kl`-alinea en ving ook de X in het attribuut `data-r="X"`. Dat zat al in de proefdruk van 1b. Nu loopt
  de streep-pas alleen over tekstknopen (`createTreeWalker`), en de lens merkte terecht op dat dit een klasse was,
  geen incident: elke toekomstige attribuutwaarde met een losse X, T of S zou stil hetzelfde doen.
- **Testlezers B en A, allebei: de ruggengraat stond verstopt.** De lopende som stond alleen in de dichtgeklapte
  uitwerkingen; wie alles goed had en nooit een uitwerking opende, zag de som van groep I na stap 1 nooit meer, en
  de hint van stap 7 verwees er wél naar. Nu staat de stapel-tot-nu-toe zichtbaar in de trede, tussen de tabel en
  de vraag (*"Zo staat de som van groep I nu:"*), en toont de uitwerking alleen de vorige regel en de nieuwe
  (`lopend(k, van)`). Testlezer B sloeg de herhaalde bovenregels toch al over.
- **Testlezers B en A, allebei: de stukjes-tabel vóór de eerste vraag was een drempel.** Vier omschrijvingen zonder
  getal, nog voor er iets gerekend was; testlezer B zakte weg bij *"H voor wat er in de wereld gebeurt"*, testlezer A gleed
  eroverheen en moest bij de vinkjes terug. De tabel staat nu in stap 2, waar hij nodig is; stap 1 is alleen
  65 − 50 (testlezer B: *"in drie seconden goed, dus ik ben terug"*).
- **Testlezer B: het bijschrift zei "samen 15" en de lege trap liet geen 15 zien.** Het grijze totaalblok staat nu in
  elke trap, ook als hij nog niet af is, zodat je het gat ziet slinken; het verbindingslijntje komt pas bij de laatste
  trede.
- **Testlezer B: het vinkjesrooster liep I → IV en de boekhouding IV → I.** Testlezer A zag hetzelfde in stap 10 (de tabel
  met nullen en enen I → IV, *"wat het model zegt"* IV → I). Beide tabellen staan nu I → IV, net als elke andere
  tabel op de bladzij; *"van onder naar boven"* klopt dan letterlijk met de tabel.
- **Testlezer B: "Solomon" in de titel, "Salomo" in het bijschrift las als een tikfout**, en in het verhaal snijdt het
  zwaard juist niet. Het bijschrift noemt nu de twee naamgenoten (Richard Solomon bedacht het ontwerp, koning Salomo
  liet een zwaard halen). Dat het oordeel eigenlijk is dat de snede uitblijft, staat er niet; de titel is Bens keuze.
- **Testlezer A: "groep IV geeft b₀, groep III geeft b₂, groep II geeft b₁, en groep I geeft b₃" las als een tikfout**
  (0, 2, 1, 3). Er staat nu bij waarom de nummers de ladder kruisen: in het model staat voormeting vóór therapie,
  dus T kreeg *b*₁ en X *b*₂, terwijl de ladder eerst X vindt. Bens volgorde van het model is gehouden.
- **Testlezer A: "voormeting = 0" in de hint las als de score 0.** Nu: *"de schakelaar voormeting op 0"*. Haar grotere
  punt blijft staan: *voormeting* is in stap 10 een schakelaar (0/1), een score (50) én heet ook *startniveau*. De
  X-botsing is weg; een kleinere voormeting-botsing is ervoor in de plaats gekomen, en de zin die hem uitlegt staat
  er eerlijk bij.
- **Testlezer A en de lens: de tabelkop "therapie (X)" en het hokje "X" in de tijdlijn droegen nog een tweede X**, de
  gebeurtenis naast het stukje. De kop heet nu *therapie*, het hokje in de tijdlijn zegt *therapie*. De enige X op
  de bladzij is nu het stukje.
- **Testlezer A: "voormeting III en IV" als naam van één getal** las als "voormeting III, en IV". Nu heet dat getal
  overal *geleende voormeting*, en stap 3 zegt dat hardop.
- **Testlezer A: "want groep I kreeg alles" is een bewering, geen reden** waarom de vier optellen. Stap 1 zegt nu dat het
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
- **Niet veranderd, wel gemeld.** Testlezer B: stap 8 vraagt drie berekeningen voor één invulvak (bestond al). Testlezer B:
  bij de hint van stap 7 zou de zwaardbalk al drie sneden mogen hebben (2 | 8 | 1 | ?) zodat S van het plaatje te
  lezen is; nu is de balk vóór het antwoord één stuk, zoals Ben het zwaard vroeg. Testlezer A: de waarschuwing dat sommige
  boeken T *pretest-sensitisatie* noemen staat ná de ladder; testlezer B wilde hem in stuk 1 juist niet in de ladder.
  Testlezer A: *"15 − 2 − 8 − 1"* (stap 7, kaart) tegen *"15 − 2 − 1 − 8"* (stap 11, in *b*-volgorde).

## Wat de testlezers en de APA-lens zeiden in stuk 1b, en wat er veranderde

Alle drie lazen de gerenderde bladzij met alle uitklappers open (`.kladje/dom.html`), testlezer A en de lens ook de bron.

- **Testlezer B stopte na stap 9**, om twee aanwijsbare redenen: de titel *"Tot slot"* terwijl er nog twee treden
  volgden (*"een kers werkt alleen als ik weet dat de taart al af is"*), en de vraag naar *b*₃ in stap 10 direct
  na de formule (*"ik kan geen regressie uit mijn hoofd draaien"*) terwijl de zin die het slot eraf haalt —
  dezelfde vier sommen als stap 4–7 — pas in de uitwerking stond. Nu: stap 9 heet *De proef op de som: de kale
  tabel* en sluit af met *"Hiermee is de ladder af. Wat volgt is een toegift"*; de inleiding zegt *"Negen stapjes,
  en daarna een toegift van twee"* (geteld); stap 10 en 11 dragen *Toegift ·* in hun kop; de zin over dezelfde vier
  sommen staat vóór de vraag; en stap 10 vraagt nu het makkelijke (*b*₀ aflezen), stap 11 de ketting (*b*₃).
- **Testlezer B, de grootste verrassing: vier volgordes voor dezelfde vier stukjes.** Kolom *bevat* zei S + T + H/M + X
  (Bens eigen notatie uit zijn methode), de trap en het zwaard H/M, X, T, S, de som van stap 7 T, H/M, X, het
  zwaardbijschrift H/M, T, X, S (testlezer A en de APA-lens zagen die laatste ook). Nu staat overal de volgorde waarin
  de ladder ze vindt: H/M, X, T, S, ook in de sommen (*"verbetering I − H/M − X − T"*). **Dat wijkt af van Bens
  geschreven volgorde** S + T + H/M + X; de reden is dat de lezer de som op het plaatje moet kunnen leggen.
- **Testlezers B en A, allebei: *startgetal* naast *startniveau*.** Twee woorden die op elkaar lijken voor twee
  dingen (*b*₀ = 52 en de geleende voormeting 50). *Startgetal* (Bens Bib-woord voor het intercept) is van de
  bladzij; *startniveau* (zijn woord uit de briefing) blijft, met de omschrijving *"waar iedereen gemiddeld begon"*,
  en 50 + 2 = 52 staat nu als som onder elkaar, niet tussen komma's in proza.
- **Testlezer A en de APA-lens: de letter X deed twee dingen, en de kleurstreep stond onder de verkeerde.** *kl()*
  streept elke losse X; in het model stond de schakelaar X (0/1) dus met de streep van het stukje X (8 punten), en
  V zonder. De lens: in een model zijn *V* en *X* variabelen, dus cursief (huis-ijkpunt Hayes' ω = a(b₁ + b₃V),
  alles cursief); het stukje X blijft rechtop met zijn streep. Zo gedaan: *V* en *X* cursief in model, tabelkoppen
  en hint, zonder streep (een onzichtbare woordvoeger U+2060 achter de schakelaar-X houdt *kl()* tegen), en stap 10
  zegt het hardop: *"die schuine X is een schakelaar, niet het stukje X van 8 punten."*
- **Testlezer A: stap 9 beloofde de kale tabel en verwees terug naar de geleende voormeting**; hoe je S uit alleen de
  vier nametingen haalt stond nergens, en de natuurlijkste fout uit een kale tabel — nameting I − nameting IV = 13
  (= X + T + S) — zat niet bij de keuzes; 12 kan ook via nameting I − nameting II, wat de uitleg niet noemde. Nu:
  de uitwerking rekent (65 − 53) − (60 − 52) = 4 voor, met de reden waarom lenen daar wegvalt; 13 staat bij de
  keuzes; en `duiding()` noemt naast de vergeten stukjes ook elke rechttoe-rechtaan weg door de tabel die op dat
  getal uitkomt (uitgerekend uit een lijst van nameting-verschillen). Het toetsscript eist nu ook dat de twee
  echte voormetingen gelijk zijn, anders klopt die som niet. *(Ingetrokken in stuk 3, 23-11-2026: de voormetingen
  zijn nu 48 en 52, de uitwerking rekent voor waarom de som met alleen nametingen dan 0 geeft, en de toets eist het
  omgekeerde: ongelijke voormetingen. De lijst van nameting-verschillen telt een weg alleen nog mee als hij met deze
  getallen echt zijn stukjes meet.)*
- **Testlezer A: *"dezelfde vier sommen"* en dan andere sommen** (stap 5: (60 − 50) − 2; stap 10: 60 − 52). Nu staat
  erbij waarom: de 50 en de 2 zitten samen in *b*₀ = 52.
- **Testlezer A: *"factor"* zonder uitleg** in de uitklapper, en haar paniek-verrassing dat een echte tweeweg-analyse een
  hoofdeffect therapie van (12 + 8) / 2 = 10 geeft en geen 8. Allebei toegevoegd, de getallen uitgerekend. (Ingetrokken voor 48/52: dit gold bij 50/50.
  Sinds 48/52 geeft de tweeweganalyse van de nametingen (8 + 8) / 2 = 8; zie *Ronde 2 van C*.)
- **Testlezer B: stap 8 herhaalde de slotzin van stap 7** en had geen beeld. De herhaling is weg; er staat nu een
  figuurtje met twee balken (therapie mét voormeting 12, zonder 8; wat uitsteekt is S), en het woord *interactie*
  valt daar voor het eerst. *Sensitisatie* valt nu al in stap 3 (de stukjestabel) in plaats van pas in stap 9.
- **Testlezer B: stap 10 en 11 zonder beeld.** Stap 10 heeft nu de trap met de vloer op 50 (de eerste trede eindigt
  op 52: dat is *b*₀, en daarom zit H/M erin verstopt); stap 11 dezelfde trap met *b*₀, *b*₂, *b*₁, *b*₃ onder de
  treden. De tabel "wat het model per groep zegt" heeft de boekhouding van stap 3 ernaast, zodat de paren *b*₂–X,
  *b*₁–T, *b*₃–S te zien zijn.
- **Testlezer B: de som van stap 7 ging sneller dan zij** (15 − 1 − 2 − 8 → 4). Nu één aftrekking per regel.
- **De APA-lens, verder:** *b* in *"heten de stukjes nu b"* stond plat (nu cursief); H/M en de andere letters stonden
  kaal overal waar tekst niet door *kl()* ging (aannametabel, lege kaart naast de gestreepte ingevulde, "Hier en
  elders", speelbord-oordeel, "En in je eigen onderzoek?"): nu streept een `.kl`-pas ook de vaste tekst; het streepje
  "–" betekende in één tabel *niet gemeten* én *nee* (nu *nee*); de caption in gebiedende vorm is een naamwoordgroep
  geworden. Bewust niet veranderd: numerieke kolommen staan rechts uitgelijnd (de huisregel voor rapportagetabellen
  zegt centreren; hier zijn het hele getallen met tabular-nums), en de kolomkop *"H/M los te zien?"* blijft een
  vraag. De lens rekende alle getallen na en vond er geen fout; de middenstip als vermenigvuldigingsteken is in
  orde, × niet (APA reserveert dat voor 2 × 2).
- **Niet veranderd, wel gemeld.** Testlezer B leest de aannametabel niet en zakt weg in stap 3 (drie tabellen vóór het
  eerste vinkje); de kaart en de schuifjes, waar zij het liefst mee speelt, staan ná de treden die zij overslaat.
  Testlezer A opent de uitklapper *"andere namen"* niet uit zichzelf, dus de waarschuwing dat sommige boeken T
  pretest-sensitisatie noemen bereikt haar niet; midden in de ladder wil ze hem ook niet (stuk 1). Beide zijn
  ontwerpkeuzes voor Ben.

## Wat de testlezers zeiden in stuk 1, en wat er veranderde

- **Testlezer A** (en los van haar de APA-lens): met de getallen van 2015 waren T en S allebei 2. Nu zijn ze 1 en 4; de
  waarschuwing "T is hier toevallig óók …" staat nog in de code en gaat alleen af als ze weer samenvallen.
- Testlezer A: waar de 5 in stap 7 vandaan kwam stond nergens; nu staat er S + X = 4 + 8 = 12.
- Testlezer A: bij een foute vinkjesmatrix stond alleen "2 van de 4 rijen kloppen"; nu staat er welke groepen.
- Testlezer A: de Campbell-en-Stanley-alinea las als "wat je net leerde is fout". Nu zegt hij dat de rekenwijze klopt om
  S te vinden, dat het om het toetsen gaat, en dat de toets op de nametingen de regressie van stap 10 is.
- Testlezer B: de trap hoort bij de ladder, niet erna. Nu kleurt hij per stap in.
- Testlezer B: stap 8 voelde als paniek ("waarom nog een keer?"). Nu staat erboven dat het een tweede weg naar
  hetzelfde getal is, die narekent of je goed zat.
- Niet veranderd: de voetregel *"De regressieve ruggengraat"* (testlezer A kende hem niet). Het is de vaste voetregel van
  alle speeltjes.

## Open vragen voor Ben

1. De kaart: vier kolommen (opdracht, en in 1c bevestigd door de meesterknecht) of vijf (zijn methode)? Open sinds
   stuk 1; de bladzij heeft er vier.
2. ~~De volgorde slotvraag → regressie, of regressie → slotvraag?~~ Beslist in 1c (meesterknecht): ladder → slotvraag
   → regressie als aangekondigde toegift. Ingetrokken als open vraag.
3. De bron naar `countcamp_lab/boek/04_speeltjes/` en `KIST` in `bouw_speelkist.py`: perswerk.
4. ~~De volgorde van stap 2 en 3 (boekhouding vóór lenen)~~ Beslist door Ben, 23-11-2026: *"(2) volgorde zo"*.
   Ingetrokken als open vraag.
5. ~~De leen-stap valt met 50 en 50 niet te toetsen~~ Beslist door Ben, 23-11-2026: *"(1) voormetingen ongelijk,
   48/52, zodat stap 3 het lenen echt leert"*. Uitgevoerd in stuk 3; de oude stand ("nu wint stap 9") is ingetrokken.
6. ~~Haakjes om het product in het model?~~ Beslist door Ben, 23-11-2026: *"(3) haakjes erom"*. Uitgevoerd in stuk 3.
7. **Nieuw in stuk 3: welke voormeting is 48 en welke 52?** Gekozen I = 48, II = 52 (Bens volgorde, en met 52/48 valt
   de som met alleen nametingen op 8 = X). Staat als vraag met die standaard op het bord.
8. **Nieuw in stuk 3: de vijfde aanname en de alinea "Welke van de twee klopt?"** zijn een toevoeging die Ben niet
   vroeg, maar die de bladzij nodig had om waar te blijven (zie *Stuk 3*). Weghalen kan; dan zegt de bladzij
   stilzwijgend dat de som met verbeteringen de goede is en de toets op de nametingen de foute.
