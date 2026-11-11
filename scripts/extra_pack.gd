extends Node
## Web only: index.pck ships just what the first minutes need; knockout stills, boss intro cards, most loading
## screens and minigame backdrops live in extra.pck next to index.html (tools/make_extra_pack.gd). This node
## downloads it in the background right after boot, mounts it, and tells the art caches to look again
## (group "extra_pack" gets extra_pack_loaded()). Until then every loader already copes with a missing
## texture (Art.tex -> null, knockout falls back to portraits, minigames get the sunburst).
## Desktop/Android builds have everything in one pack, so this does nothing there.

const Art: = preload("res://scripts/art.gd")
const PROBE: = "res://assets/art/ko/"     # the folder that only exists once the extra pack is in
const LOCAL: = "user://extra.pck"
const RETRIES: = 3

static var loaded: = false
var _http: HTTPRequest
var _tries: = 0

func _ready() -> void:
	loaded = DirAccess.dir_exists_absolute(PROBE) and not DirAccess.get_files_at(PROBE).is_empty()
	if loaded or not OS.has_feature("web"):
		loaded = true
		return
	_http = HTTPRequest.new()
	_http.download_file = LOCAL
	_http.use_threads = false
	add_child(_http)
	_http.request_completed.connect(_on_done)
	_fetch()

func _fetch() -> void:
	_tries += 1
	# relative to the page, so it follows itch's per-build upload folder (no stale cache across builds)
	var url: = str(JavaScriptBridge.eval("new URL('extra.pck', document.baseURI).href", true))
	var err: = _http.request(url)
	if err != OK:
		push_warning("extra pack: request failed to start (%d)" % err)

func _on_done(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and ProjectSettings.load_resource_pack(LOCAL, false):
		mount_done()
		var probe: = DirAccess.get_files_at(PROBE)
		var sample: = PROBE + str(probe[0]).trim_suffix(".import") if probe.size() > 0 else ""
		print("extra pack: mounted, %d KO files, sample loads: %s" % [probe.size(), sample != "" and load(sample) is Texture2D])
		return
	push_warning("extra pack: download failed (result %d, http %d), try %d" % [result, code, _tries])
	if _tries < RETRIES:
		get_tree().create_timer(4.0 * _tries).timeout.connect(_fetch)

## Flush every "missing" answer the art caches remembered and let HD layers rescan.
func mount_done() -> void:
	loaded = true
	Art.clear_cache()
	get_tree().call_group("extra_pack", "extra_pack_loaded")
