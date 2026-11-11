extends "res://scripts/minigames/minigame.gd"

const CREAM_TARGETS: = [Vector2(128, 66), Vector2(160, 66), Vector2(192, 66)]

var phase: = "drizzle"
var guide: Array = []
var covered: Array = []
var ink: Array = []
var stray: = 0.0
var last_p: = Vector2.ZERO
var drizzle_score: = 0.0
var creams: Array = []
var cream_scores: Array = []
var cherries: Array = []
var cherry_scores: Array = []
var cream_used: Array = []

func _setup() -> void:
	title = "Dessert: Black Forest Garnish"
	time_limit = 22.0 if rush() else 32.0
	for i in 15:
		var x: = 112.0 + i * 6.0
		guide.append(Vector2(x, 82.0 + (6.0 if i % 2 == 0 else -6.0)))
		covered.append(false)
	add_button("next", Rect2(236, 152, 80, 22), "NEXT STEP", KEY_ENTER, Color("#4e7a3a"))

func _nearest_guide_dist(p: Vector2) -> float:
	var best: = 1000000000.0
	for i in guide.size() - 1:
		var q: = Geometry2D.get_closest_point_to_segment(p, guide[i], guide[i + 1])
		best = minf(best, p.distance_to(q))
	return best

func paint(p: Vector2) -> void:
	if phase != "drizzle":
		return
	if not ink.is_empty():
		var seg: = p.distance_to(last_p)
		if _nearest_guide_dist(p) > 10.0:
			stray += seg
	ink.append(p)
	last_p = p
	for i in guide.size():
		if not covered[i] and p.distance_to(guide[i]) < 7.0:
			covered[i] = true
	if _coverage() >= 1.0:
		end_drizzle()

func _coverage() -> float:
	var c: = 0
	for v in covered:
		if v: c += 1
	return float(c) / covered.size()

func end_drizzle() -> void:
	if phase != "drizzle":
		return
	drizzle_score = _coverage() * maxf(0.0, 1.0 - stray / 150.0)
	if stray > 60.0:
		notes.append("I get chocolate on the rim. And the plate. And the ticket.")
	phase = "cream"
	ink.append(Vector2.INF)
	flash("Now pipe 3 whipped-cream rosettes on the dots.", Color.WHITE, 1.2)

func tap(p: Vector2) -> void:
	if phase == "cream":
		var best: = -1
		var bd: = 1000000000.0
		for i in CREAM_TARGETS.size():
			if cream_used.has(i): continue
			var d: = p.distance_to(CREAM_TARGETS[i])
			if d < bd:
				bd = d
				best = i
		cream_used.append(best)
		creams.append(p)
		cream_scores.append(clampf(1.0 - bd / 16.0, 0.0, 1.0))
		if creams.size() >= 3:
			phase = "cherry"
			flash("Cherry on each rosette.", Color.WHITE, 1.0)
	elif phase == "cherry":
		var bd2: = 1000000000.0
		for c in creams:
			bd2 = minf(bd2, p.distance_to(c))
		cherries.append(p)
		cherry_scores.append(clampf(1.0 - bd2 / 10.0, 0.0, 1.0))
		if cherries.size() >= 3:
			_done()

func _avg(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s: = 0.0
	for v in a: s += float(v)
	return s / 3.0

func _done() -> void:
	var sc: = drizzle_score * 0.4 + _avg(cream_scores) * 0.3 + _avg(cherry_scores) * 0.3
	if sc < 0.5:
		notes.append("I look at the slice. Looks like it lost a fight. Plate it anyway? Hell no. Redo.")
	finish(sc)

func _timeout() -> void:
	if phase == "drizzle":
		end_drizzle()
	_done()

func _pointer_down(p: Vector2) -> void:
	if phase == "drizzle":
		if not ink.is_empty():
			ink.append(Vector2.INF)
		last_p = p
		paint(p)
	else:
		tap(p)

func _pointer_move(p: Vector2) -> void:
	if phase == "drizzle" and is_pen():
		paint(p)

func _on_button(id: String) -> void:
	if id == "next":
		if phase == "drizzle":
			end_drizzle()
		else:
			_done()

func debug_solve(good: bool) -> void:
	if good:
		for g in guide:
			paint(g)
		for c in CREAM_TARGETS:
			tap(c)
		for c in CREAM_TARGETS:
			tap(c)
	else:
		paint(Vector2(40, 40))
		paint(Vector2(300, 140))
		end_drizzle()
		for i in 3:
			tap(Vector2(40, 150))
		for i in 3:
			tap(Vector2(300, 20))

func _draw_game() -> void:
	show_cursor = show_cursor or phase != "drizzle"
	prop_circle(Vector2(160, 92), 74, Color("#f4f4f8"))

	prop(Rect2(104, 70, 112, 46), Color("#3a1e14"))
	draw_rect(Rect2(104, 82, 112, 5), Color("#fbf6ec"))
	draw_rect(Rect2(104, 97, 112, 5), Color("#fbf6ec"))
	draw_rect(Rect2(104, 84, 112, 2), Color("#a02030"))
	prop(Rect2(104, 66, 112, 6), Color("#fbf6ec"))
	txt(Vector2(0, 26), ["Trace the drizzle along the dotted zigzag (drag / Space)", "Tap the 3 dots to pipe whipped cream", "Tap each rosette to place a cherry"][["drizzle", "cream", "cherry"].find(phase)], 8, Color("#c0d890"), HORIZONTAL_ALIGNMENT_CENTER, W)
	if phase == "drizzle":
		for i in guide.size():
			draw_circle(guide[i], 1.5, Color("#c0d890") if covered[i] else Color(0, 0, 0, 0.5))
	if phase == "cream":
		for i in CREAM_TARGETS.size():
			if not cream_used.has(i):
				draw_arc(CREAM_TARGETS[i], 6, 0, TAU, 12, Color(0, 0, 0, 0.5), 1.0)
	for i in range(1, ink.size()):
		if ink[i] != Vector2.INF and ink[i - 1] != Vector2.INF:
			draw_line(ink[i - 1], ink[i], Color("#2a120a"), 2.0)
	for c in creams:
		prop_circle(c, 6, Color("#ffffff"))
		draw_circle(c + Vector2(0, -3), 4, Color("#f0f0f0"))
	for c in cherries:
		prop_circle(c + Vector2(0, -5), 3.5, Color("#c0102a"))
		draw_line(c + Vector2(0, -8), c + Vector2(3, -13), Color("#3a6a1a"), 1.0)
