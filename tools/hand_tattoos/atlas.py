#!/usr/bin/env python3
"""Carry the hand-tattoo changes of duff_home_hd3d into the true-3D model's texture atlas.

    python3 tools/hand_tattoos/atlas.py

assets/model3d/duff_atlas.png is four 512 tiles (front, back, left = row 3, right = row 2) of the sheet's
idle frames, each the figure's silhouette box + an 8 px pad (at the 1024 input scale, figure ~82% fill)
stretched to 512 (tools/true3d/rig.py view()). The model's UVs depend on that box, so instead of
rebuilding the tile we add the sheet's before/after difference, warped the same way. Alpha and UVs stay.
"""
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SHEET = os.path.join(ROOT, "assets/art3d/duff_home_hd3d.png")
OLD = os.path.join(ROOT, "grok_art/hand_tattoos/_work/originals/assets/art3d/duff_home_hd3d.png")
ATLAS = os.path.join(ROOT, "assets/model3d/duff_atlas.png")
OLD_ATLAS = os.path.join(ROOT, "grok_art/hand_tattoos/_work/originals/assets/model3d/duff_atlas.png")
T = 512
VIEWS = [("front", 0), ("back", 1), ("left", 3), ("right", 2)]


def main():
    import subprocess
    if not os.path.exists(OLD_ATLAS):
        os.makedirs(os.path.dirname(OLD_ATLAS), exist_ok=True)
        blob = subprocess.run(["git", "-C", ROOT, "show", "HEAD:assets/model3d/duff_atlas.png"],
                              capture_output=True, check=True).stdout
        open(OLD_ATLAS, "wb").write(blob)
    new = np.asarray(Image.open(SHEET).convert("RGBA")).astype(float)
    old = np.asarray(Image.open(OLD).convert("RGBA")).astype(float)
    atlas = np.asarray(Image.open(OLD_ATLAS).convert("RGB")).astype(float)
    C = new.shape[1] // 4
    for i, (k, row) in enumerate(VIEWS):
        fo = old[row * C:(row + 1) * C, 0:C]
        fn = new[row * C:(row + 1) * C, 0:C]
        mask = fo[..., 3] > 128
        ys, xs = np.nonzero(mask)
        x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
        s = 1024 * 0.82 / max(x1 - x0, y1 - y0)
        pad = 8 / s
        X0, X1, Y0, Y1 = x0 - pad, x1 + pad, y0 - pad, y1 + pad
        diff = (fn[..., :3] - fo[..., :3]) * mask[..., None]
        # sample diff at each tile pixel
        ty, tx = np.mgrid[0:T, 0:T]
        fx = X0 + (tx + 0.5) / T * (X1 - X0) - 0.5
        fy = Y0 + (ty + 0.5) / T * (Y1 - Y0) - 0.5
        xi = np.clip(np.round(fx).astype(int), 0, C - 1)
        yi = np.clip(np.round(fy).astype(int), 0, C - 1)
        d = diff[yi, xi]
        ox, oy = (i % 2) * T, (i // 2) * T
        atlas[oy:oy + T, ox:ox + T] += d
        print(k, "changed tile px:", int((np.abs(d).sum(-1) > 0).sum()))
    Image.fromarray(np.clip(atlas, 0, 255).astype(np.uint8), "RGB").save(ATLAS)


if __name__ == "__main__":
    main()
