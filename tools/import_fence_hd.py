"""Import high-res painted fence runs as sd_<KIND>_straight.png at density 4.

    python3 tools/import_fence_hd.py DIR [KIND ...]

DIR holds sd_fence_<kind>_v1.png masters: one fence panel with a post at each end on flat magenta
(Drive "97 Gemini art drops"). Each master is keyed and split into left post, panel and right post.
A segment = left post + a slice of the panel + right post, cut so the right post starts exactly
FENCE_SEG (39) world units after the left post. Consecutive segments in a run (scripts/dressing.gd)
then lay the next left post exactly over the previous right post, so the run tiles with no seam.
The panel slice ends at the most transparent column near the cut (a gap between planks/pickets).
Origin = bottom left. The run needs no separate end post any more.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from import_dressing_hd import key_magenta, despill, largest_blobs  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
S = 4
SEG = 39.0
# target height in world units (the old Nov 8 runs: brick ~19, the rest ~28)
HEIGHT = {"red_brick": 20.0, "privacy_wood": 28.0, "chain_link": 26.0, "white_picket": 24.0}


def posts(alpha):
    """Column spans of the two end posts: they stand taller than the panel between them."""
    W = alpha.shape[1]
    tops = np.array([np.argmax(alpha[:, x] > 0) if alpha[:, x].any() else alpha.shape[0] for x in range(W)])
    thr = np.median(tops[W // 4:3 * W // 4]) / 2
    below = tops < thr
    s = int(np.argmax(below))
    e = s + int(np.argmax(~below[s:]))
    rs = W - 1 - int(np.argmax(below[::-1]))
    re_ = rs - int(np.argmax(~below[rs::-1]))
    return e + s, W - re_ + (W - 1 - rs)   # widths, bevel mirrored onto the inner side


def do(src, kind, man, gd):
    im = np.asarray(Image.open(src).convert("RGB")).astype(int)
    alpha = largest_blobs(key_magenta(im))
    im = despill(im.copy(), alpha)
    ys, xs = np.where(alpha > 0)
    im, alpha = im[ys.min():ys.max() + 1, xs.min():xs.max() + 1], alpha[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    H, W = alpha.shape
    lw, rw = posts(alpha)
    scale = HEIGHT[kind] / H                     # world units per master pixel
    want = int(round(SEG / scale)) - lw          # panel slice width in master pixels
    cov = (alpha[:, lw:W - rw] > 0).sum(0)
    lo, hi = max(1, want - 40), min(len(cov) - 1, want + 40)
    cut = lo + int(np.argmin(cov[lo:hi]))
    scale = SEG / (lw + cut)                     # exact 39-unit post-to-post spacing
    seg_im = np.concatenate([im[:, :lw + cut], im[:, W - rw:]], 1)
    seg_a = np.concatenate([alpha[:, :lw + cut], alpha[:, W - rw:]], 1)
    w, h = max(1, round(seg_im.shape[1] * scale * S)), max(1, round(H * scale * S))
    rgba = Image.fromarray(np.dstack([seg_im.astype(np.uint8), seg_a]), "RGBA").convert("RGBa")
    small = np.asarray(rgba.resize((w, h), Image.BOX).convert("RGBA")).copy()
    small[..., 3] = np.where(small[..., 3] >= 140, 255, 0)
    small[small[..., 3] == 0] = 0
    name = f"sd_{kind}_straight"
    Image.fromarray(small, "RGBA").save(ROOT / "assets" / "art" / f"{name}.png")
    entry = {"w": w, "h": h, "cell": [w, h], "origin": [0, h], "s": S}
    man["assets"][name] = entry
    line = f'  "{name}": {json.dumps(entry)},'
    gd, n = re.subn(rf'^  "{name}": \{{.*\}},$', lambda _: line, gd, flags=re.M)
    assert n == 1, f"{name} not found in art_manifest.gd"
    print(f"{name}: {w}x{h}  posts {lw}/{rw}px  slice {cut}px  ({w / S:.1f}x{h / S:.1f} world)")
    return gd


def main(d, kinds):
    d = Path(d)
    mp = ROOT / "assets" / "art" / "manifest.json"
    man = json.loads(mp.read_text())
    gp = ROOT / "scripts" / "art_manifest.gd"
    gd = gp.read_text()
    for kind in kinds or sorted(HEIGHT):
        gd = do(d / f"sd_fence_{kind}_v1.png", kind, man, gd)
    mp.write_text(json.dumps(man, indent=2) + "\n")
    gp.write_text(gd)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
