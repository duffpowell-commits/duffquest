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

const SKIN: = Color("#e9b994")

func _draw_game() -> void:
	# the bed, side view: frame, mattress, blanket bunched at the foot, pillow at the head
	prop(Rect2(26, 112, 268, 12), Color("#4a2e22"), 0.3)
	prop(Rect2(30, 100, 260, 14), Color("#e8e2f2"), 0.25)
	prop(Rect2(32, 92, 30, 12), Color("#34407a"), 0.3)
	prop(Rect2(240, 88, 34, 13), UiStyle.CREAM, 0.25)
	# Duff face-down: jeans, bare back, tattooed arm along his side, head on the pillow
	prop(Rect2(62, 86, 70, 15), Color("#3a5a8a"), 0.3)
	prop(Rect2(130, 80, 96, 21), SKIN, 0.3)
	var arm: = Rect2(144, 92, 66, 7)
	draw_rect(arm, SKIN.darkened(0.1))
	for k in 6:
		draw_arc(Vector2(arm.position.x + 6 + k * 10, arm.position.y + 2.5), 2.5, k * 0.6, k * 0.6 + PI * 1.4, 8,
			[Color("#2a7f86"), Color("#c0443c"), UiStyle.PROP_INK][k % 3], 1.2)
	draw_rect(arm, UiStyle.PROP_INK, false, 0.8)
	prop_circle(Vector2(236, 86), 10.0, SKIN)
	draw_colored_polygon(PackedVector2Array([Vector2(227, 82), Vector2(236, 75), Vector2(246, 82), Vector2(244, 87),
		Vector2(229, 87)]), Color("#4a2e1e"))
	# Madison walking his spine (real sprite, 2x), bobbing on the beat
	var prog: = clampf((t - LEAD_IN) / (BEAT * STEPS), 0.0, 1.0)
	var mx: = 140.0 + prog * 76.0
	var bob: = absf(sin(t * PI / BEAT)) * 3.0
	draw_set_transform(Vector2(mx, 82 - bob), 0.0, Vector2(2, 2))
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
