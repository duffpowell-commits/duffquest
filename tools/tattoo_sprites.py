#!/usr/bin/env python3
"""Ink Duff's tattoos onto his walking/outfit sprite sheets (deterministic pixel recolour, no AI edit).

    python3 tools/tattoo_sprites.py            # ink every sheet, write before/after renders
    python3 tools/tattoo_sprites.py --check    # dry run: report counts, write nothing

Rules (docs/duff_look.md, docs/art_rules.md D2-D5, S2, S4):
  * HIS LEFT arm  -> near-black blackout sleeve, a few skin dots left as negative-space geometry,
                     back of the hand dark with one pale centre pixel (eye in the triangle ring).
  * HIS RIGHT arm -> grey-wash on the top (upper-arm) row, dark forearm patch with one orange eye
                     pixel (the creature head), one dark row on the back of the hand (blackletter).
  * Fox: one or two blue-grey pixels on HIS LEFT side of the neck where that side is visible.

Facing per row (Art.row_for): row 0 = faces viewer (his left arm on the VIEWER'S RIGHT), row 1 = back
(his left on the VIEWER'S LEFT), row 2 = faces screen-right (we see his RIGHT side: near arm = right),
row 3 = faces screen-left (we see his LEFT side: near arm = left). Rows 2 and 3 were byte mirrors; they
are inked separately so the sleeve never swaps arms.

Only opaque pixels that were measured as skin are changed. Image size and the whole alpha channel are
asserted unchanged. Sources are always read from the backup folder, so re-running never double-inks.
"""
import colorsys
import os
import shutil
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art")
BACKUP = os.path.join(ROOT, "grok_art", "2026-11-09-sprites-backup")
RENDERS = os.path.join(ROOT, "docs", "renders", "sprite_tattoos")
C = 64

INK = [(0x2e, 0x2a, 0x36), (0x21, 0x1d, 0x28), (0x15, 0x12, 0x1a)]  # sleeve ramp: hi / mid / shadow
PATCH = (0x2b, 0x25, 0x30)        # creature head / hand script
ORANGE = (0xff, 0x8a, 0x1f)       # creature eye
GREY = (0x77, 0x73, 0x7d)         # grey-wash target (40% blend)
FOX = [(0x8f, 0xb0, 0xc8), (0x5d, 0x78, 0x90)]  # pale blue crystal + its shadow

# Per-sheet layout. facing per (row, col) cell; style "new" = 26u detailed sheets, "old" = chibi.
STD = {"rows": ["front", "back", "right", "left"], "style": "new"}
SHEETS = {
    "duff_apron_black": STD, "duff_apron_red": STD,
    "duff_clogs_black": STD, "duff_clogs_red": STD,
    "duff_coat_black": STD, "duff_coat_red": STD,     # chef coat has short sleeves: forearms are bare
    "duff_dad_black": STD, "duff_dad_red": STD,
    "duff_sleeves_black": STD, "duff_sleeves_red": STD,
    "duff_home": STD,
    "duff_shades": None,                              # sunglasses overlay only, no skin
    # Tux: the skin below the jacket cuff is read as hands (D7: the jacket covers the forearms).
    "ch_duff_suit": dict(STD, hands_only=True),
    # Roll: one row, frame k is frame 0 rotated 90 deg CCW k times.
    "duff_roll_black": {"rows": ["roll"], "style": "old"},
    "duff_roll_red": {"rows": ["roll"], "style": "old"},
    # Dress-up chibi: long white shirt sleeves, only the 5-px fists show. Profile row skipped: both
    # fists stick straight out front and back, so there is no near/far arm to tell left from right.
    "duff_dress": {"rows": ["front", "back", None], "style": "old", "hands_only": True},
}


def hsv(p):
    return colorsys.rgb_to_hsv(p[0] / 255, p[1] / 255, p[2] / 255)


def measure_skin(im, style):
    """Median chroma ratios (g/r, b/r) and bright-skin red level, measured from the front idle face."""
    box = (22, 18, 42, 34) if style == "new" else (20, 10, 44, 30)
    if style == "old" and im.size[1] == 64:
        box = (20, 14, 44, 28)
    gr, br, rr = [], [], []
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            r, g, b, a = im.getpixel((x, y))
            if a < 255 or r < 120:
                continue
            h, s, v = hsv((r, g, b))
            if 0.03 <= h <= 0.11 and s > 0.4 and v > 0.6:
                gr.append(g / r); br.append(b / r); rr.append(r)
    assert len(gr) > 40, "could not measure skin"
    med = lambda l: sorted(l)[len(l) // 2]
    return med(gr), med(br), med(rr)


def make_is_skin(mg, mb):
    def is_skin(p):
        r, g, b, a = p
        if a < 255 or r < 70:
            return False
        return abs(g / r - mg) < 0.09 and abs(b / r - mb) < 0.13 and r - b > 50
    return is_skin


def is_skin_shade(p):
    """Darker skin shading/edge pixels next to a detected arm (never apron tan, hair or outline)."""
    r, g, b, a = p
    if a < 255 or r < 60:
        return False
    h, s_, v = hsv((r, g, b))
    return h <= 0.12 and s_ > 0.4 and g / r < 0.75 and b / r < 0.47


# local <-> unrotated coords for roll frames (rotation by k quarter turns CCW about the cell centre)
def unrot(x, y, k):
    dx, dy = x - 32, y - 32
    for _ in range(k):
        dx, dy = -dy, dx
    return dx + 32, dy + 32


def components(pts):
    pts = set(pts); out = []
    while pts:
        s = pts.pop(); st = [s]; comp = [s]
        while st:
            x, y = st.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    q = (x + dx, y + dy)
                    if q in pts:
                        pts.remove(q); st.append(q); comp.append(q)
        out.append(comp)
    return out


def ink_arm(px, comp, side, hands_only, rmed, orig):
    """comp: list of (cellx, celly, ux, uy) with unrotated coords (ux, uy). px: dict to fill."""
    U = {(c[2], c[3]): (c[0], c[1]) for c in comp}
    v0 = min(u[1] for u in U); v1 = max(u[1] for u in U); h = v1 - v0 + 1
    hand_h = max(2, round(h * 0.45))
    hv0 = v1 - hand_h + 1
    fore = {u: U[u] for u in U if u[1] < hv0}
    hand = {u: U[u] for u in U if u[1] >= hv0}

    def interior(u, pool):
        return all((u[0] + dx, u[1] + dy) in pool for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))

    def tier(cell):
        r = orig[cell][0]
        return 0 if r >= 0.88 * rmed else (1 if r >= 0.68 * rmed else 2)

    def row_mid(pool, v):
        xs = sorted(u[0] for u in pool if u[1] == v)
        return xs[len(xs) // 2] if xs else None

    if side == "L":
        if not hands_only:
            for u, cell in fore.items():
                px[cell] = INK[tier(cell)]
            # negative-space geometry: one skin pixel on alternate forearm rows, zig-zagging
            frows = sorted({u[1] for u in fore})
            for i, v in enumerate(frows[len(frows) // 2: len(frows) // 2 + 1]):
                m = row_mid(fore, v)
                if m is None:
                    continue
                for cand in ((m + (1 if i % 2 else -1), v), (m, v)):
                    if cand in fore and interior(cand, U):
                        px.pop(fore[cand], None); break
        bottom = max(u[1] for u in hand) + 1   # darken the whole back of the hand
        for u, cell in hand.items():
            px[cell] = INK[tier(cell)]
        # pale centre pixel = the eye
        cx = sum(u[0] for u in hand) / len(hand); cy = sum(u[1] for u in hand if u[1] < bottom) / max(1, sum(1 for u in hand if u[1] < bottom))
        best = min((u for u in hand if u[1] < bottom), key=lambda u: (u[0] - cx) ** 2 + (u[1] - cy) ** 2, default=None)
        if best:
            px.pop(hand[best], None)
    else:
        if not hands_only and fore:
            fv = sorted({u[1] for u in fore})
            if len(fv) >= 3:   # top exposed row = upper arm under the tee hem: grey-wash
                for u, cell in fore.items():
                    if u[1] == fv[0]:
                        r, g, b = orig[cell][:3]
                        px[cell] = tuple(round(c * 0.6 + t * 0.4) for c, t in zip((r, g, b), GREY))
                fv = fv[1:]
            prow = fv[: 2]   # creature head: 2 rows x 3 px, centred
            for j, v in enumerate(prow):
                m = row_mid(fore, v)
                for dx in (-1, 0, 1):
                    u = (m + dx, v)
                    if u in fore:
                        px[fore[u]] = ORANGE if (j == 0 and dx == 0) else PATCH
        # back of the hand: one dark row (blackletter), interior pixels only
        hv = sorted({u[1] for u in hand})
        v = hv[1] if len(hv) >= 3 else hv[0]
        row = sorted(u[0] for u in hand if u[1] == v)
        for x in row[1:-1] if len(row) > 2 else row:
            px[hand[(x, v)]] = PATCH


def ink_neck(px, im, ox, oy, facing, is_skin):
    """One/two blue-grey pixels on HIS LEFT side of the neck, where that side faces the viewer."""
    sk = lambda x, y: is_skin(im.getpixel((ox + x, oy + y)))
    if facing == "front":   # his left = viewer's right: the neck side showing beside the jaw/beard
        cand = [(x, y) for y in range(31, 35) for x in range(37, 46) if sk(x, y)]
        if not cand:
            return False
        a = max(cand, key=lambda p: (p[0], p[1]))
        px[(ox + a[0], oy + a[1])] = FOX[0]
        return True
    if facing == "back":    # his left = viewer's left: one shadow pixel at the neck's left edge
        for y in (33, 32, 34):
            xs = [x for x in range(22, 42) if sk(x, y)]
            if len(xs) >= 4:
                px[(ox + xs[0], oy + y)] = FOX[1]
                return True
        return False
    if facing == "left":   # we see his left side: neck skin between jaw and collar, behind the jaw
        cand = [(x, y) for y in range(33, 37) for x in range(26, 38) if sk(x, y)]
        if not cand:
            return False
        # back-most (largest x when facing left) of the lowest rows
        cand.sort(key=lambda p: (-p[1], -p[0]))
        a = cand[0]
        px[(ox + a[0], oy + a[1])] = FOX[0]
        up = (a[0], a[1] - 1)
        if sk(*up):
            px[(ox + up[0], oy + up[1])] = FOX[1]
        return True
    return False


def ink_sheet(name, cfg):
    src = os.path.join(BACKUP, name + ".png")
    im = Image.open(src).convert("RGBA")
    W, H = im.size
    style = cfg["style"]; hands_only = cfg.get("hands_only", False)
    mg, mb, rmed = measure_skin(im, style)
    is_skin = make_is_skin(mg, mb)
    ylo, yhi = (37, 57) if style == "new" else (38, 51)
    px = {}; log = []
    for ry, facing in enumerate(cfg["rows"]):
        if facing is None:
            continue
        for cx in range(W // C):
            ox, oy = cx * C, ry * C
            k = cx if facing == "roll" else 0
            f = "front" if facing == "roll" else facing
            pts = []
            for y in range(C):
                for x in range(C):
                    if not is_skin(im.getpixel((ox + x, oy + y))):
                        continue
                    ux, uy = unrot(x, y, k)
                    if ylo <= uy <= yhi:
                        pts.append((x, y))
            # arms are vertical blobs: drop specks and 1-2 row shoe stripes (red shoes, soles)
            comps = [c for c in components(pts) if len(c) >= 4 and
                     len({unrot(x, y, k)[1] for x, y in c}) >= (3 if style == "new" else 2)]
            if f in ("front", "back"):
                comps = [c for c in comps if abs(sum(p[0] for p in c) / len(c) - 32) >= 5 or k]
            # grow each arm by up to 2 px into its own darker skin shading (edge browns, old specks)
            taken = {q for c in comps for q in c}
            for c in comps:
                for _ in range(2):
                    add = []
                    for (x, y) in c:
                        for dx in (-1, 0, 1):
                            for dy in (-1, 0, 1):
                                q = (x + dx, y + dy)
                                if q in taken or not (0 <= q[0] < C and 0 <= q[1] < C):
                                    continue
                                if ylo <= unrot(q[0], q[1], k)[1] <= yhi and \
                                        is_skin_shade(im.getpixel((ox + q[0], oy + q[1]))):
                                    taken.add(q); add.append(q)
                    c.extend(add)
            comps.sort(key=len, reverse=True)
            arms = []
            for i, c in enumerate(comps):
                uc = [unrot(x, y, k) for x, y in c]
                mx = sum(u[0] for u in uc) / len(uc)
                if f == "front":
                    side = "R" if mx < 32 else "L"
                elif f == "back":
                    side = "L" if mx < 32 else "R"
                elif f == "right":
                    side = "R" if i == 0 else "L"
                else:
                    side = "L" if i == 0 else "R"
                full = [(ox + x, oy + y, u[0], u[1]) for (x, y), u in zip(c, uc)]
                arms.append((side, full))
            orig = {}
            for side, full in arms:
                for X, Y, _, _ in full:
                    orig[(X, Y)] = im.getpixel((X, Y))
                ink_arm(px, full, side, hands_only, rmed, orig)
            neck = False
            if style == "new":
                neck = ink_neck(px, im, ox, oy, f, is_skin)
            log.append("r%dc%d %s: %s%s" % (ry, cx, facing, " ".join("%s%d" % (s, len(fl)) for s, fl in arms),
                                            " +fox" if neck else ""))
    out = im.copy()
    skinmask = {(x, y) for (x, y) in px if is_skin(im.getpixel((x, y))) or is_skin_shade(im.getpixel((x, y)))}
    assert set(px) <= skinmask, "tried to recolour a non-skin pixel"
    for (x, y), rgb in px.items():
        out.putpixel((x, y), tuple(rgb) + (255,))
    assert out.size == im.size
    assert out.getchannel("A").tobytes() == im.getchannel("A").tobytes(), "alpha changed"
    return im, out, len(px), log, (mg, mb)


def render(name, before, after):
    def on_bg(im):
        bg = Image.new("RGBA", im.size, (88, 136, 88, 255)); bg.alpha_composite(im); return bg
    s = 4
    b = on_bg(before).resize((before.width * s, before.height * s), Image.NEAREST)
    a = on_bg(after).resize((after.width * s, after.height * s), Image.NEAREST)
    gap = 16
    sheet = Image.new("RGBA", (b.width * 2 + gap, b.height), (30, 30, 34, 255))
    sheet.paste(b, (0, 0)); sheet.paste(a, (b.width + gap, 0))
    os.makedirs(RENDERS, exist_ok=True)
    sheet.save(os.path.join(RENDERS, name + ".png"))


def main():
    check = "--check" in sys.argv
    os.makedirs(BACKUP, exist_ok=True)
    for name in SHEETS:
        dst = os.path.join(BACKUP, name + ".png")
        if not os.path.exists(dst):
            shutil.copy2(os.path.join(ART, name + ".png"), dst)
    total = 0
    for name, cfg in SHEETS.items():
        if cfg is None:
            print("%-20s skipped (no skin)" % name); continue
        before, after, n, log, (mg, mb) = ink_sheet(name, cfg)
        total += n
        print("%-20s skin g/r=%.3f b/r=%.3f  %4d px recoloured" % (name, mg, mb, n))
        if "-v" in sys.argv:
            for l in log:
                print("    " + l)
        if not check:
            after.save(os.path.join(ART, name + ".png"))
            render(name, before, after)
    print("total %d px" % total)


if __name__ == "__main__":
    main()
