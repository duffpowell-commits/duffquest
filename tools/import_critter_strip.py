"""Import a Canva critter strip (N frames in one row, facing right, flat key colour) into a small 2-row sheet.

    python3 tools/import_critter_strip.py SRC TARGET_ID --cell 48 32 --feet 29 [--frames 4] [--pad 1] [--tol 160]

Keys the corner colour, cuts the strip into equal columns, scales every frame by ONE factor so the largest frame fits
the cell (minus --pad), keeps each frame's feet line at --feet and its centre on the cell centre, area-downscales
(premultiplied), hard alpha, then adds a 1 px dark outline so the critter reads on grass. Row 0 faces right, row 1 is
its mirror (faces left). Writes assets/art/<TARGET_ID>.png; the manifest entry (cell, origin, density) is unchanged.
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
    ap.add_argument("--cell", type=int, nargs=2, default=[48, 32])
    ap.add_argument("--feet", type=int, default=29)
    ap.add_argument("--frames", type=int, default=4)
    ap.add_argument("--pad", type=int, default=1)
    ap.add_argument("--tol", type=int, default=160)
    a = ap.parse_args()
    cw, chh = a.cell
    im = np.asarray(Image.open(a.src).convert("RGB")).astype(int)
    key = np.median(np.concatenate([im[:8, :8].reshape(-1, 3), im[-8:, -8:].reshape(-1, 3)]), 0)
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    d = np.abs(im - key).sum(-1)
    alpha = np.where((d < a.tol) | ((r - g > 100) & (b - g > 100)), 0, 255)
    spill = (r > g + 40) & (b > g + 40)  # magenta-tinted edge pixels: pull toward their own grey
    im = im.copy()
    im[spill, 0] = (im[spill, 0] + im[spill, 1]) // 2
    im[spill, 2] = (im[spill, 2] + im[spill, 1]) // 2
    rgba = np.dstack([im, alpha]).astype(np.uint8)
    W = im.shape[1]
    boxes = []
    for f in range(a.frames):
        x0, x1 = round(f * W / a.frames), round((f + 1) * W / a.frames)
        ys, xs = np.where(alpha[:, x0:x1] > 0)
        boxes.append((x0 + xs.min(), ys.min(), x0 + xs.max() + 1, ys.max() + 1))
    bw = max(x1 - x0 for x0, _, x1, _ in boxes)
    feet = max(y1 for _, _, _, y1 in boxes)
    hs = sorted(feet - y0 for _, y0, _, _ in boxes)
    # one scale for the body; a frame that would poke out the top (a raised tail) is shrunk on its own
    scale = min((cw - 2 * a.pad - 2) / bw, (a.feet - a.pad - 1) / hs[len(hs) // 2])
    row = Image.new("RGBA", (cw * a.frames, chh), (0, 0, 0, 0))
    for f, (x0, y0, x1, y1) in enumerate(boxes):
        fr = rgba[:, x0:x1].astype(float)
        fr = fr[y0:feet]
        al = fr[..., 3:] / 255.0
        pm = Image.fromarray(np.dstack([fr[..., :3] * al, fr[..., 3:]]).astype(np.uint8), "RGBA")
        k = min(scale, (a.feet - a.pad - 1) / (feet - y0))
        sw, sh = max(1, round((x1 - x0) * k)), max(1, round((feet - y0) * k))
        o = np.asarray(pm.resize((sw, sh), Image.BOX)).astype(float)
        A = o[..., 3:]
        rgb = np.where(A > 0, o[..., :3] * 255.0 / np.maximum(A, 1), 0)
        o = np.dstack([rgb.clip(0, 255), np.where(A >= 100, 255, 0)]).astype(np.uint8)
        cx = f * cw + cw // 2 - sw // 2
        row.alpha_composite(Image.fromarray(o, "RGBA"), (cx, a.feet - sh))
    arr = np.asarray(row).copy()
    op = arr[..., 3] > 0
    nb = np.zeros_like(op)
    nb[1:] |= op[:-1]; nb[:-1] |= op[1:]; nb[:, 1:] |= op[:, :-1]; nb[:, :-1] |= op[:, 1:]
    ring = nb & ~op
    for f in range(1, a.frames):  # never bleed an outline across a cell edge
        ring[:, f * cw - 1:f * cw + 1] &= False
    arr[ring] = (34, 26, 30, 255)
    row = Image.fromarray(arr, "RGBA")
    out = Image.new("RGBA", (cw * a.frames, chh * 2), (0, 0, 0, 0))
    out.paste(row, (0, 0))
    for f in range(a.frames):
        c = row.crop((f * cw, 0, (f + 1) * cw, chh)).transpose(Image.FLIP_LEFT_RIGHT)
        out.paste(c, (f * cw, chh))
    out.save(ROOT / "assets" / "art" / f"{a.target}.png")
    print("scale %.4f -> %s %s" % (scale, a.target, out.size))


if __name__ == "__main__":
    main()
