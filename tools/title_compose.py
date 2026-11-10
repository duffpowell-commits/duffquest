#!/usr/bin/env python3
"""Compose the title screen backdrop from the game's own art, so it matches the game and shows the real Duff.

Deterministic, no network, PIL + numpy only. Run from the repo root:
    python3 tools/title_compose.py

Reads   assets/art/bg_kitchen.png            (the Twisted Fork kitchen, in-game pixel art, 640x360)
        assets/art/portraits_hd/duff.png     (style-C dialogue portrait, 3 moods of 512x512; mood 0 = grin)
Writes  assets/art/bg_title.png              (1280x720 RGB; manifest "s": 4 keeps it 320x180 world units)

Why: the old title (Gemini G7) drew a blond, beardless cook with bare arms. The portrait is the canonical
style-C Duff (docs/art_direction/STYLE_LOCK.md): blackout sleeve + grey-wash sleeve, fox on the neck, beard,
undercut bun. The kitchen is pixel-doubled exactly like every in-game backdrop, graded toward the style lock's
Duff-frame palette (navy #0E1A33 / teal-navy #1E4A66, amber #E0A030), with a flat two-tone sunburst behind him.

Layout (1280x720): the menu draws the title bar (top ~70 px), the tagline (~72..140) and the buttons (~606..694).
Duff's head sits below the tagline and his tattooed shoulders above the buttons. He stands in a flat comic panel
(ink border, amber line) whose sides hide the portrait cell's square cut; his head breaks out of the top.
"""
import os
import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
W, H = 1280, 720
NAVY = np.array([14, 26, 51], np.float32)
TEAL = np.array([30, 74, 102], np.float32)
AMBER = np.array([224, 160, 48], np.float32)


def main():
    kit = Image.open(os.path.join(ROOT, "assets/art/bg_kitchen.png")).convert("RGB").resize((W, H), Image.NEAREST)
    a = np.asarray(kit, np.float32)
    # grade: darken + pull toward navy so the bright menu and Duff read on top
    a = a * 0.55 + NAVY * 0.25
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    cx, cy = 640.0, 420.0
    # flat two-tone sunburst behind Duff (style C: no gradients inside the rays)
    ang = np.arctan2(yy - cy, xx - cx)
    rays = (np.floor((ang + np.pi) / (np.pi / 12)) % 2).astype(np.float32)
    dist = np.sqrt(((xx - cx) / 560) ** 2 + ((yy - cy) / 420) ** 2)
    burst = np.clip(1.15 - dist, 0, 1)
    burst = np.where(burst > 0.0, np.minimum(1.0, burst * 2.2), 0.0) * 0.55
    ray_col = np.where(rays[..., None] > 0, TEAL[None, None, :], NAVY[None, None, :])
    a = a * (1 - burst[..., None]) + ray_col * burst[..., None]
    # amber glow from the fryer line behind him + vignette
    glow = np.clip(1 - ((xx - cx) / 420) ** 2 - ((yy - 300) / 220) ** 2, 0, 1) ** 2
    a += glow[..., None] * AMBER[None, None, :] * 0.18
    v = 1.0 - 0.35 * (((xx - 640) / 700) ** 2 + ((yy - 360) / 420) ** 2)
    a *= np.clip(v, 0.55, 1.0)[..., None]
    bg = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGB")

    por = Image.open(os.path.join(ROOT, "assets/art/portraits_hd/duff.png")).convert("RGBA")
    cell = por.crop((0, 0, 512, 512))  # mood 0: the grin
    size = 600
    cell = cell.resize((size, size), Image.LANCZOS)
    x0, y0 = (W - size) // 2, 136
    # comic panel: the portrait's arms are cut straight (cell x 97 and 414, from about row 290 down). The panel's
    # side borders are drawn ON TOP of those cuts, its top border sits behind his shoulders, so his head and
    # shoulders break out of the frame (flat teal fill, faint navy stripes, ink border, amber inner line).
    k = size / 512.0
    px0, px1, py0 = x0 + int(97 * k), x0 + int(414 * k) + 1, y0 + int(290 * k)
    INK = np.array([20, 18, 26], np.float32)
    panel = np.asarray(bg.convert("RGBA"), np.float32).copy()
    panel[py0:H, px0:px1, :3] = panel[py0:H, px0:px1, :3] * 0.25 + TEAL * 0.75
    for y in range(py0, H):
        for xs in range(px0 + ((y - py0) % 24), px1, 24):
            panel[y, xs:min(px1, xs + 6), :3] = panel[y, xs:min(px1, xs + 6), :3] * 0.8 + NAVY * 0.2
    panel[py0 - 4:py0 + 6, px0 - 8:px1 + 8, :3] = INK
    panel[py0 + 6:py0 + 9, px0:px1, :3] = AMBER
    bg = Image.fromarray(np.clip(panel, 0, 255).astype(np.uint8), "RGBA")
    alpha = cell.split()[3].point(lambda v: 255 if v > 128 else 0)
    # thin flat cyan rim line around the silhouette (allowed on Duff by the style lock)
    edge = np.asarray(alpha.filter(ImageFilter.MaxFilter(5))).copy()
    rim = Image.new("RGBA", cell.size, (63, 242, 230, 0))
    rim.putalpha(Image.fromarray(np.where(edge > 0, 170, 0).astype(np.uint8)))
    bg.alpha_composite(rim, (x0, y0))
    bg.alpha_composite(cell, (x0, y0))
    f = np.asarray(bg, np.float32).copy()
    f[py0 - 4:H, px0 - 8:px0 + 3, :3] = INK          # side borders over the arm cuts
    f[py0 - 4:H, px1 - 3:px1 + 8, :3] = INK
    f[py0 + 6:H, px0 + 3:px0 + 6, :3] = AMBER
    f[py0 + 6:H, px1 - 6:px1 - 3, :3] = AMBER
    bg = Image.fromarray(np.clip(f, 0, 255).astype(np.uint8), "RGBA")
    out = os.path.join(ROOT, "assets/art/bg_title.png")
    bg.convert("RGB").save(out)
    print("wrote", os.path.relpath(out, ROOT))


if __name__ == "__main__":
    main()
