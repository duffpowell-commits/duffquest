extends Node2D
## Boss knockout cutscene (Baki x Spike Spiegel, Palahniuk narration). Drawn at the screen's real
## resolution on game.gd's top CanvasLayer, like the HD portraits. main.gd starts it from
## boss_defeated() when data/knockouts.json marks the boss "live"; while it plays main is busy()
## (an empty overlay node freezes the world). Tap / any key = next beat. At the end it calls
## main.knockout_done(), which runs the normal defeat flow. Plan: docs/knockout_cutscenes.md.
##
## Art: res://assets/art/ko/<boss>_a|b|c.jpg and ko/duff_stance|slip|fin1|fin2|fin3|walk.jpg (16:9).
## Missing files fall back to the boss intro card and the HD portraits, so it always runs.
##
## Sound: res://assets/sfx/ko/*.ogg (made by tools/make_ko_sfx.py, all original synthesis), played
## on the SFX bus so the settings volume / mute apply. SFX_CUES = [seconds into beat, file, volume dB,
## bed?]; a bed (drone, crowd murmur) stops when the beat is skipped, one-shots ring out.
const Cast: = preload("res://scripts/cast.gd")
const AudioScript: = preload("res://scripts/audio.gd")
const GoreScript: = preload("res://scripts/ko_gore.gd")   # cartoon blood / spit / teeth (art rule H2)
const SFX_DIR: = "res://assets/sfx/ko/"
const SFX_CUES: = {
	"slip": [[0.35, "whoosh", 0.0, false]],                     # Duff starts to slide at bt 0.4
	"xray": [[0.0, "crack", 0.0, false], [0.0, "drone", -7.0, true]],   # the hit + the freeze
	"finisher": [[0.0, "snap1", -1.0, false], [0.35, "snap2", -1.0, false], [0.70, "snap3", 0.0, false],
		[1.05, "boom", 0.0, false]],                              # panel cuts every 0.35 s, white flash at 1.05
	"crowd": [[0.0, "crowd", -2.0, true]],
	"closer": [[0.0, "jazz", -1.0, false]],                     # walk-off sting, keeps playing after the end
}

const BEATS: = ["stance", "slip", "xray", "finisher", "crowd", "closer"]
const TEAL: = Color("#3fe0d0")
const INK: = Color(0.03, 0.02, 0.04)
const BAR: = 0.12                            # letterbox bar height, share of screen

var main: Node
var data: = {}
var kind: = ""
var beat: = 0
var bt: = 0.0                                # seconds into the current beat
var shake: = 0.0
var flash: = 0.0
var _tex: = {}
var _seed: = 0
var _last: = ""                             # main.ko_kind already started
var _cue: = 0                                # next SFX_CUES entry of this beat
var _shots: Array = []                       # one-shot players
var _bed: AudioStreamPlayer
var played: Array = []                       # cue names in order (tests read this)
var gore: Node2D = null                      # ko_gore.gd child, only while playing with "Cartoon gore" ON
var fixed_seed: = -1                         # >= 0: use this seed (renders / tests repeat exactly)
var _off: = Vector2.ZERO                     # screen shake offset this frame

func _ready() -> void:
	add_to_group("extra_pack")
	var f: = FileAccess.open("res://data/knockouts.json", FileAccess.READ)
	if f:
		data = JSON.parse_string(f.get_as_text())
	for i in 3:
		var p: = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_shots.append(p)
	_bed = AudioStreamPlayer.new()
	_bed.bus = "SFX"
	add_child(_bed)

static func is_live(kind_id: String) -> bool:
	var f: = FileAccess.open("res://data/knockouts.json", FileAccess.READ)
	if f == null:
		return false
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d is Dictionary and (d as Dictionary).has(kind_id) and bool(d[kind_id].get("live", false))

func start(boss: String) -> void:
	kind = boss
	beat = 0
	bt = 0.0
	flash = 0.0
	shake = 0.0
	_seed = fixed_seed if fixed_seed >= 0 else randi()
	_cue = 0
	played.clear()
	_drop_gore()
	if gore_on():
		gore = GoreScript.new()
		gore.name = "Gore"
		gore.seed_base = _seed
		gore.impact = (data.get(kind, {}) as Dictionary).get("impact", {})
		add_child(gore)

## The "Cartoon gore" setting (Settings screen, saved in user://settings.json). Default ON.
static func gore_on() -> bool:
	if AudioScript.inst != null and is_instance_valid(AudioScript.inst):
		return bool(AudioScript.inst.get("gore"))
	return true

func _drop_gore() -> void:
	if gore != null and is_instance_valid(gore):
		remove_child(gore)
		gore.queue_free()
	gore = null

func playing() -> bool:
	return kind != ""

## The cutscene paints the whole screen ink first (shake can bare a few px at one edge, which then
## show the frozen world's last frame: the world is paused during the cutscene anyway).
func covers_screen() -> bool:
	return playing()

func _text(key: String) -> String:
	return Cast.T(str((data.get(kind, {}) as Dictionary).get(key, "")))

## Seconds a beat holds before moving on by itself: enough to read the line.
func _hold() -> float:
	return clampf(1.6 + _text(BEATS[beat]).length() * 0.045, 2.4, 8.5)

func _next() -> void:
	beat += 1
	bt = 0.0
	_cue = 0
	if _bed and _bed.playing:
		_bed.stop()
	if beat >= BEATS.size():
		kind = ""
		# drop this boss's 1280x720 stills (~3.7 MB of texture memory each, ~6 per cutscene):
		# kept forever they pile up past what iPhone Safari allows a tab. Sounds stay cached.
		for k in _tex.keys():
			if str(k).ends_with(".jpg") or str(k).ends_with(".png"):
				_tex.erase(k)
		_drop_gore()
		if main and main.has_method("knockout_done"):
			main.knockout_done()
		return
	if BEATS[beat] == "xray":
		flash = 1.0
		shake = 1.0
	elif BEATS[beat] == "finisher":
		shake = 0.6

func _input(e: InputEvent) -> void:
	if not playing():
		return
	var press: bool = (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed) \
		or (e is InputEventKey and e.pressed and not e.echo)
	if press:
		get_viewport().set_input_as_handled()
		if bt > 0.35:                        # no accidental double-skips
			_next()

func _process(d: float) -> void:
	if not playing() and main and str(main.ko_kind) != "" and str(main.ko_kind) != _last:
		_last = str(main.ko_kind)
		start(_last)
	if main and str(main.ko_kind) == "":
		_last = ""
	if not playing():
		if visible:
			queue_redraw()
		return
	bt += d
	_play_cues()
	flash = maxf(0.0, flash - d * 2.5)
	shake = maxf(0.0, shake - d * 1.8)
	if BEATS[beat] == "finisher":             # last panel lands with a full white hit
		if bt > 1.05 and bt - d <= 1.05:
			flash = 1.0
			shake = 1.0
	if bt >= _hold():
		_next()
	if not playing():
		return
	var rng: = RandomNumberGenerator.new()      # seeded shake: same bt, same frame
	rng.seed = _seed + beat * 7919 + int(bt * 60.0)
	_off = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake * get_viewport_rect().size.y * 0.025
	if gore != null:
		var vp: = get_viewport_rect().size
		gore.sync(BEATS[beat], bt, _stage(vp), _off)
	queue_redraw()

func _stage(vp: Vector2) -> Rect2:
	return Rect2(0, vp.y * BAR, vp.x, vp.y * (0.77 - BAR))

## Where the x-ray hit lands, as a share of the stage (data/knockouts.json "impact" override or default).
func _impact_frac(b: String) -> Vector2:
	var o: Variant = ((data.get(kind, {}) as Dictionary).get("impact", {}) as Dictionary).get(b, {})
	var at: Variant = (o as Dictionary).get("at", null) if o is Dictionary else null
	if at == null:
		at = GoreScript.DEFAULTS[b]["at"][0]
	if at is Array and (at as Array)[0] is Array:
		at = (at as Array)[0]
	return Vector2(float(at[0]), float(at[1]))

# ---------------------------------------------------------------- sound

func _play_cues() -> void:
	var cues: Array = SFX_CUES.get(BEATS[beat], [])
	while _cue < cues.size() and float(cues[_cue][0]) <= bt:
		var c: Array = cues[_cue]
		_cue += 1
		_play(str(c[1]), float(c[2]), bool(c[3]))

func _play(name: String, db: float, bed: bool) -> void:
	played.append(name)
	if AudioScript.inst != null and is_instance_valid(AudioScript.inst) and bool(AudioScript.inst.silent):
		return                               # headless runs: same rule as audio.gd
	var s: = _load_sfx(SFX_DIR + name + ".ogg")
	if s == null:
		return
	var p: AudioStreamPlayer = _bed
	if not bed:
		p = _shots[0]
		for q in _shots:
			if not (q as AudioStreamPlayer).playing:
				p = q
				break
	p.stream = s
	p.volume_db = db
	p.play()

func _load_sfx(p: String) -> AudioStream:
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]

# ---------------------------------------------------------------- art

## Web: KO stills + intro cards arrive with the extra pack; forget the "missing" answers.
func extra_pack_loaded() -> void:
	_tex.clear()

func _load(p: String) -> Texture2D:
	if not _tex.has(p):
		_tex[p] = load(p) if ResourceLoader.exists(p) else null
	return _tex[p]

## A 16:9 still, or null if it isn't drawn yet.
func _still(name: String) -> Texture2D:
	return _load("res://assets/art/ko/%s.jpg" % name)

## Portrait strip cell (0 happy / 1 deadpan / 2 furious) of portraits_hd/<who>.png.
func _cell(who: String, i: int) -> Array:
	var t: = _load("res://assets/art/portraits_hd/%s.png" % who)
	if t == null:
		return [null, Rect2()]
	var w: = t.get_width() / 3.0
	return [t, Rect2(w * i, 0, w, t.get_height())]

## Grey manga version of a portrait cell for the x-ray beat (made once).
func _grey(who: String, i: int) -> Array:
	var key: = "grey_%s_%d" % [who, i]
	if not _tex.has(key):
		var c: = _cell(who, i)
		if c[0] == null:
			_tex[key] = null
		else:
			var img: = (c[0] as Texture2D).get_image().get_region(Rect2i(c[1]))
			img.decompress()
			img.adjust_bcs(1.05, 1.6, 0.0)
			_tex[key] = ImageTexture.create_from_image(img)
	var g: Texture2D = _tex[key]
	return [g, Rect2(Vector2.ZERO, g.get_size()) if g else Rect2()]

func _cover(t: Texture2D, src: Rect2, dst: Rect2, mod: = Color.WHITE, anchor_y: = 0.5) -> void:
	## draw src scaled to COVER dst (crop the overflow), centred across; anchor_y picks the vertical slice
	if t == null:
		return
	var s: = maxf(dst.size.x / src.size.x, dst.size.y / src.size.y)
	var need: = dst.size / s
	var r: = Rect2(src.position + (src.size - need) * Vector2(0.5, clampf(anchor_y, 0.0, 1.0)), need)
	draw_texture_rect_region(t, dst, r, mod)

func _fit(t: Texture2D, src: Rect2, dst: Rect2, mod: = Color.WHITE) -> void:
	## draw src scaled to FIT inside dst (bottom-aligned), centred
	if t == null:
		return
	var s: = minf(dst.size.x / src.size.x, dst.size.y / src.size.y)
	var sz: = src.size * s
	draw_texture_rect_region(t, Rect2(Vector2(dst.position.x + (dst.size.x - sz.x) * 0.5, dst.end.y - sz.y), sz), src, mod)

# ---------------------------------------------------------------- effects

func _speed_lines(c: Vector2, vp: Vector2, col: Color, n: = 70) -> void:
	var rng: = RandomNumberGenerator.new()
	rng.seed = _seed + beat * 101 + int(bt * 12.0)    # flicker 12x a second, like cel animation
	var r: = vp.length()
	for i in n:
		var a: = rng.randf() * TAU
		var r0: = rng.randf_range(0.28, 0.5) * vp.y
		var w: = rng.randf_range(1.0, 4.5)
		draw_line(c + Vector2.from_angle(a) * r0, c + Vector2.from_angle(a) * r, col, w)

func _cracks(c: Vector2, rad: float, col: Color, w: float) -> void:
	## Baki crack lines: jagged branches out from the point of impact
	var rng: = RandomNumberGenerator.new()
	rng.seed = _seed + 7
	for i in 9:
		var a: = TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
		var p: = c
		var len: = rad * rng.randf_range(0.5, 1.0)
		var steps: = 5
		for s in steps:
			var q: = p + Vector2.from_angle(a + rng.randf_range(-0.6, 0.6)) * len / steps
			draw_line(p, q, col, w * (1.0 - s / float(steps)) + 1.0)
			if rng.randf() < 0.35:
				draw_line(q, q + Vector2.from_angle(a + rng.randf_range(-1.4, 1.4)) * len * 0.18, col, 1.5)
			p = q

func _glow_rect(r: Rect2) -> void:
	for i in 4:
		draw_rect(r.grow(2.0 + i * 3.0), Color(TEAL, 0.45 - i * 0.1), false, 3.0)

func _stamp(text: String, c: Vector2, vp: Vector2, k: float) -> void:
	var f: = ThemeDB.fallback_font
	var size: = int(vp.y * 0.11)
	var sc: = lerpf(2.6, 1.0, clampf(k, 0.0, 1.0))
	draw_set_transform(c, -0.08, Vector2(sc, sc))
	var w: = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	for o in [Vector2(5, 5), Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
		draw_string(f, Vector2(-w * 0.5, size * 0.35) + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)
	draw_string(f, Vector2(-w * 0.5, size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#ffe14a"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _caption(text: String, vp: Vector2) -> void:
	## typewriter narration in the bottom letterbox bar area (bar is made taller for it)
	var f: = ThemeDB.fallback_font
	var size: = int(vp.y * 0.046)
	var shown: = text.substr(0, int(bt * 55.0))
	var box: = Rect2(vp.x * 0.06, vp.y * 0.79, vp.x * 0.88, vp.y * 0.19)
	draw_rect(Rect2(0, vp.y * 0.77, vp.x, vp.y * 0.23), Color(INK, 0.92))
	draw_line(Vector2(0, vp.y * 0.77), Vector2(vp.x, vp.y * 0.77), TEAL, 2.0)
	draw_multiline_string(f, box.position + Vector2(0, size), shown, HORIZONTAL_ALIGNMENT_LEFT, box.size.x, size, 4, Color("#f4ece0"))

# ---------------------------------------------------------------- beats

func _draw() -> void:
	if not playing():
		return
	var vp: = get_viewport_rect().size
	draw_set_transform(_off, 0.0, Vector2.ONE)
	var stage: = _stage(vp)
	draw_rect(Rect2(Vector2.ZERO, vp), INK)
	match BEATS[beat]:
		"stance": _beat_stance(vp, stage)
		"slip": _beat_slip(vp, stage)
		"xray": _beat_xray(vp, stage)
		"finisher": _beat_finisher(vp, stage)
		"crowd": _beat_crowd(vp, stage)
		"closer": _beat_closer(vp, stage)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(0, 0, vp.x, vp.y * BAR), INK)        # top letterbox bar
	_caption(_text(BEATS[beat]), vp)
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(1, 1, 1, flash))
	var f: = ThemeDB.fallback_font
	draw_string(f, Vector2(vp.x * 0.86, vp.y * 0.075), "tap ▸", HORIZONTAL_ALIGNMENT_LEFT, -1, int(vp.y * 0.03), Color(1, 1, 1, 0.45))

func _beat_stance(vp: Vector2, stage: Rect2) -> void:
	## Spike: Duff loose and bouncing on the left, the boss card slams in from the right
	draw_rect(stage, Color("#14233a"))
	_speed_lines(stage.get_center(), vp, Color(TEAL, 0.10), 40)
	var bob: = absf(sin(bt * 6.0)) * stage.size.y * 0.03
	var k: = clampf(bt / 0.3, 0.0, 1.0)
	var boss_r: = Rect2(stage.position + Vector2(stage.size.x * (0.48 + (1.0 - k) * 0.6), 0), Vector2(stage.size.x * 0.52, stage.size.y))
	var a: = _still("%s_a" % kind)
	if a:
		_cover(a, Rect2(Vector2.ZERO, a.get_size()), boss_r)
	else:
		var card: = _load("res://assets/art/boss_intro/%s.png" % kind)
		if card:
			_cover(card, Rect2(Vector2.ZERO, card.get_size()), boss_r)
	_glow_rect(boss_r)
	var st: = _still("duff_stance")
	var duff_r: = Rect2(stage.position + Vector2(stage.size.x * 0.02, -bob), Vector2(stage.size.x * 0.46, stage.size.y))
	if st:
		_cover(st, Rect2(Vector2.ZERO, st.get_size()), duff_r)
	else:
		var c: = _cell("duff", 1)
		_fit(c[0], c[1], duff_r)

func _beat_slip(vp: Vector2, stage: Rect2) -> void:
	## the boss winds up (slow zoom); Duff slides out of the way leaving afterimages
	draw_rect(stage, Color("#2a1030"))
	_speed_lines(Vector2(stage.end.x, stage.get_center().y), vp, Color(1, 1, 1, 0.12), 60)
	var z: = 1.0 + bt * 0.05
	var a: = _still("%s_a" % kind)
	var src: Texture2D = a if a else _load("res://assets/art/boss_intro/%s.png" % kind)
	if src:
		var sz: = stage.size * z
		_cover(src, Rect2(Vector2.ZERO, src.get_size()), Rect2(stage.get_center() - sz * 0.5, sz), Color(1, 1, 1, 0.75))
	var sl: = _still("duff_slip")
	var k: = clampf((bt - 0.4) / 0.5, 0.0, 1.0)
	var e: = 1.0 - pow(1.0 - k, 3.0)
	var w: = stage.size.x * 0.4
	for i in [3, 2, 1, 0]:                                  # afterimages trail behind the real one
		var x: float = stage.position.x + stage.size.x * 0.32 - e * stage.size.x * 0.28 + i * e * stage.size.x * 0.06
		var r: = Rect2(Vector2(x, stage.position.y), Vector2(w, stage.size.y))
		var m: Color = Color.WHITE if i == 0 else Color(TEAL, 0.25)
		if sl:
			_cover(sl, Rect2(Vector2.ZERO, sl.get_size()), r, m)
		else:
			var c: = _cell("duff", 1)
			_fit(c[0], c[1], r, m)

func _beat_xray(vp: Vector2, stage: Rect2) -> void:
	## Baki: freeze, manga monochrome, crack lines out of the impact point, teal rim glow
	draw_rect(stage, Color("#e8e4dc"))
	_speed_lines(stage.get_center(), vp, Color(INK, 0.55), 90)
	var b: = _still("%s_b" % kind)
	var r: = stage.grow(-stage.size.y * 0.02)
	if b:
		# "b_anchor" (data/knockouts.json): which slice of the 16:9 still the wide stage keeps,
		# 0 = top, 0.5 = middle (default). Stills with the x-ray on a face at the top edge need 0.
		_cover(b, Rect2(Vector2.ZERO, b.get_size()), r, Color.WHITE,
			float((data.get(kind, {}) as Dictionary).get("b_anchor", 0.5)))
	else:
		var g: = _grey(kind, 2)
		var rr: = Rect2(r.position + Vector2(r.size.x * 0.25, 0), Vector2(r.size.x * 0.5, r.size.y))
		_fit(g[0], g[1], rr)
		_glow_rect(Rect2(rr.position + Vector2(rr.size.x * 0.1, 0), Vector2(rr.size.x * 0.8, rr.size.y)))
	var hit: = stage.position + stage.size * _impact_frac("xray")
	var k: = clampf(bt / 0.25, 0.0, 1.0)
	_cracks(hit, stage.size.y * 0.45 * k, Color(INK, 0.9), 6.0)
	_cracks(hit, stage.size.y * 0.45 * k, Color(TEAL, 0.5), 2.0)
	for i in 3:                                              # shockwave rings
		var rr2: = stage.size.y * (0.08 + fmod(bt * 0.6 + i * 0.33, 1.0) * 0.5)
		draw_arc(hit, rr2, 0, TAU, 48, Color(1, 1, 1, 0.6 * (1.0 - fmod(bt * 0.6 + i * 0.33, 1.0))), 4.0)

func _beat_finisher(vp: Vector2, stage: Rect2) -> void:
	## move name stamped on; three diagonal panel cuts of Duff, the third one lands the hit
	draw_rect(stage, Color("#0e1726"))
	_speed_lines(stage.get_center(), vp, Color(TEAL, 0.2), 80)
	var panels: = ["duff_fin1", "duff_fin2", "duff_fin3"]
	var moods: = [2, 2, 2]
	var n: = mini(2, int(bt / 0.35))
	for i in n + 1:
		var w: = stage.size.x / 3.0
		var r: = Rect2(stage.position + Vector2(w * i, 0), Vector2(w, stage.size.y)).grow(-6)
		var t: = _still(panels[i])
		var tilt: float = [-0.05, 0.04, -0.03][i]
		draw_set_transform(r.get_center(), tilt, Vector2.ONE)
		var local: = Rect2(-r.size * 0.5, r.size)
		draw_rect(local.grow(5), INK)
		if t:
			_cover(t, Rect2(Vector2.ZERO, t.get_size()), local)
		else:
			var c: = _cell("duff", moods[i])
			_cover(c[0], c[1], local)
		draw_rect(local, TEAL, false, 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if bt > 1.05:
		_stamp(_text("move"), stage.get_center(), vp, (bt - 1.05) / 0.18)

func _beat_crowd(vp: Vector2, stage: Rect2) -> void:
	## a spectator reacts; boss card behind, shaking a little
	draw_rect(stage, Color("#1b1020"))
	var line: = _text("crowd")
	var who: = line.get_slice(":", 0).strip_edges().to_lower()
	if who == Cast.T("{partner}").to_lower():
		who = "madison"
	elif who == "earl":
		who = "regular"
	var c: = _cell(who, 0)
	var k: = clampf(bt / 0.25, 0.0, 1.0)
	var r: = Rect2(stage.position + Vector2(stage.size.x * (0.05 - (1.0 - k) * 0.4), 0), Vector2(stage.size.x * 0.42, stage.size.y))
	_fit(c[0], c[1], r)
	_glow_rect(Rect2(r.position + Vector2(r.size.x * 0.15, 0), Vector2(r.size.x * 0.7, r.size.y)))
	var card: = _still("%s_c" % kind)
	if card == null:
		card = _load("res://assets/art/boss_intro/%s.png" % kind)
	if card:
		var cr: = Rect2(stage.position + Vector2(stage.size.x * 0.52, stage.size.y * 0.12), Vector2(stage.size.x * 0.44, stage.size.y * 0.76))
		_cover(card, Rect2(Vector2.ZERO, card.get_size()), cr, Color(0.55, 0.5, 0.6))

func _beat_closer(vp: Vector2, stage: Rect2) -> void:
	## boss down (still C or the card tipped over and dimmed); Duff walks off; fade to black
	draw_rect(stage, Color("#14233a"))
	var cc: = _still("%s_c" % kind)
	if cc:
		_cover(cc, Rect2(Vector2.ZERO, cc.get_size()), stage, Color(1, 1, 1))
	else:
		var card: = _load("res://assets/art/boss_intro/%s.png" % kind)
		if card:
			var r: = Rect2(stage.position + Vector2(stage.size.x * 0.05, stage.size.y * 0.25), stage.size * Vector2(0.55, 0.7))
			draw_set_transform(r.get_center(), 0.22, Vector2.ONE)
			_cover(card, Rect2(Vector2.ZERO, card.get_size()), Rect2(-r.size * 0.5, r.size), Color(0.45, 0.42, 0.5))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var walk: = _still("duff_walk")
	var x: = stage.size.x * (0.55 + bt * 0.05)
	var dr: = Rect2(stage.position + Vector2(x, 0), Vector2(stage.size.x * 0.4, stage.size.y))
	if walk:
		_cover(walk, Rect2(Vector2.ZERO, walk.get_size()), dr)
	else:
		var c: = _cell("duff", 1)
		_fit(c[0], c[1], dr)
	var fade: = clampf((bt - _hold() + 0.8) / 0.8, 0.0, 1.0)
	draw_rect(stage, Color(0, 0, 0, fade))
