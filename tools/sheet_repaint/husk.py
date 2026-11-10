#!/usr/bin/env python3
"""Repaint the old ch_husk.png placeholder into Tyler Pivot (internal id `husk`, cast token gala_ex_1).

Deterministic, no network, PIL + numpy only. Run from the repo root:
    python3 tools/sheet_repaint/husk.py

Reads   assets/art/ch_husk.png                         (old placeholder: goggles, silver jacket, jetpack, hand blast)
Writes  grok_art/2026-11-10-gala-exes/sheet_husk.png   (master: 256x256 RGBA, 4x4 cells of 64x64, hard alpha)
        docs/renders/sheet_husk_compare.png            (old | new at 4x nearest on grey, + portrait panel 1)

Rows: front, back, facing screen-right, facing screen-left.  Cols: stand, walk 1, walk 2, attack.
Figure size, position and foot line are untouched (the silhouette only loses the jetpack).

Per cell:
  * goggles      -> painted over with hair (luma mapped onto a brown ramp)
  * jetpack      -> erased on the side rows (new back edge re-outlined); flattened into a plain blazer back
                    with a vent on the back row
  * silver jacket-> open slim MUSTARD blazer (luma mapped, lightly de-noised); the centre / front strip is
                    repainted as the cream oversized hoodie, with its hood drawn round the neck / on the back
  * lanyard + blank white badge on the hoodie; white earbuds; white grin on the stand/walk faces
  * jeans        -> black joggers;  shoes -> chunky white sneakers
  * attack       -> the hand blast becomes a dark phone on a gimbal handle firing a CYAN flash (hot-pink sparks)
Every output colour comes from the fixed ramps below; nothing is blended, alpha is 0 or 255.
"""
import os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BASE = os.path.join(ROOT, "assets/art/ch_husk.png")
OUT = os.path.join(ROOT, "grok_art/2026-11-10-gala-exes/sheet_husk.png")
CMP = os.path.join(ROOT, "docs/renders/sheet_husk_compare.png")
PORTRAIT = os.path.join(ROOT, "assets/art/portraits_hd/husk.png")

# ------------------------------------------------------------------ ramps (dark -> light)
OUTLINE = (22, 14, 18)
MUSTARD = [(92, 60, 10), (146, 100, 18), (196, 146, 32), (228, 182, 56), (248, 214, 110)]
CREAM = [(150, 128, 100), (196, 180, 148), (228, 216, 186), (248, 241, 220)]
JOGGER = [(16, 16, 22), (30, 30, 38), (46, 46, 58), (66, 66, 82)]
SNEAKER = [(160, 160, 170), (208, 208, 214), (236, 236, 238), (253, 253, 251)]
HAIR = [(40, 25, 12), (64, 41, 18), (90, 57, 24), (118, 76, 31)]
CYAN = [(0, 140, 182), (34, 212, 240), (156, 246, 255), (255, 255, 255)]
PINK = [(230, 40, 150), (255, 112, 198)]
PHONE = [(12, 14, 22), (36, 40, 54), (74, 80, 100)]
LANYARD = (26, 30, 52)
BADGE = (252, 252, 248)
BADGE_RIM = (150, 156, 176)
TEETH = (252, 252, 248)
LIP = (132, 64, 32)
BUD = (250, 250, 250)

# ------------------------------------------------------------------ per-cell layout (cell-local coords)
# gog   : goggle pixels live above this y (grey there -> hair)
# neck/waist/shoe : first y of torso / legs / shoe zone
# jet   : (x0, x1, y0, y1) jetpack box erased on side rows
# blast : (x0, x1) burst columns;  phone : (x0, x1, y0, y1)
F = dict(kind="front", gog=21, neck=34, waist=48, shoe=57)
B = dict(kind="back", gog=0, neck=31, waist=48, shoe=57)
R = dict(kind="right", gog=19, gog_far=24, neck=31, waist=47, shoe=55, jet=(14, 24, 30, 46))
L = dict(kind="left", gog=19, gog_far=24, neck=31, waist=47, shoe=55, jet=(41, 50, 30, 46))
CELLS = {
    (0, 0): F, (0, 1): F, (0, 2): F,
    (0, 3): dict(kind="front", gog=26, neck=40, collar=((20, 29, 34, 39), (39, 47, 34, 39)), waist=50, shoe=57, blast=(48, 63), phone=(43, 48, 31, 38)),
    (1, 0): B, (1, 1): B, (1, 2): B,
    (1, 3): dict(kind="back", gog=29, neck=32, waist=48, shoe=56, blast=(48, 63), phone=(43, 48, 30, 37)),
    (2, 0): R, (2, 1): R, (2, 2): R,
    (2, 3): dict(kind="right", gog=23, gog_far=29, neck=34, waist=48, shoe=55, jet=(10, 22, 31, 48),
                 blast=(48, 63), phone=(43, 48, 30, 37)),
    (3, 0): L, (3, 1): L, (3, 2): L,
    (3, 3): dict(kind="left", gog=23, gog_far=29, neck=34, waist=48, shoe=55, jet=(44, 54, 31, 48),
                 blast=(0, 15), phone=(15, 21, 30, 37)),
}


def luma(p):
    return 0.299 * float(p[0]) + 0.587 * float(p[1]) + 0.114 * float(p[2])


def ramp(r, l, lo, hi):
    t = (l - lo) / max(1.0, hi - lo)
    return r[max(0, min(len(r) - 1, int(t * len(r))))]


def is_skin(p):
    r, g, b = int(p[0]), int(p[1]), int(p[2])
    return r > 150 and r - b > 60 and g > 70 and r >= g and g > b + 15


def is_fringe(p):
    r, g, b = int(p[0]), int(p[1]), int(p[2])
    return luma(p) < 90 and r > g + 12 and b > g + 12


def is_grey(p):
    return int(max(p[:3])) - int(min(p[:3])) < 46


def is_warm(p):
    return int(p[0]) > int(p[2]) + 8


def inbox(x, y, b):
    return b is not None and b[0] <= x <= b[1] and b[2] <= y <= b[3]


class Cell:
    def __init__(self, arr):
        self.a = arr
        # skin is judged on the ORIGINAL pixels (mustard would pass a colour test)
        self.skin_mask = np.zeros((64, 64), bool)
        for y in range(64):
            for x in range(64):
                self.skin_mask[y, x] = arr[y, x, 3] > 0 and is_skin(arr[y, x])

    def skin(self, x, y):
        return 0 <= x < 64 and 0 <= y < 64 and self.skin_mask[y, x]

    def op(self, x, y):
        return 0 <= x < 64 and 0 <= y < 64 and self.a[y, x, 3] > 0

    def put(self, x, y, col):
        if 0 <= x < 64 and 0 <= y < 64:
            self.a[y, x, :3] = col
            self.a[y, x, 3] = 255

    def tint(self, x, y, col):
        """Recolour only if already opaque."""
        if self.op(x, y):
            self.a[y, x, :3] = col

    def erase(self, x, y):
        if 0 <= x < 64 and 0 <= y < 64:
            self.a[y, x] = 0

    def edge(self, x, y):
        if not self.op(x, y):
            return False
        return any(not self.op(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))


# ------------------------------------------------------------------ pass 1: material recolour
def recolour(cell, cfg):
    src = cell.a.copy()
    kind = cfg["kind"]
    bx, ph, jet = cfg.get("blast"), cfg.get("phone"), cfg.get("jet")
    op = src[..., 3] > 0

    # jetpack erase (side rows); keeps skin (hands) and anything in the phone/blast area
    if jet:
        for y in range(jet[2], jet[3] + 1):
            for x in range(jet[0], jet[1] + 1):
                if not op[y, x] or inbox(x, y, ph) or (bx and bx[0] <= x <= bx[1]):
                    continue
                if is_skin(src[y, x]):
                    continue
                cell.erase(x, y)
        op = cell.a[..., 3] > 0

    near_skin = np.zeros((64, 64), bool)  # within 2 px of skin (protects eye whites / teeth)
    for y in range(64):
        for x in range(64):
            if op[y, x] and is_skin(src[y, x]):
                near_skin[max(0, y - 2):y + 3, max(0, x - 2):x + 3] = True

    # luma, de-noised for cloth (3x3 mean over cloth pixels, blended 50/50 with the original)
    lum = np.zeros((64, 64))
    for y in range(64):
        for x in range(64):
            lum[y, x] = luma(src[y, x])
    cloth = np.zeros((64, 64), bool)
    for y in range(cfg["neck"], cfg["shoe"]):
        for x in range(64):
            if op[y, x] and lum[y, x] >= 26 and not is_skin(src[y, x]) and not is_fringe(src[y, x]):
                cloth[y, x] = True
    sm = lum.copy()
    for y in range(64):
        for x in range(64):
            if cloth[y, x]:
                ys, xs = slice(max(0, y - 1), y + 2), slice(max(0, x - 1), x + 2)
                m = cloth[ys, xs]
                sm[y, x] = 0.5 * lum[y, x] + 0.5 * lum[ys, xs][m].mean()

    for y in range(64):
        for x in range(64):
            if not op[y, x]:
                continue
            p = src[y, x]
            l = lum[y, x]
            # blast burst
            if bx and bx[0] <= x <= bx[1] and not inbox(x, y, ph) and not is_skin(p):
                r, g, b = int(p[0]), int(p[1]), int(p[2])
                if l < 40:
                    cell.a[y, x, :3] = CYAN[0]
                elif l > 205:
                    cell.a[y, x, :3] = CYAN[3] if l > 235 else CYAN[2]
                elif r >= g - 6 and b > g:  # lavender sparks -> hot pink
                    cell.a[y, x, :3] = PINK[1] if l > 150 else PINK[0]
                else:
                    cell.a[y, x, :3] = CYAN[1] if l > 150 else CYAN[0]
                continue
            # stray burst sparks outside the burst columns (lavender / ice blue)
            if bx and not inbox(x, y, ph) and not is_skin(p):
                r, g, b = int(p[0]), int(p[1]), int(p[2])
                if l > 60 and b > g + 25 and r > g:
                    cell.a[y, x, :3] = PINK[1] if l > 150 else PINK[0]
                    continue
                if l > 120 and b > r + 50 and g > r + 30:
                    cell.a[y, x, :3] = CYAN[1]
                    continue
            # phone
            if inbox(x, y, ph) and not is_skin(p):
                cell.a[y, x, :3] = PHONE[0] if l < 60 else (PHONE[1] if l < 120 else PHONE[2])
                continue
            if is_fringe(p):
                continue
            # head
            if y < cfg["neck"]:
                if any(inbox(x, y, cb) for cb in cfg.get("collar", ())) and is_grey(p) and l >= 30:
                    cell.a[y, x, :3] = ramp(CREAM, l, 30, 200)  # old jacket collar -> hood round the neck
                elif is_grey(p) and l >= 30 and not is_skin(p) and (
                        y < cfg["gog"] or (y < cfg.get("gog_far", 0) and not near_skin[y, x])):
                    cell.a[y, x, :3] = ramp(HAIR, l, 30, 230)  # goggles / goggle strap -> hair
                continue
            # hands / skin
            if is_skin(p) and y < cfg["waist"] + 4:
                continue
            # torso
            if y < cfg["waist"]:
                if l < 26:
                    continue
                cell.a[y, x, :3] = ramp(MUSTARD, sm[y, x], 30, 220)
                continue
            # legs + shoes
            if l < 22:
                continue
            shoe_zone = y >= cfg["shoe"] or (y >= cfg["shoe"] - 4 and is_warm(p) and l > 45)
            if shoe_zone:
                if l < 30:
                    continue
                cell.a[y, x, :3] = ramp(SNEAKER, l, 30, 165)
            else:
                cell.a[y, x, :3] = ramp(JOGGER, l, 22, 140)

    if jet:
        for y in range(jet[2] - 1, jet[3] + 2):
            for x in range(jet[0] - 3, jet[1] + 3):
                if cell.edge(x, y) and not inbox(x, y, ph) and not cell.skin(x, y) \
                        and luma(cell.a[y, x]) > 45 and not is_fringe(cell.a[y, x]):
                    cell.a[y, x, :3] = OUTLINE


# ------------------------------------------------------------------ pass 2: hand-drawn details
def fill(cell, x0, x1, y0, y1, shade, keep_edge=True):
    """Repaint opaque, non-skin pixels inside the box with shade(x, y); silhouette edge stays outline."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if not cell.op(x, y) or cell.skin(x, y):
                continue
            if keep_edge and cell.edge(x, y):
                cell.a[y, x, :3] = OUTLINE
                continue
            cell.a[y, x, :3] = shade(x, y)


def hoodie_front(cell, x0, x1, y0, y1):
    """Cream hoodie front between the open blazer lapels, lanyard and blank badge."""
    def sh(x, y):
        if y >= y1 - 1:
            return CREAM[1]
        if x in (x0, x1):
            return CREAM[1]
        return CREAM[3] if y <= y0 + 2 else CREAM[2]
    fill(cell, x0, x1, y0, y1, sh)
    # lapels: dark mustard line just outside the hoodie
    for y in range(y0, y1 + 1):
        cell.tint(x0 - 1, y, MUSTARD[0])
        cell.tint(x1 + 1, y, MUSTARD[0])
    # lanyard: thin V converging over 4 rows, then a blank white badge with a soft grey rim
    cx = (x0 + x1) // 2  # left of the two centre columns
    for i, y in enumerate(range(y0, y0 + 4)):
        cell.tint(x0 + 1 + i // 2, y, LANYARD)
        cell.tint(x1 - 1 - i // 2, y, LANYARD)
    by = y0 + 4
    for y in range(by, by + 4):
        for x in range(cx - 1, cx + 3):
            rim = y == by + 3 or x in (cx - 1, cx + 2)
            cell.tint(x, y, BADGE_RIM if rim else BADGE)


def hood_collar_front(cell, x0, x1, y):
    """Hood bunched round the neck: two rows of cream on the shoulders, skin (neck/chin) untouched."""
    for x in range(x0, x1 + 1):
        for yy, col in ((y, CREAM[3]), (y + 1, CREAM[2])):
            if cell.op(x, yy) and not cell.skin(x, yy) and not cell.edge(x, yy):
                cell.a[yy, x, :3] = col


def blazer_back(cell, x0, x1, y0, y1, vent_x):
    def sh(x, y):
        if x == vent_x and y >= y1 - 5:
            return MUSTARD[0]
        if y >= y1 - 1 or x in (x0, x1):
            return MUSTARD[1]
        if y0 + 4 <= y <= y0 + 7 and (x0 + 2 <= x <= vent_x - 2 or vent_x + 2 <= x <= x1 - 2):
            return MUSTARD[3]
        return MUSTARD[2]
    fill(cell, x0, x1, y0, y1, sh)


def hood_back(cell, cx, y0):
    """Cream hood lying on the upper back, centred on cx, starting under the hair at y0."""
    rows = [(-5, 4), (-5, 4), (-4, 3), (-3, 2), (-2, 1)]
    for i, (a, b) in enumerate(rows):
        y = y0 + i
        for x in range(cx + a, cx + b + 1):
            if not cell.op(x, y):
                continue
            if i == len(rows) - 1 or x in (cx + a, cx + b):
                col = CREAM[1]
            else:
                col = CREAM[3] if i < 2 else CREAM[2]
            cell.a[y, x, :3] = col
        # dark under-shadow row
    for x in range(cx - 1, cx + 1):
        cell.tint(x, y0 + len(rows), MUSTARD[0])


def hoodie_side(cell, x0, x1, y0, y1, facing):
    """Front strip of the cream hoodie showing past the open blazer, with lanyard + badge."""
    front = x1 if facing == "right" else x0
    back = x0 if facing == "right" else x1
    def sh(x, y):
        if y >= y1 - 1 or x == back:
            return CREAM[1]
        return CREAM[2] if abs(x - front) == 1 else CREAM[3]
    fill(cell, x0, x1, y0, y1, sh)
    step = -1 if facing == "right" else 1
    lap = back + step
    for y in range(y0, y1 + 1):
        cell.tint(lap, y, MUSTARD[0])  # blazer lapel edge, just behind the strip
    lx = back - step  # lanyard column, inside the strip
    bt = min(y0 + 4, y1 - 3)  # badge top; the badge never hangs below the strip
    for y in range(y0, bt):
        cell.tint(lx, y, LANYARD)
    for y in range(bt, bt + 4):
        for x in (lx, lx - step):
            cell.tint(x, y, BADGE_RIM if (y == bt + 3 or x == lx - step) else BADGE)


def hood_side(cell, x0, x1, y0, y1, facing):
    """Hood bump behind the neck on the side rows (where the jetpack cap used to be)."""
    outer = x0 if facing == "right" else x1
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if x == outer and y in (y0, y1):
                continue  # rounded back corners
            if y == y1 or x == outer:
                col = CREAM[1]
            else:
                col = CREAM[3] if y == y0 else CREAM[2]
            cell.put(x, y, col)
    for y in range(y0 - 1, y1 + 2):
        for x in range(x0 - 1, x1 + 2):
            if cell.op(x, y) and cell.edge(x, y) and luma(cell.a[y, x]) > 45 and not cell.skin(x, y):
                cell.a[y, x, :3] = OUTLINE


def gimbal(cell, x, y0, y1):
    for y in range(y0, y1 + 1):
        cell.put(x, y, PHONE[1])
        cell.put(x + 1, y, PHONE[0])
    for xx in (x - 1, x + 2):
        if not cell.op(xx, y1 + 1):
            pass
    cell.put(x, y1 + 1, OUTLINE)
    cell.put(x + 1, y1 + 1, OUTLINE)


def screen_glow(cell, x, y0, y1):
    for y in range(y0, y1 + 1):
        cell.put(x, y, CYAN[2] if (y - y0) % 3 else CYAN[3])


def grin_front(cell, cx, y):
    for x in range(cx - 1, cx + 2):
        cell.put(x, y, TEETH)
        cell.put(x, y + 1, LIP)
    cell.put(cx - 2, y, LIP)
    cell.put(cx + 2, y, LIP)


def grin_side(cell, xs, corner, y):
    for x in xs:
        cell.put(x, y, TEETH)
        cell.put(x, y + 1, LIP)
    cell.put(corner, y, LIP)


def earbud(cell, x, y):
    cell.put(x, y, BUD)
    cell.put(x, y + 1, (200, 204, 210))


def details(cell, rc):
    r, c = rc
    if r == 0 and c < 3:
        hood_collar_front(cell, 25, 40, 34)
        hoodie_front(cell, 30, 35, 36, 47)
        grin_front(cell, 32, 32)
        earbud(cell, 23, 25)
        earbud(cell, 41, 25)
    elif (r, c) == (0, 3):
        hood_collar_front(cell, 26, 41, 40)
        hoodie_front(cell, 31, 36, 42, 49)
        gimbal(cell, 45, 42, 44)
        screen_glow(cell, 48, 32, 38)
    elif r == 1 and c < 3:
        blazer_back(cell, 26, 39, 33, 47, 32)
        hood_back(cell, 32, 31)
        earbud(cell, 22, 25)
        earbud(cell, 41, 25)
    elif (r, c) == (1, 3):
        blazer_back(cell, 23, 37, 34, 47, 30)
        hood_back(cell, 30, 32)
        gimbal(cell, 44, 39, 41)
        screen_glow(cell, 48, 31, 36)
    elif r == 2 and c < 3:
        hoodie_side(cell, 35, 40, 33, 46, "right")
        hood_side(cell, 23, 25, 30, 34, "right")
        grin_side(cell, (37, 38), 36, 28)
        earbud(cell, 28, 23)
    elif (r, c) == (2, 3):
        hoodie_side(cell, 30, 35, 42, 47, "right")
        hood_side(cell, 21, 23, 33, 37, "right")
        gimbal(cell, 44, 40, 42)
        screen_glow(cell, 48, 31, 37)
    elif r == 3 and c < 3:
        hoodie_side(cell, 25, 30, 33, 46, "left")
        hood_side(cell, 40, 42, 30, 34, "left")
        grin_side(cell, (27, 28), 29, 28)
        earbud(cell, 37, 23)
    elif (r, c) == (3, 3):
        hoodie_side(cell, 35, 40, 42, 47, "left")
        hood_side(cell, 43, 45, 33, 37, "left")
        gimbal(cell, 18, 40, 42)
        screen_glow(cell, 15, 31, 37)


def despeckle(cell, cfg):
    """Drop orphan pixels (no opaque 4-neighbour) outside the burst columns."""
    bx = cfg.get("blast")
    for y in range(64):
        for x in range(64):
            if not cell.op(x, y) or (bx and bx[0] - 3 <= x <= bx[1] + 3):
                continue
            if not any(cell.op(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                cell.erase(x, y)


def build():
    base = np.array(Image.open(BASE).convert("RGBA"))
    assert base.shape == (256, 256, 4)
    out = base.copy()
    for (r, c), cfg in CELLS.items():
        cell = Cell(out[r * 64:(r + 1) * 64, c * 64:(c + 1) * 64].copy())
        recolour(cell, cfg)
        details(cell, (r, c))
        despeckle(cell, cfg)
        out[r * 64:(r + 1) * 64, c * 64:(c + 1) * 64] = cell.a
    out[..., 3] = np.where(out[..., 3] > 0, 255, 0).astype(np.uint8)
    out[out[..., 3] == 0, :3] = 0
    return base, out


def compare(base, out):
    def big(arr):
        bg = Image.new("RGBA", (256, 256), (128, 128, 128, 255))
        bg.alpha_composite(Image.fromarray(arr, "RGBA"))
        return bg.resize((1024, 1024), Image.NEAREST)
    pan = Image.open(PORTRAIT).convert("RGBA").crop((0, 0, 512, 512)).resize((256, 256), Image.LANCZOS)
    pb = Image.new("RGBA", (256, 256), (128, 128, 128, 255))
    pb.alpha_composite(pan)
    g = 24
    canvas = Image.new("RGBA", (g * 4 + 2048 + 256, 1024 + 2 * g), (128, 128, 128, 255))
    canvas.paste(big(base), (g, g))
    canvas.paste(big(out), (2 * g + 1024, g))
    canvas.paste(pb, (3 * g + 2048, g))
    return canvas


def main():
    base, out = build()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    os.makedirs(os.path.dirname(CMP), exist_ok=True)
    Image.fromarray(out, "RGBA").save(OUT)
    compare(base, out).convert("RGB").save(CMP)
    print("wrote", os.path.relpath(OUT, ROOT), "and", os.path.relpath(CMP, ROOT))


if __name__ == "__main__":
    main()
