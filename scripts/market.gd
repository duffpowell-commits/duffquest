extends RefCounted

const GOAL: = 100000.0
const HISTORY: = 40
const ASSETS: = [
	{"t": "VOOM", "name": "VOOM Total Market Index", "kind": "index", "mu": 0.03, "sig": 0.06, "div": 0.004, "start": 50.0,
		"blurb": "A sliver of ~500 big companies. Boring. Wins anyway. Wall Street hates that you know this." },
	{"t": "SCHMD", "name": "SCHMD Dividend Aristocrats ETF", "kind": "dividend", "mu": 0.022, "sig": 0.05, "div": 0.0095, "start": 25.0,
		"blurb": "Companies that raise their dividend every year. Pays you to wait, like a landlord, but you're the landlord." },
	{"t": "BUNZ", "name": "Honey Bun Holdings", "kind": "dividend stock", "mu": 0.016, "sig": 0.08, "div": 0.011, "start": 40.0,
		"blurb": "One company, sweet dividend. A single stock wobbles more than a fund." },
	{"t": "BONDZ", "name": "Boring Bond Fund", "kind": "bonds", "mu": 0.007, "sig": 0.015, "div": 0.011, "start": 10.0,
		"blurb": "Lend money to the government. They'll spend it on a parade. Steady. Cushions crashes." },
	{"t": "GTS", "name": "Grand Theft Stock Studios", "kind": "growth", "mu": 0.02, "sig": 0.16, "div": 0.0, "start": 80.0,
		"blurb": "One giant game a decade, made by crunch. Trailer drops = rockets. Delays = ouch." },
	{"t": "GMSTP", "name": "GameStomp", "kind": "meme", "mu": -0.08, "sig": 0.35, "div": 0.0, "start": 20.0,
		"blurb": "A video game store the internet decided is a personality. Can moon. Can rug." },
	{"t": "DOGEB", "name": "DogeBucks Crypto Casino", "kind": "crypto", "mu": -0.1, "sig": 0.5, "div": 0.0, "start": 0.5,
		"blurb": "A coin with a dog on it, run by a casino, endorsed by a guy who sells supplements. What could go wrong?" },
]
const TIPS: = [
	"Time in the market beats timing the market.",
	"Dividends + DRIP = shares that make more shares.",
	"An index fund is 500 eggs in 500 baskets.",
	"If it's called DogeBucks, it's a casino, not an investment.",
	"Crash week? Index funds are on sale. Don't panic-sell.",
	"Boring is a feature. Check less, hold longer.",
	"Fees and FOMO eat returns. Patience is free.",
]

static func asset(t: String) -> Dictionary:
	for a in ASSETS:
		if a["t"] == t:
			return a
	return {}

static func is_steady(t: String) -> bool:
	return str(asset(t).get("kind", "")) in ["index", "dividend", "dividend stock", "bonds"]

static func new_state(seed_val: int) -> Dictionary:
	var prices: = {}
	var hist: = {}
	for a in ASSETS:
		prices[a["t"]] = float(a["start"])
		hist[a["t"]] = [float(a["start"])]
	return {"seed": seed_val, "week": 0, "prices": prices, "history": hist, "event": "", "news": ["Stonks is open. Welcome, retail investor. (Hedge funds call you 'liquidity.')"] }

static func _rng(state: Dictionary) -> RandomNumberGenerator:
	var r: = RandomNumberGenerator.new()
	r.seed = absi(hash("%d:%d" % [int(state["seed"]), int(state["week"])])) + 1
	return r

static func tick(state: Dictionary) -> Dictionary:

	var rng: = _rng(state)
	state["week"] = int(state["week"]) + 1
	var roll: = rng.randf()
	var ev: = ""
	if roll < 0.07:
		ev = "crash"
	elif roll < 0.14:
		ev = "bull"
	elif roll < 0.26:
		ev = "fed"
	var fed_sign: = 1.0 if rng.randf() < 0.55 else -1.0
	var news: Array = []
	match ev:
		"crash": news.append("CRASH WEEK! Everything is red. Index funds are on sale.")
		"bull": news.append("Bull run! Every finance bro is a genius this week. Ask them.")
		"fed": news.append("Fed meeting day: they said 'data dependent' 41 times. Markets %s." % ("cheer" if fed_sign > 0 else "sulk"))
	var changes: = {}
	for a in ASSETS:
		var t: String = a["t"]
		var p: = float(state["prices"][t])
		var mu: = float(a["mu"])
		var sig: = float(a["sig"])
		var r: = exp(mu - sig * sig / 2.0 + sig * rng.randfn(0.0, 1.0))
		var kind: String = a["kind"]
		var steady: = is_steady(t)
		if steady:
			var hist: Array = state["history"][t]
			var peak: = p
			for i in range(maxi(0, hist.size() - 8), hist.size()):
				peak = maxf(peak, float(hist[i]))
			if p < peak * 0.88:
				r *= 1.015
		var x: = rng.randf()
		if kind == "meme" or kind == "crypto":
			var moon: = 0.06 if kind == "meme" else 0.07
			var rug: = 0.07 if kind == "meme" else 0.08
			if x < moon:
				r *= rng.randf_range(2.0, 4.0 if kind == "meme" else 5.0)
				news.append("%s is MOONING! Diamond hands! Lambos ordered on credit!" % t)
			elif x < moon + rug:
				r *= 0.3 if kind == "meme" else 0.2
				news.append("%s got RUGGED. Down %d%%. The founder is 'taking time for his mental health' in Dubai." % [t, 70 if kind == "meme" else 80])
		elif kind == "growth" and x < 0.08:
			if rng.randf() < 0.5:
				r *= 1.25
				news.append("GTS dropped a trailer. 90 million views in an hour.")
			else:
				r *= 0.8
				news.append("GTS delayed their game. Again. CEO bonus: not delayed.")
		match ev:
			"crash":
				r *= {"index": 0.83, "dividend": 0.86, "dividend stock": 0.84, "bonds": 1.01, "growth": 0.75 }.get(kind, 0.55)
			"bull":
				r *= {"index": 1.08, "dividend": 1.06, "dividend stock": 1.06, "bonds": 1.0, "growth": 1.15 }.get(kind, 1.4)
			"fed":
				r *= 1.0 + fed_sign * ({"bonds": 0.01, "index": 0.025, "dividend": 0.02 }.get(kind, 0.04))
		var np: = maxf(p * r, 0.001)
		state["prices"][t] = np
		var h: Array = state["history"][t]
		h.append(np)
		while h.size() > HISTORY:
			h.pop_front()
		changes[t] = np / p - 1.0
	if news.is_empty():
		news.append("Quiet week. Boring is good. CNBC is furious.")
	state["event"] = ev
	state["news"] = news
	return {"event": ev, "news": news, "changes": changes }

static func price(state: Dictionary, t: String) -> float:
	return float(state["prices"].get(t, 0.0))

static func change(state: Dictionary, t: String) -> float:
	var h: Array = state["history"].get(t, [])
	if h.size() < 2:
		return 0.0
	return float(h[-1]) / float(h[-2]) - 1.0

static func new_account(drip: bool = true) -> Dictionary:
	return {"cash": 0.0, "holdings": {}, "drip": drip, "divs": 0.0, "deposited": 0.0 }

static func shares(acct: Dictionary, t: String) -> float:
	return float((acct["holdings"] as Dictionary).get(t, {}).get("shares", 0.0))

static func cost(acct: Dictionary, t: String) -> float:
	return float((acct["holdings"] as Dictionary).get(t, {}).get("cost", 0.0))

static func buy(acct: Dictionary, t: String, px: float, dollars: float) -> float:

	if dollars <= 0.0 or px <= 0.0:
		return 0.0
	var h: Dictionary = acct["holdings"]
	if not h.has(t):
		h[t] = {"shares": 0.0, "cost": 0.0 }
	var n: = dollars / px
	h[t]["shares"] = float(h[t]["shares"]) + n
	h[t]["cost"] = float(h[t]["cost"]) + dollars
	return n

static func sell(acct: Dictionary, t: String, px: float, frac: float) -> float:

	var h: Dictionary = acct["holdings"]
	if not h.has(t):
		return 0.0
	frac = clampf(frac, 0.0, 1.0)
	var n: = float(h[t]["shares"]) * frac
	var proceeds: = n * px
	if frac >= 0.999:
		h.erase(t)
	else:
		h[t]["shares"] = float(h[t]["shares"]) - n
		h[t]["cost"] = float(h[t]["cost"]) * (1.0 - frac)
	return proceeds

static func holdings_value(acct: Dictionary, state: Dictionary) -> float:
	var v: = 0.0
	for t in acct["holdings"]:
		v += float(acct["holdings"][t]["shares"]) * price(state, t)
	return v

static func value(acct: Dictionary, state: Dictionary) -> float:
	return float(acct["cash"]) + holdings_value(acct, state)

static func total_cost(acct: Dictionary) -> float:
	var c: = 0.0
	for t in acct["holdings"]:
		c += float(acct["holdings"][t]["cost"])
	return c

static func pay_dividends(acct: Dictionary, state: Dictionary) -> Dictionary:

	var total: = 0.0
	var out: = 0.0
	for t in acct["holdings"].keys():
		var y: = float(asset(t).get("div", 0.0))
		if y <= 0.0:
			continue
		var px: = price(state, t)
		var amt: = float(acct["holdings"][t]["shares"]) * px * y
		if amt <= 0.0:
			continue
		total += amt
		if bool(acct["drip"]):
			buy(acct, t, px, amt)
		else:
			out += amt
	acct["divs"] = float(acct["divs"]) + total
	return {"total": total, "paid_out": out }

static func clean_account(a, drip_default: bool = true) -> Dictionary:
	var out: = new_account(drip_default)
	if typeof(a) != TYPE_DICTIONARY:
		return out
	out["cash"] = float(a.get("cash", 0.0))
	out["drip"] = bool(a.get("drip", drip_default))
	out["divs"] = float(a.get("divs", 0.0))
	out["deposited"] = float(a.get("deposited", 0.0))
	var h = a.get("holdings", {})
	if typeof(h) == TYPE_DICTIONARY:
		for t in h:
			if not asset(str(t)).is_empty() and typeof(h[t]) == TYPE_DICTIONARY:
				out["holdings"][str(t)] = {"shares": float(h[t].get("shares", 0.0)), "cost": float(h[t].get("cost", 0.0)) }
	return out

static func clean_state(s, seed_val: int) -> Dictionary:
	if typeof(s) != TYPE_DICTIONARY or not s.has("prices"):
		return new_state(seed_val)
	var out: = new_state(int(s.get("seed", seed_val)))
	out["week"] = int(s.get("week", 0))
	out["event"] = str(s.get("event", ""))
	var nw = s.get("news", [])
	if typeof(nw) == TYPE_ARRAY:
		out["news"] = nw.map(func (x): return str(x))
	for a in ASSETS:
		var t: String = a["t"]
		if s["prices"].has(t):
			out["prices"][t] = float(s["prices"][t])
		var h = s.get("history", {}).get(t, [])
		if typeof(h) == TYPE_ARRAY and not h.is_empty():
			out["history"][t] = h.map(func (x): return float(x))
	return out
