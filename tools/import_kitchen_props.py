"""Cut the house-style (C) kitchen prop sheets into single sprites for the Fork minigames.

    python3 tools/import_kitchen_props.py            # every sheet in SHEETS that exists on disk

Sources: grok_art/2026-11-10-kitchen-props/<sheet>.png = a Canva scratch-page export (1920x1080) with the square
generated sheet placed at left 420, 1080x1080: 4x4 items on flat magenta. Each cell is keyed (magenta + pink spill),
trimmed, scaled so its longest side is MAX_PX (2 px per world unit -> ~40 world units) and saved as
assets/art/kf_<name>.png. Registers kf_* in assets/art/manifest.json + scripts/art_manifest.gd (kind "prop", s 2).
"""
import json
import re
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "grok_art" / "2026-11-10-kitchen-props"
OUT = ROOT / "assets" / "art"
MAX_PX = 80
SQ = (420, 0, 1080)
MESH = {"basket", "basket_fries", "basket_wings"}   # x, y, size of the square sheet on the export page
SHEETS = {
    "k1_sheet.png": ["bun_b", "bun_t", "mayo", "fried", "grilled", "hot", "cheese", "bacon",
                     "lettuce", "tomato", "pickles", "greens", "egg", "blue", "feta", "pecans"],
    "k2_sheet.png": ["apple", "onion", "ranch", "vin", "bowl", "basket_fries", "basket_wings", "wings",
                     "pickle_raw", "flour", "egg_wash", "breadcrumbs", "fried_pickles", "board", "knife", "tomato_whole"],
    "k3_sheet.png": ["torte", "whipped", "cherry", "choc_bottle", "plate", "mint", "hotel_pan", "spray",
                     "rag", "label", "diced", "fryer", "basket", "salt", "ticket", "produce_box"],
    # gear screen + hustler door + breading hands (Nov 11)
    "k5_sheet.png": ["gear_spatula", "gear_skillet", "gear_knife", "gear_tenderizer", "gear_flail", "gear_cleaver",
                     "gear_apron", "gear_clogs", "gear_sleeves", "gear_coat", "gear_dad", "gear_shades",
                     "door", "hand_dry", "hand_wet", "gear_locked"],
}


# one big prop filling the whole export page: name, longest side in px
SINGLE = {"k4_cake.png": ("cake", 300)}


def cut(sheet: Path, names: list, grid: int = 4, max_px: int = MAX_PX) -> dict:
    page = np.asarray(Image.open(sheet).convert("RGB")).astype(int)
    x, y, n = SQ if grid == 4 else (0, 0, page.shape[1])
    im = page[y:y + n, x:x + n] if grid == 4 else page
    cell_px = n // 4
    inset = cell_px // 20
    keyc = np.median(np.concatenate([im[8:24, 8:24].reshape(-1, 3), im[-24:-8, -24:-8].reshape(-1, 3)]), 0)
    table = {}
    for i, name in enumerate(names):
        r, c = divmod(i, 4)
        if grid == 1:
            cell = im
        else:
            cell = im[r * cell_px + inset:(r + 1) * cell_px - inset, c * cell_px + inset:(c + 1) * cell_px - inset]
        rr, gg, bb = cell[..., 0], cell[..., 1], cell[..., 2]
        d = np.abs(cell - keyc).sum(-1)
        magish = (rr > 190) & (bb > 190) & (gg < 110)   # true magenta only: purple onion must survive
        alpha = np.where((d < 160) | magish, 0, 255).astype(np.uint8)
        rgb = cell.copy()
        clear = alpha == 0
        rim = np.zeros_like(clear)   # pixels within 2 px of the keyed background
        for dy in (-2, -1, 0, 1, 2):
            for dx in (-2, -1, 0, 1, 2):
                rim |= np.roll(np.roll(clear, dy, 0), dx, 1)
        spill = rim & (rr > gg + 40) & (bb > gg + 40) & (alpha > 0)   # pink fringe on the rim -> ink (not purple onion)
        rgb[spill] = [20, 18, 26]
        if name in MESH:   # wire mesh: magenta showing through the wires -> steel grey, gaps -> clear
            pinkish = (rgb[..., 0] > rgb[..., 1] + 25) & (rgb[..., 2] > rgb[..., 1] + 25)
            alpha[pinkish & (rgb[..., 1] < 120)] = 0
            grey = rgb[pinkish].mean(-1, keepdims=True).astype(int) if pinkish.any() else None
            if grey is not None:
                rgb[pinkish] = np.repeat(grey, 3, -1)
        ys, xs = np.where(alpha > 0)
        if len(ys) == 0:
            print(f"  ! {name}: empty cell, skipped")
            continue
        rgba = np.dstack([rgb.clip(0, 255).astype(np.uint8), alpha])[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        sc = max_px / max(rgba.shape[:2])
        w, h = max(1, round(rgba.shape[1] * sc)), max(1, round(rgba.shape[0] * sc))
        small = np.asarray(Image.fromarray(rgba, "RGBA").resize((w, h), Image.LANCZOS)).copy()
        small[..., 3] = np.where(small[..., 3] >= 128, 255, 0)
        key = "kf_" + name
        Image.fromarray(small, "RGBA").save(OUT / f"{key}.png")
        table[key] = {"w": w, "h": h, "cell": [w, h], "origin": [w // 2, h // 2], "kind": "prop", "s": 2}
    return table


def register(table: dict) -> None:
    mj_path = OUT / "manifest.json"
    mj = json.loads(mj_path.read_text())
    t = mj["assets"] if "assets" in mj else mj
    for k in [k for k in t if k in table]:
        del t[k]
    t.update(table)
    mj_path.write_text(json.dumps(mj, indent=2) + "\n")
    gd = ROOT / "scripts" / "art_manifest.gd"
    src = gd.read_text()
    for k in table:
        src = re.sub(r'\n  "%s": \{[^}]*\},' % re.escape(k), "", src)
    add = "".join(f'\n  "{k}": {json.dumps(v)},' for k, v in sorted(table.items()))
    gd.write_text(src.replace("const ASSETS = {", "const ASSETS = {" + add, 1))


SKIP = {"kf_salt"}   # the generated tub carries a religious symbol; never ship it


def main() -> None:
    table = {}
    for sheet, names in SHEETS.items():
        p = SRC_DIR / sheet
        if p.exists():
            got = cut(p, names)
            print(f"{sheet}: {len(got)} props")
            table.update({k: v for k, v in got.items() if k not in SKIP})
    for k in SKIP:
        (OUT / f"{k}.png").unlink(missing_ok=True)
    for sheet, (name, px) in SINGLE.items():
        p = SRC_DIR / sheet
        if p.exists():
            table.update(cut(p, [name], 1, px))
            print(f"{sheet}: 1 prop")
    register(table)


if __name__ == "__main__":
    main()
