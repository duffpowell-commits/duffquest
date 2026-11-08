extends Node
## Combat feel (M3, Nov 8): hit-stop, screen shake, impact sparks. Child of main ("Juice").
## Hit-stop slows Engine.time_scale for a few real-time milliseconds; shake drives main.cam.offset.
## Tuning lives in the consts below; combat.hit() and main.hurt_player() call in here.

const STOP_SCALE: = 0.05
# [hit-stop seconds, shake px, sparks]
const LIGHT: = [0.045, 1.2, 5]
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_us = Time.get_ticks_usec()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

## A landed hit. heavy = finisher / crit / big number; kill = it died; boss adds a bit of weight.
func impact(pos: Vector2, dir: Vector2, heavy: bool, kill: bool, boss: bool) -> void:
	var p: Array = KILL if kill else (HEAVY if heavy else LIGHT)
	hitstop(float(p[0]) + (0.02 if boss else 0.0))
	shake(float(p[1]) * (1.25 if boss else 1.0))
	if fx:
		fx.sparks(pos + Vector2(0, -6), dir, int(p[2]), heavy or kill)

func hurt() -> void:
	hitstop(float(HURT[0]))
	shake(float(HURT[1]))

func hitstop(sec: float) -> void:
	if not enabled or sec <= 0.0:
		return
	var until: = Time.get_ticks_usec() + int(sec * 1000000.0)
	_stop_until_us = maxi(_stop_until_us, until)
	Engine.time_scale = STOP_SCALE

func shake(px: float) -> void:
	if not enabled:
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
	if m == null or m.cam == null:
		return
	if _trauma > 0.0 and not get_tree().paused:
		_trauma = maxf(0.0, _trauma - SHAKE_DECAY * real)
		var a: = _shake_px * _trauma * _trauma
		m.cam.offset = Vector2(randf_range(-a, a), randf_range(-a, a)).round()
	elif m.cam.offset != Vector2.ZERO:
		m.cam.offset = Vector2.ZERO
