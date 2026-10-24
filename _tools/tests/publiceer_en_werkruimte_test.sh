#!/usr/bin/env bash
# ============================================================
# publiceer_en_werkruimte_test.sh — draait _tools/publiceer_en.sh zoals de pers
# hem draait: in een checkout waar werkkopieën van zetters naast staan, onder
# .claude/worktrees/. En meet zelf of een mislukte run de repo heel laat.
#
#   bash _tools/tests/publiceer_en_werkruimte_test.sh          alle gevallen
#   bash _tools/tests/publiceer_en_werkruimte_test.sh 2 4      alleen geval 2 en 4
#
# WAAROM (25-10-2026). C voegde en_schil samen in de gedeelde checkout en draaide
# publiceer_en.sh daar. Twee fouten die geen toets zag, want elke toets draaide in
# een verse werkkopie, waar geen .claude/worktrees/ in staat:
#  1. De Nederlandse bouw nam de werkkopieën van andere zetters mee als bijlage:
#     de globs in _quarto-nl.yml ("speeltjes/*.html", "en/**", ...) gelden op
#     elke diepte, dus ook .claude/worktrees/pub_ofb/speeltjes/solomon.html. De
#     keuring zag 13 vreemde bladzijden met hreflang en stopte (afloop 1).
#  2. Daarna stonden en/about.html, index.html, services.html en use.html op
#     verwijderd en was het manifest gewijzigd — terwijl het script belooft dat
#     een gat de repo NIET aanraakt. Quarto bouwt een bladzij naast zijn bron en
#     VERPLAATST hem dan naar de uitvoermap; de gecommitte en/*.html gingen mee.
#
# HOE. Een wegwerpkloon van deze repo onder _site_en_werk/ (gitignored, en de
# Nederlandse bouw slaat hem over), met wat hier ongecommit ligt erin als één
# commit. Daarin twee nep-werkkopieën, zoals in de gedeelde checkout:
#   .claude/worktrees/x/                       een volledige kopie van de repo
#   .claude/worktrees/x/.claude/worktrees/y/   genest: alleen speeltjes/solomon.html
# Elk geval meet het ZELF, niet via wat het script erover zegt: git status, en
# een sha256 van elk bestand onder en/ en van _tools/en_manifest.txt.
#
#   1  de hele gang naast werkkopieën: afloop 0, geen .claude/ in een bouwmap,
#      de werkkopieën onaangeroerd, git status alleen wat afloop 0 belooft
#   6  de keuring noemt een .claude/ in een site bij naam, één keer
#   2  een gat in de spooksite (stap 2)          -> afloop 1, repo als ervoor
#   3  een gat alleen in de echte stap (stap 3)  -> afloop 1, repo als ervoor
#   4  een gat ná het neerzetten in en/ (stap 5) -> afloop 1, repo als ervoor —
#      ook een bladzij die de run er nieuw neerzette, is weer weg
#   5  eerst een geslaagde run (niet gecommit), dan een mislukte: terug naar wat
#      er op de schijf stond, niet naar de laatste commit
#   7  afgeschoten (SIGTERM) ná het neerzetten   -> repo als ervoor
#   8  `en_bouw.py bouw` los, zonder het script eromheen: en/ blijft heel
#   9  een halve bewaarkopie: herstel weigert, en haalt niets weg
#
# Twee beschermingen dekken elkaar met opzet: de Engelse bouw zet en/ zelf terug,
# en stop() zet de hele run terug. Daarom meet geval 8 de eerste los; zonder dat
# geval bleef een kapotte bouw groen, want stop() ruimde zijn rommel op.
#
# Afloop: 0 alle gevallen goed, 1 minstens één fout, 2 de mutatie (zie onder)
# sloeg niet aan, 3 kon niet kijken.
# PROEF_MUTATIE="bestand|||oud|||nieuw" verandert vóór de proef één ding in de
# kloon; zo meet _tools/tests/publiceer_en_werkruimte_mutatieproef.sh of deze
# toets bijt.
# ============================================================
set -uo pipefail
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH";; esac
export PATH
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
P="${PROEF_KLOON:-$REPO/_site_en_werk/proef_werkruimte}"
GEVALLEN="${*:-1 6 2 3 4 5 7 8 9}"
ECHTE_QUARTO="$(command -v quarto)" || { echo "KON NIET KIJKEN: quarto staat niet op het pad"; exit 3; }
GIT=(git -c user.name=proef -c user.email=proef@invalid -c core.hooksPath=/dev/null -c commit.gpgsign=false)

FOUT=0; N=0
uitslag() {  # $1 = 0 goed / anders fout, $2 = wat
  N=$((N + 1))
  if [ "$1" -eq 0 ]; then echo "ok    $2"; else echo "FOUT  $2"; FOUT=$((FOUT + 1)); fi
}
# Eén voorwaarde, of een keten in een eigen functie: `waar a && b` zou alleen a
# meten (de && valt buiten waar), en dan telt een gezakte b stilletjes als goed.
waar() { if "$@"; then echo 0; else echo 1; fi; }

# ------------------------------------------------------------ de kloon ----
echo "kloon: $P"
[ -e "$P" ] && rm -rf "$P"                     # wegwerp van een vorige proef
rm -rf "$P.uit"; mkdir -p "$P.uit"            # logboeken en afdrukken van deze proef
git clone --quiet --shared --no-checkout "$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)" "$P" \
  || { echo "KON NIET KIJKEN: git clone liep vast"; exit 3; }
"${GIT[@]}" -C "$P" checkout --quiet -b proef "$(git -C "$REPO" rev-parse HEAD)" \
  || { echo "KON NIET KIJKEN: checkout liep vast"; exit 3; }
# Wat hier ongecommit ligt, gaat mee: de toets toetst de werkkopie, niet de laatste commit.
n_los=0
while IFS= read -r -d '' f; do
  if [ -f "$REPO/$f" ]; then mkdir -p "$P/$(dirname "$f")"; cp -p "$REPO/$f" "$P/$f"; else rm -f "$P/$f"; fi
  n_los=$((n_los + 1))
done < <(cd "$REPO" && git ls-files -z -m -o --exclude-standard)
if [ -n "${PROEF_MUTATIE:-}" ]; then
  python3 - "$P" "$PROEF_MUTATIE" <<'PY' || exit 2
import os, sys
wortel, (pad, oud, nieuw) = sys.argv[1], sys.argv[2].split("|||")
p = os.path.join(wortel, pad)
s = open(p, encoding="utf-8").read()
if oud not in s:
    sys.exit(f"MUTATIE SLOEG NIET AAN: {oud!r} staat niet in {pad}")
open(p, "w", encoding="utf-8").write(s.replace(oud, nieuw, 1))
print(f"mutatie: {pad}")
PY
fi
"${GIT[@]}" -C "$P" add -A && "${GIT[@]}" -C "$P" commit --quiet --allow-empty -m "proef: basis (+$n_los ongecommit bestand(en) uit de werkkopie)"
"${GIT[@]}" -C "$P" tag basis
echo "  basis: $(git -C "$P" log -1 --format='%h %s')"

# De nep-werkkopieën. x is een volledige kopie van de repo (met een .git-bestand,
# zoals een echte werkkopie); y is genest en heeft alleen het speeltje.
X="$P/.claude/worktrees/x"
mkdir -p "$X" "$X/.claude/worktrees/y/speeltjes"
git -C "$P" archive HEAD | tar -x -C "$X"
printf 'gitdir: /bestaat/niet/.git/worktrees/x\n' > "$X/.git"
cp "$P/speeltjes/solomon.html" "$X/.claude/worktrees/y/speeltjes/solomon.html"
grep -q 'rel="alternate" hreflang=' "$X/speeltjes/solomon.html" \
  || { echo "KON NIET KIJKEN: het nep-speeltje draagt geen hreflang — dan bewijst geval 1 niets"; exit 3; }
werk_afdruk() { (cd "$P" && find .claude -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | cut -c1-16); }
n_werk="$(cd "$P" && find .claude -type f | wc -l | tr -d ' ')"
WERK_VOOR="$(werk_afdruk)"
echo "  nep-werkkopieën: $n_werk bestanden onder .claude/ (bv. .claude/worktrees/x/.claude/worktrees/y/speeltjes/solomon.html)"

# ----------------------------------------------------------- meetlat ----
# De repo zoals deze toets hem ziet: git status, plus de inhoud van alles wat
# het script mag aanraken. Een tweede keer anders gewijzigd blijft voor git
# status " M", daarom de sha256 erbij.
afdruk() {  # $1 = uitvoerbestand
  (cd "$P" && git status --porcelain=v1 --untracked-files=all \
     && find en _tools/en_manifest.txt -type f -print0 | sort -z | xargs -0 shasum -a 256) > "$1"
}
zelfde_als() {  # $1 = afdruk van ervoor, $2 = naam; meet en zegt het verschil
  afdruk "$P.uit/na_$2"
  if cmp -s "$1" "$P.uit/na_$2"; then return 0; fi
  diff "$1" "$P.uit/na_$2" | grep '^[<>]' | head -8 | sed 's/^/        /'
  return 1
}
draai() {  # $1 = naam; daarna eventueel omgeving (VAR=waarde ...)
  local naam="$1"; shift
  (cd "$P" && env EN_BRON=proef "$@" bash _tools/publiceer_en.sh) > "$P.uit/$naam.log" 2>&1
}
stappen() { grep -o '^== [0-9]' "$P.uit/$1.log" | tr -d '= ' | tr '\n' ' '; }
terug_naar_basis() { "${GIT[@]}" -C "$P" reset --quiet --hard basis && "${GIT[@]}" -C "$P" clean -q -fd -- en _tools; }
zet_vast() {  # $1 = boodschap: commit wat er in de kloon veranderd is
  "${GIT[@]}" -C "$P" commit --quiet -am "proef: $1"
}
# een nep-quarto die alles doorgeeft aan de echte, en bij de TWEEDE gewone
# Nederlandse bouw (stap 5 van publiceer_en.sh; stap 1 is de eerste) iets doet:
#   knoei — één spatie erbij in _site/archief/index.html (een Nederlands bestand)
#   schiet — SIGTERM naar het script
nep_quarto() {  # $1 = knoei|schiet ; zet de map op $SHIM
  SHIM="$P.uit/shim_$1"; mkdir -p "$SHIM"; rm -f "$SHIM/teller"
  cat > "$SHIM/quarto" <<EOF
#!/usr/bin/env bash
"$ECHTE_QUARTO" "\$@"; code=\$?
if [ "\$*" = "render" ]; then
  n=\$(( \$(cat "$SHIM/teller" 2>/dev/null || echo 0) + 1 )); echo \$n > "$SHIM/teller"
  if [ \$n -eq 2 ]; then
    case "$1" in
      knoei)  printf ' ' >> _site/archief/index.html ;;
      schiet) kill -TERM \$PPID ;;
    esac
  fi
fi
exit \$code
EOF
  chmod +x "$SHIM/quarto"
}

# ----------------------------------------------------------- gevallen ----
geval_1() {
  terug_naar_basis
  # Zoals in de gedeelde checkout: bouwmappen van vroeger, waar .claude/ al in
  # zit (daar gemeten: _site/.claude/worktrees/pub_ofb/speeltjes/solomon.html).
  # Ruimt de bouw dat niet op, dan zakt de run daar alsnog.
  local m
  for m in _site _site_spook; do
    mkdir -p "$P/$m/.claude/worktrees/oud/speeltjes"
    cp "$P/speeltjes/solomon.html" "$P/$m/.claude/worktrees/oud/speeltjes/solomon.html"
  done
  draai g1; local code=$?
  uitslag "$(waar [ "$code" -eq 0 ])" "geval 1: de hele gang naast werkkopieën — afloop $code (moet 0), stappen: $(stappen g1)"
  [ "$code" -eq 0 ] || grep -E '^ +- |NIET KLAAR' "$P.uit/g1.log" | head -6 | sed 's/^/        /'
  local s n
  for s in _site _site_spook _site_en; do
    n=0; [ -d "$P/$s/.claude" ] && n="$(find "$P/$s/.claude" -type f | wc -l | tr -d ' ')"
    uitslag "$(waar [ "$n" -eq 0 ])" "geval 1: $s/.claude/ — $n bestand(en) (moet 0)"
  done
  local na; na="$(werk_afdruk)"
  uitslag "$(waar [ "$na" = "$WERK_VOOR" ])" "geval 1: de $n_werk bestanden van de werkkopieën onaangeroerd (sha256 $WERK_VOOR -> $na)"
  # wat afloop 0 belooft: het manifest, en gegenereerde bestanden onder en/ — niets anders
  local st anders
  st="$(cd "$P" && git status --porcelain=v1 --untracked-files=all)"
  anders="$(printf '%s\n' "$st" | grep -v -E '^ M _tools/en_manifest\.txt$|^( M|\?\?) en/' | grep -v '^$' || true)"
  uitslag "$(waar [ -z "$anders" ])" "geval 1: git status na afloop 0 — alleen het manifest en en/ ($(printf '%s\n' "$st" | grep -c . | tr -d ' ') regel(s))"
  printf '%s\n' "$st" | sed 's/^/        git status: /'
  [ -z "$anders" ] || printf '%s\n' "$anders" | sed 's/^/        NIET BELOOFD: /'
}

geval_6() {
  # de keuring zelf: een .claude/ in een gebouwde site is één gat, bij naam
  [ -f "$P/_site/en/index.html" ] || { terug_naar_basis; draai g6_vooraf; }
  local plek="$P/_site/.claude/worktrees/z/speeltjes"
  mkdir -p "$plek"; cp "$P/speeltjes/solomon.html" "$plek/solomon.html"
  (cd "$P" && python3 _tools/en_bouw.py keur --site _site --soort echt) > "$P.uit/g6.log" 2>&1; local code=$?
  rm -rf "$P/_site/.claude"
  local bijnaam vreemd
  bijnaam="$(grep -c 'werkruimte.*\.claude/worktrees/z/speeltjes/solomon\.html' "$P.uit/g6.log")"
  # Elke andere gatregel over .claude/, wat hij ook zegt. Eerst telde dit alleen
  # "geen tweeling in taalparen"; het speeltje draagt de balk en geeft dan "draagt
  # de taalbalk maar ...", dus bleef de toets groen terwijl de taalbalk-keuring
  # weer door .claude/ liep (gevonden door de mutatieproef, 25-10-2026).
  vreemd="$(grep '^    - ' "$P.uit/g6.log" | grep '\.claude/' | grep -vc 'werkruimte in de site')"
  goed_6() { [ "$code" -eq 1 ] && [ "$bijnaam" -ge 1 ] && [ "$vreemd" -eq 0 ]; }
  uitslag "$(waar goed_6)" \
    "geval 6: een .claude/ in de site — afloop $code (moet 1), bij naam genoemd: $bijnaam (moet ≥1), als ander gat: $vreemd (moet 0)"
}

geval_2() {
  terug_naar_basis
  printf '\n\n[proef: weg](../bestaat-niet.html)\n' >> "$P/en/about.qmd"; zet_vast "dode link in en/about.qmd"
  afdruk "$P.uit/voor_g2"
  draai g2; local code=$?
  zelfde_als "$P.uit/voor_g2" g2; local zelfde=$?
  goed_2() { [ "$code" -eq 1 ] && grep -q '^== 2' "$P.uit/g2.log" && ! grep -q '^== 3' "$P.uit/g2.log"; }
  uitslag "$(waar goed_2)" \
    "geval 2: gat in de spooksite — afloop $code (moet 1), stappen: $(stappen g2)"
  uitslag "$zelfde" "geval 2: de repo na het gat precies als ervoor (git status + sha256 van en/ en het manifest)"
}

geval_3() {
  terug_naar_basis
  printf '\n\n```{=html}\n<meta name="robots" content="noindex">\n```\n' >> "$P/en/services.qmd"; zet_vast "noindex in en/services.qmd"
  afdruk "$P.uit/voor_g3"
  draai g3; local code=$?
  zelfde_als "$P.uit/voor_g3" g3; local zelfde=$?
  goed_3() { [ "$code" -eq 1 ] && grep -q '^== 3' "$P.uit/g3.log" && ! grep -q '^== 4' "$P.uit/g3.log"; }
  uitslag "$(waar goed_3)" \
    "geval 3: gat alleen in de echte stap — afloop $code (moet 1), stappen: $(stappen g3)"
  uitslag "$zelfde" "geval 3: de repo na het gat precies als ervoor"
}

geval_4() {
  terug_naar_basis
  printf '\n\nProef: een zin erbij, zodat stap 4 en/use.html echt verandert.\n' >> "$P/en/use.qmd"
  # en een nieuwe bladzij: stap 4 zet dan en/proef.html neer, dat er vóór de run niet stond
  printf -- '---\ntitle: "Proef"\nnl_bron: gebruik.qmd@%s\n---\n\nA new page, so that step 4 puts down a file that was not there before the run.\n' \
    "$(git -C "$P" log -1 --format=%h -- gebruik.qmd)" > "$P/en/proef.qmd"
  "${GIT[@]}" -C "$P" add en/proef.qmd; zet_vast "zin erbij in en/use.qmd, nieuwe bladzij en/proef.qmd"
  afdruk "$P.uit/voor_g4"
  nep_quarto knoei
  draai g4 PATH="$SHIM:$PATH"; local code=$?
  zelfde_als "$P.uit/voor_g4" g4; local zelfde=$?
  goed_4() { [ "$code" -eq 1 ] && grep -q '^== 5' "$P.uit/g4.log" && grep -q 'anders: archief/index.html' "$P.uit/g4.log"; }
  uitslag "$(waar goed_4)" \
    "geval 4: gat ná het neerzetten (een Nederlands bestand veranderde) — afloop $code (moet 1), stappen: $(stappen g4)"
  uitslag "$zelfde" "geval 4: de repo na het gat precies als ervoor, ook al stonden en/use.html (anders) en en/proef.html (nieuw) er al"
}

geval_8() {
  # de Engelse bouw los, zonder publiceer_en.sh eromheen: ook die laat en/ heel
  terug_naar_basis
  afdruk "$P.uit/voor_g8"
  (cd "$P" && python3 _tools/en_bouw.py bouw --soort spook) > "$P.uit/g8.log" 2>&1; local code=$?
  zelfde_als "$P.uit/voor_g8" g8; local zelfde=$?
  uitslag "$(waar [ "$code" -eq 0 ])" "geval 8: en_bouw.py bouw los — afloop $code (moet 0)"
  local terug; terug="$(grep -o '[0-9]* teruggezet' "$P.uit/g8.log" | head -1)"
  uitslag "$zelfde" "geval 8: en/ na de Engelse bouw precies als ervoor (${terug:-geen herstelregel in het logboek}, zonder publiceer_en.sh eromheen)"
}

geval_9() {
  # een halve bewaarkopie mag niet gebruikt worden: dan zou herstel goede
  # bestanden weghalen (wat niet in de kopie staat, "maakte de run zelf")
  terug_naar_basis
  (cd "$P" && python3 _tools/en_bouw.py bewaar --naar _site_en_werk/proef_half) > "$P.uit/g9.log" 2>&1
  rm "$P/_site_en_werk/proef_half/en/about.html"                 # de kopie is niet meer heel
  afdruk "$P.uit/voor_g9"
  (cd "$P" && python3 _tools/en_bouw.py herstel --van _site_en_werk/proef_half) >> "$P.uit/g9.log" 2>&1; local code=$?
  zelfde_als "$P.uit/voor_g9" g9; local zelfde=$?
  goed_9() { [ "$code" -eq 3 ] && grep -q 'niet heel' "$P.uit/g9.log"; }
  uitslag "$(waar goed_9)" "geval 9: herstel met een halve bewaarkopie — afloop $code (moet 3), weigert hardop"
  uitslag "$zelfde" "geval 9: en daarbij niets weggehaald en niets teruggezet (en/about.html staat er nog)"
}

geval_5() {
  terug_naar_basis
  printf '\n\nProef: een zin erbij, zodat stap 4 en/use.html echt verandert.\n' >> "$P/en/use.qmd"; zet_vast "zin erbij in en/use.qmd"
  draai g5a; local code=$?
  goed_5a() { [ "$code" -eq 0 ] && (cd "$P" && git status --porcelain | grep -q '^ M en/use.html$'); }
  uitslag "$(waar goed_5a)" \
    "geval 5: eerst een geslaagde run — afloop $code (moet 0), en/use.html gewijzigd en niet gecommit"
  printf '\n\n[proef: weg](../bestaat-niet.html)\n' >> "$P/en/about.qmd"   # niet gecommit
  afdruk "$P.uit/voor_g5"
  draai g5b; code=$?
  zelfde_als "$P.uit/voor_g5" g5; local zelfde=$?
  uitslag "$(waar [ "$code" -eq 1 ])" "geval 5: dan een mislukte run — afloop $code (moet 1), stappen: $(stappen g5b)"
  uitslag "$zelfde" "geval 5: terug naar wat er op de schijf stond (de ongecommitte en/ van de vorige run), niet naar de laatste commit"
}

geval_7() {
  terug_naar_basis
  printf '\n\nProef: een zin erbij, zodat stap 4 en/use.html echt verandert.\n' >> "$P/en/use.qmd"; zet_vast "zin erbij in en/use.qmd"
  afdruk "$P.uit/voor_g7"
  nep_quarto schiet
  draai g7 PATH="$SHIM:$PATH"; local code=$?
  zelfde_als "$P.uit/voor_g7" g7; local zelfde=$?
  goed_7() { [ "$code" -ne 0 ] && grep -q '^== 5' "$P.uit/g7.log"; }
  uitslag "$(waar goed_7)" \
    "geval 7: afgeschoten ná het neerzetten — afloop $code (moet niet 0 zijn), stappen: $(stappen g7)"
  uitslag "$zelfde" "geval 7: de repo na het afschieten precies als ervoor"
}

for g in $GEVALLEN; do
  case "$g" in
    1|2|3|4|5|6|7|8|9) echo; echo "-- geval $g"; "geval_$g" ;;
    *) echo "onbekend geval: $g (kies uit 1 tot en met 9)"; exit 2 ;;
  esac
done

echo
if [ "$FOUT" -eq 0 ]; then echo "$N van $N toetsen goed"; else echo "$((N - FOUT)) van $N toetsen goed — $FOUT FOUT"; fi
echo "logboeken per geval: $P.uit/"
[ "$FOUT" -eq 0 ] && [ "$N" -gt 0 ]
