extends RefCounted

const PATH: = "res://data/cast.json"
## Public edition (itch, GitHub Pages, the advertised builds): data/cast_public.json overrides cast.json, and
## Art swaps in `<name>_pub` art where it exists (Art.pub). The family edition is exported with the "family"
## feature tag (CI: family web at /family/ + duffquest.apk; the public APK is duffquest-public.apk) and keeps
## the real names untouched. Renders/tests can pass `-- --family` to see the family edition.
const PUBLIC_PATH: = "res://data/cast_public.json"
static var family: bool = OS.has_feature("family") or "--family" in OS.get_cmdline_user_args()
const DEFAULTS: = {
	"game_title": "Duff Quest", "hero": "Duff", "partner": "Madison", "baby": "Octavia", "sister": "Jen",
	"sister_full": "Jennifer", "cat1": "Alastor", "cat2": "Lucifer", "cat3": "Freya", "city": "Omaha",
	"nearby_town": "Council Bluffs", "phone": "Duffphone",
	"ex_1": "The Ghoster", "ex_2": "Gym Bro Supreme", "ex_3": "DJ Vape Lord", "ex_4": "Mr. Crypto",
	"ex_final": "Bruce Willnot", "final_tower": "Nakatomeh Plaza",
	"gala_ex_1": "Tyler Pivot", "gala_ex_2": "Grant Gratuity", "gala_ex_3": "Landlord Lance", "gala_ex_4": "Chip Leverage",
	"gala_baron": "Baron Von Trustfund", "stray": "Falcor",
	"pharmacy": "Walgrumps Pharmacy", "pharmacist": "Pharmacist Deb", "grocery": "Hy-Whee Market",
	"grocery_slogan": "A helpful smile in every aisle-ish",
	"pirate_1": "Package Pauly", "pirate_2": "Doorbell Dodger", "pirate_3": "Sticky Rick",
	"pirate_4": "Two-Day Tony", "pirate_5": "Front-Step Freddie", "pirate_6": "Signature Sal",
	"cologne": "Gucchi Eau de Duff",
	"date_spot_sushi": "Akarui", "date_spot_symphony": "Holland Performing Arts Center",
	"symphony_hall": "the Holland Center", "orchestra": "Omaha Symphony", "sushi_area": "downtown Omaha",
	"fork": "The Twisted Fork", "fork_short": "the Twisted Fork", "house_sandwich": "Twisted Classic", "wordle": "Wordle",
	"coworker": "Brittany", "coworker_short": "Britt",
	"sitter_app": "SitterSnap", "plasma": "PlazMart Donor Center", "plasma_sign": "PLAZMART PLASMA", "phlebotomist": "Phlebotomist Phil",
}
static var _names: Dictionary = {}
static var _pairs: Array = []

static func names() -> Dictionary:
	if _names.is_empty():
		_names = DEFAULTS.duplicate()
		for path in ([PATH] if family else [PATH, PUBLIC_PATH]):
			var f: = FileAccess.open(path, FileAccess.READ)
			if f:
				var d = JSON.parse_string(f.get_as_text())
				f.close()
				if typeof(d) == TYPE_DICTIONARY:
					for k in d:
						if not str(k).begins_with("_"):
							_names[str(k)] = str(d[k])
		_pairs = []
		for k in _names:
			_pairs.append(["{%s}" % k, _names[k]])
			_pairs.append(["{%s}" % str(k).to_upper(), str(_names[k]).to_upper()])
	return _names

## Tests / dev: switch edition at runtime (clears the name cache).
static func set_family(on: bool) -> void:
	family = on
	_names = {}
	_pairs = []

static func lookup(key: String) -> String:
	return str(names().get(key, key))

static func N(s: String) -> String:
	if s.find("{") >= 0:
		names()
		for p in _pairs:
			s = s.replace(p[0], p[1])
	return s

static func T(s: String) -> String:
	if s.find("{") >= 0:
		names()
		for p in _pairs:
			s = s.replace(p[0], p[1])
	if clean:
		s = clean_text(s)
	if touch:
		s = touch_text(s)
	return s

static var clean: = false

## Phone mode (set by main when the touch controls show): keyboard hints in player-facing text are
## rewritten to the on-screen buttons or dropped, so a phone player never reads "Space" or "Enter".
## Only exact, known phrases are touched: story text that says "space" is left alone.
static var touch: = false
const TOUCH_WORDS: = [
	[" (H switches)", " (SWITCH HAND)"], ["HEAT -/+ (Z/X)", "the HEAT buttons"], ["Drop and pull baskets (1/2).", "Drop and pull baskets."],
	["PULL (Space)", "PULL IT"], ["SEND with Enter", "tap SEND"], [" or press 1-4", ""],
	["Compliant (1) or Violation (2)", "Compliant or Violation"], [" (Enter = center)", ""],
	[" Keys: arrows + Space, X toss.", ""], [" (or arrows + hold Space)", ""], [" (drag / Space)", ""],
	[" Enter = guess.", ""], ["  (C / Space)", ""], ["  (Space)", ""], [" (Space)", ""],
]
static var _touch_memo: Dictionary = {}

static func touch_text(s: String) -> String:
	if _touch_memo.has(s):
		return str(_touch_memo[s])
	var out: = s
	if out.find("(") >= 0 or out.find("Enter") >= 0 or out.find("press") >= 0 or out.find("Keys") >= 0:
		for w in TOUCH_WORDS:
			out = out.replace(str(w[0]), str(w[1]))
	if _touch_memo.size() > 4000:
		_touch_memo.clear()
	_touch_memo[s] = out
	return out

const CLEAN_WORDS: = [
	["motherfuck(?<s>er|ers|ing)?", "#$%!"], ["fuck(?<s>ing|in'|ed|er|ers|s)?", "#$%!"],
	["bullshit", "baloney"], ["shitty", "crappy"], ["shit(?<s>s)?", "crap"],
	["goddamn(?<s>it)?", "dang"], ["dammit", "dang it"], ["damn(?<s>ed|it)?", "dang"],
	["assholes", "jerks"], ["asshole", "jerk"], ["dumbass", "dummy"], ["badass", "tough"],
	["smartass", "smart-mouth"], ["jackass", "jerk"], ["asses", "butts"], ["ass", "butt"],
	["bastards", "jerks"], ["bastard", "jerk"], ["pissed", "ticked"], ["piss", "pee"],
	["hell", "heck"],
]
static var _clean_rx: Array = []
static var _clean_memo: Dictionary = {}

static func clean_text(s: String) -> String:
	if _clean_memo.has(s):
		return str(_clean_memo[s])
	if _clean_rx.is_empty():
		for w in CLEAN_WORDS:
			var rx: = RegEx.new()
			rx.compile("(?i)\\b(?<w>" + str(w[0]) + ")\\b")
			_clean_rx.append([rx, str(w[1])])
	var out: = s
	for pair in _clean_rx:
		var rx: RegEx = pair[0]
		var rep: String = pair[1]
		var res: = ""
		var at: = 0
		for mt in rx.search_all(out):
			var word: String = mt.get_string("w")
			var suffix: String = mt.get_string("s") if mt.names.has("s") else ""
			var r: = rep
			if suffix != "" and rep == "#$%!":
				r = rep + suffix.to_lower()
			if word == word.to_upper() and word.length() > 1 and word != word.to_lower():
				r = r.to_upper()
			elif word.substr(0, 1) != word.substr(0, 1).to_lower():
				r = r.substr(0, 1).to_upper() + r.substr(1)
			res += out.substr(at, mt.get_start() - at) + r
			at = mt.get_end()
		out = res + out.substr(at)
	if _clean_memo.size() > 4000:
		_clean_memo.clear()
	_clean_memo[s] = out
	return out
