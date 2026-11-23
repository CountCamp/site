# De kaart van het oefenboek OZP 2: twaalf toetsen bij de zeven stappen van het
# toetsingsschema. Eén bron voor twee bladzijden: de voorpagina (index.qmd)
# drukt hem als tabel (kaart_markdown), thema 11 (Welke toets?) bouwt er zijn
# keuzetabel uit (KEUZE, keuze_markdown) en drukt per toets de korte naam, het
# vaste voorbeeld en de verdeling waarnaar hij zich gedraagt (kort, voorbeeld,
# gedraagt). Meer velden zijn er niet: wat hier staat, staat ook ergens op een
# bladzijde. Spoor ozp2_kaart, 18-11-2026.
#
# De zeven stappen zijn die van college 1 (2026-27), dia 31, woordelijk
# nagelezen in _werk/tekst/2026__college 1_recap ttoetsen_extra slides
# studenten.txt (dezelfde zeven staan in college 2 dia 28, college 3 dia 28,
# college 4 dia 36 en college 5 dia 18):
#   1. Onderzoeksvraag (+ situatieschets)   2. Hypothesen (één- of tweezijdig)
#   3. Toetskeuze (assumpties?) + significantieniveau α
#   4. Berekening toetsstatistiek            5. Aflezen p-waarde (tabel)
#   6. Beslissing (vergelijk p met α)        7. Inhoudelijke conclusie
# Het college zegt "toetsstatistiek", OZP 1 zei "toetsingsgrootheid". Sinds
# 19-11-2026 volgt het hele boek het college (besluit Ben: "Tentamen stof hangt
# vooral van de college sheets af"); de voorpagina, thema 1 en de woordenlijst
# noemen het andere woord één keer. Zo ook Ha (niet H1), met een rechte a:
# een label-subscript (taalgids, besluit Ben 19-10-2026). Zie ONTWERP.md,
# "Besluiten 19-11-2026 (Ben)".
#
# "Eq. n" verwijst naar het formuleblad 2025-26 (OP 2 2025/Formuleblad2025_2026.pdf);
# het blad van 2026-27 hebben we niet (KAART_BRONNEN.md, "Wat ontbreekt").
# De tabelletters zijn die van Moore, McCabe & Craig, zoals de colleges ze
# noemen: A standaardnormaal (college 2 dia 22), D de t-verdeling (college 1
# dia 37), E de F-verdeling (college 3 dia 47), F de chi-kwadraatverdeling
# (college 5 dia 29).
#
# De SPSS-tabelnamen zijn die van de dia's 2026-27: bij de rangtoetsen de
# nieuwere "... Test Summary"-vorm (college 2 dia 45 en 66, college 5 dia 38),
# niet de oude "Ranks"/"Test Statistics"-tabellen uit Legacy Dialogs.
#
# De hypothesen van de rangtoetsen zijn die van college 2 (dia 26, 37, 49, 57:
# "verdelingen zijn gelijk / niet gelijk") en college 5 (dia 16, 25). Voor
# ANCOVA geeft geen dia een H0; die formulering is van C (zie
# 11_welke_toets/_voor_meesterknecht.md).
#
# Wat hier bewust NIET staat: getallen. Een voorbeeldzin op de kaart is een
# skelet ("t(df) = …") zodat er niets overgetikt hoeft te worden.
#
# Cellen zijn markdown in een pijptabel: geen kale | (gebruik \lvert \rvert)
# en geen regelovergang (gebruik <br>). stopifnot onderaan bewaakt dat.

STAPPEN <- c(
  "1 · Onderzoeksvraag",
  "2 · Hypothesen",
  "3 · Toetskeuze (assumpties) + α",
  "4 · Toetsstatistiek",
  "5 · *p* aflezen",
  "6 · Beslissing",
  "7 · Conclusie en rapportage"
)

# Een verwijzing naar het formuleblad of een SPSS-cel, klein en grijs.
eq <- function(...) paste0('<span class="eq">', paste0(..., collapse = ""), "</span>")

# Vaste bouwstenen, zodat een zin die overal hetzelfde is maar één keer bestaat.
# p = α → verwerpen (college 2 dia 63: "p = α → Verwerp de nulhypothese!";
# besluit Ben 19-11-2026). Hier stond tot die dag p < α.
BESLIS   <- "$p \\leq \\alpha$ → verwerp $H_0$, ook bij $p = \\alpha$.<br>$p > \\alpha$ → verwerp $H_0$ **niet** (nooit \"aannemen\")."
EENZIJD  <- "De tabel geeft de staartkans; tweezijdig ×2 (Pippi).<br>SPSS: `One-Sided p` alleen als je $H_{\\text{a}}$ dezelfde kant op wijst als je $t$."
EENZ_Z   <- "De tabel geeft de staartkans; tweezijdig ×2 (Pippi).<br>SPSS geeft de tweezijdige *p*."
RECHTS_F <- "Alleen de rechterstaart telt: nooit ×2 (geen Pippi bij *F*)."
RECHTS_H <- "Alleen de rechterstaart telt: nooit ×2 (geen Pippi bij χ²)."

kaart <- list(
  list(
    id = "z", thema = "00_fundament", kort = "*z*-toets", gedraagt = "z",
    naam = "*z*-toets<br>(één steekproef, σ bekend)",
    voorbeeld = "de Cito-score van één school tegen het landelijk gemiddelde, met de landelijke σ erbij",
    s1 = "Wijkt het gemiddelde van één groep af van een bekende norm $\\mu_0$?<br>*Woorden:* vergeleken met de norm, het landelijk gemiddelde, en σ is gegeven.",
    s2 = "$H_0: \\mu = \\mu_0$<br>$H_{\\text{a}}: \\mu \\neq \\mu_0$ (of $<$, $>$)",
    s3 = "Eén groep, uitkomst continu. **σ van de populatie bekend** (gegeven in de opgave). Normaal verdeeld, of $n$ groot.",
    s4 = paste0("$z = \\dfrac{\\bar{x} - \\mu_0}{\\sigma / \\sqrt{n}}$, geen $df$",
                eq("Eq. 7 · SPSS kent geen *z*-toets voor een gemiddelde: met de hand")),
    s5 = paste0("*z*-tabel (Tabel A op de dia's), de standaardnormale verdeling.<br>", EENZ_Z),
    s6 = BESLIS,
    s7 = paste0("BI: $\\bar{x} \\pm z^* \\dfrac{\\sigma}{\\sqrt{n}}$<br>*z* = …, *p* = …",
                eq("Eq. 8 · effectgrootte staat niet op het blad"))
  ),
  list(
    id = "t1", thema = "00_fundament", kort = "*t*-toets voor één steekproef", gedraagt = "t",
    naam = "*t*-toets<br>(één steekproef)",
    voorbeeld = "de slaapduur van de peuters van één crèche tegen de richtlijn van 90 minuten",
    s1 = "Wijkt het gemiddelde van één groep af van een norm $\\mu_0$?<br>*Woorden:* vergeleken met de norm of richtlijn; geen σ gegeven.",
    s2 = "$H_0: \\mu = \\mu_0$<br>$H_{\\text{a}}: \\mu \\neq \\mu_0$ (of $<$, $>$)",
    s3 = "Eén groep, uitkomst continu. σ onbekend, dus $s$ uit de steekproef. Ongeveer normaal.",
    s4 = paste0("$t = \\dfrac{\\bar{x} - \\mu_0}{s / \\sqrt{n}}$, $df = n - 1$",
                eq("Eq. 9, 11 · SPSS: One-Sample T Test → `One-Sample Test`: `t`, `df`")),
    s5 = paste0("*t*-tabel (Tabel D op de dia's), rij $df$.<br>", EENZIJD),
    s6 = BESLIS,
    s7 = paste0("BI: $\\bar{x} \\pm t^* \\dfrac{s}{\\sqrt{n}}$<br>*t*(*df*) = …, *p* = …, *d* = …",
                eq("Eq. 10 · Cohens *d*: `One-Sample Effect Sizes` (niet op het blad)"))
  ),
  list(
    id = "tgep", thema = "01_t_toetsen", kort = "gepaarde *t*-toets", gedraagt = "t",
    naam = "Gepaarde *t*-toets",
    voorbeeld = "acht dassen, vóór en na de cursus van hun ouders",
    s1 = "Verandert het gemiddelde bij dezelfde (of gekoppelde) eenheden tussen twee metingen?<br>*Woorden:* vóór en na, dezelfde kinderen, twee keer gemeten, paren.",
    s2 = "$H_0: \\mu_d = 0$<br>$H_{\\text{a}}: \\mu_d \\neq 0$ (of $<$, $>$)<br>met $\\mu_d$ het gemiddelde verschil in de populatie",
    s3 = "Twee metingen aan **dezelfde** eenheden (within), of gekoppelde paren. Uitkomst continu. De **verschilscores** ongeveer normaal.",
    s4 = paste0("Per eenheid $d_i$, dan $t = \\dfrac{\\bar{d}}{s_d / \\sqrt{n}}$, $df = n - 1$ ($n$ = paren)",
                eq("Eq. 17 (daar heet *d̄* *x̄* en is μ₀ = 0) · SPSS: Paired-Samples T Test → `Paired Samples Test`: `Mean`, `Std. Deviation`, `t`, `df`")),
    s5 = paste0("*t*-tabel, rij $df$.<br>", EENZIJD),
    s6 = BESLIS,
    s7 = paste0("BI: $\\bar{d} \\pm t^* \\dfrac{s_d}{\\sqrt{n}}$<br>*t*(*df*) = …, *p* = …, *d* = … (vanaf 0.2 klein, 0.5 middelgroot, 0.8 groot), 95% BI […, …]",
                eq("Cohens *d* Eq. 18, met *r* uit `Paired Samples Correlations` · SPSS' eigen *d* deelt door *s*~*d*~ en is groter"))
  ),
  list(
    id = "tonafh", thema = "01_t_toetsen", kort = "onafhankelijke *t*-toets", gedraagt = "t",
    naam = "Onafhankelijke *t*-toets",
    voorbeeld = "negen dassen in de cursus tegen elf op de wachtlijst",
    s1 = "Verschillen twee groepen met andere eenheden gemiddeld?<br>*Woorden:* twee groepen, jongens en meisjes, wel en niet, vergeleken met de controlegroep.",
    s2 = "$H_0: \\mu_1 = \\mu_2$<br>$H_{\\text{a}}: \\mu_1 \\neq \\mu_2$ (of $<$, $>$)",
    s3 = "Eén categorische onafhankelijke met **twee** groepen, andere eenheden (between). Uitkomst continu. Per groep ongeveer normaal; Levene zegt of de spreiding gelijk is.",
    s4 = paste0("$t = \\dfrac{\\bar{x}_1 - \\bar{x}_2}{\\sqrt{s_1^2 / n_1 + s_2^2 / n_2}}$, $df$ = kleinste $n$ − 1",
                eq("Eq. 12, 14 · SPSS: Independent-Samples T Test → `Independent Samples Test`: `Levene's Test` (`Sig.`) kiest de rij, dan `t`, `df`")),
    s5 = paste0("*t*-tabel, rij $df$.<br>", EENZIJD, "<br>Levene: `Sig.` $\\leq .05$ → onderste rij."),
    s6 = BESLIS,
    s7 = paste0("BI: $(\\bar{x}_1 - \\bar{x}_2) \\pm t^* \\sqrt{\\dfrac{s_1^2}{n_1} + \\dfrac{s_2^2}{n_2}}$<br>*t*(*df*) = …, *p* = …, *d* = … (vanaf 0.2 klein, 0.5 middelgroot, 0.8 groot)",
                eq("Eq. 13 · Cohens *d* Eq. 15–16 met *s*~p~ · SPSS: `Independent Samples Effect Sizes`"))
  ),
  list(
    id = "wteken", thema = "02_rangtoetsen", kort = "Wilcoxon-rangtekentoets", gedraagt = "z",
    naam = "Wilcoxon-rangtekentoets<br>(*signed rank*)",
    voorbeeld = "dezelfde dassen vóór en na, maar twee dassen schieten enorm uit",
    s1 = "Dezelfde vraag als bij de gepaarde *t*-toets, maar de verschilscores zijn niet normaal.<br>*Woorden:* vóór en na, én scheef, uitschieters, een kleine groep, mediaan.",
    s2 = "$H_0$: de verdelingen van de twee metingen zijn gelijk<br>$H_{\\text{a}}$: de verdelingen zijn niet gelijk",
    s3 = "Twee metingen aan **dezelfde** eenheden. Uitkomst minstens ordinaal. Verdeling van de verschillen lelijk (scheef, uitschieters, kleine $n$).",
    s4 = paste0("Rangen van $\\lvert d_i \\rvert$; $W^+$ = som van de rangen met een plus; dan $Z = \\dfrac{W^+ - \\mu_{W^+}}{\\sigma_{W^+}}$, geen $df$",
                eq("Eq. 49–52 · SPSS: Nonparametric Tests → Related Samples → `Related-Samples Wilcoxon Signed Rank Test Summary`: `Test Statistic`, `Standardized Test Statistic` (jouw *Z*), `Asymptotic Sig.(2-sided test)`")),
    s5 = paste0("*z*-tabel, via $Z$.<br>", EENZ_Z),
    s6 = BESLIS,
    s7 = paste0("Rapporteer met medianen: *Z* = …, *p* = …, *Mdn* vóór = …, *Mdn* na = …",
                eq("Effectgrootte staat niet op het blad"))
  ),
  list(
    id = "wsom", thema = "02_rangtoetsen", kort = "Wilcoxon-rangsomtoets", gedraagt = "z",
    naam = "Wilcoxon-rangsomtoets<br>(*rank sum*, Mann-Whitney)",
    voorbeeld = "cursus tegen wachtlijst, maar de tellingen zijn scheef",
    s1 = "Dezelfde vraag als bij de onafhankelijke *t*-toets, maar de verdelingen zijn niet normaal.<br>*Woorden:* twee groepen, én scheef, uitschieters, kleine groepen, mediaan.",
    s2 = "$H_0$: de verdelingen van de twee populaties zijn gelijk<br>$H_{\\text{a}}$: de verdelingen zijn niet gelijk",
    s3 = "Eén categorische onafhankelijke met **twee** groepen, andere eenheden. Uitkomst minstens ordinaal. Verdelingen lelijk.",
    s4 = paste0("Alle $N$ scores op één rij rangen; $W$ = rangsom van groep 1; dan $Z = \\dfrac{W - \\mu_W}{\\sigma_W}$, geen $df$",
                eq("Eq. 45–48 · SPSS: Nonparametric Tests → Independent Samples → `Independent-Samples Mann-Whitney U Test Summary`: `Wilcoxon W` (soms de rangsom van de ándere groep), `Standardized Test Statistic` (jouw *Z*, soms met omgekeerd teken), `Asymptotic Sig.(2-sided test)`")),
    s5 = paste0("*z*-tabel, via $Z$.<br>", EENZ_Z),
    s6 = BESLIS,
    s7 = paste0("Rapporteer met medianen: *W* = …, *Z* = …, *p* = …, *Mdn*₁ = …, *Mdn*₂ = …",
                eq("Effectgrootte staat niet op het blad"))
  ),
  list(
    id = "anova1", thema = "03_anova_eenweg", kort = "eenweg-ANOVA", gedraagt = "F",
    naam = "Eenweg-ANOVA",
    voorbeeld = "huiswerk in stilte, met muziek of met de tv aan: drie groepen leerlingen",
    s1 = "Verschillen drie of meer groepen gemiddeld?<br>*Woorden:* drie groepen, vier condities, per leeftijdsgroep, per klas.",
    s2 = "$H_0: \\mu_1 = \\mu_2 = \\ldots = \\mu_I$<br>$H_{\\text{a}}$: niet alle $\\mu$ zijn gelijk (minstens één verschilt)",
    s3 = "Eén categorische onafhankelijke met **drie of meer** groepen, andere eenheden. Uitkomst continu. Per groep ongeveer normaal, gelijke varianties (Levene).",
    s4 = paste0("$F = \\dfrac{\\mathit{MSG}}{\\mathit{MSE}}$, $\\mathit{DFG} = I - 1$, $\\mathit{DFE} = N - I$",
                eq("Eq. 21–29 · SPSS: One-Way ANOVA → `ANOVA`: `Between Groups`, `Within Groups`; `Sum of Squares`, `df`, `Mean Square`, `F`")),
    s5 = paste0("*F*-tabel (Tabel E op de dia's), kolom $\\mathit{DFG}$, rij $\\mathit{DFE}$.<br>", RECHTS_F, "<br>SPSS: `Sig.`"),
    s6 = BESLIS,
    s7 = paste0("*F*(*DFG*, *DFE*) = …, *p* = …, η² = … (vanaf .01 klein, .06 middelgroot, .14 groot)<br>Verworpen? Dan post hoc (LSD, Bonferroni) of een contrast: *t*-tabel, altijd tweezijdig.",
                eq("η² Eq. 30 · post hoc Eq. 31–33, contrast Eq. 34–36 · SPSS: `ANOVA Effect Sizes` (rij `Eta-squared`), `Multiple Comparisons`, `Contrast Tests`"))
  ),
  list(
    id = "kw", thema = "05_kruskal_wallis", kort = "Kruskal-Wallis", gedraagt = "χ²",
    naam = "Kruskal-Wallis",
    voorbeeld = "kinderen van 6, 9 en 12 jaar: dagen buitenspelen per week, met een hoop nullen en zevens",
    s1 = "Dezelfde vraag als bij de eenweg-ANOVA, maar de verdelingen zijn niet normaal.<br>*Woorden:* drie groepen, én scheef, uitschieters, kleine groepen, mediaan.",
    s2 = "$H_0$: de verdelingen van de $I$ populaties zijn gelijk<br>$H_{\\text{a}}$: de verdelingen zijn niet gelijk",
    s3 = "Eén categorische onafhankelijke met **drie of meer** groepen, andere eenheden. Uitkomst minstens ordinaal. Verdelingen lelijk of varianties ongelijk.",
    s4 = paste0("Alle $N$ scores rangen; rangsom $R_i$ per groep; $H = \\dfrac{12}{N(N+1)} \\sum \\dfrac{R_i^2}{n_i} - 3(N+1)$, $df = I - 1$",
                eq("Eq. 53–54 · SPSS: Nonparametric Tests → Independent Samples → `Independent-Samples Kruskal-Wallis Test Summary`: `Test Statistic` (gecorrigeerd voor knopen, dus iets groter dan jouw *H*), `Degree Of Freedom`, `Asymptotic Sig.(2-sided test)`")),
    s5 = paste0("χ²-tabel (Tabel F op de dia's), rij $df$.<br>", RECHTS_H, "<br>SPSS: `Asymptotic Sig.`"),
    s6 = BESLIS,
    s7 = paste0("*H*(*df*) = …, *p* = …, ε² = …, met medianen per groep<br>Verworpen? Dan paarsgewijs (Dunn): $z_{ij}$ in de *z*-tabel, tweezijdig ×2.",
                eq("ε² Eq. 57 · Dunn Eq. 55–56 · SPSS: `Pairwise Comparisons` (`Std. Test Statistic`, `Adj. Sig.`)"))
  ),
  list(
    id = "anova2", thema = "06_anova_meerweg", kort = "tweeweg-ANOVA", gedraagt = "F",
    naam = "Tweeweg-ANOVA<br>(factorieel)",
    voorbeeld = "online of fysiek onderwijs, bij makkelijke, gemiddelde en moeilijke stof: 2 × 3",
    s1 = "Twee categorische factoren: heeft elk een hoofdeffect op de uitkomst, en hangt het effect van de ene af van de andere (interactie)?<br>*Woorden:* twee factoren, 2 × 3, hangt af van, verschilt het effect per …",
    s2 = "Drie paar: $H_0^{\\text{A}}$: alle $\\mu_{i}$ gelijk · $H_0^{\\text{B}}$: alle $\\mu_{j}$ gelijk · $H_0^{\\text{AB}}$: geen interactie (het effect van A op de uitkomst is in elk niveau van B hetzelfde)<br>Bij elk een $H_{\\text{a}}$: niet alle gelijk, of wél interactie<br>*Op de dia's:* $H_0^{\\text{AB}}$: alle $(\\mu_{ij} - \\mu_{i} - \\mu_{j})$ zijn gelijk",
    s3 = "**Twee** categorische onafhankelijke, andere eenheden per cel. Uitkomst continu. Per cel ongeveer normaal, gelijke varianties.",
    s4 = paste0("Per bron $F = \\dfrac{\\mathit{MS}_{\\text{bron}}}{\\mathit{MSE}}$; $\\mathit{DFA} = I - 1$, $\\mathit{DFB} = J - 1$, $\\mathit{DFAB} = (I-1)(J-1)$, $\\mathit{DFE} = N - IJ$",
                eq("Eq. 37–43 · SPSS: General Linear Model → Univariate → `Tests of Between-Subjects Effects`: rijen A, B, A * B, `Error`; `Type III Sum of Squares`, `df`, `Mean Square`, `F`")),
    s5 = paste0("*F*-tabel, per bron.<br>", RECHTS_F, "<br>SPSS: `Sig.` per rij"),
    s6 = paste0(BESLIS, "<br>Eerst de interactie; is die er, dan zeggen de hoofdeffecten minder."),
    s7 = paste0("Per bron: *F*(*DFA*, *DFE*) = …, *p* = …, $\\eta^2_{\\text{p}}$ = …<br>Interactie in woorden: het effect van A op de uitkomst verschilt per niveau van B.",
                eq("$\\eta^2_{\\text{p}}$ Eq. 44 (daar $\\eta^2_{\\text{part}}$) · SPSS: `Partial Eta Squared` (aanvinken onder Options), profielplot, `Estimated Marginal Means`"))
  ),
  list(
    id = "regr1", thema = "07_regressie_enkelvoudig", kort = "correlatie of enkelvoudige regressie", gedraagt = "t",
    naam = "Correlatie en<br>enkelvoudige regressie",
    voorbeeld = "leeftijd in maanden en woordenschat bij peuters: samenhang (*r*), of woordenschat voorspellen uit leeftijd (*b*₁)",
    s1 = "Hangen twee continue variabelen lineair samen (correlatie)? Of: voorspel $y$ uit $x$ (regressie)?<br>*Woorden:* samenhang, verband, hangt samen met → $r$ · voorspellen, op basis van, per uur meer → $b_1$.",
    s2 = "$H_0: \\rho = 0$, $H_{\\text{a}}: \\rho \\neq 0$<br>of $H_0: \\beta_1 = 0$, $H_{\\text{a}}: \\beta_1 \\neq 0$ (dezelfde toets)",
    s3 = "**Twee continue** variabelen, één meting per eenheid. Verband lineair (puntenwolk: geen worst). Residuen ongeveer normaal, gelijke spreiding.",
    s4 = paste0("$t = \\dfrac{r \\sqrt{n-2}}{\\sqrt{1 - r^2}}$ of $t = \\dfrac{b_1}{\\mathit{SE}_{b_1}}$, $df = n - 2$",
                eq("*r* Eq. 58–59, *t* Eq. 63–65, *df* Eq. 69 · SPSS: Correlate → Bivariate → `Correlations` (`Pearson Correlation`, `Sig. (2-tailed)`); Regression → Linear → `Coefficients` (`B`, `Std. Error`, `t`, `Sig.`)")),
    s5 = "*t*-tabel, rij $n - 2$.<br>De tabel geeft de staartkans; tweezijdig ×2 (Pippi).<br>SPSS: `Sig. (2-tailed)` in `Correlations`, `Sig.` in `Coefficients`; allebei tweezijdig.",
    s6 = BESLIS,
    s7 = paste0("*r*(*df*) = …, *p* = … · of: *b*₁ = …, *t*(*df*) = …, *p* = …, *R*² = …<br>Richting en eenheid erbij: per … meer $x$, … meer $y$.",
                eq("*b* Eq. 60–62, *R*² Eq. 75, BI voor *b*₁ Eq. 71 · SPSS: `Model Summary` (`R Square`), `ANOVA` (`F`)"))
  ),
  list(
    id = "regrm", thema = "08_regressie_meervoudig", kort = "meervoudige regressie", gedraagt = "F",
    naam = "Meervoudige regressie",
    voorbeeld = "schermtijd van kleuters voorspellen uit ouderlijke stress, bewegen en de schermtijd van de moeder",
    s1 = "Voorspel $y$ uit twee of meer voorspellers; welke draagt uniek bij, en hoeveel verklaren ze samen?<br>*Woorden:* voorspellen uit …, en …, en …; unieke bijdrage; gecontroleerd voor (bij getallen).",
    s2 = "Model: $H_0: \\beta_1 = \\ldots = \\beta_p = 0$, $H_{\\text{a}}$: minstens één $\\beta_j \\neq 0$ (*F*)<br>per voorspeller: $H_0: \\beta_j = 0$, $H_{\\text{a}}: \\beta_j \\neq 0$ (*t*)",
    s3 = "Eén continue uitkomst, **twee of meer** voorspellers, allemaal getallen (een groep erbij? dan ANCOVA). Lineair, residuen normaal met gelijke spreiding, geen multicollineariteit (VIF).",
    s4 = paste0("$F = \\dfrac{\\mathit{MSM}}{\\mathit{MSE}}$ met $\\mathit{DFM} = p$, $\\mathit{DFE} = n - p - 1$; per voorspeller $t = \\dfrac{b_j}{\\mathit{SE}_{b_j}}$",
                eq("Eq. 76–83 · SPSS: Regression → Linear → `ANOVA` (`F`, `Sig.`), `Coefficients` (`B`, `Beta`, `t`, `Sig.`; `Tolerance`, `VIF` onder Statistics), `Model Summary` (`R Square`, `R Square Change`)")),
    s5 = "*F*-tabel voor de *F* van het model: alleen de rechterstaart, nooit ×2.<br>*t*-tabel voor de *t* per voorspeller: tweezijdig ×2.<br>SPSS geeft bij allebei de tweezijdige `Sig.`.",
    s6 = BESLIS,
    s7 = paste0("*F*(*DFM*, *DFE*) = …, *p* = …, *R*² = …; per voorspeller *b* = …, *t*(*df*) = …, *p* = …<br>Δ*R*² als je een blok voorspellers toevoegt.",
                eq("*R*² Eq. 82, BI Eq. 84 · SPSS: `R Square Change`, `F Change`"))
  ),
  list(
    id = "ancova", thema = "09_ancova", kort = "ANCOVA", gedraagt = "F",
    naam = "ANCOVA",
    voorbeeld = "jeugdbeschermers met en zonder training, gecorrigeerd voor hun werkervaring",
    s1 = "Verschillen groepen gemiddeld op de uitkomst, als je corrigeert voor een continue stoorzender (de covariaat)?<br>*Woorden:* gecorrigeerd voor, rekening houdend met, gelijkgetrokken op, covariaat.",
    s2 = "$H_0$: de **gecorrigeerde** groepsgemiddelden zijn gelijk<br>$H_{\\text{a}}$: niet alle gecorrigeerde gemiddelden zijn gelijk<br>Dit is de $H_0$ die je bij een open vraag opschrijft, in woorden (het college geeft hier geen symbolen). Vooraf nog een controle: $H_0$: geen interactie groep × covariaat (gelijke hellingen)",
    s3 = "Eén categorische onafhankelijke (groepen, andere eenheden) **plus** een continue covariaat. Uitkomst continu. Covariaat lineair met de uitkomst, in elke groep dezelfde helling (parallelle regressielijnen), en gemeten vóór de ingreep.",
    s4 = paste0("$F = \\dfrac{\\mathit{MS}_{\\text{groep}}}{\\mathit{MSE}}$ uit de uitvoer; niet op het formuleblad",
                eq("SPSS: General Linear Model → Univariate, covariaat bij `Covariate(s)` → `Tests of Between-Subjects Effects`: rij covariaat, rij groep, `Error` · eerst mét de productterm groep × covariaat (mag niet significant zijn), dan zonder")),
    s5 = paste0("*F*-tabel.<br>", RECHTS_F, "<br>SPSS: `Sig.`"),
    s6 = BESLIS,
    s7 = paste0("*F*(*df*₁, *df*₂) = …, *p* = …, $\\eta^2_{\\text{p}}$ = …, met de **gecorrigeerde** gemiddelden (het blad geeft hier geen *df*-namen)",
                eq("$\\eta^2_{\\text{p}}$: `Partial Eta Squared` · gecorrigeerde gemiddelden: `Estimated Marginal Means` (tabel `Estimates`)"))
  )
)

# ---- toetsen op de kaart zelf ----------------------------------------------
kaart_ids <- vapply(kaart, `[[`, "", "id")
stopifnot("dubbele id op de kaart" = !anyDuplicated(kaart_ids))
cellen <- unlist(lapply(kaart, function(k) k[c("naam", "s1", "s2", "s3", "s4", "s5", "s6", "s7")]))
stopifnot(
  "een kale | breekt de pijptabel" = !any(grepl("(^|[^\\\\])\\|", cellen)),
  "een regelovergang breekt de pijptabel" = !any(grepl("\n", cellen, fixed = TRUE)),
  "elke toets heeft zijn velden" = all(vapply(kaart, function(k)
    all(c("id", "thema", "kort", "gedraagt", "naam", "voorbeeld") %in% names(k)), TRUE))
)
# Elke Eq.-verwijzing moet op het blad bestaan: 1 tot en met 84.
eqs <- as.integer(unlist(regmatches(cellen, gregexpr("(?<=Eq\\. )[0-9]+|(?<=[–-])[0-9]+(?=[^0-9]*)", cellen, perl = TRUE))))
stopifnot("Eq.-nummer buiten het formuleblad" = all(eqs >= 1 & eqs <= 84))

# ---- de kaart als pijptabel (markdown), voor cat() in een asis-blok ----------
# wortel: pad van de bladzijde naar de boekwortel ("" op de voorpagina, "../" in
# een thema). Elke toets linkt naar zijn thema.
kaart_markdown <- function(wortel = "") {
  kop <- c("toets", STAPPEN)
  regels <- c(
    paste0("| ", paste(kop, collapse = " | "), " |"),
    paste0("|", paste(rep("---", length(kop)), collapse = "|"), "|")
  )
  for (k in kaart) {
    link <- paste0("[", k$naam, "](", wortel, k$thema, "/", k$thema, ".html)")
    regels <- c(regels, paste0("| ", paste(c(link, k$s1, k$s2, k$s3, k$s4, k$s5, k$s6, k$s7), collapse = " | "), " |"))
  }
  paste(regels, collapse = "\n")
}

# ---- per toets: de treden en de buur, voor thema 11 ------------------------
kaart_rij <- function(id) {
  i <- match(id, kaart_ids)
  stopifnot("onbekende toets" = !is.na(i))
  kaart[[i]]
}

# ---- de keuzetabel van thema 11: rij = hoe de onafhankelijke kant eruitziet,
# kolom = mooi (normaal) of lelijk (scheef, ordinaal, klein). Dezelfde vorm als
# de tabel van college 5 (dia 45: "1 groep / 2 groepen gepaard, ongepaard /
# > 2 groepen" tegen "normaal verdeeld / niet normaal verdeeld"), uitgebreid
# met de regressiefamilie en ANCOVA. Een streepje betekent: voor die combinatie
# leer je in OZP 2 geen toets. Elke toets van de kaart staat hier precies één
# keer, op regr1 na (verband én voorspellen); dat bewaakt stopifnot.
KEUZE <- list(
  list(rij = "één groep tegen een norm",                      mooi = c("z", "t1"), lelijk = character(0)),
  list(rij = "twee metingen, dezelfde eenheden (of paren)",    mooi = "tgep",        lelijk = "wteken"),
  list(rij = "twee groepen, andere eenheden",                  mooi = "tonafh",      lelijk = "wsom"),
  list(rij = "drie of meer groepen, andere eenheden",          mooi = "anova1",      lelijk = "kw"),
  list(rij = "drie of meer metingen, dezelfde eenheden",       mooi = character(0),  lelijk = character(0)),
  list(rij = "twee factoren: groepen × groepen",               mooi = "anova2",      lelijk = character(0)),
  list(rij = "één getal als onafhankelijke: *verband*",        mooi = "regr1",       lelijk = character(0)),
  list(rij = "één getal als onafhankelijke: *voorspellen*",    mooi = "regr1",       lelijk = character(0)),
  list(rij = "twee of meer getallen als voorspellers",         mooi = "regrm",       lelijk = character(0)),
  list(rij = "groepen én een getal als stoorzender",           mooi = "ancova",      lelijk = character(0))
)
keuze_ids <- unlist(lapply(KEUZE, function(r) c(r$mooi, r$lelijk)))
stopifnot(
  "een toets van de kaart ontbreekt in de keuzetabel" = setequal(keuze_ids, kaart_ids),
  "een toets staat vaker in de keuzetabel dan bedoeld" =
    all(table(keuze_ids)[setdiff(kaart_ids, "regr1")] == 1) && sum(keuze_ids == "regr1") == 2
)

# De korte naam van een toets, met de wereld-specifieke toevoeging waar nodig.
keuze_naam <- function(id, rij) {
  k <- kaart_rij(id)
  naam <- k$kort
  if (id == "z")  naam <- paste0(naam, " (σ bekend)")
  if (id == "t1") naam <- paste0(naam, " (σ onbekend)")
  if (id == "regr1") naam <- if (grepl("verband", rij)) "correlatie (*r*)" else "enkelvoudige regressie (*b*₁)"
  naam
}

keuze_markdown <- function(leeg = "— (niet in OZP 2)") {
  # De streepjesregel bepaalt de kolombreedtes (pandoc: relatief aan het aantal
  # streepjes zodra een regel te lang is): de rijnaam krijgt bijna de helft.
  regels <- c("| de onafhankelijke kant | de wereld is mooi (normaal) | de wereld is lelijk (scheef, ordinaal, klein) |",
              "|------------------------|--------------|--------------|")
  for (r in KEUZE) {
    m <- if (length(r$mooi)) paste(vapply(r$mooi, keuze_naam, "", rij = r$rij), collapse = " / ") else leeg
    l <- if (length(r$lelijk)) paste(vapply(r$lelijk, keuze_naam, "", rij = r$rij), collapse = " / ") else leeg
    regels <- c(regels, paste0("| ", r$rij, " | ", m, " | ", l, " |"))
  }
  paste(regels, collapse = "\n")
}
