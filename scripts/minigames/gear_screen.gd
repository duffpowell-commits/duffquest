extends "res://scripts/minigames/minigame.gd"

const Gear: = preload("res://scripts/gear.gd")
const WKEYS: = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7]
const AKEYS: = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N]

var m: Node = null
var g: Dictionary = {}
var sel: = ""

func _setup() -> void:
	title = "GEAR"
	time_limit = 0.0
	space_is_pen = false
	g = m.gear if m else Gear.new_state()
	sel = str(g["weapon"])
	for i in Gear.WEAPONS.size():
		add_button(Gear.WEAPONS[i]["id"], Rect2(4, 14 + i * 15, 154, 14), "", WKEYS[i])
	for i in Gear.ARMOR.size():
		add_button(Gear.ARMOR[i]["id"], Rect2(162, 14 + i * 15, 154, 14), "", AKEYS[i])
	add_button("shades", Rect2(162, 106, 154, 14), "", KEY_S, Color("#5a3a6a"))
	add_button("equip", Rect2(4, 156, 92, 20), "EQUIP", KEY_E, Color("#2e5aa8"))
	add_button("upgrade", Rect2(100, 156, 130, 20), "UPGRADE", KEY_U, Color("#4e7a3a"))
	add_button("done", Rect2(234, 156, 82, 20), "DONE", KEY_ESCAPE, Color("#a43a2c"))
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
				flash("I don't have enough scrap. {sister}'s Wordle pays the best.", Color("#e06a4a"))
		_:
			sel = id
	_relabel()

func _draw_game() -> void:
	txt(Vector2(150, 9), "scrap: %d   ATK %.1f  DEF %.1f (-%d%%)" % [int(g["scraps"]), Gear.attack(g), Gear.defense(g), int(Gear.reduction(g) * 100.0)], 7, Color.WHITE)
	var it: = Gear.find(sel)
	if it.is_empty():
		return
	if Gear.owns(g, sel):
		txt(Vector2(6, 128), "%s  (tier %d)" % [it["name"], int(it["tier"])], 8, Color("#f2c66a"))
		txt(Vector2(6, 140), str(it["desc"]), 7, Color(1, 1, 1, 0.8))
	else:
		txt(Vector2(6, 128), "Locked. Tier %d %s." % [int(it["tier"]), "weapon" if it.has("atk") else "armor"], 8, Color("#f2c66a"))
		var how: = "Win {sister}'s Wordle in 1-2 guesses to unlock the next piece."
		if sel == "cleaver":
			how = "Endgame. Only {sister} has it. Win her Wordle."
		elif bool(it.get("gala", false)):
			how = "??? Rumor says the very rich keep the best kitchenware."
		txt(Vector2(6, 140), how, 7, Color(1, 1, 1, 0.8))
	txt(Vector2(6, 151), "Weapons: keys 1-7.  Armor: Z X C V B N.  Shades: S.", 6, Color(1, 1, 1, 0.45))

	draw_set_transform(Vector2(300, 150), 0.0, Vector2(1, 1))
	Art.frame(self, "duff_apron_red", Vector2.ZERO, 0, 0)
	if m != null and bool(m.shades):
		Art.frame(self, "duff_shades", Vector2.ZERO, 0, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
