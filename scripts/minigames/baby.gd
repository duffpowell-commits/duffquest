extends "res://scripts/minigames/minigame.gd"

const BEAT: = 0.8
const CUES: = {
	"hungry": "She's gnawing on her fist and rooting around. (hungry)",
	"wet": "That smell. THAT SMELL. (diaper)",
	"fussy": "Fed, dry, still mad. Rock her on the beat till she's out.",
}

var needs: Array = []
var meter: = 40.0
var wrong: = 0
var formula: = 0
var diapers: = 0
var used_formula: = 0
var used_diapers: = 0
var no_formula: = false
var no_diaper: = false
var success: = false

func _setup() -> void:
	backdrop = "nursery"
	backdrop_dim = 0.45
	music = "home"
	title = "3:00 AM - OCTAVIA IS CRYING"
	time_limit = 50.0
	space_is_pen = false
	formula = int(ctx.get("formula", 0))
	diapers = int(ctx.get("diapers", 0))
	needs = ["hungry", "wet"]
	needs.shuffle()
	if randf() < 0.3:
		needs = [needs[0]]
	needs.append("fussy")
	add_button("feed", Rect2(6, 150, 100, 24), "FEED", KEY_1, Color("#43668e"))["icon"] = "kf_shop_formula"
	add_button("change", Rect2(110, 150, 100, 24), "CHANGE", KEY_2, Color("#6a5a3a"))["icon"] = "kf_shop_diapers"
	var rock: = add_button("rock", Rect2(214, 150, 100, 24), "ROCK HER", KEY_SPACE, Color("#a8406a"))
	rock["badge"] = "Z"   # no prop for a lullaby; a sleepy badge keeps the row the same card style

func need() -> String:
	return needs[0] if not needs.is_empty() else ""

func _fail_wrong(msg: String) -> void:
	wrong += 1
	meter += 12.0
	flash(msg, Color("#e6a640"), 1.2)
	if meter >= 100.0:
		_done(false)

func feed() -> void:
	if need() != "hungry":
		_fail_wrong("She's not hungry. She spits the bottle right at me.")
		return
	if formula - used_formula <= 0:
		no_formula = true
		meter += 15.0
		notes.append("No formula in the house. {partner} does a 3 AM gas station run. Brings me back a hot dog anyway.")
		flash("NO FORMULA. {partner} grabs her keys. \"I got it, babe. Go back to sleep.\"", Color("#e06a4a"), 1.6)
	else:
		used_formula += 1
		meter -= 35.0
		flash("Glug glug glug. Crisis paused.", Color("#c0d890"), 1.0)
	needs.pop_front()

func change() -> void:
	if need() != "wet":
		_fail_wrong("Clean diaper, still screaming. Wrong call, dad.")
		return
	if diapers - used_diapers <= 0:
		no_diaper = true
		meter += 15.0
		notes.append("Out of diapers. Improvised: dish towel and duct tape.")
		flash("NO DIAPERS. Dish towel it is.", Color("#e06a4a"), 1.6)
	else:
		used_diapers += 1
		meter -= 30.0
		flash("Fresh diaper. Hazmat situation contained.", Color("#c0d890"), 1.0)
	needs.pop_front()

func rock() -> void:
	if need() != "fussy":
		_fail_wrong("Rocking a %s baby just makes her madder." % ("hungry" if need() == "hungry" else "stinky"))
		return
	var off: = fmod(t, BEAT)
	off = minf(off, BEAT - off)
	meter -= 12.0 if off < 0.15 else 4.0
	if meter <= 0.0:
		_done(true)

func _done(ok: bool) -> void:
	success = ok
	if not ok:
		notes.append("{partner} wakes up to the screaming, takes over, and tells me to sleep. Hero.")
	var s: = 0.2
	if ok:
		s = maxf(0.3, 1.0 - wrong * 0.12 - (0.25 if no_formula else 0.0) - (0.2 if no_diaper else 0.0))
	finish(s)

func _timeout() -> void:
	_done(false)

var cry_cd: = 0.0

func _tick(delta: float) -> void:
	cry_cd -= delta
	if cry_cd <= 0.0 and meter > 20.0:
		cry_cd = 3.0 - minf(meter / 50.0, 1.6)
		AudioScript.sfx("baby_cry")
	meter += 2.5 * delta
	meter = maxf(meter, 0.0 if need() == "fussy" else 5.0)
	if meter >= 100.0:
		_done(false)

func _on_button(id: String) -> void:
	match id:
		"feed": feed()
		"change": change()
		"rock": rock()

func debug_solve(good: bool) -> void:
	if good:
		while not done:
			match need():
				"hungry": feed()
				"wet": change()
				"fussy":
					t = BEAT * 10.0
					rock()
	else:
		while not done:
			rock()

func _draw_game() -> void:

	var shake: = sin(t * 30.0) * minf(meter / 30.0, 3.0)
	draw_set_transform(Vector2(160 + shake, 72), 0.0, Vector2(3, 3))
	Art.frame(self, "baby", Vector2.ZERO, 2 if meter > 8.0 else 3, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	txt(Vector2(6, 24), "Crying", 8)
	bar(Rect2(50, 18, 140, 7), meter / 100.0, Color("#e06a4a"))
	txt(Vector2(200, 24), "Formula: %d  Diapers: %d" % [formula - used_formula, diapers - used_diapers], 7, Color(1, 1, 1, 0.7))
	mtxt(Vector2(10, 116), CUES.get(need(), ""), 300, 8, Color("#c0d890"), 3)
	if need() == "fussy":
		var pulse: = 1.0 - fmod(t, BEAT) / BEAT
		draw_circle(Vector2(260, 70), 6 + pulse * 8, Color(1, 0.8, 0.2, 0.3 + pulse * 0.5))
