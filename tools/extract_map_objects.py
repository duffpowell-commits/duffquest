"""One-off: pull everything that stands ON the ground out of the old painted map_outside.png
(buildings, trees, lamps, benches, signs, fences) into a transparent overlay, so the new tile
ground can go underneath while the old objects stay until Grok's replacements land.

    python3 tools/extract_map_objects.py

Writes assets/art/map_objects.png (1280x720, same placement as map_outside).
Buildings come from the exact footprint rects in main.gd; small props are connected blobs of
non-ground colour bigger than a speckle; holes inside a blob (tree canopies, windows) are filled.
"""
import re
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
GROUND = [(154, 186, 120), (126, 161, 102), (129, 138, 141), (82, 82, 97), (230, 218, 181),
          (223, 206, 164), (196, 184, 153), (181, 161, 130)]


def rects():
    src = (ROOT / "scripts" / "main.gd").read_text()
    out = [tuple(float(v) for v in m.split(",")) for m in re.findall(r'"r": Rect2\(([^)]*)\)', src)]
    for name in ("PHARM_R", "GROC_R", "PLASMA_R"):
        m = re.search(name + r": = Rect2\(([^)]*)\)", src)
        out.append(tuple(float(v) for v in m.group(1).split(",")))
    return out


def main():
    im = Image.open(ROOT / "assets" / "art" / "map_outside.png").convert("RGB")
    a = np.asarray(im).astype(int)
    d = np.min([((a - np.array(g)) ** 2).sum(-1) for g in GROUND], axis=0)
    thing = d > 150
    lab, n = ndimage.label(thing)
    keep = np.zeros_like(thing)
    for i, sl in enumerate(ndimage.find_objects(lab), start=1):
        h, w = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
        area = int((lab[sl] == i).sum())
        if area < 40 or (h <= 6 and w > 60):      # grass speckle / painted road edge
            continue
        keep[sl] |= lab[sl] == i
    keep = ndimage.binary_closing(keep, iterations=3)
    keep = ndimage.binary_fill_holes(keep)
    for x, y, w, h in rects():
        keep[int(y * 2):int((y + h) * 2), int(x * 2):int((x + w) * 2)] = True
    rgba = np.dstack([np.asarray(im), (keep * 255).astype(np.uint8)])
    out = ROOT / "assets" / "art" / "map_objects.png"
    Image.fromarray(rgba, "RGBA").save(out)
    print("wrote", out, "object px:", int(keep.sum()))


if __name__ == "__main__":
    main()
