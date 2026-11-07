extends RefCounted

const DIR: = "res://assets/art/"
const Manifest: = preload("res://scripts/art_manifest.gd")
const WALK: = [1, 0, 2, 0]

static var _tex: = {}

static func info(name: String) -> Dictionary:
	return Manifest.ASSETS.get(name, {})

static func names() -> Array:
	return Manifest.ASSETS.keys()

static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var p: = DIR + name + ".png"
		_tex[name] = load(p) as Texture2D if ResourceLoader.exists(p) else null
	return _tex[name]

static func clear_cache() -> void:
	_tex.clear()

static func row_for(v: Vector2) -> int:
	if absf(v.x) > absf(v.y):
		return 2 if v.x > 0.0 else 3
	return 1 if v.y < 0.0 else 0

static func walk_col(t: float, moving: bool, fps: float = 8.0) -> int:
	return int(WALK[int(t * fps) % 4]) if moving else 0

static func frame(ci: CanvasItem, name: String, pos: Vector2, col: int = 0, row: int = 0, modulate: Color = Color.WHITE) -> void:

	var tx: = tex(name)
	if tx == null:
		return
	var inf: = info(name)
	var cell: Array = inf.get("cell", [tx.get_width(), tx.get_height()])
	var org: Array = inf.get("origin", [0, 0])
	var cw: = float(cell[0])
	var chh: = float(cell[1])
	var k: = density(inf)
	var src: = Rect2(col * cw, row * chh, cw, chh)
	ci.draw_texture_rect_region(tx, Rect2(pos - Vector2(float(org[0]), float(org[1])) / k, Vector2(cw, chh) / k), src, modulate)

static func image(ci: CanvasItem, name: String, pos: Vector2, modulate: Color = Color.WHITE, scale: float = 1.0) -> void:

	var tx: = tex(name)
	if tx == null:
		return
	var inf: = info(name)
	var org: Array = inf.get("origin", [0, 0])
	var k: = density(inf)
	var sz: = Vector2(tx.get_width(), tx.get_height()) * scale / k
	ci.draw_texture_rect(tx, Rect2(pos - Vector2(float(org[0]), float(org[1])) * scale / k, sz), false, modulate)

static func density(inf: Dictionary) -> float:

	var k: = float(inf.get("s", 1.0))
	return k if k > 0.0 else 1.0

static func logical_size(name: String) -> Vector2:

	var tx: = tex(name)
	if tx == null:
		return Vector2.ZERO
	return Vector2(tx.get_width(), tx.get_height()) / density(info(name))

static func shadow(ci: CanvasItem, foot: Vector2, w: float = 7.0, h: float = 2.4, a: float = 0.32) -> void:

	var c: = foot + Vector2(1.2, 0.2)
	for i in 2:
		var k: = 1.0 - 0.28 * float(i)
		var pts: = PackedVector2Array()
		for j in 14:
			var an: = TAU * float(j) / 14.0
			pts.append(c + Vector2(cos(an) * w * (1.25 - 0.3 * k), sin(an) * h * (1.25 - 0.3 * k)))
		ci.draw_colored_polygon(pts, Color(0.11, 0.08, 0.05, a * (0.45 if i == 0 else 0.75)))

const DUFF_MOODS: = ["smirk", "tired", "happy"]
const HAPPY_WORDS: = ["!", "<3", "love", "yes", "great", "nice", "happy", "+", "win", "best", "achievement", "thank", "hero", "perfect", "bravo", "heck yeah", "hell yeah", "baby", "promoted", "victory"]
const TIRED_WORDS: = ["...", "ugh", "tired", "late", "-$", "fee", "pass out", "passed out", "sigh", "exhausted", "broke", "docked", "no energy", "drained", "can't", "rent", "bill", "ow", "oof", "fail",
	"damn", "dammit", "shit", "hell", "crap", "dang", "heck", "landlord", "insurance", "declined", "denied", "hold", "stressed", "complaint", "regret", "collections"]
static var _mood_rx: Dictionary = {}

static func _has_word(l: String, w: String) -> bool:

	if not w.replace(" ", "").replace("'", "").is_valid_identifier():
		return l.contains(w)
	if not _mood_rx.has(w):
		var rx: = RegEx.new()
		rx.compile("\\b" + w + "\\b")
		_mood_rx[w] = rx
	return (_mood_rx[w] as RegEx).search(l) != null

static func duff_mood(text: String, energy: float = 100.0) -> int:

	var l: = text.to_lower()
	var tired: = 0
	var happy: = 0
	for w in TIRED_WORDS:
		if _has_word(l, w):
			tired += 1
	for w in HAPPY_WORDS:
		if _has_word(l, w):
			happy += 1
	if l.contains("yeah") and (l.contains("heck") or l.contains("hell")):
		tired -= 1
	if tired > happy:
		return 1
	if happy > tired:
		return 2
	return 1 if energy < 25.0 else 0

const NPC_SPEAKERS: = ["Brittany", "Dolores", "Earl", "Karen", "Linda", "Scammer", "Inspector Tiny", "Brenda", "Palm Beach Pete", "Security", "Chef", "Landlord",
	"Server", "Grill-Boy", "Grill-Boy Brayden", "Brayden", "Jeeves", "Elon Husk", "Jeff Bozos", "Bill Fences", "The Donald", "Expo", "Butler", "Theo"]

static func is_duff_line(text: String, hero: String) -> bool:

	var c: = text.find(": ")
	if c < 0 or c > 28:
		return true
	var who: = text.substr(0, c)
	if who == hero or who == "You" or who.to_lower() == "me":
		return true
	if who in NPC_SPEAKERS:
		return false
	return not (who in preload("res://scripts/cast.gd").names().values())

static func portrait_for(text: String, hero: String, partner: String, baby: String) -> String:
	if text.begins_with(partner + ": "):
		return "madison"
	if text.begins_with(baby + " ") or text.begins_with(baby + "'s ") or text.begins_with(baby + ": "):
		return "octavia"
	return "duff" if is_duff_line(text, hero) else ""

static func madison_mood(text: String, happiness: float, kind: String = "") -> int:
	if kind == "upset" or happiness < 40.0:
		return 2
	var l: = text.to_lower()
	if kind == "fussy" or happiness < 70.0:
		return 0 if (l.contains("<3") or l.contains("love") or l.contains("!!")) else 1
	return 1 if (l.contains("ugh") or l.contains("seriously")) else 0

static func octavia_mood(text: String) -> int:
	var l: = text.to_lower()
	if l.contains("asleep") or l.contains("sleep") or l.contains("nap") or l.contains("3 am"):
		return 2
	if l.contains("gurgle") or l.contains("giggle") or l.contains("laugh") or l.contains("!") or l.contains("happy"):
		return 1
	return 0

static func family_portrait(ci: CanvasItem, who: String, pos: Vector2, mood: int, shades: bool = false) -> void:
	match who:
		"madison": frame(ci, "portrait_madison", pos, clampi(mood, 0, 2), 0)
		"octavia": frame(ci, "portrait_octavia", pos, clampi(mood, 0, 2), 0)
		_: duff_portrait(ci, pos, mood, shades)

static func duff_portrait(ci: CanvasItem, pos: Vector2, mood: int, shades: bool = false, modulate: Color = Color.WHITE) -> void:

	frame(ci, "portrait_duff", pos, clampi(mood, 0, 2), 1 if shades else 0, modulate)

static func person(ci: CanvasItem, name: String, pos: Vector2, dir: Vector2 = Vector2.DOWN, t: float = 0.0, moving: bool = false, attack: bool = false, modulate: Color = Color.WHITE, with_shadow: bool = true) -> void:
	if with_shadow and modulate.a > 0.2:
		shadow(ci, pos, 6.0, 2.0, 0.3 * modulate.a)
	frame(ci, name, pos, 3 if attack else walk_col(t, moving), row_for(dir), modulate)
