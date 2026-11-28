--[[
boek_inhoud_en.lua — de inhoudsopgave van het Engelse boek (en/book/index.qmd),
bij elke bouw uitgerekend.

Waarom uitgerekend, en niet getikt
----------------------------------
Ben, 27-10-2026 (meerkeuze): alle dertien hoofdstukken tonen, de niet-vertaalde
grijs met "coming soon" en een link naar het Nederlands. De Engelse hoofdstukken
komen er één voor één bij (Ben, 28-11: "blijf live gaan tussendoor"): H1 die dag,
H2 en H3 erna, H4–H12 via de rij. Een getikte lijst van wat er al Engels is,
loopt bij het eerstvolgende hoofdstuk achter, en dat ziet niemand: een grijze rij
voor een hoofdstuk dat allang Engels is, ziet eruit als een keuze. Daarom kijkt
dit filter bij elke bouw zelf, in de bouwmap:

  * welke hoofdstukken het boek heeft: manuscript/h<n>.html (de Nederlandse pers
    zet ze daar). Komt er een hoofdstuk bij, dan staat het hier vanzelf, grijs.
  * welke er in het Engels zijn: en/book/h<n>.html (de Engelse pers). Komt h4
    erbij, dan is rij 4 bij de volgende bouw een gewone link.
  * de titel, de droge onderwerpregel en de beweging van elk hoofdstuk: uit die
    bladzijden zelf (<h1 class="title">, <p class="subtitle lead">,
    <div class="kicker">) — uit de Engelse als die er is.

Wat er wél getikt is, en waarom
-------------------------------
Een vertaling volgt niet uit de data. Een hoofdstuk dat nog niet Engels is, heeft
geen Engelse onderwerpregel om uit te lezen, en een beweging zonder Engels
hoofdstuk geen Engelse naam. Die staan in de tabel in en/book/index.qmd (het blok
::: {#boek-inhoud-en}), elk naast de Nederlandse regel waarvan ze vertaald zijn.
Daar staan ook de MIEKE-regels en het nl_bron-stempel, en daar zoekt Mieke.
Wordt een hoofdstuk Engels, dan wint zijn bladzij en is zijn rij overbodig.

Hardop, in twee soorten
-----------------------
  FOUT — de bouw stopt, want er kan geen eerlijke rij komen: een Nederlands
    hoofdstuk zonder Engelse bladzij én zonder regel in de tabel, een beweging
    zonder Engelse naam, een bladzij waarvan de kop of de beweging niet te lezen
    is, een Engels hoofdstuk zonder Nederlandse tweeling, of twee Engelse
    hoofdstukken in één beweging die die beweging anders noemen.
  MELD: BIJ TE WERKEN — de bouw gaat door, en _tools/en_bouw.py zegt het in zijn
    uitvoer: de rij staat er, maar de tabel loopt achter. De Nederlandse regel
    veranderde sinds de vertaling, of een rij is overbodig omdat het hoofdstuk nu
    Engels is. Een vertaling van gisteren is beter dan geen; zo doet
    publiceer_en.sh het ook met nl_bron.
Elke bouw meldt daarnaast één regel met wat hij zag ("MELD: inhoud ..."), ook
als alles klopt: stilte zegt niet dat er gekeken is.

Ontstaan: spoor boek_overzicht_en, 28-11-2026. Getoetst door
_tools/tests/boek_inhoud_en_test.sh, met een bijtproef per FOUT en per MELD.
]]

local NL = "manuscript"
local EN = "en/book"
local VOORVOEGSEL = { nl = "Hoofdstuk", en = "Chapter" }
local NAAM = "boek_inhoud_en.lua"

-- HOE DIT FILTER STOPT, en waarom niet met error(). Gemeten 28-11-2026 op Quarto
-- 1.9.38, in een wegwerpproject, zestien combinaties: error() in een eigen filter
-- stopt de bouw NIET. Quarto vervangt de globale error door een melding ("ERROR
-- ([C]:-1) ..."), het filter loopt gewoon door, de bladzij wordt toch gemaakt, en
-- quarto render eindigt met afloop 0 — met het filter in de kop van de bladzij of in
-- _quarto.yml, in een website- of een default-project, met of zonder niveau.
-- assert(false, ...) en os.exit(1) stoppen wel: afloop 1, geen bladzij. Hier
-- os.exit, omdat assert een Lua-traceback van tien regels achter de melding zet, en
-- en_bouw.py toont van een mislukte bouw alleen de laatste vijftien.
-- "ERROR:" vooraan, zodat en_bouw.py hem ook als fout leest als een volgende Quarto
-- os.exit ooit net zo opvangt als error().
local function fout(tekst)
  io.stderr:write("ERROR: " .. NAAM .. ": " .. tekst .. "  (zie de kop van _tools/" .. NAAM .. ")\n")
  io.stderr:flush()
  os.exit(1)
end

-- Naar stderr: Quarto geeft het door, en en_bouw.py herhaalt elke regel die met
-- "MELD: " begint in zijn eigen uitvoer. Bewust zonder WARN of ERROR: die leest
-- en_bouw.py als een fout, en dit is er geen.
local function meld(tekst)
  io.stderr:write("MELD: " .. tekst .. "\n")
end

local function lees(pad)
  local f = io.open(pad, "rb")
  if not f then return nil end
  local t = f:read("a")
  f:close()
  return t
end

local function escape(t)
  return (t:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

-- Om te vergelijken, niet om te tonen: zonder opmaak, met de schrijfwijzen die
-- hetzelfde zijn (’ en ', &#x27;, een harde spatie) gelijkgetrokken. Anders
-- meldt een gekrulde apostrof in "odds ratio’s" een vertaling als achter.
local function plat(t)
  t = t:gsub("<[^>]*>", "")
  t = t:gsub("&#x27;", "'"):gsub("&#39;", "'"):gsub("&amp;", "&"):gsub("&nbsp;", " ")
  t = t:gsub("’", "'"):gsub("\194\160", " "):gsub("%s+", " ")
  return (t:gsub("^ ", ""):gsub(" $", ""))
end

-- {n = pad} voor elke h<n>.html in een map. h3_grabbel.html en dankwoord.html
-- tellen niet mee: alleen een getal na de h.
local function hoofdstukken(wortel, map)
  local ok, namen = pcall(pandoc.system.list_directory, wortel .. "/" .. map)
  if not ok then fout("kan " .. map .. "/ niet lezen (" .. tostring(namen) .. ")") end
  local uit, nummers = {}, {}
  for _, naam in ipairs(namen) do
    local n = naam:match("^h(%d+)%.html$")
    if n then
      uit[tonumber(n)] = map .. "/" .. naam
      table.insert(nummers, tonumber(n))
    end
  end
  table.sort(nummers)
  return uit, nummers
end

-- Kop, onderwerpregel en beweging van één hoofdstukbladzij. De kop is
-- "Chapter 4 — Titel" (of "Hoofdstuk 4 — Titel"), en het getal moet kloppen.
local function blad(wortel, pad, taal, n)
  local t = lees(wortel .. "/" .. pad)
  if not t then fout("kan " .. pad .. " niet lezen") end
  local kop = t:match('<h1 class="title">(.-)</h1>')
  if not kop then
    fout(pad .. ': geen <h1 class="title"> — veranderde de kop van de boekbladzijden in het lab?')
  end
  local m, titel = kop:match("^" .. VOORVOEGSEL[taal] .. " (%d+) — (.+)$")
  if not m then
    fout(pad .. ': de kop "' .. kop .. '" heeft niet de vorm "' .. VOORVOEGSEL[taal] .. ' <n> — <titel>"')
  end
  if tonumber(m) ~= n then
    fout(pad .. ": de kop zegt hoofdstuk " .. m .. ", de bestandsnaam " .. n)
  end
  local beweging = t:match('<div class="kicker">(.-)</div>')
  if not beweging then
    fout(pad .. ': geen <div class="kicker"> — zonder beweging weet het overzicht niet onder welke kop dit hoort')
  end
  return { pad = pad, titel = titel, sub = t:match('<p class="subtitle lead">(.-)</p>'), beweging = beweging }
end

local function html_van(blokken)
  return (pandoc.write(pandoc.Pandoc(blokken), "html"):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- De tabel in het blok: | H<n> of "beweging" | Nederlands | English |.
local function lees_tabel(div)
  local rijen, bewegingen, n_tabellen = {}, {}, 0
  for _, blok in ipairs(div.content) do
    if blok.t == "Table" then
      n_tabellen = n_tabellen + 1
      for _, body in ipairs(blok.bodies) do
        for _, rij in ipairs(body.body) do
          local c = rij.cells
          if #c ~= 3 then fout("een rij in de tabel van #boek-inhoud-en heeft " .. #c .. " kolommen in plaats van 3") end
          local wat = pandoc.utils.stringify(c[1].contents)
          local nl = pandoc.utils.stringify(c[2].contents)
          local en = html_van(c[3].contents)
          if en == "" then fout("de tabel van #boek-inhoud-en heeft een lege Engelse kolom bij " .. wat) end
          local n = wat:match("^H(%d+)$")
          if n then
            rijen[tonumber(n)] = { nl = nl, en = en }
          elseif wat == "beweging" then
            bewegingen[plat(nl)] = { nl = nl, en = en, gebruikt = false }
          else
            fout('de tabel van #boek-inhoud-en heeft een rij "' .. wat .. '": de eerste kolom is H<n> of beweging')
          end
        end
      end
    end
  end
  if n_tabellen == 0 then fout("het blok #boek-inhoud-en heeft geen tabel") end
  return rijen, bewegingen
end

local function maak(div, wortel)
  local later = div.attributes["later"]
  local in_nl = div.attributes["in-nl"]
  if not later or not in_nl then
    fout('het blok #boek-inhoud-en mist later="…" of in-nl="…" (de woorden op een grijze rij)')
  end
  local rijen, bewegingen = lees_tabel(div)
  local nl_pad, nl_nrs = hoofdstukken(wortel, NL)
  local en_pad, en_nrs = hoofdstukken(wortel, EN)
  if #nl_nrs == 0 then fout("geen enkel hoofdstuk in " .. NL .. "/ — een leeg boek is geen boek") end
  for _, n in ipairs(en_nrs) do
    if not nl_pad[n] then fout(en_pad[n] .. " heeft geen Nederlandse tweeling " .. NL .. "/h" .. n .. ".html") end
  end

  -- Elk hoofdstuk, in volgorde; de bewegingen in de volgorde waarin ze komen.
  local groepen, engels, grijs = {}, {}, {}
  for _, n in ipairs(nl_nrs) do
    local nl = blad(wortel, nl_pad[n], "nl", n)
    local en = en_pad[n] and blad(wortel, en_pad[n], "en", n) or nil
    local g = groepen[#groepen]
    if not g or g.nl ~= plat(nl.beweging) then
      g = { nl = plat(nl.beweging), nl_heel = nl.beweging, en = nil, en_van = nil, rijen = {} }
      table.insert(groepen, g)
    end
    if en then
      table.insert(engels, tostring(n))
      if g.en and plat(g.en) ~= plat(en.beweging) then
        fout(en.pad .. ' noemt zijn beweging "' .. en.beweging .. '", ' .. g.en_van .. ' dezelfde "' .. g.en .. '"')
      end
      g.en, g.en_van = g.en or en.beweging, g.en_van or en.pad
      if rijen[n] then
        meld("BIJ TE WERKEN: en/book/index.qmd, rij H" .. n .. " in de tabel is overbodig: " .. en.pad
          .. " bestaat, en zijn eigen onderwerpregel wint. Haal de rij weg.")
      end
      table.insert(g.rijen, string.format(
        '<div class="cc-toc-h">\n<a class="cc-toc-kop" href="h%d.html"><span class="cc-toc-num">%d</span>'
        .. '<span class="cc-toc-titel">%s</span>%s</a>\n</div>',
        n, n, en.titel, en.sub and ('<span class="cc-toc-sub">' .. en.sub .. '</span>') or ""))
    else
      table.insert(grijs, tostring(n))
      local r = rijen[n]
      if not r then
        fout(nl.pad .. " is er niet in het Engels (geen " .. EN .. "/h" .. n .. ".html), en de tabel in "
          .. "en/book/index.qmd heeft geen rij H" .. n .. ": zet er een, met de Nederlandse onderwerpregel \""
          .. plat(nl.sub or "") .. "\" en zijn vertaling")
      end
      if plat(r.nl) ~= plat(nl.sub or "") then
        meld("BIJ TE WERKEN: en/book/index.qmd, rij H" .. n .. ' is vertaald van "' .. r.nl .. '", en '
          .. nl.pad .. ' zegt nu "' .. plat(nl.sub or "") .. '". Vertaal de rij opnieuw.')
      end
      table.insert(g.rijen, string.format(
        '<div class="cc-toc-h cc-toc-later">\n<a class="cc-toc-kop" href="../../%s" hreflang="nl">'
        .. '<span class="cc-toc-num">%d</span><span class="cc-toc-titel" lang="nl">%s</span>'
        .. '<span class="cc-toc-sub">%s</span>'
        .. '<span class="cc-toc-later-regel">%s · <span class="cc-toc-nl">%s</span></span></a>\n</div>',
        nl.pad, n, nl.titel, r.en, escape(later), escape(in_nl)))
    end
  end

  local html = { '<div class="cc-toc">' }
  for _, g in ipairs(groepen) do
    local naam = g.en
    local b = bewegingen[g.nl]
    if naam then
      if b then
        meld("BIJ TE WERKEN: en/book/index.qmd, de rij voor de beweging \"" .. b.nl .. "\" is overbodig: "
          .. g.en_van .. " noemt hem zelf. Haal de rij weg.")
      end
    elseif b then
      naam = b.en
    else
      fout('de beweging "' .. g.nl_heel .. '" heeft geen Engels hoofdstuk en geen rij in de tabel in '
        .. "en/book/index.qmd: zet er een, als | beweging | " .. g.nl_heel .. " | <English> |")
    end
    if b then b.gebruikt = true end
    table.insert(html, '<p class="cc-bew">' .. naam .. '</p>')
    for _, r in ipairs(g.rijen) do table.insert(html, r) end
  end
  table.insert(html, "</div>")

  for n, _ in pairs(rijen) do
    if not nl_pad[n] then
      meld("BIJ TE WERKEN: en/book/index.qmd, rij H" .. n .. " hoort bij geen hoofdstuk (er is geen "
        .. NL .. "/h" .. n .. ".html). Haal de rij weg.")
    end
  end
  for _, b in pairs(bewegingen) do
    if not b.gebruikt then
      meld('BIJ TE WERKEN: en/book/index.qmd, de rij voor de beweging "' .. b.nl .. '" hoort bij geen '
        .. "beweging van het boek (meer). Haal de rij weg, of vertaal de nieuwe naam.")
    end
  end
  meld(string.format("inhoud en/book/index: %d hoofdstukken uit %s/, %d in het Engels (%s), %d grijs met een "
    .. "link naar het Nederlands (%s), %d bewegingen",
    #nl_nrs, NL, #engels, table.concat(engels, ", "), #grijs, table.concat(grijs, ", "), #groepen))
  return pandoc.RawBlock("html", table.concat(html, "\n"))
end

local gezien = 0

return {
  {
    Div = function(div)
      if div.identifier ~= "boek-inhoud-en" then return nil end
      gezien = gezien + 1
      local wortel = quarto.project.directory
      if not wortel then fout("geen projectmap — dit filter draait alleen in een Quarto-project") end
      return maak(div, wortel)
    end,
    Pandoc = function(doc)
      -- Het filter staat in de kop van en/book/index.qmd. Staat het blok er niet
      -- (meer) in, dan bouwt de bladzij zonder inhoudsopgave — en dat moet hardop.
      if gezien ~= 1 then
        fout("het blok ::: {#boek-inhoud-en} staat " .. gezien .. " keer op de bladzij (hoort 1)")
      end
      return doc
    end,
  },
}
