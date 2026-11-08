"""Import Grok's street dressing (trees, clutter, fences) into the game.

    python3 tools/import_dressing.py

Source: grok_art/2026-11-08-street-dressing/ (Cursor PR #7; cell names in street_dressing_tilemap.json).
- trees (128 px cells) and clutter (64 px cells): keyed, trimmed to the opaque box, kept at native size
  (2 px per world unit, same as the storefronts). Origin = bottom centre = the ground contact point.
- fences (256 px cells): scaled by FENCE_SCALE so a picket stands a bit taller than Duff. Grok's join
  rule (208 px stride, baseline 232) becomes FENCE_STRIDE px; origin = (left edge of cell, baseline).
Writes assets/art/sd_<name>.png and registers sd_* in assets/art/manifest.json + scripts/art_manifest.gd.
Placement lives in data/town_dressing.json (scripts/dressing.gd draws it).
Also strips the old trees/bushes/bench out of assets/art/map_objects.png (keeps the bus-stop sign).
"""
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "grok_art" / "2026-11-08-street-dressing"
OUT = ROOT / "assets" / "art"
FENCE_SCALE = 0.375          # 256 -> 96 px cell, 208 -> 78 px stride (39 world units)
FENCE_STRIDE = 78
FENCE_FAMILIES = ["chain_link", "white_picket", "privacy_wood", "red_brick"]
FENCE_PARTS = ["straight", "gate", "end", "corner"]


def key(rgb, keyc):
    a = rgb.astype(int)
    d = np.abs(a - np.array(keyc)).sum(-1)
    alpha = (d >= 120).astype(np.uint8) * 255
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    if keyc[1] > keyc[0]:  # green key: despill
        g = np.where(g > np.maximum(r, b), np.maximum(r, b), g)
    else:                  # magenta key: despill
        mag = (r > g) & (b > g) & (np.abs(r - b) < 60) & (np.minimum(r, b) - g > 60)
        r = np.where(mag, g + 30, r)
        b = np.where(mag, g + 30, b)
    return np.dstack([r, g, b, alpha]).clip(0, 255).astype(np.uint8)


def trim(rgba):
    ys, xs = np.where(rgba[..., 3] > 0)
    return rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def entry(w, h, ox, oy):
    return {"w": w, "h": h, "cell": [w, h], "origin": [ox, oy], "s": 2}


def main():
    meta = json.loads((SRC / "street_dressing_tilemap.json").read_text())
    table = {}
    for sheet, keyc in (("new_tree_sheet", (0, 255, 0)), ("new_clutter_sheet", (255, 0, 255))):
        im = np.asarray(Image.open(SRC / f"{sheet}.png").convert("RGB"))
        for c in meta[sheet]["cells"]:
            if c["name"] == "unused":
                continue
            x, y, w, h = c["rect"]
            rgba = trim(key(im[y:y + h, x:x + w], keyc))
            name = "sd_" + c["name"]
            Image.fromarray(rgba, "RGBA").save(OUT / f"{name}.png")
            table[name] = entry(rgba.shape[1], rgba.shape[0], rgba.shape[1] // 2, rgba.shape[0])
    im = np.asarray(Image.open(SRC / "new_fences_walls.png").convert("RGB"))
    cell = round(256 * FENCE_SCALE)
    base = round(232 * FENCE_SCALE)
    for r, fam in enumerate(FENCE_FAMILIES):
        for c, part in enumerate(FENCE_PARTS):
            rgba = key(im[r * 256:(r + 1) * 256, c * 256:(c + 1) * 256], (255, 0, 255))
            small = Image.fromarray(rgba, "RGBA").resize((cell, cell), Image.LANCZOS)
            arr = np.asarray(small).copy()
            arr[..., 3] = np.where(arr[..., 3] >= 128, 255, 0)   # hard alpha, no halo
            name = f"sd_{fam}_{part}"
            Image.fromarray(arr, "RGBA").save(OUT / f"{name}.png")
            table[name] = entry(cell, cell, round(16 * FENCE_SCALE), base)
    mj_path = OUT / "manifest.json"
    mj = json.loads(mj_path.read_text())
    t = mj["assets"] if "assets" in mj else mj
    for k in [k for k in t if k.startswith("sd_")]:
        del t[k]
    t.update(table)
    mj_path.write_text(json.dumps(mj, indent=2) + "\n")
    gd = ROOT / "scripts" / "art_manifest.gd"
    src = re.sub(r'\n  "sd_[a-z_]+": \{[^}]*\},', "", gd.read_text())
    add = "".join(f'\n  "{k}": {json.dumps(v)},' for k, v in sorted(table.items()))
    gd.write_text(src.replace("const ASSETS = {", "const ASSETS = {" + add, 1))
    print("sprites:", len(table))

    # old map_objects: keep only the bus-stop sign (px 291,381 .. 317,419)
    mo_path = OUT / "map_objects.png"
    mo = np.asarray(Image.open(mo_path).convert("RGBA")).copy()
    keep = mo[376:424, 286:322].copy()
    mo[..., 3] = 0
    mo[376:424, 286:322] = keep
    Image.fromarray(mo, "RGBA").save(mo_path)
    print("map_objects: only the bus-stop sign left")


if __name__ == "__main__":
    main()
