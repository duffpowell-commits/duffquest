extends Node
## Web only: index.pck ships just what the title screen needs (scripts, data, fonts, sfx, storefronts, street
## props, ground tiles, small UI art). The rest comes in two packs next to index.html, built by
## tools/make_extra_pack.gd and downloaded one after the other right after boot:
##   world.pck  characters, HD portraits, music, kitchen/home/gala/arena art. main.gd holds "Continue" and
##              "New Game" on a "Loading Omaha" card until this one is mounted (world_ready).
##   extra.pck  knockout stills, boss intro cards, most loading screens, minigame backdrops. Nothing waits
##              for it; every loader already copes with a missing texture until it lands.
## After each mount the art and audio caches forget their "missing" answers and group "extra_pack" gets
## extra_pack_loaded(). Desktop/Android builds have everything in one pack, so this does nothing there.

const Art: = preload("res://scripts/art.gd")
const Audio: = preload("res://scripts/audio.gd")
const Ground: = preload("res://scripts/ground.gd")
## [file next to index.html, a folder that only exists once that pack is mounted]
const PACKS: = [["world.pck", "res://assets/art/portraits_hd/"], ["extra.pck", "res://assets/art/ko/"]]
const RETRIES: = 3

static var world_ready: = not OS.has_feature("web")   # world.pck mounted (or not needed): safe to start playing
static var loaded: = not OS.has_feature("web")        # every pack mounted
static var progress: = 0.0        # 0..1 of world.pck, for the loading card (-1 while its size is unknown)
static var got_mb: = 0.0          # MB of world.pck downloaded so far
var _http: HTTPRequest
var _i: = 0
var _tries: = 0

static func _present(probe: String) -> bool:
	return DirAccess.dir_exists_absolute(probe) and not DirAccess.get_files_at(probe).is_empty()

func _ready() -> void:
	world_ready = not OS.has_feature("web") or _present(PACKS[0][1])
	loaded = not OS.has_feature("web") or _present(PACKS[1][1])
	if world_ready and loaded:
		progress = 1.0
		return
	_i = 0 if not world_ready else 1
	_http = HTTPRequest.new()
	_http.use_threads = false
	add_child(_http)
	_http.request_completed.connect(_on_done)
	_fetch()

func _process(_d: float) -> void:
	if _http and _i == 0:
		var total: = _http.get_body_size()
		got_mb = _http.get_downloaded_bytes() / 1048576.0
		progress = clampf(float(_http.get_downloaded_bytes()) / total, 0.0, 1.0) if total > 0 else -1.0

func _local() -> String:
	return "user://" + str(PACKS[_i][0])

func _fetch() -> void:
	_tries += 1
	_http.download_file = _local()
	# relative to the page, so it follows itch's per-build upload folder (no stale cache across builds)
	var url: = str(JavaScriptBridge.eval("new URL('%s', document.baseURI).href" % PACKS[_i][0], true))
	var err: = _http.request(url)
	if err != OK:
		push_warning("%s: request failed to start (%d)" % [PACKS[_i][0], err])

func _on_done(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	var name: String = PACKS[_i][0]
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and ProjectSettings.load_resource_pack(_local(), false):
		print("%s: mounted (%d files in %s)" % [name, DirAccess.get_files_at(PACKS[_i][1]).size(), PACKS[_i][1]])
		_next()
		return
	push_warning("%s: download failed (result %d, http %d), try %d" % [name, result, code, _tries])
	if _tries < RETRIES:
		get_tree().create_timer(4.0 * _tries).timeout.connect(_fetch)
	else:
		_next()   # give up on this pack: play on with the fallbacks rather than wait forever

func _next() -> void:
	if _i == 0:
		progress = 1.0
		world_ready = true
	mount_done()
	_i += 1
	_tries = 0
	if _i < PACKS.size():
		_fetch()
	else:
		loaded = true

## Flush every "missing" answer the caches remembered and let HD layers rescan.
func mount_done() -> void:
	Art.clear_cache()
	Audio.clear_cache()
	Ground.clear_cache()
	get_tree().call_group("extra_pack", "extra_pack_loaded")
