"""Import Grok's 13 storefronts (grok_art/2026-11-08-storefronts) into the town.

    python3 tools/import_storefronts.py

- keys each PNG by its corner colour (#00FF00 or #FF00FF), fades the fringe, removes spill
- writes assets/art/sf_<name>.png (same size = footprint rect x2, drawn at rect.position)
- registers sf_<name> in assets/art/manifest.json and scripts/art_manifest.gd (s 2, origin 0,0)
- clears the old painted buildings out of assets/art/map_objects.png (footprint rects + a margin,
  plus any blob that only existed because it touched a building)
"""
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "grok_art" / "2026-11-08-storefronts"
OUT = ROOT / "assets" / "art"

# storefront file -> building name in main.gd (or the const rect name)
MAP = {
    "home": "HOME", "neighbor": "NEIGHBOR", "kwik": "KWIK-N-GO", "fork": "THE TWISTED FORK",
    "hoa": "HOA HQ", "seen": "SEEN CAFE", "iron": "IRON TEMPLE", "club": "CLUB CLOUD 9",
    "mining": "MINING RIG", "plaza": "{FINAL_TOWER}", "walgrumps": "PHARM_R",
    "hywhee": "GROC_R", "plazmart": "PLASMA_R",
}


def rects():
    src = (ROOT / "scripts" / "main.gd").read_text()
    out = {}
    for m in re.finditer(r'"r": Rect2\(([^)]*)\)[^\n]*"n": "([^"]+)"', src):
        out[m.group(2)] = tuple(float(v) for v in m.group(1).split(","))
    for name in ("PHARM_R", "GROC_R", "PLASMA_R"):
        m = re.search(name + r": = Rect2\(([^)]*)\)", src)
        out[name] = tuple(float(v) for v in m.group(1).split(","))
    return out


def key(img):
    a = np.asarray(img.convert("RGB")).astype(float)
    bg = a[0, 0]
    d = np.sqrt(((a - bg) ** 2).sum(-1))
    alpha = np.clip((d - 60) / 80, 0, 1)            # hard key, short soft edge
    alpha[alpha < 0.5] = 0                          # pixel art: no half-transparent fringe
    alpha[alpha >= 0.5] = 1
    rgb = a.copy()
    if bg[1] > 200 and bg[0] < 80:                  # green screen: clamp green spill
        rgb[..., 1] = np.minimum(rgb[..., 1], np.maximum(rgb[..., 0], rgb[..., 2]) + 30)
    else:                                           # magenta: clamp red+blue spill
        lim = rgb[..., 1] + 40
        mask = (rgb[..., 0] > lim) & (rgb[..., 2] > lim)
        rgb[mask, 0] = np.minimum(rgb[mask, 0], lim[mask] + 40)
        rgb[mask, 2] = np.minimum(rgb[mask, 2], lim[mask] + 40)
    return np.dstack([rgb.astype(np.uint8), (alpha * 255).astype(np.uint8)])


def manifest_entry(w, h):
    return {"w": w, "h": h, "cell": [w, h], "origin": [0, 0], "s": 2}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rs = rects()
    mj_path = ROOT / "assets" / "art" / "manifest.json"
    mj = json.loads(mj_path.read_text())
    table = mj["assets"] if "assets" in mj else mj
    for f, bname in MAP.items():
        x, y, w, h = rs[bname]
        im = Image.open(SRC / f"new_storefront_{f}.png")
        assert im.size == (int(w * 2), int(h * 2)), (f, im.size, (w * 2, h * 2))
        rgba = key(im)
        # drop the building so its lowest opaque row sits on the footprint's bottom edge
        # (doors and story triggers live just below rect.end)
        rows = np.where(rgba[..., 3].any(1))[0]
        gap = rgba.shape[0] - 1 - rows.max()
        if gap > 0:
            rgba = np.vstack([np.zeros((gap,) + rgba.shape[1:], np.uint8), rgba[:-gap]])
        Image.fromarray(rgba, "RGBA").save(OUT / f"sf_{f}.png")
        e = manifest_entry(im.width, im.height)
        table[f"sf_{f}"] = e
        print(f"sf_{f}: {im.size} at {x},{y} opaque {int((rgba[..., 3] > 0).sum())}")
    mj_path.write_text(json.dumps(mj, indent=2) + "\n")
    gd = ROOT / "scripts" / "art_manifest.gd"
    src = re.sub(r'\n  "sf_[a-z]+": \{[^}]*\},', "", gd.read_text())
    add = "".join(f'\n  "sf_{f}": {json.dumps(table["sf_" + f])},' for f in MAP)
    gd.write_text(src.replace("const ASSETS = {", "const ASSETS = {" + add, 1))

    # clear old buildings from the objects overlay
    mo_path = ROOT / "assets" / "art" / "map_objects.png"
    mo = np.asarray(Image.open(mo_path).convert("RGBA")).copy()
    for x, y, w, h in rs.values():
        m = 10
        mo[max(0, int(y * 2) - m):int((y + h) * 2) + m, max(0, int(x * 2) - m):int((x + w) * 2) + m, 3] = 0
    Image.fromarray(mo, "RGBA").save(mo_path)
    print("cleared buildings from map_objects")


if __name__ == "__main__":
    main()
