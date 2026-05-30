# Heropstart-notitie — CountCamp site

> Bijgewerkt 2026-05-30 ~17:30. Interne note (underscore = wordt niet gepubliceerd).

## Klaar ✅
- **countcamp.org live over http** (repo CountCamp/site). ⚠️ HTTPS-cert nog NIET geprovisioned (`cert: none` om ~17:00) — waarschijnlijk omdat veel deploys achter elkaar de provisioning telkens resetten. Nu pushes klaar zijn: laten rijpen (~30–60 min), dan `gh api -X PUT repos/CountCamp/site/pages -f https_enforced=true`. Tot die tijd geeft https een cert-waarschuwing; http werkt.
- **DNS** bij TransIP: 4× `@ A` (185.199.108–111.153) + `www CNAME CountCamp.github.io.`. E-mailrecords ongemoeid. (Lokale provider-DNS-cache omzeild door Bens Mac op 8.8.8.8/1.1.1.1.)
- **KAAPA-vormgeving** live: papier-wit (#fdfcf9), Georgia/Helvetica Neue, Tol-Vibrant-accenten per sectie, hero + kleur-kaarten. Tagline: *"De regressieve ruggengraat — statistiek, helder en inzichtelijk. Door Benjamin Telkamp."*
- **OZP 1-werkboek ONLINE**: countcamp.org/werkboeken/ozp1/ — volledig (12 hoofdstukken), 35 MB, mét figuren + styling.
- Auto-deploy: elke push naar `main` → Action `quarto publish gh-pages` → live.

## Hoe OZP online kwam (belangrijk voor de pedagogiek-werkboek-sessie)
De verse `_site`-render van het werkboek was **367 MB** (hoofdstukken 23–71 MB). Oorzaak bleek **niet** de figuren (die zijn klein), maar **één `<link href="data:text/html,...">` per hoofdstuk waarin een volledig HTML-document URL-encoded was ingebakken** (~71 MB ballast). Bron onbekend — waarschijnlijk een Quarto-feature/extensie of iets in `_common/R/figuren.R`. **Aanrader: zoek dit in het werkboek op en zet het uit**, dan rendert het werkboek voortaan vanzelf licht.

**Publiceer-recept (gebruikt, werkt):** kopieer werkboek-`_site` → `countcamp_site/werkboeken/ozp1/`; strip alle `<link ...data:text/html...>` tags (string-find: van `<link` t/m eerste `>`); hernoem `_common`→`common` en `site_libs`→`libs`; `sed` refs (`_common/`→`common/`, `site_libs/`→`libs/`) in alle html/css/json. Dan render countcamp_site + push. (Underscore-/site_libs-mappen worden anders door Quarto genegeerd.) Resultaat: 367 MB → 35 MB.

## Parked
- **countcamp.nl-redirect** → Optie 1 gekozen (mini-GitHub-redirect), nog NIET gebouwd. Plan: apart repo/redirect-page met CNAME countcamp.nl + Ben zet dezelfde DNS-records voor .nl.
- **Manuscript** op de site (er is al een `manuscript/`-plek; README plant Quarto-book sub-project). Ben vroeg of z'n oude wisi.nl-manuscript hier kan — ja.
- **MVDA / Psychometrie / STAT 3** werkboeken nog toevoegen (zelfde recept).

## Sanity-checks
- `gh auth status` · `git -C ~/Documents/Ben_OS/countcamp_site status`
- `curl -s -o /dev/null -w "%{http_code}\n" https://countcamp.org/`
