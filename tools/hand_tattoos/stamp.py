#!/usr/bin/env python3
"""Stamp Duff's REAL hand tattoos (+ his left blackout forearm) onto his sprite sheets.

    python3 tools/hand_tattoos/stamp.py              # every sheet in SHEETS, writes before/after
    python3 tools/hand_tattoos/stamp.py duff_home_hd3d   # one sheet

Masters (tools/hand_tattoos/designs.py, from Duff's own photos, Nov 18 2026):
  docs/ref/duff/hand_left_eye_mandala.png  LEFT hand: eye in a ring of teeth in a spiked sun
  docs/ref/duff/hand_right_script.png      RIGHT hand: "This Red / Right Hand / Points Me / South"
  NO ring on either hand (Duff, Nov 18 2026: "Take the ring off").
The left forearm also goes to blackout (docs/duff_look.md: the hand blends into the sleeve).

How a frame is read: skin = opaque warm pixels (+ the old blue tattoo lines inside them). The
head is the skin piece that holds the topmost skin pixel; every other big piece is an arm or a hand.
The arm's anchor is where it leaves the sleeve (or, failing that, its top pixel); the
hand is the band of the piece farthest from that anchor. Facing per row (Art.row_for): row 0 faces
the viewer (his LEFT arm on the viewer's right), row 1 = back (his left on the viewer's left),
row 2 faces screen-right (near arm = his RIGHT), row 3 faces screen-left (near arm = his LEFT).

Originals are read from git (HEAD at the first run, kept in grok_art/hand_tattoos/_work/originals/), so
re-running never double-inks. Size and alpha are asserted unchanged.
"""
import math
import os
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
REF = os.path.join(ROOT, "docs", "ref", "duff")
BACKUP = os.path.join(ROOT, "grok_art", "hand_tattoos", "_work", "originals")
RENDERS = os.path.join(ROOT, "docs", "renders", "hand_tattoos")

INK = np.array([34, 30, 40], float)       # blackout ink (matches tools/tattoo_sprites.py ramp)

# name -> (path, rows, hands_only). rows = facing per sheet row; None = skip that row.
FOUR = ["front", "back", "right", "left"]
SHEETS = {
    "duff_home_hd3d": ("assets/art3d/duff_home_hd3d.png", FOUR, False),
    "duff_home": ("assets/art/duff_home.png", FOUR, False),
    "duff_home_black": ("assets/art/duff_home_black.png", FOUR, False),
    "duff_apron_black": ("assets/art/duff_apron_black.png", FOUR, False),
    "duff_apron_red": ("assets/art/duff_apron_red.png", FOUR, False),
    "duff_clogs_black": ("assets/art/duff_clogs_black.png", FOUR, False),
    "duff_clogs_red": ("assets/art/duff_clogs_red.png", FOUR, False),
    "duff_coat_black": ("assets/art/duff_coat_black.png", FOUR, True),
    "duff_coat_red": ("assets/art/duff_coat_red.png", FOUR, True),
    "duff_dad_black": ("assets/art/duff_dad_black.png", FOUR, False),
    "duff_dad_red": ("assets/art/duff_dad_red.png", FOUR, False),
    "duff_sleeves_black": ("assets/art/duff_sleeves_black.png", FOUR, True),
    "duff_sleeves_red": ("assets/art/duff_sleeves_red.png", FOUR, True),
    "ch_duff_suit": ("assets/art/ch_duff_suit.png", FOUR, True),
}


def load_design(name):
    a = np.asarray(Image.open(os.path.join(REF, name)).convert("RGBA")).astype(float)
    return a[..., 3] / 255.0


def sample(design, u, v):
    """Bilinear sample of a [0,1] alpha design at u,v in [0,1] (u across, v wrist->knuckles)."""
    h, w = design.shape
    x = np.clip(u, 0, 1) * (w - 1)
    y = np.clip(v, 0, 1) * (h - 1)
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int)
    x1 = np.minimum(x0 + 1, w - 1); y1 = np.minimum(y0 + 1, h - 1)
    fx = x - x0; fy = y - y0
    top = design[y0, x0] * (1 - fx) + design[y0, x1] * fx
    bot = design[y1, x0] * (1 - fx) + design[y1, x1] * fx
    return top * (1 - fy) + bot * fy


def masks(cell, strict=True):
    a = cell.astype(float)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    opaque = al > 200
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    tot = r + g + b + 1
    rc, bc = r / tot, b / tot          # chroma: tells skin from the mustard apron and the cream towel
    if strict:   # 2x outfit sheets: tell skin from the mustard apron and the cream towel
        skin = (opaque & (r > 110) & (r > g + 12) & (g > b + 4) & (lum > 100)
                & (rc >= 0.415) & (bc >= 0.17) & (bc <= 0.235))
    else:        # HD 3D sheet: plain tee, no look-alike colours; keeps the whole forearm in one piece
        skin = opaque & (r > 110) & (r > g + 12) & (g > b + 4) & (r - b > 45)
    # old tattoo line work (blue/grey) sitting inside skin counts as arm
    lines = opaque & ~skin & (lum > 35) & (b >= r - 25)
    dark = opaque & (lum < 45)
    lab, n = ndimage.label(dark)
    if n:
        sizes = ndimage.sum(dark, lab, range(1, n + 1))
        shirt = lab == (int(np.argmax(sizes)) + 1)
    else:
        shirt = dark
    return skin, lines, shirt, lum


def shirt_top_of(shirt, C):
    rows = np.nonzero(shirt.sum(1) >= C * 0.10)[0]
    return rows.min() if len(rows) else C * 0.4


def pieces(cell, C):
    skin, lines, shirt, lum = masks(cell, strict=C < 256)
    armish = skin | (lines & ndimage.binary_dilation(skin, iterations=max(1, C // 128)))
    armish = ndimage.binary_closing(armish, iterations=max(1, C // 256)) & (cell[..., 3] > 200)
    lab, n = ndimage.label(armish)
    if n == 0:
        return [], shirt, lum
    ys, xs = np.nonzero(skin)
    if len(ys) == 0:
        return [], shirt, lum
    top = np.argmin(ys)
    head = lab[ys[top], xs[top]]
    out = []
    min_area = (C / 512.0) ** 2 * 260
    hy, hx = np.nonzero(lab == head)
    head_top = hy.min()
    head_cx = hx.mean()
    for k in range(1, n + 1):
        if k == head:
            continue
        m = lab == k
        if m.sum() < min_area:
            continue
        my, mx = np.nonzero(m)
        # ponytail, ears, neck: the whole piece sits inside the head zone (chibi heads are ~0.36C tall)
        if my.max() < head_top + C * 0.36:
            continue
        if abs(mx.mean() - head_cx) < C * 0.10 and my.max() < head_top + C * 0.44:
            continue
        if my.mean() > head_top + C * 0.70:     # down at the feet: shoes, not hands
            continue
        out.append(m)
    clothes = (cell[..., 3] > 200) & ~armish & ~(lab == head)
    clothes[: int(head_top + C * 0.30)] = False   # skillet / hair above the collar never anchors an arm
    return out, clothes, lum


def anchor_of(m, clothes, C):
    """Where the arm leaves the sleeve: piece pixels touching clothes, nearest the shoulders."""
    touch = m & ndimage.binary_dilation(clothes, iterations=max(1, C // 170))
    ys, xs = np.nonzero(touch)
    cy_, cx_ = np.nonzero(clothes)
    if len(ys) == 0 or len(cy_) == 0:
        ys, xs = np.nonzero(m)
        i = np.argmin(ys)
        return np.array([ys[i], xs[i]], float)
    top = cy_.min()
    d = np.abs(ys - top)
    keep = d <= d.min() + C * 0.06
    return np.array([ys[keep].mean(), xs[keep].mean()], float)


def split_hand(m, anc, C, hands_only):
    ys, xs = np.nonzero(m)
    p = np.stack([ys, xs], 1).astype(float)
    dist = np.sqrt(((p - anc) ** 2).sum(1))
    far = p[np.argmax(dist)]
    axis = far - anc
    L = np.linalg.norm(axis)
    if L < 1:
        return None
    axis /= L
    t = (p - anc) @ axis
    band = C * 0.095
    if hands_only and t.max() - t.min() < band * 1.6:
        hand = np.ones(len(p), bool)
    else:
        hand = t >= t.max() - band
    return p, t, axis, hand


def ink_blend(px, lum, alpha, colour):
    """Blend toward ink but keep the sprite's own shading so the fist still reads as round."""
    shade = np.clip(0.55 + lum / 255.0 * 0.9, 0.55, 1.35)[:, None]
    tgt = np.clip(colour[None, :] * shade, 0, 255)
    return px * (1 - alpha[:, None]) + tgt * alpha[:, None]


def stamp_cell(cell, C, facing, hands_only, eye, script):
    out = cell.copy()
    rgb = out[..., :3].astype(float)
    arms, shirt, lum = pieces(cell, C)
    if not arms:
        return out, 0
    info = []
    for m in arms:
        anc = anchor_of(m, shirt, C)
        sp = split_hand(m, anc, C, hands_only)
        if sp is None:
            continue
        info.append((m, anc, sp))
    if not info:
        return out, 0
    # which piece is his LEFT arm
    cx = [sp[0][:, 1].mean() for _, _, sp in info]
    area = [m.sum() for m, _, _ in info]
    left = set()
    if facing == "front":
        if len(info) >= 2:
            left = {int(np.argmax(cx))}
        else:
            left = {0} if cx[0] > C / 2 else set()
    elif facing == "back":
        if len(info) >= 2:
            left = {int(np.argmin(cx))}
        else:
            left = {0} if cx[0] < C / 2 else set()
    elif facing == "left":      # near arm (biggest) = his left
        left = {int(np.argmax(area))}
    elif facing == "right":     # near arm = his right; the far one, if any, is his left
        if len(info) >= 2:
            left = {int(np.argmin(area))}
    n_ink = 0
    for i, (m, anc, (p, t, axis, hand)) in enumerate(info):
        is_left = i in left
        norm = np.array([-axis[1], axis[0]])
        if norm[1] < 0:            # u runs left -> right on screen, so the script never mirrors
            norm = -norm
        hp = p[hand]
        ht = t[hand]
        s = (hp - hp.mean(0)) @ norm
        hw = max(np.abs(s).max(), 1.0)
        u = 0.5 + 0.5 * s / hw
        v = (ht - ht.min()) / max(ht.max() - ht.min(), 1.0)  # wrist 0 -> knuckles 1
        yi = hp[:, 0].astype(int); xi = hp[:, 1].astype(int)
        px = rgb[yi, xi]
        lm = lum[yi, xi]
        if is_left:
            # whole back of the hand is blackwork; the design's gaps are skin
            a = sample(eye, u * 0.84 + 0.08, v * 0.84 + 0.08)
            alpha = 0.35 + 0.65 * a
            new = ink_blend(px, lm, alpha, INK)
            # skin negative space keeps a little of the old skin tone
            # finger dots: a short stacked row on the knuckle edge
            kn = (v > 0.86) & (np.abs(u - 0.38) < 0.05)
            new[kn] = INK * 0.9
            # no ring: Duff, Nov 18 2026, "Take the ring off"
            rgb[yi, xi] = new
            # forearm: blackout with skin chevrons
            if not hands_only:
                fp = p[~hand]
                if len(fp):
                    ft = t[~hand]
                    fs = (fp - fp.mean(0)) @ norm
                    per = C * 0.045
                    chev = ((ft + np.abs(fs) * 0.8) / per) % 1.0
                    a2 = np.where(chev < 0.16, 0.25, 0.92)
                    fy = fp[:, 0].astype(int); fx = fp[:, 1].astype(int)
                    rgb[fy, fx] = ink_blend(rgb[fy, fx], lum[fy, fx], a2, INK)
        else:
            a = sample(script, u * 0.9 + 0.05, v * 0.92 + 0.02)
            k = 0.92 if C >= 256 else 0.6   # tiny hands: keep it script-like, not a black blob
            rgb[yi, xi] = ink_blend(px, lm, a * k, INK)
        n_ink += len(hp)
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    return out, n_ink


def original(path):
    rel = os.path.relpath(path, ROOT)
    bk = os.path.join(BACKUP, rel)
    if not os.path.exists(bk):
        os.makedirs(os.path.dirname(bk), exist_ok=True)
        blob = subprocess.run(["git", "-C", ROOT, "show", "HEAD:" + rel], capture_output=True, check=True).stdout
        open(bk, "wb").write(blob)
    return bk


def run(name):
    rel, rows, hands_only = SHEETS[name]
    path = os.path.join(ROOT, rel)
    src = Image.open(original(path)).convert("RGBA")
    a = np.asarray(src).copy()
    W, H = src.size
    C = W // 4
    eye = load_design("hand_left_eye_mandala.png")
    script = load_design("hand_right_script.png")
    total = 0
    for r, facing in enumerate(rows):
        if facing is None or (r + 1) * C > H:
            continue
        for c in range(4):
            cell = a[r * C:(r + 1) * C, c * C:(c + 1) * C]
            new, n = stamp_cell(cell, C, facing, hands_only, eye, script)
            a[r * C:(r + 1) * C, c * C:(c + 1) * C] = new
            total += n
    out = Image.fromarray(a, "RGBA")
    assert out.size == src.size
    assert np.array_equal(np.asarray(out)[..., 3], np.asarray(src)[..., 3])
    out.save(path)
    os.makedirs(RENDERS, exist_ok=True)
    bg = (110, 150, 110, 255)
    pair = Image.new("RGBA", (W * 2 + 16, H), bg)
    for i, im in enumerate((src, out)):
        layer = Image.new("RGBA", (W, H), bg)
        layer.alpha_composite(im)
        pair.paste(layer, (i * (W + 16), 0))
    pair.convert("RGB").save(os.path.join(RENDERS, name + "_before_after.jpg"), quality=88)
    print(f"{name}: inked {total} hand px")


def main():
    names = sys.argv[1:] or list(SHEETS)
    for n in names:
        run(n)


if __name__ == "__main__":
    main()
