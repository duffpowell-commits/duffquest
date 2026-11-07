extends "res://scripts/minigames/minigame.gd"

const COUNT: = 8
const LINES: = ["POP! That one had a mortgage.", "{partner}: OHHH that's a good one.", "*squelch* It hits the mirror.", "{partner}: Hold STILL.", "That one was older than {baby}.", "{partner} makes the happiest noise I've ever heard.", "POP! I felt that in my soul.", "{partner}: I could do this all day."]

var heads: Array = []
var popped: = 0
var say: = ""

func _setup() -> void:
	backdrop = "bedroom"
	backdrop_dim = 0.45
	title = "BLACKHEAD PATROL  (tap them all)"
	time_limit = 12.0
	space_is_pen = true
	var rng: = RandomNumberGenerator.new()
	rng.seed = int(ctx.get("seed", 7))
	for i in COUNT:
		heads.append([Vector2(rng.randf_range(90, 230), rng.randf_range(34, 112)), false, 0.0])
	add_button("quit", Rect2(262, 154, 54, 22), "Done", KEY_ESCAPE, Color("#a43a2c"))
	say = "So {partner} snaps on imaginary gloves. \"Turn around. Into the light.\""

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

func _draw_game() -> void:
	draw_rect(Rect2(70, 24, 180, 98), Color("#f2d2b4"))
	draw_rect(Rect2(70, 24, 180, 98), Color("#c29a6a"), false, 2.0)
	draw_line(Vector2(160, 26), Vector2(160, 120), Color("#d8a868"), 2.0)
	for h in heads:
		var p: Vector2 = h[0]
		if not h[1]:
			draw_circle(p, 2.5, Color("#2a1a10"))
			draw_circle(p, 4.0, Color(0.85, 0.5, 0.4, 0.35))
		elif float(h[2]) > 0.0:
			var s: = 1.0 - float(h[2]) / 0.6
			draw_circle(p + Vector2(0, -6 * s), 2.0, Color("#f8f0c0"))
			draw_string(font, p + Vector2(4, -6), "POP", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#ffffff"))
		else:
			draw_circle(p, 2.0, Color(0.9, 0.55, 0.45, 0.6))
	txt(Vector2(6, 22), "Popped: %d/%d" % [popped, COUNT], 7, Color("#f2c66a"))
	draw_rect(Rect2(6, 124, 250, 26), Color(0.1, 0.08, 0.15, 0.92))
	mtxt(Vector2(10, 134), say, 244, 7, Color.WHITE, 2)
