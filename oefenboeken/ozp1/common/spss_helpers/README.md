# SPSS-output-pipeline — STAT 3 werkboek

## Doel

Voor elk thema in het werkboek wordt SPSS-output (descriptives, model-tabellen, plots) gegenereerd uit een `.sps`-syntax-file en als PNG ingebed in het Quarto-hoofdstuk. Studenten zien echte SPSS-output zoals het op het tentamen verschijnt; docent (Ben) houdt één reproduceerbare bron per thema.

## Per-thema-structuur

```
0X_<thema>/
├── syntax/0X_<thema>_main.sps   ← bron: één .sps die alle output produceert
├── data/<dataset>.sav            ← input
├── pics/                          ← output: PNG per pivot-table/plot
└── output_raw/                    ← .spv (SPSS Viewer file), niet commit
```

## Workflow (voorlopig — handmatig in SPSS GUI)

**Probleem:** headless batch via `stats -production silent` werkt op deze SPSS-install niet (geen output, geen error). Vermoedelijk GUI-licentiebinding van de IBM SPSS Statistics .app voor Mac.

**Workaround tot we dit oplossen:**

1. Open de `.sps` in SPSS GUI (dubbelklik in Finder, of File → Open Syntax).
2. Run all (Ctrl/Cmd + A → Run Selection, of Run → All).
3. Wacht tot output klaar is in Output Viewer.
4. Output Viewer → File → Export... → Type: PNG → Browse → kies `0X_<thema>/pics/`.
   - **Naming:** SPSS exporteert als `<basename>_001.png`, `<basename>_002.png`, etc. Pas naming aan zodat ze logisch zijn (`01_descriptives.png`, `02_correlations.png`, `03_model_summary.png`, etc.) of pas in het `.qmd` de image-paths aan.
5. Optioneel: Output Viewer → File → Save As → `output_raw/0X_<thema>.spv` voor archiveren.

## Toekomst (te onderzoeken)

- **Python-via-jaSPSStatistics**: er bestaat een Python-bridge voor SPSS (`spssaux` / `spss` module). Mogelijk headless via Python-script. Vereist installatie van Python-essentials in SPSS.
- **OUTPUT EXPORT met HTML**: in `.sps` kan `OUTPUT EXPORT /HTML DOCUMENTFILE=...` werken voor HTML-output. Dat kan ingebed worden als iframe of geconverteerd naar PNG via Chromium-headless.
- **Cloud SPSS**: IBM heeft een SPSS Cloud (Statistics Subscription) maar geen open API voor batch. Niet veelbelovend.

## Handmatig-batch-script

`run_syntax.sh` probeert `-production silent` aan te roepen. Werkt op deze install niet, maar het script blijft staan voor toekomstige systemen waar het wél werkt.

```bash
./_common/spss_helpers/run_syntax.sh 01_meervoudige_regressie/syntax/01_mra_main.sps
```
