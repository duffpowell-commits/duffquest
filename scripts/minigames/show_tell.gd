extends "res://scripts/minigames/minigame.gd"

const DATA_PATH: = "res://data/show_and_tell.json"
const FAMILY_PATH: = "res://data/show_and_tell_family.json"
const ITEMS_PER_NIGHT: = 5
const ITEM_TIME: = 4.6
const TRAVEL: = 1.6
const HIT_X: = 44.0
const TRACK_Y: = 122.0
const PERFECT: = 0.09
const GOOD: = 0.2
const REACTS: = ["haha", "aww", "omg"]
const REACT_LABEL: = {"haha": "HAHA", "aww": "AWW", "omg": "WHOA" }
const REACT_COL: = {"haha": Color("#ffd04a"), "aww": Color("#ff8ac0"), "omg": Color("#6ac8ff") }
const KIND_TAG: = {"reel": "REEL", "plush": "PLUSHIE", "animal": "ANIMALS", "food": "FOOD", "shopping": "CART", "baby": "OUR KID", "wild": "NEWS??" }

var items: Array = []
var openers: Array = []
var notes_q: Array = []
var score_pts: = 0.0
var max_pts: = 0.0
var streak: = 0
var judge: = ""
var judge_t: = 0.0
var judge_col: = Color.WHITE
var duff_react: = ""
var duff_react_t: = 0.0
var hearts: Array = []
var lead_in: = 1.2

func _setup() -> void:
	title = "SHOW & TELL"
	backdrop = "bedroom"
	backdrop_dim = 0.25
	music = "date"
	space_is_pen = false
	show_header = false
	_load_items()
	time_limit = lead_in + items.size() * ITEM_TIME + 1.0
	for i in items.size():
		var base: = lead_in + i * ITEM_TIME
		var r: String = items[i]["react"]

		notes_q.append({"t": base + 1.3, "react": r, "big": false, "hit": "" })
		notes_q.append({"t": base + 2.1, "react": r, "big": false, "hit": "" })
		notes_q.append({"t": base + 3.3, "react": r, "big": true, "hit": "" })
	for n in notes_q:
		max_pts += 3.0 if n["big"] else 1.0
	var bw: = 96.0
	for i in 3:
		var r2: String = REACTS[i]
		add_button(r2, Rect2(8 + i * (bw + 8), 158, bw, 18), "%d  %s" % [i + 1, REACT_LABEL[r2]], [KEY_1, KEY_2, KEY_3][i], REACT_COL[r2].darkened(0.45))

func _load_items() -> void:
	var data: = {}
	var f: = FileAccess.open(DATA_PATH, FileAccess.READ)
	if f != null:
		var parsed = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
	openers = data.get("openers", ["Look at this."])
	var raw: Array = (data.get("items", []) as Array).duplicate()

	var ff: = FileAccess.open(FAMILY_PATH, FileAccess.READ)
	if ff != null:
		var fam = JSON.parse_string(ff.get_as_text())
		if typeof(fam) == TYPE_DICTIONARY:
			raw.append_array(fam.get("items", []))
			openers = openers + (fam.get("openers", []) as Array)
	var pool: Array = raw.filter(func (it): return typeof(it) == TYPE_DICTIONARY and str(it.get("react", "")) in REACTS)
	if pool.is_empty():
		pool = [{"kind": "reel", "title": "A cat doing a backflip", "line": "He stuck the landing!", "react": "haha" }]
	var rng: = RandomNumberGenerator.new()
	rng.seed = int(ctx.get("seed", Time.get_ticks_usec()))
	var picks: Array = []
	while picks.size() < mini(ITEMS_PER_NIGHT, pool.size()):
		var it: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		if not picks.has(it):
			picks.append(it)
	items = picks

func _current() -> int:
	return clampi(int((t - lead_in) / ITEM_TIME), 0, items.size() - 1)

func _on_button(id: String) -> void:
	_react(id)

func _key(k: InputEventKey) -> void:
	match k.physical_keycode:
		KEY_A, KEY_LEFT: _react("haha")
		KEY_S, KEY_DOWN: _react("aww")
		KEY_D, KEY_RIGHT: _react("omg")

func _react(id: String) -> void:
	if done:
		return
	var best: Dictionary = {}
	var best_dt: = 99.0
	for n in notes_q:
		if n["hit"] == "" and absf(n["t"] - t) < best_dt:
			best_dt = absf(n["t"] - t)
			best = n
	if best.is_empty() or best_dt > GOOD:
		_set_judge("...huh?", Color(1, 1, 1, 0.6))
		streak = 0
		return
	if best["react"] != id:
		best["hit"] = "wrong"
		streak = 0
		_set_judge("wrong vibe", Color("#e0a080"))
		AudioScript.sfx("back")
		return
	var w: = 3.0 if best["big"] else 1.0
	if best_dt <= PERFECT:
		best["hit"] = "perfect"
		score_pts += w
		_set_judge("PERFECT", REACT_COL[id])
	else:
		best["hit"] = "good"
		score_pts += w * 0.6
		_set_judge("nice", REACT_COL[id].lerp(Color.WHITE, 0.4))
	streak += 1
	AudioScript.sfx("select", 1.0 + 0.04 * mini(streak, 10))
	if best["big"]:
		duff_react = id
		duff_react_t = 0.9
		if id == "aww":
			for i in 4:
				hearts.append({"p": Vector2(170 + randf_range(-20, 20), 70), "v": Vector2(randf_range(-8, 8), -22), "t": 0.0 })

func _set_judge(s: String, c: Color) -> void:
	judge = s
	judge_col = c
	judge_t = 0.6

func _tick(delta: float) -> void:
	show_cursor = false
	judge_t = maxf(0.0, judge_t - delta)
	duff_react_t = maxf(0.0, duff_react_t - delta)
	for n in notes_q:
		if n["hit"] == "" and t - n["t"] > GOOD:
			n["hit"] = "miss"
			streak = 0
	for h in hearts:
		h["t"] += delta
		h["p"] += h["v"] * delta
	hearts = hearts.filter(func (h): return h["t"] < 1.2)

func _timeout() -> void:
	finish(clampf(score_pts / maxf(1.0, max_pts), 0.0, 1.0))

func debug_solve(good: bool) -> void:
	finish(0.95 if good else 0.2)

func _draw_game() -> void:
	_draw_bed()
	_draw_phone_popup()
	_draw_track()
	_draw_dialog()

func _draw_bed() -> void:
	var bob: = sin(t * 2.0) * 0.6

	draw_rect(Rect2(92, 34, 136, 34), Color("#6a4630"))
	draw_rect(Rect2(92, 34, 136, 3), Color("#8a6040"))
	draw_rect(Rect2(98, 58, 56, 14), Color("#f0ead8"))
	draw_rect(Rect2(166, 58, 56, 14), Color("#f0ead8"))

	var talking: = int(t * 6.0) % 2 == 0 and t > lead_in
	var cur: = _current()
	var showing: = fmod(t - lead_in, ITEM_TIME) < 3.6 and t > lead_in
	var duff_row: = 2
	var mad_row: = 3 if not showing else 0
	var laugh: = duff_react == "haha" and duff_react_t > 0.0
	var dy: = -2.0 * absf(sin(duff_react_t * 18.0)) if laugh else 0.0
	_big_sprite("duff_home", Vector2(132, 99 + bob + dy), 1 if laugh else 0, duff_row)
	_big_sprite("ch_madison", Vector2(188, 99 - bob), 1 if talking else 0, mad_row)

	if showing:
		draw_rect(Rect2(178, 82, 9, 13), Color("#202030"))
		draw_rect(Rect2(179, 83, 7, 11), Color(0.75, 0.9, 1.0, 0.9))

	draw_rect(Rect2(86, 92, 148, 28), Color("#5a6ab0"))
	draw_rect(Rect2(86, 92, 148, 3), Color("#7a8ad0"))
	for x in range(94, 230, 14):
		draw_line(Vector2(x, 97), Vector2(x + 6, 118), Color("#4a5a9a"), 1.0)

	if duff_react_t > 0.0:
		var c: Color = REACT_COL.get(duff_react, Color.WHITE)
		match duff_react:
			"haha": txt(Vector2(108, 44), "HA HA", 9, c)
			"omg": txt(Vector2(128, 40), "!", 14, c)
	for h in hearts:
		var a: float = 1.0 - float(h["t"]) / 1.2
		_heart(h["p"], Color(1.0, 0.45, 0.7, a))

func _big_sprite(sheet: String, feet: Vector2, col: int, row: int) -> void:
	draw_set_transform(feet, 0.0, Vector2(3, 3))
	Art.frame(self, sheet, Vector2.ZERO, col, row)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _heart(p: Vector2, c: Color) -> void:
	draw_circle(p + Vector2(-1.5, 0), 2.0, c)
	draw_circle(p + Vector2(1.5, 0), 2.0, c)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-3.4, 0.6), p + Vector2(3.4, 0.6), p + Vector2(0, 4.5)]), c)

func _draw_phone_popup() -> void:
	if t < lead_in or items.is_empty():
		return
	var it: Dictionary = items[_current()]
	var phase: = fmod(t - lead_in, ITEM_TIME)
	var a: = clampf(minf(phase * 4.0, (ITEM_TIME - phase) * 4.0), 0.0, 1.0)
	var r: = Rect2(232, 8, 82, 76)
	draw_rect(r, Color(0.08, 0.07, 0.1, 0.92 * a))
	draw_rect(r, Color(1, 1, 1, 0.5 * a), false, 1.0)
	var tag: String = KIND_TAG.get(str(it.get("kind", "")), "LOOK")
	draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, 9)), Color(REACT_COL[it["react"]], 0.35 * a))
	txt(r.position + Vector2(6, 11), tag, 6, Color(1, 1, 1, a))
	mtxt(r.position + Vector2(5, 24), str(it.get("title", "")), r.size.x - 10, 7, Color(1, 1, 1, a), 6)

func _draw_track() -> void:
	draw_rect(Rect2(0, TRACK_Y - 9, W, 18), Color(0, 0, 0, 0.55))
	draw_line(Vector2(0, TRACK_Y - 9), Vector2(W, TRACK_Y - 9), Color(1, 1, 1, 0.15), 1.0)

	draw_arc(Vector2(HIT_X, TRACK_Y), 8.0, 0.0, TAU, 20, Color(1, 1, 1, 0.8), 1.5)
	var speed: = (W - HIT_X) / TRAVEL
	for n in notes_q:
		var dt: float = n["t"] - t
		if dt > TRAVEL + 0.1 or n["hit"] in ["perfect", "good"] or dt < -0.4:
			continue
		var x: = HIT_X + dt * speed
		var c: Color = REACT_COL[n["react"]]
		if n["hit"] in ["miss", "wrong"]:
			c = Color(0.5, 0.5, 0.5, 0.6)
		var rad: = 7.0 if n["big"] else 4.5
		draw_circle(Vector2(x, TRACK_Y), rad, c)
		draw_arc(Vector2(x, TRACK_Y), rad, 0.0, TAU, 16, Color(0, 0, 0, 0.6), 1.0)
		if n["big"]:
			txt(Vector2(x - 9, TRACK_Y + 2.5), REACT_LABEL[n["react"]], 5, Color(0.1, 0.08, 0.1))
	if judge_t > 0.0:
		txt(Vector2(HIT_X + 14, TRACK_Y - 11), judge, 7, Color(judge_col, minf(1.0, judge_t * 3.0)))
	if streak >= 3:
		txt(Vector2(W - 60, TRACK_Y - 11), "x%d streak" % streak, 6, Color("#c0d890"))

func _draw_dialog() -> void:
	var r: = Rect2(4, 133, W - 8, 23)
	draw_rect(r, Color(0.11, 0.09, 0.07, 0.95))
	draw_rect(r, Color("#e88aa8"), false, 1.0)
	var line: = ""
	if t < lead_in:
		line = "{partner}: \"Wait, don't fall asleep yet. I have stuff to show you.\""
	elif not items.is_empty():
		var it: Dictionary = items[_current()]
		var phase: = fmod(t - lead_in, ITEM_TIME)
		var opener: String = openers[_current() % openers.size()] if not openers.is_empty() else "Look."
		var full: String = Cast.T("{partner}: \"%s %s\"" % [opener, str(it.get("line", ""))])
		var shown: = int(clampf(phase / 2.6, 0.0, 1.0) * full.length())
		line = full.substr(0, shown)
	mtxt(r.position + Vector2(5, 9), line, r.size.x - 10, 7, Color.WHITE, 2)
