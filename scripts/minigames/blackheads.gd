extends "res://scripts/minigames/minigame.gd"

const COUNT: = 8
const LINES: = ["POP! That one had a mortgage.", "{partner}: OHHH that's a good one.", "*squelch* It hits the mirror.", "{partner}: Hold STILL.", "That one was older than {baby}.", "{partner} makes the happiest noise I've ever heard.", "POP! I felt that in my soul.", "{partner}: I could do this all day."]

var heads: Array = []
var popped: = 0
var say: = ""

func _setup() -> void:
	backdrop = "blackheads_back"
	title = "BLACKHEAD PATROL  (tap them all)"
	time_limit = 12.0
	space_is_pen = true
	var rng: = RandomNumberGenerator.new()
	rng.seed = int(ctx.get("seed", 7))
	for i in COUNT:
		heads.append([Vector2(rng.randf_range(112, 216), rng.randf_range(64, 116)), false, 0.0])
	add_button("quit", Rect2(262, 154, 54, 22), "Done", KEY_ESCAPE, Color("#a43a2c"))
	say = "{partner} snaps on imaginary gloves. \"Turn around. Into the light.\""

func score() -> float:
	return float(popped) / float(COUNT)

func pop_at(p: Vector2) -> bool:
	for h in heads:
		if not h[1] and (h[0] as Vector2).distance_to(p) < 8.0:
			h[1] = true
			h[2] = 0.6
			popped += 1
			say = LINES[popped % LINES.size()]
			if popped >= COUNT:
				finish(1.0)
			return true
	say = "I poke a freckle. {partner}: \"That's a freckle, babe.\""
	return false

func _pointer_down(p: Vector2) -> void:
	pop_at(p)

func _timeout() -> void:
	finish(score())

func _tick(d: float) -> void:
	for h in heads:
		h[2] = maxf(0.0, float(h[2]) - d)

func _on_button(id: String) -> void:
	if id == "quit":
		finish(score())

## Painted back (bg_blackheads_back: Duff from behind in the bedroom, both sleeves, fox on his neck), zoomed
## 1.78x on his shoulders (neck and fox still in frame); the bare back between the sleeves spans x 100-240, y 60-130.
const ZOOM_SRC: = Rect2(70, 40, 180, 101.25)

func _draw_backdrop() -> void:
	var tex: = Art.tex("bg_blackheads_back")
	if tex == null:
		super._draw_backdrop()
		return
	var k: = tex.get_width() / W
	draw_texture_rect_region(tex, Rect2(0, 0, W, H), Rect2(ZOOM_SRC.position * k, ZOOM_SRC.size * k))

func _draw_game() -> void:
	for h in heads:
		var p: Vector2 = h[0]
		if not h[1]:
			draw_circle(p, 4.5, Color("#d98a72", 0.55))
			draw_circle(p, 2.6, UiStyle.PROP_INK)
			draw_circle(p + Vector2(-0.8, -0.8), 0.8, Color(1, 1, 1, 0.5))
		elif float(h[2]) > 0.0:
			var k: = 1.0 - float(h[2]) / 0.6
			draw_circle(p + Vector2(0, -7 * k), 2.2, Color("#f8f0c0"))
			draw_circle(p, 3.0, Color("#e08a7a", 0.8))
			UiStyle.label(self, p + Vector2(4, -6 - 4 * k), "POP", 8, UiStyle.GOLD, -1.0, HORIZONTAL_ALIGNMENT_LEFT, 2)
		else:
			draw_circle(p, 2.4, Color("#e08a7a", 0.75))
	UiStyle.label(self, Vector2(6, 24), "Popped: %d/%d" % [popped, COUNT], 8, UiStyle.GOLD, -1.0, HORIZONTAL_ALIGNMENT_LEFT, 2)
	UiStyle.panel(self, Rect2(6, 124, 250, 26), UiStyle.PANEL, 0.94, 1.0 / 1.5)
	mtxt(Vector2(10, 134), say, 244, 7, Color.WHITE, 2)
