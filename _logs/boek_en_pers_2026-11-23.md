# Spoor `boek_en_pers`: de Engelse boekbladzijden (en/book/h0–h3) geperst vanaf lab `7f6fa81d`

*23-11-2026, zetter op broodje. Tak `worktree-boek_en_pers` in `countcamp_site`, vertrokken van
`e00db21` (bij de start nagemeten met `git log -1 --format=%h`: `e00db21`). Niets gepusht, niets
geleverd. Het lab is niet aangeraakt, behalve door de pers zelf. Na afloop gaf
`git -C countcamp_lab status --short` dezelfde drie ongetrackte bestanden als vóór de pers, en
verder niets.*

## In het kort

- **De pers is groen.** `publiceer.sh --en` gaf afloop **0**, zonder nooddeur. De boekpoort zei
  `POORT GROEN — 40 aangemeld · 38 gedraaid · 0 overgeslagen · 0 rood. (1119s)`, en de Engelse
  rendertoets zei `geen gaten`.
- **Alle vier de Engelse bladzijden dragen de nieuwe knop**: `'✎ where I have doubts ('`, één keer
  per bladzij, en geen enkele Nederlandse schermtekst. Ze dragen ook de drie hreflang-regels en het
  taalknopje. Hun Nederlandse tweeling draagt de taalbalk. Dat geldt voor de repo en voor de
  gebouwde site (§3).
- **Op het scherm verandert de knop niets: hij blijft verborgen.** De Engelse bladzijden hebben
  geen werkbriefjes, dus de teller van de knop staat op 0 en de hoek verdwijnt.
- **Wat de lezer wél anders ziet, is meer dan de knop** (Verrassing 1). De Engelse bladzijden waren
  sinds 25-10 niet meer geperst. Met deze pers komen de lab-reparaties van 28-10 mee: in H1 en H3
  feitelijke reparaties, *Mdn*, *SS* als één cursief teken, en *S*<sub>e</sub> met een rechtopse e.
- **Twee van de drie poorten zijn groen, en de derde zakt op werk van een ander spoor.**
  `naar_buiten.sh --nakijken` gaf **1** door het OZP 1-kaartje. Dat komt door `a4f8eb0`, dat op de
  lokale `main` staat (Verrassing 2). Ik heb nagemeten dat `main` zelf daar ook op zakt, en dat
  mijn stand zonder die commit groen is.
- **Eén keuze ligt als vraag bij C:** het tellerblok dat de bouw terugschreef, heb ik niet
  meegecommit (§4).

## 1. Wat er gedraaid is, met de afloop letterlijk

| # | commando | afloop | wat het zei |
|---|---|---|---|
| 1 | `cd countcamp_lab/boek && PUBLICATIE_SITE=<deze werkkopie> LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 bash publiceer.sh --en` | **0** | `werkkopie: bij met origin/main.` · `POORT GROEN — 40 aangemeld · 38 gedraaid · 0 overgeslagen · 0 rood. (1119s)` · `H0..H3 renderen... klaar` · `_en_toets.py --render`: `geen gaten` · `H0..H3 gepubliceerd -> h<n>.html [gestempeld]` |
| 2 | `python3 _tools/taalonderdelen.py los --controleer` (na de pers, vóór het bijtrekken) | **1** | `34 nagelopen, 8 gat(en)`: de vier `en/book/h<n>.html` en de vier `manuscript/h<n>.html` |
| 3 | `git merge --no-ff origin/main` (`16adb27`, met daarin `20f6b85`: de Nederlandse taalstukken terug) | – | daarna `los --controleer` **1**, `4 gat(en)`, alleen de vier Engelse |
| 4 | `python3 _tools/taalonderdelen.py los` | **0** | `en/book/h0..h3.html: bijgewerkt` · `34 nagelopen, 0 gat(en)` · `buiten de tabel: 426 .html nagelopen, 0 met een taalstuk` |
| 5 | `bash _tools/publiceer_en.sh` (de hele gang, op `f44d06a`) | **0** | `geen gaten` · `uit het lab: 4 bladzij(den) met de stempel van de lab-pers, 0 met een stempel die niet klopt` · `tweelingen: 25 paar uit taalparen.tsv, 0 fout` · `taalbalk: … 25 van de 25 Nederlandse tweelingen dragen hem, 0 fout` · `nederlands ongemoeid: voor 1574, na 1574 bestanden — 0 weg, 0 bij, 0 anders` · manifest `status=OK afloop=0 bladzijden=22` |
| 6 | `git merge --no-ff main` (`a4f8eb0`, lokaal, nog niet op origin) | – | daarna verschilt mijn tak van `main` alleen in `en/book/h0–h3` en `_tools/en_manifest.txt` |
| 7 | `python3 _tools/taalonderdelen.py los --controleer` (op `9e19ba6`) | **0** | `34 nagelopen, 0 gat(en)` |
| 8 | `bash _tools/publiceer_en.sh --nakijken` (op `9e19ba6`) | **0** | |
| 9 | `bash _tools/naar_buiten.sh --nakijken` (op `9e19ba6`) | **1** | het enige rode: `plankwacht … FOUT OZP 1 — Onderzoekspracticum 1 (regel 81): zegt 'Bijgewerkt 1 oktober 2026' (2026-10-01), maar oefenboeken/ozp1/ is voor het laatst veranderd op 2026-11-23 -- a4f8eb0 …`. Verder `Alle 259 bladzijden dragen de teller.`, `Alle 181 doorstuurders … de 23 andere ook.`, `losse bladzijden: 34 nagelopen, 0 gat(en)` |
| 9b | `plankwacht.py` in een weggooikloon op `6c7c192` (mijn werk, zonder `a4f8eb0`) | **0** | `alle nagerekende beloftes kloppen` |
| 9c | `plankwacht.py` in dezelfde kloon op `a4f8eb0` (`main`, zonder mijn werk) | **1** | dezelfde FOUT-regel |

De logs staan in `_site_en_werk/boek_en_pers/` (gitignored): `pers.log`, `los.log`,
`publiceer_en.log`, `taal_controleer.log`, `publiceer_en_nakijken.log`, `naar_buiten_nakijken.log`
en `plankwacht_main.log`.

**`publiceer_en.sh` meldde in stap 0 vier keer `BIJ TE WERKEN`, en dat houdt niets tegen.** Het
Nederlands is bewogen sinds de commit waarvan elke vertaling is gemaakt. H0 bewoog 4 keer, H1 21
keer, H2 15 keer en H3 22 keer. De laatste commit is telkens een `[geen-vertaling]`-commit, maar stap
0 kent dat merk niet (dat zegt de kop van het script zelf). Hoeveel van die commits echt tekst
veranderden, heb ik niet nagezocht.

## 2. Hoe ik het heb nagemeten

**De taalstukken zijn dezelfde bytes als vóór de pers.** Daarvoor heb ik het gereedschap zelf
gebruikt (`taalonderdelen.zonder_alle_stukken`), in `_site_en_werk/boek_en_pers/stukken_gelijk.py`.
Per bladzij kwamen er 11 regels bij en ging er niets weg. Die 11 regels zijn gelijk aan de stukken
in `e00db21`. Haal je de stukken weg, dan houd je byte voor byte de render van de pers over
(`c83c8ca`).

**Wat de lezer anders ziet, per bladzij** (`tekstdiff.py`). Het script vergelijkt de zichtbare
tekst, zonder scripts en stijl, met wat er vóór de pers stond (`e00db21`). In de tabel staat "anders
dan e00db21" zonder de regel "NL·EN" in de titel: die verdwijnt na de pers en komt met `los` weer
terug.

| bladzij | tekstblokken | anders dan e00db21 | voorbeeld |
|---|---|---|---|
| h0 | 83 | 0 | – |
| h1 | 212 | 13 | "Some big and gleaming, some small and dull, **some** big and dull" → "**one** big and dull" |
| h2 | 130 | 1 | "also: Med, *Mdn* (in APA style)" → "also: *Mdn*" |
| h3 | 397 | 13 | "every miss goes down by five." → "… down by five — a stone that already lay below the line ends up even further away." |

De rest van H1 en H3 bestaat uit notatie: `SS` werd `\mathit{SS}` en `S_e` werd `S_{\text{e}}`. In
H3 werd ook `32.14 × 1.6` → `32.143 × 1.6`. Alle wijzigingen komen uit lab-commits van 28-10 die het
lab al gekeurd heeft (`2de6adfc`, `14fb078c`, `46be623a`, `849763d7`, `cf045b00`, `21ce159a`).

## 3. De controles uit stap 3, op de repo én op de gebouwde site

Ik heb ze gedraaid met `_site_en_werk/boek_en_pers/stap3.py`. De lijst Nederlandse schermteksten
heb ik niet overgetikt: het script leest `NL_OP_SCHERM` (22 teksten) uit het lab-script
`boek/en/_maak_afterbody_en.py`. `_site` is de bouw van `publiceer_en.sh --nakijken`.

```
ok    repo h0: knop=1 nl_knop=0 hreflang_en=3 knopje_en=2 | manuscript: hreflang=3 taalbalk=1 | stempel=37deeeb9c170
ok    repo h1: knop=1 nl_knop=0 hreflang_en=3 knopje_en=2 | manuscript: hreflang=3 taalbalk=1 | stempel=93d89636a90f
ok    repo h2: knop=1 nl_knop=0 hreflang_en=3 knopje_en=2 | manuscript: hreflang=3 taalbalk=1 | stempel=d8214e0e5ee0
ok    repo h3: knop=1 nl_knop=0 hreflang_en=3 knopje_en=2 | manuscript: hreflang=3 taalbalk=1 | stempel=47447b815a71
ok    _site h0..h3: dezelfde acht getallen; bezoekersteller (tellerregel.tellerstand) op alle vier "geteld"
```

- **De knop, één regel vóór en na** (`en/book/h0.html`):
  vóór `knop.textContent = verborgen ? '✎ show working notes (' + totaal + ')' : '✎ text only';`
  (de after-body van vóór 10-11, zonder hoek en zonder regel eronder) ·
  na `var LEZER_DICHT = '✎ where I have doubts (';`.
- **Twee keer "waar ik twijfel" staat er in elke Engelse bladzij, en geen van beide is een
  schermtekst.** De eerste is `content: "✎ waar ik twijfel";` uit de gedeelde `boek.css`: het
  etiket van een werkbriefje. Engelse bladzijden hebben geen briefjes, dus het verschijnt niet. Ook
  `boek_en.css` zegt dat dit pas Engels moet worden als er briefjes komen. De tweede staat in een
  JS-commentaar in de after-body.
- **Dat de knop verborgen blijft, heb ik nagemeten.** Er zijn 0 elementen `.werk` of `.werk-blok`,
  en geen `<meta name="cc-werknotities" content="lezer">`. Komen er ooit briefjes zonder die meta,
  dan toont de knop `'✎ show working notes ('` en niet de nieuwe tekst.
- **Niets anders in `en/` veranderd.** `git diff --stat main HEAD -- en/` geeft 4 bestanden, alle
  vier `en/book/h<n>.html` (+1468 −583). Daarbij komt `_tools/en_manifest.txt`. Tegen mijn
  vertrekpunt `e00db21` komt er nog `en/index.qmd` bij: dat komt van `main` (`16adb27`, een
  MIEKE-commentaar), niet van mij.

## 4. De keuze die ik maakte: het tellerblok uit de bouw niet meecommitten

`publiceer_en.sh` (afloop 0) liet vier bestanden veranderd achter die ik niet had aangeraakt. Het
ging om `en/book/h0.html`, `en/toys/elephants-memory.html`, `en/toys/shuffle-correlation.html` en
`en/workbooks/inferential-statistics/index.html`. Elk kreeg dezelfde wijziging, 16 regels erbij en 1
weg: de teller-regel van het lab ging eruit, het tellerblok van de site ging erin.

**Waarom juist die vier.** Quarto kopieert een losse bladzij alleen naar de bouw als een Engelse
`.qmd` ernaar linkt. Naar `book/h0.html` linkt `en/index.qmd`, drie keer. Naar de twee speeltjes
linkt `en/toys/index.qmd`. Naar de werkboek-index linken `en/index.qmd`, `en/about.qmd` en
`en/workbooks/index.qmd`. In de bouw zet `teller_zetten.py` in elke bladzij het tellerblok. Daarna
schrijft `en_bouw.py` (stap 4, "neergezet in ./en/: 11 bladzijde(n)") alles uit de bouw terug in de
repo. Dat zijn 7 `.qmd`-bladzijden plus deze 4. Naar h1–h3 linkt geen enkele `.qmd`, en die bleven
dus gelijk.

**Wat ik deed.** Ik heb alle vier teruggezet op de stand van de lab-pers en de speelkist, en alleen
het manifest gecommit. Daarna heb ik met `publiceer_en.sh --nakijken` bewezen dat die stand groen is
(afloop 0). Mijn redenen:

1. Ben heeft precies deze wissel voor de speeltjes al eens teruggedraaid, op 16-11 (`bd7cb62`). Met
   het tellerblok van de site gaf het lab-proefje `_proef_kopieen.py` 2 afwijkingen.
2. De speeltjes en de werkboek-index vallen buiten dit spoor.
3. Zo krijgen h0 tot en met h3 dezelfde vorm.
4. Live verandert er niets, want `teller_zetten.py` zet de teller bij elke bouw.

**Wat daar tegenover staat.** De kop van het manifest zegt *"groen … voor PRECIES de bestanden die
nu in en/ staan"*. Letterlijk genomen klopt dat voor deze vier bestanden niet meer: die verschillen
één tellerregel. Daarom de `--nakijken`-run erna. En op 14-11 heeft `54b10c4` het tellerblok in h0
wél gecommit. Op het bord staat de vraag voor C, met als standaard: niet meecommitten.

## 5. Commits op deze tak

| commit | wat |
|---|---|
| `c83c8ca` | de pers: `en/book/h0–h3` vanaf lab `7f6fa81d`, nog zonder taalstukken |
| `845e465` | merge `origin/main` (`16adb27`) |
| `f44d06a` | de taalstukken terug (`taalonderdelen.py los`), byte-gelijk aan `e00db21` |
| `6c7c192` | `_tools/en_manifest.txt` van `publiceer_en.sh` (afloop 0 op `f44d06a`) |
| `9e19ba6` | merge `main` (`a4f8eb0`) |
| *(dit rapport erbovenop)* | |

`bord.sh klaar` trekt de tak nog bij, en dan veranderen de SHA's. De SHA die telt, staat in de
afmelding op het bord.

## Wat dit niet dekt

- **Live is niets gemeten.** Er is niets geleverd: `naar_buiten.sh --productie` is van C, en zou
  nu stoppen op het OZP 1-kaartje.
- **De lab-pers draaide in de gedeelde lab-checkout.** De vier renders `boek/en/H<n>_en.html` staan
  daar en zijn gitignored. Draaide er tegelijk een ander spoor in `boek/en/`, dan heb ik dat niet
  gezien. Na afloop stond `git status` van het lab zoals ervoor.
- **De APA-lens is niet gedraaid.** Ik heb geen lezerstekst geschreven. De notatiewijzigingen in
  §2 komen uit lab-commits, en een daarvan heet "APA-restjes" (`14fb078c`). Of de lens er in het lab
  overheen is gegaan, heb ik niet nagezocht.
- **Of het Engels inhoudelijk achterloopt op het Nederlands** (de `BIJ TE WERKEN`-regels), heb ik
  niet uitgezocht.

## Verrassingen

1. **De Engelse boekbladzijden op de site liepen een maand achter op het lab.** Hun stempel was van
   `geleverd=2026-10-25T10:44:49`. Daarna is er in `en/book/` alleen `54b10c4` (14-11) geweest, met
   een tellerblok in h0. De after-body van 10-11 (de hoek met de regel eronder) is in het Engels dus
   nooit live geweest. Hetzelfde geldt voor de reparaties van 28-10 in H1 en H3: het verkeerde
   "some big and dull" staat in de `en/book/h1.html` van `main` (`e00db21`). Of die versie ook
   live staat, heb ik niet gemeten; ik heb niets van countcamp.org opgehaald. De opdracht zei *"Op het
   scherm verandert er niets"*. Dat klopt voor de knop, maar niet voor de tekst van H1, H2 en H3.
   Wie levert, levert die reparaties mee. Dat is goed, maar het is meer dan een knopnaam.
2. **`main` zelf staat rood op `naar_buiten.sh --nakijken`, sinds `a4f8eb0`** (Oefenboek OZP 1,
   staat lokaal op `main` en nog niet op origin). Het OZP 1-kaartje zegt "Bijgewerkt 1 oktober
   2026", terwijl het boek op 23-11 veranderde. `--productie` stopt daarop, voor elk spoor dat na
   `a4f8eb0` levert, tot iemand het kaartje bijwerkt. Gemeten in een weggooikloon (§1, 9b en 9c).
3. **De route die de Engelse schil zelf aanwijst, maakt een eerdere reparatie ongedaan.**
   `publiceer_en.sh` eindigt met *"git add en _tools/en_manifest.txt, commit"*. Doe je dat, dan zet
   je het tellerblok weer in de twee speeltjes die `bd7cb62` op 16-11 juist had teruggezet. Dat
   gebeurt bij elke volledige run, voor elk spoor, en het staat nergens in de slotmelding (§4).
4. **De boekpoort duurt nu 1119 s, bijna 19 minuten.** Op 16-9 was dat ~254 s (13 proeven, gemeten
   in `publiceer.sh` r125); nu zijn het 38 proeven. Een Engelse persing van vier hoofdstukken kost
   daarmee ongeveer 20 minuten, en vrijwel alles daarvan is de poort. Die 20 minuten heb ik geschat
   uit de klok, niet gemeten; de 1119 s staat letterlijk in `pers.log`.
5. **Mijn eigen toets zei eerst "taalbalk 0" op alle vier de Nederlandse tweelingen, en dat klopte
   niet.** De balk zet zichzelf met een script neer (`className = "taalbalk"`), dus `class="taalbalk"`
   staat nooit in de HTML. Zoeken is niet gevonden hebben (huisregel 5c). Nu toetst hij het stuk
   `balk.html` letterlijk, met `taalonderdelen.stuk()`: 1 op alle vier.
