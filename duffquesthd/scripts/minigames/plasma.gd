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

func _setup() -> void :
	backdrop = "plasma"
	title = "{PLASMA}"
	time_limit = LIMIT
	space_is_pen = false
	add_button("squeeze", Rect2(6, 154, 200, 22), "SQUEEZE  (Space)", KEY_SPACE, Color("#2e5aa8"))
	add_button("done", Rect2(262, 154, 54, 22), "Stop", KEY_ESCAPE, Color("#a43a2c"))
	say = JOKES[0]

func squeeze() -> void :
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

func _tick(d: float) -> void :
	flow = maxf(0.0, flow - DECAY * d)
	if flow >= BAND.x and flow <= BAND.y:
		in_band += d
		bag += FILL * d
	if bag >= 1.0 and not done:
		finish(1.0)

func _timeout() -> void :
	finish(score())

func _on_button(id: String) -> void :
	if id == "squeeze":
		squeeze()
	else:
		finish(score())

func _draw_game() -> void :


	var squish: = 1.0 - clampf(t - last_sq, 0.0, 0.2) * 1.5
	draw_circle(Vector2(46, 66), 6.0 * (0.7 + 0.3 * (1.0 - squish)), Color("#e6a640"))

	draw_rect(Rect2(220, 30, 34, 60), Color("#ffffff"))
	draw_rect(Rect2(220, 30 + 60 * (1.0 - bag), 34, 60 * bag), Color("#f0c050"))
	draw_rect(Rect2(220, 30, 34, 60), Color("#8a8a9a"), false, 1.0)
	txt(Vector2(212, 100), "Bag %d%%" % int(bag * 100.0), 7, Color("#333333"))

	txt(Vector2(30, 116), "FLOW", 7, Color("#333333"))
	draw_rect(Rect2(60, 110, 150, 8), Color("#c0c0c8"))
	draw_rect(Rect2(60 + 150 * BAND.x / 1.2, 110, 150 * (BAND.y - BAND.x) / 1.2, 8), Color("#8ad08a"))
	draw_rect(Rect2(60 + 150 * clampf(flow / 1.2, 0.0, 1.0) - 1, 107, 3, 14), Color("#c03030"))
	draw_rect(Rect2(6, 124, 308, 26), Color(0.1, 0.08, 0.15, 0.92))
	mtxt(Vector2(10, 134), say, 300, 7, Color.WHITE, 2)
