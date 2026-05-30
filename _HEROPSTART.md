# Heropstart-notitie — CountCamp site

> Bijgewerkt 2026-05-30 ~16:40. Interne note (underscore = wordt niet gepubliceerd).

## Klaar ✅
- **countcamp.org live** via GitHub Pages (repo CountCamp/site). Billing-slot opgelost (Visa ...2321, €0).
- **DNS** bij TransIP gezet: 4× `@ A` (185.199.108–111.153) + `www CNAME CountCamp.github.io.`. E-mailrecords ongemoeid.
- **Custom domain** + CNAME in build (resource in _quarto.yml).
- **KAAPA-vormgeving** live: papier-wit (#fdfcf9), Georgia body / Helvetica Neue koppen, Tol-Vibrant-accenten per sectie, hero + kleur-kaarten. styles.css = volledig.
- Auto-deploy werkt: elke push naar `main` → Action `quarto publish gh-pages` → live.

## Open / parked
- **HTTPS-cert**: GitHub maakt 'm automatisch (was ~16:40 nog `nog geen`). Zodra uitgegeven: `gh api -X PUT repos/CountCamp/site/pages -f https_enforced=true` (Enforce HTTPS). Tot die tijd geeft https een cert-waarschuwing — http werkt.
- **Tagline** nog kiezen. Huidige: *"De regressieve ruggengraat — voor wie helder een onderzoekertje wil worden."* Ben twijfelt; opties #4 en #6 uit de chat waren favoriet. "helder" haakt op *helderheid is een vorm van liefde*.
- **countcamp.nl-redirect** → Optie 1 gekozen (mini-GitHub-redirect), nog NIET gebouwd. Plan: apart repo/redirect-page met CNAME countcamp.nl + Ben zet dezelfde DNS-records voor .nl.
- **Lokale DNS-tip**: Bens Mac/provider cachte oud IP; opgelost door Mac op 8.8.8.8/1.1.1.1 te zetten (System Settings → Network → DNS).

## ⚠️ OZP-online BLOKKADE (belangrijk voor de pedagogiek-sessie)
Het OZP 1-werkboek (`countcamp_lab/uni_leiden/pedagogiek/ozp1_werkboek/2526_werkboek/`) is herstructureerd naar **12 hoofdstukken** (00_fundament t/m 11_chi_kwadraat) met verse `_site/`-render.

Publiceren mislukte om twee redenen — **beide moeten opgelost voordat OZP online kan**:
1. **Veel te zware render**: hoofdstuk-HTML's zijn 23–71 MB (totaal ~367 MB). Oorzaak: een paar figuren staan als gigantische **base64-blobs inline** in de HTML → wijst op veel te hoge `fig-dpi`/figuur-afmeting (en/of embed-resources die feitelijk aanstaat, terwijl _quarto.yml `embed-resources: false` zegt). **Fix in het werkboek**: fig-dpi omlaag (bv. 96–150), figuren extern, dan worden hoofdstukken ~1–2 MB. Vereist R-re-render.
2. **Quarto kopieert de bundel niet**: een pre-gerenderde `_site` in `werkboeken/ozp1/` werd door de site-`quarto render` NIET naar `_site` gekopieerd (bij de losse "Deel 0" lukte dat eerder wél — verschil onbekend; mogelijk grootte of de geneste site-structuur/`search.json`). Bij volgende poging: onderzoek `project: resources:` declaratie, of host het werkboek als eigen gh-pages-subsite en link ernaartoe.

**Publiceer-recept dat wél werkte voor een lichte bundel** (Deel 0): kopieer rendered `_site` → `werkboeken/<naam>/`, hernoem `_common`→`common` en `site_libs`→`libs`, en `sed` de verwijzingen (`_common/`→`common/`, `site_libs/`→`libs/`) in alle html/css/json. (Underscore-/site_libs-mappen worden anders door Quarto genegeerd.)

Status nu: OZP staat op **"komt eraan"** in `werkboeken/index.qmd`; de zware bundel is uit de repo gehaald.

## Sanity-checks
- `gh auth status` · `git -C ~/Documents/Ben_OS/countcamp_site status`
- `curl -s -o /dev/null -w "%{http_code}\n" https://countcamp.github.io/site/`
