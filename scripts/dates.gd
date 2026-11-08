extends RefCounted

const KINDS: = ["akarui", "symphony"]
const NAMES: = {"akarui": "{date_spot_sushi}", "symphony": "{orchestra} at {symphony_hall}" }
const MIN_DAY: = {"akarui": 2, "symphony": 4 }
const HAPPY: = {"akarui": 25.0, "symphony": 30.0 }
const HOURS: = {"akarui": 150.0, "symphony": 210.0 }
const COOLDOWN: = 3
const INVITE_HAPPY: = 50.0
const INVITE_DAYS: = 2
const WINDOW: = [1020.0, 1260.0]
const SITTER_COST: = 35
const JEN_FEE: = 20
const TICKETS: = 60
const RIDESHARE: = 18
const RIDESHARE_HOME: = 24
const GLOW_DAYS: = 1
const GLOW_HAPPY: = 1.2
const GLOW_DEF: = 0.9

const NACHTMUSIK: = [
	[0.0, 67, 1.0], [1.5, 62, 0.5], [2.0, 67, 1.0], [3.5, 62, 0.5],
	[4.0, 67, 0.5], [4.5, 62, 0.5], [5.0, 67, 0.5], [5.5, 71, 0.5], [6.0, 74, 2.0],
	[8.0, 72, 1.0], [9.5, 69, 0.5], [10.0, 72, 1.0], [11.5, 69, 0.5],
	[12.0, 72, 0.5], [12.5, 69, 0.5], [13.0, 66, 0.5], [13.5, 69, 0.5], [14.0, 62, 2.0],
]
const LULLABY: = [
	[0.0, 64, 0.5], [0.5, 64, 0.5], [1.0, 67, 2.0], [3.0, 64, 0.5], [3.5, 64, 0.5], [4.0, 67, 2.0],
	[6.0, 64, 0.5], [6.5, 67, 0.5], [7.0, 72, 1.0], [8.0, 71, 1.5], [9.5, 69, 0.5], [10.0, 69, 1.0], [11.0, 67, 1.0],
	[12.0, 62, 0.5], [12.5, 64, 0.5], [13.0, 65, 1.0], [14.0, 62, 1.0], [15.0, 62, 0.5], [15.5, 64, 0.5], [16.0, 65, 2.0],
	[18.0, 62, 0.5], [18.5, 65, 0.5], [19.0, 71, 0.5], [19.5, 69, 0.5], [20.0, 67, 1.0], [21.0, 71, 1.0], [22.0, 72, 2.0],
]
const ODE: = [
	[0.0, 64, 1.0], [1.0, 64, 1.0], [2.0, 65, 1.0], [3.0, 67, 1.0], [4.0, 67, 1.0], [5.0, 65, 1.0], [6.0, 64, 1.0], [7.0, 62, 1.0],
	[8.0, 60, 1.0], [9.0, 60, 1.0], [10.0, 62, 1.0], [11.0, 64, 1.0], [12.0, 64, 1.5], [13.5, 62, 0.5], [14.0, 62, 2.0],
	[16.0, 64, 1.0], [17.0, 64, 1.0], [18.0, 65, 1.0], [19.0, 67, 1.0], [20.0, 67, 1.0], [21.0, 65, 1.0], [22.0, 64, 1.0], [23.0, 62, 1.0],
	[24.0, 60, 1.0], [25.0, 60, 1.0], [26.0, 62, 1.0], [27.0, 64, 1.0], [28.0, 62, 1.5], [29.5, 60, 0.5], [30.0, 60, 2.0],
]
const PROGRAM: = [
	{"title": "I. Allegro", "from": "after Mozart, Eine kleine Nachtmusik (1787)", "bpm": 112.0, "drowsy": 0.035, "notes": NACHTMUSIK },
	{"title": "II. Wiegenlied", "from": "after Brahms, Lullaby (1868). Do NOT fall asleep.", "bpm": 72.0, "drowsy": 0.1, "notes": LULLABY },
	{"title": "III. Finale", "from": "after Beethoven, Symphony No. 9 (1824)", "bpm": 120.0, "drowsy": 0.04, "notes": ODE },
]
const SUITE_TITLE: = "\"Sleepytime Classics\", a suite in three movements (arr. for the game)"

const ROLLS: = ["Salmon avocado roll", "Spicy tuna roll", "Dragon roll", "Veggie roll"]
const TEAS: = ["Taro milk tea", "Brown sugar milk tea", "Mango green tea", "Matcha latte"]
const SUGAR: = ["0%", "25%", "50%", "75%", "100%"]
const ICE: = ["No ice", "Less ice", "Regular ice"]
const TOPPINGS: = ["Boba", "Lychee jelly", "Pudding", "No topping"]
const SLOTS: = ["roll", "tea", "sugar", "ice", "topping"]
const SLOT_OPTS: = {"roll": ROLLS, "tea": TEAS, "sugar": SUGAR, "ice": ICE, "topping": TOPPINGS }
const ROLL_PRICE: = 14
const TEA_PRICE: = 7
const TOPPING_PRICE: = 1
const DUFF_MEAL: = 16
const PLATES: = {
	"salmon": ["Salmon nigiri", 4, "#ff8a5a"], "tamago": ["Tamago (egg)", 3, "#ffd23f"],
	"tuna": ["Tuna nigiri", 4, "#d0304a"], "crab": ["Krab (with a K)", 3, "#ffb0b0"],
	"uni": ["Mystery uni", 6, "#b08a3a"], "ginger": ["A single ginger slice (why)", 1, "#ffc8d8"],
}

static func new_invite() -> Dictionary:
	return {"kind": "", "day": -1, "expires": -1 }

static func new_stats() -> Dictionary:
	return {"count": 0, "last_day": -99, "akarui": 0, "symphony": 0, "best": 0.0, "sitter_day": -1, "sitter": "" }

static func clean_invite(d) -> Dictionary:
	var out: = new_invite()
	if typeof(d) != TYPE_DICTIONARY:
		return out
	out["kind"] = str(d.get("kind", "")) if str(d.get("kind", "")) in KINDS else ""
	out["day"] = int(d.get("day", -1))
	out["expires"] = int(d.get("expires", -1))
	return out

static func clean_stats(d) -> Dictionary:
	var out: = new_stats()
	if typeof(d) != TYPE_DICTIONARY:
		return out
	for k in ["count", "last_day", "akarui", "symphony", "sitter_day"]:
		if d.has(k):
			out[k] = int(d[k])
	out["best"] = float(d.get("best", 0.0))
	out["sitter"] = str(d.get("sitter", ""))
	return out

static func note_times(piece: Dictionary) -> Array:

	var spb: float = 60.0 / float(piece["bpm"])
	var out: Array = []
	for n in piece["notes"]:
		out.append(float(n[0]) * spb)
	return out

static func piece_len(piece: Dictionary) -> float:
	var last: Array = piece["notes"][-1]
	return (float(last[0]) + float(last[2])) * 60.0 / float(piece["bpm"])

static func next_kind(stats: Dictionary, day: int) -> String:

	if day >= int(MIN_DAY["symphony"]) and int(stats["symphony"]) < int(stats["akarui"]):
		return "symphony"
	return "akarui" if day >= int(MIN_DAY["akarui"]) else ""

static func order_cost(order: Dictionary) -> int:
	return ROLL_PRICE + TEA_PRICE + (TOPPING_PRICE if str(order.get("topping", "")) != "No topping" else 0)

static func make_order(seed_v: int) -> Dictionary:
	var rng: = RandomNumberGenerator.new()
	rng.seed = seed_v
	var o: = {}
	for s in SLOTS:
		var opts: Array = SLOT_OPTS[s]
		o[s] = opts[rng.randi() % opts.size()]
	var favs: = ["salmon", "tamago", "tuna", "crab"]
	var a: String = favs[rng.randi() % favs.size()]
	favs.erase(a)
	o["plates"] = [a, favs[rng.randi() % favs.size()]]
	return o

static func order_text(o: Dictionary) -> String:
	return "%s, and a %s, %s sugar, %s, %s." % [o["roll"], str(o["tea"]).to_lower(), o["sugar"], str(o["ice"]).to_lower(), str(o["topping"]).to_lower()]
