"""Paste docs/itch/page.html into the Duff Quest itch page description.

itch has no API for page edits, so this drives a real browser the way a person would.
Runs only from .github/workflows/itch_page.yml. Anti-flag rules (keep them):
  * one login at most per run, never retried; a saved session is reused when it still works
  * stops cold on a captcha, 2FA prompt or anything unexpected, saving a screenshot
  * touches only the description field, then checks the public page shows the new text
Env: ITCH_USERNAME, ITCH_PASSWORD, ITCH_TOTP_SECRET (optional), GAME_ID, PAGE_FILE,
     STATE_FILE (session cookies in/out), DRY_RUN=1 to fill nothing and save nothing, OUT dir for shots.
"""
import os, sys, time, random, re, html as htmllib
from playwright.sync_api import sync_playwright

OUT = os.environ.get("OUT", "itch_page_out")
os.makedirs(OUT, exist_ok=True)
GAME_ID = os.environ["GAME_ID"]
STATE = os.environ.get("STATE_FILE", "")
DRY = os.environ.get("DRY_RUN") == "1"
PAGE = open(os.environ.get("PAGE_FILE", "docs/itch/page.html")).read()
summary = []

def say(msg):
    print(msg, flush=True); summary.append(msg)

def pause(a=0.6, b=1.6):
    time.sleep(random.uniform(a, b))

def finish(code, page=None, shot="final"):
    if page is not None:
        try: page.screenshot(path=f"{OUT}/{shot}.png", full_page=False)
        except Exception: pass
    with open(f"{OUT}/summary.md", "w") as f:
        f.write("\n".join(f"- {s}" for s in summary) + "\n")
    sys.exit(code)

def blocked(page):
    html = page.content().lower()
    for word in ("recaptcha", "hcaptcha", "captcha", "verify you are human", "cf-challenge", "challenge-platform", "just a moment", "attention required", "access denied"):
        if word in html: return word
    return None

def login(page):
    page.goto("https://itch.io/login", wait_until="domcontentloaded"); pause(1.5, 3)
    if (w := blocked(page)): say(f"STOP: login page shows {w}. Not trying."); finish(2, page, "login_blocked")
    if not page.query_selector("input[name=username]"):
        say(f"STOP: login page has no username box. Title: {page.title()!r}. Text: {page.inner_text('body')[:300]!r}")
        finish(2, page, "login_odd")
    page.click("input[name=username]"); page.keyboard.type(os.environ["ITCH_USERNAME"], delay=random.randint(60, 140)); pause()
    page.click("input[name=password]"); page.keyboard.type(os.environ["ITCH_PASSWORD"], delay=random.randint(60, 140)); pause()
    page.keyboard.press("Enter")
    page.wait_for_load_state("domcontentloaded"); pause(2, 3.5)
    if "totp" in page.url or page.query_selector("input[name=code]"):
        secret = os.environ.get("ITCH_TOTP_SECRET")
        if not secret: say("STOP: itch asks for a 2FA code and ITCH_TOTP_SECRET isn't set."); finish(2, page, "login_2fa")
        import pyotp
        page.fill("input[name=code]", pyotp.TOTP(secret).now()); pause(); page.keyboard.press("Enter")
        page.wait_for_load_state("domcontentloaded"); pause(2, 3)
    if "/login" in page.url:
        err = page.query_selector(".form_errors, .global_flash")
        say("STOP: login failed" + (f": {err.inner_text().strip()[:160]}" if err else "") + ". Not retrying.")
        finish(2, page, "login_failed")
    say("Logged in with username + password.")

CUR = {}

def run(p):
    browser = p.chromium.launch(headless=False, args=["--disable-blink-features=AutomationControlled"])
    ctx_args = dict(viewport={"width": 1366, "height": 900}, locale="en-US", timezone_id="America/Chicago")
    if STATE and os.path.exists(STATE):
        ctx_args["storage_state"] = STATE
    ctx = browser.new_context(**ctx_args)
    page = ctx.new_page(); CUR['page'] = page
    edit = f"https://itch.io/game/edit/{GAME_ID}"
    page.goto(edit, wait_until="domcontentloaded"); pause(1.5, 3)
    if "/login" in page.url:
        say("Saved session missing or expired; logging in once.")
        login(page)
        page.goto(edit, wait_until="domcontentloaded"); pause(1.5, 3)
    else:
        say("Reused the saved itch session (no login).")
    if (w := blocked(page)): say(f"STOP: edit page shows {w}."); finish(2, page, "edit_blocked")
    ta = page.query_selector("textarea[name*=description]")
    if not ta:
        names = page.eval_on_selector_all("textarea, input", "els => els.map(e => e.name).filter(Boolean)")
        say(f"STOP: no description field on {page.url}. Fields seen: {names[:40]}"); finish(2, page, "edit_no_field")
    if STATE: ctx.storage_state(path=STATE)
    old = ta.input_value()
    say(f"Edit page OK. Field `{ta.get_attribute('name')}`, current description {len(old)} chars, new {len(PAGE)} chars.")
    norm = lambda h: re.sub(r"\s+", " ", htmllib.unescape(h)).strip()
    if norm(old) == norm(PAGE):
        say("Description already matches page.html. Nothing to do."); finish(0, page)
    if DRY:
        say("DRY RUN: found everything, changed nothing."); finish(0, page, "dry_run")
    # Put the HTML into the hidden textarea and the visible rich editor, so whichever one itch reads on save has it.
    page.evaluate("""([sel, html]) => {
        const ta = document.querySelector(sel); ta.value = html;
        ta.dispatchEvent(new Event('input', {bubbles: true})); ta.dispatchEvent(new Event('change', {bubbles: true}));
        for (const ed of document.querySelectorAll('.redactor-editor, .redactor-in, [contenteditable=true]')) {
            if (ed.closest('form') === ta.closest('form')) { ed.innerHTML = html; ed.dispatchEvent(new Event('input', {bubbles: true})); }
        }
        try { if (window.jQuery && jQuery(ta).redactor) jQuery(ta).redactor('code.set', html); } catch (e) {}
        try { if (window.$R) $R(ta, 'source.setCode', html); } catch (e) {}
    }""", ["textarea[name*=description]", PAGE])
    pause(1, 2)
    page.screenshot(path=f"{OUT}/before_save.png")
    form = page.evaluate_handle("document.querySelector('textarea[name*=description]').closest('form')")
    btn = form.as_element().query_selector("button[type=submit], input[type=submit]")
    if not btn: say("STOP: no Save button found."); finish(2, page, "no_save")
    btn.click(); page.wait_for_load_state("domcontentloaded"); pause(2, 4)
    errs = page.query_selector(".form_errors")
    if errs and errs.inner_text().strip():
        say(f"STOP: itch refused the save: {errs.inner_text().strip()[:200]}"); finish(2, page, "save_error")
    say("Saved.")
    if STATE: ctx.storage_state(path=STATE)
    # Check the public page: the newest h2 heading from page.html must be there.
    marker = re.findall(r"<h2>(.*?)</h2>", PAGE)[0].replace("&amp;", "&")
    pub = ctx.new_page(); pub.goto(os.environ.get("GAME_URL", "https://dufftkyosht.itch.io/duff-quest"), wait_until="domcontentloaded"); pause(1, 2)
    text = pub.inner_text("body")
    if marker in text:
        say(f"VERIFIED live: public page shows \"{marker}\"."); finish(0, pub, "live")
    say(f"STOP: saved, but the public page doesn't show \"{marker}\" yet."); finish(3, pub, "live_missing")


with sync_playwright() as p:
    try:
        run(p)
    except SystemExit:
        raise
    except Exception as e:
        pg = CUR.get("page")
        where = ""
        try: where = f" at {pg.url} (title {pg.title()!r})"
        except Exception: pass
        say(f"CRASH{where}: {type(e).__name__}: {str(e).splitlines()[0][:200]}")
        finish(4, pg, "crash")
