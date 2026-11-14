"""Import a 4x4 character sheet drawn at any size (e.g. ChatGPT's 1254 px sheets) into the game's 256x256 format.

    python3 tools/import_big_sheet.py SRC TARGET_ID [--height 52] [--feet 60] [--tol 160] [--cell 64] [--smooth]

--cell 128 --height 104 --feet 120 builds a 2x (512x512, manifest "s": 4) sheet. --smooth downsamples with a box
filter (keeps the shading of painted/AI sheets) instead of nearest-neighbour.

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
    ap.add_argument("--tol", type=int, default=160, help="key distance; lower it for grey art on a purple key")
    ap.add_argument("--cell", type=int, default=64, help="output cell size; 128 = 2x sheet")
    ap.add_argument("--smooth", action="store_true", help="box-filter downsample instead of nearest")
    ap.add_argument("--row-feet", action="store_true", help="put every row's stand frame on the feet line, not just row 0's")
    ap.add_argument("--auto-grid", action="store_true", help="cut rows/columns at the emptiest gaps (figures that cross the even grid)")
    ap.add_argument("--fit-action", action="store_true", help="slide each column-4 (action) frame so the whole swing stays inside its cell")
    a = ap.parse_args()
    im = np.asarray(Image.open(a.src).convert("RGB")).astype(int)
    key = np.median(np.concatenate([im[:8, :8].reshape(-1, 3), im[-8:, -8:].reshape(-1, 3)]), 0)
    H, W = im.shape[:2]
    ch, cw = H / 4, W / 4
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    d = np.abs(im - key).sum(-1)
    magish = (r - g > 100) & (b - g > 100)
    alpha = np.where((d < a.tol) | magish, 0, 255).astype(np.uint8)
    spill = (r > g + 50) & (b > g + 50)
    rgb = im.copy()
    rgb[spill, 0] = (rgb[spill, 0] + rgb[spill, 1]) // 2
    rgb[spill, 2] = (rgb[spill, 2] + rgb[spill, 1]) // 2
    rgba = np.dstack([rgb.clip(0, 255).astype(np.uint8), alpha])

    ys_cut = [round(i * ch) for i in range(5)]
    xs_cut = [round(i * cw) for i in range(5)]
    if a.auto_grid:  # move each inner cut to the emptiest line within +-20% of a cell
        def cuts(prof, step):
            out = [0]
            for i in range(1, 4):
                lo, hi = int((i - 0.2) * step), int((i + 0.2) * step)
                out.append(lo + int(np.argmin(prof[lo:hi])))
            return out + [len(prof)]
        ys_cut = cuts((alpha > 0).sum(1), ch)
        xs_cut = cuts((alpha > 0).sum(0), cw)

    def cell(rw, cl):
        return rgba[ys_cut[rw]:ys_cut[rw + 1], xs_cut[cl]:xs_cut[cl + 1]]

    c0 = cell(0, 0)
    ys, xs = np.where(c0[..., 3] > 0)
    scale = a.height / (ys.max() - ys.min() + 1)
    feet_src = ys.max()                    # stand frame's feet line in source cell coords
    cx_src = (xs.min() + xs.max()) / 2
    C = a.cell
    out = Image.new("RGBA", (C * 4, C * 4), (0, 0, 0, 0))
    for rw in range(4):
        row_dy = 0.0
        if a.row_feet:   # this row's stand frame feet vs row 0's, in even-grid coords
            ry = np.where(cell(rw, 0)[..., 3] > 0)[0]
            row_dy = (ry.max() + ys_cut[rw] - rw * ch) - feet_src
        for cl in range(4):
            c = Image.fromarray(cell(rw, cl), "RGBA")
            sw, sh = max(1, round(c.width * scale)), max(1, round(c.height * scale))
            if a.smooth:   # premultiply so the key colour doesn't bleed into the edges
                pm = np.asarray(c).astype(np.float32)
                pm[..., :3] *= pm[..., 3:4] / 255.0
                rs = np.dstack([np.asarray(Image.fromarray(pm[..., i].astype(np.float32), "F").resize((sw, sh), Image.BOX)) for i in range(4)])
                al = np.maximum(rs[..., 3:4], 1e-3)
                rs[..., :3] = np.where(al > 1, rs[..., :3] * 255.0 / al, 0)
                s = rs.clip(0, 255).astype(np.uint8)
            else:
                s = np.asarray(c.resize((sw, sh), Image.NEAREST)).copy()
            s[..., 3] = np.where(s[..., 3] >= 128, 255, 0)
            dx, dy = xs_cut[cl] - cl * cw, ys_cut[rw] - rw * ch   # cut shift vs the even grid
            ox = round(cl * C + C // 2 - (cx_src - dx) * scale)
            if a.fit_action and cl == 3:
                fx = np.where(s[..., 3] > 0)[1]
                if len(fx):
                    lo, hi = ox + fx.min(), ox + fx.max()
                    if lo < cl * C + 1:
                        ox += cl * C + 1 - lo
                    elif hi > cl * C + C - 2:
                        ox -= hi - (cl * C + C - 2)
            oy = round(rw * C + a.feet - (feet_src + row_dy - dy) * scale)
            tile = Image.new("RGBA", (C * 4, C * 4), (0, 0, 0, 0))
            tile.paste(Image.fromarray(s, "RGBA"), (ox, oy))
            box = (cl * C, rw * C, cl * C + C, rw * C + C)
            out.paste(tile.crop(box), box[:2])  # clip to the cell
    out.save(ROOT / "assets" / "art" / f"{a.target}.png")
    print("scale %.3f -> %s" % (scale, a.target))


if __name__ == "__main__":
    main()
