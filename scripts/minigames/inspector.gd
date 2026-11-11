extends "res://scripts/minigames/minigame.gd"

const OBS: = [
	["Make-line cooler reads 39°F.", false],
	["Raw chicken stored above the lettuce in the walk-in.", true],
	["Chili in the hot well at 128°F.", true],
	["Cook washes hands for 20 seconds, then puts on gloves.", false],
	["Sanitizer bucket tests at 0 ppm.", true],
	["House coleslaw made day 1, today is day 5, held at 41°F.", false],
	["Cook eating fries over the prep table.", true],
	["Big covered stockpot of soup in the walk-in, still 90°F after 4 hours.", true],
	["Thawing chicken under cold running water (65°F).", false],
	["Wiping cloths kept in sanitizer solution between uses.", false],
	["Hand sink full of dirty sheet pans.", true],
	["Grill-Boy tastes the sauce with the stirring spoon, then keeps stirring.", true],
	["Chicken breast probed at 166°F before plating.", false],
	["Kid's burger pulled at 145°F.", true],
	["Allergy ticket made with fresh gloves on a sanitized board.", false],
	["Cooked rice left on the counter all afternoon to 'cool off'.", true],
]

var picks: Array = []
var idx: = 0
var correct: = 0

func _setup() -> void:
	title = "SURPRISE HEALTH INSPECTION"
	time_limit = 30.0
	space_is_pen = false
	var ids: = range(OBS.size())
	ids.shuffle()
	picks = ids.slice(0, 4)
	add_button("ok", Rect2(10, 140, 145, 32), "COMPLIANT", KEY_1, Color("#4e7a3a"))
	add_button("bad", Rect2(165, 140, 145, 32), "VIOLATION", KEY_2, Color("#a43a2c"))

func call_it(violation: bool) -> void:
	var o: Array = OBS[picks[idx]]
	if bool(o[1]) == violation:
		correct += 1
		flash("The inspector nods. Writes something down. Ominous.", Color("#c0d890"), 1.0)
	else:
		notes.append("Inspector disagrees: \"%s\"" % o[0])
		flash("Inspector frowns and writes a LOT.", Color("#e06a4a"), 1.0)
	idx += 1
	if idx >= picks.size():
		finish(float(correct) / picks.size())

func _timeout() -> void:
	finish(float(correct) / picks.size(), "I take too long. The inspector has a quota and a parking meter.")

func _on_button(id: String) -> void:
	call_it(id == "bad")

func debug_solve(good: bool) -> void:
	while not done:
		var v: bool = OBS[picks[idx]][1]
		call_it(v if good else not v)

func _draw_game() -> void:

	prop(Rect2(150, 30, 20, 26), Color("#3a3a5a"))
	prop(Rect2(153, 18, 14, 12), Color("#f2d2b4"))
	prop(Rect2(170, 36, 10, 14), Color("#f0ead8"))
	txt(Vector2(0, 70), "Observation %d/%d:" % [mini(idx + 1, picks.size()), picks.size()], 8, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, W)
	if idx < picks.size():
		mtxt(Vector2(20, 90), OBS[picks[idx]][0], 280, 8, Color.WHITE, 4)
