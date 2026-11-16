"""Repaint the street ground in four overlapping 16:9 tiles, then stitch them back onto the exact layout.

    python3 tools/ground_repaint_tiles.py split [painting.png]     -> grok_art/2026-11-16-ground/tile_<r><c>.png
    python3 tools/ground_repaint_tiles.py merge DIR                -> assets/art/ground_painted.png

One Canva generation tops out near 2k px, and the 4 px/unit ground is 2688x1536, so the map is cut into 2x2 tiles of
1536x864 (16:9) with 384/192 px overlaps. Each tile is repainted in Canva (reference = the tile, "same layout"), saved
as DIR/tile_<r><c>.png at any size, and merged: every repaint is scaled to its tile, nudged onto the source tile by
the best whole-pixel shift of its edges (+-24 px), checked (mean edge error must stay low, or the tile is rejected and
the source tile is kept) and colour-matched to the source below BLUR px and feather-blended across the overlaps.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import import_street  # noqa: E402

TW, TH = 1536, 864
W, H = 2688, 1536
X0 = [0, W - TW]
Y0 = [0, H - TH]
TILES = ROOT / "grok_art" / "2026-11-16-ground"
SHIFT = 24
BLUR = 10   # px: detail finer than this comes from the repaint, coarser from the source painting


def base(src: Path) -> Image.Image:
    """The painting fitted to the 2x layout, before sharpening (same maths as import_street)."""
    return import_street.fit(Image.open(src).convert("RGB"))


def edges(im: Image.Image) -> np.ndarray:
    g = np.asarray(im.convert("L").filter(ImageFilter.GaussianBlur(2)).filter(ImageFilter.FIND_EDGES)).astype(float)
    return g / (g.mean() + 1e-6)


def align(src: Image.Image, new: Image.Image):
    a, b = edges(src)[::2, ::2], edges(new)[::2, ::2]
    best = (1e18, 0, 0)
    m = SHIFT // 2
    core = a[m:-m, m:-m]
    for dy in range(-m, m + 1):
        for dx in range(-m, m + 1):
            sb = b[m + dy:b.shape[0] - m + dy, m + dx:b.shape[1] - m + dx]
            e = np.abs(core - sb).mean()
            if e < best[0]:
                best = (e, dx * 2, dy * 2)
    return best


def split(src: Path) -> None:
    TILES.mkdir(parents=True, exist_ok=True)
    im = base(src)
    for r, y in enumerate(Y0):
        for c, x in enumerate(X0):
            im.crop((x, y, x + TW, y + TH)).save(TILES / f"src_{r}{c}.png")
    print("tiles ->", TILES)


FEATHER = 24  # px of cross-fade either side of a seam


def seam_cut(a: np.ndarray, b: np.ndarray, axis: int) -> np.ndarray:
    """Weight for b (0..1) across an overlap of two aligned images, cutting along the
    lowest-difference path (a min-cost seam) so roads and lane lines never ghost."""
    diff = np.abs(a - b).mean(axis=2)
    if axis == 0:  # seam runs top to bottom, left image a, right image b
        diff = diff
    else:  # seam runs left to right, top image a, bottom image b
        diff = diff.T
    n, m = diff.shape
    cost = diff.copy()
    for i in range(1, n):
        prev = cost[i - 1]
        left = np.r_[np.inf, prev[:-1]]
        right = np.r_[prev[1:], np.inf]
        cost[i] += np.minimum(np.minimum(left, prev), right)
    path = np.zeros(n, int)
    path[-1] = int(np.argmin(cost[-1]))
    for i in range(n - 2, -1, -1):
        j = path[i + 1]
        lo, hi = max(j - 1, 0), min(j + 2, m)
        path[i] = lo + int(np.argmin(cost[i, lo:hi]))
    cols = np.arange(m)[None, :]
    w = np.clip((cols - path[:, None] + FEATHER) / (2 * FEATHER), 0, 1)
    return w if axis == 0 else w.T


def merge(d: Path) -> None:
    full = base(ROOT / "grok_art/2026-11-11-street/ground_v1.png")
    tiles = {}
    for r, y in enumerate(Y0):
        for c, x in enumerate(X0):
            src = full.crop((x, y, x + TW, y + TH))
            p = d / f"tile_{r}{c}.png"
            tile = src
            if p.exists():
                new = Image.open(p).convert("RGB").resize((TW, TH), Image.LANCZOS)
                err, dx, dy = align(src, new)
                base_err = np.abs(edges(src) - edges(src.filter(ImageFilter.GaussianBlur(6)))).mean()
                ok = err < base_err
                print(f"tile {r}{c}: shift ({dx},{dy}) edge error {err:.3f} vs blur {base_err:.3f} -> {'use' if ok else 'REJECT'}")
                if ok:
                    shifted = Image.new("RGB", (TW, TH))
                    shifted.paste(src)
                    shifted.paste(new, (-dx, -dy))
                    # keep the repaint's fine detail, take colour + shading from the source (no seams between tiles)
                    lo_s = np.asarray(src.filter(ImageFilter.GaussianBlur(BLUR))).astype(float)
                    lo_n = np.asarray(shifted.filter(ImageFilter.GaussianBlur(BLUR))).astype(float)
                    tile = Image.fromarray((np.asarray(shifted).astype(float) - lo_n + lo_s).clip(0, 255).astype(np.uint8))
            else:
                print(f"tile {r}{c}: missing, keeping the source")
            tiles[r, c] = np.asarray(tile).astype(float)
    # join each row's left + right tile along a min-cost vertical seam, then the two rows along a horizontal one
    ox, oy = X0[1], Y0[1]
    rows = []
    for r in range(2):
        strip = np.zeros((TH, W, 3))
        a, b = tiles[r, 0], tiles[r, 1]
        strip[:, :ox] = a[:, :ox]
        strip[:, TW:] = b[:, TW - ox:]
        oa, ob = a[:, ox:], b[:, :TW - ox]
        w = seam_cut(oa, ob, 0)[..., None]
        strip[:, ox:TW] = oa * (1 - w) + ob * w
        rows.append(strip)
    out = np.zeros((H, W, 3))
    out[:oy] = rows[0][:oy]
    out[TH:] = rows[1][TH - oy:]
    oa, ob = rows[0][oy:], rows[1][:TH - oy]
    w = seam_cut(oa, ob, 1)[..., None]
    out[oy:TH] = oa * (1 - w) + ob * w
    img = Image.fromarray(out.clip(0, 255).astype(np.uint8))
    img = img.filter(ImageFilter.UnsharpMask(radius=1.0, percent=80, threshold=2))
    img.save(import_street.OUT)
    print("->", import_street.OUT)


if __name__ == "__main__":
    if sys.argv[1] == "split":
        split(Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "grok_art/2026-11-11-street/ground_v1.png")
    else:
        merge(Path(sys.argv[2]))
