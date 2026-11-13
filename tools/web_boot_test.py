# Headless-Chrome boot timer for the web build: python3 tools/web_boot_test.py <build_dir> <port> <label>
# Throttles to "decent 4G" (9 Mbit/s, 70 ms), prints seconds until the engine is running, bytes per file, and
# when world.pck (gates New Game) and extra.pck mounted. Needs playwright + /usr/bin/google-chrome (cloud sandbox has both).
import asyncio, sys, time, threading, functools, http.server, socketserver, gzip, os
from playwright.async_api import async_playwright
root, port, label = sys.argv[1], int(sys.argv[2]), sys.argv[3]
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
    def do_GET(self):
        # serve the deferred packs gzip-encoded like itch's CDN does (Nov 13: that broke them on the live build)
        p=self.path.split('?')[0]
        if p in ('/world.pck','/extra.pck'):
            data=gzip.compress(open(os.path.join(root,p[1:]),'rb').read(),1)
            self.send_response(200); self.send_header('Content-Type','application/octet-stream')
            self.send_header('Content-Encoding','gzip'); self.send_header('Content-Length',str(len(data))); self.end_headers()
            self.wfile.write(data); return
        return super().do_GET()
socketserver.TCPServer.allow_reuse_address=True
srv=socketserver.ThreadingTCPServer(("127.0.0.1",port),functools.partial(Q,directory=root))
threading.Thread(target=srv.serve_forever,daemon=True).start()
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path="/usr/bin/google-chrome",args=["--use-angle=swiftshader","--enable-unsafe-swiftshader","--ignore-gpu-blocklist"])
        pg=await b.new_page(viewport={"width":1280,"height":720})
        cdp=await pg.context.new_cdp_session(pg)
        await cdp.send("Network.enable")
        # "decent 4G": 9 Mbit/s down, 70 ms RTT
        await cdp.send("Network.emulateNetworkConditions",{"offline":False,"latency":70,"downloadThroughput":9_000_000/8,"uploadThroughput":3_000_000/8})
        got={}; logs=[]
        cdp.on("Network.loadingFinished", lambda e: got.__setitem__(e["requestId"], e.get("encodedDataLength",0)))
        urls={}
        cdp.on("Network.responseReceived", lambda e: urls.__setitem__(e["requestId"], e["response"]["url"].split("/")[-1]))
        pg.on("console", lambda m: logs.append((round(time.time()-t0,1), m.text)))
        t0=time.time()
        await pg.goto(f"http://127.0.0.1:{port}/index.html")
        boot=None
        for _ in range(960):
            hit=[ts for ts,t in logs if "Build configuration" in t]
            if hit: boot=hit[0]; break
            await pg.wait_for_timeout(250)
        await pg.wait_for_timeout(4000)
        await pg.screenshot(path=f"/tmp/bt/{label}_boot.png")
        for _ in range(240):
            if any("extra.pck: mounted" in t for _,t in logs): break
            await pg.wait_for_timeout(500)
        when=lambda k: next((ts for ts,t in logs if k in t), None)
        print(f"[{label}] engine + game pack running after {boot}s on throttled 4G")
        tot=0
        for rid,n in got.items():
            nm=urls.get(rid,"?")
            if n>200000: print(f"   {nm:22s} {n/1e6:6.1f} MB on the wire")
            tot+=n
        print(f"   total {tot/1e6:.1f} MB; gz loader used: {await pg.evaluate('!!window.__dq_wasm_gz')}")
        errs=[t for _,t in logs if "ERROR" in t or "rror" in t]
        print(f"   world.pck mounted (New Game ready) at {when('world.pck: mounted')}s, extra.pck at {when('extra.pck: mounted')}s")
        print("   console errors:", errs[:5])
        await b.close()
asyncio.run(main())
