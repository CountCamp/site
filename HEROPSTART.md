# Heropstart-notitie — CountCamp site live krijgen

> Geschreven 2026-05-30 ~15:20, vlak na een API-overload (529) die de vorige sessie afkapte.
> Doel van die sessie: het OZP 1-werkboek online krijgen op **countcamp.org** via GitHub Pages.

## Waar we stonden (✅ = klaar)

- ✅ **Domeinen** `countcamp.org` + `countcamp.nl` geregistreerd bij TransIP
- ✅ **Repo** `CountCamp/site` aangemaakt, publiek
- ✅ **Billing-slot eraf** — GitHub blokkeerde Actions omdat de nieuwe account geen
  betaalmethode had (géén geldprobleem, puur verificatie). Visa eindigend op **2321**
  toegevoegd, €0 in rekening (publieke repo = gratis Actions). Plan = GitHub Free.
- ✅ **Site staat LIVE**: https://countcamp.github.io/site/ → HTTP 200, met styling,
  werkboeken-pagina laadt. Nu nog het skelet met MVDA-placeholder, nog geen echte inhoud.
- ✅ **gh-pages-branch** handmatig aangemaakt + gepusht (de Action faalde eerst omdat die
  branch nog niet bestond; `quarto publish gh-pages --no-prompt` weigerde 'm aan te maken →
  daarom handmatig gevuld vanuit `_site` + `.nojekyll` + force-push). Pages serveert die branch.
- ✅ **Automatische deploy werkt nu** — elke `git push` naar `main` ververst de site vanzelf
  (workflow staat in `.github/workflows/publish.yml`).

## Wat NU openstaat (we waren net bij A begonnen)

### 👉 Stap A — countcamp.org koppelen (DNS) — HIER WAREN WE MEE BEZIG
Mijn kant, deels gedaan:
- ✅ `CNAME`-bestand geschreven met inhoud `countcamp.org` — **maar nog NIET gecommit/gepusht**
  (`git status` toont 'm als untracked). Eerste actie na herstart: committen + pushen, zodat
  elke deploy het domein onthoudt.
- ⏳ Daarna in GitHub repo-settings → Pages → Custom domain: `countcamp.org` invullen +
  "Enforce HTTPS" aanzetten (kan ik via API of jij in de UI).

Jouw kant — **DNS-records plakken bij TransIP** (staan kant-en-klaar in `README.md`):
```
@      A      185.199.108.153
@      A      185.199.109.153
@      A      185.199.110.153
@      A      185.199.111.153
www    CNAME  CountCamp.github.io.
```
En `countcamp.nl` → 301 web-forwarding naar `https://countcamp.org` (TransIP "URL Doorsturen").
DNS-propagatie kan minuten tot een uur duren; HTTPS-cert van GitHub komt daarna vanzelf.

### ⏳ Stap 7 — OZP 1-werkboek erin
Echte inhoud onder `werkboeken/` zetten i.p.v. het skelet. Bron-werkboeken staan in
`countcamp_lab/uni_leiden/...`. (README plant per-thema gerenderde HTML in `werkboeken/<vak>/`.)

## Geparkeerde vraag van Ben (niet nu)
> "Kunnen we ook mijn oude manuscript hier onderbrengen, zoals het nu op wisi.nl staat?"

Antwoord: **ja, kan.** README plant dit al expliciet — er is al een map `manuscript/` en de
README noemt "Manuscript-schetsen ... een include of een Quarto-book sub-project onder
`manuscript/`". Oppakken wanneer Ben wil.

## Snelle sanity-checks na herstart
- `gh auth status` — ben ik nog ingelogd?
- `cd ~/Documents/Ben_OS/countcamp_site && git status` — CNAME nog untracked?
- `curl -s -o /dev/null -w "%{http_code}\n" https://countcamp.github.io/site/` — nog 200?
