extends Node
## Phone performance guard (presentation only, never touches gameplay).
## - Watches the frame rate. If a phone can't hold ~40 fps for a few seconds of real play, it turns
##   on "lite graphics": the HD-2D screen shader (bloom/vignette/far blur) and the soft window
##   lights go off. The pixel art itself is unchanged. The choice is remembered (user://perf.cfg).
## - Web builds: publishes window.dq = {state, loc, px, py, fps, low} twice a second so
##   tools/web_boot_check.py can follow the game from headless Chrome. URL hash "#lite" forces lite.
const CFG: = "user://perf.cfg"
const LOW_FPS: = 40.0           # sustained average below this -> lite
const WINDOW: = 3.0             # seconds per sample window
const BAD_WINDOWS: = 2          # this many bad windows in a row trips it
const GRACE: = 4.0              # ignore the first seconds after boot / a scene change (loading hitches)

var main: Node
var low: = false
var auto: = true                # false once the player picks a setting by hand
var _acc: = 0.0
var _frames: = 0
var _bad: = 0
var _grace: = GRACE
var _pub: = 0.0
var _was_busy: = true
var _web: = OS.has_feature("web")
# Auto-switching only on the devices it is for. Desktop/xvfb tool runs are slow on purpose
# (software GL) and must never flip renders to lite.
var _can_auto: = OS.has_feature("web") or OS.has_feature("mobile")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var c: = ConfigFile.new()
	if c.load(CFG) == OK:
		auto = bool(c.get_value("gfx", "auto", true))
		low = bool(c.get_value("gfx", "low", false))
	if _web and str(JavaScriptBridge.eval("window.location.hash")).contains("lite"):
		low = true
		auto = false
	call_deferred("_apply")

func _hd() -> Node:
	return main.get_node_or_null("HD2DPresentation") if main else null

func _apply() -> void:
	var hd: = _hd()
	if hd and hd.has_method("set_low"):
		hd.set_low(low)

func _save() -> void:
	var c: = ConfigFile.new()
	c.set_value("gfx", "auto", auto)
	c.set_value("gfx", "low", low)
	c.save(CFG)

## Settings toggle / tools: pick lite (true) or full (false) by hand; turns the auto switch off.
func force_low(on: bool, remember: bool = false) -> void:
	low = on
	_apply()
	if remember:
		auto = false
		_save()

func _process(d: float) -> void:
	if _web:
		_pub -= d
		if _pub <= 0.0:
			_pub = 0.5
			_publish()
	if not _can_auto or not auto or low or main == null:
		return
	# Only judge real play: menus, loading screens and cutscenes hitch on texture loads.
	var b: bool = main.busy()
	if b or b != _was_busy:
		_was_busy = b
		_grace = GRACE
		_acc = 0.0
		_frames = 0
		return
	if _grace > 0.0:
		_grace -= d
		return
	_acc += d
	_frames += 1
	if _acc >= WINDOW:
		var fps: = _frames / _acc
		_bad = _bad + 1 if fps < LOW_FPS else 0
		_acc = 0.0
		_frames = 0
		if _bad >= BAD_WINDOWS:
			low = true
			_apply()
			_save()
			print("perf_guard: avg %.0f fps, lite graphics on" % fps)

func state() -> String:
	if main == null:
		return "boot"
	if main.in_title:
		return "title"
	if main.busy():
		return "busy"
	if not (main.dialog as Array).is_empty():
		return "dialog"
	return "play"

func _publish() -> void:
	var p: Vector2 = main.player.position if main and main.player else Vector2.ZERO
	var xf: = get_window().get_final_transform() if get_window() else Transform2D.IDENTITY
	JavaScriptBridge.eval("window.dq=%s" % JSON.stringify({
		"state": state(), "loc": str(main.location) if main else "", "px": p.x, "py": p.y,
		"fps": Engine.get_frames_per_second(), "low": low,
		"win": [get_window().size.x, get_window().size.y], "xf": [xf.x.x, xf.origin.x, xf.origin.y]}), true)
