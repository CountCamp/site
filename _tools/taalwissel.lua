--[[
taalwissel.lua — het taalknopje (NL · EN) en de hreflang-verwijzingen.

Waarom een filter, en niet in de bladzijden zelf
------------------------------------------------
Een Nederlandse bron mag de Engelse kant niet aanraken (24-10-2026, opdracht
en_schil: "Never edit a Dutch source file"). Toch moet elke Nederlandse bladzij
met een Engelse tweeling een zichtbaar knopje krijgen en de zoekmachine moet
weten dat de twee bij elkaar horen. Dit filter doet dat vanuit één tabel,
_tools/taalparen.tsv, en draait in allebei de bouwrondes (nl en en). Zo staat
het paar op één plek, en kunnen de twee kanten niet uit elkaar lopen.

Wat het doet, en alleen dat
---------------------------
Op een bladzij die in de tabel staat:
  1. in <head> drie <link rel="alternate" hreflang=...> met volle adressen —
     nl, en, en x-default (= de Nederlandse, zoals bij solomon.html: wie geen
     van beide talen spreekt, krijgt het origineel). Google, Search Central,
     "Tell Google about localized versions of your page": op elke versie
     dezelfde set, inclusief zichzelf.
  2. bovenaan de tekst het knopje: de eigen taal staat er als tekst, de andere
     als link. Op de link hreflang (de taal van de bestemming) en lang (de
     taal van het woord zelf) — W3C i18n, "Indicating the language of a link
     destination". Dezelfde vorm als solomon.html, met dezelfde reden.
  3. een klein <style>-blok voor dat knopje, ALLEEN op die bladzij. Daarom
     staat het niet in styles.css: dan zou een wijziging aan het knopje elke
     bladzij van de site raken, ook de duizend die er niets mee te maken hebben.
  4. alleen op de NEDERLANDSE kant: de taalbalk (_tools/taalwissel/balk.html,
     24-10-2026). Een <style> en een <script>, geen zichtbare tekst in de bron;
     het script zet "This page is also in English →" bovenaan als de browser
     geen Nederlands noemt, en onthoudt het wegklikken. Geen doorsturen: Ben
     nam dat advies over (zie balk.html voor het waarom en de bronnen).

Op een bladzij die NIET in de tabel staat doet het niets. Die bladzij komt
byte voor byte hetzelfde uit de bouw als zonder dit filter — gemeten, zie
_tools/publiceer_en.sh, stap "nederlands ongemoeid".

Kolom `wissel` in de tabel:
  auto       — het filter zet het knopje
  eigen      — de bladzij heeft al een eigen knopje in de bron (cv.qmd: "English
               version →"); het filter zet alleen de hreflang-verwijzingen (en
               op de Nederlandse kant de balk), anders staan er twee knopjes.
  los        — een bladzij die Quarto NIET bouwt (tabellen/, tables/): dit
  los-eigen    filter slaat hem over; _tools/taalonderdelen.py zet daar
               dezelfde stukken in.

Wat er op een Nederlandse bladzij bij komt, is precies wat de wachtrij mag
weglaten voor ze vergelijkt (nl_negeer). Die regels rekent
_tools/taalonderdelen.py uit deze stukken uit; verander je hier iets aan de
vorm van het knopje of de verwijzingen, draai dan
_tools/tests/taalwissel_negeer_test.py, en geef de nieuwe regels aan de pers.

Kan het filter de tabel niet lezen, dan breekt het de bouw af. Een site die
stil zonder taalknopjes uit de bouw komt ziet er precies zo uit als een site
waar niemand ze heeft gevraagd — en dat verschil moet iemand zien.
]]

-- Het vaste adres van de echte site. Ook in een proefdruk, met opzet: een
-- hreflang die naar de proefdruk wijst zou de zoekmachine naar een bladzij met
-- noindex sturen, en de proefdruk zelf wordt toch niet opgenomen.
local BASIS = "https://countcamp.org/"
local TABEL = "_tools/taalparen.tsv"

local function split_tab(regel)
  local velden = {}
  for veld in (regel .. "\t"):gmatch("([^\t]*)\t") do
    table.insert(velden, (veld:gsub("^%s+", ""):gsub("%s+$", "")))
  end
  return velden
end

local function lees_tabel(map)
  local pad = map .. "/" .. TABEL
  local f = io.open(pad, "r")
  if not f then
    error("taalwissel.lua: kan " .. pad .. " niet lezen — zonder tabel geen taalknopjes, en dat moet hardop")
  end
  local paren = {}
  local nr = 0
  for regel in f:lines() do
    nr = nr + 1
    if not regel:match("^%s*#") and regel:match("%S") then
      local v = split_tab(regel)
      local soorten = { auto = true, eigen = true, los = true, ["los-eigen"] = true }
      if #v < 3 or not soorten[v[3]] then
        f:close()
        error(string.format("taalwissel.lua: %s regel %d is geen 'nl<TAB>en<TAB>auto|eigen|los|los-eigen': %s", TABEL, nr, regel))
      end
      table.insert(paren, { nl = v[1], en = v[2], wissel = v[3] })
    end
  end
  f:close()
  return paren
end

-- Relatief pad van de map van `van` naar `naar`, allebei sitepaden met "/".
local function relatief(van, naar)
  local a = {}
  for deel in van:gmatch("[^/]+") do table.insert(a, deel) end
  table.remove(a) -- de bestandsnaam eraf: we vertrekken uit de map
  local b = {}
  for deel in naar:gmatch("[^/]+") do table.insert(b, deel) end
  local i = 1
  while i <= #a and i < #b and a[i] == b[i] do i = i + 1 end
  local stukken = {}
  for _ = i, #a do table.insert(stukken, "..") end
  for j = i, #b do table.insert(stukken, b[j]) end
  return table.concat(stukken, "/")
end

-- Vol adres; een index.html wordt het adres van zijn map (countcamp.org/en/).
local function vol_adres(sitepad)
  local p = sitepad:gsub("index%.html$", "")
  return BASIS .. p
end

local function deze_bladzij()
  local map = quarto.project.directory
  local invoer = quarto.doc.input_file
  if not map or not invoer then return nil, nil end
  if invoer:sub(1, #map + 1) ~= map .. "/" then return nil, map end
  local rel = invoer:sub(#map + 2)
  return (rel:gsub("%.qmd$", ".html")), map
end

-- DE STUKKEN STAAN IN _tools/taalwissel/, niet hier (sinds 24-10-2026, tweede
-- ronde en_schil). Drie lezers moeten precies dezelfde bytes zien: dit filter
-- (de bladzijden die Quarto bouwt), _tools/taalonderdelen.py (de losse
-- bladzijden: tabellen/, tables/, solomon) en de uitzondering van de wachtrij
-- (nl_negeer), die elk stuk letterlijk weglaat voor ze Nederlands vergelijkt.
-- Stond het stijlblok hier als Lua-tekst, dan waren dat drie kopieën.
--   stijl_knop.html  het knopje op een bladzij van Quarto (nl en en)
--   balk.html        de taalbalk, alleen op de NEDERLANDSE kant
-- Witruimte aan het eind van een bestand telt niet mee (een editor zet daar
-- graag een regel bij); verder komt elk teken onveranderd in de bladzij.
local function lees_stuk(map, naam)
  local pad = map .. "/_tools/taalwissel/" .. naam
  local f = io.open(pad, "r")
  if not f then
    error("taalwissel.lua: kan " .. pad .. " niet lezen — zonder dit stuk geen taalknopje of taalbalk, en dat moet hardop")
  end
  local t = f:read("a")
  f:close()
  return (t:gsub("%s+$", ""))
end

-- Werkbriefjes in de Engelse bronnen: <!-- MIEKE: ... -->, <!-- BEN: ... --> en de
-- kop "Vertaling van ...". Ze zijn voor Mieke en Ben, niet voor een bezoeker die
-- de paginabron opent — een open vraag ("klopt die nog?") hoort niet op de echte
-- site. In de .qmd blijven ze staan: daar zoekt Mieke ze. Alleen onder en/, en
-- alleen deze drie soorten; elk ander commentaar blijft staan, net als in
-- solomon-en.html, waar de redenen in de bron het huisgebruik zijn.
local function is_werkbriefje(el)
  return el.format == "html" and (
    el.text:match("^%s*<!%-%-%s*MIEKE") or
    el.text:match("^%s*<!%-%-%s*BEN:") or
    el.text:match("^%s*<!%-%-%s*Vertaling van"))
end

local function zonder_werkbriefjes(doc)
  return doc:walk({
    RawBlock = function(el) if is_werkbriefje(el) then return {} end end,
    RawInline = function(el) if is_werkbriefje(el) then return {} end end,
  })
end

function Pandoc(doc)
  if not quarto.doc.is_format("html") then return nil end
  local hier, map = deze_bladzij()
  if not hier then return nil end
  local engels = hier:sub(1, 3) == "en/"
  if engels then doc = zonder_werkbriefjes(doc) end
  local paar, kant
  for _, p in ipairs(lees_tabel(map)) do
    -- `los` en `los-eigen` zijn bladzijden die Quarto niet bouwt; die krijgen
    -- hun stukken van _tools/taalonderdelen.py, niet van dit filter.
    if p.wissel == "auto" or p.wissel == "eigen" then
      if p.nl == hier then paar, kant = p, "nl" break end
      if p.en == hier then paar, kant = p, "en" break end
    end
  end
  -- Een Nederlandse bladzij zonder tweeling: nil, dus Quarto houdt het origineel.
  if not paar then return engels and doc or nil end

  quarto.doc.include_text("in-header", table.concat({
    '<link rel="alternate" hreflang="nl" href="' .. vol_adres(paar.nl) .. '">',
    '<link rel="alternate" hreflang="en" href="' .. vol_adres(paar.en) .. '">',
    '<link rel="alternate" hreflang="x-default" href="' .. vol_adres(paar.nl) .. '">',
  }, "\n"))

  -- DE TAALBALK (Ben, 24-10-2026: geen automatisch doorsturen, wel een zacht
  -- voorstel). Alleen op de Nederlandse kant, en ook bij `eigen` (cv.html): die
  -- heeft een tweeling, alleen al een eigen knopje. Het script toont de balk
  -- pas als de browser geen Nederlands noemt; zie balk.html.
  if kant == "nl" then
    quarto.doc.include_text("in-header", lees_stuk(map, "balk.html"))
  end

  if paar.wissel == "auto" then
    quarto.doc.include_text("in-header", lees_stuk(map, "stijl_knop.html"))
    local knop
    if kant == "nl" then
      knop = '<nav class="taalwissel" aria-label="taal"><span aria-current="page">NL</span>'
        .. '<span class="taalwissel-sep" aria-hidden="true">·</span>'
        .. '<a href="' .. relatief(hier, paar.en) .. '" hreflang="en" lang="en" title="This page in English">EN</a></nav>'
    else
      knop = '<nav class="taalwissel" aria-label="language">'
        .. '<a href="' .. relatief(hier, paar.nl) .. '" hreflang="nl" lang="nl" title="Deze bladzij in het Nederlands">NL</a>'
        .. '<span class="taalwissel-sep" aria-hidden="true">·</span><span aria-current="page">EN</span></nav>'
    end
    -- WAAR HET KNOPJE IN DE HTML STAAT — en waarom niet bovenaan.
    -- Gemeten 24-10-2026 in de zoekindex van Quarto 1.9 (updateSearchIndex):
    -- de samenvatting van een bladzij is de tekst van het EERSTE element binnen
    -- <main>, plus de alinea's die er direct onder staan. Stond het knopje
    -- eerst, dan werd de zoektekst van index.html "NL·EN" in plaats van de
    -- tagline, en op de andere drie kwam "NL·EN" ervoor. (before-body helpt
    -- niet: Quarto zet dat óók als eerste in <main>.)
    -- Dus: ná het eerste blok, en dan met css (position:absolute, zie STIJL)
    -- rechtsboven gezet. Het eerste element blijft wat het was, het knopje is
    -- geen <p> en staat niet in een sectie, en de zoekindex ziet het niet.
    -- Is het eerste blok een kop, dan begint er daar een sectie en is er geen
    -- veilige plek: dan vooraan, en en_bouw.py meldt het als de zoekindex
    -- daardoor "NL·EN" bevat.
    local plek = 2
    if #doc.blocks == 0 or doc.blocks[1].t == "Header" then plek = 1 end
    table.insert(doc.blocks, plek, pandoc.RawBlock("html", knop))
  end
  return doc
end
