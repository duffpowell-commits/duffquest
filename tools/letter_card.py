"""Letter a boss name onto a text-free burst card master and write the 960x540 game card.
Canva garbles lettering, so the name is drawn here (exact spelling), matching the existing cards:
cream Baloo 2 ExtraBold with a thick near-black outline, two lines centred on the right half,
all of it in the upper two thirds.

    python3 tools/letter_card.py grok_art/2026-11-09-style-c/card_donald.png donald "Chip" "Leverage"
Output: assets/art/boss_intro/<id>.png (960x540 RGB)
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "assets" / "fonts" / "Baloo2-ExtraBold.ttf"
FILL, INK = (255, 243, 208), (20, 18, 26)


def letter(src, boss, lines, cx_frac=0.74, top_frac=0.16, bottom_frac=0.64):
    im = Image.open(src).convert("RGB").resize((1920, 1080), Image.LANCZOS)
    W, H = im.size
    d = ImageDraw.Draw(im)
    max_w = int(W * 0.44)
    band = int(H * (bottom_frac - top_frac))
    size = 260
    while True:
        f = ImageFont.truetype(str(FONT), size)
        boxes = [d.textbbox((0, 0), t, font=f, stroke_width=size // 11) for t in lines]
        widths = [b[2] - b[0] for b in boxes]
        line_h = int(size * 0.92)
        if max(widths) <= max_w and line_h * len(lines) <= band:
            break
        size -= 6
    stroke = size // 11
    total = line_h * len(lines)
    y = int(H * top_frac) + (band - total) // 2
    cx = int(W * cx_frac)
    for t, b in zip(lines, boxes):
        w = b[2] - b[0]
        # drop shadow, then outlined fill
        d.text((cx - w // 2 - b[0] + 8, y - b[1] + 10), t, font=f, fill=INK, stroke_width=stroke, stroke_fill=INK)
        d.text((cx - w // 2 - b[0], y - b[1]), t, font=f, fill=FILL, stroke_width=stroke, stroke_fill=INK)
        y += line_h
    out = ROOT / "assets" / "art" / "boss_intro" / f"{boss}.png"
    im.resize((960, 540), Image.LANCZOS).save(out, optimize=True)
    print("wrote", out.relative_to(ROOT), "font", size)


if __name__ == "__main__":
    letter(sys.argv[1], sys.argv[2], sys.argv[3:])
