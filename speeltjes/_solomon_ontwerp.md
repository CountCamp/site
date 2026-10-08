# Het oordeel van Solomon — ontwerpnotitie (stuk 1, 1b en 1c, 8-10-2026)

**De titel** is sinds stuk 1c *Het oordeel van Solomon* (Ben bedoelde het salomonsoordeel: het zwaard dat eerlijk
verdeelt). Stuk 1b heette *Het zwaard van Solomon*; dat is ingetrokken. Het zwaardje als beeld in stap 7 blijft.

Speeltje: `speeltjes/solomon.html`. Eén zelfstandig HTML-bestand, geen internet nodig.
Tegel: `speeltjes/index.qmd`, rubriek *Ontleden*. Register: `~/Ben_OS_brain/shared_assets/speeltjes/SPEELTJES_REGISTER.md`.
Toets op de getallen: `_tools/tests/solomon_getallen_test.py` (zie *De getallen*).

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
