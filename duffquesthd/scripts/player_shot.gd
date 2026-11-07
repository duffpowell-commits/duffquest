extends Node2D


var c: Node = null
var owner_ref: Node2D = null
var kind: = "grease"
var vel: = Vector2.ZERO
var dmg: = 1.0
var boomerang: = false
var returning: = false
var life: = 0.0
var hit_ids: = {}
var spin: = 0.0

const RADIUS: = {"grease": 5.0, "plate": 7.0, "reflect": 6.0, "hashbrown": 5.0}
const MAX_LIFE: = {"grease": 0.55, "plate": 2.2, "reflect": 1.2, "hashbrown": 0.5}


func _ready() -> void :
	add_to_group("player_shot")
	z_index = 20
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _physics_process(delta: float) -> void :
	life += delta
	spin += delta * 18.0
	if boomerang:
		if not returning and life > 0.55:
			returning = true
			hit_ids.clear()
		if returning and is_instance_valid(owner_ref):
			var to: Vector2 = owner_ref.global_position - global_position
			if to.length() < 8.0:
				queue_free()
				return
			vel = vel.lerp(to.normalized() * 190.0, 0.18)
	elif kind == "grease" or kind == "hashbrown":
		vel *= 0.985
	global_position += vel * delta
	if life > MAX_LIFE[kind]:
		queue_free()
		return
	var r: float = RADIUS[kind]
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or e.is_queued_for_deletion() or hit_ids.has(e.get_instance_id()):
			continue
		var reach: = r + (10.0 if e.is_in_group("boss") else 5.0)
		if e.global_position.distance_to(global_position) < reach:
			hit_ids[e.get_instance_id()] = true
			var special: = "flip" if kind == "plate" else ("stun" if kind == "reflect" else "")
			c.hit(e, vel.normalized(), dmg, special, 3.0)
			if kind == "grease":
				queue_free()
				return
	queue_redraw()

func _draw() -> void :
	match kind:
		"grease":
			draw_circle(Vector2.ZERO, 2.4, Color("#f8c848"))
			draw_circle(Vector2(-0.6, -0.6), 1.0, Color("#fff4c0"))
			draw_line(Vector2.ZERO, - vel.normalized() * 5.0, Color(1.0, 0.75, 0.25, 0.5), 1.5)
		"plate":
			var sx: = absf(cos(spin))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(maxf(0.25, sx), 1.0))
			draw_circle(Vector2.ZERO, 5.5, Color("#2a1a2e"))
			draw_circle(Vector2.ZERO, 4.8, Color("#ffffff"))
			draw_arc(Vector2.ZERO, 3.2, 0.0, TAU, 14, Color("#c8d0e8"), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"hashbrown":
			for k in 3:
				var o: = Vector2.from_angle(spin * 0.3 + k * 2.1) * 2.0
				draw_line(o - Vector2(1.5, 0.5), o + Vector2(1.5, -0.5), Color("#e8a840") if k != 1 else Color("#f8d878"), 1.5)
			draw_line(Vector2.ZERO, - vel.normalized() * 4.0, Color(0.95, 0.7, 0.3, 0.4), 1.0)
		"reflect":
			draw_circle(Vector2.ZERO, 4.0, Color(1, 1, 1, 0.9))
			draw_arc(Vector2.ZERO, 6.0, spin, spin + PI, 10, Color("#ffe080"), 1.5)
