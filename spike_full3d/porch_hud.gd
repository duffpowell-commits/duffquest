extends Control
## The porch's HUD and menus in the main game's style (scripts/hud.gd + scripts/ui_style.gd, Nov 25 2026,
## Duff: "get the slice closer to the original hud and menus"): Duff's-phone status strip (clock, day, hearts,
## cash pill), the objective line, the foe's name plate + bar, A (bonk) / B (roll) round buttons, and the menus:
## title card, pause sheet (settings), KNOCKED OUT and PORCH SECURED screens with pill buttons in the three
## button roles (MAIN teal, ALT plum, EXIT red). Main-game numbers are x3 here (its HUD is 320 wide, this is 960).
## Made by porch.gd (`Hud.make(scene, layer)`); it reads the fight's state every frame.

const INK := Color("#1e1220")
const CREAM := Color("#fff1d6")
const PANEL := Color("#2a1e36")
const GOLD := Color("#f2b63c")
const PINK := Color("#ff6f91")
const GLASS := Color("#17141f")
const BEZEL := Color("#07060a")
const DIM := Color("#b9b2c8")
const CASH := Color("#1fae5b")
const BTN_MAIN := Color("#27998f")
const BTN_ALT := Color("#5b4a72")
const BTN_EXIT := Color("#b8432f")
const A_COL := Color("#4e7a3a")
const B_COL := Color("#a43a2c")
const STRIP := Rect2(12, 10, 588, 42)
const GOAL := Rect2(12, 58, 588, 32)
const PAUSE := Rect2(892, 12, 56, 48)
const PLATE := Rect2(300, 474, 360, 56)
const A_AT := Vector2(870, 456)
const A_R := 64.0
const B_AT := Vector2(738, 348)
const B_R := 48.0
const K_AT := Vector2(870, 300)  ## the push kick, above A
const K_R := 48.0
const K_COL := Color("#c7802a")
const R_AT := Vector2(738, 212)  ## Red Right Hand: its ring is the special meter, it glows when full
const R_R := 44.0
const R_COL := Color("#c0201c")
const START_MIN := 17 * 60 + 30  ## 5:30 PM: the porch fight is the golden hour (light follows the clock, porch_daylight.gd)
const GAME_MIN_PER_SEC := .2 ## the clock creeps: one game minute every 5 seconds

var game  ## porch.gd
var display: Font
var body: Font
var heart: Texture2D
var a_down := false
var b_down := false
var k_down := false
var r_down := false
var flash_col := Color.TRANSPARENT
var flash_time := 0.0
var flash_len := 1.0
var minutes := 0.0
var clock_start := start_min()  ## minute of the day the clock started at
var menu: Control        ## the open title / pause / end screen, or null
var screen := ""         ## "", "title", "pause", "settings", "ko", "win"
var _boxes := {}
var pause_button: TouchScreenButton
## Fill the phone (8.5 pass): the window stretches with aspect "expand", so a wide phone gets a wider view
## (no black bars). The HUD is laid out for 960x540; `spare` is the extra width/height, and right-hand
## controls slide by it, centred ones by half of it.
var spare := Vector2.ZERO
var _pause_touch := -1  ## touch index holding the pause button through _input (see porch.gd _input)

static func make(scene: Node, layer: CanvasLayer) -> Control:
	var hud = (load("res://porch_hud.gd") as GDScript).new()
	hud.name = "Hud"
	hud.game = scene
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(hud)
	return hud

func _ready() -> void:
	display = load("res://fonts/Baloo2-ExtraBold.ttf")
	body = load("res://fonts/Nunito-ExtraBold.ttf")
	heart = load("res://art/ic_heart.png")
	get_tree().set_quit_on_go_back(false)  # back opens the pause sheet instead of closing the game
	var pause := TouchScreenButton.new()
	pause.name = "Pause"
	var shape := RectangleShape2D.new()
	shape.size = PAUSE.size
	pause.shape = shape
	pause.shape_centered = false
	pause.position = PAUSE.position
	pause.released.connect(func() -> void: open_pause() if screen == "" and game.active else null)
	add_child(pause)
	pause_button = pause

## Esc / P pauses and resumes; Space or Enter takes the main button on the title and end screens.
## Same backstop as porch.gd's thumb buttons: the browser's TouchScreenButton can miss a touch on it.
func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch == null or pause_button == null:
		return
	if touch.pressed:
		if Rect2(PAUSE.position + Vector2(spare.x, 0), PAUSE.size).has_point(touch.position):  # a second open_pause from the button itself is a no-op
			_pause_touch = touch.index
	elif touch.index == _pause_touch:
		_pause_touch = -1
		pause_button.released.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or not event is InputEventKey:
		return
	var key: int = event.physical_keycode
	if key in [KEY_ESCAPE, KEY_P]:
		if screen == "":
			if game.active:
				open_pause()
		elif screen == "pause":
			close_menu()
		elif screen == "settings":
			show_title()
	elif event.is_action_pressed("ui_accept") and screen in ["title", "ko", "win"]:
		get_viewport().set_input_as_handled()  # first, or the fight would also swing on this key
		if screen == "title":
			start()
		else:
			game.retry()

## Android back and losing focus (a call, the home button) pause the fight, like the main game.
func _notification(what: int) -> void:
	if game == null or not is_inside_tree():
		return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and screen != "":
		match screen:
			"pause": close_menu()
			"settings": show_title()
			_: get_tree().quit()  # back on the title or an end card leaves the game
	elif what in [NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT] and screen == "" and game.active:
		open_pause()

func start() -> void:
	close_menu()
	game.begin()

func _process(delta: float) -> void:
	_fit_to_screen()
	if game.stick:
		game.stick.visible = screen == ""  # no stick over the title, pause or end cards (it sat on the Fight button)
	if screen == "" and game.active:
		minutes += delta * GAME_MIN_PER_SEC
	flash_time = maxf(0, flash_time - delta / maxf(Engine.time_scale, .05))
	queue_redraw()

## Slide the right-hand touch buttons, the pause button and the stick's zone onto the real screen edges.
func _fit_to_screen() -> void:
	var view := get_viewport_rect().size
	spare = Vector2(maxf(0, view.x - 960), maxf(0, view.y - 540))
	for button in game.thumb_buttons:
		button.position = button.get_meta("base") + spare
	if pause_button:
		pause_button.position = PAUSE.position + Vector2(spare.x, 0)
	if game.stick:
		game.stick.position.y = 150 + spare.y
	if menu and menu.has_node("Frame"):
		menu.get_node("Frame").position = spare * .5  # stays centred if the screen turns or resizes

## ---------------------------------------------------------------- drawing helpers (ui_style.gd, x3)

func _box(r: Rect2, fill: Color, rad: float) -> void:
	if r.size.x <= 0 or r.size.y <= 0:
		return
	var k := "%s|%d" % [fill.to_html(true), roundi(rad)]
	var sb: StyleBoxFlat = _boxes.get(k)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = fill
		sb.set_corner_radius_all(roundi(rad))
		sb.anti_aliasing = true
		_boxes[k] = sb
	draw_style_box(sb, r)

## Phone glass: soft drop shadow, black bezel, dark glass, a faint sheen on the top half.
func _glass(r: Rect2, rad: float, a := .9) -> void:
	_box(Rect2(r.position + Vector2(2.7, 3.3), r.size).grow(1.8), Color(0, 0, 0, .35 * a), rad + 1.8)
	_box(r.grow(2), Color(BEZEL, a), rad + 2)
	_box(r, Color(GLASS, a), rad)
	_box(Rect2(r.position, Vector2(r.size.x, r.size.y * .45)).grow(-1.2), Color(1, 1, 1, .055 * a), maxf(rad - 1.2, 0))

## Cream lettering with an ink outline.
func _label(at: Vector2, text: String, size: int, col := CREAM, width := -1.0,
		align := HORIZONTAL_ALIGNMENT_LEFT, font: Font = null, outline := 6) -> void:
	var f := font if font else display
	draw_string_outline(f, at, text, align, width, size, outline, Color(INK, col.a))
	draw_string(f, at, text, align, width, size, col)

func _text(at: Vector2, text: String, size: int, col: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(body, at, text, align, width, size, col)

## Round touch button: ink ring, flat fill, a lighter cap, a display-font letter (ui_style.round_button).
func _round(c: Vector2, r: float, col: Color, letter: String, down: bool) -> void:
	var a := 1.0 if down else .85
	var fill := col.lightened(.15) if down else col
	draw_circle(c + Vector2(3, 3), r, Color(INK, .55 * a))
	draw_circle(c, r, Color(fill, a))
	draw_circle(c - Vector2(0, r * .25), r * .62, Color(fill.lightened(.18), a * .6))
	draw_arc(c, r, 0, TAU, 48, Color(INK, a), 3.6)
	if letter.length() == 1:
		_label(c + Vector2(0, r * .34), letter, int(r * 1.0), Color(CREAM, a), -1, HORIZONTAL_ALIGNMENT_CENTER)
	else:  # a word (USE): centred across the button
		_label(c + Vector2(-r, r * .2), letter, int(r * .55), Color(CREAM, a), r * 2, HORIZONTAL_ALIGNMENT_CENTER)

func _hint(at: Vector2, text: String) -> void:
	draw_string_outline(body, at - Vector2(60, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, 6, Color(0, 0, 0, .7))
	draw_string(body, at - Vector2(60, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 120, 18, Color(1, 1, 1, .92))

## ---------------------------------------------------------------- the HUD

func _draw() -> void:
	if flash_time > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(flash_col, .45 * flash_time / flash_len))
	if screen != "":
		return  # menus stand alone; gameplay HUD returns on resume
	_strip()
	_goal()
	draw_set_transform(Vector2(spare.x, 0))
	_pause_button()
	draw_set_transform(Vector2(spare.x * .5, spare.y))
	_foe_plate()
	draw_set_transform(Vector2(spare.x * .5, 0))
	_callout()
	draw_set_transform(spare)
	if game.active and game.exploring:  # walking around: one big USE button, named for what's here
		var spot: Dictionary = game.zones.nearest_use()
		_round(A_AT, A_R, BTN_MAIN if spot else Color(BTN_MAIN, .4), "USE", a_down and not spot.is_empty())
		if spot:
			_hint(A_AT + Vector2(-A_R - 44, 26), spot.label)
	elif game.active:
		_round(B_AT, B_R, B_COL, "B", b_down)
		_hint(B_AT + Vector2(-B_R - 38, 7), "roll")
		_meter_button()
		_round(K_AT, K_R, K_COL, "K", k_down)
		_hint(K_AT + Vector2(-K_R - 38, 7), "kick")
		_round(A_AT, A_R, A_COL, "A", a_down)
		_hint(A_AT + Vector2(-A_R - 44, 26), "bonk")
		_lesson_ring()
	draw_set_transform(Vector2.ZERO)

## Teach by doing: a pulsing cream ring around the one button the fight is teaching (porch.gd teach()).
func _lesson_ring() -> void:
	if game.lesson == "":
		return
	var at: Vector2 = {"a": A_AT, "b": B_AT, "k": K_AT, "r": R_AT}[game.lesson]
	var radius: float = {"a": A_R, "b": B_R, "k": K_R, "r": R_R}[game.lesson]
	var pulse := .5 + .5 * sin(Time.get_ticks_msec() / 140.0)
	draw_arc(at, radius + 9 + 7 * pulse, 0, TAU, 64, Color(CREAM, .45 + .45 * pulse), 5, true)

## The special: a dark button whose red ring fills with the meter; full, it lights up and pulses.
func _meter_button() -> void:
	var full: bool = game.meter >= 100
	if full:
		var pulse := .5 + .5 * sin(Time.get_ticks_msec() / 130.0)
		draw_circle(R_AT, R_R + 8 + 4 * pulse, Color(R_COL, .25 + .2 * pulse))
		_round(R_AT, R_R, R_COL, "R", r_down)
	else:
		_round(R_AT, R_R, PANEL, "R", false)
		var frac: float = game.meter / 100.0
		if frac > 0:
			draw_arc(R_AT, R_R - 4, -PI / 2, -PI / 2 + TAU * frac, 48, R_COL, 6)
	_hint(R_AT + Vector2(-R_R - 46, 7), "special")

func flash(col: Color, seconds: float) -> void:
	flash_col = col
	flash_time = seconds
	flash_len = seconds

## Minute of the day the clock starts at: START_MIN, or `--clock=HH:MM`.
static func start_min() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--clock="):
			var parts := arg.trim_prefix("--clock=").split(":")
			return (int(parts[0]) * 60 + (int(parts[1]) if parts.size() > 1 else 0)) % 1440
	return START_MIN

## Minute of the day now (fractional; the lighting follows it).
func game_minute() -> float:
	return clock_start + minutes

func clock_text() -> String:
	var m := clock_start + int(minutes)
	var h := (m / 60) % 24
	return "%d:%02d %s" % [12 if h % 12 == 0 else h % 12, m % 60, "AM" if h < 12 else "PM"]

## [time  day] .... [hearts = Duff's HP] [cash pill] [v]: the main game's status strip.
func _strip() -> void:
	_glass(STRIP, STRIP.size.y * .5)
	var y := STRIP.position.y + 29
	var tm := clock_text()
	_text(Vector2(STRIP.position.x + 21, y), tm, 21, Color.WHITE)
	var tw := body.get_string_size(tm, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
	_text(Vector2(STRIP.position.x + 32 + tw, y - 1), "Wed  Day 1", 18, DIM)
	var x := STRIP.end.x - 15
	var c := Vector2(x, STRIP.position.y + 21)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-6.6, -4.5), c + Vector2(6.6, -4.5), c + Vector2(0, 4.5)]), Color(1, 1, 1, .8))
	x -= 18
	var cash := "$%d" % game.cash
	var cw := body.get_string_size(cash, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x + 21
	var cr := Rect2(x - cw, STRIP.position.y + 7, cw, 27)
	_box(cr, CASH.darkened(.3), 13)
	_box(cr.grow(-1.5), CASH, 11.5)
	_box(Rect2(cr.position + Vector2(1.5, 1.5), Vector2(cr.size.x - 3, 10)), Color(1, 1, 1, .16), 9)
	_text(cr.position + Vector2(0, 21), cash, 21, Color.WHITE, cw, HORIZONTAL_ALIGNMENT_CENTER)
	x = cr.position.x - 14
	for i in range(game.PLAYER_HP - 1, -1, -1):  # Duff's hearts, right to left
		x -= 26
		var full: bool = i < game.player_hp
		draw_texture_rect(heart, Rect2(x, STRIP.position.y + 9, 24, 24), false, Color(1, 1, 1, 1.0 if full else .22))

## The objective line under the strip, with the main game's gold "!" badge.
func _goal() -> void:
	if game.message.text == "":
		return
	_glass(GOAL, GOAL.size.y * .5, .78)
	var b := Vector2(GOAL.position.x + 18, GOAL.position.y + 16)
	draw_circle(b, 11, GOLD)
	draw_arc(b, 11, 0, TAU, 24, INK, 2)
	_text(b + Vector2(-12, 7), "!", 19, INK, 24, HORIZONTAL_ALIGNMENT_CENTER)
	_text(Vector2(GOAL.position.x + 38, GOAL.position.y + 22), game.message.text, 18, CREAM, GOAL.size.x - 48)

## Top right: the phone button that opens the pause sheet (the main game's phone icon spot).
func _pause_button() -> void:
	_glass(PAUSE, 14, .85)
	var c := PAUSE.get_center()
	draw_rect(Rect2(c + Vector2(-9, -11), Vector2(6, 22)), CREAM)
	draw_rect(Rect2(c + Vector2(3, -11), Vector2(6, 22)), CREAM)
	_text(Vector2(PAUSE.position.x - 96, PAUSE.end.y + 22), "%d FPS%s" % [Engine.get_frames_per_second(),
		" LITE" if game.look and game.look.lite else ""], 15, DIM, 150, HORIZONTAL_ALIGNMENT_RIGHT)

## Combo callout under the strip, centred: gold "2 HIT", "KNOCKDOWN!", "DASH HOOK!" that pops and fades.
func _callout() -> void:
	if game.callout_time <= 0 or game.callout == "":
		return
	var t: float = game.callout_time
	var pop := 1.0 + .35 * clampf((t - (game.CALLOUT_TIME - .12)) / .12, 0, 1)  # starts big, settles
	var a := clampf(t / .25, 0, 1)
	var size := int(44 * pop)
	_label(Vector2(0, 150 + size * .3), game.callout, size, Color(GOLD, a), 960, HORIZONTAL_ALIGNMENT_CENTER, display, 9)

## Bottom centre: the foe's name plate and health bar (the main game's boss bar).
func _foe_plate() -> void:
	var foe: Array = game.foe_status()
	if foe.is_empty():
		return
	_box(PLATE.grow(3), INK, 12)
	_box(PLATE, PANEL, 10)
	_box(Rect2(PLATE.position, Vector2(PLATE.size.x, 20)).grow(-2), Color(1, 1, 1, .06), 8)
	_label(PLATE.position + Vector2(0, 25), foe[0], 21, CREAM, PLATE.size.x, HORIZONTAL_ALIGNMENT_CENTER, display, 5)
	var bar := Rect2(PLATE.position + Vector2(12, 34), Vector2(PLATE.size.x - 24, 12))
	_box(bar.grow(2), Color("#e8873a"), 5)
	_box(bar, Color("#3a2030"), 4)
	var frac := clampf(float(foe[1]) / float(foe[2]), 0, 1)
	if frac > 0:
		_box(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color("#e2583a"), 4)
		_box(Rect2(bar.position, Vector2(bar.size.x * frac, 4)), Color(1, 1, 1, .2), 2)

## ---------------------------------------------------------------- menus

func _pill(text: String, col: Color, on_press: Callable, width := 300.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 64)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", display)
	b.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		var base := Color("#493827") if col == BTN_MAIN else Color("#292421")
		sb.bg_color = base.lightened(.16) if state in ["pressed", "hover"] else base
		sb.set_corner_radius_all(7)
		sb.border_color = Color("#bd9255") if col == BTN_MAIN else Color("#856c49")
		sb.set_border_width_all(3)
		sb.shadow_color = Color(0, 0, 0, .35)
		sb.shadow_size = 0
		sb.shadow_offset = Vector2(0, 5)
		sb.anti_aliasing = true
		b.add_theme_stylebox_override(state, sb)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(state, CREAM)
	b.add_theme_color_override("font_outline_color", INK)
	b.add_theme_constant_override("outline_size", 2)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = CREAM
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(7)
	b.add_theme_stylebox_override("focus", focus)
	b.pressed.connect(on_press)
	return b

func _glass_panel(r: Rect2, rad := 28.0) -> Panel:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#292421", .94)
	sb.set_corner_radius_all(int(rad))
	sb.border_color = Color("#856c49")
	sb.set_border_width_all(4)
	sb.shadow_color = Color(0, 0, 0, .4)
	sb.shadow_size = 10
	sb.anti_aliasing = true
	p.add_theme_stylebox_override("panel", sb)
	return p

func _title_label(parent: Control, text: String, at: Vector2, width: float, size: int, col := GOLD, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.size = Vector2(width, size * 1.4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", font if font else display)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 8 if size > 30 else 3)
	parent.add_child(l)
	return l

func _new_menu(kind: String, wash: float) -> Control:
	close_menu()
	_fit_to_screen()  # the title opens from _ready, before the first frame has measured the screen
	screen = kind
	menu = Control.new()
	menu.name = "Menu_" + kind
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	if wash > 0:
		var dim := ColorRect.new()
		dim.color = Color(.07, .05, .09, wash)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		menu.add_child(dim)
	var frame := Control.new()  # the 960x540 layout, centred on a wider (or taller) screen
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size = Vector2(960, 540)
	frame.position = spare * .5
	menu.add_child(frame)
	get_tree().paused = true
	return frame

func close_menu() -> void:
	if menu:
		menu.hide()  # hidden at once so it stops catching touches; freed at the end of the frame
		menu.queue_free()
		menu = null
	screen = ""
	get_tree().paused = false

## Title: the approved gold logo and compact chapter stamp directly over the porch.
func show_title() -> void:
	var m := _new_menu("title", 0.0)
	# Same owner-approved dusk portrait as root/HD; the actual 3D porch and rig return as soon as Fight starts.
	var art := TextureRect.new()
	art.texture = load("res://art/bg_title.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(art)
	menu.move_child(art, 0)
	if game.bubble:
		game.bubble.hide()
		game.bubble_tail.hide()
	var logo := TextureRect.new()
	logo.texture = load("res://art/wrr_logo.png")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(344, 5)
	logo.size = Vector2(272, 171)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(logo)
	var ticket := TextureRect.new()
	ticket.texture = load("res://art/wrr_chapter_ticket.png")
	ticket.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ticket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ticket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ticket.position = Vector2(775, 16)
	ticket.size = Vector2(145, 90)
	ticket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(ticket)
	_title_label(m, "PORCH ENCOUNTER", Vector2(735, 112), 220, 17, CREAM, body)
	_title_label(m, "Get the package back.", Vector2(220, 174), 520, 22, CREAM, body)
	var fight := _pill("Fight", BTN_MAIN, start, 260)
	fight.position = Vector2(30, 410)
	m.add_child(fight)
	var controls := _pill("Controls", BTN_ALT, func() -> void: show_controls(show_title), 260)
	controls.position = Vector2(670, 376)
	m.add_child(controls)
	var settings := _pill("Settings", BTN_ALT, show_settings, 260)
	settings.position = Vector2(670, 454)
	m.add_child(settings)
	if not DisplayServer.is_touchscreen_available():
		_title_label(m, "Keys: WASD move, Space bonk, K kick, Shift roll, Esc menu", Vector2(0, 520), 960, 15, CREAM, body)

## Pause / settings: a phone glass sheet rising from the bottom with a grabber.
func open_pause() -> void:
	_sheet("pause", "Paused", [
		["Resume", BTN_MAIN, close_menu],
		["Retry", BTN_ALT, func() -> void: game.retry()],
		["Controls", BTN_ALT, func() -> void: show_controls(open_pause)],
	] + _settings_rows() + [["Quit to title", BTN_EXIT, func() -> void: game.quit_to_title()]])

## One screen: what every button does (Nov 26 first-timer: "R only made sense once it glowed").
func show_controls(back: Callable) -> void:
	var m := _new_menu("controls", .82)
	_title_label(m, "CONTROLS", Vector2(0, 26), 960, 44, GOLD)
	var rows := [
		[A_COL, "A", "Bonk. Tap again as each punch lands for a combo. Mashing gets blocked."],
		[B_COL, "B", "Roll. A red ring under a foe means he's about to swing: roll out of it."],
		[K_COL, "K", "Kick. Goes through a guard and shoves him back."],
		[R_COL, "R", "Special. The ring fills as you land hits. Far off: a fire dash. Up close: a throw."],
		[DIM, "", "Left thumb: the stick moves Duff."],
	]
	for i in rows.size():
		var y := 96 + i * 66
		var dot := Panel.new()
		var look := StyleBoxFlat.new()
		look.bg_color = rows[i][0]
		look.set_corner_radius_all(26)
		dot.add_theme_stylebox_override("panel", look)
		dot.position = Vector2(110, y)
		dot.size = Vector2(52, 52)
		m.add_child(dot)
		_title_label(dot, rows[i][1], Vector2(0, 6), 52, 30, CREAM)
		_title_label(m, rows[i][2], Vector2(186, y + 12), 680, 21, CREAM, body).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var row := HBoxContainer.new()
	row.position = Vector2(330, 444)
	row.add_child(_pill("Back", BTN_EXIT, back))
	m.add_child(row)

func show_settings() -> void:
	_sheet("settings", "Settings", _settings_rows() + [["Done", BTN_EXIT, show_title]])

func _settings_rows() -> Array:
	var lite: bool = game.look != null and game.look.lite
	var muted := AudioServer.is_bus_mute(0)
	return [
		["Graphics: %s" % ("Lite" if lite else "Full"), BTN_ALT, func() -> void: _toggle_lite()],
		["Sound: %s" % ("Off" if muted else "On"), BTN_ALT, func() -> void: _toggle_sound()],
	]

func _toggle_lite() -> void:
	if game.look:
		game.look.set_lite(not game.look.lite)
		game.look.stay_lite = game.look.lite
	_reopen()

func _toggle_sound() -> void:
	AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
	_reopen()

func _reopen() -> void:
	if screen == "pause":
		open_pause()
	else:
		show_settings()

func _sheet(kind: String, title: String, rows: Array) -> void:
	var m := _new_menu(kind, .45)
	var lines := ceili(rows.size() / 2.0)
	var h := 96 + lines * 80 + 20
	var sheet := _glass_panel(Rect2(130, 540 - h, 700, h + 40))
	m.add_child(sheet)
	var grab := ColorRect.new()
	grab.color = Color(1, 1, 1, .3)
	grab.position = Vector2(320, 12)
	grab.size = Vector2(60, 6)
	sheet.add_child(grab)
	_title_label(sheet, title, Vector2(0, 22), 700, 32, CREAM)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 16)
	grid.position = Vector2(26, 88)
	for r in rows:
		grid.add_child(_pill(r[0], r[1], r[2]))
	sheet.add_child(grid)

## KNOCKED OUT / PORCH SECURED: the main game's fail and win screens.
func show_end(won: bool) -> void:
	var m := _new_menu("win" if won else "ko", .82)
	_title_label(m, "PORCH SECURED" if won else "KNOCKED OUT", Vector2(0, 96), 960, 84)
	var r: Dictionary = game.result if won else {}
	_title_label(m, ("GRADE %s" % r.grade) if r else ("PACKAGE RECOVERED" if won else "GAME OVER"),
		Vector2(0, 196), 960, 40 if r else 28, GOLD if r else CREAM)
	var box := _glass_panel(Rect2(200, 268, 560, 96), 18)
	m.add_child(box)
	var line := "I get knocked out. Me and the sidewalk get acquainted. Retry starts the fight over."
	if not won and game.checkpoint > 0:
		line = "I get knocked out. Me and the sidewalk get acquainted. Retry starts at %s." % game.foes[game.checkpoint].d.name
	if r:
		line = "%s  ·  %d hit%s taken  ·  %d special%s\n%s" % [game.clock_label(r.time), r.hits, "" if r.hits == 1 else "s",
			r.specials, "" if r.specials == 1 else "s",
			"NEW BEST!" if r.new_best else "Best: %s in %s" % [r.best_grade, game.clock_label(r.best_time)]]
	elif won:
		line = "Mike: \"Okay. Mark me as sold.\" Duff walks the package back up the steps."
	_title_label(box, line, Vector2(24, 16), 512, 21, CREAM, body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	if won:  # the porch is secured: walk home through the front door (Phase 2 step 3)
		row.add_theme_constant_override("separation", 24)
		row.position = Vector2(96, 410)
		row.add_child(_pill("Go inside", BTN_MAIN, func() -> void: game.go_inside(), 240))
		row.add_child(_pill("Play again", BTN_ALT, func() -> void: game.retry(), 240))
		row.add_child(_pill("Quit to title", BTN_EXIT, func() -> void: game.quit_to_title(), 240))
	else:
		row.position = Vector2(150, 410)
		row.add_child(_pill("Retry", BTN_MAIN, func() -> void: game.retry()))
		row.add_child(_pill("Quit to title", BTN_EXIT, func() -> void: game.quit_to_title()))
	m.add_child(row)
