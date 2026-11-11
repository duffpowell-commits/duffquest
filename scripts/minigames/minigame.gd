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

func _ready() -> void:
	font = ThemeDB.fallback_font
	_setup()
	_auto_backdrop()

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
	if e is InputEventScreenTouch:
		var st: = e as InputEventScreenTouch
		var sp: = ui_point(st.position)
		if st.pressed:
			for b in buttons:
				if b["enabled"] and (b["rect"] as Rect2).has_point(sp):
					_on_button(b["id"])
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

func mtxt(p: Vector2, s: String, width: float, size: int = 8, col: Color = Color.WHITE, max_lines: int = -1) -> void:
	draw_multiline_string(font, p, Cast.T(s), HORIZONTAL_ALIGNMENT_LEFT, width, size, max_lines, col)

func bar(r: Rect2, frac: float, col: Color) -> void:
	draw_rect(r, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0, 1), r.size.y)), col)
	draw_rect(r, Color(1, 1, 1, 0.4), false, 1.0)

func _draw() -> void:
	_draw_backdrop()
	if done:
		return
	_draw_game()
	for b in buttons:
		var r: Rect2 = b["rect"]
		UiStyle.button(self, r, Cast.T(str(b["label"])), b["col"], bool(b["enabled"]), bool(b.get("down", false)), 1.0 / 1.5, 8)
		if int(b["key"]) != 0 and not Cast.touch:   # key chips are keyboard-only; phones never see "Space"/"Escape"
			txt(r.position + Vector2(2, 7), OS.get_keycode_string(int(b["key"])), 6, Color(1, 1, 1, 0.45))
	_draw_top()
	if show_header:
		draw_rect(Rect2(0, 0, W, 13), Color(UiStyle.PANEL, 0.95))
		draw_rect(Rect2(0, 12, W, 1.5), UiStyle.INK)
		var tw: = UiStyle.display.get_string_size(Cast.T(title), HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		draw_rect(Rect2(2, 1, minf(tw + 10, W - 50), 11), UiStyle.GOLD)
		draw_rect(Rect2(2, 1, minf(tw + 10, W - 50), 11), UiStyle.INK, false, 1.0)
		draw_string(UiStyle.display, Vector2(7, 10), Cast.T(title), HORIZONTAL_ALIGNMENT_LEFT, W - 60, 9, UiStyle.INK)
		if time_limit > 0.0:
			var left: = maxf(0.0, time_limit - t)
			UiStyle.label(self, Vector2(278, 10), "%4.1fs" % left, 9, UiStyle.PINK if left < 5.0 else UiStyle.CREAM, -1.0, HORIZONTAL_ALIGNMENT_LEFT, 3)
	if show_cursor:
		draw_arc(cursor, 4, 0, TAU, 12, Color(1, 1, 1, 0.8), 1.0)
		draw_line(cursor - Vector2(6, 0), cursor + Vector2(6, 0), Color(1, 1, 1, 0.5))
		draw_line(cursor - Vector2(0, 6), cursor + Vector2(0, 6), Color(1, 1, 1, 0.5))
	if flash_t > 0.0:
		var fr: = Rect2(20, 66, 280, 22)
		UiStyle.panel(self, fr, UiStyle.PANEL, 0.96, 1.0 / 1.5)
		mtxt(fr.position + Vector2(4, 9), flash_msg, fr.size.x - 8, 8, flash_col, 2)
