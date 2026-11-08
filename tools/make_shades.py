"""Draw the shades overlay (assets/art/duff_shades.png) for the Grok Duff sheets.
Positions come from the eye whites of the Nov 8 outfit sheets (after the 3 px import drop):
front eyes y26-28 at x26-27 / x35-37; side eye y22-23 at x39 (right) / x24 (left). Up row: none.
    python3 tools/make_shades.py
Re-measure if the Duff sheets are replaced (see the eye-white finder in the M1 notes).
Outfits v2 (Nov 8, M6): stand frames unchanged; step frames (cols 1, 2) bob the head 1 px down;
the attack frame (col 3) lunges the head sideways: front -2, right +3, left -3 px."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LENS, RIM, SHINE = (22, 20, 30, 255), (8, 8, 12, 255), (120, 140, 170, 255)
im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
px = im.load()

def lens(cx, cy, x0, y0, x1, y1):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            corner = (x in (x0, x1)) and (y in (y0, y1))
            if not corner:
                px[cx + x, cy + y] = RIM if (y in (y0, y1) or x in (x0, x1)) else LENS
    px[cx + x0 + 1, cy + y0 + 1] = SHINE

BOB = [0, 1, 1, 0]                       # per column: head y offset
LUNGE = {0: -2, 2: 3, 3: -3}              # attack column: head x offset per row

for c in range(4):
    b = BOB[c]
    # front (row 0): two round lenses + bridge
    ox, oy = c * 64 + (LUNGE[0] if c == 3 else 0), 0 + b
    lens(ox, oy, 24, 25, 29, 29)
    lens(ox, oy, 33, 25, 39, 29)
    for x in range(30, 33):
        px[ox + x, oy + 26] = RIM
    # facing right (row 2): one lens, arm back to the ear
    ox, oy = c * 64 + (LUNGE[2] if c == 3 else 0), 128 + b
    lens(ox, oy, 37, 21, 42, 25)
    for x in range(30, 37):
        px[ox + x, oy + 22] = RIM
    # facing left (row 3): mirror
    ox, oy = c * 64 + (LUNGE[3] if c == 3 else 0), 192 + b
    lens(ox, oy, 21, 21, 26, 25)
    for x in range(27, 34):
        px[ox + x, oy + 22] = RIM
im.save(ROOT / "assets/art/duff_shades.png")
print("wrote duff_shades.png")
