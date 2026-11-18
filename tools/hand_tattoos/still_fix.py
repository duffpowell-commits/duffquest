#!/usr/bin/env python3
"""Fix Duff's hands on the painted stills (KO panels, loading screens) with his REAL tattoos.

    python3 tools/hand_tattoos/still_fix.py            # every still in STILLS
    python3 tools/hand_tattoos/still_fix.py duff_fin1  # one still

The stills already have the right idea (blackout left arm, script right hand) but invented
lettering, crosses on the right fingers, and solid-black left fists. Per still, hand-placed by eye:
  "erase": polygons whose dark ink on skin is painted out (OpenCV inpaint; outlines stay
           outside the polygons), e.g. the made-up blackletter and the finger crosses.
  "script": quad TL,TR,BR,BL on the back of the RIGHT hand; TL-TR = the wrist edge. The master
           docs/ref/duff/hand_right_script.png ("This Red / Right Hand / Points Me / South") is
           warped onto it, so it reads upright when his arm hangs fingers-down, like the photo.
  "fist":  [x0, y0, x1, y1] ellipse taken from the redrawn still (FISTS: Canva redraw with Duff's
           no-ring photo as reference, same framing) and feathered over the old LEFT fist.
NO RING on either hand (Duff, Nov 18 2026: "Take the ring off").
Originals come from git (cached in grok_art/hand_tattoos/_work/originals/), so re-runs never
double-ink. Before/after crops go to docs/renders/hand_tattoos/stills/.
"""
import os
import shutil
import subprocess
import sys

import cv2
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
REF = os.path.join(ROOT, "docs", "ref", "duff")
BACKUP = os.path.join(ROOT, "grok_art", "hand_tattoos", "_work", "originals")
RENDERS = os.path.join(ROOT, "docs", "renders", "hand_tattoos", "stills")
# Right-hand script ink is RED (Duff, Nov 18 2026: "blend the right hand tattoo and make the ink red").
# RGB; multiplied into the skin so the painted shading shows through like real ink.
RED_INK = np.array([178, 22, 30], float)
# Redrawn stills (Canva, refs = the still + docs/ref/duff/photo_left_hand_back_fingers_2026-11-18.jpg).
# Masters also in Drive "97 Gemini art drops".
REGEN = os.path.join(ROOT, "grok_art", "hand_tattoos", "_work", "regen")

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
        "fist": ("duff_fin1_v1.png", (690, 55, 915, 235)),
        "crop": (100, 500, 360, 720),
        "crop2": (640, 20, 960, 280),
    },
    "duff_slip": {
        "file": "assets/art/ko/duff_slip.jpg",
        "erase": [[(362, 590), (400, 586), (456, 600), (458, 640), (440, 668), (390, 674), (362, 668), (358, 630)]],
        "script": [(364, 670), (364, 592), (458, 596), (458, 668)],
        "crop": (330, 560, 530, 710),
    },
    "duff_fin3": {
        "file": "assets/art/ko/duff_fin3.jpg",
        "fist": ("duff_fin3_v4.png", (755, 95, 1265, 645), (740, 1280), 82),  # Duff's photo was a mirrored selfie
        "cut": ((775, 135, 470, 445), (740, 160, 510, 420)),  # grabCut rects: new fist, old fist
        "crop2": (700, 120, 1280, 620),
    },
    "duff_stance": {
        # Right hand reaches out curled, knuckle side to us: the back of the hand is hidden under the
        # forearm, so no script fits. The invented blackletter on the fingers goes (fingers are bare),
        # then the finger gaps and knuckle bumps are redrawn. Left fist already reads as the eye mandala.
        "file": "assets/art/ko/duff_stance.jpg",
        "bare": {
            "poly": [(487, 304), (512, 299), (530, 298), (546, 308), (551, 318), (553, 345), (532, 353), (500, 349), (487, 336)],
            "gaps": [[(500, 346), (502, 334), (505, 322)], [(520, 353), (521, 341), (524, 327)],
                     [(539, 352), (540, 341), (543, 329)], [(551, 316), (554, 330), (552, 346)]],
            "knuckles": [(493, 318, 8), (511, 314, 9), (530, 317, 9), (547, 322, 7)],
        },
        "crop": (440, 250, 620, 380),
    },
    "duff_fin2": {
        "file": "assets/art/ko/duff_fin2.jpg",
        "erase": [[(69, 530), (108, 524), (119, 540), (117, 585), (95, 592), (69, 586)]],
        "script": [(68, 528), (117, 525), (115, 590), (71, 592)],
        "crop": (30, 480, 170, 620),
    },
    # Boss KO frames (Duff's half of each KO panel). Only the right hands needed work: made-up
    # blackletter -> his real script in red. The left fists already show the eye mandala.
    "baron_b": {
        "file": "assets/art/ko/baron_b.jpg",
        "erase": [[(92, 564), (163, 567), (170, 600), (148, 621), (94, 621), (90, 596)]],
        "below": 135,
        "script": [(92, 560), (165, 565), (175, 615), (85, 612)],
        "crop": (20, 500, 260, 680),
    },
    "bozos_b": {
        "file": "assets/art/ko/bozos_b.jpg",
        "erase": [[(85, 486), (179, 481), (181, 579), (89, 591), (84, 560)]],
        "below": 140,
        "script": [(80, 492), (175, 488), (178, 575), (84, 588)],
        "crop": (20, 440, 240, 640),
    },
    "camper_b": {
        "file": "assets/art/ko/camper_b.jpg",
        "erase": [[(538, 120), (564, 122), (575, 138), (575, 163), (560, 164), (540, 150)]],
        "below": 140,
        "script": [(582, 128), (575, 168), (536, 152), (532, 114)],
        "crop": (490, 80, 620, 200),
    },
    "willnot_b": {
        # right fist: made-up grey letters across the fingers; his fingers are bare
        "file": "assets/art/ko/willnot_b.jpg",
        "gaps": [[(118, 526), (130, 535), (141, 544)], [(102, 553), (112, 561), (123, 571)], [(88, 581), (98, 588), (108, 596)]],
        "erase": [[(100, 512), (118, 508), (142, 512), (147, 530), (130, 560), (110, 585), (102, 615), (74, 615), (74, 585), (93, 545)]],
        "below": 165, "grey": True,
        "crop": (40, 490, 200, 640),
    },
    "willnot_b_pub": {
        "file": "assets/art/ko/willnot_b_pub.jpg",
        "gaps": [[(118, 526), (130, 535), (141, 544)], [(102, 553), (112, 561), (123, 571)], [(88, 581), (98, 588), (108, 596)]],
        "erase": [[(100, 512), (118, 508), (142, 512), (147, 530), (130, 560), (110, 585), (102, 615), (74, 615), (74, 585), (93, 545)]],
        "below": 165, "grey": True,
        "crop": (40, 490, 200, 640),
    },
    # Crypto Bro KO: Duff's LEFT hand flat on the floor (eye on the back). Invented blackletter on the fingers
    # and a cross by the thumb -> canon: sun spikes onto the finger bases + finger dots (three on the ring finger).
    "crypto_b": {
        "file": "assets/art/ko/crypto_b.jpg",
        "erase": [[(17, 647), (28, 641), (44, 639), (62, 638), (84, 637), (88, 648), (85, 662), (66, 665), (44, 666), (24, 666), (14, 659)],
                  [(98, 622), (114, 624), (114, 646), (102, 646)]],
        "below": 120, "pale": True,
        "gaps": [[(14, 650), (22, 644), (32, 640)],  # hand edge the wipe took
                 [(13, 662), (21, 654), (30, 646)], [(34, 669), (43, 657), (50, 646)], [(58, 667), (63, 656), (66, 646)]],
        "spikes": [[(23, 645), (32, 641), (20, 653)], [(37, 642), (47, 641), (37, 652)],
                   [(53, 641), (62, 641), (54, 655)], [(69, 640), (79, 641), (75, 654)]],
        "dots": [(32, 656, 1.3), (29, 660, 1.3), (26, 664, 1.3), (50, 661, 1.4), (74, 659, 1.4)],
        "crop": (0, 590, 150, 690),
    },
    # ---- loading screens (assets/art/loading). Right hands: invented blackletter -> red script.
    "fryer_nap": {
        "file": "assets/art/loading/fryer_nap.jpg",
        "erase": [[(707, 574), (745, 574), (749, 600), (746, 614), (735, 621), (705, 621), (700, 607), (700, 588), (703, 576)]],
        "below": 140, "pale": True,
        "script": [(701, 572), (746, 574), (748, 617), (700, 615)],
        "crop": (670, 540, 790, 690),
    },
    "goose_bet": {  # right fist, back arm, hanging fingers-down
        "file": "assets/art/loading/goose_bet.jpg",
        "erase": [[(503, 322), (530, 316), (552, 322), (550, 340), (541, 352), (510, 351), (501, 342)]],
        "below": 140, "pale": True,
        "script": [(508, 317), (552, 322), (546, 352), (499, 346)],
        "crop": (470, 290, 590, 390),
    },
    "gym_spot": {  # right fist on the rolling pin, fingers UP -> script upside down (wrist edge at the bottom)
        "file": "assets/art/loading/gym_spot.jpg",
        "erase": [[(357, 291), (380, 283), (420, 286), (436, 296), (434, 330), (410, 346), (380, 346), (360, 331)]],
        "below": 140, "pale": True,
        "script": [(432, 344), (360, 344), (360, 286), (432, 286)],
        "crop": (340, 250, 460, 380),
    },
    "brunch_atlas": {  # raised right fist, back of the hand to us, fingers UP -> script upside down
        "file": "assets/art/loading/brunch_atlas.jpg",
        "erase": [[(256, 36), (264, 28), (290, 26), (316, 28), (322, 40), (320, 60), (295, 67), (263, 68), (254, 60)]],
        "below": 140, "pale": True,
        "script": [(320, 68), (254, 66), (252, 28), (318, 26)],
        "crop": (220, 0, 350, 110),
    },
    "octavia_fund": {  # right hand on the table, fingers down-right: grey wolf-ish piece + finger dashes -> red script, bare fingers
        "file": "assets/art/loading/octavia_fund.jpg",
        "blobs": {"polys": [[(100, 470), (140, 470), (180, 505), (178, 530), (150, 560), (95, 560), (95, 500)]], "below": 110, "max": 22},
        "erase": [[(62, 482), (100, 472), (112, 474), (126, 480), (122, 492), (110, 500), (100, 525), (85, 545), (64, 530)]],
        "below": 160, "grey": True, "pale": True,
        "script": [(60, 508), (91, 477), (116, 502), (85, 533)],
        "crop": (50, 440, 200, 570),
    },
    "one_trip": {  # right hand (blackletter on the back + finger letters) -> red script, bare fingers;
                   # left hand keeps its eye mandala, "HUNTED" off the fingers -> finger dots
        "file": "assets/art/loading/one_trip.jpg",
        "erase": [[(684, 566), (700, 562), (730, 566), (752, 574), (754, 600), (750, 614), (690, 614), (682, 595)],
                  [(697, 613), (760, 611), (759, 632), (740, 638), (700, 636)],
                  [(924, 520), (935, 514), (950, 530), (972, 555), (972, 570), (960, 572), (940, 552), (924, 535)]],
        "below": 140, "pale": True,
        "script": [(686, 565), (751, 572), (749, 613), (688, 611)],
        "gaps": [[(715, 620), (715, 630), (716, 639)], [(729, 621), (730, 630), (730, 640)], [(746, 618), (746, 628), (745, 637)],
                 [(921, 517), (931, 517), (941, 518)], [(929, 543), (939, 537), (949, 531)], [(946, 557), (955, 551), (964, 545)]],
        "dots": [(940, 511, 1.3), (948, 525, 1.4), (946, 546, 1.2), (952, 543, 1.2), (958, 540, 1.2)],
        "crop": (660, 550, 800, 690),
        "crop2": (900, 460, 1040, 600),
    },
    "plasma_day": {  # right hand on the armrest, fingers pointing LEFT: blackletter -> red script, finger marks off
        "file": "assets/art/loading/plasma_day.jpg",
        "blobs": {"polys": [[(78, 540), (138, 535), (138, 592), (78, 595)]], "below": 150, "max": 16},
        "erase": [[(98, 549), (120, 543), (160, 542), (194, 548), (201, 562), (200, 582), (145, 584), (140, 567), (120, 561), (98, 559)]],
        "below": 140, "pale": True,
        "script": [(198, 541), (198, 584), (122, 581), (122, 543)],
        "crop": (30, 510, 220, 610),
    },
    "raccoon_break": {  # LEFT hand on the fork, fingers pointing left: invented sun+triangle -> canon eye mandala + dots
        "file": "assets/art/loading/raccoon_break.jpg",
        "erase": [[(795, 354), (836, 353), (844, 365), (844, 395), (830, 402), (800, 400), (793, 380)]],
        "below": 140, "pale": True,
        "mandala": [(845, 352), (845, 406), (791, 406), (791, 352)],
        "mandala_clip": [(790, 354), (836, 351), (849, 362), (849, 398), (830, 406), (792, 404)],
        "dots": [(776, 357, 1.3), (774, 370, 1.3), (768, 384, 1.2), (774, 384, 1.2), (780, 384, 1.2)],
        "crop": (730, 330, 870, 420),
    },
    "rent_slot": {  # right hand on the jar, fingers pointing RIGHT: blackletter -> red script
        "file": "assets/art/loading/rent_slot.jpg",
        "blobs": {"polys": [[(748, 380), (792, 380), (792, 452), (748, 452)]], "below": 110, "max": 10},
        "erase": [[(648, 386), (700, 377), (730, 386), (736, 410), (732, 438), (700, 442), (656, 438), (646, 415)]],
        "below": 140, "pale": True,
        "script": [(648, 442), (648, 378), (735, 378), (735, 442)],
        "crop": (630, 360, 790, 470),
    },
    # ---- title (porch, pixel art; hands ~25 px): left hand gets the eye mandala, right hand the red script texture
    "bg_title": {
        "file": "assets/art/bg_title.png",
        "redden": [(612, 448), (630, 446), (634, 458), (632, 472), (614, 473), (609, 460)],
        "blackout": [(658, 487), (672, 484), (684, 488), (682, 500), (676, 512), (662, 513), (655, 502)],
        "eye": (669, 498, 5, 2, 30),
        "sleeve": [(695, 440), (712, 438), (724, 455), (712, 480), (696, 494), (678, 490), (684, 470)],
        "crop": (550, 410, 740, 520),
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


def erase(img, polys, below=None, grey=False, pale=False):
    """Paint out dark ink inside the polygons (BGR uint8 in, out). below=<lum>: the polygon is all
    skin, so wipe everything darker than that (thick or blurry lettering, grey halos) too."""
    h, w = img.shape[:2]
    area = np.zeros((h, w), np.uint8)
    for p in polys:
        cv2.fillPoly(area, [np.array(p, np.int32)], 255)
    lum = img.astype(float) @ [0.114, 0.587, 0.299]
    if below:
        dark = lum < below
        if grey:  # grey-wash lettering only: keep the near-black, saturated-brown outlines
            sat = img.max(axis=2).astype(int) - img.min(axis=2).astype(int)
            br = img[..., 0].astype(float) / np.maximum(img[..., 2].astype(float), 1)
            dark &= (sat < 55) | ((br > 0.34) & (sat < 100))  # outlines are dark brown (b/r ~0.25); grey ink and its edges aren't
        ink = cv2.dilate((dark & (area > 0)).astype(np.uint8), np.ones((3, 3), np.uint8), iterations=2) & (area > 0)
        # fill from nearby SKIN only (normalised blur), so the hand outline never smears in
        b_, g_, r_ = [img[..., i].astype(int) for i in range(3)]
        hue = (r_ > 120) & (r_ > g_ + 15) & (g_ > b_)
        if pale:  # yellow backdrop passes the warm-hue test; skin keeps some blue
            hue &= b_ * 10 > r_ * 4
        skin = ((lum >= below + 15) & hue & ~ink.astype(bool)).astype(np.float32)
        fill = np.zeros(img.shape, np.float32)
        got = np.zeros(img.shape[:2] + (1,), np.float32)
        for sig in (4, 10, 25):  # wide gaps fall back to a wider sample
            num = cv2.GaussianBlur(img.astype(np.float32) * skin[..., None], (0, 0), sig)
            den = cv2.GaussianBlur(skin, (0, 0), sig)[..., None]
            ok = (den > 0.15).astype(np.float32) * (1 - got)
            fill += ok * num / np.maximum(den, 1e-3)
            got += ok
        sk = (skin > 0) & (cv2.dilate(area, np.ones((25, 25), np.uint8)) > 0)
        fill += (1 - got) * np.median(img[sk], axis=0).astype(np.float32)  # last resort: the hand's own tone
        a = cv2.GaussianBlur(ink.astype(np.float32), (0, 0), 1.6 if pale else 0.8)[..., None]
        if pale:  # big wipes: keep a whisper of the old shading so the patch isn't flat
            shade = cv2.GaussianBlur(lum.astype(np.float32), (0, 0), 4) / max(float(np.median(lum[sk])), 1)
            fill *= (np.clip(shade, 0.8, 1.1) ** 0.2)[..., None]
        return (img * (1 - a) + fill * a).clip(0, 255).astype(np.uint8)
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
    al = cv2.GaussianBlur(al, (0, 0), 0.8)  # soft edge: healed ink, not a sticker
    al = (np.clip(al * 1.1, 0, 0.88) * skin)[..., None]
    base = img.astype(float)
    inked = base * (RED_INK[::-1] / 255.0) * 0.9  # multiply: keeps the skin's light and shadow
    out = base * (1 - al) + inked * al
    return out.clip(0, 255).astype(np.uint8)


def lay_mandala(img, quad, clip):
    """Warp the LEFT-hand eye mandala master (top = wrist) onto quad TL,TR,BR,BL, inked only inside clip."""
    m = Image.open(os.path.join(REF, "hand_left_eye_mandala.png")).split()[-1]
    a = np.asarray(m).astype(np.float32) / 255.0
    n = a.shape[0]
    M = cv2.getPerspectiveTransform(np.float32([(0, 0), (n, 0), (n, n), (0, n)]), np.float32(quad))
    h, w = img.shape[:2]
    al = cv2.warpPerspective(a, M, (w, h), flags=cv2.INTER_AREA)
    keep = np.zeros((h, w), np.float32)
    cv2.fillPoly(keep, [np.array(clip, np.int32)], 1.0)
    keep = cv2.GaussianBlur(keep, (0, 0), 0.8)
    al = (cv2.GaussianBlur(al, (0, 0), 0.5) * keep * 0.92)[..., None]
    ink = np.array([30, 24, 28], float)  # BGR blackwork
    return (img * (1 - al) + ink * al).clip(0, 255).astype(np.uint8)


def tiny(img, cfg):
    """Pixel-art sized hands (~20 px): redden the right hand's ink in place, black out the left hand
    and open a skin-coloured eye in it (the mandala's eye is all that reads at this size)."""
    h, w = img.shape[:2]
    lum = img.astype(float) @ [0.114, 0.587, 0.299]
    out = img.astype(float)
    if cfg.get("redden"):
        area = np.zeros((h, w), np.uint8)
        cv2.fillPoly(area, [np.array(cfg["redden"], np.int32)], 1)
        b_, r_ = img[..., 0].astype(int), img[..., 2].astype(int)
        ink = (area > 0) & (lum < cfg.get("redden_below", 95)) & (lum > 38) & (r_ > b_ + 12)  # tattoo, not the black shirt
        red = RED_INK[::-1] * np.clip(lum / 80.0, 0.55, 1.15)[..., None]
        out[ink] = out[ink] * 0.4 + red[ink] * 0.6
    if cfg.get("blackout"):
        area = np.zeros((h, w), np.float32)
        cv2.fillPoly(area, [np.array(cfg["blackout"], np.int32)], 1.0)
        a = (cv2.GaussianBlur(area, (0, 0), 0.6) * 0.85)[..., None]
        out = out * (1 - a) + np.array([28, 22, 26], float) * a
        if cfg.get("sleeve"):  # blackout sleeve: darken, old linework survives as faint negative lines
            sl = np.zeros((h, w), np.float32)
            cv2.fillPoly(sl, [np.array(cfg["sleeve"], np.int32)], 1.0)
            sl = (cv2.GaussianBlur(sl, (0, 0), 0.8) * 0.7)[..., None]
            out = out * (1 - sl) + np.array([28, 22, 26], float) * sl
        cx, cy, rx, ry, ang = cfg["eye"]
        skin = np.array(cfg.get("skin", (120, 160, 220)), float)  # BGR
        m = np.zeros((h, w), np.uint8)
        cv2.ellipse(m, (cx, cy), (rx, ry), ang, 0, 360, 1, -1)
        out[m > 0] = skin
        cv2.circle(m2 := np.zeros((h, w), np.uint8), (cx, cy), max(1, ry - 1), 1, -1)
        out[m2 > 0] = np.array([28, 22, 26], float)
    return out.clip(0, 255).astype(np.uint8)


def grab(img, rect):
    """Biggest grabCut foreground blob inside rect (x, y, w, h), holes closed."""
    m = np.zeros(img.shape[:2], np.uint8)
    cv2.grabCut(img, m, rect, np.zeros((1, 65)), np.zeros((1, 65)), 6, cv2.GC_INIT_WITH_RECT)
    fm = ((m == 1) | (m == 3)).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(fm)
    fm = (lab == 1 + np.argmax(st[1:, 4])).astype(np.uint8)
    return cv2.morphologyEx(fm, cv2.MORPH_CLOSE, np.ones((15, 15), np.uint8))


def cut_fist(img, new, rect_new, rect_old):
    """Paste only the redrawn fist (grabCut) and paint the old fist's leftovers out with the burst around it."""
    fm = cv2.morphologyEx(grab(new, rect_new), cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (41, 41)))
    old = grab(img, rect_old)
    rest = cv2.dilate(old & (1 - fm), np.ones((7, 7), np.uint8))
    img = cv2.inpaint(img, rest * 255, 9, cv2.INPAINT_TELEA)
    a = cv2.GaussianBlur(fm.astype(np.float32), (0, 0), 1.5)[..., None]
    return (img * (1 - a) + new * a).clip(0, 255).astype(np.uint8)


def lay_fist(img, fist, cut=None):
    src, (x0, y0, x1, y1) = fist[:2]
    h, w = img.shape[:2]
    new = cv2.resize(cv2.imread(os.path.join(REGEN, src), cv2.IMREAD_COLOR), (w, h), interpolation=cv2.INTER_AREA)
    if len(fist) > 2:  # (fx0, fx1): mirror this column band left-right (selfie refs come out mirrored)
        fx0, fx1 = fist[2]
        new[:, fx0:fx1] = new[:, fx0:fx1][:, ::-1].copy()
    if len(fist) > 3:  # rotate the redraw (degrees, CCW) about the ellipse centre to match the old fist's pose
        R = cv2.getRotationMatrix2D(((fist[2][0] + fist[2][1]) / 2, 370), fist[3], 1.0)
        new = cv2.warpAffine(new, R, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT)
    if cut:
        return cut_fist(img, new, *cut)
    m = np.zeros((h, w), np.uint8)
    cv2.ellipse(m, ((x0 + x1) // 2, (y0 + y1) // 2), ((x1 - x0) // 2, (y1 - y0) // 2), 0, 0, 360, 255, -1)
    m = cv2.GaussianBlur(m, (0, 0), 6).astype(np.float32)[..., None] / 255.0
    return (img * (1 - m) + new * m).clip(0, 255).astype(np.uint8)


def blobs(img, cfg):
    """Erase small dark marks (finger dashes, stray letters) inside the polygons but keep long lines:
    a dark component that reaches outside the polygon or is longer than "max" px is an outline."""
    h, w = img.shape[:2]
    area = np.zeros((h, w), np.uint8)
    for p in cfg["polys"]:
        cv2.fillPoly(area, [np.array(p, np.int32)], 1)
    lum = img.astype(float) @ [0.114, 0.587, 0.299]
    dark = (lum < cfg.get("below", 100)).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(dark, connectivity=8)
    kill = np.zeros((h, w), bool)
    for k in range(1, n):
        x, y, bw, bh, a = st[k]
        if max(bw, bh) > cfg.get("max", 14):
            continue
        comp = lab[y:y + bh, x:x + bw] == k
        if (area[y:y + bh, x:x + bw][comp] == 0).any():
            continue
        kill[y:y + bh, x:x + bw] |= comp
    ink = cv2.dilate(kill.astype(np.uint8), np.ones((3, 3), np.uint8), iterations=1)
    return cv2.inpaint(img, ink * 255, 3, cv2.INPAINT_TELEA)


def bare(img, cfg):
    """Wipe every dark mark inside the polygon (fingers drawn with made-up ink), then redraw
    the finger gaps (dark) and knuckle bumps (half-strength) as soft lines."""
    h, w = img.shape[:2]
    area = np.zeros((h, w), np.uint8)
    cv2.fillPoly(area, [np.array(cfg["poly"], np.int32)], 255)
    lum = img.astype(float) @ [0.114, 0.587, 0.299]
    ink = cv2.dilate(((lum < 120) & (area > 0)).astype(np.uint8) * 255, np.ones((3, 3), np.uint8)) & area
    img = cv2.inpaint(img, ink, 5, cv2.INPAINT_TELEA)
    soft = cv2.bilateralFilter(img, 7, 30, 5)  # the inpaint leaves speckles; smooth skin only in the area
    a = cv2.GaussianBlur(area.astype(np.float32) / 255, (0, 0), 1.0)[..., None]
    img = (img * (1 - a) + soft * a).astype(np.uint8)
    return lines(img, cfg)


def lines(img, cfg):
    """Redraw finger gaps (dark) and knuckle bumps (half-strength) as soft painted lines."""
    h, w = img.shape[:2]
    K = 4
    m = Image.new("L", (w * K, h * K), 0)
    d = ImageDraw.Draw(m)
    for pts in cfg.get("gaps", []):
        d.line([(x * K, y * K) for x, y in pts], fill=255, width=int(1.8 * K), joint="curve")
    for cx, cy, r in cfg.get("knuckles", []):
        d.arc([(cx - r) * K, (cy - r * 0.6) * K, (cx + r) * K, (cy + r * 0.6) * K], 200, 340, fill=150, width=int(1.3 * K))
    for pts in cfg.get("spikes", []):  # mandala sun spikes running onto the finger backs (solid ink)
        d.polygon([(x * K, y * K) for x, y in pts], fill=235)
    for cx, cy, r in cfg.get("dots", []):  # finger dots (ring finger = three)
        d.ellipse([(cx - r) * K, (cy - r) * K, (cx + r) * K, (cy + r) * K], fill=235)
    m = np.asarray(m.resize((w, h), Image.LANCZOS)).astype(np.float32) / 255 * 0.9
    m = cv2.GaussianBlur(m, (0, 0), 0.5)[..., None]
    line = np.array([30, 20, 25], float)  # BGR outline ink
    return (img * (1 - m) + line * m).clip(0, 255).astype(np.uint8)


def fix(name):
    cfg = STILLS[name]
    rel = cfg["file"]
    img = cv2.imread(original(rel), cv2.IMREAD_COLOR)
    before = img.copy()
    if cfg.get("erase"):
        img = erase(img, cfg["erase"], cfg.get("below"), cfg.get("grey", False), cfg.get("pale", False))
    if cfg.get("blobs"):
        img = blobs(img, cfg["blobs"])
    if cfg.get("bare"):
        img = bare(img, cfg["bare"])
    if cfg.get("redden") or cfg.get("blackout"):
        img = tiny(img, cfg)
    if cfg.get("mandala"):
        img = lay_mandala(img, cfg["mandala"], cfg["mandala_clip"])
    if (cfg.get("gaps") or cfg.get("spikes") or cfg.get("dots")) and not cfg.get("bare"):
        img = lines(img, cfg)
    if cfg.get("script"):
        img = lay_script(img, cfg["script"])
    if cfg.get("fist"):
        img = lay_fist(img, cfg["fist"], cfg.get("cut"))
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
