#!/usr/bin/env python3
"""Fix Duff's hands on the painted stills (KO panels, loading screens) with his REAL tattoos.

    python3 tools/hand_tattoos/still_fix.py            # every still in STILLS
    python3 tools/hand_tattoos/still_fix.py duff_fin1  # one still

The stills already have the right idea (blackout left arm, script right hand) but invented
lettering, crosses on the right fingers, and no signet ring. Per still, hand-placed by eye:
  "erase": polygons whose dark ink on skin is painted out (OpenCV inpaint; outlines stay
           outside the polygons), e.g. the made-up blackletter and the finger crosses.
  "script": quad TL,TR,BR,BL on the back of the RIGHT hand; TL-TR = the wrist edge. The master
           docs/ref/duff/hand_right_script.png ("This Red / Right Hand / Points Me / South") is
           warped onto it, so it reads upright when his arm hangs fingers-down, like the photo.
  "ring":  [cx, cy, r, angle] silver signet ring band on the LEFT pinky.
Originals come from git (cached in grok_art/hand_tattoos/_work/originals/), so re-runs never
double-ink. Before/after crops go to docs/renders/hand_tattoos/stills/.
"""
import os
import shutil
import subprocess
import sys

import cv2
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
REF = os.path.join(ROOT, "docs", "ref", "duff")
BACKUP = os.path.join(ROOT, "grok_art", "hand_tattoos", "_work", "originals")
RENDERS = os.path.join(ROOT, "docs", "renders", "hand_tattoos", "stills")
INK = np.array([30, 20, 22], float)

STILLS = {
    "duff_fin1": {
        "file": "assets/art/ko/duff_fin1.jpg",
        "erase": [
            [(150, 546), (205, 546), (290, 586), (292, 608), (252, 616), (232, 638), (160, 642), (146, 600)],
            [(180, 688), (194, 688), (194, 710), (180, 710)],
            [(220, 680), (234, 680), (234, 707), (220, 707)],
            [(262, 668), (277, 668), (277, 696), (262, 696)],
            [(294, 647), (310, 647), (310, 676), (294, 676)],
        ],
        "script": [(143, 552), (262, 564), (272, 652), (150, 654)],
        "crop": (100, 500, 360, 720),
    },
    "duff_slip": {
        "file": "assets/art/ko/duff_slip.jpg",
        "erase": [[(362, 590), (400, 586), (456, 600), (458, 640), (440, 668), (390, 674), (362, 668), (358, 630)]],
        "script": [(364, 670), (364, 592), (458, 596), (458, 668)],
        "crop": (330, 560, 530, 710),
    },
    "duff_fin2": {
        "file": "assets/art/ko/duff_fin2.jpg",
        "erase": [[(69, 530), (108, 524), (119, 540), (117, 585), (95, 592), (69, 586)]],
        "script": [(68, 528), (117, 525), (115, 590), (71, 592)],
        "crop": (30, 480, 170, 620),
    },
}


def original(rel):
    dst = os.path.join(BACKUP, rel)
    if not os.path.exists(dst):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        data = subprocess.run(["git", "show", "HEAD:" + rel], cwd=ROOT, capture_output=True, check=True).stdout
        with open(dst, "wb") as f:
            f.write(data)
    return dst


def erase(img, polys):
    """Paint out dark ink inside the polygons (BGR uint8 in, out)."""
    h, w = img.shape[:2]
    area = np.zeros((h, w), np.uint8)
    for p in polys:
        cv2.fillPoly(area, [np.array(p, np.int32)], 255)
    lum = img.astype(float) @ [0.114, 0.587, 0.299]
    dark = (lum < 115) & (area > 0)
    # big dark blobs are shirt / background poking into the polygon, not ink: keep them
    allDark = (lum < 115).astype(np.uint8)
    big = cv2.morphologyEx(allDark, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (13, 13))) > 0
    dark &= ~big
    ink = dark.astype(np.uint8) * 255
    keep_out = cv2.dilate(big.astype(np.uint8) * 255, np.ones((3, 3), np.uint8), iterations=1)
    ink = cv2.dilate(ink, np.ones((3, 3), np.uint8), iterations=2) & area & ~keep_out
    return cv2.inpaint(img, ink, 5, cv2.INPAINT_TELEA)


def lay_script(img, quad, bold=2):
    m = Image.open(os.path.join(REF, "hand_right_script.png")).split()[-1]
    a = np.asarray(m).astype(np.float32) / 255.0
    if bold > 1:  # brush weight to match the painted ink
        a = cv2.dilate(a, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (bold, bold)))
    n = a.shape[0]
    src = np.float32([(0, 0), (n, 0), (n, n), (0, n)])
    M = cv2.getPerspectiveTransform(src, np.float32(quad))
    h, w = img.shape[:2]
    big = cv2.resize(a, (n, n))
    al = cv2.warpPerspective(big, M, (w, h), flags=cv2.INTER_LINEAR)
    b, g, r = [img[..., i].astype(int) for i in range(3)]
    skin = ((r > 120) & (r > g + 10) & (g > b)).astype(np.float32)
    skin = cv2.GaussianBlur(skin, (3, 3), 0)
    al = (np.clip(al * 1.15, 0, 1) * skin)[..., None]
    out = img.astype(float) * (1 - al) + INK[::-1] * al
    return out.clip(0, 255).astype(np.uint8)


def lay_ring(img, ring):
    """Silver band across the pinky: from p0 to p1 (finger edge to edge), w = band width."""
    p0, p1, w = ring
    ov = img.copy()
    cv2.line(ov, p0, p1, (60, 58, 56), w + 2, cv2.LINE_AA)       # dark rim
    cv2.line(ov, p0, p1, (196, 198, 204), w, cv2.LINE_AA)        # silver
    mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
    cv2.circle(ov, (int(mx), int(my)), max(2, w // 2 + 1), (24, 22, 22), -1, cv2.LINE_AA)  # signet face
    cv2.line(ov, (p0[0], p0[1] - w // 3), (p1[0], p1[1] - w // 3), (245, 245, 245), 1, cv2.LINE_AA)
    return ov


def fix(name):
    cfg = STILLS[name]
    rel = cfg["file"]
    img = cv2.imread(original(rel), cv2.IMREAD_COLOR)
    before = img.copy()
    if cfg.get("erase"):
        img = erase(img, cfg["erase"])
    if cfg.get("script"):
        img = lay_script(img, cfg["script"])
    if cfg.get("ring"):
        img = lay_ring(img, cfg["ring"])
    out = os.path.join(ROOT, rel)
    if rel.endswith(".jpg"):
        cv2.imwrite(out, img, [cv2.IMWRITE_JPEG_QUALITY, 92])
    else:
        cv2.imwrite(out, img)
    os.makedirs(RENDERS, exist_ok=True)
    for key, suffix in (("crop", ""), ("crop2", "_left")):
        if key not in cfg:
            continue
        x0, y0, x1, y1 = cfg[key]
        a, b = before[y0:y1, x0:x1], img[y0:y1, x0:x1]
        sheet = np.concatenate([a, np.full((a.shape[0], 8, 3), 255, np.uint8), b], 1)
        k = max(1, 600 // a.shape[0])
        sheet = cv2.resize(sheet, None, fx=k, fy=k, interpolation=cv2.INTER_NEAREST)
        cv2.imwrite(os.path.join(RENDERS, name + suffix + "_before_after.jpg"), sheet, [cv2.IMWRITE_JPEG_QUALITY, 90])
    print("fixed", rel)


def main():
    names = sys.argv[1:] or list(STILLS)
    for n in names:
        fix(n)


if __name__ == "__main__":
    main()
