"""Build the HD baby sheet (baby_hd.png) from Octavia's HD dialogue portrait.

Cells (128 px each, manifest "s": 8 so a cell is 32 world px like the old pixel baby):
  0 asleep (neutral face, lids painted shut)  1 neutral  2 crying  3 happy
Usage: python3 tools/make_baby_hd.py
"""
from PIL import Image, ImageDraw, ImageFilter

SRC = "assets/art/portraits_hd/octavia.png"
OUT = "assets/art/baby_hd.png"
CELL = 128
EYES = [((254, 236), (36, 30)), ((357, 236), (31, 30))]   # in the neutral cell, 512 px space


def cell(im, i):
    return im.crop((i * 512, 0, i * 512 + 512, 512))


def shut_eyes(c):
    c = c.copy()
    d = ImageDraw.Draw(c)
    skin = c.getpixel((300, 300))[:3]
    for (x, y), (rx, ry) in EYES:
        # skin over the open eye, then a soft sleepy lid line with a few lashes
        lid = Image.new("L", c.size, 0)
        ImageDraw.Draw(lid).ellipse((x - rx, y - ry, x + rx, y + ry), fill=255)
        lid = lid.filter(ImageFilter.GaussianBlur(3))
        c.paste(Image.new("RGBA", c.size, skin + (255,)), (0, 0), lid)
        d.arc((x - rx + 4, y - 18, x + rx - 4, y + 14), 20, 160, fill=(60, 34, 24, 255), width=6)
        for k in (-1, 0, 1):
            lx = x + k * 13
            d.line((lx, y + 12, lx + k * 4, y + 22), fill=(60, 34, 24, 255), width=4)
    return c


def main():
    im = Image.open(SRC).convert("RGBA")
    frames = [shut_eyes(cell(im, 1)), cell(im, 1), cell(im, 2), cell(im, 0)]
    out = Image.new("RGBA", (CELL * 4, CELL), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f.resize((CELL, CELL), Image.LANCZOS), (i * CELL, 0))
    out.save(OUT)
    print("wrote", OUT, out.size)


if __name__ == "__main__":
    main()
