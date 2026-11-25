#!/usr/bin/env python3
"""Keep only the base-colour texture of a Meshy GLB (drops normal + metallic/roughness maps).

Meshy sometimes returns PBR maps we don't use; on a phone they cost VRAM and fill rate for
little gain under the porch's flat lighting. Same look as duff/pirate.glb, half the size.
  python3 tools/strip_pbr.py IN.glb OUT.glb [MAX_TEXTURE_PX]
MAX_TEXTURE_PX (e.g. 1024) re-encodes the base colour as a JPEG no bigger than that: small props
don't need Meshy's 2K, and every texture costs phone VRAM.
"""
import io
import json
import struct
import sys


def shrink(data: bytes, max_px: int) -> bytes:
    from PIL import Image
    im = Image.open(io.BytesIO(data)).convert("RGB")
    im.thumbnail((max_px, max_px), Image.LANCZOS)
    out = io.BytesIO()
    im.save(out, "JPEG", quality=88)
    return out.getvalue()


def main(src: str, dst: str, max_px: int = 0) -> None:
    raw = open(src, "rb").read()
    jlen = struct.unpack("<I", raw[12:16])[0]
    j = json.loads(raw[20:20 + jlen])
    bin_off = 20 + jlen + 8
    blob = raw[bin_off:bin_off + struct.unpack("<I", raw[20 + jlen:24 + jlen])[0]]

    keep_tex = set()
    for m in j.get("materials", []):
        m.pop("normalTexture", None)
        m.pop("occlusionTexture", None)
        m.pop("emissiveTexture", None)
        pbr = m.get("pbrMetallicRoughness", {})
        pbr.pop("metallicRoughnessTexture", None)
        pbr["metallicFactor"] = 0.0
        if "baseColorTexture" in pbr:
            keep_tex.add(pbr["baseColorTexture"]["index"])

    # Remap textures and images to the kept ones.
    tex_map, new_tex, img_map, new_img = {}, [], {}, []
    for t in sorted(keep_tex):
        tx = dict(j["textures"][t])
        s = tx["source"]
        if s not in img_map:
            img_map[s] = len(new_img)
            new_img.append(j["images"][s])
        tx["source"] = img_map[s]
        tex_map[t] = len(new_tex)
        new_tex.append(tx)
    for m in j.get("materials", []):
        pbr = m.get("pbrMetallicRoughness", {})
        if "baseColorTexture" in pbr:
            pbr["baseColorTexture"]["index"] = tex_map[pbr["baseColorTexture"]["index"]]
    dropped_views = {im["bufferView"] for im in j["images"]} - {im["bufferView"] for im in new_img}
    j["textures"], j["images"] = new_tex, new_img

    # Rebuild the binary chunk without the dropped buffer views.
    view_map, views, out = {}, [], bytearray()
    for i, v in enumerate(j["bufferViews"]):
        if i in dropped_views:
            continue
        data = blob[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]]
        if max_px and i in {im["bufferView"] for im in j["images"]}:
            data = shrink(data, max_px)
        while len(out) % 4:
            out.append(0)
        nv = dict(v)
        nv["byteOffset"] = len(out)
        nv["byteLength"] = len(data)
        out += data
        view_map[i] = len(views)
        views.append(nv)
    j["bufferViews"] = views
    if max_px:
        for im in j["images"]:
            im["mimeType"] = "image/jpeg"
    for a in j.get("accessors", []):
        if "bufferView" in a:
            a["bufferView"] = view_map[a["bufferView"]]
    for im in j["images"]:
        im["bufferView"] = view_map[im["bufferView"]]
    while len(out) % 4:
        out.append(0)
    j["buffers"] = [{"byteLength": len(out)}]

    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * (-len(js) % 4)
    total = 12 + 8 + len(js) + 8 + len(out)
    with open(dst, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(out), 0x004E4942) + out)
    print(f"{src} -> {dst}: {len(raw)} -> {total} bytes, images {len(new_img)}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 0)
