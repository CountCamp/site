# Sitecheck 10-8-2026 — wat beweert de site, en wat is er werkelijk

Proefdruk van spoor `sitecheck`. Niets gecommit, niets gepusht.

Onderzocht: alle `.qmd`-bladzijden, 210 `.html`-bladzijden in `manuscript/`,
`oefenboeken/` en `speeltjes/`, de verhalenpagina tegen de dertien
hoofdstukbladzijden, en de **live** site op countcamp.org.

> De bestandsnaam van dít bestand begint met een underscore. Dat is met opzet:
> Quarto rendert elke gewone `.md` in de projectmap tot een publieke bladzij.
> Zie punt 3 hieronder.

---

## Wat er wél klopt — eerst het goede nieuws

De rotatie van vanmiddag (welnee H5→H7, Bestaat het echt? H6→H5, Hoe beslis je?
H7→H6) is **overal** meegegaan:

| controle | uitkomst |
|---|---|
| titel/nummer-paren over 210 bestanden | **0 fout** — geen enkele plek noemt een hoofdstuktitel bij een verkeerd nummer |
| `verwijzingen_kaart.py` | 0 FOUT, 9 LET OP (alle negen bekend en verklaard) |
| de elf doorverwijs-stubs in `manuscript/werkplaats/` | alle elf kloppen, ook live — de vier die sinds 21-7 logen zijn vanmiddag 13:47 gerepareerd |
| verhalen: 23 stuks | allemaal bij het juiste hoofdstuk; elk verhaal komt letterlijk terug in de hoofdstukbladzij zelf; geen verhaal in een hoofdstuk dat op de verzamelpagina ontbreekt |
| kapotte links op de bladzijden zelf | 0 |
| CSS-klassen uit de `.qmd`'s | alle gedefinieerd in `styles.css` |
| oefenboeken H0 t/m H12 + Schil, in alle drie de broertjes | oefeningnummering volgt de nieuwe volgorde |
| dataset-download per hoofdstuk | elk blok heeft er een; `gepakt` staat in `diamantjes.csv` én in H12 |
| bron versus live | **niet uit elkaar gelopen** — de Action heeft alles doorgezet |

De enige uitzondering op dat laatste is de CSS-restyle van de inhoudsopgave in
`manuscript/index.qmd` (16:16, nog niet gecommit). Dat is werk van een ander
spoor, niet aangeraakt. De *inhoud* van de inhoudsopgave — dertien hoofdstukken,
geen secties — staat wél live.

---

## Wat er niet klopt, op volgorde van hoe erg het is voor een bezoeker

### 1. LIEGT — het cv zegt dat het boek elf hoofdstukken heeft ✅ gerepareerd

`cv.qmd` r.43 en `cv-en.qmd` r.43. Er zijn er **dertien** (H0 t/m H12), zoals de
boekpagina zelf zegt. Stond ook zo live.

Elf klopte tot 21-7; sindsdien zijn er twee hoofdstukken bijgekomen en is er twee
keer gerenummerd. De boekpagina ging elke keer mee, het cv niet — dat is de
bladzij waar niemand aan denkt als het boek verandert.

Gerepareerd naar *Dertien hoofdstukken* / *Thirteen chapters*, en gerenderd:
`_site/cv.html` en `_site/cv-en.html` tonen het nieuwe getal.

### 2. STUK — 21 schermafdrukken ontbreken in de JASP-handleiding

Geven ook live een 404, dus een bezoeker ziet stukgelopen plaatjes.

- `manuscript/handleiding/hoofdstuk-1-...html` — `Bronnen/JASP Pictures/Ch1JASP/opgave14.png`, `opgave16.png`, `opgave17.png`
- `manuscript/handleiding/hoofdstuk-2-...html` — `main_files/figure-html/antwoord51 -1.png` t/m `-3.png`
- `manuscript/handleiding/hoofdstuk-5-...html` — vijftien uit `Bronnen/JASP Pictures/`, o.a. `jaspScatterplotStart.png`, `5qol12.png`, `5qol21.png`, `5qol43.png` t/m `5qol47.png`

De bestanden zitten niet in de repo, ook niet onder een andere schrijfwijze — er
staan wél `opgave13.png` en `opgave1.14.png`, maar geen enkele variant van 1.4,
1.6 en 1.7. Dit is dus niet met een padje recht te zetten; de plaatjes moeten
ergens vandaan komen. **Niet gerepareerd — dit is een vondst, geen klusje.**

Het valt op omdat de handleiding op de oefenboeken-bladzij wordt aangeprezen als
*"de beproefde handleiding"* en *"leesbaar en compleet"*.

### 3. VOORLEGGEN — twee interne notities staan publiek en in Google's sitemap

`https://countcamp.org/DUBBELINGEN.html` (200) en
`https://countcamp.org/manuscript/werkplaats/LEESMIJ.html` (200).

Allebei staan ze in `sitemap.xml` én in `search.json`, dus ze komen boven in de
zoekbalk van de site zelf. Een bezoeker die "diamantjes" of "hoofdstuk" intikt,
krijgt het dubbelingen-register en het logboek van de doorverwijs-stubs te zien.

Oorzaak: Quarto maakt van elke gewone `.md` in de projectmap een bladzij.
`README.md` en `_HEROPSTART.md` ontsnappen (Quarto slaat `README` en alles met
een underscore over), deze twee niet.

Uitweg, als Ben ze niet publiek wil: hernoemen naar `_DUBBELINGEN.md` en
`_LEESMIJ.md`, óf in `_quarto.yml` onder `project:` een `render:`-lijst zetten
met een `"!*.md"`-regel. Het eerste is één handeling, het tweede vangt ook
toekomstige notities. **Beslissing van Ben — niet zelf gedaan.**

### 4. VOORLEGGEN — de sitemap kent het boek niet

`sitemap.xml` heeft veertien adressen: de zeven gewone bladzijden, het cv in twee
talen, de LICENSE, de twee notities uit punt 3, en de twee index-bladzijden van
oefenboeken en speeltjes. **Geen enkel hoofdstuk.** Niet h0 t/m h12, niet
`verhalen.html`, niet de handleiding, niet de broertjes, niet één speeltje.

Dat komt doordat al die bestanden in `_quarto.yml` onder `resources:` staan:
Quarto kopieert ze, maar rekent ze niet als bladzij, dus ze belanden niet in
`sitemap.xml` en niet in `search.json`. Voor Google is countcamp.org daarmee een
cv met een paar overzichtspagina's, en het boek zelf bestaat niet.

Dit is geen fout die vandaag ontstaan is, maar het is wel de grootste afstand
tussen wat de site *is* en wat de site *laat zien*. Een aparte sitemap voor de
hoofdstukken naast de gegenereerde is een klein scriptje. **Voorleggen.**

### 5. SLORDIG — de oefenboek-tegels zijn wéér uit elkaar gelopen

`DUBBELINGEN.md` waarschuwt hiervoor en meldt dat ze op 10-8 zijn gelijkgetrokken.
Twee blijven verschillen:

| | `manuscript/index.qmd` | `oefenboeken/index.qmd` |
|---|---|---|
| JASP | "Hetzelfde, maar in **JASP** —" | "Dezelfde stof in **JASP** —" |
| GGZ-VS | "De begrippen die je in onderzoek tegenkomt — van meetniveau … — elk in een vaste zes-slag" | "Van meetniveau … , elk in een vaste zes-slag" |
| GGZ-VS slot | "een register om een tekentje op te zoeken" | "een register" |

Kan ook bewust zijn (korter op de boekpagina). **Niet aangeraakt — vraag aan Ben:
zijn dit kopieën die gelijk moeten blijven, of twee eigen teksten?** Als het
eerste: dan is dit het derde keer in twee dagen en verdient het de uitweg die
`DUBBELINGEN.md` zelf al noemt — één bron, tegels genereren.

### 6. SLORDIG — werkboek of oefenboek?

De navigatie zegt *Oefenboeken*, de bladzij heet *Oefenboeken*, maar er staat op
drie plekken *werkboeken* waar de broertjes bedoeld worden:

- `over.qmd` r.9 — "Je vindt hier [werkboeken](oefenboeken/index.qmd) in SPSS, R en JASP"
- `diensten.qmd` r.9 — "De werkboeken op deze site zijn gratis"
- `diensten.qmd` r.33 — "dezelfde didactiek als de werkboeken hier"

En in `oefenboeken/index.qmd` r.74 en r.78 staat het generiek ("Een werkboek open
je gewoon in je browser"). Waar *Werkboek OZP 1*, *Werkboek MVDA* en het
*GGZ-VS/JASP-werkboek* staan is het een eigennaam en klopt het gewoon.

**Niet aangeraakt** — dit is een woordkeuze, geen fout. Als *oefenboek* het woord
is, dan zijn dit vijf regels.

### 7. SLORDIG — `README.md` beschrijft een site die niet meer bestaat

De mappenkaart noemt `werkboeken/` als de echte overzichtsmap (dat zijn nu
doorverwijs-stubs) en kent `oefenboeken/`, `speeltjes/`, `tabellen/`, `tables/`
en `power/` niet. Het statusbord onderaan heeft nog open vakjes voor "GitHub
Pages repo aangemaakt", "DNS gekoppeld" en "wisi.nl 301" — allemaal aantoonbaar
gedaan. Niet zichtbaar voor bezoekers (Quarto rendert `README.md` niet, zie punt
3), maar het is wel het eerste wat iemand leest die de repo opent.

### 8. SLORDIG — twee bladzijden over hetzelfde onderwerp, één ervan onvindbaar

`gebruik.qmd` ("Wat mag je ermee?") staat in de footer. `LICENSE.md` ("Gebruik
van het materiaal op countcamp.org") staat nergens in de navigatie maar is wel
publiek en wel geïndexeerd. Ze spreken elkaar niet tegen, maar `LICENSE` heeft
twee regels die `gebruik` mist (citeren met bronvermelding; niet verkopen of
onder een andere naam publiceren) en `gebruik` heeft de steun-alinea die
`LICENSE` mist. Staat niet in `DUBBELINGEN.md`. **Voorleggen: één bladzij of
twee, en zo ja, welke linkt naar welke?**

### 9. LOGBOEK — de speeltjes in de broertjes dragen oude nummers in hun naam

`.../speeltjes/w6_trek_interval.html` wordt aangeroepen vanuit oefening **5.1**,
en `w6_schud_verschil.html` vanuit hoofdstuk 9. Alleen de bestandsnamen; de
inhoud en de nummering van de oefeningen kloppen. Een bezoeker ziet het hooguit
in de adresbalk. Het komt uit de uitrol-pers, dus repareren betekent daar een
hernoemtabel bijwerken — niet vanuit de site. Geen haast, wel iets om te weten
bij de volgende hernummering.

---

## Wat ik heb aangeraakt

| bestand | wat |
|---|---|
| `cv.qmd` r.43 | "Elf hoofdstukken" → "Dertien hoofdstukken" |
| `cv-en.qmd` r.43 | "Eleven chapters" → "Thirteen chapters" |

Beide gerenderd en nagekeken in `_site/`. Verder niets — `manuscript/index.qmd`
en de 21 gewijzigde speeltjes-bestanden zijn van andere sporen en zijn met rust
gelaten.
