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
## "True 3D" test slice (real models for Duff + porch pirates in the 3D view): web link #true3d or env DQ_TRUE3D=1.
## Never saved, never in Settings: off for players until Duff says otherwise.
var true3d: = OS.get_environment("DQ_TRUE3D") == "1"
var edm: = false                              # Settings > EDM soundtrack (Nov 18): mus_edm_<name> over mus_<name>
var view3d: = true                           # 3D town view (scripts/view3d/, game.gd); only on engines with 3D. Default since Nov 16
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
	if inst != null and is_instance_valid(inst):
		inst.current = ""   # re-pick: a better file (the EDM version) may have just landed; same file keeps playing

static func sfx(name: String, pitch: float = 1.0) -> void:
	if inst != null and is_instance_valid(inst):
		inst.play_sfx(name, pitch)

## EDM stings (Nov 18): with the EDM soundtrack on, big moments get a one-shot (sting_<name>.wav: ko, rent,
## levelup, tapestop); with it off they keep their old sfx (`fallback`, "" = nothing).
const STINGS: = ["ko", "rent", "levelup", "tapestop"]
static func sting(name: String, fallback: String = "") -> void:
	if inst == null or not is_instance_valid(inst):
		return
	var n: String = inst.sting_name(name, fallback)
	if n != "":
		inst.play_sfx(n)

func sting_name(name: String, fallback: String) -> String:
	return ("sting_" + name) if edm and STINGS.has(name) else fallback

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

## Music + SFX normally come from res://default_bus_layout.tres (Nov 19): on the web, Godot's sample playback only
## routes buses that exist at boot, so buses added here at runtime played nothing (the whole game was silent).
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
		"screen_shake": bool(JuiceScript.shake_on), "view3d": view3d, "view3d_v": 2, "edm": edm }

func set_screen_shake(on: bool) -> void:
	JuiceScript.shake_on = on
	save_settings()

func set_clean(on: bool) -> void:
	CastScript.clean = on
	save_settings()

func set_view3d(on: bool) -> void:
	view3d = on
	save_settings()

## Swap soundtracks now: the same place's track restarts from the other set.
func set_edm(on: bool) -> void:
	edm = on
	save_settings()
	var want: = current
	current = "__"
	play_music(want)

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
	# Web portals (CrazyGames etc.) are PEGI 12: CI marks that build with window.DQ_PORTAL, and new players
	# start with clean language on and cartoon gore off. Both stay switchable in Settings.
	var portal: = OS.has_feature("web") and str(JavaScriptBridge.eval("window.DQ_PORTAL ? 1 : 0", true)) == "1"
	CastScript.clean = bool(d.get("clean", portal))
	gore = bool(d.get("gore", not portal))
	JuiceScript.shake_on = bool(d.get("screen_shake", true))
	edm = bool(d.get("edm", false))
	# 3D became the default Nov 16 (view3d_v 2): settings saved before that carry the old "off" default, so they
	# start in 3D once; after that the player's own Settings choice sticks
	view3d = bool(d.get("view3d", true)) if int(d.get("view3d_v", 1)) >= 2 else true
	# web links: "#3d" / "#2d" in the URL force the view (phone tests, side-by-side checks)
	if OS.has_feature("web"):
		var h: = str(JavaScriptBridge.eval("window.location.hash", true))
		if h.contains("3d"):
			view3d = true
		elif h.contains("2d"):
			view3d = false
		true3d = true3d or h.contains("true3d")
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

## Which files can play for a place, best first: the EDM version when the toggle is on, then the original,
## then a stand-in for places only the EDM set scores ("night" -> the neighborhood theme).
const MUSIC_FALLBACK: = {"night": "neighborhood"}
func _music_candidates(name: String) -> Array:
	var out: Array = []
	for n in [name, str(MUSIC_FALLBACK.get(name, ""))]:
		if n == "":
			continue
		if edm:
			out.append("edm_" + n)
		out.append(n)
	return out

func play_music(name: String) -> void:
	if name == current:
		return
	current = name
	if name == "" or silent:
		music_player.stop()
		return
	var s: AudioStream = null
	for n in _music_candidates(name):
		s = stream(DIR + "mus_" + n + ".ogg")
		if s != null:
			break
	if s == null:
		current = ""   # not here yet (web world pack still downloading): ask again next time
		return
	if music_player.stream == s and music_player.playing:
		return   # already playing this file (a re-pick after a pack mount): don't restart it
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	music_player.stream = s
	music_player.play()
