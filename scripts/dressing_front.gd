extends Node2D
## Draws the street dressing that stands in front of Duff (see dressing.gd). Child of main, z 1.

const Dressing: = preload("res://scripts/dressing.gd")
var m: Node

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if m == null or m.player == null or m.location != "outside":
		return
	var ph: String = m.phase()
	var mod: = Color.WHITE
	if ph == "Night" or ph == "Evening":
		mod = Color.WHITE.lerp(Color(0.05, 0.05, 0.2), 0.35 if ph == "Night" else 0.15)
	Dressing.draw_layer(self, m.dressing, m.player.position.y + 10.0, true, mod)
