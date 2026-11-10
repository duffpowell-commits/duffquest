extends Node2D
## Outdoor depth sort (Nov 9, replaces the M2/M4 "front layer picked by Duff's feet" overlay).
## Every street dressing item is its own tiny Node2D child of this node. This node and main are
## y-sorted while outside, so trees/props, Duff, enemies, bosses, raccoons, cats, projectiles,
## Brittany and the inspector all draw in one order by their feet: an enemy in FRONT of a tree now
## draws over it, one behind it draws under it.
## Sort keys: an item node sits at ground_y - FEET_OFS so it compares with actor ORIGINS (Duff's feet
## are origin +10; enemies +11, bosses ~+16, raccoons +7, cats +5: off by at most 6 px).
## See-through (M4): any item drawn over an actor's body box is faded to SEE_THROUGH_ALPHA.
## Cheap on phones: item nodes never redraw (static texture); per frame we only flip self_modulate
## after ~56 items x ~10 rect tests. Items tucked behind a storefront stay in main._draw_outside.

const Dressing: = preload("res://scripts/dressing.gd")
const FEET_OFS: = 10.0   # Duff's feet below his origin; item node y = ground y - this
var m: Node
var fade_others: = true   # false = only Duff gets see-through (old behaviour; tools/actor_fade_shot)
var nodes: Array = []     # [Node2D] parallel to items
var items: Array = []     # dressing dicts drawn here (not the ones behind a storefront)
var britt: Node2D
var insp: Node2D
var _out: = false

class Item extends Node2D:
	var it: Dictionary
	func _draw() -> void:
		var d: = it.duplicate()
		d["p"] = Vector2(0, FEET_OFS)   # local: node sits FEET_OFS above the ground point
		Dressing.draw_item(self, d)

## Brittany / the inspector used to be drawn in main._draw (under everything); now sorted too.
class Proxy extends Node2D:
	var m: Node
	var who: = ""
	func _draw() -> void:
		if who == "brittany":
			m.draw_brittany(self, -position)
		else:
			m.draw_inspector_at(self, -position)

func _ready() -> void:
	y_sort_enabled = true
	z_index = 0
	for it in m.dressing:
		if it.get("behind_building", false) or str(it["a"]) == "":
			continue
		var n: = Item.new()
		n.it = it
		n.position = it["p"] - Vector2(0, FEET_OFS)
		add_child(n)
		nodes.append(n)
		items.append(it)
	britt = Proxy.new()
	britt.m = m
	britt.who = "brittany"
	britt.position = m.BRITT_POS
	add_child(britt)
	insp = Proxy.new()
	insp.m = m
	insp.who = "inspector"
	add_child(insp)
	_set_outside(false)

func _set_outside(on: bool) -> void:
	_out = on
	visible = on
	m.y_sort_enabled = on

func _process(_d: float) -> void:
	if m == null or m.player == null:
		return
	var on: bool = m.location == "outside"
	if on != _out:
		_set_outside(on)
	if not on:
		return
	var ph: String = m.phase()
	britt.visible = ph != "Night"
	britt.queue_redraw()
	insp.visible = m.inspector_follow
	if insp.visible:
		insp.position = m.inspector_pos
		insp.queue_redraw()
	var mod: = Color.WHITE
	if ph == "Night" or ph == "Evening":
		mod = Color.WHITE.lerp(Color(0.05, 0.05, 0.2), 0.35 if ph == "Night" else 0.15)
	britt.self_modulate = mod   # she used to sit under main's evening tint rect
	var actors: = actor_boxes(m)
	if not fade_others:
		actors = actors.slice(0, 1)
	for i in nodes.size():
		var c: = mod
		if covers_actor(items[i], nodes[i].position.y, actors):
			c.a *= Dressing.SEE_THROUGH_ALPHA
		if nodes[i].self_modulate != c:
			nodes[i].self_modulate = c

## True if the item is drawn over (sorts after) some actor and its art overlaps that actor's body.
static func covers_actor(it: Dictionary, sort_y: float, actors: Array) -> bool:
	var r: = Dressing.art_rect(it)
	if not r.has_area():
		return false
	for a in actors:
		if float(a[1]) < sort_y and r.intersects(a[0]):
			return true
	return false

## [body box, sort y (node origin y)] for everyone visible on the street. Feet offsets match each
## actor's draw call (player +10, enemy +11, boss +11 x1.45, raccoon +7, cat +5, Brittany/inspector +6).
static func actor_boxes(m: Node) -> Array:
	var out: Array = [[Dressing.body(m.player.position + Vector2(0, 10), 12, 26), m.player.position.y]]
	for e in m.live_enemies():
		var ht: Variant = e.get("hidden_t")
		if ht != null and float(ht) > 0.0:
			continue   # a hiding boss must not be given away by a fading tree
		var k: = 1.45 if e.is_in_group("boss") else 1.0
		out.append([Dressing.body(e.global_position + Vector2(0, 11 * k), 12 * k, 26 * k), e.global_position.y])
	for rc in m.raccoons:
		if is_instance_valid(rc) and rc.visible:
			out.append([Dressing.body(rc.global_position + Vector2(0, 7), 12, 12), rc.global_position.y])
	for c in m.cats:
		if is_instance_valid(c) and c.visible:
			out.append([Dressing.body(c.global_position + Vector2(0, 5), 10, 10), c.global_position.y])
	if m.phase() != "Night":
		out.append([Dressing.body(m.BRITT_POS + Vector2(0, 6), 12, 26), m.BRITT_POS.y])
	if m.inspector_follow:
		out.append([Dressing.body(m.inspector_pos + Vector2(0, 6), 12, 26), m.inspector_pos.y])
	return out
