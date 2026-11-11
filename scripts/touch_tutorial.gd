extends Node2D
## Three tap-through cards that teach the phone controls (IGN review v2, Nov 10): walk, A, B.
## Child of touch_controls.gd, so it shares its 320x180 coordinates and can point at the real buttons.
## Shown once per install on a touch device when a new game starts (remembered in user://touch_tut.cfg);
## replayable from the title's "How to play". While it's up, main.busy() is true, so the world waits.
## Tap anywhere for the next card, SKIP (top-right) to bail. Any key or click also advances (desktop/tests).

const UiStyle: = preload("res://scripts/ui_style.gd")
const Cast: = preload("res://scripts/cast.gd")
const TouchScript: = preload("res://scripts/touch_controls.gd")
const CFG: = "user://touch_tut.cfg"
const W: = 320.0
const H: = 180.0
const SKIP: = Rect2(278, 4, 38, 14)

## [title, body, focus] -- focus: "joy" | "a" | "b"
const CARDS: = [
	["WALK", "Thumb down anywhere on the left half and drag. That's legs. I go where the thumb goes.", "joy"],
	["A DOES THE THING", "Talk, open doors, use stuff, read the next line. Nobody in reach? It swings. That's a bonk.", "a"],
	["B GETS ME OUT", "Roll out of a punch, a Karen, a bad decision. G, S and D show up once I've earned them.", "b"],
]

signal done

var card: = -1
var t: = 0.0

static func seen() -> bool:
	var c: = ConfigFile.new()
	return c.load(CFG) == OK and bool(c.get_value("tut", "seen", false))

static func mark_seen() -> void:
	var c: = ConfigFile.new()
	c.load(CFG)
	c.set_value("tut", "seen", true)
	c.save(CFG)

func start() -> void:
	card = 0
	t = 0.0
	visible = true
	z_index = 100
	queue_redraw()

func active() -> bool:
	return card >= 0

func next() -> void:
	if card < 0:
		return
	card += 1
	t = 0.0
	if card >= CARDS.size():
		finish()
	queue_redraw()

func finish() -> void:
	card = -1
	visible = false
	mark_seen()
	done.emit()

func _process(d: float) -> void:
	if card >= 0:
		t += d
		queue_redraw()

func _input(e: InputEvent) -> void:
	if card < 0:
		return
	var pos: = Vector2(-1, -1)
	var press: = false
	if e is InputEventScreenTouch and e.pressed:
		press = true
		pos = get_canvas_transform().affine_inverse() * e.position
	elif e is InputEventMouseButton and e.pressed:
		press = true
		pos = get_canvas_transform().affine_inverse() * e.position
	elif e is InputEventKey and e.pressed and not e.echo:
		press = true
	if not press:
		return
	get_viewport().set_input_as_handled()
	if t < 0.25:   # swallow the tap that opened it
		return
	if SKIP.has_point(pos):
		finish()
	else:
		next()

func _focus_point(f: String) -> Vector2:
	match f:
		"joy": return TouchScript.JOY_HOME
		"a": return TouchScript.BTN_A
		_: return TouchScript.BTN_B

func _draw() -> void:
	if card < 0:
		return
	var c: Array = CARDS[card]
	var fp: = _focus_point(str(c[2]))
	var fr: = 30.0 if c[2] == "joy" else 16.0
	# Dim everything except a soft hole around the control being taught.
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.62))
	var pulse: = 1.0 + 0.08 * sin(t * 6.0)
	draw_circle(fp, fr * pulse, Color(1, 0.95, 0.8, 0.10))
	draw_arc(fp, fr * pulse, 0, TAU, 40, Color("#f2c14e"), 1.5)
	if c[2] == "joy":
		# a ghost thumb sliding right and back
		var k: = fp + Vector2(sin(t * 2.5) * 14.0, 0)
		draw_circle(fp, TouchScript.JOY_R, Color(0.94, 0.89, 0.77, 0.18))
		draw_circle(k, 8, Color(0.94, 0.89, 0.77, 0.75))
	else:
		UiStyle.round_button(self, fp, TouchScript.BTN_R, Color("#4e7a3a") if c[2] == "a" else Color("#a43a2c"), "A" if c[2] == "a" else "B", 1.0)
	# Card on the side away from the control.
	var cw: = 170.0
	var cx: = 150.0 if c[2] == "joy" else 14.0
	var box: = Rect2(cx, 34, cw, 86)
	UiStyle.panel(self, box, UiStyle.PANEL, 0.97, 1.0)
	draw_rect(box, Color("#f2c14e"), false, 1.0)
	var f: = ThemeDB.fallback_font
	draw_string(f, box.position + Vector2(8, 15), str(c[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#f2c14e"))
	draw_multiline_string(f, box.position + Vector2(8, 30), Cast.T(str(c[1])), HORIZONTAL_ALIGNMENT_LEFT, cw - 16, 8, -1, UiStyle.CREAM)
	draw_string(f, box.position + Vector2(8, box.size.y - 7), "%d / %d   tap to continue" % [card + 1, CARDS.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.95, 0.85, 0.75))
	# SKIP
	draw_rect(SKIP, Color(0, 0, 0, 0.55))
	draw_rect(SKIP, Color(1, 0.95, 0.85, 0.6), false, 1.0)
	draw_string(f, SKIP.position + Vector2(0, 10), "SKIP", HORIZONTAL_ALIGNMENT_CENTER, SKIP.size.x, 8, UiStyle.CREAM)
