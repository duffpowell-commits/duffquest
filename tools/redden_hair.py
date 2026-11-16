#!/usr/bin/env python3
"""Shift a character's brown hair to copper/auburn red without touching skin.

Usage: python3 tools/redden_hair.py SRC OUT [--hue -14] [--sat 1.18] [--val 0.94]
         [--max-v 0.72] [--min-px 40] [--erode 3] [--box x0,y0,x1,y1 ...] [--keep x0,y0,x1,y1 ...] [--debug MASK.png]

How it finds the hair: pixels in the brown/orange band (hue 12-48 deg, sat > .3) are
split into blobs by the dark ink outlines (4-connected). Skin blobs are bright (median
value well above hair), so only blobs whose median value is under --max-v get shifted.
--box limits the search to rectangles (e.g. the coworker in a loading screen) and is
needed on painted scenes where other brown things exist. Needs numpy, pillow, scipy.
Used Nov 16 2026 for Brittany (ch_brittany, portraits_hd/brittany, loading/goose_bet).
"""
import argparse
import numpy as np
from PIL import Image
from scipy import ndimage


def rgb_to_hsv(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = a.max(-1)
    mn = a.min(-1)
    d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    rm = m & (mx == r)
    gm = m & (mx == g) & ~rm
    bm = m & ~rm & ~gm
    h[rm] = ((g[rm] - b[rm]) / d[rm]) % 6
    h[gm] = (b[gm] - r[gm]) / d[gm] + 2
    h[bm] = (r[bm] - g[bm]) / d[bm] + 4
    h = h * 60.0
    s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0)
    return h, s, mx


def hsv_to_rgb(h, s, v):
    h = (h % 360) / 60.0
    i = np.floor(h).astype(int) % 6
    f = h - np.floor(h)
    p = v * (1 - s)
    q = v * (1 - s * f)
    t = v * (1 - s * (1 - f))
    out = np.zeros(h.shape + (3,))
    for k, (rr, gg, bb) in enumerate([(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]):
        sel = i == k
        out[sel, 0] = rr[sel]
        out[sel, 1] = gg[sel]
        out[sel, 2] = bb[sel]
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--hue", type=float, default=-14.0)
    ap.add_argument("--sat", type=float, default=1.18)
    ap.add_argument("--val", type=float, default=0.94)
    ap.add_argument("--max-v", type=float, default=0.72)
    ap.add_argument("--min-px", type=int, default=40)
    ap.add_argument("--min-s", type=float, default=0.3, help="pixel art: 0.82 splits hair (s .84-.91) from skin (s .6-.78)")
    ap.add_argument("--pixels", action="store_true", help="skip the blob test: every candidate pixel is hair (use with --min-s)")
    ap.add_argument("--clean", type=int, default=0, help="opening radius to strip speckle (painted scenes: 2)")
    ap.add_argument("--erode", type=int, default=3)
    ap.add_argument("--box", action="append", default=[])
    ap.add_argument("--skin-v", type=float, default=1.0, help="pixels brighter than this with skin saturation stay put")
    ap.add_argument("--keep", action="append", default=[], help="x0,y0,x1,y1 never recoloured (e.g. a scrunched forehead)")
    ap.add_argument("--debug")
    a = ap.parse_args()

    im = Image.open(a.src)
    mode = im.mode
    rgba = np.asarray(im.convert("RGBA")).astype(np.float64) / 255.0
    rgb = rgba[..., :3]
    h, s, v = rgb_to_hsv(rgb)
    cand = (h >= 12) & (h <= 48) & (s > a.min_s) & (v > 0.08) & (rgba[..., 3] > 0.05)
    if a.box:
        inbox = np.zeros_like(cand)
        for b in a.box:
            x0, y0, x1, y1 = [int(n) for n in b.split(",")]
            inbox[y0:y1, x0:x1] = True
        cand &= inbox
    # erode first so thin gaps in the ink (temple, jaw) don't fuse hair and face,
    # then hand every candidate pixel to its nearest eroded blob
    core = ndimage.binary_erosion(cand, iterations=a.erode) if a.erode > 0 else cand
    lab, n = ndimage.label(core)
    if a.erode > 0 and n:
        _, (iy, ix) = ndimage.distance_transform_edt(lab == 0, return_indices=True)
        lab = np.where(cand, lab[iy, ix], 0)
    hair = np.zeros_like(cand)
    for i in range(1, n + 1):
        blob = lab == i
        cnt = int(blob.sum())
        if cnt < a.min_px:
            continue
        if float(np.median(v[blob])) < a.max_v:
            hair |= blob
    # stray strands: small or slightly lighter blobs that touch the hair
    near = ndimage.binary_dilation(hair, iterations=3)
    for i in range(1, n + 1):
        blob = lab == i
        if not (blob & near).any() or (blob & hair).any():
            continue
        if int(blob.sum()) < a.min_px * 5 and float(np.median(v[blob])) < a.max_v + 0.1:
            hair |= blob

    if a.skin_v < 1.0:
        hair &= ~((v > a.skin_v) & (s < 0.66))   # lit skin never counts as hair
    if a.clean > 0:
        # painted/JPEG art: drop speckle on shaded skin, keep only big hair masses
        hair = ndimage.binary_opening(hair, iterations=a.clean)
        hl, hn = ndimage.label(hair)
        if hn:
            sizes = ndimage.sum(hair, hl, range(1, hn + 1))
            keep = np.zeros(hn + 1, bool)
            keep[1:] = sizes >= a.min_px * 10
            hair = keep[hl]
        hair = ndimage.binary_closing(hair, iterations=1) & cand
    if a.pixels:
        hair = cand.copy()
    for b in a.keep:
        x0, y0, x1, y1 = [int(n) for n in b.split(",")]
        hair[y0:y1, x0:x1] = False
    nh = h + a.hue
    ns = np.clip(s * a.sat, 0, 1)
    nv = np.clip(v * a.val, 0, 1)
    new = hsv_to_rgb(nh, ns, nv)
    out = rgb.copy()
    out[hair] = new[hair]
    res = np.concatenate([out, rgba[..., 3:]], -1)
    img = Image.fromarray((res * 255 + 0.5).clip(0, 255).astype(np.uint8), "RGBA")
    if mode == "RGB":
        img = img.convert("RGB")
        img.save(a.out, quality=92)
    else:
        img.save(a.out)
    if a.debug:
        Image.fromarray((hair * 255).astype(np.uint8)).save(a.debug)
    print("%s: %d hair px recoloured" % (a.out, int(hair.sum())))


if __name__ == "__main__":
    main()
