extends Node
## Marketplace Mike (boss "mike" in the main game's scripts/boss.gd): walks in once the parcel is back.
## Easy on purpose. Melee jab up close; from range he "posts" you (throws his OBO sign) or charges
## ("Cash only!"). At half health he rages. First boss moved out of porch.gd (Nov 25, 2026): the
## pattern for every new foe is a script like this one, made by porch.gd and ticked from its physics loop.
## `game` is porch.gd: the shared fight services (Duff, _hurt_duff, _move, _tell, _say, feel, HUD).

const Art = preload("porch_art.gd")
const RigActor = preload("rig_actor.gd")
const HEIGHT := 1.65
const HP := 8
const SPEED := 1.9
const RAGE_SPEED := 2.5
const SPECIAL_RANGE := 2.2  ## posting / charge only from at least this far
const SPECIAL_EVERY := 2.6  ## seconds between specials (x .7 once he rages)
const POST_TELE := .7       ## wind-up before the sign leaves his hand: dodge then
const SIGN_SPEED := 6.5
const SIGN_RADIUS := .55
const CHARGE_TELE := .75
const CHARGE_SPEED := 7.2
const CHARGE_TIME := .85
const DIZZY := 1.0          ## after a charge: free hits
const SPAWN := Vector3(5.6, 0, 3.4)
const RADIUS := .5          ## body width: fighters stay an arm's length apart
const STOP := 1.05          ## stops walking in at this distance
const REACH := 1.2          ## and jabs from here
const JAB_TELE := .38
const SHOVE := 7.5          ## m/s: his jab shoves Duff out to sign / charge range

var game  ## porch.gd
var body: CharacterBody3D
var model  ## rig_actor.gd
var hp := HP
var state := "away"  ## away, stalk, jab_tele, post, charge_tele, charge, dizzy, taunt, ko
var timer := 0.0
var cool := 0.0
var recovery := 0.0
var raged := false
var charge_next := false
var charge_dir := Vector3.FORWARD
var obo_sign: Node3D
var sign_velocity := Vector3.ZERO
var sign_life := 0.0

static func make(porch) -> Node:
	var foe = (load("res://foe_mike.gd") as GDScript).new()
	foe.name = "Mike"
	foe.game = porch
	porch.add_child(foe)
	foe.body = porch._actor(SPAWN, RADIUS)
	foe.model = RigActor.make(foe.body, "mike", HEIGHT)
	foe.model.fit_head_bone()  # every head matches Duff's (Duff, Nov 25)
	foe.body.hide()
	foe.body.collision_layer = 0
	foe.body.collision_mask = 0
	foe.obo_sign = foe.make_sign()
	foe.obo_sign.hide()
	return foe

func arrive() -> void:
	game.package.hide()  # Duff has it now
	game.player_hp = maxi(game.player_hp, game.PLAYER_HP)  # fresh fight; Mike is the easy first boss
	state = "stalk"
	cool = 1.6
	body.position = SPAWN
	body.show()
	body.collision_layer = game.ACTOR_LAYER
	body.collision_mask = game.WORLD_LAYER | game.ACTOR_LAYER
	game._say(body, "That pirate was my best guy. Porch box goes for twelve bucks. Or best offer.", 4.0)
	game.message.text = "Marketplace Mike wants the parcel back."
	if game.feel:
		game.feel.sfx("pickup", 0.0)
		game.feel.play_music("mus_boss")
	game._update_hud()

func tick(delta: float) -> void:
	timer = maxf(0, timer - delta)
	cool = maxf(0, cool - delta)
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
			var speed := RAGE_SPEED if raged else SPEED
			var lane: Vector3 = game._side_spot(body, STOP) - body.position
			lane.y = 0
			var walking: bool = lane.length() > .12 and state == "stalk"
			var heading: Vector3 = lane.normalized()
			if not game._clear_strike(body, game.player):
				heading = (direction + direction.cross(Vector3.UP)).normalized()  # step around the planter
			game._move(body, heading * speed if walking else Vector3.ZERO)
			var pace := Vector2(body.get_real_velocity().x, body.get_real_velocity().z).length()
			model.move(minf(pace / SPEED, 1.0) * .55)
		"jab_tele":
			game._move(body, Vector3.ZERO)
			model.move(0)
			if direction != Vector3.ZERO:
				model.rotation.y = atan2(-direction.x, -direction.z)
			if timer <= 0:
				state = "stalk"
				game._tell(null)
				recovery = .8 if raged else 1.15
				if distance <= REACH + .25 and game._clear_strike(body, game.player) and game._hurt_duff(body.position):
					if game.feel:  # the shove sends Duff out to where the sign and the charge reach him
						game.feel.push(game.player, game.player.position - body.position, SHOVE)
					cool = minf(cool, .35)
		"post":
			game._move(body, Vector3.ZERO)
			if direction != Vector3.ZERO:
				model.rotation.y = atan2(-direction.x, -direction.z)
				charge_dir = direction  # the sign flies at where Duff is when it leaves his hand
			if timer <= 0:
				throw_sign()
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
				dizzy()
				return
			game._move(body, charge_dir * CHARGE_SPEED)
			var bonked := false
			for i in body.get_slide_collision_count():
				var contact := body.get_slide_collision(i)
				var wall := contact.get_collider() as CollisionObject3D
				if wall and wall.collision_layer & game.WORLD_LAYER and absf(contact.get_normal().y) < .5:
					bonked = true
			if bonked or timer <= 0:
				dizzy()
		"dizzy", "taunt":
			game._move(body, Vector3.ZERO)
			if timer <= 0:
				state = "stalk"
				model.locked = 0

## Mike draws back for a shove: up close he pushes Duff out, then goes to the sign or the charge.
func jab(seconds: float) -> void:
	state = "jab_tele"
	timer = seconds
	model.strike("jab", seconds + .3)
	game._tell(body)

## Ranged turn: alternate posting (sign throw) and the charge, each with a readable wind-up.
func special(direction: Vector3) -> void:
	cool = SPECIAL_EVERY * (.7 if raged else 1.0)
	charge_dir = direction
	if game.feel:
		game.feel.sfx("tele", 0.0)
	game._tell(body)
	if charge_next:
		state = "charge_tele"
		timer = CHARGE_TELE
		model.strike("taunt", CHARGE_TELE)
		game._say(body, "Cash only! No lowballers!")
	else:
		state = "post"
		timer = POST_TELE
		model.strike("throw", POST_TELE + .35)
		game._say(body, "Listed: one Duff. Used. Fair condition.")
	charge_next = not charge_next

func dizzy() -> void:
	game._tell(null)
	state = "dizzy"
	timer = DIZZY
	model.strike("hit", DIZZY)

func hit(damage := 1) -> void:
	hp -= damage
	game._show_impact(body.position)
	game._update_hud()
	if hp <= 0:
		game._tell(null)
		state = "ko"
		model.strike("ko")
		body.collision_layer = 0
		body.collision_mask = 0
		obo_sign.hide()
		game._say(body, "Okay. Mark me as sold.")
		game._mike_sold()
		return
	if state == "charge":
		return  # mid-charge he shrugs it off
	if state == "jab_tele":
		return  # his shove has armour too
	if state in ["post", "charge_tele"]:
		state = "stalk"  # hitting first knocks him out of his wind-up
		game._tell(null)
	if not raged and hp <= HP / 2:
		raged = true
		state = "taunt"
		timer = 1.2
		model.strike("taunt", 1.2)
		game._say(body, "Price drop! Everything must go! Starting with YOU!")
		return
	if state == "stalk":
		model.locked = 0
		model.strike("hit", game.HIT_ANIM)
		recovery = maxf(recovery, game.HIT_ANIM)

func throw_sign() -> void:
	obo_sign.position = body.position + Vector3.UP * 1.05 + charge_dir * .5
	obo_sign.rotation = Vector3(-.65, 0, 0)  # face tipped toward the camera so "OBO" reads in flight
	sign_velocity = charge_dir * SIGN_SPEED
	sign_life = 1.4
	obo_sign.show()
	if game.feel:
		game.feel.sfx("whoosh")

func tick_sign(delta: float) -> void:
	if not obo_sign.visible:
		return
	sign_life -= delta
	var step := sign_velocity * delta
	var ray := PhysicsRayQueryParameters3D.create(obo_sign.position, obo_sign.position + step, game.WORLD_LAYER)
	if sign_life <= 0 or not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		obo_sign.hide()
		return
	obo_sign.position += step
	obo_sign.rotation.z = sin(sign_life * 14.0) * .35  # tumbling wobble
	var gap: Vector3 = obo_sign.position - game.player.position
	gap.y = 0
	if gap.length() <= SIGN_RADIUS and game._hurt_duff(obo_sign.position):
		obo_sign.hide()  # a dodged sign keeps flying past him

## Mike's OBO sign, readable from both sides.
func make_sign() -> Node3D:
	var art := Art.Sculpture.new()
	art.box(Vector3.ZERO, Vector3(.62, .3, .04), Color("#c9822f"))
	var board: Node3D = art.finish(game, "OboSign")
	for side in [-1.0, 1.0]:
		var text := Label3D.new()
		text.text = "OBO"
		text.font_size = 72
		text.outline_size = 0
		text.pixel_size = .0032
		text.modulate = Color("#3a2414")
		text.position = Vector3(0, 0, side * .023)
		text.rotation.y = 0.0 if side > 0 else PI
		board.add_child(text)
	return board
