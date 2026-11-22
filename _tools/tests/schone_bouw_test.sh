#!/usr/bin/env bash
# ============================================================
# schone_bouw_test.sh — houdt de site-bouw Quarto uit .claude/?
#
#   bash _tools/tests/schone_bouw_test.sh
#
# WAAROM (22-11-2026, spoor pers_nacht). In de gedeelde checkout liep
# `naar_buiten.sh --productie` twee keer vast op de werkkopie van een andere
# zetter (NotFound ... stat .claude/worktrees/taalpers/_site_en_werk/...).
# Quarto 1.9.38 loopt bij elke website-bouw de hele projectmap af, op de
# uitvoermap na; geen instelling houdt hem eruit. Sindsdien bouwen de scripts via
# _tools/schone_bouw.py, in een kopie zonder .claude/. Zie de kop daarvan.
#
# HOE. Een wegwerpkloon onder _site_en_werk/ (gitignored, en de schone bouw neemt
# _site* niet mee), met wat hier ongecommit ligt erin. Daarin een proefboom met
# een DICHTE map (chmod 000): loopt iets daar in, dan stopt de bouw met
# PermissionDenied. Eén bovenaan (.claude/worktrees/_proef/, zoals een werkkopie)
# en één dieper (oefenboeken/.claude/, onder een bijlage-glob).
#
#   1  --lokaal naast de proefboom: afloop 0, niets uit de proefboom in _site/,
#      de proefboom onaangeroerd (sha256 van elk bestand en elke link)
#   2  schone_bouw.py weigert een --uit die geen bouwmap is, en raakt die map niet
#   3  geen script bouwt ter plaatse: naar_buiten.sh, publiceer_en.sh en
#      en_bouw.py roepen quarto alleen via schone_bouw.py aan
#   4  BIJTPROEF: dezelfde --lokaal met de bouw terug ter plaatse moet stuklopen
#      op de dichte map; en een kale quarto-aanroep erbij moet zaak 3 laten zakken
#
# Afloop: 0 alles goed, 1 minstens één fout, 2 een mutatie sloeg niet aan,
# 3 kon niet kijken.
# ============================================================
set -uo pipefail
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH";; esac
export PATH LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
P="$REPO/_site_en_werk/schone_bouw_proef"
command -v quarto >/dev/null || { echo "KON NIET KIJKEN: quarto staat niet op het pad"; exit 3; }
GIT=(git -c user.name=proef -c user.email=proef@invalid -c core.hooksPath=/dev/null -c commit.gpgsign=false)

FOUT=0; N=0
uitslag() {  # $1 = 0 goed / anders fout, $2 = wat
  N=$((N + 1))
  if [ "$1" -eq 0 ]; then echo "ok    $2"; else echo "FOUT  $2"; FOUT=$((FOUT + 1)); fi
}
waar() { if "$@"; then echo 0; else echo 1; fi; }

DICHT=()
opruimen() {
  local d
  for d in "${DICHT[@]}"; do [ -d "$d" ] && chmod 755 "$d"; done
  rm -rf "$P"
}
trap opruimen EXIT

# ------------------------------------------------------------ de kloon ----
[ -e "$P" ] && { chmod -R u+rwx "$P" 2>&1 | head -2; rm -rf "$P"; }
git clone --quiet --shared --no-checkout "$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)" "$P" \
  || { echo "KON NIET KIJKEN: git clone liep vast"; exit 3; }
"${GIT[@]}" -C "$P" checkout --quiet -b proef "$(git -C "$REPO" rev-parse HEAD)" \
  || { echo "KON NIET KIJKEN: checkout liep vast"; exit 3; }
n_los=0
while IFS= read -r -d '' f; do
  if [ -f "$REPO/$f" ]; then mkdir -p "$P/$(dirname "$f")"; cp -p "$REPO/$f" "$P/$f"; else rm -f "$P/$f"; fi
  n_los=$((n_los + 1))
done < <(cd "$REPO" && git ls-files -z -m -o --exclude-standard)
echo "kloon: $P  (HEAD $(git -C "$REPO" log -1 --format=%h) + $n_los ongecommit bestand(en))"

# ---------------------------------------------------------- proefboom ----
maak_boom() {  # $1 = map
  local b="$1"
  mkdir -p "$b/speeltjes" "$b/oefenboeken/ts" "$b/en" "$b/_site_en_werk/proef_werkruimte" "$b/gesloten"
  printf -- '---\ntitle: proef\n---\n\nPROEF_SCHONE_BOUW\n' > "$b/index.qmd"
  printf '<html><head></head><body>PROEF_SCHONE_BOUW</body></html>\n' > "$b/speeltjes/proef.html"
  cp "$b/speeltjes/proef.html" "$b/oefenboeken/ts/proef.html"
  cp "$b/speeltjes/proef.html" "$b/en/proef.html"
  echo proef > "$b/CNAME"
  echo binnen > "$b/gesloten/binnen.html"
  ln -sf /bestaat/niet/weg.html "$b/_site_en_werk/proef_werkruimte/weg.html"
}
BOVEN="$P/.claude/worktrees/_proef"
DIEP="$P/oefenboeken/.claude"
maak_boom "$BOVEN"; maak_boom "$DIEP"
afdruk() {  # sha256 van elk bestand, en van elke link zijn doel (de proeflink wijst nergens heen)
  (cd "$P" && {
     find .claude oefenboeken/.claude -type f -print0 | sort -z | xargs -0 shasum -a 256
     find .claude oefenboeken/.claude -type l | sort | while IFS= read -r l; do echo "$l -> $(readlink "$l")"; done
   } | shasum -a 256 | cut -c1-16)
}
n_boom="$(cd "$P" && find .claude oefenboeken/.claude \( -type f -o -type l \) | wc -l | tr -d ' ')"
VOOR="$(afdruk)"
chmod 000 "$BOVEN/gesloten" "$DIEP/gesloten"; DICHT=("$BOVEN/gesloten" "$DIEP/gesloten")
echo "proefboom: $n_boom bestanden/links in .claude/worktrees/_proef/ en oefenboeken/.claude/, twee dichte mappen"

lokaal() {  # $1 = naam van het logboek
  (cd "$P" && bash _tools/naar_buiten.sh --lokaal) > "$P.$1.log" 2>&1
}

# ------------------------------------------------------------- zaak 1 ----
echo; echo "-- zaak 1: --lokaal naast de proefboom"
lokaal z1; code=$?
uitslag "$(waar [ "$code" -eq 0 ])" "1 --lokaal: afloop $code (moet 0)"
[ "$code" -eq 0 ] || grep -E 'ERROR|PermissionDenied|NotFound' "$P.z1.log" | head -3 | sed 's/^/        /'
n_site="$(find "$P/_site" -type f 2>&1 | wc -l | tr -d ' ')"
n_merk="$(grep -rl PROEF_SCHONE_BOUW "$P/_site" 2>&1 | wc -l | tr -d ' ')"
uitslag "$(waar [ "$n_site" -gt 100 ])" "1 _site/ gebouwd: $n_site bestanden (moet ruim boven 100)"
uitslag "$(waar [ "$n_merk" -eq 0 ])" "1 bestanden in _site/ uit de proefboom (merkteken PROEF_SCHONE_BOUW): $n_merk (moet 0)"
c=0; [ -e "$P/_site/.claude" ] && c=1; [ -e "$P/_site/oefenboeken/.claude" ] && c=$((c + 1))
uitslag "$(waar [ "$c" -eq 0 ])" "1 _site/.claude en _site/oefenboeken/.claude: $c van de 2 bestaan (moet 0)"
uitslag "$(waar [ ! -e "$BOVEN/index.html" ])" "1 naast de proef-.qmd geen gebouwde index.html"
chmod 755 "$BOVEN/gesloten" "$DIEP/gesloten"; NA="$(afdruk)"; chmod 000 "$BOVEN/gesloten" "$DIEP/gesloten"
uitslag "$(waar [ "$VOOR" = "$NA" ])" "1 de $n_boom bestanden van de proefboom onaangeroerd (sha256 $VOOR -> $NA)"
grep -q '^schone bouw: .*kopie zonder .claude/' "$P.z1.log"
uitslag "$?" "1 de bouw zegt zelf dat hij in een kopie zonder .claude/ draaide"

# ------------------------------------------------------------- zaak 2 ----
echo; echo "-- zaak 2: --uit moet een bouwmap zijn"
en_voor="$(cd "$P" && find en -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | cut -c1-16)"
(cd "$P" && python3 _tools/schone_bouw.py --uit en -- render) > "$P.z2.log" 2>&1; code=$?
en_na="$(cd "$P" && find en -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | cut -c1-16)"
weigert() { [ "$code" -eq 3 ] && grep -q 'geen bouwmap' "$P.z2.log"; }
uitslag "$(waar weigert)" "2 --uit en: afloop $code (moet 3), met de reden 'geen bouwmap'"
uitslag "$(waar [ "$en_voor" = "$en_na" ])" "2 en/ onaangeroerd ($en_voor -> $en_na)"

# ------------------------------------------------------------- zaak 3 ----
# Een quarto-aanroep die bouwt, buiten schone_bouw.py om. Shell: elke regel die
# geen commentaar en geen echo/printf is. Python: de echte aanroepen uit de
# syntaxboom (een docstring of zeg("$ quarto render") telt niet).
ter_plaatse() {  # $1 = repo; drukt de gevonden aanroepen af, afloop 1 als er een is
  python3 - "$1" <<'PY'
import ast, re, sys, os
wortel = sys.argv[1]
vond = []
for pad in ("_tools/naar_buiten.sh", "_tools/publiceer_en.sh"):
    for i, regel in enumerate(open(os.path.join(wortel, pad), encoding="utf-8"), 1):
        r = regel.strip()
        if not r or r.startswith("#") or re.match(r"(echo|printf)\b", r):
            continue
        if re.search(r'(^|[\s;&|(])quarto\s+(render|preview|"?\$)', r):
            vond.append(f"{pad}:{i}: {r}")
pad = "_tools/en_bouw.py"
boom = ast.parse(open(os.path.join(wortel, pad), encoding="utf-8").read())
for knoop in ast.walk(boom):
    if isinstance(knoop, ast.Call) and knoop.args and isinstance(knoop.args[0], (ast.List, ast.Tuple)):
        elt = knoop.args[0].elts
        if elt and isinstance(elt[0], ast.Constant) and elt[0].value == "quarto":
            vond.append(f"{pad}:{knoop.lineno}: {ast.unparse(knoop)[:100]}")
for v in vond:
    print("        " + v)
sys.exit(1 if vond else 0)
PY
}
echo; echo "-- zaak 3: geen bouw ter plaatse"
ter_plaatse "$P"; code=$?
uitslag "$code" "3 naar_buiten.sh, publiceer_en.sh en en_bouw.py: geen quarto-aanroep buiten schone_bouw.py"
for pad in _tools/naar_buiten.sh _tools/publiceer_en.sh _tools/en_bouw.py; do
  n="$(grep -c 'schone_bouw\.py' "$P/$pad")"
  uitslag "$(waar [ "$n" -ge 1 ])" "3 $pad noemt schone_bouw.py ($n keer)"
done

# ------------------------------------------------------------- zaak 4 ----
echo; echo "-- zaak 4: bijtproef"
muteer() {  # $1 bestand, $2 oud, $3 nieuw
  python3 - "$P/$1" "$2" "$3" <<'PY' || exit 2
import sys
p, oud, nieuw = sys.argv[1:]
s = open(p, encoding="utf-8").read()
if oud not in s:
    sys.exit(f"MUTATIE SLOEG NIET AAN: {oud!r} staat niet in {p}")
open(p, "w", encoding="utf-8").write(s.replace(oud, nieuw, 1))
PY
}
muteer _tools/naar_buiten.sh \
  'QUARTO_PROFILE=spook python3 _tools/schone_bouw.py --uit _site -- render' \
  'QUARTO_PROFILE=spook quarto render'
# Elke dichte map apart: dan bewijst elk van de twee dat hij een wandeling ziet,
# en niet alleen degene die Quarto toevallig eerst tegenkomt.
for plek in .claude/worktrees/_proef oefenboeken/.claude; do
  chmod 755 "$BOVEN/gesloten" "$DIEP/gesloten"; chmod 000 "$P/$plek/gesloten"
  lokaal z4; code=$?
  bijt() { [ "$code" -ne 0 ] && grep -q "PermissionDenied.*$plek/gesloten" "$P.z4.log"; }
  uitslag "$(waar bijt)" "4 --lokaal ter plaatse: afloop $code (moet niet 0), loopt vast op $plek/gesloten"
  grep -o "PermissionDenied[^']*'[^']*'" "$P.z4.log" | head -1 | sed "s|$P/||; s/^/        /"
done
chmod 000 "$BOVEN/gesloten" "$DIEP/gesloten"
ter_plaatse "$P" >/dev/null; code=$?
uitslag "$(waar [ "$code" -ne 0 ])" "4 zaak 3 ziet de teruggezette bouw ter plaatse in naar_buiten.sh (afloop $code, moet 1)"
"${GIT[@]}" -C "$P" checkout --quiet -- _tools/naar_buiten.sh
muteer _tools/en_bouw.py \
  'r = subprocess.run([sys.executable, os.path.join(REPO, "_tools", "schone_bouw.py"),' \
  'r = subprocess.run(["quarto", "render", "--profile", profiel], cwd=REPO, capture_output=True, text=True) or subprocess.run([sys.executable, os.path.join(REPO, "_tools", "schone_bouw.py"),'
ter_plaatse "$P" >/dev/null; code=$?
uitslag "$(waar [ "$code" -ne 0 ])" "4 zaak 3 ziet een kale quarto-aanroep in en_bouw.py (afloop $code, moet 1)"

echo
if [ "$FOUT" -eq 0 ]; then echo "$N van $N toetsen goed"; else echo "$((N - FOUT)) van $N toetsen goed — $FOUT FOUT"; fi
echo "logboeken: $P.z1.log, $P.z2.log, $P.z4.log"
[ "$FOUT" -eq 0 ] && [ "$N" -gt 0 ]
