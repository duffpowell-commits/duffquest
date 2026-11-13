extends "res://scripts/minigames/minigame.gd"

const SCENE_LINES: = [
	"Later that night. No sirens. No vents. Just the couch.",
	"{partner}: You fought a guy in a tank top in a burning tower... for us?",
	"{hero}: I fought him for the leftovers. You guys were a close second.",
	"{partner}: Liar. ...Come here.",
	"And {baby}? Out cold on {hero}'s chest. Nobody moves. Ever again.",
	"{cat1} and {cat2} pile on. {cat3} sits one cushion away. That's love, for {cat3}.",
	"{partner}: Same time tomorrow?",
	"{hero}: Every day. Honey buns included.",
]
const LINE_T: = 2.6
var credits: Array = []
var scroll: = 0.0
var phase: = "scene"
var shades: = false

func _setup() -> void:
	music = "credits"
	time_limit = 0.0
	show_header = false
	space_is_pen = false
	credits = credits_lines()
	add_button("skip", Rect2(262, 164, 54, 13), "Skip", KEY_ESCAPE, Color(0.2, 0.2, 0.3, 0.7))

static func credits_lines() -> Array:
	var c: Array = [
		"{GAME_TITLE}", "",
		"STARRING", "{hero} ... as himself", "{partner} ... his whole heart", "{baby} ... the boss of everyone",
		"{cat1} and {cat2} ... chaos, 3 AM division", "{cat3} ... (refused to sign the release)", "{sister_full} ... texts, Wordle, roasts", "",
		"THE EXES (parody nicknames)", "{ex_1}", "{ex_2}", "{ex_3}", "{ex_4}", "",
		"FINAL BOSS", "{ex_final} ... an affectionate parody of every 80s action hero", "",
		"ALSO FEATURING", "Grill-Boy Brayden, Palm Beach Pete, the porch pirates,", "the raccoons (friends now), every Karen in {city},", "and The Elite Gala", "",
		"Filmed on location in {city} and {nearby_town}", "", "Made with love.", "", "A work of parody and fiction. Stores and brands are", "parodies; none of them endorsed this game.", "Full notice: Settings > Credits & legal.", "", "THE END", "(Rent is due. Rent is always due. Tonight, nobody checks.)",
	]
	return c.map(func (x): return Cast.T(str(x)))

func _tick(delta: float) -> void:
	if phase == "scene" and t >= LINE_T * SCENE_LINES.size() + 1.5:
		phase = "credits"
	elif phase == "credits":
		scroll += 14.0 * delta
		if scroll > credits.size() * 11.0 + H:
			_to_end()

func _to_end() -> void:
	if phase == "end":
		return
	phase = "end"
	buttons.clear()
	add_button("done", Rect2(110, 150, 100, 20), "Continue", KEY_ENTER, Color("#4e7a3a"))

func _on_button(id: String) -> void:
	match id:
		"skip":
			if phase == "scene":
				phase = "credits"
				t = LINE_T * SCENE_LINES.size() + 2.0
			else:
				_to_end()
		"done":
			finish(1.0)

func _draw_game() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("#120f1a"))
	if phase == "scene":
		_draw_couch()
		var shown: = mini(SCENE_LINES.size(), int(t / LINE_T) + 1)
		var line: = Cast.T(SCENE_LINES[shown - 1])
		if line.begins_with(Cast.T("{hero}") + ": "):

			draw_rect(Rect2(10, 112, 300, 52), Color(0, 0, 0, 0.6))
			Art.duff_portrait(self, Vector2(12, 114), 2, shades)
			mtxt(Vector2(66, 132), line, 238, 8, Color.WHITE)
		else:
			draw_rect(Rect2(10, 128, 300, 30), Color(0, 0, 0, 0.6))
			mtxt(Vector2(16, 140), line, 288, 8, Color.WHITE)
	elif phase == "credits":
		_draw_couch(0.35)
		for i in credits.size():
			var y: = H + 10.0 + i * 11.0 - scroll
			if y < -10.0 or y > H + 10.0:
				continue
			var s: String = credits[i]
			var head: = s == s.to_upper() and s != ""
			txt(Vector2(0, y), s, 9 if head else 7, Color("#e6a640") if head else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	else:
		_draw_couch()
		txt(Vector2(0, 40), "THE END", 16, Color("#e6a640"), HORIZONTAL_ALIGNMENT_CENTER, W)
		txt(Vector2(0, 60), Cast.T("And {partner}'s happy. Not just for now."), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
		txt(Vector2(0, 74), "Achievement: Happily Ever After", 7, Color("#a0ffa0"), HORIZONTAL_ALIGNMENT_CENTER, W)

func _draw_couch(a: float = 1.0) -> void:

	Art.image(self, "bg_living_night", Vector2.ZERO, Color(1, 1, 1, a))
	if int(t * 1.5) % 2 == 0 and phase == "scene":
		txt(Vector2(124, 66), "z", 6, Color(1, 1, 1, 0.7 * a))
	draw_circle(Vector2(140, 56), 2.5, Color(1, 0.4, 0.6, a))
