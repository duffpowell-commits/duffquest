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
## Button palette (Nov 15, Duff: "two colours"): one main, one secondary, red only for leaving.
const BTN_MAIN: = Color("#27998f")      # do the thing
const BTN_ALT: = Color("#5b4a72")       # everything else (options, toggles, steps)
const BTN_EXIT: = Color("#b8432f")      # back / close / leave / done / stop
const BTN_EXIT_WORDS: = ["back", "close", "leave", "done", "stop", "quit", "cancel", "give up", "nope", "exit"]

## Collapse a caller's colour into the three roles. Low-saturation (the old grey default) = ALT,
## a leaving label = EXIT, any other colour = MAIN.
static func btn_role(col: Color, text: String) -> Color:
	var t: = text.strip_edges().to_lower()
	for w in BTN_EXIT_WORDS:
		if t == w or t.begins_with(w + " ") or t.begins_with(w + "!") or t.begins_with(w + ":") or t.begins_with(w + "("):
			return BTN_EXIT
	if col.is_equal_approx(BTN_ALT) or col.s < 0.25:
		return BTN_ALT
	return BTN_MAIN

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

## Rounded box in the caller's units: StyleBoxFlat, cached per colour/radius (menus redraw every frame).
static var _boxes: = {}
static func box(ci: CanvasItem, r: Rect2, fill: Color, rad: float) -> void:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	var ri: = clampi(roundi(rad), 0, int(minf(r.size.x, r.size.y) * 0.5))
	var k: = "%s|%d" % [fill.to_html(true), ri]
	var sb: StyleBoxFlat = _boxes.get(k)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = fill
		sb.set_corner_radius_all(ri)
		sb.anti_aliasing = true
		sb.anti_aliasing_size = 0.5
		_boxes[k] = sb
	ci.draw_style_box(sb, r)

## Corner radius for a box of height `h`, in the caller's units (w = line width unit).
static func _rad(h: float, w: float) -> float:
	return minf(3.0 * w * 1.5, h * 0.3)

## Comic panel: rounded, hard ink drop shadow, flat fill with a lighter top band, gold hairline
## inside, thick ink border. `w` = border width in the caller's units.
static func panel(ci: CanvasItem, r: Rect2, fill: Color = PANEL, alpha: float = 0.94, w: float = 1.0) -> void:
	var rad: = _rad(r.size.y, w) + w * 0.6
	var bw: = w * 1.4
	box(ci, Rect2(r.position + Vector2(w * 1.6, w * 1.6), r.size).grow(bw * 0.5), Color(INK, 0.6 * alpha), rad + bw * 0.5)
	box(ci, r.grow(bw * 0.5), Color(INK, alpha), rad + bw * 0.5)
	var inner: = r.grow(-bw * 0.5)
	box(ci, inner, Color(fill, alpha * fill.a), rad - bw * 0.5)
	box(ci, Rect2(inner.position, Vector2(inner.size.x, minf(inner.size.y * 0.5, 9.0 * w * 1.5))),
		Color(fill.lightened(0.07), alpha * fill.a * 0.6), rad - bw * 0.5)
	# gold hairline: four thin rounded strips just inside the border
	var g: = inner.grow(-w * 1.4)
	var gc: = Color(GOLD, 0.32 * alpha)
	var t: = maxf(w * 0.5, 0.35)
	ci.draw_rect(Rect2(g.position.x + rad * 0.6, g.position.y, g.size.x - rad * 1.2, t), gc)
	ci.draw_rect(Rect2(g.position.x + rad * 0.6, g.end.y - t, g.size.x - rad * 1.2, t), gc)
	ci.draw_rect(Rect2(g.position.x, g.position.y + rad * 0.6, t, g.size.y - rad * 1.2), gc)
	ci.draw_rect(Rect2(g.end.x - t, g.position.y + rad * 0.6, t, g.size.y - rad * 1.2), gc)

## Side-quest marker over an NPC: "!" (gold, has a quest for you) or "?" (teal, your quest wants you here).
## Ink-bordered badge with a hard shadow and a little tail, in world pixels. `p` = the tail's tip.
static func quest_marker(ci: CanvasItem, p: Vector2, mark: String) -> void:
	install()
	var col: = GOLD if mark == "!" else TEAL
	var r: = Rect2(p + Vector2(-4.5, -13.0), Vector2(9.0, 10.0))
	ci.draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color(INK, 0.6))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-2.5, -3.5), p + Vector2(2.5, -3.5), p]), INK)
	ci.draw_rect(r, INK)
	ci.draw_rect(r.grow(-1.0), col)
	ci.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2.0, 3.0)), col.lightened(0.25))
	ci.draw_string_outline(display, Vector2(r.position.x, r.end.y - 1.6), mark, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, 2, INK)
	ci.draw_string(display, Vector2(r.position.x, r.end.y - 1.6), mark, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, CREAM)

## Cream lettering with an ink outline, in the display font.
static func label(ci: CanvasItem, pos: Vector2, text: String, size: int, col: Color = CREAM, width: float = -1.0,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, outline: int = 3) -> void:
	install()
	ci.draw_string_outline(display, pos, text, align, width, size, outline, Color(INK, col.a))
	ci.draw_string(display, pos, text, align, width, size, col)

## Name tag: text on a dark ink plate with a thin border, so it reads on any painted backdrop.
## `pos` is the text baseline, laid out like draw_string (align within `width`). `w` = line width
## in the caller's units (1/1.5 in the overworld, 1.0 in minigames). Returns the plate rect.
static func tag(ci: CanvasItem, pos: Vector2, text: String, size: int, col: Color = CREAM, width: float = -1.0,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, w: float = 1.0, font: Font = null) -> Rect2:
	install()
	var f: = font if font else body
	var tw: = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var x: = pos.x
	if width > 0.0 and align == HORIZONTAL_ALIGNMENT_CENTER:
		x = pos.x + (width - tw) * 0.5
	elif width > 0.0 and align == HORIZONTAL_ALIGNMENT_RIGHT:
		x = pos.x + width - tw
	var padx: = maxf(2.0, size * 0.35)
	var r: = Rect2(x - padx, pos.y - size * 0.86, tw + padx * 2.0, size * 1.2)
	ci.draw_rect(Rect2(r.position + Vector2(w, w), r.size), Color(INK, 0.45 * col.a))
	ci.draw_rect(r, Color(INK, 0.82 * col.a))
	ci.draw_rect(r, Color(CREAM, 0.28 * col.a), false, w * 0.75)
	ci.draw_string(f, Vector2(x, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	return r

## Chunky button: rounded, saturated fill, glossy top band, a darker lip along the bottom (it's a
## key cap), thick ink border, hard shadow that the button sinks into when pressed.
static func button(ci: CanvasItem, r: Rect2, text: String, col: Color, enabled: bool = true, pressed: bool = false,
		w: float = 1.0, size: int = 8) -> void:
	var c: = btn_role(col, text)
	if not enabled:
		c = c.darkened(0.55).lerp(Color(0.3, 0.28, 0.33), 0.4)
	var sink: = w * 1.6 if pressed else 0.0
	var rr: = Rect2(r.position + Vector2(sink, sink), r.size)
	var rad: = _rad(r.size.y, w)
	var bw: = w * 1.4
	if not pressed:
		box(ci, Rect2(r.position + Vector2(w * 1.6, w * 1.6), r.size).grow(bw * 0.5), Color(INK, 0.85), rad + bw * 0.5)
	box(ci, rr.grow(bw * 0.5), INK, rad + bw * 0.5)
	var lip: = minf(rr.size.y * 0.16, 3.0 * w * 1.5) * (0.4 if pressed else 1.0)
	var inner: = rr.grow(-bw * 0.5)
	box(ci, inner, c.darkened(0.3), rad - bw * 0.5)
	box(ci, Rect2(inner.position, Vector2(inner.size.x, inner.size.y - lip)), c, rad - bw * 0.5)
	if enabled:   # gloss: a lighter band on the top half, and a thin shine line under the border
		box(ci, Rect2(inner.position + Vector2(w, w * 0.6), Vector2(inner.size.x - 2.0 * w, (inner.size.y - lip) * 0.42)),
			Color(c.lightened(0.22), 0.75), maxf(rad - bw, 0.0))
		ci.draw_rect(Rect2(inner.position.x + rad, inner.position.y + w * 0.7, inner.size.x - rad * 2.0, maxf(w * 0.55, 0.35)),
			Color(1, 1, 1, 0.35))
	var fit: = fit_text(text, rr.size.x - BUTTON_PAD, rr.size.y - 1.0 - lip, size)
	var lines: PackedStringArray = fit[0]
	var sz: int = fit[1]
	var y0: = rr.position.y + (rr.size.y - lip) * 0.5 + sz * 0.36 - (lines.size() - 1) * sz * 0.55
	for i in lines.size():
		label(ci, Vector2(rr.position.x, y0 + i * sz * LINE_H), lines[i], sz, CREAM if enabled else Color(CREAM, 0.45),
			rr.size.x, HORIZONTAL_ALIGNMENT_CENTER)

## Phone-style pill button (Nov 17, menu sheets + phone apps): fully rounded, flat role colour, soft top
## sheen, a hairline darker rim, white text. Same roles as button() (btn_role).
static func pill_button(ci: CanvasItem, r: Rect2, text: String, col: Color, enabled: bool = true, pressed: bool = false,
		w: float = 1.0, size: int = 8) -> void:
	var c: = btn_role(col, text)
	if not enabled:
		c = c.darkened(0.5).lerp(Color(0.3, 0.28, 0.33), 0.45)
	var rr: = r.grow(-w * 0.4 if pressed else 0.0)
	var rad: = minf(rr.size.y * 0.5, 9.0 * w * 1.5)
	box(ci, Rect2(rr.position + Vector2(0, w * 1.2), rr.size), Color(0, 0, 0, 0.35), rad)
	box(ci, rr, c.darkened(0.35), rad)
	box(ci, rr.grow(-w * 0.6), c.darkened(0.08) if pressed else c, maxf(rad - w * 0.6, 0.0))
	if enabled:
		box(ci, Rect2(rr.position + Vector2(w * 1.2, w * 0.9), Vector2(rr.size.x - w * 2.4, rr.size.y * 0.42)),
			Color(1, 1, 1, 0.16), maxf(rad - w * 1.2, 0.0))
	var fit: = fit_text(text, rr.size.x - BUTTON_PAD, rr.size.y - 1.0, size)
	var lines: PackedStringArray = fit[0]
	var sz: int = fit[1]
	var y0: = rr.position.y + rr.size.y * 0.5 + sz * 0.36 - (lines.size() - 1) * sz * 0.55
	for i in lines.size():
		var tc: = Color.WHITE if enabled else Color(1, 1, 1, 0.45)
		ci.draw_string(display, Vector2(rr.position.x, y0 + i * sz * LINE_H + w * 0.6), lines[i], HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, sz, Color(0, 0, 0, 0.35 * tc.a))
		ci.draw_string(display, Vector2(rr.position.x, y0 + i * sz * LINE_H), lines[i], HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, sz, tc)

## Branding-specific menu controls. Keep the gameplay HUD and role palette unchanged.
static func brand_button(ci: CanvasItem, r: Rect2, text: String, primary: bool, enabled: bool, pressed: bool) -> void:
	var rim := Color("#bd9255") if primary else Color("#856c49")
	var fill := Color("#493827") if primary else Color("#292421")
	if pressed:
		fill = fill.lightened(0.19)
	if not enabled:
		rim = rim.darkened(0.5)
		fill = fill.darkened(0.3)
	box(ci, Rect2(r.position + Vector2(0, 1.2), r.size), Color(0, 0, 0, 0.6), 3)
	box(ci, r, rim, 3)
	box(ci, r.grow(-0.75), fill, 2)
	var fit := fit_text(text, r.size.x - 12, r.size.y - 2, 8)
	var ls: PackedStringArray = fit[0]
	var sz: int = fit[1]
	var y := r.get_center().y + sz * 0.36 - (ls.size() - 1) * sz * 0.55
	for i in ls.size():
		ci.draw_string(display, Vector2(r.position.x, y + i * sz * LINE_H), ls[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, sz, CREAM if enabled else Color(CREAM, 0.55))

## Phone glass sheet (menu cards, phone apps): soft shadow, black bezel, dark glass, faint top sheen.
const GLASS: = Color("#17141f")
static func glass(ci: CanvasItem, r: Rect2, rad: float, a: float = 0.92, w: float = 1.0) -> void:
	box(ci, Rect2(r.position + Vector2(0, w * 1.5), r.size).grow(w), Color(0, 0, 0, 0.35 * a), rad + w)
	box(ci, r.grow(w), Color("#07060a", a), rad + w)
	box(ci, r, Color(GLASS, a), rad)
	box(ci, Rect2(r.position, Vector2(r.size.x, minf(r.size.y * 0.45, 30.0 * w))).grow(-w * 0.5), Color(1, 1, 1, 0.045 * a), maxf(rad - w * 0.5, 0.0))

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
		enabled: bool = true, pressed: bool = false, w: float = 1.0, size: int = 8, icon: Texture2D = null, stack: bool = false) -> void:
	var neutral: = col.s < 0.25
	var fill: = CREAM if neutral else col.lightened(0.1)
	var ink_text: = INK if neutral else CREAM
	if not enabled:
		fill = fill.darkened(0.45)
	var sink: = w * 1.6 if pressed else 0.0
	var rr: = Rect2(r.position + Vector2(sink, sink), r.size)
	var rad: = _rad(r.size.y, w)
	var lw: = w * 1.4
	if not pressed:
		box(ci, Rect2(r.position + Vector2(w * 2.0, w * 2.0), r.size).grow(lw * 0.5), Color(INK, 0.85), rad + lw * 0.5)
	box(ci, rr.grow(lw * 0.5), INK, rad + lw * 0.5)
	box(ci, rr.grow(-lw * 0.5), fill.darkened(0.1), rad - lw * 0.5)
	# one hard cel band along the bottom, like the props
	box(ci, Rect2(rr.position, Vector2(rr.size.x, rr.size.y * 0.78)).grow(-lw * 0.5), fill, rad - lw * 0.5)
	if neutral:   # faint ruled lines: it's an index card
		var y: = rr.position.y + 9.0 * w
		while y < rr.end.y - 4.0 * w:
			ci.draw_line(Vector2(rr.position.x + 3 * w, y), Vector2(rr.end.x - 3 * w, y), Color(TEAL, 0.18), w * 0.6)
			y += 8.0 * w
	var bw: = minf(rr.size.y * 0.7, 15.0)
	var badge_r: = Rect2(rr.position + Vector2(3 * w, (rr.size.y - bw) * 0.5), Vector2(bw, bw))
	if icon != null:   # picture tile: the house-style prop sits where the badge would, a touch bigger
		var ih: = rr.size.y - 2.0
		var iw: = ih * icon.get_width() / float(icon.get_height())
		if iw > ih * 1.15:
			iw = ih * 1.15
			ih = iw * icon.get_height() / float(icon.get_width())
		# Nov 18: narrower tiles (wider gaps between them) shrink the picture a little before the name gets cut.
		var need: = 0.0
		for word in text.split(" "):
			need = maxf(need, _w(word, MIN_SIZE))
		var room: = rr.size.x - (2 * w + iw + 3 * w) - 3 * w
		if need > room and not stack and need - room <= iw * 0.28:   # only when that makes the name fit
			var new_iw: = iw - (need - room)
			ih *= new_iw / iw
			iw = new_iw
		badge_r = Rect2(rr.position + Vector2(2 * w, (rr.size.y - ih) * 0.5), Vector2(iw, ih))
		ci.draw_texture_rect(icon, badge_r, false, Color.WHITE if enabled else Color(0.55, 0.55, 0.55))
	else:
		ci.draw_rect(Rect2(badge_r.position + Vector2(w, w), badge_r.size), Color(INK, 0.7))
		ci.draw_rect(badge_r, badge_col)
		ci.draw_rect(badge_r, INK, false, w * 1.1)
		label(ci, Vector2(badge_r.position.x, badge_r.end.y - bw * 0.24), badge, int(bw * (0.8 if badge.length() < 2 else 0.58)), CREAM, bw,
			HORIZONTAL_ALIGNMENT_CENTER, 2)
	var tx: = badge_r.end.x + 3 * w
	var tw: = rr.end.x - tx - 3 * w
	if icon != null and (tw < 17.0 or stack):   # narrow (or app-style) picture tile: icon on top, name underneath
		var ih2: = rr.size.y - 9.0
		var iw2: = minf(ih2 * icon.get_width() / float(icon.get_height()), rr.size.x - 6.0)
		ih2 = iw2 * icon.get_height() / float(icon.get_width())
		# repaint the card body over the side-placed icon, then the stacked layout
		box(ci, rr.grow(-lw * 0.5), fill, rad - lw * 0.5)
		ci.draw_texture_rect(icon, Rect2(rr.position.x + (rr.size.x - iw2) * 0.5, rr.position.y + 1.0, iw2, ih2), false,
			Color.WHITE if enabled else Color(0.55, 0.55, 0.55))
		var small: = fit_text(text, rr.size.x - 4.0, 7.0, 6)
		var ln: PackedStringArray = small[0]
		ci.draw_string(display, Vector2(rr.position.x + 2, rr.end.y - 2.0), ln[0] if ln.size() > 0 else text,
			HORIZONTAL_ALIGNMENT_CENTER, rr.size.x - 4.0, int(small[1]), ink_text)
		return
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
