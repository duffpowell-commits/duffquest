#!/usr/bin/env python3
"""Boot the web build in headless Chrome as a phone, play the first seconds, fail on console errors.

    python3 tools/web_boot_check.py              # export first (tools/ship_itch.sh --no-push), then check
    python3 tools/web_boot_check.py --no-export  # check the existing build/web
    python3 tools/web_boot_check.py --net fast4g # also throttle the network (first-boot download time)

Phone profile: 915x412 landscape CSS px, DPR 2.625, touch, Android Chrome UA, 4x CPU throttle,
WebGL2 through SwiftShader (software, so frame times are a pessimistic floor, not a real phone).
Steps: load -> title screen (window.dq.state, published by scripts/perf_guard.gd) -> tap New Game ->
tap through the intro -> drag the joystick and check Duff moved -> screenshot
docs/renders/web_boot_mobile.png. Writes a JSON summary to /tmp/web_boot_check.json.
Exit 1 on any console error / page error, or if a step doesn't happen. Needs: pip install playwright
(--break-system-packages) and Chrome (/usr/bin/google-chrome, or playwright's chromium).
"""
import argparse
import functools
import http.server
import json
import os
import shutil
import subprocess
import sys
import threading
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, "build", "web")
SHOT = os.path.join(ROOT, "docs", "renders", "web_boot_mobile.png")
UA = ("Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/131.0.0.0 Mobile Safari/537.36")
NETS = {  # Chrome DevTools presets (bytes/s, ms)
    "fast4g": dict(downloadThroughput=9e6 / 8, uploadThroughput=1.5e6 / 8, latency=60),
    "slow4g": dict(downloadThroughput=1.6e6 / 8, uploadThroughput=0.75e6 / 8, latency=150),
}
# Emscripten prints these via console.error every 10 s while index.wasm is still downloading
# (slow networks). Not errors; logged as "benign" instead of failing the check.
BENIGN = ("still waiting on run dependencies", "dependency: wasm-instantiate", "(end of list)")
# Points in the 320x180 UI space (main.UI_SCALE = 2 on the 640x360 game).
NEW_GAME = (55, 162)      # card.gd: first of 3 buttons on the bottom row (no save -> New Game)
BTN_A = (296, 140)        # touch_controls.gd
JOY = (36, 142)


class Quiet(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".pck": "application/octet-stream", ".js": "text/javascript"}

    def log_message(self, *a):
        pass


def serve(directory):
    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=directory))
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--no-export", action="store_true", help="use the existing build/web")
    ap.add_argument("--net", choices=sorted(NETS), help="throttle the network too")
    ap.add_argument("--cpu", type=float, default=4.0, help="CPU throttle rate (default 4x)")
    ap.add_argument("--timeout", type=float, default=600.0, help="seconds to reach the title")
    ap.add_argument("--shot", default=SHOT)
    ap.add_argument("--hash", default="", help="URL hash, e.g. lite")
    a = ap.parse_args()

    if not a.no_export:
        env = dict(os.environ)
        subprocess.run([os.path.join(ROOT, "tools", "ship_itch.sh"), "--no-push"], check=True, env=env, cwd=ROOT)
    if not os.path.isfile(os.path.join(WEB, "index.pck")):
        sys.exit("no build/web/index.pck; run without --no-export")
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "-q", "--break-system-packages", "playwright"], check=True)
        from playwright.sync_api import sync_playwright

    sizes = {f: os.path.getsize(os.path.join(WEB, f)) for f in os.listdir(WEB)}
    httpd = serve(WEB)
    url = "http://127.0.0.1:%d/index.html%s" % (httpd.server_address[1], ("#" + a.hash) if a.hash else "")
    errors, warnings, benign, log = [], [], [], []
    res = {"url": url, "bytes": sum(sizes.values()), "files": sizes, "cpu_throttle": a.cpu, "net": a.net or "local"}
    ok = True

    def fail(msg):
        nonlocal ok
        ok = False
        print("FAIL:", msg)
        res.setdefault("fail", []).append(msg)

    chrome = shutil.which("google-chrome") or shutil.which("chromium")
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=chrome, headless=True, args=[
            "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist",
            "--autoplay-policy=no-user-gesture-required"])
        ctx = browser.new_context(viewport={"width": 915, "height": 412}, device_scale_factor=2.625,
                                  is_mobile=True, has_touch=True, user_agent=UA)
        page = ctx.new_page()

        def on_console(m):
            line = "[%s] %s" % (m.type, m.text)
            log.append(line)
            if m.type == "error" and any(b in m.text for b in BENIGN):
                benign.append(m.text)
            elif m.type == "error":
                errors.append(m.text)
            elif m.type == "warning":
                warnings.append(m.text)
        page.on("console", on_console)
        page.on("pageerror", lambda e: errors.append("pageerror: %s" % e))
        cdp = ctx.new_cdp_session(page)
        cdp.send("Emulation.setCPUThrottlingRate", {"rate": a.cpu})
        if a.net:
            cdp.send("Network.enable")
            cdp.send("Network.emulateNetworkConditions", {"offline": False, **NETS[a.net]})

        def dq():
            return page.evaluate("window.dq || null")

        def to_css(pt):
            """UI point (320x180) -> CSS px, from the game's own stretch transform (dq.xf)."""
            d = dq() or {}
            s, ox, oy = d.get("xf", [None, None, None])
            box = page.evaluate("(() => { const c = document.querySelector('#canvas');"
                                " const r = c.getBoundingClientRect(); return [r.left, r.top, c.width / r.width]; })()")
            if s is None:   # fallback: integer stretch, centred
                w, h = d.get("win", [915 * 2.625, 412 * 2.625])
                s = max(1, int(min(w / 640, h / 360)))
                ox, oy = (w - 640 * s) / 2, (h - 360 * s) / 2
            return box[0] + (ox + pt[0] * 2 * s) / box[2], box[1] + (oy + pt[1] * 2 * s) / box[2]

        def tap(pt):
            x, y = to_css(pt)
            page.touchscreen.tap(x, y)

        t0 = time.time()
        page.goto(url, wait_until="load")
        state = None
        while time.time() - t0 < a.timeout:
            d = dq()
            state = d and d.get("state")
            if state == "title":
                break
            if errors and any("Couldn't load" in e or "abort" in e.lower() for e in errors):
                break
            time.sleep(0.25)
        res["title_s"] = round(time.time() - t0, 1)
        timing = page.evaluate("""(() => performance.getEntriesByType('resource')
            .filter(e => /index\\.(pck|wasm)$/.test(e.name))
            .map(e => [e.name.split('/').pop(), Math.round(e.responseEnd), e.transferSize]))()""")
        res["downloads_ms"] = {n: t for n, t, _ in timing}
        print("title screen after %.1f s (%s)" % (res["title_s"], ", ".join("%s done @%.1fs" % (n, t / 1000) for n, t, _ in timing)))
        if state != "title":
            fail("never reached the title screen (state=%r)" % state)
        else:
            time.sleep(1.5)
            tap(NEW_GAME)
            t1 = time.time()
            # tap through the intro dialogue / loading screen / fridge calendar until Duff is free
            taps = 0
            while time.time() - t1 < 90:
                d = dq() or {}
                if d.get("state") == "play":
                    break
                if d.get("state") in ("dialog", "busy") and time.time() - t1 > 1.0:
                    tap(BTN_A)
                    taps += 1
                time.sleep(0.8)
            d = dq() or {}
            res["intro_taps"] = taps
            if d.get("state") != "play":
                fail("new game never reached free play (state=%r)" % d.get("state"))
            else:
                p0 = (d["px"], d["py"])
                # drag the joystick right (and a bit down) and hold it ~2.5 s, sampling frame times
                x0, y0 = to_css(JOY)
                x1, y1 = to_css((JOY[0] + 18, JOY[1] + 4))
                page.evaluate("""(() => { window.__ft = []; let last = performance.now();
                    const f = (t) => { window.__ft.push(t - last); last = t; if (window.__ft.length < 100000) requestAnimationFrame(f); };
                    requestAnimationFrame(f); })()""")
                pt = lambda x, y: [{"x": x, "y": y, "id": 1}]
                cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": pt(x0, y0)})
                for i in range(1, 9):
                    cdp.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": pt(x0 + (x1 - x0) * i / 8, y0 + (y1 - y0) * i / 8)})
                    time.sleep(0.05)
                time.sleep(2.5)
                d = dq() or {}
                p1 = (d.get("px", 0), d.get("py", 0))
                page.screenshot(path=a.shot, scale="css")
                cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
                ft = sorted(page.evaluate("window.__ft.slice(5)"))
                moved = ((p1[0] - p0[0]) ** 2 + (p1[1] - p0[1]) ** 2) ** 0.5
                res.update(walk_from=p0, walk_to=p1, moved_px=round(moved, 1), loc=d.get("loc"), lite=d.get("low"),
                           game_fps=d.get("fps"))
                if ft:
                    res["frame_ms"] = {"mean": round(sum(ft) / len(ft), 1), "p50": round(ft[len(ft) // 2], 1),
                                       "p95": round(ft[int(len(ft) * 0.95)], 1), "n": len(ft)}
                print("walked %.0f px in %s; frame ms %s; game fps %s; lite %s" % (moved, d.get("loc"), res.get("frame_ms"), d.get("fps"), d.get("low")))
                if moved < 8:
                    fail("joystick drag didn't move Duff (%s -> %s)" % (p0, p1))
                print("screenshot:", os.path.relpath(a.shot, ROOT))
        browser.close()
    httpd.shutdown()
    res.update(console_errors=errors, console_warnings=warnings, benign_emscripten=len(benign))
    for e in errors:
        print("CONSOLE ERROR:", e[:300])
    for w in warnings[:20]:
        print("console warning:", w[:200])
    if errors:
        fail("%d console error(s)" % len(errors))
    with open("/tmp/web_boot_check.json", "w") as fh:
        json.dump(res | {"log": log[-200:]}, fh, indent=1)
    print("WEB BOOT CHECK", "PASS" if ok else "FAIL", "(%d errors, %d warnings)" % (len(errors), len(warnings)))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
