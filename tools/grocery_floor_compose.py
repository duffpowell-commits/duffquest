#!/usr/bin/env python3
"""Rebuild bg_grocery (Hy-Whee shopping floor) as a top-down store whose shelves sit exactly on the
minigame's collision rects (scripts/minigames/grocery.gd SHELVES, 320x180 space, x4 = 1280x720).

The painted pieces come from the old perspective backdrop (git 88c80a8:assets/art/bg_grocery.png,
kept locally in grok_art/2026-11-13-hywhee/_work/bg_grocery_old.png):
  - product bays: the front faces of the old aisle end caps, tiled into long horizontal shelf runs
  - back wall: a clean wall column, squeezed into the 56 px band above the floor, plus the old sign
  - front wall: the old window/door strip, cropped (the list bar covers most of it in play)
The floor itself is synthesised in the old floor's colour with a faint tile grid.

Usage: python3 tools/grocery_floor_compose.py SRC_OLD.png assets/art/bg_grocery.png
"""
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 4                                   # minigame unit -> backdrop pixel
SHELVES = [(46, 36, 228, 8), (46, 64, 228, 8), (46, 92, 228, 8), (46, 120, 228, 8)]
FLOOR_TOP = 14 * S                      # 56: wall band above
FLOOR_BOT = 150 * S                     # 600: front wall below
OUTLINE = (34, 26, 30)
W, H = 1280, 720

# product rows on the old end caps (x0, x1) x (y0, y1)
CAPS = [(466, 546), (738, 818), (998, 1078)]
ROWS = [(358, 389), (393, 423), (426, 458), (461, 495)]


def floor(rng):
    base = np.zeros((H, W, 3), np.float32)
    base[:] = (209, 190, 150)
    base += rng.normal(0, 2.2, (H, W, 1)).astype(np.float32)
    # faint 64 px tiles, offset so a seam never sits right under a shelf edge
    # vinyl tiles: a gentle two-tone checker with darker grout lines
    yy, xx = np.mgrid[0:H, 0:W]
    checker = (((xx - 16) // 64 + (yy - 24) // 64) % 2).astype(np.float32)
    base += (checker * 7 - 3.5)[..., None]
    for x in range(16, W, 64):
        base[:, x] -= 14
    for y in range(24, H, 64):
        base[y, :] -= 14
    # the back wall casts a soft band of shade onto the first metre of floor
    shade = np.clip(1.0 - (np.arange(H) - FLOOR_TOP) / 28.0, 0, 1) * (np.arange(H) >= FLOOR_TOP)
    base *= (1.0 - 0.18 * shade)[:, None, None]
    # soft light from the windows at the bottom, darker toward the back wall
    ys = np.linspace(-1, 1, H)[:, None, None]
    base *= (1.0 + 0.04 * ys)
    return base


def back_wall(old, img):
    col = old.crop((336, 0, 364, 124)).resize((28, FLOOR_TOP), Image.LANCZOS)
    for x in range(0, W, 28):
        img.paste(col, (x, 0))
    sign = old.crop((385, 0, 905, 82))
    h = FLOOR_TOP - 8
    sign = sign.resize((int(sign.width * h / sign.height), h), Image.LANCZOS)
    img.paste(sign, ((W - sign.width) // 2, 3))


def front_wall(old, img):
    img.paste(old.crop((0, 548, W, 548 + (H - FLOOR_BOT))), (0, FLOOR_BOT))


def side_walls(img):
    d = ImageDraw.Draw(img)
    for x0 in (0, W - 28):
        d.rectangle((x0, FLOOR_TOP, x0 + 27, FLOOR_BOT - 1), fill=(204, 160, 78))
        d.rectangle((x0 + 10, FLOOR_TOP, x0 + 17, FLOOR_BOT - 1), fill=(150, 42, 36))
    d.line((27, FLOOR_TOP, 27, FLOOR_BOT), fill=OUTLINE, width=2)
    d.line((W - 28, FLOOR_TOP, W - 28, FLOOR_BOT), fill=OUTLINE, width=2)


def shelf_strip(bays, rng, w):
    top_h, face_h, base_h = 16, 32, 6
    h = top_h + face_h + base_h
    st = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(st)
    # top surface: wood plank with a lit front edge
    d.rectangle((0, 0, w - 1, top_h - 1), fill=(150, 108, 62, 255))
    # back row of stock seen over the top: the same bays, short and in shade
    x = 6
    while x < w - 6:
        b = bays[rng.randrange(len(bays))]
        bw2 = rng.randrange(40, 70)
        piece = b.resize((bw2, top_h - 5), Image.LANCZOS)
        piece = Image.eval(piece, lambda v: int(v * 0.72))
        st.paste(piece, (x, 2), None)
        x += bw2 + 2
    d.rectangle((0, top_h - 3, w - 1, top_h - 1), fill=(176, 132, 80, 255))
    # front face: product bays between posts
    post = 4
    n = 11
    bw = (w - post * (n + 1)) // n
    x = post
    order = list(range(len(bays)))
    rng.shuffle(order)
    d.rectangle((0, top_h, w - 1, top_h + face_h - 1), fill=(70, 50, 35, 255))
    for i in range(n):
        b = bays[order[i % len(order)]]
        if rng.random() < 0.5:
            b = b.transpose(Image.FLIP_LEFT_RIGHT)
        st.paste(b.resize((bw, face_h - 1), Image.LANCZOS), (x, top_h + 1))
        x += bw + post
    # kick plate
    d.rectangle((0, top_h + face_h, w - 1, h - 1), fill=(64, 58, 66, 255))
    d.line((0, top_h + face_h, w - 1, top_h + face_h), fill=(110, 104, 112, 255))
    d.rectangle((0, 0, w - 1, h - 1), outline=OUTLINE + (255,), width=2)
    return st


def main(src, out):
    rng = random.Random(7)
    old = Image.open(src).convert("RGB")
    img = Image.fromarray(np.clip(floor(np.random.default_rng(7)), 0, 255).astype(np.uint8))
    back_wall(old, img)
    side_walls(img)
    front_wall(old, img)
    bays = [old.crop((x0, y0, x1, y1)) for (x0, x1) in CAPS for (y0, y1) in ROWS]
    img = img.convert("RGBA")
    for (sx, sy, sw, sh) in SHELVES:
        x0, y0, w = sx * S, sy * S, sw * S
        bottom = (sy + sh) * S + 6
        st = shelf_strip(bays, rng, w)
        # soft floor shadow under and right of the run
        sh_img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(sh_img).rectangle((x0 + 6, bottom - 4, x0 + w + 6, bottom + 8), fill=(40, 28, 20, 110))
        img = Image.alpha_composite(img, sh_img.filter(ImageFilter.GaussianBlur(4)))
        img.alpha_composite(st, (x0, bottom - st.height))
    img.convert("RGB").save(out)
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
