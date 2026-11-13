extends "res://scripts/minigames/minigame.gd"

const Market: = preload("res://scripts/market.gd")
const Errands: = preload("res://scripts/errands.gd")
const SideQuests: = preload("res://scripts/side_quests.gd")
const C_ME: = Color("#2f6fd6")
const C_THEM: = Color("#3a3846")
const C_UP: = Color("#7aa05a")
const C_DOWN: = Color("#ff6b6b")
const CLEAR: = Color(0, 0, 0, 0)

var m: Node = null
var screen: = "home"
var acct: = "brokerage"
var sel_t: = "VOOM"
var action: = ""
var tip_i: = 0

func _setup() -> void:
	time_limit = 0.0
	show_header = false
	space_is_pen = false
	tip_i = randi() % Market.TIPS.size()
	show_screen(screen)

func show_screen(s: String) -> void:
	screen = s
	buttons.clear()
	match s:
		"home":
			var n_unread: int = m.unread_count() if m else 0
			_app(add_button("messages", Rect2(10, 40, 70, 40), "Messages" + (" (%d)" % n_unread if n_unread > 0 else ""), KEY_1, Color("#4e7a3a")), "kf_app_messages", true)
			_app(add_button("stonks", Rect2(88, 40, 70, 40), "Stonks", KEY_2, Color("#3a5a2c")), "kf_app_stonks", true)
			_app(add_button("fund", Rect2(166, 40, 70, 40), "{baby}'s Fund", KEY_3, Color("#6a4a96")), "kf_app_fund", true)
			_app(add_button("gear", Rect2(244, 40, 66, 40), "Gear", KEY_4, Color("#7a5a2a")), "kf_app_gear", true)
			if m and m.gala_unlocked:
				add_button("gala_thread", Rect2(10, 88, 300, 26), "THE ELITE GALA  (invitation)", KEY_5, Color("#a08020"))
			_app(add_button("settings", Rect2(10, 152, 92, 22), "Settings", KEY_6, Color("#57504e")), "kf_app_settings", false)
			add_button("close", Rect2(110, 152, 100, 22), "Close", KEY_ESCAPE, Color("#a43a2c"))
			var n_new: int = SideQuests.unread(m.side_quests, m.show_hidden_quests) if m else 0
			_app(add_button("notes", Rect2(218, 152, 92, 22), "Notes" + (" (%d)" % n_new if n_new > 0 else ""), KEY_7, Color("#2f8a80")), "kf_app_notes", false)
		"notes":
			add_button("back", Rect2(110, 156, 100, 20), "Back", KEY_ESCAPE)
		"messages":
			var ml: = "{partner} <3" + ("   * NEW *" if m and m.unread.get("madison", false) else "") + "\n" + _preview("madison")
			add_button("thread_madison", Rect2(6, 18, 308, 30), ml, KEY_1, CLEAR)
			var lbl: = "{sister}" + ("   * NEW *" if m and m.unread.get("sister", false) else "") + "\n" + _preview("sister")
			add_button("thread_sister", Rect2(6, 52, 308, 30), lbl, KEY_2, CLEAR)
			if m and m.gala_unlocked:
				add_button("gala_thread", Rect2(6, 86, 308, 30), "Unknown Number" + ("   * NEW *" if m.unread.get("gala", false) else "") + "\n" + _preview("gala"), KEY_3, CLEAR)
			add_button("back", Rect2(110, 152, 100, 22), "Back", KEY_ESCAPE)
		"thread_madison":
			if m:
				m.unread["madison"] = false
			add_button("back", Rect2(212, 154, 102, 22), "Back", KEY_ESCAPE)
		"thread_sister":
			if m:
				m.unread["sister"] = false
			if m and not m.wordle_daily_done():
				add_button("daily", Rect2(6, 154, 200, 22), "Play today's {wordle}", KEY_1, Color("#4e7a3a"))
			elif m and not m.wordle_practice_done():
				add_button("practice", Rect2(6, 154, 200, 22), "Practice round (small rewards)", KEY_1, Color("#2e5aa8"))
			add_button("back", Rect2(212, 154, 102, 22), "Back", KEY_ESCAPE)
		"gala_thread":
			if m:
				m.unread["gala"] = false
			add_button("gala", Rect2(6, 154, 200, 22), "Take the limo to the Gala", KEY_1, Color("#a08020"))
			add_button("back", Rect2(212, 154, 102, 22), "Back", KEY_ESCAPE)
		"stonks":
			for i in Market.ASSETS.size():
				add_button("t_" + Market.ASSETS[i]["t"], Rect2(4, 30 + i * 15, 312, 14), "", [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7][i], CLEAR)
			add_button("acct", Rect2(4, 154, 120, 22), "Acct: " + _acct_name(), KEY_Q, Color("#6a4a96"))
			add_button("portfolio", Rect2(128, 154, 90, 22), "Portfolio", KEY_W, Color("#3a5a2c"))
			add_button("back", Rect2(222, 154, 94, 22), "Back", KEY_ESCAPE)
		"asset":
			var labels: = [["b10", "Buy $10", KEY_1], ["b50", "Buy $50", KEY_2], ["b250", "Buy $250", KEY_3], ["bmax", "Buy MAX", KEY_4]]
			for i in 4:
				add_button(labels[i][0], Rect2(4 + i * 79, 130, 75, 20), labels[i][1], labels[i][2], Color("#3a5a2c"))
			add_button("s25", Rect2(4, 154, 100, 22), "Sell 25%", KEY_5, Color("#7a2a22"))
			add_button("sall", Rect2(108, 154, 100, 22), "Sell ALL", KEY_6, Color("#7a2a22"))
			add_button("back", Rect2(212, 154, 104, 22), "Back", KEY_ESCAPE)
		"portfolio":
			add_button("drip", Rect2(4, 154, 120, 22), "DRIP: " + ("ON" if m.account(acct)["drip"] else "OFF"), KEY_D, Color("#2e5aa8"))
			add_button("acct", Rect2(128, 154, 90, 22), "Acct: " + _acct_name(), KEY_Q, Color("#6a4a96"))
			add_button("back", Rect2(222, 154, 94, 22), "Back", KEY_ESCAPE)
		"fund":
			var d: = [["d20", "+$20", KEY_1], ["d100", "+$100", KEY_2], ["d500", "+$500", KEY_3], ["dall", "+ALL", KEY_4]]
			for i in 4:
				add_button(d[i][0], Rect2(4 + i * 79, 108, 75, 20), d[i][1], d[i][2], Color("#6a4a96"))
			add_button("invest", Rect2(4, 132, 154, 20), "Invest fund cash", KEY_I, Color("#3a5a2c"))
			add_button("drip", Rect2(162, 132, 154, 20), "Fund DRIP: " + ("ON" if m.account("college")["drip"] else "OFF"), KEY_D, Color("#2e5aa8"))
			add_button("back", Rect2(110, 156, 100, 20), "Back", KEY_ESCAPE)

func _short_name(a: Dictionary) -> String:
	var n: = str(a["name"])
	var t: = str(a["t"])
	return n.substr(t.length() + 1) if n.begins_with(t + " ") else n

func _acct_name() -> String:
	return "Brokerage" if acct == "brokerage" else "{baby}'s Fund"

func _preview(th: String) -> String:
	var msgs: Array = m.threads.get(th, []) if m else []
	if msgs.is_empty():
		return "(no messages)"
	var s: = str(msgs[-1].get("text", ""))
	return s.substr(0, 48) + ("..." if s.length() > 48 else "")

func _close_with(a: String) -> void:
	action = a
	finish(1.0)

func _on_button(id: String) -> void:
	match id:
		"close": _close_with("")
		"back":
			match screen:
				"asset", "portfolio": show_screen("stonks")
				"thread_sister", "gala_thread", "thread_madison": show_screen("messages")
				_: show_screen("home")
		"messages", "stonks", "fund", "thread_sister", "gala_thread", "thread_madison", "notes": show_screen(id)
		"gear": _close_with("gear")
		"settings": _close_with("settings")
		"daily": _close_with("wordle_daily")
		"practice": _close_with("wordle_practice")
		"gala": _close_with("gala")
		"portfolio": show_screen("portfolio")
		"acct":
			acct = "college" if acct == "brokerage" else "brokerage"
			show_screen(screen)
		"drip":
			var a: = "college" if screen == "fund" else acct
			m.toggle_drip(a)
			show_screen(screen)
		"invest":
			acct = "college"
			show_screen("stonks")
		"b10", "b50", "b250", "bmax":
			var amt: float = {"b10": 10.0, "b50": 50.0, "b250": 250.0, "bmax": -1.0 }[id]
			var spent: float = m.trade_buy(acct, sel_t, amt)
			if spent > 0.0:
				flash("Bought $%s of %s." % [_money(spent), sel_t], C_UP, 1.0)
			else:
				flash("Not enough cash in this account.", C_DOWN, 1.2)
		"s25", "sall":
			var got: float = m.trade_sell(acct, sel_t, 0.25 if id == "s25" else 1.0)
			if got > 0.0:
				flash("Sold for $%s.%s" % [_money(got), " Paper hands?" if not Market.is_steady(sel_t) else ""], Color.WHITE, 1.2)
			else:
				flash("I don't own any %s here." % sel_t, C_DOWN, 1.0)
		"d20", "d100", "d500", "dall":
			var want: int = {"d20": 20, "d100": 100, "d500": 500, "dall": -1 }[id]
			var got2: int = m.fund_deposit(want)
			if got2 > 0:
				flash("I deposit $%d. {partner} smiles." % got2, C_UP, 1.2)
			else:
				flash("Wallet's empty, chef.", C_DOWN, 1.0)
		_:
			if id.begins_with("t_"):
				sel_t = id.substr(2)
				show_screen("asset")

static func _money(v: float) -> String:
	var sgn: = "-" if v < 0.0 else ""
	v = absf(v)
	if v < 1000.0:
		return sgn + "%.2f" % v
	var s: = str(int(round(v)))
	var out: = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return sgn + s + out

func _pct(x: float) -> String:
	return "%s%.1f%%" % ["+" if x >= 0.0 else "", x * 100.0]

func _spark(r: Rect2, hist: Array, col: Color) -> void:
	if hist.size() < 2:
		return
	var lo: = 1000000000000.0
	var hi: = -1000000000000.0
	for v in hist:
		lo = minf(lo, float(v))
		hi = maxf(hi, float(v))
	var span: = maxf(hi - lo, hi * 0.01 + 0.0001)
	var pts: = PackedVector2Array()
	for i in hist.size():
		var x: = r.position.x + r.size.x * i / float(hist.size() - 1)
		var y: = r.end.y - r.size.y * (float(hist[i]) - lo) / span
		pts.append(Vector2(x, y))
	draw_polyline(pts, col, 1.0)

func _status_bar() -> void:
	draw_rect(Rect2(0, 0, W, 12), Color("#14100c"))
	txt(Vector2(4, 9), "{phone}", 7, Color(1, 1, 1, 0.8))
	txt(Vector2(0, 9), m.clock_text() if m else "", 7, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	draw_rect(Rect2(296, 3, 16, 6), Color(1, 1, 1, 0.7), false, 1.0)
	draw_rect(Rect2(297, 4, 11, 4), Color("#7aa05a"))

## Home-screen app tile: painted icon (kf_app_*, tools/import_kitchen_props.py); plain tile if the art is missing.
func _app(b: Dictionary, icon: String, stack: bool) -> void:
	if Art.tex(icon) != null:
		b["icon"] = icon
		b["stack"] = stack

func _draw_game() -> void:
	if screen == "home":   # wallpaper: STYLE_LOCK Duff-frame navy/teal sunburst
		UiStyle.burst(self, Rect2(0, 0, W, H), Color("#1E4A66"), Vector2(W * 0.5, H * 0.62), 24, t * 0.03)
	else:
		draw_rect(Rect2(0, 0, W, H), Color("#1c1712"))
	_status_bar()
	if m == null:
		return
	match screen:
		"home": _draw_home()
		"messages": txt(Vector2(6, 160), "", 7)
		"thread_sister": _draw_thread("sister", "{sister}")
		"thread_madison":
			_draw_thread("madison", "{partner} <3")
			_draw_errand_status()
		"gala_thread": _draw_thread("gala", "Unknown Number")
		"stonks": _draw_stonks()
		"asset": _draw_asset()
		"portfolio": _draw_portfolio()
		"fund": _draw_fund()
		"notes": _draw_notes()

func _draw_home() -> void:
	txt(Vector2(0, 30), "Home", 9, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	Art.image(self, "av_duff", Vector2(6, 13))
	var fv: float = m.fund_value()
	txt(Vector2(10, 128), "{baby}'s fund: $%s of $100,000" % _money(fv), 8, Color("#d0b0ff"))
	bar(Rect2(10, 132, 300, 5), fv / Market.GOAL, Color("#9a78c0"))
	txt(Vector2(10, 147), "Tip: " + Market.TIPS[tip_i], 7, Color(1, 1, 1, 0.55))

func _draw_top() -> void:
	if screen != "messages":
		return
	for b in buttons:
		var id: = str(b["id"])
		if id.begins_with("thread_") or id == "gala_thread":
			var key: = "gala" if id == "gala_thread" else id.substr(7)
			if AVATARS.has(key):
				var r: Rect2 = b["rect"]
				Art.image(self, str(AVATARS[key]), Vector2(r.end.x - 27.0, r.position.y + (r.size.y - 24.0) / 2.0))

const AVATARS: = {"madison": "av_madison", "sister": "av_jen", "gala": "av_gala", "chef": "av_chef", "bank": "av_bank", "sitter": "av_sitter" }

func _draw_thread(th: String, who: String) -> void:
	var top: = 38.0
	draw_rect(Rect2(0, 12, W, 12), Color("#2b2218"))
	txt(Vector2(0, 21), who, 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	if AVATARS.has(th):
		Art.image(self, str(AVATARS[th]), Vector2(W - 28.0, 13))
	var msgs: Array = m.threads.get(th, [])
	var y: = 150.0
	for i in range(msgs.size() - 1, -1, -1):
		var msg: Dictionary = msgs[i]
		var from: = str(msg.get("from", "sys"))
		var text: = Cast.T(str(msg.get("text", "")))
		var grid: Array = msg.get("grid", [])
		var bw: = clampf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10.0, 40.0, 190.0)
		var th_h: = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, bw - 8.0, 7).y
		var h: = th_h + 6.0 + (grid.size() * 5.0 + 3.0 if not grid.is_empty() else 0.0)
		if from == "sys":
			var sw: = minf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x + 8.0, 300.0)
			h = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, 292, 6).y + 4.0
			y -= h + 3.0
			if y < top:
				break
			draw_rect(Rect2((W - sw) / 2.0, y, sw, h), Color(1, 1, 1, 0.08))
			mtxt(Vector2((W - sw) / 2.0 + 4.0, y + 7.0), text, sw - 8.0, 6, Color("#f2c66a"))
			continue
		y -= h + 3.0
		if y < top:
			break
		var me: = from == "me"
		var x: = W - bw - 6.0 if me else 6.0
		draw_rect(Rect2(x, y, bw, h), C_ME if me else (Color("#5a4a1a") if from == "gala" else (Color("#a8406a") if from == "madison" else C_THEM)))
		mtxt(Vector2(x + 4.0, y + 8.0), text, bw - 8.0, 7, Color.WHITE)
		if not grid.is_empty():
			var gy: = y + th_h + 5.0
			for r in grid.size():
				var row: Array = grid[r]
				for c in row.size():
					var col: Color = [Color("#3a3a40"), Color("#c9a83a"), Color("#5aa050")][int(row[c])]
					draw_rect(Rect2(x + 4.0 + c * 5.0, gy + r * 5.0, 4, 4), col)

func _draw_stonks() -> void:
	var mk: Dictionary = m.market
	txt(Vector2(4, 20), "STONKS  week %d" % int(mk["week"]), 8, Color("#7aa05a"))
	var cash: float = m.account_cash(acct)
	txt(Vector2(120, 20), "%s  cash $%s" % [_acct_name(), _money(cash)], 7, Color.WHITE)
	var news: Array = mk.get("news", [])
	txt(Vector2(4, 28), str(news[0]) if not news.is_empty() else "", 6, Color("#f2c66a"))
	for i in Market.ASSETS.size():
		var a: Dictionary = Market.ASSETS[i]
		var t: String = a["t"]
		var y: = 30.0 + i * 15.0
		var ch: = Market.change(mk, t)
		txt(Vector2(8, y + 10), t, 8, Color.WHITE)
		txt(Vector2(52, y + 10), _short_name(a).substr(0, 24), 6, Color(1, 1, 1, 0.6))
		txt(Vector2(160, y + 10), "$" + _money(Market.price(mk, t)), 7, Color.WHITE)
		txt(Vector2(212, y + 10), _pct(ch), 7, C_UP if ch >= 0.0 else C_DOWN)
		var own: = Market.shares(m.account(acct), t)
		if own > 0.0:
			draw_circle(Vector2(5, y + 7), 1.5, Color("#e6a640"))
		_spark(Rect2(252, y + 2, 60, 10), mk["history"][t], C_UP if ch >= 0.0 else C_DOWN)
	txt(Vector2(4, 150), "1 week here = 1 quarter on Wall Street. Dividends pay every Monday.", 6, Color(1, 1, 1, 0.45))

func _draw_asset() -> void:
	var mk: Dictionary = m.market
	var a: = Market.asset(sel_t)
	txt(Vector2(4, 22), "%s  %s" % [sel_t, _short_name(a)], 8, Color("#7aa05a"))
	txt(Vector2(4, 31), "Type: %s" % a["kind"], 6, Color(1, 1, 1, 0.6))
	mtxt(Vector2(4, 40), str(a["blurb"]), 150, 7, Color(1, 1, 1, 0.85), 3)
	var px: = Market.price(mk, sel_t)
	var ch: = Market.change(mk, sel_t)
	txt(Vector2(4, 72), "$%s  %s this week" % [_money(px), _pct(ch)], 8, C_UP if ch >= 0.0 else C_DOWN)
	var y: = float(a["div"])
	txt(Vector2(4, 82), ("Dividend: %.1f%%/yr, paid every Monday" % (y * 400.0)) if y > 0.0 else "No dividend. You only win if someone pays more later.", 6, Color(1, 1, 1, 0.7))
	var ac: Dictionary = m.account(acct)
	var sh: = Market.shares(ac, sel_t)
	if sh > 0.0:
		var val: = sh * px
		var gain: = val - Market.cost(ac, sel_t)
		txt(Vector2(4, 96), "%s: %.3f sh = $%s" % [_acct_name(), sh, _money(val)], 7, Color.WHITE)
		txt(Vector2(4, 106), "Gain/loss: %s$%s (%s)" % ["+" if gain >= 0.0 else "-", _money(absf(gain)), _pct(gain / maxf(0.01, Market.cost(ac, sel_t)))], 7, C_UP if gain >= 0.0 else C_DOWN)
	else:
		txt(Vector2(4, 100), "You own none in %s." % _acct_name(), 7, Color(1, 1, 1, 0.6))
	txt(Vector2(4, 124), "Cash available: $%s" % _money(m.account_cash(acct)), 7, Color("#f2c66a"))
	var r: = Rect2(162, 40, 150, 62)
	draw_rect(r, Color(1, 1, 1, 0.04))
	var hist: Array = mk["history"][sel_t]
	_spark(r, hist, C_UP if float(hist[-1]) >= float(hist[0]) else C_DOWN)
	txt(Vector2(162, 112), "last %d weeks" % hist.size(), 6, Color(1, 1, 1, 0.45))

func _draw_portfolio() -> void:
	var mk: Dictionary = m.market
	var ac: Dictionary = m.account(acct)
	txt(Vector2(4, 22), "PORTFOLIO: " + _acct_name(), 8, Color("#7aa05a"))
	var y: = 34.0
	for t in ac["holdings"]:
		var sh: = Market.shares(ac, t)
		var val: = sh * Market.price(mk, t)
		var c: = Market.cost(ac, t)
		var g: = (val - c) / maxf(0.01, c)
		txt(Vector2(6, y), t, 7, Color.WHITE)
		txt(Vector2(52, y), "%.3f sh" % sh, 6, Color(1, 1, 1, 0.7))
		txt(Vector2(130, y), "$" + _money(val), 7, Color.WHITE)
		txt(Vector2(200, y), _pct(g), 7, C_UP if g >= 0.0 else C_DOWN)
		y += 11.0
	if (ac["holdings"] as Dictionary).is_empty():
		txt(Vector2(6, y), "Nothing yet. Start with an index fund. Boring = good.", 7, Color(1, 1, 1, 0.6))
	var hv: = Market.holdings_value(ac, mk)
	var tc: = Market.total_cost(ac)
	txt(Vector2(6, 124), "Invested $%s   Worth $%s   (%s)" % [_money(tc), _money(hv), _pct((hv - tc) / maxf(0.01, tc))], 7, Color("#f2c66a"))
	txt(Vector2(6, 136), "Dividends earned: $%s   DRIP %s" % [_money(float(ac["divs"])), "reinvests them into more shares" if ac["drip"] else "pays them out as cash"], 6, Color(1, 1, 1, 0.7))
	var steady: = 0.0
	for t in ac["holdings"]:
		if Market.is_steady(t):
			steady += Market.shares(ac, t) * Market.price(mk, t)
	if hv > 0.0:
		txt(Vector2(6, 146), "Steady (index/dividend/bonds): %d%%" % int(steady / hv * 100.0), 6, Color(1, 1, 1, 0.55))

func _draw_fund() -> void:
	var mk: Dictionary = m.market
	var ac: Dictionary = m.account("college")
	var fv: float = m.fund_value()
	txt(Vector2(4, 22), "{BABY}'S COLLEGE FUND", 8, Color("#d0b0ff"))
	bar(Rect2(4, 28, 312, 10), fv / Market.GOAL, Color("#9a78c0"))
	txt(Vector2(4, 50), "$%s of $100,000  (%.1f%%)" % [_money(fv), fv / Market.GOAL * 100.0], 8, Color.WHITE)
	txt(Vector2(4, 62), "You've put in: $%s   Dividends: $%s" % [_money(float(ac["deposited"])), _money(float(ac["divs"]))], 7, Color(1, 1, 1, 0.75))
	txt(Vector2(4, 72), "Uninvested fund cash: $%s   Invested: $%s" % [_money(float(ac["cash"])), _money(Market.holdings_value(ac, mk))], 7, Color(1, 1, 1, 0.75))
	txt(Vector2(4, 84), "Wallet: $%d. Deposits make {partner} happy. No withdrawals: it's {baby}'s." % m.money, 6, Color("#f2c66a"))
	txt(Vector2(4, 96), "Cash just sits there. Invest it: the fund can hold Stonks too.", 6, Color(1, 1, 1, 0.55))

func _draw_errand_status() -> void:

	var e: Dictionary = m.errand
	var st: = str(e.get("status", ""))
	if st == "":
		return
	var label: String = {"active": "TO DO", "fetched": "GOT IT: bring it home", "done": "DONE <3", "missed": "MISSED", "late": "delivered late" }.get(st, st)
	var what: String = "Rx pickup at {pharmacy}" if e.get("kind", "") == "pharmacy" else "{grocery}: " + Errands.list_text(e)
	draw_rect(Rect2(0, 24, W, 11), Color("#3e2d19"))
	txt(Vector2(4, 32), "Today: %s  [%s, due %s]" % [what, label, Errands.due_text(e)], 6, Color("#ffb0d8") if st != "missed" else Color("#e06a4a"))

## Notes app = the side-quest journal. NEW rows glow until the screen has been seen once.
var _notes_rows: Array = []

func _draw_notes() -> void:
	if _notes_rows.is_empty() or not _notes_seen:
		_notes_rows = SideQuests.journal(m.side_quests, m.show_hidden_quests)
		SideQuests.mark_read(m.side_quests)
		_notes_seen = true
	draw_rect(Rect2(0, 12, W, 12), Color("#123b38"))
	txt(Vector2(4, 21), "NOTES  -  stuff I said I'd handle", 7, Color("#9fe8de"))
	if _notes_rows.is_empty():
		txt(Vector2(0, 80), "Nothing yet. Somebody on this block always needs something.", 7, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_CENTER, W)
		return
	var y: = 28.0
	for row in _notes_rows:
		if y > 140.0:
			break
		var done: = str(row["status"]) == "done"
		var r: = Rect2(4, y, W - 8, 30)
		draw_rect(r, Color("#24302c") if not done else Color("#1f1c19"))
		draw_rect(Rect2(r.position, Vector2(3, r.size.y)), UiStyle.TEAL if not done else Color("#6a6258"))
		var head: = str(row["title"]) + ("   NEW" if bool(row["new"]) else "")
		txt(r.position + Vector2(8, 9), head, 8, Color.WHITE if not done else Color(1, 1, 1, 0.5))
		txt(r.position + Vector2(r.size.x - 34, 9), str(row["progress"]) if not done else "DONE", 7, UiStyle.GOLD if not done else Color(1, 1, 1, 0.4))
		txt(r.position + Vector2(8, 19), str(row["step"]), 7, Color("#d8f0ea") if not done else Color(1, 1, 1, 0.4))
		var cl: Array = row["clues"]
		if not cl.is_empty():
			var cs: = "Clues: " + ", ".join(cl)
			txt(r.position + Vector2(8, 28), cs.substr(0, 70) + ("..." if cs.length() > 70 else ""), 6, Color("#f2c66a"))
		y += 34.0

var _notes_seen: = false
