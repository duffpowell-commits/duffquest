extends Control
## A skippable publisher card. The parent owns any startup work and scene transition.

signal dismissed

const PUBLISHER := "3 Eyed Fox Studios"
const DISPLAY_SECONDS := 0.75

var finished := false


func _ready() -> void:
	%Skip.pressed.connect(_dismiss)
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
