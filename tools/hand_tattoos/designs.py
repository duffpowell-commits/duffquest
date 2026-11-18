#!/usr/bin/env python3
"""Draw Duff's two hand tattoos as clean design masters (alpha = ink).

    python3 tools/hand_tattoos/designs.py        # writes docs/ref/duff/hand_*.png

Truth (Duff, Nov 18 2026, photos docs/ref/duff/photo_*_hand_*_2026-11-18.jpg):
  LEFT hand  = eye mandala, part of the blackout sleeve: an eye in the centre, a ring of
               triangle teeth, a spiked sun whose points run onto the backs of the fingers
               (Duff: "The mandala is on the back of the fingers"). Dot clusters on the fingers
               (three on the ring finger, a pair on the middle, single dots by pinky and thumb).
               NO RING (Duff, Nov 18 2026: "Take the ring off").
  RIGHT hand = four lines of brush calligraphy, wrist to knuckles:
               "This Red / Right Hand / Points Me / South", a swirl under "South".
               It reads upright when his arm hangs at his side (fingers down), so line 1 sits
               at the wrist.

Each design is drawn in "hand space": the top of the image = the WRIST, the bottom = the
KNUCKLES. tools/hand_tattoos/stamp.py maps that onto every sprite hand.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, "docs", "ref", "duff")
FONT = os.path.join(HERE, "KaushanScript-Regular.ttf")
WORDS = ["This Red", "Right Hand", "Points Me", "South"]
INK = (24, 21, 30, 255)
S = 512  # master size (square)


def eye_mandala(size=S):
    """Alpha = ink. Wrist at the top, knuckles (spike tips) at the bottom."""
    k = 4  # supersample
    n = size * k
    im = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(im)
    c = n / 2
    R = n / 2

    def circ(r, fill=None, outline=None, width=0):
        d.ellipse((c - r, c - r, c + r, c + r), fill=fill, outline=outline, width=width)

    # Sun: 10 spikes on a solid blackwork disc. Two long spikes point down to the finger bases.
    spikes = 10
    pts = []
    for i in range(spikes * 2):
        a = math.pi / 2 + i * math.pi / spikes  # start pointing DOWN (knuckles)
        r = R * (0.98 if i % 2 == 0 else 0.70)
        pts.append((c + r * math.cos(a), c + r * math.sin(a)))
    d.polygon(pts, fill=255)
    # skin outlines inside each spike (negative space hatch line)
    for i in range(0, spikes * 2, 2):
        a = math.pi / 2 + i * math.pi / spikes
        a1 = math.pi / 2 + (i - 1) * math.pi / spikes
        a2 = math.pi / 2 + (i + 1) * math.pi / spikes
        tip = (c + R * 0.86 * math.cos(a), c + R * 0.86 * math.sin(a))
        b1 = (c + R * 0.74 * math.cos(a1 + 0.08), c + R * 0.74 * math.sin(a1 + 0.08))
        b2 = (c + R * 0.74 * math.cos(a2 - 0.08), c + R * 0.74 * math.sin(a2 - 0.08))
        d.line([b1, tip, b2], fill=0, width=int(n * 0.012))
    # ring band 0.66..0.72 solid
    circ(R * 0.70, fill=255)
    # teeth band: skin disc, then dark triangles (base on the outer circle, point inward)
    circ(R * 0.64, fill=0)
    teeth = 16
    for i in range(teeth):
        a0 = i * 2 * math.pi / teeth
        a1 = (i + 1) * 2 * math.pi / teeth
        am = (a0 + a1) / 2
        tri = [(c + R * 0.64 * math.cos(a0), c + R * 0.64 * math.sin(a0)),
               (c + R * 0.64 * math.cos(a1), c + R * 0.64 * math.sin(a1)),
               (c + R * 0.42 * math.cos(am), c + R * 0.42 * math.sin(am))]
        d.polygon(tri, fill=255)
    circ(R * 0.64, outline=255, width=int(n * 0.012))
    circ(R * 0.42, outline=255, width=int(n * 0.014))
    # eye: almond outline, iris, pupil (eye runs across the hand)
    w, h = R * 0.36, R * 0.20
    almond = []
    for i in range(64):
        t = i / 63 * math.pi
        almond.append((c - w * math.cos(t), c - h * math.sin(t)))
    for i in range(64):
        t = i / 63 * math.pi
        almond.append((c + w * math.cos(t), c + h * math.sin(t)))
    d.polygon(almond, outline=255, width=int(n * 0.018))
    d.line(almond + [almond[0]], fill=255, width=int(n * 0.018))
    circ(R * 0.15, outline=255, width=int(n * 0.022))
    circ(R * 0.07, fill=255)
    return im.resize((size, size), Image.LANCZOS)


def script(size=S):
    """Alpha = ink. Line 1 ("This Red") at the top = wrist."""
    k = 2
    n = size * k
    im = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(im)
    font = ImageFont.truetype(FONT, int(n * 0.155))
    y = n * 0.04
    for i, line in enumerate(WORDS):
        bb = d.textbbox((0, 0), line, font=font)
        w = bb[2] - bb[0]
        x = (n - w) / 2 - bb[0] + (i - 1.5) * n * 0.02  # slight drift, like the photo
        d.text((x, y - bb[1]), line, font=font, fill=255, stroke_width=int(n * 0.007), stroke_fill=255)
        y += n * 0.205
    # swirl flourish under "South" (knuckles)
    cx, cy = n * 0.30, n * 0.89
    pts = []
    for i in range(160):
        t = i / 159 * 3.0 * math.pi
        r = n * 0.010 + n * 0.060 * (t / (3.0 * math.pi))
        pts.append((cx + r * math.cos(t), cy + r * 0.75 * math.sin(t)))
    pts += [(n * 0.45, n * 0.95), (n * 0.62, n * 0.93), (n * 0.80, n * 0.88)]
    d.line(pts, fill=255, width=int(n * 0.016), joint="curve")
    return im.resize((size, size), Image.LANCZOS)


def to_rgba(alpha):
    im = Image.new("RGBA", alpha.size, INK[:3] + (0,))
    im.putalpha(alpha)
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    to_rgba(eye_mandala()).save(os.path.join(OUT, "hand_left_eye_mandala.png"))
    # hand_right_script.png is now TRACED from Duff's close-up photo (Nov 18: Canva stencil of
    # photo_right_hand_script_closeup_2026-11-18.jpg + the pennant swash under "Points"). Never overwrite it.
    if not os.path.exists(os.path.join(OUT, "hand_right_script.png")):
        to_rgba(script()).save(os.path.join(OUT, "hand_right_script.png"))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
