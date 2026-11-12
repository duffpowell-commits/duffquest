"""Prepare a Canva 4x4 character sheet for tools/import_big_sheet.py.

    python3 tools/prep_canva_sheet.py SRC OUT [--mirror-left] [--band 6]

Canva draws thin dark grid lines between cells; they survive the colour key and land in the sprite. This paints a
band around every cell edge with the corner (background) colour. --mirror-left replaces row 4 (facing left) with a
left-right mirror of row 3 (facing right), because Canva often draws row 4 facing the wrong way.
"""
import argparse

import numpy as np
from PIL import Image, ImageOps


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--mirror-left", action="store_true")
    ap.add_argument("--band", type=int, default=6)
    a = ap.parse_args()
    im = Image.open(a.src).convert("RGB")
    arr = np.asarray(im).copy()
    key = np.median(arr[:8, :8].reshape(-1, 3), 0).astype(np.uint8)
    H, W = arr.shape[:2]
    b = a.band
    for i in range(5):
        y, x = round(i * H / 4), round(i * W / 4)
        arr[max(0, y - b):y + b, :] = key
        arr[:, max(0, x - b):x + b] = key
    im = Image.fromarray(arr)
    if a.mirror_left:
        ch, cw = H / 4, W / 4
        for c in range(4):
            src = im.crop((round(c * cw), round(2 * ch), round((c + 1) * cw), round(3 * ch)))
            im.paste(ImageOps.mirror(src), (round(c * cw), round(3 * ch)))
    im.save(a.out)


if __name__ == "__main__":
    main()
