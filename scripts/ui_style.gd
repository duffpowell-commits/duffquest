extends Node
## Menu style (M8, Nov 8): copies the look of Place's boss cards: flat bold colour, thick ink
## outlines, hard drop shadows, cream lettering with an ink outline in a chunky rounded font.
## Autoload "UiFonts" installs the fonts before any scene draws; everything else calls the static
## helpers below (hud.gd, minigame.gd, touch_controls.gd).
##   display = Baloo 2 ExtraBold (headers, buttons, titles; closest to the cards' lettering)
##   body    = Nunito ExtraBold (dialogue, menus; becomes ThemeDB.fallback_font, so every
##             draw_string that used the engine font picks it up)
## Fonts are OFL (assets/fonts/OFL-*.txt).

const INK: = Color("#1e1220")
const CREAM: = Color("#fff1d6")
const PANEL: = Color("#2a1e36")
const GOLD: = Color("#f2b63c")
const PINK: = Color("#ff6f91")
const TEAL: = Color("#2fb3a8")

static var display: Font
static var body: Font

static func install() -> void:
	if body != null:
		return
	body = load("res://assets/fonts/Nunito-ExtraBold.ttf")
	display = load("res://assets/fonts/Baloo2-ExtraBold.ttf")
	ThemeDB.fallback_font = body

func _enter_tree() -> void:
	install()

## Comic panel: hard ink drop shadow, flat fill, faint cream inner line, thick ink border.
## `w` = border width in the caller's units.
static func panel(ci: CanvasItem, r: Rect2, fill: Color = PANEL, alpha: float = 0.94, w: float = 1.0) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(w * 1.6, w * 1.6), r.size), Color(INK, 0.6 * alpha))
	ci.draw_rect(r, Color(fill, alpha * fill.a))
	ci.draw_rect(r.grow(-w * 1.6), Color(CREAM, 0.16 * alpha), false, w * 0.5)
	ci.draw_rect(r, Color(INK, alpha), false, w * 1.4)

## Cream lettering with an ink outline, in the display font.
static func label(ci: CanvasItem, pos: Vector2, text: String, size: int, col: Color = CREAM, width: float = -1.0,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, outline: int = 3) -> void:
	install()
	ci.draw_string_outline(display, pos, text, align, width, size, outline, Color(INK, col.a))
	ci.draw_string(display, pos, text, align, width, size, col)

## Chunky button: saturated fill, light top band, thick ink border, hard shadow that the button
## sinks into when pressed.
static func button(ci: CanvasItem, r: Rect2, text: String, col: Color, enabled: bool = true, pressed: bool = false,
		w: float = 1.0, size: int = 8) -> void:
	var c: = col
	if c.s < 0.25:
		c = TEAL.darkened(0.15)          # the old grey default button colour -> the cards' teal
	if not enabled:
		c = c.darkened(0.55)
	var sink: = w * 1.6 if pressed else 0.0
	var rr: = Rect2(r.position + Vector2(sink, sink), r.size)
	if not pressed:
		ci.draw_rect(Rect2(r.position + Vector2(w * 1.6, w * 1.6), r.size), Color(INK, 0.85))
	ci.draw_rect(rr, c)
	ci.draw_rect(Rect2(rr.position, Vector2(rr.size.x, rr.size.y * 0.38)), c.lightened(0.14))
	ci.draw_rect(rr, INK, false, w * 1.4)
	var fit: = fit_text(text, rr.size.x - BUTTON_PAD, rr.size.y - 1.0, size)
	var lines: PackedStringArray = fit[0]
	var sz: int = fit[1]
	var y0: = rr.position.y + rr.size.y * 0.5 + sz * 0.36 - (lines.size() - 1) * sz * 0.55
	for i in lines.size():
		label(ci, Vector2(rr.position.x, y0 + i * sz * LINE_H), lines[i], sz, CREAM if enabled else Color(CREAM, 0.45),
			rr.size.x, HORIZONTAL_ALIGNMENT_CENTER)

const BUTTON_PAD: = 16.0      # both side margins inside a button together (the key hint sits in the left 6)
const LINE_H: = 1.1           # button line spacing, x font size
const MIN_SIZE: = 6

## Text fitting for button labels (same idea as tools/text_fit.gd: measure with the real font).
## Keeps `size` if every line fits `width`; else word-wraps into as many lines as `height` holds;
## else steps the size down to MIN_SIZE; last resort cuts the final line with "...".
## Returns [PackedStringArray lines, int size]. Explicit "\n" breaks are kept.
static func fit_text(text: String, width: float, height: float, size: int) -> Array:
	install()
	for sz in range(size, MIN_SIZE - 1, -1):
		var max_lines: = maxi(1, int(floor((height + sz * (LINE_H - 1.0)) / (sz * LINE_H))))
		var out: = PackedStringArray()
		for para in text.split("\n"):
			out.append_array(wrap_words(para, width, sz))
		if out.size() <= max_lines and _widest(out, sz) <= width:
			return [out, sz]
	var lines: = PackedStringArray()
	for para in text.split("\n"):
		lines.append_array(wrap_words(para, width, MIN_SIZE))
	var keep: = maxi(1, int(floor((height + MIN_SIZE * (LINE_H - 1.0)) / (MIN_SIZE * LINE_H))))
	if lines.size() > keep:
		lines = lines.slice(0, keep)
		lines[keep - 1] = lines[keep - 1] + "..."
	for i in lines.size():
		while lines[i].length() > 4 and _w(lines[i], MIN_SIZE) > width:
			lines[i] = lines[i].substr(0, lines[i].length() - 4) + "..."
	return [lines, MIN_SIZE]

## Greedy word wrap with the display font (a single word wider than `width` stays on its own line).
static func wrap_words(para: String, width: float, size: int) -> PackedStringArray:
	var out: = PackedStringArray()
	var cur: = ""
	for wd in para.split(" ", false):
		var t: = wd if cur == "" else cur + " " + wd
		if cur != "" and _w(t, size) > width:
			out.append(cur)
			cur = wd
		else:
			cur = t
	out.append(cur)
	return out

static func _w(s: String, size: int) -> float:
	return display.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

static func _widest(lines: PackedStringArray, size: int) -> float:
	var m: = 0.0
	for l in lines:
		m = maxf(m, _w(l, size))
	return m

## Style-lock "prop" (STYLE_LOCK.md L1/L2): a play object in a minigame (oil vat, cutting board, plate,
## tile, skin patch) drawn like the HD art: hard ink drop shadow, flat fill, ONE hard cel-shadow band on
## the lower part, thick near-black ink outline. `w` = outline width in the caller's units.
const PROP_INK: = Color("#14121a")

static func prop(ci: CanvasItem, r: Rect2, fill: Color, w: float = 1.0, shade: float = 0.3) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(w * 1.5, w * 1.5), r.size), Color(PROP_INK, 0.55 * fill.a))
	ci.draw_rect(r, fill)
	if shade > 0.0 and r.size.y > 4.0:
		var sh: = r.size.y * shade
		ci.draw_rect(Rect2(r.position.x, r.end.y - sh, r.size.x, sh), Color(fill.darkened(0.22), fill.a))
	ci.draw_rect(r, Color(PROP_INK, fill.a), false, w * 1.3)

static func prop_circle(ci: CanvasItem, c: Vector2, rad: float, fill: Color, w: float = 1.0) -> void:
	ci.draw_circle(c + Vector2(w * 1.5, w * 1.5), rad, Color(PROP_INK, 0.55 * fill.a))
	ci.draw_circle(c, rad, fill)
	# one hard shadow crescent (lower right), no gradient
	ci.draw_circle(c + Vector2(rad * 0.18, rad * 0.18), rad * 0.82, Color(fill.darkened(0.2), fill.a))
	ci.draw_circle(c - Vector2(rad * 0.06, rad * 0.06), rad * 0.8, fill)
	ci.draw_arc(c, rad, 0, TAU, maxi(16, int(rad * 2.0)), Color(PROP_INK, fill.a), w * 1.3)

## Answer card (quiz / inspector calls): a cream index card with a hard shadow and thick ink border,
## a coloured badge tab on the left holding the key letter, ink lettering. `col` tints the result:
## low saturation = neutral cream card; anything saturated (green right / red wrong) floods the card.
static func card_button(ci: CanvasItem, r: Rect2, text: String, badge: String, badge_col: Color, col: Color,
		enabled: bool = true, pressed: bool = false, w: float = 1.0, size: int = 8) -> void:
	var neutral: = col.s < 0.25
	var fill: = CREAM if neutral else col.lightened(0.1)
	var ink_text: = INK if neutral else CREAM
	if not enabled:
		fill = fill.darkened(0.45)
	var sink: = w * 1.6 if pressed else 0.0
	var rr: = Rect2(r.position + Vector2(sink, sink), r.size)
	if not pressed:
		ci.draw_rect(Rect2(r.position + Vector2(w * 2.0, w * 2.0), r.size), Color(INK, 0.85))
	ci.draw_rect(rr, fill)
	# one hard cel band along the bottom, like the props
	ci.draw_rect(Rect2(rr.position.x, rr.end.y - rr.size.y * 0.22, rr.size.x, rr.size.y * 0.22), fill.darkened(0.1))
	if neutral:   # faint ruled lines: it's an index card
		var y: = rr.position.y + 9.0 * w
		while y < rr.end.y - 4.0 * w:
			ci.draw_line(Vector2(rr.position.x + 3 * w, y), Vector2(rr.end.x - 3 * w, y), Color(TEAL, 0.18), w * 0.6)
			y += 8.0 * w
	var bw: = minf(rr.size.y * 0.7, 15.0)
	var badge_r: = Rect2(rr.position + Vector2(3 * w, (rr.size.y - bw) * 0.5), Vector2(bw, bw))
	ci.draw_rect(Rect2(badge_r.position + Vector2(w, w), badge_r.size), Color(INK, 0.7))
	ci.draw_rect(badge_r, badge_col)
	ci.draw_rect(badge_r, INK, false, w * 1.1)
	label(ci, Vector2(badge_r.position.x, badge_r.end.y - bw * 0.24), badge, int(bw * (0.8 if badge.length() < 2 else 0.58)), CREAM, bw,
		HORIZONTAL_ALIGNMENT_CENTER, 2)
	ci.draw_rect(rr, INK, false, w * 1.4)
	var tx: = badge_r.end.x + 3 * w
	var tw: = rr.end.x - tx - 3 * w
	var fit: = fit_text(text, tw, rr.size.y - 2.0, size)
	var lines: PackedStringArray = fit[0]
	var sz: int = fit[1]
	var y0: = rr.position.y + rr.size.y * 0.5 + sz * 0.36 - (lines.size() - 1) * sz * 0.55
	for i in lines.size():
		var p: = Vector2(tx, y0 + i * sz * LINE_H)
		if neutral:
			ci.draw_string(display, p, lines[i], HORIZONTAL_ALIGNMENT_CENTER, tw, sz, ink_text)
		else:
			label(ci, p, lines[i], sz, ink_text, tw, HORIZONTAL_ALIGNMENT_CENTER, 2)

## Round touch button: ink ring, flat fill, display-font letter.
static func round_button(ci: CanvasItem, c: Vector2, r: float, col: Color, text: String, alpha: float = 0.85) -> void:
	ci.draw_circle(c + Vector2(1.0, 1.0), r, Color(INK, 0.55 * alpha))
	ci.draw_circle(c, r, Color(col, alpha))
	ci.draw_circle(c - Vector2(0, r * 0.25), r * 0.62, Color(col.lightened(0.18), alpha * 0.6))
	ci.draw_arc(c, r, 0, TAU, 32, Color(INK, alpha), 1.2)
	label(ci, c + Vector2(0, r * 0.32), text, int(r * 1.0), Color(CREAM, alpha), -1.0, HORIZONTAL_ALIGNMENT_LEFT, 2)

## The cards' sunburst: alternating light/dark rays from `center` filling `r`.
static func burst(ci: CanvasItem, r: Rect2, base: Color, center: Vector2, rays: int = 28, spin: float = 0.0) -> void:
	ci.draw_rect(r, base.darkened(0.18))
	var rad: = r.size.length() * 1.2
	var light: = base.lightened(0.06)
	for i in rays:
		if i % 2 == 1:
			continue
		var a0: = spin + TAU * float(i) / rays
		var a1: = spin + TAU * float(i + 1) / rays
		ci.draw_colored_polygon(PackedVector2Array([center, center + Vector2.from_angle(a0) * rad,
			center + Vector2.from_angle(a1) * rad]), light)
