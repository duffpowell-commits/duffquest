"""Cut the HD street-odds + HUD icon sheet into the game's small sprites (s 4 = 4 px per world unit).

    python3 tools/import_hud_icons.py [grok_art/2026-11-16-icons/hud_icons_sheet.png]

Source: a 2048x2048 Canva export (master: Drive "97 Gemini art drops", hud_icons_sheet_v1.png), 4x4 cells of 512 px
on flat magenta, in this order:
  drone, drone (rotor blur), nft frame, package / top-down van, honey bun, shake bottle, phone /
  cat peek, bus stop sign, coin, heart / bolt, piggy bank, bus icon, (empty)
Each cell is soft-keyed (alpha from the distance to the key colour, colour un-mixed so blurred rotors stay see-through),
trimmed, fitted into the asset's old world size at 4x density and saved over assets/art/<name>.png. The manifest
entries (assets/art/manifest.json + scripts/art_manifest.gd) get the new w/h/cell/origin and "s": 4, so every draw
call keeps the same world size and anchor. The shake bottle has no slot in the game yet and is skipped.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "grok_art" / "2026-11-16-icons" / "hud_icons_sheet.png"
OUT = ROOT / "assets" / "art"
CELL = 512
S = 4

# name: (cell index, box w, box h, anchor) in output px. anchor: "c" centre, "b" bottom centre, "tl" top-left.
# Boxes are the old world sizes x 4 (old px / old s * 4).
ITEMS = {
    "nft": (2, 56, 56, "b"),
    "package": (3, 40, 38, "b"),
    "honeybun": (5, 32, 32, "b"),
    "phone": (7, 48, 80, "tl"),
    "freya_peek": (8, 48, 44, "c"),
    "bus_sign": (9, 64, 80, "b"),
    "ic_coin": (10, 37, 37, "tl"),
    "ic_heart": (11, 37, 37, "tl"),
    "ic_bolt": (12, 37, 37, "tl"),
    "ic_piggy": (13, 37, 37, "tl"),
    "ic_bus": (14, 37, 37, "tl"),
}
# old origins in world units (old px / old s), kept so every draw call lands in the same place
ORIGIN_W = {"nft": (7, 13), "package": (5, 8.5), "honeybun": (4, 7), "phone": (0, 0), "freya_peek": (6, 6),
            "bus_sign": (8, 19), "ic_coin": (0, 0), "ic_heart": (0, 0), "ic_bolt": (0, 0), "ic_piggy": (0, 0),
            "ic_bus": (0, 0)}


def key(cell: np.ndarray, kc: np.ndarray) -> np.ndarray:
    """Soft magenta key -> RGBA float. Alpha from how far a pixel strays from the key, colour un-mixed."""
    c = cell.astype(float)
    # how far each channel moved away from the key, as a fraction of the room it had to move
    room = np.where(kc > 127, kc, 255 - kc).astype(float)
    a = (np.abs(c - kc) / np.maximum(room, 1)).max(-1)
    alpha = np.clip((a - 0.14) / (0.55 - 0.14), 0, 1)
    rgb = kc + (c - kc) / np.maximum(alpha[..., None], 1e-3)
    rgb = np.clip(rgb, 0, 255)
    # leftover pink fringe on thin edges -> darken toward ink
    pink = (rgb[..., 0] > rgb[..., 1] + 60) & (rgb[..., 2] > rgb[..., 1] + 60) & (alpha < 0.9)
    rgb[pink] = rgb[pink] * 0.35
    out = np.dstack([rgb, alpha * 255])
    out[alpha <= 0] = 0
    return out


def _label(m: np.ndarray):
    """4-connected component labels (pure numpy + a BFS; cells are small)."""
    from collections import deque
    lab = np.zeros(m.shape, int)
    n = 0
    H, W = m.shape
    for y0, x0 in zip(*np.nonzero(m)):
        if lab[y0, x0]:
            continue
        n += 1
        lab[y0, x0] = n
        q = deque([(y0, x0)])
        while q:
            y, x = q.popleft()
            for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= yy < H and 0 <= xx < W and m[yy, xx] and not lab[yy, xx]:
                    lab[yy, xx] = n
                    q.append((yy, xx))
    return lab, n


PAD = 96   # art may spill past its 512 cell (the van does); crop wider, keep only blobs centred in the cell


def cell_img(sheet: np.ndarray, idx: int, kc: np.ndarray) -> np.ndarray:
    r, c = divmod(idx, 4)
    y0, x0 = max(0, r * CELL - PAD), max(0, c * CELL - PAD)
    y1, x1 = min(sheet.shape[0], (r + 1) * CELL + PAD), min(sheet.shape[1], (c + 1) * CELL + PAD)
    rgba = key(sheet[y0:y1, x0:x1], kc)
    m = rgba[..., 3] > 40
    lab, n = _label(m)
    sizes = np.bincount(lab.ravel(), minlength=n + 1)
    mine = []
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        cy, cx = ys.mean() + y0, xs.mean() + x0
        if r * CELL <= cy < (r + 1) * CELL and c * CELL <= cx < (c + 1) * CELL:
            mine.append(i)
    biggest = max(sizes[i] for i in mine)
    keep = np.isin(lab, [i for i in mine if sizes[i] >= biggest * 0.15])
    k2 = keep.copy()
    for dy in (-3, -2, -1, 0, 1, 2, 3):
        for dx in (-3, -2, -1, 0, 1, 2, 3):
            k2 |= np.roll(np.roll(keep, dy, 0), dx, 1)
    rgba[~k2] = 0
    return rgba


def bbox(rgba: np.ndarray):
    ys, xs = np.where(rgba[..., 3] > 20)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def to_img(rgba: np.ndarray) -> Image.Image:
    return Image.fromarray(rgba.round().astype(np.uint8), "RGBA")


def premul_resize(im: Image.Image, size) -> Image.Image:
    """Resize without dark/pink halos: premultiply, resample, un-premultiply."""
    a = np.asarray(im).astype(float)
    a[..., :3] *= a[..., 3:] / 255.0
    big = Image.fromarray(a.round().astype(np.uint8), "RGBA").resize(size, Image.LANCZOS)
    b = np.asarray(big).astype(float)
    al = b[..., 3:]
    b[..., :3] = np.where(al > 0, b[..., :3] * 255.0 / np.maximum(al, 1), 0)
    return Image.fromarray(np.clip(b, 0, 255).round().astype(np.uint8), "RGBA")


def fit(rgba: np.ndarray, w: int, h: int, anchor: str, stretch: bool = False) -> Image.Image:
    x0, y0, x1, y1 = bbox(rgba)
    im = to_img(rgba[y0:y1, x0:x1])
    if stretch:
        return premul_resize(im, (w, h))
    k = min(w / im.width, h / im.height)
    nw, nh = max(1, round(im.width * k)), max(1, round(im.height * k))
    im = premul_resize(im, (nw, nh))
    out = Image.new("RGBA", (w, h))
    px = (w - nw) // 2 if anchor != "tl" else (w - nw) // 2
    py = h - nh if anchor == "b" else (h - nh) // 2
    out.alpha_composite(im, (px, py))
    return out


def deskew(rgba: np.ndarray) -> np.ndarray:
    """Rotate a tilted object (the phone) upright: the angle whose bounding box is smallest."""
    best = None
    for ang in np.arange(-30, 30.5, 0.5):
        im = to_img(rgba).rotate(ang, resample=Image.BICUBIC, expand=True)
        a = np.asarray(im)[..., 3] > 128
        ys, xs = np.nonzero(a)
        area = (xs.max() - xs.min()) * (ys.max() - ys.min())
        if best is None or area < best[0]:
            best = (area, ang)
    return np.asarray(to_img(rgba).rotate(best[1], resample=Image.BICUBIC, expand=True)).astype(float)


def sharpen(im: Image.Image) -> Image.Image:
    from PIL import ImageFilter
    rgb = im.convert("RGB").filter(ImageFilter.UnsharpMask(1.0, 60, 2))
    out = rgb.convert("RGBA")
    out.putalpha(im.getchannel("A"))
    return out


def set_entry(man: dict, gd: str, name: str, e: dict) -> str:
    man["assets"][name] = e
    pat = re.compile(r'(\n  "%s": )\{.*?\n  \}' % re.escape(name), re.S)
    body = json.dumps(e, indent=2).replace("\n", "\n  ")
    gd2, n = pat.subn(lambda m: m.group(1) + body, gd, count=1)
    assert n == 1, name
    return gd2


def main(src: Path) -> None:
    sheet = np.asarray(Image.open(src).convert("RGB")).astype(int)
    kc = np.median(np.concatenate([sheet[4:40, 4:40].reshape(-1, 3), sheet[-40:-4, -40:-4].reshape(-1, 3)]), 0)
    man_p = OUT / "manifest.json"
    gd_p = ROOT / "scripts" / "art_manifest.gd"
    man = json.loads(man_p.read_text())
    gd = gd_p.read_text()

    for name, (idx, w, h, anchor) in ITEMS.items():
        rgba = cell_img(sheet, idx, kc)
        if name == "phone":
            rgba = deskew(rgba)
            im = fit(rgba, w, h, anchor, stretch=True)
        else:
            if name == "freya_peek":   # the old peek had its wall on the right
                rgba = rgba[:, ::-1].copy()
            im = fit(rgba, w, h, anchor)
        im = sharpen(im)
        im.save(OUT / f"{name}.png")
        ox, oy = ORIGIN_W[name]
        e = dict(man["assets"][name])
        e.update({"w": w, "h": h, "origin": [round(ox * S), round(oy * S)], "s": S})
        if "cell" in e:
            e["cell"] = [w, h]
        gd = set_entry(man, gd, name, e)
        print(name, im.size)

    # drone: 2-frame strip (idle, rotor blur), both cut on one shared box so the body doesn't jump
    a = cell_img(sheet, 0, kc)
    b = cell_img(sheet, 1, kc)
    ax0, ay0, ax1, ay1 = bbox(a)
    bx0, by0, bx1, by1 = bbox(b)
    # align on the body: centre of the opaque core
    def core_c(r):
        ys, xs = np.where(r[..., 3] > 250)
        return xs.mean(), ys.mean()
    (acx, acy), (bcx, bcy) = core_c(a), core_c(b)
    half_w = max(acx - ax0, ax1 - acx, bcx - bx0, bx1 - bcx)
    half_h = max(acy - ay0, ay1 - acy, bcy - by0, by1 - bcy)
    fw, fh = 80, 64
    k = min(fw / (2 * half_w), fh / (2 * half_h))
    strip = Image.new("RGBA", (fw * 2, fh))
    for i, (r, cx, cy) in enumerate(((a, acx, acy), (b, bcx, bcy))):
        x0, y0 = int(round(cx - half_w)), int(round(cy - half_h))
        x1, y1 = int(round(cx + half_w)), int(round(cy + half_h))
        pad = np.zeros((r.shape[0] + 400, r.shape[1] + 400, 4))
        pad[200:-200, 200:-200] = r
        crop = to_img(pad[y0 + 200:y1 + 200, x0 + 200:x1 + 200])
        nw, nh = round(crop.width * k), round(crop.height * k)
        fr = sharpen(premul_resize(crop, (nw, nh)))
        strip.alpha_composite(fr, (i * fw + (fw - nw) // 2, (fh - nh) // 2))
    strip.save(OUT / "drone.png")
    e = dict(man["assets"]["drone"])
    e.update({"w": fw * 2, "h": fh, "cell": [fw, fh], "origin": [fw // 2, fh // 2], "s": S})
    gd = set_entry(man, gd, "drone", e)
    print("drone", strip.size)

    # van: top-down, nose up in the sheet. truck_h faces right (nose right), truck_v faces down (nose down);
    # enemy.gd mirrors both by lane direction.
    van = cell_img(sheet, 4, kc)
    x0, y0, x1, y1 = bbox(van)
    v = to_img(van[y0:y1, x0:x1])
    for name, img, (w, h) in (("truck_h", v.rotate(-90, expand=True), (128, 80)),
                              ("truck_v", v.rotate(180, expand=True), (80, 128))):
        im = sharpen(fit(np.asarray(img).astype(float), w, h, "c"))
        im.save(OUT / f"{name}.png")
        e = dict(man["assets"][name])
        e.update({"w": w, "h": h, "origin": [w // 2, h // 2], "s": S})
        if "cell" in e:
            e["cell"] = [w, h]
        gd = set_entry(man, gd, name, e)
        print(name, im.size)

    man_p.write_text(json.dumps(man, indent=2) + "\n")
    gd_p.write_text(gd)


if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else SRC)
