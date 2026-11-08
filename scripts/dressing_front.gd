extends Node2D
## Draws the street dressing that stands in front of Duff (see dressing.gd). Child of main, z 1.
## Anything it would hide (Duff, enemies, bosses, raccoons, cats, Brittany, the inspector) gets the
## covering tree/prop faded (M4, Nov 8).

const Dressing: = preload("res://scripts/dressing.gd")
var m: Node
var fade_others: = true   # false = only Duff gets see-through (old behaviour; tools/actor_fade_shot)

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if m == null or m.player == null or m.location != "outside":
		return
	var ph: String = m.phase()
	var mod: = Color.WHITE
	if ph == "Night" or ph == "Evening":
		mod = Color.WHITE.lerp(Color(0.05, 0.05, 0.2), 0.35 if ph == "Night" else 0.15)
	Dressing.draw_layer(self, m.dressing, m.player.position.y + 10.0, true, mod, actor_boxes(m) if fade_others else actor_boxes(m).slice(0, 1))

## Body boxes of everyone visible on the street. Feet offsets match each actor's draw call
## (player +10, enemy/boss +11, raccoon +7, cat +5, Brittany/inspector +6).
static func actor_boxes(m: Node) -> Array:
	var out: Array = [Dressing.body(m.player.position + Vector2(0, 10), 12, 26)]
	for e in m.live_enemies():
		var ht: Variant = e.get("hidden_t")
		if ht != null and float(ht) > 0.0:
			continue   # a hiding boss must not be given away by a fading tree
		var k: = 1.45 if e.is_in_group("boss") else 1.0
		out.append(Dressing.body(e.global_position + Vector2(0, 11), 12 * k, 26 * k))
	for rc in m.raccoons:
		if is_instance_valid(rc) and rc.visible:
			out.append(Dressing.body(rc.global_position + Vector2(0, 7), 12, 12))
	for c in m.cats:
		if is_instance_valid(c) and c.visible:
			out.append(Dressing.body(c.global_position + Vector2(0, 5), 10, 10))
	if m.phase() != "Night":
		out.append(Dressing.body(m.BRITT_POS + Vector2(0, 6), 12, 26))
	if m.inspector_follow:
		out.append(Dressing.body(m.inspector_pos + Vector2(0, 6), 12, 26))
	return out
