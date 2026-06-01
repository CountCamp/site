-- callouts.lua — map custom callout-classes naar LaTeX-environments uit
-- countcamp.tex. Voor HTML-output doet Quarto niets met deze filter (CSS
-- regelt het al via .callout-note.<class>).
--
-- Classes: .opgave, .tidy-alt, .spss-syntax, .rotterdam-conventie
-- Plus inline-spans: .getal, .eng

function Div(el)
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
