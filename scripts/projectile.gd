extends Node2D

var m: Node = null
var vel: = Vector2.ZERO
var dmg: = 5.0
var kind: = "complaint"
var life: = 4.0
var money_cost: = 0
var thrower: Node2D = null
var boomer_t: = 0.7
var spin: = 0.0
var fuse: = 0.0
var dir: = Vector2.RIGHT
var radius: = 0.0
var used: = false
var wall_body: StaticBody2D = null
var size: = Vector2(40, 8)
var label: = ""
const SPECIAL: = ["strike", "laser", "wave", "trap", "wall", "bass", "cloud", "rug", "glass"]
var tick: = 0.0

func _ready() -> void:
	add_to_group("hostile")
	add_to_group("projectile")

func _physics_process(delta: float) -> void:
	spin += delta * 12.0
	if kind in SPECIAL:
		_special(delta)
		queue_redraw()
		return
	if kind == "tariff":
		boomer_t -= delta
		if boomer_t <= 0.0:
			for i in 6:
				var b: Node2D = get_script().new()
				b.position = position
				b.m = m
				b.kind = "tariff_bit"
				b.dmg = 5.0
				b.vel = Vector2.from_angle(TAU * i / 6.0) * 80.0
				b.life = 2.0
				get_parent().add_child(b)
			queue_free()
			return
	position += vel * delta
	life -= delta
	if kind == "flipflop":
		boomer_t -= delta
		if boomer_t <= 0.0 and thrower and is_instance_valid(thrower):
			vel = (thrower.global_position - global_position).normalized() * 130.0
			if global_position.distance_to(thrower.global_position) < 8.0:
				queue_free()
				return
	if m and m.player and global_position.distance_to(m.player.global_position + Vector2(0, 2)) < 8.0:
		if m.hurt_player(dmg, global_position, 110.0, kind):
			if money_cost > 0:
				m.citation(money_cost)
			queue_free()
			return
	if life <= 0.0 or not _in_bounds():
		queue_free()
		return
	queue_redraw()

func _in_bounds() -> bool:
	var g: = global_position
	if m and str(m.get("location")) == "gala":
		return Rect2(m.GALA_ORIGIN, m.GALA_SIZE).grow(30).has_point(g)
	if m and str(m.get("location")) == "arena":
		return Rect2(m.ARENA_ORIGIN, m.ARENA_SIZE).grow(30).has_point(g)
	return g.x >= -40 and g.y >= -40 and g.x <= 680 and g.y <= 400

func _hit_check(r: float) -> bool:
	return m and m.player and global_position.distance_to(m.player.global_position + Vector2(0, 2)) < r

func _special(delta: float) -> void:
	life -= delta
	fuse -= delta
	var p: CharacterBody2D = m.player if m else null
	match kind:
		"strike":
			if fuse <= 0.0 and not used:
				used = true
				life = 0.2
				if _hit_check(18.0):
					m.hurt_player(dmg, global_position, 220.0, "rocket")
		"laser":
			if fuse <= 0.0 and not used and p:
				var a: = global_position
				var b: = a + dir * 260.0
				var cp: = Geometry2D.get_closest_point_to_segment(p.global_position, a, b)
				if cp.distance_to(p.global_position) < 7.0:
					used = m.hurt_player(dmg, cp, 200.0, "laser")
				if fuse < -0.25:
					used = true
		"bass":
			if fuse <= 0.0:
				radius += 120.0 * delta
				if p and not used and absf(global_position.distance_to(p.global_position) - radius) < 5.0:
					used = true
					if not p.rolling():
						m.stun_player(0.9, "The bass DROPS. So do I. Damn.")
						m.hurt_player(dmg, global_position, 120.0, "bass")
				if radius > 220.0:
					life = 0.0
		"cloud":
			if fuse <= 0.0 and p:
				tick -= delta
				if tick <= 0.0 and global_position.distance_to(p.global_position) < 16.0:
					tick = 0.7
					m.hurt_player(dmg, global_position, 40.0, "vape")
		"rug":
			if fuse <= 0.0 and not used and p:
				used = true
				life = 0.35
				if Rect2(global_position - size / 2.0, size).has_point(p.global_position) and not p.rolling():
					m.hurt_player(dmg, global_position - Vector2(0, 30), 260.0, "rug")
		"glass":
			pass
		"wave":
			if fuse <= 0.0:
				radius += 110.0 * delta
				if p and not used and absf(global_position.distance_to(p.global_position) - radius) < 5.0:
					used = true
					if not p.rolling():
						m.stun_player(1.0, "Your {hero} ran into a problem and needs to restart.")
						m.hurt_player(dmg, global_position, 0.0, "bsod")
				if radius > 220.0:
					life = 0.0
		"trap":
			if fuse <= 0.0 and _hit_check(8.0) and not p.rolling():
				m.stun_player(1.5, "Installing update 1 of 47... do not turn off your {hero}.")
				m.hurt_player(dmg, global_position, 0.0, "update")
				life = 0.0
		"wall":
			if fuse <= 0.0 and wall_body == null:
				var rect: = Rect2(global_position - size / 2.0, size)
				if p and rect.grow(4).has_point(p.global_position + Vector2(0, 7)):
					m.hurt_player(dmg, global_position, 260.0, "wall")
				wall_body = StaticBody2D.new()
				wall_body.collision_layer = 1
				var cs: = CollisionShape2D.new()
				var sh: = RectangleShape2D.new()
				sh.size = size
				cs.shape = sh
				wall_body.add_child(cs)
				add_child(wall_body)
	if life <= 0.0:
		queue_free()

func _draw() -> void:
	var f: = ThemeDB.fallback_font
	var blink: = int(spin * 1.5) % 2 == 0
	match kind:
		"post":
			var pl: = label if label != "" else "post"
			var pw: = maxf(12.0, pl.length() * 3.2 + 2.0)
			draw_rect(Rect2(-pw / 2.0, -4, pw, 8), Color("#1da1f2") if label == "" else Color("#e04040"))
			draw_string(f, Vector2(-pw / 2.0 + 1.0, 2), pl, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.WHITE)
		"coin":
			draw_circle(Vector2.ZERO, 3.0, Color("#ffd23f"))
			draw_string(f, Vector2(-2, 2), label if label != "" else "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("#a07010"))
		"tariff":
			draw_rect(Rect2(-8, -6, 16, 12), Color("#a07040"))
			draw_string(f, Vector2(-8, 2), "TARIFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color.WHITE)
		"tariff_bit":
			draw_rect(Rect2(-3, -3, 6, 6), Color("#c08850"))
		"strike":
			if fuse > 0.0:
				var r: = 18.0 * clampf(fuse, 0.2, 1.0)
				draw_arc(Vector2.ZERO, 18.0, 0, TAU, 20, Color(1, 0.2, 0.2, 0.7), 1.0)
				draw_arc(Vector2.ZERO, r, 0, TAU, 16, Color(1, 0.4, 0.2, 0.9), 1.0)
				draw_line(Vector2(-4, 0), Vector2(4, 0), Color(1, 0.2, 0.2))
				draw_line(Vector2(0, -4), Vector2(0, 4), Color(1, 0.2, 0.2))
				draw_rect(Rect2(Vector2(-2, -12 - fuse * 60.0), Vector2(4, 8)), Color("#e0e0e0"))
			else:
				draw_circle(Vector2.ZERO, 18.0, Color(1, 0.6, 0.1, 0.7))
		"laser":
			var end: = dir * 260.0
			if fuse > 0.0:
				if blink:
					draw_line(Vector2.ZERO, end, Color(1, 0.3, 0.3, 0.6), 1.0)
			else:
				draw_line(Vector2.ZERO, end, Color(1, 0.95, 0.6, 0.95), 5.0)
				draw_line(Vector2.ZERO, end, Color.WHITE, 2.0)
		"bass":
			if fuse > 0.0:
				draw_arc(Vector2.ZERO, 10.0, 0, TAU, 16, Color("#ff40d0"), 2.0)
			else:
				draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color("#ff40d0"), 4.0)
				draw_arc(Vector2.ZERO, radius - 4.0, 0, TAU, 48, Color("#40e0ff", 0.6), 1.0)
		"cloud":
			if fuse > 0.0:
				draw_arc(Vector2.ZERO, 16.0, 0, TAU, 20, Color(1, 1, 1, 0.5 if blink else 0.2), 1.0)
			else:
				for i in 5:
					var o: = Vector2.from_angle(i * 1.3 + spin * 0.05) * 8.0
					draw_circle(o, 9.0, Color(0.85, 0.85, 0.95, 0.45))
				draw_string(f, Vector2(-10, 2), "mango", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.5, 0.3, 0.6, 0.6))
		"rug":
			var rr2: = Rect2(-size / 2.0, size)
			if fuse > 0.0:
				draw_rect(rr2, Color(0.7, 0.2, 0.2, 0.25 if blink else 0.45))
				for x in range(int(rr2.position.x) + 4, int(rr2.end.x), 8):
					draw_line(Vector2(x, rr2.position.y), Vector2(x, rr2.end.y), Color("#ffd23f", 0.5))
				draw_string(f, Vector2(-14, 2), label if label != "" else "RUG PULL", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)
			else:
				draw_rect(rr2.grow(4), Color(1, 0.8, 0.2, 0.5))
		"glass":
			for i in 4:
				var a: = i * 1.7 + float(get_instance_id() % 7)
				var o: = Vector2.from_angle(a) * 4.0
				draw_line(o, o + Vector2.from_angle(a + 1.0) * 3.0, Color("#c8f0ff"), 1.0)
			draw_circle(Vector2.ZERO, 1.0, Color("#e8ffff"))
		"wave":
			if fuse > 0.0:
				draw_arc(Vector2.ZERO, 10.0, 0, TAU, 16, Color("#2050d0"), 2.0)
			else:
				draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color("#2050d0"), 4.0)
				draw_arc(Vector2.ZERO, radius - 3.0, 0, TAU, 48, Color(1, 1, 1, 0.4), 1.0)
		"trap":
			var c: = Color("#2050d0") if fuse <= 0.0 else Color(0.3, 0.4, 0.9, 0.4)
			draw_rect(Rect2(-7, -7, 14, 14), c, fuse <= 0.0)
			draw_rect(Rect2(-7, -7, 14, 14), Color.WHITE, false, 1.0)
			draw_string(f, Vector2(-7, 2), label if label != "" else "UPD", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.WHITE)
		"wall":
			var rr: = Rect2(-size / 2.0, size)
			if fuse > 0.0:
				draw_rect(rr, Color(1, 0.3, 0.3, 0.5 if blink else 0.2), false, 1.0)
			else:
				draw_rect(rr, Color("#a8a090"))
				for x in range(int(rr.position.x), int(rr.end.x), 6):
					draw_line(Vector2(x, rr.position.y), Vector2(x, rr.end.y), Color("#807868"))
	match kind:
		"seen":
			var sl: = label if label != "" else "Seen"
			var sw: = maxf(14.0, sl.length() * 3.2 + 2.0)
			draw_rect(Rect2(-sw / 2.0, -4, sw, 8), Color("#ffffff"))
			draw_string(f, Vector2(-sw / 2.0 + 1.0, 2), sl, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("#3070ff") if label == "" else Color("#d03030"))
		"mug":
			draw_set_transform(Vector2.ZERO, spin * 0.6, Vector2.ONE)
			draw_rect(Rect2(-3, -3, 6, 6), Color("#2a1a2e"))
			draw_rect(Rect2(-2.5, -2.5, 5, 5), Color("#f4f0e8"))
			draw_rect(Rect2(-2, -2, 4, 1.5), Color("#6a4a2a"))
			draw_arc(Vector2(3.5, 0), 1.5, -PI / 2.0, PI / 2.0, 6, Color("#f4f0e8"), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"dumbbell":
			var dd: = Vector2.from_angle(spin * 0.5) * 4.0
			draw_line(-dd, dd, Color("#888888"), 2.0)
			draw_circle(-dd, 2.5, Color("#333333"))
			draw_circle(dd, 2.5, Color("#333333"))
		"bullet":
			draw_line(Vector2.ZERO, -vel.normalized() * 4.0, Color("#ffe060"), 2.0)
		"complaint":
			draw_rect(Rect2(-5, -4, 10, 7), Color.WHITE)
			draw_string(f, Vector2(-2, 2), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#d02020"))
		"citation":
			draw_rect(Rect2(-3, -4, 6, 8), Color("#ffe8a0"))
			draw_line(Vector2(-2, -2), Vector2(2, -2), Color("#555555"))
			draw_line(Vector2(-2, 0), Vector2(2, 0), Color("#555555"))
			draw_string(f, Vector2(-2, 4), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("#2a7a3a"))
		"flipflop":
			var d: = Vector2.from_angle(spin) * 4.0
			draw_line(-d, d, Color("#ff4fb0"), 3.0)
			draw_line(Vector2.ZERO, d.rotated(1.2) * 0.6, Color("#40d0ff"), 1.0)
		"firework":
			var c: = Color.from_hsv(fmod(spin * 0.1, 1.0), 0.8, 1.0)
			draw_circle(Vector2.ZERO, 2.5, c)
			draw_line(Vector2.ZERO, -vel.normalized() * 6.0, Color(c, 0.5), 1.0)
