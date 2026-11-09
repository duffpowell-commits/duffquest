extends Node2D
## Fridge calendar: the month on paper, stuck to the fridge with magnets, plus today's sticky notes
## (Duff, Madison, Octavia's crayon, the cats). Full screen at real resolution on game.gd's top layer.
## Shows each morning after the loading screen (main.calendar_pending) and when Duff checks the
## fridge at home. Tap to close. Data: data/calendar.json + data/daily_events.json via daily.gd.
const Cast: = preload("res://scripts/cast.gd")
const Daily: = preload("res://scripts/daily.gd")

const MIN_T: = 0.6
const MAX_T: = 25.0
const FADE: = 0.2
const FRIDGE: = Color("#ebe7dc")
const PAPER: = Color("#fbfaf4")
const INK: = Color("#2b2730")
const RED: = Color("#c8322f")
const GREEN: = Color("#2f8a4a")
const PENCIL: = Color(0.35, 0.33, 0.38, 0.55)
const NOTE: = {
	"partner": {"bg": Color("#ffe27a"), "ink": Color("#5b2a86"), "font": "caveat", "sig": "- M"},
	"hero": {"bg": Color("#a9dcff"), "ink": Color("#1d3a6b"), "font": "patrick", "sig": "- D"},
	"baby": {"bg": Color("#ffc2dc"), "ink": Color("#7a3fd0"), "font": "caveat", "sig": "- O (crayon)"},
	"cat1": {"bg": Color("#ffd9b0"), "ink": Color("#6b3d12"), "font": "caveat", "sig": "{cat1}"},
	"cat2": {"bg": Color("#ffd9b0"), "ink": Color("#6b3d12"), "font": "caveat", "sig": "{cat2}"},
	"cat3": {"bg": Color("#e6d5ff"), "ink": Color("#4a2f6b"), "font": "caveat", "sig": "{cat3}"},
}
const DOW: = ["S", "M", "T", "W", "T", "F", "S"]

var main: Node
var _seen_req: = 0
var _t: = -1.0
var _fonts: = {}

func _ready() -> void:
	_fonts["caveat"] = load("res://assets/fonts/Caveat-Bold.woff2")
	_fonts["patrick"] = load("res://assets/fonts/PatrickHand-Regular.woff2")
	_fonts["head"] = load("res://assets/fonts/Baloo2-ExtraBold.ttf")
	_fonts["small"] = load("res://assets/fonts/Nunito-ExtraBold.ttf")
	for k in _fonts:
		if _fonts[k] == null:
			_fonts[k] = ThemeDB.fallback_font

func _input(e: InputEvent) -> void:
	if _t < 0.0:
		return
	var press: bool = (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed) \
		or (e is InputEventKey and e.pressed and not e.echo)
	if press:
		get_viewport().set_input_as_handled()
		if _t > MIN_T:
			_close()

func _close() -> void:
	_t = -1.0
	if main and main.has_method("calendar_done"):
		main.calendar_done()

func _process(d: float) -> void:
	if main and int(main.calendar_req) != _seen_req:
		_seen_req = int(main.calendar_req)
		_t = 0.0
	if _t >= 0.0:
		_t += d
		if _t >= MAX_T:
			_close()
	queue_redraw()

func _T(s: String) -> String:
	return Cast.T(s)

func _draw() -> void:
	if _t < 0.0 or main == null:
		return
	var vp: = get_viewport_rect().size
	var u: = vp.y / 360.0
	var a: = clampf(_t / FADE, 0.0, 1.0)
	var mod: = Color(1, 1, 1, a)
	draw_set_transform(Vector2.ZERO)
	_draw_fridge(vp, u, a)
	var day: = int(main.day_count)
	var dom: = Daily.day_of_month(day)
	# weekday of the 1st, Sunday-first columns (main.DAY_NAMES: 0 Monday .. 6 Sunday)
	var wd_today: = int(main.day_i) % 7
	var col_today: = (wd_today + 1) % 7
	var col_first: = posmod(col_today - (dom - 1), 7)
	_draw_paper(Rect2(vp.x * 0.035, vp.y * 0.05, vp.x * 0.585, vp.y * 0.78), u, a, day, dom, col_first)
	_draw_notes(Rect2(vp.x * 0.645, vp.y * 0.05, vp.x * 0.30, vp.y * 0.78), u, a, day)
	# today band
	var band: = Rect2(0, vp.y * 0.86, vp.x, vp.y * 0.14)
	draw_rect(band, Color(0.03, 0.02, 0.04, 0.86 * a))
	draw_line(band.position, Vector2(vp.x, band.position.y), Color(0.25, 0.88, 0.82, a), 2.0 * u)
	var card: = _T(str(Daily.entry(day).get("card", "")))
	if card == "":
		card = "Day %d. Coffee. Then everything else." % day
	var head: = "%s %d" % [main.DAY_NAMES[wd_today].to_upper(), dom]
	draw_string(_fonts["small"], Vector2(vp.x * 0.03, band.position.y + 16 * u), head, HORIZONTAL_ALIGNMENT_LEFT, -1, int(9 * u), Color(0.25, 0.88, 0.82, a))
	draw_multiline_string(_fonts["patrick"], Vector2(vp.x * 0.03, band.position.y + 30 * u), card, HORIZONTAL_ALIGNMENT_LEFT,
		vp.x * 0.86, int(13 * u), 2, Color(0.96, 0.93, 0.88, a))
	if _t > MIN_T:
		draw_string(_fonts["small"], Vector2(vp.x * 0.89, band.position.y + 16 * u), "tap", HORIZONTAL_ALIGNMENT_LEFT, -1, int(8 * u), Color(1, 1, 1, 0.45 * a))

func _draw_fridge(vp: Vector2, u: float, a: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(FRIDGE, a))
	# soft top-light / bottom shade
	for i in 12:
		var y0: = vp.y * i / 12.0
		draw_rect(Rect2(0, y0, vp.x, vp.y / 12.0 + 1), Color(0, 0, 0, 0.012 * i * a))
	# handle
	var hx: = vp.x * 0.968
	draw_rect(Rect2(hx, vp.y * 0.12, 9 * u, vp.y * 0.62), Color(0.62, 0.64, 0.68, a))
	draw_rect(Rect2(hx + 2 * u, vp.y * 0.12, 2 * u, vp.y * 0.62), Color(1, 1, 1, 0.55 * a))

func _magnet(p: Vector2, u: float, col: Color, a: float) -> void:
	draw_circle(p + Vector2(1.5, 2) * u, 7 * u, Color(0, 0, 0, 0.18 * a))
	draw_circle(p, 7 * u, Color(col, a))
	draw_circle(p + Vector2(-2, -2) * u, 2.2 * u, Color(1, 1, 1, 0.45 * a))

func _draw_paper(r: Rect2, u: float, a: float, day: int, dom: int, col_first: int) -> void:
	draw_rect(Rect2(r.position + Vector2(3, 4) * u, r.size), Color(0, 0, 0, 0.16 * a))
	draw_rect(r, Color(PAPER, a))
	_magnet(r.position + Vector2(r.size.x * 0.12, 6 * u), u, Color("#e0453a"), a)
	_magnet(r.position + Vector2(r.size.x * 0.88, 6 * u), u, Color("#2fb3a6"), a)
	var head: = "%s" % Daily.month_name(day)
	draw_string(_fonts["head"], Vector2(r.position.x, r.position.y + 30 * u), head, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(20 * u), Color(INK, a))
	var sub: = _T("{hero} + {partner} + {baby} + {cat1}, {cat2} & {cat3}")
	draw_string(_fonts["caveat"], Vector2(r.position.x, r.position.y + 42 * u), sub, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(11 * u), Color(0.45, 0.3, 0.6, a))
	var gx: = r.position.x + 8 * u
	var gw: = r.size.x - 16 * u
	var cw: = gw / 7.0
	var gy: = r.position.y + 48 * u
	for i in 7:
		draw_string(_fonts["small"], Vector2(gx + i * cw, gy + 8 * u), DOW[i], HORIZONTAL_ALIGNMENT_CENTER, cw, int(8 * u), Color(INK, 0.6 * a))
	gy += 12 * u
	var rows: = int(ceil((col_first + Daily.MONTH_LEN) / 7.0))
	var ch: = (r.end.y - 6 * u - gy) / rows
	var cal_month: = (day - 1) / Daily.MONTH_LEN
	for d in range(1, Daily.MONTH_LEN + 1):
		var idx: = col_first + d - 1
		var cell: = Rect2(gx + (idx % 7) * cw, gy + (idx / 7) * ch, cw, ch)
		draw_rect(cell, Color(INK, 0.18 * a), false, 1.0)
		draw_string(_fonts["small"], cell.position + Vector2(3 * u, 9 * u), str(d), HORIZONTAL_ALIGNMENT_LEFT, -1, int(7 * u), Color(INK, 0.75 * a))
		var e: = Daily.entry(cal_month * Daily.MONTH_LEN + d)
		var tag: = _T(str(e.get("tag", "")))
		if tag != "":
			var tc: = Color("#5b2a86")
			if tag == "RENT": tc = RED
			elif tag == "PAYDAY": tc = GREEN
			elif tag == "<3": tc = Color("#d0457a")
			draw_string(_fonts["caveat"], Vector2(cell.position.x, cell.end.y - 5 * u), tag, HORIZONTAL_ALIGNMENT_CENTER, cell.size.x, int(10 * u), Color(tc, a))
		if d < dom:
			# crossed off in pencil
			var p: = 5 * u
			draw_line(cell.position + Vector2(p, p + 4 * u), cell.end - Vector2(p, p), Color(PENCIL, PENCIL.a * a), 1.4 * u)
			draw_line(Vector2(cell.end.x - p, cell.position.y + p + 4 * u), Vector2(cell.position.x + p, cell.end.y - p), Color(PENCIL, PENCIL.a * a), 1.4 * u)
		elif d == dom:
			_marker_ring(cell.grow(-1.5 * u), u, a)

func _marker_ring(cell: Rect2, u: float, a: float) -> void:
	var c: = cell.get_center()
	var rx: = cell.size.x * 0.5
	var ry: = cell.size.y * 0.5
	for lap in 2:
		var pts: = PackedVector2Array()
		for i in 41:
			var t: = TAU * i / 40.0 + lap * 0.35
			var wob: = 1.0 + 0.04 * sin(t * 3.0 + lap)
			pts.append(c + Vector2(cos(t) * rx * wob, sin(t) * ry * wob))
		draw_polyline(pts, Color(RED, 0.85 * a), 2.0 * u, true)

func _notes_for(day: int) -> Array:
	var out: Array = []
	var ev: = str(main.today_event()) if main.has_method("today_event") else ""
	if ev != "":
		var e: = Daily.event(ev)
		var n: Dictionary = (e.get("note", {}) as Dictionary).duplicate()
		n["effect"] = str(e.get("effect", ""))
		out.append(n)
	for n in Daily.entry(day).get("notes", []):
		out.append(n)
	return out.slice(0, 4)

func _draw_notes(area: Rect2, u: float, a: float, day: int) -> void:
	var notes: = _notes_for(day)
	if notes.is_empty():
		draw_string(_fonts["caveat"], area.position + Vector2(0, area.size.y * 0.4), "(nothing on the fridge today)",
			HORIZONTAL_ALIGNMENT_CENTER, area.size.x, int(13 * u), Color(INK, 0.4 * a))
		return
	var gap: = 6 * u
	var h: = (area.size.y - gap * (notes.size() - 1)) / notes.size()
	h = minf(h, area.size.y * 0.42)
	for i in notes.size():
		var n: Dictionary = notes[i]
		var style: Dictionary = NOTE.get(str(n.get("from", "partner")), NOTE["partner"])
		var r: = Rect2(area.position.x, area.position.y + i * (h + gap), area.size.x, h)
		var rot: = deg_to_rad([-2.5, 1.8, -1.2, 2.2][i % 4])
		draw_set_transform(r.get_center(), rot)
		var lr: = Rect2(-r.size * 0.5, r.size)
		draw_rect(Rect2(lr.position + Vector2(2, 3) * u, lr.size), Color(0, 0, 0, 0.15 * a))
		draw_rect(lr, Color(style["bg"], a))
		draw_rect(Rect2(lr.position, Vector2(lr.size.x, 5 * u)), Color(0, 0, 0, 0.06 * a))   # sticky strip
		var font: Font = _fonts[style["font"]]
		var fs: = int((14 if style["font"] == "caveat" else 11) * u)
		var effect: = str(n.get("effect", ""))
		var text_h: = lr.size.y - (22 if effect != "" else 14) * u
		var lines: = maxi(1, int(text_h / (fs * 1.05)))
		draw_multiline_string(font, lr.position + Vector2(7 * u, 6 * u + fs), _T(str(n.get("text", ""))), HORIZONTAL_ALIGNMENT_LEFT,
			lr.size.x - 14 * u, fs, lines, Color(style["ink"], a))
		var sig: = _T(str(style["sig"]))
		var sig_p: = Vector2(lr.end.x - 8 * u, lr.end.y - (12 if effect != "" else 4) * u)
		if str(n.get("from", "")).begins_with("cat"):
			_paw(sig_p - Vector2(5 * u, 4 * u), u, Color(style["ink"], 0.8 * a))
			sig_p.x -= 12 * u
		draw_string(font, sig_p - Vector2(200 * u, 0), sig, HORIZONTAL_ALIGNMENT_RIGHT, 200 * u, int(fs * 0.8), Color(style["ink"], 0.85 * a))
		if effect != "":
			draw_string(_fonts["small"], Vector2(lr.position.x + 7 * u, lr.end.y - 4 * u), effect, HORIZONTAL_ALIGNMENT_LEFT,
				lr.size.x - 14 * u, int(6.5 * u), Color(0.15, 0.15, 0.2, 0.8 * a))
		draw_set_transform(Vector2.ZERO)

func _paw(p: Vector2, u: float, col: Color) -> void:
	draw_circle(p, 2.6 * u, col)
	for o in [Vector2(-3, -3.5), Vector2(-1, -5), Vector2(1.5, -5), Vector2(3.5, -3.3)]:
		draw_circle(p + o * u, 1.1 * u, col)
