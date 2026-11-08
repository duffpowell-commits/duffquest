extends "res://scripts/minigames/minigame.gd"

const ING: = {
	"bun_b": ["Btm bun", "#d9a05a"], "mayo": ["Mayo", "#f4f0dc"], "fried": ["Fried chx", "#c88a3a"],
	"grilled": ["Grill chx", "#a07a50"], "hot": ["Hot sauce", "#d0402a"], "cheese": ["Cheese", "#f2c230"],
	"bacon": ["Bacon", "#b04a3a"], "lettuce": ["Lettuce", "#6ac04a"], "tomato": ["Tomato", "#e04a3a"],
	"pickles": ["Pickles", "#7a9a3a"], "bun_t": ["Top bun", "#e0aa62"],
}
const ORDER: = ["bun_b", "mayo", "fried", "grilled", "hot", "cheese", "bacon", "lettuce", "tomato", "pickles", "bun_t"]
const KEYS: = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS]
const MENU: = {
	"Twisted Classic": ["bun_b", "mayo", "fried", "pickles", "bun_t"],
	"Deluxe": ["bun_b", "mayo", "fried", "cheese", "lettuce", "tomato", "pickles", "bun_t"],
	"Club Fork": ["bun_b", "mayo", "grilled", "bacon", "cheese", "lettuce", "tomato", "bun_t"],
}

var item: = ""
var base: Array = []
var expected: Array = []
var mods: Array = []
var built: Array = []
var eighty_six: = ""
var eighty_six_note: = ""
var stolen: = false
var steal_armed: = false
var recovered: = false

func _setup() -> void:
	title = "Chicken Sandwich Build"
	time_limit = 17.0 if rush() else 26.0
	space_is_pen = false
	var names: = MENU.keys()
	item = names[randi() % names.size()]
	base = (MENU[item] as Array).duplicate()
	expected = base.duplicate()
	_roll_mods()
	if ctx.get("eighty_six", false):
		_roll_86()
	steal_armed = bool(ctx.get("steal", false))
	for i in ORDER.size():
		var id: String = ORDER[i]
		var row: = 0 if i < 6 else 1
		var col: = i if i < 6 else i - 6
		add_button(id, Rect2(4 + col * 52.5, 128 + row * 24, 50, 21), ING[id][0], KEYS[i], Color(ING[id][1]).darkened(0.45))
	add_button("undo", Rect2(4 + 5 * 52.5, 152, 50, 21), "UNDO", KEY_BACKSPACE)
	add_button("send", Rect2(266, 104, 50, 21), "SEND", KEY_ENTER, Color("#4e7a3a"))
	if eighty_six != "":
		add_button("comp", Rect2(212, 104, 50, 21), "COMP IT", KEY_C, Color("#a8406a"))
		get_button(eighty_six)["enabled"] = false
		get_button(eighty_six)["label"] = "86'd"
	if steal_armed:
		add_button("grab", Rect2(4, 104, 110, 21), "GRAB TICKET BACK", KEY_G, Color("#9c5a2c"))
		get_button("grab")["enabled"] = false

func _roll_mods() -> void:
	var pool: Array = []
	if expected.has("pickles"): pool.append("NO PICKLES")
	if expected.has("tomato"): pool.append("NO TOMATO")
	if expected.has("mayo"): pool.append("NO MAYO")
	pool.append("ADD SPICY")
	if not expected.has("bacon"): pool.append("ADD BACON")
	if expected.has("fried"): pool.append("SUB GRILLED")
	pool.shuffle()
	mods = pool.slice(0, 1 if rush() else 2)
	for m in mods:
		apply_mod(m)

func apply_mod(m: String) -> void:
	match m:
		"NO PICKLES": expected.erase("pickles")
		"NO TOMATO": expected.erase("tomato")
		"NO MAYO": expected.erase("mayo")
		"ADD SPICY":
			var ci: = _chicken_index()
			expected.insert(ci + 1, "hot")
		"ADD BACON":
			var ci2: = _chicken_index()
			var at: = ci2 + 1
			if expected.has("hot"): at = expected.find("hot") + 1
			if expected.has("cheese"): at = expected.find("cheese") + 1
			expected.insert(at, "bacon")
		"SUB GRILLED":
			expected[expected.find("fried")] = "grilled"

func _chicken_index() -> int:
	var i: = expected.find("fried")
	return i if i >= 0 else expected.find("grilled")

func _roll_86() -> void:
	var cands: Array = []
	for c in ["tomato", "bacon", "fried", "pickles"]:
		if expected.has(c):
			cands.append(c)
	if cands.is_empty():
		return
	eighty_six = cands[randi() % cands.size()]
	if eighty_six == "fried":
		expected[expected.find("fried")] = "grilled"
		eighty_six_note = "86 FRIED CHX: sub grilled (or comp)"
	else:
		expected.erase(eighty_six)
		eighty_six_note = "86 %s: leave it off (or comp)" % String(ING[eighty_six][0]).to_upper()

func add_ing(id: String) -> void:
	if built.size() >= 12:
		return
	built.append(id)

func send() -> void:
	var dist: = _edit_distance(built, expected)
	var s: = maxf(0.0, 1.0 - float(dist) / expected.size())
	for m in mods:
		if not _mod_ok(m):
			notes.append("Ticket said %s. Table 7 is furious." % m)
	if eighty_six != "" and built.has(eighty_six):
		notes.append("I serve an 86'd item? Where did I even get that?")
	if t > time_limit * 0.8:
		s *= 0.9
		notes.append("My ticket's slow. Expo is glaring. Owner's on his third vacation.")
	if stolen and recovered and s >= 0.8:
		bonus = 5
		notes.append("I get the ticket back from Brayden and nail it: +$5")
	finish(s)

func _mod_ok(m: String) -> bool:
	match m:
		"NO PICKLES": return not built.has("pickles")
		"NO TOMATO": return not built.has("tomato")
		"NO MAYO": return not built.has("mayo")
		"ADD SPICY": return built.has("hot")
		"ADD BACON": return built.has("bacon")
		"SUB GRILLED": return built.has("grilled") and not built.has("fried")
	return true

static func _edit_distance(a: Array, b: Array) -> int:
	var prev: Array = range(b.size() + 1)
	for i in a.size():
		var cur: Array = [i + 1]
		for j in b.size():
			var cost: = 0 if a[i] == b[j] else 1
			cur.append(mini(mini(int(prev[j + 1]) + 1, int(cur[j]) + 1), int(prev[j]) + cost))
		prev = cur
	return int(prev[b.size()])

func _timeout() -> void:
	notes.append("My ticket times out.")
	send()

func _tick(_d: float) -> void:
	if steal_armed and not stolen and t > 4.0:
		stolen = true
		get_button("grab")["enabled"] = true
		flash("Grill-Boy Brayden swipes my ticket! (G to grab it back)", Color("#e6a640"), 2.0)

func grab() -> void:
	if stolen and not recovered:
		recovered = true
		t += 3.0
		get_button("grab")["enabled"] = false
		flash("I get the ticket back. Brayden pretends nothing happened. Heard, buddy.", Color.WHITE, 1.4)

func _on_button(id: String) -> void:
	match id:
		"undo":
			if not built.is_empty(): built.pop_back()
		"send": send()
		"comp":
			notes.append("I comp it after the 86. Manager sighs like it's his money. It's the owner's. He has four boats.")
			finish(0.7)
		"grab": grab()
		_: add_ing(id)

func debug_solve(good: bool) -> void:
	if steal_armed:
		t = 4.5
		_tick(0.0)
		grab()
	t = 0.0
	var seq: Array = expected if good else base
	for id in seq:
		add_ing(id)
	if not good:
		built.reverse()
	send()

func _draw_game() -> void:

	draw_rect(Rect2(4, 16, 120, 86), Color("#f0ead8"))
	var dark: = Color("#2b2218")
	if stolen and not recovered:
		mtxt(Vector2(8, 40), "TICKET STOLEN BY GRILL-BOY BRAYDEN", 112, 8, Color("#a43a2c"))
	else:
		txt(Vector2(8, 26), item.to_upper(), 8, dark)
		var y: = 36.0
		for m in mods:
			txt(Vector2(8, y), "** " + str(m), 8, Color("#a43a2c"))
			y += 9.0
		if eighty_six_note != "":
			mtxt(Vector2(8, y), eighty_six_note, 112, 8, Color("#a8406a"), 2)
			y += 18.0
		txt(Vector2(8, y + 2), "Spec (btm to top):", 6, Color("#6a625a"))
		y += 10.0
		var spec: = ""
		for id in base:
			spec += String(ING[id][0]) + ", "
		mtxt(Vector2(8, y), spec.trim_suffix(", "), 112, 6, Color("#6a625a"), 4)

	draw_rect(Rect2(150, 108, 100, 4), Color("#cccccc"))
	var by: = 106.0
	for id in built:
		var h: = 6.0 if id in ["bun_b", "bun_t", "fried", "grilled"] else 3.0
		if not _layer_sprite(id, by, h):
			var w: = 50.0 if id != "hot" else 42.0
			draw_rect(Rect2(200 - w / 2, by - h, w, h), Color(ING[id][1]))
		by -= h + 0.5
	txt(Vector2(150, 24), "%d layers" % built.size(), 8, Color(1, 1, 1, 0.6))

## Gemini G6 kitchen props (tools/import_props.py) for the layers it drew; the rest stay flat bars.
## Each sprite is squashed to the layer's slot height x2 so the stack still reads bottom-to-top.
const LAYER_ART: = {"bun_b": ["kp_bun", 0.45, 1.0], "bun_t": ["kp_bun", 0.0, 0.55], "fried": ["kp_fried_chicken", 0.0, 1.0],
	"grilled": ["kp_fried_chicken", 0.0, 1.0], "lettuce": ["kp_lettuce", 0.0, 1.0], "tomato": ["kp_tomato", 0.15, 0.85]}

func _layer_sprite(id: String, by: float, h: float) -> bool:
	if not LAYER_ART.has(id) or Art.tex(LAYER_ART[id][0]) == null:
		return false
	var tx: Texture2D = Art.tex(LAYER_ART[id][0])
	var a: Array = LAYER_ART[id]
	var src: = Rect2(0, tx.get_height() * float(a[1]), tx.get_width(), tx.get_height() * (float(a[2]) - float(a[1])))
	var w: = src.size.x / 2.0
	var dh: = maxf(h * 2.2, 7.0)
	var mod: = Color("#b08868") if id == "grilled" else Color.WHITE
	draw_texture_rect_region(tx, Rect2(200 - w / 2, by - dh + h * 0.5, w, dh), src, mod)
	return true
