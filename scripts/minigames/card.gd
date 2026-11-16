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
		var y: = 176.0 - (rows - r) * 24.0
		var x: = (6.0 + c * (W - 12.0 - bw + 4.0)) if flank else (6.0 + c * bw)
		add_button(o[0], Rect2(x, y, bw - 4, 21), o[1], o[2], UiStyle.BTN_MAIN if i == 0 else UiStyle.BTN_ALT)

func _on_button(id: String) -> void:
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
	return top - 3.0 - 19.0

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

func _draw_game() -> void:
	if backdrop == "" and not veiled:
		UiStyle.burst(self, Rect2(0, 0, W, H), Color("#3a2a52"), Vector2(W * 0.5, H * 0.62), 28, t * 0.05)
	if backdrop == "" and not veiled:   # vignette: the burst fades to dark at the edges so the card has a centre
		for i in 6:
			var g: = float(i) * 6.0
			draw_rect(Rect2(g, g, W - g * 2.0, H - g * 2.0), Color(UiStyle.INK, 0.07), false, 6.0)
	draw_rect(Rect2(0, 0, W, 17), UiStyle.PINK.darkened(0.15))
	draw_rect(Rect2(0, 0, W, 6), UiStyle.PINK.darkened(0.02))
	draw_rect(Rect2(0, 13, W, 2.5), UiStyle.PINK.darkened(0.32))
	draw_rect(Rect2(0, 15.5, W, 1.5), UiStyle.INK)
	draw_rect(Rect2(0, 17, W, 1.5), Color(UiStyle.INK, 0.4))
	UiStyle.label(self, Vector2(0, 13), Cast.T(heading), 12, UiStyle.CREAM, W, HORIZONTAL_ALIGNMENT_CENTER, 4)
	var x2: = 168.0 if not lines2.is_empty() else 0.0
	var w1: = (x2 - 12.0) if x2 > 0.0 else (W - 12.0 - (60.0 if big != "" else 0.0))
	var fs: = _body_size(w1)
	var y: = 20.0 + fs
	# panel behind the text: always (backdrop art or the burst)
	var hh: = 0.0
	for l in lines:
		var ls: = str(l)
		hh += fs * 1.3 if "\t" in ls else _wrap_h(ls, w1, fs)
	hh = maxf(hh, 10.0 * lines2.size())
	if hh > 0.0:
		UiStyle.panel(self, Rect2(2, 19, W - 4, hh + 4), UiStyle.PANEL, 0.9, 1.0 / 1.5)
	for l in lines:
		var s: = str(l)
		if "\t" in s:
			var parts: = s.split("\t")
			txt(Vector2(6, y), parts[0], fs, Color.WHITE)
			txt(Vector2(118, y), parts[1], fs, grade_col(parts[1].substr(0, 1)))
			y += fs * 1.3
			continue
		for ln in _wrap(s, w1, fs):
			draw_string(font, Vector2(6, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
			y += fs * 1.3
	y = 28.0
	for l in lines2:
		txt(Vector2(x2, y), str(l), 8, Color("#e6e6f0"))
		y += 10.0
	if big != "" and not lines2.is_empty():
		UiStyle.label(self, Vector2(W - 30, 14), big, 15, big_col, 30, HORIZONTAL_ALIGNMENT_CENTER, 4)
	elif big != "":
		UiStyle.label(self, Vector2(W - 64, 66), big, 44, big_col, 60, HORIZONTAL_ALIGNMENT_CENTER, 8)

func grade_col(g: String) -> Color:
	return {"S": Color("#e6a640"), "A": Color("#c0d890"), "B": Color("#8ad0ff"), "C": Color("#e6a640"), "F": Color("#e06a4a") }.get(g, Color.WHITE)
