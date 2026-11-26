extends Node
## Walkable zones (Phase 2 step 3, Nov 25 2026). Each zone is one root node holding its set,
## colliders and lamps; the world light, sun and camera stay on porch.gd. Loading a zone frees the
## old root and builds the new one behind a short fade card. Doors are spots on the floor: walk onto
## one and it takes you through (it only arms once Duff has stepped off it, so arriving never
## bounces him straight back).
##   porch      the fight. After PORCH SECURED, "Go inside" (or the front door) leads home.
##   apartment  Duff's place: couch, kitchenette, table, lamp, window. The door goes back out.
## `--zone=apartment` starts inside, with nobody to fight (renders, phone checks).

const Apartment = preload("zone_apartment.gd")

const FADE := .28        ## seconds to black and back
const DOOR_RADIUS := .6  ## how close to a door spot takes you through
const ARM_GAP := .3      ## step this far past the radius before a door works

## name -> [card text, explore camera?, x limit, z range]
const ZONES := {
	"porch": ["THE PORCH", false, 5.2, Vector2(-1.2, 4.6)],
	"apartment": ["HOME", true, 1.0, Vector2(-1.4, .6)],
}

## Who you fight in a zone, in order: [foe id (foe_data.gd), when he comes in]. "start" = already
## there; "parcel" = once Duff picks up the dropped parcel; a number = that many seconds after the one
## before goes down. `won` = the line when the last one drops.
const FIGHTS := {
	"porch": {"foes": [["pirate", "start"], ["mike", "parcel"], ["sendback", 2.2]], "won": "Refund denied. Porch secured."},
}

var game  ## porch.gd
var root: Node3D
var zone := ""
var indoor := false
var doors: Array = []  ## [{at: Vector2 (x, z), to, spawn: Vector3, face: Vector3}]
var spots := {}        ## named places in the zone (couch seats, kitchen...) for people at home
var people := {}       ## who's in this zone (rig actors by name), e.g. Madison and Brittany at home
var uses: Array = []   ## [{id, label, at: Vector2 (x, z), radius}]: what USE does near each spot
var armed := false
var moving := false
var trips := 0         ## zone changes so far (tests)
var card: ColorRect
var card_label: Label

static func make(owner) -> Node:
	var zones = (load("res://porch_zones.gd") as GDScript).new()
	zones.name = "Zones"
	zones.game = owner
	zones.process_mode = Node.PROCESS_MODE_ALWAYS
	owner.add_child(zones)
	zones._build_card()
	return zones

## Build `which` in place of the current zone. Doors and spots come from the builder.
func load_zone(which: String) -> void:
	if root:
		game.remove_child(root)
		root.queue_free()
	zone = which
	doors = []
	spots = {}
	uses = []
	people = {}
	root = Node3D.new()
	root.name = "Zone_" + which
	game.add_child(root)
	if which == "apartment":
		Apartment.build(self, root)
		indoor = true
	else:
		game._build_porch_set(root)
		doors.append({"at": Vector2(0, -2.3), "to": "apartment", "spawn": Vector3(-2.75, 0, -.45),
			"face": Vector3.RIGHT})
		indoor = false
	var z: Array = ZONES[which]
	game.fight_cam.set_zone(z[1] or game.exploring, z[2], z[3])
	armed = false
	if game.exploring and game.feel:  # home has its own music and room sound; the porch gets its street theme back
		game.feel.play_music("mus_edm_home" if which == "apartment" else "mus_edm_neighborhood")
		game.feel.play_bed("home_bed" if which == "apartment" else "")
	if game.exploring:
		game.message.text = "Home. The door on the left goes back out." if which == "apartment" \
			else "Porch secured. The front door's on the stoop."
	if game.look:
		game.look.dress(root)

## Walking around: a door Duff steps onto takes him through.
func tick() -> void:
	if moving:
		return
	var at := Vector2(game.player.position.x, game.player.position.z)
	var near: Dictionary = {}
	for door in doors:
		if at.distance_to(door.at) <= DOOR_RADIUS:
			near = door
	if near.is_empty():
		if not armed:
			armed = true
			for door in doors:
				if at.distance_to(door.at) <= DOOR_RADIUS + ARM_GAP:
					armed = false
		return
	if armed:
		travel(near.to, near.spawn, near.face)

## The USE spot Duff is standing at (closest wins), or {} when there's nothing to use.
func nearest_use() -> Dictionary:
	var at := Vector2(game.player.position.x, game.player.position.z)
	var best: Dictionary = {}
	var best_d := INF
	for spot in uses:
		var d := at.distance_to(spot.at)
		if d <= spot.radius and d < best_d:
			best = spot
			best_d = d
	return best

## Fade out, swap zones, put Duff at `spawn` facing `face`, fade back in.
func travel(to: String, spawn: Vector3, face := Vector3.BACK) -> void:
	moving = true
	game.active = false
	card_label.text = ZONES[to][0]
	if game.hud and game.hud.get("display"):
		card_label.add_theme_font_override("font", game.hud.display)
	card.show()
	var out := create_tween()
	out.tween_property(card, "color:a", 1.0, FADE)
	out.parallel().tween_property(card_label, "modulate:a", 1.0, FADE)
	await out.finished
	arrive(to, spawn, face)
	var back := create_tween()
	back.tween_interval(.25)
	back.tween_property(card, "color:a", 0.0, FADE)
	back.parallel().tween_property(card_label, "modulate:a", 0.0, FADE)
	await back.finished
	card.hide()
	game.active = true
	moving = false

## The swap itself (no fade): tests and `--zone=` use it directly.
func arrive(to: String, spawn: Vector3, face := Vector3.BACK) -> void:
	load_zone(to)
	game.player.position = spawn
	game.player.velocity = Vector3.ZERO
	game.facing = face
	game.player_model.rotation.y = atan2(-face.x, -face.z)
	game.fight_cam.snap(game.player.position, null)
	trips += 1

func _build_card() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	card = ColorRect.new()
	card.color = Color(.07, .05, .09, 0)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.hide()
	layer.add_child(card)
	card_label = Label.new()
	card_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_label.add_theme_font_size_override("font_size", 64)
	card_label.add_theme_color_override("font_color", Color("#f6e7cf"))
	card_label.add_theme_color_override("font_outline_color", Color("#1d1620"))
	card_label.add_theme_constant_override("outline_size", 10)
	card_label.modulate.a = 0
	card.add_child(card_label)
