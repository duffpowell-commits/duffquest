"""Import a high-res painted storefront as sf_<NAME>.png at density 4 (one texel per screen pixel).

    python3 tools/import_storefront_hd.py SRC NAME [--up N]

The building keeps its footprint in main.gd: same bottom edge (doors and story triggers sit there) and
same centre x. The canvas is footprint x 4; --up N (world units) lets the roof rise N units above the
footprint (canvas grows upward, manifest origin shifts so Art.image still draws at r.position).
Keys out flat magenta, trims, area-downscales with premultiplied alpha, hard-thresholds alpha, then
writes the PNG and updates assets/art/manifest.json + scripts/art_manifest.gd.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
S = 4
# footprint sizes in world units (main.gd `buildings` / *_R rects)
FOOT = {
    "home": (110, 70), "neighbor": (80, 60), "kwik": (130, 70), "fork": (150, 70), "hoa": (120, 70),
    "seen": (60, 40), "iron": (55, 50), "club": (80, 52), "mining": (58, 42), "plaza": (52, 80),
    "walgrumps": (76, 38), "hywhee": (110, 48), "plazmart": (72, 40),
}
# roof rise used for the Nov 12 masters (default when --up is not given); negative shrinks below the lot top
UP = {"home": 7, "mining": 4, "plaza": 6, "seen": -4}


def key_magenta(im):
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    bg = (r > 170) & (b > 170) & (g < 120) & (np.abs(r - b) < 70)
    return np.where(bg, 0, 255).astype(np.uint8)


def main(src, name, up=None):
    up = UP.get(name, 0) if up is None else up
    fw, fh = FOOT[name]
    W, H = fw * S, (fh + up) * S
    im = np.asarray(Image.open(src).convert("RGB")).astype(int)
    alpha = key_magenta(im)
    ys, xs = np.where(alpha > 0)
    im, alpha = im[ys.min():ys.max() + 1, xs.min():xs.max() + 1], alpha[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    s = min(W / im.shape[1], H / im.shape[0])
    w, h = max(1, round(im.shape[1] * s)), max(1, round(im.shape[0] * s))
    rgba = Image.fromarray(np.dstack([im.astype(np.uint8), alpha]), "RGBA").convert("RGBa")
    small = np.asarray(rgba.resize((w, h), Image.BOX).convert("RGBA")).copy()
    small[..., 3] = np.where(small[..., 3] >= 140, 255, 0)
    small[small[..., 3] == 0] = 0
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.paste(Image.fromarray(small, "RGBA"), ((W - w) // 2, H - h))
    out.save(ROOT / "assets" / "art" / f"sf_{name}.png")

    entry = {"w": W, "h": H, "cell": [W, H], "origin": [0, up * S], "s": S}
    mp = ROOT / "assets" / "art" / "manifest.json"
    man = json.loads(mp.read_text())
    man["assets"][f"sf_{name}"] = entry
    mp.write_text(json.dumps(man, indent=2) + "\n")
    gp = ROOT / "scripts" / "art_manifest.gd"
    line = f'  "sf_{name}": {{"w": {W}, "h": {H}, "cell": [{W}, {H}], "origin": [0, {up * S}], "s": {S}}},'
    txt, n = re.subn(rf'^  "sf_{name}": \{{.*\}},$', line, gp.read_text(), flags=re.M)
    assert n == 1, f"sf_{name} not found in art_manifest.gd"
    gp.write_text(txt)
    print(f"sf_{name}: {w}x{h} in {W}x{H} (up {up})")


if __name__ == "__main__":
    a = sys.argv[1:]
    up = None
    if "--up" in a:
        i = a.index("--up")
        up = int(a[i + 1])
        del a[i:i + 2]
    main(a[0], a[1], up)
