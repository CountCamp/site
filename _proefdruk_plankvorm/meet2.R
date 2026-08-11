# Herkansing detailschoten (clip in paginacoördinaten, dus + scrollY).
library(chromote)
b <- ChromoteSession$new(width = 1440, height = 1000)
b$Page$navigate("file:///Users/ben/Documents/Ben_OS/countcamp_site/_site/oefenboeken/index.html")
Sys.sleep(3)

paginarect <- function(sel) jsonlite::fromJSON(b$Runtime$evaluate(sprintf(
  '(() => { const r = document.querySelector("%s").getBoundingClientRect();
     return JSON.stringify({x: r.x + window.scrollX, y: r.y + window.scrollY,
                            w: r.width, h: r.height,
                            vx: r.x + r.width/2, vy: r.y + r.height/2}); })()', sel))$result$value)

# hover op de eerste regel (blauw), schot van de hele eerste plank
b$Runtime$evaluate('document.querySelector(".cc-plank").scrollIntoView({block: "center"})')
Sys.sleep(0.5)
p <- paginarect(".cc-boek")
b$Input$dispatchMouseEvent(type = "mouseMoved", x = p$vx, y = p$vy)
Sys.sleep(0.6)
r <- paginarect(".cc-plank")
b$screenshot("na/hover_rug_boek1.png", cliprect = c(r$x - 40, r$y - 25, r$w + 80, r$h + 50))
cat("hover-schot:", r$h, "px plank\n")

# toetsenbordfocus op de eerste boeklink, schot van dezelfde plank
b$Input$dispatchMouseEvent(type = "mouseMoved", x = 5, y = 5)
b$Runtime$evaluate('window.scrollTo(0,0)')
Sys.sleep(0.3)
for (i in 1:40) {
  b$Input$dispatchKeyEvent(type = "keyDown", key = "Tab", code = "Tab",
                           windowsVirtualKeyCode = 9L, nativeVirtualKeyCode = 9L)
  b$Input$dispatchKeyEvent(type = "keyUp", key = "Tab", code = "Tab",
                           windowsVirtualKeyCode = 9L, nativeVirtualKeyCode = 9L)
  Sys.sleep(0.15)
  klaar <- b$Runtime$evaluate('document.activeElement.closest(".cc-boek") !== null')$result$value
  if (isTRUE(klaar)) break
}
cat("focus op:", b$Runtime$evaluate('document.activeElement.textContent.trim()')$result$value, "\n")
b$Runtime$evaluate('document.activeElement.closest(".cc-plank").scrollIntoView({block: "center"})')
Sys.sleep(0.4)
r <- jsonlite::fromJSON(b$Runtime$evaluate(
  '(() => { const r = document.activeElement.closest(".cc-plank").getBoundingClientRect();
     return JSON.stringify({x: r.x + window.scrollX, y: r.y + window.scrollY,
                            w: r.width, h: r.height}); })()')$result$value)
b$screenshot("na/focus_rug_boek1.png", cliprect = c(r$x - 40, r$y - 25, r$w + 80, r$h + 50))
cat("focus-schot klaar\n")
b$close()
