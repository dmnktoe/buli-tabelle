#!/usr/bin/env python3
"""Zeichnet die Icons der Downloadseite.

    pip install Pillow && python3 scripts/make-web-icons.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

DOCS = Path(__file__).resolve().parent.parent / "docs"

BASE = 512
SUPERSAMPLE = 4

LUNA_TOP = (74, 140, 247)
LUNA_MID = (30, 86, 200)
LUNA_BOTTOM = (22, 65, 158)

ZONE_CL = (159, 232, 159)
ZONE_RELEGATION = (255, 200, 214)
ZONE_ABSTIEG = (255, 158, 158)
SEPARATOR = (228, 226, 216)
BAR_INK = (46, 46, 46)
CARD_BORDER = (113, 111, 100)

ROW_FILLS = [ZONE_CL, (255, 255, 255), (255, 255, 255), ZONE_RELEGATION, ZONE_ABSTIEG]


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
            color = lerp(LUNA_TOP, LUNA_MID, t / 0.52)
        else:
            color = lerp(LUNA_MID, LUNA_BOTTOM, (t - 0.52) / 0.48)
        gradient.putpixel((0, y), color)
    gradient = gradient.resize((x1 - x0, gradient.height))

    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle(plate, radius=90 * k, fill=255)
    canvas.paste(gradient, (x0, y0), mask.crop(plate))

    card = (104 * k, 116 * k, (104 + 304) * k, (116 + 280) * k)
    row_h = 46 * k
    head_h = (card[3] - card[1]) - 5 * row_h

    draw.rectangle(card, fill=(255, 255, 255))
    head = (card[0], card[1], card[2], card[1] + head_h)
    draw.rectangle(head, fill=(0, 0, 0))

    head_mid = (head[1] + head[3]) / 2
    for x, w in ((22, 46), (82, 96), (304 - 66, 44)):
        x0 = card[0] + x * k
        draw.rounded_rectangle(
            (x0, head_mid - 5 * k, x0 + w * k, head_mid + 5 * k),
            radius=5 * k,
            fill=(255, 255, 255, 217),
        )

    for index, fill in enumerate(ROW_FILLS):
        top = head[3] + index * row_h
        row = (card[0], top, card[2], top + row_h)
        draw.rectangle(row, fill=fill)
        draw.rectangle((row[0], row[3] - 2 * k, row[2], row[3]), fill=SEPARATOR)

        mid = (row[1] + row[3]) / 2
        draw.ellipse(
            (row[0] + 22 * k, mid - 7 * k, row[0] + 36 * k, mid + 7 * k), fill=BAR_INK
        )
        draw.rounded_rectangle(
            (row[0] + 56 * k, mid - 6 * k, row[0] + 178 * k, mid + 6 * k),
            radius=6 * k,
            fill=BAR_INK,
        )
        draw.rounded_rectangle(
            (row[2] - 62 * k, mid - 6 * k, row[2] - 22 * k, mid + 6 * k),
            radius=6 * k,
            fill=BAR_INK,
        )

    draw.rectangle(
        (card[0] + k, card[1] + k, card[2] - k, card[3] - k),
        outline=CARD_BORDER,
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
