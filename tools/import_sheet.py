"""Import a Grok 4x4 character sheet (256x256, 64 px cells, flat green or magenta key) into the game.

    python3 tools/import_sheet.py SRC TARGET_ID [--drop 3]

- background colour is read from the corner pixel; near-key pixels become transparent (hard alpha)
- green/magenta spill on edge pixels is pulled back to neutral
- every cell is shifted down by --drop px so feet sit on the manifest origin (y=60);
  Grok's Nov 7 sheets stand on y=57
Writes assets/art/<TARGET_ID>.png (keeps the manifest entry as it is).
"""
import argparse
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent


def run(src, target, drop):
    im = Image.open(src).convert("RGB")
    assert im.size == (256, 256), im.size
    key = im.getpixel((0, 0))
    px = im.load()
    out = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    op = out.load()
    green = key[1] > key[0] and key[1] > key[2]
    for y in range(256):
        for x in range(256):
            r, g, b = px[x, y]
            if sum(abs(a - k) for a, k in zip((r, g, b), key)) < 120:
                continue
            if green and g > max(r, b):
                g = max(r, b)          # despill green
            if not green and r > g and b > g and abs(r - b) < 60 and min(r, b) - g > 60:
                r = b = g + 30         # despill magenta
            ty = y + drop
            if ty // 64 == y // 64:    # never push pixels into the next row's cell
                op[x, ty] = (r, g, b, 255)
    dst = ROOT / "assets" / "art" / f"{target}.png"
    out.save(dst)
    print("wrote", dst, "key", key)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("target")
    ap.add_argument("--drop", type=int, default=3)
    a = ap.parse_args()
    run(a.src, a.target, a.drop)
