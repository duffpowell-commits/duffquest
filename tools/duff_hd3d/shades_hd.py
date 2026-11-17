"""Draw the round-shades overlay for the 3D view's HD Duff sheet (assets/art3d/duff_shades_home_hd3d.png).
The 2x overlay (duff_shades_home) is fitted to the 2x sheet's faces; the HD sheet's head sits higher and
smaller, so the 2x shades landed on his mouth in 3D. Eye centres below were measured on duff_home_hd3d.png
(iris + eye-white blobs per cell, 512 px cells). Re-measure if the HD sheet is rebuilt.
    python3 tools/duff_hd3d/shades_hd.py
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
CELL, SS = 512, 4                         # supersample, then downscale for clean round edges
LENS, RIM, SHINE = (24, 22, 32, 250), (8, 8, 12, 255), (140, 160, 195, 230)
W, H = 15, 11                             # lens half size (px, final scale)
# front row: (left eye x, right eye x, eye y) per column
FRONT = [(213, 262, 163), (209, 255, 162), (183, 228, 162), (130, 176, 167)]
# side rows: eye (x, y) per column; row 2 faces right, row 3 faces left
RIGHT = [(290, 203), (284, 205), (265, 205), (241, 210)]
LEFT = [(208, 211), (195, 212), (171, 212), (164, 215)]

im = Image.new("RGBA", (CELL * 4 * SS, CELL * 4 * SS), (0, 0, 0, 0))
d = ImageDraw.Draw(im)

def s(v):
    return int(round(v * SS))

def lens(cx, cy, w=W, h=H):
    d.rounded_rectangle([s(cx - w), s(cy - h), s(cx + w), s(cy + h)], radius=s(h * 0.9), fill=RIM)
    d.rounded_rectangle([s(cx - w + 3), s(cy - h + 3), s(cx + w - 3), s(cy + h - 3)], radius=s(h * 0.7), fill=LENS)
    d.ellipse([s(cx - w + 5), s(cy - h + 4), s(cx - w + 10), s(cy - h + 8)], fill=SHINE)

def bar(x0, x1, y, t=3):
    d.rectangle([s(min(x0, x1)), s(y - t / 2), s(max(x0, x1)), s(y + t / 2)], fill=RIM)

for c in range(4):
    ox = c * CELL
    lx, rx, y = FRONT[c]
    bar(ox + lx, ox + rx, y - 4)                  # bridge
    lens(ox + lx, y)
    lens(ox + rx, y)
    ex, ey = RIGHT[c]                             # facing right: lens over the eye, arm back to the ear
    oy = 2 * CELL
    bar(ox + ex - 48, ox + ex, oy + ey - 4)
    lens(ox + ex, oy + ey, 12, H)
    ex, ey = LEFT[c]
    oy = 3 * CELL
    bar(ox + ex, ox + ex + 48, oy + ey - 4)
    lens(ox + ex, oy + ey, 12, H)

im = im.resize((CELL * 4, CELL * 4), Image.LANCZOS)
im.save(ROOT / "assets/art3d/duff_shades_home_hd3d.png")
print("wrote assets/art3d/duff_shades_home_hd3d.png")
