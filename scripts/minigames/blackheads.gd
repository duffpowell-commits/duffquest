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

const SKIN: = Color("#e9b994")
const SLEEVE_INK: = [Color("#2a7f86"), Color("#c0443c"), Color("#1e1a24")]

## One tattooed arm hanging at Duff's side: skin prop + sleeve swirls (both sleeves, always: duff_look.md).
func _arm(x: float, flip: float) -> void:
	var r: = Rect2(x, 46, 18, 76)
	prop(r, SKIN, 0.2)
	for k in 5:
		var c: = Vector2(r.position.x + 9 + flip * (k % 2) * 3, 54 + k * 14)
		draw_arc(c, 5.0, 0.2 * k, 0.2 * k + PI * 1.3, 10, SLEEVE_INK[k % 3], 1.6)
		draw_circle(c + Vector2(-flip * 3, 4), 1.4, SLEEVE_INK[(k + 1) % 3])
	draw_rect(r, UiStyle.PROP_INK, false, 1.3)

func _draw_game() -> void:
	_arm(50, 1.0)
	_arm(252, -1.0)
	# Duff's back: neck, shoulder slope, one cel band down the lower back, ink outline
	var back: = PackedVector2Array([Vector2(148, 14), Vector2(172, 14), Vector2(178, 28), Vector2(236, 34),
		Vector2(252, 46), Vector2(246, 122), Vector2(74, 122), Vector2(68, 46), Vector2(84, 34), Vector2(142, 28)])
	var shadow: = PackedVector2Array()
	for v in back:
		shadow.append(v + Vector2(1.5, 1.5))
	draw_colored_polygon(shadow, Color(UiStyle.PROP_INK, 0.55))
	draw_colored_polygon(back, SKIN)
	draw_colored_polygon(PackedVector2Array([Vector2(72, 100), Vector2(248, 100), Vector2(246, 122), Vector2(74, 122)]),
		SKIN.darkened(0.18))
	draw_arc(Vector2(118, 60), 20.0, -PI * 0.3, PI * 0.3, 10, SKIN.darkened(0.25), 1.2)      # shoulder blades: ) (
	draw_arc(Vector2(202, 60), 20.0, PI * 0.7, PI * 1.3, 10, SKIN.darkened(0.25), 1.2)
	draw_line(Vector2(160, 32), Vector2(160, 118), SKIN.darkened(0.2), 1.4)                  # spine
	var outline: = back.duplicate()
	outline.append(back[0])
	draw_polyline(outline, UiStyle.PROP_INK, 1.4)
	# the fox on his neck, peeking over the collar line
	var f: = Vector2(160, 22)
	draw_colored_polygon(PackedVector2Array([f + Vector2(-6, -3), f + Vector2(-3, -8), f + Vector2(0, -4),
		f + Vector2(3, -8), f + Vector2(6, -3), f + Vector2(0, 4)]), Color("#e07a2a"))
	draw_colored_polygon(PackedVector2Array([f + Vector2(-3, 0), f + Vector2(3, 0), f + Vector2(0, 4)]), UiStyle.CREAM)
	draw_polyline(PackedVector2Array([f + Vector2(-6, -3), f + Vector2(-3, -8), f + Vector2(0, -4), f + Vector2(3, -8),
		f + Vector2(6, -3), f + Vector2(0, 4), f + Vector2(-6, -3)]), UiStyle.PROP_INK, 1.0)
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
