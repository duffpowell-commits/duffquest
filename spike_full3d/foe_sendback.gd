extends Node
## Sir Sends-It-Back (boss "sendback" in the main game's scripts/boss.gd): the porch's third fight, after
## Marketplace Mike. The fight that makes you use the specials. He holds up a silver cloche ("sent
## back!") that deflects every punch and kick; only Red Right Hand or Return to Sender smashes it, and
## that leaves him dizzy and open. From range he throws a spread of 1-star review cards or charges
## ("I'm coming BACK there"); up close he swats. At half health he rages: longer plate, wider spread.
## Same pattern as foe_mike.gd: made by porch.gd, ticked from its physics loop, `game` = porch.gd.

const Art = preload("porch_art.gd")
const RigActor = preload("rig_actor.gd")
const HEIGHT := 1.75
const HP := 10
const SPEED := 1.7
const RAGE_SPEED := 2.2
const SPECIAL_RANGE := 2.2  ## cards / charge only from at least this far
const SPECIAL_EVERY := 2.8  ## seconds between ranged moves (x .75 once he rages)
const CARD_TELE := .75      ## wind-up before the cards leave his hand: dodge then
const CARD_SPEED := 6.0
const CARD_RADIUS := .45
const CARD_FAN := .36       ## radians between cards in the spread
const CHARGE_TELE := .8
const CHARGE_SPEED := 6.8
const CHARGE_TIME := .85
const DIZZY := 1.1          ## after a charge into a wall or into Duff
const PLATE_AFTER := 2      ## clean hits in a row before the cloche comes up
const PLATE_TIME := 2.6     ## seconds he hides behind it (raged: PLATE_TIME * 1.4)
const PLATE_REST := 3.0     ## seconds after lowering it before he can raise it again
const PLATE_SHOVE := 6.0    ## m/s: a punch on the cloche bounces Duff back
const BROKEN := 1.8         ## dizzy after a special smashes the cloche: free hits
const SPAWN := Vector3(-5.6, 0, 3.4)
const RADIUS := .5
const STOP := 1.05
const REACH := 1.2
const JAB_TELE := .4

var game  ## porch.gd
var body: CharacterBody3D
var model  ## rig_actor.gd
var hp := HP
var state := "away"  ## away, stalk, jab_tele, plate, cards_tele, charge_tele, charge, dizzy, taunt, ko
var timer := 0.0
var cool := 0.0
var recovery := 0.0
var raged := false
var charge_next := false
var charge_dir := Vector3.FORWARD
var streak := 0         ## clean hits taken since the cloche last came down
var plate_rest := 0.0
var cloche: Node3D      ## up in front of his chest while he guards
var cards: Array = []   ## [Node3D, velocity, life] per flying review card

static func make(porch) -> Node:
	var foe = (load("res://foe_sendback.gd") as GDScript).new()
	foe.name = "SendsItBack"
	foe.game = porch
	porch.add_child(foe)
	foe.body = porch._actor(SPAWN, RADIUS)
	foe.model = RigActor.make(foe.body, "sendback", HEIGHT)
	foe.model.fit_head_bone()
	foe.body.hide()
	foe.body.collision_layer = 0
	foe.body.collision_mask = 0
	foe.cloche = foe.make_cloche()
	foe.cloche.hide()
	return foe

func arrive() -> void:
	game.player_hp = maxi(game.player_hp, game.PLAYER_HP)  # fresh fight
	state = "stalk"
	cool = 1.8
	streak = 0
	plate_rest = 0
	body.position = SPAWN
	body.show()
	body.collision_layer = game.ACTOR_LAYER
	body.collision_mask = game.WORLD_LAYER | game.ACTOR_LAYER
	game._say(body, "Excuse me. My delivery was left on the WRONG porch. It's cold. I'm sending it back. Through you.", 4.2)
	game.message.text = "Only a special breaks his cloche."
	if game.feel:
		game.feel.sfx("pickup", 0.0)
	game._update_hud()

func tick(delta: float) -> void:
	timer = maxf(0, timer - delta)
	cool = maxf(0, cool - delta)
	recovery = maxf(0, recovery - delta)
	plate_rest = maxf(0, plate_rest - delta)
	var offset: Vector3 = game.player.position - body.position
	offset.y = 0
	var distance: float = offset.length()
	var direction: Vector3 = offset.normalized()
	match state:
		"stalk":
			if direction != Vector3.ZERO:
				model.rotation.y = atan2(-direction.x, -direction.z)
			if distance <= REACH and recovery <= 0 and game._clear_strike(body, game.player):
				jab(JAB_TELE)
				return
			elif cool <= 0 and distance >= SPECIAL_RANGE and game.active:
				special(direction)
				return
			_walk(direction, RAGE_SPEED if raged else SPEED)
		"plate":
			if direction != Vector3.ZERO:
				model.rotation.y = atan2(-direction.x, -direction.z)
			_walk(direction, SPEED * .45)  # inches forward behind the cloche
			if timer <= 0:
				lower_plate()
		"jab_tele":
			game._move(body, Vector3.ZERO)
			model.move(0)
			if direction != Vector3.ZERO:
				model.rotation.y = atan2(-direction.x, -direction.z)
			if timer <= 0:
				state = "stalk"
				game._tell(null)
				recovery = .8 if raged else 1.1
				if distance <= REACH + .25 and game._clear_strike(body, game.player):
					game._hurt_duff(body.position)
		"cards_tele":
			game._move(body, Vector3.ZERO)
			if direction != Vector3.ZERO:
				model.rotation.y = atan2(-direction.x, -direction.z)
				charge_dir = direction  # the cards fly at where Duff is when they leave his hand
			if timer <= 0:
				throw_cards()
				state = "stalk"
				game._tell(null)
		"charge_tele":
			game._move(body, Vector3.ZERO)
			if timer <= 0:
				game._tell(null)
				state = "charge"
				timer = CHARGE_TIME
				model.locked = 0
				model.play("charge")
				model.player.speed_scale = 1.0
		"charge":
			if distance <= REACH and charge_dir.dot(direction) > .2:
				game._hurt_duff(body.position)
				dizzy(DIZZY)
				return
			game._move(body, charge_dir * CHARGE_SPEED)
			var bonked := false
			for i in body.get_slide_collision_count():
				var contact := body.get_slide_collision(i)
				var wall := contact.get_collider() as CollisionObject3D
				if wall and wall.collision_layer & game.WORLD_LAYER and absf(contact.get_normal().y) < .5:
					bonked = true
			if bonked or timer <= 0:
				dizzy(DIZZY)
		"dizzy", "taunt":
			game._move(body, Vector3.ZERO)
			if timer <= 0:
				state = "stalk"
				model.locked = 0
				if not raged and hp <= HP / 2:
					rage()  # he saved it for when he could stand up straight

func _walk(direction: Vector3, speed: float) -> void:
	var lane: Vector3 = game._side_spot(body, STOP) - body.position
	lane.y = 0
	var walking: bool = lane.length() > .12
	var heading: Vector3 = lane.normalized()
	if not game._clear_strike(body, game.player):
		heading = (direction + direction.cross(Vector3.UP)).normalized()  # step around the planter
	game._move(body, heading * speed if walking else Vector3.ZERO)
	if state == "plate":
		return  # the held pose stays; no walk clip behind the cloche
	var pace := Vector2(body.get_real_velocity().x, body.get_real_velocity().z).length()
	model.move(minf(pace / SPEED, 1.0) * .55)

## Up close: a back-hand swat, red ring first.
func jab(seconds: float) -> void:
	state = "jab_tele"
	timer = seconds
	model.strike("hook", seconds + .3)
	game._tell(body)

## Ranged turn: alternate the 1-star card spread and the charge, each with a readable wind-up.
func special(direction: Vector3) -> void:
	cool = SPECIAL_EVERY * (.75 if raged else 1.0)
	charge_dir = direction
	if game.feel:
		game.feel.sfx("tele", 0.0)
	game._tell(body)
	if charge_next:
		state = "charge_tele"
		timer = CHARGE_TELE
		model.strike("taunt", CHARGE_TELE)
		game._say(body, "I'm coming BACK there.")
	else:
		state = "cards_tele"
		timer = CARD_TELE
		model.strike("throw", CARD_TELE + .35)
		game._say(body, "This is TOO medium. One star.")
	charge_next = not charge_next

## Up goes the cloche: every punch and kick bounces off until it comes down or a special smashes it.
func raise_plate() -> void:
	state = "plate"
	timer = PLATE_TIME * (1.4 if raged else 1.0)
	streak = 0
	game._tell(null)
	cloche.show()
	model.strike("jab", .35)
	model.locked = timer + .1  # arm out, cloche up: hold the end of the jab
	game._say(body, "Sent BACK.", 1.4)
	if game.feel:
		game.feel.sfx("pickup", 0.0, -2.0)

func lower_plate() -> void:
	cloche.hide()
	plate_rest = PLATE_REST
	model.locked = 0
	if state == "plate":
		state = "stalk"

## A punch or kick on the cloche: a clang, and Duff bounces back.
func deflect() -> void:
	game._call("SENT BACK!")
	if game.feel:
		game.feel.sfx("bonk", .05, 2.0)
		game.feel.push(game.player, game.player.position - body.position, PLATE_SHOVE)

func guarding() -> bool:
	return state in ["plate", "taunt"]

## Return to Sender grabbed him mid-move: whatever he was doing stops (the cloche stays in his hand
## until the landing smashes it).
func cancel() -> void:
	if state in ["jab_tele", "cards_tele", "charge_tele", "charge", "taunt"]:
		state = "stalk"
	game._tell(null)

func dizzy(seconds: float) -> void:
	game._tell(null)
	state = "dizzy"
	timer = seconds
	model.strike("hit", seconds)

## `special`: the hit came from Red Right Hand or Return to Sender (it goes through the cloche).
func hit(damage: int, stun: float, special := false) -> void:
	var smashed := special and cloche.visible
	if smashed:
		damage += 1
	hp = maxi(0, hp - damage)
	game._show_impact(body.position)
	game._update_hud()
	if smashed:
		lower_plate()
		game._call("CLOCHE SMASHED!")
	if hp <= 0:
		game._tell(null)
		lower_plate()
		state = "ko"
		model.strike("ko")
		body.collision_layer = 0
		body.collision_mask = 0
		for card in cards:
			card[0].queue_free()
		cards.clear()
		game._say(body, "...This beating is cooked perfectly. Five stars. Still not tipping.", 3.0)
		game._porch_won("Refund denied. Porch secured.")
		return
	if special:
		dizzy(BROKEN)  # knocked silly, cloche or not: free hits
		if smashed:
			game._say(body, "My CLOCHE!", 1.4)
		return
	if state in ["charge", "jab_tele"]:
		return  # mid-charge and mid-swat he shrugs it off
	if state in ["cards_tele", "charge_tele"]:
		state = "stalk"  # hitting first knocks him out of his wind-up
		game._tell(null)
	if state == "dizzy":
		return  # free hits: no cloche (and no rage) while he's seeing stars
	if not raged and hp <= HP / 2:
		rage()
		return
	streak += 1
	if streak >= PLATE_AFTER and plate_rest <= 0:
		raise_plate()
		return
	if state == "stalk":
		model.locked = 0
		model.strike("hit", game.HIT_ANIM)
		recovery = maxf(recovery, stun)

func rage() -> void:
	raged = true
	state = "taunt"
	timer = 1.2
	model.strike("taunt", 1.2)
	game._say(body, "I want a refund. On this FIGHT.")

## A fan of 1-star review cards at Duff: step out of the spread or roll through it.
func throw_cards() -> void:
	var count := 5 if raged else 3
	for i in count:
		var angle := (i - (count - 1) * .5) * CARD_FAN * (.8 if raged else 1.0)
		var heading := charge_dir.rotated(Vector3.UP, angle)
		var card := make_card()
		card.position = body.position + Vector3.UP * 1.1 + heading * .5
		card.rotation = Vector3(-.65, atan2(-heading.x, -heading.z), 0)
		cards.append([card, heading * CARD_SPEED, 1.4])
	if game.feel:
		game.feel.sfx("whoosh")

func tick_cards(delta: float) -> void:
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for card in cards.duplicate():
		var node: Node3D = card[0]
		card[2] -= delta
		var step: Vector3 = card[1] * delta
		var ray := PhysicsRayQueryParameters3D.create(node.position, node.position + step, game.WORLD_LAYER)
		if card[2] <= 0 or not space.intersect_ray(ray).is_empty():
			_drop(card)
			continue
		node.position += step
		node.rotation.z = sin(card[2] * 16.0) * .4  # flutter
		var gap: Vector3 = node.position - game.player.position
		gap.y = 0
		if gap.length() <= CARD_RADIUS and game._hurt_duff(node.position):
			_drop(card)  # a rolled-through card keeps flying past him

func _drop(card: Array) -> void:
	cards.erase(card)
	card[0].queue_free()

## A small white review card: "1 STAR" in red on both faces.
func make_card() -> Node3D:
	var art := Art.Sculpture.new()
	art.box(Vector3.ZERO, Vector3(.36, .22, .02), Color("#f4efe4"))
	var board: Node3D = art.finish(game, "ReviewCard")
	for side in [-1.0, 1.0]:
		var text := Label3D.new()
		text.text = "1 STAR"
		text.font_size = 64
		text.outline_size = 0
		text.pixel_size = .0026
		text.modulate = Color("#c0392b")
		text.position = Vector3(0, 0, side * .012)
		text.rotation.y = 0.0 if side > 0 else PI
		board.add_child(text)
	return board

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
