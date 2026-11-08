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
	var cols: = n if n <= 3 else 2
	var rows: = int(ceil(float(n) / cols))
	var bw: = 308.0 / cols
	for i in n:
		var o: Array = opts[i]
		var r: = i / cols
		var c: = i % cols
		var y: = 176.0 - (rows - r) * 24.0
		add_button(o[0], Rect2(6 + c * bw, y, bw - 4, 21), o[1], o[2], Color("#c8452f") if i == 0 else Color("#57504e"))

func _on_button(id: String) -> void:
	done = true
	chosen.emit(id)

## Real wrapped height of a line in the body font (the old fixed 10 per line overlapped with Nunito).
func _wrap_h(s: String, w: float) -> float:
	return font.get_multiline_string_size(Cast.T(s), HORIZONTAL_ALIGNMENT_LEFT, w, 8).y

func _draw_game() -> void:
	if backdrop == "":
		UiStyle.burst(self, Rect2(0, 0, W, H), Color("#3a2a52"), Vector2(W * 0.5, H * 0.62), 28, t * 0.05)
	draw_rect(Rect2(0, 0, W, 17), UiStyle.PINK.darkened(0.15))
	draw_rect(Rect2(0, 15.5, W, 1.5), UiStyle.INK)
	UiStyle.label(self, Vector2(0, 13), Cast.T(heading), 12, UiStyle.CREAM, W, HORIZONTAL_ALIGNMENT_CENTER, 4)
	var x2: = 168.0 if not lines2.is_empty() else 0.0
	var w1: = (x2 - 12.0) if x2 > 0.0 else (W - 12.0 - (60.0 if big != "" else 0.0))
	var y: = 28.0
	# panel behind the text: always (backdrop art or the burst)
	var hh: = 0.0
	for l in lines:
		var ls: = str(l)
		hh += 10.0 if "\t" in ls else _wrap_h(ls, w1)
	hh = maxf(hh, 10.0 * lines2.size())
	if hh > 0.0:
		UiStyle.panel(self, Rect2(2, 19, W - 4, hh + 4), UiStyle.PANEL, 0.9, 1.0 / 1.5)
	for l in lines:
		var s: = str(l)
		if "\t" in s:
			var parts: = s.split("\t")
			txt(Vector2(6, y), parts[0], 8, Color.WHITE)
			txt(Vector2(118, y), parts[1], 8, grade_col(parts[1].substr(0, 1)))
			y += 10.0
			continue
		mtxt(Vector2(6, y), s, w1, 8, Color.WHITE)
		y += _wrap_h(s, w1)
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
