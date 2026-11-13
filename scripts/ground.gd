extends RefCounted
## Builds the outdoor ground from tiles (dual grid) and caches it as one texture.
## Layout: res://data/town_ground.txt (one letter per grid corner). Tiles: assets/art/ground/
## (cut from Grok's sheets by tools/import_ground.py). Each square between four corners gets the
## tile whose corners match: a full material, or a two-material transition (straight, outer, inner).

const LAYOUT: = "res://data/town_ground.txt"
const ATLAS: = "res://assets/art/ground/ground_atlas.png"
const INDEX: = "res://assets/art/ground/ground_atlas.json"
const LETTERS: = {"g": "grass", "s": "sidewalk", "a": "asphalt", "d": "dirt", "b": "brick", "v": "gravel"}

static var _tex: Texture2D = null
static var _origin: = Vector2.ZERO
static var warnings: PackedStringArray = []

## Origin of the built texture in art pixels (2 px per world unit, like map_outside).
static func origin() -> Vector2:
	return _origin

## Painted street (tools/import_street.py, Nov 11): same size + origin as the tile build. The tiles still get
## built once so the origin/layout parse stays the single source of truth, then the painting replaces them.
const PAINTED: = "res://assets/art/ground_painted.png"

## Web: the painted street arrives with the world pack; rebuild on the next texture() call.
static func clear_cache() -> void:
	_tex = null

static func texture() -> Texture2D:
	if _tex == null:
		_tex = _build()
		if ResourceLoader.exists(PAINTED):
			var p: = load(PAINTED) as Texture2D
			if p != null and p.get_size() == _tex.get_size():
				_tex = p
	return _tex

static func _build() -> Texture2D:
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	var atlas: Image = (load(ATLAS) as Texture2D).get_image()
	atlas.convert(Image.FORMAT_RGBA8)
	var tile: = int(index["tile"])
	var cols: = int(index["cols"])
	var grid: Array = []
	for line in FileAccess.get_file_as_string(LAYOUT).split("\n"):
		var l: = line.strip_edges()
		if l == "" or l.begins_with("#"):
			continue
		if l.begins_with("tile "):
			tile = int(l.split(" ")[1])
		elif l.begins_with("origin "):
			var p: = l.split(" ")
			_origin = Vector2(float(p[1]), float(p[2]))
		else:
			grid.append(l)
	var rows: = grid.size()
	var ncols: = (grid[0] as String).length()
	var img: = Image.create((ncols - 1) * tile, (rows - 1) * tile, false, Image.FORMAT_RGBA8)
	warnings.clear()
	var rng: = RandomNumberGenerator.new()
	rng.seed = 1890
	for j in rows - 1:
		for i in ncols - 1:
			var cs: = [str(grid[j][i]), str(grid[j][i + 1]), str(grid[j + 1][i]), str(grid[j + 1][i + 1])]
			var cell: = _pick(index, cs, rng, i, j)
			var src: = Rect2i((cell % cols) * tile, (cell / cols) * tile, tile, tile)
			img.blit_rect(atlas, src, Vector2i(i * tile, j * tile))
	return ImageTexture.create_from_image(img)

static func _pick(index: Dictionary, cs: Array, rng: RandomNumberGenerator, i: int, j: int) -> int:
	var mats: Dictionary = index["materials"]
	var kinds: = {}
	for c in cs:
		kinds[c] = true
	if kinds.size() == 1:
		var v: Array = mats.get(LETTERS.get(cs[0], "grass"), mats["grass"])
		return int(v[rng.randi() % v.size()])
	if kinds.size() == 2:
		var ks: = kinds.keys()
		for order in [[ks[0], ks[1]], [ks[1], ks[0]]]:
			var a: String = LETTERS.get(order[0], "")
			var b: String = LETTERS.get(order[1], "")
			var mask: = ""
			for c in cs:
				mask += "1" if c == order[0] else "0"
			var key: = "%s|%s|%s" % [a, b, mask]
			if index["transitions"].has(key):
				return int(index["transitions"][key])
	warnings.append("no tile for corners %s at square (%d,%d); using %s" % [str(cs), i, j, cs[0]])
	var f: Array = mats.get(LETTERS.get(cs[0], "grass"), mats["grass"])
	return int(f[0])
