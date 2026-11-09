"""Fix wrong-facing cells in a 4x4 AI sheet (any size) before import_big_sheet.py.

    python3 tools/fix_sheet_cells.py SRC OUT DST=SRC[:m] ...

Cells are "row,col" (rows down/up/right/left, cols stand/step/step/attack). ":m" mirrors the source cell
left-right. Every copy reads from the ORIGINAL sheet, so order doesn't matter. Example (row 3 = mirrored row 2):
    python3 tools/fix_sheet_cells.py in.png out.png 3,0=2,0:m 3,1=2,1:m 3,2=2,2:m 3,3=2,3:m
"""
import sys

from PIL import Image, ImageOps


def main():
    src, out, *specs = sys.argv[1:]
    im = Image.open(src).convert("RGB")
    res = im.copy()
    cw, ch = im.width / 4, im.height / 4

    def box(rc):
        r, c = (int(v) for v in rc.split(","))
        return (round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))

    for s in specs:
        dst, srcc = s.split("=")
        mirror = srcc.endswith(":m")
        tile = im.crop(box(srcc.removesuffix(":m")))
        if mirror:
            tile = ImageOps.mirror(tile)
        b = box(dst)
        res.paste(tile.resize((b[2] - b[0], b[3] - b[1])), b[:2])
    res.save(out)


if __name__ == "__main__":
    main()
