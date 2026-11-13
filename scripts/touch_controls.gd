extends Node2D
const UiStyle: = preload("res://scripts/ui_style.gd")
const Cast: = preload("res://scripts/cast.gd")

signal a_pressed
signal b_pressed
signal g_pressed
signal p_pressed
signal s_pressed
signal s_released
signal swap_pressed
signal d_pressed
signal drawer_pressed

const JOY_HOME: = Vector2(36, 142)
const JOY_R: = 20.0
const BTN_A: = Vector2(296, 140)
const BTN_B: = Vector2(272, 160)
const BTN_R: = 11.0
const BTN_G: = Vector2(306, 112)
const BTN_G_R: = 11.0     # = BTN_R (IGN v2: every thumb button as big as A)
const BTN_P: = Vector2(195, 9)     # hud.gd layout()["phone"]
const BTN_P_R: = 9.0
const BTN_S: = Vector2(248, 148)
const BTN_S_R: = 11.0
const BTN_SW: = Vector2(240, 126)
const BTN_SW_R: = 11.0
const BTN_D: = Vector2(282, 116)
const BTN_D_R: = 11.0
var s_idx: = -1

var m: Node = null

var player: CharacterBody2D
var joy_center: = JOY_HOME
var joy_knob: = Vector2.ZERO
var joy_idx: = -1
var used: = false

## Show the touch pad up front only on a phone or tablet. On the web that means the browser says it is iOS or
## Android: a touchscreen laptop also reports a touchscreen, and portals (CrazyGames) reject games that pick mobile
## controls from touch detection. Anyone who really touches the screen gets the pad on that first touch (_input).
static func default_visible() -> bool:
	if OS.has_feature("web"):
		return OS.has_feature("web_ios") or OS.has_feature("web_android")
	return DisplayServer.is_touchscreen_available()

## A real finger, not a mouse click turned into a touch by pointing/emulate_touch_from_mouse.
static func real_touch(e: InputEvent) -> bool:
	return e is InputEventScreenTouch and e.device != InputEvent.DEVICE_ID_EMULATION

func _ready() -> void:
	visible = default_visible()
	if visible:
		Cast.touch = true

func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var t: = e as InputEventScreenTouch
		var tp: = get_canvas_transform().affine_inverse() * t.position
		if real_touch(t):
			visible = true
			used = true
			Cast.touch = true
		if not visible:
			return
		if t.pressed:
			if tp.distance_to(BTN_A) < BTN_R + 5.0:
				a_pressed.emit()
				get_viewport().set_input_as_handled()
			elif not dialog_open() and tp.distance_to(BTN_B) < BTN_R + 5.0:
				b_pressed.emit()
				get_viewport().set_input_as_handled()
			elif not dialog_open() and tp.distance_to(BTN_G) < BTN_G_R + 4.0:
				g_pressed.emit()
				get_viewport().set_input_as_handled()
			elif tp.distance_to(BTN_P) < BTN_P_R:
				p_pressed.emit()
				get_viewport().set_input_as_handled()
			elif not dialog_open() and _on_hud(tp):
				drawer_pressed.emit()
				get_viewport().set_input_as_handled()
			elif not dialog_open() and _special_shown() and tp.distance_to(BTN_S) < BTN_S_R + 4.0:
				s_idx = t.index
				s_pressed.emit()
				get_viewport().set_input_as_handled()
			elif not dialog_open() and tp.distance_to(BTN_SW) < BTN_SW_R + 4.0:
				swap_pressed.emit()
				get_viewport().set_input_as_handled()
			elif not dialog_open() and _demon_shown() and tp.distance_to(BTN_D) < BTN_D_R + 4.0:
				d_pressed.emit()
				get_viewport().set_input_as_handled()
			elif tp.x < 160.0 and joy_idx == -1 and not dialog_open():
				joy_idx = t.index
				joy_center = tp
				joy_knob = Vector2.ZERO
		elif t.index == s_idx:
			s_idx = -1
			s_released.emit()
		elif t.index == joy_idx:
			joy_idx = -1
			joy_knob = Vector2.ZERO
			joy_center = JOY_HOME
	elif e is InputEventScreenDrag:
		var d: = e as InputEventScreenDrag
		if d.index == joy_idx:
			joy_knob = (get_canvas_transform().affine_inverse() * d.position - joy_center).limit_length(JOY_R)
	if player:
		player.joy_vec = joy_knob / JOY_R
	queue_redraw()

## Taps on the HUD's top strip (or the open drawer) toggle the detail drawer.
func _on_hud(tp: Vector2) -> bool:
	if m == null or m.get("hud") == null or not m.hud.visible:
		return false
	var L: Dictionary = m.hud.layout()
	if (L["strip"] as Rect2).grow(2.0).has_point(tp):
		return true
	return bool(m.hud.drawer_open) and (L["drawer"] as Rect2).has_point(tp)

func _demon_shown() -> bool:
	return m != null and m.get("combat") != null and m.combat.demon_unlocked

func dialog_open() -> bool:
	return m != null and m.get("dialog") != null and not (m.dialog as Array).is_empty()

func _process(_d: float) -> void:
	# Menus/overlays turn off input here (main.open_overlay), so a finger lifted while
	# one is open never sends its release. Drop any held stick/special so the player
	# doesn't keep walking after the menu closes (Brittany's "Never mind" bug).
	if not is_processing_input():
		release_all()
	if visible:
		queue_redraw()


func release_all() -> void:
	if s_idx != -1:
		s_idx = -1
		s_released.emit()
	if joy_idx != -1 or joy_knob != Vector2.ZERO:
		joy_idx = -1
		joy_knob = Vector2.ZERO
		joy_center = JOY_HOME
	if player and player.joy_vec != Vector2.ZERO:
		player.joy_vec = Vector2.ZERO

static func rects() -> Dictionary:

	return {"joy": Rect2(JOY_HOME - Vector2(JOY_R, JOY_R), Vector2(JOY_R, JOY_R) * 2.0),
		"a": Rect2(BTN_A - Vector2(BTN_R, BTN_R), Vector2(BTN_R, BTN_R) * 2.0),
		"b": Rect2(BTN_B - Vector2(BTN_R, BTN_R), Vector2(BTN_R, BTN_R) * 2.0),
		"g": Rect2(BTN_G - Vector2(BTN_G_R, BTN_G_R), Vector2(BTN_G_R, BTN_G_R) * 2.0) }

func _btn(c: Vector2, r: float, col: Color, label: String, _f: Font) -> void:
	UiStyle.round_button(self, c, r, col, label, 0.82)

func _draw() -> void:
	var f: = ThemeDB.fallback_font
	var talk: = dialog_open()
	if not talk:
		draw_circle(joy_center, JOY_R, Color(0.94, 0.89, 0.77, 0.12))
		draw_arc(joy_center, JOY_R, 0, TAU, 32, Color(0.94, 0.89, 0.77, 0.4), 0.67)
		draw_circle(joy_center + joy_knob, 8, Color(0.94, 0.89, 0.77, 0.42))
		_btn(BTN_B, BTN_R, Color("#a43a2c"), "B", f)
		_hint(BTN_B + Vector2(0, -13), "roll")
		_btn(BTN_G, BTN_G_R, Color("#d8982e"), "G", f)
		var c = m.combat if m != null and m.get("combat") != null else null
		if c != null:
			var sp: Dictionary = c.current()
			if not sp.is_empty():   # no special before Pinwheel (Lv 2): just A and B
				var ok: bool = c.heat >= c.cost_of(sp)
				_btn(BTN_S, BTN_S_R, Color("#e0702a") if ok else Color("#6a4a3a"), "S", f)
				_hint(BTN_S + Vector2(0, 17), str(sp["short"]))
			if c.unlocked().size() > 1:
				_btn(BTN_SW, BTN_SW_R, Color("#7a6a8a"), "", f)
				draw_string(f, BTN_SW + Vector2(-5, 2.5), "<>", HORIZONTAL_ALIGNMENT_CENTER, 10, 7, Color("#f0ead8"))
			if _demon_shown():
				var glow: bool = c.demon_ready() or c.demon_t > 0.0
				_btn(BTN_D, BTN_D_R, Color("#c02a6a") if glow else Color("#4a2a3a"), "D", f)
	_btn(BTN_A, BTN_R, Color("#4e7a3a"), "A", f)
	_hint(BTN_A + Vector2(0, 18), "next" if talk else ("talk/use" if _near_thing() else "bonk"))

## Button captions: 6 px, near-opaque, with a dark outline so they read on any floor (review: 5 px at 55% was invisible).
func _hint(at: Vector2, s: String) -> void:
	var f: = ThemeDB.fallback_font
	draw_string_outline(f, at - Vector2(20, 0), s, HORIZONTAL_ALIGNMENT_CENTER, 40, 6, 2, Color(0, 0, 0, 0.7))
	draw_string(f, at - Vector2(20, 0), s, HORIZONTAL_ALIGNMENT_CENTER, 40, 6, Color(1, 1, 1, 0.92))

func _special_shown() -> bool:
	return m != null and m.get("combat") != null and not m.combat.current().is_empty()

func _near_thing() -> bool:
	return m != null and m.has_method("nearest_interactable") and not (m.nearest_interactable() as Dictionary).is_empty()
