extends "res://scripts/minigames/minigame.gd"


const ING: = {
	"greens": ["Greens", "#4a9a3a"], "chicken": ["Chicken", "#c8a070"], "bacon": ["Bacon", "#b04a3a"], 
	"egg": ["Egg", "#f5e08a"], "tomato": ["Tomato", "#e04a3a"], "blue": ["Blue chz", "#c8d0e0"], 
	"feta": ["Feta", "#f4f4f4"], "pecans": ["Pecans", "#8a5a2a"], "apple": ["Apple", "#d0e060"], 
	"onion": ["Onion", "#c08ac0"], "ranch": ["Ranch", "#f0f0e0"], "vin": ["Balsamic", "#5a2a2a"], 
}
const ORDER: = ["greens", "chicken", "bacon", "egg", "tomato", "blue", "feta", "pecans", "apple", "onion", "ranch", "vin"]
const KEYS: = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL]
const MENU: = {
	"Cobb": ["greens", "chicken", "bacon", "egg", "tomato", "blue", "ranch"], 
	"Harvest": ["greens", "apple", "pecans", "feta", "vin"], 
	"Garden": ["greens", "tomato", "onion", "egg", "vin"], 
}

const ALLERGENS: = {
	"TREE NUTS": ["pecans"], 
	"DAIRY": ["blue", "feta", "ranch"], 
	"EGG": ["egg", "ranch"], 
}

var item: = ""
var expected: Array = []
var mods: Array = []
var allergy: = ""
var built: Array = []
var gloves: = false
var gloves_late: = false
var eighty_six: = ""

func _setup() -> void :
	title = "Salad Station"
	time_limit = 16.0 if rush() else 24.0
	space_is_pen = false
	var names: = MENU.keys()
	item = names[randi() % names.size()]
	expected = (MENU[item] as Array).duplicate()
	_roll_mods()
	if ctx.get("eighty_six", false):
		var cands: Array = []
		for c in ["bacon", "feta", "apple", "tomato", "onion"]:
			if expected.has(c): cands.append(c)
		if not cands.is_empty():
			eighty_six = cands[randi() % cands.size()]
			expected.erase(eighty_six)
	for i in ORDER.size():
		var id: String = ORDER[i]
		var row: = 0 if i < 7 else 1
		var col: = i if i < 7 else i - 7
		add_button(id, Rect2(4 + col * 45, 128 + row * 24, 43, 21), ING[id][0], KEYS[i], Color(ING[id][1]).darkened(0.5))
	add_button("gloves", Rect2(4 + 5 * 45, 152, 88, 21), "GLOVES+SANITIZE", KEY_G, Color("#43668e"))
	add_button("serve", Rect2(266, 104, 50, 21), "SERVE", KEY_ENTER, Color("#4e7a3a"))
	if eighty_six != "":
		add_button("comp", Rect2(212, 104, 50, 21), "COMP IT", KEY_C, Color("#a8406a"))
		get_button(eighty_six)["enabled"] = false
		get_button(eighty_six)["label"] = "86'd"

func _roll_mods() -> void :
	var options: Array = []
	for a in ALLERGENS:
		for ing in ALLERGENS[a]:
			if expected.has(ing):
				options.append(a)
				break
	if not options.is_empty() and randf() < 0.75:
		allergy = options[randi() % options.size()]
		mods.append("ALLERGY: " + allergy)
		var had_dressing: = expected.has("ranch")
		for ing in ALLERGENS[allergy]:
			expected.erase(ing)
		if had_dressing and not expected.has("ranch") and not expected.has("vin"):
			expected.append("vin")
			mods.append("(sub balsamic for ranch)")
	if expected.has("onion") and randf() < 0.5:
		mods.append("NO ONION")
		expected.erase("onion")
	elif expected.has("bacon") and randf() < 0.4:
		mods.append("NO BACON")
		expected.erase("bacon")

func add_ing(id: String) -> void :
	if built.has(id):
		return
	if allergy != "" and not gloves:
		gloves_late = true
	built.append(id)

func serve() -> void :
	var hit: = 0
	var extras: = 0
	for id in built:
		if expected.has(id): hit += 1
		else: extras += 1
	var s: = float(hit) / float(expected.size() + extras)
	for id in expected:
		if not built.has(id):
			notes.append("Forgot the %s." % String(ING[id][0]).to_lower())
	if allergy != "" and gloves_late:
		s -= 0.15
		notes.append("Allergy ticket: change gloves + sanitize BEFORE you build.")
	if allergy != "":
		for ing in ALLERGENS[allergy]:
			if built.has(ing):
				s = minf(s, 0.2)
				notes.append("%s on a %s allergy ticket. That's an ambulance, chef." % [String(ING[ing][0]), allergy.to_lower()])
				break
	if eighty_six != "" and built.has(eighty_six):
		notes.append("Served an 86'd item.")
	finish(s)

func _timeout() -> void :
	notes.append("Salad timed out. Wilted, like my 401(k).")
	serve()

func _on_button(id: String) -> void :
	match id:
		"gloves":
			gloves = true
			flash("Fresh gloves, sanitized board. Inspector-approved.", Color("#c0d890"), 1.2)
			get_button("gloves")["enabled"] = false
		"serve": serve()
		"comp":
			notes.append("Comped the salad after the 86.")
			finish(0.7)
		_: add_ing(id)

func debug_solve(good: bool) -> void :
	if good:
		if allergy != "":
			press("gloves")
		for id in expected:
			add_ing(id)
	else:
		for id in (MENU[item] as Array).slice(0, 2):
			add_ing(id)
		for id in ["onion", "pecans", "blue", "ranch"]:
			add_ing(id)
	serve()

func _draw_game() -> void :
	draw_rect(Rect2(4, 16, 120, 86), Color("#f0ead8"))
	txt(Vector2(8, 26), item.to_upper() + " SALAD", 8, Color("#2b2218"))
	var y: = 37.0
	for m in mods:
		txt(Vector2(8, y), str(m), 8, Color("#a43a2c"))
		y += 9.0
	if eighty_six != "":
		txt(Vector2(8, y), "86 %s: leave off/comp" % String(ING[eighty_six][0]).to_upper(), 8, Color("#a8406a"))
		y += 9.0
	var spec: = ""
	for id in MENU[item]:
		spec += String(ING[id][0]) + ", "
	txt(Vector2(8, y + 4), "Spec:", 6, Color("#6a625a"))
	mtxt(Vector2(8, y + 12), spec.trim_suffix(", "), 112, 6, Color("#6a625a"), 4)

	draw_circle(Vector2(200, 72), 38, Color("#e8e8f0"))
	draw_circle(Vector2(200, 72), 33, Color("#cfd2dc"))
	for i in built.size():
		var a: = i * 2.4
		draw_circle(Vector2(200, 72) + Vector2.from_angle(a) * (6.0 + i * 2.5), 7, Color(ING[built[i]][1]))
	if gloves:
		txt(Vector2(150, 24), "Gloves: fresh", 8, Color("#c0d890"))
