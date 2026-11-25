extends Node
## The Porch Pirate: walks in beside Duff and jabs after a short red-ring wind-up. The tutorial foe.
## Same pattern as foe_mike.gd: made by porch.gd, ticked from its physics loop; `game` = porch.gd.

const Art = preload("porch_art.gd")
const RigActor = preload("rig_actor.gd")
const HP := 5
const HEIGHT := 1.4
const SPEED := 2.1
const RADIUS := .42
const STOP := 1.0     ## stops walking in at this distance
const REACH := 1.15   ## and jabs from here
const TELE := .4      ## wind-up before a jab: dodge it or hit him first
const REST := .9      ## after his jab
const SPAWN := Vector3(3, 0, -1)

var game  ## porch.gd
var body: CharacterBody3D
var model  ## rig_actor.gd
var hp := HP
var recovery := 0.0
var wind := 0.0       ## > 0 while he winds up a jab

static func make(porch) -> Node:
	var foe = (load("res://foe_pirate.gd") as GDScript).new()
	foe.name = "Pirate"
	foe.game = porch
	porch.add_child(foe)
	foe.body = porch._actor(SPAWN, RADIUS)
	foe.model = RigActor.make(foe.body, "pirate", HEIGHT)
	foe.model.fit_head_bone()  # every head matches Duff's (Duff, Nov 25)
	return foe

func tick(delta := 1.0 / 60) -> void:
	var offset: Vector3 = game.player.position - body.position
	offset.y = 0
	var distance := offset.length()
	var direction := offset.normalized()
	if direction != Vector3.ZERO:
		model.rotation.y = atan2(-direction.x, -direction.z)
	if wind > 0:
		game._move(body, Vector3.ZERO)
		model.move(0)
		wind -= delta
		if wind <= 0:
			game._tell(null)
			recovery = REST
			if distance <= REACH + .25 and game._clear_strike(body, game.player):
				game._hurt_duff(body.position)
		return
	var lane: Vector3 = game._side_spot(body, STOP) - body.position
	lane.y = 0
	game._move(body, lane.normalized() * SPEED if lane.length() > .12 else Vector3.ZERO)
	var speed := Vector2(body.get_real_velocity().x, body.get_real_velocity().z).length()
	model.move(minf(speed / SPEED, 1.0) * .55)
	if distance <= REACH and recovery <= 0 and game._clear_strike(body, game.player):
		windup(TELE)

## He draws back for a jab: the red ring and the slow start of the clip are the tell.
func windup(seconds: float) -> void:
	wind = seconds
	model.strike("jab", seconds + .3)
	game._tell(body)

## Duff's hit lands: stagger, or the KO that drops the parcel.
func hit(damage: int, stun: float) -> void:
	hp = maxi(hp - damage, 0)
	game._show_impact(body.position)
	if hp > 0:
		recovery = maxf(recovery, stun)
		if wind <= 0:
			model.strike("hit", game.HIT_ANIM)
	else:
		game._tell(null)
		var drop := body.position + Vector3.UP * .22
		game.package.reparent(game)
		game.package.position = drop
		game.package.rotation = Vector3(0, .25, 0)
		model.strike("ko")
		body.collision_layer = 0
		body.collision_mask = 0
		game.message.text = "Walk over to grab the parcel."
	game._update_hud()
