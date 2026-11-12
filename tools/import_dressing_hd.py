"""Import high-res painted street props as sd_<NAME>.png at density 4 (one texel per screen pixel).

    python3 tools/import_dressing_hd.py DIR [NAME ...]

DIR holds sd_<name>_v1.png masters (flat magenta background, Drive "97 Gemini art drops").
Each prop keeps its old world footprint: it is fitted inside BOX (world units, the Nov 8 s:2 size / 2),
keyed, trimmed, area-downscaled with premultiplied alpha and hard-thresholded. Origin = bottom centre
(the ground contact point), so data/town_dressing.json placements stay valid.
Fences are not handled here (they still come from tools/import_dressing.py).
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
S = 4
# max box in world units (old s:2 pixel size / 2)
BOX = {
    "bike_rack": (16, 12.5), "bus_bench": (19.5, 12), "fire_hydrant": (8.5, 14),
    "football_fan_flag": (17.5, 21), "hedge": (56, 23.5), "lilac": (32.5, 38),
    "little_free_library": (13.5, 21), "mailbox": (11.5, 19), "maple": (54, 56),
    "newspaper_box": (11.5, 19), "oak": (56, 54), "pine": (44, 56), "pothole_cone": (8.5, 12),
    "recycling_bin": (14, 19), "scattered_leaves": (22, 15.5), "scraggly_ash": (50.5, 56),
    "shopping_cart": (11, 16),
}


def key_magenta(im):
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    bg = (r > 170) & (b > 170) & (g < 120) & (np.abs(r - b) < 70)
    return np.where(bg, 0, 255).astype(np.uint8)


def despill(im, alpha):
    # pull magenta fringe toward neutral on edge pixels
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    mag = (alpha > 0) & (r > g + 40) & (b > g + 40) & (np.abs(r - b) < 60)
    m = np.minimum(r, b)
    im[..., 0] = np.where(mag, (g + m) // 2, r)
    im[..., 2] = np.where(mag, (g + m) // 2, b)
    return im


def largest_blobs(alpha):
    # drop tiny specks left by the key (anything under 0.2% of the opaque area)
    try:
        from scipy import ndimage
    except ImportError:
        return alpha
    lab, n = ndimage.label(alpha > 0)
    if n <= 1:
        return alpha
    sizes = ndimage.sum(alpha > 0, lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= sizes.max() * 0.002])
    return np.where(keep, alpha, 0).astype(np.uint8)


def do(src, name, man, gd):
    bw, bh = BOX[name]
    W, H = round(bw * S), round(bh * S)
    im = np.asarray(Image.open(src).convert("RGB")).astype(int)
    alpha = largest_blobs(key_magenta(im))
    im = despill(im.copy(), alpha)
    ys, xs = np.where(alpha > 0)
    im, alpha = im[ys.min():ys.max() + 1, xs.min():xs.max() + 1], alpha[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    s = min(W / im.shape[1], H / im.shape[0])
    w, h = max(1, round(im.shape[1] * s)), max(1, round(im.shape[0] * s))
    rgba = Image.fromarray(np.dstack([im.astype(np.uint8), alpha]), "RGBA").convert("RGBa")
    small = np.asarray(rgba.resize((w, h), Image.BOX).convert("RGBA")).copy()
    small[..., 3] = np.where(small[..., 3] >= 140, 255, 0)
    small[small[..., 3] == 0] = 0
    Image.fromarray(small, "RGBA").save(ROOT / "assets" / "art" / f"sd_{name}.png")
    entry = {"w": w, "h": h, "cell": [w, h], "origin": [w // 2, h], "s": S}
    man["assets"][f"sd_{name}"] = entry
    line = f'  "sd_{name}": {json.dumps(entry)},'
    gd, n = re.subn(rf'^  "sd_{name}": \{{.*\}},$', lambda _: line, gd, flags=re.M)
    assert n == 1, f"sd_{name} not found in art_manifest.gd"
    print(f"sd_{name}: {w}x{h} (box {W}x{H})")
    return gd


def main(d, names):
    d = Path(d)
    mp = ROOT / "assets" / "art" / "manifest.json"
    man = json.loads(mp.read_text())
    gp = ROOT / "scripts" / "art_manifest.gd"
    gd = gp.read_text()
    for name in names or sorted(BOX):
        gd = do(d / f"sd_{name}_v1.png", name, man, gd)
    mp.write_text(json.dumps(man, indent=2) + "\n")
    gp.write_text(gd)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
