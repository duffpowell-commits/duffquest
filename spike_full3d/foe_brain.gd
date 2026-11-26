extends Node
## One AI for every foe, driven by foe_data.gd (Phase 2 refactor step 2, Nov 26 2026). Replaces
## foe_pirate.gd, foe_mike.gd and foe_sendback.gd, which were three hand-written copies of the same
## fight: walk in beside Duff, jab after a red-ring wind-up, and (if the data has them) a ranged turn
## that alternates a throw and a charge, a rage at half health, and a shield only specials break.
## Made by porch.gd, ticked from its physics loop; `game` = porch.gd's shared fight services.
## porch.gd counts `recovery` down for every foe; `timer`, `cool` and `plate_rest` count down here.
##
## States: away, stalk, jab_tele, <throw.state>, charge_tele, charge, plate, dizzy, taunt, ko.

const Art = preload("porch_art.gd")
const RigActor = preload("rig_actor.gd")
const Data = preload("foe_data.gd")

var id := ""
var d: Dictionary      ## this foe's foe_data.gd entry
var game               ## porch.gd
var body: CharacterBody3D
var model              ## rig_actor.gd
var hp := 0
var state := "away"
var timer := 0.0
var cool := 0.0
var recovery := 0.0
var raged := false
var charge_next := false
var charge_dir := Vector3.FORWARD
var streak := 0        ## clean hits taken since the shield last came down
var plate_rest := 0.0
var shield: Node3D     ## the guard prop (Sends-It-Back's cloche), up in front of his chest
var shots: Array = []  ## [Node3D, velocity, life] per thrown prop in flight
var pool: Array = []   ## every thrown prop made so far (hidden ones get thrown again)

## Old names (tests, tools and porch.gd read these).
var HP: int:
	get: return d.hp
var HEIGHT: float:
	get: return d.height
var PLATE_AFTER: int:
	get: return d.guard.after
var CARD_TELE: float:
	get: return d.throw.tele
var cloche: Node3D:
	get: return shield
var cards: Array:
	get: return shots
var wind: float:       ## > 0 while a jab winds up (the pirate's old name)
	get: return timer if state == "jab_tele" else 0.0
	set(v):
		if v > 0:
			jab(v)
		elif state == "jab_tele":
			state = "stalk"
			timer = 0

static func make(porch, foe_id: String) -> Node:
	var foe = (load("res://foe_brain.gd") as GDScript).new()
	foe.id = foe_id
	foe.d = Data.FOES[foe_id]
	foe.name = foe_id.capitalize().replace(" ", "")
	foe.game = porch
	foe.hp = foe.d.hp
	porch.add_child(foe)
	foe.body = porch._actor(foe.d.spawn, foe.d.radius)
	foe.body.set_meta("brain", foe)
	foe.model = RigActor.make(foe.body, foe.d.model, foe.d.height)
	foe.model.fit_head_bone()  # every head matches Duff's (Duff, Nov 25)
	if foe.d.has("guard"):
		foe.shield = foe.call("make_" + foe.d.guard.prop)
		foe.shield.hide()
	foe.body.hide()
	foe.body.collision_layer = 0
	foe.body.collision_mask = 0
	return foe

## In the fight: punchable, ticked, framed by the camera.
func fighting() -> bool:
	return state not in ["away", "ko"]

## He walks in (or, for the first foe, is just there) and the fight is his.
func arrive(fresh := true) -> void:
	if fresh:
		game.player_hp = maxi(game.player_hp, game.PLAYER_HP)  # each fight starts Duff full
	state = "stalk"
	cool = d.ranged.first if d.has("ranged") else 0.0
	streak = 0
	plate_rest = 0
	body.position = d.spawn
	body.show()
	body.collision_layer = game.ACTOR_LAYER
	body.collision_mask = game.WORLD_LAYER | game.ACTOR_LAYER
	var walk_in: Dictionary = d.get("arrive", {})
	if walk_in.is_empty():
		_teach()
		return
	game._say(body, walk_in.line, walk_in.get("line_time", 2.8))
	game.message.text = walk_in.message
	_teach()
	if game.feel:
		game.feel.sfx("pickup", 0.0)
		if walk_in.has("music"):
			game.feel.play_music(walk_in.music)
	game._update_hud()

## His lesson: one button and one line (foe_data "teach"), shown as he steps in.
func _teach() -> void:
	if d.has("teach"):
		game.teach(d.teach[0], d.teach[1])

## The tutorial foe ("waits"): squares up but won't swing until Duff has thrown his first punch.
func waiting() -> bool:
	return d.get("waits", false) and not (game.learned.has("a") or game.learned.has("k") or game.learned.has("r"))

func tick(delta := 1.0 / 60) -> void:
	timer = maxf(0, timer - delta)
	cool = maxf(0, cool - delta)
	plate_rest = maxf(0, plate_rest - delta)
	var offset: Vector3 = game.player.position - body.position
	offset.y = 0
	var distance: float = offset.length()
	var direction: Vector3 = offset.normalized()
	var throw_state: String = d.throw.state if d.has("throw") else ""
	match state:
		"stalk":
			_face(direction)
			if waiting():
				game._move(body, Vector3.ZERO)
				model.move_at(0)
				return
			if distance <= d.reach and recovery <= 0 and game._clear_strike(body, game.player):
				jab(d.jab.tele)
				return
			elif d.has("ranged") and cool <= 0 and distance >= d.ranged.range and game.active:
				special(direction)
				return
			_walk(direction, d.get("rage_speed", d.speed) if raged else d.speed)
		"plate":
			_face(direction)
			_walk(direction, d.speed * .45)  # inches forward behind the shield
			if timer <= 0:
				lower_plate()
		"jab_tele":
			game._move(body, Vector3.ZERO)
			model.move_at(0)
			_face(direction)
			if timer <= 0:
				state = "stalk"
				game._tell(null)
				recovery = d.jab.get("rage_rest", d.jab.rest) if raged else d.jab.rest
				if distance <= d.reach + .25 and game._clear_strike(body, game.player) and game._hurt_duff(body.position):
					if d.jab.has("shove") and game.feel:  # shoves Duff out to where the throw and the charge reach him
						game.feel.push(game.player, game.player.position - body.position, d.jab.shove)
					if d.jab.has("cool_after"):
						cool = minf(cool, d.jab.cool_after)
		throw_state:
			game._move(body, Vector3.ZERO)
			if direction != Vector3.ZERO:
				_face(direction)
				charge_dir = direction  # the throw flies at where Duff is when it leaves his hand
			if timer <= 0:
				throw_shots()
				state = "stalk"
				game._tell(null)
		"charge_tele":
			game._move(body, Vector3.ZERO)
			if timer <= 0:
				game._tell(null)
				state = "charge"
				timer = d.charge.time
				model.locked = 0
				model.play("charge")
				model.player.speed_scale = 1.0
		"charge":
			if distance <= d.reach and charge_dir.dot(direction) > .2:
				game._hurt_duff(body.position)
				dizzy(d.charge.dizzy)
				return
			game._move(body, charge_dir * d.charge.speed)
			var bonked := false
			for i in body.get_slide_collision_count():
				var contact := body.get_slide_collision(i)
				var wall := contact.get_collider() as CollisionObject3D
				if wall and wall.collision_layer & game.WORLD_LAYER and absf(contact.get_normal().y) < .5:
					bonked = true
			if bonked or timer <= 0:
				dizzy(d.charge.dizzy)
		"dizzy", "taunt":
			game._move(body, Vector3.ZERO)
			if timer <= 0:
				state = "stalk"
				model.locked = 0
				if d.get("dizzy_free") and _can_rage():
					rage()  # he saved it for when he could stand up straight

func _face(direction: Vector3) -> void:
	if direction != Vector3.ZERO:
		model.turn_to(atan2(-direction.x, -direction.z))

## Walk to his spot beside Duff (around the planter if he steps around things).
func _walk(direction: Vector3, speed: float) -> void:
	var lane: Vector3 = game._side_spot(body, d.stop) - body.position
	lane.y = 0
	var walking: bool = lane.length() > .12
	var heading: Vector3 = lane.normalized()
	if d.get("step_around") and not game._clear_strike(body, game.player):
		heading = (direction + direction.cross(Vector3.UP)).normalized()
	game._move(body, heading * speed if walking else Vector3.ZERO)
	if state == "plate":
		return  # the held pose stays; no walk clip behind the shield
	var pace := Vector2(body.get_real_velocity().x, body.get_real_velocity().z).length()
	model.move_at(pace)  # legs match the ground speed: no skating

## Up close: he draws back for a jab, red ring first.
func jab(seconds: float) -> void:
	game.teach("b", "Red ring under him? Tap B to roll out of it.")
	state = "jab_tele"
	timer = seconds
	model.strike(d.jab.clip, seconds + .3)
	game._tell(body)

## Ranged turn: alternate the throw and the charge, each with a readable wind-up.
func special(direction: Vector3) -> void:
	cool = d.ranged.every * (d.ranged.rage_every if raged else 1.0)
	charge_dir = direction
	if game.feel:
		game.feel.sfx("tele", 0.0)
	game._tell(body)
	if charge_next and d.has("charge") or not d.has("throw"):
		state = "charge_tele"
		timer = d.charge.tele
		model.strike("taunt", d.charge.tele)
		game._say(body, d.charge.line)
	else:
		state = d.throw.state
		timer = d.throw.tele
		model.strike("throw", d.throw.tele + .35)
		game._say(body, d.throw.line)
	charge_next = not charge_next

## Up goes the shield: every punch and kick bounces off until it comes down or a special smashes it.
func raise_plate() -> void:
	state = "plate"
	timer = d.guard.time * (d.guard.rage_time if raged else 1.0)
	streak = 0
	game._tell(null)
	shield.show()
	model.strike("jab", .35)
	model.locked = timer + .1  # arm out, shield up: hold the end of the jab
	game._say(body, d.guard.line, 1.4)
	if game.feel:
		game.feel.sfx("pickup", 0.0, -2.0)

func lower_plate() -> void:
	if shield == null:
		return
	shield.hide()
	plate_rest = d.guard.rest
	model.locked = 0
	if state == "plate":
		state = "stalk"

## A punch or kick on the shield: a clang, and Duff bounces back.
func deflect() -> void:
	game._call("SENT BACK!")
	if game.feel:
		game.feel.sfx("bonk", .05, 2.0)
		game.feel.push(game.player, game.player.position - body.position, d.guard.shove)

## Blocks every punch and kick right now (specials still go through).
func guarding() -> bool:
	return state in d.get("armoured", [])

## A blocked hit (Duff mashed into his guard): the shield sends it back, or he counters at once.
func block() -> void:
	if state == "plate":
		deflect()
	elif state != "taunt" or d.get("counter_from_taunt"):
		recovery = 0
		jab(game.COUNTER_TELE)

## Can he read a mashed flurry right now? Not while dizzy or mid-charge (that's the opening).
func can_guard() -> bool:
	return d.get("reads_mashing", true) and state not in ["dizzy", "charge"]

## Grabbed by Return to Sender mid-move: whatever he was doing stops (a shield stays in his hand
## until the landing smashes it).
func cancel() -> void:
	if state in ["jab_tele", d.throw.state if d.has("throw") else "jab_tele", "charge_tele", "charge", "taunt"]:
		state = "stalk"
	game._tell(null)

func dizzy(seconds: float) -> void:
	game._tell(null)
	state = "dizzy"
	timer = seconds
	model.strike("hit", seconds)

func _can_rage() -> bool:
	return d.has("rage") and not raged and hp <= d.hp / 2

func rage() -> void:
	raged = true
	state = "taunt"
	timer = d.rage.time
	model.strike("taunt", d.rage.time)
	game._say(body, d.rage.line)

## Duff's hit lands. `stun` = seconds he can't swing; `special` = Red Right Hand or Return to Sender
## (it goes through the shield).
func hit(damage: int, stun: float, special := false) -> void:
	var smashed := special and shield != null and shield.visible
	if smashed:
		damage += d.guard.get("smash_bonus", 0)
	hp = maxi(0, hp - damage)
	game._show_impact(body.position)
	game._update_hud()
	if smashed:
		lower_plate()
		game._call("CLOCHE SMASHED!")
	if hp <= 0:
		knocked_out()
		return
	if special and d.has("special_dizzy"):
		dizzy(d.special_dizzy)  # knocked silly, shield or not: free hits
		if smashed and d.has("smash_line"):
			game._say(body, d.smash_line, 1.4)
		return
	if state in ["charge", "jab_tele"]:
		return  # mid-charge and mid-jab he shrugs it off
	if d.has("throw") and state == d.throw.state or state == "charge_tele":
		state = "stalk"  # hitting first knocks him out of his wind-up
		game._tell(null)
	if state == "dizzy" and d.get("dizzy_free"):
		return  # free hits: no shield (and no rage) while he's seeing stars
	if _can_rage():
		rage()
		return
	if d.has("guard"):
		streak += 1
		if streak >= d.guard.after and plate_rest <= 0:
			raise_plate()
			return
	if state == "stalk":
		model.locked = 0
		model.strike("hit", game.HIT_ANIM)
		recovery = maxf(recovery, stun)

func knocked_out() -> void:
	game._tell(null)
	lower_plate()
	state = "ko"
	model.strike("ko")
	body.collision_layer = 0
	body.collision_mask = 0
	clear_shots()
	var down: Dictionary = d.get("ko", {})
	if down.has("line"):
		game._say(body, down.line, down.get("line_time", 2.8))
	game._foe_down(self)

## The throw: one prop, or a fan of them, at where Duff was when it left his hand.
func throw_shots() -> void:
	var t: Dictionary = d.throw
	var count: int = t.get("rage_count", t.count) if raged else t.count
	for i in count:
		var angle: float = (i - (count - 1) * .5) * t.get("fan", 0.0) * (t.get("rage_fan", 1.0) if raged else 1.0)
		var heading := charge_dir.rotated(Vector3.UP, angle)
		var prop := _prop()
		prop.position = body.position + Vector3.UP * t.up + heading * .5
		prop.rotation = Vector3(-.65, atan2(-heading.x, -heading.z) if t.yaw else 0.0, 0)  # tipped toward the camera so it reads in flight
		prop.show()
		shots.append([prop, heading * t.speed, 1.4])
	if game.feel:
		game.feel.sfx("whoosh")

func _prop() -> Node3D:
	for prop in pool:
		if not prop.visible:
			return prop
	var made: Node3D = call("make_" + d.throw.prop)
	pool.append(made)
	return made

func tick_shots(delta: float) -> void:
	if shots.is_empty():
		return
	var t: Dictionary = d.throw
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for shot in shots.duplicate():
		var node: Node3D = shot[0]
		shot[2] -= delta
		var step: Vector3 = shot[1] * delta
		var ray := PhysicsRayQueryParameters3D.create(node.position, node.position + step, game.WORLD_LAYER)
		if shot[2] <= 0 or not space.intersect_ray(ray).is_empty():
			_drop(shot)
			continue
		node.position += step
		node.rotation.z = sin(shot[2] * t.wobble[0]) * t.wobble[1]  # flutter
		var gap: Vector3 = node.position - game.player.position
		gap.y = 0
		if gap.length() <= t.radius and game._hurt_duff(node.position):
			_drop(shot)  # a rolled-through prop keeps flying past him

func _drop(shot: Array) -> void:
	shots.erase(shot)
	shot[0].hide()

func clear_shots() -> void:
	for shot in shots:
		shot[0].hide()
	shots.clear()

## Mike's OBO sign, readable from both sides.
func make_obo_sign() -> Node3D:
	var art := Art.Sculpture.new()
	art.box(Vector3.ZERO, Vector3(.62, .3, .04), Color("#c9822f"))
	var board: Node3D = art.finish(game, "OboSign")
	_print_both_sides(board, "OBO", 72, .0032, Color("#3a2414"), .023)
	board.hide()
	return board

## A small white review card: "1 STAR" in red on both faces.
func make_review_card() -> Node3D:
	var art := Art.Sculpture.new()
	art.box(Vector3.ZERO, Vector3(.36, .22, .02), Color("#f4efe4"))
	var board: Node3D = art.finish(game, "ReviewCard")
	_print_both_sides(board, "1 STAR", 64, .0026, Color("#c0392b"), .012)
	board.hide()
	return board

func _print_both_sides(board: Node3D, words: String, size: int, pixel: float, ink: Color, depth: float) -> void:
	for side in [-1.0, 1.0]:
		var text := Label3D.new()
		text.text = words
		text.font_size = size
		text.outline_size = 0
		text.pixel_size = pixel
		text.modulate = ink
		text.position = Vector3(0, 0, side * depth)
		text.rotation.y = 0.0 if side > 0 else PI
		board.add_child(text)

## The silver cloche (a dome and a handle), held up in front of his chest like a shield.
func make_cloche() -> Node3D:
	var art := Art.Sculpture.new()
	art.form(Vector3.ZERO, Vector3(.7, .66, .44), Color("#eef1f5"), Vector3.ZERO, 16)  # deep enough to read side-on
	art.form(Vector3(0, 0, -.23), Vector3(.12, .12, .1), Color("#c3c8cf"))  # the handle, pointing at Duff
	art.band(Vector3(0, 0, .0), .35, Color("#9aa0a8"), Vector3(PI / 2, 0, 0), .025)
	var dome: MeshInstance3D = art.finish(model, "Cloche", Vector3(0, 1.1, -.42))  # the model faces -Z
	var shine := dome.material_override as StandardMaterial3D
	shine.metallic = .8
	shine.roughness = .25
	return dome

func tick_cards(delta: float) -> void:  ## old name (tests)
	tick_shots(delta)
