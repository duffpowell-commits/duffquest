#!/usr/bin/env python3
"""Fail if the web build makes no sound.

    python3 tools/web_audio_check.py build/web           # CI: after the web export, before itch

Nov 19: the whole web game shipped silent (runtime-added buses are ignored by web sample playback) and
nothing caught it. This boots the build in headless Chrome, taps an analyser onto every connection into
the AudioDestination (so it hears exactly what reaches the speakers), and checks the title music peaks
above PEAK_MIN. Exit 1 = silent build. Needs Python playwright (installed on first run) and Chrome.
"""
import argparse
import functools
import http.server
import os
import shutil
import subprocess
import sys
import threading
import time

PEAK_MIN = 0.05        # the live title theme peaks ~0.7; silence is 0.0

TAP = r"""
(() => {
  const orig = AudioNode.prototype.connect;
  window.__dq_peak = 0; window.__dq_ctx = 0;
  AudioNode.prototype.connect = function (dest, ...rest) {
    const r = orig.call(this, dest, ...rest);
    try {
      if (dest instanceof AudioDestinationNode) {
        const ctx = dest.context;
        if (!ctx.__dq_an) {
          const an = ctx.createAnalyser(); an.fftSize = 2048; ctx.__dq_an = an; window.__dq_ctx++;
          window.__dq_ac = ctx;
          const buf = new Float32Array(an.fftSize);
          setInterval(() => {
            an.getFloatTimeDomainData(buf);
            let m = 0; for (let i = 0; i < buf.length; i++) { const v = Math.abs(buf[i]); if (v > m) m = v; }
            if (m > window.__dq_peak) window.__dq_peak = m;
          }, 40);
        }
        orig.call(this, ctx.__dq_an);
      }
    } catch (e) {}
    return r;
  };
})();
"""


class Quiet(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".pck": "application/octet-stream", ".js": "text/javascript"}

    def log_message(self, *a):
        pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("web", nargs="?", default="build/web")
    ap.add_argument("--listen", type=float, default=8.0, help="seconds to listen per scene")
    ap.add_argument("--timeout", type=float, default=240.0, help="seconds to reach the title")
    a = ap.parse_args()
    web = os.path.abspath(a.web)
    if not os.path.isfile(os.path.join(web, "index.pck")):
        sys.exit("no index.pck in %s" % web)
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "-q", "--break-system-packages", "playwright"], check=True)
        # a fresh user site-packages isn't on this process's path yet: start over so the import sees it
        os.execv(sys.executable, [sys.executable] + sys.argv)

    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=web))
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    url = "http://127.0.0.1:%d/index.html" % httpd.server_address[1]
    chrome = shutil.which("google-chrome") or shutil.which("chromium")
    fails = []
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path=chrome, headless=True, args=[
            "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist",
            "--autoplay-policy=no-user-gesture-required"])
        ctx = browser.new_context(viewport={"width": 1280, "height": 720})
        ctx.add_init_script(TAP)
        page = ctx.new_page()
        page.goto(url, wait_until="load")
        t0, state = time.time(), None
        while time.time() - t0 < a.timeout:
            state = page.evaluate("(window.dq || {}).state || null")
            if state == "title":
                break
            time.sleep(0.25)
        print("title after %.1f s (state=%r)" % (time.time() - t0, state))
        if state != "title":
            fails.append("never reached the title screen")
        else:
            # a click unlocks the AudioContext like a real first tap would (autoplay flag covers most of it)
            page.mouse.click(640, 40)
            page.evaluate("window.__dq_peak = 0")
            time.sleep(a.listen)
            peak = page.evaluate("window.__dq_peak")
            n = page.evaluate("window.__dq_ctx")
            print("title: peak %.3f over %.0f s (%d audio context(s) tapped)" % (peak, a.listen, n))
            print("audio context:", page.evaluate("(() => { const c = window.__dq_ac; return c ? {state: c.state, t: c.currentTime, rate: c.sampleRate, lat: c.baseLatency} : null; })()"))
            if peak < PEAK_MIN:
                fails.append("title is silent (peak %.3f < %.2f)" % (peak, PEAK_MIN))
        browser.close()
    httpd.shutdown()
    for f in fails:
        print("FAIL:", f)
    print("WEB AUDIO CHECK", "FAIL" if fails else "PASS")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
