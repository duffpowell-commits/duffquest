extends CharacterBody2D

const Proj: = preload("res://scripts/projectile.gd")

const STATS: = {
	"scammer": {"hp": 3.0, "speed": 46.0, "contact": 0.0, "name": "Scammer" },
	"karen": {"hp": 5.0, "speed": 34.0, "contact": 4.0, "name": "Karen" },
	"hoa": {"hp": 7.0, "speed": 22.0, "contact": 6.0, "name": "HOA Goon" },
	"driver": {"hp": 999.0, "speed": 240.0, "contact": 18.0, "name": "Road-Rage Driver" },
	"hustler": {"hp": 2.0, "speed": 50.0, "contact": 0.0, "name": "Door-to-Door Hustler" },
	"pete": {"hp": 18.0, "speed": 38.0, "contact": 8.0, "name": "Palm Beach Pete" },
	"drone": {"hp": 1.0, "speed": 58.0, "contact": 6.0, "name": "Tip Drone" },
	"butler": {"hp": 2.0, "speed": 42.0, "contact": 6.0, "name": "Hired Butler" },
	"nft": {"hp": 1.0, "speed": 50.0, "contact": 5.0, "name": "Bored Ape-ish NFT" },
	"pirate": {"hp": 3.0, "speed": 52.0, "contact": 0.0, "name": "Porch Pirate" },
	"drunk": {"hp": 4.0, "speed": 30.0, "contact": 5.0, "name": "3 AM Drunk" },
	"heckler": {"hp": 5.0, "speed": 36.0, "contact": 3.0, "name": "Bachelor Party Bro" },
	"kid": {"hp": 2.0, "speed": 48.0, "contact": 4.0, "name": "Sugar-High Kid" },
}
const LINES: = {
	"scammer": ["Psst. Rolex? It's a Rolecks.", "Your extended warranty is expiring!", "HoneyBunCoin. Whitepaper's a napkin.", "I'm a prince. Of {nearby_town}.", "Gift cards only. For tax reasons."],
	"karen": ["Excuse me. EXCUSE ME.", "Is that a WORKER? In PUBLIC?", "One star. For this whole SIDEWALK.", "I know the mayor's dentist.", "I'd like to speak to your landlord."],
	"karen_buddy": ["Linda's here. Linda has NOTES.", "We're BOTH calling corporate.", "My husband's a lawyer. Of brand."],
	"hoa": ["Grass: 0.4 inches too free.", "Citation 14-B: unlicensed joy.", "That mailbox is a crime.", "Bylaw 9: no fun after 8 PM.", "I don't make rules. I laminate them."],
	"driver": ["HONK HONK!", "SIDEWALKS ARE WOKE!", "LATE FOR MY COLD PLUNGE!", "I'M FINANCING THIS AT 19%!"],
	"hustler": ["Be your own boss! (Pay me.)", "Rise and grind, king!", "Not an MLM. A FAMILY.", "Passive income! Active begging!"],
	"drone": ["*bzzz* Add a tip? 30%? 40%?", "*bzzz* Tip your drone", "*bzzz* Driver rating: you"],
	"nft": ["I'm worth 40 ETH! (JPEG)", "Right-click me, coward", "Utility coming Q5!"],
	"butler": ["Pardon me, sir. *slap*", "The Baron sends regards. From his yacht.", "No benefits, sir. *slap*"],
	"pirate": ["Just browsing your porch, boss.", "Last-mile logistics, baby!", "Delivery guy. In reverse.", "Your doorbell cam sells my data too.", "Leave at door? Don't mind if I do."],
	"drunk": ["I'm not drunk, YOU'RE drunk. Respectfully.", "Hash browns. ALL the hash browns.", "Do you know who I am? ...Do YOU?", "I love you, man. Fight me.", "Is this the bathroom? This is the bathroom now."],
	"heckler": ["WOOOO! BACHELOR PARTY!", "Kyle's getting MARRIED, bro!", "Chef! Chef! Do a flip!", "Our Uber's 40 minutes out. We live here now."],
	"kid": ["IT'S MY BIRTHDAYYYY", "I had FOUR sodas!", "Tag, you're it! FOREVER!", "My dad says you're the help!"],
	"pete": ["I'M PALM BEACH PETE! FEAR THE TAN!", "SPF is a psyop, bro!", "Banned from 3 Waffle Houses. Respectfully.", "These flip-flops have SEEN things.", "I wrestled a gator once! Lost! Twice!", "I'm here for the tax haven!"],
}
const TELE_LINES: = {"flipflop": "CATCH, BUDDY!", "charge": "SPRING BREAK!!!", "fireworks": "HOLD MY ENERGY DRINK!" }

var m: Node = null
var kind: = "scammer"
var hp: = 3.0
var max_hp: = 3.0
var speed: = 40.0
var state: = "roam"
var st: = 0.0
var knock: = Vector2.ZERO
var flash: = 0.0
var stun: = 0.0
var line: = ""
var line_t: = 0.0
var line_cd: = 1.0
var buddy: = false
var summoned: = false
var stolen: = 0
var act_cd: = 1.5
var contact_cd: = 0.0
var next_attack: = ""
var charge_dir: = Vector2.ZERO
var lane: = {}
var hit_done: = false
var wander: = Vector2.ZERO
var think_t: = 0.0
var home: = Vector2.ZERO
var t: = 0.0
var pname: = ""
var loot: = ""

func _ready() -> void:
	add_to_group("hostile")
	add_to_group("enemy")
	var s: Dictionary = STATS[kind]
	max_hp = float(s["hp"]) * (0.6 if buddy else 1.0)
	hp = max_hp
	speed = float(s["speed"])
	home = position
	if kind == "driver":
		state = "tele"
		st = 1.1
		AudioScript.sfx("honk")
		say(LINES["driver"][randi() % LINES["driver"].size()])
		return
	collision_layer = 4
	collision_mask = 1
	var cs: = CollisionShape2D.new()
	var c: = CircleShape2D.new()
	c.radius = 7.0 if kind == "pete" else 5.0
	cs.shape = c
	add_child(cs)
	if kind == "pete":
		say("I'M PALM BEACH PETE! FEAR THE TAN!")
		act_cd = 2.0
	if kind == "pirate":
		if pname == "":
			var names: Array = m.PIRATE_NAMES if m else ["Porch Pirate"]
			pname = names[randi() % names.size()]
		state = "seek"
		act_cd = 1.0

func display_name() -> String:
	if kind == "karen" and buddy:
		return "Karen's Buddy Linda"
	if kind == "pirate" and pname != "":
		return preload("res://scripts/cast.gd").T(pname)
	return str(STATS[kind]["name"])

func say(s: String, dur: float = 2.2) -> void:
	line = preload("res://scripts/cast.gd").T(s)
	line_t = dur
	var bk: Variant = m.get("barks") if m != null and is_instance_valid(m) else null
	if bk != null and not bk.admit(self):
		line_t = 0.0   # rate-limited (scripts/barks.gd)

## Ambient barks wait their turn when another enemy close by is already talking (Nov 9 QA: bubbles
## piled up when 3+ enemies bunched). Telegraph / story lines still always show.
const BARK_SPACE: = 70.0
func bark_crowded() -> bool:
	for e in get_tree().get_nodes_in_group("enemy"):
		if e == self or not is_instance_valid(e) or not (e is Node2D):
			continue
		var lt: Variant = e.get("line_t")
		if lt != null and float(lt) > 0.0 and (e as Node2D).global_position.distance_to(global_position) < BARK_SPACE:
			return true
	return false

func telegraphing() -> bool:
	return state.begins_with("tele")

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	line_t = maxf(0.0, line_t - delta)
	contact_cd = maxf(0.0, contact_cd - delta)
	stun = maxf(0.0, stun - delta)
	if m == null or m.player == null:
		return
	if kind == "driver":
		_ai_driver(delta)
		queue_redraw()
		return
	var p: CharacterBody2D = m.player
	var to: Vector2 = p.global_position - global_position
	var dist: = to.length()
	var calm: bool = p.frozen or not m.dialog.is_empty()
	line_cd -= delta
	if line_cd <= 0.0 and dist < 150.0:
		line_cd = randf_range(6.0, 10.0)
		var key: = "karen_buddy" if buddy else kind
		if not bark_crowded():
			say(LINES[key][randi() % LINES[key].size()])
	var v: = Vector2.ZERO
	if stun > 0.0:
		v = Vector2.ZERO
	elif calm:
		v = Vector2.ZERO
	else:
		match kind:
			"scammer": v = _ai_scammer(delta, to, dist)
			"karen": v = _ai_karen(delta, to, dist)
			"hoa": v = _ai_hoa(delta, to, dist)
			"hustler": v = _ai_hustler(delta, to, dist)
			"pete": v = _ai_pete(delta, to, dist)
			"pirate": v = _ai_pirate(delta, to, dist)
			"drone", "butler", "nft", "kid": v = to.normalized() * speed if dist > 4.0 else Vector2.ZERO
			"drunk": v = _ai_drunk(delta, to, dist)
			"heckler": v = _ai_heckler(delta, to, dist)
	velocity = v + knock
	knock = knock.move_toward(Vector2.ZERO, 520.0 * delta)
	move_and_slide()

	var cdmg: = float(STATS[kind]["contact"])
	if kind == "pete" and state == "charge":
		cdmg = 12.0
	if kind == "drunk" and state == "lunge":
		cdmg = 9.0
	if cdmg > 0.0 and dist < (13.0 if kind == "pete" else 11.0) and contact_cd <= 0.0 and not calm and stun <= 0.0:
		if m.hurt_player(cdmg, global_position, 240.0 if state == "charge" else 150.0, kind):
			contact_cd = 1.0
			knock = -to.normalized() * 90.0
	queue_redraw()

func _wander(delta: float) -> Vector2:
	think_t -= delta
	if think_t <= 0.0:
		think_t = randf_range(1.0, 2.5)
		wander = Vector2.from_angle(randf() * TAU) * 18.0 if randf() < 0.7 else Vector2.ZERO
	if global_position.distance_to(home) > 70.0:
		return (home - global_position).normalized() * 22.0
	return wander

func _ai_scammer(delta: float, to: Vector2, dist: float) -> Vector2:
	st -= delta
	match state:
		"flee", "leave":
			if st <= 0.0:
				m.enemy_gone(self)
				return Vector2.ZERO
			return -to.normalized() * (78.0 if state == "flee" else 40.0)
		"tele":
			if st <= 0.0:
				state = "lunge"
				st = 0.35
				charge_dir = to.normalized()
			return Vector2.ZERO
		"lunge":
			if dist < 14.0 and contact_cd <= 0.0:
				contact_cd = 2.0
				state = "roam"
				m.enemy_touch(self)
				return Vector2.ZERO
			if st <= 0.0:
				state = "roam"
				act_cd = 1.2
			return charge_dir * 120.0
	act_cd -= delta
	if dist < 34.0 and act_cd <= 0.0:
		state = "tele"
		st = 0.45
		say("Hey king! Quick opportunity...", 1.0)
		return Vector2.ZERO
	if dist < 140.0:
		return to.normalized() * speed
	return _wander(delta)

func _ai_pirate(delta: float, to: Vector2, dist: float) -> Vector2:

	st -= delta
	match state:
		"flee":
			var gp: = global_position
			if st <= 0.0:
				m.enemy_gone(self)
				return Vector2.ZERO
			var away: = -to.normalized()
			var edge: = Vector2(-1.0 if gp.x < 320.0 else 1.0, -1.0 if gp.y < 180.0 else 1.0).normalized()
			return (away * 0.7 + edge * 0.3).normalized() * 60.0
		"leave":
			if st <= 0.0:
				m.enemy_gone(self)
			return -to.normalized() * 45.0
		"tele":
			if st <= 0.0:
				state = "lunge"
				st = 0.35
				charge_dir = to.normalized()
			return Vector2.ZERO
		"lunge":
			if dist < 14.0:
				m.pirate_snatch(self, "bag")
				return Vector2.ZERO
			if st <= 0.0:
				state = "seek"
				act_cd = 1.2
			return charge_dir * 125.0
	if m.porch_pkg:
		var tp: Vector2 = m.PORCH_PT - global_position
		if tp.length() < 9.0:
			m.pirate_snatch(self, "porch")
			return Vector2.ZERO
		return tp.normalized() * speed
	if m.pirate_bag_loot() != "":
		act_cd -= delta
		if dist < 30.0 and act_cd <= 0.0:
			state = "tele"
			st = 0.5
			say("Ooh, is that for ME?", 1.0)
			return Vector2.ZERO
		return to.normalized() * speed
	state = "leave"
	st = 3.0
	say("Nothing to steal. Lame.")
	return Vector2.ZERO

func _ai_karen(delta: float, to: Vector2, dist: float) -> Vector2:
	st -= delta
	if state == "tele":
		if st <= 0.0:
			state = "roam"
			act_cd = 2.2 if buddy else 1.6
			throw("complaint", to.normalized() * 85.0, 7.0)
		return Vector2.ZERO
	act_cd -= delta
	if dist < 130.0 and act_cd <= 0.0:
		state = "tele"
		st = 0.5
		return Vector2.ZERO
	if dist > 140.0:
		return _wander(delta)
	if dist < 55.0:
		return -to.normalized() * speed
	if dist > 85.0:
		return to.normalized() * speed
	return to.normalized().orthogonal() * speed * 0.6 * (1.0 if int(t / 2.0) % 2 == 0 else -1.0)

func _ai_drunk(delta: float, to: Vector2, dist: float) -> Vector2:
	st -= delta
	if state == "tele":
		if st <= 0.0:
			state = "lunge"
			st = 0.35
			charge_dir = to.normalized()
		return Vector2.ZERO
	if state == "lunge":
		if st <= 0.0:
			state = "roam"
			act_cd = randf_range(2.0, 3.2)
		return charge_dir * 120.0
	act_cd -= delta
	if dist < 40.0 and act_cd <= 0.0:
		state = "tele"
		st = 0.6
		say("C'mere, buddy...", 0.6)
		return Vector2.ZERO
	var sway: = to.normalized().orthogonal() * sin(t * 2.3) * speed * 0.9
	return to.normalized() * speed + sway

func _ai_heckler(delta: float, to: Vector2, dist: float) -> Vector2:
	st -= delta
	if state == "tele":
		if st <= 0.0:
			state = "roam"
			act_cd = 2.0
			throw("mug", to.normalized() * 90.0, 6.0)
		return Vector2.ZERO
	act_cd -= delta
	if dist < 140.0 and act_cd <= 0.0:
		state = "tele"
		st = 0.55
		return Vector2.ZERO
	if dist < 50.0:
		return -to.normalized() * speed
	if dist > 90.0:
		return to.normalized() * speed
	return to.normalized().orthogonal() * speed * 0.7 * (1.0 if int(t / 2.0) % 2 == 0 else -1.0)

func _ai_hoa(delta: float, to: Vector2, dist: float) -> Vector2:
	st -= delta
	if state == "tele":
		if st <= 0.0:
			state = "roam"
			act_cd = 3.0
			var pr: = throw("citation", to.normalized() * 70.0, 4.0)
			pr.money_cost = 5
		return Vector2.ZERO
	act_cd -= delta
	if dist < 120.0 and act_cd <= 0.0:
		state = "tele"
		st = 0.8
		say("*writing you up*", 0.8)
		return Vector2.ZERO
	if dist < 150.0:
		return to.normalized() * speed
	return _wander(delta)

func _ai_hustler(delta: float, to: Vector2, dist: float) -> Vector2:
	st -= delta
	match state:
		"leave":
			if st <= 0.0:
				m.enemy_gone(self)
			return -to.normalized() * 45.0
		"tele":
			if st <= 0.0:
				state = "lunge"
				st = 0.3
				charge_dir = to.normalized()
			return Vector2.ZERO
		"lunge":
			if dist < 14.0 and contact_cd <= 0.0:
				contact_cd = 3.0
				state = "roam"
				m.enemy_touch(self)
				return Vector2.ZERO
			if st <= 0.0:
				state = "roam"
				act_cd = 1.0
			return charge_dir * 100.0
	act_cd -= delta
	if dist < 28.0 and act_cd <= 0.0:
		state = "tele"
		st = 0.4
		say("Got a minute?!", 1.0)
		return Vector2.ZERO
	if dist < 130.0:
		return to.normalized() * speed
	return _wander(delta)

func _ai_pete(delta: float, to: Vector2, dist: float) -> Vector2:
	st -= delta
	match state:
		"tele":
			if st <= 0.0:
				_pete_attack(to)
			return Vector2.ZERO
		"charge":
			if st <= 0.0:
				state = "roam"
				act_cd = 2.2
			return charge_dir * 190.0
	act_cd -= delta
	if dist < 160.0 and act_cd <= 0.0:
		next_attack = ["flipflop", "charge", "fireworks"][randi() % 3] if next_attack == "" else next_attack
		state = "tele"
		st = {"flipflop": 0.6, "charge": 0.75, "fireworks": 1.0 }[next_attack]
		say(TELE_LINES[next_attack], st + 0.4)
		return Vector2.ZERO
	if dist > 160.0:
		return _wander(delta)
	if dist > 60.0:
		return to.normalized() * speed
	return to.normalized().orthogonal() * speed * (1.0 if int(t / 1.5) % 2 == 0 else -1.0)

func _pete_attack(to: Vector2) -> void:
	match next_attack:
		"flipflop":
			var pr: = throw("flipflop", to.normalized() * 120.0, 6.0)
			pr.boomer_t = 0.7
			state = "roam"
			act_cd = 2.4
		"charge":
			state = "charge"
			st = 0.6
			charge_dir = to.normalized()
		"fireworks":
			for i in 10:
				throw("firework", Vector2.from_angle(TAU * i / 10.0 + t) * 60.0, 4.0)
			state = "roam"
			act_cd = 3.0
	var order: = ["flipflop", "charge", "fireworks"]
	next_attack = order[(order.find(next_attack) + 1 + randi() % 2) % 3]

func _ai_driver(delta: float) -> void:
	st -= delta
	var axis: = str(lane.get("axis", "h"))
	var dir: = float(lane.get("dir", 1))
	if state == "tele":
		if st <= 0.0:
			state = "charge"
		return
	var mv: = (Vector2(dir, 0) if axis == "h" else Vector2(0, dir)) * speed * delta
	position += mv
	var p: CharacterBody2D = m.player
	if not hit_done and absf(p.global_position.x - global_position.x) < (12.0 if axis == "h" else 7.0) and absf(p.global_position.y + 3.0 - global_position.y) < (7.0 if axis == "h" else 12.0):
		if m.hurt_player(18.0, global_position - mv * 4.0, 260.0, "driver"):
			hit_done = true
			say("WATCH WHERE YOU'RE WALKING!")
	if position.x < -60 or position.x > 700 or position.y < -60 or position.y > 420:
		m.enemy_gone(self)

func throw(k: String, vel: Vector2, dmg: float) -> Node2D:
	var pr: = Proj.new()
	pr.m = m
	pr.kind = k
	pr.vel = vel
	pr.dmg = dmg
	pr.thrower = self
	pr.position = global_position + Vector2(0, -2)
	get_parent().add_child(pr)
	return pr

func take_hit(dir: Vector2, dmg: float, special: String = "") -> float:
	if kind == "driver":
		say("HEY! THAT'S A LEASE!")
		return 0.0
	var d: = dmg
	if kind == "hoa":
		d = dmg if special == "pierce" else maxf(0.5, dmg - 0.5)
	hp -= d
	flash = 0.15
	var kb: = 200.0 * (1.6 if special == "flip" else 1.0) * (0.4 if kind in ["hoa", "pete"] else 1.0)
	knock = dir * kb
	if special == "stun":
		stun = 0.8
		if telegraphing():
			state = "roam"
			act_cd = 1.0
	if kind == "karen" and not buddy and not summoned and hp > 0.0 and hp <= max_hp * 0.5:
		summoned = true
		say("I WANT TO SPEAK TO THE MANAGER! LINDA!!", 2.5)
		m.spawn_enemy("karen", global_position + Vector2(24, -10), {"buddy": true })
	if hp <= 0.0:
		m.enemy_defeated(self)
	return d

func _draw() -> void:
	var f: = ThemeDB.fallback_font
	var w: = Color.WHITE if flash > 0.0 else Color(0, 0, 0, 0)
	var tele: = telegraphing() and int(t * 12.0) % 2 == 0
	match kind:
		"driver": _draw_driver()
		"drone": Art.frame(self, "drone", Vector2(0, -2), int(t * 14.0) % 2, 0, _mod())
		"nft": Art.image(self, "nft", Vector2(0, -2 + sin(t * 5.0) * 1.5), _mod())
		"pete": _draw_pete()
		_: _draw_person()
	if tele and kind != "driver":
		draw_string(f, Vector2(-2, -14), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#ff4040"))
	if stun > 0.0:
		for i in 3:
			draw_circle(Vector2(cos(t * 8.0 + i * 2.1) * 6.0, -13.0), 1.2, Color("#ffe040"))
	if hp < max_hp and kind != "driver":
		if m != null and m.get("combat") != null:
			var lv: int = int(m.combat.ENEMY_LEVEL.get(kind, 3))
			var lc: Color = Color("#ff6060") if lv > m.combat.level + 2 else (Color("#a0a0a0") if lv < m.combat.level - 3 else Color("#f0ead8"))
			draw_string(f, Vector2(-8, 19), "Lv%d" % lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, lc)
		draw_rect(Rect2(-8, 12, 16, 2), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-8, 12, 16.0 * clampf(hp / max_hp, 0, 1), 2), Color("#ff5050") if kind != "pete" else Color("#ff9020"))
	if kind == "pirate" and hp >= max_hp and pname != "":
		var nm: = display_name()
		var nw: = f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 5).x
		draw_string(f, Vector2(-nw / 2.0, 19), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("#ffd0a0"))
	# speech bubble: drawn by main's Barks node (scripts/barks.gd), laid out with everyone else's
	if w.a > 0.0:
		pass

func _draw_driver() -> void:
	var axis: = str(lane.get("axis", "h"))
	var dir: = float(lane.get("dir", 1))
	var f: = ThemeDB.fallback_font
	if state == "tele" and m and m.player:

		var p: Vector2 = m.player.global_position
		var on: = int(t * 10.0) % 2 == 0
		var col: = Color(1, 0.2, 0.2, 0.55 if on else 0.25)
		if axis == "h":
			for x in range(-700, 700, 16):
				draw_rect(Rect2(x - position.x * 0.0, -2, 8, 3), col)
			draw_string(f, Vector2(p.x - global_position.x - 12, -10), "HONK!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#ff4040"))
		else:
			for y in range(-420, 420, 16):
				draw_rect(Rect2(-2, y, 3, 8), col)
			draw_string(f, Vector2(-12, p.y - global_position.y - 10), "HONK!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#ff4040"))

	if axis == "h":
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
		Art.image(self, "truck_h", Vector2.ZERO)
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, dir))
		Art.image(self, "truck_v", Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

const Art: = preload("res://scripts/art.gd")
const AudioScript: = preload("res://scripts/audio.gd")

func sprite_name() -> String:
	if kind == "karen" and buddy:
		return "ch_karen_buddy"
	if kind == "pirate":
		return "ch_pirate%d" % (absi(hash(pname)) % 4)
	return "ch_" + kind

func _mod() -> Color:
	return Color(1, 0.45, 0.45) if flash > 0.0 else Color.WHITE

func _look() -> Vector2:
	if velocity.length() > 4.0:
		return velocity
	if m != null and is_instance_valid(m) and m.get("player") != null:
		return m.player.global_position - global_position
	return Vector2.DOWN

func _draw_person() -> void:
	if m != null and m.has_method("on_fight_floor") and m.on_fight_floor():   # match Duff + bosses on painted fight floors
		var k: float = m.STAGE_SCALE * 0.9
		draw_set_transform(Vector2(0, 11.0 * (1.0 - k)), 0.0, Vector2(k, k))
	Art.person(self, sprite_name(), Vector2(0, 11), _look(), t, velocity.length() > 4.0, telegraphing(), _mod())
	if kind == "pirate" and loot != "":
		Art.image(self, "package", Vector2(9, 6))

func _draw_pete() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.3, 1.3))
	Art.person(self, "ch_pete", Vector2(0, 8.5), _look(), t, velocity.length() > 4.0, state == "charge" or telegraphing(), _mod())
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "charge":
		draw_line(-charge_dir * 6.0, -charge_dir * 16.0, Color(1, 1, 1, 0.6), 2.0)
