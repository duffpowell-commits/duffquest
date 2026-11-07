extends Node2D
const Buffs: = preload("res://scripts/buffs.gd")

const SHORT: = {"honey buns": "buns", "formula": "formula", "diapers": "diapers", "cherries": "cherries", "chocolate": "choc", "cream": "cream", "flour": "flour", "eggs": "eggs", "treats": "treats", "ensure": "Ensure", "cake": "CAKE", "rolecks": "Rolecks", "meds": "Rx bag", "package": "her package", "cologne": "cologne" }

const Cast: = preload("res://scripts/cast.gd")
const Market: = preload("res://scripts/market.gd")
const Art: = preload("res://scripts/art.gd")

var m: Node

func _process(_d: float) -> void:
	queue_redraw()

const PX: = 1.0 / 1.5
const INK: = Color(0.07, 0.05, 0.04)
const PANEL: = Color(0.11, 0.09, 0.07)
const RIM_LIT: = Color(0.86, 0.75, 0.55)
const RIM_DARK: = Color(0.05, 0.04, 0.03)
const GOLD: = Color("#f2c66a")
const PAPER: = Color("#f0ead8")

static func layout() -> Dictionary:
	return {
		"status": Rect2(2, 2, 100, 32), "phone": Rect2(104, 2, 12, 30), "fund": Rect2(118, 2, 60, 20),
		"buffs": Rect2(118, 24, 60, 24), "bag": Rect2(2, 36, 112, 10), "info": Rect2(182, 2, 136, 34),
		"toast": Rect2(10, 50, 300, 36), "hint": Rect2(0, 108, 320, 12), "dialog": Rect2(64, 108, 192, 66),
		"dialog_portrait": Rect2(64, 108, 192, 66), "boss": Rect2(66, 154, 188, 22), "timer": Rect2(222, 38, 96, 12),
		"saved": Rect2(286, 168, 32, 10),
	}

func _panel(r: Rect2, a: float = 0.82) -> void:

	draw_rect(Rect2(r.position + Vector2(PX * 2, PX * 2), r.size), Color(0, 0, 0, 0.25 * a))
	draw_rect(r, Color(PANEL.r, PANEL.g, PANEL.b, a))
	draw_rect(Rect2(r.position, Vector2(r.size.x, PX)), Color(RIM_LIT.r, RIM_LIT.g, RIM_LIT.b, 0.55 * a))
	draw_rect(Rect2(r.position, Vector2(PX, r.size.y)), Color(RIM_LIT.r, RIM_LIT.g, RIM_LIT.b, 0.4 * a))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - PX), Vector2(r.size.x, PX)), Color(RIM_DARK.r, RIM_DARK.g, RIM_DARK.b, a))
	draw_rect(Rect2(r.position + Vector2(r.size.x - PX, 0), Vector2(PX, r.size.y)), Color(RIM_DARK.r, RIM_DARK.g, RIM_DARK.b, a))

func _bar(pos: Vector2, w: float, frac: float, col: Color) -> void:
	var h: = 4.0
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0, 0, 0, 0.65))
	draw_rect(Rect2(pos, Vector2(w * clampf(frac, 0, 1), h)), col)
	draw_rect(Rect2(pos, Vector2(w * clampf(frac, 0, 1), PX)), col.lightened(0.35))
	draw_rect(Rect2(pos + Vector2(0, h - PX), Vector2(w * clampf(frac, 0, 1), PX)), col.darkened(0.35))
	draw_rect(Rect2(pos, Vector2(w, h)), Color(1, 0.94, 0.8, 0.35), false, PX)

func _t(f: Font, p: Vector2, s: String, size: int, col: Color, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(f, p + Vector2(PX, PX), s, align as HorizontalAlignment, width, size, Color(INK.r, INK.g, INK.b, 0.8 * col.a))
	draw_string(f, p, s, align as HorizontalAlignment, width, size, col)

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
	var st: Rect2 = L["status"]
	_panel(st)
	Art.image(self, "ic_heart", st.position + Vector2(2, 2))
	_t(f, st.position + Vector2(13, 8), Cast.T("{partner}"), 6, w, 32)
	_bar(st.position + Vector2(46, 4), 50, m.happiness / 100.0, Color("#e88aa8"))
	Art.image(self, "ic_bolt", st.position + Vector2(2, 12))
	_t(f, st.position + Vector2(13, 18), "Energy", 6, w, 32)
	_bar(st.position + Vector2(46, 14), 50, m.energy / 100.0, Color("#f2c66a"))
	Art.image(self, "ic_coin", st.position + Vector2(2, 22))
	_t(f, st.position + Vector2(13, 29), "$%d   %s" % [m.money, Cast.T(m.mood_label())], 7, w, 74)
	_draw_face(st.position + Vector2(92, 26), m.mood_face())
	_draw_phone(f)
	_draw_fund(f)
	_draw_buffs(f)
	if m.location == "gala" or m.location == "arena":
		_draw_boss(f)
	var bag: = bag_text()
	if bag != "":
		var br: Rect2 = L["bag"]
		_panel(br, 0.72)
		_t(f, br.position + Vector2(3, 7.5), "Bag: " + bag, 6, GOLD, br.size.x - 5)

	var ir: Rect2 = L["info"]
	_panel(ir)
	_mt(f, ir.position + Vector2(4, 8), Cast.T(m.quest_text()), ir.size.x - 7, 6, 2, GOLD)
	var dn: String = m.DAY_NAMES[m.day_i % 7].substr(0, 3)
	_t(f, ir.position + Vector2(4, 23), "Day %d %s %s  %s" % [m.day_count, dn, m.clock_text(), m.phase()], 6, w, ir.size.x - 7)
	var dr: int = m.days_until_rent()
	var rent_col: = Color("#e06a4a") if m.money < m.rent_due() and dr <= 2 else Color(1, 1, 1, 0.72)
	_t(f, ir.position + Vector2(4, 31), "Rent $%d due Mon (%dd)" % [m.rent_due(), dr], 6, rent_col, ir.size.x - 7)
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
		var hr: Rect2 = L["hint"]
		_t(f, hr.position + Vector2(0, 9), Cast.T(m.hint), 7, Color("#c0d890"), hr.size.x, HORIZONTAL_ALIGNMENT_CENTER)

	if not m.dialog.is_empty():
		var line: String = Cast.T(str(m.dialog[0]))
		var who: = Art.portrait_for(line, Cast.T("{hero}"), Cast.T("{partner}"), Cast.T("{baby}"))
		var duff: = who != ""
		var r: Rect2 = L["dialog"]
		_panel(r, 0.95)
		draw_rect(r.grow(-PX * 2), Color("#e88aa8"), false, PX)
		if duff:

			var pr: = Rect2(r.position + Vector2(6, 9), Vector2(48, 48))
			draw_rect(pr, Color("#3e2d19"))
			draw_rect(Rect2(pr.position, Vector2(48, 16)), Color("#5a3f24"))
			var mood: = Art.duff_mood(line, float(m.energy))
			if who == "madison":
				mood = Art.madison_mood(line, float(m.happiness), str(m.mood_kind()))
			elif who == "octavia":
				mood = Art.octavia_mood(line)
			Art.family_portrait(self, who, pr.position, mood, bool(m.shades))
			draw_rect(pr, Color("#e88aa8"), false, PX)
			_mt(f, r.position + Vector2(59, 13), line, r.size.x - 64, 7, 6, w)
		else:
			_mt(f, r.position + Vector2(7, 13), line, r.size.x - 14, 7, 6, w)
		_t(f, r.position + Vector2(r.size.x - 34, r.size.y - 3), "E / A >", 6, Color(1, 1, 1, 0.6))

func _draw_phone(f: Font) -> void:

	var o: Vector2 = (layout()["phone"] as Rect2).position + Vector2(0, 1)
	var buzz: float = m.ping_t
	if buzz > 0.0:
		o.x += sin(buzz * 60.0) * 1.5
	Art.image(self, "phone", o)
	if m.location == "gala":
		draw_rect(Rect2(o + Vector2(1, 2), Vector2(10, 14)), Color("#333333"))
	if m.phone_cracked:
		draw_line(o + Vector2(2, 3), o + Vector2(9, 14), Color(1, 1, 1, 0.8), 1.0)
		draw_line(o + Vector2(9, 4), o + Vector2(4, 12), Color(1, 1, 1, 0.6), 1.0)
	var n: int = m.unread_count()
	if n > 0:
		draw_circle(o + Vector2(12, 1), 4.0, Color("#ff3b30"))
		draw_string(f, o + Vector2(10, 4), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)
	_t(f, o + Vector2(4, 27), "P", 5, Color(1, 1, 1, 0.45))

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

func _draw_buffs(f: Font) -> void:

	var icons: = status_icons()
	for i in icons.size():
		var ic: Array = icons[i]
		var r: = Rect2(118 + i * 12, 24, 11, 11) if i < 5 else Rect2(118 + (i - 5) * 12, 36, 11, 11)
		var c: Color = ic[1]
		draw_rect(r, Color(0.07, 0.05, 0.04, 0.7))
		if Art.tex("buff_" + str(ic[0])) != null:
			Art.image(self, "buff_" + str(ic[0]), r.position)
		else:
			draw_string(f, r.position + Vector2(0, 7), str(ic[0]), HORIZONTAL_ALIGNMENT_CENTER, 11, 5, c)
		draw_rect(r, c, false, PX)
		draw_rect(Rect2(r.position + Vector2(1, 9.33), Vector2(9.0 * float(ic[2]), PX * 2.0)), c)

func _draw_face(p: Vector2, face: String) -> void:

	if Art.tex("face_" + face) != null:
		Art.image(self, "face_" + face, p)
	else:
		Art.image(self, "face_meh", p)

func _draw_fund(f: Font) -> void:
	var fv: float = m.fund_value()
	var fr: Rect2 = layout()["fund"]
	_panel(fr)
	Art.image(self, "ic_piggy", fr.position + Vector2(1, 1))
	_t(f, fr.position + Vector2(12, 7.5), Cast.T("{baby}'s fund"), 5, Color("#c8b0e8"), fr.size.x - 13)
	_bar(fr.position + Vector2(3, 10), fr.size.x - 6, fv / Market.GOAL, Color("#9a78c0"))
	var lbl: = ("$%.1fk" % (fv / 1000.0)) if fv >= 1000.0 else ("$%d" % int(fv))
	_t(f, fr.position + Vector2(3, 19), lbl + " / 100k", 5, Color.WHITE, fr.size.x - 6)

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
