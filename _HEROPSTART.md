# Heropstart-notitie — CountCamp site

> Bijgewerkt 2026-05-30 ~18:30. Interne note (underscore = wordt niet gepubliceerd).

## Klaar ✅
- **countcamp.org volledig live over HTTPS** (repo CountCamp/site). Cert `approved`, Enforce HTTPS aan; http→https 303-redirect werkt. www + apex werken.
- **DNS** bij TransIP: 4× `@ A` (185.199.108–111.153) + `www CNAME CountCamp.github.io.`. E-mailrecords ongemoeid. (Lokale provider-DNS-cache omzeild door Bens Mac op 8.8.8.8/1.1.1.1.)
- **KAAPA-vormgeving** live: papier-wit (#fdfcf9), Georgia/Helvetica Neue, Tol-Vibrant-accenten per sectie, hero + kleur-kaarten. Tagline (definitief): *"De regressieve ruggengraat — statistiek, helder en inzichtelijk. Door Benjamin Telkamp."*
- **OZP 1-werkboek ONLINE & grondig opgebouwd**: countcamp.org/werkboeken/ozp1/ — volledig (12 hoofdstukken), 29 MB, mét figuren, styling én de R-helper-broncode (klikbare "bekijk de code"-links resolven). **0 dangling assets** (gevalideerd).
- Auto-deploy: elke push naar `main` → Action `quarto publish gh-pages` → live.

## Het publish-script (gebruik dit voortaan voor werkboeken)
`_tools/publish_workbook.py` — herhaalbaar, gevalideerd. Doet:
1. verse kopie van werkboek-`_site` → `werkboeken/<name>/`
2. hernoemt `_common`→`common`, `site_libs`→`libs` (Quarto negeert underscore/site_libs anders)
3. mergt bron-`_common` (R-helpers etc.) zodat "bekijk de code"-links resolven
4. **str!pt de redundante `<link href="data:text/html,...">` ballast** (zie root-cause)
5. herschrijft asset-refs + **valideert dat élke href/src bestaat** (exit 1 bij gaten)

Gebruik:
```
python3 _tools/publish_workbook.py --src "<werkboek>/_site" --name ozp1
quarto render && git add -A && git commit -m "..." && git push
```
(Resource-glob `- "werkboeken/ozp1/**"` staat al in `_quarto.yml` zodat quarto de map naar `_site` kopieert; voor een nieuw werkboek een eigen glob toevoegen.)

## ⚠️ ROOT CAUSE — voor de pedagogiek-werkboek-sessie (nog op te lossen aan de BRON)
De werkboek-render produceert per hoofdstuk één **redundante `<link href="data:text/html,[heel HTML-document]">`** — ballast die cumulatief groeit (00_fundament ~2 MB → 11_chi ~74 MB; totaal 367 MB). De echte inhoud staat er los van en overleeft strippen volledig.

Vastgesteld in de bron (`countcamp_lab/uni_leiden/pedagogiek/ozp1_werkboek/2526_werkboek/`):
- **géén** lua-filters, `embed-resources: false`, **géén** `self-contained` → niet de oorzaak.
- **Sterkste verdachte: geneste per-hoofdstuk `_quarto.yml`.** Elk hoofdstuk heeft een eigen `_quarto.yml` met `project: type: website, output-dir: _book` — náást de root-`_quarto.yml` (`type: website`, `_site`). Geneste website-projecten + page-navigatie lijken die malformede `<link>` te genereren.
- **Aanbevolen experiment (in een KOPIE van het werkboek):** haal de per-hoofdstuk `_quarto.yml`'s weg (of zet ze om naar gewone `_metadata.yml` zonder `project:`), render opnieuw, check of de `data:text/html`-link verdwijnt. Zo ja → bron is genezen en publiceren wordt triviaal (geen strip meer nodig; script blijft werken, strip wordt dan een no-op).
- Werkboek is **niet onder git** → eerst archiveren/koppie maken vóór structuurwijziging.

## Parked
- **countcamp.nl-redirect** → Optie 1 gekozen (mini-GitHub-redirect), nog NIET gebouwd. Plan: apart repo/redirect-page met CNAME countcamp.nl + Ben zet dezelfde DNS-records voor .nl.
- **Manuscript** op de site (er is al een `manuscript/`-plek; README plant Quarto-book sub-project). Ben vroeg of z'n oude wisi.nl-manuscript hier kan — ja.
- **MVDA / Psychometrie / STAT 3** werkboeken nog toevoegen (zelfde script).

## Sanity-checks
- `gh auth status` · `git -C ~/Documents/Ben_OS/countcamp_site status`
- `curl -s -o /dev/null -w "%{http_code}\n" https://countcamp.org/`
