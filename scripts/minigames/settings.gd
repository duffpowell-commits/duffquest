extends "res://scripts/minigames/minigame.gd"

const JuiceScript: = preload("res://scripts/juice.gd")

const MUSIC_BAR: = Rect2(176, 44, 108, 10)
const SFX_BAR: = Rect2(176, 74, 108, 10)
const STEP: = 0.1

var audio: Node = null
var dragging: = ""
var dev: = false        # main.gd: debug builds only -> "Dev: quests" button
var action: = ""

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
	add_button("mute", Rect2(148, 90, 164, 16), _mute_label(), KEY_M, Color("#6a4a96"))
	add_button("clean", Rect2(148, 108, 164, 16), _clean_label(), KEY_C, Color("#3a6a5a"))
	add_button("gore", Rect2(148, 126, 164, 16), _gore_label(), KEY_G, Color("#8a2a34"))
	add_button("shake", Rect2(148, 144, 164, 16), _shake_label(), KEY_K, Color("#4a5a8a"))
	add_button("back", Rect2(110, 163, 100, 15), "Back", KEY_ESCAPE, Color("#a43a2c"))
	if _guard():
		add_button("gfx", Rect2(214, 163, 98, 15), _gfx_label(), KEY_V, Color("#3a5a8a"))
	if dev:
		add_button("dev_quests", Rect2(8, 163, 98, 15), "Dev: quests", KEY_Q, Color("#8a6a1a"))

## perf_guard.gd (game.gd's child): Lite graphics = no HD-2D screen shader / window lights, for slow phones.
func _guard() -> Node:
	return get_tree().root.find_child("PerfGuard", true, false) if is_inside_tree() else null

func _gfx_label() -> String:
	var g: = _guard()
	return "Graphics: Lite" if g and g.low else "Graphics: Full"

func _mute_label() -> String:
	return "Sound: MUTED (tap to unmute)" if audio and audio.muted else "Sound: ON (tap to mute)"

func _clean_label() -> String:
	return "Clean language: ON (C)" if Cast.clean else "Clean language: OFF (C)"

func _gore_label() -> String:
	return "Cartoon gore: ON (G)" if audio == null or audio.gore else "Cartoon gore: OFF (G)"

func _shake_label() -> String:
	return "Screen shake: ON (K)" if JuiceScript.shake_on else "Screen shake: OFF (K)"

func music_vol() -> float:
	return float(audio.music_vol) if audio else 0.0

func sfx_vol() -> float:
	return float(audio.sfx_vol) if audio else 0.0

func _on_button(id: String) -> void:
	if id == "dev_quests":
		action = "dev_quests"
		finish(1.0)
		return
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

		"shake":
			audio.set_screen_shake(not JuiceScript.shake_on)
			get_button("shake")["label"] = _shake_label()
			AudioScript.sfx("select")
		"gfx":
			var g: = _guard()
			if g:
				g.force_low(not g.low, true)
				get_button("gfx")["label"] = _gfx_label()
				AudioScript.sfx("select")
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
	draw_rect(Rect2(8, 20, 304, 142), Color(0, 0, 0, 0.35))
	Art.image(self, "ic_heart", Vector2(14, 44))
	txt(Vector2(26, 52), "Music", 8)
	bar(MUSIC_BAR, music_vol(), Color("#ff6aa8"))
	txt(Vector2(108, 52), "%d%%" % roundi(music_vol() * 100.0), 8, Color("#f2c66a"))
	Art.image(self, "ic_bolt", Vector2(14, 74))
	txt(Vector2(26, 82), "Sound FX", 8)
	bar(SFX_BAR, sfx_vol(), Color("#f2c66a"))
	txt(Vector2(108, 82), "%d%%" % roundi(sfx_vol() * 100.0), 8, Color("#f2c66a"))
	txt(Vector2(26, 101), "Mute all", 8)
	txt(Vector2(26, 119), "Clean language", 8)
	txt(Vector2(26, 137), "Cartoon gore (KOs)", 8)
	txt(Vector2(26, 155), "Screen shake", 8)
	txt(Vector2(0, 32), "Saved automatically. Music + SFX are original chiptune (see README).", 6, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_CENTER, W)
