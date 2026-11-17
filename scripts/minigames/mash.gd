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
	pill_buttons = true
	var nope: = add_button("mash", Rect2(112, 128, 200, 40), "NOPE! (mash it)", KEY_SPACE, Color("#a43a2c"))
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

## Nov 17: my front doorway (painted door swinging shut on its hinge), the hustler on the step, his pitch in a
## speech bubble pointing at him, and how shut the door is as a pill gauge. Scene behind = the blurred street.
func _draw_game() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.03, 0.02, 0.06, 0.35))
	var dr: = Rect2(14, 22, 84, 150)                     # doorway: dark hall, wood frame, threshold
	UiStyle.box(self, dr.grow(5), Color("#3a2418"), 3.0)
	UiStyle.box(self, dr.grow(3.5), Color("#6b4430"), 2.5)
	draw_rect(dr, Color("#1a1218"))
	draw_rect(Rect2(dr.position.x, dr.position.y, dr.size.x, 10), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(dr.position.x - 6, dr.end.y - 2, dr.size.x + 12, 4), Color("#8a6a4a"))
	draw_set_transform(Vector2(dr.get_center().x, dr.end.y - 2), 0.0, Vector2(4.4, 4.4))
	Art.frame(self, "ch_hustler", Vector2.ZERO, 3 if pitch_i % 2 == 1 else 0, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var shut: = clampf(float(presses) / NEED, 0.0, 1.0)
	var dt: = Art.tex("kf_door")
	if shut > 0.02:                                       # the door swings in from the left hinge
		var drect: = Rect2(dr.position.x, dr.position.y, dr.size.x * shut, dr.size.y)
		if dt != null:
			draw_texture_rect(dt, drect, false)
		else:
			draw_rect(drect, Color("#7a4a30"))
		draw_rect(Rect2(drect.end.x - 2.5, drect.position.y, 2.5, drect.size.y), Color(0, 0, 0, 0.45))
	# speech bubble, tail toward his head
	var bub: = Rect2(112, 24, 200, 54)
	draw_colored_polygon(PackedVector2Array([Vector2(bub.position.x + 2, bub.position.y + 30), Vector2(bub.position.x + 2, bub.position.y + 44), Vector2(dr.end.x - 8, 74)]), Color("#1e1220"))
	UiStyle.box(self, bub.grow(1.2), Color("#1e1220"), 9.0)
	UiStyle.box(self, bub, Color("#fff8ec"), 8.0)
	draw_colored_polygon(PackedVector2Array([Vector2(bub.position.x + 3, bub.position.y + 32), Vector2(bub.position.x + 3, bub.position.y + 42), Vector2(dr.end.x - 5, 73)]), Color("#fff8ec"))
	mtxt(Vector2(bub.position.x + 9, bub.position.y + 17), PITCH[pitch_i], bub.size.x - 18, 9, Color("#2b2218"), 3)
	# door gauge
	var g: = Rect2(112, 96, 200, 9)
	UiStyle.box(self, g, Color(0, 0, 0, 0.55), 4.5)
	UiStyle.box(self, Rect2(g.position, Vector2(maxf(g.size.x * shut, 9.0), g.size.y)), Color("#34c759"), 4.5)
	txt(Vector2(112, 117), "Door shut: %d / %d" % [presses, NEED], 8, Color.WHITE)

## First-time how-to card (minigame.gd coach).
func howto() -> Array:
	return [
		{"i": "kf_door", "v": "mash", "s": "Mash NOPE as fast as you can before he gets you."}]
