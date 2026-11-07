extends "res://scripts/minigames/minigame.gd"


const PHASES: = ["chop", "stock", "fifo", "wipe"]
const PHASE_TIME: = {"chop": 10.0, "stock": 15.0, "fifo": 20.0, "wipe": 18.0}
const BEAT: = 0.5

var pi: = 0
var phase_scores: Array = []

var chops: = 0
var chop_q: = 0.0
var last_chop: = -10.0

var pans: Array = []

var shelf: Array = []
var tossed: Array = []
var sel: = -1
var kb: = 0
var today_s: = "10/31"

var cells: Array = []
var tool: = "soap"
var warned: = false

func _setup() -> void :
	_enter_phase()

func phase() -> String:
	return PHASES[mini(pi, PHASES.size() - 1)]

func _enter_phase() -> void :
	buttons.clear()
	t = 0.0
	time_limit = PHASE_TIME[phase()]
	space_is_pen = true
	match phase():
		"chop":
			title = "Prep 1/4: Chop on the beat"
			add_button("chop", Rect2(110, 150, 100, 24), "CHOP", KEY_SPACE, Color("#a43a2c"))
		"stock":
			title = "Prep 2/4: Stock the make line"
			_make_pans()
			for i in 5:
				add_button("p%d" % i, Rect2(6 + i * 62, 112, 58, 22), "OK", [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5][i])
			add_button("done", Rect2(236, 152, 80, 22), "DONE", KEY_ENTER, Color("#4e7a3a"))
		"fifo":
			title = "Prep 3/4: FIFO the walk-in"
			space_is_pen = false
			_make_shelf()
			add_button("toss", Rect2(6, 152, 100, 22), "TOSS SELECTED", KEY_X, Color("#a43a2c"))
			add_button("done", Rect2(236, 152, 80, 22), "DONE", KEY_ENTER, Color("#4e7a3a"))
		"wipe":
			title = "Prep 4/4: Wash, then sanitize"
			cells = []
			for i in 40: cells.append(0)
			add_button("soap", Rect2(6, 152, 80, 22), "SOAPY WATER", KEY_1, Color("#43668e"))
			add_button("san", Rect2(90, 152, 80, 22), "SANITIZER", KEY_2, Color("#3a8a6a"))
			add_button("done", Rect2(236, 152, 80, 22), "DONE", KEY_ENTER, Color("#4e7a3a"))

func end_phase() -> void :
	var s: = 0.0
	match phase():
		"chop": s = chop_q / 12.0
		"stock": s = _stock_score()
		"fifo": s = _fifo_score()
		"wipe": s = _wipe_score()
	phase_scores.append(clampf(s, 0, 1))
	pi += 1
	if pi >= PHASES.size():
		var tot: = 0.0
		for v in phase_scores: tot += float(v)
		finish(tot / PHASES.size())
	else:
		_enter_phase()

func _timeout() -> void :
	end_phase()


func chop() -> void :
	if t - last_chop < 0.18:
		hurt(5, "Rushed the knife. Nicked your finger. Band-aid + glove. -5 Energy")
		notes.append("Cut yourself rushing the chop.")
		last_chop = t
		chops += 1
	else:
		var off: = fmod(t, BEAT)
		off = minf(off, BEAT - off)
		chop_q += 1.0 if off < 0.09 else (0.6 if off < 0.16 else 0.25)
		last_chop = t
		chops += 1
	if chops >= 12:
		end_phase()


func _make_pans() -> void :
	var names: = ["Tomatoes", "Lettuce", "Pickles", "Onions", "Chx salad"]
	pans = []
	var idx: = [0, 1, 2, 3, 4]
	idx.shuffle()
	for i in 5:
		var p: = {"n": names[i], "level": randf_range(0.6, 1.0), "temp": randi_range(35, 40), "act": "ok"}
		pans.append(p)
	pans[idx[0]]["level"] = randf_range(0.05, 0.3)
	pans[idx[1]]["level"] = randf_range(0.05, 0.3)
	pans[idx[2]]["temp"] = randi_range(46, 54)

func _correct_act(p: Dictionary) -> String:
	if int(p["temp"]) > 41: return "toss"
	if float(p["level"]) < 0.4: return "refill"
	return "ok"

func cycle_pan(i: int) -> void :
	var p: Dictionary = pans[i]
	var order: = ["ok", "refill", "toss"]
	p["act"] = order[(order.find(p["act"]) + 1) % 3]
	get_button("p%d" % i)["label"] = String(p["act"]).to_upper()

func _stock_score() -> float:
	var c: = 0
	for p in pans:
		if p["act"] == _correct_act(p): c += 1
		elif _correct_act(p) == "toss": notes.append("%s was at %d°F. Above 41°F for who-knows-how-long = toss it." % [p["n"], p["temp"]])
	return c / 5.0


func _make_shelf() -> void :
	shelf = []
	tossed = []
	var offs: = [-2, -1, 1, 3, 5]
	offs.shuffle()
	for o in offs:
		var day: = 31 + int(o)
		var label: = "%d/%02d" % [11 if day > 31 else 10, day - 31 if day > 31 else day]
		shelf.append({"off": o, "label": label})
	sel = -1
	kb = 0

func pick(i: int) -> void :
	if i < 0 or i >= shelf.size():
		return
	if sel == -1:
		sel = i
	elif sel == i:
		sel = -1
	else:
		var tmp = shelf[sel]
		shelf[sel] = shelf[i]
		shelf[i] = tmp
		sel = -1

func toss_selected() -> void :
	if sel < 0:
		return
	tossed.append(shelf[sel])
	shelf.remove_at(sel)
	sel = -1
	kb = clampi(kb, 0, maxi(0, shelf.size() - 1))

func _fifo_score() -> float:
	var total: = shelf.size() + tossed.size()
	var right: = 0
	for it in tossed:
		if int(it["off"]) < 0: right += 1
		else: notes.append("Tossed perfectly good milk (%s). Food cost cries. Owner docks the line, not himself." % it["label"])
	var kept_expired: = false
	for it in shelf:
		if int(it["off"]) >= 0: right += 1
		else: kept_expired = true
	if kept_expired:
		notes.append("Expired milk still on the shelf. Toss anything past its date.")
	var inv: = 0
	var pairs: = 0
	for i in shelf.size():
		for j in range(i + 1, shelf.size()):
			pairs += 1
			if int(shelf[i]["off"]) > int(shelf[j]["off"]): inv += 1
	var order_s: = 1.0 - (float(inv) / pairs if pairs > 0 else 0.0)
	if inv > 0:
		notes.append("FIFO: oldest in front. You've got newer stuff in front of older.")
	return 0.5 * float(right) / total + 0.5 * order_s

func _slot_rect(i: int) -> Rect2:
	return Rect2(10 + i * 60, 60, 52, 50)


func _cell_rect(i: int) -> Rect2:
	var col: = i % 10
	var row: = i / 10
	return Rect2(60 + col * 20, 40 + row * 20, 20, 20)

func wipe_at(p: Vector2) -> void :
	for i in cells.size():
		if _cell_rect(i).grow(3).has_point(p):
			if tool == "soap" and cells[i] == 0:
				cells[i] = 1
			elif tool == "san":
				if cells[i] == 1:
					cells[i] = 2
				elif cells[i] == 0 and not warned:
					warned = true
					flash("Sanitizer doesn't work on a dirty surface. Wash first!", Color("#e6a640"))

func _wipe_score() -> float:
	var c: = 0
	for v in cells:
		if v == 2: c += 1
	if warned:
		notes.append("Tried to sanitize before cleaning. Clean, rinse, THEN sanitize.")
	return float(c) / cells.size()


func _pointer_down(p: Vector2) -> void :
	match phase():
		"fifo":
			for i in shelf.size():
				if _slot_rect(i).has_point(p):
					pick(i)
		"wipe":
			wipe_at(p)
		"stock":
			for i in 5:
				if Rect2(6 + i * 62, 40, 58, 66).has_point(p):
					cycle_pan(i)

func _pointer_move(p: Vector2) -> void :
	if phase() == "wipe" and is_pen():
		wipe_at(p)

func _key(e: InputEventKey) -> void :
	if phase() == "fifo":
		match e.physical_keycode:
			KEY_LEFT, KEY_A: kb = maxi(0, kb - 1)
			KEY_RIGHT, KEY_D: kb = mini(shelf.size() - 1, kb + 1)
			KEY_SPACE: pick(kb)

func _on_button(id: String) -> void :
	match id:
		"chop": chop()
		"done": end_phase()
		"toss": toss_selected()
		"soap": tool = "soap"
		"san": tool = "san"
		_:
			if id.begins_with("p"): cycle_pan(int(id.substr(1)))

func debug_solve(good: bool) -> void :

	for i in 12:
		t = i * BEAT + (0.0 if good else 0.2)
		chop()

	for i in 5:
		var want: = _correct_act(pans[i]) if good else "ok"
		while pans[i]["act"] != want:
			cycle_pan(i)
	end_phase()

	if good:
		var i: = 0
		while i < shelf.size():
			if int(shelf[i]["off"]) < 0:
				sel = i
				toss_selected()
			else:
				i += 1
		for a in shelf.size():
			for b in range(shelf.size() - 1 - a):
				if int(shelf[b]["off"]) > int(shelf[b + 1]["off"]):
					pick(b)
					pick(b + 1)
	end_phase()

	if good:
		tool = "soap"
		for i in cells.size(): wipe_at(_cell_rect(i).get_center())
		tool = "san"
		for i in cells.size(): wipe_at(_cell_rect(i).get_center())
	else:
		tool = "san"
		for i in cells.size(): wipe_at(_cell_rect(i).get_center())
	end_phase()

func _draw_game() -> void :
	match phase():
		"chop":
			var pulse: = 1.0 - fmod(t, BEAT) / BEAT
			draw_circle(Vector2(270, 50), 8 + pulse * 8, Color(1, 0.8, 0.2, 0.3 + pulse * 0.5))
			txt(Vector2(240, 80), "Chop on the pulse", 8, Color(1, 1, 1, 0.6))
			draw_rect(Rect2(40, 60, 170, 60), Color("#b8865a"))
			draw_circle(Vector2(90, 90), 22, Color("#e04a3a"))
			for i in chops:
				draw_rect(Rect2(120 + i * 6, 76, 4, 28), Color("#e04a3a"))
			txt(Vector2(40, 140), "%d / 12 chops" % chops, 8)
			txt(Vector2(0, 28), "Steady beats only. Rushing = cuts.", 8, Color("#c0d890"), HORIZONTAL_ALIGNMENT_CENTER, W)
		"stock":
			txt(Vector2(0, 28), "Tap a pan to set: OK / REFILL (low) / TOSS (over 41°F)", 8, Color("#c0d890"), HORIZONTAL_ALIGNMENT_CENTER, W)
			for i in pans.size():
				var p: Dictionary = pans[i]
				var r: = Rect2(6 + i * 62, 40, 58, 66)
				draw_rect(r, Color("#9aa0aa"))
				var lv: float = p["level"]
				draw_rect(Rect2(r.position.x + 4, r.end.y - 4 - 40 * lv, 50, 40 * lv), Color("#6aa04a"))
				txt(Vector2(r.position.x, r.position.y + 10), p["n"], 8, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, 58)
				var hot: = int(p["temp"]) > 41
				txt(Vector2(r.position.x, r.position.y + 20), "%d°F" % p["temp"], 8, Color("#7a2a22") if hot else Color("#103a10"), HORIZONTAL_ALIGNMENT_CENTER, 58)
		"fifo":
			txt(Vector2(0, 28), "Today is %s. Oldest in FRONT (left). Toss anything expired." % today_s, 8, Color("#c0d890"), HORIZONTAL_ALIGNMENT_CENTER, W)
			txt(Vector2(10, 52), "FRONT", 8, Color(1, 1, 1, 0.6))
			txt(Vector2(260, 52), "BACK", 8, Color(1, 1, 1, 0.6))
			draw_rect(Rect2(6, 112, 308, 4), Color("#888888"))
			for i in shelf.size():
				var r: = _slot_rect(i)
				draw_rect(r, Color("#f4f4f8"))
				draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 10), Color("#3a5fc8"))
				txt(Vector2(r.position.x, r.position.y + 26), "MILK", 8, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
				txt(Vector2(r.position.x, r.position.y + 40), "use by", 6, Color(0.3, 0.3, 0.3), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
				txt(Vector2(r.position.x, r.position.y + 48), shelf[i]["label"], 8, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
				if i == sel:
					draw_rect(r.grow(2), Color("#e6a640"), false, 2.0)
				elif i == kb:
					draw_rect(r.grow(2), Color(1, 1, 1, 0.4), false, 1.0)
			txt(Vector2(0, 132), "Tap two cartons to swap. Keys: arrows + Space, X toss.", 8, Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_CENTER, W)
		"wipe":
			show_cursor = true
			txt(Vector2(0, 28), "Tool: %s. Drag to wipe (or arrows + hold Space)." % ("SOAPY WATER" if tool == "soap" else "SANITIZER"), 8, Color("#c0d890"), HORIZONTAL_ALIGNMENT_CENTER, W)
			for i in cells.size():
				var c: Color = [Color("#7a6a4a"), Color("#b8c0c8"), Color("#e8f4f0")][cells[i]]
				draw_rect(_cell_rect(i), c)
			draw_rect(Rect2(60, 40, 200, 80), Color(1, 1, 1, 0.3), false, 1.0)
