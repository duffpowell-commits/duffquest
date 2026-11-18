#!/usr/bin/env python3
"""Patch Duff's hands in an already-cut video (trailer, GIFs) without re-shooting it.

    python3 tools/hand_tattoos/video_patch.py IN OUT [--since <git rev>]

Every still in assets/art/ko + assets/art/loading + bg_title that changed since <rev> (default: the
last commit before Nov 18 2026) is a candidate. Per frame, ORB features find each OLD still (any pan,
zoom, panel crop) by homography; where the old and new still differ (the hands) AND the frame really
shows the old still there (not covered by a panel border or caption), the new still is warped in.
Audio is copied. Works for .mp4 and .gif (GIF palette rebuilt by ffmpeg)."""
import os, subprocess, sys, tempfile
import cv2
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEFAULT_REV = "9074c028093226002fdb123fb61679b23799cc1b"


def git_img(rev, rel):
    data = subprocess.run(["git", "show", f"{rev}:{rel}"], cwd=ROOT, capture_output=True, check=True).stdout
    return cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR)


def candidates(rev):
    out = subprocess.run(["git", "diff", "--name-only", rev, "HEAD", "--", "assets/art/ko", "assets/art/loading",
                          "assets/art/bg_title.png"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.split()
    orb = cv2.ORB_create(3000)
    c = []
    for rel in out:
        if not rel.endswith((".jpg", ".png")):
            continue
        old, new = git_img(rev, rel), cv2.imread(os.path.join(ROOT, rel))
        if old is None or new is None or old.shape != new.shape:
            continue
        diff = (np.abs(old.astype(int) - new.astype(int)).sum(2) > 10).astype(np.uint8)
        if diff.sum() < 20:
            continue
        diff = cv2.dilate(diff, np.ones((5, 5), np.uint8))
        g = cv2.cvtColor(old, cv2.COLOR_BGR2GRAY)
        kp, des = orb.detectAndCompute(g, None)
        c.append(dict(rel=rel, old=old, new=new, diff=diff, kp=kp, des=des))
    return c


def patch(frame, cands, orb, bf):
    g = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    kp, des = orb.detectAndCompute(g, None)
    if des is None:
        return frame, []
    hits = []
    H_, W_ = frame.shape[:2]
    for c in cands:
        ms = bf.knnMatch(c["des"], des, k=2)
        good = [m for m, n in (p for p in ms if len(p) == 2) if m.distance < 0.75 * n.distance]
        if len(good) < 25:
            continue
        src = np.float32([c["kp"][m.queryIdx].pt for m in good])
        dst = np.float32([kp[m.trainIdx].pt for m in good])
        H, inl = cv2.findHomography(src, dst, cv2.RANSAC, 3.0)
        if H is None or inl.sum() < 25:
            continue
        old_w = cv2.warpPerspective(c["old"], H, (W_, H_))
        new_w = cv2.warpPerspective(c["new"], H, (W_, H_))
        d_w = cv2.warpPerspective(c["diff"] * 255, H, (W_, H_)) > 127
        shows = np.abs(frame.astype(int) - old_w.astype(int)).sum(2) < 90
        m = (d_w & cv2.erode(shows.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool)).astype(np.float32)
        if m.sum() < 10:
            continue
        a = cv2.GaussianBlur(m, (0, 0), 0.8)[..., None]
        frame = (frame * (1 - a) + new_w * a).clip(0, 255).astype(np.uint8)
        hits.append(os.path.basename(c["rel"]))
    return frame, hits


def main():
    src, dst = sys.argv[1], sys.argv[2]
    rev = sys.argv[sys.argv.index("--since") + 1] if "--since" in sys.argv else DEFAULT_REV
    cands = candidates(rev)
    print("candidates:", [os.path.basename(c["rel"]) for c in cands])
    orb, bf = cv2.ORB_create(4000), cv2.BFMatcher(cv2.NORM_HAMMING)
    cap = cv2.VideoCapture(src)
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    tmp = tempfile.mkdtemp()
    n = 0
    seen = {}
    while True:
        ok, f = cap.read()
        if not ok:
            break
        f, hits = patch(f, cands, orb, bf)
        for h in hits:
            seen[h] = seen.get(h, 0) + 1
        cv2.imwrite(os.path.join(tmp, f"f{n:05d}.png"), f)
        n += 1
    print("frames", n, "patched:", seen)
    if dst.endswith(".gif"):
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(fps), "-i", os.path.join(tmp, "f%05d.png"),
                        "-vf", "split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a",
                        "-loop", "0", dst], check=True)
    else:
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-framerate", str(fps), "-i", os.path.join(tmp, "f%05d.png"),
                        "-i", src, "-map", "0:v", "-map", "1:a?", "-c:v", "libx264", "-crf", "18", "-preset", "medium",
                        "-pix_fmt", "yuv420p", "-c:a", "copy", "-movflags", "+faststart", dst], check=True)
    subprocess.run(["rm", "-rf", tmp])


if __name__ == "__main__":
    main()
