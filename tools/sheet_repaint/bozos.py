#!/usr/bin/env python3
"""Repaint the retired ch_donald.png sheet into Grant Gratuity (`bozos`, gala_ex_2).

Deterministic pixel edit, no image service. Run from the repo root:
    python3 tools/sheet_repaint/bozos.py

Reads  assets/art/ch_donald.png (never written)
Writes grok_art/2026-11-10-gala-exes/sheet_bozos.png   (256x256 RGBA master, 4x4 cells of 64)
       docs/renders/sheet_bozos_compare.png             (old | new at 4x on grey, plus portrait panel 1)

What changes (brief: docs/gala_exes_art_brief.md section 2):
  navy suit      -> emerald velvet tuxedo (5-step ramp keyed off the old shading)
  long red tie   -> small black bow tie, white shirt V, black satin lapels, jacket closes below
  thick moustache-> thin pencil line
  plain eyes     -> tiny rectangular glasses (front + side rows)
  hair           -> wet-look shine streak along the slicked top
  wrists         -> big gold smartwatch on one wrist, gold cufflink on the other
  attack column  -> pointing hand replaced by a dark card-reader tablet (three blank rounded
                    buttons, no text) swung toward the facing direction with a white-yellow glare
Grid, frame count, figure size/position and foot line are unchanged; alpha stays 0/255.
"""
import os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BASE = os.path.join(ROOT, "assets/art/ch_donald.png")
PORTRAIT = os.path.join(ROOT, "assets/art/portraits_hd/bozos.png")
OUT = os.path.join(ROOT, "grok_art/2026-11-10-gala-exes/sheet_bozos.png")
CMP = os.path.join(ROOT, "docs/renders/sheet_bozos_compare.png")
CELL = 64

# ---------------------------------------------------------------- palette
OUTL = (16, 18, 20)
E = [(8, 30, 22), (13, 60, 41), (19, 90, 61), (28, 120, 80), (46, 148, 98)]  # emerald velvet ramp
LAPEL = (20, 20, 24)
LAPEL_HI = (68, 72, 80)
SHIRT = (244, 244, 236)
SHIRT_SH = (190, 192, 196)
BOW = (14, 14, 18)
BOW_HI = (78, 80, 90)
GOLD = (236, 186, 46)
GOLD_DK = (150, 100, 20)
GOLD_HI = (255, 240, 150)
WATCH_FACE = (30, 34, 40)
GLASS = (24, 24, 30)
LENS_HI = (196, 228, 240)
TAB = (30, 32, 38)
TAB_EDGE = (62, 66, 76)
TAB_SCR = (40, 58, 84)
TAB_BTN = (112, 144, 186)
GLARE_W = (255, 255, 255)
GLARE_Y = (255, 238, 120)
HAIR_SHINE = (118, 128, 148)
HAIR_SHINE2 = (70, 76, 90)
STACHE = (40, 24, 18)


def cell(img, r, c):
    return img[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL]


def put(px, x, y, col):
    if 0 <= x < CELL and 0 <= y < CELL:
        px[y, x, :3] = col
        px[y, x, 3] = 255


def clear(px, x, y):
    if 0 <= x < CELL and 0 <= y < CELL:
        px[y, x] = (0, 0, 0, 0)


def opaque(px, x, y):
    return 0 <= x < CELL and 0 <= y < CELL and px[y, x, 3] > 0


# ---------------------------------------------------------------- global masks
def suit_mask(px):
    r, g, b, a = [px[..., i].astype(int) for i in range(4)]
    return (a > 0) & (b > r + 15) & (b > g + 10)


def tie_mask(px, y0):
    r, g, b, a = [px[..., i].astype(int) for i in range(4)]
    m = (a > 0) & (r >= 40) & (g < 0.35 * r) & (b < 0.4 * r)
    # gold/orange emblem printed on the tie
    emb = (a > 0) & (r > 190) & (b < 40)
    m = m | emb
    m[:y0] = False
    return m


def skin_mask(px):
    r, g, b, a = [px[..., i].astype(int) for i in range(4)]
    return (a > 0) & (r > 150) & (g > 90) & (r > g + 40) & (b > 30)


def recolour_suit(px):
    m = suit_mask(px)
    v = px[..., :3].max(-1).astype(int)
    out = px.copy()
    steps = [(36, E[0]), (60, E[1]), (78, E[2]), (92, E[3]), (999, E[4])]
    for y, x in zip(*np.nonzero(m)):
        for lim, col in steps:
            if v[y, x] < lim:
                out[y, x, :3] = col
                break
    return out


def hair_shine(px, y_max, x_lo=0, x_hi=CELL):
    """Wet-look streak 2 px under the top silhouette of the hair."""
    r, g, b, a = [px[..., i].astype(int) for i in range(4)]
    v = np.maximum(np.maximum(r, g), b)
    sat = v - np.minimum(np.minimum(r, g), b)
    hair = (a > 0) & (v < 75) & (sat < 30)
    cols = [x for x in range(x_lo, x_hi) if hair[:y_max, x].any()]
    if not cols:
        return
    x0, x1 = cols[0], cols[-1]
    w = x1 - x0 + 1
    for x in cols:
        t = (x - x0) / max(1, w - 1)
        if t < 0.18 or t > 0.85:
            continue
        top = int(np.argmax(a[:y_max, x] > 0))
        for dy, col in ((2, HAIR_SHINE), (3, HAIR_SHINE2)):
            y = top + dy
            if y < y_max and hair[y, x]:
                if dy == 3 and (x % 3 == 0):
                    continue
                put(px, x, y, col)


# ---------------------------------------------------------------- tuxedo
BOW_SHAPE = ["BB.W.BB", "BBBKBBB", "BB.W.BB"]


def tux_front(px, tie_y0, close_y, x_lo=0, x_hi=CELL):
    """Front / three-quarter chest: long tie -> bow tie, white shirt V, black satin lapels."""
    m = tie_mask(px, tie_y0)
    m[:, :x_lo] = False
    m[:, x_hi:] = False
    ys, xs = np.nonzero(m)
    top = int(ys.min())
    cx = int(round(xs[ys <= top + 2].mean()))
    for y, x in zip(ys, xs):
        put(px, x, y, LAPEL if y <= close_y else E[3])
    # collar band either side of the bow
    for y in range(top, top + 3):
        for s in (-1, 1):
            for k in (4, 5):
                if opaque(px, cx + s * k, y):
                    put(px, cx + s * k, y, SHIRT if k == 4 or y > top else SHIRT_SH)
    # bow tie
    for j, row in enumerate(BOW_SHAPE):
        for i, ch in enumerate(row):
            x, y = cx - 3 + i, top + j
            put(px, x, y, {"B": BOW, "K": (48, 48, 56), "W": SHIRT, ".": BOW}[ch])
    put(px, cx - 3, top, BOW_HI)
    put(px, cx + 2, top, BOW_HI)
    # shirt V narrowing to the button, black satin lapels hugging it
    y0 = top + 3
    for y in range(y0, close_y + 1):
        t = (y - y0) / max(1, close_y - y0)
        hw = int(round(3 * (1 - t)))
        for x in range(cx - hw, cx + hw + 1):
            put(px, x, y, SHIRT)
        if hw >= 1:
            put(px, cx + hw, y, SHIRT_SH)
        for s in (-1, 1):
            for k in (1, 2):
                x = cx + s * (hw + k)
                if opaque(px, x, y):
                    put(px, x, y, LAPEL_HI if (k == 2 and y % 3 == 0) else LAPEL)
    for y in (y0 + 2, y0 + 5):
        if y < close_y - 1:
            put(px, cx, y, SHIRT_SH)
    put(px, cx, close_y + 1, GOLD_DK)
    for y in range(close_y + 2, int(ys.max()) + 1):
        if m[y, cx]:
            put(px, cx, y, E[1])
    return cx


def tux_side(px, tie_y0, close_y, f):
    """Profile chest (f=+1 faces screen-right, -1 left). The hanging tie and its outline are cut
    away; what stays is a 1 px shirt front, a small bow at the collar, and a re-inked edge."""
    m = tie_mask(px, tie_y0)
    ys, xs = np.nonzero(m)
    top, bot = int(ys.min()), int(ys.max())
    v = px[..., :3].max(-1).astype(int)
    ring = np.zeros_like(m)
    for y, x in zip(ys, xs):
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                yy, xx = y + dy, x + dx
                if 0 <= yy < CELL and 0 <= xx < CELL and px[yy, xx, 3] and not m[yy, xx] and v[yy, xx] < 90:
                    ring[yy, xx] = True
    region = m | ring
    for y in range(max(0, top - 1), min(CELL, bot + 2)):
        body = [x for x in range(CELL) if px[y, x, 3] and not region[y, x]]
        if not body:
            front = None
        else:
            front = max(body) if f > 0 else min(body)
        ahead = [x for x in range(CELL) if region[y, x] and (front is None or f * (x - front) > 0)]
        ahead.sort(key=lambda x: f * x)
        for i, x in enumerate(ahead):
            if y <= close_y:
                col = SHIRT if i == 0 else OUTL if i == 1 else None
            else:
                col = OUTL if i == 0 and front is not None and m[y, x] else None
            if col is None:
                clear(px, x, y)
            else:
                put(px, x, y, col)
        # any tie pixel left behind the body edge becomes lapel
        for x in range(CELL):
            if m[y, x] and px[y, x, 3] and x not in ahead:
                put(px, x, y, LAPEL)
    return top


# ---------------------------------------------------------------- accessories
def watch(px, x, y, w=3, h=2):
    """Gold smartwatch block with a dark face, top-left at (x, y)."""
    for j in range(h):
        for i in range(w):
            put(px, x + i, y + j, GOLD)
    put(px, x, y, GOLD_HI)
    put(px, x + w - 1, y + h - 1, GOLD_DK)
    if w >= 3:
        put(px, x + 1, y + (1 if h > 2 else 0), WATCH_FACE)


def cufflink(px, x, y):
    put(px, x, y, GOLD)


# ---------------------------------------------------------------- tablet
def tablet(px, x0, y0, w, h, screen=True):
    """Card-reader tablet: dark body, outline, screen with three blank rounded buttons."""
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            edge = x in (x0, x0 + w - 1) or y in (y0, y0 + h - 1)
            put(px, x, y, OUTL if edge else TAB)
    for x in range(x0 + 1, x0 + w - 1):
        put(px, x, y0 + 1, TAB_EDGE)
    if not screen:
        return
    sx0, sy0, sx1, sy1 = x0 + 2, y0 + 2, x0 + w - 3, y0 + h - 3
    for y in range(sy0, sy1 + 1):
        for x in range(sx0, sx1 + 1):
            put(px, x, y, TAB_SCR)
    # three blank buttons: rounded bars (ends left as screen colour)
    bh = 1
    n = 3
    span = sy1 - sy0 + 1
    gap = max(1, (span - n * bh) // (n + 1))
    y = sy0 + gap
    for _ in range(n):
        for x in range(sx0 + 1, sx1):
            put(px, x, y, TAB_BTN)
        y += bh + gap


def glare(px, cx, cy, size=3):
    put(px, cx, cy, GLARE_W)
    for d in range(1, size + 1):
        col = GLARE_W if d == 1 else GLARE_Y
        for dx, dy in ((d, 0), (-d, 0), (0, d), (0, -d)):
            put(px, cx + dx, cy + dy, col)
    for dx, dy in ((1, 1), (-1, -1), (1, -1), (-1, 1)):
        put(px, cx + dx, cy + dy, GLARE_Y)


def erase(px, box):
    x0, y0, x1, y1 = box
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            clear(px, x, y)


# ---------------------------------------------------------------- face templates
SKIN = (240, 164, 90)
SKIN_SH = (196, 114, 60)
LID = (176, 98, 54)
EYE_W = (246, 242, 234)
PUPIL = (22, 18, 18)
BROW = (30, 22, 20)
LIP = (128, 52, 44)


def clean_box(px, x0, y0, x1, y1):
    """Turn every non-skin pixel inside the box into the neighbouring skin tone."""
    sk = skin_mask(px)
    base = sk.copy()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if px[y, x, 3] == 0 or base[y, x]:
                continue
            col = None
            for d in range(1, 8):
                for xx, yy in ((x - d, y), (x + d, y), (x, y - d), (x, y + d)):
                    if 0 <= xx < CELL and 0 <= yy < CELL and base[yy, xx]:
                        col = tuple(int(c) for c in px[yy, xx, :3])
                        break
                if col:
                    break
            put(px, x, y, col or SKIN)


def plot(px, ox, oy, pts, col, f=1):
    for dx, dy in pts:
        put(px, ox + f * dx, oy + dy, col)


def front_face(px, ox, oy, angry=False, mouth=True, stache_dy=6):
    """Origin = top-left of the left lens frame. Lenses 5x4, 2 px bridge gap."""
    for lx in (0, 7):
        plot(px, ox + lx, oy, [(i, 0) for i in range(5)] + [(i, 3) for i in range(5)]
             + [(0, 1), (0, 2), (4, 1), (4, 2)], GLASS)
        plot(px, ox + lx, oy, [(1, 1), (2, 1), (3, 1)], LID)
        plot(px, ox + lx, oy, [(1, 2), (3, 2)], EYE_W)
        plot(px, ox + lx, oy, [(2, 2)], PUPIL)
        if not angry:
            plot(px, ox + lx, oy, [(1, 1)], LENS_HI)
    plot(px, ox, oy, [(5, 1), (6, 1), (-1, 1), (12, 1)], GLASS)
    if angry:
        plot(px, ox, oy, [(0, -3), (1, -3), (2, -2), (3, -2), (8, -2), (9, -2), (10, -3), (11, -3)], BROW)
    else:
        plot(px, ox, oy, [(1, -2), (2, -2), (3, -2), (4, -2), (7, -2), (8, -2), (9, -3), (10, -3), (11, -3)], BROW)
    # nose
    plot(px, ox, oy, [(6, 4), (5, 5), (6, 5)], SKIN_SH)
    # pencil moustache: thin line, tiny philtrum gap, tips flick up
    plot(px, ox, oy, [(i, stache_dy) for i in (2, 3, 4, 5, 7, 8, 9, 10)] + [(1, stache_dy - 1), (11, stache_dy - 1)], STACHE)
    if mouth:
        plot(px, ox, oy, [(4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 7)], LIP)


def side_face(px, E, M, f, mouth=True, clean_mouth=(1, 2)):
    """f=+1 faces screen-right, -1 screen-left. E = front-most eye pixel, M = front end of the
    pencil moustache (one px inside the profile edge)."""
    ex, ey = E
    mx, my = M
    xs = sorted((ex - 4 * f, ex + 2 * f))
    clean_box(px, xs[0], ey - 3, xs[1], ey + 1)
    xs = sorted((mx, mx - 4 * f))
    clean_box(px, xs[0], my - clean_mouth[0], xs[1], my + clean_mouth[1])
    plot(px, ex, ey, [(-2, -3), (-1, -3), (0, -3), (1, -4)], BROW, f)
    rect = [(i, -1) for i in range(-2, 3)] + [(i, 1) for i in range(-2, 3)] + [(-2, 0), (2, 0)]
    plot(px, ex, ey, rect, GLASS, f)
    plot(px, ex, ey, [(-6, -1), (-5, -1), (-4, -1), (-3, -1)], GLASS, f)
    plot(px, ex, ey, [(-1, 0), (0, 0)], EYE_W, f)
    plot(px, ex, ey, [(1, 0)], PUPIL, f)
    plot(px, mx, my, [(0, 0), (-1, 0), (-2, 0), (-3, -1)], STACHE, f)
    plot(px, mx, my, [(0, -1)], SKIN_SH, f)
    if mouth:
        plot(px, mx, my, [(0, 2), (-1, 2), (-2, 1)], LIP, f)


def drop_specks(px, min_size=20):
    """Remove small islands of opaque pixels (leftover tie outline) not attached to the figure."""
    a = px[..., 3] > 0
    seen = np.zeros_like(a)
    for y0 in range(CELL):
        for x0 in range(CELL):
            if not a[y0, x0] or seen[y0, x0]:
                continue
            comp, stack = [], [(y0, x0)]
            seen[y0, x0] = True
            while stack:
                y, x = stack.pop()
                comp.append((y, x))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < CELL and 0 <= xx < CELL and a[yy, xx] and not seen[yy, xx]:
                            seen[yy, xx] = True
                            stack.append((yy, xx))
            if len(comp) < min_size:
                for y, x in comp:
                    clear(px, x, y)


def side_bow(px, kx, ky, f):
    """Bow tie seen from the side, knot at (kx, ky), wings flaring toward the facing side."""
    plot(px, kx, ky, [(-1, -2), (0, -2), (-1, 2), (0, 2)], SHIRT, f)
    plot(px, kx, ky, [(0, -1), (1, -1), (2, -1), (1, 0), (0, 1), (1, 1), (2, 1)], BOW, f)
    plot(px, kx, ky, [(0, 0)], (56, 56, 64), f)
    plot(px, kx, ky, [(2, 0)], OUTL, f)
    plot(px, kx, ky, [(2, -1)], BOW_HI, f)


# ---------------------------------------------------------------- per-cell edits
def build():
    src = np.array(Image.open(BASE).convert("RGBA"))
    assert src.shape == (256, 256, 4)
    img = src.copy()
    for R in range(4):
        for C in range(4):
            px = cell(img, R, C)
            px[...] = recolour_suit(px)
    for R in range(4):
        for C in range(4):
            edit_cell(cell(img, R, C), R, C)
    a = img[..., 3]
    img[a < 128] = 0
    img[..., 3][img[..., 3] >= 128] = 255
    return src, img


FRONT_FACE = {0: (26, 20), 1: (28, 20), 2: (28, 20)}
SIDE_R = {0: ((36, 20), (40, 24)), 1: ((36, 20), (40, 24)), 2: ((37, 20), (41, 24))}
SIDE_L = {0: ((30, 20), (26, 24)), 1: ((30, 20), (26, 24)), 2: ((29, 20), (25, 24))}
# wrists: big gold watch on HIS LEFT wrist, white cuff + gold cufflink on his right
WRIST = {
    (0, 0): dict(watch=(45, 46), cuff=(14, 17, 46), link=(15, 46)),
    (0, 1): dict(watch=(46, 42), cuff=(16, 20, 44), link=(18, 44)),
    (0, 2): dict(watch=(46, 42), cuff=(16, 20, 44), link=(18, 44)),
    (0, 3): dict(watch=(42, 39, 2, 3)),
    (2, 3): dict(watch=(46, 31, 2, 3)),
    (3, 3): dict(cuffv=(16, 31, 33), link=(16, 32)),
    (1, 0): dict(watch=(14, 45), cuff=(43, 47, 45), link=(45, 45)),
    (1, 1): dict(watch=(16, 43), cuff=(44, 48, 43), link=(46, 43)),
    (1, 2): dict(watch=(16, 43), cuff=(45, 48, 43), link=(47, 43)),
    (2, 0): dict(watch=(23, 44)),
    (2, 1): dict(watch=(17, 41)),
    (2, 2): dict(watch=(17, 41)),
    (3, 1): dict(cuffv=(46, 42, 44), link=(46, 43)),
    (3, 2): dict(cuffv=(46, 42, 44), link=(46, 43)),
    (3, 0): dict(cuff=(39, 44, 44), link=(41, 44)),
}

# attack column: (erase box, tablet x, y, w, h, screen?, glare centre, grip pixels, facing)
ATTACK = {
    0: dict(erase=None, tab=(14, 32, 13, 10, True), glare=(14, 32), grip=[(26, 36), (26, 37), (26, 38)]),
    1: dict(erase=(50, 27, 57, 36), tab=(50, 25, 6, 12, False), glare=(57, 28), grip=[(50, 30), (50, 31)]),
    2: dict(erase=(48, 29, 57, 36), tab=(50, 26, 10, 10, True), glare=(59, 26),
            hand=[(48, 31), (49, 31), (48, 32), (49, 32), (48, 33), (49, 33)], grip=[(50, 31), (50, 32)]),
    3: dict(erase=(4, 29, 17, 36), tab=(4, 26, 10, 10, True), glare=(4, 26),
            hand=[(15, 31), (14, 31), (15, 32), (14, 32), (15, 33), (14, 33)], grip=[(13, 31), (13, 32)]),
}


def wrists(px, R, C):
    w = WRIST.get((R, C))
    if not w:
        return
    if "cuff" in w:
        x0, x1, y = w["cuff"]
        for x in range(x0, x1 + 1):
            put(px, x, y, SHIRT)
    if "cuffv" in w:
        x, y0, y1 = w["cuffv"]
        for y in range(y0, y1 + 1):
            put(px, x, y, SHIRT)
    if "link" in w:
        cufflink(px, *w["link"])
    if "watch" in w:
        watch(px, *w["watch"])


def swing_tablet(px, R):
    a = ATTACK[R]
    if a["erase"]:
        erase(px, a["erase"])
    hand = a.get("hand", [])
    for x, y in hand:
        put(px, x, y, SKIN if (x + y) % 2 else SKIN_SH)
    if hand:
        xs = sorted({x for x, _ in hand})
        ys = [y for _, y in hand]
        for x in xs:
            put(px, x, min(ys) - 1, OUTL)
            put(px, x, max(ys) + 1, OUTL)
    tablet(px, *a["tab"])
    for i, (x, y) in enumerate(a["grip"]):
        put(px, x, y, SKIN if i % 2 == 0 else SKIN_SH)
    glare(px, *a["glare"])


def edit_cell(px, R, C):
    if R == 0:
        if C == 3:
            tux_front(px, 34, 46)
            clean_box(px, 27, 20, 41, 29)
            front_face(px, 29, 23, angry=True, mouth=False, stache_dy=5)
        else:
            tux_front(px, 31, 45)
            ox, oy = FRONT_FACE[C]
            clean_box(px, ox - 1, oy - 2, ox + 13, oy + 8)
            front_face(px, ox, oy)
        hair_shine(px, 18)
    elif R == 1:
        hair_shine(px, 24)
    elif R == 2:
        if C == 3:
            tux_front(px, 32, 45, 28, 42)
            side_face(px, (35, 23), (39, 27), +1, mouth=False, clean_mouth=(1, 1))
        else:
            tux_side(px, 30, 44, +1)
            side_face(px, *SIDE_R[C], +1)
            side_bow(px, 38, 32, +1)
        hair_shine(px, 18)
    elif R == 3:
        if C == 3:
            tux_front(px, 32, 45, 24, 40)
            side_face(px, (31, 23), (27, 27), -1, mouth=False, clean_mouth=(1, 1))
        else:
            tux_side(px, 30, 44, -1)
            side_face(px, *SIDE_L[C], -1)
            side_bow(px, 28, 32, -1)
        hair_shine(px, 18)
    drop_specks(px)
    if C == 3:
        swing_tablet(px, R)
    wrists(px, R, C)


def compare(src, out):
    S = 4
    def boarded(a):
        im = Image.fromarray(a, "RGBA")
        bg = Image.new("RGBA", im.size, (128, 128, 128, 255))
        bg.alpha_composite(im)
        return bg.resize((256 * S, 256 * S), Image.NEAREST)
    p = Image.open(PORTRAIT).convert("RGBA").crop((0, 0, 512, 512))
    ph = 256 * S
    pbg = Image.new("RGBA", p.size, (128, 128, 128, 255))
    pbg.alpha_composite(p)
    pbg = pbg.resize((ph, ph), Image.LANCZOS)
    pad = 16
    W = 256 * S * 2 + ph + pad * 4
    sheet = Image.new("RGBA", (W, 256 * S + pad * 2), (60, 60, 60, 255))
    sheet.paste(boarded(src), (pad, pad))
    sheet.paste(boarded(out), (pad * 2 + 256 * S, pad))
    sheet.paste(pbg, (pad * 3 + 256 * S * 2, pad))
    sheet.convert("RGB").save(CMP)


def main():
    src, out = build()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    os.makedirs(os.path.dirname(CMP), exist_ok=True)
    Image.fromarray(out, "RGBA").save(OUT)
    compare(src, out)
    print("wrote", os.path.relpath(OUT, ROOT))
    print("wrote", os.path.relpath(CMP, ROOT))


if __name__ == "__main__":
    main()
