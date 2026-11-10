"""Import a 4x4 character sheet drawn at any size (e.g. ChatGPT's 1254 px sheets) into the game's 256x256 format.

    python3 tools/import_big_sheet.py SRC TARGET_ID [--height 52] [--feet 60]

Keys the corner colour, scales every cell by ONE factor so the row-0 stand frame is --height px tall (Duff's
stand frames are 52 px: y 9..60), keeps each figure's position in its cell relative to the stand frame's feet
and centre line, hard alpha, nearest-neighbour. Writes assets/art/<TARGET_ID>.png (manifest entry unchanged).
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("target")
    ap.add_argument("--height", type=int, default=52)
    ap.add_argument("--feet", type=int, default=60)
    a = ap.parse_args()
    im = np.asarray(Image.open(a.src).convert("RGB")).astype(int)
    key = np.median(np.concatenate([im[:8, :8].reshape(-1, 3), im[-8:, -8:].reshape(-1, 3)]), 0)
    H, W = im.shape[:2]
    ch, cw = H / 4, W / 4
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    d = np.abs(im - key).sum(-1)
    magish = (r - g > 100) & (b - g > 100)
    alpha = np.where((d < 160) | magish, 0, 255).astype(np.uint8)
    spill = (r > g + 50) & (b > g + 50)
    rgb = im.copy()
    rgb[spill, 0] = (rgb[spill, 0] + rgb[spill, 1]) // 2
    rgb[spill, 2] = (rgb[spill, 2] + rgb[spill, 1]) // 2
    rgba = np.dstack([rgb.clip(0, 255).astype(np.uint8), alpha])

    def cell(rw, cl):
        return rgba[round(rw * ch):round((rw + 1) * ch), round(cl * cw):round((cl + 1) * cw)]

    c0 = cell(0, 0)
    ys, xs = np.where(c0[..., 3] > 0)
    scale = a.height / (ys.max() - ys.min() + 1)
    feet_src = ys.max()                    # stand frame's feet line in source cell coords
    cx_src = (xs.min() + xs.max()) / 2
    out = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    for rw in range(4):
        for cl in range(4):
            c = Image.fromarray(cell(rw, cl), "RGBA")
            sw, sh = max(1, round(c.width * scale)), max(1, round(c.height * scale))
            s = np.asarray(c.resize((sw, sh), Image.NEAREST)).copy()
            s[..., 3] = np.where(s[..., 3] >= 128, 255, 0)
            ox = round(cl * 64 + 32 - cx_src * scale)
            oy = round(rw * 64 + a.feet - feet_src * scale)
            tile = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
            tile.paste(Image.fromarray(s, "RGBA"), (ox, oy))
            box = (cl * 64, rw * 64, cl * 64 + 64, rw * 64 + 64)
            out.paste(tile.crop(box), box[:2])  # clip to the cell
    out.save(ROOT / "assets" / "art" / f"{a.target}.png")
    print("scale %.3f -> %s" % (scale, a.target))


if __name__ == "__main__":
    main()
