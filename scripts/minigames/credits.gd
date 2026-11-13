extends "res://scripts/minigames/minigame.gd"
## Settings > "Credits & legal": who made what, the parody/fiction notice, and every license the game
## has to ship (Godot's MIT text + its third-party notices, the four OFL fonts). Drag, mouse wheel or
## the arrow keys scroll. Built once on open; only the visible lines are drawn.

const FONT_FILES: = ["OFL-Baloo2.txt", "OFL-Nunito.txt", "OFL-Caveat.txt", "OFL-PatrickHand.txt"]
const BOX: = Rect2(8, 17, 304, 144)
const LINE_H: = 8.0
const SIZE: = 6
const PAD: = 4.0

var lines: Array = []      # [text, color]
var scroll: = 0.0
var drag_from: = -1.0
var drag_scroll: = 0.0

## Plain-text notice, shared with docs/itch/PAGE.md and the ending credits. Keep the three in sync.
static func notice() -> Array:
	return [
		"This is a comedy and a work of parody and fiction.",
		"Stores, restaurants, brands and products in the game are made-up parodies or",
		"used only for jokes. None of them made, sponsored or endorsed this game.",
		"The family and friends in it appear with their permission. Every other",
		"character is invented, and every event is made up or exaggerated for laughs.",
		"Any resemblance to other real people is a coincidence.",
	]

func _setup() -> void:
	title = "CREDITS & LEGAL"
	time_limit = 0.0
	space_is_pen = false
	add_button("up", Rect2(8, 163, 60, 15), "Up", KEY_UP, Color("#3a5a8a"))
	add_button("back", Rect2(110, 163, 100, 15), "Back", KEY_ESCAPE, Color("#a43a2c"))
	add_button("down", Rect2(252, 163, 60, 15), "Down", KEY_DOWN, Color("#3a5a8a"))
	_build()

func _head(s: String) -> void:
	lines.append(["", Color.WHITE])
	lines.append([s, Color("#f2c66a")])

func _para(s: String, col: Color = Color.WHITE) -> void:
	for raw in s.split("\n"):
		_wrap(str(raw).strip_edges(false, true), col)

func _wrap(s: String, col: Color) -> void:
	var width: = BOX.size.x - PAD * 2.0
	if s == "" or font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x <= width:
		lines.append([s, col])
		return
	var cur: = ""
	for word in s.split(" "):
		var next: = word if cur == "" else cur + " " + word
		if cur != "" and font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x > width:
			lines.append([cur, col])
			cur = word
		else:
			cur = next
	if cur != "":
		lines.append([cur, col])

func _build() -> void:
	var dim: = Color(1, 1, 1, 0.7)
	lines.append([Cast.T("{GAME_TITLE}"), Color("#ff6aa8")])
	_para(Cast.T("Made by {hero}, a line cook in {city}, on a phone."))
	_head("NOTICE")
	for s in notice():
		_para(s)
	_head("HOW IT WAS MADE")
	_para("Code: written with Claude (Anthropic) in the Godot Engine 4.5.")
	_para("Art: made with AI image tools (Grok, Gemini, ChatGPT, Canva AI) from the author's own photos and direction, then finished by hand and in code.")
	_para("Music and sound effects: synthesized by code for this game. The date-night theme is Brahms' Lullaby (1868, public domain).")
	_para("Writing: the author's life and jokes, edited with AI help.")
	_head("PRIVACY")
	_para("The game collects nothing about you. No accounts, ads, analytics or tracking. Your save stays on your device (in the browser's storage on the web). The game only downloads its own files; it never sends anything about you.")
	_head("FONTS (SIL Open Font License 1.1)")
	var ofl: = ""
	for f in FONT_FILES:
		var txt_s: = FileAccess.get_file_as_string("res://assets/fonts/" + f)
		if txt_s == "":
			_para(f.trim_prefix("OFL-").trim_suffix(".txt"), dim)
			continue
		_para(txt_s.get_slice("\n", 0).strip_edges().trim_prefix("﻿"), dim)
		if ofl == "":
			var at: = txt_s.find("-----")
			ofl = txt_s.substr(at) if at >= 0 else ""
	if ofl != "":
		_para(ofl, dim)
	_head("GODOT ENGINE (MIT License)")
	_para("This game uses Godot Engine, available under the following license:", dim)
	_para(Engine.get_license_text(), dim)
	_head("THIRD-PARTY CODE IN GODOT ENGINE")
	_para("Portions of this software are copyright (c) The FreeType Project (www.freetype.org). All rights reserved.", dim)
	for c in Engine.get_copyright_info():
		lines.append(["", Color.WHITE])
		_para(str(c.get("name", "")), Color("#a0c0ff"))
		for p in c.get("parts", []):
			for cr in p.get("copyright", []):
				_para("(c) " + str(cr), dim)
			_para("License: " + str(p.get("license", "")), dim)
	_head("LICENSE TEXTS")
	var info: = Engine.get_license_info()
	for k in info.keys():
		lines.append(["", Color.WHITE])
		_para(str(k), Color("#a0c0ff"))
		_para(str(info[k]), dim)

func max_scroll() -> float:
	return maxf(0.0, lines.size() * LINE_H + PAD * 2.0 - BOX.size.y)

func _scroll_by(d: float) -> void:
	scroll = clampf(scroll + d, 0.0, max_scroll())

func _on_button(id: String) -> void:
	match id:
		"up": _scroll_by(-BOX.size.y * 0.8)
		"down": _scroll_by(BOX.size.y * 0.8)
		"back": finish(1.0)

func _tick(delta: float) -> void:
	if Input.is_key_pressed(KEY_PAGEDOWN):
		_scroll_by(240.0 * delta)
	elif Input.is_key_pressed(KEY_PAGEUP):
		_scroll_by(-240.0 * delta)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		var mb: = e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_by(LINE_H * 3.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_by(-LINE_H * 3.0)

func _pointer_down(p: Vector2) -> void:
	if BOX.has_point(p):
		drag_from = p.y
		drag_scroll = scroll

func _pointer_move(p: Vector2) -> void:
	if drag_from >= 0.0:
		scroll = clampf(drag_scroll + (drag_from - p.y), 0.0, max_scroll())

func _pointer_up(_p: Vector2) -> void:
	drag_from = -1.0

func _draw_game() -> void:
	draw_rect(BOX, Color(0, 0, 0, 0.55))
	var first: = maxi(0, int((scroll - PAD) / LINE_H))
	var last: = mini(lines.size() - 1, int((scroll + BOX.size.y) / LINE_H) + 1)
	for i in range(first, last + 1):
		var y: = BOX.position.y + PAD + (i + 1) * LINE_H - 2.0 - scroll
		if y < BOX.position.y + LINE_H - 2.0 or y > BOX.end.y - 1.0:
			continue
		var ln: Array = lines[i]
		draw_string(font, Vector2(BOX.position.x + PAD, y), str(ln[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, ln[1])
	var ms: = max_scroll()
	if ms > 0.0:
		var h: = maxf(8.0, BOX.size.y * BOX.size.y / (BOX.size.y + ms))
		var y0: = BOX.position.y + (BOX.size.y - h) * scroll / ms
		draw_rect(Rect2(BOX.end.x - 3, y0, 2, h), Color(1, 1, 1, 0.4))
