extends "res://scripts/minigames/minigame.gd"


const PROTEINS: = [
	{"n": "Chicken breast", "t": 165, "c": "#e8c9a0", "why": "Poultry: 165°F (instant).", "raw": "Salmonella says thanks."}, 
	{"n": "Chicken wings", "t": 165, "c": "#e2b47a", "why": "Poultry: 165°F (instant).", "raw": "Raw wings. Bold. Illegal."}, 
	{"n": "Ground turkey burger", "t": 165, "c": "#d9b08c", "why": "Ground poultry is still poultry: 165°F.", "raw": "That's a lawsuit on a bun."}, 
	{"n": "Ground beef patty", "t": 155, "c": "#8a4b3a", "why": "Ground beef: 155°F for 17 seconds.", "raw": "E. coli has entered the chat. Corporate blames 'supply chain.'"}, 
	{"n": "Pork chop", "t": 145, "c": "#d9a08c", "why": "Pork / whole cuts: 145°F for 15 seconds.", "raw": "Pink pork, angry inspector, angrier lawyer."}, 
	{"n": "Ribeye steak", "t": 145, "c": "#9a4a3a", "why": "Whole-muscle beef: 145°F for 15 seconds (or as ordered by an informed guest).", "raw": "Under temp. Back on the grill."}, 
	{"n": "Salmon fillet", "t": 145, "c": "#f08a6a", "why": "Fish: 145°F for 15 seconds.", "raw": "Sushi is a different restaurant, chef."}, 
]
const CENTER: = Vector2(160, 84)
const RADII: = Vector2(54, 26)

var rounds: = 2
var round_i: = 0
var protein: Dictionary = {}
var phase: = "probe"
var tc: = 0.0
var rate: = 20.0
var bias: = 0.0
var core: = 38.0
var phase_t: = 0.0
var scores: Array = []
var probe_pos: = Vector2.ZERO

func _setup() -> void :
	title = "Meat Temp Check"
	if ctx.get("fixit", false):
		title = "Fix Brayden's Burger"
		rounds = 1
	elif rush():
		rounds = 1
	time_limit = 14.0 * rounds
	add_button("pull", Rect2(110, 150, 100, 24), "PULL IT", KEY_SPACE, Color("#a43a2c"))
	_start_round()

func _start_round() -> void :
	if ctx.get("fixit", false):
		protein = PROTEINS[3]
	else:
		protein = PROTEINS[randi() % PROTEINS.size()]
	phase = "probe"
	tc = 0.0
	core = 38.0
	bias = 0.0
	rate = randf_range(24.0, 32.0) if rush() else randf_range(17.0, 24.0)
	get_button("pull")["enabled"] = false
	get_button("pull")["label"] = "PROBE FIRST"

func _probe(d: float) -> void :
	if phase != "probe":
		return
	bias = d * 12.0
	phase = "cooking"
	get_button("pull")["enabled"] = true
	get_button("pull")["label"] = "PULL IT"
	if d > 0.6:
		flash("Probing the thin edge? It reads hot. The center is what counts.", Color("#e6a640"))

func _pull() -> void :
	if phase != "cooking":
		return
	var target: int = protein["t"]
	var diff: = core - target
	var s: = 0.0
	if diff < 0.0:
		s = 0.0
		notes.append("%s pulled at %d°F, needs %d°F. %s" % [protein["n"], int(core), target, protein["raw"]])
		flash("UNDERCOOKED! %s" % protein["raw"], Color("#e06a4a"), 1.4)
	elif diff <= 5.0:
		s = 1.0
		flash("Perfect. %s" % protein["why"], Color("#c0d890"), 1.4)
	elif diff <= 10.0:
		s = 0.85
		flash("Good. %s" % protein["why"], Color("#c0d890"), 1.4)
	elif diff <= 18.0:
		s = 0.65
		flash("A bit over. %s" % protein["why"], Color("#e6a640"), 1.4)
	elif diff <= 28.0:
		s = 0.45
		flash("Dry. Safe, but dry.", Color("#e6a640"), 1.4)
	else:
		s = 0.2
		notes.append("%s cooked to shoe leather (%d°F)." % [protein["n"], int(core)])
		flash("Shoe leather.", Color("#e06a4a"), 1.4)
	scores.append(s)
	phase = "result"
	phase_t = 1.4
	get_button("pull")["enabled"] = false

func _next_round() -> void :
	round_i += 1
	if round_i >= rounds:
		_done()
	else:
		_start_round()

func _done() -> void :
	var total: = 0.0
	for s in scores:
		total += float(s)
	var sc: = total / rounds
	if ctx.get("fixit", false) and sc >= 0.65:
		bonus = 5
		notes.append("Fixed Brayden's burnt burger: +$5")
	finish(sc)

func _timeout() -> void :
	if phase == "cooking":
		_pull()
	_done()

func _tick(delta: float) -> void :
	if phase == "cooking":
		tc += delta
		core = 38.0 + rate * tc
		if core > float(protein["t"]) + 45.0:
			_pull()
	elif phase == "result":
		phase_t -= delta
		if phase_t <= 0.0:
			_next_round()

func _pointer_down(p: Vector2) -> void :
	if phase != "probe":
		return
	var d: = ((p - CENTER) / RADII).length()
	if d > 1.0:
		flash("You probed the air. Aim for the meat.", Color("#e6a640"), 1.0)
		return
	probe_pos = p
	_probe(d)

func _key(e: InputEventKey) -> void :
	if e.physical_keycode == KEY_ENTER and phase == "probe":
		probe_pos = CENTER
		_probe(0.05)

func _on_button(id: String) -> void :
	if id == "pull":
		_pull()

func debug_solve(good: bool) -> void :
	for i in rounds:
		_probe(0.05)
		tc = (float(protein["t"]) + (2.0 if good else -10.0) - 38.0) / rate
		core = 38.0 + rate * tc
		_pull()
		_next_round()

func _draw_game() -> void :
	txt(Vector2(0, 28), "%s  (round %d/%d)" % [protein.get("n", ""), round_i + 1, rounds], 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	draw_rect(Rect2(60, 104, 200, 10), Color("#6a625a"))
	for x in range(62, 260, 8):
		draw_rect(Rect2(x, 104, 3, 10), Color("#2a2a2a"))
	var col: = Color(protein.get("c", "#cccccc"))
	if phase != "probe":
		col = col.lerp(Color("#6b3a1a"), clampf((core - 38.0) / 200.0, 0, 0.7))
	draw_set_transform(CENTER, 0, RADII / RADII.x)
	draw_circle(Vector2.ZERO, RADII.x, col)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if phase == "probe":
		txt(Vector2(0, 140), "Tap the THICKEST part to probe (Enter = center)", 8, Color("#c0d890"), HORIZONTAL_ALIGNMENT_CENTER, W)
	else:
		draw_line(probe_pos, probe_pos + Vector2(30, -40), Color("#dddddd"), 2.0)
		var reading: = core + bias
		draw_rect(Rect2(probe_pos + Vector2(24, -58), Vector2(40, 18)), Color("#111111"))
		txt(probe_pos + Vector2(26, -45), "%d°F" % int(reading), 12, Color("#c0d890"))

	bar(Rect2(290, 24, 10, 120), 0.0, Color.RED)
	var frac: = clampf((core + bias - 32.0) / 200.0, 0.0, 1.0)
	draw_rect(Rect2(290, 24 + 120 * (1.0 - frac), 10, 120 * frac), Color("#e06a4a"))
	for temp in [100, 150, 200]:
		var y: float = 24 + 120 * (1.0 - (temp - 32.0) / 200.0)
		txt(Vector2(262, y + 3), str(temp), 6, Color(1, 1, 1, 0.5))
