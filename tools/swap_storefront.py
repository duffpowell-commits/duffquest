"""Swap one storefront sprite for a new image of any size (keeps the footprint, size and manifest entry).

    python3 tools/swap_storefront.py SRC NAME      e.g. grok_art/2026-11-08-chatgpt-test/r1_chatgpt_try2.png kwik

Keys the corner colour (magenta/green), trims, scales (nearest) to fit the existing sf_<NAME>.png canvas
(= footprint x2), centres it and drops it so its lowest opaque row sits on the canvas bottom (footprint
edge, where doors and story triggers live). Writes assets/art/sf_<NAME>.png.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent


def main(src, name):
    dst = ROOT / "assets" / "art" / f"sf_{name}.png"
    W, H = Image.open(dst).size
    im = np.asarray(Image.open(src).convert("RGB")).astype(int)
    key = np.median(np.concatenate([im[:8, :8].reshape(-1, 3), im[-8:, -8:].reshape(-1, 3)]), 0)
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    if key[1] > key[0]:
        bgish = (g - r > 90) & (g - b > 90)
    else:
        bgish = (r - g > 90) & (b - g > 90)
    alpha = np.where((np.abs(im - key).sum(-1) < 150) | bgish, 0, 255).astype(np.uint8)
    rgba = np.dstack([im.clip(0, 255).astype(np.uint8), alpha])
    ys, xs = np.where(alpha > 0)
    rgba = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    s = min(W / rgba.shape[1], H / rgba.shape[0])
    w, h = max(1, round(rgba.shape[1] * s)), max(1, round(rgba.shape[0] * s))
    small = np.asarray(Image.fromarray(rgba, "RGBA").resize((w, h), Image.NEAREST)).copy()
    small[..., 3] = np.where(small[..., 3] >= 128, 255, 0)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.paste(Image.fromarray(small, "RGBA"), ((W - w) // 2, H - h))
    out.save(dst)
    print(f"sf_{name}: {w}x{h} in {W}x{H}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
