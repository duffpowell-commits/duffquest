extends Node2D

const Art: = preload("res://scripts/art.gd")
const Cast: = preload("res://scripts/cast.gd")
const AudioScript: = preload("res://scripts/audio.gd")

const DURATION: = 180.0
const START_MIN: = 1320.0
const COOK_T: = 4.0
const READY_T: = 5.0
const PATIENCE: = 32.0
const MAX_TICKETS: = 5
const BASE_PAY: = 5
const MAX_TIP: = 3
const WALKOUT_PEN: = 2
const FINISH_BONUS: = 20
const GRILLS: = [Vector2(64, 64), Vector2(160, 64), Vector2(256, 64)]  # the three griddles in arena_waffle
const MENU: = [
	["ALL-STAR", "All-Star Special. Eggs, toast, waffle, the works."],
	["PECAN WAF", "Pecan waffle! Extra butter, extra pecan, extra regret."],
	["HB S/S/C", "Hash browns: scattered, smothered, covered!"],
	["HB ALL", "Hash browns ALL THE WAY. Every topping. God help us."],
	["PATTY MELT", "Patty melt, grilled onions, no judgment."],
	["T-BONE", "T-bone and eggs. At 3 AM. Respect."],
	["CHX WAF", "Chicken and waffle. The holy union."],
	["CHOC CHIP", "Chocolate chip waffle for the guy crying in booth 2."],
	["BACON x3", "Triple bacon. Side of bacon."],
	["CHEESE N EGG", "Cheese 'n eggs. Scrambled hard, like my soul."],
]
const CALLS: = ["Order in!", "Ticket!", "Hon, you got one!", "Fire it!", "Order up, sugar!"]
## Duff answers about one call in three. "Heard" lives in the kitchens (Waffle Haus, the Fork) and nowhere else.
const HEARD: = ["Heard.", "Heard, Dolores.", "Heard. Already on the flat-top.", "HEARD."]

var m: Node = null
var t: = 0.0
var tickets: Array = []
var grills: Array = [-1, -1, -1]
var next_order: = 3.0
var next_spawn: = 8.0
var delivered: = 0
var walked: = 0
var burnt: = 0
var tips: = 0
var spawned_orders: = 0
var rush_announced: = false
var regular_night: = false
var regular_spawned: = false
var regular_beaten: = false
var done: = false
var call_line: = ""
var call_t: = 0.0
var smoke: Array = [0.0, 0.0, 0.0]

func _ready() -> void:
	z_index = 1

func frac() -> float:
	return clampf(t / DURATION, 0.0, 1.0)

func clock_text() -> String:
	var c: = int(fmod(clock_minutes(), 1440.0))
	var h: = c / 60
	var h12: = h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, c % 60, "AM" if h < 12 else "PM"]

func origin() -> Vector2:
	return m.ARENA_ORIGIN

func tick(delta: float) -> void:
	if done:
		return
	t += delta
	call_t = maxf(0.0, call_t - delta)
	for i in 3:
		smoke[i] = maxf(0.0, smoke[i] - delta)
	m.clock = clock_minutes()
	_orders(delta)
	_crowd(delta)
	if frac() >= 1.0 and (not regular_night or regular_beaten):
		done = true
		m.end_waffle(result(false))
	queue_redraw()

func _orders(delta: float) -> void:
	next_order -= delta
	var closing: = frac() > 0.94
	if next_order <= 0.0 and not closing:
		next_order = randf_range(8.0, 11.0) if frac() < 0.3 or frac() > 0.65 else randf_range(10.0, 13.0)
		if _waiting() < MAX_TICKETS:
			var it: Array = MENU[randi() % MENU.size()]
			tickets.append({"code": it[0], "call": it[1], "left": PATIENCE, "state": "wait", "grill": -1, "cook": 0.0 })
			spawned_orders += 1
			call_line = "%s %s" % [CALLS[randi() % CALLS.size()], it[1]]
			call_t = 3.5
			AudioScript.sfx("select")
			if randi() % 3 == 0:
				m._toast(HEARD[randi() % HEARD.size()])
	for i in range(tickets.size() - 1, -1, -1):
		var tk: Dictionary = tickets[i]
		match str(tk["state"]):
			"wait":
				tk["left"] = float(tk["left"]) - delta
				if float(tk["left"]) <= 0.0:
					walked += 1
					m._toast("Booth %d walks out. Leaves a one-star review written in syrup. -$%d" % [randi_range(1, 6), WALKOUT_PEN])
					_remove(i)
			"cook":
				tk["cook"] = float(tk["cook"]) + delta
				if float(tk["cook"]) >= COOK_T:
					tk["state"] = "ready"
					tk["cook"] = 0.0
					AudioScript.sfx("pickup")
			"ready":
				tk["cook"] = float(tk["cook"]) + delta
				if float(tk["cook"]) >= READY_T:
					burnt += 1
					smoke[int(tk["grill"])] = 2.0
					m._toast("BURNT. The %s is charcoal. And the smoke alarm has opinions." % str(tk["code"]))
					AudioScript.sfx("fail")
					_remove(i)

func _waiting() -> int:
	var n: = 0
	for tk in tickets:
		if str(tk["state"]) == "wait":
			n += 1
	return n

func _remove(i: int) -> void:
	var g: = int(tickets[i]["grill"])
	if g >= 0:
		grills[g] = -1
	tickets.remove_at(i)
	for k in 3:
		if grills[k] > i:
			grills[k] -= 1

func use_grill(g: int) -> void:
	if done:
		return
	var idx: int = grills[g]
	if idx >= 0:
		var tk: Dictionary = tickets[idx]
		if str(tk["state"]) == "ready":
			var tip: = int(round(MAX_TIP * clampf(float(tk["left"]) / PATIENCE + 0.25, 0.0, 1.0)))
			delivered += 1
			tips += tip
			AudioScript.sfx("cash")
			m._toast("%s, plated! +$%d%s" % [str(tk["code"]), BASE_PAY, (" (+$%d tip)" % tip) if tip > 0 else ""])
			_remove(idx)
		else:
			m._toast("Still cooking. %.0f more seconds. Go punch something." % maxf(0.0, COOK_T - float(tk["cook"])))
		return
	for i in tickets.size():
		if str(tickets[i]["state"]) == "wait":
			tickets[i]["state"] = "cook"
			tickets[i]["grill"] = g
			tickets[i]["cook"] = 0.0
			grills[g] = i
			AudioScript.sfx("fryer", 1.2)
			return
	m._toast("No tickets. I enjoy my 4 seconds of peace.")

func grill_label(g: int) -> String:
	var idx: int = grills[g]
	if idx < 0:
		return "Grill %d: fire the next ticket" % (g + 1) if _waiting() > 0 else "Grill %d (no tickets)" % (g + 1)
	var tk: Dictionary = tickets[idx]
	return ("Plate the %s" % str(tk["code"])) if str(tk["state"]) == "ready" else ("Grill %d: %s cooking..." % [g + 1, str(tk["code"])])

func _crowd(delta: float) -> void:
	var f: = frac()
	var live: Array = m.live_enemies()
	if regular_night and not regular_spawned and f >= 0.83:
		regular_spawned = true
		m.waffle_spawn_regular()
		return
	if f > 0.25 and not rush_announced:
		rush_announced = true
		m._toast("So it's 2 AM. Bars just closed. Here they come.")
		next_spawn = 1.0
	var cap: = 1
	var every: = 22.0
	if f > 0.25 and f < 0.62:
		cap = 4
		every = 4.5
	elif f >= 0.62 and f < 0.83:
		cap = 2
		every = 9.0
	elif f >= 0.83:
		cap = 1 if not regular_night else 0
		every = 14.0
	if f > 0.95:
		cap = 0
	next_spawn -= delta
	var crowd: = live.filter(func (e): return not e.is_in_group("boss") and str(e.kind) in ["drunk", "heckler"])
	if next_spawn <= 0.0 and crowd.size() < cap:
		next_spawn = every
		var o: = origin()
		var side: = Vector2(30, 150) if randf() < 0.5 else Vector2(290, 150)
		var k: = "heckler" if f > 0.25 and randf() < 0.4 else "drunk"
		m.spawn_enemy(k, o + side)

func on_regular_beaten() -> void:
	regular_beaten = true

func result(ko: bool) -> Dictionary:
	var pay: = delivered * BASE_PAY + tips - walked * WALKOUT_PEN + (FINISH_BONUS if not ko else 0)
	if ko:
		pay = int(pay * 0.5)
	var served: float = float(delivered) / float(maxi(1, spawned_orders))
	return {"ko": ko, "delivered": delivered, "walked": walked, "burnt": burnt, "tips": tips, "orders": spawned_orders,
		"pay": maxi(0, pay), "score": served, "regular": regular_night, "regular_beaten": regular_beaten }

func clock_minutes() -> float:
	var mins: = START_MIN + frac() * 480.0
	if regular_night and regular_spawned and not regular_beaten and frac() >= 1.0:
		mins = START_MIN + 479.0
	return mins

func _draw() -> void:
	var o: = origin()
	var f: = ThemeDB.fallback_font
	# lettering on the art's blank yellow sign (x 92..228, lower half sits below the HUD bar)
	draw_string(f, o + Vector2(92, 26), "W A F F L E   H A U S", HORIZONTAL_ALIGNMENT_CENTER, 136, 8, Color("#1a1418"))
	Art.person(self, "ch_dolores", o + Vector2(22, 92), Vector2.DOWN, t, false, call_t > 0.0)

	for g in 3:
		var gp: Vector2 = o + GRILLS[g]
		var idx: int = grills[g]
		var plate: = Rect2(gp + Vector2(-19, 5), Vector2(38, 11))
		if idx >= 0:
			var tk: Dictionary = tickets[idx]
			var cooking: = str(tk["state"]) == "cook"
			var p: = clampf(float(tk["cook"]) / (COOK_T if cooking else READY_T), 0.0, 1.0)
			draw_rect(plate, Color(0, 0, 0, 0.6))
			if cooking:
				draw_rect(Rect2(plate.position + Vector2(1, 8), Vector2(36 * p, 2)), Color("#f0c040"))
				draw_string(f, plate.position + Vector2(0, 7), str(tk["code"]), HORIZONTAL_ALIGNMENT_CENTER, 38, 5, Color("#f0ead8"))
				for k in 3:
					var sx: = gp.x - 8 + k * 8
					var sy: = gp.y - 2 - fmod(t * 10.0 + k * 3, 6.0)
					draw_line(Vector2(sx, sy), Vector2(sx + 1, sy - 3), Color(1, 1, 1, 0.5), 1.0)
			else:
				var hot: = p > 0.6
				draw_rect(Rect2(plate.position + Vector2(1, 8), Vector2(36 * (1.0 - p), 2)), Color("#ff5040") if hot else Color("#60e060"))
				if int(t * 6.0) % 2 == 0 or not hot:
					draw_string(f, plate.position + Vector2(0, 7), "PLATE IT!" if not hot else "BURNING!", HORIZONTAL_ALIGNMENT_CENTER, 38, 5, Color("#60ff60") if not hot else Color("#ff6040"))
		else:
			draw_rect(plate, Color(0, 0, 0, 0.35))
			draw_string(f, plate.position + Vector2(0, 7), "GRILL %d" % (g + 1), HORIZONTAL_ALIGNMENT_CENTER, 38, 5, Color(1, 1, 1, 0.55))
		if smoke[g] > 0.0:
			for k in 4:
				draw_circle(gp + Vector2(-6 + k * 4, -2 - (2.0 - smoke[g]) * 10.0 - k * 2), 4.0, Color(0.3, 0.3, 0.3, 0.5 * smoke[g] / 2.0))
		draw_arc(gp + Vector2(0, 3), 9.0, 0, TAU, 16, Color(1, 0.85, 0.3, 0.3 + 0.2 * sin(t * 4.0 + g)), 1.0)

	var ry: = 32.0  # order rail hangs just under the hood, above the griddles
	draw_rect(Rect2(o + Vector2(10, ry - 1), Vector2(300, 1)), Color("#c8d0dc"))
	var x: = 12.0
	for tk in tickets:
		if str(tk["state"]) != "wait":
			continue
		var r: = Rect2(o + Vector2(x, ry), Vector2(38, 12))
		var urgent: = float(tk["left"]) < 8.0
		draw_rect(r, Color("#fffaf0") if not urgent or int(t * 5.0) % 2 == 0 else Color("#ffc0b0"))
		draw_rect(r, Color("#2a1a2e"), false, 1.0)
		draw_string(f, r.position + Vector2(1, 6), str(tk["code"]), HORIZONTAL_ALIGNMENT_CENTER, 36, 5, Color("#2a1a2e"))
		draw_rect(Rect2(r.position + Vector2(2, 8.5), Vector2(34.0 * clampf(float(tk["left"]) / PATIENCE, 0.0, 1.0), 2)), Color("#d04040") if urgent else Color("#40a040"))
		x += 40.0
	var tally: = "Served %d  Walked %d" % [delivered, walked]
	draw_string(f, o + Vector2(250, ry + 8), tally, HORIZONTAL_ALIGNMENT_RIGHT, 60, 5, Color("#2a1a2e"))
	if call_t > 0.0 and call_line != "":
		var sw: = minf(220.0, f.get_string_size(call_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x)
		var bp: = o + Vector2(160 - sw / 2.0 - 3.0, ry + 16)
		draw_rect(Rect2(bp, Vector2(sw + 6, 10)), Color(1, 1, 1, 0.93))
		draw_rect(Rect2(bp, Vector2(sw + 6, 10)), Color("#f0c040"), false, 1.0)
		draw_string(f, bp + Vector2(3, 8), call_line, HORIZONTAL_ALIGNMENT_LEFT, sw, 6, Color("#222222"))
