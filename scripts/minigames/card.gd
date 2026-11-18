extends "res://scripts/minigames/minigame.gd"

signal chosen(id: String)

var heading: = ""
var lines: Array = []
var lines2: Array = []
var big: = ""
var big_col: = Color.WHITE
var opts: Array = []

func _setup() -> void:
	time_limit = 0.0
	show_header = false
	pill_buttons = true
	space_is_pen = false
	var n: = opts.size()
	var cols: = n if n <= 3 else (3 if n >= 7 else 2)   # 7+ choices in 3 columns, so the text above keeps room
	if backdrop == "title" and n > 1:
		cols = 2
	var rows: = int(ceil(float(n) / cols))
	var bw: = 308.0 / cols
	# Title: two button columns flank the porch steps, so Duff (centre of bg_title) stays in view.
	var flank: = backdrop == "title" and cols == 2
	if flank:
		bw = 128.0
	for i in n:
		var o: Array = opts[i]
		var r: = i / cols
		var c: = i % cols
		# Nov 18 (Duff: fat fingers): 6-8 units between choices (was 3-4); taller rows when there's room.
		var pitch: = 28.0 if rows <= 2 else 26.0
		var y: = 177.0 - (rows - r) * pitch
		var x: = (6.0 + c * (W - 12.0 - bw + 8.0)) if flank else (10.0 + c * bw)
		add_button(o[0], Rect2(x, y, bw - 8, 22), o[1], o[2], UiStyle.BTN_MAIN if i == 0 else UiStyle.BTN_ALT)
	if _sliding():
		position.y = SLIDE_PX

## Nov 17: sheets slide up into place (0.22 s ease-out); taps during the slide are ignored so a double tap from
## the previous screen can't pick an option. Not on the title or fail screens, and never headless (tests).
const SLIDE_T: = 0.22
const SLIDE_PX: = 70.0

func _sliding() -> bool:
	return backdrop != "title" and get_script() == preload("res://scripts/minigames/card.gd") \
		and DisplayServer.get_name() != "headless" and t < SLIDE_T

func _tick(_d: float) -> void:
	var k: = clampf(t / SLIDE_T, 0.0, 1.0)
	position.y = SLIDE_PX * pow(1.0 - k, 3.0) if _sliding() else 0.0

func _on_button(id: String) -> void:
	if _sliding():
		return
	done = true
	chosen.emit(id)

## Body lines are wrapped here (body font) and drawn at 1.3x size apart: Nunito's own line gap is ~1.7x,
## which pushed long cards (the 86 list) under their buttons.
func _wrap(s: String, w: float, size: int) -> PackedStringArray:
	var out: = PackedStringArray()
	for para in Cast.T(s).split("\n"):
		var cur: = ""
		for word in para.split(" "):
			var trial: = word if cur == "" else cur + " " + word
			if cur != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > w:
				out.append(cur)
				cur = word
			else:
				cur = trial
		out.append(cur)
	return out

func _wrap_h(s: String, w: float, size: int = 8) -> float:
	return _wrap(s, w, size).size() * size * 1.3

## Room for body text: from the first line down to just above the top row of buttons.
func _text_room() -> float:
	var top: = H
	for b in buttons:
		top = minf(top, (b["rect"] as Rect2).position.y)
	return top - 5.0 - 19.0 - 2.0   # sheet: title 19, gap above the buttons 5

## Body size that fits above the buttons: 8, else 7, else 6 (the 86 list's last line used to slide under them).
func _body_size(w1: float) -> int:
	for sz in [8, 7, 6]:
		var hh: = 0.0
		for l in lines:
			var ls: = str(l)
			hh += sz * 1.3 if "\t" in ls else _wrap_h(ls, w1, sz)
		if hh <= _text_room():
			return sz
	return 6

## Nov 17: cards are phone sheets (match the phone HUD). A dark glass sheet rises from the bottom just as tall as
## its text + buttons, with a grabber, a bold title and a hairline; the scene stays visible above it. The title
## screen keeps Duff on the porch clear: its title + line sit on a small glass plate up top instead.
func _draw_game() -> void:
	if backdrop == "" and not veiled:
		UiStyle.burst(self, Rect2(0, 0, W, H), Color("#3a2a52"), Vector2(W * 0.5, H * 0.62), 28, t * 0.05)
	var x2: = 168.0 if not lines2.is_empty() else 0.0
	var w1: = (x2 - 18.0) if x2 > 0.0 else (W - 20.0 - (60.0 if big != "" else 0.0))
	var fs: = _body_size(w1)
	var hh: = 0.0
	for l in lines:
		var ls: = str(l)
		hh += fs * 1.3 if "\t" in ls else _wrap_h(ls, w1, fs)
	hh = maxf(hh, 10.0 * lines2.size())
	if big != "" and lines2.is_empty():
		hh = maxf(hh, 50.0)
	var btop: = H
	for b in buttons:
		btop = minf(btop, (b["rect"] as Rect2).position.y)
	if backdrop == "title":
		_draw_title_plate(fs, hh)
		return
	var top: = maxf(2.0, btop - 5.0 - hh - (19.0 if hh > 0.0 else 15.0))
	var sheet: = Rect2(3, top, W - 6, H - top + 10.0)
	if top > 40.0:   # a soft dark fade above the sheet so it reads as lifted off the scene
		for i in 6:
			draw_rect(Rect2(0, top - 12.0 + i * 2.0, W, 2.0), Color(0, 0, 0, 0.04 * (i + 1)))
	UiStyle.glass(self, sheet, 8.0, 0.94, 1.0 / 1.5)
	draw_rect(Rect2(W * 0.5 - 10.0, top + 2.5, 20.0, 1.4), Color(1, 1, 1, 0.3))   # grabber
	draw_string(UiStyle.display, Vector2(11, top + 14.5), Cast.T(heading), HORIZONTAL_ALIGNMENT_LEFT, W - 22.0, 11, UiStyle.CREAM)
	draw_rect(Rect2(10, top + 17.5, W - 20.0, 0.6), Color(1, 1, 1, 0.12))
	var y: = top + 19.0 + fs
	for l in lines:
		var s: = str(l)
		if "\t" in s:
			var parts: = s.split("\t")
			txt(Vector2(11, y), parts[0], fs, Color.WHITE)
			txt(Vector2(123, y), parts[1], fs, grade_col(parts[1].substr(0, 1)))
			y += fs * 1.3
			continue
		for ln in _wrap(s, w1, fs):
			draw_string(font, Vector2(11, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.92))
			y += fs * 1.3
	y = top + 27.0
	for l in lines2:
		txt(Vector2(x2, y), str(l), 8, Color("#e6e6f0"))
		y += 10.0
	if big != "" and not lines2.is_empty():
		UiStyle.label(self, Vector2(W - 34, top + 15), big, 15, big_col, 30, HORIZONTAL_ALIGNMENT_CENTER, 4)
	elif big != "":
		UiStyle.label(self, Vector2(W - 68, top + 19.0 + hh * 0.5 + 14.0), big, 44, big_col, 60, HORIZONTAL_ALIGNMENT_CENTER, 8)

## Title screen: logo-style title and the tagline on a glass plate at the top; the porch stays in view.
func _draw_title_plate(fs: int, _hh: float) -> void:
	var w1: = W - 40.0
	var rows: = 0
	for l in lines:
		rows += _wrap(str(l), w1, fs).size()
	var plate: = Rect2(14, 4, W - 28, 21.0 + rows * fs * 1.3)
	UiStyle.glass(self, plate, 7.0, 0.82, 1.0 / 1.5)
	UiStyle.label(self, Vector2(0, 18), Cast.T(heading), 14, UiStyle.GOLD, W, HORIZONTAL_ALIGNMENT_CENTER, 4)
	var y: = 22.0 + fs
	for l in lines:
		for ln in _wrap(str(l), w1, fs):
			draw_string(font, Vector2(20, y), ln, HORIZONTAL_ALIGNMENT_CENTER, w1, fs, Color(1, 1, 1, 0.92))
			y += fs * 1.3

func grade_col(g: String) -> Color:
	return {"S": Color("#e6a640"), "A": Color("#c0d890"), "B": Color("#8ad0ff"), "C": Color("#e6a640"), "F": Color("#e06a4a") }.get(g, Color.WHITE)
