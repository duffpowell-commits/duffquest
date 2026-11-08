#!/usr/bin/env python3
"""Make one image with Gemini's image model (Nano Banana) and save it.

Key: env GEMINI_API_KEY or ~/.gemini_key (never commit it).

  python3 tools/gemini_art.py OUT.png "prompt text" [--ref a.png --ref b.png]
         [--model gemini-3.1-flash-image] [--aspect 16:9] [--size 2K] [--upscale-refs 4]

--upscale-refs N blows small pixel refs (sheets, 640x360 rooms) up N x nearest
before sending, so the model sees real pixels instead of mush.
Prints any text the model returned. Exit 2 if no image came back.
"""
import argparse, base64, io, json, os, sys, urllib.request
from PIL import Image

API = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"


def key():
    k = os.environ.get("GEMINI_API_KEY")
    if not k:
        k = open(os.path.expanduser("~/.gemini_key")).read().strip()
    return k


def ref_part(path, up):
    im = Image.open(path).convert("RGB" if path.endswith(".jpg") else "RGBA")
    if up > 1 and max(im.size) * up <= 2048:
        im = im.resize((im.width * up, im.height * up), Image.NEAREST)
    buf = io.BytesIO()
    im.save(buf, "PNG")
    return {"inline_data": {"mime_type": "image/png",
                            "data": base64.b64encode(buf.getvalue()).decode()}}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("prompt")
    ap.add_argument("--ref", action="append", default=[])
    ap.add_argument("--model", default="gemini-3.1-flash-image")
    ap.add_argument("--aspect", default=None)
    ap.add_argument("--size", default=None)
    ap.add_argument("--upscale-refs", type=int, default=1)
    a = ap.parse_args()
    prompt = open(a.prompt[1:]).read() if a.prompt.startswith("@") else a.prompt
    parts = [ref_part(r, a.upscale_refs) for r in a.ref] + [{"text": prompt}]
    cfg = {"responseModalities": ["IMAGE", "TEXT"]}
    ic = {}
    if a.aspect: ic["aspectRatio"] = a.aspect
    if a.size: ic["imageSize"] = a.size
    if ic: cfg["imageConfig"] = ic
    body = json.dumps({"contents": [{"parts": parts}], "generationConfig": cfg}).encode()
    req = urllib.request.Request(API % a.model, body, {
        "Content-Type": "application/json", "x-goog-api-key": key()})
    try:
        d = json.load(urllib.request.urlopen(req, timeout=300))
    except urllib.error.HTTPError as e:
        print("HTTP", e.code, e.read().decode()[:800]); sys.exit(1)
    got = False
    for c in d.get("candidates", []):
        for p in c.get("content", {}).get("parts", []):
            if "text" in p:
                print("model:", p["text"].strip()[:500])
            blob = p.get("inlineData") or p.get("inline_data")
            if blob and not got:
                os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
                open(a.out, "wb").write(base64.b64decode(blob["data"]))
                im = Image.open(a.out)
                print("saved", a.out, im.size)
                got = True
    if not got:
        print("no image:", json.dumps(d)[:800]); sys.exit(2)


if __name__ == "__main__":
    main()
