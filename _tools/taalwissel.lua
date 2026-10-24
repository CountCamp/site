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

Op een bladzij die NIET in de tabel staat doet het niets. Die bladzij komt
byte voor byte hetzelfde uit de bouw als zonder dit filter — gemeten, zie
_tools/publiceer_en.sh, stap "nederlands ongemoeid".

Kolom `wissel` in de tabel:
  auto   — het filter zet het knopje
  eigen  — de bladzij heeft al een eigen knopje in de bron (cv.qmd: "English
           version →"); het filter zet alleen de hreflang-verwijzingen, anders
           staan er twee knopjes boven elkaar.

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
      if #v < 3 or (v[3] ~= "auto" and v[3] ~= "eigen") then
        f:close()
        error(string.format("taalwissel.lua: %s regel %d is geen 'nl<TAB>en<TAB>auto|eigen': %s", TABEL, nr, regel))
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

local STIJL = [[
<style>
/* taalwissel.lua: het taalknopje, alleen op bladzijden met een tweeling */
.taalwissel{text-align:right;font-size:.86rem;letter-spacing:.05em;margin:0 0 .6rem 0;color:#6c757d;}
.taalwissel a{text-decoration:none;}
.taalwissel a:hover{text-decoration:underline;}
.taalwissel [aria-current]{font-weight:600;color:inherit;}
.taalwissel-sep{margin:0 .45em;}
</style>]]

function Pandoc(doc)
  if not quarto.doc.is_format("html") then return nil end
  local hier, map = deze_bladzij()
  if not hier then return nil end
  local paar, kant
  for _, p in ipairs(lees_tabel(map)) do
    if p.nl == hier then paar, kant = p, "nl" break end
    if p.en == hier then paar, kant = p, "en" break end
  end
  if not paar then return nil end

  quarto.doc.include_text("in-header", table.concat({
    '<link rel="alternate" hreflang="nl" href="' .. vol_adres(paar.nl) .. '">',
    '<link rel="alternate" hreflang="en" href="' .. vol_adres(paar.en) .. '">',
    '<link rel="alternate" hreflang="x-default" href="' .. vol_adres(paar.nl) .. '">',
  }, "\n"))

  if paar.wissel == "auto" then
    quarto.doc.include_text("in-header", STIJL)
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
    table.insert(doc.blocks, 1, pandoc.RawBlock("html", knop))
  end
  return doc
end
