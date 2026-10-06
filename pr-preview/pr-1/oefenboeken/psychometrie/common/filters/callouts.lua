-- callouts.lua — map custom callout-classes naar LaTeX-environments uit
-- countcamp.tex. Voor HTML-output doet Quarto niets met deze filter (CSS
-- regelt het al via .callout-note.<class>).
--
-- Classes: .opgave, .tidy-alt, .spss-syntax, .rotterdam-conventie,
--          .conventie (zelfde kader als Rotterdam), .formule
-- Kale div (geen callout): .rapportage
-- Plus inline-spans: .getal, .eng
--
-- LET OP — de vier takken hieronder vuren niet meer (gemeten 15-8-2026).
-- Quarto zet `::: {.callout-note .opgave}` om in een Callout-knoop vóór deze
-- filter draait, dus `Div()` ziet hem nooit; de PDF valt daardoor terug op
-- Quarto's standaard-callout en ccOpgave/ccTidyAlt/ccSpssSyntax/ccRotterdam
-- in countcamp.tex zijn dode code. In HTML klopt alles wél, want dat gaat
-- via CSS. Zie de reparatielijst; niet meegenomen in de rapportage-klus om
-- die niet te laten uitdijen.
--
-- `.rapportage` is daarom bewust een KALE div en geen callout: die bereikt
-- de filter wel, en het geeft één markup voor het boek (stil, alleen CSS)
-- en de werkboeken (zichtbaar kader). De auteur typt overal hetzelfde en
-- hoeft niet te weten waar hij is.

-- Rapportage-blok: de zin die de student letterlijk overneemt in haar eigen
-- verslag. Geen uitleg maar rapportage, dus APA onverkort (TAALGIDS §2).
-- De kop zegt wat de lezer met het blok moet DOEN, niet welk register het is.
local RAP_KOP = "Zo rapporteer je het"

local function rapportage(el)
  local titel = el.attributes["title"] or RAP_KOP
  if FORMAT:match 'latex' then
    return {
      pandoc.RawBlock("latex", "\\begin{ccRapportage}[" .. titel .. "]"),
      pandoc.Div(el.content),
      pandoc.RawBlock("latex", "\\end{ccRapportage}")
    }
  end
  if FORMAT:match 'html' then
    local kop = pandoc.Div({ pandoc.Plain({ pandoc.Str(titel) }) },
                           pandoc.Attr("", { "rapportage-kop" }))
    local lijf = pandoc.Div(el.content, pandoc.Attr("", { "rapportage-lijf" }))
    return pandoc.Div({ kop, lijf },
                      pandoc.Attr(el.identifier, { "rapportage", "rap-af" }))
  end
  return nil
end

function Div(el)
  -- `rap-af` markeert een blok dat deze filter al heeft omgebouwd; zonder die
  -- vlag zou de nieuwe buiten-div opnieuw langskomen en oneindig nesten.
  if el.classes:includes("rapportage") and not el.classes:includes("rap-af") then
    return rapportage(el)
  end

  if FORMAT:match 'latex' then
    if el.classes:includes("opgave") then
      local title = el.attributes["title"] or ""
      return {
        pandoc.RawBlock("latex", "\\begin{ccOpgave}[" .. title .. "]"),
        el,
        pandoc.RawBlock("latex", "\\end{ccOpgave}")
      }
    end
    if el.classes:includes("tidy-alt") then
      local title = el.attributes["title"] or ""
      return {
        pandoc.RawBlock("latex", "\\begin{ccTidyAlt}[" .. title .. "]"),
        el,
        pandoc.RawBlock("latex", "\\end{ccTidyAlt}")
      }
    end
    if el.classes:includes("spss-syntax") then
      local title = el.attributes["title"] or "SPSS-syntax"
      return {
        pandoc.RawBlock("latex", "\\begin{ccSpssSyntax}[" .. title .. "]"),
        el,
        pandoc.RawBlock("latex", "\\end{ccSpssSyntax}")
      }
    end
    if el.classes:includes("rotterdam-conventie") then
      local title = el.attributes["title"] or "Rotterdam-conventie"
      return {
        pandoc.RawBlock("latex", "\\begin{ccRotterdam}[" .. title .. "]"),
        el,
        pandoc.RawBlock("latex", "\\end{ccRotterdam}")
      }
    end
    if el.classes:includes("conventie") then
      local title = el.attributes["title"] or "Conventie"
      return {
        pandoc.RawBlock("latex", "\\begin{ccRotterdam}[" .. title .. "]"),
        el,
        pandoc.RawBlock("latex", "\\end{ccRotterdam}")
      }
    end
    if el.classes:includes("formule") then
      local title = el.attributes["title"] or "Formule"
      return {
        pandoc.RawBlock("latex", "\\begin{ccFormule}[" .. title .. "]"),
        el,
        pandoc.RawBlock("latex", "\\end{ccFormule}")
      }
    end
    if el.classes:includes("dieren-subtitel") then
      local content = pandoc.utils.stringify(el)
      return pandoc.RawBlock("latex", "\\dierensubtitel{" .. content .. "}")
    end
  end
  return nil
end

function Span(el)
  if FORMAT:match 'latex' then
    if el.classes:includes("getal") then
      local content = pandoc.utils.stringify(el)
      return pandoc.RawInline("latex", "\\getal{" .. content .. "}")
    end
    if el.classes:includes("eng") then
      local content = pandoc.utils.stringify(el)
      return pandoc.RawInline("latex", "\\engterm{" .. content .. "}")
    end
  end
  return nil
end

-- ------------------------------------------------------------------
-- Callout-knopen: hetzelfde kader, maar dan langs de weg die Quarto
-- werkelijk neemt.
--
-- `::: {.callout-note .opgave}` bereikt Div() nooit: Quarto heeft er dan
-- al een Callout-knoop van gemaakt. De takken hierboven vuurden daardoor
-- niet en de PDF viel terug op Quarto's standaard-callout, terwijl de HTML
-- via CSS wél klopte. Gemeten en gerepareerd 15-8-2026.
--
-- Sinds 16-8-2026 geldt hetzelfde voor Quarto's eigen vijf soorten. Die
-- kregen in de PDF alleen een flauw tintje van `\colorlet` in
-- countcamp.tex, want dat zet de kleur maar niet de vorm.
--
-- Een eigen class wint altijd van het soort: `.opgave` is een
-- `callout-note` en moet ccOpgave blijven, niet ccConceptKader.

-- Afgeleid uit de Div-takken van dít bestand en nagelopen tegen de
-- omgevingen die countcamp.tex werkelijk definieert: niet elk werkboek
-- kent elke omgeving, en verwijzen naar een omgeving die de tex niet
-- kent is een LaTeX-fout.
local LATEX_ENV = {
  ["opgave"] = "ccOpgave",
  ["tidy-alt"] = "ccTidyAlt",
  ["spss-syntax"] = "ccSpssSyntax",
  ["rotterdam-conventie"] = "ccRotterdam",
  ["conventie"] = "ccRotterdam",
  ["formule"] = "ccFormule",
}

local INGEBOUWD_ENV = {
  ["note"] = "ccConceptKader",
  ["tip"] = "ccVuistregelKader",
  ["warning"] = "ccAlarmKader",
  ["important"] = "ccDontKader",
  ["caution"] = "ccAntwoordKader",
}

-- Zonder eigen kop vult Quarto er zelf een in, maar dat gebeurt ná deze
-- filter -- gemeten 16-8-2026: `el.title` is dan gewoon nil. Zodra wij
-- het kader overnemen moeten we die kop dus zelf zetten. Dit zijn
-- letterlijk Quarto's eigen woorden uit `_language-nl.yml` en
-- `_language-en.yml`, zodat de PDF hetzelfde zegt als de HTML in plaats
-- van iets eigens te verzinnen. In het hele corpus zijn het er vijf op
-- 1240 kaders, dus het gaat om de randgevallen -- maar juist die vallen
-- op als er ineens een Engels woord in een Nederlands werkboek staat.
local STANDAARDKOP = {
  nl = { note = "Opmerking", tip = "Tip", warning = "Waarschuwing",
         important = "Belangrijk", caution = "Opgelet" },
  en = { note = "Note", tip = "Tip", warning = "Warning",
         important = "Important", caution = "Caution" },
}

local function standaardkop(soort)
  local taal = quarto.metadata.get("lang")
  taal = taal and pandoc.utils.stringify(taal) or ""
  local woorden = taal:match("^nl") and STANDAARDKOP.nl or STANDAARDKOP.en
  return woorden[soort] or ""
end

-- De kop door de LaTeX-schrijver halen, niet door stringify. `el.title`
-- is een Block (een Plain) -- gemeten, niet aangenomen. stringify plette
-- `$b$ versus $\beta$` tot de losse letters `\beta`, en dat werd in de
-- PDF een tofu-blokje; de schrijver houdt er `\(\beta\)` van en escapet
-- meteen ook `&`, `%` en `_`. `wrap_text = "none"` houdt de kop op één
-- regel, want een lege regel in een optioneel argument breekt LaTeX.
local SCHRIJFOPTIES = pandoc.WriterOptions({ wrap_text = "none" })

local function kop_naar_latex(titel)
  local uit = pandoc.write(pandoc.Pandoc(titel), "latex", SCHRIJFOPTIES)
  return (uit:gsub("%s+$", ""))
end

function Callout(el)
  if not FORMAT:match 'latex' then return nil end
  local env
  if el.attr and el.attr.classes then
    for _, klasse in ipairs(el.attr.classes) do
      if LATEX_ENV[klasse] then env = LATEX_ENV[klasse] break end
    end
  end
  if not env then env = INGEBOUWD_ENV[el.type] end
  if not env then return nil end
  local titel = el.title and kop_naar_latex(el.title) or standaardkop(el.type)
  -- De accolades beschermen een `]` in de kop tegen de argument-lezer.
  return {
    pandoc.RawBlock("latex", "\\begin{" .. env .. "}[{" .. titel .. "}]"),
    pandoc.Div(el.content),
    pandoc.RawBlock("latex", "\\end{" .. env .. "}")
  }
end
