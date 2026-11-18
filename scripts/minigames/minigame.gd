extends Node2D
const UiStyle: = preload("res://scripts/ui_style.gd")
const Cast: = preload("res://scripts/cast.gd")

signal finished(score: float, notes: Array)

const W: = 320.0
const H: = 180.0
const BG: = Color("#1c1712")
const Art: = preload("res://scripts/art.gd")
const AudioScript: = preload("res://scripts/audio.gd")
const KITCHEN: = ["quiz", "prep", "pickles", "fryer", "temp_check", "sandwich", "salad", "garnish", "inspector"]

var backdrop: = ""
var veiled: = false   # main.open_overlay put the blurred live scene behind us
var backdrop_dim: = 0.0
var music: = ""
var work_duff: = false
var duff_armor: = "apron"

var shift: Node = null
var ctx: Dictionary = {}
var title: = "Station"
var time_limit: = 30.0
var t: = 0.0
var done: = false
var notes: Array = []
var buttons: Array = []
var bonus: = 0
var cursor: = Vector2(160, 90)
var pen_down: = false
var key_pen: = false
var space_is_pen: = true
var show_header: = true
var show_cursor: = false
var flash_msg: = ""
var flash_t: = 0.0
var flash_col: = Color.WHITE
var font: Font
const SQUISH_T: = 0.14
var pill_buttons: = false   # phone-style pill buttons (menu sheets, phone apps) instead of chunky key caps

## --- First-time coach (how-to card, easy first go, replay with "?") ---------------------------------
## A game opts in by returning steps from howto(): [{"i": prop art or "", "v": "tap"|"drag"|"hold"|"beat"|"mash"|"read", "s": text}].
## The first time each game (or prep phase, see coach_key) is played, its card opens and the clock waits.
## `pace` slows the game's clock: 0.7 on the first go, 0.85 on the second, full speed after (PACE_RAMP).
## Off in headless runs (tests, soak) unless a test turns it on.
const COACH_PATH: = "user://coach.json"
const PACE_RAMP: = [0.7, 0.85]
const HELP_C: = Vector2(267, 6.5)
static var coach_on: bool = DisplayServer.get_name() != "headless"
static var _plays: = {}
static var _plays_loaded: = false
var coach_open: = false
var coach_t: = 0.0
var coach_pace: = true   # false: card only, the game keeps real time (walk-around scenes)
var pace: = 1.0
var _coach_steps: Array = []
var _coach_key: = ""
var _coach_counted: Array = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	_setup()
	_auto_backdrop()
	coach_start()

func howto() -> Array: return []

func coach_key() -> String:
	return (get_script() as Script).resource_path.get_file().get_basename()

static func coach_plays(key: String) -> int:
	if not _plays_loaded:
		_plays_loaded = true
		if FileAccess.file_exists(COACH_PATH):
			var d = JSON.parse_string(FileAccess.get_file_as_string(COACH_PATH))
			if typeof(d) == TYPE_DICTIONARY:
				_plays = d
	return int(_plays.get(key, 0))

static func _coach_save() -> void:
	var f: = FileAccess.open(COACH_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_plays))

## Call when a new game (or prep phase) starts. Opens the card on a first go, sets the pace.
func coach_start() -> void:
	var key: = coach_key()
	if key == _coach_key:
		return
	_coach_key = key
	_coach_steps = howto()
	pace = 1.0
	coach_open = false
	if _coach_steps.is_empty() or not coach_on:
		return
	var n: = coach_plays(key)
	if coach_pace and n < PACE_RAMP.size():
		pace = float(PACE_RAMP[n])
	if n == 0:
		coach_show()

func coach_show() -> void:
	if _coach_steps.is_empty():
		return
	coach_open = true
	coach_t = 0.0
	pen_down = false
	key_pen = false

func coach_close() -> void:
	coach_open = false
	AudioScript.sfx("select")

## Count one finished go of the current game/phase (once per key per run).
func coach_done() -> void:
	if _coach_steps.is_empty() or not coach_on or _coach_key in _coach_counted:
		return
	_coach_counted.append(_coach_key)
	_plays[_coach_key] = coach_plays(_coach_key) + 1
	_coach_save()

func _help_hit(p: Vector2) -> bool:
	return not _coach_steps.is_empty() and coach_on and p.distance_to(_help_c()) <= 9.0

func _help_c() -> Vector2:
	return HELP_C if show_header else Vector2(W - 9, 8)

func _auto_backdrop() -> void:

	var sh: = shift if shift != null else _find_shift()
	var nm: = (get_script() as Script).resource_path.get_file().get_basename()
	if backdrop == "" and (KITCHEN.has(nm) or sh != null):
		backdrop = "kitchen"
		backdrop_dim = 0.5 if KITCHEN.has(nm) else 0.35
		work_duff = true
	if sh != null and sh.get("m") != null and sh.m.get("player") != null:
		duff_armor = str(sh.m.player.armor_id)
	if backdrop == "kitchen" and music == "":
		music = "kitchen"
	if music != "":
		AudioScript.music(music)

func _find_shift() -> Node:
	var p: = get_parent()
	while p != null:
		if p.has_signal("shift_over"):
			return p
		p = p.get_parent()
	return null

func _draw_backdrop() -> void:
	if backdrop == "" or Art.tex("bg_" + backdrop) == null:
		if veiled:
			return
		# No painted set: the boss cards' two-tone sunburst in this screen's own colour (STYLE_LOCK sec. 2),
		# turning slowly, instead of a flat slab. Lightened a touch so the rays read on dark BGs.
		UiStyle.burst(self, Rect2(0, 0, W, H), BG.lightened(0.12), Vector2(W * 0.5, H * 0.58), 28, t * 0.04)
		return
	Art.image(self, "bg_" + backdrop, Vector2.ZERO)
	if backdrop_dim > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(0.05, 0.03, 0.08, backdrop_dim))
	if work_duff:
		var top: = H - 4.0
		for b in buttons:
			top = minf(top, (b["rect"] as Rect2).position.y - 2.0)
		var sheet: = "duff_%s_black" % (duff_armor if ["apron", "clogs", "sleeves", "coat", "dad"].has(duff_armor) else "apron")
		if has_signal("chosen"):
			draw_set_transform(Vector2(W - 20.0, top), 0.0, Vector2(2, 2))
			Art.person(self, sheet, Vector2.ZERO, Vector2.DOWN, t, false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			Art.person(self, sheet, Vector2(W - 12.0, top), Vector2.LEFT, t, false)

func _setup() -> void: pass
func _tick(_d: float) -> void: pass
func _draw_game() -> void: pass
func _draw_top() -> void: pass
func _on_button(_id: String) -> void: pass
func _pointer_down(_p: Vector2) -> void: pass
func _pointer_up(_p: Vector2) -> void: pass
func _pointer_move(_p: Vector2) -> void: pass
func _key(_e: InputEventKey) -> void: pass
func _timeout() -> void: finish(0.0)
func debug_solve(_good: bool) -> void: pass

## House-style play objects (see UiStyle.prop). Minigame coords are 320x180, so 1.0 = a thick line.
func prop(r: Rect2, col: Color, shade: float = 0.3) -> void:
	UiStyle.prop(self, r, col, 1.0, shade)

func prop_circle(c: Vector2, rad: float, col: Color) -> void:
	UiStyle.prop_circle(self, c, rad, col, 1.0)

func is_pen() -> bool:
	return pen_down or key_pen

func rush() -> bool:
	return bool(ctx.get("rush", false))

func finish(score: float, note: String = "") -> void:
	if done:
		return
	done = true
	coach_done()
	if note != "":
		notes.append(note)
	if not has_signal("chosen") and time_limit >= 0.0:
		AudioScript.sfx("win" if score >= 0.6 else "fail")
	finished.emit(clampf(score, 0.0, 1.0), notes)

func flash(msg: String, col: Color = Color.WHITE, dur: float = 1.6) -> void:
	flash_msg = msg
	flash_col = col
	flash_t = dur

func hurt(amount: int, why: String) -> void:
	flash(why, Color("#e06a4a"), 2.0)
	if shift and shift.has_method("injure"):
		shift.injure(amount, why)

## House-style prop (kf_*, tools/import_kitchen_props.py): `h` world units tall, centred on `c`. False if the art is missing.
func pic(name: String, c: Vector2, h: float, mod: Color = Color.WHITE) -> bool:
	var tx: = Art.tex(name)
	if tx == null:
		return false
	var w: = h * tx.get_width() / float(tx.get_height())
	draw_texture_rect(tx, Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h)), false, mod)
	return true

## Nov 18 (Duff's fat-finger note): a tap inside a button hits it; a near miss within BUTTON_REACH of one goes to
## the nearest enabled button, so a thumb that lands on the gap between two still picks the one it was closest to.
const BUTTON_REACH: = 5.0

func _button_at(p: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d: = BUTTON_REACH
	for b in buttons:
		if not b["enabled"]:
			continue
		var r: Rect2 = b["rect"]
		if r.has_point(p):
			return b
		var d: = p.distance_to(Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y)))
		if d < best_d:
			best = b
			best_d = d
	return best

func add_button(id: String, rect: Rect2, label: String, key: int = 0, col: Color = Color("#57504e")) -> Dictionary:
	var b: = {"id": id, "rect": rect, "label": label, "key": key, "enabled": true, "col": col }
	buttons.append(b)
	return b

func get_button(id: String) -> Dictionary:
	for b in buttons:
		if b["id"] == id:
			return b
	return {}

func press(id: String) -> void:

	var b: = get_button(id)
	if b.is_empty() or not b["enabled"] or done:
		return
	AudioScript.sfx("back" if id in ["back", "close", "no", "later"] else "select")
	_on_button(id)

func _process(delta: float) -> void:
	if done:
		return
	if coach_open:
		coach_t += delta
		queue_redraw()
		return
	delta *= pace
	t += delta
	flash_t = maxf(0.0, flash_t - delta)
	var kv: = Vector2.ZERO
	if InputMap.has_action("move_left"):
		kv = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if kv != Vector2.ZERO:
		show_cursor = true
		cursor = (cursor + kv * 110.0 * delta).clamp(Vector2.ZERO, Vector2(W, H))
		_pointer_move(cursor)
	_tick(delta)
	if time_limit > 0.0 and t >= time_limit and not done:
		_timeout()
	queue_redraw()

func _input(e: InputEvent) -> void:
	if done:
		return
	if coach_open:
		var go: = false
		if e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed:
			go = true
		elif e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
			go = (e as InputEventKey).physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE, KEY_H, KEY_F1]
		if go and coach_t > 0.35:   # the tap that opened the game doesn't also close its card
			coach_close()
		if e is InputEventScreenTouch or e is InputEventScreenDrag or e is InputEventKey:
			get_viewport().set_input_as_handled()
		return
	if e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed and _help_hit(ui_point((e as InputEventScreenTouch).position)):
		coach_show()
		get_viewport().set_input_as_handled()
		return
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo \
			and (e as InputEventKey).physical_keycode == KEY_F1 and not _coach_steps.is_empty() and coach_on:
		coach_show()
		get_viewport().set_input_as_handled()
		return
	if e is InputEventScreenTouch:
		var st: = e as InputEventScreenTouch
		var sp: = ui_point(st.position)
		if st.pressed:
			var hb: = _button_at(sp)
			if not hb.is_empty():
				hb["press_ms"] = Time.get_ticks_msec()
				_on_button(hb["id"])
				get_viewport().set_input_as_handled()
				return
			cursor = sp
			pen_down = true
			_pointer_down(sp)
		elif pen_down:
			pen_down = false
			_pointer_up(sp)
		get_viewport().set_input_as_handled()
	elif e is InputEventScreenDrag:
		cursor = ui_point((e as InputEventScreenDrag).position)
		_pointer_move(cursor)
		get_viewport().set_input_as_handled()
	elif e is InputEventKey:
		var k: = e as InputEventKey
		if k.echo:
			return
		if k.pressed:
			for b in buttons:
				if b["enabled"] and int(b["key"]) != 0 and int(b["key"]) == int(k.physical_keycode):
					b["press_ms"] = Time.get_ticks_msec()
					_on_button(b["id"])
					get_viewport().set_input_as_handled()
					return
		if space_is_pen and k.physical_keycode == KEY_SPACE:
			key_pen = k.pressed
			show_cursor = true
			if k.pressed:
				_pointer_down(cursor)
			else:
				_pointer_up(cursor)
			get_viewport().set_input_as_handled()
			return
		if k.pressed:
			_key(k)

func ui_point(p: Vector2) -> Vector2:

	return get_canvas_transform().affine_inverse() * p

func txt(p: Vector2, s: String, size: int = 8, col: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(font, p, Cast.T(s), align as HorizontalAlignment, width, size, col)

## Text on a dark plate (UiStyle.tag), for labels that sit on top of painted backdrops.
func tag(p: Vector2, s: String, size: int = 7, col: Color = UiStyle.CREAM, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	UiStyle.tag(self, p, Cast.T(s), size, col, width, align as HorizontalAlignment, 1.0, font)

func mtxt(p: Vector2, s: String, width: float, size: int = 8, col: Color = Color.WHITE, max_lines: int = -1) -> void:
	draw_multiline_string(font, p, Cast.T(s), HORIZONTAL_ALIGNMENT_LEFT, width, size, max_lines, col)

## A ticket's spec as picture tiles instead of tiny text (IGN v4 #5): icons left to right in build order, a small
## arrow under them, the 86'd item slashed in red. icons[i] = art name or "" (then a colour dot from cols[i]).
func spec_icons(p: Vector2, icons: Array, cols: Array, crossed: int = -1, sz: float = 13.0, per_row: int = 8) -> float:
	for i in icons.size():
		var c: = p + Vector2((i % per_row) * (sz + 1.0) + sz * 0.5, floorf(i / float(per_row)) * (sz + 3.0) + sz * 0.5)
		draw_circle(c, sz * 0.5, Color(0, 0, 0, 0.08))
		var fade: = Color(1, 1, 1, 0.5) if i == crossed else Color.WHITE
		if str(icons[i]) == "" or not pic(str(icons[i]), c, sz, fade):
			prop_circle(c, sz * 0.38, cols[i] * fade)
		if i == crossed:   # 86'd: faded, with a red slash on a dark keyline so it shows on red food too
			draw_line(c + Vector2(-sz, -sz) * 0.45, c + Vector2(sz, sz) * 0.45, Color("#2b2218"), 3.5)
			draw_line(c + Vector2(-sz, -sz) * 0.45, c + Vector2(sz, sz) * 0.45, Color("#e0402a"), 2.0)
	var rows: = int(ceil(icons.size() / float(per_row)))
	var ay: = p.y + rows * (sz + 3.0)
	var aw: = minf(icons.size(), per_row) * (sz + 1.0) - 1.0
	draw_line(Vector2(p.x + 2, ay), Vector2(p.x + aw - 4, ay), Color("#6a625a"), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x + aw - 4, ay - 2.5), Vector2(p.x + aw, ay), Vector2(p.x + aw - 4, ay + 2.5)]), Color("#6a625a"))
	return ay + 4.0

## spec_icons at the bottom of a ticket whose text ends at text_y: big tiles in two rows when they fit, else one row.
func ticket_spec(text_y: float, bottom: float, icons: Array, cols: Array, crossed: int) -> void:
	var big: = icons.size() > 6
	var need: = (2.0 if big else 1.0) * 20.0 + 4.0
	if bottom - text_y >= need:
		spec_icons(Vector2(8, bottom - need), icons, cols, crossed, 17.0, 6)
	else:
		spec_icons(Vector2(8, maxf(text_y, bottom - 20.0)), icons, cols, crossed, 13.0, 8)

func bar(r: Rect2, frac: float, col: Color) -> void:
	draw_rect(r, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0, 1), r.size.y)), col)
	draw_rect(r, Color(1, 1, 1, 0.4), false, 1.0)

func _draw() -> void:
	_draw_backdrop()
	if done:
		return
	_draw_game()
	var now_ms: = Time.get_ticks_msec()
	for b in buttons:
		var r: Rect2 = b["rect"]
		var since: = float(now_ms - int(b.get("press_ms", -100000))) / 1000.0
		if since < SQUISH_T:   # Nov 17: a pressed button squishes in and springs back
			r = r.grow(-sin(since / SQUISH_T * PI) * minf(r.size.y * 0.12, 2.0))
			b["down"] = since < SQUISH_T * 0.5
		elif b.get("down", false) and b.has("press_ms"):
			b["down"] = false
		if since < SQUISH_T + 0.05:
			queue_redraw()
		if b.get("hide", false):   # drawn by the screen itself (settings switches), still tappable / key-bound
			continue
		if b.has("badge") or b.has("icon"):   # answer card (quiz, inspector) or picture tile (Fork ingredients)
			var ic: Texture2D = Art.tex(str(b["icon"])) if b.has("icon") else null
			UiStyle.card_button(self, r, Cast.T(str(b["label"])), str(b.get("badge", "")), b.get("badge_col", UiStyle.TEAL),
				b["col"], bool(b["enabled"]), bool(b.get("down", false)), 1.0 / 1.5, 8, ic, bool(b.get("stack", false)))
			continue
		if pill_buttons:
			UiStyle.pill_button(self, r, Cast.T(str(b["label"])), b["col"], bool(b["enabled"]), bool(b.get("down", false)), 1.0 / 1.5, 8)
		else:
			UiStyle.button(self, r, Cast.T(str(b["label"])), b["col"], bool(b["enabled"]), bool(b.get("down", false)), 1.0 / 1.5, 8)
		if int(b["key"]) != 0 and not Cast.touch:   # key chips are keyboard-only; phones never see "Space"/"Escape"
			txt(r.position + Vector2(2, 7), OS.get_keycode_string(int(b["key"])), 6, Color(1, 1, 1, 0.45))
	_draw_top()
	if show_header:
		draw_rect(Rect2(0, 0, W, 13), Color(UiStyle.PANEL, 0.95))
		draw_rect(Rect2(0, 12, W, 1.5), UiStyle.INK)
		var tw: = UiStyle.display.get_string_size(Cast.T(title), HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		var tab: = Rect2(2, 1, minf(tw + 10, W - (68.0 if _coach_steps.size() > 0 and coach_on else 50.0)), 11)
		UiStyle.box(self, Rect2(tab.position + Vector2(1, 1), tab.size).grow(0.5), Color(UiStyle.INK, 0.7), 3.0)
		UiStyle.box(self, tab.grow(0.5), UiStyle.INK, 3.0)
		UiStyle.box(self, tab.grow(-0.5), UiStyle.GOLD, 2.5)
		UiStyle.box(self, Rect2(tab.position + Vector2(1, 0.5), Vector2(tab.size.x - 2, 4)), UiStyle.GOLD.lightened(0.25), 2.0)
		draw_string(UiStyle.display, Vector2(7, 10), Cast.T(title), HORIZONTAL_ALIGNMENT_LEFT, tab.size.x - 8, 9, UiStyle.INK)
		if time_limit > 0.0:
			var left: = maxf(0.0, time_limit - t)
			UiStyle.label(self, Vector2(278, 10), "%4.1fs" % left, 9, UiStyle.PINK if left < 5.0 else UiStyle.CREAM, -1.0, HORIZONTAL_ALIGNMENT_LEFT, 3)
	if show_cursor:
		draw_arc(cursor, 4, 0, TAU, 12, Color(1, 1, 1, 0.8), 1.0)
		draw_line(cursor - Vector2(6, 0), cursor + Vector2(6, 0), Color(1, 1, 1, 0.5))
		draw_line(cursor - Vector2(0, 6), cursor + Vector2(0, 6), Color(1, 1, 1, 0.5))
	if flash_t > 0.0 and not coach_open:
		var fr: = Rect2(20, 66, 280, 22)
		UiStyle.panel(self, fr, UiStyle.PANEL, 0.96, 1.0 / 1.5)
		mtxt(fr.position + Vector2(4, 9), flash_msg, fr.size.x - 8, 8, flash_col, 2)
	if not _coach_steps.is_empty() and coach_on:
		var hc: = _help_c()
		draw_circle(hc + Vector2(0.8, 0.8), 6.0, Color(UiStyle.INK, 0.6))
		draw_circle(hc, 6.0, UiStyle.TEAL)
		draw_arc(hc, 6.0, 0, TAU, 24, UiStyle.INK, 1.0)
		UiStyle.label(self, hc + Vector2(-6, 3.5), "?", 9, UiStyle.CREAM, 12, HORIZONTAL_ALIGNMENT_CENTER, 2)
		if pace < 1.0 and not coach_open:
			tag(Vector2(0, 22), "EASY FIRST GO  (slowed down)" if pace <= PACE_RAMP[0] else "WARM-UP  (a bit slower)", 6, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, W - 4)
	if coach_open:
		_draw_coach()

## The how-to card: dims the game, three picture steps, each with a little animated hint of the move.
func _draw_coach() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.04, 0.02, 0.07, 0.72))
	var n: = _coach_steps.size()
	var row_h: = 30.0
	var r: = Rect2(18, 18, W - 36, 44 + n * row_h + 34)
	r.position.y = (H - r.size.y) * 0.5
	UiStyle.panel(self, r, UiStyle.PANEL, 0.98, 1.0)
	UiStyle.label(self, r.position + Vector2(0, 12), "HOW TO PLAY", 7, UiStyle.GOLD, r.size.x, HORIZONTAL_ALIGNMENT_CENTER, 2)
	UiStyle.label(self, r.position + Vector2(0, 26), Cast.T(title), 10, UiStyle.CREAM, r.size.x, HORIZONTAL_ALIGNMENT_CENTER, 3)
	for i in n:
		var st: Dictionary = _coach_steps[i]
		var y: = r.position.y + 36 + i * row_h
		var row: = Rect2(r.position.x + 8, y, r.size.x - 16, row_h - 3)
		UiStyle.box(self, row, Color(UiStyle.INK, 0.55), 4.0)
		var badge: = row.position + Vector2(9, row.size.y * 0.5)
		draw_circle(badge, 6.0, UiStyle.GOLD)
		draw_string(UiStyle.display, badge + Vector2(-6, 3.5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 12, 9, UiStyle.INK)
		var ic: = row.position + Vector2(36, row.size.y * 0.5)
		var art: = str(st.get("i", ""))
		if art != "" and pic(art, ic, row.size.y - 4):
			_coach_verb(str(st.get("v", "")), ic + Vector2(10, 6))
		else:
			_coach_verb(str(st.get("v", "")), ic)
		var lines: = UiStyle.wrap_words(Cast.T(str(st.get("s", ""))), row.size.x - 66, 8)
		var ty: = row.position.y + row.size.y * 0.5 - (lines.size() - 1) * 4.5 + 3
		for ln in lines.size():
			draw_string(font, Vector2(row.position.x + 56, ty + ln * 9), lines[ln], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiStyle.CREAM)
	var fy: = r.end.y - 28
	var pulse: = 0.5 + 0.5 * sin(coach_t * 5.0)
	var go: = Rect2(r.get_center().x - 60, fy, 120, 16)
	UiStyle.button(self, go, "GOT IT, LET'S GO", UiStyle.BTN_MAIN.lightened(0.12 * pulse), true, false, 1.0, 8)
	var foot: = "First go runs slow. Tap ? to see this again." if pace < 1.0 else "Tap ? to see this again."
	draw_string(font, Vector2(r.position.x, r.end.y - 4), foot, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 6, Color(UiStyle.CREAM, 0.6))

## A tiny looping hint of the gesture: tap = ripple, drag = sliding dot, hold = filling ring, beat = pulse on a 0.5 s beat, mash = fast ripples.
func _coach_verb(v: String, c: Vector2) -> void:
	var w: = Color(1, 1, 1, 0.95)
	match v:
		"tap", "mash":
			var per: = 0.9 if v == "tap" else 0.25
			var k: = fmod(coach_t, per) / per
			draw_arc(c, 2.0 + k * 7.0, 0, TAU, 16, Color(1, 1, 1, 1.0 - k), 1.0)
			draw_circle(c, 2.6, w)
		"drag":
			var k: = fmod(coach_t, 1.4) / 1.4
			var a: = c + Vector2(-9, 0)
			var p: = a + Vector2(18 * k, 0)
			draw_line(a, p, Color(1, 1, 1, 0.5), 2.0)
			draw_circle(p, 2.6, w)
		"hold":
			var k: = fmod(coach_t, 1.6) / 1.2
			draw_circle(c, 2.6, w)
			draw_arc(c, 6.0, -PI * 0.5, -PI * 0.5 + TAU * minf(k, 1.0), 20, UiStyle.GOLD, 1.5)
		"beat":
			var k: = fmod(coach_t, 0.5) / 0.5
			draw_circle(c, 2.0 + (1.0 - k) * 3.5, Color(UiStyle.GOLD, 0.4 + 0.6 * (1.0 - k)))
		"read":
			draw_circle(c, 2.6, Color(UiStyle.TEAL, 0.9))
