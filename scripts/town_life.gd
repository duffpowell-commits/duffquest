extends Node2D
## Living town (Nov 17, Duff's pick): the street stops being a still painting. Cosmetic only: nothing here collides,
## fights, saves or touches the game's RNG (own RandomNumberGenerator, so soak/test seeds don't move).
## - Cars: tinted delivery vans (truck_h / truck_v) on the four road lanes; they brake for Duff and never run while a
##   hostile driver is out (so a passing van never reads as the HONK hazard).
## - Walkers: off-duty workers (waitress, sitter, usher...) on the sidewalks; they step around Duff and turn back
##   from fights. Fewer at night.
## - Pigeons: little flocks on the sidewalk that peck, then scatter when Duff runs at them (back ~25 s later).
## - Steam: puffs off the {fork_nick}'s roof vents.
## - Weather: a screen-space layer (same in 2D and 3D): drifting fall leaves most days, rain some evenings, light snow
##   on cold days. Picked per in-game day from the day number, so it's stable all day.
## Everything here draws through Art.frame / Art.image, so the 3D view turns each one into a card for free.

const Art: = preload("res://scripts/art.gd")

var m: Node
var rng: = RandomNumberGenerator.new()
var t: = 0.0

# --- road + sidewalk geometry (world units, from the painted ground: road centre y 175, x 316) ---
const LANES_H: = [[167.0, -1.0], [184.0, 1.0]]      # [y, dir]
const LANES_V: = [[308.0, 1.0], [324.0, -1.0]]      # [x, dir]
const X0: = -30.0
const X1: = 700.0
const Y0: = -40.0
const Y1: = 400.0
const WALK_H: = [141.0, 211.0]                       # north / south sidewalk centre lines
const WALK_V: = 283.0                                # west sidewalk along the north-south road
const WALKERS: = ["ch_waitress", "ch_sitter", "ch_usher", "ch_regular", "ch_phlebotomist"]   # not the cashier: her scanner reads as a gun
const CAR_TINTS: = [Color(1, 1, 1), Color(1.0, 0.72, 0.7), Color(0.72, 0.82, 1.0), Color(0.78, 1.0, 0.8), Color(1.0, 0.95, 0.68)]
const FLOCKS: = [Vector2(118, 146), Vector2(556, 207), Vector2(250, 205), Vector2(430, 139)]
const VENTS: = [Vector2(476, 268), Vector2(581, 268)]   # the {fork_nick}'s two roof vents (2D roof line)
## 3D: puffs stand on the facade's front edge and the view lifts them by (PUFF_BASE_Y - y), so a puff's 2D climb
## up the roof becomes real height (view3d.gd _sync_actors).
const PUFF_BASE_Y: = 318.0

var cars: Array = []
var car_t: = 4.0
var walkers: Array = []
var birds: Array = []
var puffs: Array = []
var puff_t: = 0.0
var weather: Node2D

## One small node per car / walker / pigeon / puff, placed at its feet, so main's outdoor y-sort puts each one in
## front of or behind Duff, trees and buildings correctly (this node y-sorts too, which Godot 4 nests).
class Ent extends Node2D:
	var life: Node
	var kind: = ""
	var d: Dictionary
	func _draw() -> void:
		life.draw_ent(self, kind, d)

func _ent(kind: String, d: Dictionary) -> void:
	var e: = Ent.new()
	e.life = self
	e.kind = kind
	e.d = d
	d["node"] = e
	add_child(e)

func _drop(d: Dictionary) -> void:
	if d.has("node") and is_instance_valid(d["node"]):
		(d["node"] as Node).queue_free()

func _ready() -> void:
	rng.seed = 1117
	z_index = 0
	y_sort_enabled = true
	for i in 4:
		walkers.append(_new_walker(true))
		_ent("walker", walkers[i])
	_reset_birds()
	var layer: = CanvasLayer.new()
	layer.layer = 1
	layer.scale = Vector2(2, 2)
	add_child(layer)
	weather = Weather.new()
	weather.life = self
	layer.add_child(weather)

func active() -> bool:
	return m != null and m.location == "outside" and not m.in_title

func _process(delta: float) -> void:
	var on: = active()
	visible = on
	weather.visible = on
	if not on or m.busy():
		return
	t += delta
	_tick_cars(delta)
	_tick_walkers(delta)
	_tick_birds(delta)
	_tick_puffs(delta)
	for c in get_children():
		if c is Ent:
			c.queue_redraw()

func _night() -> bool:
	var c: = fmod(float(m.clock), 1440.0)
	return c >= 1380.0 or c < 330.0

# --- cars ------------------------------------------------------------------------------------------------------

func _hostile_driver() -> bool:
	for e in m.live_enemies():
		if str(e.get("kind")) == "driver":
			return true
	return false

func _tick_cars(delta: float) -> void:
	car_t -= delta
	if car_t <= 0.0 and cars.size() < 2 and not _hostile_driver():
		car_t = rng.randf_range(6.0, 14.0) * (1.8 if _night() else 1.0)
		var h: = rng.randf() < 0.6
		var lane: Array = (LANES_H if h else LANES_V)[rng.randi() % 2]
		var dir: float = lane[1]
		var start: = Vector2(X0 if dir > 0 else X1, lane[0]) if h else Vector2(lane[0], Y0 if dir > 0 else Y1)
		var top: = rng.randf_range(70.0, 95.0)
		cars.append({"h": h, "dir": dir, "pos": start, "v": top, "top": top, "tint": CAR_TINTS[rng.randi() % CAR_TINTS.size()]})
		_ent("car", cars.back())
	var p: Vector2 = m.player.global_position
	for c in cars.duplicate():
		var h: bool = c["h"]
		var dir: float = c["dir"]
		var pos: Vector2 = c["pos"]
		var ahead: = (p.x - pos.x) * dir if h else (p.y - pos.y) * dir
		var side: = absf(p.y - pos.y) if h else absf(p.x - pos.x)
		var blocked: = side < 14.0 and ahead > 0.0 and ahead < 48.0
		for o in cars:   # queue behind the car in front
			if o != c and o["h"] == h and o["dir"] == dir and is_equal_approx(float((o["pos"] as Vector2).y if h else (o["pos"] as Vector2).x), pos.y if h else pos.x):
				var gap: = ((o["pos"] as Vector2).x - pos.x) * dir if h else ((o["pos"] as Vector2).y - pos.y) * dir
				blocked = blocked or (gap > 0.0 and gap < 40.0)
		c["v"] = move_toward(float(c["v"]), 0.0 if blocked else float(c["top"]), (220.0 if blocked else 60.0) * delta)
		pos += (Vector2(dir, 0) if h else Vector2(0, dir)) * float(c["v"]) * delta
		c["pos"] = pos
		(c["node"] as Node2D).position = pos + Vector2(0, 10)
		if pos.x < X0 - 5 or pos.x > X1 + 5 or pos.y < Y0 - 5 or pos.y > Y1 + 5:
			_drop(c)
			cars.erase(c)

# --- walkers ---------------------------------------------------------------------------------------------------

func _new_walker(anywhere: bool) -> Dictionary:
	var vert: = rng.randf() < 0.25
	var dir: = 1.0 if rng.randf() < 0.5 else -1.0
	var line: float = WALK_V if vert else WALK_H[rng.randi() % 2]
	var along: float
	if anywhere:
		along = rng.randf_range(Y0, Y1) if vert else rng.randf_range(X0, X1)
	else:
		along = (Y0 if dir > 0 else Y1) if vert else (X0 if dir > 0 else X1)
	return {"sheet": WALKERS[rng.randi() % WALKERS.size()], "v": vert, "dir": dir, "line": line, "at": along,
		"speed": rng.randf_range(17.0, 25.0), "off": 0.0, "pause": 0.0, "hide": false}

func _w_pos(w: Dictionary) -> Vector2:
	var o: float = w["off"]
	return Vector2(float(w["line"]) + o, float(w["at"])) if w["v"] else Vector2(float(w["at"]), float(w["line"]) + o)

const ExtraPackScript: = preload("res://scripts/extra_pack.gd")

func _tick_walkers(delta: float) -> void:
	var want: = 1 if _night() else 4
	if not ExtraPackScript.world_ready:   # audit Nov 19: their sheets ride world.pck; before it lands they were bare shadows
		want = 0
	var p: Vector2 = m.player.global_position
	var foes: Array = m.live_enemies()
	for i in walkers.size():
		var w: Dictionary = walkers[i]
		w["hide"] = i >= want
		if w["hide"]:
			(w["node"] as Node2D).visible = false
			continue
		var pos: = _w_pos(w)
		for e in foes:   # a fight up ahead: turn around
			var ep: Vector2 = (e as Node2D).global_position
			var d: float = (ep.y - pos.y) * float(w["dir"]) if w["v"] else (ep.x - pos.x) * float(w["dir"])
			if d > 0.0 and d < 70.0 and pos.distance_to(ep) < 90.0:
				w["dir"] = -float(w["dir"])
				break
		# step around Duff: slide sideways while he's close, drift back after
		var near: = pos.distance_to(p) < 18.0
		var side: = 1.0 if ((p.x - pos.x) if w["v"] else (p.y - pos.y)) < 0.0 else -1.0
		w["off"] = move_toward(float(w["off"]), (10.0 * side) if near else 0.0, 30.0 * delta)
		w["at"] = float(w["at"]) + float(w["dir"]) * float(w["speed"]) * delta
		var a: float = w["at"]
		if (w["v"] and (a < Y0 - 10 or a > Y1 + 10)) or (not w["v"] and (a < X0 - 10 or a > X1 + 10)):
			_drop(w)
			walkers[i] = _new_walker(false)
			_ent("walker", walkers[i])
		(walkers[i]["node"] as Node2D).position = _w_pos(walkers[i])
		(walkers[i]["node"] as Node2D).visible = true

# --- pigeons ---------------------------------------------------------------------------------------------------

func _reset_birds() -> void:
	birds.clear()
	for f in FLOCKS:
		for k in 3:
			birds.append({"home": f + Vector2(rng.randf_range(-9, 9), rng.randf_range(-3, 3)), "pos": Vector2.ZERO,
				"fly": false, "vel": Vector2.ZERO, "alt": 0.0, "away": 0.0, "peck": rng.randf() * 3.0, "flip": rng.randf() < 0.5})
	for b in birds:
		b["pos"] = b["home"]
		_ent("bird", b)

func _tick_birds(delta: float) -> void:
	var p: Vector2 = m.player.global_position
	var pv: Vector2 = m.player.velocity
	for b in birds:
		var bn: Node2D = b["node"]
		bn.position = b["pos"]
		bn.visible = not _night()
		if b["fly"]:
			b["pos"] = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
			b["alt"] = float(b["alt"]) + 34.0 * delta
			b["away"] = float(b["away"]) + delta
			if float(b["away"]) > 25.0 and (b["home"] as Vector2).distance_to(p) > 70.0:   # come back when he's gone
				b["fly"] = false
				b["pos"] = b["home"]
				b["alt"] = 0.0
			continue
		b["peck"] = float(b["peck"]) - delta
		if float(b["peck"]) < 0.0:
			b["peck"] = rng.randf_range(0.6, 2.4)
			b["flip"] = rng.randf() < 0.5
		var d: = (b["pos"] as Vector2).distance_to(p)
		if d < 16.0 or (d < 40.0 and pv.length() > 50.0):
			var away: = ((b["pos"] as Vector2) - p).normalized()
			if away == Vector2.ZERO:
				away = Vector2.UP
			b["fly"] = true
			b["vel"] = (away + Vector2(rng.randf_range(-0.3, 0.3), -0.4)).normalized() * rng.randf_range(70.0, 95.0)
			b["flip"] = (b["vel"] as Vector2).x < 0.0
			b["away"] = 0.0

# --- steam -----------------------------------------------------------------------------------------------------

func _tick_puffs(delta: float) -> void:
	puff_t -= delta
	if puff_t <= 0.0:
		puff_t = rng.randf_range(0.35, 0.6)
		var v: Vector2 = VENTS[rng.randi() % VENTS.size()]
		puffs.append({"pos": v + Vector2(rng.randf_range(-2, 2), 0), "age": 0.0, "life": rng.randf_range(1.6, 2.4)})
		_ent("puff", puffs.back())
	for pf in puffs.duplicate():
		pf["age"] = float(pf["age"]) + delta
		pf["pos"] = (pf["pos"] as Vector2) + Vector2(4.0, -9.0) * delta
		(pf["node"] as Node2D).position = pf["pos"]
		if float(pf["age"]) >= float(pf["life"]):
			_drop(pf)
			puffs.erase(pf)

# --- drawing ---------------------------------------------------------------------------------------------------

## Draws one entity at its node's origin (its feet).
func draw_ent(ci: CanvasItem, kind: String, d: Dictionary) -> void:
	match kind:
		"car":
			var tint: Color = d["tint"]
			if d["h"]:
				Art.xf(ci, Vector2(0, -10), 0.0, Vector2(d["dir"], 1))
				Art.image(ci, "truck_h", Vector2.ZERO, tint)
			else:
				Art.xf(ci, Vector2(0, -10), 0.0, Vector2(1, d["dir"]))
				Art.image(ci, "truck_v", Vector2.ZERO, tint)
			Art.xf(ci, Vector2.ZERO, 0.0, Vector2.ONE)
		"walker":
			if d["hide"]:
				return
			var dv: = (Vector2(0, d["dir"]) if d["v"] else Vector2(d["dir"], 0))
			Art.person(ci, d["sheet"], Vector2.ZERO, dv, t + float(d["speed"]), true)
		"bird":
			var col: = (2 + int(t * 12.0) % 2) if d["fly"] else (0 if float(d["peck"]) < 0.25 else 1)
			Art.xf(ci, Vector2(0, -float(d["alt"])), 0.0, Vector2(-1.25 if d["flip"] else 1.25, 1.25))
			Art.frame(ci, "amb_pigeon", Vector2.ZERO, col, 0)
			Art.xf(ci, Vector2.ZERO, 0.0, Vector2.ONE)
		"puff":
			var k: = float(d["age"]) / float(d["life"])
			Art.image(ci, "amb_puff", Vector2.ZERO, Color(1, 1, 1, 0.8 * (1.0 - k) * minf(1.0, k * 5.0)), 0.6 + k * 1.0)

## Today's weather: "leaves" (most days, it's an Omaha November), "rain" (evening/night on some days), "snow"
## (some days from day 6 on). Stable for the whole in-game day.
func weather_kind() -> String:
	var d: int = int(m.day_count)
	var roll: = posmod(d * 7919 + 13, 100)
	if d >= 6 and roll < 22:
		return "snow"
	var c: = fmod(float(m.clock), 1440.0)
	if roll >= 70 and (c >= 1020.0 or c < 300.0):
		return "rain"
	return "leaves"

## Screen-space weather (320x180 HUD units), drawn under the HUD.
class Weather extends Node2D:
	var life: Node
	var parts: Array = []
	var kind: = ""

	func _process(delta: float) -> void:
		if not visible or life.m == null or life.m.busy():
			return
		var k: String = life.weather_kind()
		if k != kind:
			kind = k
			parts.clear()
		var want: int = {"snow": 70, "rain": 90, "leaves": 9}[kind]
		while parts.size() < want:
			parts.append(_spawn(parts.size() < want / 2))
		var tt: float = life.t
		for p in parts:
			match kind:
				"snow":
					p["p"] = (p["p"] as Vector2) + Vector2(sin(tt * 1.3 + float(p["s"])) * 6.0 + 4.0, float(p["v"])) * delta
				"rain":
					p["p"] = (p["p"] as Vector2) + Vector2(-40.0, float(p["v"])) * delta
				_:
					p["p"] = (p["p"] as Vector2) + Vector2(14.0 + sin(tt * 0.9 + float(p["s"])) * 10.0, float(p["v"]) * 0.35) * delta
					p["r"] = float(p["r"]) + delta * (1.6 + float(p["s"]) * 0.3)
			var q: Vector2 = p["p"]
			if q.y > 186.0 or q.x > 330.0 or q.x < -10.0:
				var n: = _spawn(false)
				p.merge(n, true)
		queue_redraw()

	func _spawn(anywhere: bool) -> Dictionary:
		var r: RandomNumberGenerator = life.rng
		var x: = r.randf_range(-10.0, 320.0)
		var y: = r.randf_range(-10.0, 180.0) if anywhere else r.randf_range(-14.0, -4.0)
		if kind == "leaves" and not anywhere:   # leaves blow in from the left edge too
			if r.randf() < 0.5:
				x = -8.0
				y = r.randf_range(0.0, 150.0)
		var v: float = {"snow": r.randf_range(14.0, 26.0), "rain": r.randf_range(220.0, 280.0), "leaves": r.randf_range(10.0, 22.0)}.get(kind, 20.0)
		return {"p": Vector2(x, y), "v": v, "s": r.randf() * 6.28, "r": r.randf() * 6.28,
			"c": [Color("#d9772b"), Color("#c4472e"), Color("#e2a83a"), Color("#9a5a2a")][r.randi() % 4]}

	func _draw() -> void:
		for p in parts:
			var q: Vector2 = p["p"]
			match kind:
				"snow":
					var rad: = 0.6 + fmod(float(p["s"]), 1.0) * 0.7
					draw_circle(q, rad, Color(1, 1, 1, 0.85))
				"rain":
					draw_line(q, q + Vector2(-2.2, 9.0), Color(0.75, 0.85, 1.0, 0.45), 0.6)
				_:
					var a: float = p["r"]
					var dx: = Vector2(cos(a), sin(a)) * 1.8
					var dy: = Vector2(-sin(a), cos(a)) * maxf(0.35, absf(sin(a * 0.7)))   # never edge-on: a flat quad fails to triangulate
					draw_colored_polygon(PackedVector2Array([q - dx, q - dy, q + dx, q + dy]), p["c"])
		if kind == "rain":   # wet, dim evening
			draw_rect(Rect2(0, 0, 320, 180), Color(0.1, 0.12, 0.2, 0.12))
		elif kind == "snow":
			draw_rect(Rect2(0, 0, 320, 180), Color(0.85, 0.9, 1.0, 0.06))
