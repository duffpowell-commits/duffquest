extends "res://scripts/minigames/minigame.gd"

const Gear: = preload("res://scripts/gear.gd")
const WKEYS: = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7]
const AKEYS: = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N]

var m: Node = null
var g: Dictionary = {}
var sel: = ""

## Nov 17: Gear is a shop-app grid on the Duffphone look. Weapons and armour are icon tiles (locked ones show the
## item as a black silhouette, so you can see what you're chasing); the right card shows the pick: Duff wearing
## it, name, stats, EQUIP / UPGRADE / DONE. Tiles are hidden buttons, so keys 1-7, Z-N and S still work.
const TILE: = 25.0
const GAP: = 2.0
const GX: = 7.0
const WY: = 34.0
const AY: = 76.0
const DETAIL: = Rect2(204, 24, 110, 152)

func _setup() -> void:
	title = "GEAR"
	time_limit = 0.0
	space_is_pen = false
	show_header = false
	pill_buttons = true
	g = m.gear if m else Gear.new_state()
	sel = str(g["weapon"])
	for i in Gear.WEAPONS.size():
		add_button(Gear.WEAPONS[i]["id"], Rect2(GX + i * (TILE + GAP), WY, TILE, TILE), "", WKEYS[i])["hide"] = true
	for i in Gear.ARMOR.size():
		add_button(Gear.ARMOR[i]["id"], Rect2(GX + i * (TILE + GAP), AY, TILE, TILE), "", AKEYS[i])["hide"] = true
	add_button("shades", Rect2(GX + Gear.ARMOR.size() * (TILE + GAP), AY, TILE, TILE), "", KEY_S)["hide"] = true
	add_button("equip", Rect2(DETAIL.position.x + 5, 128, DETAIL.size.x - 10, 13), "EQUIP", KEY_E, UiStyle.BTN_MAIN)
	add_button("upgrade", Rect2(DETAIL.position.x + 5, 143, DETAIL.size.x - 10, 13), "UPGRADE", KEY_U, UiStyle.BTN_ALT)
	add_button("done", Rect2(DETAIL.position.x + 5, 160, DETAIL.size.x - 10, 13), "DONE", KEY_ESCAPE, UiStyle.BTN_EXIT)
	_relabel()

func _relabel() -> void:
	for list in [Gear.WEAPONS, Gear.ARMOR]:
		for it in list:
			var b: = get_button(it["id"])
			var id: String = it["id"]
			if Gear.owns(g, id):
				var l: = Gear.level(g, id)
				var stat: = ("ATK %.1f" % (float(it["atk"]) + 0.5 * l)) if it.has("atk") else ("DEF %.1f" % (float(it["def"]) + 0.5 * l))
				var eq: = (str(g["weapon"]) == id or str(g["armor"]) == id)
				b["label"] = "%s%s +%d  %s" % ["[E] " if eq else "", it.get("short", it["name"]), l, stat]
				b["col"] = Color("#5a4a2a") if eq else Color("#57504e")
			else:
				b["label"] = ("??? (Elite Gala)" if bool(it.get("gala", false)) else "??? (tier %d)" % int(it["tier"]))
				b["col"] = Color("#24222e")
			# item icon on the row (kf_gear_*), mystery crate while it's locked
			var art: String = ("kf_gear_" + str({"golden_spatula": "spatula", "trust_fund": "coat"}.get(id, id))) if Gear.owns(g, id) else "kf_gear_locked"
			if Art.tex(art) != null:
				b["icon"] = art
			else:
				b.erase("icon")
			if id == sel:
				b["col"] = (b["col"] as Color).lightened(0.25)
	get_button("shades")["label"] = "Round shades (S): %s" % ("ON" if m != null and bool(m.shades) else "OFF")
	if Art.tex("kf_gear_shades") != null:
		get_button("shades")["icon"] = "kf_gear_shades"
	var up: = get_button("upgrade")
	if Gear.owns(g, sel) and Gear.level(g, sel) < Gear.MAX_LEVEL:
		up["label"] = "UPGRADE (%d scrap)" % Gear.upgrade_cost(sel, Gear.level(g, sel))
		up["enabled"] = Gear.can_upgrade(g, sel)
	else:
		up["label"] = "MAXED" if Gear.owns(g, sel) else "UPGRADE"
		up["enabled"] = false
	get_button("equip")["enabled"] = Gear.owns(g, sel) and str(g["weapon"]) != sel and str(g["armor"]) != sel

func _on_button(id: String) -> void:
	match id:
		"done":
			finish(1.0)
		"shades":
			sel = "shades"
			if m:
				m.shades = not bool(m.shades)
				flash("Round shades %s. Cosmetic only, zero stats, maximum vibes." % ("on" if m.shades else "off"), Color("#f2c66a"), 1.0)
			_relabel()
			return
		"equip":
			if Gear.equip(g, sel):
				flash("Equipped %s." % Gear.find(sel)["name"], Color("#c0d890"), 1.0)
				if m:
					m.apply_gear()
		"upgrade":
			if Gear.upgrade(g, sel):
				flash("%s is now +%d. {sister} would still roast it." % [Gear.find(sel)["name"], Gear.level(g, sel)], Color("#c0d890"), 1.2)
				if m:
					m.apply_gear()
			else:
				flash("I don't have enough scrap. {sister}'s {wordle} pays the best.", Color("#e06a4a"))
		_:
			sel = id
	_relabel()

func _art(id: String) -> String:
	return "kf_gear_" + str({"golden_spatula": "spatula", "trust_fund": "coat"}.get(id, id))

func _tile(b: Dictionary, id: String) -> void:
	var r: Rect2 = b["rect"]
	var owned: = id == "shades" or Gear.owns(g, id)
	var eq: = id == "shades" and m != null and bool(m.shades) or (str(g["weapon"]) == id or str(g["armor"]) == id)
	UiStyle.box(self, r, Color(UiStyle.GLASS.lightened(0.1 if owned else 0.02), 0.95), 5.0)
	if id == sel:
		UiStyle.box(self, r.grow(1.2), Color(UiStyle.GOLD, 0.95), 6.0)
		UiStyle.box(self, r, Color(UiStyle.GLASS.lightened(0.14), 1.0), 5.0)
	var art: = _art(id)
	if Art.tex(art) != null:
		var k: = (TILE - 5.0) / 40.0
		Art.image(self, art, r.get_center(), Color.WHITE if owned else Color(0, 0, 0, 0.8), k)
	if not owned:
		draw_string(UiStyle.display, r.position + Vector2(0, r.size.y * 0.5 + 4), "?", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, Color(1, 1, 1, 0.55))
	if eq:   # green equipped dot
		draw_circle(r.position + Vector2(4.5, 4.5), 2.6, Color("#07060a"))
		draw_circle(r.position + Vector2(4.5, 4.5), 2.0, Color("#34c759"))
	if owned and id != "shades" and Gear.level(g, id) > 0:
		var lv: = "+%d" % Gear.level(g, id)
		var lr: = Rect2(r.end.x - 11, r.end.y - 7.5, 10, 6.5)
		UiStyle.box(self, lr, Color("#07060a", 0.85), 3.0)
		draw_string(UiStyle.display, Vector2(lr.position.x, lr.end.y - 1.2), lv, HORIZONTAL_ALIGNMENT_CENTER, lr.size.x, 5, UiStyle.GOLD)

func _draw_game() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.03, 0.02, 0.06, 0.55))
	UiStyle.box(self, Rect2(0, 0, W, 19), Color(UiStyle.GLASS, 0.96), 0.0)
	draw_rect(Rect2(0, 19, W, 0.6), Color(1, 1, 1, 0.12))
	draw_string(UiStyle.display, Vector2(8, 13.5), "Gear", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	var chip: = "scrap %d" % int(g["scraps"])
	var cw: = UiStyle.display.get_string_size(chip, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10.0
	UiStyle.box(self, Rect2(W - cw - 6, 4, cw, 11), Color("#7a6a58"), 5.5)
	draw_string(UiStyle.display, Vector2(W - cw - 6, 12.3), chip, HORIZONTAL_ALIGNMENT_CENTER, cw, 7, Color.WHITE)
	draw_string(UiStyle.display, Vector2(GX + 2, WY - 3), "WEAPONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 0.5))
	draw_string(UiStyle.display, Vector2(GX + 2, AY - 3), "ARMOR + SHADES", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 0.5))
	for b in buttons:
		if b.get("hide", false):
			_tile(b, str(b["id"]))
	# stats strip under the grid
	var st: = "ATK %.1f     DEF %.1f  (-%d%% damage)" % [Gear.attack(g), Gear.defense(g), int(Gear.reduction(g) * 100.0)]
	UiStyle.box(self, Rect2(GX, 110, 7 * (TILE + GAP) - GAP, 13), Color(UiStyle.GLASS.lightened(0.06), 0.93), 5.0)
	draw_string(UiStyle.display, Vector2(GX, 119.5), st, HORIZONTAL_ALIGNMENT_CENTER, 7 * (TILE + GAP) - GAP, 7, Color.WHITE)
	if not Cast.touch:
		txt(Vector2(GX, 134), "Keys: weapons 1-7, armor Z X C V B N, shades S.", 6, Color(1, 1, 1, 0.45))
	# detail card
	UiStyle.glass(self, DETAIL, 7.0, 0.94, 1.0 / 1.5)
	draw_set_transform(Vector2(DETAIL.get_center().x, 66), 0.0, Vector2(1.25, 1.25))
	var arm: = str(g.get("armor", "apron"))
	if not ["apron", "clogs", "sleeves", "coat", "dad"].has(arm):
		arm = "apron"
	Art.frame(self, "duff_%s_red" % arm, Vector2.ZERO, 0, 0)
	if m != null and bool(m.shades):
		Art.frame(self, "duff_shades" if arm == "apron" else "duff_shades_" + arm, Vector2.ZERO, 0, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var x0: = DETAIL.position.x + 6
	var tw: = DETAIL.size.x - 12
	if sel == "shades":
		draw_string(UiStyle.display, Vector2(x0, 82), "Round shades", HORIZONTAL_ALIGNMENT_LEFT, tw, 8, UiStyle.GOLD)
		mtxt(Vector2(x0, 92), "Cosmetic only. Zero stats, maximum vibes.", tw, 6, Color(1, 1, 1, 0.8), 4)
		return
	var it: = Gear.find(sel)
	if it.is_empty():
		return
	if Gear.owns(g, sel):
		draw_string(UiStyle.display, Vector2(x0, 82), str(it["name"]), HORIZONTAL_ALIGNMENT_LEFT, tw, 8, UiStyle.GOLD)
		var l: = Gear.level(g, sel)
		var stat: = ("ATK %.1f" % (float(it["atk"]) + 0.5 * l)) if it.has("atk") else ("DEF %.1f" % (float(it["def"]) + 0.5 * l))
		txt(Vector2(x0, 91), "Tier %d  +%d   %s" % [int(it["tier"]), l, stat], 6, Color("#8cc4e8"))
		mtxt(Vector2(x0, 100), str(it["desc"]), tw, 6, Color(1, 1, 1, 0.8), 4)
	else:
		draw_string(UiStyle.display, Vector2(x0, 82), "Locked: tier %d %s" % [int(it["tier"]), "weapon" if it.has("atk") else "armor"], HORIZONTAL_ALIGNMENT_LEFT, tw, 7, UiStyle.GOLD)
		var how: = "Win {sister}'s {wordle} in 1-2 guesses to unlock the next piece."
		if sel == "cleaver":
			how = "Endgame. Only {sister} has it. Win her {wordle}."
		elif bool(it.get("gala", false)):
			how = "??? Rumor says the very rich keep the best kitchenware."
		mtxt(Vector2(x0, 92), how, tw, 6, Color(1, 1, 1, 0.8), 4)
