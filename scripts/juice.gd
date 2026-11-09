extends Node
## Combat feel (M3, Nov 8): hit-stop, screen shake, impact sparks. Child of main ("Juice").
## Hit-stop slows Engine.time_scale for a few real-time milliseconds; shake drives main.cam.offset.
## Tuning lives in the consts below; combat.hit() and main.hurt_player() call in here.

const STOP_SCALE: = 0.05
# [hit-stop seconds, shake px, sparks]
const LIGHT: = [0.07, 1.2, 5]
const HEAVY: = [0.085, 2.6, 9]
const KILL: = [0.12, 3.6, 12]
const HURT: = [0.07, 3.2, 0]
const SHAKE_DECAY: = 7.0      # trauma lost per real second

var m: Node
var fx: Node
var _stop_until_us: = 0
var _trauma: = 0.0
var _shake_px: = 0.0
var _last_us: = 0
var enabled: = true
## Settings > Screen shake (accessibility, Nov 9). Saved as `screen_shake` in user://settings.json by audio.gd.
## Off = no camera shake / zoom punch; hit-stop and sparks stay.
static var shake_on: = true
var _base_zoom: = Vector2.ONE
var _shaking: = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_us = Time.get_ticks_usec()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

## A landed hit. heavy = finisher / crit / big number; kill = it died; boss adds a bit of weight.
func impact(pos: Vector2, dir: Vector2, heavy: bool, kill: bool, boss: bool) -> void:
	var p: Array = KILL if kill else (HEAVY if heavy else LIGHT)
	if fx:
		fx.sparks(pos + Vector2(0, -6), dir, int(p[2]), heavy or kill)
	if _quiet():
		return
	hitstop(float(p[0]) + (0.02 if boss else 0.0))
	shake(float(p[1]) * (1.25 if boss else 1.0))

## No freeze/shake during scripted moments (86 finisher cinematic, pause menus).
func _quiet() -> bool:
	return get_tree().paused or (m != null and m.get("combat") != null and bool(m.combat.cinematic))

func hurt() -> void:
	if _quiet():
		return
	hitstop(float(HURT[0]))
	shake(float(HURT[1]))

func hitstop(sec: float) -> void:
	if not enabled or sec <= 0.0:
		return
	var until: = Time.get_ticks_usec() + int(sec * 1000000.0)
	_stop_until_us = maxi(_stop_until_us, until)
	Engine.time_scale = STOP_SCALE

func shake(px: float) -> void:
	if not enabled or not shake_on:
		return
	_shake_px = maxf(_shake_px * _trauma, px)
	_trauma = 1.0

func _process(_d: float) -> void:
	var now: = Time.get_ticks_usec()
	var real: = float(now - _last_us) / 1000000.0
	_last_us = now
	if _stop_until_us > 0 and now >= _stop_until_us:
		_stop_until_us = 0
		Engine.time_scale = 1.0
	_trauma = maxf(0.0, _trauma - SHAKE_DECAY * real)   # wears off even while paused
	if m == null or m.cam == null:
		return
	var cam: Camera2D = m.cam
	if not _shaking:
		_base_zoom = cam.zoom
	if _trauma > 0.0 and not get_tree().paused:
		_shaking = true
		var a: = _shake_px * _trauma * _trauma
		cam.offset = _clamp_to_limits(cam, Vector2(randf_range(-a, a), randf_range(-a, a)).round())
		# a little zoom punch too, so a camera pinned at its limits (arena) still kicks
		cam.zoom = _base_zoom * (1.0 + 0.012 * a)
	elif _shaking:
		_shaking = false
		cam.offset = Vector2.ZERO
		cam.zoom = _base_zoom

## Camera offset ignores limits, so keep the shaken view inside them (no void past the arena).
func _clamp_to_limits(cam: Camera2D, off: Vector2) -> Vector2:
	var half: = get_viewport().get_visible_rect().size / (2.0 * _base_zoom)
	var c: = cam.global_position
	var cx: = clampf(c.x, cam.limit_left + half.x, cam.limit_right - half.x)
	var cy: = clampf(c.y, cam.limit_top + half.y, cam.limit_bottom - half.y)
	var lo: = Vector2(cam.limit_left + half.x - cx, cam.limit_top + half.y - cy)
	var hi: = Vector2(cam.limit_right - half.x - cx, cam.limit_bottom - half.y - cy)
	return Vector2(clampf(off.x, minf(lo.x, 0.0), maxf(hi.x, 0.0)), clampf(off.y, minf(lo.y, 0.0), maxf(hi.y, 0.0)))
