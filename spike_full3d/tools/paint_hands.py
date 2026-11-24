#!/usr/bin/env python3
"""Paint Duff's REAL hand tattoos onto the back of each hand of his rigged Meshy model.

    python3 tools/paint_hands.py SRC.glb models/duff.glb [preview.png]

Why: generated textures garble the right-hand script and drift on the left-hand mandala. Duff's
rule (Nov 18 2026): copy the masters, never invent; NO ring. Masters are the alpha masks in
docs/ref/duff/ (u across the hand, v wrist -> knuckles):
  hand_left_eye_mandala.png  LEFT hand, black ink, sun spikes run onto the backs of the fingers
  hand_right_script.png      RIGHT hand, RED ink, "This Red / Right Hand / Points Me / South"

How: the hand is every vertex skinned >= 50% to LeftHand / RightHand. Its long axis (wrist ->
fingertips) and its thin axis (palm <-> back) come from PCA; the back is the side whose normals
face away from the body. Each back-facing triangle is rasterised in UV space and every texel is
projected onto the hand plane, so the master lands upright when the arm hangs (wrist at the top).
The old generated hand ink is first covered with the hand's own skin tone.
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REF = os.path.join(HERE, "..", "..", "docs", "ref", "duff")
BLACK_INK = np.array([30, 27, 36], float)
RED_INK = np.array([170, 24, 32], float)

# side -> (master, ink, v range along the hand as fraction of wrist->fingertip, width fraction)
HANDS = {
    "LeftHand": ("hand_left_eye_mandala.png", BLACK_INK, (0.06, 0.78), 0.96),
    "RightHand": ("hand_right_script.png", RED_INK, (0.02, 0.6), 0.6),
}


def read_glb(path):
    b = open(path, "rb").read()
    jlen = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + jlen])
    off = 20 + jlen
    blen = struct.unpack("<I", b[off:off + 4])[0]
    return j, bytearray(b[off + 8:off + 8 + blen])


def write_glb(path, j, views):
    """views: list of bytes per bufferView, packed back in order with 4-byte alignment."""
    blob = bytearray()
    for i, data in enumerate(views):
        while len(blob) % 4:
            blob += b"\0"
        j["bufferViews"][i]["byteOffset"] = len(blob)
        j["bufferViews"][i]["byteLength"] = len(data)
        blob += data
    while len(blob) % 4:
        blob += b"\0"
    j["buffers"][0]["byteLength"] = len(blob)
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(blob)
    out = struct.pack("<III", 0x46546C67, 2, total) + struct.pack("<II", len(js), 0x4E4F534A) + js
    out += struct.pack("<II", len(blob), 0x004E4942) + blob
    open(path, "wb").write(out)


def accessor(j, blob, i):
    a = j["accessors"][i]
    v = j["bufferViews"][a["bufferView"]]
    comp = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[a["componentType"]]
    n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
    start = v.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = v.get("byteStride", 0) or np.dtype(comp).itemsize * n
    raw = np.frombuffer(bytes(blob[start:start + stride * a["count"]]), np.uint8).reshape(a["count"], stride)
    return raw[:, :np.dtype(comp).itemsize * n].copy().view(comp).reshape(a["count"], n)


def master(name):
    return np.asarray(Image.open(os.path.join(REF, name)).convert("RGBA")).astype(float)[..., 3] / 255.0


def knuckle_dots(u, v):
    """LEFT hand only: a little cluster of three dots on the back of each finger (Duff's photos)."""
    a = np.zeros_like(u)
    for fu in (.16, .38, .61, .83):
        for du, dv in ((0, 0), (-.035, .035), (.035, .035)):
            d = np.hypot((u - fu - du) * 1.0, (v - .86 - dv) * 1.6)
            a = np.maximum(a, np.clip((.022 - d) / .006, 0, 1))
    return a


def sample(design, u, v):
    h, w = design.shape
    x = np.clip(u * (w - 1), 0, w - 1)
    y = np.clip(v * (h - 1), 0, h - 1)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    x1, y1 = np.minimum(x0 + 1, w - 1), np.minimum(y0 + 1, h - 1)
    fx, fy = x - x0, y - y0
    return (design[y0, x0] * (1 - fx) * (1 - fy) + design[y0, x1] * fx * (1 - fy)
            + design[y1, x0] * (1 - fx) * fy + design[y1, x1] * fx * fy)


def main(src, dst, preview=None):
    j, blob = read_glb(src)
    prim = j["meshes"][0]["primitives"][0]
    att = prim["attributes"]
    pos = accessor(j, blob, att["POSITION"]).astype(float)
    nrm = accessor(j, blob, att["NORMAL"]).astype(float)
    uv = accessor(j, blob, att["TEXCOORD_0"]).astype(float)
    joints = accessor(j, blob, att["JOINTS_0"]).astype(int)
    weights = accessor(j, blob, att["WEIGHTS_0"]).astype(float)
    tris = accessor(j, blob, prim["indices"]).reshape(-1, 3)
    skin_names = [j["nodes"][n]["name"] for n in j["skins"][0]["joints"]]
    img_view = j["images"][0]["bufferView"]
    v0 = j["bufferViews"][img_view]
    tex = np.asarray(Image.open(io.BytesIO(bytes(blob[v0.get("byteOffset", 0):v0.get("byteOffset", 0) + v0["byteLength"]]))).convert("RGB")).astype(float)
    th, tw = tex.shape[:2]
    body_mid = pos.mean(axis=0)

    for side, (design_name, ink, (va, vb), width_frac) in HANDS.items():
        ji = skin_names.index(side)
        fi = skin_names.index(side.replace("Hand", "ForeArm"))
        hand_w = np.where(joints == ji, weights, 0).sum(axis=1)
        arm_w = np.where(joints == fi, weights, 0).sum(axis=1)
        hand = hand_w >= 0.5
        hp = pos[hand]
        c = hp.mean(axis=0)
        wrist = pos[(hand_w > 0.2) & (arm_w > 0.2)].mean(axis=0)
        ev, evec = np.linalg.eigh(np.cov((hp - c).T))
        axis = evec[:, 2] * np.sign(np.dot(evec[:, 2], c - wrist))  # wrist -> fingertips
        thin = evec[:, 0]
        out = c - body_mid
        out[1] = 0
        if np.dot(thin, out) < 0:
            thin = -thin  # back of hand faces away from the body
        across = np.cross(thin, axis)  # viewer's right, looking at the back with the wrist on top
        across /= np.linalg.norm(across)
        length = np.max((hp - wrist) @ axis)
        half = np.percentile(np.abs((hp - c) @ across), 96) * width_frac
        design = master(design_name)
        hand_set = np.zeros(len(pos), bool)
        hand_set[np.where(hand)[0]] = True
        sel = tris[hand_set[tris].all(axis=1)]
        n_tex = 0
        skin_samples = []
        stamps = []
        for t in sel:
            p3 = pos[t]
            fn = np.cross(p3[1] - p3[0], p3[2] - p3[0])
            if np.linalg.norm(fn) == 0:
                continue
            fn /= np.linalg.norm(fn)
            if np.dot(fn, nrm[t].mean(axis=0)) < 0:
                fn = -fn
            facing = np.dot(fn, thin)
            uvp = uv[t] * [tw, th]
            x0, y0 = np.floor(uvp.min(axis=0)).astype(int)
            x1, y1 = np.ceil(uvp.max(axis=0)).astype(int)
            xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
            P = np.stack([xs.ravel() + .5, ys.ravel() + .5], 1)
            a, b, cc = uvp
            den = (b[1] - cc[1]) * (a[0] - cc[0]) + (cc[0] - b[0]) * (a[1] - cc[1])
            if abs(den) < 1e-9:
                continue
            l1 = ((b[1] - cc[1]) * (P[:, 0] - cc[0]) + (cc[0] - b[0]) * (P[:, 1] - cc[1])) / den
            l2 = ((cc[1] - a[1]) * (P[:, 0] - cc[0]) + (a[0] - cc[0]) * (P[:, 1] - cc[1])) / den
            l3 = 1 - l1 - l2
            inside = (l1 >= -.02) & (l2 >= -.02) & (l3 >= -.02)
            if not inside.any():
                continue
            L = np.stack([l1, l2, l3], 1)[inside]
            px = np.clip(P[inside].astype(int), 0, [tw - 1, th - 1])
            p = L @ p3
            v = ((p - wrist) @ axis) / length
            u = ((p - c) @ across) / (2 * half) + .5
            skin_samples.append(tex[px[:, 1], px[:, 0]])
            stamps.append((px, u, v, facing))
        skin_all = np.concatenate(skin_samples)
        lum = skin_all @ [.3, .59, .11]
        skin = np.median(skin_all[lum > np.percentile(lum, 70)], axis=0)  # bare skin, not old ink
        for px, u, v, facing in stamps:
            back = np.clip((facing - .15) / .35, 0, 1)
            if not back.any():
                continue
            vv = (v - va) / (vb - va)
            in_box = (u >= 0) & (u <= 1) & (vv >= 0) & (vv <= 1)
            # cover the generated hand ink on the back of the hand
            cover = back * (v < max(vb, .9) + .04) * (v > va - .06)
            cur = tex[px[:, 1], px[:, 0]]
            cur = cur * (1 - cover[:, None]) + skin * cover[:, None]
            a = np.where(in_box, sample(design, np.clip(u, 0, 1), np.clip(vv, 0, 1)), 0)
            if side == "LeftHand":
                a = np.maximum(a, knuckle_dots(u, v))
            a = a * back
            cur = cur * (1 - a[:, None] * .92) + ink * a[:, None] * .92
            tex[px[:, 1], px[:, 0]] = cur
            n_tex += int(in_box.sum())
        print(f"{side}: {hand.sum()} verts, {len(sel)} tris, {n_tex} inked texels, skin {skin.round()}")

    out = Image.fromarray(np.clip(tex, 0, 255).astype(np.uint8))
    buf = io.BytesIO()
    out.save(buf, "JPEG", quality=92)
    views = []
    for i, bv in enumerate(j["bufferViews"]):
        views.append(buf.getvalue() if i == img_view else bytes(blob[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]]))
    write_glb(dst, j, views)
    if preview:
        out.save(preview)


if __name__ == "__main__":
    main(*sys.argv[1:])
