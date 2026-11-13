"""Portal covers (CrazyGames: 1920x1080, 800x1200, 800x800; title only, no borders or logos).
Drawn sunburst background + the HD Duff portrait (happy cell) + the itch logo.
Run: python3 tools/make_portal_covers.py  -> docs/portals/covers/"""
import math
from PIL import Image, ImageDraw, ImageFilter

NAVY, NAVY2, GOLD = (16, 30, 52), (28, 52, 84), (232, 150, 52)
portrait = Image.open("assets/art/portraits_hd/duff.png").convert("RGBA").crop((0, 0, 512, 512))
portrait = portrait.crop(portrait.getbbox())
logo = Image.open("docs/itch/logo.png").convert("RGBA")


def sunburst(w, h, cx, cy, rays=28):
    img = Image.new("RGB", (w * 2, h * 2), NAVY)
    d = ImageDraw.Draw(img)
    r = math.hypot(w, h) * 2
    for i in range(rays):
        if i % 2:
            continue
        a0, a1 = 2 * math.pi * i / rays, 2 * math.pi * (i + 1) / rays
        d.polygon([(cx * 2, cy * 2), (cx * 2 + r * math.cos(a0), cy * 2 + r * math.sin(a0)),
                   (cx * 2 + r * math.cos(a1), cy * 2 + r * math.sin(a1))], fill=NAVY2)
    img = img.resize((w, h), Image.LANCZOS)
    glow = Image.new("RGB", (w, h), GOLD)
    mask = Image.new("L", (w, h), 0)
    rr = int(min(w, h) * 0.42)
    ImageDraw.Draw(mask).ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=110)
    return Image.composite(glow, img, mask.filter(ImageFilter.GaussianBlur(rr * 0.6)))


def fit(im, height=None, width=None):
    s = height / im.height if height else width / im.width
    out = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    return out.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2)) if s > 1 else out


def shadow(im, off=10, blur=14):
    a = im.split()[3].point(lambda v: v * 0.55)
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    sh.putalpha(a)
    return sh.filter(ImageFilter.GaussianBlur(blur)), off


def paste(base, im, x, y, drop=True):
    if drop:
        sh, o = shadow(im)
        base.alpha_composite(sh, (x + o, y + o))
    base.alpha_composite(im, (x, y))


def make(w, h, duff_h, duff_x, logo_w, logo_xy, burst):
    base = sunburst(w, h, *burst).convert("RGBA")
    d = fit(portrait, height=duff_h)
    paste(base, d, duff_x - d.width // 2, h - d.height, drop=False)
    lg = fit(logo, width=logo_w)
    paste(base, lg, logo_xy[0] - lg.width // 2, logo_xy[1])
    return base.convert("RGB")


make(1920, 1080, 1040, 560, 980, (1350, 300), (560, 520)).save("docs/portals/covers/cover_1920x1080.png")
make(800, 1200, 780, 400, 700, (400, 50), (400, 760)).save("docs/portals/covers/cover_800x1200.png")
make(800, 800, 560, 250, 470, (560, 70), (300, 480)).save("docs/portals/covers/cover_800x800.png")
print("ok")
