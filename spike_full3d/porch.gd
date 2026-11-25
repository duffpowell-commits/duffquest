extends Node3D

const Art = preload("porch_art.gd")
const RigActor = preload("rig_actor.gd")
const Kit = preload("porch_kit.gd")
const Look = preload("porch_look.gd")
const FightCam = preload("porch_camera.gd")
const Feel = preload("porch_feel.gd")
const WORLD_LAYER := 1
const ACTOR_LAYER := 2
const PLANTER_AT := Vector3(1.66, 0, -.74)
const PLANTER_SIZE := Vector3(1.06, .62, .82)
const PLAYER_SPEED := 4.6
const PIRATE_SPEED := 2.1
const PLAYER_HP := 5
const PIRATE_HP := 5
const DUFF_HEIGHT := 1.7
const PIRATE_HEIGHT := 1.4
## Game time each one-shot clip is squeezed into (gameplay timing stays the same as the block-model slice).
const ATTACK_ANIM := .42
const DODGE_ANIM := .45
const HIT_ANIM := .4
const PIRATE_ATTACK_ANIM := .55
## Marketplace Mike (boss "mike" in scripts/boss.gd): walks in once the parcel is back. Easy on purpose.
## Melee jab up close; from range he "posts" you (throws his OBO sign) or charges ("Cash only!").
const MIKE_HEIGHT := 1.65
const MIKE_HP := 8
const MIKE_SPEED := 1.9
const MIKE_RAGE_SPEED := 2.5
const MIKE_SPECIAL_RANGE := 2.2  ## posting / charge only from at least this far
const MIKE_SPECIAL_EVERY := 2.6  ## seconds between specials (x .7 once he rages)
const POST_TELE := .7            ## wind-up before the sign leaves his hand: dodge then
const SIGN_SPEED := 6.5
const SIGN_RADIUS := .55
const CHARGE_TELE := .75
const CHARGE_SPEED := 7.2
const CHARGE_TIME := .85
const MIKE_DIZZY := 1.0          ## after a charge: free hits
const MIKE_SPAWN := Vector3(5.6, 0, 3.4)
## Body widths: fighters stay an arm's length apart instead of standing inside each other.
const DUFF_RADIUS := .42
const PIRATE_RADIUS := .42
const MIKE_RADIUS := .5
const PIRATE_STOP := 1.0     ## the pirate stops walking in at this distance
const PIRATE_REACH := 1.15   ## and jabs from here
const MIKE_STOP := 1.05
const MIKE_REACH := 1.2
## Real fight (Duff, Nov 25: "the pirate fights back harder", "Mike uses his sign and charge up close")
const PIRATE_TELE := .4       ## the pirate's wind-up before a jab: dodge it or hit him first
const PIRATE_REST := .9       ## after his jab
const MIKE_JAB_TELE := .38
const MIKE_SHOVE := 7.5       ## m/s: Mike's jab shoves Duff out to sign / charge range
const COUNTER_TELE := .18     ## a blocked hit gets this quick counter
const CHAIN_WINDOW := .9      ## hits closer together than this are one flurry
const GUARD_AFTER := 2        ## a foe blocks the hit after this many in a flurry, then counters

var player: CharacterBody3D
var pirate: CharacterBody3D
var player_model: RigActor
var pirate_model: RigActor
var mike: CharacterBody3D
var mike_model: RigActor
var mike_hp := MIKE_HP
var mike_state := "away"  ## away, stalk, post, charge_tele, charge, dizzy, taunt, ko
var mike_timer := 0.0
var mike_cool := 0.0
var mike_recovery := 0.0
var mike_raged := false
var charge_next := false
var charge_dir := Vector3.FORWARD
var obo_sign: Node3D
var sign_velocity := Vector3.ZERO
var sign_life := 0.0
var jab_next := true
var package: Node3D
var hit_marker: MeshInstance3D
var impact: MeshInstance3D
var impact_time := 0.0
var health: Label
var message: Label
var fps_label: Label
var look: Node  ## porch_look.gd (golden hour); null with --plain
var camera: Camera3D
var fight_cam  ## porch_camera.gd: frames Duff and his current foe
var feel  ## porch_feel.gd: sound, hit-stop, shake, knockback
var player_hp := PLAYER_HP
var pirate_hp := PIRATE_HP
var attack_time := 0.0
var dodge_time := 0.0
var dodge_recovery := 0.0
var pirate_recovery := 0.0
var invulnerable := 0.0
var facing := Vector3.FORWARD
var active := true
var dodge_requested := false
var attack_requested := false
var stick: Control             ## Godot 4.7's VirtualJoystick: drives ui_left/right/up/down
var bubble: PanelContainer     ## speech bubble over whoever is talking
var bubble_text: Label
var bubble_tail: Polygon2D
var bubble_from: Node3D
var bubble_time := 0.0
var clock := 0.0
var pirate_wind := 0.0        ## > 0 while the pirate winds up a jab
var chain := {}               ## foe -> [hits landed in this flurry, clock of the last]
var tell_ring: MeshInstance3D
var tell_foe: CharacterBody3D ## whose wind-up the red ring marks
var blocked := 0              ## hits a foe has blocked (for the bot and tests)

func _ready() -> void:
	_build_street()
	player = _actor(Vector3(-2, 0, 3), DUFF_RADIUS)
	pirate = _actor(Vector3(3, 0, -1), PIRATE_RADIUS)
	player_model = RigActor.make(player, "duff", DUFF_HEIGHT)
	pirate_model = RigActor.make(pirate, "pirate", PIRATE_HEIGHT)
	pirate_model.fit_head_bone()  # every head matches Duff's (Duff, Nov 25)
	package = Art.parcel(pirate_model, Vector3(0, .78, -.3))
	mike = _actor(MIKE_SPAWN, MIKE_RADIUS)
	mike_model = RigActor.make(mike, "mike", MIKE_HEIGHT)
	mike_model.fit_head_bone()
	mike.hide()
	mike.collision_layer = 0
	mike.collision_mask = 0
	obo_sign = _obo_sign()
	obo_sign.hide()
	hit_marker = _strike_arc(player_model)
	hit_marker.hide()
	var burst := Art.Sculpture.new()
	for ray in 7:
		var angle := ray * TAU / 7.0
		var offset := Vector3(cos(angle), sin(angle), 0)
		burst.form(offset * .25, Vector3(.22, .056, .045), Color("#ffca79"), Vector3(0, 0, angle), 6)
	impact = burst.finish(self, "Impact")
	impact.hide()
	tell_ring = _tell_ring()
	fight_cam.snap(player.position, current_foe())
	feel = Feel.make(self, camera)
	if not OS.get_cmdline_user_args().has("--plain"):
		look = Look.apply(self, [player_model, pirate_model, mike_model])
	_build_hud()
	_update_hud()

## The foe the camera keeps in frame: the pirate until he drops, then Mike once he is in.
func current_foe():
	if pirate_hp > 0:
		return pirate.position
	if mike.visible and mike_state != "ko":
		return mike.position
	return null

func _process(delta: float) -> void:
	_place_bubble(delta)
	tell_ring.visible = tell_foe != null and active
	if tell_ring.visible:
		tell_ring.position = tell_foe.position + Vector3.UP * .04
		tell_ring.scale = Vector3.ONE * (1.0 + .12 * sin(clock * 30.0))
	fight_cam.follow(delta, player.position, current_foe())
	fps_label.text = "%d FPS%s" % [Engine.get_frames_per_second(), " LITE" if look and look.lite else ""]

func _physics_process(delta: float) -> void:
	if not active:
		return
	clock += delta
	attack_time = maxf(0, attack_time - delta)
	impact_time = maxf(0, impact_time - delta)
	impact.visible = impact_time > 0.0
	impact.scale = Vector3.ONE * (1.15 - impact_time * 2.0)
	dodge_time = maxf(0, dodge_time - delta)
	dodge_recovery = maxf(0, dodge_recovery - delta)
	pirate_recovery = maxf(0, pirate_recovery - delta)
	mike_recovery = maxf(0, mike_recovery - delta)
	invulnerable = maxf(0, invulnerable - delta)
	var direction := _movement()
	if dodge_time <= 0 and direction != Vector3.ZERO:
		facing = direction.normalized()
		player_model.rotation.y = atan2(-direction.x, -direction.z)
	if dodge_requested:
		dodge_requested = false
		_dodge()
	if attack_requested:
		attack_requested = false
		_attack()
	hit_marker.visible = attack_time > .14
	var motion := facing * 8.8 if dodge_time > 0 else direction * PLAYER_SPEED
	_move(player, motion)
	var speed := Vector2(player.get_real_velocity().x, player.get_real_velocity().z).length()
	player_model.move(minf(speed / PLAYER_SPEED, 1.0))
	if pirate_hp > 0:
		_tick_pirate(delta)
	elif mike_state == "away":
		if player.position.distance_to(package.position) <= .85:
			_mike_arrives()
	elif mike_state != "ko":
		_tick_mike(delta)
	_tick_sign(delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		attack_requested = true
	elif event is InputEventKey:
		if event.physical_keycode == KEY_SHIFT:
			dodge_requested = true
		elif event.physical_keycode == KEY_R:
			_reset()

## Keys (WASD / arrows) or the on-screen stick, which presses the ui_* actions with analog strength.
func _movement() -> Vector3:
	var keys := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	# deadzone 0: the stick already applies its own (ui_* actions default to 0.5, which ate half the throw)
	var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", 0.0) + keys
	move = move.limit_length(1.0)
	if move.length() < .05:
		return Vector3.ZERO
	return Vector3(move.x, 0, move.y)

func _move(actor: CharacterBody3D, motion: Vector3) -> void:
	if feel:
		motion += feel.knock_of(actor)
	actor.velocity = Vector3(motion.x, -2, motion.z)
	actor.move_and_slide()

func _tick_pirate(delta := 1.0 / 60) -> void:
	var offset := player.position - pirate.position
	offset.y = 0
	var distance := offset.length()
	var direction := offset.normalized()
	if direction != Vector3.ZERO:
		pirate_model.rotation.y = atan2(-direction.x, -direction.z)
	if pirate_wind > 0:
		_move(pirate, Vector3.ZERO)
		pirate_model.move(0)
		pirate_wind -= delta
		if pirate_wind <= 0:
			_tell(null)
			pirate_recovery = PIRATE_REST
			if distance <= PIRATE_REACH + .25 and _clear_strike(pirate, player):
				_hurt_duff(pirate.position)
		return
	var lane := _side_spot(pirate, PIRATE_STOP) - pirate.position
	lane.y = 0
	_move(pirate, lane.normalized() * PIRATE_SPEED if lane.length() > .12 else Vector3.ZERO)
	var speed := Vector2(pirate.get_real_velocity().x, pirate.get_real_velocity().z).length()
	pirate_model.move(minf(speed / PIRATE_SPEED, 1.0) * .55)
	if distance <= PIRATE_REACH and pirate_recovery <= 0 and _clear_strike(pirate, player):
		_pirate_windup(PIRATE_TELE)

## The pirate draws back for a jab: the red ring and the slow start of the clip are the tell.
func _pirate_windup(seconds: float) -> void:
	pirate_wind = seconds
	pirate_model.strike("jab", seconds + .3)
	_tell(pirate)

## One point of damage unless Duff is in dodge / hit immunity. Returns true when it landed.
func _hurt_duff(from: Vector3) -> bool:
	if invulnerable > 0 or not active:
		return false
	player_hp -= 1
	_show_impact(player.position)
	if feel:
		feel.hurt(player, from)
	invulnerable = .45
	_update_hud()
	if player_hp <= 0:
		active = false
		hit_marker.hide()
		player_model.strike("ko")
		message.text = "Duff is down. Retry the encounter."
		bubble_time = 0
		if feel:
			feel.stop_music()
	else:
		player_model.strike("hit", HIT_ANIM)
	return true

func _attack() -> void:
	var foe := _foe()
	if not active or attack_time > 0 or foe == null or dodge_time > 0:
		return
	attack_time = .27
	player_model.strike("jab" if jab_next else "hook", ATTACK_ANIM)
	jab_next = not jab_next
	var offset := foe.position - player.position
	offset.y = 0
	if offset.length() > 1.75 or facing.dot(offset.normalized()) < .38 or not _clear_strike(player, foe):
		if feel:
			feel.sfx("swing")
		return
	if _guards(foe):
		_block(foe)
		return
	if feel:
		var ko := (foe == mike and mike_hp <= 1) or (foe == pirate and pirate_hp <= 1)
		feel.landed(foe, player.position, ko)
	if foe == mike:
		_hit_mike()
		return
	pirate_hp -= 1
	_show_impact(pirate.position)
	if pirate_hp > 0:
		pirate_recovery = maxf(pirate_recovery, HIT_ANIM)  # staggered: no new jab during the hit clip
		if pirate_wind <= 0:
			pirate_model.strike("hit", HIT_ANIM)
		# a wind-up has armour: hitting into it doesn't stop the jab. Dodge it, then punish.
	else:
		_tell(null)
	if pirate_hp == 0:
		var drop := pirate.position + Vector3.UP * .22
		package.reparent(self)
		package.position = drop
		package.rotation = Vector3(0, .25, 0)
		pirate_model.strike("ko")
		pirate.collision_layer = 0
		pirate.collision_mask = 0
		message.text = "Walk over to grab the parcel."
	_update_hud()

## Mashing gets read: the hit after GUARD_AFTER in one flurry is blocked. A dizzy Mike can't guard
## (that's the reward for dodging his charge); a taunting one blocks everything.
func _guards(foe: CharacterBody3D) -> bool:
	if foe == mike and mike_state in ["dizzy", "charge"]:
		return false
	if foe == mike and mike_state == "taunt":
		return true  # his price-drop rant is no opening
	var flurry: Array = chain.get(foe, [0, -99.0])
	if clock - flurry[1] > CHAIN_WINDOW:
		flurry = [0, clock]
	if flurry[0] >= (GUARD_AFTER - 1 if foe == mike and mike_raged else GUARD_AFTER):  # raged, he reads you faster
		chain.erase(foe)
		return true
	chain[foe] = [flurry[0] + 1, clock]
	return false

## A blocked hit: a dull bonk, a small shake, and the foe swings straight back.
func _block(foe: CharacterBody3D) -> void:
	blocked += 1
	_show_impact(foe.position)
	if feel:
		feel.sfx("bonk")
		feel.add_trauma(.15)
	if foe == pirate:
		pirate_recovery = 0
		_pirate_windup(COUNTER_TELE)
	else:
		_mike_jab(COUNTER_TELE)

## Who Duff's punches can land on right now.
func _foe() -> CharacterBody3D:
	if pirate_hp > 0:
		return pirate
	if mike_state not in ["away", "ko"]:
		return mike
	return null

func _mike_arrives() -> void:
	package.hide()  # Duff has it now
	player_hp = maxi(player_hp, PLAYER_HP)  # fresh fight; Mike is the easy first boss
	mike_state = "stalk"
	mike_cool = 1.6
	mike.position = MIKE_SPAWN
	mike.show()
	mike.collision_layer = ACTOR_LAYER
	mike.collision_mask = WORLD_LAYER | ACTOR_LAYER
	_say(mike, "That pirate was my best guy. Porch box goes for twelve bucks. Or best offer.", 4.0)
	message.text = "Marketplace Mike wants the parcel back."
	if feel:
		feel.sfx("pickup", 0.0)
		feel.play_music("mus_boss")
	_update_hud()

func _tick_mike(delta: float) -> void:
	mike_timer = maxf(0, mike_timer - delta)
	mike_cool = maxf(0, mike_cool - delta)
	var offset := player.position - mike.position
	offset.y = 0
	var distance := offset.length()
	var direction := offset.normalized()
	match mike_state:
		"stalk":
			if direction != Vector3.ZERO:
				mike_model.rotation.y = atan2(-direction.x, -direction.z)
			if distance <= MIKE_REACH and mike_recovery <= 0 and _clear_strike(mike, player):
				_mike_jab(MIKE_JAB_TELE)
				return
			elif mike_cool <= 0 and distance >= MIKE_SPECIAL_RANGE and active:
				_mike_special(direction)
			var speed := MIKE_RAGE_SPEED if mike_raged else MIKE_SPEED
			var lane := _side_spot(mike, MIKE_STOP) - mike.position
			lane.y = 0
			var walking := lane.length() > .12 and mike_state == "stalk"
			var heading := lane.normalized()
			if not _clear_strike(mike, player):
				heading = (direction + direction.cross(Vector3.UP)).normalized()  # step around the planter
			_move(mike, heading * speed if walking else Vector3.ZERO)
			var pace := Vector2(mike.get_real_velocity().x, mike.get_real_velocity().z).length()
			mike_model.move(minf(pace / MIKE_SPEED, 1.0) * .55)
		"jab_tele":
			_move(mike, Vector3.ZERO)
			mike_model.move(0)
			if direction != Vector3.ZERO:
				mike_model.rotation.y = atan2(-direction.x, -direction.z)
			if mike_timer <= 0:
				mike_state = "stalk"
				_tell(null)
				mike_recovery = .8 if mike_raged else 1.15
				if distance <= MIKE_REACH + .25 and _clear_strike(mike, player) and _hurt_duff(mike.position):
					if feel:  # the shove sends Duff out to where the sign and the charge reach him
						feel.push(player, player.position - mike.position, MIKE_SHOVE)
					mike_cool = minf(mike_cool, .35)
		"post":
			_move(mike, Vector3.ZERO)
			if direction != Vector3.ZERO:
				mike_model.rotation.y = atan2(-direction.x, -direction.z)
				charge_dir = direction  # the sign flies at where Duff is when it leaves his hand
			if mike_timer <= 0:
				_throw_sign()
				mike_state = "stalk"
				_tell(null)
		"charge_tele":
			_move(mike, Vector3.ZERO)
			if mike_timer <= 0:
				_tell(null)
				mike_state = "charge"
				mike_timer = CHARGE_TIME
				mike_model.locked = 0
				mike_model.play("charge")
				mike_model.player.speed_scale = 1.0
		"charge":
			if distance <= MIKE_REACH and charge_dir.dot(direction) > .2:
				_hurt_duff(mike.position)
				_mike_dizzy()
				return
			_move(mike, charge_dir * CHARGE_SPEED)
			var bonked := false
			for i in mike.get_slide_collision_count():
				var hit := mike.get_slide_collision(i)
				var body := hit.get_collider() as CollisionObject3D
				if body and body.collision_layer & WORLD_LAYER and absf(hit.get_normal().y) < .5:
					bonked = true
			if bonked or mike_timer <= 0:
				_mike_dizzy()
		"dizzy", "taunt":
			_move(mike, Vector3.ZERO)
			if mike_timer <= 0:
				mike_state = "stalk"
				mike_model.locked = 0

## Mike draws back for a shove: up close he pushes Duff out, then goes to the sign or the charge.
func _mike_jab(seconds: float) -> void:
	mike_state = "jab_tele"
	mike_timer = seconds
	mike_model.strike("jab", seconds + .3)
	_tell(mike)

## Ranged turn: alternate posting (sign throw) and the charge, each with a readable wind-up.
func _mike_special(direction: Vector3) -> void:
	mike_cool = MIKE_SPECIAL_EVERY * (.7 if mike_raged else 1.0)
	charge_dir = direction
	if feel:
		feel.sfx("tele", 0.0)
	_tell(mike)
	if charge_next:
		mike_state = "charge_tele"
		mike_timer = CHARGE_TELE
		mike_model.strike("taunt", CHARGE_TELE)
		_say(mike, "Cash only! No lowballers!")
	else:
		mike_state = "post"
		mike_timer = POST_TELE
		mike_model.strike("throw", POST_TELE + .35)
		_say(mike, "Listed: one Duff. Used. Fair condition.")
	charge_next = not charge_next

func _mike_dizzy() -> void:
	_tell(null)
	mike_state = "dizzy"
	mike_timer = MIKE_DIZZY
	mike_model.strike("hit", MIKE_DIZZY)

func _hit_mike() -> void:
	mike_hp -= 1
	_show_impact(mike.position)
	_update_hud()
	if mike_hp <= 0:
		_tell(null)
		mike_state = "ko"
		mike_model.strike("ko")
		mike.collision_layer = 0
		mike.collision_mask = 0
		obo_sign.hide()
		active = false
		hit_marker.hide()
		_say(mike, "Okay. Mark me as sold.")
		message.text = "Parcel recovered. Porch secured."
		if feel:
			feel.stop_music()
			feel.sfx("win", 0.0)
		return
	if mike_state == "charge":
		return  # mid-charge he shrugs it off
	if mike_state == "jab_tele":
		return  # his shove has armour too
	if mike_state in ["post", "charge_tele"]:
		mike_state = "stalk"  # hitting first knocks him out of his wind-up
		_tell(null)
	if not mike_raged and mike_hp <= MIKE_HP / 2:
		mike_raged = true
		mike_state = "taunt"
		mike_timer = 1.2
		mike_model.strike("taunt", 1.2)
		_say(mike, "Price drop! Everything must go! Starting with YOU!")
		return
	if mike_state == "stalk":
		mike_model.locked = 0
		mike_model.strike("hit", HIT_ANIM)
		mike_recovery = maxf(mike_recovery, HIT_ANIM)

func _throw_sign() -> void:
	obo_sign.position = mike.position + Vector3.UP * 1.05 + charge_dir * .5
	obo_sign.rotation = Vector3(-.65, 0, 0)  # face tipped toward the camera so "OBO" reads in flight
	sign_velocity = charge_dir * SIGN_SPEED
	sign_life = 1.4
	obo_sign.show()
	if feel:
		feel.sfx("whoosh")

func _tick_sign(delta: float) -> void:
	if not obo_sign.visible:
		return
	sign_life -= delta
	var step := sign_velocity * delta
	var ray := PhysicsRayQueryParameters3D.create(obo_sign.position, obo_sign.position + step, WORLD_LAYER)
	if sign_life <= 0 or not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		obo_sign.hide()
		return
	obo_sign.position += step
	obo_sign.rotation.z = sin(sign_life * 14.0) * .35  # tumbling wobble
	var gap := obo_sign.position - player.position
	gap.y = 0
	if gap.length() <= SIGN_RADIUS and _hurt_duff(obo_sign.position):
		obo_sign.hide()  # a dodged sign keeps flying past him

## Mike's OBO sign, readable from both sides.
func _obo_sign() -> Node3D:
	var art := Art.Sculpture.new()
	art.box(Vector3.ZERO, Vector3(.62, .3, .04), Color("#c9822f"))
	var board: Node3D = art.finish(self, "OboSign")
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

## Where a foe stands to fight: beside Duff on its own side, at arm's length, on his depth line,
## so the two face off left/right like a brawler and nobody hides the other from the camera.
func _side_spot(foe: CharacterBody3D, gap: float) -> Vector3:
	var side := signf(foe.position.x - player.position.x)
	if side == 0:
		side = 1.0
	var spot := player.position + Vector3(side * gap, 0, 0)
	if absf(spot.x) > 5.0:  # no room at the fence: take the other side
		spot = player.position - Vector3(side * gap, 0, 0)
	return spot

func _clear_strike(attacker: CharacterBody3D, target: CharacterBody3D) -> bool:
	var height := Vector3.UP * .50
	var ray := PhysicsRayQueryParameters3D.create(
		attacker.global_position + height, target.global_position + height, WORLD_LAYER
	)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _dodge() -> void:
	if active and dodge_recovery <= 0:
		dodge_time = .23
		player_model.strike("dodge", DODGE_ANIM)
		dodge_recovery = .65
		invulnerable = maxf(invulnerable, .27)
		if feel:
			feel.sfx("roll")

func _reset() -> void:
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		Input.action_release(action)  # a stick held through Retry would otherwise keep Duff walking
	get_tree().reload_current_scene()

func _actor(at: Vector3, radius := .34) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.collision_layer = ACTOR_LAYER
	actor.collision_mask = WORLD_LAYER | ACTOR_LAYER
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = 1.4
	collision.shape = shape
	collision.position.y = .7
	actor.add_child(collision)
	add_child(actor)
	actor.position = at
	return actor

## Red ring at a foe's feet while he winds up. null hides it.
func _tell(foe: CharacterBody3D) -> void:
	tell_foe = foe

func _tell_ring() -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = .5
	torus.outer_radius = .62
	torus.rings = 24
	torus.ring_segments = 4
	ring.mesh = torus
	ring.scale = Vector3(1, .05, 1)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color("#ff3b30")
	ring.material_override = glow
	ring.name = "TellRing"
	ring.hide()
	add_child(ring)
	return ring

func _show_impact(at: Vector3) -> void:
	impact.position = at + Vector3.UP * 1.03
	impact_time = .20
	impact.show()

func _strike_arc(parent: Node3D) -> MeshInstance3D:
	var art := Art.Sculpture.new()
	for segment in 12:
		var angle := lerpf(-.80, .80, segment / 11.0)
		var at := Vector3(sin(angle), 0, -cos(angle)) * .86
		at.y = .72
		var weight := sin(segment / 11.0 * PI)
		art.form(at, Vector3(.15, .025 + .07 * weight, .04), Color("#f5be77"), Vector3(0, -angle, .11), 8)
	return art.finish(parent, "StrikeArc")

func _collider(label: String, at: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = WORLD_LAYER
	body.collision_mask = ACTOR_LAYER
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var hit := CollisionShape3D.new()
	hit.shape = shape
	body.add_child(hit)
	add_child(body)
	body.position = at

func _build_street() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("#9c7475")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("#e9cbc0")
	world.environment.ambient_light_energy = .69
	# AgX keeps the Meshy textures' colour and the set's highlights from clipping (Compatibility supports it).
	world.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	world.environment.tonemap_exposure = 1.0
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-41, -36, 0)
	sun.light_color = Color("#ffdbb6")
	sun.light_energy = 1.02
	sun.shadow_enabled = true
	add_child(sun)
	camera = Camera3D.new()
	add_child(camera)
	camera.make_current()
	fight_cam = FightCam.new(camera)
	if OS.get_cmdline_user_args().has("--kit"):  # our own set, to compare with the Meshy one
		Kit.build(self, PLANTER_AT, PLANTER_SIZE)
		Art.ground(self)
	else:
		Art.meshy_set(self, PLANTER_AT, PLANTER_SIZE)
	var lamp := OmniLight3D.new()  # porch light by the door
	lamp.position = Vector3(0, 2.6, -2.9)
	lamp.light_color = Color("#ffb15e")
	lamp.light_energy = 1.4
	lamp.omni_range = 2.8
	add_child(lamp)
	_collider("Ground", Vector3(0, -.16, 0), Vector3(16, .32, 11))
	_collider("FrontageCollider", Vector3(0, 1.4, -4.85), Vector3(10.6, 2.8, 1.9))
	_collider("StoopCollider", Vector3(0, .119, -2.95), Vector3(2.84, .238, 1.03))
	_collider("StepCollider", Vector3(0, .066, -2.35), Vector3(2.92, .132, .22))
	for x in [-6.9, 6.9]:
		_collider("FenceCollider", Vector3(x, .65, 0), Vector3(.32, 1.3, 11))
	_collider("StreetLimit", Vector3(0, .6, 5.39), Vector3(15, 1.2, .23))
	_collider("RearLimit", Vector3(0, .7, -5.51), Vector3(15, 1.4, .25))
	_collider("PlanterCollider", PLANTER_AT + Vector3.UP * PLANTER_SIZE.y * .5, PLANTER_SIZE)
	for x in [-6.0, 6.0]:
		_collider("TrunkCollider", Vector3(x, .9, -4.2), Vector3(.5, 1.8, .5))
	_collider("MailboxCollider", Vector3(6.1, .62, 2.45), Vector3(.42, 1.25, .5))

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := _hud_label(layer, Vector2(22, 13), 23, Color("#ffcf97"))
	title.text = "DUFF QUEST"
	health = _hud_label(layer, Vector2(22, 47), 16, Color.WHITE)
	message = _hud_label(layer, Vector2(22, 73), 16, Color("#ffe7ca"))
	message.text = "Stop the Porch Pirate and recover the parcel."
	fps_label = _hud_label(layer, Vector2(800, 22), 14, Color("#eddbd0"))
	var hint := _hud_label(layer, Vector2(22, 512), 14, Color("#eddbd0"))
	hint.text = "WASD / arrows  ·  Space to hit  ·  Shift to dodge  ·  R to retry"
	hint.visible = not DisplayServer.is_touchscreen_available()  # no small print on a phone
	stick = _stick(layer)
	_button(layer, "HIT", Vector2(806, 392), "attack", 128)
	_button(layer, "DODGE", Vector2(690, 300), "dodge", 96)
	_button(layer, "Retry", Vector2(884, 15), "reset", 0)
	_build_bubble(layer)

## Left half of the screen: the stick appears where the thumb lands (4.7 VirtualJoystick, dynamic).
func _stick(layer: CanvasLayer) -> Control:
	var pad := VirtualJoystick.new()
	pad.name = "Stick"
	pad.position = Vector2(0, 150)
	pad.size = Vector2(440, 390)
	pad.joystick_mode = VirtualJoystick.JOYSTICK_DYNAMIC
	pad.joystick_size = 150.0
	pad.tip_size = 66.0
	pad.deadzone_ratio = .15
	pad.initial_offset_ratio = Vector2(.3, .6)
	pad.action_left = &"ui_left"
	pad.action_right = &"ui_right"
	pad.action_up = &"ui_up"
	pad.action_down = &"ui_down"
	layer.add_child(pad)
	return pad

func _hud_label(layer: CanvasLayer, at: Vector2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_shadow_color", Color("#25191e"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)
	return label

## A round thumb button (size 0 = the small square Retry).
func _button(layer: CanvasLayer, caption: String, at: Vector2, action: String, size := 0) -> void:
	var button := TouchScreenButton.new()
	button.name = action.capitalize()
	button.position = at
	var box := Vector2(54, 50) if size == 0 else Vector2(size, size)
	var bounds := RectangleShape2D.new()
	bounds.size = box
	button.shape = bounds
	button.shape_centered = false
	layer.add_child(button)
	var panel := Panel.new()
	panel.size = box
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#211b29d9") if size == 0 else (Color("#b8432fd0") if action == "attack" else Color("#2f6f8ad0"))
	style.border_color = Color("#edb178a0") if size == 0 else Color("#ffe5c3c0")
	style.set_border_width_all(1 if size == 0 else 3)
	style.set_corner_radius_all(10 if size == 0 else size / 2)
	style.anti_aliasing = true
	panel.add_theme_stylebox_override("panel", style)
	button.add_child(panel)
	var label := Label.new()
	label.size = box
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = caption
	label.add_theme_font_size_override("font_size", 16 if size == 0 else size / 5)
	label.add_theme_color_override("font_color", Color("#fff3e2"))
	panel.add_child(label)
	button.pressed.connect(func() -> void: panel.modulate = Color("#ffd59e"))
	button.released.connect(func() -> void: panel.modulate = Color.WHITE)
	match action:
		"attack": button.pressed.connect(func() -> void: attack_requested = true)
		"dodge": button.pressed.connect(func() -> void: dodge_requested = true)
		"reset": button.released.connect(_reset)

## Comic speech bubble that floats over the speaker's head.
func _build_bubble(layer: CanvasLayer) -> void:
	bubble = PanelContainer.new()
	bubble.name = "Bubble"
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff8ec")
	style.border_color = Color("#2a1d18")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	bubble.add_theme_stylebox_override("panel", style)
	bubble_text = Label.new()
	bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_text.custom_minimum_size = Vector2(300, 0)
	bubble_text.add_theme_font_size_override("font_size", 19)
	bubble_text.add_theme_color_override("font_color", Color("#2a1d18"))
	bubble.add_child(bubble_text)
	bubble_tail = Polygon2D.new()
	bubble_tail.polygon = PackedVector2Array([Vector2(-12, -3), Vector2(12, -3), Vector2(0, 18)])
	bubble_tail.color = Color("#2a1d18")
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([Vector2(-8, -5), Vector2(8, -5), Vector2(0, 12)])
	inner.color = Color("#fff8ec")
	bubble_tail.add_child(inner)
	layer.add_child(bubble_tail)
	layer.add_child(bubble)
	bubble.hide()
	bubble_tail.hide()

func _say(speaker: Node3D, line: String, seconds := 2.8) -> void:
	bubble_from = speaker
	bubble_text.text = line
	bubble_time = seconds
	bubble.size = Vector2.ZERO  # shrink to the new line
	_place_bubble(0.0)

func _place_bubble(delta: float) -> void:
	bubble_time = maxf(0, bubble_time - delta)
	var showing := bubble_time > 0 and bubble_from != null and camera != null \
		and not camera.is_position_behind(bubble_from.global_position)
	bubble.visible = showing
	bubble_tail.visible = showing
	if not showing:
		return
	var head := camera.unproject_position(bubble_from.global_position + Vector3.UP * 1.95)
	var view := get_viewport().get_visible_rect().size
	if not Rect2(Vector2.ZERO, view).has_point(head):  # speaker off screen: wait until he walks in
		bubble.hide()
		bubble_tail.hide()
		return
	var box := bubble.get_combined_minimum_size()
	var at := Vector2(head.x - box.x * .5, head.y - box.y - 18)
	if at.y >= 8:  # room above the head: tail points down at him
		at.x = clampf(at.x, 12, view.x - box.x - 12)
		bubble.position = at
		bubble_tail.rotation = 0
		bubble_tail.position = Vector2(clampf(head.x, at.x + 20, at.x + box.x - 20), at.y + box.y - 2)
		return
	# no room (the camera keeps heads high): sit beside his head, tail pointing at it
	var right := head.x + 40 + box.x <= view.x - 12
	at = Vector2(head.x + 40 if right else head.x - 40 - box.x, clampf(head.y - box.y * .5, 8, view.y - box.y - 12))
	bubble.position = at
	bubble_tail.rotation = PI / 2 if right else -PI / 2
	bubble_tail.position = Vector2(at.x + 2 if right else at.x + box.x - 2, clampf(head.y, at.y + 16, at.y + box.y - 16))

func _update_hud() -> void:
	if mike_state == "away":
		health.text = "DUFF %d/%d   ·   PIRATE %d/%d" % [player_hp, PLAYER_HP, pirate_hp, PIRATE_HP]
	else:
		health.text = "DUFF %d/%d   ·   MARKETPLACE MIKE %d/%d" % [player_hp, PLAYER_HP, maxi(mike_hp, 0), MIKE_HP]
