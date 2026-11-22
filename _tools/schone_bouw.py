#!/usr/bin/env python3
"""schone_bouw.py — bouw de site in een kopie ZONDER .claude/, en zet alleen de
uitvoermap terug in de repo.

    python3 _tools/schone_bouw.py --uit _site -- render
    python3 _tools/schone_bouw.py --uit _site_spook -- render --profile spook --output-dir _site_spook
    python3 _tools/schone_bouw.py --uit _site_en -- render --profile en

Alles na `--` gaat ongewijzigd naar `quarto`; QUARTO_PROFILE en de rest van de
omgeving ook. Afloop: die van quarto, of 3 als deze schil zelf niet kon (geen
quarto op het pad, kopie mislukt, de bouw schreef niet naar --uit).

WAAROM (22-11-2026, spoor pers_nacht). `naar_buiten.sh --productie` liep die
nacht twee keer vast in de gedeelde checkout:
    NotFound ... stat '.../.claude/worktrees/taalpers/_site_en_werk/proef_werkruimte/...'
Quarto liep de werkkopie van een andere zetter af, terwijl diens toets daar een
wegwerpkloon neerzette en weghaalde. Gemeten op Quarto 1.9.38: een website-bouw
loopt ALTIJD de hele projectmap af, op de uitvoermap na, wat er ook in `render:`,
`resources:` of .gitignore staat. De plek is projectResourceFiles (in quarto.js
rond regel 78213): die plakt Quarto's eigen uitsluitingen ("!/.quarto/",
"!**/*.quarto_ipynb") achter de bijlage-globs, en een uitsluiting wordt niet
gesnoeid maar apart afgelopen en pas daarna afgetrokken (resolveGlobs, rond
regel 8090). Het enige wat de wandeling snoeit is de uitvoermap
(`exclude = [outputDir]`). Ook "!.claude/**" in _quarto-nl.yml houdt hem er dus
niet uit -- die regel stuurt hem er juist naartoe, op zoek naar wat hij moet
weglaten. Vijftien varianten in een mini-project, met een dichte map
(chmod 000) onder .claude/: alle vijftien liepen erin (PermissionDenied,
afloop 1), ook `render: [index.qmd]` zonder één bijlage.

Een instelling kan het dus niet. Wat wel kan: Quarto een projectmap geven waar
geen .claude/ in staat. Dit script kopieert de werkkopie naar een tijdelijke map
buiten de repo -- zonder .claude/ (op elke diepte), .git, .quarto en de
bouwmappen _site en _site_* -- draait daar quarto, en zet alleen de uitvoermap
terug. Bijkomend: Quarto komt zo niet meer aan de bronnen in de repo zelf. Dat
deed hij wel: hij bouwt een bladzij naast zijn .qmd en VERPLAATST hem dan
(en/*.html, zie bewaar/herstel in en_bouw.py).

WAT DIT NIET DEKT. Een kale `quarto render` of `quarto preview` met de hand in
de gedeelde checkout loopt nog steeds .claude/ af. Die gaat buiten de scripts
om. De GitHub Action bouwt in een verse kloon, en daar staat geen .claude/.
Getoetst door _tools/tests/schone_bouw_test.sh (met bijtproef).
"""
import argparse
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time

HIER = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HIER)

NOOIT = {".claude"}              # op elke diepte: daar wonen de werkkopieën van zetters
NIET_BOVENAAN = {".git", ".quarto"}


def zeg(tekst: str) -> None:
    # Naar stderr, zodat wie quarto's uitvoer leest of opvangt die ongemengd houdt.
    # Bewust zonder de woorden WARN en ERROR: en_bouw.py leest die als een fout van Quarto.
    print(f"schone bouw: {tekst}", file=sys.stderr, flush=True)


def is_bouwmap(naam: str) -> bool:
    return naam == "_site" or naam.startswith("_site_")


def overslaan(map_: str, namen: list[str]) -> set[str]:
    weg = {n for n in namen if n in NOOIT}
    if os.path.abspath(map_) == REPO:
        weg |= {n for n in namen if n in NIET_BOVENAAN or is_bouwmap(n)}
    return weg


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--uit", required=True,
                    help="de uitvoermap die terug moet in de repo: _site of _site_<iets>")
    ap.add_argument("quarto", nargs=argparse.REMAINDER, help="-- en dan de argumenten voor quarto")
    a = ap.parse_args()
    args = a.quarto[1:] if a.quarto[:1] == ["--"] else a.quarto
    if not args:
        zeg("geen quarto-argumenten (bv. -- render)")
        return 3
    # Deze schil gooit de oude uitvoermap in de repo weg. Alleen een bouwmap mag dat zijn,
    # en hij staat direct in de repo: een pad met / of .. erin weigert hij.
    if not is_bouwmap(a.uit) or os.sep in a.uit or "/" in a.uit:
        zeg(f"--uit {a.uit!r} is geen bouwmap in de wortel van de repo (_site of _site_<iets>)")
        return 3
    if shutil.which("quarto") is None:
        zeg("quarto staat niet op het pad -- kon niet bouwen")
        return 3

    tmp = tempfile.mkdtemp(prefix="countcamp_schone_bouw_")
    spiegel = os.path.join(tmp, os.path.basename(REPO))
    try:
        t0 = time.time()
        try:
            shutil.copytree(REPO, spiegel, symlinks=True, ignore=overslaan)
        except (OSError, shutil.Error) as e:
            zeg(f"de kopie naar {spiegel} mislukte ({e}) -- niet gebouwd")
            return 3
        n = sum(len(fs) for _d, _ds, fs in os.walk(spiegel))
        zeg(f"quarto {' '.join(args)}  in {spiegel}  "
            f"(kopie zonder .claude/, .git, .quarto, _site*: {n} bestanden, {time.time() - t0:.1f}s)")
        # Een signaal (Ctrl-C, afgeschoten, terminal dicht) gaat door naar quarto; dan
        # wachten tot die stopt, de uitvoermap NIET terugzetten, en de kopie opruimen.
        # Zonder dit ruimde een afgeschoten schil zijn kopie niet op en liep quarto
        # daarin door.
        ontvangen: list[int] = []
        proc = subprocess.Popen(["quarto", *args], cwd=spiegel)

        def doorgeven(signum, _frame):
            ontvangen.append(signum)
            if proc.poll() is None:
                proc.send_signal(signum)
        for s in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            signal.signal(s, doorgeven)
        code = proc.wait()
        if ontvangen:
            zeg(f"onderbroken door signaal {ontvangen[0]}; {a.uit}/ in de repo is NIET aangeraakt")
            return 128 + ontvangen[0]
        if code != 0:
            zeg(f"quarto eindigde met afloop {code}; {a.uit}/ in de repo is NIET aangeraakt")
            return code
        nieuw = os.path.join(spiegel, a.uit)
        if not os.path.isdir(nieuw):
            zeg(f"quarto gaf afloop 0 maar schreef geen {a.uit}/ -- klopt --uit met de uitvoermap van deze bouw?")
            return 3
        doel = os.path.join(REPO, a.uit)
        if os.path.lexists(doel):
            shutil.rmtree(doel)
        shutil.move(nieuw, doel)
        m = sum(len(fs) for _d, _ds, fs in os.walk(doel))
        zeg(f"{a.uit}/ terug in de repo ({m} bestanden)")
        return 0
    finally:
        try:
            shutil.rmtree(tmp)
        except OSError as e:
            zeg(f"let op: de tijdelijke kopie {tmp} kon niet weg ({e}); de bouw zelf staat los daarvan")


if __name__ == "__main__":
    sys.exit(main())
