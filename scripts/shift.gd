extends Node2D

signal shift_over(result: Dictionary)

const Card: = preload("res://scripts/minigames/card.gd")
const GAMES: = {
	"quiz": preload("res://scripts/minigames/quiz.gd"),
	"prep": preload("res://scripts/minigames/prep.gd"),
	"pickles": preload("res://scripts/minigames/pickles.gd"),
	"fryer": preload("res://scripts/minigames/fryer.gd"),
	"temp": preload("res://scripts/minigames/temp_check.gd"),
	"sandwich": preload("res://scripts/minigames/sandwich.gd"),
	"salad": preload("res://scripts/minigames/salad.gd"),
	"garnish": preload("res://scripts/minigames/garnish.gd"),
	"inspector": preload("res://scripts/minigames/inspector.gd"),
}
const NAMES: = {
	"quiz": "Lineup Quiz", "prep": "Prep/Stock/Clean", "pickles": "Fried Pickles", "fryer": "Fryer",
	"temp": "Temp Check", "sandwich": "Chx Sandwich", "salad": "Salads", "garnish": "Dessert",
	"inspector": "Inspection", "fix_temp": "Fix: Burger", "fix_fryer": "Fix: Wings",
}
const HELP: = {
	"quiz": "Chef's lineup. Food safety + methods. Tap an answer or press 1-4.",
	"prep": "Chop on the beat, stock the make line, FIFO the walk-in, wash then sanitize.",
	"pickles": "Flour, egg wash, breading. Dry hand for dry, wet hand for wet (H switches).",
	"fryer": "Drop and pull baskets (1/2). Keep oil 350-375°F with HEAT -/+ (Z/X).",
	"temp": "Tap the thickest part to probe. PULL (Space) at the safe temp. No hints.",
	"sandwich": "Build bottom to top per ticket. Watch the mods. SEND with Enter.",
	"salad": "Build to the ticket. Allergy? Gloves + sanitize first, and zero allergens.",
	"garnish": "Drag the drizzle, tap for cream rosettes, tap for cherries.",
	"inspector": "Call each observation: Compliant (1) or Violation (2).",
	"fix_temp": "Brayden torched a burger. Re-fire it: ground beef to 155°F.",
	"fix_fryer": "Brayden burned the wings. Re-fire them. Wings = 165°F.",
}
const FULL: = ["quiz", "prep", "pickles", "fryer", "temp", "sandwich", "salad", "garnish"]
const RUSH_POOL: = ["fryer", "sandwich", "salad", "garnish", "temp"]
const RUSH_LETTER: = {"fryer": "F", "sandwich": "S", "salad": "L", "garnish": "D", "temp": "T" }
const RUSH_TICKETS: = 8
const RUSH_TIME: = 150.0
const BASE_PER_STATION: = 6
const MULT: = {"S": 2.0, "A": 1.25, "B": 1.0, "C": 0.8, "F": 0.5 }
const TIPS: = {"S": 20, "A": 12, "B": 8, "C": 3, "F": 0 }
const ENERGY_COST: = {"full": 20, "quick": 10, "rush": 15 }

var m: Node = null
var day_name: = "Friday"
var auto: = false
var force: Dictionary = {}
var mode: = ""
var queue: Array = []
var results: Array = []
var events: Array = []
var injuries: = 0
var bonus_total: = 0
var inspector_result: = ""
var current: Node = null
var report: Dictionary = {}
var overlay: Node2D

var rail: Array = []
var rush_t: = 0.0
var rush_spawn: = 0.0
var combo: = 0
var best_combo: = 0
var rush_pay: = 0.0
var rush_served: = 0

func _ready() -> void:
	overlay = Node2D.new()
	overlay.z_index = 10
	add_child(overlay)
	overlay.draw.connect(_draw_overlay)

static func grade_for(s: float) -> String:
	if s >= 0.92: return "S"
	if s >= 0.8: return "A"
	if s >= 0.65: return "B"
	if s >= 0.5: return "C"
	return "F"

static func grade_color(g: String) -> Color:
	return {"S": Color("#ffd23f"), "A": Color("#8aff8a"), "B": Color("#8ad0ff"), "C": Color("#ffb060"), "F": Color("#ff5f5f") }.get(g, Color.WHITE)

static func quip(g: String) -> String:
	match g:
		"S": return "Chef's kiss. And then corporate takes the credit."
		"A": return "Clean. Chef nods. That's the whole bonus."
		"B": return "Solid. Nobody gets sick. Legally."
		"C": return "Eh. Expo sighs loud enough to bill me. Nobody tips the fry cook."
	return "Disaster. Some influencer's filming a 14-part TikTok about it. Nobody tips the fry cook."

static func compute_pay(md: String, n_stations: int, grade: String, bonus: int, rpay: float, walked: int) -> Dictionary:
	var base: = int(round(rpay)) if md == "rush" else BASE_PER_STATION * n_stations
	var mult: float = MULT[grade]
	var pay: = int(round(base * mult))
	var tips: int = TIPS[grade]
	if md == "quick":
		tips = tips / 2
	var docked: = 10 if grade == "F" else 0
	var walk_pen: = walked * 2
	var total: = maxi(0, pay + tips + bonus - docked - walk_pen)
	return {"base": base, "mult": mult, "pay": pay, "tips": tips, "bonus": bonus, "docked": docked, "walked": walked, "walk_pen": walk_pen, "total": total }

func _roll(name: String, chance: float) -> bool:
	if force.has(name):
		return bool(force[name])
	return randf() < chance

func injure(amount: int, why: String) -> void:
	injuries += amount
	events.append(why)

func _show(node: Node) -> void:
	if current and is_instance_valid(current):
		current.queue_free()
	current = node
	node.set("shift", self)
	add_child(node)
	move_child(overlay, -1)

func _card(heading: String, lines: Array, lines2: Array, big: String, opts: Array, cb: Callable) -> void:
	var c: = Card.new()
	c.heading = heading
	c.lines = lines
	c.lines2 = lines2
	c.big = big
	c.big_col = grade_color(big)
	c.opts = opts
	c.chosen.connect(cb)
	_show(c)

func start() -> void:
	_card("THE TWISTED FORK  -  %s" % day_name,
		["Clock in. The Fork is a family (unpaid overtime). Grade sets pay: S = double, F = docked.",
		"Full Shift: all 8 stations. Quick Shift: 4 random ones.",
		"Friday Night Rush: tickets pile on the rail. Chain good grades for a combo. Tips go to 'the pool' (Chef's boat)."],
		[], "", [["full", "Full Shift (8)", KEY_1], ["quick", "Quick Shift (4)", KEY_2], ["rush", "Friday Night Rush", KEY_3], ["leave", "Never mind", KEY_ESCAPE]],
		_on_menu)

func _on_menu(id: String) -> void:
	if id == "leave":
		shift_over.emit({"left": true })
		return
	begin(id)

func begin(md: String) -> void:
	mode = md
	results.clear()
	events.clear()
	injuries = 0
	bonus_total = 0
	inspector_result = ""
	if md == "rush":
		_start_rush()
		return
	var list: Array = FULL.duplicate()
	if md == "quick":
		list.shuffle()
		list = list.slice(0, 4)
	queue = []
	for k in list:
		queue.append({"key": k, "ctx": {} })
	if _roll("eighty_six", 0.45):
		for q in queue:
			if q["key"] in ["sandwich", "salad"]:
				q["ctx"]["eighty_six"] = true
				events.append("The 86 board grows mid-shift. Management calls it 'menu agility.'")
				break
	if _roll("grill_boy", 0.55):
		var kind: String = force.get("grill_kind", ["steal", "burger", "wings"][randi() % 3])
		var sand_i: = -1
		for i in queue.size():
			if queue[i]["key"] == "sandwich": sand_i = i
		if kind == "steal" and sand_i >= 0:
			queue[sand_i]["ctx"]["steal"] = true
		elif kind == "wings":
			queue.insert(randi_range(1, queue.size()), {"key": "fix_fryer", "ctx": {"fixit": true } })
		else:
			queue.insert(randi_range(1, queue.size()), {"key": "fix_temp", "ctx": {"fixit": true } })
	if _roll("inspector", 0.35):
		queue.insert(randi_range(1, queue.size()), {"key": "inspector", "ctx": {} })
	_next({})

func _next(prev: Dictionary) -> void:
	if queue.is_empty():
		_finish_shift()
		return
	var nxt: Dictionary = queue.pop_front()
	if auto:
		_play(nxt)
		return
	var lines: Array = []
	var big: = ""
	var heading: = "NEXT STATION"
	if not prev.is_empty():
		big = prev["grade"]
		heading = "%s: %s" % [prev["name"], prev["grade"]]
		lines.append(quip(prev["grade"]))
		for n in (prev["notes"] as Array).slice(0, 3):
			lines.append("- " + str(n))
	var k: String = nxt["key"]
	lines.append(" ")
	match k:
		"inspector": lines.append("!! And who walks in? Tiny, the health inspector. Clipboard out. Everybody look sanitary.")
		"fix_temp": lines.append("!! Grill-Boy Brayden burns a burger. Again. Fix it for +$5.")
		"fix_fryer": lines.append("!! Brayden leaves the wings in to film a 'day in the life.' Fix it for +$5.")
	if nxt["ctx"].get("steal", false):
		lines.append("!! I catch Brayden eyeing my sandwich tickets. Not on my line, bud.")
	if nxt["ctx"].get("eighty_six", false):
		lines.append("!! Something's about to get 86'd. Leave it off or comp the ticket.")
	lines.append("NEXT: %s. %s" % [NAMES[k], HELP[k]])
	_card(heading, lines, [], big, [["go", "Let's go", KEY_SPACE]], func (_id: String) -> void: _play(nxt))

func _play(item: Dictionary) -> void:
	var key: String = item["key"]
	var sk: = key
	if key == "fix_temp": sk = "temp"
	elif key == "fix_fryer": sk = "fryer"
	var g: Node = GAMES[sk].new()
	g.set("ctx", item["ctx"])
	g.finished.connect(func (score: float, notes: Array) -> void: _on_game_done(item, g, score, notes))
	_show(g)

func _on_game_done(item: Dictionary, g: Node, score: float, notes: Array) -> void:
	var key: String = item["key"]
	var res: = {"key": key, "name": NAMES[key], "score": score, "grade": grade_for(score), "notes": notes.duplicate(),
		"bonus": int(g.get("bonus")), "kind": "event" if key in ["inspector", "fix_temp", "fix_fryer"] else "station" }
	bonus_total += int(g.get("bonus"))
	if key == "inspector":
		var prep_ok: = true
		for r in results:
			if r["key"] == "prep" and r["grade"] == "F":
				prep_ok = false
		if score >= 0.75 and prep_ok:
			inspector_result = "pass"
			bonus_total += 15
			res["bonus"] = 15
			(res["notes"] as Array).push_front("PASSED inspection: +$15 bonus.")
		else:
			inspector_result = "fail"
			(res["notes"] as Array).push_front("FAILED. The inspector's following me around today. Swell.")
	results.append(res)
	if mode == "rush":
		_rush_done(res)
	else:
		_next(res)

func _start_rush() -> void:
	rail = []
	rush_t = 0.0
	rush_spawn = 0.0
	combo = 0
	best_combo = 0
	rush_pay = 0.0
	rush_served = 0
	for i in 3:
		_spawn_ticket()
	if auto:
		_rush_next()
		return
	_card("FRIDAY NIGHT RUSH", ["Tickets every few seconds. Clear %d before the dining room posts about it." % RUSH_TICKETS,
		"Each S/A grade in a row bumps your combo: x1.5, x2, x2.5, x3.", "Tickets left on the rail at the end = walked tables (-$2 each). Shorter timers. Go."],
		[], "", [["go", "Fire it up", KEY_SPACE]], func (_id: String) -> void: _rush_next())

func _spawn_ticket() -> void:
	if rail.size() < 8:
		rail.append(RUSH_POOL[randi() % RUSH_POOL.size()])

func _rush_next() -> void:
	if rush_served >= RUSH_TICKETS or rush_t >= RUSH_TIME:
		_finish_shift()
		return
	if rail.is_empty():
		_spawn_ticket()
	var key: String = rail.pop_front()
	var ctx: = {"rush": true }
	if key in ["sandwich", "salad"] and randf() < 0.2:
		ctx["eighty_six"] = true
	if key == "sandwich" and randf() < 0.25:
		ctx["steal"] = true
	_play({"key": key, "ctx": ctx })

func combo_mult() -> float:
	return 1.0 + 0.5 * mini(combo, 4)

func _rush_done(res: Dictionary) -> void:
	rush_served += 1
	if res["grade"] in ["S", "A"]:
		combo += 1
	else:
		combo = 0
	best_combo = maxi(best_combo, combo)
	res["combo"] = combo_mult()
	rush_pay += 5.0 * float(res["score"]) * combo_mult()
	_rush_next()

func _process(delta: float) -> void:
	if mode == "rush" and current and not (current is Card) and not bool(current.get("done")):
		rush_t += delta
		rush_spawn += delta
		if rush_spawn >= 7.0:
			rush_spawn = 0.0
			_spawn_ticket()
	overlay.queue_redraw()

func _draw_overlay() -> void:
	if mode != "rush" or current == null or current is Card:
		return
	var f: = ThemeDB.fallback_font
	overlay.draw_rect(Rect2(118, 0, 160, 12), Color(0, 0, 0, 0.85))
	overlay.draw_string(f, Vector2(120, 9), "RAIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 0.6))
	for i in rail.size():
		var r: = Rect2(138 + i * 12, 1, 10, 10)
		overlay.draw_rect(r, Color("#f4f0dc"))
		overlay.draw_string(f, r.position + Vector2(2, 8), RUSH_LETTER[rail[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#a03a3a"))
	var col: = Color("#ffd23f") if combo > 0 else Color(1, 1, 1, 0.6)
	overlay.draw_string(f, Vector2(236, 9), "x%.1f" % combo_mult(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
	overlay.draw_string(f, Vector2(256, 9), "%d/%d" % [rush_served, RUSH_TICKETS], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)
	if rail.size() >= 8:
		overlay.draw_string(f, Vector2(0, 176), "IN THE WEEDS", HORIZONTAL_ALIGNMENT_CENTER, 320, 8, Color("#ff5f5f"))

func _finish_shift() -> void:
	var stations: = results.filter(func (r: Dictionary) -> bool: return r["kind"] == "station")
	var avg: = 0.0
	for r in stations:
		avg += float(r["score"])
	avg = avg / maxi(1, stations.size())
	var grade: = grade_for(avg)
	var walked: = rail.size() if mode == "rush" else 0
	report = compute_pay(mode, stations.size(), grade, bonus_total, rush_pay, walked)
	var sen: = float(m.pay_mult()) if m and m.has_method("pay_mult") else 1.0
	report["seniority"] = sen
	report["raw_total"] = report["total"]
	report["total"] = int(round(int(report["total"]) * sen))
	report["mode"] = mode
	report["grade"] = grade
	report["avg"] = avg
	report["injuries"] = injuries
	report["energy_cost"] = int(ENERGY_COST.get(mode, 15))
	report["meal"] = 40 if grade in ["S", "A", "B"] else 0
	report["inspector"] = inspector_result
	report["achievement"] = "Chef's Kiss" if grade == "S" else ""
	report["best_combo"] = best_combo
	var lo: Array = []
	if grade == "S":
		lo = ["cake slice", "bakery honey buns"]
	elif grade == "A":
		lo = ["cake slice"]
	elif grade == "B" and (bool(force.get("leftovers", false)) or randf() < 0.4):
		lo = ["bakery honey buns"]
	report["leftovers"] = lo
	report["results"] = results.duplicate()
	if auto:
		shift_over.emit(report)
		return
	var left: Array = []
	for r in results:
		var tag: = "  (+$%d)" % r["bonus"] if int(r["bonus"]) > 0 else ""
		left.append("%s\t%s%s" % [r["name"], r["grade"], tag])
	var right: Array = []
	right.append("Base pay:   $%d" % report["base"])
	right.append("Grade %s:    x%.2f" % [grade, report["mult"]])
	right.append("Tips:       $%d" % report["tips"])
	if bonus_total > 0: right.append("Bonuses:    $%d" % bonus_total)
	if report["docked"] > 0: right.append("Docked:    -$%d" % report["docked"])
	if walked > 0: right.append("Walked tables: -$%d" % report["walk_pen"])
	if sen > 1.0: right.append("%s raise: x%.1f" % [m.pay_title(), sen])
	right.append("TOTAL:      $%d" % report["total"])
	right.append("Energy: -%d (-%d injuries)" % [report["energy_cost"], injuries])
	if report["meal"] > 0: right.append("Shift meal: +%d Energy" % report["meal"])
	if not lo.is_empty(): right.append("Take home: " + ", ".join(lo.map(func (x: String) -> String: return "cake" if x == "cake slice" else "honey buns")))
	if mode == "rush": right.append("Best combo: %d in a row" % best_combo)
	if report["achievement"] != "": right.append("ACHIEVEMENT: Chef's Kiss!")
	if inspector_result == "fail": right.append("Inspector's tailing me now.")
	_card("REPORT CARD  -  %s" % ("FRIDAY NIGHT RUSH" if mode == "rush" else ("FULL SHIFT" if mode == "full" else "QUICK SHIFT")),
		left, right, grade, [["out", "Clock out", KEY_SPACE]], func (_id: String) -> void: shift_over.emit(report))
