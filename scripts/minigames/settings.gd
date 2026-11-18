extends "res://scripts/minigames/minigame.gd"

const JuiceScript: = preload("res://scripts/juice.gd")

## Nov 17: Settings is the Duffphone's Settings app: a glass title bar, grouped cards of rows, iOS switches and
## sliders. Every row is one (hidden) button the size of the row, so a tap anywhere on it toggles; keys still work.
const LEFT: = 6.0
const RIGHT: = 164.0
const COL_W: = 150.0
const ROW_H: = 17.0
const TOP: = 33.0
const MUSIC_BAR: = Rect2(LEFT + 10, TOP + 15, 104, 3)
const SFX_BAR: = Rect2(LEFT + 10, TOP + 37, 104, 3)
const OFF: = Rect2(-40, -40, 1, 1)   # key-only buttons (volume - / +)
const TOGGLES: = ["clean", "gore", "shake", "edm", "view3d", "gfx"]
const STEP: = 0.1

var audio: Node = null
var dragging: = ""
var dev: = false        # main.gd: debug builds only -> "Dev: quests" button
var action: = ""

func _setup() -> void:
	title = "SETTINGS"
	time_limit = 0.0
	space_is_pen = false
	show_header = false
	pill_buttons = true
	if audio == null:
		audio = AudioScript.inst
	add_button("music_down", OFF, "-", KEY_1)
	add_button("music_up", OFF, "+", KEY_2)
	add_button("sfx_down", OFF, "-", KEY_3)
	add_button("sfx_up", OFF, "+", KEY_4)
	_row("mute", Rect2(LEFT, TOP + 44, COL_W, ROW_H), _mute_label(), KEY_M)
	var y: = TOP
	for id in TOGGLES:
		if id == "gfx" and not _guard():
			continue
		if id == "view3d" and not ClassDB.class_exists("Node3D"):   # the slim 2D web engine has no 3D
			continue
		var lbl: String = {"clean": _clean_label(), "gore": _gore_label(), "shake": _shake_label(),
			"edm": _edm_label(), "view3d": _view3d_label(), "gfx": _gfx_label()}[id]
		var key: int = {"clean": KEY_C, "gore": KEY_G, "shake": KEY_K, "edm": KEY_E, "view3d": KEY_B, "gfx": KEY_V}[id]
		_row(id, Rect2(RIGHT, y, COL_W, ROW_H), lbl, key)
		y += ROW_H
	_row("credits", Rect2(LEFT, TOP + 79, COL_W, ROW_H), "Credits & legal", KEY_L)
	_row("report", Rect2(LEFT, TOP + 79 + ROW_H, COL_W, ROW_H), "Send a bug report", KEY_R)
	if dev:
		_row("dev_quests", Rect2(LEFT, TOP + 79 + ROW_H * 2, COL_W, ROW_H), "Dev: quests", KEY_Q)
	add_button("back", Rect2(4, 3, 46, 13), "Back", KEY_ESCAPE, Color("#a43a2c"))

func _row(id: String, r: Rect2, label: String, key: int) -> void:
	add_button(id, r, label, key)["hide"] = true

## perf_guard.gd (game.gd's child): Lite graphics = no HD-2D screen shader / window lights, for slow phones.
func _guard() -> Node:
	return get_tree().root.find_child("PerfGuard", true, false) if is_inside_tree() else null

func _gfx_label() -> String:
	var g: = _guard()
	return "Graphics: Lite" if g and g.low else "Graphics: Full"

func _view3d_label() -> String:
	return "3D view: ON (B)" if audio and audio.view3d else "3D view: OFF (B)"

func _mute_label() -> String:
	return "Sound: MUTED (tap to unmute)" if audio and audio.muted else "Sound: ON (tap to mute)"

func _clean_label() -> String:
	return "Clean language: ON (C)" if Cast.clean else "Clean language: OFF (C)"

func _gore_label() -> String:
	return "Cartoon gore: ON (G)" if audio == null or audio.gore else "Cartoon gore: OFF (G)"

func _edm_label() -> String:
	return "EDM soundtrack: ON (E)" if audio != null and audio.edm else "EDM soundtrack: OFF (E)"

func _shake_label() -> String:
	return "Screen shake: ON (K)" if JuiceScript.shake_on else "Screen shake: OFF (K)"

func music_vol() -> float:
	return float(audio.music_vol) if audio else 0.0

func sfx_vol() -> float:
	return float(audio.sfx_vol) if audio else 0.0

## Toggles share one look: teal when on, slate when off, so the column reads as a set.
func _tint_toggles() -> void:
	for id in ["mute", "clean", "gore", "shake", "edm", "gfx", "view3d"]:
		var b: = get_button(id)
		if b.is_empty():
			continue
		var l: = str(b["label"])
		var on: = (": ON" in l) or l.ends_with("Full")
		b["col"] = UiStyle.TEAL.darkened(0.2) if on else Color("#4f3d66")

func _on_button(id: String) -> void:
	if id == "dev_quests" or id == "credits" or id == "report":
		action = id
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
		"edm":
			audio.set_edm(not audio.edm)
			get_button("edm")["label"] = _edm_label()
			AudioScript.sfx("select")
			flash("EDM soundtrack ON. Drop incoming." if audio.edm else "Original soundtrack. Duff's own tunes.", Color.WHITE, 1.0)
		"view3d":
			audio.set_view3d(not audio.view3d)
			get_button("view3d")["label"] = _view3d_label()
			AudioScript.sfx("select")
			flash("3D town ON. Same town, more depth." if audio.view3d else "3D town OFF. Back to the flat map.", Color.WHITE, 1.0)
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
	if MUSIC_BAR.grow(6).has_point(p):
		dragging = "music"
		_set_from(MUSIC_BAR, p, "music")
	elif SFX_BAR.grow(6).has_point(p):
		dragging = "sfx"
		_set_from(SFX_BAR, p, "sfx")

func _pointer_move(p: Vector2) -> void:
	if dragging != "":
		_set_from(MUSIC_BAR if dragging == "music" else SFX_BAR, p, dragging)

func _pointer_up(_p: Vector2) -> void:
	if dragging == "sfx":
		AudioScript.sfx("select")
	dragging = ""

func _on(id: String) -> bool:
	match id:
		"mute": return audio != null and audio.muted
		"clean": return Cast.clean
		"gore": return audio == null or audio.gore
		"shake": return JuiceScript.shake_on
		"edm": return audio != null and audio.edm
		"view3d": return audio != null and audio.view3d
		"gfx": return _guard() != null and _guard().low
	return false

const ROW_TEXT: = {"mute": "Mute all", "clean": "Clean language", "gore": "Cartoon gore (KOs)", "shake": "Screen shake",
	"edm": "EDM soundtrack", "view3d": "3D view", "gfx": "Lite graphics", "credits": "Credits & legal", "report": "Send a bug report", "dev_quests": "Dev: quests"}

func _card(r: Rect2, head: String) -> void:
	draw_string(UiStyle.display, r.position + Vector2(4, -3), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 0.5))
	UiStyle.box(self, r, Color(UiStyle.GLASS.lightened(0.06), 0.93), 5.0)

func _switch(c: Vector2, on: bool) -> void:   # iOS-style: pill track, white knob
	var tr: = Rect2(c - Vector2(9, 5), Vector2(18, 10))
	UiStyle.box(self, tr, Color("#34c759") if on else Color(1, 1, 1, 0.2), 5.0)
	var k: = Vector2(tr.end.x - 5.0 if on else tr.position.x + 5.0, c.y)
	draw_circle(k + Vector2(0, 0.6), 4.2, Color(0, 0, 0, 0.25))
	draw_circle(k, 4.0, Color.WHITE)

func _slider(bar_r: Rect2, v: float, col: Color, label: String) -> void:
	txt(bar_r.position + Vector2(0, -5), label, 7, Color.WHITE)
	txt(Vector2(bar_r.end.x + 6, bar_r.position.y + 3), "%d%%" % roundi(v * 100.0), 7, Color(1, 1, 1, 0.6))
	UiStyle.box(self, bar_r.grow(0.3), Color(1, 1, 1, 0.18), 1.8)
	UiStyle.box(self, Rect2(bar_r.position, Vector2(maxf(bar_r.size.x * v, 3.0), bar_r.size.y)).grow(0.3), col, 1.8)
	var k: = Vector2(bar_r.position.x + bar_r.size.x * v, bar_r.get_center().y)
	draw_circle(k + Vector2(0, 0.7), 5.0, Color(0, 0, 0, 0.3))
	draw_circle(k, 4.6, Color.WHITE)

func _draw_game() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.03, 0.02, 0.06, 0.55))
	UiStyle.box(self, Rect2(0, 0, W, 19), Color(UiStyle.GLASS, 0.96), 0.0)
	draw_rect(Rect2(0, 19, W, 0.6), Color(1, 1, 1, 0.12))
	draw_string(UiStyle.display, Vector2(0, 13.5), "Settings", HORIZONTAL_ALIGNMENT_CENTER, W, 10, Color.WHITE)
	# left: sound card (two sliders + mute), more card; right: game card (switch rows)
	_card(Rect2(LEFT, TOP - 4, COL_W, 48 + ROW_H + 4), "SOUND")
	_slider(MUSIC_BAR, music_vol(), Color("#ff6aa8"), "Music")
	_slider(SFX_BAR, sfx_vol(), Color("#f2c66a"), "Sound FX")
	var more: = 2 + (1 if dev else 0)
	_card(Rect2(LEFT, TOP + 77, COL_W, ROW_H * more + 4), "MORE")
	var toggles: = buttons.filter(func(b): return TOGGLES.has(str(b["id"])))
	if not toggles.is_empty():
		_card(Rect2(RIGHT, TOP - 4, COL_W, ROW_H * toggles.size() + 4), "GAME")
	for b in buttons:
		var id: = str(b["id"])
		if not b.get("hide", false) or not ROW_TEXT.has(id):
			continue
		var r: Rect2 = b["rect"]
		var cy: = r.position.y + r.size.y * 0.5
		if bool(b.get("down", false)):
			UiStyle.box(self, Rect2(r.position.x + 1, cy - 8, r.size.x - 2, 16), Color(1, 1, 1, 0.08), 4.0)
		txt(Vector2(r.position.x + 10, cy + 2.5), str(ROW_TEXT[id]), 7, Color.WHITE)
		if id in ["credits", "report", "dev_quests"]:
			draw_string(UiStyle.display, Vector2(r.end.x - 12, cy + 3), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.45))
		else:
			_switch(Vector2(r.end.x - 16, cy), _on(id))
		if b != buttons.back() and id != "credits" and id != "report" and r.position.x == RIGHT and r.end.y < TOP + ROW_H * toggles.size():
			draw_rect(Rect2(r.position.x + 10, r.end.y - 0.3, r.size.x - 14, 0.5), Color(1, 1, 1, 0.08))
	txt(Vector2(LEFT + 4, H - 6), "Saved automatically.", 6, Color(1, 1, 1, 0.45))
