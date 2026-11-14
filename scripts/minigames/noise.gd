extends "res://scripts/minigames/minigame.gd"
## "Too Loud" (scripts/too_loud.gd): Hy-Whee on a Saturday. The noise meter climbs; dig {partner}'s headphones out
## of the bag before it fills. Wrong grabs add noise. Meter full = they leave the cart (score 0); never a game over.

const ITEMS: = [
	["headphones", "Headphones", ""],
	["diapers", "Diapers", "kf_shop_diapers"],
	["formula", "Formula", "kf_shop_formula"],
	["honey", "Honey", "kf_shop_honey"],
	["chocolate", "Chocolate", "kf_shop_chocolate"],
	["treats", "Treats", "kf_shop_treats"],
]
const WRONG: = {
	"diapers": "Diapers. Wrong, but never useless.",
	"formula": "Formula. That's {baby}'s.",
	"honey": "My honey. Why is my honey in her bag?",
	"chocolate": "Emergency chocolate. Different emergency.",
	"treats": "Treats. {stray} isn't even here.",
}
const NOISES: = ["SQUEAK", "BEEP", "CLEANUP ON AISLE 3", "WAAAH", "*cart rattle*", "PRICE CHECK", "SQUEAK SQUEAK", "*crash*", "ATTENTION SHOPPERS"]
const FILL_TIME: = 14.0
const WRONG_COST: = 0.14

var level: = 0.0
var extra: = 0.0
var pops: Array = []    # [text, pos, life]
var pop_t: = 0.0
var say: = ""
var rng: = RandomNumberGenerator.new()

func _setup() -> void:
	backdrop = "grocery"
	backdrop_dim = 0.35
	title = "TOO LOUD  (find her headphones)"
	time_limit = -1.0
	space_is_pen = false
	rng.seed = int(ctx.get("seed", 11))
	var order: = range(ITEMS.size())
	for i in range(order.size() - 1, 0, -1):
		var j: = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	for k in order.size():
		var it: Array = ITEMS[order[k]]
		var r: = Rect2(150 + (k % 3) * 56, 62 + (k / 3) * 50, 52, 46)
		var b: = add_button(str(it[0]), r, str(it[1]), KEY_1 + k, Color("#5b4c46"))
		b["icon"] = str(it[2])   # headphones: blank card, drawn in _draw_top
		b["stack"] = true
	say = "{partner}: \"I'm good. Totally good.\""

func _on_button(id: String) -> void:
	if done:
		return
	if id == "headphones":
		finish(1.0, "headphones")
		return
	extra += WRONG_COST
	flash(Cast.T(str(WRONG.get(id, "Nope."))), Color("#f0c070"), 1.6)
	get_button(id)["enabled"] = false

func _tick(d: float) -> void:
	level = clampf(t / FILL_TIME + extra, 0.0, 1.0)
	if level >= 1.0:
		finish(0.0, "bailed")
		return
	if level > 0.66:
		say = "{partner} is still smiling. Her hands aren't."
	elif level > 0.33:
		say = "{partner}: \"Totally good.\" (Her jaw is doing a thing.)"
	pop_t -= d
	if pop_t <= 0.0:
		pop_t = lerpf(0.55, 0.12, level)
		pops.append([NOISES[rng.randi_range(0, NOISES.size() - 1)], Vector2(rng.randf_range(16, 300), rng.randf_range(44, 150)), 1.6])
	for p in pops:
		p[2] = float(p[2]) - d
	pops = pops.filter(func (p: Array) -> bool: return float(p[2]) > 0.0)

func debug_solve(good: bool) -> void:
	if good:
		press("headphones")
	else:
		extra = 1.0
		_tick(0.0)

func _draw_game() -> void:
	# the room gets louder: noise words pop everywhere, and they shake harder as the meter climbs
	var shake: = level * 3.0
	for p in pops:
		var j: = Vector2(rng.randf_range(-shake, shake), rng.randf_range(-shake, shake))
		var a: = clampf(float(p[2]) / 0.4, 0.0, 1.0)
		UiStyle.label(self, (p[1] as Vector2) + j, str(p[0]), 8 + int(level * 7.0), Color(1.0, 0.9, 0.75, a * (0.6 + 0.4 * level)), -1.0, HORIZONTAL_ALIGNMENT_LEFT, 3)
	# her, holding it together (the bag is on the right)
	var mj: = Vector2(rng.randf_range(-shake, shake) * 0.3, 0.0)
	draw_set_transform(Vector2(70, 150) + mj, 0.0, Vector2(2, 2))
	Art.frame(self, "ch_madison", Vector2.ZERO, 0, 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	UiStyle.tag(self, Vector2(8, 172), Cast.T(say), 8)
	# noise meter
	UiStyle.tag(self, Vector2(150, 34), "NOISE", 8)
	bar(Rect2(184, 26, 126, 9), level, Color("#e0603a").lerp(Color("#ff2a2a"), level))
	UiStyle.tag(self, Vector2(150, 56), "her bag", 7)

## Her headphones have no kitchen-sheet icon: draw a pair on their card (band + two cups), same ink as UiStyle props.
func _draw_top() -> void:
	var b: = get_button("headphones")
	if b.is_empty():
		return
	var r: Rect2 = b["rect"]
	if not bool(b.get("down", false)):
		prop(r.grow(-1.0), Color("#fbf0d9"), 0.0)
		draw_string(UiStyle.display, Vector2(r.position.x, r.end.y - 5), "Headphones", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 7, UiStyle.INK)
	var c: = r.position + Vector2(r.size.x * 0.5, 22)
	draw_arc(c, 11.0, PI, TAU, 18, UiStyle.INK, 5.0)
	draw_arc(c, 11.0, PI, TAU, 18, Color("#d9567a"), 3.0)
	prop(Rect2(c.x - 15, c.y - 3, 7, 11), Color("#3a3240"), 0.3)
	prop(Rect2(c.x + 8, c.y - 3, 7, 11), Color("#3a3240"), 0.3)
