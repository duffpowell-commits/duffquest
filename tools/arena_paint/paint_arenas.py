#!/usr/bin/env python3
"""Paint themed boss-arena backdrops in code, replacing the six identical placeholder rooms.

Deterministic, no network, PIL + numpy only. Run from the repo root:
    python3 tools/arena_paint/paint_arenas.py            # all arenas
    python3 tools/arena_paint/paint_arenas.py alley      # one arena

Writes  assets/art/arena_<id>.png   (640x360 RGB, painted at 320x180 world units, 2x nearest)
        docs/renders/arenas_painted_sheet.png   (contact sheet of every arena, incl. the real gym art)

Layout contract (matches the arena walls in scripts/main.gd, so no wall data changes):
  * y 0..30   back wall (collision band). Props may overhang to y~36, never further.
  * x 0..8 and 312..320 side walls, y 172..180 front ledge (all collision).
  * Every in-code overlay in main.gd/_draw_arena and waffle.gd has a spot reserved for it:
      alley   "FORK - STAFF" plate over the staff door (148..172, y 7..14)
      ghoster "seen" receipts at (60,70) (260,70) (60,140) (260,140)  -> round cafe rugs
      djvape  colour dance floor 8..312 x 30..172 on a 16px grid; "DJ BOOTH" at y 26
      crypto  blinking LEDs at y 8, x = 14 + 24k                      -> one mining rig per 24px
      willnot countdown at y ~38..46 centred                          -> dark floor mat
      waffle  "WAFFLE HAUS" letters x 102..212, y ~5..14; grills at x 90/160/230, y 40; Dolores at (22,92)
"""
import os
import sys
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
W, H = 320, 180
WALL = 30          # back-wall collision band
OUTLINE = (24, 16, 22)


# ------------------------------------------------------------------ canvas helpers
class Canvas:
    def __init__(self, base=(0, 0, 0)):
        self.a = np.zeros((H, W, 3), np.float32)
        self.a[:] = base

    def rect(self, x0, y0, x1, y1, c):
        x0, y0 = max(0, int(x0)), max(0, int(y0))
        x1, y1 = min(W, int(x1)), min(H, int(y1))
        if x1 > x0 and y1 > y0:
            self.a[y0:y1, x0:x1] = c

    def box(self, x0, y0, x1, y1, c, hi=None, lo=None, line=OUTLINE):
        """Filled box with 1px outline, top highlight and bottom shade."""
        self.rect(x0, y0, x1, y1, line)
        self.rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, c)
        if hi:
            self.rect(x0 + 1, y0 + 1, x1 - 1, y0 + 2, hi)
        if lo:
            self.rect(x0 + 1, y1 - 2, x1 - 1, y1 - 1, lo)

    def noise(self, x0, y0, x1, y1, amp, seed, scale=1):
        rng = np.random.default_rng(seed)
        x0, y0, x1, y1 = max(0, x0), max(0, y0), min(W, x1), min(H, y1)
        h, w = y1 - y0, x1 - x0
        n = rng.integers(-1, 2, ((h + scale - 1) // scale, (w + scale - 1) // scale)).astype(np.float32)
        n = np.kron(n, np.ones((scale, scale)))[:h, :w]
        self.a[y0:y1, x0:x1] += (n * amp)[..., None]

    def shade(self, x0, y0, x1, y1, f):
        x0, y0, x1, y1 = max(0, x0), max(0, y0), min(W, x1), min(H, y1)
        self.a[y0:y1, x0:x1] *= f

    def vgrad(self, x0, y0, x1, y1, f0, f1):
        """Multiply a vertical ramp f0 -> f1 over the box."""
        x0, y0, x1, y1 = max(0, x0), max(0, y0), min(W, x1), min(H, y1)
        r = np.linspace(f0, f1, y1 - y0, dtype=np.float32)[:, None, None]
        self.a[y0:y1, x0:x1] *= r

    def glow(self, cx, cy, rx, ry, col, strength):
        """Additive soft light pool (elliptical)."""
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        d = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
        k = np.clip(1.0 - d, 0, 1) ** 2 * (strength / 100.0)
        self.a += k[..., None] * np.array(col, np.float32)[None, None, :]

    def disc(self, cx, cy, rx, ry, c, ring=None):
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        d = ((xx - cx + 0.5) / rx) ** 2 + ((yy - cy + 0.5) / ry) ** 2
        if ring is not None:
            self.a[d <= 1.0] = ring
            d2 = ((xx - cx + 0.5) / (rx - 1)) ** 2 + ((yy - cy + 0.5) / (ry - 1)) ** 2
            self.a[d2 <= 1.0] = c
        else:
            self.a[d <= 1.0] = c

    def shadow_disc(self, cx, cy, rx, ry, f=0.6):
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
        d = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
        self.a[d <= 1.0] *= f

    def px(self, x, y, c):
        if 0 <= x < W and 0 <= y < H:
            self.a[int(y), int(x)] = c

    def image(self):
        return Image.fromarray(np.clip(self.a, 0, 255).astype(np.uint8), "RGB")


def frame(cv, side=(46, 40, 52), side_hi=(78, 70, 86), ledge=(40, 34, 44)):
    """Side walls, front ledge, wall-foot contact shadow, soft vignette."""
    cv.vgrad(8, WALL + 3, 312, WALL + 12, 0.62, 1.0)          # contact shadow under the back wall
    for x0, x1, edge in ((0, 8, 7), (312, 320, 312)):
        cv.rect(x0, 0, x1, H, side)
        cv.noise(x0, 0, x1, H, 4, 99 + x0, 2)
        cv.rect(edge, 0, edge + 1, H, side_hi)
    cv.rect(0, 172, W, H, ledge)
    cv.rect(0, 172, W, 173, side_hi)
    cv.noise(0, 173, W, H, 3, 77, 2)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    v = 1.0 - 0.22 * (((xx - 160) / 170) ** 2 + ((yy - 100) / 110) ** 2)
    cv.a *= np.clip(v, 0.7, 1.0)[..., None]


def bricks(cv, y0, y1, base, mortar, seed, bw=12, bh=5):
    cv.rect(8, y0, 312, y1, mortar)
    rng = np.random.default_rng(seed)
    row = 0
    for y in range(y0, y1, bh):
        off = 0 if row % 2 == 0 else bw // 2
        for x in range(8 - off, 312, bw):
            k = rng.uniform(0.82, 1.12)
            c = tuple(v * k for v in base)
            cv.rect(max(8, x + 1), y + 1, min(312, x + bw), min(y1, y + bh), c)
            cv.rect(max(8, x + 1), y + 1, min(312, x + bw), y + 2, tuple(min(255, v * 1.15) for v in c))
        row += 1


def planks(cv, y0, y1, base, seed, ph=6):
    rng = np.random.default_rng(seed)
    for y in range(y0, y1, ph):
        x = 8 - int(rng.integers(0, 40))
        while x < 312:
            ln = int(rng.integers(36, 80))
            k = rng.uniform(0.86, 1.1)
            c = tuple(v * k for v in base)
            cv.rect(max(8, x), y, min(312, x + ln), min(y1, y + ph), c)
            cv.rect(max(8, x), y + ph - 1, min(312, x + ln), min(y1, y + ph), tuple(v * 0.62 for v in base))
            cv.rect(max(8, x + ln - 1), y, min(312, x + ln), min(y1, y + ph - 1), tuple(v * 0.7 for v in base))
            x += ln
    cv.noise(8, y0, 312, y1, 5, seed + 1, 1)


def tiles(cv, x0, y0, x1, y1, ca, cb, size, grout=None, seed=1, amp=3):
    for ty, y in enumerate(range(y0, y1, size)):
        for tx, x in enumerate(range(x0, x1, size)):
            c = ca if (tx + ty) % 2 == 0 else cb
            cv.rect(x, y, min(x1, x + size), min(y1, y + size), c)
            if grout:
                cv.rect(x, y, min(x1, x + size), y + 1, grout)
                cv.rect(x, y, x + 1, min(y1, y + size), grout)
    cv.noise(x0, y0, x1, y1, amp, seed, 1)


def text_px(cv, x, y, s, c, scale=1):
    """Tiny 3x5 pixel font (caps + digits) for painted signage."""
    F = {
        "A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110",
        "E": "111100110100111", "F": "111100110100100", "G": "011100101101011", "H": "101101111101101",
        "I": "111010010010111", "K": "101101110101101", "L": "100100100100111", "M": "101111111101101",
        "N": "110101101101101", "O": "010101101101010", "P": "110101110100100", "R": "110101110101101",
        "S": "011100010001110", "T": "111010010010010", "U": "101101101101111", "V": "101101101101010",
        "W": "101101111111101", "Y": "101101010010010", "0": "111101101101111", "1": "010110010010111",
        "2": "110001010100111", "3": "110001010001110", "4": "101101111001001", "5": "111100110001110",
        "6": "011100111101111", "7": "111001010010010", "8": "111101111101111", "9": "111101111001110",
        "!": "010010010000010", "%": "101001010100101", "$": "011110010011110", "-": "000000111000000",
        "/": "001001010100100", ".": "000000000000010", "'": "010010000000000", ":": "000010000010000",
    }
    cx = x
    for ch in s:
        if ch == " ":
            cx += 4 * scale
            continue
        g = F.get(ch)
        if g:
            for i, b in enumerate(g):
                if b == "1":
                    cv.rect(cx + (i % 3) * scale, y + (i // 3) * scale, cx + (i % 3 + 1) * scale, y + (i // 3 + 1) * scale, c)
        cx += 4 * scale
    return cx


# ------------------------------------------------------------------ arenas
def alley():
    """Behind the Twisted Fork: brick back wall, staff door + lamp, dumpster, crates, wet asphalt."""
    cv = Canvas((44, 46, 54))
    # asphalt: blue-grey, coarse grain, slight warm cast from the door lamp
    cv.noise(8, WALL, 312, 172, 5, 11, 1)
    cv.noise(8, WALL, 312, 172, 4, 12, 3)
    rng = np.random.default_rng(13)
    for _ in range(9):  # cracks
        x, y = rng.integers(20, 300), rng.integers(50, 165)
        for _k in range(int(rng.integers(6, 16))):
            cv.px(x, y, (28, 28, 34))
            x += int(rng.integers(-1, 2)) or 1
            y += int(rng.integers(-1, 2))
    # painted loading-zone stripes
    for x in range(22, 300, 26):
        cv.rect(x, 156, x + 14, 158, (150, 128, 52))
    cv.noise(8, 156, 312, 158, 10, 14, 1)
    # puddles (reflect the lamp)
    for cx, cy, rx, ry in ((96, 128, 22, 6), (232, 104, 16, 5), (196, 150, 12, 3)):
        cv.disc(cx, cy, rx, ry, (40, 52, 70))
        cv.disc(cx - 3, cy - 1, rx * 0.55, max(1, ry * 0.45), (70, 88, 110))
    # back wall: dark red brick
    bricks(cv, 0, WALL + 3, (104, 48, 40), (52, 40, 40), 15)
    cv.vgrad(8, 0, 312, WALL + 3, 0.7, 1.0)
    # grease stain + kitchen exhaust vent
    cv.box(214, 5, 238, 17, (88, 92, 98), (128, 132, 138), (56, 58, 64))
    for y in range(7, 16, 2):
        cv.rect(216, y, 236, y + 1, (40, 42, 48))
    cv.shade(216, 17, 236, 31, 0.72)
    # staff door with lamp: plate for the in-code "FORK - STAFF" label
    cv.box(146, 3, 175, 34, (46, 84, 86), (70, 116, 118), (30, 56, 58))
    cv.rect(160, 4, 161, 33, (30, 56, 58))
    cv.box(147, 6, 173, 15, (214, 200, 164), (236, 226, 196), (170, 156, 120))
    cv.rect(169, 20, 172, 23, (200, 176, 80))  # handle
    cv.box(156, 0, 165, 4, (60, 60, 64))      # lamp
    cv.rect(157, 3, 164, 4, (255, 220, 140))
    cv.glow(160, 40, 70, 46, (255, 196, 110), 46)
    cv.glow(96, 127, 18, 4, (255, 210, 140), 30)
    # 86 list taped to the wall
    cv.box(122, 9, 138, 25, (232, 228, 214), (250, 248, 240), (196, 190, 172))
    text_px(cv, 124, 11, "86", (180, 30, 30))
    for y in range(18, 24, 2):
        cv.rect(124, y, 136, y + 1, (120, 116, 108))
    # dumpster (left)
    cv.shadow_disc(40, 37, 34, 6, 0.55)
    cv.box(12, 10, 70, 35, (44, 98, 64), (64, 132, 88), (28, 66, 42))
    cv.box(10, 7, 72, 12, (36, 80, 52), (58, 116, 78))
    for x in range(18, 66, 9):
        cv.rect(x, 14, x + 1, 33, (32, 74, 48))
    text_px(cv, 26, 20, "FORK", (220, 220, 200))
    # trash bags
    for cx, cy in ((80, 30), (88, 34), (76, 36)):
        cv.disc(cx, cy, 7, 5, (26, 26, 30), ring=OUTLINE)
        cv.rect(cx - 2, cy - 4, cx + 1, cy - 3, (60, 60, 70))
    # crates + barrel (right)
    cv.shadow_disc(270, 37, 40, 5, 0.55)
    for x0, y0 in ((248, 14), (268, 14), (258, 2)):
        cv.box(x0, y0, x0 + 20, y0 + 20, (150, 108, 62), (184, 138, 84), (104, 72, 40))
        cv.rect(x0 + 1, y0 + 9, x0 + 19, y0 + 11, (104, 72, 40))
    cv.box(290, 12, 306, 35, (70, 74, 90), (100, 104, 122), (46, 48, 60))
    cv.rect(291, 18, 305, 19, (46, 48, 60))
    cv.rect(291, 28, 305, 29, (46, 48, 60))
    text_px(cv, 292, 21, "OIL", (200, 180, 90))
    frame(cv, (54, 34, 34), (90, 58, 52), (34, 30, 36))
    return cv


def ghoster():
    """Seen Cafe: cream wall over wood wainscot, espresso counter, chalkboard, wood floor, read-receipt rugs."""
    cv = Canvas((150, 104, 70))
    planks(cv, WALL, 172, (150, 104, 70), 21)
    # rugs under the in-code "seen" receipts
    for cx, cy in ((60, 72), (260, 72), (60, 142), (260, 142)):
        cv.shadow_disc(cx, cy + 2, 20, 9, 0.75)
        cv.disc(cx, cy, 19, 9, (70, 92, 136), ring=(40, 54, 86))
        cv.disc(cx, cy, 13, 6, (96, 122, 170))
        # double check mark
        for i, (dx, dy) in enumerate(((-6, 0), (-5, 1), (-4, 2), (-3, 1), (-2, 0), (-1, -1), (0, -2))):
            cv.px(cx + dx, cy + dy, (222, 236, 255))
            cv.px(cx + dx + 4, cy + dy, (222, 236, 255))
    # back wall: cream plaster + wood wainscot
    cv.rect(8, 0, 312, 20, (226, 212, 184))
    cv.noise(8, 0, 312, 20, 3, 22, 2)
    cv.rect(8, 20, 312, WALL + 3, (110, 70, 44))
    for x in range(8, 312, 10):
        cv.rect(x, 21, x + 1, WALL + 3, (84, 52, 32))
    cv.rect(8, 20, 312, 21, (160, 112, 72))
    # chalkboard menu (left) + "SEEN" sign
    cv.box(22, 3, 76, 19, (40, 50, 46), None, None, (104, 70, 42))
    text_px(cv, 25, 5, "LATTE 5", (232, 232, 220))
    text_px(cv, 25, 11, "GHOST 0", (232, 232, 220))
    cv.box(250, 3, 296, 13, (64, 78, 120), (90, 108, 156), (44, 54, 86))
    text_px(cv, 258, 5, "SEEN", (220, 232, 255))
    # pendant lights
    for x in (110, 160, 210):
        cv.rect(x, 0, x + 1, 5, (60, 50, 44))
        cv.box(x - 4, 5, x + 5, 9, (210, 160, 70), (240, 200, 110))
        cv.glow(x, 26, 30, 20, (255, 214, 140), 22)
    # espresso counter across the middle of the wall
    cv.shadow_disc(160, 36, 70, 4, 0.6)
    cv.box(96, 18, 224, 35, (122, 78, 50), (150, 102, 66), (86, 52, 32))
    cv.rect(97, 18, 223, 21, (212, 206, 196))          # marble top
    cv.box(104, 9, 128, 21, (180, 184, 192), (220, 224, 230), (130, 134, 142))  # espresso machine
    cv.rect(110, 14, 112, 18, (40, 40, 44))
    cv.rect(120, 14, 122, 18, (40, 40, 44))
    cv.box(190, 12, 214, 21, (236, 228, 210), (250, 246, 236))  # pastry case
    for x in (194, 202, 208):
        cv.disc(x, 17, 2, 2, (200, 140, 70))
    # plants in the corners
    for x in (12, 292):
        cv.box(x, 22, x + 14, 34, (170, 90, 60), (200, 116, 80))
        for dx, dy in ((2, 14), (7, 10), (12, 14), (4, 18), (10, 18)):
            cv.disc(x + dx, dy, 4, 4, (60, 120, 70))
    frame(cv, (96, 64, 44), (140, 98, 66), (78, 52, 36))
    return cv


def djvape():
    """Club Cloud 9: black glossy dance floor on the 16px grid, speaker stacks, DJ booth, neon clouds."""
    cv = Canvas((20, 16, 30))
    # dance floor tiles (the colour wash is animated in code on the same grid)
    for y in range(30, 172, 16):
        for x in range(8, 312, 16):
            cv.box(x, y, x + 16, y + 16, (28, 22, 42), (44, 36, 64), (18, 14, 28), (12, 10, 18))
    cv.noise(8, WALL, 312, 172, 3, 31, 1)
    # vape fog along the front
    rng = np.random.default_rng(32)
    for _ in range(26):
        cv.glow(rng.uniform(10, 310), rng.uniform(154, 176), rng.uniform(14, 30), rng.uniform(4, 8), (150, 140, 190), 12)
    # back wall: acoustic foam
    cv.rect(8, 0, 312, WALL + 3, (34, 24, 52))
    for y in range(0, WALL + 3, 6):
        for x in range(8, 312, 6):
            cv.rect(x + 1, y + 1, x + 5, y + 5, (44, 32, 68) if (x // 6 + y // 6) % 2 else (38, 28, 60))
    # neon CLOUD 9 + clouds
    cv.glow(160, 8, 60, 10, (255, 60, 200), 40)
    text_px(cv, 132, 3, "CLOUD 9", (255, 120, 230), 2)
    for cx in (60, 260):
        for dx, r in ((-8, 5), (0, 7), (8, 5)):
            cv.disc(cx + dx, 10, r, r - 1, (90, 60, 120), ring=(255, 120, 230))
        cv.glow(cx, 10, 24, 12, (255, 80, 210), 28)
    # speaker stacks
    for x0 in (14, 278):
        cv.shadow_disc(x0 + 14, 37, 18, 4, 0.5)
        for i, y0 in enumerate((2, 18)):
            cv.box(x0, y0, x0 + 28, y0 + 17, (22, 20, 26), (40, 38, 46), (14, 12, 18))
            cv.disc(x0 + 14, y0 + 8, 6, 6, (50, 48, 58), ring=(10, 10, 12))
            cv.disc(x0 + 14, y0 + 8, 2, 2, (90, 88, 100))
    # DJ booth (front panel stays dark so the cyan "DJ BOOTH" label reads)
    cv.shadow_disc(160, 37, 46, 4, 0.5)
    cv.box(118, 15, 202, 35, (16, 14, 24), (40, 220, 255), (10, 8, 16))
    cv.rect(119, 16, 201, 18, (60, 56, 76))                  # deck top
    for x in (128, 176):
        cv.disc(x + 8, 17, 6, 2, (24, 24, 30), ring=(90, 90, 110))
    cv.rect(150, 16, 170, 18, (90, 255, 220))                # mixer LEDs
    cv.glow(160, 30, 56, 12, (40, 200, 255), 26)
    frame(cv, (26, 18, 40), (64, 46, 96), (18, 12, 28))
    return cv


def crypto():
    """The Mining Rig garage: a wall of GPU racks (code blinks their LEDs), cables, a suspicious rug."""
    cv = Canvas((112, 112, 110))
    # concrete slab: control joints, oil stains
    cv.noise(8, WALL, 312, 172, 5, 41, 1)
    cv.noise(8, WALL, 312, 172, 4, 42, 4)
    for x in (88, 168, 248):
        cv.rect(x, WALL + 3, x + 1, 172, (84, 84, 84))
    cv.rect(8, 104, 312, 105, (84, 84, 84))
    for cx, cy, r in ((40, 140, 10), (212, 70, 7), (280, 150, 9)):
        cv.disc(cx, cy, r, r * 0.45, (70, 68, 66))
        cv.disc(cx + 2, cy, r * 0.5, r * 0.25, (58, 56, 56))
    # the rug (don't stand on it)
    cv.shadow_disc(160, 120, 44, 18, 0.8)
    cv.box(118, 104, 202, 136, (150, 44, 52), (180, 64, 70), (110, 30, 38))
    cv.box(126, 110, 194, 130, (210, 168, 70), None, None, (110, 30, 38))
    cv.box(132, 114, 188, 126, (150, 44, 52), None, None, (110, 30, 38))
    text_px(cv, 141, 117, "HODL", (232, 200, 100))
    for x in range(120, 202, 3):
        cv.rect(x, 101, x + 1, 104, (220, 200, 160))
        cv.rect(x, 136, x + 1, 139, (220, 200, 160))
    # cables sagging from the rigs to the power strip
    for k, col in enumerate(((30, 30, 34), (170, 48, 40), (40, 60, 150), (30, 30, 34), (200, 170, 40))):
        x0, y0, x1, y1 = 22 + k * 64, 35, 58 + k * 5, 91
        for i in range(200):
            u = i / 199.0
            x = x0 + (x1 - x0) * u
            y = y0 + (y1 - y0) * u + 10 * np.sin(np.pi * u) + 3 * np.sin(u * 9 + k)
            cv.rect(round(x), round(y), round(x) + 1, round(y) + 1, col)
    # power strip + box fan
    cv.box(54, 88, 84, 94, (220, 220, 214), (240, 240, 236), (170, 170, 166))
    for x in range(58, 82, 5):
        cv.rect(x, 90, x + 2, 92, (40, 40, 40))
    cv.rect(57, 89, 59, 90, (255, 60, 40))
    cv.box(250, 52, 280, 80, (190, 196, 204), (220, 226, 232), (150, 156, 164))
    cv.disc(265, 66, 11, 11, (60, 64, 72), ring=(120, 124, 132))
    cv.disc(265, 66, 3, 3, (160, 164, 172))
    # back wall: cinder block + pegboard band
    cv.rect(8, 0, 312, WALL + 3, (140, 136, 126))
    for y in range(0, WALL + 3, 8):
        off = 0 if (y // 8) % 2 == 0 else 8
        for x in range(8 - off, 312, 16):
            cv.rect(max(8, x), y, min(312, x + 16), y + 1, (110, 106, 98))
            cv.rect(max(8, x), y, max(8, x) + 1, y + 8, (110, 106, 98))
    # rigs: one open frame per 24px, LEDs at y 8 are blinked in code
    for i, x in enumerate(range(12, 308, 24)):
        cv.box(x, 2, x + 21, 34, (26, 28, 32), (52, 56, 62), (16, 16, 20))
        for y in range(12, 32, 5):
            cv.box(x + 2, y, x + 19, y + 4, (52, 58, 66), (80, 88, 98), None, (10, 10, 12))
            cv.disc(x + 7, y + 2, 1.6, 1.6, (30, 30, 34))
            cv.disc(x + 14, y + 2, 1.6, 1.6, (30, 30, 34))
        cv.rect(x + 2, 6, x + 19, 7, (20, 60, 30))
    cv.glow(160, 20, 170, 20, (60, 255, 120), 16)
    frame(cv, (96, 94, 88), (132, 130, 122), (70, 68, 64))
    return cv


def willnot():
    """30th floor of the tower: night skyline windows, cubicle row, carpet tiles, a mat under the countdown."""
    cv = Canvas((72, 78, 96))
    tiles(cv, 8, WALL, 312, 172, (72, 78, 96), (64, 70, 88), 12, (56, 60, 76), 51, 3)
    # countdown mat (code draws the red timer here)
    cv.box(104, 34, 216, 50, (26, 20, 24), (60, 20, 24), (14, 10, 12))
    cv.glow(160, 44, 70, 14, (255, 40, 40), 26)
    # office chairs + a cubicle wall on each side of the floor
    for cx, cy in ((36, 92), (284, 92), (40, 150), (280, 150)):
        cv.shadow_disc(cx, cy + 4, 9, 4, 0.6)
        cv.disc(cx, cy, 7, 5, (40, 40, 48), ring=OUTLINE)
        cv.rect(cx - 6, cy - 9, cx + 7, cy - 4, (40, 40, 48))
        cv.rect(cx - 6, cy - 9, cx + 7, cy - 8, (70, 70, 82))
    # back wall: floor-to-ceiling glass, night skyline
    cv.rect(8, 0, 312, WALL + 3, (14, 18, 40))
    cv.vgrad(8, 0, 312, 20, 0.7, 1.3)
    rng = np.random.default_rng(52)
    x = 8
    while x < 312:
        bw, bh = int(rng.integers(8, 20)), int(rng.integers(6, 20))
        cv.rect(x, 20 - bh, x + bw, 20, (24, 28, 52))
        for wy in range(20 - bh + 2, 19, 3):
            for wx in range(x + 2, x + bw - 1, 3):
                if rng.uniform() < 0.45:
                    cv.px(wx, wy, (255, 214, 120))
        x += bw + int(rng.integers(0, 3))
    for x in range(8, 312, 38):
        cv.rect(x, 0, x + 2, WALL + 3, (90, 96, 110))   # window mullions
    # cubicle row where the beaten exes watch
    cv.rect(8, 20, 312, WALL + 3, (120, 128, 142))
    cv.rect(8, 20, 312, 21, (170, 176, 190))
    for x in range(8, 312, 40):
        cv.rect(x, 20, x + 1, WALL + 3, (86, 92, 104))
        cv.box(x + 12, 13, x + 28, 22, (30, 34, 44), (90, 160, 220), (20, 22, 30))   # monitor
        cv.rect(x + 19, 22, x + 21, 25, (40, 40, 48))
    # the big red clock housing
    cv.box(140, 2, 180, 13, (40, 10, 14), (120, 24, 30), (24, 6, 8))
    text_px(cv, 147, 5, "0:00", (255, 60, 50))
    cv.glow(160, 8, 34, 10, (255, 40, 40), 30)
    frame(cv, (60, 64, 80), (104, 110, 128), (44, 46, 60))
    return cv


def waffle():
    """Waffle Haus kitchen: yellow sign board, subway tile, three grills on the line, checker floor."""
    cv = Canvas((200, 60, 50))
    tiles(cv, 8, WALL, 312, 172, (196, 52, 46), (232, 226, 210), 12, None, 61, 3)
    cv.vgrad(8, WALL, 312, 172, 1.0, 0.86)
    # Dolores' station mat
    cv.box(10, 78, 36, 104, (52, 52, 56), (76, 76, 80), (36, 36, 40))
    for y in range(81, 102, 3):
        cv.rect(12, y, 34, y + 1, (40, 40, 44))
    # back wall: white subway tile
    cv.rect(8, 0, 312, WALL + 3, (226, 226, 220))
    for y in range(0, WALL + 3, 4):
        off = 0 if (y // 4) % 2 == 0 else 4
        for x in range(8 - off, 312, 8):
            cv.rect(max(8, x), y, min(312, x + 8), y + 1, (190, 192, 188))
            cv.rect(max(8, x), y, max(8, x) + 1, y + 4, (190, 192, 188))
    # sign board behind the in-code letters
    cv.box(98, 2, 216, 17, (250, 200, 40), (255, 226, 110), (200, 150, 20))
    cv.glow(157, 10, 70, 10, (255, 220, 120), 18)
    # the line: steel counter with three grills (code draws tickets/plates at y ~45..56)
    cv.shadow_disc(160, 42, 120, 5, 0.6)
    cv.box(60, 24, 260, 40, (160, 166, 172), (210, 214, 220), (110, 114, 120))
    for gx in (90, 160, 230):
        cv.box(gx - 18, 26, gx + 18, 38, (40, 40, 44), (80, 80, 86), (24, 24, 28))
        for y in range(28, 37, 2):
            cv.rect(gx - 16, y, gx + 16, y + 1, (60, 60, 66))
        cv.glow(gx, 32, 20, 6, (255, 120, 40), 18)
    # hood over the line + menu boards
    cv.box(54, 18, 266, 24, (130, 136, 142), (170, 176, 182), (96, 100, 106))
    for x0, s in ((14, "WAFFLE 4"), (244, "HASH 3")):
        cv.box(x0, 4, x0 + 50, 14, (30, 30, 34), None, None, (120, 90, 50))
        text_px(cv, x0 + 3, 6, s, (240, 230, 200))
    frame(cv, (150, 150, 146), (200, 200, 196), (110, 110, 108))
    return cv


ARENAS = {"alley": alley, "ghoster": ghoster, "djvape": djvape, "crypto": crypto, "willnot": willnot, "waffle": waffle}


def main(names):
    out = {}
    for n in names:
        img = ARENAS[n]().image().resize((640, 360), Image.NEAREST)
        img.save(os.path.join(ROOT, "assets/art/arena_%s.png" % n))
        out[n] = img
        print("wrote assets/art/arena_%s.png" % n)
    if len(names) == len(ARENAS):
        order = ["alley", "ghoster", "gymbro", "djvape", "crypto", "willnot", "waffle"]
        sheet = Image.new("RGB", (640 * 2 + 12, (360 + 6) * 4), (20, 20, 24))
        for i, n in enumerate(order):
            im = out.get(n) or Image.open(os.path.join(ROOT, "assets/art/arena_%s.png" % n)).convert("RGB")
            sheet.paste(im, ((i % 2) * (640 + 12), (i // 2) * 366))
        p = os.path.join(ROOT, "docs/renders/arenas_painted_sheet.png")
        sheet.save(p)
        print("wrote", os.path.relpath(p, ROOT))


if __name__ == "__main__":
    main(sys.argv[1:] or list(ARENAS))
