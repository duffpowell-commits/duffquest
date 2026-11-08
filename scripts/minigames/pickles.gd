extends "res://scripts/minigames/minigame.gd"

const STEPS: = ["flour", "egg", "bread"]
const NEEDS: = {"flour": "dry", "egg": "wet", "bread": "dry" }

var total: = 3
var battered: = 0
var step: = 0
var hand: = "dry"
var errors: = 0
var clumps: = 0
var phase: = "bread"
var fry_p: = 0.0
var fry_score: = 0.0

func _setup() -> void:
	title = "Fried Pickles: Breading Station"
	time_limit = 32.0
	add_button("flour", Rect2(8, 122, 70, 22), "Flour", KEY_1, Color("#8a8070"))
	add_button("egg", Rect2(84, 122, 70, 22), "Egg wash", KEY_2, Color("#a08a30"))
	add_button("bread", Rect2(160, 122, 70, 22), "Breading", KEY_3, Color("#8a6a40"))
	add_button("basket", Rect2(236, 122, 78, 22), "Into basket", KEY_4, Color("#555a66"))
	add_button("hand", Rect2(8, 150, 146, 24), "SWITCH HAND", KEY_H, Color("#57504e"))
	add_button("pull", Rect2(160, 150, 154, 24), "PULL BASKET", KEY_SPACE, Color("#a43a2c"))
	get_button("pull")["enabled"] = false

func switch_hand() -> void:
	hand = "wet" if hand == "dry" else "dry"

func dip(bin: String) -> void:
	if phase != "bread":
		return
	if step >= 3:
		errors += 1
		flash("It's breaded. Put it in the basket!", Color("#e6a640"))
		return
	if STEPS[step] != bin:
		errors += 1
		flash("Out of order! Flour, egg wash, breading. Every time.", Color("#e06a4a"))
		return
	if NEEDS[bin] != hand:
		clumps += 1
		flash("Wrong hand. Club hands! I'm breading my own fingers.", Color("#e6a640"))
	step += 1

func to_basket() -> void:
	if phase != "bread":
		return
	if step < 3:
		errors += 1
		flash("Naked pickle in the fryer? Finish breading it.", Color("#e06a4a"))
		return
	battered += 1
	step = 0
	if battered >= total:
		phase = "fry"
		fry_p = 0.0
		for id in ["flour", "egg", "bread", "basket", "hand"]:
			get_button(id)["enabled"] = false
		get_button("pull")["enabled"] = true
		flash("Basket's down at 350°F. Pull when golden.", Color.WHITE, 1.2)

func pull() -> void:
	if phase != "fry":
		return
	if fry_p >= 0.8 and fry_p <= 1.05:
		fry_score = 1.0
	elif fry_p >= 0.65 and fry_p <= 1.2:
		fry_score = 0.6
	else:
		fry_score = 0.15
		notes.append("The pickles come out %s." % ("raw and soggy" if fry_p < 0.65 else "burnt"))
	_done()

func _done() -> void:
	if errors > 0:
		notes.append("%d breading order mistake(s)." % errors)
	if clumps > 0:
		notes.append("I get club hands %d time(s). Dry hand for dry, wet hand for wet." % clumps)
	var bread_score: = float(battered) / total * maxf(0.0, 1.0 - 0.12 * errors - 0.08 * clumps)
	finish(bread_score * 0.7 + fry_score * 0.3)

func _timeout() -> void:
	if phase == "fry":
		pull()
	else:
		_done()

func _tick(delta: float) -> void:
	if phase == "fry":
		fry_p += delta / 3.0
		if fry_p > 1.6:
			pull()

func _on_button(id: String) -> void:
	match id:
		"hand": switch_hand()
		"basket": to_basket()
		"pull": pull()
		_: dip(id)

func debug_solve(good: bool) -> void:
	for i in total:
		for s in STEPS:
			if good and NEEDS[s] != hand:
				switch_hand()
			dip(s)
		to_basket()
	fry_p = 0.9 if good else 1.5
	pull()

func _draw_game() -> void:
	var bins: = [["Flour", Color("#f0ece0")], ["Egg wash", Color("#f2c66a")], ["Breading", Color("#c8964a")]]
	for i in 3:
		var x: = 18 + i * 76
		draw_rect(Rect2(x, 70, 54, 34), Color("#9aa0aa"))
		draw_rect(Rect2(x + 4, 74, 46, 26), bins[i][1])
		if phase == "bread" and step == i:
			draw_rect(Rect2(x - 2, 68, 58, 38), Color("#c0d890"), false, 1.0)
	txt(Vector2(8, 28), "Pickles battered: %d / %d" % [battered, total], 8)
	txt(Vector2(8, 40), "Current pickle: %s" % (["needs flour", "needs egg wash", "needs breading", "ready for the basket"][step] if phase == "bread" else "frying"), 8, Color("#c0d890"))

	var dry_col: = Color("#f2d2b4") if hand == "dry" else Color("#f2d2b4").darkened(0.5)
	var wet_col: = Color("#f2c66a") if hand == "wet" else Color("#f2c66a").darkened(0.5)
	draw_rect(Rect2(244, 26, 30, 30), dry_col)
	draw_rect(Rect2(280, 26, 30, 30), wet_col)
	txt(Vector2(244, 64), "DRY", 8, Color.WHITE if hand == "dry" else Color(1, 1, 1, 0.4), HORIZONTAL_ALIGNMENT_CENTER, 30)
	txt(Vector2(280, 64), "WET", 8, Color.WHITE if hand == "wet" else Color(1, 1, 1, 0.4), HORIZONTAL_ALIGNMENT_CENTER, 30)
	txt(Vector2(240, 80), "Active hand", 8, Color(1, 1, 1, 0.6))

	var pc: Color = [Color("#6a9a3a"), Color("#d8d4c4"), Color("#e8cf7a"), Color("#c8964a")][step if phase == "bread" else 3]
	draw_circle(Vector2(272, 100), 9, pc)
	if phase == "fry":
		var fc: = Color("#e8cf7a").lerp(Color("#c07a20"), clampf(fry_p, 0, 1))
		if fry_p > 1.05:
			fc = Color("#c07a20").lerp(Color("#2a1a0a"), clampf((fry_p - 1.05) / 0.5, 0, 1))
		draw_rect(Rect2(18, 70, 206, 34), Color("#c89b3c"))
		for k in total:
			draw_circle(Vector2(50 + k * 50, 87), 9, fc)
		bar(Rect2(18, 108, 206, 5), fry_p / 1.4, fc)
		draw_rect(Rect2(18 + 206 * 0.8 / 1.4, 106, 206 * 0.25 / 1.4, 9), Color(1, 1, 1, 0.25))
