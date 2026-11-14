extends "res://scripts/minigames/minigame.gd"

const PITCH: = [
	"So! Are you the CEO of this household?",
	"Just sign here. And here. And here. And... here.",
	"Let me grab my upline. He's in the van.",
	"Your neighbors are already passive-income kings!",
	"Is this a bad time? Great, I'll be quick.",
	"Steak-of-the-Month. It's vegan. Don't ask.",
	"Quit your job! Starter kit's just $900!",
]
const NEED: = 14

var presses: = 0
var pitch_i: = 0
var pitch_t: = 0.0

func _setup() -> void:
	title = "DOOR-TO-DOOR HUSTLER"
	time_limit = 6.0
	space_is_pen = false
	var nope: = add_button("mash", Rect2(40, 110, 240, 50), "NOPE! (mash it)", KEY_SPACE, Color("#a43a2c"))
	if Art.tex("kf_door") != null:
		nope["icon"] = "kf_door"

func _on_button(_id: String) -> void:
	_press()

func _key(_k: InputEventKey) -> void:
	_press()

func _pointer_down(_p: Vector2) -> void:
	_press()

func _press() -> void:
	if done:
		return
	presses += 1
	if presses >= NEED:
		finish(1.0, "escaped")

func _tick(delta: float) -> void:
	show_cursor = false
	pitch_t += delta
	if pitch_t > 1.1:
		pitch_t = 0.0
		pitch_i = (pitch_i + 1) % PITCH.size()

func debug_solve(good: bool) -> void:
	if good:
		for i in NEED:
			_press()
	else:
		finish(0.0, "trapped")

func _draw_game() -> void:

	draw_set_transform(Vector2(40, 82), 0.0, Vector2(3, 3))
	Art.frame(self, "ch_hustler", Vector2.ZERO, 3 if pitch_i % 2 == 1 else 0, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# my front door swings shut on him, one mash at a time (hinge on the left of the frame)
	var dt: = Art.tex("kf_door")
	if dt != null:
		var shut: = clampf(float(presses) / NEED, 0.0, 1.0)
		prop(Rect2(4, 10, 6, 74), Color("#4a2e22"), 0.2)
		prop(Rect2(74, 10, 6, 74), Color("#4a2e22"), 0.2)
		if shut > 0.02:
			draw_texture_rect(dt, Rect2(10, 12, 64 * shut, 72), false)
			draw_rect(Rect2(10 + 64 * shut - 2, 12, 2, 72), Color(UiStyle.INK, 0.6))
	prop(Rect2(72, 22, 236, 46), Color("#fff1d6"), 0.0)
	mtxt(Vector2(78, 36), PITCH[pitch_i], 224, 9, Color("#2b2218"), 3)
	bar(Rect2(40, 84, 240, 10), float(presses) / NEED, Color("#c0d890"))
	txt(Vector2(40, 104), "Escape: %d / %d" % [presses, NEED], 8, Color.WHITE)
