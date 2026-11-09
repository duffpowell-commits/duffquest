#!/usr/bin/env python3
"""DuffQuest logo in house style C: thick tapered ink, flat bold colour, hard offset shadow, sunburst.
Builds from the game's own font (Baloo 2 ExtraBold, OFL) so it stays crisp at any size.
Outputs (docs/itch/): logo.png (transparent), logo_banner.png (960x300 itch header), icon_512.png, logo_preview.jpg.
Usage: python3 tools/make_logo.py"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "itch"
BALOO = str(ROOT / "assets/fonts/Baloo2-ExtraBold.ttf")
NUNITO = str(ROOT / "assets/fonts/Nunito-ExtraBold.ttf")
INK = (22, 14, 20, 255)
CREAM = (255, 240, 205, 255)
ORANGE = (240, 122, 40, 255)
RED = (196, 48, 44, 255)
TEAL = (24, 120, 128, 255)
DEEP = (16, 52, 64, 255)
SS = 2  # supersample


def word(text, size, fill, stroke, tilt=0.0):
    """One word: hard ink shadow + ink stroke + flat fill, on transparent, tilted."""
    f = ImageFont.truetype(BALOO, size)
    pad = stroke * 3 + size // 6
    tmp = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    b = tmp.textbbox((0, 0), text, font=f, stroke_width=stroke)
    w, h = b[2] - b[0] + pad * 2, b[3] - b[1] + pad * 2
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    off = max(4, size // 14)
    d.text((pad - b[0] + off, pad - b[1] + off), text, font=f, fill=INK, stroke_width=stroke, stroke_fill=INK)
    d.text((pad - b[0], pad - b[1]), text, font=f, fill=fill, stroke_width=stroke, stroke_fill=INK)
    # light hatching on the lower third of the letters (style C: hatching used sparingly)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).text((pad - b[0], pad - b[1]), text, font=f, fill=255)
    hatch = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hatch)
    y0 = int(pad + (b[3] - b[1]) * 0.62)
    for x in range(-h, w, max(6, size // 16)):
        hd.line([(x, h), (x + h, 0)], fill=(0, 0, 0, 70), width=max(2, size // 60))
    hm = Image.new("L", (w, h), 0)
    ImageDraw.Draw(hm).rectangle([0, y0, w, h], fill=255)
    from PIL import ImageChops
    im.alpha_composite(Image.composite(hatch, Image.new("RGBA", (w, h)), ImageChops.multiply(mask, hm)))
    return im.rotate(tilt, resample=Image.BICUBIC, expand=True)


def pan(r, stroke):
    """Frying pan emblem (Duff is a line cook): ink-outlined pan + handle, flat colour."""
    s = r * 4
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = int(s * 0.38), s // 2
    # handle (behind)
    hw = r // 3
    hand = [(cx + r * 0.8, cy - hw // 2), (cx + r * 2.6, cy - hw * 0.8), (cx + r * 2.6, cy + hw * 0.8), (cx + r * 0.8, cy + hw // 2)]
    d.polygon([(x + stroke // 2, y + stroke // 2) for x, y in hand], fill=INK)
    d.polygon(hand, fill=RED, outline=INK, width=stroke)
    d.ellipse([cx + r * 2.25, cy - hw * 0.25, cx + r * 2.45, cy + hw * 0.25], fill=INK)
    # pan body
    off = stroke
    d.ellipse([cx - r + off, cy - r + off, cx + r + off, cy + r + off], fill=INK)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=DEEP, outline=INK, width=stroke)
    ri = int(r * 0.78)
    d.ellipse([cx - ri, cy - ri, cx + ri, cy + ri], fill=(44, 44, 52, 255), outline=INK, width=max(2, stroke // 2))
    # egg (sunny side up) = the "O" joke stays readable at icon size
    ew = int(r * 0.55)
    d.ellipse([cx - ew, cy - int(ew * 0.8), cx + ew, cy + int(ew * 0.85)], fill=CREAM, outline=INK, width=max(2, stroke // 2))
    yk = int(r * 0.22)
    d.ellipse([cx - yk, cy - yk, cx + yk, cy + yk], fill=ORANGE, outline=INK, width=max(2, stroke // 2))
    # shine
    d.arc([cx - ri + 6, cy - ri + 6, cx + ri - 6, cy + ri - 6], 200, 250, fill=(255, 255, 255, 140), width=max(2, stroke // 2))
    return im


def sunburst(w, h, c1, c2, rays=22, center=None):
    im = Image.new("RGBA", (w, h), c1)
    d = ImageDraw.Draw(im)
    cx, cy = center or (w / 2, h / 2)
    R = math.hypot(w, h)
    for i in range(rays):
        if i % 2:
            continue
        a0 = 2 * math.pi * i / rays
        a1 = 2 * math.pi * (i + 1) / rays
        d.polygon([(cx, cy), (cx + R * math.cos(a0), cy + R * math.sin(a0)), (cx + R * math.cos(a1), cy + R * math.sin(a1))], fill=c2)
    return im


def logo(scale=1, with_pan=True):
    s = SS * scale
    duff = word("DUFF", 230 * s, CREAM, 16 * s, tilt=4)
    quest = word("QUEST", 230 * s, ORANGE, 16 * s, tilt=4)
    W = max(duff.width, quest.width + 30 * s) + (260 * s if with_pan else 0)
    H = duff.height + quest.height
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    if with_pan:
        p = pan(118 * s, 11 * s).rotate(-28, resample=Image.BICUBIC, expand=True)
        im.alpha_composite(p, (duff.width - 240 * s, -60 * s))
    im.alpha_composite(duff, (0, 0))
    im.alpha_composite(quest, (30 * s, duff.height - 170 * s))
    return im.crop(im.getbbox())


def tagline(text, size):
    f = ImageFont.truetype(NUNITO, size)
    tmp = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    b = tmp.textbbox((0, 0), text, font=f, stroke_width=size // 7)
    im = Image.new("RGBA", (b[2] - b[0] + 20, b[3] - b[1] + 20), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((10 - b[0], 10 - b[1]), text, font=f, fill=CREAM, stroke_width=size // 7, stroke_fill=INK)
    return im


def fit(im, w, h):
    r = min(w / im.width, h / im.height)
    return im.resize((max(1, int(im.width * r)), max(1, int(im.height * r))), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    L = logo()
    # 1) transparent logo, 1400 wide
    lg = fit(L, 1400, 900)
    lg.save(OUT / "logo.png")
    # 2) itch header banner 960x300 on sunburst
    bw, bh = 960 * SS, 300 * SS
    ban = sunburst(bw, bh, TEAL, DEEP, rays=28, center=(bw * 0.42, bh * 0.55))
    bp = pan(150 * SS, 14 * SS).rotate(-20, resample=Image.BICUBIC, expand=True)
    bp = fit(bp, bw * 0.5, bh * 1.15)
    ban.alpha_composite(bp, (int(bw * 0.56), (bh - bp.height) // 2 - 10 * SS))
    ll = fit(logo(with_pan=False), bw * 0.5, bh * 0.78)
    ban.alpha_composite(ll, (int(bw * 0.05), int(bh * 0.04)))
    tg = fit(tagline("Rent's due. Madison's watching. Punch the problem.", 46 * SS), bw * 0.5, bh * 0.14)
    ban.alpha_composite(tg, (int(bw * 0.05), bh - tg.height - 14 * SS))
    ImageDraw.Draw(ban).rectangle([0, 0, bw - 1, bh - 1], outline=INK, width=10 * SS)
    ban.resize((960, 300), Image.LANCZOS).convert("RGB").save(OUT / "logo_banner.png")
    # 3) app icon 512: pan on orange sunburst
    iw = 512 * SS
    ic = sunburst(iw, iw, ORANGE, RED, rays=20)
    p = fit(pan(200 * SS, 22 * SS).rotate(-30, resample=Image.BICUBIC, expand=True), iw * 1.05, iw * 1.05)
    p = p.crop(p.getbbox())
    p = fit(p, iw * 0.86, iw * 0.86)
    ic.alpha_composite(p, ((iw - p.width) // 2, (iw - p.height) // 2 - int(iw * 0.04)))
    dq = fit(word("DQ", 170 * SS, CREAM, 14 * SS, tilt=6), iw * 0.5, iw * 0.4)
    ic.alpha_composite(dq, (int(iw * 0.06), iw - dq.height - int(iw * 0.05)))
    ImageDraw.Draw(ic).rectangle([0, 0, iw - 1, iw - 1], outline=INK, width=16 * SS)
    ic.resize((512, 512), Image.LANCZOS).save(OUT / "icon_512.png")
    # 4) preview sheet: logo on dark + light, banner, icon
    pv = Image.new("RGB", (1200, 1240), (30, 26, 34))
    dark = fit(lg, 560, 380)
    light = Image.new("RGB", (600, 400), (238, 232, 220))
    pv.paste((30, 26, 34), (0, 0, 600, 400))
    pv.paste(light, (600, 0))
    pv.paste(dark, ((600 - dark.width) // 2, (400 - dark.height) // 2), dark)
    pv.paste(dark, (600 + (600 - dark.width) // 2, (400 - dark.height) // 2), dark)
    b2 = Image.open(OUT / "logo_banner.png").resize((1200, 375))
    pv.paste(b2, (0, 420))
    i2 = Image.open(OUT / "icon_512.png").convert("RGB").resize((400, 400))
    pv.paste(i2, (60, 820))
    i3 = i2.resize((128, 128))
    pv.paste(i3, (520, 952))
    i4 = i2.resize((64, 64))
    pv.paste(i4, (700, 1016))
    pv.save(OUT / "logo_preview.jpg", quality=88)
    for n in ["logo.png", "logo_banner.png", "icon_512.png", "logo_preview.jpg"]:
        print("wrote docs/itch/" + n)


if __name__ == "__main__":
    main()
