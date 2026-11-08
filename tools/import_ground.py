"""Cut Grok's ground sheets (grok_art/2026-11-07-ground/) into a game tile atlas.

    python3 tools/import_ground.py [--tile 64]

One 256 px art cell becomes one TILE px game tile (default 64 px = 32 world units at the game's
2 px/unit art density). Art uses 2x2 pixel clusters, so a nearest sample at a fixed phase keeps
pixels crisp and keeps the shared borders between tiles matching.

Transition tiles are classified by LOOKING at their four corners (which material sits in each
corner), not by trusting names, so the autotiler can't get an orientation convention wrong.

Writes:
  assets/art/ground/ground_atlas.png   tiles in a grid, TILE px each
  assets/art/ground/ground_atlas.json  {"tile": 64, "cols": N,
      "materials": {name: [cell, ...]},            # interchangeable full-material variants
      "transitions": {"A|B|mask": cell},           # mask = corners TL TR BL BR, "1" = material A
      "decals": {name: cell}}                      # road paint + fixtures (full tiles on asphalt)
"""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "grok_art" / "2026-11-07-ground"
OUT = ROOT / "assets" / "art" / "ground"
CELL = 256


def mean(img, box):
    px = img.crop(box).resize((1, 1), Image.BOX).getpixel((0, 0))
    return px[:3]


def dist(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b))


def main(tile):
    meta = json.load(open(SRC / "ground_tilemap.json"))
    sheets = {k: Image.open(SRC / v["file"]).convert("RGB") for k, v in meta["sheets"].items()}
    step = CELL // tile
    phase = step // 2

    def shrink(img):
        out = Image.new("RGB", (tile, tile))
        sp, op = img.load(), out.load()
        for y in range(tile):
            for x in range(tile):
                op[x, y] = sp[x * step + phase, y * step + phase]
        return out

    cells = []          # list of tile images, index = atlas cell

    def add(img):
        cells.append(shrink(img))
        return len(cells) - 1

    materials, mat_colour = {}, {}
    for m in meta["materials"]:
        sheet = sheets[m["sheet"]]
        materials[m["name"]] = []
        for v in m["variants"]:
            x, y, w, h = v["rect"]
            crop = sheet.crop((x, y, x + w, y + h))
            materials[m["name"]].append(add(crop))
        x, y = m["variants"][0]["rect"][:2]
        mat_colour[m["name"]] = mean(sheet, (x, y, x + 512, y + 512))

    transitions, decals, report = {}, {}, []
    inset, size = 24, 40
    corners = [(inset, inset), (CELL - inset - size, inset), (inset, CELL - inset - size), (CELL - inset - size, CELL - inset - size)]
    for t in meta["tiles"]:
        sheet = sheets[t["sheet"]]
        x0, y0 = (t["col"] - 1) * CELL, (t["row"] - 1) * CELL
        crop = sheet.crop((x0, y0, x0 + CELL, y0 + CELL))
        if "pair" not in t:
            decals[t["name"]] = add(crop)
            continue
        a, b = t["A"], t["B"]
        ca, cb = mat_colour[a], mat_colour[b]
        mask = ""
        for cx, cy in corners:
            c = mean(crop, (cx, cy, cx + size, cy + size))
            mask += "1" if dist(c, ca) < dist(c, cb) else "0"
        key = f"{a}|{b}|{mask}"
        if key in transitions:
            report.append(f"DUPLICATE mask {key}: {t['name']}")
        transitions[key] = add(crop)
        report.append(f"{t['name']:32s} -> {mask}")

    cols = 16
    rows = (len(cells) + cols - 1) // cols
    atlas = Image.new("RGB", (cols * tile, rows * tile))
    for i, c in enumerate(cells):
        atlas.paste(c, ((i % cols) * tile, (i // cols) * tile))
    OUT.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT / "ground_atlas.png")
    json.dump({"tile": tile, "cols": cols, "materials": materials, "transitions": transitions,
               "decals": decals}, open(OUT / "ground_atlas.json", "w"), indent=1)
    print("\n".join(report))
    print(f"{len(cells)} tiles -> {OUT / 'ground_atlas.png'} ({atlas.size[0]}x{atlas.size[1]})")
    # every pair should have exactly 12 distinct masks: 4 straight (2 bits), 4 outer (1 bit), 4 inner (3 bits)
    for p in meta["autotile"]["pairs"]:
        ms = sorted(k.split("|")[2] for k in transitions if k.startswith(p["A"] + "|" + p["B"] + "|"))
        print(p["id"], len(ms), ms)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--tile", type=int, default=64)
    main(ap.parse_args().tile)
