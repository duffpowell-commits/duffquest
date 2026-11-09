"""Cut a Grok portrait strip (N expressions side by side on a flat background) into a clean,
transparent, equal-cell PNG sheet for the dialogue box.

    python3 tools/import_portrait.py grok_art/duff_portraits_v2.jpg duff --cell 512

- background colour is read from the image corners (works for magenta, purple, green...)
- JPG fringe: pixels close to the background become transparent; edge pixels get the background
  tint pulled out (despill)
- panels are found by empty background columns (equal slices if they touch), trimmed, and centred into equal square cells
  sharing one scale (so every expression has the same head size)
Output: assets/art/portraits_hd/<name>.png  (N cells wide, 1 cell tall)
"""
import argparse
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "art" / "portraits_hd"


def keep_largest(img, min_px=0):
    """Drop alpha islands other than the biggest one (stray hair from a neighbouring panel).
    min_px > 0: also keep every island at least that many pixels (detached props like a floating icon)."""
    w, h = img.size
    a = img.getchannel("A").load()
    seen = [[False] * w for _ in range(h)]
    comps = []
    for sy in range(h):
        for sx in range(w):
            if seen[sy][sx] or a[sx, sy] == 0:
                continue
            stack, comp = [(sx, sy)], []
            seen[sy][sx] = True
            while stack:
                x, y = stack.pop()
                comp.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and a[nx, ny] > 0:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            comps.append(comp)
    comps.sort(key=len, reverse=True)
    keep = comps[:1] + [c for c in comps[1:] if min_px and len(c) >= min_px]
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src, dst = img.load(), out.load()
    for comp in keep:
        for x, y in comp:
            dst[x, y] = src[x, y]
    return out


def run(src, name, cell, margin, count=3, min_island=0):
    im = Image.open(src).convert("RGB")
    W, H = im.size
    px = im.load()
    # top corners only: busts run off the bottom edge, so the bottom corners are often body
    corners = [px[2, 2], px[W - 3, 2]]
    bg = tuple((corners[0][i] + corners[1][i]) // 2 for i in range(3))

    def dist(c):
        return sum(abs(a - b) for a, b in zip(c, bg))

    rgba = Image.new("RGBA", (W, H))
    op = rgba.load()
    for y in range(H):
        for x in range(W):
            c = px[x, y]
            d = dist(c)
            if d < 90:
                op[x, y] = (0, 0, 0, 0)
            elif d < 200:  # fringe: fade + pull the background tint out
                a = int(255 * (d - 90) / 110)
                k = 1 - (d - 90) / 110
                r, g, b = (int(max(0, min(255, (ci - bi * k) / max(0.2, 1 - k)))) for ci, bi in zip(c, bg))
                op[x, y] = (r, g, b, a)
            else:
                op[x, y] = c + (255,)

    alpha = rgba.getchannel("A")
    empty = [all(alpha.getpixel((x, y)) == 0 for y in range(0, H, 3)) for x in range(W)]
    panels, start = [], None
    for x in range(W + 1):
        filled = x < W and not empty[x]
        if filled and start is None:
            start = x
        elif not filled and start is not None:
            if x - start > 40:
                panels.append((start, x))
            start = None
    if len(panels) != count:
        # panels touch (hair overlapping): fall back to equal slices
        panels = [(round(i * W / count), round((i + 1) * W / count)) for i in range(count)]
    crops = []
    for x0, x1 in panels:
        c = keep_largest(rgba.crop((x0, 0, x1, H)), min_island)
        crops.append(c.crop(c.getchannel("A").getbbox()))
    biggest = max(max(c.width, c.height) for c in crops)
    scale = (cell - 2 * margin) / biggest
    sheet = Image.new("RGBA", (cell * len(crops), cell), (0, 0, 0, 0))
    for i, c in enumerate(crops):
        c = c.resize((round(c.width * scale), round(c.height * scale)), Image.LANCZOS)
        # bottom-align (shoulders sit on the box edge), centre horizontally
        sheet.alpha_composite(c, (i * cell + (cell - c.width) // 2, cell - margin - c.height))
    OUT.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT / f"{name}.png")
    print(f"bg={bg} panels={panels} -> {OUT / (name + '.png')} ({sheet.width}x{sheet.height})")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("name")
    ap.add_argument("--cell", type=int, default=512)
    ap.add_argument("--margin", type=int, default=16)
    ap.add_argument("--count", type=int, default=3, help="expressions in the strip")
    ap.add_argument("--min-island", type=int, default=0,
                    help="also keep detached pieces this many px or bigger (e.g. 400 for a floating icon)")
    a = ap.parse_args()
    run(a.src, a.name, a.cell, a.margin, a.count, a.min_island)
