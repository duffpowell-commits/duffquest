extends RefCounted


const DIR: = "res://assets/art/"
const Manifest: = preload("res://scripts/art_manifest.gd")
const CastScript: = preload("res://scripts/cast.gd")
const WALK: = [1, 0, 2, 0]

static var _tex: = {}
## Set by game.gd when the HD portrait overlay is running (full-resolution dialogue faces).
static var hd_enabled: = false

static func info(name: String) -> Dictionary:
	return Manifest.ASSETS.get(name, {})

static func names() -> Array:
	return Manifest.ASSETS.keys()

## Public edition: `<file>_pub.<ext>` replaces `<file>.<ext>` when it exists (renamed signs, the made-up final
## boss). The family edition (Cast.family) always gets the original.
static func pub(p: String) -> String:
	if CastScript.family:
		return p
	var alt: = p.get_basename() + "_pub." + p.get_extension()
	return alt if ResourceLoader.exists(alt) else p

static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var p: = pub(DIR + name + ".png")
		_tex[name] = load(p) as Texture2D if ResourceLoader.exists(p) else null
	return _tex[name]

static func clear_cache() -> void :
	_tex.clear()

## Pixel size + opaque rect of every storefront (sf_*) and street prop (sd_*), baked into data/art_rects.json by
## tools/bake_art_rects.gd. main.gd builds the walls from these at startup, so on the web the walls are right
## before world.pck (which carries the art itself) has arrived. test_daily checks they match the textures.
const RECTS: = "res://data/art_rects.json"
static var _rects: Variant = null

static func _baked(name: String) -> Dictionary:
	if _rects == null:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(RECTS)) if FileAccess.file_exists(RECTS) else null
		_rects = d if d is Dictionary else {}
	return (_rects as Dictionary).get(name, {})

## Texture size in pixels: the texture's own, else the baked one, else zero.
static func tex_size(name: String) -> Vector2:
	var tx: = tex(name)
	if tx != null:
		return Vector2(tx.get_size())
	var b: = _baked(name)
	return Vector2(b["size"][0], b["size"][1]) if b.has("size") else Vector2.ZERO

## Opaque pixels of the texture: baked when known (no get_image() at startup), else measured, else empty.
static func used_rect(name: String) -> Rect2i:
	var b: = _baked(name)
	if b.has("used"):
		var u: Array = b["used"]
		return Rect2i(int(u[0]), int(u[1]), int(u[2]), int(u[3]))
	var tx: = tex(name)
	return tx.get_image().get_used_rect() if tx != null else Rect2i()

static func row_for(v: Vector2) -> int:
	if absf(v.x) > absf(v.y):
		return 2 if v.x > 0.0 else 3
	return 1 if v.y < 0.0 else 0

static func walk_col(t: float, moving: bool, fps: float = 8.0) -> int:
	return int(WALK[int(t * fps) % 4]) if moving else 0

static func frame(ci: CanvasItem, name: String, pos: Vector2, col: int = 0, row: int = 0, modulate: Color = Color.WHITE) -> void :

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
	ci.draw_texture_rect_region(tx, Rect2((pos * k).round() / k - Vector2(float(org[0]), float(org[1])) / k, Vector2(cw, chh) / k), src, modulate)

static func image(ci: CanvasItem, name: String, pos: Vector2, modulate: Color = Color.WHITE, scale: float = 1.0) -> void :

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

static var _soft_shadow: Texture2D
## Set each frame by hd_presentation.gd from the clock: where the sun throws shadows, and how long they get.
static var sun_shift: = Vector2.ZERO
static var sun_stretch: = 1.0
static func shadow(ci: CanvasItem, foot: Vector2, w: float = 7.0, h: float = 2.4, a: float = 0.32) -> void:
	if _soft_shadow == null:
		var image := Image.create_empty(64,24,false,Image.FORMAT_RGBA8)
		for y in 24:
			for x in 64:
				var d := Vector2((x-32.0)/32.0,(y-12.0)/12.0).length()
				image.set_pixel(x,y,Color(0.12,0.13,0.17,pow(maxf(0.0,1.0-d),1.6)))
		_soft_shadow = ImageTexture.create_from_image(image)
	var sw: = w * sun_stretch
	var c: = foot + Vector2(1, 0) + sun_shift * (w / 6.0)
	ci.draw_texture_rect(_soft_shadow,Rect2(c.round()-Vector2(sw*1.3,h*1.7),Vector2(sw*2.6,h*3.4)),false,Color(1,1,1,a))

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
	"Server", "Grill-Boy", "Grill-Boy Brayden", "Brayden", "Jeeves", "Expo", "Butler", "Theo"]

static var _boss_names: Array = []

## Every boss's display name (cast tokens resolved). Bounty bosses ("The Allergy Liar: ...") used to
## fall through to Duff's portrait. Loaded lazily: boss.gd preloads this script.
static func boss_names() -> Array:
	if _boss_names.is_empty():
		var bosses: Dictionary = load("res://scripts/boss.gd").BOSSES
		var cast: = preload("res://scripts/cast.gd")
		for k in bosses:
			_boss_names.append(cast.T(str(bosses[k]["name"])))
	return _boss_names

static func is_duff_line(text: String, hero: String) -> bool:

	var c: = text.find(": ")
	if c < 0 or c > 28:
		return true
	var who: = text.substr(0, c)
	if who == hero or who == "You" or who.to_lower() == "me":
		return true
	if who in NPC_SPEAKERS or who in boss_names():
		return false
	return not (who in preload("res://scripts/cast.gd").names().values())


static var _boss_by_name: Dictionary = {}

## Boss kind ("husk", "willnot"...) if this dialogue line is spoken by a boss, else "".
## A line that yells: an ALL-CAPS word of 4+ letters ("A WORKER?", "LATE FEE!") or two '!'.
static func _shouty(body: String) -> bool:
	if body.count("!") >= 2:
		return true
	var rx: = RegEx.create_from_string("\\b[A-Z]{4,}\\b")
	return rx.search(body) != null

static func boss_speaker(text: String) -> String:
	if _boss_by_name.is_empty():
		var bosses: Dictionary = load("res://scripts/boss.gd").BOSSES
		var cast: = preload("res://scripts/cast.gd")
		for k in bosses:
			_boss_by_name[cast.T(str(bosses[k]["name"]))] = k
	var c: = text.find(": ")
	return str(_boss_by_name.get(text.substr(0, c), "")) if c > 0 else ""

## Boss intro cards (boss_intro/<id>.png) that still show the OLD lettered names (the billionaire parodies,
## retired Nov 9 for the gala exes). Their intros fall back to the plain dialogue box until new cards land
## (docs/gala_exes_art_brief.md); then drop the id from this list.
const RETIRED_CARDS: = []

static func has_intro_card(kind: String) -> bool:
	return kind != "" and not (kind in RETIRED_CARDS) and ResourceLoader.exists("res://assets/art/boss_intro/%s.png" % kind)

## Boss kind if this line is that boss's intro (the line that gets the full-screen splash), else "".
static func boss_intro_for(text: String) -> String:
	var k: = boss_speaker(text)
	if k == "":
		return ""
	var b: Dictionary = load("res://scripts/boss.gd").BOSSES[k]
	return k if text == preload("res://scripts/cast.gd").T(str(b["intro"])) else ""

static func portrait_for(text: String, hero: String, partner: String, baby: String) -> String:
	if hd_enabled and text.begins_with("Brittany: "):
		return "brittany"
	if hd_enabled and text.begins_with("Dolores"):      # 'Dolores leans in: "..."', 'Dolores (31 years in): ...'
		return "dolores"
	if hd_enabled:
		var boss: = boss_speaker(text)
		if boss != "":
			return boss                                    # HD only: no pixel boss portraits
	if text.begins_with(partner + ": ") or text.begins_with(partner + " texts"):
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

## HD cartoon portraits (assets/art/portraits_hd/<who>.png, 3 cells: happy, deadpan, furious).
const HD_PORTRAITS: = ["duff", "madison", "octavia", "brittany", "dolores"]
const ANGRY_WORDS: = ["pissed", "furious", "stole", "steal", "stealing", "thief", "hate", "rage", "seriously", "unbelievable", "wtf", "screw"]
const WAIL_WORDS: = ["cry", "cries", "crying", "wail", "wails", "scream", "screams", "screaming", "fuss", "fussy", "shriek", "shrieks", "meltdown"]

## Which HD expression cell (0 happy, 1 deadpan, 2 furious) fits this line.
static func hd_mood(who: String, line: String, energy: float, happiness: float, kind: String) -> int:
	var l: = line.to_lower()
	if boss_speaker(line) == who and who != "":
		# boss sheets: 0 smug, 1 shocked, 2 enraged
		var b: Dictionary = load("res://scripts/boss.gd").BOSSES[who]
		var cast: = preload("res://scripts/cast.gd")
		if line == cast.T(str(b.get("rage", ""))):
			return 2
		if line == cast.T(str(b.get("defeat", ""))):
			return 1
		return 2 if _shouty(line.substr(line.find(": ") + 2)) else 0
	match who:
		"madison":
			return madison_mood(line, happiness, kind)          # same order: happy, meh, upset
		"octavia":
			for w in WAIL_WORDS:
				if _has_word(l, w):
					return 2
			return 0 if octavia_mood(line) == 1 else 1
		"brittany", "dolores":
			for w in ANGRY_WORDS:
				if _has_word(l, w):
					return 2
			for w in HAPPY_WORDS:
				if _has_word(l, w):
					return 0
			return 1
	for w in ANGRY_WORDS:
		if _has_word(l, w):
			return 2
	return 0 if duff_mood(line, energy) == 2 else 1             # old: 0 neutral, 1 tired, 2 happy

static func family_portrait(ci: CanvasItem, who: String, pos: Vector2, mood: int, shades: bool = false) -> void :
	if who in load("res://scripts/boss.gd").BOSSES:
		return                                                     # bosses: HD portraits only
	match who:
		"brittany": pass                                           # HD only
		"madison": frame(ci, "portrait_madison", pos, clampi(mood, 0, 2), 0)
		"octavia": frame(ci, "portrait_octavia", pos, clampi(mood, 0, 2), 0)
		_: duff_portrait(ci, pos, mood, shades)

static func duff_portrait(ci: CanvasItem, pos: Vector2, mood: int, shades: bool = false, modulate: Color = Color.WHITE) -> void :

	frame(ci, "portrait_duff", pos, clampi(mood, 0, 2), 1 if shades else 0, modulate)

static func person(ci: CanvasItem, name: String, pos: Vector2, dir: Vector2 = Vector2.DOWN, t: float = 0.0, moving: bool = false, attack: bool = false, modulate: Color = Color.WHITE, with_shadow: bool = true) -> void :
	if with_shadow and modulate.a > 0.2:
		shadow(ci, pos, 6.0, 2.0, 0.3 * modulate.a)
	frame(ci, name, pos, 3 if attack else walk_col(t, moving), row_for(dir), modulate)
