extends Node2D

var cat_name: = "{cat1}"
var col: = Color("#e08a2a")
var target: Node2D
var room: = Rect2()
var hungry: = true
var vel: = Vector2.ZERO
var think: = 0.0
var bubble: = ""
var bubble_t: = 0.0

func say(s: String, dur: float = 2.0) -> void:
	bubble = preload("res://scripts/cast.gd").T(s)
	bubble_t = dur

func _process(delta: float) -> void:
	think -= delta
	bubble_t = maxf(0.0, bubble_t - delta)
	var to: = target.position - position if target else Vector2.ZERO
	if hungry and target and to.length() < 70.0:
		vel = to.normalized() * 40.0 if to.length() > 14.0 else Vector2.ZERO
		if think <= 0.0:
			think = randf_range(2.5, 5.0)
			say(["Mrrrow? (food)", "MEOW. (food)", "*headbutts your shin*", "*stares at the bowl, then you*"][randi() % 4])
	elif think <= 0.0:
		think = randf_range(0.8, 2.5)
		vel = Vector2.from_angle(randf() * TAU) * randf_range(0.0, 45.0) if randf() < 0.75 else Vector2.ZERO
	position += vel * delta
	position = position.clamp(room.position, room.end)
	queue_redraw()

const Art: = preload("res://scripts/art.gd")
const SHEETS: = {"{cat1}": "cat_alastor", "{cat2}": "cat_lucifer", "{cat3}": "cat_freya" }
var anim_t: = 0.0

func sheet_name() -> String:
	return str(SHEETS.get(cat_name, "cat_alastor"))

func _draw() -> void:

	anim_t = Time.get_ticks_msec() / 1000.0
	var fr: = 2
	if vel.length() > 4.0:
		fr = int(anim_t * 8.0) % 2
	elif not hungry:
		fr = 3
	Art.shadow(self, Vector2(0, 5), 5.0, 1.6, 0.26)
	Art.frame(self, sheet_name(), Vector2(0, 5), fr, 0 if vel.x >= 0 else 1)
	if bubble_t > 0.0:
		var f: = ThemeDB.fallback_font
		var w: = f.get_string_size(bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x + 6
		draw_rect(Rect2(-w / 2, -22, w, 10), Color(1, 1, 1, 0.9))
		draw_string(f, Vector2(-w / 2 + 3, -14), bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.BLACK)
