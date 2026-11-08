extends SceneTree
## Finds dialogue / toast lines that don't fit their box (they get cut off mid-sentence).
##   godot --headless --path . --script tools/text_fit.gd
## Scans every string literal of 25+ chars in scripts/ (toast(...) args get the toast box, the rest
## the dialog box, worst case = portrait shown),
## swaps in cast names, then wraps it with the same font, size and width the HUD uses.
## Box limits come from hud.gd: toast 3 lines at width 288-4, dialog 6 lines at width 128
## (portrait lines) or 178. Writes docs/text_fit.txt and prints a summary.

const Cast: = preload("res://scripts/cast.gd")
const TOAST_W: = 300.0 - 8.0 - 4.0
const TOAST_LINES: = 3
const DLG_W_PORTRAIT: = 192.0 - 64.0
const DLG_W: = 192.0 - 14.0
const DLG_LINES: = 5   # 6 fit on paper, but line 6 runs into the "E / A >" prompt
const SIZE: = 7

var font: Font

func _init() -> void:
	font = _font()
	var files: = _scripts("res://scripts")
	var re_lit: = RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var re_toast: = RegEx.create_from_string("(?:_toast|toast)\\(\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")
	var bad: Array = []
	var seen: = {}
	var checked: = 0
	for path in files:
		var src: = FileAccess.get_file_as_string(path)
		var lines: = src.split("\n")
		for i in lines.size():
			var ln: String = lines[i]
			if ln.strip_edges().begins_with("#") or ln.find("preload(") >= 0 or ln.find("load(") >= 0:
				continue
			var toast_lits: = {}
			for m in re_toast.search_all(ln):
				toast_lits[m.get_string(1)] = true
			for m in re_lit.search_all(ln):
				var raw: String = m.get_string(1)
				if raw.length() < 25 or raw.begins_with("res://") or seen.has(raw):
					continue
				seen[raw] = true
				var s: = Cast.T(raw.replace("\\\"", "\"").replace("\\n", "\n"))
				s = s.replace("%d", "999").replace("%s", "something long").replace("%.0f", "99").replace("%.1f", "9.9")
				checked += 1
				if toast_lits.has(raw):
					var n: = _lines(s, TOAST_W)
					if n > TOAST_LINES:
						bad.append("TOAST %d/%d lines  %s:%d  %s" % [n, TOAST_LINES, path.get_file(), i + 1, s])
				else:
					var w: = DLG_W_PORTRAIT   # worst case: a portrait is shown (most lines are Duff's)
					var n2: = _lines(s, w)
					if n2 > DLG_LINES:
						bad.append("DIALOG %d/%d lines  %s:%d  %s" % [n2, DLG_LINES, path.get_file(), i + 1, s])
	bad.sort()
	var out: = FileAccess.open("res://docs/text_fit.txt", FileAccess.WRITE)
	out.store_string("Lines that overflow their box (checked %d literals)\n\n" % checked + "\n".join(bad) + "\n")
	print("text_fit: checked %d, overflow %d -> docs/text_fit.txt" % [checked, bad.size()])
	quit()

func _lines(s: String, width: float) -> int:
	# same wrap as draw_multiline_string (word break, ignores trailing spaces)
	var n: = 0
	for para in s.split("\n"):
		var words: = para.split(" ", false)
		var cur: = ""
		var k: = 1
		for wd in words:
			var t: = wd if cur == "" else cur + " " + wd
			if cur != "" and font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x > width:
				k += 1
				cur = wd
			else:
				cur = t
		n += k
	return n

func _scripts(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir + "/" + d))
	return out


## The game's real body font (M8): --script runs skip autoloads, so install it here.
func _font() -> Font:
	preload("res://scripts/ui_style.gd").install()
	return ThemeDB.fallback_font
