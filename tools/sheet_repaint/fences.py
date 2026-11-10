#!/usr/bin/env python3
"""Repaint ch_crypto.png into Landlord Lance (`fences`, gala_ex_3).

Deterministic, no network, PIL + numpy only.
Run from the repo root:  python3 tools/sheet_repaint/fences.py

Reads   assets/art/ch_crypto.png                        (slim guy: orange hair, blue tracksuit, blade attack)
Writes  grok_art/2026-11-10-gala-exes/sheet_fences.png  (master, 256x256, 4x4 cells of 64x64)
        docs/renders/sheet_fences_compare.png           (base | new at 4x on grey, + portrait panel 1)

What it does (row = facing: front, back, right, left; col = stand, walk1, walk2, attack):
  * base rows 2/3 are swapped: ch_crypto has its side rows backwards (row 2 faces screen-LEFT), the game's
    Art.row_for() wants row 2 = moving right. Each figure keeps its own in-cell position and foot line.
  * orange hair -> gelled blond; a WHITE captain's hat (dark brim, navy band) is drawn over the top of the
    head in every facing, with wraparound sunglasses pushed up on the crown and an orange croakie strap
  * skin -> sunburnt pink (redder cheeks / nose on the faces)
  * blue tracksuit jacket -> navy blazer (yellow stripes painted out), dark tee -> salmon polo + popped collar
  * blue trousers -> khaki shorts that stop above the knee, bare pink shins below (no socks)
  * sneakers -> brown boat shoes with cream soles;  gold key ring at the belt
  * attack column: the blade + its arm are erased; a navy sleeve ends in a flat pink palm slapping a blank
    white notice forward, with a burst of white paper scraps
Hard alpha only (0/255); every colour comes from the fixed ramps below, nothing is blended.
"""
import colorsys
import math
import os

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BASE = os.path.join(ROOT, "assets/art/ch_crypto.png")
OUT = os.path.join(ROOT, "grok_art/2026-11-10-gala-exes/sheet_fences.png")
CMP = os.path.join(ROOT, "docs/renders/sheet_fences_compare.png")
PORTRAIT = os.path.join(ROOT, "assets/art/portraits_hd/fences.png")

# ---------------------------------------------------------------- ramps (dark -> light)
OUTLINE = (16, 16, 28)
WARMDARK = (58, 24, 26)
RED = (206, 44, 52)
HALO = (162, 183, 187)
NAVY = [(16, 21, 44), (26, 34, 70), (38, 50, 98), (58, 76, 134)]
KHAKI = [(112, 88, 54), (160, 130, 82), (200, 170, 112), (228, 204, 146)]
SKIN = [(168, 78, 80), (228, 130, 116), (250, 170, 148), (255, 206, 186)]
BURN = (234, 112, 104)
SALMON = [(118, 30, 54), (198, 54, 80), (238, 92, 106), (255, 142, 140)]
BLOND = [(150, 102, 30), (204, 154, 48), (232, 188, 70), (248, 216, 106), (255, 240, 164)]
BROWN = [(78, 44, 24), (132, 78, 40), (176, 112, 58), (206, 146, 84)]
SOLE = (234, 216, 176)
WHITE = [(150, 160, 178), (206, 214, 226), (250, 250, 246)]
BRIM = [(22, 26, 42), (56, 64, 90)]
LENS = (18, 20, 30)
GLINT = (130, 214, 240)
STRAP = (255, 128, 30)
GOLD = [(150, 104, 26), (226, 178, 52), (255, 236, 150)]
EYE = (40, 70, 120)
EYEWHITE = (240, 240, 234)
PAPER = [(150, 158, 176), (214, 220, 230), (252, 252, 250)]


def luma(c):
    return 0.30 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def pick(ramp, l, cuts):
    """cuts: ascending luma thresholds, len(ramp)-1 of them."""
    for i, t in enumerate(cuts):
        if l < t:
            return ramp[i]
    return ramp[-1]


def hsv(c):
    h, s, v = colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)
    return h * 360, s, v


def classify(c):
    r, g, b = c
    if g == 183 and b == 187:
        return "halo"
    h, s, v = hsv(c)
    if v < 0.22:
        return "dark"
    if s < 0.30 and v > 0.80 and r > 200:
        return "white"
    if 180 <= h <= 245 and s < 0.55 and v > 0.55:
        return "lblue"
    if 240 < h < 275 and 0.3 < s < 0.5 and v > 0.4:
        return "weapon"
    if 240 < h < 300 and v < 0.45:
        return "phone"
    if 170 <= h <= 245:
        return "blue"
    if 40 < h < 170:
        return "stripe" if s > 0.25 else "lblue"
    if (h < 42 or h > 340) and r > 100:
        if g / max(r, 1) < 0.46 and b < 32:
            return "hair"
        if s > 0.25:
            return "skin"
        return "white"
    if h < 45 or h > 300:
        return "dark"
    return "blue"


# per output cell: hem = first shorts row, knee = first bare-shin row
CFG = {
    (0, 0): dict(hem=46, knee=51), (0, 1): dict(hem=47, knee=51), (0, 2): dict(hem=47, knee=51),
    (0, 3): dict(hem=47, knee=52),
    (1, 0): dict(hem=45, knee=51), (1, 1): dict(hem=47, knee=51), (1, 2): dict(hem=47, knee=51),
    (1, 3): dict(hem=48, knee=52),
    (2, 0): dict(hem=47, knee=52), (2, 1): dict(hem=48, knee=52), (2, 2): dict(hem=48, knee=52),
    (2, 3): dict(hem=49, knee=53),
    (3, 0): dict(hem=47, knee=52), (3, 1): dict(hem=48, knee=52), (3, 2): dict(hem=48, knee=52),
    (3, 3): dict(hem=49, knee=53),
}
FACING = {0: "front", 1: "back", 2: "right", 3: "left"}

# ---------------------------------------------------------------- hat templates
HATKEY = {"o": OUTLINE, "W": WHITE[2], "w": WHITE[1], "g": WHITE[0], "S": LENS, "s": GLINT,
          "c": STRAP, "n": NAVY[2], "N": NAVY[1], "y": GOLD[1], "B": BRIM[0], "b": BRIM[1]}
HAT_FRONT = [
    "......oooooooooo......",
    "...oooWWWWWWWWWWooo...",
    ".ooWWWWWWWWWWWWWWWWoo.",
    "oWWWWWWWWWWWWWWWWWWwwo",
    "owwWSSSsSSWWSSsSSSWwgo",
    ".ogwSSSSSSooSSSSSSwggo",
    "..ocnnnnnnyynnnnnnco..",
    "..oBbbBBBBBBBBBBBBBo..",
    "...oooooooooooooooo...",
]
HAT_BACK = [
    "......oooooooooo......",
    "...oooWWWWWWWWWWooo...",
    ".ooWWWWWWWWWWWWWWWWoo.",
    "owWWWWWWWWWWWWWWWWWwwo",
    "owwWWWWWWWWWWWWWWWwwgo",
    ".oggwwwwwwwwwwwwwwggo.",
    "..ocNnnnnnnnnnnnnNco..",
    "..oNnnnnnnnnnnnnnnNo..",
    "...oooooooooooooooo...",
]
HAT_RIGHT = [
    ".....oooooooooooo.......",
    "...ooWWWWWWWWWWWWoo.....",
    ".ooWWWWWWWWWWWWWWWWoo...",
    "owWWWWWWWWWWWWWWWWWWWo..",
    "owwWWWWWWWWWWWSSSsSSWo..",
    ".oggwwwwwwccccSSSSSSgo..",
    "..oNnnnnnnnnnnnnnnnnnoo.",
    "...ooooooooooBbbBBBBBBBo",
    "............oooooooooooo",
]


def mirror(t):
    return [row[::-1] for row in t]


def stamp(cell, tmpl, x0, y0):
    for j, row in enumerate(tmpl):
        for i, ch in enumerate(row):
            if ch == ".":
                continue
            x, y = x0 + i, y0 + j
            if 0 <= x < 64 and 0 <= y < 64:
                cell[y, x] = (*HATKEY[ch], 255)


def silhouette(tmpl, x0, y0):
    out = set()
    for j, row in enumerate(tmpl):
        for i, ch in enumerate(row):
            if ch != ".":
                out.add((x0 + i, y0 + j))
    return out


def put(cell, x, y, col):
    if 0 <= x < 64 and 0 <= y < 64:
        cell[y, x] = (*col, 255)


def clear(cell, x, y):
    if 0 <= x < 64 and 0 <= y < 64:
        cell[y, x] = (0, 0, 0, 0)



# ---------------------------------------------------------------- attack: palm slaps a blank notice
SLAPKEY = {"o": OUTLINE, "N": NAVY[0], "n": NAVY[1], "m": NAVY[2], "M": NAVY[3], "j": SKIN[1], "K": SKIN[2],
           "k": SKIN[3], "P": PAPER[2], "p": PAPER[1], "q": PAPER[0], "r": RED}
SLAP_RIGHT = [  # shoulder at (0, 8); sleeve -> flat palm pressed on a tilted sheet
    "..............oooo...",
    ".............oPPPPo..",
    "............oPPPPPpo.",
    "............oPPPPPpo.",
    "...........oPPPPPPpo.",
    "...........oPPrrPPpo.",
    "ooooooooo..oPPrrPPpo.",
    "MMMMMMMMmoooPPPPPPpo.",
    "mmmmmmmmmokKKPPPPPpo.",
    "nnnnnnnnnojKKkPPPPpo.",
    "NNNNNNNNNojjKKPPPPpo.",
    "oooooooooooojjPPPPpo.",
    "...........oPPPPPPpo.",
    "...........oPPPPPpo..",
    "...........oppppppo..",
    "............oooooo...",
]
SLAP_FRONT = [  # shoulder at (0, 6); notice faces the viewer
    "........oooooooo.",
    ".......oPPPPPPPPo",
    ".......oPPPPPPPpo",
    ".......oPPPPPPPpo",
    "ooooo..oPPPPrrPpo",
    "MMMMmoooPPPPrrPpo",
    "mmmmmokKkPPPPPPpo",
    "nnnnnojKKKPPPPPpo",
    "NNNNNojjKKPPPPPpo",
    "oooooooojjPPPPPpo",
    ".......oPPPPPPPpo",
    ".......opppppppo.",
    "........oooooooo.",
]
SLAP_BACK = [  # shoulder at (0, 6); we see the back of the sheet, fingertips curl round its edge
    "........oooooooo.",
    ".......oPPPPPPPPo",
    ".......oPPPPPPPpo",
    ".......oPPPPPPPpo",
    "ooooo..oPPPPPPPpo",
    "MMMMmoooPPPPPPPpo",
    "mmmmmmokPPPPPPPpo",
    "nnnnnnoKPPPPPPPpo",
    "NNNNNNojPPPPPPPpo",
    "ooooooooPPPPPPPpo",
    ".......oPPPPPPPpo",
    ".......opppppppo.",
    "........oooooooo.",
]
# paper burst around the sheet's centre, for a slap to the right (mirrored for the left):
# (dx, dy, scrap) with scraps as tiny tumbling paper bits
SCRAPS = {"A": ["Pp", "pq"], "B": ["PPp"], "C": [".P", "Pp"], "D": ["P"], "E": ["p"]}
BURST = []
for _k in range(13):  # a ring of scraps round the sheet, open behind the arm
    _ang = math.radians(-135 + _k * 270 / 12)
    _rx, _ry = 7.5 + (_k % 3) * 1.5, 9.5 + (_k % 3) * 1.5
    BURST.append((int(round(_rx * math.cos(_ang))), int(round(_ry * math.sin(_ang))), "ADCEBDA"[_k % 7]))
# per output row: (template, shoulder anchor in template, shoulder in cell, mirrored?, erase rects)
SLAPS = {
    0: (SLAP_FRONT, (0, 6), (45, 36), False, [(41, 44, 64, 55)]),
    1: (SLAP_BACK, (0, 6), (45, 37), False, [(14, 38, 24, 48), (41, 44, 64, 55)]),
    2: (SLAP_RIGHT, (0, 8), (32, 36), False, [(8, 41, 21, 48)]),
    3: (SLAP_RIGHT, (0, 8), (31, 36), True, [(44, 41, 58, 48)]),
}


def draw_slap(cell, row):
    tmpl, (ax, ay), (sx, sy), flip, rects = SLAPS[row]
    erased = set()
    for (x0, y0, x1, y1) in rects:
        for y in range(y0, y1):
            for x in range(x0, x1):
                if cell[y, x, 3]:
                    erased.add((x, y))
                    clear(cell, x, y)
    # close the outline where the old blade arm was cut away
    for (x, y) in erased:
        for (u, v) in neighbours(x, y, diag=False):
            if cell[v, u, 3] and tuple(cell[v, u, :3]) not in (HALO, OUTLINE):
                put(cell, u, v, OUTLINE)
    w = len(tmpl[0])
    if flip:
        tmpl = mirror(tmpl)
        x0 = sx - (w - 1 - ax)
    else:
        x0 = sx - ax
    y0 = sy - ay
    for j, line in enumerate(tmpl):
        for i, ch in enumerate(line):
            if ch != ".":
                put(cell, x0 + i, y0 + j, SLAPKEY[ch])
    # burst scraps flying off the sheet
    pts = [(i, j) for j, line in enumerate(tmpl) for i, ch in enumerate(line) if ch in "Pp"]
    pcx = x0 + (min(i for i, _ in pts) + max(i for i, _ in pts)) // 2
    pcy = y0 + (min(j for _, j in pts) + max(j for _, j in pts)) // 2
    for (dx, dy, key) in BURST:
        shape = SCRAPS[key]
        if flip:
            shape = mirror(shape)
            bx = pcx - dx - (len(shape[0]) - 1)
        else:
            bx = pcx + dx
        for j, line in enumerate(shape):
            for i, ch in enumerate(line):
                x, y = bx + i, pcy + dy + j
                if ch != "." and 0 <= x < 64 and 0 <= y < 64 and not cell[y, x, 3]:
                    put(cell, x, y, SLAPKEY[ch])


# ---------------------------------------------------------------- per-cell repaint
WEAPON = {(81, 76, 127), (229, 187, 122), (220, 173, 112), (239, 186, 132)}
# attack cells: box (x0, y0, x1, y1) that holds the old blade, per output row
WEAPON_BOX = {0: (37, 43, 64, 64), 1: (0, 38, 32, 64), 2: (0, 43, 27, 64), 3: (37, 43, 64, 64)}


def neighbours(x, y, diag=True):
    for j in (-1, 0, 1):
        for i in (-1, 0, 1):
            if (i or j) and (diag or not (i and j)) and 0 <= x + i < 64 and 0 <= y + j < 64:
                yield x + i, y + j


def strip_weapon(src, cls, row):
    """Erase the blade (and its rim / hilt pixels) from an attack cell, in place."""
    bx0, by0, bx1, by1 = WEAPON_BOX[row]
    inbox = lambda x, y: bx0 <= x < bx1 and by0 <= y < by1
    gone = {(x, y) for y in range(64) for x in range(64)
            if src[y, x, 3] and tuple(int(v) for v in src[y, x, :3]) in WEAPON and inbox(x, y)}
    for _ in range(3):
        grow = set()
        for (x, y) in gone:
            for (u, v) in neighbours(x, y):
                if (u, v) not in gone and inbox(u, v) and cls[v, u] in ("lblue", "weapon", "phone", "halo"):
                    grow.add((u, v))
        gone |= grow
    for (x, y) in gone:
        src[y, x] = 0
        cls[y, x] = None
    # dark rim pixels left floating next to the hole
    for _ in range(2):
        drop = []
        for y in range(by0, by1):
            for x in range(bx0, bx1):
                if cls[y, x] in ("dark", "halo"):
                    n = sum(1 for (u, v) in neighbours(x, y) if cls[v, u] not in (None, "halo"))
                    if n <= 2:
                        drop.append((x, y))
        for (x, y) in drop:
            src[y, x] = 0
            cls[y, x] = None


def repaint_cell(src_in, rc):
    r, c = rc
    face = FACING[r]
    cfg = CFG[rc]
    src = src_in.copy()
    cls = np.empty((64, 64), dtype=object)
    for y in range(64):
        for x in range(64):
            cls[y, x] = classify(tuple(int(v) for v in src[y, x, :3])) if src[y, x, 3] else None
    if c == 3:
        strip_weapon(src, cls, r)
    cell = src.copy()

    # head geometry from the hair mask
    hair_rows = [y for y in range(40) if sum(1 for x in range(64) if cls[y, x] == "hair") >= 3]
    hair_top = hair_rows[0]
    neck = min(y for y in range(hair_top, 64) if sum(1 for x in range(64) if cls[y, x] == "blue") >= 4)
    head_xs = [x for y in range(hair_top, neck) for x in range(64) if cls[y, x] in ("hair", "skin")]
    hx0, hx1 = min(head_xs), max(head_xs)
    top_xs = [x for y in range(hair_top, hair_top + 9) for x in range(64) if cls[y, x] in ("hair", "skin")]
    tx0, tx1 = min(top_xs), max(top_xs)
    cx = (tx0 + tx1) // 2

    # shoes = the bottom four rows of every foot column (some side-walk feet have no white at all)
    shoe = np.zeros((64, 64), bool)
    body = lambda x, y: cls[y, x] not in (None, "halo")
    for x in range(64):
        yb = max((y for y in range(64) if body(x, y)), default=-1)
        if yb >= 56:
            for y in range(yb, yb - 4, -1):
                if not body(x, y):
                    break
                shoe[y, x] = True
    shin = np.zeros((64, 64), bool)
    legcls = ("blue", "lblue", "stripe", "white")

    for y in range(64):
        for x in range(64):
            k = cls[y, x]
            if k is None:
                continue
            p = tuple(int(v) for v in src[y, x, :3])
            l = luma(p)
            if shoe[y, x] and k != "halo":
                low = not (y < 63 and body(x, y + 1))
                if low:
                    put(cell, x, y, BROWN[0] if l < 60 else SOLE)
                elif k == "white":
                    sole = y < 62 and not body(x, y + 2)
                    put(cell, x, y, SOLE if sole else BROWN[3])
                else:
                    put(cell, x, y, pick(BROWN, l, (30, 60, 100)))
                continue
            if k == "hair" and y >= neck - 1:
                k = "skin"
            if k == "hair" and y > hair_top + 7:  # orange eye / cheek shading inside the face
                mid = (hx0 + hx1) / 2
                if (face == "front" and hx0 + 4 <= x <= hx1 - 4) or (face == "right" and x >= mid + 3) or (
                        face == "left" and x <= mid - 3):
                    k = "skin"
            if k == "halo":
                put(cell, x, y, HALO)
            elif k == "hair":
                put(cell, x, y, pick(BLOND, l, (95, 112, 128, 148)))
            elif k == "skin":
                put(cell, x, y, pick(SKIN, l, (110, 140, 205)))
            elif k == "white" and y < neck:
                put(cell, x, y, EYEWHITE)
            elif k in legcls and (k != "white" or y >= cfg["hem"]):
                if y >= cfg["hem"]:
                    if y >= cfg["knee"]:
                        put(cell, x, y, SKIN[2])
                        shin[y, x] = True
                    else:
                        put(cell, x, y, pick(KHAKI, l, (20, 38, 70)))
                elif k == "stripe" and (y < neck + (1 if face == "front" else 3)):
                    put(cell, x, y, pick(SALMON, l, (80, 140, 190)))  # popped collar
                else:
                    put(cell, x, y, pick(NAVY, l, (26, 40, 75)))
            elif k == "dark":
                h, sat, v = hsv(p)
                if sat > 0.3 and (h < 45 or h > 290):
                    put(cell, x, y, WARMDARK)
                elif sat > 0.3 and 45 <= h < 180:
                    put(cell, x, y, OUTLINE)
            elif k in ("phone", "weapon"):
                put(cell, x, y, SKIN[1])

    # eyes: green -> blue-grey
    for y in range(hair_top, neck):
        for x in range(64):
            if src[y, x, 3] and 75 < hsv(tuple(int(v) for v in src[y, x, :3]))[0] < 170 \
                    and hsv(tuple(int(v) for v in src[y, x, :3]))[1] > 0.3:
                put(cell, x, y, EYE)

    # front: the dark tee between the lapels becomes the salmon polo, collar popped up at the neck
    if face == "front":
        for y in range(neck + 2, cfg["hem"]):
            for x in range(cx - 5, cx + 7):
                p = tuple(int(v) for v in src[y, x, :3])
                if src[y, x, 3] and cls[y, x] in ("dark", "blue") and luma(p) < 32:
                    l = luma(p)
                    if l >= 20:
                        put(cell, x, y, SALMON[2])
                    elif l >= 8:
                        put(cell, x, y, SALMON[1])
        ny = neck + 1
        for side in (-1, 1):
            bx = cx + (1 if side > 0 else 0)
            for (dx, dy, col) in ((4, 0, OUTLINE), (5, 0, OUTLINE), (3, 1, SALMON[3]), (4, 1, SALMON[2]),
                                  (5, 1, OUTLINE), (3, 2, SALMON[2]), (4, 2, SALMON[1]), (2, 2, SALMON[3]),
                                  (5, 2, OUTLINE), (2, 3, SALMON[1]), (3, 3, SALMON[0])):
                put(cell, bx + side * dx - (1 if side > 0 else 0), ny + dy, col)
        # fill the speckled tee into one clean polo, two dark buttons on the placket
        for y in range(neck + 2, cfg["hem"] - 1):
            xs = [x for x in range(cx - 5, cx + 7) if tuple(cell[y, x, :3]) in SALMON]
            if len(xs) >= 2:
                for x in range(xs[0] + 1, xs[-1]):
                    if tuple(cell[y, x, :3]) not in SALMON:
                        put(cell, x, y, SALMON[2])
        for dy in (4, 6):
            if tuple(cell[neck + dy, cx, :3]) in SALMON:
                put(cell, cx, neck + dy, SALMON[0])
        # sunburn: red nose tip and cheeks
        eyes = [(x, y) for y in range(hair_top, neck) for x in range(64) if tuple(cell[y, x, :3]) == EYE]
        if eyes:
            ey = max(y for _, y in eyes)
            exs = sorted({x for x, _ in eyes})
            for x in (exs[0] - 1, exs[0], exs[-1], exs[-1] + 1):
                put(cell, x, ey + 3, BURN)
            put(cell, cx, ey + 2, BURN)
            put(cell, cx + 1, ey + 2, BURN)

    # shins: narrow every bare-leg run to outline + 3 skin + outline
    opaque = lambda x, y: cell[y, x, 3] > 0 and tuple(cell[y, x, :3]) != HALO
    for y in range(cfg["knee"], 64):
        x = 0
        while x < 64:
            if not opaque(x, y):
                x += 1
                continue
            a = x
            while x < 64 and opaque(x, y):
                x += 1
            b = x - 1
            xs = [u for u in range(a, b + 1) if shin[y, u]]
            if len(xs) * 2 < (b - a + 1) or not xs:
                continue
            m = int(round(sum(xs) / len(xs)))
            lo, hi = max(a, m - 2), min(b, m + 2)
            for u in range(a, b + 1):
                if u < lo or u > hi:
                    clear(cell, u, y)
            put(cell, lo, y, OUTLINE)
            put(cell, hi, y, OUTLINE)
            for u in range(lo + 1, hi):
                put(cell, u, y, SKIN[3] if u == lo + 1 else (SKIN[1] if u == hi - 1 else SKIN[2]))
    # shorts hem: close the bottom edge where the leg got narrower
    for x in range(64):
        y = cfg["knee"] - 1
        if cell[y, x, 3] and tuple(cell[y, x, :3]) in KHAKI and not cell[y + 1, x, 3]:
            put(cell, x, y, KHAKI[0])

    # hat
    bottom = hair_top + 6
    if face == "front":
        t = HAT_FRONT
        x0 = cx - len(t[0]) // 2 + 1
    elif face == "back":
        t = HAT_BACK
        x0 = cx - len(t[0]) // 2 + 1
    elif face == "right":
        t = HAT_RIGHT
        x0 = hx1 + 3 - len(t[0])
    else:
        t = mirror(HAT_RIGHT)
        x0 = hx0 - 2
    y0 = bottom - len(t) + 1
    sil = silhouette(t, x0, y0)
    for y in range(0, bottom + 1):
        for x in range(64):
            if (x, y) not in sil and cell[y, x, 3]:
                clear(cell, x, y)
    stamp(cell, t, x0, y0)
    # gelled blond spikes poking out under the brim
    if face in ("front", "back"):
        for (u, v, col) in ((tx0 - 1, bottom + 1, BLOND[3]), (tx0 - 2, bottom + 2, BLOND[2]),
                            (tx0 - 1, bottom + 2, BLOND[1]), (tx1 + 1, bottom + 1, BLOND[3]),
                            (tx1 + 2, bottom + 2, BLOND[2]), (tx1 + 1, bottom + 2, BLOND[1])):
            put(cell, u, v, col)
    else:
        bx = tx0 - 1 if face == "right" else tx1 + 1
        d = -1 if face == "right" else 1
        for (u, v, col) in ((bx, bottom + 1, BLOND[3]), (bx + d, bottom + 2, BLOND[2]), (bx, bottom + 3, BLOND[2]),
                            (bx + d, bottom + 4, BLOND[1]), (bx, bottom + 2, BLOND[1])):
            put(cell, u, v, col)

    # gold key ring at the belt
    ky = cfg["hem"] - 1
    navy_xs = [x for x in range(64) if tuple(cell[ky - 1, x, :3]) in NAVY]
    if face == "front":
        kx = max(navy_xs) - 3
    elif face == "back":
        kx = min(navy_xs) + 3
    else:
        kx = {"right": cx - 4, "left": cx + 4}[face]
    for (u, v, col) in ((kx, ky - 1, GOLD[1]), (kx - 1, ky, GOLD[1]), (kx + 1, ky, GOLD[0]),
                        (kx, ky + 1, GOLD[2]), (kx + 1, ky + 1, GOLD[1]), (kx, ky + 2, GOLD[0])):
        put(cell, u, v, col)
    if c == 3:
        draw_slap(cell, r)
    return cell


def halo_fix(cell):
    """Drop halo pixels that no longer touch the figure; ring the new hat with halo on the open sides."""
    a = cell[:, :, 3] > 0
    is_halo = (cell[:, :, 0] == HALO[0]) & (cell[:, :, 1] == HALO[1]) & (cell[:, :, 2] == HALO[2]) & a
    body = a & ~is_halo
    for y in range(64):
        for x in range(64):
            if is_halo[y, x]:
                if not any(body[y + j, x + i] for i in (-1, 0, 1) for j in (-1, 0, 1)
                           if 0 <= y + j < 64 and 0 <= x + i < 64):
                    cell[y, x] = (0, 0, 0, 0)


def build():
    base = np.array(Image.open(BASE).convert("RGBA"))
    src = base.copy()
    # swap side rows (see docstring)
    src[128:192], src[192:256] = base[192:256].copy(), base[128:192].copy()
    out = np.zeros_like(src)
    for r in range(4):
        for c in range(4):
            cell = repaint_cell(src[r * 64:(r + 1) * 64, c * 64:(c + 1) * 64], (r, c))
            halo_fix(cell)
            out[r * 64:(r + 1) * 64, c * 64:(c + 1) * 64] = cell
    out[:, :, 3] = np.where(out[:, :, 3] > 0, 255, 0)
    return base, out


def compare(base, out):
    def big(arr):
        im = Image.fromarray(arr, "RGBA")
        bg = Image.new("RGBA", im.size, (128, 128, 128, 255))
        bg.alpha_composite(im)
        return bg.resize((1024, 1024), Image.NEAREST)

    por = Image.open(PORTRAIT).convert("RGBA").crop((0, 0, 512, 512)).resize((256, 256), Image.LANCZOS)
    can = Image.new("RGBA", (1024 * 2 + 256 + 48, 1024 + 32), (90, 90, 90, 255))
    can.paste(big(base), (16, 16))
    can.paste(big(out), (1024 + 32, 16))
    pbg = Image.new("RGBA", (256, 256), (128, 128, 128, 255))
    pbg.alpha_composite(por)
    can.paste(pbg, (2048 + 40, 16))
    return can


def main():
    base, out = build()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    os.makedirs(os.path.dirname(CMP), exist_ok=True)
    Image.fromarray(out, "RGBA").save(OUT)
    compare(base, out).convert("RGB").save(CMP)
    print("wrote", os.path.relpath(OUT, ROOT), "and", os.path.relpath(CMP, ROOT))


if __name__ == "__main__":
    main()
