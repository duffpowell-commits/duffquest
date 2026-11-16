extends "res://scripts/minigames/minigame.gd"

const BAND: = Vector2(0.4, 0.8)
const DECAY: = 0.22
const SQUEEZE: = 0.16
const LIMIT: = 16.0
const FILL: = 0.11
const JOKES: = [
	"{phlebotomist}: \"Tiny pinch! Corporate calls it a 'liquidity event.'\"",
	"{phlebotomist}: \"Squeeze like you're mad at your landlord.\"",
	"{phlebotomist}: \"We sell this for 20x what we pay you. Anyway, juice box?\"",
	"{phlebotomist}: \"Join our loyalty program! Earn points by being bled!\"",
]

var flow: = 0.5
var bag: = 0.0
var in_band: = 0.0
var squeezes: = 0
var too_fast: = 0
var last_sq: = -9.0
var say: = ""

func _setup() -> void:
	backdrop = "plasma"
	title = "{PLASMA}"
	time_limit = LIMIT
	space_is_pen = false
	add_button("squeeze", Rect2(6, 154, 200, 22), "SQUEEZE  (Space)", KEY_SPACE, Color("#2e5aa8"))
	add_button("done", Rect2(262, 154, 54, 22), "Stop", KEY_ESCAPE, Color("#a43a2c"))
	say = JOKES[0]

func squeeze() -> void:
	squeezes += 1
	if t - last_sq < 0.25:
		too_fast += 1
		flow = minf(1.2, flow + SQUEEZE * 1.6)
		say = "{phlebotomist}: \"Easy, tiger. Steady. Shareholders are watching your vein.\""
	else:
		flow = minf(1.2, flow + SQUEEZE)
		if squeezes % 4 == 0:
			say = JOKES[(squeezes / 4) % JOKES.size()]
	last_sq = t

func score() -> float:
	return clampf(bag, 0.0, 1.0)

func _tick(d: float) -> void:
	flow = maxf(0.0, flow - DECAY * d)
	if flow >= BAND.x and flow <= BAND.y:
		in_band += d
		bag += FILL * d
	if bag >= 1.0 and not done:
		finish(1.0)

func _timeout() -> void:
	finish(score())

func _on_button(id: String) -> void:
	if id == "squeeze":
		squeeze()
	else:
		finish(score())

func _draw_game() -> void:

	var squish: = 1.0 - clampf(t - last_sq, 0.0, 0.2) * 1.5
	prop_circle(Vector2(46, 66), 6.0 * (0.7 + 0.3 * (1.0 - squish)), Color("#e6a640"))
	tag(Vector2(28, 82), "stress ball", 6)

	_draw_bag(Rect2(220, 30, 34, 60))
	tag(Vector2(220, 26), "YOUR BAG", 6)
	tag(Vector2(212, 100), "Bag %d%%" % int(bag * 100.0), 7)

	tag(Vector2(14, 104), "FLOW: keep the red line in the green to fill the bag", 6, Color("#c0d890"))
	tag(Vector2(28, 117), "FLOW", 7)
	prop(Rect2(60, 110, 150, 8), Color("#c0c0c8"))
	draw_rect(Rect2(60 + 150 * BAND.x / 1.2, 110, 150 * (BAND.y - BAND.x) / 1.2, 8), Color("#8ad08a"))
	draw_rect(Rect2(60 + 150 * clampf(flow / 1.2, 0.0, 1.0) - 1, 107, 3, 14), Color("#c03030"))
	draw_rect(Rect2(6, 124, 308, 26), Color(0.1, 0.08, 0.15, 0.92))
	mtxt(Vector2(10, 134), say, 300, 7, Color.WHITE, 2)


# Collection bag: a frosted plastic pouch with a hanger tab and a tube; the
# straw-coloured plasma rises inside it with a glossy meniscus.
func _draw_bag(r: Rect2) -> void:
	var ink: = Color("#2a2030")
	# hanger tab + tube out the bottom
	prop(Rect2(r.position.x + r.size.x * 0.5 - 5, r.position.y - 5, 10, 6), Color("#cfd6dc"))
	draw_line(r.position + Vector2(r.size.x * 0.5, r.size.y), r.position + Vector2(r.size.x * 0.5 - 14, r.size.y + 10), ink, 3.0)
	draw_line(r.position + Vector2(r.size.x * 0.5, r.size.y), r.position + Vector2(r.size.x * 0.5 - 14, r.size.y + 10), Color("#e0b850"), 1.5)
	# pouch body: frosted, slightly blue-grey, not paper white
	var body: = StyleBoxFlat.new()
	body.bg_color = Color("#b8c6d0", 0.55)
	body.set_corner_radius_all(6)
	body.border_color = ink
	body.set_border_width_all(1)
	draw_style_box(body, r)
	# plasma fill
	var h: = (r.size.y - 4) * clampf(bag, 0.0, 1.0)
	if h > 0.5:
		var fill: = StyleBoxFlat.new()
		fill.bg_color = Color("#f0c050")
		fill.set_corner_radius_all(4)
		fill.corner_radius_top_left = 2 if h > 6 else 4
		fill.corner_radius_top_right = fill.corner_radius_top_left
		var fr: = Rect2(r.position.x + 2, r.position.y + r.size.y - 2 - h, r.size.x - 4, h)
		draw_style_box(fill, fr)
		draw_rect(Rect2(fr.position.x + 1, fr.position.y, fr.size.x - 2, 1), Color("#fff0b0"))
	# seal line, graduation ticks, plastic shine
	draw_line(r.position + Vector2(3, 5), r.position + Vector2(r.size.x - 3, 5), Color(ink, 0.5), 1.0)
	for i in range(1, 4):
		var y: = r.position.y + r.size.y * i / 4.0
		draw_line(Vector2(r.end.x - 7, y), Vector2(r.end.x - 3, y), Color(ink, 0.55), 1.0)
	draw_line(r.position + Vector2(5, 9), r.position + Vector2(5, r.size.y - 9), Color(1, 1, 1, 0.5), 2.0)

## First-time how-to card (minigame.gd coach).
func howto() -> Array:
	return [
		{"i": "", "v": "beat", "s": "Tap SQUEEZE to push the red flow line up. It sinks on its own."},
		{"i": "", "v": "read", "s": "Keep the red line inside the green band. That fills the bag."},
		{"i": "", "v": "mash", "s": "Steady taps. Mashing overshoots the band."}]
