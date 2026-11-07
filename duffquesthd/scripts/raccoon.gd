extends CharacterBody2D


const GOBLIN_LINES: = ["*chitter*", "*rummages*", "*holds up a shiny wrapper*", "*washes a fry in a puddle*", "*unionizes*"]

var target: CharacterBody2D
var home: = Vector2.ZERO
var think_t: = 0.0
var wander: = Vector2.ZERO
var hop: = Vector2.ZERO
var pet_t: = 0.0
var huff_t: = 0.0
var line: = ""
var line_t: = 0.0
var line_cd: = 4.0
var t: = 0.0

func _ready() -> void :
	add_to_group("raccoon")
	collision_layer = 4
	collision_mask = 1
	home = position
	var cs: = CollisionShape2D.new()
	var c: = CircleShape2D.new()
	c.radius = 5
	cs.shape = c
	add_child(cs)

func say(s: String, dur: float = 1.8) -> void :
	line = s
	line_t = dur

func _physics_process(delta: float) -> void :
	t += delta
	pet_t = maxf(0.0, pet_t - delta)
	huff_t = maxf(0.0, huff_t - delta)
	line_t = maxf(0.0, line_t - delta)
	think_t -= delta
	if think_t <= 0.0:
		think_t = randf_range(1.2, 3.0)
		wander = Vector2.from_angle(randf() * TAU) * 16.0 if randf() < 0.6 else Vector2.ZERO
	var v: = wander
	if pet_t > 0.0:
		v = Vector2.ZERO
	if global_position.distance_to(home) > 34.0:
		v = (home - global_position).normalized() * 22.0
	velocity = v + hop
	hop = hop.move_toward(Vector2.ZERO, 300.0 * delta)
	move_and_slide()
	line_cd -= delta
	if line_cd <= 0.0 and target and global_position.distance_to(target.global_position) < 70.0:
		line_cd = randf_range(6.0, 11.0)
		say(GOBLIN_LINES[randi() % GOBLIN_LINES.size()])
	queue_redraw()

func pet() -> void :
	pet_t = 1.4
	AudioScript.sfx("chitter")
	say("<3 *happy chitter*")

func bonked(from: Vector2) -> void :

	huff_t = 1.0
	AudioScript.sfx("chitter", 0.8)
	hop = (global_position - from).normalized() * 120.0
	say("*offended chitter*")

func take_hit(dir: Vector2, _dmg: float = 1.0, _special: String = "") -> float:
	bonked(global_position - dir * 10.0)
	return 0.0

const Art: = preload("res://scripts/art.gd")
const AudioScript: = preload("res://scripts/audio.gd")

func _draw() -> void :

	var mv: = velocity.length() > 2.0
	var fr: = 3 if pet_t > 0.0 else (int(t * 8.0) % 2 if mv else 2)
	var face_left: = velocity.x < -1.0 if mv else (target != null and is_instance_valid(target) and target.global_position.x < global_position.x)
	Art.shadow(self, Vector2(0, 7), 5.5, 1.8, 0.28)
	Art.frame(self, "raccoon", Vector2(0, 7), fr, 1 if face_left else 0)
	if pet_t > 0.0:
		var f: = ThemeDB.fallback_font
		draw_string(f, Vector2(-3, -10 - (1.4 - pet_t) * 6.0), "<3", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#ff5fa2"))
	if huff_t > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -10), "!#", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("#ff7a3a"))
	if line_t > 0.0 and line != "":
		var f2: = ThemeDB.fallback_font
		var sw: = f2.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		draw_rect(Rect2( - sw / 2.0 - 2.0, -24, sw + 4.0, 9), Color(1, 1, 1, 0.9))
		draw_string(f2, Vector2( - sw / 2.0, -17), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("#222222"))
