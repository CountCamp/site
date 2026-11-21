#!/usr/bin/env bash
# Bouwt ozp1_spss_data.zip opnieuw uit ALLE .sav-bestanden in deze map.
#
# Waarom een script en geen handwerk: op 28-9-2026 bleek de zip nergens gebouwd
# te worden -- geen script, geen regel in _quarto.yml, niets. Hij was dus met de
# hand gemaakt op 2 juni en daarna nooit meer aangeraakt. Wie een .sav toevoegt
# of weghaalt zonder de zip bij te werken, laat studenten een download halen die
# niet klopt met het werkboek, en er gaat niets af.
#
# Draaien:  bash _common/data/maak_zip.sh
set -euo pipefail
HIER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP="$HIER/ozp1_spss_data.zip"

cd "$HIER"
rm -f "$ZIP"
# -X laat de Mac-extra's (resource forks, Finder-rommel) weg; -j platslaan zodat
# de student de bestanden los uitpakt en niet in een map.
zip -qXj "$ZIP" ./*.sav

python3 - "$ZIP" <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
namen = sorted(i.filename for i in z.infolist())
for n in namen:
    print("  ", n)
print(f"in de zip: {len(namen)} .sav-bestand(en)")
if len(namen) != len(set(namen)):
    raise SystemExit("dubbele naam in de zip")
PY

echo "op schijf:  $(ls -1 "$HIER"/*.sav | wc -l | tr -d ' ') .sav-bestand(en)"
