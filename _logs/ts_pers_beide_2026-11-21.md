# Spoor `ts_pers_beide`: de Nederlandse en Engelse TS-pers samen, met de taalparen terug

*21-11-2026, tak `worktree-ts_pers_beide` in `countcamp_site`, vertrokken van `4f280ce` (nagemeten
bij de start: `git log -1 --format=%h` gaf `4f280ce`). Lab-main stond op `243a2508`, gemeten door
beide persen zelf (*"tak: main   commit: 243a2508"*, *"achter op origin/main: 0"*). Niets
gepusht, niets gepubliceerd.*

## In het kort

- **Nederlands: klaar om te mergen.** `_werk/naar_site.sh` gaf afloop **0**. Daarna waren knopje,
  hreflang en taalbalk weg op alle 9 Nederlandse TS-bladzijden met een Engelse tweeling.
  `taalonderdelen.py los` heeft ze teruggezet (0 gaten). Ik heb het in **één commit** gezet,
  `1f2ee19`, zodat er geen commit in de geschiedenis staat met kapotte paren. Daarna gaven
  `publiceer_en.sh --nakijken` en `naar_buiten.sh --nakijken` allebei afloop 0.
- **Engels: rood, en niet gepubliceerd.** `en/_werk/naar_site_en.sh` gaf afloop **1**. Week 4 is nu
  groen; de rode toets gaat over **week 5**. Toets 6 vindt daar 6 getallen die niet bij het
  Nederlands passen. De oorzaak zit in het lab. `ts_naloop` heeft in het Nederlands vraag 11 van
  het tentamenblok veranderd, en het Engels volgt die verandering nog niet. Ik ben gestopt zoals de
  opdracht zegt; de pers kwam niet aan stap 5, dus `en/` is niet aangeraakt. Op het bord staat
  een vraag aan jou, met mijn standaard: *alleen het Nederlands leveren*.
- **Het voorstel ligt klaar als getoetste patch**, niet als losse tekst:
  `_logs/ts_pers_beide_voorstel_taalstukken.patch` (commit `4ae6be4`, **niet toegepast**). Hij
  doet twee dingen. `publish_workbook.py` zet de taalstukken zelf terug, en `naar_buiten.sh`
  krijgt een poort die rood wordt als ze ontbreken. Dat laatste is nodig, want **vandaag ziet
  geen enkele poort op de weg naar buiten een verloren Nederlandse kant** (§5).

## 1. De Nederlandse pers, letterlijk

```
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 bash <lab>/uni_leiden/psychologie/ts_oefenboek/_werk/naar_site.sh \
    --site /Users/ben/Documents/Ben_OS/countcamp_site/.claude/worktrees/ts_pers_beide
```

Afloop **0**. Ik riep het script aan met zijn volledige pad in plaats van met een `cd` naar het
lab: de sessie mag daar niet heen, en het script gaat zelf naar zijn boekmap (`cd "$BOEK"`). De
regels die tellen (volledig log: `_site_en_werk/naar_site_nl.log`, gitignored):

```
== 1. lab: tak en ongecommit werk
  tak: main   commit: 243a2508   (gekeken: boekmap en …/ozp1_werkboek/2526_werkboek/_common)
  achter op origin/main (stand van de laatste fetch): 0
== 2. renderen
  grieks_rechtop: 14 bladzijden; 234 Griekse letter(s) rechtop gezet (benoemt, of krijgt een waarde), 122 cursief gelaten (rekent mee in een formule), …
  grieks_rechtop: daarvan 8 in een beslisregel (p ≤ α) en 36 in een hypothese (H₀: μ₁ = μ₂), …
== 3. _site vers en compleet
  14 bladzijden in de render-lijst; 14 .html in _site
== 4. neutraliteitswacht (alleen 'rooster' mag)
    bron: 14 .qmd-bestanden, 18349 regels -- 111 treffer(s)
    site: 14 bladzijden -- 203 treffer(s)
  per soort: 314 [rooster:
== 5. publish_workbook.py -> …/ts_pers_beide/oefenboeken/ts/
  teller: 0 bladzij(den) had hem al, 14 erbij gezet, 0 overgeslagen
  ontbrekende assets: 0
✅ Compleet en gevalideerd.
```

**Wat er inhoudelijk veranderde** (na het terugzetten van de taalstukken: 8 weekbladzijden en
`search.json`; op `index.html` alleen de taalstukken). Eén voorbeeld per soort, uit
`git diff 4f280ce 1f2ee19`:

- *ts_naloop*, week 4: het tipkader zegt nu *"Zijn de conditionele kansen gelijk, dan:
  onafhankelijk. Scheelt er iets, hoe weinig ook, dan: afhankelijk, in deze groep. … Reken ze
  altijd na."* Het tentamenblok begint met *"Je hebt alleen je rekenmachine en je spiekbriefje
  nodig: … de grens 3.84 van je spiekbriefje."*
- *grieks_registers*: in een formule die meerekent is χ nu cursief
  (`<mi mathvariant="normal">χ</mi>` → `<mi>χ</mi>`), zoals de drie registers voorschrijven.
- De twee PDF's in `08_tabellen/` verschillen alleen in `/CreationDate` (19:20 → 21:15) en in de
  byte-posities daarna. Ik heb dat nagemeten door alle stromen uit te pakken: verder is alles
  gelijk. Ze zitten in de commit als uitvoer van de pers.

## 2. De Engelse pers, letterlijk

```
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 bash <lab>/uni_leiden/psychologie/ts_oefenboek/en/_werk/naar_site_en.sh \
    --site /Users/ben/Documents/Ben_OS/countcamp_site/.claude/worktrees/ts_pers_beide
```

Afloop **1**. Stap 1–3 waren groen (lab `243a2508`, schoon; 9 van 9 bladzijden vers). Het einde
van de uitvoer, letterlijk:

```
== 4. alle Engelse wachters
    10 -> afloopcode 0
     2 -> afloopcode 1
     1 2 wachter(s) met een afloopcode boven 0.
STOP: een Engelse wachter zakte (afloop 1). Het hele verslag: /var/folders/_7/jhw9sjdx3j5g3fxmnsfwy7mm0000gn/T/ts_en_wachters.DIJkv31CxO
```

Het verslag staat nu ook in `_site_en_werk/naar_site_en_wachters.log`. De twee rode wachters:

1. **`_toets_en.py --render`, afloop 1.** Letterlijk:
   ```
     6 GAT(EN):
       - 05_effect_power/05_effect_power.html: wiskundegetal '2': 54 keer in het Nederlands, 55 in het Engels
       - 05_effect_power/05_effect_power.html: wiskundegetal '19': 2 keer in het Nederlands, 1 in het Engels
       - 05_effect_power/05_effect_power.html: wiskundegetal '20': 3 keer in het Nederlands, 2 in het Engels
       - 05_effect_power/05_effect_power.html: wiskundegetal '0.54': 4 keer in het Nederlands, 3 in het Engels
       - 05_effect_power/05_effect_power.html: wiskundegetal '2.40': 7 keer in het Nederlands, 5 in het Engels
       - 05_effect_power/05_effect_power.html: wiskundegetal '5.76': 3 keer in het Nederlands, 1 in het Engels
   ```
   Daarbij drie keer **BIJ TE WERKEN** (een melding, geen blokkade): week 1 (5 Nederlandse commits
   na `578e8543`), week 4 (2 na `fcf386a5`) en week 5 (3 na `44706509`).
2. **`_bijtproef_en.py`, afloop 1**: `37 proeven (9 schoon, 28 kapot), 1 niet zoals geëist`. Dat
   ene is *"ongeschonden kopie schoon voor _toets_en.py --render"*. De ongeschonden kopie heeft
   dezelfde 6 gaten. Het is dus dezelfde oorzaak, en de wachter zelf werkt.

**Waar de 6 getallen vandaan komen.** Ik heb beide bronnen gelezen; git kon ik in het lab niet
draaien, dat weigert de sessie hier. In het Nederlandse `05_effect_power.qmd` (regels 1815–1855)
heeft vraag 11 nu de afleider `n_onder` (*"n onder de streep in plaats van df"*, .22), met de
opties van klein naar groot. In het commentaar staat *"Ben, 21-11 … 'Ja, .22 erin'"* en *".22
vervangt 1 − eta2 (.77)"*. In het Engelse `en/05_effect_power/05_effect_power.qmd` (regels
1941–1962) staat nog `df_boven` (1 − η², .77) met `decreasing = TRUE`, en `nl_bron` is `44706509`.
Alle 6 getallen passen bij dat verschil. Het Nederlandse antwoord rekent bijvoorbeeld de fout
"n in plaats van df" voor: *"5.76/25.76"* (dat is 2.40² / (2.40² + 20)). Daar komen de extra keren
2.40, 5.76 en 20 vandaan. Het Engelse antwoord heeft die zin nog niet.

**Er ontbreekt meer dan toets 6 ziet.** Toets 6 telt alleen getallen in de wiskunde (`<mn>`) en in
de R-uitvoer, niet in de lopende tekst (kop van `en/_controles/_toets_en.py`, regel 22). Week 4
staat daarom op "0 fout", terwijl het Engelse week 4 nog de oude zin heeft (*"almost never exactly
equal, so here the answer is almost always …"*, regel 904). Het nieuwe Nederlandse tipkader en de
zin *"Je hebt alleen je rekenmachine en je spiekbriefje nodig … de grens 3.84"* staan er niet in.
Een bijwerkstap voor het Engels hoort dus week 1, 4 én 5 te dekken, niet alleen week 5.

**Wat er op de site staat, en blijft staan:** `en/workbooks/inferential-statistics/` is van
`4f280ce`, met de stempel `lab-commit=334da05e…`. Daar staat nog de **oude** week 4 vraag 10, de
vraag die het Nederlands vandaag heeft ingetrokken. De Engelse versie in lab-main heeft de nieuwe
vraag (`en_ts_bij2`). Die komt pas live als week 5 ook bij is. Dit is de afweging die ik op het
bord heb gezet.

## 3. De site: taalparen en nakijken, afloopcodes letterlijk

| wat | wanneer | afloop | de regel die telt |
|---|---|---|---|
| `python3 _tools/taalonderdelen.py los --controleer` | direct na de NL-pers | **1** | `losse bladzijden: 34 nagelopen, 9 gat(en)`, bv. `oefenboeken/ts/index.html: de taalstukken staan er niet (goed) in` |
| `python3 _tools/taalonderdelen.py los` | | 0 | 9× `bijgewerkt` (alle 9 Nederlandse TS-bladzijden), `34 nagelopen, 0 gat(en)` |
| `python3 _tools/taalonderdelen.py los --controleer` | daarna, en opnieuw na de commit | 0 | `losse bladzijden: 34 nagelopen, 0 gat(en)` |
| `bash _tools/publiceer_en.sh --nakijken` | op `1f2ee19` | 0 | `losse tweelingen: 17 paar, 0 fout` · `taalbalk: … 25 van de 25 Nederlandse tweelingen dragen hem, 0 fout` · `uit een oefenboek: 9 bladzij(den) met de stempel van publish_workbook.py, 0 met een stempel die niet klopt` · `Wat er in en/ staat, is in orde.` |
| `bash _tools/naar_buiten.sh --nakijken` | op `1f2ee19` | 0 | `plankwacht: 11 kaartjes, 5 belofte(s) nagerekend` · `oefenboeken/ts 14 14 0` (teller) · `Alle 181 doorstuurders …` · `Alle poorten staan groen. --productie zou hierop niet struikelen.` |

**Niet gedraaid: de volle `bash _tools/publiceer_en.sh`.** Je opdracht zegt *"if the press footer
asks for it"*. Alleen de Engelse pers vraagt erom, en die kwam niet aan haar slotblok. Aan `en/`
is niets veranderd: `git status` na de rode pers was leeg. Daardoor zijn ook `en/index.html` en
`en/workbooks/index.html` **niet** opnieuw gebouwd. Wat `taalmerk` daar verandert, moet je na het
mergen dus zelf bouwen, zoals de opdracht al zei. Uit mijn tak komt niets dat ermee botst. Hun
`.qmd` heb ik niet aangeraakt.

**Op de syntaxis van de opdracht:** `python3 _tools/taalonderdelen.py --controleer` bestaat niet.
Het is `python3 _tools/taalonderdelen.py los --controleer`; zonder `los` stopt argparse met
afloop 2.

## 4. De commits op deze tak

| commit | wat |
|---|---|
| `1f2ee19` | `oefenboeken/ts/`: de Nederlandse pers vanaf lab `243a2508`, mét de taalstukken terug (11 bestanden: 8 weekbladzijden, `search.json`, 2 PDF's; `index.html` is na het terugzetten gelijk aan `4f280ce` en zit er dus niet in). `[geen-vertaling]`, want dit is uitvoer van de lab-pers: of het Engels de Nederlandse inhoud volgt, bewaakt de taalnaad in het lab, niet hier. |
| `4ae6be4` | `_logs/ts_pers_beide_voorstel_taalstukken.patch`: het voorstel als bestand. `_tools/` op deze tak is gelijk aan `4f280ce`. |
| (kop) | dit rapport |

**Te mergen: de kop van de tak.** De SHA staat in de afmelding op het bord, want `bord.sh klaar`
trekt de tak bij en dan verandert hij. Wil je alleen het Nederlands en geen voorstelbestand, dan
is `1f2ee19` de commit.

## 5. Het voorstel: zodat niemand de taalparen meer kan vergeten

### Welke bestaande wachter ziet het nu al?

Ik heb het gemeten in plaats van gelezen. Ik maakte de 9 Nederlandse TS-bladzijden in de
werkkopie weer kaal, precies zoals de pers ze achterliet (per bladzijde 0 regels erbij en 59 eraf,
net als bij `index.html` na de echte pers). Daarna draaide ik elke wachter, en daarna zette ik de
bladzijden terug met `taalonderdelen.py los` (`git diff --quiet`: gelijk aan `1f2ee19`).

| wachter | ziet het? | gemeten |
|---|---|---|
| `taalonderdelen.py los --controleer` | ja, afloop 1 | `34 nagelopen, 9 gat(en)` |
| `publiceer_en.sh --nakijken` (en de volle `publiceer_en.sh`, zelfde keuring `en_bouw.py keur`) | **ja**, afloop 1 | `losse tweelingen: 17 paar, 9 fout` · `taalbalk: … 16 van de 25 Nederlandse tweelingen dragen hem, 9 fout` |
| `naar_buiten.sh --nakijken`, dus ook de poorten van `--productie` | **nee**, afloop 0 | `Alle poorten staan groen. --productie zou hierop niet struikelen.` |
| de Action `publish.yml` | **nee** | draait alleen `_tools/tellerwacht.py --echt` |
| lab `boek/_tools/publicatie/lever.sh` | alleen voor het boek | regels 104–142: draait zelf `los` en `los --controleer` |

Een kale Nederlandse kant komt dus live, tenzij iemand er toevallig aan denkt `publiceer_en.sh`
te draaien. Dat is al één keer gebeurd. Volgens het commentaar in `lever.sh` (regels 53–61)
stonden `manuscript/h0`–`h3` van 2-11 tot 11-11 zonder taalstukken: *"Elke keer moest iemand na
lever.sh met de hand `taalonderdelen.py los` draaien, en wie dat vergat, merkte niets."* Het boek
kreeg toen een reparatie in zijn eigen pers. De oefenboeken kregen er nooit een.

### Wat de patch doet (twee lagen)

1. **De maker zet ze zelf: `publish_workbook.py`, stap 5b.** Dat is het gereedschap dat
   `oefenboeken/<naam>/` en `en/workbooks/<naam>/` weggooit en opnieuw neerzet, en het wordt
   door **beide** TS-persen aangeroepen. Na teller, stempel en validatie loopt het de bladzijden
   onder de doelmap langs die in `taalparen.tsv` `los` of `los-eigen` staan, en roept het
   `taalonderdelen.pas_toe_los()` aan. Dat is dezelfde aanroep als in `bouw_speelkist.py`, en de
   stukken zelf blijven op één plek staan. Een rij voor een bladzij die het boek niet meer maakt,
   een bladzij zonder plek voor het knopje, of een tabel zonder gereedschap geeft afloop 1, met
   de bladzij bij naam. Zonder `taalparen.tsv` zegt het dat, en gaat het door.
2. **De deur toetst ze: `naar_buiten.sh`, poort `taalstukken_nakijken`.** Die draait
   `taalonderdelen.py los --controleer`: blokkerend in `--nakijken` en `--productie`, meldend in
   `--lokaal` en `--proefdruk`, in dezelfde vorm als de doorstuurpoort (een verloren wachter heet
   ONGEMETEN en krijgt niet de schuld van de bladzijden). Hij heeft geen bouw nodig en is in een
   tel klaar. Hij vangt ook elke andere route: `boek/publiceer.sh` zonder `lever.sh` (die
   kopieert met een kale `cp`, regel 291), een handkopie, of een volgend Engels oefenboek.

**Waarom niet in `naar_site.sh` (jouw voorbeeld).** Dat script staat in het lab en dekt alleen de
Nederlandse TS-pers. De Engelse pers gooit ook haar eigen kant van de paren weg
(`publish_workbook.py` begint met een `rmtree` van de doelmap), en het volgende oefenboek met een
tweeling zou het gat opnieuw openen. Het gereedschap dat de bladzijden schrijft, moet ze ook
afmaken.

### Getoetst, met de patch toegepast

| proef | uitslag |
|---|---|
| NL-pers opnieuw met de gewijzigde `publish_workbook.py` (dus zonder `taalonderdelen.py los` daarna) | afloop 0, `taalstukken: 9 bladzij(den) met een losse tweeling in taalparen.tsv, 9 bijgezet, 0 fout`. Onder `oefenboeken/ts/`: **0 .html of .json anders dan `1f2ee19`**; alleen de twee PDF's (aanmaakdatum, teruggezet). Twee keer gemeten, voor en na het verplaatsen van de stap. |
| het Engelse boek, in twee weggooisites onder `_site_en_werk/` (`_tools/` en configs, zoals `--weggooisite`): de oude volgorde (publish, dan `los`) tegen de patch | **9 van 9 bladzijden byte-gelijk**, op de leveringstijd in de stempel na; 9 knopjes; stempel `9 … door en_bouw.py herkend`. Geen Engels naar de site of de tak: dit was een toets van het gereedschap, op de rode render. Script: `_site_en_werk/en_volgorde_proef.sh`. |
| `naar_buiten.sh --nakijken` met de patch, op de goede stand / kaal / weer terug | afloop 0 / **1** (alle 9 bij naam, `Herstellen: python3 _tools/taalonderdelen.py los`) / gelijk aan `1f2ee19` |
| `naar_buiten_teller_test.sh` | 41 zaken, alles groen (was 31; nieuw zaak 6a–6d) |
| `publish_teller_test.sh` | 36 zaken, alles groen (was 23; nieuw zaak 7a–7e) |
| tegenproef `naar_buiten.sh`: poort niet in `--nakijken` / poort altijd groen / poort niet in `--productie` | 3 van 3 opgemerkt, door 6a, 6a en 6d. Script: `_site_en_werk/mutatieproef_taalstukken.sh` |
| tegenproef `publish_workbook.py`: geen taalstap / fouten houden niet tegen | 2 van 2 opgemerkt. Bij de eerste vallen alle 11 rode regels in zaak 7 (*"knopje 0, hreflang 0, balk 0"*), geen enkele in zaak 1–6. Mijn proefscript meldde hem eerst als MISLUKT, omdat de eerste rode regel een `verwacht` zonder nummer is; dat was een fout in de proef, niet in de toets. |
| `naar_buiten_poort_mutatieproef.sh`, `tellers_test.sh`, `tellers_mutatieproef.sh` | groen, met en zonder patch |
| `doorstuurders_test.sh`, `plankwacht_test.sh` | **zakten eerst door de patch**: hun proefrepo's kopiëren de echte `naar_buiten.sh` zonder `taalonderdelen.py`. Dezelfde reparatie als bij de derde poort: een nagemaakte, groene wachter erbij. Daarna 27 en 41 groen. Zit in de patch. |
| `en_werkboek_lab_test.py` (afloop 3), `en_werkboek_lab_mutatieproef.sh` (afloop 1) | **rood met én zonder patch**, en dus niet groen te noemen. `KON NIET KIJKEN: _site_spook/ is niet gebouwd`. Die map is gitignored en staat in een verse werkkopie nooit. |

**Wat de patch NIET dekt.** Een kapotte `taalparen.tsv` laat `taalonderdelen.py` stoppen met
`SystemExit` en dus met afloop 1. De poort zegt dan *"mist zijn taalknopje"* in plaats van
*"de tabel is kapot"*; de foutregel van het gereedschap staat er wel boven. Na het toepassen kloppen
er drie teksten in het lab niet meer: het slotblok van `naar_site_en.sh` (stap 2, *"ook na ELKE
Nederlandse herpublicatie"*), `en/LEESMIJ.md` §7 punt 5, en het slotblok van `naar_site.sh`. Dat is
lab-werk.

## Verrassingen

1. **Geen enkele poort op de weg naar buiten ziet een verloren Nederlandse taalkant.** Met 9 kale
   Nederlandse TS-bladzijden zei `naar_buiten.sh --nakijken`, dezelfde poorten als `--productie`:
   *"Alle poorten staan groen. --productie zou hierop niet struikelen."* De Action toetst alleen de
   teller. Wie na deze pers `taalonderdelen.py los` vergeten was, had zonder enige melding
   een NL-site geleverd waarop het knopje naar het Engels op het hele TS-boek weg is. Het is de
   tweede keer in drie weken: het boek had het van 2-11 tot 11-11.
2. **De Engelse pers zakt nu op week 5, niet op week 4, en daardoor blijft de ingetrokken vraag
   live.** `en_ts_bij2` heeft week 4 bijgewerkt, maar dezelfde avond veranderde `ts_naloop` vraag
   11 van week 5 (*"Ja, .22 erin"*, Ben). Zolang week 5 in het Engels niet bij is, blokkeert de pers
   ook de verbeterde week 4. Live staat daarom nog de vraag die het Nederlands vandaag heeft
   ingetrokken. Ben besliste eerder *"Nu live, daarna bijwerken"*. Gold dat ook voor deze
   tweede ronde? Dat is aan jou; ik ben niet langs rood gegaan.
3. **Groen op toets 6 betekent niet "de Engelse tekst is bij".** De toets telt alleen getallen in
   formules en R-uitvoer. Het nieuwe tipkader en de spiekbriefje-zin van week 4 (met 3.84 in de
   lopende tekst) staan niet in het Engels, en week 4 stond toch op "0 fout". Alleen de melding
   BIJ TE WERKEN wijst erop, en die houdt niets tegen.
4. **De plek van de nieuwe stap deed ertoe.** Mijn eerste versie zette de taalstukken vóór de
   validatie. Dan telt `validate_assets` de link van het knopje naar de tweeling mee, en in een
   weggooisite staat die er niet: 9× `MIST: index.html -> ../../../oefenboeken/ts/index.html`,
   afloop 1. `naar_site_en.sh --weggooisite` zou daardoor voortaan rood zijn geworden. Daarom staat
   de stap nu ná de validatie, en dat is ook de volgorde van het handwerk van vandaag.
5. **De naamcontrole van de briefing gaf een vals alarm.** Volgens `zetter.sh` bestonden
   `_werk/naar_site.sh` en `en/_werk/naar_site_en.sh` niet. Ze staan gewoon in de TS-map van het
   lab; de controle zocht in de site-werkkopie en in `~/Documents/Ben_OS`. (De derde,
   `_logs/ts_pers_beide_2026-11-21.md`, is dit rapport.)

Kleiner, voor het logboek:

- Elke Nederlandse TS-pers verandert de twee tabel-PDF's, alleen in hun aanmaakdatum. Dat geeft
  twee binaire bestanden per pers in de geschiedenis. De lab-toets `nl_ongemoeid` vergelijkt PDF's
  daarom al *"op hun kern, zonder aanmaakdatum"*.
- In `publiceer_en.sh --nakijken` op de kale stand stond *"tweelingen: 25 paar uit taalparen.tsv,
  18 fout — bv. index.html ↔ en/index.html"*. Het voorbeeld is het eerste paar uit de tabel, niet
  een fout paar. Wie het voorbeeld volgt, kijkt naar een bladzij die in orde is.

## Voor C

- **De vraag op het bord**: mag de Nederlandse helft (`1f2ee19`) alleen landen? Mijn standaard is
  ja, en het Engels blijft dan de live versie van lab `334da05e`.
- **Een bijwerkstap voor het Engels in het lab**, voor week 1, 4 en 5 samen (§2). Daarna de
  Engelse pers opnieuw. Ik kan dat doen op deze tak; daar verandert dan alleen
  `en/workbooks/inferential-statistics/` plus `taalonderdelen.py los`.
- **De patch**: `git apply _logs/ts_pers_beide_voorstel_taalstukken.patch` past schoon op deze tak
  (`git apply --check`). Wil je hem, dan zijn er geen handmatige stappen meer na een
  oefenboekpers, en vangt `--productie` het gat als iemand een andere weg neemt.
- **Na het mergen van `taalmerk`**: `en/index.html` en `en/workbooks/index.html` zijn hier niet
  opnieuw gebouwd (§3).
- Logs en proefscripts staan in `_site_en_werk/` (gitignored): `naar_site_nl.log`,
  `naar_site_en.log`, `naar_site_en_wachters.log`, `publiceer_en_nakijken.log`,
  `naar_buiten_nakijken.log`, `mutatie_*.log`, `toets_*_*.log`, en de proefscripts. De
  weggooisites `volgorde/` en `volgorde2/` mogen weg; ik heb ze laten staan (huisregel 9).
