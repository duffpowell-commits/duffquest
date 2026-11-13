extends Node
## Web only: index.pck ships just what the title screen needs (scripts, data, fonts, sfx, small UI art). The rest
## comes in three packs next to index.html, built by tools/make_extra_pack.gd and downloaded one after the other
## right after boot:
##   street.pck  the first minute outside: Duff (and his dialogue portrait), the porch pirates, the street's
##               storefronts, props and ground, the home interior. "New Game" waits only on this one
##               (street_ready): the cold open is a porch fight on that street, and it plays while world.pck
##               streams in behind it.
##   world.pck   the rest of the cast, HD portraits, music, kitchen/gala/arena art. "Continue" waits on this one
##               (world_ready), and so do the Fork, arenas and minigames (main.gd _after_world).
##   extra.pck   knockout stills, boss intro cards, most loading screens, minigame backdrops. Nothing waits
##               for it; every loader already copes with a missing texture until it lands.
## After each mount the art and audio caches forget their "missing" answers and group "extra_pack" gets
## extra_pack_loaded(). Desktop/Android builds have everything in one pack, so this does nothing there.

const Art: = preload("res://scripts/art.gd")
const Audio: = preload("res://scripts/audio.gd")
const Ground: = preload("res://scripts/ground.gd")
## [file next to index.html, a file or folder that only exists once that pack is mounted]
const PACKS: = [["street.pck", "res://assets/art/duff_home.png.import"], ["world.pck", "res://assets/art/portraits_hd/madison.png.import"],
	["extra.pck", "res://assets/art/ko/"]]
const RETRIES: = 3

static var street_ready: = not OS.has_feature("web")  # street.pck mounted: safe to start a new game
static var world_ready: = not OS.has_feature("web")   # world.pck mounted too: safe to load a save, work, fight bosses
static var loaded: = not OS.has_feature("web")        # every pack mounted
static var progress: = 0.0        # 0..1 of the pack downloading now, for the loading card (-1 while its size is unknown)
static var got_mb: = 0.0          # MB of that pack downloaded so far
static var fetching: = -1         # index into PACKS of the pack downloading now
static var retrying: = ""         # set while a gating pack is between failed tries, for the loading card
var _http: HTTPRequest
var _i: = 0
var _tries: = 0

static func _present(probe: String) -> bool:
	if not probe.ends_with("/"):
		return FileAccess.file_exists(probe)
	return DirAccess.dir_exists_absolute(probe) and not DirAccess.get_files_at(probe).is_empty()

## Is the pack a loading card waits on (0 street, 1 world) mounted?
static func ready_for(need: int) -> bool:
	return street_ready if need == 0 else world_ready

func _ready() -> void:
	street_ready = not OS.has_feature("web") or _present(PACKS[0][1])
	world_ready = not OS.has_feature("web") or _present(PACKS[1][1])
	loaded = not OS.has_feature("web") or _present(PACKS[2][1])
	if world_ready:
		street_ready = true
	if street_ready and world_ready and loaded:
		progress = 1.0
		return
	_i = 0 if not street_ready else (1 if not world_ready else 2)
	_http = HTTPRequest.new()
	_http.use_threads = false
	# The browser already undoes Content-Encoding: gzip (itch's CDN gzips .pck). With accept_gzip on, Godot then
	# tries to inflate the plain bytes again and every download dies with RESULT_BODY_DECOMPRESS_FAILED.
	_http.accept_gzip = false
	add_child(_http)
	_http.request_completed.connect(_on_done)
	_fetch()

func _process(_d: float) -> void:
	if _http and _i < PACKS.size():
		var total: = _http.get_body_size()
		got_mb = _http.get_downloaded_bytes() / 1048576.0
		progress = clampf(float(_http.get_downloaded_bytes()) / total, 0.0, 1.0) if total > 0 else -1.0

func _local() -> String:
	return "user://" + str(PACKS[_i][0])

func _fetch() -> void:
	_tries += 1
	fetching = _i
	progress = 0.0
	got_mb = 0.0
	_http.download_file = _local()
	# relative to the page, so it follows itch's per-build upload folder (no stale cache across builds)
	var url: = str(JavaScriptBridge.eval("new URL('%s', document.baseURI).href" % PACKS[_i][0], true))
	var err: = _http.request(url)
	if err != OK:
		push_warning("%s: request failed to start (%d)" % [PACKS[_i][0], err])

func _on_done(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	var name: String = PACKS[_i][0]
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and ProjectSettings.load_resource_pack(_local(), false):
		print("%s: mounted (probe %s)" % [name, PACKS[_i][1]])
		_next()
		return
	push_warning("%s: download failed (result %d, http %d), try %d" % [name, result, code, _tries])
	if _i <= 1:
		# street.pck and world.pck hold Duff, the cast and the town: playing without them is an empty map. Never
		# give up on them; the loading card shows the retry and keeps its Back button.
		retrying = "Bad signal (%d/%d). Trying again..." % [result, code]
		get_tree().create_timer(minf(4.0 * _tries, 20.0)).timeout.connect(_fetch)
	elif _tries < RETRIES:
		get_tree().create_timer(4.0 * _tries).timeout.connect(_fetch)
	else:
		_next()   # late art only: play on with the fallbacks rather than wait forever

func _next() -> void:
	retrying = ""
	if _i == 0:
		street_ready = true
	elif _i == 1:
		world_ready = true
	mount_done()
	_i += 1
	_tries = 0
	if _i < PACKS.size():
		_fetch()
	else:
		fetching = -1
		loaded = true

## Flush every "missing" answer the caches remembered and let HD layers rescan.
func mount_done() -> void:
	Art.clear_cache()
	Audio.clear_cache()
	Ground.clear_cache()
	get_tree().call_group("extra_pack", "extra_pack_loaded")
