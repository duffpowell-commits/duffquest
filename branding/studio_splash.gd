extends Control
## A timed publisher card. The parent owns any startup work and scene transition.

signal dismissed

const PUBLISHER := "3 Eyed Fox Studios"
const DISPLAY_SECONDS := 2.5

var finished := false
var _visible_since_ms := -1


func _process(_delta: float) -> void:
	var now_ms := Time.get_ticks_msec()
	if _visible_since_ms < 0:
		_visible_since_ms = now_ms
		return
	if now_ms - _visible_since_ms < int(DISPLAY_SECONDS * 1000.0):
		return
	set_process(false)
	finished = true
	hide()
	dismissed.emit()
