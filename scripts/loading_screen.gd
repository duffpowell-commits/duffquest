extends Node2D
## Loading screens: a random funny scene + Duff's caption, full screen at real resolution (game.gd's
## top layer). main.show_loading() raises main.loading_req; while one is up main.loading_on makes
## main busy() (world frozen). Holds HOLD seconds, tap to dismiss after MIN_T. Art: assets/art/loading/
## <id>.jpg, captions: data/loading_screens.json. Never repeats the last few.
const Cast: = preload("res://scripts/cast.gd")

const HOLD: = 3.2
const MIN_T: = 0.5
const FADE: = 0.25
var main: Node
var screens: Array = []
var _seen_req: = 0
var _cur: = {}
var _tex: Texture2D
var _t: = -1.0
var _recent: Array = []

func _ready() -> void:
	add_to_group("extra_pack")
	_scan()

## Web: most loading screens arrive with the extra pack (scripts/extra_pack.gd); look again then.
func extra_pack_loaded() -> void:
	_scan()

func _scan() -> void:
	screens.clear()
	var f: = FileAccess.open("res://data/loading_screens.json", FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			for s in d.get("screens", []):
				if ResourceLoader.exists("res://assets/art/loading/%s.jpg" % s["id"]):
					screens.append(s)

func _pick() -> void:
	if screens.is_empty():
		return
	var pool: = screens.filter(func(s): return not _recent.has(s["id"]))
	if pool.is_empty():
		pool = screens
	_cur = pool[randi() % pool.size()]
	_recent.append(_cur["id"])
	if _recent.size() > mini(5, screens.size() - 1):
		_recent.pop_front()
	_tex = load("res://assets/art/loading/%s.jpg" % _cur["id"])
	_t = 0.0

func _finish() -> void:
	_t = -1.0
	if main and main.has_method("loading_done"):
		main.loading_done()

func _input(e: InputEvent) -> void:
	if _t < 0.0:
		return
	var press: bool = (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed) \
		or (e is InputEventKey and e.pressed and not e.echo)
	if press:
		get_viewport().set_input_as_handled()
		if _t > MIN_T:
			_t = maxf(_t, HOLD - FADE)

func _process(d: float) -> void:
	if main and int(main.loading_req) != _seen_req:
		_seen_req = int(main.loading_req)
		if screens.is_empty():
			main.loading_done()
		else:
			_pick()
	if _t >= 0.0:
		_t += d
		if _t >= HOLD:
			_finish()
	queue_redraw()

## True while the dark backing rect is fully opaque (game.gd then stops rendering the world under it).
func covers_screen() -> bool:
	return _t >= 0.0 and _tex != null and minf(_t / FADE, (HOLD - _t) / FADE) >= 0.5

func _draw() -> void:
	if _t < 0.0 or _tex == null:
		return
	var vp: = get_viewport_rect().size
	var a: = clampf(minf(_t / FADE, (HOLD - _t) / FADE), 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.03, 0.02, 0.04, minf(1.0, a * 2.0)))
	# cover-fit the 16:9 art with a slow push-in
	var ts: = _tex.get_size()
	var s: = maxf(vp.x / ts.x, vp.y / ts.y) * (1.0 + _t * 0.012)
	var sz: = ts * s
	draw_texture_rect(_tex, Rect2((vp - sz) * 0.5, sz), false, Color(1, 1, 1, a))
	var f: = ThemeDB.fallback_font
	var size: = int(vp.y * 0.04)
	var cap: = Cast.T(str(_cur.get("caption", "")))
	var band: = Rect2(0, vp.y * 0.83, vp.x, vp.y * 0.17)
	draw_rect(band, Color(0.03, 0.02, 0.04, 0.82 * a))
	draw_line(band.position, Vector2(vp.x, band.position.y), Color(0.25, 0.88, 0.82, a), 2.0)
	draw_multiline_string(f, Vector2(vp.x * 0.05, band.position.y + size * 1.4), cap, HORIZONTAL_ALIGNMENT_LEFT,
		vp.x * 0.9, size, 3, Color(0.96, 0.93, 0.88, a))
