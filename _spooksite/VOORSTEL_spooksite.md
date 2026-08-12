# De spooksite — twee wegen, en wat ze kosten

*Voorstel voor Ben. Geschreven 12-8-2026 door het spoor `drukkerij`. Er is
niets aangemeld, geen account gemaakt, niets gepubliceerd — dit is een keuze
die jij maakt.*

## Waar het over gaat

Je wilt een bladzij kunnen bekijken zoals hij op de site zou staan, zonder dat
hij op de site staat. Drie eisen die je zelf stelde:

- **(a) een eigen hostnaam of pad**, en nooit iets dat per ongeluk productie kan worden
- **(b) noindex via een HTTP-KOP**, niet via een robots.txt-verbod
- **(c) een zichtbare balk op de bladzij**, uit een bouwvariabele

Eis (b) klinkt als een detail maar is het niet. Een robots.txt-verbod zegt
"kom hier niet kijken". Een zoekmachine die niet mag kijken, kan de bladzij ook
niet lezen — en dus ook niet zien dat hij hem niet mag opnemen. Zo'n bladzij
kan alsnog in de zoekresultaten terechtkomen, zonder tekst, met alleen een URL.
Een noindex is het omgekeerde: kom gerust kijken, en neem me daarna niet op.
Dat is de reden dat je de kop wilde en niet het verbod.

## Wat er ligt: de GitHub-weg (geen nieuw account)

Dit is gebouwd en klaar om aan te zetten. De PR-proefdruk-actie
(`rossjrw/pr-preview-action`, de gangbare oplossing hiervoor) zet elke pull
request neer op

    https://countcamp.org/pr-preview/pr-<nummer>/

zet de link als opmerking in de PR, en ruimt hem op zodra de PR dicht gaat.

| eis | krijg je? |
|---|---|
| (a) eigen pad | **ja** — `/pr-preview/pr-N/`, met een eigen bouwprofiel |
| (a) eigen hostnaam | **nee** — alles staat op countcamp.org |
| (b) noindex als KOP | **nee, en dat kán niet** |
| (b) noindex als meta-tag | **ja**, op elke bladzij |
| (c) balk uit de bouw | **ja** |
| kosten | niets |
| werk | de vier bestanden die er liggen committen, meer niet |

**Waarom die kop niet kan.** GitHub Pages laat je geen eigen HTTP-koppen
zetten. Dat is geen instelling die we missen; het is er niet, en GitHub zegt
dat zelf ([discussie
#84963](https://github.com/orgs/community/discussions/84963)). Wat we in plaats
daarvan doen is `<meta name="robots" content="noindex, nofollow, noarchive">`
in de kop van elke proefbladzij. Die doet hetzelfde werk en — belangrijker —
hij doet het op de goede manier: de zoekmachine mag de bladzij ophalen en ziet
dán pas dat hij hem niet mag opnemen. De *reden* achter eis (b) blijft dus
overeind; alleen het middel is anders. Google behandelt de meta-tag en de kop
gelijkwaardig.

**Wat hier het echte risico is**, en dat is een ander risico dan je noemde: de
proefdruk landt in *dezelfde gh-pages-tak* als de echte site, in een submap.
Er is dus geen tweede deploy-pad — dat is goed, want twee echte deploy-paden
was precies wat je wilde vermijden — maar de scheiding is een mapnaam. Zet
iemand `umbrella-dir` per ongeluk op `.`, dan overschrijft een proefdruk de
site. Daarom staat die waarde in `.github/workflows/proefdruk.yml` met een
waarschuwing erbij, en controleert de bouw vóór het neerzetten dat er noindex
én een balk in zit en géén bezoekersteller.

## Het alternatief: Cloudflare Pages

Cloudflare Pages doet precies wat je vroeg, zonder uitzonderingen.

| eis | krijg je? |
|---|---|
| (a) eigen hostnaam | **ja** — `<tak>.<project>.pages.dev`, per tak |
| (b) noindex als KOP | **ja, vanzelf** — Cloudflare zet `X-Robots-Tag: noindex` op elke proefdruk, zonder dat je iets instelt |
| (c) balk uit de bouw | ja (dezelfde bestanden die er nu liggen) |
| kosten | gratis voor ons volume (500 bouwen per maand) |
| extra | je kunt proefdrukken achter een inlog zetten (Cloudflare Access), zodat alleen jij ze ziet |

**Wat het kost aan gedoe, en dat is het echte prijskaartje.** Een
Cloudflare-account aanmaken, de GitHub-repo koppelen, en een keuze maken over
de echte site: wil je die ook naar Cloudflare verhuizen, of blijft
countcamp.org op GitHub Pages staan en gebruik je Cloudflare alleen voor
proefdrukken? Dat laatste kan, maar dan heb je twee bouwsystemen die allebei
je site kunnen bouwen — en dat is een variant van precies de fout waar je voor
waarschuwde. Verhuizen betekent DNS omzetten voor countcamp.org: één avond
werk en een dag waarin de site via een nieuwe weg loopt.

## Wat ik je zou adviseren

**Begin met de GitHub-weg.** Hij ligt er, hij kost niets, hij verandert niets
aan hoe de echte site gebouwd wordt, en hij dekt eis (a) en (c) volledig en
eis (b) in de geest maar niet naar de letter. Merk je in de praktijk dat je
proefdrukken écht buiten de deur wilt houden — omdat je ze deelt met Paul of
met een uitgever, en je wilt zeker weten dat ze nergens opduiken — dan is dát
het moment voor Cloudflare, en dan is de balk en het profiel al gebouwd en
verhuist alleen de plek waar het neerkomt.

Wat ik je **niet** zou adviseren, en wat in de briefing al werd afgeraden: een
tweede repo als spooksite. Dan zijn er twee echte deploy-paden en is "de
proefdruk werd per ongeluk de site" een kwestie van tijd.

## Wat er nu ligt (nog niet gecommit, niets gepubliceerd)

| bestand | wat het doet |
|---|---|
| `_quarto-spook.yml` | het bouwprofiel van een proefdruk: noindex, balk, geen bezoekersteller |
| `_quarto-echt.yml` | het bouwprofiel van de echte site: de bezoekersteller |
| `_quarto.yml` | `profile: default: echt` erbij; de teller is eruit verhuisd |
| `_spooksite/maak_banner.sh` | schrijft de balk, met de gegevens van de bouw erin |
| `.github/workflows/proefdruk.yml` | de PR-proefdruk, met controle vóór het neerzetten |
| `_tools/naar_buiten.sh` | de enige deur naar buiten: `--lokaal`, `--proefdruk`, `--productie` |

Alles is hier op de machine gedraaid en nagekeken. De echte site is met geen
enkel commando geraakt.

### Waarom de bezoekersteller verhuisde

Dat was een verrassing tijdens het bouwen. De teller stond in `_quarto.yml`,
en een Quarto-profiel *plakt* zijn eigen `include-in-header` erbij — het
vervangt de bestaande niet. Elke proefdruk droeg de teller dus gewoon mee en
telde mee in je bezoekcijfers. Nu staat hij in `_quarto-echt.yml`, het profiel
dat een proefdruk nooit gebruikt, en controleert `naar_buiten.sh --productie`
ná de bouw of hij er ook echt in zit — want de omgekeerde fout (de teller stil
kwijtraken door een tikfout in een profielnaam) merk je pas maanden later aan
een grafiek die op nul staat.

### Hoe je hem gebruikt

```bash
cd ~/Documents/Ben_OS/countcamp_site

bash _tools/naar_buiten.sh --lokaal        # proefdruk hier bekijken
bash _tools/naar_buiten.sh --proefdruk     # proefdruk op internet, via een PR
bash _tools/naar_buiten.sh --productie     # naar de echte site
```

Zonder vlag doet het script niets en toont het deze drie regels. Dat is de
bedoeling: er bestaat geen handeling die per ongeluk productie kan worden.
Elke weg heeft zijn eigen stappen — ze delen niets — en na elke bouw wordt de
gebouwde HTML gecontroleerd op de drie merktekens (noindex, balk,
bezoekersteller), zodat een proefdruk zich niet als de echte site kan
voordoen en de echte site niet per ongeluk noindex draagt.
