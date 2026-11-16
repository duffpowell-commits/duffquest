extends "res://scripts/minigames/minigame.gd"

const BEAT: = 0.8
const STEPS: = 8
const WINDOW: = 0.17
const LEAD_IN: = 1.2
const GOOD: = ["CRACK. Vertebra 4 says thank you.", "*pop* That one was from my last job.", "{partner}: Ooh, I felt that one.", "CRUNCH. I can see colors now.", "My spine sounds like bubble wrap. Good bubble wrap."]
const BAD: = ["Ow. That was a kidney.", "{partner}: Sorry! Was that your ribs?", "She wobbles. I see my life flash.", "Off-beat. Now she's standing on my elbow."]

var hits: = 0
var misses: = 0
var judged: Array = []
var say: = ""

func _setup() -> void:
	backdrop = "backwalk_bed"   # painted: Duff face-down on the bed, side view, head on the pillow at the right
	music = "home"
	title = "BACK WALK  (press on the beat)"
	time_limit = 0.0
	space_is_pen = false
	for i in STEPS:
		judged.append("")
	add_button("step", Rect2(6, 154, 200, 22), "STEP  (Space)", KEY_SPACE, Color("#2e5aa8"))
	add_button("quit", Rect2(262, 154, 54, 22), "Stop", KEY_ESCAPE, Color("#a43a2c"))
	say = "{partner} climbs on. \"Tell me if I'm too heavy.\" (Never say yes.)"

func beat_time(i: int) -> float:
	return LEAD_IN + BEAT * float(i + 1)

func nearest_beat() -> int:
	var best: = -1
	var bd: = 99.0
	for i in STEPS:
		var d: = absf(t - beat_time(i))
		if d < bd:
			bd = d
			best = i
	return best

func score() -> float:
	return float(hits) / float(STEPS)

func _tick(_d: float) -> void:
	for i in STEPS:
		if judged[i] == "" and t > beat_time(i) + WINDOW:
			judged[i] = "miss"
			misses += 1
			say = BAD[misses % BAD.size()]
	if t > beat_time(STEPS - 1) + 0.6 and not done:
		finish(score())

func _on_button(id: String) -> void:
	if id == "quit":
		finish(score())
		return
	var i: = nearest_beat()
	if i >= 0 and judged[i] == "" and absf(t - beat_time(i)) <= WINDOW:
		judged[i] = "hit"
		hits += 1
		say = GOOD[hits % GOOD.size()]
		flash("CRACK!", Color("#c0d890"), 0.4)
	else:
		say = "I go too early. Now she's balancing on one foot."

## On bg_backwalk_bed his bare back runs from the belt (x ~188) to the shoulders (x ~238), top at y ~97.
const BACK_X0: = 188.0
const BACK_X1: = 238.0
const BACK_Y: = 97.0

func _draw_game() -> void:
	# Madison walking his spine (real sprite, 2x), bobbing on the beat
	var prog: = clampf((t - LEAD_IN) / (BEAT * STEPS), 0.0, 1.0)
	var mx: = BACK_X0 + prog * (BACK_X1 - BACK_X0)
	var bob: = absf(sin(t * PI / BEAT)) * 3.0
	draw_set_transform(Vector2(mx, BACK_Y - bob), 0.0, Vector2(2, 2))
	Art.person(self, "ch_madison", Vector2.ZERO, Vector2.RIGHT, t, true, false, Color.WHITE, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# beat ring closing in over her head
	var i: = nearest_beat()
	var dt: = beat_time(i) - t
	var ring_c: = Vector2(mx, 30)
	if i >= 0 and dt > -WINDOW and judged[i] == "":
		var r: = 6.0 + maxf(0.0, dt) * 30.0
		draw_arc(ring_c, r + 1.0, 0, TAU, 32, UiStyle.PROP_INK, 3.0)
		draw_arc(ring_c, r, 0, TAU, 32, UiStyle.GOLD, 2.0)
		prop_circle(ring_c, 5.0, UiStyle.CREAM)
	# the eight beats as little cel-shaded lights
	for k in STEPS:
		var c: = Color("#5a4e6a")
		if judged[k] == "hit":
			c = Color("#8ccf5a")
		elif judged[k] == "miss":
			c = Color("#e06a4a")
		prop_circle(Vector2(18 + k * 12, 22), 4.0, c)
	UiStyle.panel(self, Rect2(6, 126, 308, 24), UiStyle.PANEL, 0.94, 1.0 / 1.5)
	mtxt(Vector2(10, 135), say, 300, 7, Color.WHITE, 2)

## First-time how-to card (minigame.gd coach).
func howto() -> Array:
	return [
		{"i": "", "v": "beat", "s": "Footsteps march down his back to a steady beat."},
		{"i": "", "v": "tap", "s": "Tap STEP right as each footprint lands. Early or late = ouch."}]
