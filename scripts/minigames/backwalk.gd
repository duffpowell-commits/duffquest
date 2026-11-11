extends "res://scripts/minigames/minigame.gd"

const BEAT: = 0.8
const STEPS: = 8
const WINDOW: = 0.17
const LEAD_IN: = 1.2
const GOOD: = ["CRACK. Vertebra 4 says thank you.", "*pop* That one was from 2019.", "{partner}: Ooh, I felt that one.", "CRUNCH. I can see colors now.", "My spine sounds like bubble wrap. Good bubble wrap."]
const BAD: = ["Ow. That was a kidney.", "{partner}: Sorry! Was that your ribs?", "She wobbles. I see my life flash.", "Off-beat. Now she's standing on my elbow."]

var hits: = 0
var misses: = 0
var judged: Array = []
var say: = ""

func _setup() -> void:
	backdrop = "bedroom"
	backdrop_dim = 0.3
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

func _draw_game() -> void:
	prop(Rect2(40, 98, 240, 22), Color("#4a3a6a"))

	prop(Rect2(60, 92, 170, 14), Color("#fbf6ec"))
	prop(Rect2(230, 90, 18, 16), Color("#f2d2b4"))
	draw_rect(Rect2(232, 88, 14, 5), Color("#6e5236"))
	prop(Rect2(30, 94, 30, 10), Color("#3a3a5a"))

	var prog: = clampf((t - LEAD_IN) / (BEAT * STEPS), 0.0, 1.0)
	var mx: = 80.0 + prog * 140.0
	var bob: = absf(sin(t * PI / BEAT)) * 4.0
	draw_rect(Rect2(mx - 4, 60 - bob, 8, 14), Color("#9a78c0"))
	draw_rect(Rect2(mx - 3, 52 - bob, 6, 7), Color("#f2d2b4"))
	draw_rect(Rect2(mx - 4, 50 - bob, 8, 3), Color("#5a3a2a"))
	draw_rect(Rect2(mx - 4, 74 - bob, 3, 16 + bob), Color("#f2d2b4"))
	draw_rect(Rect2(mx + 1, 74 - bob, 3, 16 + bob), Color("#f2d2b4"))

	var i: = nearest_beat()
	var dt: = beat_time(i) - t
	if i >= 0 and dt > -WINDOW and judged[i] == "":
		var r: = 6.0 + maxf(0.0, dt) * 30.0
		draw_arc(Vector2(mx, 40), r, 0, TAU, 24, Color("#e6a640"), 2.0)
		draw_arc(Vector2(mx, 40), 6.0, 0, TAU, 16, Color(1, 1, 1, 0.6), 1.0)
	for k in STEPS:
		var c: = Color(1, 1, 1, 0.25)
		if judged[k] == "hit":
			c = Color("#c0d890")
		elif judged[k] == "miss":
			c = Color("#e06a4a")
		draw_rect(Rect2(90 + k * 18, 24, 12, 6), c)
	draw_rect(Rect2(6, 124, 308, 26), Color(0.1, 0.08, 0.15, 0.92))
	mtxt(Vector2(10, 134), say, 300, 7, Color.WHITE, 2)
