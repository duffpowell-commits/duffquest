extends "res://scripts/minigames/minigame.gd"


const Dates: = preload("res://scripts/dates.gd")
const Tone: = preload("res://scripts/tone.gd")
const HIT_X: = 70.0
const SPEED: = 70.0
const LEAD: = 2.0
const PERFECT: = 0.1
const OK: = 0.22
const BETWEEN_T: = 3.5
const BRAVO_T: = 3.0
const DRESS: = {
	"top": [["Suit jacket", 1.0], ["Chef coat (clean-ish)", 0.3], ["Band tee", 0.0]], 
	"shoes": [["Dress shoes", 1.0], ["Work clogs", 0.5], ["Crocs (sport mode)", 0.1]], 
	"extra": [["A tie", 1.0], ["Spritz of {cologne}", 1.0], ["Nothing", 0.3]], 
}
const SNACKS: = [["wine", "Glass of wine for her ($12)", 12], ["pretzels", "Chocolate pretzels to share ($8)", 8], ["bun", "The honey bun in your coat pocket", 0], ["line", "Stand in the bathroom line (free)", 0]]
const RUN_T: = 6.0
const RUN_STEP: = 0.075
const RUN_DRIFT: = 0.12
const SLIP_GAP: = 0.16

var m: Node = null
var state: = "dress"
var dress: = {"top": 0, "shoes": 0, "extra": 0}
var style: = 0.0
var cologne_used: = false
var rideshare: = false
var bus_caught: = false
var slips: = 0
var run_t: = 0.0
var dist: = 0.0
var last_run: = -9.0
var ride_home: = ""
var late: = false
var mv: = 0
var mt: = 0.0
var times: Array = []
var judged: Array = []
var played: Array = []
var hits: = 0
var perfects: = 0
var misses: = 0
var total_notes: = 0
var awake: = 1.0
var snores: = 0
var clapped_between: = false
var clapped_mid: = 0
var bravo: = false
var phase_t: = 0.0
var snack: = ""
var spent: = 0
var say: = ""
var players: Array = []
var p_i: = 0
var audio: = true

func _setup() -> void :
	backdrop = "holland"
	music = "date"
	title = "{ORCHESTRA} @ {SYMPHONY_HALL}"
	time_limit = 0.0
	space_is_pen = false
	audio = bool(ctx.get("audio", true))
	for piece in Dates.PROGRAM:
		var ts: = Dates.note_times(piece)
		times.append(ts)
		var j: Array = []
		for _i in ts.size():
			j.append("")
		judged.append(j)
		played.append(0)
	if audio:
		for i in 4:
			var p: = AudioStreamPlayer.new()
			add_child(p)
			players.append(p)
	go(str(ctx.get("start", "dress")))

func go(s: String) -> void :
	state = s
	buttons.clear()
	phase_t = 0.0
	match s:
		"dress":
			say = "{partner}: \"Wear something that doesn't say 'I work with fryers.'\""
			add_button("top", Rect2(6, 96, 150, 18), "", KEY_1)
			add_button("shoes", Rect2(6, 116, 150, 18), "", KEY_2)
			add_button("extra", Rect2(6, 136, 150, 18), "", KEY_3)
			add_button("ready", Rect2(206, 154, 110, 22), "Let's go", KEY_SPACE, Color("#4e7a3a"))
			_relabel()
		"ride":
			if m != null and bool(m.has_car):
				say = "Downtown to {symphony_hall}. The minivan has a full tank and a car seat full of crumbs."
				add_button("bus", Rect2(6, 154, 150, 22), "Take the minivan (free)", KEY_1, Color("#2e5aa8"))
			else:
				say = "Downtown to {symphony_hall}. The #18 leaves the corner in one minute. Or a rideshare (surge pricing)."
				add_button("bus", Rect2(6, 154, 150, 22), "Run for the #18 (%s)" % ("$%d" % fares() if fares() > 0 else "pass"), KEY_1, Color("#2e5aa8"))
			add_button("rideshare", Rect2(160, 154, 156, 22), "Rideshare ($%d)" % Dates.RIDESHARE, KEY_2)
		"busrun":
			say = "RUN! The #18 is pulling away. Mash RUN. %s" % ("(Dress shoes slip if you mash too fast.)" if int(dress["shoes"]) == 0 else ("(Work clogs: slow but steady.)" if int(dress["shoes"]) == 1 else "(Crocs in sport mode. Respect.)"))
			run_t = 0.0
			dist = 0.0
			add_button("run", Rect2(6, 154, 200, 22), "RUN  (Space)", KEY_SPACE, Color("#4e7a3a"))
		"concert":
			mt = 0.0
			var piece: Dictionary = Dates.PROGRAM[mv]
			say = "%s  (%s)" % [piece["title"], piece["from"]]
			add_button("tap", Rect2(6, 154, 200, 22), "NOD ON THE BEAT  (Space)", KEY_SPACE, Color("#2e5aa8"))
			add_button("clap", Rect2(210, 154, 106, 22), "Clap (C)", KEY_C, Color("#6e5236"))
		"between":
			say = "Silence between movements. A man in row F starts clapping. Alone. Everyone stares at him..."
			add_button("clap", Rect2(110, 154, 100, 22), "Clap (C)", KEY_C, Color("#6e5236"))
		"intermission":
			say = "INTERMISSION. {partner}: \"I'm starving. Surprise me.\""
			for i in SNACKS.size():
				var sn: Array = SNACKS[i]
				var b: = add_button("snack_" + str(sn[0]), Rect2(6 + (i % 2) * 156, 112 + (i / 2) * 22, 152, 20), str(sn[1]), [KEY_1, KEY_2, KEY_3, KEY_4][i])
				if sn[0] == "bun":
					b["enabled"] = m != null and int(m.inventory.get("honey buns", 0)) > 0
		"bravo":
			say = "The last chord rings out. NOW is when you clap."
			add_button("clap", Rect2(60, 154, 200, 22), "BRAVO! Clap! (C / Space)", KEY_SPACE, Color("#4e7a3a"))
		"done":
			say = summary()
			var car: bool = m != null and bool(m.has_car)
			add_button("home", Rect2(6, 154, 150, 22), "Drive home (free)" if car else ("Last bus home (%s)" % ("$%d" % fares() if fares() > 0 else "pass")), KEY_SPACE, Color("#4e7a3a"))
			add_button("ride_home", Rect2(160, 154, 156, 22), "Rideshare home ($%d)" % Dates.RIDESHARE_HOME, KEY_2)

func _relabel() -> void :
	for k in ["top", "shoes", "extra"]:
		var opt: Array = DRESS[k][int(dress[k])]
		var lbl: = str(opt[0])
		if k == "extra" and int(dress[k]) == 1 and not has_cologne():
			lbl += " (you have none)"
		get_button(k)["label"] = "%s: %s" % [k.capitalize(), lbl]

func has_cologne() -> bool:
	return m != null and int(m.inventory.get("cologne", 0)) > 0

func dress_score() -> float:
	var s: = 0.0
	for k in ["top", "shoes", "extra"]:
		var v: float = float(DRESS[k][int(dress[k])][1])
		if k == "extra" and int(dress[k]) == 1 and not has_cologne():
			v = 0.0
		s += v
	s /= 3.0
	var smelly: bool = m != null and bool(m.fryer_smell)
	if smelly and not (int(dress["extra"]) == 1 and has_cologne()):
		s -= 0.25
	return clampf(s, 0.0, 1.0)

func _finish_dress() -> void :
	style = dress_score()
	if int(dress["extra"]) == 1 and has_cologne():
		m.inventory["cologne"] = int(m.inventory["cologne"]) - 1
		cologne_used = true
	var smelly: bool = m != null and bool(m.fryer_smell)
	if style >= 0.85:
		flash("{partner}: \"Oh. OH. Okay, mister.\"", Color("#e88aa8"), 1.6)
	elif smelly and not cologne_used:
		flash("{partner}: \"You smell like a fry basket in a nice jacket.\"", Color("#f2c66a"), 1.6)
	elif style < 0.4:
		flash("{partner}: \"...Are those CROCS?\"", Color("#f2c66a"), 1.6)
	go("ride")

func _on_button(id: String) -> void :
	match id:
		"top", "shoes", "extra":
			dress[id] = (int(dress[id]) + 1) % (DRESS[id] as Array).size()
			_relabel()
		"ready":
			_finish_dress()
		"bus":
			if m != null and bool(m.has_car):
				flash("The minivan. You use your blinker. {partner} does her makeup at a red light.", Color("#c0d890"), 1.8)
				_seat()
			else:
				go("busrun")
		"rideshare":
			rideshare = true
			spent += Dates.RIDESHARE
			flash("Your rideshare driver, Kyle, plays EDM and offers you a vape. -$%d" % Dates.RIDESHARE, Color("#f2c66a"), 1.8)
			_seat()
		"run":
			run()
		"tap":
			tap()
		"clap":
			clap()
		"home":
			ride_home = "bus"
			spent += fares()
			finish(score())
		"ride_home":
			ride_home = "rideshare"
			spent += Dates.RIDESHARE_HOME
			finish(score())
		_:
			if id.begins_with("snack_"):
				pick_snack(id.substr(6))

func _seat() -> void :
	mv = 1 if late else 0
	if late:
		flash("You missed movement I. You watched it on a lobby TV with an usher named Gary.", Color("#e06a4a"), 2.2)
		go("between")
	else:
		go("concert")

func fares() -> int:

	return int(m.fare_for(2)) if m != null and m.has_method("fare_for") else 4

func run() -> void :
	if state != "busrun":
		return
	var gap: = t - last_run
	last_run = t
	var shoes: = int(dress["shoes"])
	if shoes == 0 and gap < SLIP_GAP:
		slips += 1
		dist = maxf(0.0, dist - 0.12)
		flash("Dress shoes + wet pavement. You moonwalk backwards. Smooth.", Color("#f2c66a"), 0.9)
		return
	dist += RUN_STEP * (1.25 if shoes == 2 else (0.85 if shoes == 1 else 1.0))
	if dist >= 1.0:
		bus_caught = true
		spent += fares()
		flash("You catch the #18! {partner} is already on, saving you a seat. The driver claps.", Color("#c0d890"), 1.8)
		_seat()

func _missed_bus() -> void :
	late = true
	spent += fares()
	flash("The #18 pulls away. You catch the next one. Fifteen minutes. You're late.", Color("#e06a4a"), 1.8)
	_seat()


func _sound(midi: int) -> void :
	if not audio or players.is_empty():
		return
	var p: AudioStreamPlayer = players[p_i % players.size()]
	p_i += 1
	p.stream = Tone.stream(midi)
	p.play()

func tap() -> void :
	if state != "concert":
		return
	var ts: Array = times[mv]
	var j: Array = judged[mv]
	var best: = -1
	var bd: = 99.0
	for i in ts.size():
		if j[i] != "":
			continue
		var d: = absf((mt - LEAD) - float(ts[i]))
		if d < bd:
			bd = d
			best = i
	if best >= 0 and bd <= OK:
		j[best] = "perfect" if bd <= PERFECT else "hit"
		hits += 1
		if bd <= PERFECT:
			perfects += 1
		awake = minf(1.0, awake + 0.07)
	else:
		say = "You nodded at nothing. The cellist noticed."

func clap() -> void :
	match state:
		"between":
			if not clapped_between:
				clapped_between = true
				_sound_noise()
				flash("You clapped between movements. 1,800 people turn around. {partner}: \"Babe.\"", Color("#e06a4a"), 2.2)
		"bravo":
			if not bravo:
				bravo = true
				_sound_noise()
				flash("BRAVO! Standing ovation. {partner} squeezes your hand.", Color("#c0d890"), 1.6)
				go("done")
		"concert":
			clapped_mid += 1
			flash("You clapped mid-music. Bold. Wrong, but bold.", Color("#e06a4a"), 1.4)

func _sound_noise() -> void :
	if audio and not players.is_empty():
		var p: AudioStreamPlayer = players[p_i % players.size()]
		p_i += 1
		p.stream = Tone.noise()
		p.play()

func pick_snack(id: String) -> void :
	for sn in SNACKS:
		if sn[0] == id:
			spent += int(sn[2])
	snack = id
	match id:
		"wine": flash("{partner} gets her wine. In a sippy-lid cup. Very classy. Very Omaha.", Color("#e88aa8"), 1.8)
		"pretzels": flash("Chocolate pretzels. She eats 80% of them. As agreed.", Color("#e88aa8"), 1.8)
		"bun":
			m.inventory["honey buns"] = int(m.inventory["honey buns"]) - 1
			flash("A honey bun. From your COAT. She has never loved you more.", Color("#e88aa8"), 2.0)
		_: flash("You stood in line for 14 minutes. She got bored and made friends with an usher.", Color("#f2c66a"), 1.8)
	mv = 2
	go("concert")

func snack_good() -> bool:
	return snack in ["wine", "pretzels", "bun"]

func _tick(d: float) -> void :
	phase_t += d
	match state:
		"busrun":
			run_t += d
			dist = maxf(0.0, dist - RUN_DRIFT * d)
			if run_t >= RUN_T:
				_missed_bus()
		"concert":
			_tick_concert(d)
		"between":
			if phase_t >= BETWEEN_T:
				if not clapped_between:
					flash("You sat in reverent silence. (You were thinking about the fryer.) Classy.", Color("#c0d890"), 1.6)
				mv = 1
				go("concert")
		"bravo":
			if phase_t >= BRAVO_T:
				flash("You forgot to clap. The man in row F claps for you. He's redeemed.", Color("#f2c66a"), 1.8)
				go("done")

func _tick_concert(d: float) -> void :
	mt += d
	var piece: Dictionary = Dates.PROGRAM[mv]
	var ts: Array = times[mv]
	var j: Array = judged[mv]
	while int(played[mv]) < ts.size() and mt - LEAD >= float(ts[int(played[mv])]):
		_sound(int(piece["notes"][int(played[mv])][1]))
		played[mv] = int(played[mv]) + 1
	for i in ts.size():
		if j[i] == "" and (mt - LEAD) - float(ts[i]) > OK:
			j[i] = "miss"
			misses += 1
	awake -= float(piece["drowsy"]) * d
	if awake <= 0.0:
		snores += 1
		awake = 0.55
		flash("SNNNRRRK. {partner} elbows you awake. The flautist heard that.", Color("#e06a4a"), 1.8)
	if mt >= LEAD + Dates.piece_len(piece) + 0.8:
		_end_movement()

func _end_movement() -> void :
	var n: int = (times[mv] as Array).size()
	total_notes += n
	if mv == 0:
		go("between")
	elif mv == 1:
		go("intermission")
	else:
		go("bravo")

func accuracy() -> float:
	return float(hits) / float(maxi(1, total_notes))

func score() -> float:
	var s: = 0.2 * style + 0.45 * accuracy()
	s += 0.1 if snores == 0 else maxf(0.0, 0.1 - 0.05 * snores)
	s += 0.1 if not clapped_between else 0.0
	s += 0.1 if bravo else 0.0
	s += 0.05 if snack_good() else 0.0
	s -= 0.1 if late else 0.0
	s -= 0.03 * clapped_mid
	return clampf(s, 0.0, 1.0)

func summary() -> String:
	return "Kept time on %d/%d notes. Snores: %d. %s %s" % [hits, total_notes, snores, 
		"Clapped between movements (oof)." if clapped_between else "Didn't clap between movements!", 
		"Led the standing O." if bravo else ""]


func _draw_game() -> void :

	var bob: = sin(t * 6.0) * 3.0 if state == "concert" else 0.0
	draw_line(Vector2(160, 52), Vector2(168 + bob, 40), Color.WHITE, 1.0)
	if state == "dress":
		_draw_mirror()
	elif state == "busrun":
		_draw_busrun()
	elif state in ["concert", "between", "bravo"]:
		_draw_staff()

	var dim: = 1.0 - clampf((0.35 - awake) * 2.0, 0.0, 0.6) if state == "concert" else 1.0

	Art.frame(self, "ch_madison_dress", Vector2(255, 137), 0, 1)
	Art.frame(self, "ch_duff_suit", Vector2(271, 137), 0, 1, Color(dim, dim, dim))
	if state == "concert" and awake < 0.35:
		txt(Vector2(278, 116), "z", 8, Color(1, 1, 1, 0.7))

	if state in ["concert", "between", "bravo"]:
		txt(Vector2(6, 66), "AWAKE", 6, Color("#f2c66a"))
		bar(Rect2(32, 61, 60, 5), awake, Color("#e6a640") if awake > 0.3 else Color("#e06a4a"))
		txt(Vector2(100, 66), "%d/%d  snores %d" % [hits, hits + misses, snores], 6, Color(1, 1, 1, 0.7))
	if state == "dress":
		draw_rect(Rect2(6, 70, 308, 22), Color(0.1, 0.08, 0.15, 0.92))
		mtxt(Vector2(10, 79), say, 300, 7, Color.WHITE, 2)
	else:
		draw_rect(Rect2(6, 128, 240, 24), Color(0.1, 0.08, 0.15, 0.92))
		mtxt(Vector2(10, 136), say, 236, 7, Color.WHITE, 3)
	if state == "intermission":
		txt(Vector2(8, 106), "Lobby snack bar", 8, Color("#f2c66a"))

func _draw_mirror() -> void :
	draw_rect(Rect2(170, 90, 60, 60), Color("#7a6e8e"))
	draw_rect(Rect2(172, 92, 56, 56), Color("#a8e0ff"))
	draw_rect(Rect2(176, 96, 4, 20), Color(1, 1, 1, 0.35))

	draw_set_transform(Vector2(200, 146), 0.0, Vector2(2, 2))
	Art.frame(self, "duff_dress", Vector2.ZERO, dress_cell().x, dress_cell().y)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func dress_cell() -> Vector2i:
	return Vector2i(int(dress["top"]) * 2 + (0 if int(dress["extra"]) == 0 else 1), int(dress["shoes"]))

func _draw_busrun() -> void :
	draw_rect(Rect2(0, 84, W, 34), Color("#3a3a40"))
	draw_rect(Rect2(0, 116, W, 6), Color("#bdb5a6"))
	var bx: = 200.0 + run_t * 6.0
	draw_rect(Rect2(bx, 86, 110, 28), Color("#2a6ab0"))
	for i in 5:
		draw_rect(Rect2(bx + 6 + i * 20, 90, 14, 9), Color("#a8d8f0"))
	txt(Vector2(bx + 80, 110), "#18", 7, Color.WHITE)
	var px: = 20.0 + dist * (bx - 30.0)
	Art.person(self, "ch_duff_suit", Vector2(px + 3.0, 116), Vector2.RIGHT, t * 1.6, true)
	bar(Rect2(20, 74, 120, 5), dist, Color("#c0d890"))
	txt(Vector2(150, 79), "%.1fs  slips %d" % [maxf(0.0, RUN_T - run_t), slips], 6, Color.WHITE)

func _draw_staff() -> void :
	for k in 5:
		draw_line(Vector2(0, 84 + k * 6), Vector2(W, 84 + k * 6), Color(1, 1, 1, 0.25))
	draw_line(Vector2(HIT_X, 78), Vector2(HIT_X, 114), Color("#e6a640"), 2.0)
	if state != "concert":
		return
	var piece: Dictionary = Dates.PROGRAM[mv]
	var ts: Array = times[mv]
	var j: Array = judged[mv]
	for i in ts.size():
		var x: = HIT_X + (float(ts[i]) - (mt - LEAD)) * SPEED
		if x < -10 or x > W + 10:
			continue
		var pitch: int = int(piece["notes"][i][1])
		var y: = 108.0 - (pitch - 60) * 1.6
		var c: = Color.WHITE
		if j[i] == "perfect":
			c = Color("#c0d890")
		elif j[i] == "hit":
			c = Color("#c0ffc0")
		elif j[i] == "miss":
			c = Color("#e06a4a")
		draw_circle(Vector2(x, y), 3.0, c)
		draw_line(Vector2(x + 3, y), Vector2(x + 3, y - 10), c, 1.0)
