# De doorverwijs-pagina's — wat elk oud adres bedoelde

Deze map bevat elf stubs, `h0.html` t/m `h10.html`. Het zijn **oude adressen**:
toen het manuscript nog in `werkplaats/` stond, was dít de plek waar een
hoofdstuk woonde. Wie zo'n adres ooit heeft opgeslagen of gelinkt, komt hier
nog steeds uit.

**Twee regels, en de tweede is de gevaarlijke.**

1. **De bestandsnaam verandert nooit.** Dat is het adres zelf. Hernoem je hem,
   dan is het oude adres weg en krijgt de bezoeker een 404.
2. **Het doel moet bij elke hernummering mee.** Doe je dat niet, dan blijft de
   stub werken maar stuurt hij de lezer naar een *ander hoofdstuk* — zonder
   404, zonder foutmelding, zonder dat enige controle aanslaat. Een stub die
   liegt ziet er precies zo uit als een stub die klopt.

Op 10-8-2026 bleek dat regel 2 twee keer was overgeslagen: alle elf stubs
stonden nog op `hN → hN` terwijl er sinds hun aanmaak twee hernummeringen
overheen waren gegaan. Vier ervan stuurden de lezer al drie weken naar het
verkeerde hoofdstuk.

## Wat er sindsdien gebeurd is

| wanneer | wat |
|---|---|
| **21-7-2026** | mediatie wordt H10, logistische regressie schuift naar H11 — alles vanaf de oude H10 schuift één op |
| **22-7-2026** | betrouwbaarheid schuift tussen als H5; H5–H11 → H6–H12 |
| **10-8-2026** | de rotatie: H5 → H7, H6 → H5, H7 → H6 |

De reeks stopt bij `h10`, dus deze stubs dateren van vóór 21-7. Daarmee ligt
vast wat elk adres tóén bedoelde:

| oud adres | bedoelde toen | wijst nu naar |
|---|---|---|
| `h0` | In den beginne | h0 |
| `h1` | De gemiddelde slok | h1 |
| `h2` | De vorm van de hoop | h2 |
| `h3` | De grabbelton geschud | h3 |
| `h4` | Het rechthoekje | h4 |
| `h5` | Bestaat het echt? | h5 — 22-7 naar 6, 10-8 weer terug |
| `h6` | Hoe beslis je? | h6 — 22-7 naar 7, 10-8 weer terug |
| `h7` | Meer dan één verschil | **h8** |
| `h8` | Groepen zijn ook getallen | **h9** |
| `h9` | Verschil in verschil | **h10** |
| `h10` | En hij buigt | **h12** |

Er zijn bewust **geen** stubs voor `h11` en `h12`: die adressen hebben in de
werkplaats nooit bestaan, dus niemand kan ze hebben opgeslagen. Een stub voor
een adres dat nooit bestond voegt niets toe en kan bij een volgende
hernummering zélf gaan liegen.

## Bij de volgende hernummering

Draai `boek/_tools/_cascade_stubs.py` — daar staat de tabel hierboven als code.
Werk de `DOELEN`-tabel bij en laat het script de elf bestanden opnieuw
schrijven. Controleer daarna met:

```
python3 boek/_tools/verwijzingen_kaart.py
```

De kaart meldt de stubs onder LET OP; hij kan niet zíén of ze kloppen — dat is
nou juist het punt — maar hij herinnert je eraan dat ze bestaan.
