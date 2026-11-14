"""Smug smirk pass for HD Duff sheets (Duff asked Nov 14: "make me look more smug").

Finds the mouth line on the front walk frames (row 0, cols 0-2) from the eye anchor, lifts one
corner a pixel, darkens it and trims the other end, so the mouth reads lopsided.
Run once per sheet:  python3 tools/duff_smirk.py SHEET SHEET
"""
import sys
import numpy as np
from PIL import Image

C = 128
DY = {0: 36, 2: 28, 3: 28}          # eye line below the figure top (same as duff_eyes_narrow)

def skin(c):
    r, g, b, al = [c[..., i].astype(int) for i in range(4)]
    return (al > 200) & (r > 170) & (g > 110) & (b > 70) & (r > g + 15) & (g > b + 10) & (r - b < 150)

def lum(px):
    return px[..., :3].astype(int).sum(-1)

def find_mouth(c, row):
    """Mouth = the longest run of pixels much darker than the lip row under them,
    a few rows below the eyes, near the middle of the face."""
    al = c[..., 3] > 0
    top = np.where(al.any(1))[0][0]
    ey = top + DY[row]
    band = skin(c[ey - 2:ey + 3])
    xs = np.where(band.any(0))[0]
    if not len(xs):
        return None
    cx = int(np.median(xs))
    L = lum(c)
    best = None
    for y in range(ey + 6, ey + 14):
        run = None
        for x in range(cx - 12, cx + 12):
            ok = L[y, x] < 400 and L[y + 1, x] - L[y, x] > 75 and c[y, x, 3] > 200
            if ok:
                run = (x, x) if run is None else (run[0], x)
            elif run is not None:
                if best is None or run[1] - run[0] > best[2] - best[1]:
                    best = (y, run[0], run[1])
                run = None
        if run is not None and (best is None or run[1] - run[0] > best[2] - best[1]):
            best = (y, run[0], run[1])
    if best is None or best[2] - best[1] < 4:
        return None
    return best

def mix(px, ink, t):
    return (px[:3].astype(int) * (1 - t) + ink * t).astype(np.uint8)

def smirk(c, row):
    m = find_mouth(c, row)
    if not m:
        return False
    y, xa, xb = m
    L = lum(c)
    ink = c[y, xa + int(np.argmin(L[y, xa:xb + 1])), :3].astype(int)
    lip = [c[y + 1, x, :3].copy() for x in range(xa, xb + 1)]
    # screen-right corner curls up: last pixel up 2, the two before it up 1
    for x, dy in ((xb, 2), (xb - 1, 1), (xb - 2, 1)):
        c[y - dy, x, :3] = mix(c[y - dy, x], ink, 0.85)
        c[y, x, :3] = lip[x - xa]
    c[y - 1, xb, :3] = mix(c[y - 1, xb], ink, 0.6)          # join the curl
    c[y - 1, xb - 3, :3] = mix(c[y - 1, xb - 3], ink, 0.35)  # soften the step
    # cheek dimple under the curl
    c[y - 1, xb + 1, :3] = mix(c[y - 1, xb + 1], ink, 0.35)
    # the other corner sags flat: trim one pixel
    c[y, xa, :3] = lip[0]
    return True

def cock_brow(c, row):
    """Raise the screen-left eyebrow one pixel (and arch its outer end two)."""
    al = c[..., 3] > 0
    top = np.where(al.any(1))[0][0]
    ey = top + DY[row]
    band = skin(c[ey - 2:ey + 3])
    xs = np.where(band.any(0))[0]
    if not len(xs):
        return False
    cx = int(np.median(xs))
    L = lum(c)
    y0, y1 = ey - 12, ey - 4                 # brow band above the eye
    x0, x1 = cx - 20, cx - 2
    dark = (L[y0:y1, x0:x1] < 200) & (c[y0:y1, x0:x1, 3] > 200)
    cols = np.where(dark.any(0))[0]
    if len(cols) < 4:
        return False
    old = c.copy()
    bx0, bx1 = x0 + cols.min(), x0 + cols.max()
    for x in range(bx0, bx1 + 1):
        lift = 2 if x - bx0 < (bx1 - bx0) // 3 else 1   # outer third arches higher
        ys = [y for y in range(y0, y1) if L[y, x] < 200 and old[y, x, 3] > 200]
        if not ys:
            continue
        top_y, bot_y = min(ys), max(ys)
        skin_px = old[top_y - 2, x, :3]
        for y in range(top_y, bot_y + 1):
            c[y - lift, x, :3] = old[y, x, :3]
        for y in range(bot_y - lift + 1, bot_y + 1):
            c[y, x, :3] = skin_px
    return True

def main(src, out):
    a = np.array(Image.open(src).convert('RGBA'))
    n = 0
    for row in (0,):
        for col in range(3):          # front walk frames; col 3 is the angry action
            c = a[row * C:(row + 1) * C, col * C:(col + 1) * C]
            n += smirk(c, row)
            cock_brow(c, row)
    Image.fromarray(a).save(out)
    print(src, 'smirked', n, 'frames')

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
