# Nameting spoor plankvorm (11-8-2026): doet de oplichter wat we beloven?
# Echte muisbeweging via CDP (geen geforceerde klasse), daarna toetsenbord-
# focus, computed styles en schoten van de hover- en focus-toestand.
library(chromote)
b <- ChromoteSession$new(width = 1440, height = 1000)
b$Page$navigate("file:///Users/ben/Documents/Ben_OS/countcamp_site/_site/oefenboeken/index.html")
Sys.sleep(3)

mid <- function(sel) {
  js <- sprintf('(() => { const r = document.querySelector("%s").getBoundingClientRect();
    return JSON.stringify({x: r.x + r.width/2, y: r.y + r.height/2}); })()', sel)
  jsonlite::fromJSON(b$Runtime$evaluate(js)$result$value)
}
bg <- function(sel) b$Runtime$evaluate(sprintf(
  'getComputedStyle(document.querySelector("%s")).backgroundColor', sel))$result$value

# scroll de eerste plank in beeld en meet de rustkleur
b$Runtime$evaluate('document.querySelector(".cc-plank").scrollIntoView({block: "center"})')
Sys.sleep(0.5)
cat("rust  boek1 bg:", bg(".cc-boek"), "\n")
cat("lijn  boek1:", b$Runtime$evaluate(
  'getComputedStyle(document.querySelector(".cc-boek")).borderLeftWidth + " " +
   getComputedStyle(document.querySelector(".cc-boek")).borderLeftColor')$result$value, "\n")

# muis op de eerste regel (sectie: bij het boek, blauw)
p <- mid(".cc-boek")
b$Input$dispatchMouseEvent(type = "mouseMoved", x = p$x, y = p$y)
Sys.sleep(0.6)
cat("hover boek1 bg:", bg(".cc-boek"), "\n")
cat("hover boek1 chip bg:", bg(".cc-boek .cc-chip"), "\n")
r1 <- jsonlite::fromJSON(b$Runtime$evaluate('(() => { const r = document.querySelector(".cc-plank").getBoundingClientRect();
  return JSON.stringify({x: r.x, y: r.y, w: r.width, h: r.height}); })()')$result$value)
b$screenshot("na/hover_rug_boek1.png", cliprect = c(r1$x - 30, r1$y - 20, r1$w + 60, r1$h + 40))

# muis op de maat-regel (paars) en de vak-regel (groen)
b$Runtime$evaluate('document.querySelector(".cc-boek-maat").scrollIntoView({block: "center"})')
Sys.sleep(0.4)
p <- mid(".cc-boek-maat")
b$Input$dispatchMouseEvent(type = "mouseMoved", x = p$x, y = p$y)
Sys.sleep(0.6)
cat("hover maat bg:", bg(".cc-boek-maat"), "\n")
b$Runtime$evaluate('document.querySelector(".cc-boek-vak").scrollIntoView({block: "center"})')
Sys.sleep(0.4)
p <- mid(".cc-boek-vak")
b$Input$dispatchMouseEvent(type = "mouseMoved", x = p$x, y = p$y)
Sys.sleep(0.6)
cat("hover vak bg:", bg(".cc-boek-vak"), "\n")

# toetsenbord: Tab tot de eerste boeklink focus heeft; dan focus-within + ring
b$Input$dispatchMouseEvent(type = "mouseMoved", x = 10, y = 10)  # muis weg
b$Runtime$evaluate('window.scrollTo(0,0)')
Sys.sleep(0.3)
for (i in 1:40) {
  b$Input$dispatchKeyEvent(type = "keyDown", key = "Tab", code = "Tab",
                           windowsVirtualKeyCode = 9L, nativeVirtualKeyCode = 9L)
  b$Input$dispatchKeyEvent(type = "keyUp", key = "Tab", code = "Tab",
                           windowsVirtualKeyCode = 9L, nativeVirtualKeyCode = 9L)
  klaar <- b$Runtime$evaluate('document.activeElement.closest(".cc-boek") !== null')$result$value
  if (isTRUE(klaar)) break
}
Sys.sleep(0.4)
cat("focus op:", b$Runtime$evaluate('document.activeElement.textContent.trim()')$result$value, "\n")
cat("focus boek bg:", b$Runtime$evaluate(
  'getComputedStyle(document.activeElement.closest(".cc-boek")).backgroundColor')$result$value, "\n")
cat("focus ring:", b$Runtime$evaluate(
  'getComputedStyle(document.activeElement).outlineWidth + " " +
   getComputedStyle(document.activeElement).outlineStyle + " " +
   getComputedStyle(document.activeElement).outlineColor')$result$value, "\n")
b$Runtime$evaluate('document.activeElement.closest(".cc-plank").scrollIntoView({block: "center"})')
Sys.sleep(0.4)
r2 <- jsonlite::fromJSON(b$Runtime$evaluate('(() => { const r = document.querySelector(".cc-plank").getBoundingClientRect();
  return JSON.stringify({x: r.x, y: r.y, w: r.width, h: r.height}); })()')$result$value)
b$screenshot("na/focus_rug_boek1.png", cliprect = c(r2$x - 30, r2$y - 20, r2$w + 60, r2$h + 40))

# geen JavaScript: valt de bladzij terug op de rug-vorm? (attribuut lezen
# via het DOM-domein, want paginascripts staan uit)
b2 <- ChromoteSession$new(width = 1440, height = 1000)
b2$Emulation$setScriptExecutionDisabled(value = TRUE)
b2$Page$navigate("file:///Users/ben/Documents/Ben_OS/countcamp_site/_site/oefenboeken/index.html")
Sys.sleep(3)
doc <- b2$DOM$getDocument()
html_node <- b2$DOM$querySelector(doc$root$nodeId, "html")
attrs <- b2$DOM$getAttributes(html_node$nodeId)$attributes
cat("zonder JS, html-attributen:", paste(attrs, collapse = " "), "\n")
b2$close()
b$close()

# contrast (WCAG-relatieve luminantie), tinten tegen papier en tekst op tint
lum <- function(hex) {
  v <- strtoi(c(substr(hex,2,3), substr(hex,4,5), substr(hex,6,7)), 16L) / 255
  v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  sum(v * c(0.2126, 0.7152, 0.0722))
}
cr <- function(a, b) { la <- lum(a); lb <- lum(b); (max(la,lb)+0.05)/(min(la,lb)+0.05) }
cat("\n-- contrast --\n")
cat("papier #fdfcf9 vs oplichter blauw  #DFEBF2:", round(cr("#fdfcf9","#DFEBF2"),3), "\n")
cat("papier #fdfcf9 vs oplichter paars  #E9E9F3:", round(cr("#fdfcf9","#E9E9F3"),3), "\n")
cat("papier #fdfcf9 vs oplichter groen  #E4EDE7:", round(cr("#fdfcf9","#E4EDE7"),3), "\n")
cat("tekst  #4a4a4a op blauw  #DFEBF2:", round(cr("#4a4a4a","#DFEBF2"),2), "\n")
cat("tekst  #4a4a4a op paars  #E9E9F3:", round(cr("#4a4a4a","#E9E9F3"),2), "\n")
cat("tekst  #4a4a4a op groen  #E4EDE7:", round(cr("#4a4a4a","#E4EDE7"),2), "\n")
cat("titel  #2A79A7 (hoverkleur) op blauw #DFEBF2:", round(cr("#2A79A7","#DFEBF2"),2), "\n")
cat("kop    #1a3a5c op blauw #DFEBF2:", round(cr("#1a3a5c","#DFEBF2"),2), "\n")
