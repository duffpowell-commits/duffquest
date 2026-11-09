extends "res://scripts/minigames/minigame.gd"

const MUSIC_BAR: = Rect2(176, 44, 108, 10)
const SFX_BAR: = Rect2(176, 74, 108, 10)
const STEP: = 0.1

var audio: Node = null
var dragging: = ""

func _setup() -> void:
	title = "SETTINGS"
	time_limit = 0.0
	space_is_pen = false
	if audio == null:
		audio = AudioScript.inst
	add_button("music_down", Rect2(148, 39, 24, 20), "-", KEY_1)
	add_button("music_up", Rect2(288, 39, 24, 20), "+", KEY_2)
	add_button("sfx_down", Rect2(148, 69, 24, 20), "-", KEY_3)
	add_button("sfx_up", Rect2(288, 69, 24, 20), "+", KEY_4)
	add_button("mute", Rect2(148, 92, 164, 18), _mute_label(), KEY_M, Color("#6a4a96"))
	add_button("clean", Rect2(148, 112, 164, 18), _clean_label(), KEY_C, Color("#3a6a5a"))
	add_button("gore", Rect2(148, 132, 164, 18), _gore_label(), KEY_G, Color("#8a2a34"))
	add_button("back", Rect2(110, 162, 100, 17), "Back", KEY_ESCAPE, Color("#a43a2c"))

func _mute_label() -> String:
	return "Sound: MUTED (tap to unmute)" if audio and audio.muted else "Sound: ON (tap to mute)"

func _clean_label() -> String:
	return "Clean language: ON (C)" if Cast.clean else "Clean language: OFF (C)"

func _gore_label() -> String:
	return "Cartoon gore: ON (G)" if audio == null or audio.gore else "Cartoon gore: OFF (G)"

func music_vol() -> float:
	return float(audio.music_vol) if audio else 0.0

func sfx_vol() -> float:
	return float(audio.sfx_vol) if audio else 0.0

func _on_button(id: String) -> void:
	if audio == null:
		if id == "back":
			finish(1.0)
		return
	match id:
		"music_down": audio.set_music_vol(music_vol() - STEP)
		"music_up": audio.set_music_vol(music_vol() + STEP)
		"sfx_down":
			audio.set_sfx_vol(sfx_vol() - STEP)
			AudioScript.sfx("select")
		"sfx_up":
			audio.set_sfx_vol(sfx_vol() + STEP)
			AudioScript.sfx("select")
		"mute":
			audio.set_muted(not audio.muted)
			get_button("mute")["label"] = _mute_label()
		"clean":
			audio.set_clean(not Cast.clean)
			get_button("clean")["label"] = _clean_label()
			AudioScript.sfx("select")
			flash("Clean language ON. Heck yeah." if Cast.clean else "Clean language OFF. Hell yeah.", Color.WHITE, 1.0)
		"gore":
			audio.set_gore(not audio.gore)
			get_button("gore")["label"] = _gore_label()
			AudioScript.sfx("select")
			flash("Cartoon gore ON. Teeth everywhere." if audio.gore else "Cartoon gore OFF. Knockouts stay clean.", Color.WHITE, 1.0)
		"back": finish(1.0)

func _set_from(bar: Rect2, p: Vector2, which: String) -> void:
	var v: = clampf((p.x - bar.position.x) / bar.size.x, 0.0, 1.0)
	if which == "music":
		audio.set_music_vol(v)
	else:
		audio.set_sfx_vol(v)

func _pointer_down(p: Vector2) -> void:
	if audio == null:
		return
	if MUSIC_BAR.grow(4).has_point(p):
		dragging = "music"
		_set_from(MUSIC_BAR, p, "music")
	elif SFX_BAR.grow(4).has_point(p):
		dragging = "sfx"
		_set_from(SFX_BAR, p, "sfx")

func _pointer_move(p: Vector2) -> void:
	if dragging != "":
		_set_from(MUSIC_BAR if dragging == "music" else SFX_BAR, p, dragging)

func _pointer_up(_p: Vector2) -> void:
	if dragging == "sfx":
		AudioScript.sfx("select")
	dragging = ""

func _draw_game() -> void:
	draw_rect(Rect2(8, 20, 304, 134), Color(0, 0, 0, 0.35))
	Art.image(self, "ic_heart", Vector2(14, 44))
	txt(Vector2(26, 52), "Music", 8)
	bar(MUSIC_BAR, music_vol(), Color("#ff6aa8"))
	txt(Vector2(108, 52), "%d%%" % roundi(music_vol() * 100.0), 8, Color("#f2c66a"))
	Art.image(self, "ic_bolt", Vector2(14, 74))
	txt(Vector2(26, 82), "Sound FX", 8)
	bar(SFX_BAR, sfx_vol(), Color("#f2c66a"))
	txt(Vector2(108, 82), "%d%%" % roundi(sfx_vol() * 100.0), 8, Color("#f2c66a"))
	txt(Vector2(26, 104), "Mute all", 8)
	txt(Vector2(26, 124), "Clean language", 8)
	txt(Vector2(26, 144), "Cartoon gore (KOs)", 8)
	txt(Vector2(0, 159), "Saved automatically. Music + SFX are original chiptune (see README).", 6, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_CENTER, W)
