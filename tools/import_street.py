"""Fit a painted street ground onto the gameplay layout and save it as assets/art/ground_painted.png.

    python3 tools/import_street.py [painting.png]

The painting (Canva repaint of data/town_ground.txt's tile render, grok_art/2026-11-11-street/) keeps the layout
but not the exact proportions, so: find both roads' centre lines in the painting and in the layout render (asphalt =
blue >= green, red < 135), pick ONE uniform scale that still covers the whole map, and line the road centres up.
Roads land within a few px of the gameplay roads (driver lanes, sidewalks) without stretching the art.
scripts/ground.gd uses ground_painted.png when it exists (same size + origin as the tile build).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "grok_art/2026-11-11-street/ground_v1.png"
LAYOUT = ROOT / "grok_art/2026-11-11-street/ground_layout.png"
OUT = ROOT / "assets/art/ground_painted.png"


def roads(img: Image.Image):
    a = np.asarray(img.convert("RGB")).astype(int)
    h, w, _ = a.shape
    m = (a[..., 2] >= a[..., 1] - 5) & (a[..., 0] < 135)
    xs = np.where(m[:int(h * 0.22)].mean(0) > 0.6)[0]   # top strip: only the vertical road
    ys = np.where(m[:, :int(w * 0.22)].mean(1) > 0.6)[0]   # left strip: only the horizontal road
    return (xs.min() + xs.max()) / 2.0, (ys.min() + ys.max()) / 2.0, xs.max() - xs.min(), ys.max() - ys.min()


def main() -> None:
    lay = Image.open(LAYOUT)
    pnt = Image.open(SRC).convert("RGB")
    W, H = lay.size
    lx, ly, lw, lh = roads(lay)
    px, py, pw, ph = roads(pnt)
    s = max(W / pnt.width, H / pnt.height)
    # road width wants (lw/pw, lh/ph); never go below full coverage
    s = max(s, min(lw / pw, lh / ph))
    for _ in range(40):   # grow until the centred painting covers every edge
        ox, oy = lx - px * s, ly - py * s
        if ox <= 0 and oy <= 0 and ox + pnt.width * s >= W and oy + pnt.height * s >= H:
            break
        s *= 1.01
    big = pnt.resize((round(pnt.width * s), round(pnt.height * s)), Image.LANCZOS)
    out = Image.new("RGB", (W, H))
    out.paste(big, (round(ox), round(oy)))
    out.save(OUT)
    print(f"scale {s:.3f} offset ({ox:.0f},{oy:.0f}); roads painted {pw * s:.0f}/{ph * s:.0f} px vs layout {lw}/{lh}; "
          f"centre error {abs(px * s + ox - lx):.1f},{abs(py * s + oy - ly):.1f} px -> {OUT.name}")


if __name__ == "__main__":
    main()
