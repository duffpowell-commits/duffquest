"""Swap the six street-dressing trees for ChatGPT's R2 sheet (rematch vs Grok, Nov 8).

    python3 tools/import_chatgpt_trees.py

Source: grok_art/2026-11-08-chatgpt-test/r2_chatgpt.png (3x3 grid, first 6 cells, magenta key).
Each tree is keyed, trimmed and scaled (nearest) to the HEIGHT of the Grok sprite it replaces
(hedge: to its WIDTH, it's a wall piece), so placements in data/town_dressing.json keep working.
Origin = bottom centre. Updates sd_* entries in assets/art/manifest.json + scripts/art_manifest.gd.
"""
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "grok_art" / "2026-11-08-chatgpt-test" / "r2_chatgpt.png"
OUT = ROOT / "assets" / "art"
NAMES = ["maple", "oak", "scraggly_ash", "pine", "lilac", "hedge"]
SKIP = {"hedge"}  # ChatGPT drew a boxy hedge (1.27:1); Grok's long 112x47 wall piece stays


def main():
    im = np.asarray(Image.open(SRC).convert("RGB")).astype(int)
    c = im.shape[1] / 3
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    alpha = np.where((r - g > 90) & (b - g > 90), 0, 255).astype(np.uint8)
    rgba = np.dstack([im.clip(0, 255).astype(np.uint8), alpha])
    mj_path = OUT / "manifest.json"
    mj = json.loads(mj_path.read_text())
    t = mj["assets"] if "assets" in mj else mj
    gd_path = ROOT / "scripts" / "art_manifest.gd"
    gd = gd_path.read_text()
    for i, n in enumerate(NAMES):
        if n in SKIP:
            continue
        rw, cl = divmod(i, 3)
        cell = rgba[round(rw * c):round((rw + 1) * c), round(cl * c):round((cl + 1) * c)]
        ys, xs = np.where(cell[..., 3] > 0)
        cell = cell[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        key = "sd_" + n
        old = t[key]
        if n == "hedge":
            w = old["w"]; h = round(cell.shape[0] * w / cell.shape[1])
        else:
            h = old["h"]; w = round(cell.shape[1] * h / cell.shape[0])
        small = np.asarray(Image.fromarray(cell, "RGBA").resize((w, h), Image.NEAREST)).copy()
        small[..., 3] = np.where(small[..., 3] >= 128, 255, 0)
        Image.fromarray(small, "RGBA").save(OUT / f"{key}.png")
        e = {"w": w, "h": h, "cell": [w, h], "origin": [w // 2, h], "s": 2}
        t[key] = e
        gd = re.sub(r'"%s": \{[^}]*\}' % key, '"%s": %s' % (key, json.dumps(e)), gd)
        print(key, w, h)
    mj_path.write_text(json.dumps(mj, indent=2) + "\n")
    gd_path.write_text(gd)


if __name__ == "__main__":
    main()
