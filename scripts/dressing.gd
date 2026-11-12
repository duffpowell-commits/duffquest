extends RefCounted
## Town street dressing (Grok, Nov 8): trees, clutter and fences from data/town_dressing.json.
## Items are y-sorted together with every actor by scripts/dressing_front.gd (Nov 9); the few
## tucked behind a storefront ("behind_building", tagged in main._ready) are drawn by main._draw_outside.

const Art: = preload("res://scripts/art.gd")
const FENCE_SEG: = 39.0   # world units per fence segment (tools/import_dressing.py FENCE_STRIDE / 2)

## [{a, p, s, wall (Rect2 or null), tree}] sorted by ground y.
static func load_items(path: String = "res://data/town_dressing.json") -> Array:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var out: Array = []
	if typeof(d) != TYPE_DICTIONARY:
		push_error("dressing: bad " + path)
		return out
	for o in d.get("objects", []):
		var p: = Vector2(float(o["p"][0]), float(o["p"][1]))
		var wall: Variant = null
		if o.get("tree", false):
			wall = Rect2(p - Vector2(4, 5), Vector2(8, 5))
		elif o.has("wall"):
			var ws: = Vector2(float(o["wall"][0]), float(o["wall"][1]))
			wall = Rect2(p - Vector2(ws.x / 2.0, ws.y), ws)
		out.append({"a": str(o["a"]), "p": p, "s": float(o.get("s", 1.0)), "wall": wall, "tree": bool(o.get("tree", false))})
	for f in d.get("fences", []):
		var p0: = Vector2(float(f["p"][0]), float(f["p"][1]))
		var n: = int(f["n"])
		var kind: = str(f["kind"])
		for i in n:
			out.append({"a": "sd_%s_straight" % kind, "p": p0 + Vector2(i * FENCE_SEG, 0), "s": 1.0, "wall": null, "tree": false})
		out.append({"a": "sd_%s_end" % kind, "p": p0 + Vector2(n * FENCE_SEG - FENCE_SEG / 2.0 + 1.0, 0), "s": 1.0, "wall": null, "tree": false, "end": true})
		out.append({"a": "", "p": p0, "s": 1.0, "wall": Rect2(p0 - Vector2(0, 5), Vector2(n * FENCE_SEG + 4.0, 5)), "tree": false})
	out.sort_custom(func(x, y): return x["p"].y < y["p"].y)
	return out

static func tree_points(items: Array) -> Array:
	var pts: Array = []
	for it in items:
		if it["tree"]:
			pts.append(it["p"] - Vector2(0, 5))
	return pts

static func draw_item(ci: CanvasItem, it: Dictionary, mod: Color = Color.WHITE) -> void:
	if str(it["a"]) == "":
		return
	var p: Vector2 = it["p"]
	if it.get("end", false):
		p -= Vector2(FENCE_SEG / 2.0 - 1.0, 0)   # end post art sits mid-cell
	elif casts_shadow(it):
		# soft contact shadow so props sit ON the street instead of floating (HD-2D pass, Nov 12)
		var w: = clampf(art_rect(it).size.x * (0.32 if it.get("tree", false) else 0.42), 4.0, 22.0)
		Art.shadow(ci, p, w, w * 0.32, 0.26 * mod.a)
	Art.image(ci, str(it["a"]), p, mod, float(it["s"]))

## Flat ground litter (leaves) and fence runs don't get a blob shadow.
static func casts_shadow(it: Dictionary) -> bool:
	var a: = str(it["a"])
	return not ("leaves" in a or "fence" in a or it.has("n"))

const SEE_THROUGH_ALPHA: = 0.45

## Body box (world units) for something whose feet are at `feet`.
static func body(feet: Vector2, w: float, h: float) -> Rect2:
	return Rect2(feet - Vector2(w / 2.0, h), Vector2(w, h))

## Screen area an item's sprite covers, in world units.
static func art_rect(it: Dictionary) -> Rect2:
	var a: = str(it["a"])
	var tx: = Art.tex(a)
	if tx == null:
		return Rect2()
	var inf: = Art.info(a)
	var k: = Art.density(inf) / float(it["s"])
	var org: Array = inf.get("origin", [tx.get_width() / 2, tx.get_height()])
	return Rect2(it["p"] - Vector2(float(org[0]), float(org[1])) / k, Vector2(tx.get_size()) / k)
