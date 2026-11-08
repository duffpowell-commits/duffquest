"""Cut Gemini's kitchen props sheet (G6) into single sprites.

    python3 tools/import_props.py

Source: grok_art/2026-11-08-gemini-test/g6_try1.jpg (1024x1024 JPEG, 4x4 cells of 256 on magenta, thin grid lines).
Each cell is inset past the grid line, keyed (JPEG magenta, sampled from the corners), trimmed, scaled by SCALE
with hard alpha, and saved as assets/art/kp_<name>.png (origin = centre, 2 px per world unit).
Registers kp_* in assets/art/manifest.json + scripts/art_manifest.gd. Used by sandwich.gd and fryer.gd.
"""
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "grok_art" / "2026-11-08-gemini-test" / "g6_try1.jpg"
OUT = ROOT / "assets" / "art"
SCALE = 0.25
# bigger sprites for the minigame stars (native size, no runtime scaling)
SCALE_OF = {"fry_basket": 0.42, "fries": 0.36, "fried_chicken": 0.45, "bun": 0.6, "lettuce": 0.55, "tomato": 0.6}
INSET = 10
NAMES = ["fry_basket", "fries", "fried_chicken", "bun",
         "lettuce", "tomato", "pickle_jar", "mash",
         "thermometer", "ticket", "heat_lamp", "ketchup",
         "spatula", "skillet", "plate", "salt"]


def main():
    im = np.asarray(Image.open(SRC).convert("RGB")).astype(int)
    keyc = np.median(np.concatenate([im[20:40, 20:40].reshape(-1, 3), im[-40:-20, -40:-20].reshape(-1, 3)]), 0)
    table = {}
    for i, name in enumerate(NAMES):
        r, c = divmod(i, 4)
        cell = im[r * 256 + INSET:(r + 1) * 256 - INSET, c * 256 + INSET:(c + 1) * 256 - INSET]
        d = np.abs(cell - keyc).sum(-1)
        rr, gg, bb = cell[..., 0], cell[..., 1], cell[..., 2]
        magish = (rr - gg > 90) & (bb - gg > 90) & (np.abs(rr - bb) < 70)
        alpha = np.where((d < 150) | magish, 0, 255).astype(np.uint8)
        # despill: pull pinkish edge pixels toward grey
        spill = (rr > gg + 40) & (bb > gg + 40)
        rgb = cell.copy()
        rgb[spill, 0] = (rgb[spill, 1] + rgb[spill, 0]) // 2
        rgb[spill, 2] = (rgb[spill, 1] + rgb[spill, 2]) // 2
        if name == "fry_basket":  # steel mesh: JPEG left the magenta showing through it -> plain grey
            purple = (rgb[..., 0] > rgb[..., 1] + 12) & (rgb[..., 2] > rgb[..., 1] + 12)
            grey = rgb[purple].mean(-1, keepdims=True).astype(int)
            rgb[purple] = np.repeat(grey, 3, -1)
        rgba = np.dstack([rgb.clip(0, 255).astype(np.uint8), alpha])
        ys, xs = np.where(alpha > 0)
        rgba = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        sc = SCALE_OF.get(name, SCALE)
        w, h = max(1, round(rgba.shape[1] * sc)), max(1, round(rgba.shape[0] * sc))
        small = np.asarray(Image.fromarray(rgba, "RGBA").resize((w, h), Image.LANCZOS)).copy()
        small[..., 3] = np.where(small[..., 3] >= 140, 255, 0)
        key = "kp_" + name
        Image.fromarray(small, "RGBA").save(OUT / f"{key}.png")
        table[key] = {"w": w, "h": h, "cell": [w, h], "origin": [w // 2, h // 2], "kind": "prop", "s": 2}
    mj_path = OUT / "manifest.json"
    mj = json.loads(mj_path.read_text())
    t = mj["assets"] if "assets" in mj else mj
    for k in [k for k in t if k.startswith("kp_")]:
        del t[k]
    t.update(table)
    mj_path.write_text(json.dumps(mj, indent=2) + "\n")
    gd = ROOT / "scripts" / "art_manifest.gd"
    src = re.sub(r'\n  "kp_[a-z_]+": \{[^}]*\},', "", gd.read_text())
    add = "".join(f'\n  "{k}": {json.dumps(v)},' for k, v in sorted(table.items()))
    gd.write_text(src.replace("const ASSETS = {", "const ASSETS = {" + add, 1))
    print("props:", ", ".join(f"{k} {v['w']}x{v['h']}" for k, v in table.items()))


if __name__ == "__main__":
    main()
