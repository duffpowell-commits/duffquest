extends Node2D

const PX: = 1.0 / 1.5
const PANEL: = Color(0.11, 0.09, 0.07)

var m: Node = null
var c: Node = null
var t: = 0.0
var dim_on: = false
var dim_a: = 0.0
var black_t: = 0.0
var black_dur: = 0.0
var banner_s: = ""
var banner_col: = Color.WHITE
var banner_t: = 0.0
var banner_dur: = 0.0
var card_t: = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 10

func dim(on: bool) -> void:
	dim_on = on

func blackout(dur: float) -> void:
	black_t = dur
	black_dur = dur

func banner(s: String, col: Color, dur: float) -> void:
	banner_s = s
	banner_col = col
	banner_t = dur
	banner_dur = dur

func demon_card() -> void:
	card_t = 1.3

func _process(delta: float) -> void:
	t += delta
	dim_a = move_toward(dim_a, 0.55 if dim_on else 0.0, delta * 2.5)
	black_t = maxf(0.0, black_t - delta)
	banner_t = maxf(0.0, banner_t - delta)
	card_t = maxf(0.0, card_t - delta)
	queue_redraw()

func _hidden() -> bool:
	return m == null or m.in_title or m.in_shift

func _draw() -> void:
	if _hidden():
		return
	var f: = ThemeDB.fallback_font
	var full: = Rect2(0, 0, 320, 180)

	if c.demon_t > 0.0:
		var pulse: = 0.5 + 0.5 * sin(t * 6.0)
		draw_rect(full, Color(0.45, 0.0, 0.25, 0.14 + 0.04 * pulse))
		for i in 6:
			var a: = (0.1 - i * 0.015) * (0.8 + 0.4 * pulse)
			draw_rect(full.grow(-i * 3.0), Color(0.6, 0.0, 0.2, a), false, 3.0)
	elif c.crash_t > 0.0:
		draw_rect(full, Color(0.1, 0.12, 0.2, 0.18))
	if not c.cinematic:
		_draw_panel(f)

	if dim_a > 0.0:
		draw_rect(full, Color(0, 0, 0, dim_a))
	if black_t > 0.0:
		draw_rect(full, Color(0, 0, 0, 1))
		var phase: = black_dur - black_t
		var flash: = int(phase / 0.13)
		if fmod(phase, 0.13) < 0.035 and flash < 9:
			var rng: = RandomNumberGenerator.new()
			rng.seed = flash * 7919
			var cx: = rng.randf_range(110, 210)
			var cy: = rng.randf_range(60, 120)
			draw_rect(full, Color(1, 1, 1, 0.55))
			for k in 4:
				var a2: = rng.randf_range(0, TAU)
				draw_line(Vector2(cx, cy), Vector2(cx, cy) + Vector2.from_angle(a2) * rng.randf_range(20, 60), Color(1, 1, 1), 2.0)
	if card_t > 0.0:
		var k: = clampf(card_t / 1.3, 0.0, 1.0)
		var slide: = (1.0 - minf(1.0, (1.3 - card_t) * 6.0)) * 200.0
		var r: = Rect2(40 + slide, 72, 240, 30)
		draw_rect(r, Color(0.08, 0.0, 0.06, 0.92 * minf(1.0, k * 3.0)))
		draw_rect(r, Color(1.0, 0.25, 0.4, minf(1.0, k * 3.0)), false, 1.5)
		_center(f, r.position + Vector2(0, 21), r.size.x, "IT'S DEMON TIME", 16, Color(1.0, 0.85, 0.3, minf(1.0, k * 3.0)))
	if banner_t > 0.0:
		var a3: = minf(1.0, banner_t / banner_dur * 3.0)
		_center(f, Vector2(0, 98), 320, banner_s, 11, Color(banner_col.r, banner_col.g, banner_col.b, a3))

func _center(f: Font, pos: Vector2, width: float, s: String, size: int, col: Color) -> void:
	var w: = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p: = pos + Vector2((width - w) / 2.0, 0)
	draw_string(f, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, col.a * 0.85))
	draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

## Level / special / heat: a slim bar above the attack buttons, only while fighting (or while
## something about it is worth seeing: heat refilling, points to spend, demon time).
const PANEL_R: = Rect2(240, 92, 78, 12)          # touch: above the attack buttons
const PANEL_R_KEYS: = Rect2(238, 163, 78, 12)    # keyboard/mouse: no buttons there, so tuck it into the bottom-right corner

func panel_rect() -> Rect2:
	var tc = m.get("touch")
	return PANEL_R if (tc != null and tc.visible) else PANEL_R_KEYS
const COMBAT_HOLD: = 4.0
var fight_t: = 0.0

func in_fight() -> bool:
	if m.location in ["arena", "gala"]:
		return true
	var p: Vector2 = m.player.global_position
	for e in m.live_enemies():
		if (e as Node2D).global_position.distance_to(p) < 170.0:
			return true
	return false

func panel_shown() -> bool:
	return fight_t > 0.0 or c.demon_t > 0.0 or c.crash_t > 0.0 or c.demon_ready() or c.points > 0 or c.heat < c.heat_max() - 0.5

func _draw_panel(f: Font) -> void:
	if not m.dialog.is_empty() or m.busy():
		return
	fight_t = COMBAT_HOLD if in_fight() else maxf(0.0, fight_t - get_process_delta_time())
	if not panel_shown():
		return
	var r: = panel_rect()
	draw_rect(Rect2(r.position + Vector2(PX * 2, PX * 2), r.size), Color(0, 0, 0, 0.2))
	draw_rect(r, Color(PANEL.r, PANEL.g, PANEL.b, 0.82))
	var sp: Dictionary = c.current()
	draw_string(f, r.position + Vector2(2, 5.5), "Lv %d" % c.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("#9fe0ff"))
	var sname: String = sp.get("short", "") if not sp.is_empty() else ""
	var cost: = int(c.cost_of(sp)) if not sp.is_empty() else 0
	var ready: bool = not sp.is_empty() and c.heat >= c.cost_of(sp)
	draw_string(f, r.position + Vector2(18, 5.5), ("%s %d" % [sname, cost]) if sname != "" else "", HORIZONTAL_ALIGNMENT_LEFT, 38, 5,
		Color("#f0ead8") if ready else Color(1, 1, 1, 0.45))
	var hb: = Rect2(r.position + Vector2(2, 7), Vector2(r.size.x - 4, 2.5))
	draw_rect(hb, Color(0, 0, 0, 0.65))
	var frac: = clampf(c.heat / c.heat_max(), 0.0, 1.0)
	var col: = Color("#ff7a2a")
	if c.demon_t > 0.0:
		col = Color("#c03aff").lerp(Color("#ff3a7a"), 0.5 + 0.5 * sin(t * 8.0))
	elif c.demon_ready():
		col = Color("#ffb02a").lerp(Color("#fff0a0"), 0.5 + 0.5 * sin(t * 10.0))
	draw_rect(Rect2(hb.position, Vector2(hb.size.x * frac, hb.size.y)), col)
	if not sp.is_empty():
		var mark: = hb.position.x + hb.size.x * clampf(c.cost_of(sp) / c.heat_max(), 0.0, 1.0)
		draw_line(Vector2(mark, hb.position.y - 0.5), Vector2(mark, hb.end.y + 0.5), Color(1, 1, 1, 0.7), PX)
	var xb: = Rect2(r.position + Vector2(2, 10.2), Vector2(r.size.x - 4, 1.0))
	draw_rect(xb, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(xb.position, Vector2(xb.size.x * clampf(float(c.xp) / c.xp_to_next(), 0.0, 1.0), xb.size.y)), Color("#6ac8ff"))
	if c.points > 0:
		draw_string(f, r.position + Vector2(56, 5.5), "+%d pts" % c.points, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("#a0ff90"))
	if c.demon_t > 0.0:
		_center(f, Vector2(r.position.x, r.position.y - 2), r.size.x, "DEMON TIME", 6, Color("#ff7ab0"))
	elif c.crash_t > 0.0:
		_center(f, Vector2(r.position.x, r.position.y - 2), r.size.x, "the crash...", 6, Color(0.7, 0.75, 0.9))
	elif c.demon_ready():
		_center(f, Vector2(r.position.x, r.position.y - 2), r.size.x, "R: DEMON TIME", 6, Color("#ffd060"))
