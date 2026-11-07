extends CharacterBody2D

signal attacked(pos: Vector2, dir: Vector2)

const SPEED: = 70.0
const ROLL_TIME: = 0.32
const ROLL_SPEED: = 175.0
const IFRAMES: = 0.8

var facing: = Vector2.DOWN
var frozen: = false
var joy_vec: = Vector2.ZERO
var swing_t: = 0.0
var swing_cd: = 0.25
var hurt_t: = 0.0
var iframe_len: = IFRAMES
var carrying: = false
var speed_mult: = 1.0
var roll_t: = 0.0
var roll_cd: = 0.0
var roll_cd_len: = 0.7
var roll_dir: = Vector2.DOWN
var knock: = Vector2.ZERO
var stun_t: = 0.0
var weapon_id: = "spatula"
var armor_id: = "apron"
const Art: = preload("res://scripts/art.gd")
const AudioScript: = preload("res://scripts/audio.gd")
const ARMORS: = ["apron", "clogs", "sleeves", "coat", "dad"]
var shoes: = "red"
var anim_t: = 0.0
var moving: = false

var combo_step: = 0
var combo_len: = 3
var _last_swing_ms: = -10000
const COMBO_WINDOW_MS: = 600
var demon: = false
var charge: = 0.0
var counter_pose: = 0.0
var eating: = 0.0
var eighty_six: = 0.0
var dash_t: = 0.0
var buffered: = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs: = CollisionShape2D.new()
	var r: = RectangleShape2D.new()
	r.size = Vector2(10, 6)
	cs.shape = r
	cs.position = Vector2(0, 7)
	add_child(cs)

func _physics_process(delta: float) -> void:
	var v: = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v == Vector2.ZERO:
		v = joy_vec
	if frozen:
		v = Vector2.ZERO
		roll_t = 0.0
	if stun_t > 0.0:
		stun_t -= delta
		v = Vector2.ZERO
	if v.length() > 0.15:
		facing = v.normalized()
	if roll_t > 0.0:
		roll_t -= delta
		velocity = roll_dir * ROLL_SPEED
	else:
		velocity = v.limit_length(1.0) * SPEED * speed_mult
	velocity += knock
	knock = knock.move_toward(Vector2.ZERO, 600.0 * delta)
	move_and_slide()
	anim_t += delta
	moving = velocity.length() > 5.0
	swing_t = maxf(0.0, swing_t - delta)
	if buffered and swing_t <= 0.0:
		swing()
	counter_pose = maxf(0.0, counter_pose - delta)
	eating = maxf(0.0, eating - delta)
	eighty_six = maxf(0.0, eighty_six - delta)
	dash_t = maxf(0.0, dash_t - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	roll_cd = maxf(0.0, roll_cd - delta)
	queue_redraw()

func swing() -> void:
	if swing_t > 0.0 and not frozen:
		buffered = true
		return
	if frozen or stun_t > 0.0 or swing_t > 0.0 or roll_t > 0.0:
		return
	buffered = false
	var now: = Time.get_ticks_msec()
	combo_step = (combo_step + 1) % combo_len if now - _last_swing_ms < COMBO_WINDOW_MS + int(swing_cd * 1000.0) else 0
	_last_swing_ms = now
	var finisher: = combo_step == combo_len - 1
	swing_t = swing_cd * (1.8 if finisher else 1.0)
	AudioScript.sfx("swing", 0.8 if finisher else 1.0 + 0.08 * combo_step)
	attacked.emit(global_position + facing * 12.0, facing)

func is_finisher() -> bool:
	return combo_step == combo_len - 1

func roll() -> bool:
	if frozen or stun_t > 0.0 or roll_t > 0.0 or roll_cd > 0.0:
		return false
	var v: = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v == Vector2.ZERO:
		v = joy_vec
	roll_dir = v.normalized() if v.length() > 0.15 else facing
	roll_t = ROLL_TIME
	roll_cd = roll_cd_len + ROLL_TIME
	AudioScript.sfx("roll")
	return true

func rolling() -> bool:
	return roll_t > 0.0

func invulnerable() -> bool:
	return roll_t > 0.0 or hurt_t > 0.0 or dash_t > 0.0

func take_knock(from: Vector2, force: float) -> void:
	var d: = global_position - from
	knock = (d.normalized() if d.length() > 0.01 else -facing) * force

func hurt() -> void:
	hurt_t = iframe_len
	AudioScript.sfx("hurt")

var at_home: = false
var shades: = false

func sheet_name() -> String:
	if at_home and shoes != "black" and armor_id != "dad":
		return "duff_home"
	return "duff_%s_%s" % [armor_id if ARMORS.has(armor_id) else "apron", shoes if shoes == "black" else "red"]

func _draw() -> void:
	var flash: = hurt_t > 0.0 and int(hurt_t * 20.0) % 2 == 0
	var mod: = Color(1, 0.55, 0.55, 0.75) if flash else Color.WHITE
	if roll_t > 0.0:

		Art.shadow(self, Vector2(0, 6), 5.0, 1.8)
		Art.frame(self, "duff_roll_" + (shoes if shoes == "black" else "red"), Vector2(0, 5), int(roll_t * 24.0) % 4, 0, mod)
		draw_arc(Vector2(0, 3), 9, roll_t * 30.0, roll_t * 30.0 + 2.0, 6, Color(1, 1, 1, 0.5), 1.0)
		return
	var tnow: = Time.get_ticks_msec() / 1000.0
	if demon:

		for i in 5:
			var ang: = tnow * 3.0 + i * TAU / 5.0
			draw_circle(Vector2(cos(ang) * 6.0, -2.0 + sin(ang) * 3.0), 3.5, Color(0.8, 0.1, 0.4, 0.18))
		mod = mod * Color(1.0, 0.82, 0.82)
	if charge > 0.0:
		var cr: = 6.0 + charge * 8.0 + sin(tnow * 30.0) * 1.0
		draw_circle(Vector2(0, -2), cr, Color(1.0, 0.6, 0.15, 0.12 + 0.18 * charge))
		draw_arc(Vector2(0, -2), cr, 0.0, TAU, 20, Color(1.0, 0.85, 0.4, 0.5 + 0.4 * charge), 1.0)
	if dash_t > 0.0:
		for i in 3:
			Art.person(self, sheet_name(), Vector2(0, 11) - facing.normalized() * (6.0 + i * 6.0), facing, anim_t, false, false, Color(0.7, 0.9, 1.0, 0.35 - i * 0.1), false)
	Art.person(self, sheet_name(), Vector2(0, 11), facing, anim_t, moving, swing_t > 0.0, mod)
	if demon:

		for i in 6:
			var fx: = -5.0 + i * 2.0
			var fh: = 4.0 + 3.0 * absf(sin(tnow * 9.0 + i * 1.7))
			draw_line(Vector2(fx, -13.0), Vector2(fx + sin(tnow * 7.0 + i) * 1.2, -13.0 - fh), Color(1.0, 0.45 + 0.1 * (i % 2), 0.1, 0.85), 1.6)
		draw_circle(Vector2(2.5, -3.0), 1.6 + 0.5 * sin(tnow * 10.0), Color(1.0, 0.55, 0.15, 0.75))
	if counter_pose > 0.0:

		var cpos: = facing.normalized() * 8.0 + Vector2(0, -3)
		draw_circle(cpos, 5.0, Color("#3a3440"))
		draw_arc(cpos, 5.0, 0.0, TAU, 16, Color("#cfd6e6"), 1.0)
		draw_line(cpos, cpos - facing.normalized() * 6.0, Color("#6a4a30"), 1.5)
	if eating > 0.0:
		draw_circle(Vector2(0, 2), 5.0, Color.WHITE)
		draw_circle(Vector2(0, 2), 3.0, Color("#d08040"))
		if int(eating * 10.0) % 2 == 0:
			draw_string(ThemeDB.fallback_font, Vector2(4, -14), "nom", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.WHITE)
	if eighty_six > 0.0:

		var g: = 0.6 + 0.4 * sin(tnow * 8.0)
		draw_string(ThemeDB.fallback_font, Vector2(-6.5, 4), "86", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.25 * g + 0.2, 0.1, 1.0))
		draw_arc(Vector2(0, 0), 12.0 + 2.0 * g, 0.0, TAU, 24, Color(1.0, 0.4, 0.1, 0.35 * g), 1.5)
	if shades:
		Art.person(self, "duff_shades", Vector2(0, 11), facing, anim_t, moving, swing_t > 0.0, mod, false)
	if stun_t > 0.0:
		var st: = Time.get_ticks_msec() / 120.0
		for i in 3:
			draw_circle(Vector2(cos(st + i * 2.1) * 6.0, -13.0), 1.2, Color("#40a0ff"))
	if carrying:
		Art.image(self, "honeybun", Vector2(8, 4))
	if swing_t > 0.0:
		var a: = facing.angle()
		var col: Color = {"spatula": Color(1, 1, 1, 0.9), "skillet": Color("#555555"), "knife": Color("#dfe8f0"), "tenderizer": Color("#c0a080"), "flail": Color("#e0c040"), "cleaver": Color("#ff5050") }.get(weapon_id, Color.WHITE)
		if weapon_id == "flail":
			draw_arc(Vector2.ZERO, 20.0, 0, TAU, 20, col, 2.0)
		else:
			var fin: = is_finisher()
			draw_arc(facing * 4.0, 16.0 if fin else 12.0 + combo_step * 1.5, a - (1.6 if fin else 1.1), a + (1.6 if fin else 1.1), 12, col, (3.0 if fin else 2.0) if weapon_id != "cleaver" else 3.0)
			if fin:
				draw_arc(facing * 4.0, 19.0, a - 1.2, a + 1.2, 12, Color(col.r, col.g, col.b, 0.45), 1.5)
