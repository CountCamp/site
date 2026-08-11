#!/usr/bin/env python3
"""Schermafdruk van de plank, voor en na — om het chip-neveneffect te kunnen zien."""
import subprocess, pathlib
HIER = pathlib.Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for wat in ("voor", "na"):
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-first-run",
                    "--hide-scrollbars", "--window-size=900,1500",
                    "--virtual-time-budget=9000",
                    "--screenshot=%s" % (HIER / ("schot_%s.png" % wat)),
                    "file://%s" % (HIER / ("chip_%s.html" % wat))],
                   capture_output=True, timeout=180)
    print(wat, (HIER / ("schot_%s.png" % wat)).stat().st_size, "bytes")
