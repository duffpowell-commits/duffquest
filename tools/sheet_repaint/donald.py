#!/usr/bin/env python3
"""Repaint the gym-bro boss sheet into Chip Leverage (`donald`, gala_ex_4, FINAL gala boss).

Deterministic, no network, PIL + numpy only.
Run from the repo root:  python3 tools/sheet_repaint/donald.py

Reads   assets/art/ch_gymbro.png                     (very buff man, neon tank, shorts, sneakers, dumbbells)
Writes  grok_art/2026-11-10-gala-exes/sheet_donald.png (master, 256x256, 4x4 cells of 64x64)
        docs/renders/sheet_donald_compare.png         (old | new at 4x on grey, + portrait panel 1)

What it does (rows = front, back, screen-right, screen-left; cols = stand, walk 1, walk 2, attack):
  * every base pixel is sorted into a material by colour (outline, skin, tank, shorts, socks/shoes, headband,
    dumbbell, sweat), then per-cell rectangles say where shorts/legs/shoes/dumbbells/sleeves are
  * skin -> fake-tan ramp;  neon tank -> charcoal quarter-zip vest (stand collar, zip pull);
    upper arms -> pale-blue dress-shirt sleeves with a rolled cuff, bare forearms below
  * shorts + bare calves + socks -> full-length slate slacks;  sneakers -> dark brown loafers
  * headband / bald crown -> swept-back silver hair (own drawing per facing) + a gold pen behind one ear
  * dumbbells + sweat drops erased, empty hands redrawn as fists
  * attack column: arms redrawn, a brown cardboard archive box held in both hands (overhead on the
    front/back rows, thrust forward on the side rows) with white papers bursting from the lid
  * shading is re-quantised onto fixed 4-step ramps (source luminance, median-smoothed per material),
    silhouette edges get a 1 px dark outline.  Hard alpha only (0/255).
"""
import os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BASE = os.path.join(ROOT, "assets/art/ch_gymbro.png")
OUT = os.path.join(ROOT, "grok_art/2026-11-10-gala-exes/sheet_donald.png")
CMP = os.path.join(ROOT, "docs/renders/sheet_donald_compare.png")
PORTRAIT = os.path.join(ROOT, "assets/art/portraits_hd/donald.png")

# ---------------------------------------------------------------- materials + ramps (dark -> light)
T, OUTL, SKIN, VEST, SHIRT, SLACK, SHOE, HAIR, BOX, PAPER, GOLD, WHITE, MOUTH = range(13)
RAMPS = {
    OUTL: [(24, 20, 28)] * 4,
    SKIN: [(150, 82, 46), (198, 118, 68), (226, 150, 94), (242, 184, 132)],     # fake tan
    VEST: [(30, 32, 38), (48, 51, 58), (68, 72, 80), (92, 96, 105)],            # charcoal fleece
    SHIRT: [(112, 146, 190), (156, 188, 224), (190, 214, 240), (224, 236, 250)],  # pale blue
    SLACK: [(62, 72, 90), (84, 96, 116), (106, 120, 140), (130, 145, 165)],      # slate
    SHOE: [(30, 20, 18), (54, 34, 26), (80, 52, 38), (110, 76, 56)],            # dark loafer
    HAIR: [(88, 92, 104), (132, 137, 149), (172, 176, 187), (212, 215, 222)],   # silver
    BOX: [(112, 74, 40), (160, 112, 62), (194, 146, 88), (222, 182, 124)],       # cardboard
    PAPER: [(186, 194, 208), (226, 230, 236), (246, 246, 244), (255, 255, 255)],
    GOLD: [(140, 100, 24), (206, 160, 44), (242, 206, 86), (255, 240, 160)],
    WHITE: [(250, 250, 246)] * 4,
    MOUTH: [(110, 34, 40)] * 4,
}
NO_AUTO_OUTLINE = {PAPER, GOLD}
QUANT = {SKIN: [0.18, 0.55, 0.88], VEST: [0.3, 0.82, 0.97], SLACK: [0.25, 0.75, 0.95],
         SHOE: [0.3, 0.7, 0.92], SHIRT: [0.2, 0.5, 0.85]}

# stamp legend: char -> (material, level)
LEG = {'O': (OUTL, 0), 'x': (T, 0), 'W': (WHITE, 0), 'M': (MOUTH, 0)}
for i, ch in enumerate('abcd'):
    LEG[ch] = (SKIN, i)
for i, ch in enumerate('efgh'):
    LEG[ch] = (SHIRT, i)
for i, ch in enumerate('ijkl'):
    LEG[ch] = (VEST, i)
for i, ch in enumerate('mnop'):
    LEG[ch] = (BOX, i)
for i, ch in enumerate('qrst'):
    LEG[ch] = (PAPER, i)
for i, ch in enumerate('uvwy'):
    LEG[ch] = (GOLD, i)
for i, ch in enumerate('0123'):
    LEG[ch] = (HAIR, i)
for i, ch in enumerate('ABCD'):
    LEG[ch] = (SLACK, i)
for i, ch in enumerate('EFGH'):
    LEG[ch] = (SHOE, i)

# ---------------------------------------------------------------- source classes
C_T, C_OUT, C_DARK, C_LIGHT, C_GREEN, C_SKIN, C_RED, C_PURP, C_OTHER = range(9)


def classify(a):
    rgb = a[..., :3] / 255.0
    mx, mn = rgb.max(-1), rgb.min(-1)
    v = mx
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    d = np.maximum(mx - mn, 1e-6)
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    op = a[..., 3] > 0
    c = np.full(a.shape[:2], C_T, int)
    c[op] = C_OTHER
    c[op & (v < 0.16)] = C_OUT
    c[op & (v >= 0.16) & (s < 0.28) & (v < 0.5)] = C_DARK
    c[op & (s < 0.25) & (v >= 0.5)] = C_LIGHT
    c[op & (s >= 0.28) & (h >= 45) & (h < 110)] = C_GREEN
    c[op & (s >= 0.28) & (h >= 8) & (h < 45) & (v >= 0.16)] = C_SKIN
    c[op & (s >= 0.28) & ((h < 8) | (h >= 330)) & (v >= 0.16)] = C_RED
    purp = op & (s >= 0.2) & (h >= 200) & (h < 330) & (v >= 0.16)
    c[purp] = C_PURP
    lum = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
    return c, lum, v


# ---------------------------------------------------------------- hand-drawn parts
FIST_DOWN = [      # a closed fist hanging at the side, knuckles toward viewer
    ".OOOO.",
    "OccbbO",
    "OcdccO",
    "ObccbO",
    "ObbbaO",
    ".OOOO.",
]
CUFF_W = "OhhgO"


def flip(stamp):
    return [row[::-1] for row in stamp]


# ---------------------------------------------------------------- canvas helpers
class Cell:
    def __init__(self, src, cls, lum, r, c):
        self.r, self.c = r, c
        y0, x0 = r * 64, c * 64
        self.src = src[y0:y0 + 64, x0:x0 + 64]
        self.cls = cls[y0:y0 + 64, x0:x0 + 64]
        self.lum = lum[y0:y0 + 64, x0:x0 + 64]
        self.mat = np.full((64, 64), T, int)
        self.lvl = np.full((64, 64), -1, int)   # -1 = derive from source luminance later
        self.fixed = np.zeros((64, 64), bool)  # drawn pixels: no auto-outline erosion
        cl = self.cls
        self.mat[cl == C_OUT] = OUTL
        self.mat[cl == C_GREEN] = VEST
        self.mat[cl == C_SKIN] = SKIN
        self.mat[cl == C_RED] = OUTL
        self.mat[cl == C_OTHER] = OUTL
        # dark purple = outline, light purple = sweat (erased)
        purp = cl == C_PURP
        self.mat[purp & (self.lum < 70)] = OUTL
        # dark neutral / light neutral default to erased (dumbbells); regions claim them back

    def rect(self, x0, y0, x1, y1):
        m = np.zeros((64, 64), bool)
        m[max(0, y0):min(64, y1 + 1), max(0, x0):min(64, x1 + 1)] = True
        return m

    def classes(self, *cs):
        return np.isin(self.cls, cs)

    def setm(self, mask, mat, lvl=-1):
        self.mat[mask] = mat
        self.lvl[mask] = lvl

    def stamp(self, x, y, rows, fixed=True):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch == '.' or ch == ' ':
                    continue
                xx, yy = x + i, y + j
                if 0 <= xx < 64 and 0 <= yy < 64:
                    m, l = LEG[ch]
                    self.mat[yy, xx] = m
                    self.lvl[yy, xx] = l
                    self.fixed[yy, xx] = fixed

    def px(self, x, y, mat, lvl=0):
        if 0 <= x < 64 and 0 <= y < 64:
            self.mat[y, x] = mat
            self.lvl[y, x] = lvl
            self.fixed[y, x] = True

    def limb(self, p0, p1, w, mat, cap=True):
        """Thick shaded segment with a 1 px outline. Light from the upper left."""
        (x0, y0), (x1, y1) = p0, p1
        dx, dy = x1 - x0, y1 - y0
        L = max(1e-6, (dx * dx + dy * dy) ** 0.5)
        nx, ny = -dy / L, dx / L
        if nx + ny > 0:  # make the normal point to the upper-left (light side)
            nx, ny = -nx, -ny
        ys, xs = np.mgrid[0:64, 0:64]
        t = ((xs - x0) * dx + (ys - y0) * dy) / (L * L)
        tc = np.clip(t, 0, 1)
        px_, py_ = x0 + tc * dx, y0 + tc * dy
        dist = np.hypot(xs - px_, ys - py_)
        side = (xs - px_) * nx + (ys - py_) * ny
        r = w / 2.0
        outer = dist <= r + 1.0
        inner = dist <= r
        self.mat[outer & ~inner] = OUTL
        self.lvl[outer & ~inner] = 0
        self.fixed[outer] = True
        lv = np.where(side > r * 0.45, 3, np.where(side > -r * 0.2, 2, 1))
        self.mat[inner] = mat
        self.lvl[inner] = lv[inner]

    def box(self, x0, y0, x1, y1, lid=3, hole=True):
        """Cardboard archive box, front face, with a lid band and a hand hole."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                edge = x in (x0, x1) or y in (y0, y1)
                if edge:
                    self.px(x, y, OUTL)
                elif y == y0 + lid:
                    self.px(x, y, OUTL)           # lid seam
                elif y < y0 + lid:
                    self.px(x, y, BOX, 3 if y == y0 + 1 else 2)
                else:
                    lvl = 2
                    if x == x1 - 1 or y == y1 - 1:
                        lvl = 1
                    if x == x0 + 1:
                        lvl = 3
                    self.px(x, y, BOX, lvl)
        if hole:
            cx = (x0 + x1) // 2
            hy = y0 + lid + 2
            for x in range(cx - 1, cx + 2):
                self.px(x, hy, OUTL)
        # tiny label
        lx, ly = x0 + 2, y1 - 3
        if x1 - x0 >= 9 and y1 - y0 >= 8:
            for x in range(lx, lx + 3):
                self.px(x, ly, PAPER, 2)

    def papers(self, pts):
        """pts: list of (x, y, kind) kind 'h' = 2px horizontal sheet, 'v' = vertical, 'd' = 1px"""
        for x, y, k in pts:
            if k == 'h':
                self.px(x, y, PAPER, 3)
                self.px(x + 1, y, PAPER, 2)
            elif k == 'v':
                self.px(x, y, PAPER, 3)
                self.px(x, y + 1, PAPER, 1)
            elif k == 'b':  # 2x2 sheet with a ruled line
                self.px(x, y, PAPER, 3)
                self.px(x + 1, y, PAPER, 3)
                self.px(x, y + 1, PAPER, 1)
                self.px(x + 1, y + 1, PAPER, 2)
            else:
                self.px(x, y, PAPER, 3)


# ---------------------------------------------------------------- generic per-cell recipe
def apply_regions(cell, cfg):
    cl = cell.cls
    neutral = cell.classes(C_DARK, C_LIGHT, C_OTHER) | ((cl == C_PURP) & (cell.lum >= 70))
    # 1) dumbbells / sweat are erased unless a region below claims them back
    cell.setm(neutral & ~cell.classes(C_OUT, C_GREEN, C_SKIN, C_RED), T)
    # 2) shorts -> slacks (keep the dark seam pixels as outline)
    for (x0, y0, x1, y1) in cfg.get('shorts', []):
        m = cell.rect(x0, y0, x1, y1) & (cl != C_T) & (cl != C_OUT)
        cell.setm(m, SLACK)
    # 3) bare legs + socks -> slacks (everything, the ankle lines disappear)
    for (x0, y0, x1, y1) in cfg.get('legs', []):
        m = cell.rect(x0, y0, x1, y1) & (cl != C_T)
        cell.setm(m, SLACK)
        # inner outline pixels in the leg get the slack shadow tone
        cell.lvl[m & (cl == C_OUT)] = 0
    # 4) sneakers -> loafers
    for (x0, y0, x1, y1) in cfg.get('shoes', []):
        m = cell.rect(x0, y0, x1, y1) & (cl != C_T)
        inner = m & (cl != C_OUT)
        cell.setm(inner, SHOE)
        cell.setm(m & (cl == C_OUT), OUTL)
    # 5) explicit erasers win over the claims above
    for (x0, y0, x1, y1) in cfg.get('erase', []):      # erase everything but skin / tank
        m = cell.rect(x0, y0, x1, y1) & ~cell.classes(C_SKIN, C_GREEN)
        cell.setm(m, T)
    for (x0, y0, x1, y1) in cfg.get('wipe', []):       # erase everything
        cell.setm(cell.rect(x0, y0, x1, y1), T)
    for (x0, y0, x1, y1) in cfg.get('wipe_keep_vest', []):   # erase everything except the tank
        cell.setm(cell.rect(x0, y0, x1, y1) & (cl != C_GREEN), T)
    for (x0, y0, x1, y1) in cfg.get('skinfill', []):   # dumbbell bits inside an arm -> skin
        m = cell.rect(x0, y0, x1, y1) & cell.classes(C_DARK, C_LIGHT, C_PURP, C_OTHER, C_OUT)
        cell.setm(m, SKIN, 1)
    # 6) upper arms -> shirt sleeves
    for (x0, y0, x1, y1) in cfg.get('sleeves', []):
        m = cell.rect(x0, y0, x1, y1) & (cell.mat == SKIN)
        cell.mat[m] = SHIRT
    # 7) chest / upper back skin between the tank straps -> vest
    for (x0, y0, x1, y1) in cfg.get('vest', []):
        m = cell.rect(x0, y0, x1, y1) & (cell.mat == SKIN)
        cell.mat[m] = VEST
    # 8) face whites (teeth/eyes) and mouth
    for (x0, y0, x1, y1) in cfg.get('face', []):
        m = cell.rect(x0, y0, x1, y1)
        cell.setm(m & (cl == C_LIGHT), WHITE, 0)
        cell.setm(m & (cl == C_RED), MOUTH, 0)
    for (x0, y0, x1, y1, mat, lvl) in cfg.get('fill', []):
        m = cell.rect(x0, y0, x1, y1) & (cell.mat != T)
        cell.setm(m, mat, lvl)
    # 9) hand-drawn stamps
    for (x, y, st) in cfg.get('stamps', []):
        cell.stamp(x, y, st)
    for fn in cfg.get('draw', []):
        fn(cell)


def cleanup_interior(cell, cfg):
    """Dark noise pixels buried inside one material become that material's darkest tone."""
    keep = np.zeros((64, 64), bool)
    for (x0, y0, x1, y1) in cfg.get('face', []) + cfg.get('keep', []):
        keep |= cell.rect(x0, y0, x1, y1)
    mat = cell.mat.copy()
    for y in range(1, 63):
        for x in range(1, 63):
            if mat[y, x] != OUTL or cell.fixed[y, x] or keep[y, x]:
                continue
            nb = mat[y - 1:y + 2, x - 1:x + 2].ravel()
            if (nb == T).any():
                continue
            vals, cnt = np.unique(nb[(nb != OUTL)], return_counts=True)
            if len(vals) and cnt.max() >= 5:
                cell.mat[y, x] = vals[cnt.argmax()]
                cell.lvl[y, x] = 0


def despeckle(cell):
    """Drop leftover specks: opaque pixels with at most one opaque 8-neighbour (paper is exempt)."""
    for _ in range(2):
        op = cell.mat != T
        pad = np.pad(op, 1).astype(int)
        n = sum(pad[1 + dy:65 + dy, 1 + dx:65 + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1)) - op
        kill = op & (n <= 1) & (cell.mat != PAPER)
        cell.mat[kill] = T


def auto_outline(mat, fixed):
    out = mat.copy()
    H, W = mat.shape
    opaque = mat != T
    pad = np.pad(opaque, 1, constant_values=False)
    nb_t = ~pad[0:-2, 1:-1] | ~pad[2:, 1:-1] | ~pad[1:-1, 0:-2] | ~pad[1:-1, 2:]
    edge = opaque & nb_t & ~fixed & ~np.isin(mat, list(NO_AUTO_OUTLINE))
    out[edge] = OUTL
    return out


# ---------------------------------------------------------------- the 16 cells
# hair, drawn per facing (stand-frame cell coords; walk frames shift the stamp)
HEAD_FRONT = [               # origin (25, 7): swept-back silver hair + smug grin with veneers
    ".....OOOOOO.....",
    "...OO233332OO...",
    "..O12333333221O.",
    ".O1123333322110O",
    ".O0112000002100O",
    ".O01OddddddO10O.",
    ".O0OcddddddcO0O.",
    ".Oc000cccc000cO.",
    ".OcWOccbbccWOcO.",
    ".OcccccbbcccccO.",
    ".ObcOcbaabcOcbO.",
    ".ObcOWWWWWWOcbO.",
    ".ObbcOOOOOOcbbO.",
    ".OabbccccccbbaO.",
    "..OaabbbbbbaaO..",
]
HAIR_BACK = [                # origin (25, 6)
    ".....OOOOOO.....",
    "...OO2233322OO..",
    "..O23333333221O.",
    ".O1223333322211O",
    ".O1122312221111O",
    ".O1112212211110O",
    ".O0111211211100O",
    ".O0011111111000O",
    "..O00111111000O.",
    "...OOO0000OOO...",
]
HEAD_SIDE_R = [              # origin (25, 3): profile facing screen-right
    ".....OOOOOO......",
    "...OO223332OO....",
    "..O12233333222O..",
    ".O0112233332221O.",
    ".O0011222222211O.",
    ".O0001112222110O.",
    ".O0001111100000O.",
    ".O0001111OddddcO.",
    ".O000111OcddddcO.",
    ".O0001OOccc000cO.",
    ".O001OcbOcccWOcbO",
    "..ObbObbOccccccbO",
    "..ObbObcccccccOO.",
    "...OObbcccccMWWO.",
    "....ObbbccccccbO.",
    ".....OaabbbbbbaO.",
]
HEAD_SIDE_L = [row[::-1] for row in HEAD_SIDE_R]   # origin (24, 3)


def draw_front_head(cell, ox=0, oy=0):
    cell.stamp(25 + ox, 7 + oy, HEAD_FRONT)
    # gold pen tucked over his left ear (image right)
    for (x, y, l) in [(40, 12, 1), (41, 11, 2), (42, 10, 3)]:
        cell.px(x + ox, y + oy, GOLD, l)


def draw_front_collar(cell, ox=0, oy=0):
    # charcoal stand collar, pale-blue shirt collar in the notch, zip with a gold pull
    cell.stamp(27 + ox, 22 + oy, [
        "OkkkOhghOkkkO",
        ".jjjjOvOjjjj.",
    ])
    for y in range(24, 33):
        cell.px(33 + ox, y + oy, VEST, 3)


def cuff(cell, x0, x1, y):
    cell.px(x0, y, OUTL)
    cell.px(x1, y, OUTL)
    for x in range(x0 + 1, x1):
        cell.px(x, y, SHIRT, 3)


def crease(cell, x, y0, y1):
    for y in range(y0, y1 + 1):
        if cell.mat[y, x] == SLACK:
            cell.lvl[y, x] = 3
            cell.fixed[y, x] = True


CFG = {}

# ---------- row 0: facing viewer
_front_body = dict(
    erase=[(6, 32, 23, 46), (43, 37, 51, 44)],
    skinfill=[(44, 26, 47, 36)],
    shorts=[(24, 33, 44, 44)],
    sleeves=[(12, 17, 24, 30), (40, 17, 54, 28)],
    vest=[(25, 22, 40, 30)],
    face=[(26, 13, 41, 21)],
)


def draw_front(cell):
    draw_front_head(cell)
    draw_front_collar(cell)
    cuff(cell, 14, 21, 31)
    cell.limb((18, 32), (17, 36), 4, SKIN)
    cell.stamp(14, 35, FIST_DOWN)
    cuff(cell, 42, 49, 29)
    crease(cell, 27, 45, 53)
    crease(cell, 39, 45, 53)


CFG[(0, 0)] = dict(_front_body, legs=[(22, 44, 45, 54)], shoes=[(17, 55, 48, 60)], draw=[draw_front])
CFG[(0, 1)] = dict(_front_body, legs=[(22, 43, 33, 54), (34, 43, 44, 49)],
                   shoes=[(21, 55, 35, 60), (33, 50, 44, 56)], draw=[draw_front])
CFG[(0, 2)] = dict(_front_body, legs=[(22, 43, 33, 54), (34, 43, 44, 49)],
                   shoes=[(21, 55, 35, 60), (33, 50, 44, 56)], draw=[draw_front])

# ---------- row 1: facing away
_back_body = dict(
    erase=[(8, 31, 20, 44), (44, 31, 56, 44)],
    shorts=[(20, 35, 44, 42)],
    sleeves=[(12, 17, 26, 30), (39, 17, 54, 30)],
    vest=[(26, 18, 40, 26)],
)


def draw_back(cell):
    cell.stamp(25, 6, HAIR_BACK)
    # ears
    cell.stamp(24, 11, ["Oc", "Ob", ".O"])
    cell.stamp(40, 11, ["cO", "bO", "O."])
    # nape + collar: a sliver of shirt collar above the vest stand collar
    for x in range(28, 38):
        cell.px(x, 17, SHIRT, 2 if x % 4 else 1)
        cell.px(x, 18, VEST, 2)
    cell.px(27, 17, OUTL)
    cell.px(38, 17, OUTL)
    cuff(cell, 15, 23, 31)
    cuff(cell, 42, 50, 31)
    cell.stamp(15, 34, FIST_DOWN)
    cell.stamp(44, 34, FIST_DOWN)
    crease(cell, 28, 44, 52)
    crease(cell, 38, 44, 52)


CFG[(1, 0)] = dict(_back_body, legs=[(22, 42, 44, 53)], shoes=[(20, 54, 45, 60)], draw=[draw_back])
CFG[(1, 1)] = dict(_back_body, legs=[(22, 42, 33, 50), (33, 42, 44, 51)],
                   shoes=[(22, 51, 33, 60), (32, 52, 44, 60)], draw=[draw_back])
CFG[(1, 2)] = dict(_back_body, legs=[(22, 42, 33, 50), (33, 42, 44, 51)],
                   shoes=[(22, 51, 33, 60), (32, 52, 44, 60)], draw=[draw_back])

# ---------- row 2: facing screen-right


def draw_side_r(ox):
    def f(cell):
        cell.stamp(25 + ox, 3, HEAD_SIDE_R)
        for (x, y, l) in [(30, 12, 1), (31, 11, 2), (32, 10, 3)]:     # gold pen over the ear
            cell.px(x + ox, y, GOLD, l)
        # stand collar + shirt collar at the front of the neck
        cell.stamp(31 + ox, 19, ["OkkkkkhgO", ".jjjjjjOg"])
        cuff(cell, 20 + ox, 30 + ox, 30)
    return f


_side_r = dict(
    erase=[(14, 32, 23, 44), (38, 18, 48, 24)],
    shorts=[(24, 33, 41, 43)],
    sleeves=[(18, 16, 32, 29)],
    vest=[(33, 20, 40, 33)],
    face=[(30, 8, 41, 18)],
)
CFG[(2, 0)] = dict(_side_r, legs=[(24, 43, 40, 52)], shoes=[(22, 53, 44, 60)], draw=[draw_side_r(0)])
CFG[(2, 1)] = dict(_side_r, legs=[(18, 43, 32, 48), (32, 43, 44, 49)],
                   shoes=[(14, 49, 32, 60), (33, 50, 52, 60)], draw=[draw_side_r(-1)])
CFG[(2, 2)] = dict(_side_r, legs=[(18, 43, 32, 48), (32, 43, 44, 49)],
                   shoes=[(14, 49, 32, 60), (33, 50, 52, 60)], draw=[draw_side_r(-1)])

# ---------- row 3: facing screen-left (own drawing, mirrored geometry only for the hair spans)


def draw_side_l(ox):
    def f(cell):
        cell.stamp(24 + ox, 3, HEAD_SIDE_L)
        for (x, y, l) in [(36, 12, 1), (35, 11, 2), (34, 10, 3)]:
            cell.px(x + ox, y, GOLD, l)
        cell.stamp(26 + ox, 19, ["OghkkkkkO", "gOjjjjjj."])
        cuff(cell, 35 + ox, 46 + ox, 30)
    return f


_side_l = dict(
    erase=[(41, 32, 50, 44), (17, 18, 27, 24)],
    shorts=[(25, 33, 41, 43)],
    sleeves=[(33, 16, 48, 29)],
    vest=[(26, 20, 33, 33)],
    face=[(24, 8, 37, 18)],
)
CFG[(3, 0)] = dict(_side_l, legs=[(27, 43, 42, 52)], shoes=[(24, 53, 44, 60)], draw=[draw_side_l(0)])
CFG[(3, 1)] = dict(_side_l, legs=[(24, 43, 34, 49), (34, 43, 48, 48)],
                   shoes=[(15, 50, 34, 60), (35, 49, 52, 60)], draw=[draw_side_l(1)])
CFG[(3, 2)] = dict(_side_l, legs=[(24, 43, 34, 49), (34, 43, 48, 48)],
                   shoes=[(15, 50, 34, 60), (35, 49, 52, 60)], draw=[draw_side_l(1)])


# ---------- attack column: arms redrawn, archive box in both hands, papers bursting from the lid
FIST = [
    ".OOO.",
    "OcddO",
    "ObccO",
    "ObbbO",
    ".OOO.",
]


def arm(cell, shoulder, elbow, hand, w_up=6, w_fore=4):
    """Sleeved upper arm, rolled cuff just below the elbow, bare forearm."""
    cell.limb(shoulder, elbow, w_up, SHIRT)
    ex, ey = elbow
    hx, hy = hand
    # cuff: 1/4 of the way down the forearm
    cx, cy = ex + (hx - ex) * 0.22, ey + (hy - ey) * 0.22
    cell.limb((cx, cy), hand, w_fore, SKIN)
    cell.limb(elbow, (cx, cy), w_fore + 1, SHIRT)
    # light cuff band
    cell.px(int(round(cx)), int(round(cy)), SHIRT, 3)


def attack_front(cell):
    # box overhead (in front of the crown), both arms up gripping its sides
    cell.box(27, 1, 46, 10, lid=3)
    arm(cell, (27, 26), (19, 18), (25, 9))
    arm(cell, (45, 26), (52, 18), (47, 9))
    cell.stamp(23, 5, FIST)
    cell.stamp(45, 5, FIST)
    cell.stamp(30, 11, HEAD_FRONT[2:])          # head below the box (top rows hidden by the box)
    for (x, y, l) in [(45, 16, 1), (46, 15, 2), (47, 14, 3)]:
        cell.px(x, y, GOLD, l)
    cell.stamp(32, 26, ["OkkkOhghOkkkO", ".jjjjOvOjjjj."])
    for y in range(28, 37):
        cell.px(38, y, VEST, 3)
    # papers bursting out of the lid
    for (x, y, k) in [(20, 0, 0), (49, 0, 1), (16, 3, 2), (52, 3, 0)]:
        sheet(cell, x, y, k)
    for (x, y) in [(29, 0), (30, 0), (35, 0), (36, 0), (41, 0), (42, 0), (24, 0), (55, 1), (14, 1)]:
        cell.px(x, y, PAPER, 3)
    crease(cell, 23, 46, 51)
    crease(cell, 44, 46, 51)


CFG[(0, 3)] = dict(
    wipe_keep_vest=[(0, 0, 30, 30), (0, 0, 63, 9), (44, 22, 63, 46)],
    shorts=[(20, 37, 47, 46)],
    legs=[(16, 45, 30, 52), (38, 44, 49, 52)],
    shoes=[(10, 53, 27, 60), (37, 53, 53, 60)],
    vest=[(29, 23, 45, 31)],
    draw=[attack_front],
)


def attack_back(cell):
    # seen from behind: box overhead, the head in front of its bottom edge
    cell.box(18, 1, 41, 10, lid=3, hole=False)
    arm(cell, (25, 22), (16, 15), (20, 7))
    arm(cell, (40, 22), (48, 14), (40, 7))
    cell.stamp(17, 4, FIST)
    cell.stamp(39, 4, FIST)
    cell.stamp(22, 8, HAIR_BACK)
    for x in range(25, 35):
        cell.px(x, 19, SHIRT, 2 if x % 4 else 1)
        cell.px(x, 20, VEST, 2)
    for (x, y) in [(20, 0), (21, 0), (27, 0), (33, 0), (34, 0), (38, 0), (15, 1), (16, 0), (44, 1), (45, 0)]:
        cell.px(x, y, PAPER, 3)
    crease(cell, 24, 45, 50)
    crease(cell, 43, 45, 49)


CFG[(1, 3)] = dict(
    wipe_keep_vest=[(0, 0, 63, 7), (0, 0, 23, 44), (36, 0, 63, 21), (44, 21, 63, 44)],
    shorts=[(18, 37, 47, 45)],
    legs=[(17, 44, 30, 51), (36, 43, 49, 50)],
    shoes=[(14, 52, 30, 60), (39, 51, 53, 60)],
    vest=[(23, 16, 38, 26)],
    draw=[attack_back],
)


def vest_torso(cell, rows, front_right=True):
    """Fill a charcoal vest body. rows: {y: (x0, x1)}; light from the upper-left."""
    ys = sorted(rows)
    for y in ys:
        x0, x1 = rows[y]
        for x in range(x0, x1 + 1):
            edge = (x in (x0, x1) or y == ys[0] or (y - 1 in rows and not (rows[y - 1][0] <= x <= rows[y - 1][1])))
            if edge:
                cell.px(x, y, OUTL)
                continue
            u = (y - ys[0]) / max(1, ys[-1] - ys[0])
            t = (x - x0) / max(1, x1 - x0)
            sc = 1.6 - 0.9 * u + (0.8 * (t - 0.5) if front_right else -0.8 * (t - 0.5))
            if (front_right and x == x0 + 1) or (not front_right and x == x1 - 1):
                sc -= 0.8
            cell.px(x, y, VEST, int(np.clip(round(sc), 0, 3)))


def sheet(cell, x, y, kind=0):
    """One flying sheet of paper (3x2 or 2x3), white with a grey shadow edge."""
    shapes = [
        ["tts", "srq"],
        ["ts", "ts", "rq"],
        [".tt", "tsr", "q.."],
    ]
    for j, row in enumerate(shapes[kind % 3]):
        for i, ch in enumerate(row):
            if ch != '.':
                m, l = LEG[ch]
                cell.px(x + i, y + j, m, l)


def attack_side(cell, d):
    """d=+1 facing screen-right, d=-1 facing screen-left. X(x) maps right-facing coords."""
    X = (lambda x: x) if d > 0 else (lambda x: 63 - x)

    def rows_m(rows):
        return {y: (min(X(a), X(b)), max(X(a), X(b))) for y, (a, b) in rows.items()}
    torso = {16: (15, 26), 17: (12, 29), 18: (11, 31), 19: (10, 32), 20: (10, 32)}
    for y in range(21, 31):
        torso[y] = (10, 33)
    torso.update({31: (11, 33), 32: (11, 33), 33: (12, 32), 34: (12, 32)})
    vest_torso(cell, rows_m(torso), front_right=d > 0)
    # zip down the front edge of the vest
    for y in range(19, 34):
        cell.px(X(32), y, VEST, 3)
    # box held out in front with the lid toward the throw
    bx0, bx1 = (37, 49) if d > 0 else (14, 26)
    cell.box(bx0, 7, bx1, 20, lid=3, hole=True)
    # paper poking out of the lid seam
    for x in range(bx0 + 3, bx0 + 8):
        cell.px(x, 9 + 1, PAPER, 3)
    # near arm: big sleeved upper arm, rolled cuff, forearm to the box
    cell.limb((X(18), 21), (X(29), 21), 8, SHIRT)
    cell.limb((X(29), 21), (X(31), 20), 6, SHIRT)
    cell.limb((X(32), 20), (X(37), 18), 5, SKIN)
    for y in range(17, 25):
        cell.px(X(31), y, SHIRT, 3)
    cell.px(X(31), 16, OUTL)
    cell.px(X(31), 25, OUTL)
    cell.stamp(X(35) if d > 0 else X(39), 15, FIST)
    cell.stamp(X(47) if d > 0 else X(51), 13, FIST)        # far hand on the far side of the box
    # head + collar
    if d > 0:
        cell.stamp(12, 1, HEAD_SIDE_R)
        cell.stamp(19, 16, ["OkkkkkkhgO", ".jjjjjjjOg"])
        pen = [(17, 10, 1), (18, 9, 2), (19, 8, 3)]
    else:
        cell.stamp(63 - 12 - 16, 1, HEAD_SIDE_L)
        cell.stamp(63 - 19 - 9, 16, ["OghkkkkkkO", "gOjjjjjjj."])
        pen = [(63 - 17, 10, 1), (63 - 18, 9, 2), (63 - 19, 8, 3)]
    for (x, y, l) in pen:
        cell.px(x, y, GOLD, l)
    # papers bursting forward out of the lid
    for (x, y, k) in [(50, 3, 0), (54, 0, 1), (57, 5, 2), (52, 8, 0), (45, 1, 2), (59, 1, 0), (41, 3, 1)]:
        xx = x if d > 0 else 63 - x - 2
        sheet(cell, xx, y, k)
    for (x, y) in [(56, 9), (61, 4), (48, 0)]:
        cell.px(X(x), y, PAPER, 3)


def attack_side_r(cell):
    attack_side(cell, +1)
    crease(cell, 15, 44, 48)
    crease(cell, 36, 44, 47)


CFG[(2, 3)] = dict(
    wipe_keep_vest=[(0, 0, 63, 33)],
    shorts=[(12, 33, 40, 43)],
    legs=[(10, 43, 22, 49), (30, 43, 41, 48)],
    shoes=[(6, 50, 20, 59), (32, 49, 50, 59)],
    draw=[attack_side_r],
)


def attack_side_l(cell):
    attack_side(cell, -1)
    crease(cell, 31, 44, 48)
    crease(cell, 50, 45, 49)


CFG[(3, 3)] = dict(
    wipe_keep_vest=[(0, 0, 63, 33)],
    shorts=[(26, 34, 54, 43)],
    legs=[(25, 43, 37, 49), (44, 43, 56, 49)],
    shoes=[(15, 50, 34, 59), (44, 49, 60, 59)],
    draw=[attack_side_l],
)


# ---------------------------------------------------------------- render
def render():
    src = np.array(Image.open(BASE).convert('RGBA')).astype(int)
    cls, lum, val = classify(src)
    out = np.zeros((256, 256, 4), np.uint8)
    mats = np.full((256, 256), T, int)
    lvls = np.full((256, 256), -1, int)
    fixed = np.zeros((256, 256), bool)
    for r in range(4):
        for c in range(4):
            cell = Cell(src, cls, lum, r, c)
            cfg = CFG.get((r, c), {})
            apply_regions(cell, cfg)
            sl = (slice(r * 64, r * 64 + 64), slice(c * 64, c * 64 + 64))
            for _ in range(3):
                cleanup_interior(cell, cfg)
            despeckle(cell)
            mats[sl] = auto_outline(cell.mat, cell.fixed)
            lvls[sl] = cell.lvl
            fixed[sl] = cell.fixed
    # luminance-derived levels, smoothed per material, ranked per (material, source class)
    need = (lvls < 0) & (mats != T)
    sm = lum.copy()
    H, W = mats.shape
    for y, x in zip(*np.nonzero(need)):
        y0, y1, x0, x1 = max(0, y - 2), min(H, y + 3), max(0, x - 2), min(W, x + 3)
        win = mats[y0:y1, x0:x1] == mats[y, x]
        sm[y, x] = np.median(lum[y0:y1, x0:x1][win])
    for m in RAMPS:
        for c in range(9):
            sel = need & (mats == m) & (cls == c)
            if sel.sum() < 4:
                lvls[sel] = 1
                continue
            vals = sm[sel]
            q = np.quantile(vals, QUANT.get(m, [0.22, 0.6, 0.9]))
            lvls[sel] = np.digitize(vals, q)
    # majority filter on derived levels (kills the salt-and-pepper of the source sprite)
    lv2 = lvls.copy()
    for y, x in zip(*np.nonzero(need)):
        y0, y1, x0, x1 = max(0, y - 1), min(H, y + 2), max(0, x - 1), min(W, x + 2)
        win = (mats[y0:y1, x0:x1] == mats[y, x])
        vals = lvls[y0:y1, x0:x1][win]
        cnt = np.bincount(np.clip(vals, 0, 3), minlength=4)
        if cnt[lvls[y, x]] < 3:
            lv2[y, x] = cnt.argmax()
    lvls = lv2
    for m, ramp in RAMPS.items():
        for i, col in enumerate(ramp):
            sel = (mats == m) & (np.clip(lvls, 0, 3) == i)
            out[sel, :3] = col
            out[sel, 3] = 255
    return src, out


def compare(src, out):
    def big(a):
        im = Image.fromarray(a.astype(np.uint8), 'RGBA')
        bg = Image.new('RGBA', im.size, (128, 128, 128, 255))
        bg.alpha_composite(im)
        return bg.resize((1024, 1024), Image.NEAREST)
    p = Image.open(PORTRAIT).convert('RGBA')
    pw = p.width // 3
    panel = p.crop((0, 0, pw, p.height))
    panel = panel.resize((int(pw * 256 / p.height), 256), Image.LANCZOS)   # portrait panel 1, 256 high
    pbg = Image.new('RGBA', panel.size, (128, 128, 128, 255))
    pbg.alpha_composite(panel)
    can = Image.new('RGB', (1024 * 2 + pbg.width + 64, 1024 + 32), (60, 60, 60))
    can.paste(big(src).convert('RGB'), (16, 16))
    can.paste(big(out).convert('RGB'), (1024 + 32, 16))
    can.paste(pbg.convert('RGB'), (2048 + 48, 16))
    return can


def main():
    src, out = render()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    os.makedirs(os.path.dirname(CMP), exist_ok=True)
    Image.fromarray(out, 'RGBA').save(OUT)
    compare(src, out).save(CMP)
    a = out[..., 3]
    assert out.shape == (256, 256, 4) and set(np.unique(a)) <= {0, 255}
    print('wrote', OUT)
    print('wrote', CMP)


if __name__ == '__main__':
    main()
