"""Swap street-dressing props for a sheet drawn by an AI app (rematch R3, Nov 8: Canva).

    python3 tools/import_prop_sheet.py SRC [--cols 4] [--only a,b,...] [--out DIR]

SRC: grid sheet on a magenta key, objects in the order of NAMES (row by row). Each object is keyed,
trimmed and scaled to the HEIGHT of the sprite it replaces (scattered_leaves: to its WIDTH, it's a ground
decal), so placements in data/town_dressing.json keep working. BOX downscale (these sprites are 13-42 px,
nearest-neighbour from 300 px turns them to noise), hard alpha, origin = bottom centre.
--out writes PNGs to another folder for comparison and leaves the game files alone.
"""
import argparse
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art"
NAMES = ["recycling_bin", "fire_hydrant", "newspaper_box", "bus_bench", "political_sun_sign",
         "football_fan_flag", "pothole_cone", "little_free_library", "mailbox", "bike_rack",
         "shopping_cart", "scattered_leaves"]
BY_WIDTH = {"scattered_leaves"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--only", default="")
    ap.add_argument("--out", default="")
    a = ap.parse_args()
    only = set(filter(None, a.only.split(",")))
    im = np.asarray(Image.open(a.src).convert("RGB")).astype(int)
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    key = (r - g > 90) & (b - g > 90)
    alpha = np.where(key, 0, 255).astype(np.uint8)
    # de-spill: magenta-tinted fringe pixels (r,b both well above g) pulled toward grey-green
    spill = ~key & (r > g + 40) & (b > g + 40)
    rgb = im.copy()
    rgb[spill, 0] = (rgb[spill, 0] + rgb[spill, 1]) // 2
    rgb[spill, 2] = (rgb[spill, 2] + rgb[spill, 1]) // 2
    rgba = np.dstack([rgb.clip(0, 255).astype(np.uint8), alpha])
    # find the objects as blobs instead of trusting the grid: AI apps don't keep cell lines
    lab, n = ndimage.label(ndimage.binary_closing(alpha > 0, iterations=6))
    sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    keep = [i + 1 for i in np.argsort(sizes)[::-1][:len(NAMES)]]
    objs = ndimage.find_objects(lab)
    boxes = {k: objs[k - 1] for k in keep}
    cy = {k: (boxes[k][0].start + boxes[k][0].stop) / 2 for k in keep}
    rows, cur = [], []
    for k in sorted(keep, key=lambda k: cy[k]):
        if cur and cy[k] - cy[cur[-1]] > im.shape[0] / 10:
            rows.append(cur); cur = []
        cur.append(k)
    rows.append(cur)
    order = [k for rw in rows for k in sorted(rw, key=lambda k: boxes[k][1].start)]
    mj_path = OUT / "manifest.json"
    mj = json.loads(mj_path.read_text())
    t = mj["assets"] if "assets" in mj else mj
    gd_path = ROOT / "scripts" / "art_manifest.gd"
    gd = gd_path.read_text()
    dest = Path(a.out) if a.out else OUT
    dest.mkdir(parents=True, exist_ok=True)
    for i, n in enumerate(NAMES):
        if only and n not in only:
            continue
        k = order[i]
        sl = boxes[k]
        cell = rgba[sl].copy()
        cell[..., 3] = np.where(lab[sl] == k, cell[..., 3], 0)
        key = "sd_" + n
        old = t[key]
        if n in BY_WIDTH:
            w = old["w"]; h = max(1, round(cell.shape[0] * w / cell.shape[1]))
        else:
            h = old["h"]; w = max(1, round(cell.shape[1] * h / cell.shape[0]))
        # premultiply so the magenta key doesn't bleed into edge colours when averaging
        pre = cell.astype(float)
        pre[..., :3] *= pre[..., 3:4] / 255
        p = Image.fromarray(pre.clip(0, 255).astype(np.uint8), "RGBA").resize((w, h), Image.BOX)
        small = np.asarray(p).astype(float)
        aa = small[..., 3:4]
        small[..., :3] = np.where(aa > 0, small[..., :3] * 255 / np.maximum(aa, 1), 0)
        small[..., 3] = np.where(small[..., 3] >= 110, 255, 0)
        Image.fromarray(small.clip(0, 255).astype(np.uint8), "RGBA").save(dest / f"{key}.png")
        if not a.out:
            e = {"w": w, "h": h, "cell": [w, h], "origin": [w // 2, h], "s": 2}
            t[key] = e
            gd = re.sub(r'"%s": \{[^}]*\}' % key, '"%s": %s' % (key, json.dumps(e)), gd)
        print(key, w, h)
    if not a.out:
        mj_path.write_text(json.dumps(mj, indent=2) + "\n")
        gd_path.write_text(gd)


if __name__ == "__main__":
    main()
