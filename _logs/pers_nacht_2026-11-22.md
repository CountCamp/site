# pers_nacht — 22-11-2026, 00:37–01:25

Zetter `pers_nacht`, werkkopie `.claude/worktrees/pers_nacht`, tak `worktree-pers_nacht`,
vertrokken van site-main `eac21b8` (nagemeten: `git log -1 --format=%h` gaf `eac21b8`).
Lab: main `188d3bb2` (de pers meldde zelf: *"tak: main commit: 188d3bb2 … achter op origin/main: 0"*).
Niets gepusht, niets gedeployd.

## Kort

1. **De oorzaak zit in Quarto, niet in onze instellingen.** Bij elke bouw van de site loopt
   Quarto de héle projectmap af: hij zet elke map en elk bestand op een rij om te zien wat
   hij moet bouwen of kopiëren. Dat heet hieronder *de wandeling*. Alleen de uitvoermap
   (`_site/`) slaat hij over. Geen regel in `render:`, `resources:` of `.gitignore` houdt
   hem uit `.claude/worktrees/`. De regel `"!.claude/**"` in `_quarto-nl.yml` stuurt hem er
   zelfs heen: hij zoekt daar op wat hij straks moet weglaten. Vannacht liep hij zo door de
   werkkopie van `taalpers`, terwijl diens toets daar een wegwerpkloon neerzette en weer
   weghaalde. Een bestand dat net weg was, gaf `NotFound ... stat`.
2. **De reparatie:** `_tools/schone_bouw.py`. Die bouwt in een kopie van de werkkopie in
   `$TMPDIR`, zonder `.claude/`, en zet alleen de uitvoermap terug. Alle vier de plekken
   waar een script de site bouwt gaan er nu doorheen. De uitvoer is byte voor byte gelijk
   aan een bouw ter plaatse. Een bijtproef laat zien dat het verschil echt is: met de
   reparatie blijft Quarto weg uit een dichte map onder `.claude/`, zonder de reparatie
   loopt hij erop vast.
3. **Nederlandse pers: geperst.** Afloop 0, commit `7e7d545`. Week 4 heeft de twee nieuwe
   figuren, week 5 vraag 3 toont .04 / .08 / .92 / 2.00. `taalonderdelen.py los` met de
   hand was **niet** nodig: de pers zette de taalstukken zelf terug ("9 bijgezet, 0 fout"),
   en `los --controleer` geeft 0 gaten.
4. **Engelse pers: NIET geperst.** Een Engelse wachter staat rood op week 5 (10 getallen
   uit `ts_klein_fix` die het Engels nog niet heeft). `en/` staat precies zoals op site-main.
5. **Poorten op de eindstand:** `taalonderdelen.py los --controleer` 0,
   `publiceer_en.sh --nakijken` 0, `naar_buiten.sh --nakijken` 0.

Commits op `worktree-pers_nacht`, in volgorde:

| commit | wat |
|---|---|
| `7e7d545` | Oefenboek TS (NL): pers vanaf lab `188d3bb2` (geen `[geen-vertaling]`: het Engels moet dit volgen) |
| `79324d6` | **de reparatie**: `_tools/schone_bouw.py`, en `naar_buiten.sh`, `publiceer_en.sh` en `en_bouw.py` bouwen erdoor |
| `58567bd` | `schone_bouw.py` geeft een signaal door aan quarto; twee bestaande toetsen kennen de schone bouw |
| `b2ea7be` | nieuwe toets `_tools/tests/schone_bouw_test.sh` (17 van 17, met bijtproef) |
| `2949355` | mutatieproef van de werkruimte-toets: twee sloten die nu achter de schone bouw staan |
| (dit rapport) | `_logs/pers_nacht_2026-11-22.md` |

---

## 1. De oorzaak

### Wat ik zag

De bouw van de site in mijn werkkopie, met een proefboom onder `.claude/worktrees/_proef/`
en daarin één map die niemand mag lezen (`chmod 000`). Loopt Quarto daar binnen, dan stopt
hij met `PermissionDenied`. Dat is de meetlat in alles hieronder.

    ERROR: PermissionDenied: Permission denied (os error 13): readdir '/Users/ben/Documents/Ben_OS/countcamp_site/.claude/worktrees/pers_nacht/.claude/worktrees/_proef/gesloten'
        at walkSync (file:///Users/ben/.local/quarto-1.9.38/bin/quarto.js:2953:24)
        ...
        at expandGlobSync (quarto.js:3092:18)
        at resolveGlobs (quarto.js:8145:24)
        at resolvePathGlobs (quarto.js:8071:10)
        at projectResourceFiles (quarto.js:78220:35)
        at projectContext (quarto.js:92058:22)

### Geen instelling houdt hem eruit: 15 van 15

Een mini-project (`_site_en_werk/pers_nacht/mini.sh`) met dezelfde dichte map. Elke variant
liep erin, met afloop 1:

    render index.qmd                             afloop 1  LOOPT IN .claude/
    render *.qmd                                 afloop 1  LOOPT IN .claude/
    render /*.qmd                                afloop 1  LOOPT IN .claude/
    render sub/*.qmd                             afloop 1  LOOPT IN .claude/
    render *.qmd + .gitignore .claude/           afloop 1  LOOPT IN .claude/
    geen render-lijst                            afloop 1  LOOPT IN .claude/
    res CNAME                                    afloop 1  LOOPT IN .claude/
    res /CNAME                                   afloop 1  LOOPT IN .claude/
    res oefenboeken/**                           afloop 1  LOOPT IN .claude/
    res /oefenboeken/**                          afloop 1  LOOPT IN .claude/
    res !.claude/**                              afloop 1  LOOPT IN .claude/
    res !/.claude/**                             afloop 1  LOOPT IN .claude/
    res !*.md                                    afloop 1  LOOPT IN .claude/
    res CNAME + .gitignore .claude/              afloop 1  LOOPT IN .claude/
    res CNAME + .gitignore .claude/worktrees/    afloop 1  LOOPT IN .claude/

Het duidelijkste geval is het eerste: alleen `index.qmd`, en geen enkele bijlage.

### Waarom, in de code van Quarto 1.9.38

Gelezen in `~/.local/quarto-1.9.38/bin/quarto.js`. Een agent heeft dezelfde bestanden in de
broncode op GitHub gelezen (tag `v1.9.38`), en kwam op hetzelfde uit.

- `projectResourceFiles` (regel 78213–78236) plakt bij elke bouw met een uitvoermap Quarto's
  eigen uitsluitingen achter de bijlage-globs: `kQuartoIgnore.map((entry) => "!" + entry)`.
  Volgens de broncode zijn dat `/.quarto/` en `**/*.quarto_ipynb`. De enige map die de
  wandeling overslaat, is de uitvoermap: `const exclude = outputDir ? [outputDir] : [];`.
- `resolveGlobs` (regel 8090–8150) loopt een `!`-regel **apart** af en trekt hem pas daarna
  af (`const excludeFiles = expandGlobs(excludeGlobs)`). Een `!`-regel zonder `/` vooraan
  wordt `**/…`. Dat is de hele boom.
- `walkSync` (regel 2928–2992) slaat alleen over wat in `skip` staat, en dat is alleen de
  uitvoermap. Bij elke submap begint hij met een `stat`. Is die map net weg, dan krijg je
  `NotFound ... stat`, precies de melding van vannacht.
- Quarto leest `.gitignore` nergens om een wandeling in te korten. Hij leest hem alleen om er
  zijn eigen regels in bij te zetten (`gitignoreEntries` geeft een vaste lijst terug).

### Wat er vannacht gebeurde

Waarschijnlijk, uit de melding en de toetscode afgeleid, niet nagemeten op het moment zelf.
`taalpers` draaide in zijn werkkopie `_tools/tests/publiceer_en_werkruimte_test.sh`. Die zet
een wegwerpkloon neer onder `_site_en_werk/proef_werkruimte/` en haalt hem weer weg
(regel 73: `rm -rf "$P"`). Op hetzelfde moment liep C's `naar_buiten.sh --productie`, in de
gedeelde checkout, door `.claude/worktrees/taalpers/_site_en_werk/proef_werkruimte/`. Een
bestand dat bij het afroepen van de map nog bestond, was weg toen hij het opende. Dit hangt
dus af van wat een andere zetter op dat moment doet. Daarom ging het niet elke keer mis.

## 2. De reparatie

**`_tools/schone_bouw.py --uit <map> -- <quarto-argumenten>`**

1. Kopieer de werkkopie naar `$TMPDIR/countcamp_schone_bouw_*/`. `.claude/` slaat hij over
   op elke diepte; `.git`, `.quarto`, `_site` en `_site_*` alleen bovenaan.
2. Draai daar `quarto <argumenten>`, met dezelfde omgeving (`QUARTO_PROFILE` gaat mee).
3. Bij afloop 0: haal `<map>` in de repo weg en zet die uit de kopie ervoor in de plaats.
   Bij een fout of een signaal blijft `<map>` in de repo zoals hij was. `--uit` moet `_site`
   of `_site_<iets>` zijn, anders weigert hij (afloop 3). Een signaal (Ctrl-C, afgeschoten)
   geeft hij door aan quarto. Daarna wacht hij en ruimt hij de kopie op.

Wie bouwt er nu doorheen (`79324d6`):

| plek | was | is |
|---|---|---|
| `naar_buiten.sh --lokaal` | `QUARTO_PROFILE=spook quarto render` | `QUARTO_PROFILE=spook python3 _tools/schone_bouw.py --uit _site -- render` |
| `naar_buiten.sh --productie` | `quarto render >/dev/null` | `python3 _tools/schone_bouw.py --uit _site -- render >/dev/null` |
| `publiceer_en.sh` `nlbouw()` (3× per run) | `quarto "${args[@]}"` | `python3 "$REPO/_tools/schone_bouw.py" --uit "${2:-_site}" -- "${args[@]}"` |
| `en_bouw.py bouw` | `["quarto","render","--profile",profiel]` | `[sys.executable, …/schone_bouw.py, "--uit", "_site_en", "--", "render", "--profile", profiel]` |

In `_quarto-nl.yml` staat nu bij `"!.claude/**"` dat die regel `.claude/` uit de uitvoer
houdt, en niet uit de wandeling. De regel zelf blijft staan, voor wie met de hand bouwt.

**Zelfde uitvoer.** Ik heb dezelfde stand op twee manieren gebouwd, ter plaatse en via de
schone bouw, en de twee `_site`'s naast elkaar gelegd (`diff -rq`):

    profiel spook:  ter plaatse 1673 bestanden, schoon 1673 — aantal verschillen: 0
    profiel echt:   ter plaatse 1673 bestanden, schoon 1673 — aantal verschillen: 0
    schone bouw: ... (kopie zonder .claude/, .git, .quarto, _site*: 1839 bestanden, 0.3s)

Een bouw duurt zo ongeveer een seconde langer: 7 s in plaats van 6 s (spook), 9 s tegen 9 s
(echt).

### Bijtproef, in deze werkkopie, zoals de opdracht vroeg

`_site_en_werk/pers_nacht/bijtproef.sh`: proefboom onder `.claude/worktrees/_proef/` met een
`.qmd`, `speeltjes/proef.html`, `oefenboeken/ts/proef.html`, `en/proef.html`, `CNAME`, twee
links die nergens heen wijzen, en de dichte map `gesloten/`.

    proefboom: 9 bestanden/links onder .claude/worktrees/_proef, afdruk 2491c94661254c9c; .claude/worktrees/_proef/gesloten dicht (chmod 000)

    == MET de reparatie: bash _tools/naar_buiten.sh --lokaal
      afloop 0
      | 269:schone bouw: quarto render  in /var/folders/_7/.../countcamp_schone_bouw_ozgunqyb/pers_nacht  (kopie zonder .claude/, .git, .quarto, _site*: 1839 bestanden, 0.3s)
      | 288:schone bouw: _site/ terug in de repo (1673 bestanden)
      _site/.claude bestaat: nee
      bestanden in _site/ met PROEF_PERS_NACHT: 0
      bestanden in _site/ in totaal: 1673
      .claude/worktrees/_proef/index.html gebouwd: nee

    == ZONDER de reparatie: naar_buiten.sh uit eac21b8 (bouwt ter plaatse)
      afloop 1
      | 269:ERROR: PermissionDenied: Permission denied (os error 13): readdir '/Users/ben/Documents/Ben_OS/countcamp_site/.claude/worktrees/pers_nacht/.claude/worktrees/_proef/gesloten'

    proefboom na afloop: afdruk 2491c94661254c9c (gelijk); mtimes gelijk

    BIJTPROEF: de reparatie houdt Quarto uit .claude/, en zonder reparatie bijt de proef.

`publiceer_en.sh --nakijken` en `publiceer_en.sh --alleen-spook` gaven met dezelfde dichte map
ook afloop 0. Daarmee lopen `nlbouw` (Nederlands, echt en spook) en `en_bouw.py bouw` (Engels)
er ook langs.

### De blijvende toets: `_tools/tests/schone_bouw_test.sh` — 17 van 17

Die draait in een wegwerpkloon onder `_site_en_werk/`, met twee dichte mappen: één bovenaan
(`.claude/worktrees/_proef/`) en één dieper, onder een bijlage-glob (`oefenboeken/.claude/`).

    ok    1 --lokaal: afloop 0 (moet 0)
    ok    1 bestanden in _site/ uit de proefboom (merkteken PROEF_SCHONE_BOUW): 0 (moet 0)
    ok    1 de 14 bestanden van de proefboom onaangeroerd (sha256 a98dfe5d472d4a78 -> a98dfe5d472d4a78)
    ok    2 --uit en: afloop 3 (moet 3), met de reden 'geen bouwmap'
    ok    3 naar_buiten.sh, publiceer_en.sh en en_bouw.py: geen quarto-aanroep buiten schone_bouw.py
    ok    4 --lokaal ter plaatse: afloop 1 (moet niet 0), loopt vast op .claude/worktrees/_proef/gesloten
    ok    4 --lokaal ter plaatse: afloop 1 (moet niet 0), loopt vast op oefenboeken/.claude/gesloten
    ok    4 zaak 3 ziet de teruggezette bouw ter plaatse in naar_buiten.sh (afloop 1, moet 1)
    ok    4 zaak 3 ziet een kale quarto-aanroep in en_bouw.py (afloop 1, moet 1)
    17 van 17 toetsen goed

Zaak 3 kijkt of iemand later weer een kale `quarto render` in een van de drie scripts zet. In
`en_bouw.py` leest hij de echte aanroepen uit de syntaxboom. Een docstring of een regel als
`zeg("$ quarto render")` telt dus niet mee.

### Wat de reparatie NIET dekt

- **Een `quarto render` of `quarto preview` met de hand in de gedeelde checkout** loopt nog
  steeds door `.claude/worktrees/`. Die gaat buiten de scripts om. Het echte begin van het
  probleem is dat de werkkopieën ín de projectmap staan. Zie verrassing 1.
- **De grootte van de kopie in de gedeelde checkout heb ik niet gemeten.** Mijn gereedschap
  mag daar niet lezen. In deze werkkopie: 1839 bestanden, 0,3 s. De kopie neemt alles mee
  wat bovenaan staat, behalve `.claude`, `.git`, `.quarto` en `_site*`. Staat er in de
  gedeelde checkout bovenaan iets groots dat niet in git zit, dan komt dat ook mee. De eerste
  `--productie` drukt de telling en de tijd af op de regel `schone bouw: …`; kijk daar één keer
  naar.
- De GitHub Action bouwt met een kale `quarto render`, in een verse kloon. Daar staat geen
  `.claude/`, dus daar verandert niets.

## 3. Nederlandse pers

    $ cd ~/Documents/Ben_OS/countcamp_lab/uni_leiden/psychologie/ts_oefenboek
    $ LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 bash _werk/naar_site.sh --site <werkkopie pers_nacht>
    afloop 0

De laatste regels:

      ontbrekende assets: 0
      taalstukken: 9 bladzij(den) met een losse tweeling in taalparen.tsv, 9 bijgezet, 0 fout
      taalstukken aan de overkant (buiten deze map): 0 niet in orde
      doorstuurders onder oefenboeken/ts/: 0 teruggezet, 0 ververst, 0 stonden er nog
    resultaat: 7.1MB
    ✅ Compleet en gevalideerd. Volgende stap: bash _tools/naar_buiten.sh --nakijken, dan committen en leveren met --productie.
    Klaar in /Users/ben/Documents/Ben_OS/countcamp_site/.claude/worktrees/pers_nacht (niets gecommit, niets gepusht).

Wat er veranderde (`7e7d545`): weken 4, 5 en 7, `search.json`, twee nieuwe figuren
(`04_categorisch_files/figure-html/fig-tonnen-1.png`, `fig-gelijk-1.png`) en twee tabel-PDF's.
De PDF's verschillen alleen in hun aanmaakdatum: na het uitpakken van alle stromen zijn ze
inhoudelijk gelijk (44 en 52 stromen, 0 anders; `CreationDate` 21-11 21:15 → 22-11 00:46).
Ik heb ze meegecommit zoals de pers ze maakte, net als bij de vorige pers.

**Hoefde `taalonderdelen.py los` nog met de hand? Nee.** Ik heb het niet gedraaid.
`publish_workbook.py` zette de stukken zelf terug ("9 bijgezet, 0 fout"), en daarna gaf
`taalonderdelen.py los --controleer` afloop 0 met "34 nagelopen, 0 gat(en)". Wat `taalpers`
erover beloofde, klopt dus.

### Week 4 en week 5, in de gebouwde site

`_site_en_werk/pers_nacht/check_nl.py` leest de bladzijden in de repo (`oefenboeken/ts/`) en
in een verse `_site/` (gebouwd door `publiceer_en.sh --alleen-spook`, stap 1, op de stand mét
de pers):

    == _site/oefenboeken/ts
      week 4 fig-tonnen: id 1x, png-verwijzing 1x, png bestaat (88148 bytes) -> ok
          bijschrift: Figuur 6: Oranje is koffie én snel, en elk vlak is zo groot als zijn aantal: ...
      week 4 fig-gelijk: id 1x, png-verwijzing 1x, png bestaat (77178 bytes) -> ok
          bijschrift: Figuur 1: Links de telefoontabel van deze week, .50 tegenover .25. ...
      week 5 vraag 3: Een t-toets voor twee onafhankelijke groepen geeft t(48) = 2.00. Hoe groot is η²?
          opties: .04 / .08 / .92 / 2.00  (verwacht .04 / .08 / .92 / 2.00) -> ok
    FOUTEN: 0

Week 7 vraag 24 (de naam van het kader) heb ik niet nagekeken. De opdracht vroeg er niet
naar.

## 4. Engelse pers: NIET geperst

    $ LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 bash en/_werk/naar_site_en.sh --site <werkkopie pers_nacht>
    afloop 1
    == 4. alle Engelse wachters
        10 -> afloopcode 0
         2 -> afloopcode 1
         1 2 wachter(s) met een afloopcode boven 0.
    STOP: een Engelse wachter zakte (afloop 1). Het hele verslag: /var/folders/_7/jhw9sjdx3j5g3fxmnsfwy7mm0000gn/T/ts_en_wachters.YFmIufHf6J

De rode regels, letterlijk uit dat verslag:

    BIJ TE WERKEN: 04_categorisch/04_categorisch.qmd: uni_leiden/psychologie/ts_oefenboek/04_categorisch/04_categorisch.qmd veranderde 4 keer na c111d55c -- laatste: 6dedff8d 2026-11-21 TS week 4: figuren na de bevestigingsronde, met rapport (ts_figuren2)
    BIJ TE WERKEN: 05_effect_power/05_effect_power.qmd: uni_leiden/psychologie/ts_oefenboek/05_effect_power/05_effect_power.qmd veranderde 9 keer na 0d9b7168 -- laatste: e4084b69 2026-11-21 TS week 5 vraag 4, lezersronde 4: de hele trede bij φ
    BIJ TE WERKEN: 07_toetskeuze/07_toetskeuze.qmd: uni_leiden/psychologie/ts_oefenboek/07_toetskeuze/07_toetskeuze.qmd veranderde 5 keer na 578e8543 -- laatste: 0ddab658 2026-11-21 TS week 7: wacht op de getypte vraagnummers naar de rangsomvraag [geen-vertaling]
    ...
      6 getallen 05_effect_power/05_effect_power.html: 269 wiskundegetallen NL tegen 259 EN, 42 getallen in de R-uitvoer NL tegen 42 EN -- 10 fout
    ...
      10 GAT(EN):
        - 05_effect_power/05_effect_power.html: wiskundegetal '48': 3 keer in het Nederlands, 1 in het Engels
        - 05_effect_power/05_effect_power.html: wiskundegetal '52': 2 keer in het Nederlands, 1 in het Engels
        - 05_effect_power/05_effect_power.html: wiskundegetal '.04': 1 keer in het Nederlands, 0 in het Engels
        - 05_effect_power/05_effect_power.html: wiskundegetal '.09': 3 keer in het Nederlands, 2 in het Engels
        - 05_effect_power/05_effect_power.html: wiskundegetal '.92': 1 keer in het Nederlands, 0 in het Engels
        - 05_effect_power/05_effect_power.html: wiskundegetal '100': 3 keer in het Nederlands, 1 in het Engels
        - 05_effect_power/05_effect_power.html: wiskundegetal '2.00': 6 keer in het Nederlands, 4 in het Engels
        - 05_effect_power/05_effect_power.html: wiskundegetal '3.00': 1 keer in het Nederlands, 0 in het Engels
        - 05_effect_power/05_effect_power.html: wiskundegetal '3.33': 1 keer in het Nederlands, 0 in het Engels
        - 05_effect_power/05_effect_power.html: wiskundegetal '9.00': 4 keer in het Nederlands, 1 in het Engels
    -> afloopcode 1

    === Engels: bijtproef van de Engelse wachters ===
      ZAKT  ongeschonden kopie schoon voor _toets_en.py --render (afloop 1)
                (dezelfde acht week-5-getallen)
    37 proeven (9 schoon, 28 kapot), 1 niet zoals geëist.
    -> afloopcode 1

De tweede rode wachter is geen tweede fout. De bijtproef eist dat een ongeschonden kopie
schoon is, en die kopie heeft dezelfde week-5-gaten. Een voorbeeld van zo'n gat: in het
Nederlands staat bij vraag 3 de fout-uitleg "C zet *df* boven de streep: 48/52 = .92". Het
Engels heeft vraag 3 nog met de oude opties, dus `.92` komt er 0 keer in voor.

De pers stopt bij de eerste rode stap. `publish_workbook.py` (stap 5) is dus nooit gedraaid,
en `git status` was daarna leeg. **`en/` staat byte voor byte zoals op site-main `eac21b8`.**

## 5. Poorten op de eindstand (`2949355`, git status leeg)

    $ python3 _tools/taalonderdelen.py --controleer   -> afloop 2
        | usage: taalonderdelen.py [-h] {regels,los,ruim} ...
        | taalonderdelen.py: error: the following arguments are required: cmd
    $ python3 _tools/taalonderdelen.py los --controleer   -> afloop 0
        |   losse bladzijden: 34 nagelopen, 0 gat(en)
        |   buiten de tabel: 427 .html nagelopen, 0 met een taalstuk
    $ bash _tools/publiceer_en.sh --nakijken   -> afloop 0
        |   geen gaten
        | Wat er in en/ staat, is in orde.
    $ bash _tools/naar_buiten.sh --nakijken   -> afloop 0
        |   Alle 259 bladzijden dragen de teller.
        |   Alle 181 doorstuurders uit de tabel staan er en wijzen naar een bestaande bladzij; de 23 andere ook.
        |     losse bladzijden: 34 nagelopen, 0 gat(en)
        | Alle poorten staan groen. --productie zou hierop niet struikelen.

De vorm uit de opdracht (`taalonderdelen.py --controleer`) kent het gereedschap niet: afloop 2,
zonder dat er iets is gekeken. De vorm die `naar_buiten.sh` zelf gebruikt, is
`taalonderdelen.py los --controleer`.

## 6. Toetsen die ik gedraaid heb

| toets | uitslag | opmerking |
|---|---|---|
| `schone_bouw_test.sh` (nieuw) | 17 van 17 | met bijtproef, zie §2 |
| `publiceer_en_werkruimte_test.sh` | 22 van 22 | geval 7: de nep-quarto schiet nu het script zelf af (zie onder) |
| `publiceer_en_werkruimte_mutatieproef.sh` | 11 van 11 gevangen | vóór mijn aanpassing: 1 ZORGELIJK (verrassing 3) |
| `naar_buiten_teller_test.sh` | 73 van 73 | was 72 van 73: zaak 5g zocht de tekst `quarto render` |
| `naar_buiten_poort_mutatieproef.sh` | alle mutaties opgemerkt | |
| `plankwacht_test.sh` · `tellers_test.sh` · `doorstuurders_test.sh` · `en_na_manifest_test.sh` | 48 · 31 · 27 · 16, alles groen | |
| `en_boek_lab_test.py` · `en_werkboek_lab_test.py` | 48 van 48 · 65 van 65 | eerst KON NIET KIJKEN (geen `_site_spook/`); na `publiceer_en.sh --alleen-spook` groen |
| `en_schil_test.py` | 19 van 19 | |
| `en_boek_lab_mutatieproef.sh` · `en_werkboek_lab_mutatieproef.sh` | 19 van 19 · 24 van 24 gevangen | |
| `taalwissel_negeer_test.py` | 37 van 40 | **3 vals rood**, niet door de reparatie (verrassing 6) |
| `taalbalk_browser_test.py`, `teller_hostwacht_chrome.py`, `teller_hostwacht_test.ts` | niet gedraaid | hebben Chrome of Deno nodig |

Twee aanpassingen aan bestaande toetsen, zodat ze blijven meten wat ze zeggen:

- `naar_buiten_teller_test.sh` 5g zocht in `--productie` en `--lokaal` de letterlijke tekst
  `quarto render` als bouwstap. Nu zoekt hij `_tools/schone_bouw.py --uit _site -- render`.
  Komt er een kale `quarto render` terug, dan zakt 5g.
- `publiceer_en_werkruimte_test.sh` geval 7 schoot `$PPID` af, de ouder van quarto. Dat is nu
  de schil en niet het script, en dan meet het geval iets anders. De nep-quarto zoekt
  `publiceer_en.sh` nu zelf op, en kan nooit pid 1 raken. Geval 7 eindigt weer op
  *"NIET KLAAR (afloop 3): onderbroken door een signaal"*.

## 7. Voor C

- **Samenvoegen:** de tak ligt op `eac21b8` (site-main is niet verder gegaan:
  `git rev-list --count HEAD..main` = 0). Daarna `naar_buiten.sh --productie`. Let daarbij
  één keer op de regel `schone bouw: … N bestanden, X s`. Dat is de eerste meting in de
  gedeelde checkout.
- **Weggooien:** mijn proefboom `.claude/worktrees/_proef/` in déze werkkopie (9 bestanden of
  links, 8 mappen, alles van mij) kon ik niet weghalen: `rm -r` werd geweigerd. Hij staat in
  `.gitignore`, er is geen map meer dicht, en de schone bouw slaat hem over, dus hij is
  onschuldig. Het script met een proefrun staat klaar:
  `bash .claude/worktrees/pers_nacht/_site_en_werk/pers_nacht/proefboom_weg.sh`. Zonder vlag
  somt het alleen op; met `--doe` haalt het weg. Ook als vraag op het bord.
- **Het Engels:** wacht op `en_ts_bij4`. Lees daarbij verrassing 4: de getallenwachter kijkt
  alleen naar week 5.

## Verrassingen

1. **Geen instelling kan Quarto uit `.claude/` houden. Het enige wat werkt, is dat de
   werkkopieën niet in de projectmap staan.** De schone bouw dekt elke bouw die via onze
   scripts loopt. Een `quarto render` of `quarto preview` met de hand in de gedeelde checkout
   dekt hij niet. Ik heb één ander middel gemeten: als `.claude/worktrees` een *symlink* is
   (een wegwijzer naar een map elders), volgt Quarto hem niet. Met de werkkopieën achter zo'n
   wegwijzer naar een dichte map: afloop 0. Dezelfde boom als echte map: `PermissionDenied`,
   afloop 1 (`_site_en_werk/pers_nacht/symlink.sh`). Dat zou elke bouw dekken, ook die met de
   hand, en ook in het lab. **Niet gemeten:** of `git worktree`, `claude --worktree`, de
   grenswacht en `zetter.sh` werken met zo'n wegwijzer. Dat is een besluit voor de drukkerij,
   niet iets voor deze tak.
2. **De regel `"!.claude/**"` deed het omgekeerde van wat zijn commentaar beloofde.** Volgens
   dat commentaar (25-10) gaf hij "0, ook voor de geneste". Dat klopt voor de uitvoer. Maar
   juist om te vinden wat hij moet weglaten, loopt Quarto `.claude/` helemaal af. Het
   commentaar zegt dat nu zelf. Het is hetzelfde patroon als `taalpers` verrassing 3:
   *"Quarto slaat mappen met `_` of `.` over"* bleek niet waar.
3. **Een groene mutatieproef was voor een deel decor.** De mutatie *"de Engelse bouw zet en/
   niet terug"* werd "gevangen" omdat geval 8 los **altijd** zakte, ook zonder mutatie en ook
   vóór vandaag. Een verse kloon heeft geen `_spooksite/banner.html`, want die balk wordt door
   de bouw geschreven en staat niet in git. Gemeten: geval 8 los, zonder mutatie, gaf
   `Error resolving include-before- unable to open file _spooksite/banner.html`. In de hele
   reeks merkte niemand dat, omdat een eerder geval de balk al had geschreven. Geval 8 schrijft
   de balk nu zelf (los: 2 van 2). De twee mutaties die nu achter de schone bouw staan, halen
   die bouw er ook bij weg. Daarna valt elk om de reden die hij noemt: 1639 bestanden in
   `_site/.claude/`, en *"en/ niet precies als ervoor"*.
4. **De Engelse getallenwachter kijkt alleen naar week 5, terwijl week 4 en 7 ook achterlopen.**
   Week 4 (de twee nieuwe figuren) en week 7 (vraag 24) staan als *BIJ TE WERKEN* in het
   verslag, maar de getallen zijn daar gelijk ("265 tegen 265", "301 tegen 301", 0 fout), en
   *BIJ TE WERKEN* houdt de pers niet tegen. Het bewijs staat in hetzelfde verslag: met drie
   BIJ TE WERKEN-regels zegt de wachter toch *"1 nl_bron: 9 bladzijde(n), 0 fout"*, en alle
   10 gaten die hij telt, zijn week-5-getallen. Brengt `en_ts_bij4` alleen week 5 bij, dan wordt
   de wachter groen terwijl week 4 nog zonder de nieuwe figuren staat. **Groen is hier dus geen
   bewijs dat het Engels gelijkloopt.** Kijk bij de volgende Engelse pers naar de
   BIJ TE WERKEN-regels, niet alleen naar de afloop.
5. **`herstel` in `en_bouw.py` heeft bij de bouw niets meer te doen.** In de kopie verplaatst
   Quarto `en/*.html` daar en niet in de repo, dus geval 8 meldt nu "0 teruggezet". Ik heb het
   als tweede slot laten staan. Het wordt nog geproefd, maar alleen samen met een bouw ter
   plaatse (verrassing 3).
6. **`taalwissel_negeer_test.py` staat rood bij elke pers met nieuwe inhoud.** De toets bouwt
   de lokale `main` en `HEAD`, en eist dat het Nederlands gelijk blijft. Alles wat hij als
   anders noemde, was uitvoer van de pers van vannacht: weken 4, 5 en 7, de twee nieuwe
   PNG's, de PDF's en `search.json`. Twee mutatiezaken bleven daardoor "ok" om de verkeerde
   reden: *"een kleur in de stijl van de balk (over.html): de wachtrij stopt (anders:
   oefenboeken/ts/04_categorisch/04_categorisch.html)"*. Hij zag het verschil van de pers en
   niet de mutatie. Dit is hetzelfde patroon als `taalpers` verrassing 7. Voor een
   taalwissel-tak klopt de toets; voor een pers-tak niet.
7. **De opdracht noemde een commando dat niet bestaat:** `taalonderdelen.py --controleer`
   geeft afloop 2, met een gebruiksmelding en zonder te kijken. Wie op "niet 0" let en niet
   leest, denkt dat er gaten zijn.
8. **Elke Nederlandse TS-pers schrijft twee PDF's opnieuw met alleen een nieuwe aanmaakdatum.**
   Ze zijn inhoudelijk gelijk, maar git ziet ze als gewijzigd. Elke pers commit dus twee
   binaire bestanden van zo'n 60 KB. Dat is onschuldig, maar wie `git status` leest als "wat
   veranderde er aan het boek", leest twee keer mis.
