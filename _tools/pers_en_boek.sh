#!/usr/bin/env bash
# ============================================================
# pers_en_boek.sh — Engelse boekhoofdstukken uit het lab op de site, in de drie
# fasen die de wachtrij van het Engelse spoor verwacht.
# ------------------------------------------------------------
#   bash _tools/pers_en_boek.sh <H>... spook   de lab-pers schrijft <site>/en/book/h<n>.html,
#                                              de taalstukken gaan erin (beide kanten),
#                                              en de spooksite wordt gebouwd en gekeurd
#   bash _tools/pers_en_boek.sh <H>... links   de echte keuring (links, merken, tweelingen,
#                                              taalbalk) op een verse Nederlandse bouw
#   bash _tools/pers_en_boek.sh <H>... echt    publiceer_en.sh (de hele gang, afloop 0),
#                                              dan naar_buiten.sh --nakijken
#
#   <H> is een hoofdstuk zoals de lab-pers het noemt: H0, H1 ... (publiceer.sh --en H0).
#   De fase is het LAATSTE woord, want zo roept de wachtrij een pers aan
#   (wachtrij_en.tsv, kolom pers: '<pers> spook', '<pers> links', '<pers> echt').
#   In de rij is de pers dus bijvoorbeeld:
#       bash "$WACHTRIJ_SITE/_tools/pers_en_boek.sh" H0
#   en met de hand, in de gedeelde checkout van de site, alle drie na elkaar:
#       for f in spook links echt; do bash _tools/pers_en_boek.sh H0 $f || break; done
#
# WELKE SITE, WELK LAB
#   site  $WACHTRIJ_SITE, anders $PUBLICATIE_SITE, anders de repo van dit script.
#   lab   $WACHTRIJ_REPO als dat een lab is (er staat boek/publiceer.sh in), anders
#         $PERS_LAB, anders countcamp_lab naast de site — zoals het lab de site naast
#         zich zoekt (boek/_tools/publicatie/_gemeenschappelijk.sh).
#
# AFLOOP (huisafspraak): 0 deze fase is groen · 1 er is een gat (de regels erboven
# zeggen welk) · 2 verkeerd aangeroepen, of iets ontbreekt · 3 kon niet kijken, of
# niet gemeten. Stilte is nooit groen: elke fase zegt wat ze bekeek.
#
# WAT HET AANRAAKT. In de site: en/book/h<n>.html (de lab-pers), de taalstukken in
# die bladzij en in haar Nederlandse tweeling manuscript/h<n>.html (taalonderdelen.py
# los), en — alleen in fase echt, bij afloop 0 — wat publiceer_en.sh bij afloop 0
# schrijft: de gegenereerde en/*.html, en/libs/ en _tools/en_manifest.txt. In het lab:
# alleen de render naast de bron (boek/en/H<n>_en.html, gitignored). Het commit niet
# en pusht niet; dat doet de rij, of de meesterknecht met de hand:
#     git add en manuscript/h<n>.html _tools/en_manifest.txt && git commit
#     bash _tools/naar_buiten.sh --productie
#
# DE ENIGE NEDERLANDSE WIJZIGING is het knopje, hreflang en de taalbalk op
# manuscript/h<n>.html. Fase spook meet dat zelf na: haal je de stukken die de
# wachtrij mag weglaten (taalonderdelen.py regels) uit elk Nederlands bestand dat
# veranderde, dan staat er byte voor byte wat er in de laatste commit stond. Elk
# ander Nederlands verschil is een gat.
#
# IN DE WACHTRIJ (WACHTRIJ_FASE staat), en waarom de nooddeur van het lab hier open
# mag. De lab-pers weigert in een werkkopie: zijn poort vraagt "loopt deze werkkopie
# achter op zijn remote?", en een werkkopie-tak heeft geen remote (afloop 3) — en in
# de rij is het netwerk van git dicht (protocol.allow=never), dus ophalen lukt ook
# niet. Die vraag beantwoordt de rij zelf: hij zet de tak eerst op de live commit
# (rebase op origin/main) en draait dan pas de pers. Dit script meet dat na, lokaal en
# zonder netwerk — bevat HEAD van het lab origin/main? — en opent pas dan de nooddeur
# (PUBLICATIE_STIL=1), die dat hardop zegt. Loopt het lab achter, dan weigert het.
# Buiten de rij gaat de nooddeur nooit open: dan meet de poort van het lab gewoon zelf.
#
# WAT DE RIJ NU NOG TEGENHOUDT — gemeten 25-10-2026 met de echte functies van
# wachtrij.py (lees_rij, paden_toets, nl_controle) op wat dit script in een
# nagebootste rij schreef (lab-werkkopie op 4906f691, site-kloon van en_boekpers).
# Geen van vier is in dit script op te lossen; het zijn keuzes in de rij of het lab.
#   1. Het git-netwerk van de rij (protocol.allow=never) sluit ook het lokale
#      transport, en daarop zakt boek/_tools/publicatie/zelftest.sh in de boekpoort:
#      37 van 92 ("fatal: transport 'file' not allowed"). Dat raakt de lab-pers hier
#      én de '#: poort lab' van de rij, dus elke lab-stap. Met alleen
#      protocol.file.allow=always erbij: 92 van 92, en dan gaan alle drie de fasen groen.
#   2. publiceer_en.sh schrijft bij afloop 0 _tools/en_manifest.txt, en '_tools/*'
#      is '#: beschermd' voor de site.
#   3. manuscript/h<n>.html valt buiten '#: bron_engels site'.
#   4. En dan zegt nl_controle "1 Nederlands bestand anders" — het rijbestand heeft
#      geen '#: nl_negeer'. Met de vijf regels van `taalonderdelen.py regels`: door,
#      0 Nederlands anders, 0 nieuwe kapotte verwijzingen.
#
# PER HOOFDSTUK, en wat dat niet dekt. De Engelse zijbalk (in het lab gemaakt)
# noemt elk hoofdstuk waarvan het lab een H<n>_en.qmd heeft, in JavaScript. Wie H1
# alleen perst, laat h0.html staan met een zijbalk zonder H1 — dat ziet geen
# keuring. Wie H0 perst terwijl het lab al een H1 heeft die nog niet op de site
# staat, zet een dode zijbalk-link neer; die weigert en_bouw.py sinds dit spoor
# (de linkkeuring zelf leest alleen href= en src=, en zag hem niet). Pers daarom
# alle Engelse hoofdstukken samen: <pers> H0 H1 <fase>.
#
# Ontstaan: spoor en_boekpers, 25-10-2026.
# ============================================================
set -uo pipefail
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH";; esac
export PATH
HIER_REPO="$(cd "$(dirname "$0")/.." && pwd)"

zeg() { echo "$*"; }
stop() { local c="$1"; shift; echo; echo "NIET GROEN (afloop $c): $*"; exit "$c"; }

[ $# -ge 2 ] || { sed -n '4,22p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
FASE="${!#}"
HS=("${@:1:$#-1}")
case "$FASE" in spook|links|echt) ;; *) stop 2 "de fase is het laatste woord: spook, links of echt — niet '$FASE'" ;; esac
for h in "${HS[@]}"; do
  [[ "$h" =~ ^[A-Za-z0-9_]+$ ]] || stop 2 "'$h' is geen bladzijnaam van de lab-pers (zoals H0)"
done

SITE="${WACHTRIJ_SITE:-${PUBLICATIE_SITE:-$HIER_REPO}}"
SITE="$(cd "$SITE" 2>&1 && pwd)" || stop 2 "de site bestaat niet: ${WACHTRIJ_SITE:-${PUBLICATIE_SITE:-$HIER_REPO}}"
[ -f "$SITE/_tools/publiceer_en.sh" ] || stop 2 "$SITE is geen site met een Engelse schil (_tools/publiceer_en.sh ontbreekt)"
is_lab() { [ -f "$1/boek/publiceer.sh" ] && [ -f "$1/boek/_tools/publicatie/_gemeenschappelijk.sh" ]; }
if [ -n "${WACHTRIJ_REPO:-}" ] && is_lab "$WACHTRIJ_REPO"; then LAB="$WACHTRIJ_REPO"
elif [ -n "${PERS_LAB:-}" ]; then LAB="$PERS_LAB"
else LAB="$(dirname "$SITE")/countcamp_lab"; fi
is_lab "$LAB" || stop 2 "geen lab gevonden in $LAB (boek/publiceer.sh) — zet PERS_LAB"
LAB="$(cd "$LAB" && pwd)"
IN_RIJ=nee; [ -n "${WACHTRIJ_FASE:-}" ] && IN_RIJ=ja

# De bladzij van hoofdstuk H op de site: dezelfde regel als pub_doelnaam in het lab.
doel() { if [[ "$1" =~ ^H[0-9]+$ ]]; then echo "en/book/$(echo "$1" | tr 'H' 'h').html"; else echo "en/book/$1.html"; fi; }

zeg "== pers_en_boek.sh $FASE: ${HS[*]}"
zeg "  site: $SITE"
zeg "  lab:  $LAB$( [ "$IN_RIJ" = ja ] && echo "   (in de wachtrij, stap ${WACHTRIJ_STAP:-?})")"

# ---- de bladzijden staan er, en hun stempel klopt — ook tegen het lab ---------
# Dat de stempel de vorm heeft, ziet en_bouw.py ook (LAB_STEMPEL). Of de hash bij
# de bronnen van DIT lab hoort, ziet alleen wie het lab erbij heeft: dat is hier.
# pub_bron_hash in een subshell, zodat de variabelen van het lab hier niet blijven.
lab_hash() { ( PUB_TAAL=en; PUBLICATIE_SITE="$SITE"; . "$LAB/boek/_tools/publicatie/_gemeenschappelijk.sh" && pub_bron_hash "$1" ); }
keur_stempels() {
  local h rel verwacht uit fout=0
  for h in "${HS[@]}"; do
    rel="$(doel "$h")"
    verwacht="$(lab_hash "$h")" || verwacht=""
    if [ -z "$verwacht" ]; then echo "  $rel: de bron-hash van $h in het lab is niet uit te rekenen (ontbreekt er een bron?)"; fout=3; continue; fi
    uit="$(python3 - "$SITE" "$rel" "$verwacht" <<'PY'
import os, re, sys
site, rel, verwacht = sys.argv[1:4]
sys.path.insert(0, os.path.join(site, "_tools"))
import en_bouw
pad = os.path.join(site, rel)
if not os.path.isfile(pad):
    print(f"{rel}: staat niet in de site"); sys.exit(1)
t = open(pad, encoding="utf-8", errors="replace").read()
ja, reden = en_bouw.uit_het_lab(rel, t)
if not ja:
    print(reden or f"{rel}: draagt geen stempel van de lab-pers"); sys.exit(1)
h = re.findall(r"bron-hash=([0-9a-f]{64})", t[t.rfind("</html>"):])[-1]
if h != verwacht:
    print(f"{rel}: de stempel zegt bron-hash {h[:12]}…, de bronnen in het lab geven nu {verwacht[:12]}… — "
          f"de bladzij is niet van deze bronnen (of een bron veranderde tijdens de pers)"); sys.exit(1)
print(f"{rel}: stempel klopt, en hoort bij de bronnen in het lab ({h[:12]}…)")
PY
)"; local c=$?
    echo "  $uit"
    [ "$c" -eq 0 ] || { [ "$fout" -eq 3 ] || fout=1; }
  done
  return "$fout"
}

# ---- de enige Nederlandse wijziging: de taalstukken ---------------------------
# Elk Nederlands bestand in de site dat niet schoon is (alles buiten en/), moet een
# gevraagde manuscript/h<n>.html zijn, en zonder de stukken die de wachtrij weglaat
# precies zijn wat er in HEAD staat. Gemeten op git status, ongetrackt meegeteld.
keur_nederlands() {
  python3 - "$SITE" "${HS[@]}" <<'PY'
import os, re, subprocess, sys
site, hs = sys.argv[1], sys.argv[2:]
sys.path.insert(0, os.path.join(site, "_tools"))
import taalonderdelen as TO
toegestaan = {"manuscript/" + (h.lower() if re.fullmatch(r"H\d+", h) else h) + ".html" for h in hs}
r = subprocess.run(["git", "-C", site, "status", "--porcelain=v1", "-z", "--untracked-files=all"],
                   capture_output=True, text=True)
if r.returncode != 0:
    print(f"  Nederlands: git status liep vast — kon niet kijken: {r.stderr.strip()[:200]}"); sys.exit(3)
paden = [e[3:] for e in r.stdout.split("\0") if len(e) > 3]
nl = sorted(p for p in paden if not (p == "en" or p.startswith("en/")))
def zonder(t):
    for _n, rx in TO.negeer_regexen():
        t = re.sub(rx, "", t)
    return t
fout = []
for p in nl:
    if p not in toegestaan:
        fout.append(f"{p}: veranderde buiten en/, en deze pers raakt daar alleen de gevraagde manuscript/h<n>.html"
                    f" (ligt er ander werk in deze checkout? draai de pers op een schone)"); continue
    oud = subprocess.run(["git", "-C", site, "show", f"HEAD:{p}"], capture_output=True, text=True)
    if oud.returncode != 0:
        fout.append(f"{p}: staat niet in HEAD — een nieuwe Nederlandse bladzij maakt deze pers nooit"); continue
    nu = open(os.path.join(site, p), encoding="utf-8").read()
    if zonder(nu) != zonder(oud.stdout):
        fout.append(f"{p}: verschilt van HEAD in meer dan de taalstukken (knopje, hreflang, taalbalk)")
print(f"  Nederlands: {len(nl)} bestand(en) buiten en/ veranderd, {len(fout)} meer dan de taalstukken"
      + (f" — bv. {nl[0]}" if nl else ""))
for f in fout:
    print("    - " + f)
sys.exit(1 if fout else 0)
PY
}

case "$FASE" in
# ------------------------------------------------------------------ spook ----
spook)
  zeg; zeg "-- 1. de lab-pers: publiceer.sh --en ${HS[*]}, naar deze site"
  if [ "$IN_RIJ" = ja ]; then
    hoofd="$(git -C "$LAB" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>&1)" && hoofd="${hoofd#origin/}" || hoofd=main
    git -C "$LAB" rev-parse --verify --quiet "origin/$hoofd^{commit}" >/dev/null \
      || stop 3 "het lab heeft geen origin/$hoofd — kon niet meten of deze werkkopie bij is"
    if git -C "$LAB" merge-base --is-ancestor "origin/$hoofd" HEAD; then
      zeg "  gemeten, lokaal en zonder netwerk: HEAD van het lab ($(git -C "$LAB" rev-parse --short HEAD)) bevat"
      zeg "  origin/$hoofd ($(git -C "$LAB" rev-parse --short "origin/$hoofd")). Dat is de vraag van de poort van het lab, en die"
      zeg "  kan in de rij zelf niet kijken (geen remote op de tak, netwerk dicht): daarom PUBLICATIE_STIL=1."
      export PUBLICATIE_STIL=1
    else
      stop 1 "de werkkopie van het lab bevat origin/$hoofd niet: hij loopt achter, en dan zet de pers oude bestanden online"
    fi
  fi
  # Zonder OEFENBOEKEN_SITE: die zet de rij voor publiceer_oefenboeken.sh, en de
  # boekpers gebruikt hem niet — maar zijn boekpoort geeft hem door aan de
  # publicatie-zelftest van het lab, en daar wijst hij een zandbak naar deze site.
  # Gemeten 25-10-2026 in een lab-werkkopie: met de omgeving van de rij zakt T48a
  # ("BLIND: <zandbak>/oefenboeken/_poort/poort.sh niet gevonden"), zonder deze
  # ene variabele niet. De boekpoort haalt de PUBLICATIE_*-knoppen al weg, deze nog niet.
  rc=0; env -u OEFENBOEKEN_SITE PUBLICATIE_SITE="$SITE" bash "$LAB/boek/publiceer.sh" --en "${HS[@]}" || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "de lab-pers gaf afloop $rc (zie hierboven) — er is niets gekeurd"
  zeg; zeg "-- 2. de stempels: van de lab-pers, en van deze bronnen"
  rc=0; keur_stempels || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "een bladzij uit het lab draagt niet de stempel die hij hoort te dragen"
  zeg; zeg "-- 3. de taalstukken in beide kanten: taalonderdelen.py los"
  rc=0; python3 "$SITE/_tools/taalonderdelen.py" los | sed 's/^/  /' || rc=$?
  [ "$rc" -eq 0 ] || stop 1 "taalonderdelen.py los gaf afloop $rc"
  rc=0; keur_nederlands || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "er veranderde meer Nederlands dan het knopje"
  zeg; zeg "-- 4. de spooksite: publiceer_en.sh --alleen-spook"
  rc=0; bash "$SITE/_tools/publiceer_en.sh" --alleen-spook || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "de spooksite heeft gaten, of kon niet gebouwd worden (zie hierboven)"
  ;;
# ------------------------------------------------------------------ links ----
links)
  zeg; zeg "-- de bladzijden staan er, met hun stempel"
  rc=0; keur_stempels || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "niet alle gevraagde bladzijden staan er als bladzij uit het lab — eerst fase spook"
  zeg; zeg "-- de echte keuring op een verse Nederlandse bouw: publiceer_en.sh --nakijken"
  rc=0; bash "$SITE/_tools/publiceer_en.sh" --nakijken || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "de keuring vond gaten (zie hierboven)"
  ;;
# ------------------------------------------------------------------- echt ----
echt)
  zeg; zeg "-- de bladzijden staan er, met hun stempel"
  rc=0; keur_stempels || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "niet alle gevraagde bladzijden staan er als bladzij uit het lab — eerst fase spook"
  rc=0; keur_nederlands || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "er veranderde meer Nederlands dan het knopje"
  zeg; zeg "-- de hele gang: publiceer_en.sh"
  [ "$IN_RIJ" = ja ] && export EN_BRON="${EN_BRON:-wachtrij_en}"
  rc=0; bash "$SITE/_tools/publiceer_en.sh" || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "publiceer_en.sh gaf afloop $rc (zie hierboven)"
  zeg; zeg "-- de poort van de site: naar_buiten.sh --nakijken"
  rc=0; bash "$SITE/_tools/naar_buiten.sh" --nakijken || rc=$?
  [ "$rc" -eq 0 ] || stop "$rc" "de poort van de site staat rood (zie hierboven)"
  zeg; zeg "-- wat er nu in de site klaarstaat (git status):"
  git -C "$SITE" status --short --untracked-files=all | sed 's/^/  /'
  ;;
esac
zeg; zeg "FASE $FASE GROEN voor ${HS[*]}."
exit 0
