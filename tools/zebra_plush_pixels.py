# Madison's zebra plush (after her Wild Republic one): sitting, facing right, bold stripes, black muzzle,
# upright mane, hooves. Hand-placed pixels at home_interior density (s:2), coloured from the room's own
# warm palette (sampled off the teddy on the same shelf): no pure black or white, 3-step shading lit from
# the right like the room, and a soft brown outline.
# Run: python3 tools/zebra_plush_pixels.py assets/art/home_zebra_plush.png
import sys
from PIL import Image

# Regions: F head, N neck, B body, L front legs, G hind leg (all striped hide), A mane, M muzzle,
# m nostril, E eye, P inner ear, H hoof, T tail tuft, O outline.
G = [
"...........OO..OO.....",
"..........OPFOOFPO....",
".........OAFFFFFFO....",
"........OAAFFFFFFFO...",
"........OAFFFFEFFFFO..",
".......OAAFFFFFFFFFFO.",
".......OAFFFFFFFMMMMMO",
".......OAFFFFFFMMMMmMO",
"......OAANFFFFFOMMMMO.",
"......OANNNFFFFFOOOO..",
"......OANNNNNFFO......",
".....OBBNNNNNNNO......",
"....OBBBBNNNNNBBO.....",
"...OBBBBBBBBBBOLLO....",
"...OBBBBBBBBBOLLLLO...",
"..OBBBBBBBBBBOLLLLO...",
".OTOBBBBBBBBBOLLLLO...",
"OTTOBBBBBBBBOLLLLLO...",
"OTO.OBBBBBBBOLLLLLO...",
".O..OGGGGGBBOLLLLLO...",
"...OGGGGGGGOOLLLLLO...",
"..OGGGGGGGGGOLLLLLO...",
"..OHHGGGGGGGOHHHHHO...",
"..OHHHOOOOOOOHHHHHO...",
"...OOO.......OOOOO....",
]

# Ramps (hi, mid, lo), sampled to sit with the teddy and shelf.
HIDE = [(242, 204, 164), (214, 166, 134), (172, 120, 104)]
STRIPE = [(106, 64, 64), (82, 48, 52), (62, 34, 42)]
OUTLINE = (56, 30, 36)
FLAT = {"m": (40, 22, 30), "E": (32, 18, 26), "P": (200, 124, 112)}
HOOF = [(96, 66, 70), (74, 48, 56), (58, 36, 44)]

HIDE_REGIONS = "FNBLG"


def striped(c, x, y):
    if c == "F":
        if y <= 1 or (12 <= x <= 16 and 3 <= y <= 5):  # ears and the eye stay clear
            return False
        return (y + x // 4) % 3 == 0
    if c == "N":
        return (x - y) % 3 == 0
    if c == "B":
        return (x + y // 4) % 3 == 0
    if c == "L":
        return y % 3 == 1
    if c == "G":
        return (x + y) % 3 == 0
    return False


def level(x, y, row, h):
    # light from the right and above, like the lamp and window in home_interior
    xs = [i for i, ch in enumerate(row) if ch not in ".O"]
    lo, hi = (min(xs), max(xs)) if xs else (0, 1)
    nx = (x - lo) / max(1, hi - lo)
    f = 0.6 * nx + 0.4 * (1 - y / (h - 1))
    return 0 if f > 0.6 else (1 if f > 0.32 else 2)


h = len(G)
w = max(len(r) for r in G)
im = Image.new("RGBA", (w, h + 1), (0, 0, 0, 0))
for y, row in enumerate(G):
    for x, c in enumerate(row):
        if c == ".":
            continue
        if c == "O":
            col = OUTLINE
        elif c in FLAT:
            col = FLAT[c]
        else:
            lv = level(x, y, row, h)
            # darken one step where the hide meets the outline on the shadow side (left/below)
            if c in HIDE_REGIONS and ((x > 0 and row[x - 1] == "O") or (y + 1 < h and x < len(G[y + 1]) and G[y + 1][x] == "O")):
                lv = min(2, lv + 1)
            if c in HIDE_REGIONS:
                col = (STRIPE if striped(c, x, y) else HIDE)[lv]
            elif c in "AT":
                col = STRIPE[min(2, lv + 1)]
            elif c == "M":
                col = STRIPE[2] if lv else STRIPE[1]
            elif c == "H":
                col = HOOF[lv]
        im.putpixel((x, y), col + (255,))
# eye catchlight and a lit nose ridge
im.putpixel((15, 4), (226, 196, 178, 255))
# contact shadow on the shelf under the hooves
for x in range(3, 19):
    if im.getpixel((x, h - 1))[3] or im.getpixel((x, h - 2))[3]:
        im.putpixel((x, h), (60, 26, 18, 110))
im.save(sys.argv[1])
print(im.size)
