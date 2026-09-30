#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""controleer_tellers.py — draagt elke oefenboek-bladzij de bezoekersteller?

    python3 _tools/controleer_tellers.py              # kijken
    python3 _tools/controleer_tellers.py --repareer    # en er meteen in zetten

Waarom dit bestaat
------------------
Op 30-9-2026 gemeten: van de 169 HTML-bladzijden onder `oefenboeken/` en
`werkboeken/` droegen er 112 een teller. Het hele psychometrie-oefenboek (0 van
6), zestien van de achttien OZP1-thema's en acht van de negen MVDA-thema's waren
blind. Niemand wist dat, want er was niets dat het zou zeggen — de site rendert
en publiceert even vrolijk zonder teller als met.

De oorzaak zit niet in deze repo maar in de bouwweg van elk werkboek, en die is
per werkboek anders. Vandaar dat de uitvoer PER MAP telt en niet één totaal
geeft: één getal zou verbergen dat ggz_vs volledig in orde is terwijl
psychometrie volledig blind is.

Wat het niet doet
-----------------
Het kijkt naar de bestanden in deze repo, niet naar de live site. Wat hier staat
wordt door `quarto render` als *resource* overgenomen (zie `_quarto.yml`), dus
onveranderd — maar een bladzij die de site zélf rendert krijgt zijn teller pas
bij het bouwen, uit `_quarto-echt.yml`. Die staan niet onder deze twee mappen en
worden hier dus niet gemeten; `naar_buiten.sh --productie` bewaakt die.
"""
from __future__ import annotations
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tellerregel import tellerstand, soort, met_teller, REGEL  # noqa: E402

SITE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPPEN = ['oefenboeken', 'werkboeken']
# `_site/` is de bouw-uitvoer en `.quarto/` de cache: allebei buiten versie, en
# meetellen zou de telling laten verdubbelen met kopieën van zichzelf.
OVERSLAAN = {'_site', '.quarto', '.git', 'site_libs'}


def vak(pad: str) -> str:
    """Onder welke kop hoort deze bladzij in de uitvoer.

    `oefenboeken/ozp1/00_fundament/00_fundament.html` -> `oefenboeken/ozp1`
    `werkboeken/index.html`                           -> `werkboeken/(wortel)`
    """
    deel = pad.split(os.sep)
    if len(deel) > 2:
        return os.sep.join(deel[:2])
    return deel[0] + os.sep + '(wortel)'


def loop(wortel: str):
    """Geef elke .html onder `wortel`, als (relatief pad, inhoud)."""
    for dp, dn, fn in os.walk(os.path.join(SITE, wortel)):
        dn[:] = [d for d in dn if d not in OVERSLAAN]
        for f in sorted(fn):
            if not f.endswith('.html'):
                continue
            p = os.path.join(dp, f)
            yield os.path.relpath(p, SITE), p


def main() -> int:
    global SITE
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--repareer', action='store_true',
                    help='zet de teller erin waar hij mist (idempotent)')
    ap.add_argument('--map', action='append', dest='mappen', metavar='MAP',
                    help='alleen deze map nalopen (mag meermaals); '
                         'standaard: ' + ' en '.join(MAPPEN))
    # `--site` bestaat voor de toets: die zet een proefboom in /tmp neer en moet
    # de wachter daarop kunnen laten kijken. Zonder zo'n uitgang kun je een
    # wachter alleen op de echte site proeven, en dan is "rood" niet te maken
    # zonder de site te beschadigen -- een toets die nooit rood kan worden staat
    # ook groen.
    ap.add_argument('--site', default=SITE, metavar='PAD',
                    help='wortel om in te kijken (standaard: deze repo)')
    args = ap.parse_args()
    mappen = args.mappen or MAPPEN
    SITE = os.path.abspath(args.site)

    # per vak: [geteld, bladzijden, uitgesloten]
    telling: dict[str, list[int]] = {}
    mist: list[str] = []
    halve: list[str] = []
    uitgesloten: list[tuple[str, str]] = []
    hersteld: list[str] = []
    gezien = 0

    afwezig: list[str] = []
    for wortel in mappen:
        # Een map die er NIET IS, is iets anders dan een map waarin ik niets kon
        # zien. `werkboeken/` bestaat alleen uit doorstuurders van een oud pad en
        # mag best verdwijnen; daarop de levering tegenhouden is een valse
        # alarmbel, en een wachter die valse alarmbellen geeft leer je wegklikken.
        # De blindheidstoets staat verderop en kijkt of er ergens ÜBERHAUPT een
        # bladzij gevonden is -- dát is waar stilte ongeldig betekent.
        # Gemeten op 30-9-2026: hierop struikelde zaak 8 van plankwacht_test.sh,
        # die een proefrepo bouwt met wél oefenboeken/ en géén werkboeken/.
        if not os.path.isdir(os.path.join(SITE, wortel)):
            afwezig.append(wortel)
            continue
        for rel, vol in loop(wortel):
            gezien += 1
            t = open(vol, encoding='utf-8', errors='ignore').read()
            k = vak(rel)
            telling.setdefault(k, [0, 0, 0])
            s = soort(t)
            if s != 'bladzij':
                telling[k][2] += 1
                uitgesloten.append((rel, s))
                continue
            telling[k][1] += 1
            stand = tellerstand(t)
            if stand == 'geteld':
                telling[k][0] += 1
                continue
            if stand == 'half':
                halve.append(rel)
            if args.repareer:
                nieuw, wat = met_teller(t)
                if wat == 'toegevoegd':
                    open(vol, 'w', encoding='utf-8').write(nieuw)
                    hersteld.append(rel)
                    telling[k][0] += 1
                    continue
            mist.append(rel)

    print('teller-controle — %s' % ', '.join(mappen))
    print('wortel     : %s' % SITE)
    print('gereedschap: os.walk (volgt een gesymlinkt startpunt), '
          'toets op twee merken uit _tools/tellerregel.py')
    print('')
    print('  %-30s %8s %8s %12s' % ('map', 'geteld', 'bladzij', 'uitgesloten'))
    for k in sorted(telling):
        g, b, u = telling[k]
        vlag = '' if g == b else '   <-- MIST %d' % (b - g)
        print('  %-30s %8d %8d %12d%s' % (k, g, b, u, vlag))
    tg = sum(v[0] for v in telling.values())
    tb = sum(v[1] for v in telling.values())
    tu = sum(v[2] for v in telling.values())
    print('  %-30s %8d %8d %12d' % ('TOTAAL', tg, tb, tu))

    if afwezig:
        print('')
        print('niet gekeken, want de map bestaat hier niet: %s'
              % ', '.join(afwezig))

    if uitgesloten:
        print('')
        print('uitgesloten (%d) — geen bladzij, dus geen teller:' % len(uitgesloten))
        for rel, s in uitgesloten:
            print('    %-14s %s' % (s, rel))

    if hersteld:
        print('')
        print('teller ingevoegd in %d bladzij(den):' % len(hersteld))
        for rel in hersteld:
            print('    + %s' % rel)

    if halve:
        print('')
        print('HALVE TELLER (%d) — één merk aanwezig, het andere niet. Dit telt '
              'NIETS en ziet eruit als een teller; met de hand nakijken:' % len(halve))
        for rel in halve:
            print('    ? %s' % rel)

    # Stilte betekent ongeldig, nooit goed: een controle die nul bladzijden zag
    # heeft niets bewezen en mag niet groen staan.
    if gezien == 0:
        print('')
        print('NIETS GEMETEN — geen enkele .html gevonden onder %s. Dat is geen '
              'schone uitslag maar een blinde: klopt het pad?' % ', '.join(mappen))
        if afwezig:
            print('  (van die mappen bestaat hier geen enkele: %s)'
                  % ', '.join(afwezig))
        return 3

    if mist:
        print('')
        print('ZONDER TELLER (%d van de %d bladzijden):' % (len(mist), tb))
        for rel in sorted(mist):
            print('    - %s' % rel)
        print('')
        print('Niet publiceren. Herstellen: '
              'python3 _tools/controleer_tellers.py --repareer')
        return 1

    print('')
    print('Alle %d bladzijden dragen de teller.' % tb)
    return 0


if __name__ == '__main__':
    sys.exit(main())
