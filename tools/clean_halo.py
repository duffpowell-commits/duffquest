"""Remove the green-screen halo from cut-out portraits (assets/art/portraits_hd/*.png).

    python3 tools/clean_halo.py                      # every portrait in place
    python3 tools/clean_halo.py assets/art/portraits_hd/duff.png --out /tmp/duff.png

Only the outer edge band (BAND px in from transparency) is touched, so green shirts, slime and
neon inside a character survive. Edge pixels that sit next to a green-dominant interior (a green
jacket's own outline) are left alone too.
- despill: in the band, green is clamped to max(red, blue) (the standard green-screen despill).
- erode: the outermost ring is dropped where it is semi-transparent and clearly green (pure spill).
A second run only touches a handful of px (the ring the erode exposed). tools/import_portrait.py calls clean() on every new cut.
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

PORTRAITS = Path(__file__).resolve().parent.parent / "assets" / "art" / "portraits_hd"
BAND = 5            # px from the transparent edge that may be despilled
SPILL = 12          # green must beat max(r, b) by this much to count as spill
CLEAR = 30          # ...and by this much (plus being mostly see-through) to be eroded
ERODE_ALPHA = 128   # only outer-ring pixels fainter than this go (keeps the anti-aliasing)
PROTECT = 6         # skip band pixels within this many px of genuinely green interior


def _shift(m, dx, dy):
    out = np.zeros_like(m)
    h, w = m.shape
    out[max(0, dy):h + min(0, dy), max(0, dx):w + min(0, dx)] = \
        m[max(0, -dy):h + min(0, -dy), max(0, -dx):w + min(0, -dx)]
    return out


def _dilate(m, n):
    for _ in range(n):
        m = m | _shift(m, 1, 0) | _shift(m, -1, 0) | _shift(m, 0, 1) | _shift(m, 0, -1)
    return m


def _edge_dist(solid, limit):
    """Chebyshev-ish steps from each solid pixel to the nearest non-solid one, capped at limit+1."""
    dist = np.full(solid.shape, limit + 1, np.int16)
    outside = ~solid
    for d in range(1, limit + 1):
        grown = _dilate(outside, 1)
        dist[solid & grown & (dist > limit)] = d
        outside = grown
    return dist


def clean(img):
    """Return a de-haloed copy of an RGBA PIL image."""
    a = np.asarray(img.convert("RGBA")).astype(np.int16)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    solid = al > 0
    dist = _edge_dist(solid, BAND + 4)
    spill = g - np.maximum(r, b)
    # genuinely green material: green-dominant, opaque and well inside the silhouette
    interior_green = (dist > BAND + 1) & (spill > SPILL) & (al == 255)
    # opening: specks of trapped screen don't count, only real green areas (jackets, slime)
    core = ~_dilate(~interior_green, 2)
    protect = _dilate(core, PROTECT + 2)
    band = solid & (dist <= BAND) & ~protect & (spill > SPILL)
    g2 = np.where(band, np.maximum(r, b), g)
    erode = band & (dist <= 1) & (spill > CLEAR) & (al < ERODE_ALPHA)
    al2 = np.where(erode, 0, al)
    out = np.stack([r, g2, b, al2], -1).clip(0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA"), int(band.sum()), int(erode.sum())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="*", help="PNGs (default: every portraits_hd/*.png, in place)")
    ap.add_argument("--out", help="write here instead of in place (single file only)")
    args = ap.parse_args()
    files = [Path(f) for f in args.files] or sorted(PORTRAITS.glob("*.png"))
    for f in files:
        img, n_band, n_erode = clean(Image.open(f))
        dst = Path(args.out) if args.out else f
        img.save(dst, optimize=True)
        print(f"{f.name}: despilled {n_band} px, eroded {n_erode} px -> {dst}")


if __name__ == "__main__":
    main()
