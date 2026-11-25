"""Reskin a rigged Meshy body into another character for 0 credits (Nov 25 2026 test: Marketplace Mike's
body -> Sir Sends-It-Back). Paints the base-colour texture by body region (from vertex height, rasterised
into UV space) and colour class (skin / shirt / shorts / dark), keeping the original shading.

    python3 tools/reskin.py models/mike.glb models/mike_Image_0.jpg <recipe> <out.jpg>   (keep outputs in tools/reskins/ until a fight uses them: tools/ never ships)
recipe: sendback (the only one so far; add more in RECIPES).
"""
import sys
import numpy as np
import trimesh
from PIL import Image, ImageDraw

# region: 1 feet, 2 lower legs, 3 hips/upper legs, 4 torso/arms, 5 neck/head (by triangle height, metres)
CUTS = [(.11, 1), (.62, 2), (.95, 3), (1.42, 4)]  # .62 = just under the hands in the A-pose
RECIPES = {
    # Sir Sends-It-Back (assets/art/ch_sendback.png): red hair, green jacket, charcoal trousers, grey sneakers.
    "sendback": {
        "hair": (0.62, 0.20, 0.10),
        "shirt": (0.17, 0.42, 0.24),
        "trousers": (0.20, 0.21, 0.24),
        "shoes": (0.80, 0.80, 0.82),
    },
}


def rgb_to_hsv(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = a.max(-1), a.min(-1)
    d = mx - mn + 1e-6
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    s = np.where(mx > 0, d / (mx + 1e-6), 0)
    return h, s, mx


def tint(px, color, lum_ref):
    lum = px.mean(-1, keepdims=True)
    return np.clip(np.array(color) * (lum / lum_ref), 0, 1)


def main(glb, tex_path, recipe, out):
    rec = RECIPES[recipe]
    g = list(trimesh.load(glb, force="scene").geometry.values())[0]
    tex = np.asarray(Image.open(tex_path).convert("RGB")).astype(np.float32) / 255
    n = tex.shape[0]
    reg_img = Image.new("L", (n, n), 0)
    draw = ImageDraw.Draw(reg_img)
    for tri in g.faces:
        y = g.vertices[tri, 1].mean()
        r = next((code for cut, code in CUTS if y < cut), 5)
        draw.polygon([(g.visual.uv[i, 0] * n, (1 - g.visual.uv[i, 1]) * n) for i in tri], fill=r)
    reg = np.asarray(reg_img)
    h, s, v = rgb_to_hsv(tex)
    skin = (h > 8) & (h < 40) & (s > .25) & (s < .65) & (v > .45)
    pink = ((h > 300) | (h < 8)) & (s > .12) & (v > .3) & ~skin
    khaki = (h > 38) & (h < 75) & (s > .15) & (v > .3)
    dark = v < .33
    outp = tex.copy()

    def paint(mask, color):
        if mask.any():
            ref = tex[mask].mean() + 1e-6
            outp[mask] = tint(tex[mask], color, ref)

    paint((reg == 5) & dark, rec["hair"])
    paint(((reg == 4) | (reg == 3)) & pink, rec["shirt"])
    paint((reg == 3) & ~skin & ~pink, rec["trousers"])  # shorts, belt, bag; hands stay skin
    paint(reg == 2, rec["trousers"])  # bare shins become trouser legs
    paint(reg == 1, rec["shoes"])
    Image.fromarray((outp * 255).astype(np.uint8)).save(out, quality=92)


if __name__ == "__main__":
    main(*sys.argv[1:5])
