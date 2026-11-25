extends Node3D

const Art = preload("porch_art.gd")
const RigActor = preload("rig_actor.gd")
const Kit = preload("porch_kit.gd")
const Look = preload("porch_look.gd")
const FightCam = preload("porch_camera.gd")
const Feel = preload("porch_feel.gd")
const Hud = preload("porch_hud.gd")
const FoeMike = preload("foe_mike.gd")
const FoePirate = preload("foe_pirate.gd")
const FoeSendback = preload("foe_sendback.gd")
const Zones = preload("porch_zones.gd")
const WORLD_LAYER := 1
const ACTOR_LAYER := 2
const PLANTER_AT := Vector3(1.66, 0, -.74)
const PLANTER_SIZE := Vector3(1.06, .62, .82)
const PLAYER_SPEED := 4.6
const PIRATE_SPEED := FoePirate.SPEED
const PLAYER_HP := 5
const PIRATE_HP := FoePirate.HP
const DUFF_HEIGHT := 1.7
const PIRATE_HEIGHT := FoePirate.HEIGHT
## Game time each one-shot clip is squeezed into (gameplay timing stays the same as the block-model slice).
const ATTACK_ANIM := .42
const DODGE_ANIM := .45
const HIT_ANIM := .4
const PIRATE_ATTACK_ANIM := .55
## Marketplace Mike lives in foe_mike.gd. These names stay for the tests and tools (old spelling).
const MIKE_HEIGHT := FoeMike.HEIGHT
const MIKE_HP := FoeMike.HP
const POST_TELE := FoeMike.POST_TELE
const CHARGE_TELE := FoeMike.CHARGE_TELE
const MIKE_SPAWN := FoeMike.SPAWN
const MIKE_JAB_TELE := FoeMike.JAB_TELE
## Body widths: fighters stay an arm's length apart instead of standing inside each other.
const DUFF_RADIUS := .42
const PIRATE_REACH := FoePirate.REACH
## Real fight (Duff, Nov 25: "the pirate fights back harder", "Mike uses his sign and charge up close")
const PIRATE_TELE := FoePirate.TELE
const COUNTER_TELE := .18     ## a blocked hit gets this quick counter
const CHAIN_WINDOW := .9      ## hits closer together than this are one flurry
const GUARD_AFTER := 2        ## a foe blocks the hit after this many in a flurry, then counters
const COMBO_GAP := .7         ## combos: press again within this after a hit lands, never mid-swing
const FINISHER_KNOCK := 2.4   ## the third hit in rhythm knocks the foe this many times further
const FINISHER_STUN := .9     ## and leaves him unable to swing for this long
const DASH_WINDOW := .55      ## roll, then A within this: a dash hook
const DASH_REACH := 2.6
const DASH_SPEED := 9.0
const KICK_ANIM := .55        ## K: the push kick. Slower than a punch, longer reach, shoves him back
const KICK_LOCK := .42        ## no other swing until the kick is out
const KICK_REACH := 2.05
const KICK_COOL := .9          ## seconds between kicks: going through a guard has a price
const KICK_KNOCK := 2.2       ## times a punch's shove
const LAUNCH_KNOCK := 3.4     ## A A K: the kick ends the combo as a launcher
const WALL_TIME := .5         ## a launched foe that hits a wall, fence or planter within this takes 1 more
const METER_HIT := 14         ## special meter (0..100): per landed hit
const METER_HURT := 10        ## and per hit Duff takes
const RRH_WINDUP := .9        ## Red Right Hand: feet planted, the fist catches fire
const RRH_DASH := .4          ## then he rockets forward fist first for this long
const RRH_SPEED := 10.0       ## m/s: about 4 m of porch
const RRH_RECOVER := .45      ## a whiff leaves him skidding, wide open
const RRH_TIME := RRH_WINDUP + RRH_DASH + RRH_RECOVER
const RRH_HIT_RADIUS := 1.05  ## the fist connects with anyone this close along the dash
const RRH_DAMAGE := 3
const RRH_KNOCK := 4.0        ## times a punch's shove
const RRH_PEAK := .76  ## fist fully out in the burn clip (tools/bake_burn.gd: .95 s of 1.25)
const RRH_CLIP := "burn"       ## Duff's right straight with a big coil (tools/bake_burn.gd)
## Return to Sender: R with the foe up close grabs him and throws him over Duff's shoulder (Meshy Over
## Shoulder Throw, Duff's pick Nov 25; tools/bake_toss.gd). Times are in the toss clip's seconds.
const RTS_CLIP := "toss"
const RTS_RANGE := 1.45       ## the foe this close: R grabs instead of dashing
const RTS_SPEED := 2.0        ## the clip plays this much faster than Meshy's
const RTS_GRAB := .5          ## hands close on him
const RTS_RELEASE := 2.2      ## thrown over the shoulder
const RTS_FLY := .55          ## real seconds in the air
const RTS_FLYUP_LAND := .9    ## seconds into the foe's flyup clip where he hits the ground flat (tools/bake_victim.gd)
const RTS_THROW := 3.2        ## m from Duff where he lands (Duff: "Bigger throw")
const RTS_ARC := 1.4          ## m the arc peaks above the straight line
const RTS_DAMAGE := 3
## Win grade (replay hook): 100 minus hits taken and time over par, plus specials landed.
const PAR_TIME := 130.0        ## fight seconds before the clock starts costing points
const GRADE_HIT := 8.0         ## points per hit Duff takes
const GRADE_SLOW := .4         ## points per second over par
const GRADE_SPECIAL := 6.0     ## points per special landed (up to 3)
const GRADES := [[95.0, "S"], [80.0, "A"], [65.0, "B"], [50.0, "C"], [-INF, "D"]]
const BEST_PATH := "user://porch_best.cfg"
const STOOP_AT := Vector3(0, .19, -2.32)  ## the bottom step: where a thrown pirate's parcel lands
const CALLOUT_TIME := .75     ## real seconds a combo callout stays up
const PERFECT_WINDOW := .6    ## dodge through a hit, then K within this: counter kick in slow motion

var player: CharacterBody3D
var thief  ## foe_pirate.gd: the Porch Pirate. The names below read and write his state (old spelling).
var pirate: CharacterBody3D:
	get: return thief.body
var player_model: RigActor
var pirate_model: RigActor:
	get: return thief.model
var boss  ## foe_mike.gd: Marketplace Mike. The names below read and write his state (old spelling).
var mike: CharacterBody3D:
	get: return boss.body
var mike_model: RigActor:
	get: return boss.model
var mike_hp: int:
	get: return boss.hp
	set(v): boss.hp = v
var mike_state: String:
	get: return boss.state
	set(v): boss.state = v
var mike_timer: float:
	get: return boss.timer
	set(v): boss.timer = v
var mike_cool: float:
	get: return boss.cool
	set(v): boss.cool = v
var mike_recovery: float:
	get: return boss.recovery
	set(v): boss.recovery = v
var mike_raged: bool:
	get: return boss.raged
	set(v): boss.raged = v
var charge_next: bool:
	get: return boss.charge_next
	set(v): boss.charge_next = v
var charge_dir: Vector3:
	get: return boss.charge_dir
	set(v): boss.charge_dir = v
var obo_sign: Node3D:
	get: return boss.obo_sign
var rival  ## foe_sendback.gd: Sir Sends-It-Back, the third fight (after Mike)
var special_strike := false  ## true only while Red Right Hand / Return to Sender deal their hit
var rival_in := -1.0  ## seconds until he walks in once Mike is sold
var sendback: CharacterBody3D:
	get: return rival.body
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
var pirate_hp: int:
	get: return thief.hp
	set(v): thief.hp = v
var attack_time := 0.0
var dodge_time := 0.0
var dodge_recovery := 0.0
var pirate_recovery: float:
	get: return thief.recovery
	set(v): thief.recovery = v
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
var pirate_wind: float:
	get: return thief.wind
	set(v): thief.wind = v
var chain := {}               ## foe -> [hits landed in this flurry, clock of the last]
var tell_ring: MeshInstance3D
var tell_foe: CharacterBody3D ## whose wind-up the red ring marks
var blocked := 0              ## hits a foe has blocked (for the bot and tests)
var hud: Control              ## porch_hud.gd: the main game's HUD and menus
var cash := 40                ## Duff's cash pill on the status strip
var bubble_name: Label        ## pink name tag on the speech bubble
var end_in := 0.0             ## counts down to the KO / win screen
var end_won := false
var opening := 0.0            ## the pirate answers Duff this long after the fight starts
var combo := 0                ## hits landed in rhythm (resets on a miss, a block, or a mashed press)
var combo_at := -99.0         ## clock of the last combo hit
var combo_broken := false     ## A was pressed mid-swing: that's mashing, the next hit starts over
var last_dodge := -99.0
var launched := {}            ## foe -> seconds left in which a wall hit hurts
var wall_hits := 0             ## launched foes that hit a wall (for tests)
var perfect_at := -99.0       ## clock of the last dodge that slipped a hit
var kick_requested := false
var kick_cool := 0.0
var meter := 0.0              ## fills on hits landed and taken; full = Red Right Hand
var special_time := 0.0       ## > 0 while Red Right Hand plays
var special_hit := false
var special_requested := false
var rrh_glow: OmniLight3D
var rrh_trail: MeshInstance3D
var rrh_fire: CPUParticles3D
var rrh_points: Array[Vector3] = []
var toss_foe: CharacterBody3D  ## held / in the air during Return to Sender
var toss_t := 0.0             ## seconds into the toss clip
var toss_from := Vector3.ZERO
var toss_land := Vector3.ZERO
var toss_fly := -1.0          ## seconds in the air (-1 = not thrown yet)
var tosses := 0               ## landed throws (for tests)
var hits_taken := 0
var specials_landed := 0
var result := {}              ## the win card's grade, time and best (set when Mike goes down)
var meter_rang := false       ## the full-meter chime played for this fill
var callout := ""             ## "2 HIT", "KNOCKDOWN!", "DASH HOOK!" for the HUD
var callout_time := 0.0
var zones  ## porch_zones.gd: the porch, the apartment, the doors between
var exploring := false        ## walking around with nobody to fight (after the porch is secured)

func _ready() -> void:
	_build_street()
	player = _actor(Vector3(-2, 0, 3), DUFF_RADIUS)
	player_model = RigActor.make(player, "duff", DUFF_HEIGHT)
	thief = FoePirate.make(self)
	package = Art.parcel(pirate_model, Vector3(0, .78, -.3))
	boss = FoeMike.make(self)
	rival = FoeSendback.make(self)
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
		look = Look.apply(self, [player_model, pirate_model, mike_model, rival.model])
	_build_hud()
	_update_hud()
	if OS.get_cmdline_user_args().has("--zone=apartment"):  # start at home, nobody to fight
		_start_exploring()
		zones.arrive("apartment", Vector3(-1.0, 0, .4))
		return
	var wants_title := OS.has_feature("template") or OS.get_cmdline_user_args().has("--title")
	if wants_title and not Engine.get_meta("porch_skip_title", false):
		hud.show_title()
	else:
		begin()

## The fight starts: Duff calls the pirate out and the pirate answers.
func begin() -> void:
	_say(player, "Hey! That's my package.", 2.2)
	opening = 2.4

## [name, hp, max] for the foe plate, or [] when nobody is fighting.
func foe_status() -> Array:
	if exploring:
		return []
	if pirate_hp > 0:
		return ["Porch Pirate", pirate_hp, PIRATE_HP]
	if rival.state != "away":
		return ["Sir Sends-It-Back", rival.hp, FoeSendback.HP]
	if mike.visible and mike_state != "away":
		return ["Marketplace Mike", maxi(mike_hp, 0), MIKE_HP]
	return []

func retry() -> void:
	Engine.set_meta("porch_skip_title", true)
	_reset()

func quit_to_title() -> void:
	Engine.set_meta("porch_skip_title", false)
	_reset()

## The foe the camera keeps in frame: the pirate until he drops, then Mike once he is in.
func current_foe():
	if exploring:
		return null
	if pirate_hp > 0:
		return pirate.position
	if mike.visible and mike_state != "ko":
		return mike.position
	if rival.state not in ["away", "ko"]:
		return rival.body.position
	return null

func _process(delta: float) -> void:
	_place_bubble(delta)
	if special_time > 0 and not active:
		special_time = 0  # the fight ended mid-special (his KO punch, or Duff KO'd in the recovery)
		_end_special()
	if opening > 0:
		opening -= delta
		if opening <= 0 and active and pirate_hp > 0 and bubble_from == player:
			_say(pirate, "Just browsing your porch, boss.")
	callout_time = maxf(0, callout_time - delta / maxf(Engine.time_scale, .05))  # real time: hit-stop and slow-mo mustn't pin it on screen
	if end_in > 0:
		end_in -= delta
		if end_in <= 0:
			hud.show_end(end_won)
	tell_ring.visible = tell_foe != null and active
	if tell_ring.visible:
		tell_ring.position = tell_foe.position + Vector3.UP * .04
		tell_ring.scale = Vector3.ONE * (1.0 + .12 * sin(clock * 30.0))
	fight_cam.follow(delta, player.position, current_foe())
	if meter >= 100 and not meter_rang and active:
		meter_rang = true
		if feel:
			feel.sfx("achievement", 0.0, -4.0)  # special ready
	elif meter < 100:
		meter_rang = false
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
	kick_cool = maxf(0, kick_cool - delta)
	var direction := _movement()
	if dodge_time <= 0 and special_time <= 0 and direction != Vector3.ZERO:
		facing = direction.normalized()
		player_model.rotation.y = atan2(-direction.x, -direction.z)
	if special_requested:
		special_requested = false
		red_right_hand()
	if special_time > 0:
		_tick_special(delta)
	if dodge_requested:
		dodge_requested = false
		_dodge()
	if attack_requested:
		attack_requested = false
		_attack()
	if kick_requested:
		kick_requested = false
		_kick()
	for foe in launched.keys():
		launched[foe] -= delta
		if launched[foe] <= 0:
			launched.erase(foe)
	hit_marker.visible = attack_time > .14
	var motion := facing * 8.8 if dodge_time > 0 else direction * PLAYER_SPEED
	if special_time > 0:
		motion = facing * RRH_SPEED if _dashing() else Vector3.ZERO
	_move(player, motion)
	var speed := Vector2(player.get_real_velocity().x, player.get_real_velocity().z).length()
	player_model.move(minf(speed / PLAYER_SPEED, 1.0))
	if exploring:
		zones.tick()
		return
	if pirate_hp > 0:
		if toss_foe != pirate:
			_tick_pirate(delta)
	elif mike_state == "away":
		if player.position.distance_to(package.position) <= .85:
			_mike_arrives()
	elif mike_state != "ko":
		if toss_foe != mike:
			_tick_mike(delta)
	elif rival.state == "away":
		if rival_in > 0:
			rival_in -= delta
			if rival_in <= 0:
				rival.arrive()
	elif rival.state != "ko" and toss_foe != sendback:
		rival.tick(delta)
	_tick_sign(delta)
	rival.tick_cards(delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		attack_requested = true
	elif event is InputEventKey:
		if event.physical_keycode == KEY_SHIFT:
			dodge_requested = true
		elif event.physical_keycode in [KEY_K, KEY_C]:
			kick_requested = true
		elif event.physical_keycode in [KEY_R, KEY_E, KEY_V]:
			special_requested = true  # R like the button
		elif event.physical_keycode == KEY_BACKSPACE:
			retry()

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
	if launched.has(actor) and _hit_wall(actor):
		launched.erase(actor)
		_wall_splat(actor)

func _tick_pirate(delta := 1.0 / 60) -> void:
	thief.tick(delta)

func _pirate_windup(seconds: float) -> void:
	thief.windup(seconds)

## One point of damage unless Duff is in dodge / hit immunity. Returns true when it landed.
func _hurt_duff(from: Vector3) -> bool:
	if invulnerable > 0 and clock - last_dodge <= .3 and active:
		perfect_at = clock  # slipped it with a roll: K now is a counter kick
		_call("PERFECT!")
	if invulnerable > 0 or not active:
		return false
	player_hp -= 1
	hits_taken += 1
	meter = minf(100, meter + METER_HURT)
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
		end_in = 1.2
		end_won = false
		bubble_time = 0
		if feel:
			feel.stop_music()
	else:
		player_model.strike("hit", HIT_ANIM)
	return true

## A: jab, then hook. Press again in rhythm (after the swing, within COMBO_GAP) and it's a combo:
## the foe can't guard it, and the third hit is a knockdown. Pressing mid-swing (mashing) drops it,
## and mashed hits get guarded like before. A right after a roll is a dash hook.
func _attack() -> void:
	var foe := _foe()
	if not active or foe == null or dodge_time > 0:
		return
	if attack_time > 0:
		combo_broken = true
		return
	var since_roll := clock - last_dodge
	var dash := since_roll >= .18 and since_roll <= DASH_WINDOW
	var rhythm := combo > 0 and not combo_broken and clock - combo_at <= COMBO_GAP
	combo_broken = false
	var step := combo + 1 if rhythm else 1
	var finisher := step >= 3 and not dash
	attack_time = .27
	var offset := foe.position - player.position
	offset.y = 0
	if dash:
		facing = offset.normalized()  # the dash homes in on him
		player_model.rotation.y = atan2(-facing.x, -facing.z)
		player_model.strike("hook", ATTACK_ANIM)
		if feel:
			feel.push(player, facing, DASH_SPEED)
	elif finisher:
		player_model.strike("hook", ATTACK_ANIM * 1.25)
	else:
		player_model.strike("jab" if step == 1 else "hook", ATTACK_ANIM)
	var reach := DASH_REACH if dash else 1.75
	if offset.length() > reach or facing.dot(offset.normalized()) < .38 or not _clear_strike(player, foe):
		combo = 0
		if feel:
			feel.sfx("swing")
		return
	var taunting := _armoured(foe)
	if taunting or (not rhythm and not dash and _guards(foe)):
		combo = 0
		_block(foe)
		return
	if rhythm or dash:
		chain.erase(foe)  # a clean combo hit isn't part of a mashed flurry
	combo = 0 if finisher else step
	combo_at = clock
	var damage := 2 if finisher else 1
	if finisher:
		_call("KNOCKDOWN!")
	elif dash:
		_call("DASH HOOK!")
	elif step == 2:
		_call("2 HIT")
	if feel:
		var ko := _hp_of(foe) <= damage
		feel.landed(foe, player.position, ko)
		if finisher:
			feel.push(foe, offset, feel.KNOCK_HIT * FINISHER_KNOCK)
			feel.add_trauma(.25)
	_damage(foe, damage, FINISHER_STUN if finisher else HIT_ANIM)

## K: the push kick. Longer reach than a punch and it goes through a guard (not Mike's rant).
## As the third hit of a combo (A A K) it's a launcher; into a wall it hurts once more.
## Right after a roll slips a hit it's a counter kick: slow motion, can't miss in reach.
func _kick() -> void:
	var foe := _foe()
	if not active or foe == null or dodge_time > 0:
		return
	if attack_time > 0:
		combo_broken = true
		return
	var counter := clock - perfect_at <= PERFECT_WINDOW
	if kick_cool > 0 and not counter:
		return
	var rhythm := combo > 0 and not combo_broken and clock - combo_at <= COMBO_GAP
	combo_broken = false
	var launcher := rhythm and combo >= 2
	attack_time = KICK_LOCK
	kick_cool = KICK_COOL
	var offset := foe.position - player.position
	offset.y = 0
	if counter:
		facing = offset.normalized()
		player_model.rotation.y = atan2(-facing.x, -facing.z)
	player_model.strike("kick", KICK_ANIM)
	if offset.length() > KICK_REACH or facing.dot(offset.normalized()) < .38 or not _clear_strike(player, foe):
		combo = 0
		if feel:
			feel.sfx("swing")
		return
	if _armoured(foe):
		combo = 0
		_block(foe)
		return
	chain.erase(foe)  # a kick breaks the guard
	combo = 0
	perfect_at = -99.0
	var damage := 2 if launcher or counter else 1
	_call("COUNTER KICK!" if counter else ("LAUNCHER!" if launcher else "KICK!"))
	if feel:
		var ko := _hp_of(foe) <= damage
		feel.landed(foe, player.position, ko)
		feel.push(foe, offset, feel.KNOCK_HIT * (LAUNCH_KNOCK if launcher else KICK_KNOCK))
		if counter:
			feel.slow_mo(.45)
	if launcher:
		launched[foe] = WALL_TIME
	_damage(foe, damage, FINISHER_STUN if launcher or counter else HIT_ANIM)

## Hit damage on a foe, with the pirate's or Mike's reaction (stun = seconds he can't swing).
func _damage(foe: CharacterBody3D, damage: int, stun: float) -> void:
	if special_time <= 0:
		meter = minf(100, meter + METER_HIT)
	if foe == mike:
		_hit_mike(damage)
		if mike_state == "stalk":
			mike_recovery = maxf(mike_recovery, stun)
		return
	if foe == sendback:
		rival.hit(damage, stun, special_strike)  # a special goes through his cloche (a wall bounce after one doesn't)
		return
	thief.hit(damage, stun)

func _hit_wall(actor: CharacterBody3D) -> bool:
	for i in actor.get_slide_collision_count():
		var hit := actor.get_slide_collision(i)
		if absf(hit.get_normal().y) >= .5:
			continue  # the ground is not a wall
		var other := hit.get_collider()
		if other is CollisionObject3D and other.collision_layer & WORLD_LAYER and not other is CharacterBody3D:
			return true
	return false

func _wall_splat(foe: CharacterBody3D) -> void:
	if not active or _hp_of(foe) <= 0 or _armoured(foe):
		return
	wall_hits += 1  # no callout (Duff, Nov 25): the thud and shake say it
	if feel:
		feel.sfx("bonk")
		feel.add_trauma(.4)
		feel.hit_stop(feel.HIT_STOP)
	_damage(foe, 1, FINISHER_STUN)

## Red Right Hand (special, full meter): Duff's tattooed right hand glows red, winds up and lands a haymaker
## that goes through any guard (even Mike's rant) for 3 and throws the foe across the porch.
func red_right_hand() -> void:
	var foe := _foe()
	if not active or meter < 100 or special_time > 0 or foe == null:
		return
	meter = 0
	var near := foe.position - player.position
	near.y = 0
	if near.length() <= RTS_RANGE and player_model.has_clip(RTS_CLIP):
		_return_to_sender(foe)
		return
	special_time = RRH_TIME
	special_hit = false
	invulnerable = maxf(invulnerable, RRH_WINDUP + RRH_DASH)  # a whiff leaves him open
	combo = 0
	var offset := foe.position - player.position
	offset.y = 0
	facing = offset.normalized()
	player_model.rotation.y = atan2(-facing.x, -facing.z)
	player_model.strike(RRH_CLIP if player_model.has_clip(RRH_CLIP) else "hook", RRH_WINDUP / RRH_PEAK)  # reaches full extension as the dash starts
	player_model.locked = RRH_TIME  # keep locomotion off the frozen fist for the whole dash
	attack_time = RRH_TIME
	_call("RED RIGHT HAND!")
	if feel:
		feel.sfx("sting_levelup", 0.0, -4.0)
	if rrh_glow == null:
		_build_rrh()
	rrh_glow.visible = true
	rrh_trail.visible = true
	rrh_fire.emitting = true
	rrh_points.clear()
	if feel:
		feel.sfx("tele", 0.0, 2.0)

func _tick_special(delta: float) -> void:
	if toss_foe:
		_tick_toss(delta)
		return
	special_time = maxf(0, special_time - delta)
	var into := RRH_TIME - special_time
	rrh_glow.light_energy = clampf(into / RRH_WINDUP, 0, 1) * 1.4 if not special_hit else maxf(0, rrh_glow.light_energy - delta * 8)
	var hand := player_model.skeleton.global_transform * player_model.skeleton.get_bone_global_pose(player_model.skeleton.find_bone("RightHand")).origin
	rrh_points.push_front(hand)
	if rrh_points.size() > 14:
		rrh_points.pop_back()
	_draw_trail()
	var anim := player_model.player
	if _dashing() and anim.speed_scale != 0.0:
		anim.seek(anim.current_animation_length * RRH_PEAK, true)  # fist out, frozen: he flies arm-first
		anim.speed_scale = 0.0
	elif not _dashing() and anim.speed_scale == 0.0:
		anim.speed_scale = 1.6  # snap back
	if _dashing() and not special_hit:
		var foe := _foe()
		if foe:
			var offset := foe.position - player.position
			offset.y = 0
			if offset.length() <= RRH_HIT_RADIUS + .4 and facing.dot(offset.normalized()) > .2:
				special_hit = true
				specials_landed += 1
				if feel:
					feel.sfx("explosion", .05, -8.0)
				special_time = minf(special_time, RRH_RECOVER * .6)  # connected: stop the dash, short recovery
				if foe == mike and mike_state == "taunt":
					mike_state = "stalk"  # the hand goes through his rant
				if feel:
					feel.landed(foe, player.position, true)
					feel.push(foe, facing, feel.KNOCK_HIT * RRH_KNOCK)
					feel.add_trauma(.7)
					feel.sfx("sting_ko", 0.0, -2.0)
				hud.flash(Color(0.85, 0.08, 0.06), .35)
				special_strike = true
				_damage(foe, RRH_DAMAGE, FINISHER_STUN * 1.5)
				special_strike = false
	if special_time <= 0:
		_end_special()

## Return to Sender: grab the foe up close and throw him over Duff's shoulder for 3, through any guard.
## The clip moves Duff; the game carries the foe in his hands and flies him to the landing spot.
func _return_to_sender(foe: CharacterBody3D) -> void:
	var length := player_model.player.get_animation("rig/" + RTS_CLIP).length
	toss_foe = foe
	toss_t = 0
	toss_fly = -1
	special_time = maxf(length / RTS_SPEED, RTS_RELEASE / RTS_SPEED + RTS_FLY + .05)  # he always lands before it ends
	special_hit = true  # never a dash
	invulnerable = maxf(invulnerable, special_time)
	attack_time = special_time
	combo = 0
	var offset := foe.position - player.position
	offset.y = 0
	facing = offset.normalized()
	player_model.rotation.y = atan2(-facing.x, -facing.z)
	player_model.strike(RTS_CLIP, length / RTS_SPEED)
	player_model.locked = special_time
	if foe == mike and mike_state in ["taunt", "post", "charge_tele", "charge", "jab_tele"]:
		mike_state = "stalk"  # grabbed mid-move: whatever he was doing is cancelled
	if foe == pirate:
		pirate_wind = 0  # a jab he was winding up is cancelled
	if foe == sendback:
		rival.cancel()
	_tell(null)
	_call("RETURN TO SENDER!")
	if feel:
		feel.sfx("tele", 0.0, 2.0)

func _tick_toss(delta: float) -> void:
	special_time = maxf(0, special_time - delta)
	toss_t += delta * RTS_SPEED
	var foe := toss_foe
	var model: Node3D = _model_of(foe)
	var height := _height_of(foe)
	var sk := player_model.skeleton
	var hands := sk.global_transform * ((sk.get_bone_global_pose(sk.find_bone("LeftHand")).origin
		+ sk.get_bone_global_pose(sk.find_bone("RightHand")).origin) * .5)
	if toss_t >= RTS_GRAB and toss_t < RTS_RELEASE:
		if foe.collision_layer != 0:
			foe.collision_layer = 0  # in Duff's hands: no pushing either way
			foe.collision_mask = 0
			_foe_clip(model, "flail", 0.0)  # kicking and waving in Duff's hands (loops)
			if feel:
				feel.sfx("bonk", 0.0, -4.0)
				feel.add_trauma(.2)
		var lift := clampf((toss_t - RTS_GRAB) / (RTS_RELEASE - RTS_GRAB), 0, 1)
		var look := player.global_position - foe.global_position
		model.rotation.y = atan2(-look.x, -look.z)
		model.rotation.x = -lift * 1.2  # tipping back over the shoulder
		_hold_at(foe, model, height, hands - Vector3(0, height * lerpf(.12, -.1, lift), 0))
	elif toss_t >= RTS_RELEASE and toss_fly < 0:
		toss_fly = 0
		toss_from = foe.global_position + Basis.from_euler(model.rotation) * Vector3(0, height * .5, 0)
		# the flyup clip tumbles him and lands him flat right as the arc comes down
		_foe_clip(model, "flyup", model.player.get_animation("rig/flyup").length * RTS_FLY / RTS_FLYUP_LAND)
		var out := hands - player.global_position
		out.y = 0
		out = out.normalized() if out.length() > .05 else -facing
		toss_land = _clear_landing(player.global_position, out)
	if toss_fly >= 0 and toss_fly < RTS_FLY:
		toss_fly += delta / maxf(Engine.time_scale, .05)  # real time: the landing hit-stop shouldn't stall the arc
		var k := minf(toss_fly / RTS_FLY, 1.0)
		model.rotation.x = lerpf(-1.2, 0.0, minf(k * 2.0, 1.0))  # the clip does the tumbling
		var centre := toss_from.lerp(toss_land + Vector3.UP * height * .18, k) + Vector3.UP * sin(k * PI) * RTS_ARC
		_hold_at(foe, model, height, centre)
		if k >= 1.0:
			_toss_lands()
	if special_time <= 0:
		_end_special()

## Put the foe's middle (half his height up his body) at `centre`, whatever way he is tipped.
func _hold_at(foe: CharacterBody3D, model: Node3D, height: float, centre: Vector3) -> void:
	foe.global_position = centre - Basis.from_euler(model.rotation) * Vector3(0, height * .5, 0)

## Where a thrown foe comes down: RTS_THROW out, short of any fence, wall or planter.
func _clear_landing(from: Vector3, out: Vector3) -> Vector3:
	var land := from + out * RTS_THROW
	var space := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(from + Vector3.UP * .5, land + Vector3.UP * .5, WORLD_LAYER)
	var hit := space.intersect_ray(ray)
	if hit:
		land = Vector3(hit.position.x, 0, hit.position.z) - out * .45
	land.y = 0
	return land

func _toss_lands() -> void:
	var foe := toss_foe
	var model: Node3D = _model_of(foe)
	toss_fly = RTS_FLY
	foe.global_position = toss_land
	foe.collision_layer = ACTOR_LAYER
	foe.collision_mask = WORLD_LAYER | ACTOR_LAYER
	tosses += 1
	specials_landed += 1
	if feel:
		feel.sfx("hit")
		feel.add_trauma(1.0)
		feel.sfx("bonk", .05, -2.0)  # the thud of a body on the lawn
		feel.hit_stop(feel.HIT_STOP_KO)
		feel.sfx("sting_ko", 0.0, -2.0)
	hud.flash(Color(0.85, 0.08, 0.06), .3)
	var was_pirate := foe == pirate
	special_strike = true
	_damage(foe, RTS_DAMAGE, FINISHER_STUN * 1.5)
	special_strike = false
	model.rotation.x = 0
	var down := _hp_of(foe) <= 0
	# _damage just started a KO fall or a hit stagger from standing: he is already flat, so hold the flyup's last frame
	model.player.stop()
	model.player.speed_scale = 1.0
	model.player.play("rig/flyup", 0.0)
	model.player.seek(model.player.current_animation_length, true)
	if down:
		model.current = "ko"  # stays down: locomotion and the KO clip leave him alone
		model.locked = 0
	else:
		model.current = "flyup"
		# lies there a beat, then gets up (a slow blend into idle) while still stunned
		model.locked = 1.3
		var rise := create_tween()
		rise.tween_interval(.75)
		rise.tween_callback(func() -> void:
			if model.current == "flyup":
				model.current = "idle"
				model.player.speed_scale = 1.0
				model.player.play("rig/idle", .5))
	if was_pirate and pirate_hp == 0:
		_send_parcel_home()

## A foe's clip that doesn't fit `strike` (a loop, or one stretched to the throw's timing).
func _foe_clip(model, clip: String, seconds: float) -> void:
	if not model.has_clip(clip):
		return
	if seconds > 0:
		model.strike(clip, seconds)
	else:
		model.player.speed_scale = 1.0
		model.locked = 99.0  # held: the AI is off anyway; _end_toss / the landing unlocks
		model.play(clip, true)

## The thrown pirate's parcel sails back onto the stoop: Return to Sender.
func _send_parcel_home() -> void:
	var from := package.position
	var arc := func(k: float) -> void:
		package.position = from.lerp(STOOP_AT, k) + Vector3.UP * sin(k * PI) * 1.4
		package.rotation.y = k * TAU
	var fly := create_tween()
	fly.tween_method(arc, 0.0, 1.0, .75).set_trans(Tween.TRANS_SINE)
	fly.tween_callback(func() -> void:
		if feel:
			feel.sfx("cash", 0.0, -2.0))  # delivered

## Put a held or flying foe back on his feet (the fight ended mid-throw, or the throw is over).
func _end_toss() -> void:
	if toss_foe == null:
		return
	if toss_fly < RTS_FLY:
		var model: Node3D = _model_of(toss_foe)
		model.rotation.x = 0
		model.locked = 0  # let go mid-carry: back to his own clips
		if model.current in ["flail", "flyup"]:
			model.play("idle")
		toss_foe.global_position.y = 0
		if toss_foe.collision_layer == 0 and _hp_of(toss_foe) > 0:
			toss_foe.collision_layer = ACTOR_LAYER
			toss_foe.collision_mask = WORLD_LAYER | ACTOR_LAYER
	toss_foe = null

## Fire out, glow and trail off, the frozen fist let go.
func _end_special() -> void:
	_end_toss()
	if player_model.player.speed_scale == 0.0:
		player_model.player.speed_scale = 1.0
	if rrh_glow:
		rrh_fire.emitting = false
		rrh_glow.visible = false
		rrh_trail.visible = false

func _dashing() -> bool:
	var into := RRH_TIME - special_time
	return special_time > 0 and not special_hit and into >= RRH_WINDUP and into < RRH_WINDUP + RRH_DASH

func _build_rrh() -> void:
	rrh_glow = OmniLight3D.new()
	rrh_glow.light_color = Color(1.0, 0.12, 0.08)
	rrh_glow.omni_range = .5  # the hand, not the whole body
	rrh_glow.omni_attenuation = 2.0
	rrh_glow.light_energy = 0
	rrh_glow.visible = false
	var socket := BoneAttachment3D.new()
	socket.bone_name = "RightHand"
	player_model.skeleton.add_child(socket)
	socket.add_child(rrh_glow)
	var ember := MeshInstance3D.new()  # the fist itself burns red
	var ball := SphereMesh.new()
	ball.radius = .09
	ball.height = .18
	ember.mesh = ball
	var hot := StandardMaterial3D.new()
	hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hot.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hot.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hot.albedo_color = Color(1, .18, .1, .7)
	ember.material_override = hot
	ember.scale = Vector3.ONE / player_model.skeleton.get_parent().global_transform.basis.get_scale()
	rrh_glow.add_child(ember)
	rrh_fire = CPUParticles3D.new()  # flames off the fist, left behind in the world as he moves
	rrh_fire.local_coords = false
	rrh_fire.amount = 48
	rrh_fire.lifetime = .4
	rrh_fire.emitting = false
	rrh_fire.direction = Vector3.UP
	rrh_fire.spread = 35
	rrh_fire.gravity = Vector3(0, 1.6, 0)
	rrh_fire.initial_velocity_min = .3
	rrh_fire.initial_velocity_max = .9
	rrh_fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	rrh_fire.emission_sphere_radius = .08
	var flame := SphereMesh.new()
	flame.radius = .07
	flame.height = .14
	flame.radial_segments = 8
	flame.rings = 4
	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mat.vertex_color_use_as_albedo = true
	flame.material = flame_mat
	rrh_fire.mesh = flame
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, .85, .3, 1))
	ramp.set_color(1, Color(.8, .05, .02, 0))
	ramp.add_point(.45, Color(1, .25, .05, .9))
	rrh_fire.color_ramp = ramp
	var shrink := Curve.new()
	shrink.add_point(Vector2(0, 1))
	shrink.add_point(Vector2(1, .2))
	rrh_fire.scale_amount_curve = shrink
	rrh_fire.scale_amount_min = 1.0
	rrh_fire.scale_amount_max = 1.8
	rrh_glow.add_child(rrh_fire)
	rrh_trail = MeshInstance3D.new()
	rrh_trail.mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	rrh_trail.material_override = mat
	rrh_trail.visible = false
	add_child(rrh_trail)

## A red ribbon along the hand's last few positions, widest and brightest at the hand.
func _draw_trail() -> void:
	var mesh := rrh_trail.mesh as ImmediateMesh
	mesh.clear_surfaces()
	if rrh_points.size() < 2:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in rrh_points.size():
		var k := 1.0 - float(i) / rrh_points.size()
		var up := Vector3.UP * .26 * k
		var fire := Color(1, .1, .05).lerp(Color(1, .8, .25), k * k)  # yellow-hot at the fist, red down the tail
		mesh.surface_set_color(Color(fire, k))
		mesh.surface_add_vertex(rrh_points[i] + up)
		mesh.surface_set_color(Color(fire, k))
		mesh.surface_add_vertex(rrh_points[i] - up)
	mesh.surface_end()

func _call(text: String) -> void:
	callout = text
	callout_time = CALLOUT_TIME

## Mashing gets read: the hit after GUARD_AFTER in one flurry is blocked. A dizzy Mike can't guard
## (that's the reward for dodging his charge); a taunting one blocks everything.
func _guards(foe: CharacterBody3D) -> bool:
	if foe == mike and mike_state in ["dizzy", "charge"]:
		return false
	if foe == sendback and rival.state in ["dizzy", "charge"]:
		return false
	if foe == mike and mike_state == "taunt":
		return true  # his price-drop rant is no opening
	var flurry: Array = chain.get(foe, [0, -99.0])
	if clock - flurry[1] > CHAIN_WINDOW:
		flurry = [0, clock]
	if flurry[0] >= (GUARD_AFTER - 1 if (foe == mike and mike_raged) or (foe == sendback and rival.raged) else GUARD_AFTER):  # raged, he reads you faster
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
	elif foe == sendback:
		if rival.state == "plate":
			rival.deflect()  # the cloche sends it back
		elif rival.state != "taunt":
			rival.jab(COUNTER_TELE)
	else:
		_mike_jab(COUNTER_TELE)

## Who Duff's punches can land on right now.
func _foe() -> CharacterBody3D:
	if exploring:
		return null
	if pirate_hp > 0:
		return pirate
	if mike_state not in ["away", "ko"]:
		return mike
	if rival.state not in ["away", "ko"]:
		return sendback
	return null

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
	if active and dodge_recovery <= 0 and special_time <= 0:  # no rolling out of the special: a whiff stays open
		dodge_time = .23
		player_model.strike("dodge", DODGE_ANIM)
		dodge_recovery = .65
		last_dodge = clock
		invulnerable = maxf(invulnerable, .27)
		if feel:
			feel.sfx("roll")

func _reset() -> void:
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		Input.action_release(action)  # a stick held through Retry would otherwise keep Duff walking
	get_tree().paused = false  # a menu pauses the tree; the new porch must run
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

func _collider(label: String, at: Vector3, dimensions: Vector3, parent: Node3D = null) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = WORLD_LAYER
	body.collision_mask = ACTOR_LAYER
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var hit := CollisionShape3D.new()
	hit.shape = shape
	body.add_child(hit)
	(parent if parent else self).add_child(body)
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
	zones = Zones.make(self)
	zones.load_zone("porch")

## The porch set (zone "porch", porch_zones.gd): Meshy set or our kit, the porch lamp, colliders.
func _build_porch_set(root: Node3D) -> void:
	if OS.get_cmdline_user_args().has("--kit"):  # our own set, to compare with the Meshy one
		Kit.build(root, PLANTER_AT, PLANTER_SIZE)
		Art.ground(root)
	else:
		Art.meshy_set(root, PLANTER_AT, PLANTER_SIZE)
	var lamp := OmniLight3D.new()  # porch light by the door
	lamp.name = "PorchLamp"
	lamp.position = Vector3(0, 2.6, -2.9)
	lamp.light_color = Color("#ffb15e")
	lamp.light_energy = 1.4
	lamp.omni_range = 2.8
	lamp.set_meta("base_energy", 3.2)  # golden hour; porch_look.gd scales it with the clock
	lamp.set_meta("look_range", 4.5)
	lamp.add_to_group("zone_lamp")
	root.add_child(lamp)
	_collider("Ground", Vector3(0, -.16, 0), Vector3(16, .32, 11), root)
	_collider("FrontageCollider", Vector3(0, 1.4, -4.85), Vector3(10.6, 2.8, 1.9), root)
	_collider("StoopCollider", Vector3(0, .119, -2.95), Vector3(2.84, .238, 1.03), root)
	_collider("StepCollider", Vector3(0, .066, -2.35), Vector3(2.92, .132, .22), root)
	for x in [-6.9, 6.9]:
		_collider("FenceCollider", Vector3(x, .65, 0), Vector3(.32, 1.3, 11), root)
	_collider("StreetLimit", Vector3(0, .6, 5.39), Vector3(15, 1.2, .23), root)
	_collider("RearLimit", Vector3(0, .7, -5.51), Vector3(15, 1.4, .25), root)
	_collider("PlanterCollider", PLANTER_AT + Vector3.UP * PLANTER_SIZE.y * .5, PLANTER_SIZE, root)
	for x in [-6.0, 6.0]:
		_collider("TrunkCollider", Vector3(x, .9, -4.2), Vector3(.5, 1.8, .5), root)
	_collider("MailboxCollider", Vector3(6.1, .62, 2.45), Vector3(.42, 1.25, .5), root)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	# The fight still writes these; the HUD draws them in the main game's style (porch_hud.gd).
	health = _hud_label(layer, Vector2(22, 47), 16, Color.WHITE)
	message = _hud_label(layer, Vector2(22, 73), 16, Color("#ffe7ca"))
	message.text = "Stop the Porch Pirate and recover the parcel."
	fps_label = _hud_label(layer, Vector2(800, 22), 14, Color("#eddbd0"))
	for label in [health, message, fps_label]:
		label.hide()
	stick = _stick(layer)
	_button(layer, Hud.A_AT, Hud.A_R, "attack")
	_button(layer, Hud.B_AT, Hud.B_R, "dodge")
	_button(layer, Hud.K_AT, Hud.K_R, "kick")
	_button(layer, Hud.R_AT, Hud.R_R, "special")
	_build_bubble(layer)
	hud = Hud.make(self, layer)  # last: its menus cover everything else

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
	for part in ["normal_joystick", "pressed_joystick", "normal_tip", "pressed_tip"]:
		var ring := StyleBoxFlat.new()  # faint cream ring + ink tip, like the main game's pad
		var tip: bool = part.ends_with("tip")
		var down: bool = part.begins_with("pressed")
		ring.bg_color = Color(Hud.CREAM, .9 if down else .7) if tip else Color(Hud.INK, .32 if down else .22)
		ring.border_color = Color(Hud.INK, .8) if tip else Color(Hud.CREAM, .55 if down else .35)
		ring.set_border_width_all(3)
		ring.set_corner_radius_all(200)
		ring.anti_aliasing = true
		pad.add_theme_stylebox_override(part, ring)
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

## An invisible round-ish thumb zone over the HUD's drawn A / B button.
func _button(layer: CanvasLayer, centre: Vector2, radius: float, action: String) -> void:
	var button := TouchScreenButton.new()
	button.name = action.capitalize()
	button.position = centre - Vector2.ONE * radius
	var bounds := RectangleShape2D.new()
	bounds.size = Vector2.ONE * radius * 2
	button.shape = bounds
	button.shape_centered = false
	layer.add_child(button)
	var down: String = {"attack": "a_down", "dodge": "b_down", "kick": "k_down", "special": "r_down"}[action]
	button.pressed.connect(func() -> void: hud.set(down, true))
	button.released.connect(func() -> void: hud.set(down, false))
	match action:
		"attack": button.pressed.connect(func() -> void: attack_requested = true)
		"dodge": button.pressed.connect(func() -> void: dodge_requested = true)
		"kick": button.pressed.connect(func() -> void: kick_requested = true)
		"special": button.pressed.connect(func() -> void: special_requested = true)

## Speech bubble over whoever talks, in the main game's dialogue look: plum glass, cream text, pink name tag.
func _build_bubble(layer: CanvasLayer) -> void:
	var body: Font = load("res://fonts/Nunito-ExtraBold.ttf")
	var display: Font = load("res://fonts/Baloo2-ExtraBold.ttf")
	bubble = PanelContainer.new()
	bubble.name = "Bubble"
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Hud.PANEL
	style.border_color = Hud.INK
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, .35)
	style.shadow_offset = Vector2(3, 4)
	style.shadow_size = 2
	bubble.add_theme_stylebox_override("panel", style)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	bubble.add_child(lines)
	bubble_name = Label.new()
	bubble_name.add_theme_font_override("font", display)
	bubble_name.add_theme_font_size_override("font_size", 19)
	bubble_name.add_theme_color_override("font_color", Hud.PINK)
	lines.add_child(bubble_name)
	bubble_text = Label.new()
	bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_text.custom_minimum_size = Vector2(300, 0)
	bubble_text.add_theme_font_override("font", body)
	bubble_text.add_theme_font_size_override("font_size", 19)
	bubble_text.add_theme_color_override("font_color", Hud.CREAM)
	lines.add_child(bubble_text)
	bubble_tail = Polygon2D.new()
	bubble_tail.polygon = PackedVector2Array([Vector2(-13, -4), Vector2(13, -4), Vector2(0, 19)])
	bubble_tail.color = Hud.INK
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([Vector2(-8, -6), Vector2(8, -6), Vector2(0, 12)])
	inner.color = Hud.PANEL
	bubble_tail.add_child(inner)
	layer.add_child(bubble_tail)
	layer.add_child(bubble)
	bubble.hide()
	bubble_tail.hide()

func _say(speaker: Node3D, line: String, seconds := 2.8) -> void:
	bubble_from = speaker
	bubble_name.text = {player: "Duff", mike: "Marketplace Mike", sendback: "Sir Sends-It-Back"}.get(speaker, "Porch Pirate")
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
	var top := Hud.GOAL.end.y + 6  # stay clear of the status strip and objective line
	if at.y >= top:  # room above the head: tail points down at him
		at.x = clampf(at.x, 12, view.x - box.x - 12)
		bubble.position = at
		bubble_tail.rotation = 0
		bubble_tail.position = Vector2(clampf(head.x, at.x + 20, at.x + box.x - 20), at.y + box.y - 2)
		return
	# no room (the camera keeps heads high): sit beside his head, tail pointing at it
	var right := head.x + 40 + box.x <= view.x - 12
	at = Vector2(head.x + 40 if right else head.x - 40 - box.x, clampf(head.y - box.y * .5, top, maxf(top, view.y - box.y - 12)))
	bubble.position = at
	bubble_tail.rotation = PI / 2 if right else -PI / 2
	bubble_tail.position = Vector2(at.x + 2 if right else at.x + box.x - 2, clampf(head.y, at.y + 16, at.y + box.y - 16))

func _update_hud() -> void:
	if rival.state != "away":
		health.text = "DUFF %d/%d   ·   SIR SENDS-IT-BACK %d/%d" % [player_hp, PLAYER_HP, rival.hp, FoeSendback.HP]
	elif mike_state == "away":
		health.text = "DUFF %d/%d   ·   PIRATE %d/%d" % [player_hp, PLAYER_HP, pirate_hp, PIRATE_HP]
	else:
		health.text = "DUFF %d/%d   ·   MARKETPLACE MIKE %d/%d" % [player_hp, PLAYER_HP, maxi(mike_hp, 0), MIKE_HP]

## The letter for a won fight: 100, minus GRADE_HIT a hit taken and GRADE_SLOW a second past par,
## plus GRADE_SPECIAL for each special landed (up to 3).
static func grade_for(seconds: float, hits: int, specials: int) -> String:
	var score := 100.0 - GRADE_HIT * hits - GRADE_SLOW * maxf(0, seconds - PAR_TIME) + GRADE_SPECIAL * mini(specials, 3)
	for step in GRADES:
		if score >= step[0]:
			return step[1]
	return "D"

static func grade_rank(grade: String) -> int:
	return "DCBAS".find(grade)

## This win's grade and time against the best on this phone; saves a new best.
func _grade_result() -> Dictionary:
	var grade := grade_for(clock, hits_taken, specials_landed)
	var best := ConfigFile.new()
	best.load(BEST_PATH)  # missing on the first win: stays empty
	var best_grade: String = best.get_value("porch", "grade", "")
	var best_time: float = best.get_value("porch", "time", INF)
	var new_best := best_grade == "" or grade_rank(grade) > grade_rank(best_grade) \
		or (grade == best_grade and clock < best_time)
	if new_best:
		best.set_value("porch", "grade", grade)
		best.set_value("porch", "time", clock)
		best.save(BEST_PATH)
		best_grade = grade
		best_time = clock
	return {"grade": grade, "time": clock, "hits": hits_taken, "specials": specials_landed,
		"best_grade": best_grade, "best_time": best_time, "new_best": new_best}

static func clock_label(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]

## Mike's moves, for porch.gd's own code and the tests (foe_mike.gd does the work).
func _mike_arrives() -> void:
	boss.arrive()

func _tick_mike(delta: float) -> void:
	boss.tick(delta)

func _tick_sign(delta: float) -> void:
	boss.tick_sign(delta)

func _mike_jab(seconds: float) -> void:
	boss.jab(seconds)

func _hit_mike(damage := 1) -> void:
	boss.hit(damage)


## Mike is sold: Sir Sends-It-Back walks up the path after a beat (the third fight).
func _mike_sold() -> void:
	hit_marker.hide()
	message.text = "Parcel recovered. Somebody else is coming up the walk..."
	rival_in = 2.2
	chain.clear()

## The last foe is down: the porch is secured, the fight is graded.
func _porch_won(line: String) -> void:
	active = false
	hit_marker.hide()
	message.text = line
	end_in = 1.6
	end_won = true
	result = _grade_result()
	if feel:
		feel.stop_music()
		feel.sfx("win", 0.0)

## "Go inside" on the win card: the fight is over, Duff walks home through the front door.
func go_inside() -> void:
	hud.close_menu()
	_start_exploring()
	zones.travel("apartment", Vector3(-2.75, 0, -.45), Vector3.RIGHT)

## No more fight: foes, parcel and fight bits leave the scene; Duff walks freely.
func _start_exploring() -> void:
	exploring = true
	active = true
	end_in = 0
	hit_marker.hide()
	tell_foe = null
	bubble_time = 0
	opening = 0
	message.text = "Porch secured. Walk home: the front door's on the stoop."
	for body in [pirate, mike, sendback]:
		body.hide()
		body.process_mode = Node.PROCESS_MODE_DISABLED
		body.collision_layer = 0
		body.collision_mask = 0
	package.hide()
	if obo_sign:
		obo_sign.hide()
	rival.cancel()
	if feel:
		feel.stop_music()

## Which foe script a body belongs to, and the bits porch.gd needs from it.
func _hp_of(foe: CharacterBody3D) -> int:
	if foe == pirate:
		return pirate_hp
	if foe == mike:
		return mike_hp
	return rival.hp

func _model_of(foe: CharacterBody3D) -> Node3D:
	if foe == pirate:
		return pirate_model
	if foe == mike:
		return mike_model
	return rival.model

func _height_of(foe: CharacterBody3D) -> float:
	if foe == pirate:
		return PIRATE_HEIGHT
	if foe == mike:
		return MIKE_HEIGHT
	return FoeSendback.HEIGHT

## Blocks every punch and kick (specials still go through): Mike's rant, Sends-It-Back's cloche.
func _armoured(foe: CharacterBody3D) -> bool:
	if foe == mike:
		return mike_state == "taunt"
	if foe == sendback:
		return rival.guarding()
	return false
