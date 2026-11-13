extends Node
const CastScript: = preload("res://scripts/cast.gd")
const JuiceScript: = preload("res://scripts/juice.gd")

const DIR: = "res://assets/audio/"
const TRACKS: = ["neighborhood", "home", "kitchen", "boss", "willnot", "gala", "date", "credits"]
const SFX: = ["achievement", "baby_cry", "back", "bonk", "bus", "cash", "chitter", "coin", "door", "explosion", "fail", "fryer", "gun", "hiss",
	"hit", "honk", "hurt", "laser", "meow", "pickup", "roll", "select", "swing", "tele", "text", "whoosh", "win"]
const SETTINGS_PATH: = "user://settings.json"
const POOL: = 8

static var inst: Node = null
static var _streams: = {}

var settings_path: = SETTINGS_PATH
var music_vol: = 0.7
var sfx_vol: = 0.8
var muted: = false
var gore: = true                             # "Cartoon gore" in the KO cutscenes (knockout.gd reads this)
var current: = ""
var played: Array = []
var music_player: AudioStreamPlayer
var pool: Array = []
var _last: = {}
var silent: = DisplayServer.get_name() == "headless"

static func stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _streams[path]

## Web: forget "missing" answers once a late pack (music) is mounted (scripts/extra_pack.gd).
static func clear_cache() -> void:
	_streams.clear()

static func sfx(name: String, pitch: float = 1.0) -> void:
	if inst != null and is_instance_valid(inst):
		inst.play_sfx(name, pitch)

static func music(name: String) -> void:
	if inst != null and is_instance_valid(inst):
		inst.play_music(name)

func _ready() -> void:
	inst = self
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	for i in POOL:
		var p: = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		pool.append(p)
	load_settings()

func _exit_tree() -> void:
	for p in pool + [music_player]:
		(p as AudioStreamPlayer).stop()
		(p as AudioStreamPlayer).stream = null
	if inst == self:
		inst = null
		_streams.clear()
		preload("res://scripts/art.gd").clear_cache()

func _ensure_bus(n: String) -> void:
	if AudioServer.get_bus_index(n) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, n)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")

func apply() -> void:
	for pair in [["Music", music_vol], ["SFX", sfx_vol]]:
		var i: = AudioServer.get_bus_index(str(pair[0]))
		if i >= 0:
			var v: float = pair[1]
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
			AudioServer.set_bus_mute(i, muted or v <= 0.001)

func set_music_vol(v: float) -> void:
	music_vol = clampf(snappedf(v, 0.1), 0.0, 1.0)
	apply()
	save_settings()

func set_sfx_vol(v: float) -> void:
	sfx_vol = clampf(snappedf(v, 0.1), 0.0, 1.0)
	apply()
	save_settings()

func set_muted(on: bool) -> void:
	muted = on
	apply()
	save_settings()

func to_dict() -> Dictionary:
	return {"music": music_vol, "sfx": sfx_vol, "mute": muted, "clean": bool(CastScript.clean), "gore": gore,
		"screen_shake": bool(JuiceScript.shake_on) }

func set_screen_shake(on: bool) -> void:
	JuiceScript.shake_on = on
	save_settings()

func set_clean(on: bool) -> void:
	CastScript.clean = on
	save_settings()

func set_gore(on: bool) -> void:
	gore = on
	save_settings()

func save_settings() -> void:
	var f: = FileAccess.open(settings_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict()))

func load_settings() -> void:
	var d: Dictionary = {}
	if FileAccess.file_exists(settings_path):
		var f: = FileAccess.open(settings_path, FileAccess.READ)
		if f:
			var v: Variant = JSON.parse_string(f.get_as_text())
			if v is Dictionary:
				d = v
	music_vol = clampf(float(d.get("music", 0.7)), 0.0, 1.0)
	sfx_vol = clampf(float(d.get("sfx", 0.8)), 0.0, 1.0)
	muted = bool(d.get("mute", false))
	CastScript.clean = bool(d.get("clean", false))
	gore = bool(d.get("gore", true))
	JuiceScript.shake_on = bool(d.get("screen_shake", true))
	apply()

func play_sfx(name: String, pitch: float = 1.0) -> void:
	var now: = Time.get_ticks_msec()
	if now - int(_last.get(name, -1000)) < 45:
		return
	_last[name] = now
	played.append(name)
	if played.size() > 40:
		played.pop_front()
	if silent:
		return
	var s: = stream(DIR + name + ".wav")
	if s == null:
		return
	var best: AudioStreamPlayer = pool[0]
	for p in pool:
		if not (p as AudioStreamPlayer).playing:
			best = p
			break
	best.stream = s
	best.pitch_scale = pitch * randf_range(0.96, 1.04)
	best.play()

func play_music(name: String) -> void:
	if name == current:
		return
	current = name
	if name == "" or silent:
		music_player.stop()
		return
	var s: = stream(DIR + "mus_" + name + ".ogg")
	if s == null:
		current = ""   # not here yet (web world pack still downloading): ask again next time
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	music_player.stream = s
	music_player.play()
