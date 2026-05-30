# CountCamp — site bron

Quarto-website voor `countcamp.org` (primair) + `countcamp.nl` (redirect) + `wisi.nl` (redirect).

Aangemaakt 2026-05-11 als opvolger van de oude wisi.nl-Versio-site.

## Wat hier staat

```
countcamp_site/
├── _quarto.yml          # site-config (navigatie, theme, etc.)
├── index.qmd            # landingspagina
├── over.qmd             # over CountCamp + Ben
├── werkboeken/          # overzicht + downloads werkboeken
├── manuscript/          # "De regressieve ruggengraat"-startpagina
├── archief/             # Handleiding Statistiek I (2018) PDF + oude uitgaven
└── styles.css           # basis-styling (Charter + Helvetica Neue)
```

## Render lokaal

```bash
cd ~/Documents/Ben_OS/countcamp_site
quarto preview
# of: quarto render
```

Output landt in `_site/` (gitignored).

## Deploy naar GitHub Pages

1. **GitHub-repo aanmaken** onder `github.com/CountCamp/site` (org bestaat al).
2. **Remote toevoegen + pushen:**
   ```bash
   git remote add origin git@github.com:CountCamp/site.git
   git add . && git commit -m "initial skeleton"
   git push -u origin main
   ```
3. **Pages activeren** in repo-settings → Pages → Source: GitHub Actions.
4. **Workflow toevoegen** `.github/workflows/publish.yml` (Quarto-publish-action). Komt later — als alles staat.

## DNS koppelen (bij TransIP)

Volgorde van handelingen bij TransIP-dashboard, ná domeinen zijn geregistreerd:

### countcamp.org (primair, naar Pages)

DNS-records (A + CNAME):
```
@      A      185.199.108.153
@      A      185.199.109.153
@      A      185.199.110.153
@      A      185.199.111.153
www    CNAME  CountCamp.github.io.
```

In GitHub repo-settings → Pages → Custom domain: `countcamp.org` (+ "Enforce HTTPS").

### countcamp.nl (301-redirect naar countcamp.org)

TransIP heeft een "Web Forwarding" / "URL Doorsturen"-functie in DNS. Stel in:
- Redirect type: 301 (permanent)
- Doel: `https://countcamp.org`
- Include path/query: ja (zodat sub-paden meekomen)

### wisi.nl (idem 301 — bij Registrar.nl)

Zelfde principe. Registrar.nl heeft Forwarder-instelling in DNS-paneel.

## Bronnen die hier later landen

- **Werkboeken** uit `~/Documents/Ben_OS/countcamp_lab/uni_leiden/psychologie/mvda/2526_r_practicals/` — per thema gerenderde HTML komt in `werkboeken/mvda/thema_<n>/`. Build-script (later) kopieert de _output/-HTMLs hierheen.
- **Manuscript-schetsen** uit `~/Documents/Ben_OS/countcamp_lab/03_content_blocks/manuscript/` — een include of een Quarto-book sub-project onder `manuscript/`.
- **Handleiding Statistiek I (2018) PDF** staat al in `archief/handleiding-statistiek-2018.pdf` (gekopieerd uit `99_archive/My CC Book/...`).

## Statusbord

- [x] Skelet aangelegd 2026-05-11
- [x] Handleiding 2018 PDF gekopieerd naar archief
- [ ] Domeinen geregistreerd bij TransIP (countcamp.org + countcamp.nl + eventueel countcamp.com later via backorder)
- [ ] GitHub Pages repo aangemaakt + initial push
- [ ] DNS gekoppeld
- [ ] Werkboek MVDA (Thema 1 + 2) gepubliceerd onder werkboeken/
- [ ] Manuscript-schetsen gelinkt
- [ ] Versio opgezegd (ná migratie compleet)
- [ ] wisi.nl 301 → countcamp.org
