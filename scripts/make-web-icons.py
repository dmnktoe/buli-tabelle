#!/usr/bin/env python3
"""Zeichnet die Icons der Downloadseite.

    pip install Pillow && python3 scripts/make-web-icons.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

DOCS = Path(__file__).resolve().parent.parent / "docs"

BASE = 512
SUPERSAMPLE = 4

ACCENT_TOP = (216, 27, 58)
ACCENT_MID = (200, 16, 46)
ACCENT_BOTTOM = (142, 11, 32)

ZONE_CHAMPIONS = (28, 107, 240)
ZONE_PLAYOFF = (199, 154, 22)
ZONE_RELEGATION = (208, 59, 44)
SEPARATOR = (232, 232, 236)
BAR_INK = (61, 61, 61)
HEAD_INK = (107, 107, 107)
CARD_EDGE = (255, 255, 255)

# Zone je Zeile – None heißt: kein Balken, wie im Mittelfeld der Tabelle.
ROW_ZONES = [ZONE_CHAMPIONS, None, None, ZONE_PLAYOFF, ZONE_RELEGATION]


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def draw_icon(size):
    s = size * SUPERSAMPLE
    k = s / BASE

    canvas = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    inset = round(26 * k)
    x0, y0, x1, y1 = inset, inset, s - inset, s - inset
    plate = (x0, y0, x1, y1)

    gradient = Image.new("RGB", (1, y1 - y0))
    for y in range(gradient.height):
        t = y / max(gradient.height - 1, 1)
        if t <= 0.52:
            color = lerp(ACCENT_TOP, ACCENT_MID, t / 0.52)
        else:
            color = lerp(ACCENT_MID, ACCENT_BOTTOM, (t - 0.52) / 0.48)
        gradient.putpixel((0, y), color)
    gradient = gradient.resize((x1 - x0, gradient.height))

    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle(plate, radius=112 * k, fill=255)
    canvas.paste(gradient, (x0, y0), mask.crop(plate))

    card = (104 * k, 116 * k, (104 + 304) * k, (116 + 280) * k)
    row_h = 46 * k
    head_h = (card[3] - card[1]) - 5 * row_h

    # Glaskarte: helle Fläche mit weicher Kante statt hartem Rahmen.
    draw.rounded_rectangle(card, radius=34 * k, fill=(255, 255, 255, 247))

    head = (card[0], card[1], card[2], card[1] + head_h)
    head_mid = (head[1] + head[3]) / 2
    for x, w in ((26, 40), (84, 90), (304 - 66, 40)):
        x0 = card[0] + x * k
        draw.rounded_rectangle(
            (x0, head_mid - 4 * k, x0 + w * k, head_mid + 4 * k),
            radius=4 * k,
            fill=HEAD_INK,
        )

    for index, zone in enumerate(ROW_ZONES):
        top = head[3] + index * row_h
        row = (card[0], top, card[2], top + row_h)
        mid = (row[1] + row[3]) / 2

        if index < len(ROW_ZONES) - 1:
            draw.rectangle(
                (row[0] + 20 * k, row[3] - 2 * k, row[2] - 20 * k, row[3]), fill=SEPARATOR
            )

        # Zonenbalken am Zeilenrand statt flächiger Einfärbung.
        if zone:
            draw.rounded_rectangle(
                (row[0] + 14 * k, mid - 13 * k, row[0] + 20 * k, mid + 13 * k),
                radius=3 * k,
                fill=zone,
            )

        draw.ellipse(
            (row[0] + 32 * k, mid - 7 * k, row[0] + 46 * k, mid + 7 * k), fill=BAR_INK
        )
        draw.rounded_rectangle(
            (row[0] + 60 * k, mid - 6 * k, row[0] + 178 * k, mid + 6 * k),
            radius=6 * k,
            fill=BAR_INK,
        )
        draw.rounded_rectangle(
            (row[2] - 62 * k, mid - 6 * k, row[2] - 22 * k, mid + 6 * k),
            radius=6 * k,
            fill=BAR_INK,
        )

    draw.rounded_rectangle(
        (card[0] + k, card[1] + k, card[2] - k, card[3] - k),
        radius=33 * k,
        outline=CARD_EDGE,
        width=round(2 * k),
    )

    return canvas.resize((size, size), Image.LANCZOS)


def main():
    icon = draw_icon(1024)
    icon.convert("RGB").save(DOCS / "icon.png")

    draw_icon(180).save(DOCS / "apple-touch-icon.png")
    draw_icon(32).save(DOCS / "favicon-32x32.png")
    draw_icon(16).save(DOCS / "favicon-16x16.png")
    draw_icon(64).save(DOCS / "favicon.ico", sizes=[(64, 64)])

    print("→ docs/icon.png, apple-touch-icon.png, favicon-*.png, favicon.ico")


if __name__ == "__main__":
    main()
