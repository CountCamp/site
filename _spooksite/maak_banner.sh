#!/usr/bin/env bash
# ============================================================
# maak_banner.sh — schrijft de balk die op elke proefbladzij staat.
# ------------------------------------------------------------
#   bash _spooksite/maak_banner.sh "<wat dit is>" ["<waar het vandaan komt>"]
#
# Bijvoorbeeld:
#   bash _spooksite/maak_banner.sh "proefdruk van PR #42" "tak stippen"
#   bash _spooksite/maak_banner.sh "lokale proefdruk"
#
# WAAROM DIT EEN SCRIPT IS EN GEEN VAST BESTAND. De balk moet uit een
# BOUW-VARIABELE komen, niet uit iets dat iemand met de hand aan- en uitzet.
# Een balk die je met de hand zet, vergeet je met de hand weg te halen — en
# dan staat "PROEFDRUK" op de echte site, of erger: hij staat er níét terwijl
# je wél naar een proefdruk kijkt. Dit script draait in de bouw, met de
# gegevens van die bouw erin, en het bestand dat het schrijft staat buiten
# versiebeheer. Zo kan de balk niet liegen: hij bestaat alleen waar hij hoort.
#
# Ontbreekt het bestand, dan faalt de proefdruk-bouw luidruchtig. Dat is de
# bedoeling: een proefdruk zonder balk is een proefdruk die zich voordoet als
# de echte site.
# ============================================================
set -euo pipefail
HIER="$(cd "$(dirname "$0")" && pwd)"
WAT="${1:?geef in een paar woorden wat dit is, bv. \"proefdruk van PR #42\"}"
HERKOMST="${2:-}"
WANNEER="$(date '+%Y-%m-%d %H:%M')"

# Geen inhoud van buiten rechtstreeks in html. Een taknaam met een < erin zou
# anders de bladzij kunnen breken.
ontsmet() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'; }

{
  printf '<div class="spookbalk" role="status">\n'
  printf '  <strong>PROEFDRUK — dit is niet de echte site.</strong>\n'
  printf '  <span>%s' "$(ontsmet "$WAT")"
  [ -n "$HERKOMST" ] && printf ' · %s' "$(ontsmet "$HERKOMST")"
  printf ' · gebouwd %s</span>\n' "$WANNEER"
  printf '  <span class="spookbalk-thuis"><a href="https://countcamp.org">naar de echte site</a></span>\n'
  printf '</div>\n'
  cat <<'CSS'
<style>
/* ONDERAAN vastgezet, niet bovenaan. De site heeft zelf al een navigatiebalk
   die bovenin blijft plakken (body.nav-fixed); een tweede plakker daar
   verdwijnt er bij het scrollen achter. Onderaan botst hij met niets en is
   hij op élke bladzij en op élke scrollhoogte te zien — en dat is de hele
   opdracht van deze balk: je mag nooit vergeten dat je naar een proefdruk
   kijkt. Gemeten met schermafdrukken, boven en halverwege, breed en op 390px. */
.spookbalk{
  position:fixed; left:0; right:0; bottom:0; z-index:99999;
  background:#7b2d26; color:#fff;
  font-family:system-ui,-apple-system,sans-serif; font-size:.86rem; line-height:1.5;
  padding:.5rem 1rem; display:flex; flex-wrap:wrap; gap:.1rem .9rem; align-items:baseline;
  border-top:3px solid #4a1a15; box-shadow:0 -6px 18px rgba(0,0,0,.18);
}
.spookbalk strong{ letter-spacing:.04em; }
.spookbalk a{ color:#fff; text-decoration:underline; }
.spookbalk-thuis{ margin-left:auto; }
/* Ruimte onderaan de bladzij, anders dekt de balk de laatste regels af. */
body{ padding-bottom:4.5rem; }
@media print{ .spookbalk{ position:static; } body{ padding-bottom:0; } }
</style>
CSS
} > "$HIER/banner.html"

echo "balk geschreven: $HIER/banner.html  ($WAT${HERKOMST:+ · $HERKOMST})"
