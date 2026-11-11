extends "res://scripts/minigames/minigame.gd"

const COLS: = 10
const ROWS: = 5
const TILE: = 26.0
const ORIGIN: = Vector2(30, 30)
const KNOCKS: = ["{cat1} knocks a cup off the nightstand. Eye contact maintained.", "{cat2} launches the baby monitor off the dresser.", "A cat yowls because I exist.", "{cat1} body-slams the laundry basket."]

var creaky: = {}
var pos: = Vector2i(0, 2)
var goal: = Vector2i(COLS - 1, 2)
var cats: Array = []
var noise: = 0.0
var peak: = 0.0
var last_move: = -10.0
var cat_t: = 0.0

func _setup() -> void:
	title = "BABY'S FINALLY ASLEEP"
	music = "home"
	backdrop = "nursery"
	backdrop_dim = 0.62
	time_limit = 40.0
	space_is_pen = false
	_gen()
	cats = [
		{"n": "{cat1}", "p": Vector2i(3, 0), "d": Vector2i(1, 0), "c": Color("#e08a2a") },
		{"n": "{cat2}", "p": Vector2i(6, 4), "d": Vector2i(0, -1), "c": Color("#f0a040") },
	]

func _gen() -> void:
	for attempt in 50:
		creaky = {}
		for c in [2, 4, 6, 8]:
			creaky[Vector2i(c, 2)] = true
		var n: = 0
		while n < 9:
			var v: = Vector2i(randi_range(1, COLS - 2), randi_range(0, ROWS - 1))
			if not creaky.has(v):
				creaky[v] = true
				n += 1
		if not safe_path().is_empty():
			return

func safe_path(avoid_cats: bool = false) -> Array:
	var start: = pos
	var prev: = {start: start }
	var q: Array = [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == goal:
			var path: Array = []
			while c != start:
				path.push_front(c)
				c = prev[c]
			return path
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: Vector2i = c + d
			if nx.x < 0 or nx.y < 0 or nx.x >= COLS or nx.y >= ROWS or prev.has(nx) or creaky.has(nx):
				continue
			if avoid_cats and _cat_at(nx) != "":
				continue
			prev[nx] = c
			q.append(nx)
	return []

func _cat_at(v: Vector2i) -> String:
	for c in cats:
		if c["p"] == v:
			return c["n"]
	return ""

func _make_noise(amount: float, msg: String = "") -> void:
	noise += amount
	peak = maxf(peak, noise)
	if msg != "":
		flash(msg, Color("#e6a640"), 1.3)
	if noise >= 100.0:
		notes.append("She wakes up. Guess who's sleeping on the floor by the crib tonight.")
		finish(0.0)

func step(d: Vector2i) -> void:
	var nx: = pos + d
	if nx.x < 0 or nx.y < 0 or nx.x >= COLS or nx.y >= ROWS:
		return
	pos = nx
	if t - last_move < 0.35:
		_make_noise(8.0, "Tiptoe, don't sprint.")
	last_move = t
	if done: return
	if creaky.has(pos):
		_make_noise(30.0, "CREEEEAK.")
	else:
		_make_noise(2.0)
	if done: return
	var c: = _cat_at(pos)
	if c != "":
		_make_noise(40.0, "I step on %s. He screams like a car alarm." % c)
	if done: return
	if pos == goal:
		finish(clampf(1.0 - maxf(0.0, peak - 30.0) / 120.0, 0.3, 1.0))

func _timeout() -> void:
	notes.append("I take so long she wakes up for round two.")
	finish(0.0)

func _tick(delta: float) -> void:
	noise = maxf(0.0, noise - 6.0 * delta)
	cat_t += delta
	if cat_t >= 0.8:
		cat_t = 0.0
		for c in cats:
			var nx: Vector2i = c["p"] + c["d"]
			if nx.x < 0 or nx.y < 0 or nx.x >= COLS or nx.y >= ROWS:
				c["d"] = -c["d"]
				nx = c["p"] + c["d"]
			c["p"] = nx
			if nx == pos:
				_make_noise(40.0, KNOCKS[randi() % KNOCKS.size()])
				if done: return
		if randf() < 0.08:
			_make_noise(20.0, KNOCKS[randi() % KNOCKS.size()])

func _tile_rect(v: Vector2i) -> Rect2:
	return Rect2(ORIGIN + Vector2(v) * TILE, Vector2(TILE - 1, TILE - 1))

func _pointer_down(p: Vector2) -> void:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if _tile_rect(pos + d).has_point(p):
			step(d)
			return

func _key(e: InputEventKey) -> void:
	match e.physical_keycode:
		KEY_LEFT, KEY_A: step(Vector2i(-1, 0))
		KEY_RIGHT, KEY_D: step(Vector2i(1, 0))
		KEY_UP, KEY_W: step(Vector2i(0, -1))
		KEY_DOWN, KEY_S: step(Vector2i(0, 1))

func debug_solve(good: bool) -> void:
	if good:
		var path: = safe_path(true)
		var tries: = 0
		while path.is_empty() and tries < 100:
			tries += 1
			for c in cats:
				c["p"] = Vector2i(randi_range(0, COLS - 1), randi_range(0, ROWS - 1))
			path = safe_path(true) if _cat_at(pos) == "" else []
		for v in path:
			last_move = -10.0
			t = 0.0
			step(v - pos)
			if done: return
	else:
		while not done:
			last_move = -10.0
			step(Vector2i(1, 0))

const WOOD: = [Color("#7a5236"), Color("#6c4830")]

func _draw_game() -> void:
	var floor: = Rect2(ORIGIN - Vector2(1, 1), Vector2(COLS * TILE + 1, ROWS * TILE + 1))
	UiStyle.prop(self, floor, WOOD[0], 1.0, 0.0)
	# one plank per row; board joints staggered every other row, tile seams only as faint grain breaks
	for y in ROWS:
		var row: = Rect2(ORIGIN.x, ORIGIN.y + y * TILE, COLS * TILE - 1, TILE - 1)
		draw_rect(row, WOOD[y % 2])
		draw_rect(Rect2(row.position.x, row.end.y - 5, row.size.x, 5), WOOD[y % 2].darkened(0.18))
		for k in 3:   # grain
			var gy: = row.position.y + 6 + k * 6
			draw_line(Vector2(row.position.x + 4 + (y * 37 + k * 53) % 40, gy), Vector2(row.end.x - (k * 29) % 50, gy),
				Color(WOOD[y % 2].darkened(0.28), 0.5), 0.6)
		for x in range(2 if y % 2 == 0 else 1, COLS, 2):
			draw_line(Vector2(ORIGIN.x + x * TILE - 0.5, row.position.y), Vector2(ORIGIN.x + x * TILE - 0.5, row.end.y),
				UiStyle.PROP_INK, 1.0)
		draw_line(Vector2(row.position.x, row.end.y + 0.5), Vector2(row.end.x, row.end.y + 0.5), UiStyle.PROP_INK, 1.0)
	for x in COLS:   # faint tile ticks so you can count steps
		for y in ROWS:
			var r: = _tile_rect(Vector2i(x, y))
			draw_rect(r, Color(1, 1, 1, 0.04), false, 0.5)
	# creaky boards: warped up, lit edge, an ink crack, little creak marks
	for v in creaky:
		var r: = _tile_rect(v)
		draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 6)), WOOD[v.y % 2].lightened(0.12))
		draw_line(r.position + Vector2(2, 2), Vector2(r.end.x - 2, r.position.y + 2), Color("#f2c88a", 0.7), 1.0)
		var crack: = PackedVector2Array([r.position + Vector2(4, 9), r.position + Vector2(10, 14), r.position + Vector2(14, 10),
			r.position + Vector2(21, 15)])
		draw_polyline(crack, UiStyle.PROP_INK, 1.2)
		for k in 2:
			var a: = r.position + Vector2(18 + k * 3, 3)
			draw_line(a, a + Vector2(2, -3), Color(UiStyle.CREAM, 0.55), 0.8)
	# nightlight glow by the crib, cool moonlight on the floor
	for k in 4:
		draw_circle(_tile_rect(Vector2i(0, 2)).get_center(), 42.0 - k * 9.0, Color("#ffd27a", 0.05))
	draw_rect(Rect2(ORIGIN, Vector2(COLS * TILE, ROWS * TILE)), Color("#1a2450", 0.18))
	# tiles you can step to: dashed cream outline (touch players tap these)
	if not done:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nv: Vector2i = pos + d
			if nv.x >= 0 and nv.y >= 0 and nv.x < COLS and nv.y < ROWS:
				var nr: = _tile_rect(nv).grow(-2)
				var a: = 0.35 + 0.2 * sin(t * 5.0)
				draw_rect(nr, Color(UiStyle.CREAM, a), false, 1.0)
	# crib (start)
	var cr: = _tile_rect(Vector2i(0, 2)).grow(-1)
	prop(cr, Color("#e8dcf6"), 0.2)
	for k in range(1, 5):
		draw_line(Vector2(cr.position.x + k * cr.size.x / 5.0, cr.position.y + 2), Vector2(cr.position.x + k * cr.size.x / 5.0, cr.end.y - 2),
			Color("#9a88c0"), 1.0)
	Art.frame(self, "baby", cr.get_center(), 0, 0)
	# bed (goal): headboard against the wall, navy blanket, cream pillow
	var g: = _tile_rect(goal)
	var bed: = Rect2(g.position.x - 2, g.position.y - 10, W - g.position.x - 2, g.size.y + 20)
	prop(Rect2(bed.end.x - 6, bed.position.y - 4, 6, bed.size.y + 8), Color("#4a2e22"), 0.2)
	prop(Rect2(bed.position, bed.size - Vector2(6, 0)), Color("#34407a"), 0.25)
	prop(Rect2(bed.end.x - 22, bed.position.y + 6, 14, bed.size.y - 12), UiStyle.CREAM, 0.2)
	draw_line(bed.position + Vector2(8, 4), bed.position + Vector2(8, bed.size.y - 4), Color("#4a58a0"), 2.0)
	UiStyle.label(self, Vector2(bed.position.x, bed.end.y + 9), "BED", 8, UiStyle.GOLD, bed.size.x, HORIZONTAL_ALIGNMENT_CENTER, 2)
	for c in cats:
		var dv: Vector2i = c["d"]
		var cs: = {"{cat1}": "cat_alastor", "{cat2}": "cat_lucifer" }.get(str(c["n"]), "cat_freya") as String
		draw_set_transform(_tile_rect(c["p"]).get_center() + Vector2(0, 6), 0.0, Vector2(1.5, 1.5))
		Art.frame(self, cs, Vector2.ZERO, int(t * 5.0) % 2, 1 if dv.x < 0 else 0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var pr: = _tile_rect(pos)
	var dn: = "duff_%s_red" % (duff_armor if ["apron", "clogs", "sleeves", "coat", "dad"].has(duff_armor) else "apron")
	Art.person(self, dn, pr.get_center() + Vector2(0, 11), Vector2.RIGHT, t, false)
	UiStyle.label(self, Vector2(30, 24), "Noise", 8, UiStyle.CREAM, -1.0, HORIZONTAL_ALIGNMENT_LEFT, 2)
	bar(Rect2(62, 18, 120, 7), noise / 100.0, Color("#e06a4a"))
	txt(Vector2(30, 172), "Tap a lit tile or use arrows. Warped boards creak. Avoid the cats.", 7, Color(1, 1, 1, 0.75))
