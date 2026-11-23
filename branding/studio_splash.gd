extends Control
## A skippable publisher card. The parent owns any startup work and scene transition.

signal dismissed

const UiStyle = preload("res://scripts/ui_style.gd")
const PUBLISHER := "3 Eyed Fox Studios"
const DISPLAY_SECONDS := 2.5

var finished := false


func _ready() -> void:
	var skip: Button = %Skip
	for state: String in ["normal", "hover", "pressed"]:
		var fill := StyleBoxFlat.new()
		fill.bg_color = UiStyle.BTN_ALT
		if state == "hover":
			fill.bg_color = fill.bg_color.lightened(0.15)
		elif state == "pressed":
			fill.bg_color = fill.bg_color.darkened(0.15)
		fill.set_corner_radius_all(22)
		skip.add_theme_stylebox_override(state, fill)
	skip.pressed.connect(_dismiss)
	get_tree().create_timer(DISPLAY_SECONDS).timeout.connect(_dismiss)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_dismiss()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_dismiss()


func _dismiss() -> void:
	if finished:
		return
	finished = true
	set_process_input(false)
	hide()
	dismissed.emit()
