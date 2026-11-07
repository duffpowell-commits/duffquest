extends CharacterBody2D

const Proj: = preload("res://scripts/projectile.gd")
const Cast: = preload("res://scripts/cast.gd")

const BOSSES: = {
	"husk": {"name": "Elon Husk", "hp": 260.0, "attacks": ["posting", "rocket"],
		"intro": "Elon Husk: I bought this gala at 4 AM. Also your landlord. Also the concept of Tuesday.",
		"taunts": ["Free speech means I talk and you get rate-limited.", "Your apron is now a paid subscription.", "Self-punching in two weeks. It's been nine years.", "I'm not a billionaire. I'm a meme with a lawyer."],
		"rage": "Elon Husk: Fine. I'm posting a poll about whether you deserve to live.",
		"defeat": "Elon Husk: Losing builds character. I'll buy one tomorrow." },
	"bozos": {"name": "Jeff Bozos", "hp": 280.0, "attacks": ["drones", "shine"],
		"intro": "Jeff Bozos: Your beating ships today! Bathroom breaks not included for the driver.",
		"taunts": ["My warehouse workers get TWO pee bottles. Generous.", "Customers who fought me also bought: medical debt.", "I went to space so I'd never hear 'union' again.", "Your rating dropped to four stars. You're fired."],
		"rage": "Jeff Bozos: Activating surge pain! Now 30% more efficient!",
		"defeat": "Jeff Bozos: Fine. I'll write it off. I write EVERYTHING off." },
	"fences": {"name": "Bill Fences", "hp": 280.0, "attacks": ["bsod", "update"],
		"intro": "Bill Fences: Hello, user. Your defeat has been installed without consent.",
		"taunts": ["Restarting your life to apply updates.", "I solved poverty in a TED Talk. You're welcome.", "Your license for 'breathing' has expired.", "This beating is 64% complete. Estimated time: forever."],
		"rage": "Bill Fences: Initiating philanthropy! It's tax-deductible violence!",
		"defeat": "Bill Fences: Fatal error. I'll start a foundation about it." },
	"baron": {"name": "{gala_baron}", "hp": 300.0, "attacks": ["hire", "coins"],
		"intro": "{gala_baron}: A WORKER? At my gala? Jeeves, sanitize the chandelier.",
		"taunts": ["My trust fund has a trust fund. And an intern.", "I've never worked a day. It's EXHAUSTING.", "Bootstraps? Darling, I was born in a boot.", "Is that a name tag? How very... employed."],
		"rage": "{gala_baron}: Jeeves! Hire MORE help! Minimum wage, maximum loyalty!",
		"defeat": "{gala_baron}: My monocle! My yacht slip! Mummy will hear of this!" },
	"donald": {"name": "The Donald", "hp": 360.0, "attacks": ["tariff", "wall"],
		"intro": "The Donald: Tremendous gala. Paid for by a charity I may or may not have closed.",
		"taunts": ["Nobody's ever been sued more. Big league.", "Tariffs on spatulas. You'll pay. I won't.", "Your apron? Very low ratings. Sad.", "I declared bankruptcy six times. Ask me how I'm still rich."],
		"rage": "The Donald: Everybody's saying I'm winning. Mostly me. I'm saying it.",
		"defeat": "The Donald: Rigged! I'm counting this as a win anyway. Tremendous loss." },

	"ghoster": {"name": "{ex_1}", "hp": 32.0, "attacks": ["seen", "vanish"],
		"intro": "{ex_1}: hey! been sooo busy. with what? ...growth. personal growth. mostly naps.",
		"taunts": ["Seen 3:12 AM.", "my therapist says I'm 'avoidant.' I left her on read.", "let's circle back. (never)", "u up? (it's noon)"],
		"rage": "{ex_1}: ...typing... ...typing... ...typing...",
		"defeat": "{ex_1}: k. (He vanishes. Like he always does. At least he's consistent.)" },
	"gymbro": {"name": "{ex_2}", "hp": 60.0, "attacks": ["curl", "flex", "charge"],
		"intro": "{ex_2}: Bro. She's with a LINE COOK? I sell a 6-week mindset course. It's 4 weeks long.",
		"taunts": ["Rise and grind. I don't sleep, I invoice.", "My protein powder sponsors my personality.", "Discipline is just free motivation, bro. Pay me to explain.", "Leg day is for people without a brand."],
		"rage": "{ex_2}: BEAST MODE! This is literally content right now!",
		"defeat": "{ex_2}: My gains... my sponsorship... link in bio..." },
	"djvape": {"name": "{ex_3}", "hp": 75.0, "attacks": ["drop", "vape"],
		"intro": "{ex_3}: Yo. I'm a brand ambassador for a vape that's not legal in 4 states. It's a vibe.",
		"taunts": ["Exposure is basically money, bro.", "This track samples my rent notice.", "I'm not unemployed. I'm 'between drops.'", "Smash that follow. My landlord accepts follows."],
		"rage": "{ex_3}: THE DROP is coming. Like my royalties. Any month now.",
		"defeat": "{ex_3}: The venue paid me in drink tickets... again." },
	"crypto": {"name": "{ex_4}", "hp": 90.0, "attacks": ["nft", "rug"],
		"intro": "{ex_4}: HoneyBunCoin, bro. Decentralized pastries. The whitepaper is a napkin.",
		"taunts": ["It's not a Ponzi. Ponzi had a business plan.", "Have fun staying solvent!", "I'm not broke, I'm pre-rich.", "Tokenize your trauma. Ask me how."],
		"rage": "{ex_4}: Liquidity event! I'm liquidating YOUR liquidity!",
		"defeat": "{ex_4}: Down 100%... but up spiritually. That's still a gain, right?" },

	"willnot": {"name": "{ex_final}", "hp": 200.0, "attacks": ["spray", "vent"],
		"intro": "{ex_final}: Took you long enough, fry boy. I own forty floors and zero shoes.",
		"taunts": ["Every tower needs a guy in a tank top. I'm management.", "I fought terrorists once. Now I fight HR.", "Glass on the floor? That's the corporate culture.", "Forty floors and the vending machine still eats dollars."],
		"rage": "{ex_final}: Party's over, fry cook. I'm calling security. I AM security.",
		"defeat": "{ex_final}: My feet... why is it ALWAYS glass... who decorates these places..." },

	"regular": {"name": "The Regular", "hp": 300.0, "attacks": ["curl", "hire", "charge", "curl"],
		"swap": {"dumbbell": "mug" }, "minion": "drunk",
		"tele": {"curl": "*slurps coffee. Loudly.*", "hire": "BOYS! BOOTH FOUR! NOW!", "charge": "I've sat on that stool since 1994!" },
		"intro": "The Regular: That's MY stool, son. Sat on it since 1994. The stool knows my name. It's Earl. I'm also Earl.",
		"taunts": ["Refill. REFILL. I'm not asking twice. I'm asking forty times.", "Back in my day hash browns cost a nickel and a war.", "I tip in exact change. And advice.", "The last cook cried. He's a dentist now. Happier, too."],
		"rage": "The Regular: That's it. I'm putting down my coffee. NOBODY has seen me put down my coffee.",
		"defeat": "The Regular: ...Good hash browns, kid. Real good. Same time tomorrow." },

	"sendback": {"name": "Sir Sends-It-Back", "hp": 130.0, "attacks": ["posting", "charge"],
		"labels": {"post": "1 STAR" }, "tele": {"posting": "This is TOO medium.", "charge": "I'm coming BACK there." },
		"intro": "Sir Sends-It-Back: I ordered it medium-rare-well. You brought me FOOD. Unacceptable.",
		"taunts": ["Is this water or TAP water?", "I'm a food blogger. 14 followers. All bots. All furious.", "Send it back. No, the plate. No, the building.", "My compliments to the chef. They're all complaints."],
		"rage": "Sir Sends-It-Back: I want a refund. On this FIGHT.",
		"defeat": "Sir Sends-It-Back: ...This beating is cooked perfectly. Five stars. Still not tipping." },
	"coupon": {"name": "Coupon Carol", "hp": 150.0, "attacks": ["coins", "update"],
		"labels": {"coin": "%", "trap": "EXP" }, "tele": {"coins": "These are DEFINITELY still valid!", "update": "Expired? It's EXTENDED. In my heart." },
		"intro": "Coupon Carol: 46 coupons, sweetie. Every one's for a different restaurant. Honor ALL of them.",
		"taunts": ["This one's from 2009. It's vintage. It's worth MORE.", "BOGO means the second beating is free.", "I'd like to stack these. Physically. On you.", "Do you price match? I'm matching THIS price: zero."],
		"rage": "Coupon Carol: Fine! I'm using the NUCLEAR coupon. The one from the phone book!",
		"defeat": "Coupon Carol: ...Is there a coupon for getting beat up? Asking for me." },
	"allergy": {"name": "The Allergy Liar", "hp": 160.0, "attacks": ["seen", "vanish", "seen"],
		"labels": {"seen": "ONION" }, "pop": "pop", "pop_line": "SURPRISE! Extra onions!",
		"tele": {"seen": "I'm DEATHLY allergic! Extra please!", "vanish": "*goes to 'check her EpiPen'*", "pop": "SURPRISE! Extra onions!" },
		"intro": "The Allergy Liar: I'm deathly allergic to onions. Anyway, the onion rings, please. Hold the guilt.",
		"taunts": ["Gluten-free! On a regular bun! Toasted in gluten!", "I'm lactose intolerant. Of your attitude.", "It's not an allergy, it's a PREFERENCE. In red ink.", "Can you make it vegan but with bacon?"],
		"rage": "The Allergy Liar: You made me break out! In RAGE!",
		"defeat": "The Allergy Liar: ...Okay. I'm not allergic. I just like the drama. And the free dessert." },
	"camper": {"name": "The Four-Hour Camper", "hp": 170.0, "attacks": ["flex", "curl", "curl"],
		"swap": {"dumbbell": "mug" }, "flex_line": "Still drinking that. (Cup's empty.)",
		"tele": {"flex": "*opens 47 browser tabs*", "curl": "Refill? And another? And another?" },
		"intro": "The Four-Hour Camper: One coffee. Four hours. Six outlets. I'm building a startup. It's an app that finds outlets.",
		"taunts": ["What's the wifi password? ...What's the NEW one?", "I'm not loitering, I'm networking. With the outlet.", "Can you turn the music down? I'm on a call. With my mom.", "I'll order when the vibe is right. The vibe is never right."],
		"rage": "The Four-Hour Camper: My laptop's at 3%! This is a CRISIS!",
		"defeat": "The Four-Hour Camper: Fine. I'll go to the library. Outlets AND quiet. Why did I ever leave?" },
	"bdaydad": {"name": "Birthday Party Dad", "hp": 220.0, "attacks": ["hire", "coins", "charge"], "minion": "kid",
		"tele": {"hire": "Kids! Go say hi to the nice cook!", "coins": "Here's a TIP: thirty-seven cents!", "charge": "I have a RESERVATION. In my HEART!" },
		"intro": "Birthday Party Dad: Table for nineteen. No reservation. Fourteen kids. Separate checks. I brought my own cake. You'll cut it.",
		"taunts": ["Can you sing? It's on the menu. I made it the menu.", "The kids want nuggets shaped like your will to live.", "I'm a 'cool dad.' I said 'yeet' once. On purpose.", "Do you have a kids menu for adults?"],
		"rage": "Birthday Party Dad: Who wants CAKE?! (He means to throw it.)",
		"defeat": "Birthday Party Dad: ...Kids, we're leaving. Say thank you to the nice cook. Not you, Tanner. You bit him." },
	"dasher": {"name": "The Dine-and-Dasher", "hp": 250.0, "attacks": ["charge", "vanish", "rug"],
		"labels": {"seen": "$0.00", "rug": "NO TIP" }, "pop": "pop", "pop_line": "Check, please! (He's running.)",
		"tele": {"charge": "*eyeing the exit*", "vanish": "*bathroom break (forever)*", "rug": "Put it on my tab! (No tab exists.)", "pop": "Check, please!" },
		"intro": "The Dine-and-Dasher: Steak, lobster, three shakes and a pie to go. Oh, my wallet's in my other... (He's already running.)",
		"taunts": ["My card's in my other pants. My other pants are in my other life.", "I don't dash. I sprint with purpose.", "Venmo you later! (He has no phone.)", "Tipping is a social construct. So is paying."],
		"rage": "The Dine-and-Dasher: You'll never catch me! I did CARDIO for this!",
		"defeat": "The Dine-and-Dasher: Okay okay! Here's the money. And the pie. It's been a weird night." },
}
const VENTS: = [Vector2(40, 52), Vector2(280, 52), Vector2(40, 152), Vector2(280, 152)]
const TELE: = {
	"posting": [0.6, "Hold on, just posting..."], "rocket": [0.35, "LAUNCH!"],
	"drones": [0.7, "Same-day harm incoming!"], "shine": [0.2, "*belt buckle gleams*"],
	"bsod": [0.8, "Have you tried turning it off and on?"], "update": [0.5, "Mandatory update!"],
	"hire": [0.7, "Jeeves! Fetch the unpaid interns!"], "coins": [0.7, "*monocle glints*"],
	"tariff": [0.8, "TARIFF! (You pay it.)"], "wall": [0.4, "A beautiful wall. Somebody else's money."],
	"seen": [0.5, "*Seen*"], "vanish": [0.4, "brb"], "pop": [0.45, "u up?"],
	"curl": [0.6, "Curl for the algorithm, bro!"], "flex": [0.3, "Check out these GUNS!"], "charge": [0.7, "LEG DAY? NEVER HEARD OF IT!"],
	"drop": [0.9, "Wait for it... wait for it..."], "vape": [0.6, "*long inhale*"],
	"nft": [0.7, "Minting! Early investors only!"], "rug": [0.4, "Trust the roadmap, bro."],
	"spray": [0.5, "*ka-chunk*"], "vent": [0.4, "*crawls into the air vent*"],
}

var m: Node = null
var kind: = "husk"
var hp: = 160.0
var max_hp: = 160.0
var state: = "intro"
var st: = 1.0
var act_cd: = 1.5
var atk_i: = 0
var cur: = ""
var flash: = 0.0
var knock: = Vector2.ZERO
var line: = ""
var line_t: = 0.0
var taunt_cd: = 6.0
var enraged: = false
var contact_cd: = 0.0
var t: = 0.0
var stun: = 0.0
var stolen: = 0
var buddy: = false
var hidden_t: = 0.0
var pop_pos: = Vector2.ZERO
var flex_t: = 0.0
var dash_t: = 0.0
var dash_v: = Vector2.ZERO

func _ready() -> void:
	add_to_group("hostile")
	add_to_group("enemy")
	add_to_group("boss")
	max_hp = float(BOSSES[kind]["hp"])
	hp = max_hp
	collision_layer = 4
	collision_mask = 1
	var cs: = CollisionShape2D.new()
	var c: = CircleShape2D.new()
	c.radius = 8.0
	cs.shape = c
	add_child(cs)

func display_name() -> String:
	return Cast.T(str(BOSSES[kind]["name"]))

func say(s: String, dur: float = 2.2) -> void:
	line = Cast.T(s)
	line_t = dur

func telegraphing() -> bool:
	return state == "tele"

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta)
	line_t = maxf(0.0, line_t - delta)
	contact_cd = maxf(0.0, contact_cd - delta)
	stun = maxf(0.0, stun - delta)
	if m == null or m.player == null:
		return
	var p: CharacterBody2D = m.player
	var to: Vector2 = p.global_position - global_position
	var dist: = to.length()
	var calm: bool = not m.dialog.is_empty()
	var v: = Vector2.ZERO
	if not calm:
		flex_t = maxf(0.0, flex_t - delta)
		if hidden_t > 0.0:
			hidden_t -= delta
			if hidden_t <= 0.0:
				_pop_out()
			queue_redraw()
			return
		if dash_t > 0.0:
			dash_t -= delta
			velocity = dash_v
			move_and_slide()
			if dist < 15.0 and contact_cd <= 0.0 and m.hurt_player(12.0, global_position, 260.0, "charge"):
				contact_cd = 1.0
			queue_redraw()
			return
		if kind == "willnot" and stun <= 0.0:
			_check_glass()
	if not calm and stun <= 0.0:
		st -= delta
		taunt_cd -= delta
		if taunt_cd <= 0.0 and state == "roam":
			taunt_cd = randf_range(6.0, 9.0)
			var tl: Array = BOSSES[kind]["taunts"]
			say(tl[randi() % tl.size()])
		match state:
			"intro":
				if st <= 0.0:
					state = "roam"
			"roam":
				act_cd -= delta
				if act_cd <= 0.0:
					var atks: Array = BOSSES[kind]["attacks"]
					cur = atks[atk_i % atks.size()]
					atk_i += 1
					state = "tele"
					AudioScript.sfx("tele")
					st = float(TELE[cur][0])
					say(str(_opt("tele", cur, TELE[cur][1])), st + 0.6)
				elif flex_t > 0.0:
					v = Vector2.ZERO
				elif dist > 90.0:
					v = to.normalized() * 36.0
				elif dist < 55.0:
					v = -to.normalized() * 30.0
				else:
					v = to.normalized().orthogonal() * 28.0 * (1.0 if int(t / 2.5) % 2 == 0 else -1.0)
			"tele":
				if st <= 0.0:
					_attack(to)
					state = "roam"
					act_cd = (2.2 if not enraged else 1.5) + randf() * 0.6
	velocity = v + knock
	knock = knock.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()
	if dist < 14.0 and contact_cd <= 0.0 and not calm:
		if m.hurt_player(8.0, global_position, 200.0, "boss"):
			contact_cd = 1.0
	queue_redraw()

func _opt(key: String, sub: String, fallback):
	var d = BOSSES[kind].get(key, {})
	return d.get(sub, fallback) if typeof(d) == TYPE_DICTIONARY else fallback

func minion_kind() -> String:
	return str(BOSSES[kind].get("minion", "butler"))

func _proj(k: String, pos: Vector2, vel: Vector2, dmg: float) -> Node2D:
	var pr: = Proj.new()
	pr.m = m
	pr.label = str(_opt("labels", k, ""))
	k = str(_opt("swap", k, k))
	pr.kind = k
	pr.vel = vel
	pr.dmg = dmg
	pr.thrower = self
	pr.position = pos
	get_parent().add_child(pr)
	return pr

func _minions(k: String) -> int:
	var n: = 0
	for e in m.live_enemies():
		if e.kind == k:
			n += 1
	return n

const AudioScript: = preload("res://scripts/audio.gd")
const ATTACK_SFX: = {"rocket": "whoosh", "shine": "laser", "spray": "gun", "coins": "coin", "drones": "whoosh", "bsod": "fail", "tariff": "honk", "nft": "coin", "drop": "explosion", "vape": "hiss" }

func _attack(to: Vector2) -> void:
	var p: Vector2 = m.player.global_position
	if ATTACK_SFX.has(cur):
		AudioScript.sfx(str(ATTACK_SFX[cur]))
	var aim: = to.normalized()
	match cur:
		"posting":
			var n: = 7 if enraged else 5
			for i in n:
				var a: = aim.rotated((i - (n - 1) / 2.0) * 0.22)
				_proj("post", global_position, a * 95.0, 6.0)
		"rocket":
			var offs: = [Vector2.ZERO, Vector2(22, 10), Vector2(-20, 14), Vector2(10, -22), Vector2(-14, -18)]
			for i in (5 if enraged else 3):
				var s: = _proj("strike", p + offs[i], Vector2.ZERO, 14.0)
				s.fuse = 1.0 + i * 0.15
				s.life = 2.0
		"drones":
			for i in mini(3, 6 - _minions("drone")):
				m.spawn_enemy("drone", global_position + Vector2.from_angle(TAU * i / 3.0) * 14.0)
		"shine":
			for i in (2 if enraged else 1):
				var l: = _proj("laser", global_position + Vector2(0, -12), Vector2.ZERO, 12.0)
				l.dir = aim.rotated(0.35 * i * (1 if i % 2 == 0 else -1))
				l.fuse = 0.9
				l.life = 1.3
		"bsod":
			var w: = _proj("wave", global_position, Vector2.ZERO, 5.0)
			w.fuse = 0.2
			w.life = 3.0
		"update":
			var spots: = [Vector2.ZERO, Vector2(24, 0), Vector2(-24, 0), Vector2(0, 22), Vector2(0, -22)]
			for i in (5 if enraged else 3):
				var tr: = _proj("trap", p + spots[i], Vector2.ZERO, 4.0)
				tr.fuse = 1.2
				tr.life = 7.0
		"hire":
			for i in mini(3 if not enraged else 4, 6 - _minions(minion_kind())):
				m.spawn_enemy(minion_kind(), global_position + Vector2.from_angle(TAU * i / 3.0 + 0.5) * 16.0)
		"coins":
			var n2: = 11 if enraged else 9
			for i in n2:
				_proj("coin", global_position, aim.rotated((i - (n2 - 1) / 2.0) * 0.16) * 100.0, 5.0)
		"tariff":
			var tf: = _proj("tariff", global_position, aim * 55.0, 12.0)
			tf.boomer_t = 1.3
		"seen":
			var ns: = 5 if enraged else 3
			for i in ns:
				_proj("seen", global_position, aim.rotated((i - (ns - 1) / 2.0) * 0.3) * 85.0, 6.0)
		"vanish":
			hidden_t = 1.2 if enraged else 1.6
			var off: = Vector2.from_angle(randf() * TAU) * 42.0
			pop_pos = _clamp_arena(p + off)
		"pop":
			var nr: = 8 if enraged else 6
			for i in nr:
				_proj("seen", global_position, Vector2.from_angle(TAU * i / nr) * 70.0, 6.0)
		"curl":
			var nc: = 3 if enraged else 2
			for i in nc:
				var db: = _proj("dumbbell", global_position, aim.rotated((i - (nc - 1) / 2.0) * 0.35) * 70.0, 10.0)
				db.life = 3.0
		"flex":
			flex_t = 1.6 if enraged else 2.0
		"charge":
			dash_t = 0.6
			dash_v = aim * (190.0 if enraged else 165.0)
		"drop":
			var bw: = _proj("bass", global_position, Vector2.ZERO, 6.0)
			bw.fuse = 0.15
			bw.life = 3.0
			if enraged:
				var bw2: = _proj("bass", global_position, Vector2.ZERO, 6.0)
				bw2.fuse = 0.9
				bw2.life = 3.6
		"vape":
			var nv: = 5 if enraged else 3
			for i in nv:
				var cl: = _proj("cloud", _clamp_arena(p + (Vector2.ZERO if i == 0 else Vector2.from_angle(TAU * i / nv) * 34.0)), Vector2.ZERO, 3.0)
				cl.fuse = 0.8
				cl.life = 5.0
		"nft":
			for i in mini(3, 5 - _minions("nft")):
				m.spawn_enemy("nft", global_position + Vector2.from_angle(TAU * i / 3.0) * 16.0)
		"rug":
			var rg: = _proj("rug", p, Vector2.ZERO, 12.0)
			rg.size = Vector2(70, 40) if not enraged else Vector2(90, 50)
			rg.fuse = 1.1
			rg.life = 2.0
		"spray":
			var nb: = 14 if enraged else 10
			for i in nb:
				var bl: = _proj("bullet", global_position, aim.rotated(-0.6 + 1.2 * i / float(nb - 1)) * 150.0, 4.0)
				bl.life = 2.0
			for i in 2:
				var gl: = _proj("glass", _clamp_arena(global_position + Vector2.from_angle(randf() * TAU) * randf_range(20.0, 70.0)), Vector2.ZERO, 0.0)
				gl.life = 14.0
		"vent":
			hidden_t = 1.5 if enraged else 2.2
			var best: = Vector2.ZERO
			var bd: = -1.0
			for vp in VENTS:
				var wp: Vector2 = m.ARENA_ORIGIN + vp
				var d: = wp.distance_to(global_position) + randf() * 40.0
				if d > bd:
					bd = d
					best = wp
			pop_pos = best
		"wall":
			var side: = aim.orthogonal()
			var vertical: = absf(side.x) < absf(side.y)
			var sz: = Vector2(8, 44) if not vertical else Vector2(44, 8)
			for sgn in [-1.0, 1.0]:
				var wl: = _proj("wall", p + side * 22.0 * sgn, Vector2.ZERO, 8.0)
				wl.size = sz
				wl.fuse = 0.9
				wl.life = 3.0
			if enraged:
				var wl2: = _proj("wall", p - aim * 26.0, Vector2.ZERO, 8.0)
				wl2.size = Vector2(44, 8) if not vertical else Vector2(8, 44)
				wl2.fuse = 0.9
				wl2.life = 3.0

func _clamp_arena(pt: Vector2) -> Vector2:
	var o: Vector2 = m.ARENA_ORIGIN
	return Vector2(clampf(pt.x, o.x + 20.0, o.x + m.ARENA_SIZE.x - 20.0), clampf(pt.y, o.y + 40.0, o.y + m.ARENA_SIZE.y - 20.0))

func _pop_out() -> void:

	position = pop_pos
	state = "tele"
	cur = str(BOSSES[kind].get("pop", "pop" if kind == "ghoster" else "spray"))
	st = float(TELE[cur][0]) + (0.25 if kind == "willnot" else 0.0)
	say(str(BOSSES[kind].get("pop_line", "*CLANG* Surprise, chef!" if kind == "willnot" else "u up?")), st + 0.6)

func _check_glass() -> void:
	for g in get_tree().get_nodes_in_group("projectile"):
		if is_instance_valid(g) and not g.is_queued_for_deletion() and g.kind == "glass" and g.global_position.distance_to(global_position + Vector2(0, 8)) < 10.0:
			g.queue_free()
			stun = 1.6
			state = "roam"
			act_cd = maxf(act_cd, 1.6)
			flash = 0.2
			say("OW! Glass! Why am I ALWAYS barefoot?!", 1.6)
			return

func take_hit(dir: Vector2, dmg: float, special: String = "") -> float:
	if state == "intro" or hidden_t > 0.0:
		return 0.0
	if flex_t > 0.0:
		say(str(BOSSES[kind].get("flex_line", "Can't hurt these GUNS, bro!")), 1.0)
		flash = 0.05
		return 0.0
	hp -= dmg
	flash = 0.12
	knock = dir * 90.0
	if special == "stun":
		stun = 0.4
	if not enraged and hp <= max_hp * 0.5 and hp > 0.0:
		enraged = true
		say(str(BOSSES[kind]["rage"]), 2.5)
	if hp <= 0.0:
		m.boss_defeated(self)
	return dmg

func _draw() -> void:
	var f: = ThemeDB.fallback_font
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.45, 1.45))
	if hidden_t > 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_hidden(f)
		return
	_draw_sprite()
	if hidden_t > 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_hidden(f)
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "tele" and int(t * 12.0) % 2 == 0:
		draw_string(f, Vector2(-2, -22), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#ff4040"))
	if line_t > 0.0 and line != "":
		var sw: = f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		var bp: = Vector2(-sw / 2.0 - 2.0, -34.0)
		draw_rect(Rect2(bp, Vector2(sw + 4.0, 9)), Color(1, 1, 1, 0.92))
		draw_string(f, bp + Vector2(2, 7), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("#222222"))

const Art: = preload("res://scripts/art.gd")

func _look() -> Vector2:
	if m != null and is_instance_valid(m) and m.get("player") != null:
		return (m.player.global_position - global_position)
	return Vector2.DOWN

func _draw_sprite() -> void:

	var mod: = Color.WHITE
	if kind == "ghoster":
		mod = Color(1, 1, 1, 0.55 + 0.25 * sin(t * 3.0))
	if flash > 0.0:
		mod = Color(1, 0.45, 0.45, mod.a)
	var moving: = velocity.length() > 5.0 or dash_t > 0.0
	var atk: = state == "tele" or flex_t > 0.0
	Art.person(self, "ch_" + kind, Vector2(0, 11), _look(), t, moving, atk, mod)
	var f: = ThemeDB.fallback_font
	match kind:
		"bozos":
			var gleam: = 1.0 if (state == "tele" and cur == "shine") or int(t * 2.0) % 3 == 0 else 0.4
			draw_rect(Rect2(-1, 5, 2, 1), Color(1, 1, 0.7, gleam))
		"fences":
			if state == "tele":
				draw_rect(Rect2(6, -2, 6, 5), Color("#2050d0"))
				draw_string(f, Vector2(6, 2), ":(", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color.WHITE)
		"ghoster":
			draw_string(f, Vector2(-9, -14), "Seen", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.3, 0.5, 1.0, mod.a))
		"gymbro":
			if flex_t > 0.0:
				draw_string(f, Vector2(-9, -15), "FLEX", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("#ffd23f"))
		"camper":
			if flex_t > 0.0:
				draw_string(f, Vector2(-11, -15), "ON A CALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("#8ad0ff"))
		"djvape":
			draw_circle(Vector2(10, -2), 1.5 + sin(t * 4.0), Color(1, 1, 1, 0.5))

func _draw_hidden(f: Font) -> void:

	var lp: = pop_pos - global_position
	var shake: = Vector2(sin(t * 50.0), 0) * (1.5 if hidden_t < 0.8 else 0.5)
	if kind == "willnot":
		draw_string(f, lp + Vector2(-10, -14) + shake, "*clang*", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("#ffd23f"))
		draw_rect(Rect2(lp + Vector2(-9, -6) + shake, Vector2(18, 12)), Color(1, 0.3, 0.2, 0.35 if int(t * 10) % 2 == 0 else 0.15))
	else:
		draw_rect(Rect2(lp + Vector2(-12, -6), Vector2(24, 10)), Color(1, 1, 1, 0.7))
		draw_string(f, lp + Vector2(-10, 2), ".".repeat(1 + int(t * 3.0) % 3), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#555555"))
