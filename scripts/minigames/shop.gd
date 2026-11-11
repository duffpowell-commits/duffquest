extends "res://scripts/minigames/minigame.gd"

const ITEMS: = [
	["honey buns", "Honey buns", 3], ["formula", "Formula", 12], ["diapers", "Diapers", 10],
	["cherries", "Cherries", 3], ["chocolate", "Chocolate", 3], ["cream", "Heavy cream", 2],
	["flour", "Flour", 2], ["eggs", "Eggs", 3], ["treats", "Cat treats", 2], ["ensure", "Ensure", 4],
]
const KEYS: = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]

var m: Node = null

func _setup() -> void:
	backdrop = "kwik"
	backdrop_dim = 0.45
	title = "KWIK-N-GO  (now with surge pricing)"
	time_limit = 0.0
	space_is_pen = false
	for i in ITEMS.size():
		var it: Array = ITEMS[i]
		var b: = add_button(it[0], Rect2(118 + (i % 2) * 100, 30 + (i / 2) * 24, 96, 21), "", KEYS[i])   # right block: the left third shows the painted store
		b["icon"] = "kf_shop_" + str(it[0]).split(" ")[0]   # shelf tile: the product itself, not a teal slab
	add_button("done", Rect2(216, 154, 98, 22), "DONE", KEY_ESCAPE, Color("#a43a2c"))
	_relabel()

func price(id: String) -> int:
	for it in ITEMS:
		if it[0] == id:
			var mult: float = m.price_mult() if m and m.has_method("price_mult") else 1.0
			var extra: int = m.formula_extra() if m and id == "formula" and m.has_method("formula_extra") else 0
			return int(ceil((int(it[2]) + extra) * mult))
	return 0

func _relabel() -> void:
	for it in ITEMS:
		var have: = int(m.inventory.get(it[0], 0)) if m else 0
		get_button(it[0])["label"] = "%s $%d\nhave %d" % [it[1], price(it[0]), have]

func buy(id: String) -> bool:
	var p: = price(id)
	if m == null or m.money < p:
		flash("My card gets declined. Now the cashier looks up. Broke is the only way to get seen in here.", Color("#e06a4a"))
		return false
	m.money -= p
	m.inventory[id] = int(m.inventory.get(id, 0)) + 1
	flash("Bought %s. -$%d" % [id, p], Color("#c0d890"), 0.9)
	_relabel()
	return true

func _on_button(id: String) -> void:
	if id == "done":
		finish(1.0)
	else:
		buy(id)

func _draw_game() -> void:
	txt(Vector2(6, 24), "Cash: $%d" % (m.money if m else 0), 8, Color("#f2c66a"))
	txt(Vector2(150, 24), "Cake = cherries, chocolate, cream, flour, eggs", 6, Color(1, 1, 1, 0.6))
