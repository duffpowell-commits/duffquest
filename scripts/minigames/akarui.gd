extends "res://scripts/minigames/minigame.gd"

const Dates: = preload("res://scripts/dates.gd")
const LISTEN_T: = 6.0
const BELT_T: = 20.0
const BELT_Y: = 92.0
const BELT_V: = 55.0
const ZONE: = Vector2(136, 180)
const SPAWN_EVERY: = 1.15
const PLATE_MIX: = ["salmon", "tamago", "tuna", "crab", "salmon", "uni", "tamago", "ginger", "tuna", "crab"]

var m: Node = null
var state: = "listen"
var her: Dictionary = {}
var picks: = {}
var order_right: = 0
var plates: Array = []
var spawn_t: = 0.0
var spawn_i: = 0
var belt_t: = 0.0
var grab_cd: = 0.0
var good: = 0
var wrong: = 0
var grabbed: Array = []
var plate_cost: = 0
var bill: = 0
var spent: = 0
var bill_choice: = ""
var phase_t: = 0.0
var say: = ""

func _setup() -> void:
	backdrop = "akarui"
	music = "date"
	title = "{DATE_SPOT_SUSHI}  ({sushi_area})"
	time_limit = 0.0
	space_is_pen = false
	her = Dates.make_order(int(ctx.get("seed", 5)))
	var rng: = RandomNumberGenerator.new()
	rng.seed = int(ctx.get("seed", 5)) + 1
	for s in Dates.SLOTS:
		var opts: Array = Dates.SLOT_OPTS[s]
		var right: = opts.find(her[s])
		picks[s] = (right + 1 + rng.randi() % (opts.size() - 1)) % opts.size()
	go(str(ctx.get("start", "listen")))

func go(s: String) -> void:
	state = s
	buttons.clear()
	phase_t = 0.0
	match s:
		"listen":
			say = ("(You drove the minivan downtown.) " if m != null and bool(m.has_car) else "(You took the #18 downtown.) ") + "{partner}: \"I'm gonna run to the bathroom. Order for me? I want the %s And if salmon... no, if %s or %s come by on the belt, GRAB THEM.\"" % [Dates.order_text(her), _plate_name(her["plates"][0]).to_lower(), _plate_name(her["plates"][1]).to_lower()]
			add_button("gotit", Rect2(206, 154, 110, 22), "Got it (Space)", KEY_SPACE, Color("#4e7a3a"))
		"order":
			say = "Server: \"And for her?\" (Tap each line to change it.)"
			for i in Dates.SLOTS.size():
				add_button("slot_" + str(Dates.SLOTS[i]), Rect2(6, 30 + i * 20, 200, 18), "", [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5][i])
			add_button("place", Rect2(206, 154, 110, 22), "Place order", KEY_SPACE, Color("#4e7a3a"))
			_relabel()
		"conveyor":
			say = "Conveyor time. GRAB her favorites when they pass the chopsticks: %s, %s." % [_plate_name(her["plates"][0]).to_lower(), _plate_name(her["plates"][1]).to_lower()]
			add_button("grab", Rect2(6, 154, 200, 22), "GRAB  (Space)", KEY_SPACE, Color("#2e5aa8"))
		"bill":
			bill = Dates.order_cost(her) + Dates.DUFF_MEAL + plate_cost
			say = "The bill: $%d (her order $%d, your ramen $%d, plates $%d). {partner} looks at it. Then at you." % [bill, Dates.order_cost(her), Dates.DUFF_MEAL, plate_cost]
			add_button("pay", Rect2(6, 112, 152, 20), "I got this ($%d)" % bill, KEY_1, Color("#4e7a3a"))
			add_button("split", Rect2(162, 112, 152, 20), "Split it ($%d each)" % int(ceil(bill / 2.0)), KEY_2)
			var c: = add_button("charm", Rect2(6, 134, 152, 18), "Charm the server ($%d)" % charm_price() if charming() else "Charm the server (needs CHARISMA)", KEY_3, Color("#a8406a"))
			c["enabled"] = charming()
			add_button("slow", Rect2(162, 134, 152, 18), "Reach for wallet... slowly", KEY_4)
		"done":
			say = summary()
			add_button("home", Rect2(206, 154, 110, 22), "Head home", KEY_SPACE, Color("#4e7a3a"))

func _plate_name(k: String) -> String:
	return str(Dates.PLATES[k][0])

func _relabel() -> void:
	for s in Dates.SLOTS:
		var opts: Array = Dates.SLOT_OPTS[s]
		get_button("slot_" + str(s))["label"] = "%s: %s" % [str(s).capitalize(), opts[int(picks[s])]]

func charming() -> bool:
	return m != null and m.has_method("charisma") and m.charisma() > 0

func charm_price() -> int:
	return int(floor(bill * 0.85))

func place_order() -> void:
	order_right = 0
	for s in Dates.SLOTS:
		var opts: Array = Dates.SLOT_OPTS[s]
		if opts[int(picks[s])] == her[s]:
			order_right += 1
	if order_right == Dates.SLOTS.size():
		flash("{partner} comes back: \"You remembered EVERYTHING? Even the ice?\"", Color("#c0d890"), 2.0)
	elif order_right >= 3:
		flash("Close! She gets a %s she didn't ask for. She drinks it anyway." % str(Dates.SLOT_OPTS["tea"][int(picks["tea"])]).to_lower(), Color("#f2c66a"), 2.0)
	else:
		flash("She stares at her drink. \"Who is this for? Is this for your OTHER girlfriend?\"", Color("#e06a4a"), 2.0)
	go("conveyor")

func grab() -> void:
	if grab_cd > 0.0:
		flash("Chopstick fumble. The tamago escapes. Probably for the best.", Color("#f2c66a"), 0.9)
		return
	grab_cd = 0.35
	for p in plates:
		var x: float = p[1]
		if x >= ZONE.x and x <= ZONE.y:
			var k: String = p[0]
			plates.erase(p)
			grabbed.append(k)
			plate_cost += int(Dates.PLATES[k][1])
			if k in her["plates"]:
				good += 1
				flash("Got the %s! She does a little chair dance." % _plate_name(k).to_lower(), Color("#c0d890"), 1.0)
			else:
				wrong += 1
				var why: = "She makes you eat it." if k == "uni" else ("It's one ginger slice on a whole plate. $1." if k == "ginger" else "Not her favorite. You eat it. Sacrifices.")
				flash("%s. %s" % [_plate_name(k), why], Color("#f2c66a"), 1.2)
			return
	flash("You clack your chopsticks at the air. Very intimidating.", Color(1, 1, 1, 0.8), 0.8)

func pay_bill(choice: String) -> void:
	var wallet: int = int(m.money) if m else 999
	var amt: = 0
	match choice:
		"pay": amt = bill
		"split": amt = int(ceil(bill / 2.0))
		"charm": amt = charm_price()
		"slow": amt = 0
	if amt > wallet:
		bill_choice = "declined"
		spent = 0
		flash("Card declined. {partner} pays. She's nice about it. That's worse.", Color("#e06a4a"), 2.0)
	else:
		bill_choice = choice
		spent = amt
		match choice:
			"pay": flash("You pay. She calls you \"provider\" in a voice. It's a good voice.", Color("#c0d890"), 1.8)
			"split": flash("Split down the middle. Modern couple. She's fine with it. Mostly.", Color(1, 1, 1), 1.8)
			"charm": flash("You smell incredible. The server comps the boba AND takes 15% off. She's impressed.", Color("#e88aa8"), 2.0)
			"slow": flash("You reach for your wallet... sloooowly... She sighs and pays. Noted.", Color("#e06a4a"), 2.0)
	go("done")

func _on_button(id: String) -> void:
	match id:
		"gotit": go("order")
		"place": place_order()
		"grab": grab()
		"pay", "split", "charm", "slow": pay_bill(id)
		"home": finish(score())
		_:
			if id.begins_with("slot_"):
				var s: = id.substr(5)
				picks[s] = (int(picks[s]) + 1) % (Dates.SLOT_OPTS[s] as Array).size()
				_relabel()

func _tick(d: float) -> void:
	phase_t += d
	grab_cd = maxf(0.0, grab_cd - d)
	if state == "listen" and phase_t >= LISTEN_T:
		go("order")
	elif state == "conveyor":
		belt_t += d
		spawn_t -= d
		if spawn_t <= 0.0 and belt_t < BELT_T - 3.0:
			spawn_t = SPAWN_EVERY
			plates.append([PLATE_MIX[spawn_i % PLATE_MIX.size()], -16.0])
			spawn_i += 1
		for p in plates:
			p[1] = float(p[1]) + BELT_V * d
		plates = plates.filter(func (p): return float(p[1]) < W + 20.0)
		if belt_t >= BELT_T:
			go("bill")

func score() -> float:
	var s: = 0.4 * float(order_right) / float(Dates.SLOTS.size())
	s += 0.3 * minf(1.0, good / 3.0)
	s += {"pay": 0.3, "charm": 0.3, "split": 0.2, "declined": 0.05, "slow": 0.0 }.get(bill_choice, 0.0)
	s -= minf(0.15, 0.05 * wrong)
	return clampf(s, 0.0, 1.0)

func summary() -> String:
	return "Order: %d/5 right. Her favorites grabbed: %d. Bill: %s." % [order_right, good, {"pay": "you paid", "charm": "charmed the server", "split": "split it", "slow": "she paid (you were slow)", "declined": "card declined" }.get(bill_choice, "?")]

func _draw_game() -> void:
	txt(Vector2(0, 22), "{date_spot_sushi} . sushi . poke . boba", 7, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)

	draw_rect(Rect2(0, BELT_Y - 10, W, 20), Color("#5a5a60"))
	for i in 17:
		var x: = fposmod(i * 20.0 + belt_t * BELT_V, W + 20.0) - 10.0
		draw_line(Vector2(x, BELT_Y - 10), Vector2(x, BELT_Y + 10), Color(0, 0, 0, 0.25))
	for p in plates:
		var k: String = p[0]
		var x: float = p[1]
		draw_circle(Vector2(x, BELT_Y), 8.0, Color("#fbf6ec"))
		draw_circle(Vector2(x, BELT_Y), 5.0, Color(str(Dates.PLATES[k][2])))
	if state == "conveyor":
		draw_rect(Rect2(ZONE.x, BELT_Y - 14, ZONE.y - ZONE.x, 28), Color("#e6a640"), false, 1.0)
		draw_line(Vector2(158, BELT_Y - 30), Vector2(150, BELT_Y - 6), Color("#c29a6a"), 2.0)
		draw_line(Vector2(164, BELT_Y - 30), Vector2(160, BELT_Y - 6), Color("#c29a6a"), 2.0)
		txt(Vector2(6, 120), "%.0fs  favorites %d  other %d" % [maxf(0.0, BELT_T - belt_t), good, wrong], 7, Color("#f2c66a"))

	if state == "order":
		var tea: = str(Dates.SLOT_OPTS["tea"][int(picks["tea"])])
		var tc: = {"Taro milk tea": "#b8a0d8", "Brown sugar milk tea": "#c89a6a", "Mango green tea": "#ffc040", "Matcha latte": "#8ac070" }
		draw_rect(Rect2(250, 40, 30, 56), Color(str(tc.get(tea, "#cccccc"))))
		draw_rect(Rect2(250, 40, 30, 56), Color.WHITE, false, 1.0)
		var top: = str(Dates.SLOT_OPTS["topping"][int(picks["topping"])])
		if top != "No topping":
			for i in 7:
				draw_circle(Vector2(254 + (i % 4) * 7, 88 + (i / 4) * 5), 2.0, Color("#2a1a10") if top == "Boba" else (Color("#f0f0d0") if top == "Lychee jelly" else Color("#f0d080")))
		draw_line(Vector2(270, 30), Vector2(268, 60), Color("#ff5fa2"), 3.0)
	if state != "listen" and state != "order" and state != "conveyor":
		pass
	var r: = Rect2(6, 126, 308, 26)
	if state == "listen":
		r = Rect2(6, 30, 308, 50)
	elif state == "bill":
		r = Rect2(6, 74, 308, 34)
	draw_rect(r, Color(0.1, 0.08, 0.15, 0.95))
	mtxt(r.position + Vector2(4, 9), say, r.size.x - 8, 7, Color.WHITE, 5 if state in ["listen", "bill"] else 3)
