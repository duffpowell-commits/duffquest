"""Cut a Grok portrait strip (N expressions side by side on a flat background) into a clean,
transparent, equal-cell PNG sheet for the dialogue box.

    python3 tools/import_portrait.py grok_art/duff_portraits_v2.jpg duff --cell 512

- background colour is read from the image corners (works for magenta, purple, green...)
- JPG fringe: pixels close to the background become transparent; edge pixels get the background
  tint pulled out (despill)
- panels are found by empty background columns, trimmed, and centred into equal square cells
  sharing one scale (so every expression has the same head size)
Output: assets/art/portraits_hd/<name>.png  (N cells wide, 1 cell tall)
"""
import argparse
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "art" / "portraits_hd"


def run(src, name, cell, margin):
    im = Image.open(src).convert("RGB")
    W, H = im.size
    px = im.load()
    corners = [px[2, 2], px[W - 3, 2], px[2, H - 3], px[W - 3, H - 3]]
    bg = tuple(sorted(c[i] for c in corners)[1] for i in range(3))

    def dist(c):
        return sum(abs(a - b) for a, b in zip(c, bg))

    rgba = Image.new("RGBA", (W, H))
    op = rgba.load()
    for y in range(H):
        for x in range(W):
            c = px[x, y]
            d = dist(c)
            if d < 90:
                op[x, y] = (0, 0, 0, 0)
            elif d < 200:  # fringe: fade + pull the background tint out
                a = int(255 * (d - 90) / 110)
                k = 1 - (d - 90) / 110
                r, g, b = (int(max(0, min(255, (ci - bi * k) / max(0.2, 1 - k)))) for ci, bi in zip(c, bg))
                op[x, y] = (r, g, b, a)
            else:
                op[x, y] = c + (255,)

    alpha = rgba.getchannel("A")
    empty = [all(alpha.getpixel((x, y)) == 0 for y in range(0, H, 3)) for x in range(W)]
    panels, start = [], None
    for x in range(W + 1):
        filled = x < W and not empty[x]
        if filled and start is None:
            start = x
        elif not filled and start is not None:
            if x - start > 40:
                panels.append((start, x))
            start = None
    crops = []
    for x0, x1 in panels:
        c = rgba.crop((x0, 0, x1, H))
        crops.append(c.crop(c.getchannel("A").getbbox()))
    biggest = max(max(c.width, c.height) for c in crops)
    scale = (cell - 2 * margin) / biggest
    sheet = Image.new("RGBA", (cell * len(crops), cell), (0, 0, 0, 0))
    for i, c in enumerate(crops):
        c = c.resize((round(c.width * scale), round(c.height * scale)), Image.LANCZOS)
        # bottom-align (shoulders sit on the box edge), centre horizontally
        sheet.alpha_composite(c, (i * cell + (cell - c.width) // 2, cell - margin - c.height))
    OUT.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT / f"{name}.png")
    print(f"bg={bg} panels={panels} -> {OUT / (name + '.png')} ({sheet.width}x{sheet.height})")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("name")
    ap.add_argument("--cell", type=int, default=512)
    ap.add_argument("--margin", type=int, default=16)
    a = ap.parse_args()
    run(a.src, a.name, a.cell, a.margin)
