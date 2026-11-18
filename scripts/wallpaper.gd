extends RefCounted
## Loading-screen art reused as wallpapers (Nov 17, Duff's ask):
## - Duff's phone home screen shows one per in-game day (sharp, like a real lock screen).
## - Menus with no world frame to blur (shift menus, cold boot) get a blurred, rotating one instead of the
##   old sunburst. Only screens whose jpg is mounted count (web: most arrive with the late pack).
const DIR: = "res://assets/art/loading/%s.jpg"

static var _ids: Array = []
static var _blur: = {}      # id -> blurred ImageTexture
static var _turn: = 0

static func ids() -> Array:
	if _ids.is_empty():
		var f: = FileAccess.open("res://data/loading_screens.json", FileAccess.READ)
		if f:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				for s in d.get("screens", []):
					_ids.append(str(s["id"]))
	return _ids.filter(func(i): return ResourceLoader.exists(DIR % i))

static var _sharp: = {}     # id -> 640x360 ImageTexture

## The wallpaper for in-game day `day` (same all day, a new one tomorrow). Rebuilt from the image at 640x360
## (half size, smoothly filtered): the phone screen never shows more, and it skips the 1280 texture's shimmer.
static func for_day(day: int) -> Texture2D:
	var a: = ids()
	if a.is_empty():
		return null
	var id: String = a[posmod(day, a.size())]
	if not _sharp.has(id):
		var img: = _image(id)
		if img == null:
			return null
		img.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		_trim(_sharp)
		_sharp[id] = ImageTexture.create_from_image(img)
	return _sharp[id]

## Keep at most two of each (Nov 18: iPhone memory); older ones rebuild if they come round again.
static func _trim(cache: Dictionary) -> void:
	while cache.size() >= 2:
		cache.erase(cache.keys()[0])

static func _image(id: String) -> Image:
	var tex: Texture2D = load(DIR % id)
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty():
		return null
	if img.is_compressed():
		img.decompress()
	return img

## Next blurred wallpaper (rotates each call), 320x180, for menu backdrops.
static func blurred_next() -> Texture2D:
	var a: = ids()
	if a.is_empty():
		return null
	_turn += 1
	var id: String = a[posmod(_turn, a.size())]
	if _blur.has(id):
		return _blur[id]
	_trim(_blur)
	var img: = _image(id)
	if img == null:
		return null
	for sz in [Vector2i(640, 360), Vector2i(320, 180), Vector2i(160, 90), Vector2i(80, 45), Vector2i(40, 23), Vector2i(80, 45), Vector2i(160, 90), Vector2i(320, 180)]:
		img.resize(sz.x, sz.y, Image.INTERPOLATE_BILINEAR)
	_blur[id] = ImageTexture.create_from_image(img)
	return _blur[id]
