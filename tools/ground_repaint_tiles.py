"""Repaint the street ground in four overlapping 16:9 tiles, then stitch them back onto the exact layout.

    python3 tools/ground_repaint_tiles.py split [painting.png]     -> grok_art/2026-11-16-ground/tile_<r><c>.png
    python3 tools/ground_repaint_tiles.py merge DIR                -> assets/art/ground_painted.png

One Canva generation tops out near 2k px, and the 4 px/unit ground is 2688x1536, so the map is cut into 2x2 tiles of
1536x864 (16:9) with 384/192 px overlaps. Each tile is repainted in Canva (reference = the tile, "same layout"), saved
as DIR/tile_<r><c>.png at any size, and merged: every repaint is scaled to its tile, nudged onto the source tile by
the best whole-pixel shift of its edges (+-24 px), checked (mean edge error must stay low, or the tile is rejected and
the source tile is kept) and feather-blended across the overlaps.
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


def ramp(n: int, ov: int, lo: bool, hi: bool) -> np.ndarray:
    w = np.ones(n)
    if lo:
        w[:ov] = np.linspace(0, 1, ov)
    if hi:
        w[-ov:] = np.linspace(1, 0, ov)
    return w


def merge(d: Path) -> None:
    full = base(ROOT / "grok_art/2026-11-11-street/ground_v1.png")
    acc = np.zeros((H, W, 3))
    wsum = np.zeros((H, W, 1))
    ovx, ovy = 2 * TW - W, 2 * TH - H
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
                    tile = shifted
            else:
                print(f"tile {r}{c}: missing, keeping the source")
            wy = ramp(TH, ovy, r == 1, r == 0)
            wx = ramp(TW, ovx, c == 1, c == 0)
            w = (wy[:, None] * wx[None, :])[..., None]
            acc[y:y + TH, x:x + TW] += np.asarray(tile).astype(float) * w
            wsum[y:y + TH, x:x + TW] += w
    out = Image.fromarray((acc / np.maximum(wsum, 1e-6)).clip(0, 255).astype(np.uint8))
    out = out.filter(ImageFilter.UnsharpMask(radius=1.0, percent=80, threshold=2))
    out.save(import_street.OUT)
    print("->", import_street.OUT)


if __name__ == "__main__":
    if sys.argv[1] == "split":
        split(Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "grok_art/2026-11-11-street/ground_v1.png")
    else:
        merge(Path(sys.argv[2]))
