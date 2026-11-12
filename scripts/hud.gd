extends Node2D
const UiStyle: = preload("res://scripts/ui_style.gd")
const Buffs: = preload("res://scripts/buffs.gd")

const SHORT: = {"honey buns": "buns", "formula": "formula", "diapers": "diapers", "cherries": "cherries", "chocolate": "choc", "cream": "cream", "flour": "flour", "eggs": "eggs", "treats": "treats", "ensure": "Ensure", "cake": "CAKE", "rolecks": "Rolecks", "meds": "Rx bag", "package": "her package", "cologne": "cologne" }

const Cast: = preload("res://scripts/cast.gd")
const Market: = preload("res://scripts/market.gd")
const Art: = preload("res://scripts/art.gd")
const Errands: = preload("res://scripts/errands.gd")

var m: Node

const PX: = 1.0 / 1.5
const INK: = Color(0.07, 0.05, 0.04)
const PANEL: = Color(0.11, 0.09, 0.07)
const RIM_LIT: = Color(0.86, 0.75, 0.55)
const RIM_DARK: = Color(0.05, 0.04, 0.03)
const GOLD: = Color("#f2c66a")
const PAPER: = Color("#f0ead8")

## HUD units (320x180, x2 = the 640x360 game). Declutter (Nov 9): ONE top strip (Madison bar,
## Energy bar, $, day + time) + the phone; errand/rent/fund/bag/mood live in a drawer that a tap on
## the strip (or Tab) toggles. A short "peek" line drops out of the strip when one of them changes,
## and a red chip pulses next to the phone while rent or an errand is about to bite.
static func layout() -> Dictionary:
	return {
		"strip": Rect2(2, 2, 186, 13), "phone": Rect2(190, 1, 10, 16), "chip": Rect2(203, 4, 38, 9),
		"drawer": Rect2(2, 17, 186, 60), "peek": Rect2(2, 17, 186, 12), "buffs": Rect2(2, 17, 60, 10),
		"toast": Rect2(10, 50, 300, 36), "hint": Rect2(0, 108, 320, 12), "dialog": Rect2(64, 108, 192, 66),
		"dialog_portrait": Rect2(64, 108, 192, 66), "boss": Rect2(66, 154, 188, 22), "timer": Rect2(234, 2, 84, 12),
		"saved": Rect2(286, 168, 32, 10),
	}

## Drawer + peek state.
var drawer_open: = false
var peek_text: = ""
var peek_col: = Color.WHITE
var peek_t: = 0.0
const PEEK_TIME: = 3.5
var _seen: = {}                  # last values the peek compares against ("" = not primed yet)
var _pulse: = 0.0

func toggle_drawer() -> void:
	drawer_open = not drawer_open
	peek_t = 0.0

func _peek(s: String, col: Color) -> void:
	peek_text = s
	peek_col = col
	peek_t = PEEK_TIME

## What the drawer hides that's urgent right now: "" / "errand" / "rent".
func urgent() -> String:
	if m.location in ["gala", "arena"]:
		return ""
	var e: Dictionary = m.errand
	if Errands.pending(e) and int(e["day"]) == int(m.day_count) and float(e["due"]) - fmod(float(m.clock), 1440.0) <= 90.0:
		return "errand"
	if int(m.days_until_rent()) <= 1 and int(m.money) < int(m.rent_due()):
		return "rent"
	return ""

func rent_text() -> String:
	return "Rent $%d due Mon (%dd)" % [m.rent_due(), m.days_until_rent()]

func fund_text() -> String:
	var fv: float = m.fund_value()
	var lbl: = ("$%.1fk" % (fv / 1000.0)) if fv >= 1000.0 else ("$%d" % int(fv))
	return Cast.T("{baby}'s college fund: ") + lbl   # no "/ 100k": the goal gates nothing since Nov 9

## Peek when something behind the drawer changes. First call only primes the values.
func _watch() -> void:
	if m.in_title or not visible:
		return
	var now: = {"quest": Cast.T(m.quest_text()), "bag": bag_text(), "fund": int(m.fund_value() / 100.0),
		"rent": int(m.rent_due()), "urgent": urgent() + str(m.day_count)}
	if _seen.is_empty():
		_seen = now
		return
	var msg: = ""
	var col: = GOLD
	if now["urgent"] != _seen["urgent"] and urgent() != "":
		msg = (Cast.T(m.quest_text()) if urgent() == "errand" else rent_text() + "  -  short $%d" % (int(m.rent_due()) - int(m.money)))
		col = Color("#ff8a6a")
	elif now["quest"] != _seen["quest"]:
		msg = str(now["quest"])
	elif now["bag"] != _seen["bag"] and str(now["bag"]) != "":
		msg = "Bag: " + str(now["bag"])
		col = PAPER
	elif now["rent"] != _seen["rent"]:
		msg = rent_text()
		col = PAPER
	elif now["fund"] != _seen["fund"] and int(now["fund"]) > 0:
		msg = fund_text()
		col = Color("#c8b0e8")
	_seen = now
	if msg != "" and not drawer_open:
		_peek(msg, col)

func _process(d: float) -> void:
	_pulse += d
	peek_t = maxf(0.0, peek_t - d)
	if m != null:
		_watch()
	queue_redraw()

func _panel(r: Rect2, a: float = 0.82) -> void:
	UiStyle.panel(self, r, UiStyle.PANEL, minf(1.0, a + 0.1), PX)

func _bar(pos: Vector2, w: float, frac: float, col: Color) -> void:
	var h: = 4.0
	var f: = clampf(frac, 0, 1)
	draw_rect(Rect2(pos, Vector2(w, h)), Color(UiStyle.INK, 0.85))
	draw_rect(Rect2(pos, Vector2(w * f, h)), col)
	draw_rect(Rect2(pos, Vector2(w * f, h * 0.4)), col.lightened(0.3))
	draw_rect(Rect2(pos, Vector2(w, h)), UiStyle.INK, false, PX * 1.2)

func _t(f: Font, p: Vector2, s: String, size: int, col: Color, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(f, p + Vector2(PX, PX), s, align as HorizontalAlignment, width, size, Color(INK.r, INK.g, INK.b, 0.8 * col.a))
	draw_string(f, p, s, align as HorizontalAlignment, width, size, col)

## Typewriter: wrap the WHOLE line first (spaces become newlines, same length), then cut it at the
## revealed count, so words never jump to the next row mid-reveal.
static func wrap_words(f: Font, s: String, width: float, size: int) -> String:
	var out: = s
	var row_start: = 0
	var last_space: = -1
	var i: = 0
	while i < out.length():
		var ch: = out[i]
		if ch == "\n":
			row_start = i + 1
			last_space = -1
		elif ch == " ":
			last_space = i
		if f.get_string_size(out.substr(row_start, i - row_start + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and last_space > row_start:
			out[last_space] = "\n"
			row_start = last_space + 1
			last_space = -1
		i += 1
	return out

func typed(f: Font, line: String, width: float, size: int) -> String:
	var n: = int(m.dlg_chars)
	var wrapped: = wrap_words(f, line, width, size)
	return wrapped if n >= wrapped.length() else wrapped.substr(0, n)

func _mt(f: Font, p: Vector2, s: String, width: float, size: int, lines: int, col: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_multiline_string(f, p + Vector2(PX, PX), s, align as HorizontalAlignment, width, size, lines, Color(INK.r, INK.g, INK.b, 0.8 * col.a))
	draw_multiline_string(f, p, s, align as HorizontalAlignment, width, size, lines, col)

func bag_text() -> String:
	var parts: Array = []
	if int(m.gear["scraps"]) > 0:
		parts.append("scrap %d" % int(m.gear["scraps"]))
	for k in m.inventory:
		var n: = int(m.inventory[k])
		if n > 0:
			parts.append("%s%s" % [SHORT.get(k, k), (" x%d" % n) if n > 1 else ""])
	for lo in m.leftovers:
		parts.append("leftover " + ("cake" if lo == "cake slice" else "buns"))
	return ", ".join(parts)

func _draw() -> void:
	var f: = ThemeDB.fallback_font
	var w: = PAPER
	var L: = layout()
	_draw_strip(f)
	_draw_phone(f)
	var below: = 17.0
	if drawer_open and m.dialog.is_empty():
		below = _draw_drawer(f) + 2.0
	elif peek_t > 0.0 and m.dialog.is_empty():
		below = _draw_peek(f) + 2.0
	_draw_buffs(f, below)
	if m.location == "gala" or m.location == "arena":
		_draw_boss(f)
	if m.save_flash_t > 0.0:
		var sr: Rect2 = L["saved"]
		_t(f, sr.position + Vector2(0, 8), "saved", 6, Color(1, 1, 1, 0.6))

	if m.toast_t > 0.0:
		var tr: Rect2 = L["toast"]
		var tw: = tr.size.x - 8.0
		var toast: String = Cast.T(m.toast)
		var n: = clampi(int(ceil(f.get_string_size(toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x / (tw - 4.0))), 1, 3)
		var r2: = Rect2(tr.position, Vector2(tr.size.x, 6 + n * 9))
		_panel(r2, 0.92)
		draw_rect(Rect2(r2.position + Vector2(PX, PX), Vector2(r2.size.x - 2 * PX, PX)), Color("#e88aa8"))
		_mt(f, r2.position + Vector2(4, 9), toast, tw, 7, n, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	if m.hint != "" and m.dialog.is_empty():
		# Dark pill behind the prompt so it reads on any floor (the teal rug ate the old pale-green text).
		var hr: Rect2 = L["hint"]
		var ht: String = Cast.T(m.hint)
		var tw: = f.get_string_size(ht, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		var pill: = Rect2(hr.position.x + (hr.size.x - tw) * 0.5 - 5.0, hr.position.y + 1.0, tw + 10.0, 11.0)
		draw_rect(pill, Color(INK, 0.82))
		draw_rect(pill, Color("#f2c14e"), false, PX)
		_t(f, hr.position + Vector2(0, 9), ht, 7, Color("#fff4d6"), hr.size.x, HORIZONTAL_ALIGNMENT_CENTER)

	if not m.dialog.is_empty():
		var line: String = Cast.T(str(m.dialog[0]))
		var who: = Art.portrait_for(line, Cast.T("{hero}"), Cast.T("{partner}"), Cast.T("{baby}"))
		var duff: = who != ""
		var r: Rect2 = L["dialog"]
		_panel(r, 0.95)
		if duff:

			var pr: = Rect2(r.position + Vector2(6, 9), Vector2(48, 48))
			draw_rect(pr, Color("#3e2d19"))
			draw_rect(Rect2(pr.position, Vector2(48, 16)), Color("#5a3f24"))
			var mood: = Art.duff_mood(line, float(m.energy))
			if who == "madison":
				mood = Art.madison_mood(line, float(m.happiness), str(m.mood_kind()))
			elif who == "octavia":
				mood = Art.octavia_mood(line)
			if not Art.hd_enabled:
				Art.family_portrait(self, who, pr.position, mood, bool(m.shades))
			draw_rect(pr, UiStyle.INK, false, PX * 1.4)
			_mt(f, r.position + Vector2(59, 13), typed(f, line, r.size.x - 64, 7), r.size.x - 64, 7, 6, w)
		else:
			_mt(f, r.position + Vector2(7, 13), typed(f, line, r.size.x - 14, 7), r.size.x - 14, 7, 6, w)
		if int(m.dlg_chars) >= line.length():
			UiStyle.label(self, r.position + Vector2(r.size.x - 30, r.size.y - 3), "E / A >", 6, Color(UiStyle.GOLD, 0.9), -1.0, HORIZONTAL_ALIGNMENT_LEFT, 2)

func _draw_phone(f: Font) -> void:
	var k: = 0.75                                   # phone.png is 12x20 HUD units at 1.0
	var o: Vector2 = (layout()["phone"] as Rect2).position + Vector2(0, 0.5)
	var buzz: float = m.ping_t
	if buzz > 0.0:
		o.x += sin(buzz * 60.0) * 1.5
	Art.image(self, "phone", o, Color.WHITE, k)
	if m.location == "gala":
		draw_rect(Rect2(o + Vector2(1, 2) * k, Vector2(10, 14) * k), Color("#333333"))
	if m.phone_cracked:
		draw_line(o + Vector2(2, 3) * k, o + Vector2(9, 14) * k, Color(1, 1, 1, 0.8), 1.0)
		draw_line(o + Vector2(9, 4) * k, o + Vector2(4, 12) * k, Color(1, 1, 1, 0.6), 1.0)
	var n: int = m.unread_count()
	if n > 0:
		draw_circle(o + Vector2(9.5, 1), 3.5, Color("#ff3b30"))
		draw_string(f, o + Vector2(8, 3.5), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.WHITE)

func status_icons() -> Array:

	var out: Array = []
	for k in m.active_buffs():
		var info: Dictionary = Buffs.KINDS[k]
		out.append([str(info["label"]), Color(str(info["color"])), clampf(m.buff_left(k) / 360.0, 0.0, 1.0)])
	if m.glow_active():
		out.append(["LUV", Color("#ff5fa2"), 1.0 if m.glow_day > m.day_count else 0.5])
	if m.drained():
		out.append(["DRN", Color("#7fd0ff"), 1.0])
	return out

func _draw_face(p: Vector2, face: String) -> void:

	if Art.tex("face_" + face) != null:
		Art.image(self, "face_" + face, p)
	else:
		Art.image(self, "face_meh", p)

func _draw_boss(f: Font) -> void:
	var b = m.current_boss()
	if b == null or not is_instance_valid(b):
		return
	var stage: = ("  (%d/%d)" % [int(m.gala_stage) + 1, m.BOSS_ORDER.size()]) if m.location == "gala" else ""
	var br: Rect2 = layout()["boss"]
	var r: = Rect2(br.position + Vector2(4, 13), Vector2(br.size.x - 8, 5))
	_panel(br)
	_t(f, br.position + Vector2(0, 9), "%s%s%s" % [b.display_name(), stage, "  ENRAGED" if b.enraged else ""], 7, GOLD, br.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	draw_rect(r, Color(0.2, 0.05, 0.03))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(b.hp / b.max_hp, 0.0, 1.0), r.size.y)), Color("#c8573a") if not b.enraged else Color("#e6a640"))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(b.hp / b.max_hp, 0.0, 1.0), PX)), Color("#f2c66a"))
	draw_rect(r, Color(1, 0.94, 0.8, 0.6), false, PX)
	if m.location == "arena" and m.arena_id == "willnot" and m.final_timer > 0.0:
		var tl: float = m.final_timer
		var tm: Rect2 = layout()["timer"]
		_panel(tm, 0.8)
		_t(f, tm.position + Vector2(0, 9), "TOWER: %d:%02d" % [int(tl) / 60, int(tl) % 60], 8, Color("#e06a4a") if tl < 30.0 else GOLD, tm.size.x, HORIZONTAL_ALIGNMENT_CENTER)

## The one always-on panel: [heart bar] [bolt bar] [$] [day time] [v]. Tap/Tab opens the drawer.
func _draw_strip(f: Font) -> void:
	var st: Rect2 = layout()["strip"]
	_panel(st)
	var p: = st.position
	Art.image(self, "ic_heart", p + Vector2(2, 2.5), Color.WHITE, 0.85)
	_bar(p + Vector2(11, 4.5), 30, m.happiness / 100.0, Color("#e88aa8"))
	Art.image(self, "ic_bolt", p + Vector2(44, 2.5), Color.WHITE, 0.85)
	_bar(p + Vector2(53, 4.5), 30, m.energy / 100.0, Color("#f2c66a"))
	Art.image(self, "ic_coin", p + Vector2(86, 2.5), Color.WHITE, 0.85)
	_t(f, p + Vector2(95, 9.5), "$%d" % m.money, 7, w_col(), 34)
	var dn: String = m.DAY_NAMES[m.day_i % 7].substr(0, 3)
	_t(f, p + Vector2(124, 9), "D%d %s %s" % [m.day_count, dn, m.clock_text()], 6, PAPER, 54)
	# drawer handle: a little chevron, flipped when open
	var c: = p + Vector2(st.size.x - 5, 6.5)
	var dy: = -1.6 if drawer_open else 1.6
	draw_colored_polygon(PackedVector2Array([c + Vector2(-2.4, -dy), c + Vector2(2.4, -dy), c + Vector2(0, dy)]), Color(GOLD, 0.9))
	var u: = urgent()
	if u != "":
		var cr: Rect2 = layout()["chip"]
		var a: = 0.65 + 0.35 * sin(_pulse * 6.0)
		UiStyle.panel(self, cr, Color("#b8321e"), a, PX)
		var due: = ("ERRAND " + Errands.due_text(m.errand)) if u == "errand" else ("RENT %dd" % m.days_until_rent())
		_t(f, cr.position + Vector2(0, 6.8), due, 5, Color(1, 1, 1, a), cr.size.x, HORIZONTAL_ALIGNMENT_CENTER)

func w_col() -> Color:
	return Color("#e06a4a") if urgent() == "rent" else PAPER

## Lines the drawer shows (text, colour, max lines). Also what the smoke/render tools check.
func drawer_lines() -> Array:
	var out: Array = []
	out.append([Cast.T(m.quest_text()), GOLD, 2])
	var dr: int = m.days_until_rent()
	out.append([rent_text(), Color("#e06a4a") if m.money < m.rent_due() and dr <= 2 else PAPER, 1])
	if m.fund_value() >= 1.0:   # only once there's money in it (IGN review: dead "$0 / 100k" line)
		out.append([fund_text(), Color("#c8b0e8"), 1])
	out.append([Cast.T("{partner}: ") + Cast.T(m.mood_label()), Color("#e88aa8"), 1, "mood"])
	var bag: = bag_text()
	out.append(["Bag: " + (bag if bag != "" else "empty"), PAPER if bag != "" else Color(1, 1, 1, 0.5), 2])
	return out

func _draw_drawer(f: Font) -> float:
	var dr: Rect2 = layout()["drawer"]
	var tw: = dr.size.x - 8.0
	var rows: = drawer_lines()
	var h: = 4.0
	var heights: Array = []
	for r in rows:
		var n: = clampi(int(ceil(f.get_string_size(str(r[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x / (tw - 2.0))), 1, int(r[2]))
		heights.append(n)
		h += n * 8.0 + 1.0
	var box: = Rect2(dr.position, Vector2(dr.size.x, h + 2.0))
	_panel(box, 0.9)
	var y: = box.position.y + 3.0
	for i in rows.size():
		var r: Array = rows[i]
		_mt(f, Vector2(box.position.x + 4, y + 6), str(r[0]), tw, 6, int(heights[i]), r[1])
		y += int(heights[i]) * 8.0 + 1.0
		if r.size() > 3 and r[3] == "mood":
			_draw_face(Vector2(box.position.x + 10 + f.get_string_size(str(r[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x, y - 5), m.mood_face())
	return box.end.y

func _draw_peek(f: Font) -> float:
	var pr: Rect2 = layout()["peek"]
	var a: = clampf(peek_t / 0.4, 0.0, 1.0) * clampf((PEEK_TIME - peek_t) / 0.15, 0.0, 1.0)
	var slide: = (1.0 - clampf((PEEK_TIME - peek_t) / 0.15, 0.0, 1.0)) * -6.0
	var r: = Rect2(pr.position + Vector2(0, slide), pr.size)
	UiStyle.panel(self, r, UiStyle.PANEL, 0.9 * a, PX)
	draw_rect(Rect2(r.position + Vector2(PX, PX), Vector2(2, r.size.y - 2 * PX)), Color(peek_col, a))
	_t(f, r.position + Vector2(6, 8.3), peek_text, 6, Color(peek_col, a), r.size.x - 9)
	return r.end.y

func _draw_buffs(f: Font, y: float) -> void:
	var icons: = status_icons()
	for i in icons.size():
		var ic: Array = icons[i]
		var r: = Rect2(2 + i * 10, y, 9, 9)
		var c: Color = ic[1]
		draw_rect(r, Color(0.07, 0.05, 0.04, 0.7))
		if Art.tex("buff_" + str(ic[0])) != null:
			Art.image(self, "buff_" + str(ic[0]), r.position, Color.WHITE, 9.0 / 11.0)
		else:
			draw_string(f, r.position + Vector2(0, 6), str(ic[0]), HORIZONTAL_ALIGNMENT_CENTER, 9, 4, c)
		draw_rect(r, c, false, PX)
		draw_rect(Rect2(r.position + Vector2(1, 7.6), Vector2(7.0 * float(ic[2]), PX * 2.0)), c)
