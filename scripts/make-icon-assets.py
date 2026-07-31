#!/usr/bin/env python3
"""Erzeugt alle Bild-Assets aus buli-tabelle.icon/ (Icon Composer).

Einmalig auszuführen, wenn sich das Icon ändert – die Ergebnisse liegen im Repo,
damit weder Build noch CI eine Python-Toolchain brauchen:

    pip install Pillow cairosvg
    python3 scripts/make-icon-assets.py

Erzeugt:
  Resources/AppIconSource.png   Quelle für scripts/make-icon.sh -> AppIcon.icns
  Resources/MenuBarBall.pdf     Template-Image für Menüleiste und Titelleisten
  docs/icon.png                 Downloadseite
  docs/apple-touch-icon.png, docs/favicon-{16x16,32x32}.png, docs/favicon.ico
"""

import io
import json
import pathlib
import re
import xml.etree.ElementTree as ET

import cairosvg
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
ICON_BUNDLE = ROOT / "buli-tabelle.icon"
BALL_SVG = ICON_BUNDLE / "Assets" / "Soccerball.svg"

# Hintergrundverlauf aus icon.json (erster Stopp oben). Der sRGB-Stopp ist exakt
# das Bundesliga-Rot #C12A24; der zweite ist der nach sRGB konvertierte P3-Wert.
GRADIENT_TOP = (0xC1, 0x2A, 0x24)
GRADIENT_BOTTOM = (0xDB, 0x35, 0x2E)

SS = 4  # Supersampling für weiche Kanten


def gradient_stops():
    """Liest die Verlaufsfarben aus icon.json, fällt auf die Konstanten zurück."""
    try:
        spec = json.loads((ICON_BUNDLE / "icon.json").read_text())
        colors = spec["fill"]["linear-gradient"]
    except Exception:
        return GRADIENT_TOP, GRADIENT_BOTTOM
    top = parse_color(colors[0]) or GRADIENT_TOP
    bottom = parse_color(colors[1]) or GRADIENT_BOTTOM
    return top, bottom


def parse_color(value):
    """`srgb:r,g,b,a` bzw. `display-p3:r,g,b,a` -> 8-Bit-sRGB-Tupel."""
    match = re.match(r"(srgb|display-p3):([\d.,]+)", value)
    if not match:
        return None
    space = match.group(1)
    parts = [float(x) for x in match.group(2).split(",")]
    r, g, b = parts[:3]
    if space == "display-p3":
        r, g, b = p3_to_srgb(r, g, b)
    return tuple(round(max(0.0, min(1.0, c)) * 255) for c in (r, g, b))


def p3_to_srgb(r, g, b):
    def to_linear(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    def to_gamma(c):
        c = max(0.0, min(1.0, c))
        return c * 12.92 if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

    rl, gl, bl = to_linear(r), to_linear(g), to_linear(b)
    return (
        to_gamma(1.2249 * rl - 0.2247 * gl),
        to_gamma(-0.0420 * rl + 1.0419 * gl),
        to_gamma(-0.0197 * rl - 0.0786 * gl + 1.0979 * bl),
    )


def squircle_mask(size, radius_ratio=0.2246, exponent=5.0):
    """Apple-artige Superellipse als Alpha-Maske."""
    big = size * SS
    mask = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(mask)
    half = big / 2
    # Superellipse |x/a|^n + |y/a|^n = 1, abgetastet als Polygon.
    points = []
    steps = 720
    for i in range(steps):
        t = 2 * 3.141592653589793 * i / steps
        ct, st = __import__("math").cos(t), __import__("math").sin(t)
        x = half * (abs(ct) ** (2 / exponent)) * (1 if ct >= 0 else -1)
        y = half * (abs(st) ** (2 / exponent)) * (1 if st >= 0 else -1)
        points.append((half + x, half + y))
    draw.polygon(points, fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def vertical_gradient(size, top, bottom):
    grad = Image.new("RGB", (1, size))
    for y in range(size):
        t = y / max(size - 1, 1)
        grad.putpixel(
            (0, y),
            tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)),
        )
    return grad.resize((size, size), Image.BICUBIC)


def render_ball(px, template=False):
    """Rendert Soccerball.svg. `template`: ohne weiße Fläche, nur Linien/Flächen."""
    svg = BALL_SVG.read_text()
    if template:
        # Weiße Ballfläche entfernen und die Konturen kräftig genug für kleine
        # Größen machen – die feinen Nahtlinien fallen weg, sie verschmieren dort.
        svg = svg.replace('<circle fill="#fff" r="2376"/>', '<circle fill="none" r="2376"/>')
        svg = re.sub(r'<path fill="none" d="[^"]*"/>', "", svg)
        svg = svg.replace('stroke-width="24"', 'stroke-width="150"')
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=px, output_height=px)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def app_icon(size=1024, ball_ratio=0.58, plate_ratio=0.805):
    top, bottom = gradient_stops()
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    plate = round(size * plate_ratio)
    mask = squircle_mask(plate)
    body = vertical_gradient(plate, top, bottom).convert("RGBA")

    # Glasiger Lichtschein oben (translucency/glass aus icon.json, angenähert).
    sheen = Image.new("L", (1, plate))
    for y in range(plate):
        t = y / max(plate - 1, 1)
        sheen.putpixel((0, y), round(46 * max(0.0, 1 - t * 2.6)))
    body = Image.alpha_composite(
        body,
        Image.merge(
            "RGBA",
            (
                Image.new("L", (plate, plate), 255),
                Image.new("L", (plate, plate), 255),
                Image.new("L", (plate, plate), 255),
                sheen.resize((plate, plate), Image.BICUBIC),
            ),
        ),
    )
    body.putalpha(mask)

    offset = (size - plate) // 2
    # Weicher Schlagschatten unter der Platte.
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 110), (offset, offset + round(size * 0.012)), mask)
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(size * 0.016)))
    canvas.alpha_composite(body, (offset, offset))

    ball_px = round(size * ball_ratio)
    ball = render_ball(ball_px)
    bx = (size - ball_px) // 2

    ball_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ball_shadow.paste((0, 0, 0, 130), (bx, bx + round(size * 0.018)), ball.split()[3])
    canvas = Image.alpha_composite(canvas, ball_shadow.filter(ImageFilter.GaussianBlur(size * 0.014)))
    canvas.alpha_composite(ball, (bx, bx))
    return canvas


def web_icon(size, ball_ratio=0.62):
    """Für Web/Favicon: Platte füllt die Fläche, Ball etwas größer."""
    top, bottom = gradient_stops()
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = squircle_mask(size)
    body = vertical_gradient(size, top, bottom).convert("RGBA")
    body.putalpha(mask)
    canvas.alpha_composite(body)

    ball_px = round(size * ball_ratio)
    ball = render_ball(max(ball_px, 64)).resize((ball_px, ball_px), Image.LANCZOS)
    canvas.alpha_composite(ball, ((size - ball_px) // 2, (size - ball_px) // 2))
    return canvas


def menu_bar_pdf(path, pt=18):
    """Vektor-Template fürs Menüleisten-Symbol – macOS färbt es hell/dunkel."""
    svg = BALL_SVG.read_text()
    svg = svg.replace('<circle fill="#fff" r="2376"/>', '<circle fill="none" r="2376"/>')
    svg = re.sub(r'<path fill="none" d="[^"]*"/>', "", svg)
    svg = svg.replace('stroke-width="24"', 'stroke-width="150"')
    svg = svg.replace('width="500" height="500"', f'width="{pt}" height="{pt}"')
    cairosvg.svg2pdf(bytestring=svg.encode(), write_to=str(path))


def main():
    ET.fromstring(BALL_SVG.read_text())  # frühe Fehlermeldung bei kaputtem SVG

    (ROOT / "Resources").mkdir(exist_ok=True)
    app = app_icon()
    app.save(ROOT / "Resources" / "AppIconSource.png")
    print("→ Resources/AppIconSource.png")

    menu_bar_pdf(ROOT / "Resources" / "MenuBarBall.pdf")
    print("→ Resources/MenuBarBall.pdf")

    docs = ROOT / "docs"
    web_icon(512).save(docs / "icon.png")
    print("→ docs/icon.png")
    web_icon(180).save(docs / "apple-touch-icon.png")
    print("→ docs/apple-touch-icon.png")

    for px in (16, 32):
        web_icon(256, ball_ratio=0.7).resize((px, px), Image.LANCZOS).save(
            docs / f"favicon-{px}x{px}.png"
        )
        print(f"→ docs/favicon-{px}x{px}.png")

    base = web_icon(256, ball_ratio=0.7)
    base.save(docs / "favicon.ico", sizes=[(16, 16), (32, 32), (48, 48)])
    print("→ docs/favicon.ico")


if __name__ == "__main__":
    main()
