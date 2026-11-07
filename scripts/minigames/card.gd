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
		add_button(o[0], Rect2(6 + c * bw, y, bw - 4, 21), o[1], o[2], Color("#a43a2c") if i == 0 else Color("#57504e"))

func _on_button(id: String) -> void:
	done = true
	chosen.emit(id)

func _draw_game() -> void:
	draw_rect(Rect2(0, 0, W, 16), Color("#a43a2c"))
	txt(Vector2(0, 12), heading, 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	var x2: = 168.0 if not lines2.is_empty() else 0.0
	var w1: = (x2 - 12.0) if x2 > 0.0 else (W - 12.0 - (60.0 if big != "" else 0.0))
	var y: = 28.0
	if backdrop != "":

		var hh: = 0.0
		for l in lines:
			var ls: = str(l)
			hh += 10.0 if "\t" in ls else 10.0 * maxi(1, int(ceil(font.get_string_size(ls, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x / w1)))
		hh = maxf(hh, 10.0 * lines2.size())
		if hh > 0.0:
			draw_rect(Rect2(2, 19, W - 4, hh + 4), Color(0.08, 0.06, 0.12, 0.82))
	for l in lines:
		var s: = str(l)
		if "\t" in s:
			var parts: = s.split("\t")
			txt(Vector2(6, y), parts[0], 8, Color.WHITE)
			txt(Vector2(118, y), parts[1], 8, grade_col(parts[1].substr(0, 1)))
			y += 10.0
			continue
		var n: = maxi(1, int(ceil(font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x / w1)))
		mtxt(Vector2(6, y), s, w1, 8, Color.WHITE)
		y += 10.0 * n
	y = 28.0
	for l in lines2:
		txt(Vector2(x2, y), str(l), 8, Color("#e6e6f0"))
		y += 10.0
	if big != "" and not lines2.is_empty():
		draw_rect(Rect2(W - 30, 0, 30, 16), Color(0, 0, 0, 0.5))
		txt(Vector2(W - 30, 13), big, 14, big_col, HORIZONTAL_ALIGNMENT_CENTER, 30)
	elif big != "":
		txt(Vector2(W - 64, 64), big, 40, big_col, HORIZONTAL_ALIGNMENT_CENTER, 60)

func grade_col(g: String) -> Color:
	return {"S": Color("#e6a640"), "A": Color("#c0d890"), "B": Color("#8ad0ff"), "C": Color("#e6a640"), "F": Color("#e06a4a") }.get(g, Color.WHITE)
