"""Cut the 3D view's standing van art out of one 2x2 Canva sheet (Nov 17, Duff: "cars need work").

    python3 tools/import_vans.py grok_art/2026-11-17-vans/_work/vans_v1.png

Sheet (master: Drive "97 Gemini art drops" / Canva design "DuffQuest art drop Nov 10" page vans_v1): a white delivery
van on flat magenta, seen from the game's high three-quarter camera. Top-left = driving right, top-right = driving
left (unused: the 3D view mirrors the right one), bottom-left = front (coming toward the camera), bottom-right = back.

Writes assets/art/van_side.png, van_front.png, van_back.png at 4 px per world unit (s 4), origin = bottom centre, and
registers them in assets/art/manifest.json + scripts/art_manifest.gd. The 3D view swaps these in for the top-down
truck_h / truck_v art (view3d.VANS); the flat 2D view keeps the top-down vans.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from import_hud_icons import key, _label  # noqa: E402  (same soft magenta key as the HUD icon sheet)

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art"
S = 4
# name: (cell index in the 2x2 grid, width in world units). The town van's top-down art is 32 units long.
ITEMS = {"van_side": (0, 36), "van_front": (2, 19), "van_back": (3, 22)}


def cut(sheet: np.ndarray, idx: int, kc: np.ndarray) -> np.ndarray:
    cell = sheet.shape[0] // 2
    r, c = divmod(idx, 2)
    src = sheet[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell]
    rgba = key(src, kc)
    # the soft key reads mid greys as half see-through and un-mixes them green: everything inside the van's
    # outline is solid, original colour; only the outermost 3 px keep the soft edge
    solid = np.sqrt(((src - kc) ** 2).sum(-1)) > 70
    outside = _flood_outside(~solid)
    inside = ~outside
    core = inside.copy()
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            core &= np.roll(np.roll(inside, dy, 0), dx, 1)
    rgba[core, :3] = src[core]
    rgba[core, 3] = 255
    m = rgba[..., 3] > 40
    lab, n = _label(m[::2, ::2])   # label at half res (cells are big), keep the biggest blob
    sizes = np.bincount(lab.ravel(), minlength=n + 1)
    sizes[0] = 0
    keep = np.kron(lab == sizes.argmax(), np.ones((2, 2), bool))[: m.shape[0], : m.shape[1]]
    k2 = keep.copy()
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            k2 |= np.roll(np.roll(keep, dy, 0), dx, 1)
    rgba[~k2] = 0
    ys, xs = np.nonzero(rgba[..., 3] > 8)
    return rgba[ys.min(): ys.max() + 1, xs.min(): xs.max() + 1]


def _flood_outside(free: np.ndarray) -> np.ndarray:
    """Background pixels reachable from the cell border (holes inside the van stay 'inside')."""
    from collections import deque
    H, W = free.shape
    seen = np.zeros_like(free)
    q = deque()
    for y in range(H):
        for x in (0, W - 1):
            if free[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((y, x))
    for x in range(W):
        for y in (0, H - 1):
            if free[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= yy < H and 0 <= xx < W and free[yy, xx] and not seen[yy, xx]:
                seen[yy, xx] = True
                q.append((yy, xx))
    return seen


def entry(w: int, h: int) -> dict:
    return {"w": w, "h": h, "cell": [w, h], "origin": [w // 2, h], "kind": "prop", "s": S}


def register(entries: dict) -> None:
    man_p = OUT / "manifest.json"
    gd_p = ROOT / "scripts" / "art_manifest.gd"
    man = json.loads(man_p.read_text())
    gd = gd_p.read_text()
    for name, e in entries.items():
        man["assets"][name] = e
        line = '  "%s": %s,' % (name, json.dumps(e).replace('":', '": ').replace(',"', ', "'))
        pat = re.compile(r'\n  "%s": .*' % re.escape(name))
        if pat.search(gd):
            gd = pat.sub(lambda _m: "\n" + line, gd, count=1)
        else:
            gd = gd.replace("const ASSETS = {\n", "const ASSETS = {\n" + line + "\n", 1)
    man_p.write_text(json.dumps(man, indent=2) + "\n")
    gd_p.write_text(gd)


def main(src: Path) -> None:
    sheet = np.asarray(Image.open(src).convert("RGB")).astype(int)
    kc = np.median(np.concatenate([sheet[4:40, 4:40].reshape(-1, 3), sheet[-40:-4, -40:-4].reshape(-1, 3)]), 0)
    entries = {}
    for name, (idx, wu) in ITEMS.items():
        rgba = cut(sheet, idx, kc)
        w = wu * S
        h = round(rgba.shape[0] * w / rgba.shape[1])
        im = Image.fromarray(rgba.astype(np.uint8), "RGBA").resize((w, h), Image.LANCZOS)
        im.save(OUT / f"{name}.png")
        entries[name] = entry(w, h)
        print(name, im.size)
    register(entries)


if __name__ == "__main__":
    main(Path(sys.argv[1]))
