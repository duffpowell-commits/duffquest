extends Node2D

var c: Node = null
var items: Array = []
var beams: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 60

func number(pos: Vector2, amount: float, big: bool = false) -> void:
	var s: = str(int(round(amount))) if amount >= 1.0 else "%.1f" % amount
	text(pos + Vector2(randf_range(-4, 4), 0), s, Color("#ffe040") if big else Color("#ffffff"), 0.7, 9 if big else 7)

func text(pos: Vector2, s: String, col: Color, dur: float = 0.9, size: int = 7) -> void:
	items.append({"type": "text", "pos": pos, "s": s, "col": col, "t": 0.0, "dur": dur, "size": size })

## Impact burst: n short streaks thrown away from the hit (mostly along dir), white-hot to orange.
func sparks(pos: Vector2, dir: Vector2, n: int, big: bool) -> void:
	if n <= 0:
		return
	var base: = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	var rays: Array = []
	for i in n:
		var spread: = PI * (0.9 if big else 0.6)
		rays.append([base.rotated(randf_range(-spread, spread)), randf_range(0.6, 1.0)])
	items.append({"type": "sparks", "pos": pos, "rays": rays, "big": big, "t": 0.0, "dur": 0.24 if big else 0.18 })
	if big:
		ring(pos, 14.0, Color(1.0, 0.85, 0.4))

func ring(pos: Vector2, radius: float, col: Color) -> void:
	items.append({"type": "ring", "pos": pos, "r": radius, "col": col, "t": 0.0, "dur": 0.35 })

func cut(pos: Vector2, dir: Vector2) -> void:
	items.append({"type": "cut", "pos": pos, "dir": dir.normalized().rotated(randf_range(-0.6, 0.6)), "t": 0.0, "dur": 0.6 })

func receipt(pos: Vector2) -> void:
	items.append({"type": "receipt", "pos": pos, "t": 0.0, "dur": 1.6 })

func beam(owner: Node2D, dir: Vector2, length: float, width: float, dur: float, tick_dmg: float) -> void:
	beams.append({"owner": owner, "dir": dir, "len": length, "w": width, "t": 0.0, "dur": dur,
		"dmg": tick_dmg, "tick": 0.0 })

func _process(delta: float) -> void:
	var paused: = get_tree().paused
	for it in items:
		if it["type"] == "receipt" or not paused:
			it["t"] += delta
		if it["type"] == "text":
			it["pos"] += Vector2(0, -16.0 * delta)
	items = items.filter(func (it): return it["t"] < it["dur"])
	if not paused:
		for b in beams:
			b["t"] += delta
			b["tick"] -= delta
			if b["tick"] <= 0.0 and is_instance_valid(b["owner"]):
				b["tick"] = 0.1
				_beam_damage(b)
		beams = beams.filter(func (b): return b["t"] < b["dur"] and is_instance_valid(b["owner"]))
	queue_redraw()

func _beam_damage(b: Dictionary) -> void:
	var o: Vector2 = b["owner"].global_position + Vector2(0, -6)
	var d: Vector2 = b["dir"]
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		var rel: Vector2 = e.global_position - o
		var along: = rel.dot(d)
		var across: = absf(rel.cross(d))
		var pad: = 10.0 if e.is_in_group("boss") else 4.0
		if along > 0.0 and along < b["len"] and across < b["w"] * 0.5 + pad:
			c.hit(e, d, b["dmg"], "", 1.0, false)
	for pr in get_tree().get_nodes_in_group("projectile"):
		if is_instance_valid(pr):
			var rel2: Vector2 = pr.global_position - o
			if rel2.dot(d) > 0.0 and rel2.dot(d) < b["len"] and absf(rel2.cross(d)) < b["w"] * 0.5 + 3.0:
				pr.queue_free()

func _draw() -> void:
	var f: = ThemeDB.fallback_font
	_draw_moves()
	for b in beams:
		if not is_instance_valid(b["owner"]):
			continue
		var o: Vector2 = b["owner"].global_position + Vector2(0, -6)
		var d: Vector2 = b["dir"]
		var k: float = 1.0 - b["t"] / b["dur"]
		var w: float = b["w"] * (0.6 + 0.4 * k)
		var end: Vector2 = o + d * float(b["len"])
		draw_line(o, end, Color(1.0, 0.45, 0.1, 0.55 * k), w + 6.0)
		draw_line(o, end, Color(1.0, 0.75, 0.3, 0.85 * k), w)
		draw_line(o, end, Color(1.0, 1.0, 0.85, k), maxf(1.0, w * 0.35))
		draw_circle(o, w * 0.7, Color(1.0, 0.9, 0.6, k))
	for it in items:
		var k: float = 1.0 - it["t"] / it["dur"]
		match it["type"]:
			"text":
				var s: String = it["s"]
				var pop: = maxf(0.0, 1.0 - float(it["t"]) / 0.12)
				var sz: int = int(round(float(it["size"]) * (1.0 + 0.7 * pop)))
				var wdt: = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
				var p: Vector2 = it["pos"] - Vector2(wdt / 2.0, 0)
				var col: Color = it["col"]
				col.a = minf(1.0, k * 2.0)
				draw_string(f, p + Vector2(0.7, 0.7), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, col.a * 0.8))
				draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
			"sparks":
				var e: float = 1.0 - k
				var reach: = (16.0 if it["big"] else 10.0)
				for ray in it["rays"]:
					var dv: Vector2 = ray[0]
					var ln: float = float(ray[1]) * reach
					var a0: Vector2 = it["pos"] + dv * ln * (0.25 + e * 0.8)
					var a1: Vector2 = it["pos"] + dv * ln * (0.6 + e * 0.9)
					var hot: = Color(1.0, 1.0, 0.85, k).lerp(Color(1.0, 0.55, 0.15, k), e)
					draw_line(a0, a1, hot, 1.5 if it["big"] else 1.0)
				if e < 0.35:
					draw_circle(it["pos"], (6.0 if it["big"] else 4.0) * (1.0 - e * 2.0), Color(1, 1, 0.9, 0.9))
			"ring":
				var r: float = it["r"] * (1.0 - k * k)
				var col2: Color = it["col"]
				col2.a = k
				draw_arc(it["pos"], r, 0.0, TAU, 40, col2, 2.0)
				draw_arc(it["pos"], r * 0.8, 0.0, TAU, 32, Color(col2.r, col2.g, col2.b, k * 0.4), 1.0)
			"cut":

				var d: Vector2 = it["dir"].orthogonal()
				for j in 3:
					var o: Vector2 = it["pos"] + Vector2(0, -6) + it["dir"] * (j - 1) * 3.0
					draw_line(o - d * 9.0, o + d * 9.0, Color(1, 1, 1, k), 1.0)
			"receipt":

				var t: float = it["t"]
				var p2: Vector2 = it["pos"] + Vector2(sin(t * 6.0) * 3.0, t * 10.0)
				var a: = minf(1.0, (it["dur"] - t) * 2.0)
				draw_rect(Rect2(p2, Vector2(16, 20)), Color(1, 1, 1, a))
				draw_rect(Rect2(p2, Vector2(16, 20)), Color(0.16, 0.1, 0.18, a), false, 1.0)
				draw_string(f, p2 + Vector2(1.5, 9), "86'd", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.85, 0.1, 0.1, a))
				for ly in [12.0, 15.0, 18.0]:
					draw_line(p2 + Vector2(2, ly), p2 + Vector2(14, ly), Color(0.3, 0.3, 0.3, a * 0.6), 0.6)

func _draw_moves() -> void:
	if c == null or c.m == null or c.m.player == null:
		return
	var p: Vector2 = c.m.player.global_position
	var tnow: = Time.get_ticks_msec() / 1000.0
	if c.brulee_t > 0.0:
		var a: = minf(1.0, c.brulee_t * 2.0)
		for i in 10:
			var ang: = tnow * 4.0 + i * TAU / 10.0
			var fp: = p + Vector2(cos(ang) * 22.0, sin(ang) * 14.0 - 2.0)
			var fh: = 4.0 + 2.0 * sin(tnow * 15.0 + i)
			draw_line(fp, fp + Vector2(0, -fh), Color(1.0, 0.55, 0.1, 0.85 * a), 2.0)
			draw_circle(fp, 1.5, Color(1.0, 0.9, 0.4, 0.9 * a))
		draw_arc(p + Vector2(0, -2), 22.0, 0.0, TAU, 32, Color(1.0, 0.4, 0.1, 0.35 * a), 1.0)
	if c.tempura_t > 0.0:
		for i in 14:
			var ang2: = -tnow * 14.0 + i * TAU / 14.0
			var r: = 10.0 + 14.0 * fmod(i * 0.37 + tnow * 2.0, 1.0)
			draw_circle(p + Vector2(cos(ang2) * r, sin(ang2) * r * 0.6 - 3.0), 1.2, Color(1.0, 0.85, 0.4, 0.9))
		draw_arc(p + Vector2(0, -3), 12.0, tnow * 14.0, tnow * 14.0 + 4.0, 12, Color("#e0c040"), 2.0)
	for sn in c.snared:
		var e = sn["e"]
		if is_instance_valid(e):
			var ep: Vector2 = e.global_position + Vector2(0, -4)
			draw_rect(Rect2(ep - Vector2(9, 12), Vector2(18, 22)), Color(0.75, 0.9, 1.0, 0.28))
			draw_rect(Rect2(ep - Vector2(9, 12), Vector2(18, 22)), Color(0.85, 0.95, 1.0, 0.8), false, 1.0)
			for ly in [-6.0, 2.0]:
				draw_line(ep + Vector2(-8, ly), ep + Vector2(8, ly + 2.0), Color(1, 1, 1, 0.5), 0.6)
