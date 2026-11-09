import sys
# Builds docs/art_direction/compare_ABC.jpg (tall phone sheet). Usage: python3 tools/art_compare_sheet.py <repo> <out.jpg>
# Needs /tmp/portraits/01.png from tools/portrait_shot.tscn (dialogue frame).
from PIL import Image, ImageDraw, ImageFont
R = sys.argv[1]  # repo root
G = R + '/grok_art/2026-11-09-art-direction/'
F = R + '/assets/fonts/Baloo2-ExtraBold.ttf'
N = R + '/assets/fonts/Nunito-ExtraBold.ttf'
W = 1080
def font(p, s): return ImageFont.truetype(p, s)
def fit(path, w):
    im = Image.open(path).convert('RGB')
    return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
blocks = []
def text_block(lines, bg, h=None, pad=24):
    # lines: list of (text, fontpath, size, colour)
    hs = [font(p, s).getbbox(t)[3] + 10 for t, p, s, c in lines]
    H = h or sum(hs) + pad * 2
    im = Image.new('RGB', (W, H), bg); d = ImageDraw.Draw(im); y = pad
    for (t, p, s, c), lh in zip(lines, hs):
        d.text((32, y), t, font=font(p, s), fill=c); y += lh
    return im
def badge(im, letter, col):
    d = ImageDraw.Draw(im); sz = 136 if im.width > 600 else 84; f = font(F, int(sz * 0.8))
    x1, y1 = im.width - 14, im.height - 14; x0, y0 = x1 - sz, y1 - sz
    d.rounded_rectangle((x0, y0, x1, y1), 20, fill=col, outline=(0, 0, 0), width=5)
    bb = d.textbbox((0, 0), letter, font=f); cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    d.text((cx - (bb[2] - bb[0]) / 2 - bb[0], cy - (bb[3] - bb[1]) / 2 - bb[1]), letter, font=f, fill=(255, 255, 255))
    return im
DARK = (22, 20, 34); WHITE = (255, 255, 255); GREY = (200, 200, 210)
COL = {'A': (200, 60, 60), 'B': (40, 140, 200), 'C': (225, 150, 30)}
opts = [
  ('A', 'CURRENT: gritty anime KO style', 'Painterly, hatching, paper grit. Clashes with cards + portraits.',
   R + '/assets/art/ko/duff_stance.jpg', R + '/assets/art/ko/coupon_b.jpg'),
  ('B', 'FLAT CARTOON (boss-card style)', 'Thick ink, flat colour, sunburst. Matches cards + portraits.',
   G + 'stance_B.png', G + 'coupon_B.png'),
  ('C', 'MIDDLE GROUND', 'Card faces + linework, keeps KO speed lines + light hatching.',
   G + 'stance_C.png', G + 'coupon_C.png'),
]
blocks.append(text_block([('DuffQuest: pick ONE art style', F, 64, WHITE),
                          ('for every HD image (KO, loading, cards, portraits)', N, 36, GREY),
                          ('Same 2 shots in 3 styles. Then each next to the boss card.', N, 32, GREY)], (10, 10, 18)))
for L, title, sub, s1, s2 in opts:
    blocks.append(text_block([(f'{L}   {title}', F, 54, COL[L]), (sub, N, 32, WHITE)], DARK))
    for p in (s1, s2):
        blocks.append(badge(fit(p, W), L, COL[L]))
    blocks.append(Image.new('RGB', (W, 18), (10, 10, 18)))
# context section
blocks.append(text_block([('HOW IT SITS WITH THE REST', F, 58, WHITE),
                          ('Today\'s dialogue box (portrait = card style, unchanged):', N, 32, GREY)], (10, 10, 18)))
dlg = Image.open('/tmp/portraits/01.png').convert('RGB').crop((250, 425, 1035, 705))
blocks.append(fit_im := dlg.resize((W, round(dlg.height * W / dlg.width)), Image.LANCZOS))
card = R + '/assets/art/boss_intro/coupon.png'
for L, title, sub, s1, s2 in opts:
    blocks.append(text_block([(f'{L}:  boss intro card  |  KO still', F, 44, COL[L])], DARK, pad=14))
    row = Image.new('RGB', (W, 304), (0, 0, 0))
    row.paste(fit(card, 538), (0, 0)); row.paste(badge(fit(s2, 538), L, COL[L]), (542, 0))
    blocks.append(row)
blocks.append(text_block([('Pick A, B or C. Every new image then gets', N, 34, WHITE),
                          ('locked to that style + one Duff face sheet.', N, 34, WHITE)], (10, 10, 18)))
H = sum(b.height for b in blocks)
out = Image.new('RGB', (W, H), (10, 10, 18)); y = 0
for b in blocks: out.paste(b, (0, y)); y += b.height
out.save(sys.argv[2], quality=82, optimize=True)
print(out.size)
