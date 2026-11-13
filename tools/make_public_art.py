#!/usr/bin/env python3
"""Build the public-edition art swaps (`*_pub.*`) from the family-edition art.

Public builds (itch, GitHub Pages root, the advertised APK) load `<name>_pub.<ext>` in place of `<name>.<ext>`
when it exists (`Art.pub()`); the family build (feature tag `family`) never does. Every output keeps its
source's exact pixel size so baked rects (`data/art_rects.json`) and sheet cells still line up.
Why each swap exists: docs/legal/RISK_AUDIT.md.

    python3 tools/make_public_art.py            # writes every *_pub file
    godot --headless --path . --import          # then import them
"""
import colorsys
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art")
FONT = os.path.join(ROOT, "assets", "fonts", "Baloo2-ExtraBold.ttf")

GREEN = (26, 77, 42)
CREAM = (248, 226, 172)
GOLD = (196, 168, 92)
DARK = (18, 34, 22)


def font(size):
    return ImageFont.truetype(FONT, size)


def text_c(d, cx, y, s, f, fill, stroke=0, stroke_fill=None, spacing=0):
    """Draw s centred on cx with its ink top at y (optionally letter-spaced)."""
    if spacing == 0:
        l, t, r, b = d.textbbox((0, 0), s, font=f, stroke_width=stroke)
        d.text((cx - (r - l) / 2 - l, y - t), s, font=f, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)
        return
    widths = [d.textlength(ch, font=f) for ch in s]
    total = sum(widths) + spacing * (len(s) - 1)
    t = d.textbbox((0, 0), s, font=f)[1]
    x = cx - total / 2
    for ch, w in zip(s, widths):
        d.text((x, y - t), ch, font=f, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)
        x += w + spacing


# --- The Twisted Fork -> The Busted Spatula -------------------------------------------------------------
def fork_sign():
    src = Image.open(os.path.join(ART, "sf_fork.png")).convert("RGBA")
    im = src.copy()
    # The fork icon's handle hangs below the plate onto the green band: paint those cream pixels band-green.
    px = im.load()
    for y in range(128, 142):
        for x in range(306, 340):
            r, g, b, a = px[x, y]
            if a > 0 and (r > 120 and g > 100):
                px[x, y] = (34, 86, 44, a)
    # Plate mask: the arch on top of the long rectangle, same footprint as the original plate.
    S = 4  # supersample for smooth edges
    W, H = im.size
    def plate(draw, inset, fill):
        i = inset * S
        draw.rounded_rectangle([(178 * S + i, 84 * S + i), (429 * S - i, 136 * S - i)], radius=5 * S, fill=fill)
        draw.ellipse([(228 * S + i, 61 * S + i), (372 * S - i, 116 * S - i)], fill=fill)
    layers = [(0, DARK), (2, CREAM), (4, GREEN), (6, GOLD), (7, GREEN)]
    big = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(big)
    for inset, col in layers:
        plate(bd, inset, col + (255,))
    small = big.resize((W, H), Image.LANCZOS)
    im.alpha_composite(small)
    d = ImageDraw.Draw(im)
    # Arch: "THE" with a little spatula on each side.
    text_c(d, 300, 71, "THE", font(14), CREAM, spacing=2)
    for sx, flip in ((272, False), (328, True)):
        spat = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
        sd = ImageDraw.Draw(spat)
        sd.rounded_rectangle([(10, 8), (22, 17)], radius=2, fill=CREAM)        # blade
        for k in (13, 16, 19):
            sd.line([(k, 10), (k, 15)], fill=GREEN, width=1)                    # slots
        sd.line([(16, 17), (16, 30)], fill=CREAM, width=3)                     # handle
        sd.line([(15, 23), (18, 26)], fill=GREEN, width=1)                     # the "bust"
        spat = spat.rotate(25 if flip else -25, resample=Image.BICUBIC)
        im.alpha_composite(spat, (int(sx - 16), 68))
    # Main line.
    f = font(27)
    text_c(d, 303, 100, "BUSTED SPATULA", f, CREAM, stroke=1, stroke_fill=DARK, spacing=1)
    return im


# --- Walgrumps: same parody name, no Walgreens red + white script ---------------------------------------
TEAL = (22, 112, 118)
TEAL_D = (12, 70, 76)
MUSTARD = (246, 196, 72)


def walgrumps_sign():
    im = Image.open(os.path.join(ART, "sf_walgrumps.png")).convert("RGBA")
    px = im.load()
    W, H = im.size
    # Red band -> teal, keeping the painted shading (hue swap on reddish pixels only).
    for y in range(66, 104):
        for x in range(10, 296):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if s > 0.35 and (h < 0.05 or h > 0.93) and l < 0.75:
                nh = 0.50
                nr, ng, nb = colorsys.hls_to_rgb(nh, l * 0.92, min(1.0, s * 0.8))
                px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
    # Paint out the script word with the band's own (new) colour, row by row so the shading stays, then
    # block letters.
    for y in range(73, 99):
        row = sorted(px[x, y][:3] for x in list(range(20, 62)) + list(range(208, 214)))
        col = row[len(row) // 2]
        for x in range(64, 208):
            px[x, y] = col + (255,)
    d = ImageDraw.Draw(im)
    text_c(d, 136, 76, "WALGRUMPS", font(21), MUSTARD, stroke=1, stroke_fill=TEAL_D, spacing=1)
    return im


# --- Bruce Willnot -> Rex Tankton (no blond 80s action hero look-alike) --------------------------------
def _recolor_hair_shirt(im, max_x=None, min_x=0):
    """Blond mullet -> near-black hair, off-white tank top -> charcoal. Skin (hue ~20-30 deg, or darker than
    the shirt) is left alone. max_x limits the change to the left of a card (the intro's name side)."""
    px = im.load()
    W, H = im.size
    has_a = im.mode == "RGBA"
    for y in range(H):
        for x in range(min_x, W if max_x is None else max_x):
            p = px[x, y]
            a = p[3] if has_a else 255
            if a == 0:
                continue
            r, g, b = p[:3]
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            hd = h * 360
            out = None
            if 33 <= hd <= 62 and 0.22 < s < 0.72 and 0.18 < l < 0.74:
                out = colorsys.hls_to_rgb(22 / 360, 0.07 + l * 0.30, s * 0.40)          # hair
            elif 26 <= hd <= 44 and 0.72 <= l <= 0.93 and s < 0.85:
                out = colorsys.hls_to_rgb(220 / 360, 0.10 + (l - 0.72) * 1.2, 0.10)     # shirt
            if out:
                v = tuple(int(c * 255) for c in out)
                px[x, y] = v + ((a,) if has_a else ())
    return im


BURST = ((183, 83, 27), (220, 113, 43))
BURST_C = (432, 260)


def _intro_card(src):
    """Recolour the boss, rebuild the sunburst behind the baked name, print the new name."""
    im = _recolor_hair_shirt(src, max_x=520)
    px = im.load()
    W, H = im.size
    x0, y0, x1, y1 = 515, 135, 925, 380
    def burst_at(x, y):
        # Walk outward along the ray until we leave the name box and hit a clean burst pixel.
        cx, cy = BURST_C
        dx, dy = x - cx, y - cy
        d = math.hypot(dx, dy)
        ux, uy = dx / d, dy / d
        t = d
        while True:
            t += 3
            qx, qy = int(cx + ux * t), int(cy + uy * t)
            if not (0 <= qx < W and 0 <= qy < H):
                return BURST[0]
            if x0 <= qx <= x1 and y0 <= qy <= y1:
                continue
            q = px[qx, qy][:3]
            for c in BURST:
                if sum(abs(q[i] - c[i]) for i in range(3)) < 24:
                    return c
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = burst_at(x, y) + (255,)
    d = ImageDraw.Draw(im)
    f = font(96)
    ink = (250, 240, 208)
    edge = (40, 28, 40)
    text_c(d, 715, 168, "Rex", f, ink, stroke=7, stroke_fill=edge)
    text_c(d, 715, 268, "Tankton", f, ink, stroke=7, stroke_fill=edge)
    return im


def willnot_set():
    out = {}
    for rel in ("ch_willnot.png", "portraits_hd/willnot.png", "ko/willnot_a.jpg", "ko/willnot_b.jpg", "ko/willnot_c.jpg"):
        src = Image.open(os.path.join(ART, rel))
        im = src.convert("RGBA") if rel.endswith(".png") else src.convert("RGB")
        # ko/willnot_b also shows Duff on the left, and ko/willnot_c has white comic-panel strips in two
        # corners: keep the recolour to the boss's columns there.
        lo, hi = {"ko/willnot_b.jpg": (600, None), "ko/willnot_c.jpg": (300, 760)}.get(rel, (0, None))
        out[rel] = _recolor_hair_shirt(im, max_x=hi, min_x=lo)
    out["boss_intro/willnot.png"] = _intro_card(Image.open(os.path.join(ART, "boss_intro", "willnot.png")).convert("RGBA"))
    return out


def pub_path(rel):
    base, ext = os.path.splitext(rel)
    return os.path.join(ART, base + "_pub" + ext)


def save(rel, im):
    p = pub_path(rel)
    src = Image.open(os.path.join(ART, rel))
    assert im.size == src.size, (rel, im.size, src.size)
    if p.endswith(".jpg"):
        im.convert("RGB").save(p, quality=90)
    else:
        im.save(p)
    print("wrote", os.path.relpath(p, ROOT), im.size)


def main():
    save("sf_fork.png", fork_sign())
    save("sf_walgrumps.png", walgrumps_sign())
    for rel, im in willnot_set().items():
        save(rel, im)


if __name__ == "__main__":
    sys.exit(main())
