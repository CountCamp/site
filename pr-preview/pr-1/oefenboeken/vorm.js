/* =====================================================================
   DE VORM-SCHAKELAAR — oefenboeken/index.qmd en broertjes/index.html
   Twee vormen voor de boekenlijsten:
     "rug"   — ruggengraatje: geen kaders, dunne gekleurde lijn,
               de hele regel licht op als je eroverheen gaat
     "kaart" — boekenplank: witte kaarten met de sectiekleur als rug

   STANDAARD WISSELEN = alleen het woord hieronder veranderen.
   Per bezoek omzetten kan met ?vorm=rug of ?vorm=kaart achter de URL —
   zo stuur je iemand twee links die dezelfde bladzij in twee vormen
   tonen. De opmaak hangt op html[data-vorm]; zonder JavaScript valt de
   bladzij terug op de rug-vorm. CSS: styles.css ("De boekenplank") en
   de <style> in broertjes/index.html.
   ===================================================================== */
var VORM_STANDAARD = "rug"; /* <-- "rug" of "kaart" */

(function () {
  var v = new URLSearchParams(window.location.search).get("vorm");
  if (v !== "rug" && v !== "kaart") v = VORM_STANDAARD;
  document.documentElement.setAttribute("data-vorm", v);
})();
