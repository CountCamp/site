#!/usr/bin/env bash
# ============================================================
# sitemapwacht_mutatieproef.sh — meet de TOETS, niet de wachter.
#
#   bash _tools/tests/sitemapwacht_mutatieproef.sh
#
# `sitemapwacht_test.sh` groen is een bewering: een toets die nooit rood kán
# worden, staat ook groen. Hier wordt de wachter telkens op één plek kreupel
# gemaakt, en de toets moet dat merken. Blijft hij groen, dan was die plek in
# de wachter versiering.
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
M="$(mktemp -d)"
trap 'rm -rf "$M"' EXIT
zorgelijk=0
getoetst=0

mutatie() {  # $1 = naam, $2 = oud, $3 = nieuw
  local naam="$1"
  getoetst=$((getoetst + 1))
  python3 - "$2" "$3" "$M/kreupel.py" <<'PY'
import sys
oud, nieuw, uit = sys.argv[1], sys.argv[2], sys.argv[3]
s = open("_tools/sitemapwacht.py", encoding="utf-8").read()
if s.count(oud) != 1:
    sys.exit("mutatie niet toepasbaar: %r staat er %d keer in" % (oud, s.count(oud)))
open(uit, "w", encoding="utf-8").write(s.replace(oud, nieuw))
PY
  if [ $? -ne 0 ]; then
    echo "  MISLUKT    $naam -- de mutatie paste niet meer op de code"
    zorgelijk=$((zorgelijk + 1)); return
  fi
  if WACHTER="$M/kreupel.py" bash _tools/tests/sitemapwacht_test.sh > "$M/uit" 2>&1; then
    echo "  VERSIERING $naam -- de toets bleef groen"
    zorgelijk=$((zorgelijk + 1))
  else
    echo "  opgemerkt  $naam -- $(command grep -c '^  ZAKT' "$M/uit") zaak/zaken zakten, bv.:"
    command grep -m1 '^  ZAKT' "$M/uit" | sed 's/^  ZAKT  /               /'
  fi
}

echo "nulmeting: de echte wachter"
if bash _tools/tests/sitemapwacht_test.sh > "$M/uit" 2>&1; then
  echo "  ok         $(tail -1 "$M/uit")"
else
  echo "  MISLUKT    de toets staat al rood met de echte wachter; dit is geen uitslag"
  tail -5 "$M/uit"; exit 1
fi

echo "mutaties"
mutatie "keurt niets meer af" \
  "    if fouten:
        n = sum" \
  "    if False:
        n = sum"
mutatie "ziet geen ontbrekende canonical" \
  "        if not k.canon_kop:
            fout('geen canonical', rel)" \
  "        if False:
            fout('geen canonical', rel)"
mutatie "ziet geen dubbele canonical" \
  "elif len(k.canon_kop) > 1:" "elif len(k.canon_kop) > 2:"
mutatie "keurt het adres van de canonical niet" \
  "elif not R.gelijk_adres(k.canon_kop[0], verwacht):" "elif False:"
mutatie "kijkt niet of de canonical in <head> staat" \
  "        if k.canon_romp:" "        if False:"
mutatie "telt een canonical in <body> mee als in <head>" \
  "(self.canon_kop if self.in_head else self.canon_romp)" "(self.canon_kop)"
mutatie "ziet niet dat een echte bladzij uit de sitemap viel" \
  "            if staat:
                r[1] += 1
            else:" \
  "            if True:
                r[1] += 1
            else:"
mutatie "laat een doorstuurder in de sitemap toe" \
  "            fout('doorstuurder in de sitemap'" "            pass  # fout('doorstuurder in de sitemap'"
mutatie "ziet de vorm …/index.html niet" \
  "        if u.endswith('/index.html'):" "        if False:"
mutatie "ziet een dubbel adres niet" \
  "        if u in in_sitemap:" "        if False:"
mutatie "tweede bron (doorstuurders.tsv) weg" \
  "    for oud in sorted(oude_adressen()):" "    for oud in []:"
mutatie "hreflang niet gekeurd" \
  "        for taal, href in k.hreflang:" "        for taal, href in []:"
mutatie "noindex niet herkend" \
  "                self.noindex = True" "                pass"
mutatie "kopie in de sitemap toegestaan" \
  "            if staat:
                fout('kopie in de sitemap'" \
  "            if False:
                fout('kopie in de sitemap'"
mutatie "geen sitemap is goed" \
  "        fout('geen sitemap.xml', smp)" "        pass"
mutatie "kapotte XML is goed" \
  "        return [], ['sitemap.xml is geen geldige XML: %s' % e]" "        return [], []"
mutatie "sitemap in een proefdruk toegestaan" \
  "            fout('sitemap in een proefdruk', 'sitemap.xml')" "            pass"
mutatie "robots.txt in een proefdruk niet gekeurd" \
  "            fout('robots.txt wijst in een proefdruk naar een sitemap', r_)" "            pass"
mutatie "robots.txt op de echte site niet gekeurd" \
  "        if r_ != R.SITE_URL + '/sitemap.xml':" "        if False:"
mutatie "relatieve canonical in een proefdruk toegestaan" \
  "                    if not href.startswith(R.SITE_URL + '/'):" "                    if False:"
mutatie "blind is groen" \
  "              'nooit goed.' % site)
        return 3" \
  "              'nooit goed.' % site)
        return 0"

# De poort in naar_buiten.sh: een kreupele kopie via NAAR_BUITEN (de bedrading
# en de zaken 39-44 lezen die).
poort() {  # $1 = naam, $2 = oud, $3 = nieuw
  getoetst=$((getoetst + 1))
  python3 - _tools/naar_buiten.sh "$M/naar_buiten.sh" "$2" "$3" <<'PY'
import sys
bron, uit, oud, nieuw = sys.argv[1:5]
s = open(bron, encoding="utf-8").read()
if s.count(oud) != 1:
    sys.exit("mutatie niet toepasbaar: %r staat er %d keer in" % (oud, s.count(oud)))
open(uit, "w", encoding="utf-8").write(s.replace(oud, nieuw))
PY
  if [ $? -ne 0 ]; then
    echo "  MISLUKT    $1 -- de mutatie paste niet meer op de code"
    zorgelijk=$((zorgelijk + 1)); return
  fi
  if NAAR_BUITEN="$M/naar_buiten.sh" bash _tools/tests/sitemapwacht_test.sh > "$M/uit" 2>&1; then
    echo "  VERSIERING $1 -- de toets bleef groen"
    zorgelijk=$((zorgelijk + 1))
  else
    echo "  opgemerkt  $1 -- $(command grep -c '^  ZAKT' "$M/uit") zaak/zaken zakten, bv.:"
    command grep -m1 '^  ZAKT' "$M/uit" | sed 's/^  ZAKT  /               /'
  fi
}
echo "mutaties in naar_buiten.sh"
poort "--productie stopt niet als de sitemappoort rood is" \
  '    gebouwde_sitemap_nakijken echt blokkerend || { echo "  Niet geleverd."; exit 1; }' \
  '    gebouwde_sitemap_nakijken echt blokkerend'
poort "--productie roept de sitemappoort niet aan" \
  '    gebouwde_sitemap_nakijken echt blokkerend || { echo "  Niet geleverd."; exit 1; }
' ''
poort "--lokaal roept de sitemappoort niet aan" \
  '    gebouwde_sitemap_nakijken spook melden
' ''
poort "de sitemappoort houdt nooit tegen" \
  '       echo "  Staat _tools/sitemapwacht.py er, en draait hij los?" ;;
  esac
  if [ "$streng" = blokkerend ]; then return 1; fi' \
  '       echo "  Staat _tools/sitemapwacht.py er, en draait hij los?" ;;
  esac'
poort "de sitemappoort slikt een blinde wachter" \
  '  python3 "$HIER/_tools/sitemapwacht.py" "--$profiel" --site "$HIER/_site" | sed '"'"'s/^/  /'"'"' || code=$?' \
  '  python3 "$HIER/_tools/sitemapwacht.py" "--$profiel" --site "$HIER/_site" | sed '"'"'s/^/  /'"'"' || true'

echo
if [ "$zorgelijk" -eq 0 ]; then
  echo "Alle $getoetst mutaties opgemerkt."
else
  echo "$zorgelijk van $getoetst mutatie(s) NIET opgemerkt of niet toepasbaar."
fi
[ "$zorgelijk" -eq 0 ]
