#!/usr/bin/env python3
"""WCAG 2.x contrastverhouding — onafhankelijke narekening van de browsermeting.

Rekent met de exacte, ongeronde kanaalwaarden die de browsermeting teruggaf,
zodat het afronden op hex de uitkomst niet stilletjes verschuift.
"""


def lum(c):
    out = 0.0
    for waarde, gewicht in zip(c, (0.2126, 0.7152, 0.0722)):
        v = waarde / 255
        v = v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
        out += gewicht * v
    return out


def ratio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def uithex(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


metingen = [
    ("callout-KOP, exact",
     (55.55, 57.35, 58.40), (231.50, 240.95, 250.50)),
    ("callout-KOP, op hex afgerond",
     uithex("#38393a"), uithex("#e8f1fb")),
    ("callout-body, exact",
     (26.0, 26.0, 26.0), (223.0, 235.0, 242.0)),
    ("HYPOTHETISCH: de weggehaalde regel color:#fff op dezelfde kopbalk",
     (0.85 * 255 + 0.15 * 223, 0.85 * 255 + 0.15 * 235, 0.85 * 255 + 0.15 * 242),
     (231.50, 240.95, 250.50)),
]

for label, voor, achter in metingen:
    print(f"{ratio(voor, achter):7.2f} : 1   {label}")
