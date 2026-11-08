extends "res://scripts/minigames/minigame.gd"

const SERVE_T: = 2.0
const CUT_WINDOW: = 1.3
const WAIT_T: = 8.0
const DING_T: = 3.5
const FULL_COPAY: = 10
const INSURED_COPAY: = 5
const AISLE: = [["formula", "Formula", 12], ["ensure", "Ensure (vanilla)", 4], ["diapers", "Diapers", 10], ["honey buns", "Honey buns (impulse)", 3], ["treats", "Cat treats", 2], ["cologne", "{cologne} x3", 12]]
const HOLDUPS: = [
	"Guy ahead of me is on hold with his insurance. In line. Simultaneously.",
	"Guy up front asks why his inhaler costs $400. Pharmacist: 'Innovation.'",
	"Old guy's showing {pharmacist} 40 photos of a grandkid. Only good thing in this building.",
	"His coupon says 'up to 80% off.' It is 0% off.",
	"His prior authorization needs a prior authorization.",
	"Insurance wants the generic. The generic is backordered. Until 2031.",
	"Now self-checkout is asking HIM for a tip.",
	"His rewards card wants his blood type.",
]
const CUTTERS: = ["\"I just have a QUICK question...\"", "\"Oh, are you in line? I'm just picking up.\"", "\"I was here earlier, I just went to the car.\"", "\"Is this the line? Doesn't matter.\""]

const TREES: = [
	[
		["Blue Crossword Insurance: Caring Is Our Brand! For English, press 1. Para espanol, oprima 2. To hear this as a sea shanty, press 3.", ["1  English", "2  Espanol", "3  Sea shanty"], 0],
		["If you are a member, press 1. If you are a pharmacy, press 2. If you are our CEO, you are on a yacht, press 3.", ["1  Member", "2  Pharmacy", "3  Your voice"], 0],
		["Please say your member ID. ... Sorry, I didn't get that. Press 1 to try again, 2 for a representative, 3 to hear our hours.", ["1  Try again", "2  Representative", "3  Hours"], 1],
		["Your call is very important to us. Not important enough to staff. (smooth jazz saxophone)", [], -1],
		["Brenda: Hi! I'm one of three humans left here. I see the hold. Was this a 90-day supply?", ["1  Yes, 90 days", "2  No idea, I just pick it up", "3  Can I just pay?"], 1],
	],
	[
		["You've reached Blue Crossword. Our menu has changed. Please listen closely. Press 1 if you've listened closely.", ["1  I listened", "2  I did not", "3  What menu"], 0],
		["For claims, press 1. For holds, press 2. For a joke, press 3.", ["1  Claims", "2  Holds", "3  A joke"], 1],
		["Transferring you to the Department of Denials. (pan flute power ballad)", [], -1],
		["Hold department! Can you confirm the patient's name?", ["1  {partner}", "2  {hero}", "3  Honey Bun"], 0],
		["Great. And is the patient annoyed? That's our KPI.", ["1  Very", "2  Not at all", "3  She's fine"], 0],
	],
]

var m: Node = null
var rng: = RandomNumberGenerator.new()
var state: = "line"
var prev_state: = "done"
var has_errand: = true
var outcome: = "ready"
var say: = ""
var ahead: = 4
var serve_t: = SERVE_T
var cut_t: = 3.0
var cut_on: = 0.0
var shooed: = 0
var let_cut: = 0
var minutes: = 0.0
var got_meds: = false
var copay: = 0
var insured: = false
var tree: Array = []
var tree_i: = 0
var hold_t: = 0.0
var wrong: = 0
var phone_tree_beaten: = false
var wait_fill: = 0.0
var ding_t: = 0.0
var asked: = 0
var bought: Array = []

func _setup() -> void:
	backdrop = "pharmacy"
	title = "{PHARMACY}"
	time_limit = 0.0
	space_is_pen = false
	rng.seed = int(ctx.get("seed", randi()))
	has_errand = bool(ctx.get("errand", true))
	outcome = str(ctx.get("outcome", ["ready", "not_ready", "insurance"][rng.randi() % 3]))
	ahead = int(ctx.get("ahead", 3 + rng.randi() % 3))
	tree = TREES[int(ctx.get("tree", rng.randi() % TREES.size()))]
	cut_t = rng.randf_range(2.0, 3.5)
	var st: = str(ctx.get("start", ""))
	if not has_errand:
		say = "Nothing to pick up today. Good, 'cause the line's %d people deep. The aisle's open." % ahead
		go("aisle")
		prev_state = "browse"
	elif st != "":
		ahead = 0
		go(st)
	else:
		say = HOLDUPS[rng.randi() % HOLDUPS.size()]
		go("line")

func go(s: String) -> void:
	state = s
	buttons.clear()
	match s:
		"line":
			add_button("ahem", Rect2(6, 154, 150, 22), "AHEM!  (Space)", KEY_SPACE, Color("#9c5a2c"))
		"counter":
			say = "{pharmacist}: Hi, hon! Name on the prescription?"
			add_button("n_partner", Rect2(6, 154, 96, 22), "{partner}", KEY_1)
			add_button("n_hero", Rect2(106, 154, 96, 22), "{hero}", KEY_2)
			add_button("n_bun", Rect2(206, 154, 50, 22), "Honey Bun", KEY_3)
		"wait":
			add_button("ask", Rect2(6, 154, 96, 22), "Is it ready?", KEY_1)
			add_button("aisle", Rect2(106, 154, 70, 22), "Aisle", KEY_2, Color("#2e5aa8"))
			var b: = add_button("pickup", Rect2(180, 154, 76, 22), "PICK UP!", KEY_SPACE, Color("#4e7a3a"))
			b["enabled"] = ding_t > 0.0
		"phone":
			_phone_buttons()
		"pay":
			add_button("pay", Rect2(6, 154, 150, 22), "Pay $%d copay" % copay, KEY_1, Color("#4e7a3a"))
		"aisle":
			for i in AISLE.size():
				var it: Array = AISLE[i]
				add_button("buy_" + str(it[0]), Rect2(6 + (i % 2) * 156, 34 + (i / 2) * 24, 152, 21), "", [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6][i])
			add_button("back", Rect2(6, 154, 100, 22), "Back" if prev_state != "browse" else "Done", KEY_B, Color("#2e5aa8"))
			_relabel()
		"done":
			add_button("aisle", Rect2(6, 154, 120, 22), "Shop the aisle", KEY_1, Color("#2e5aa8"))
	add_button("leave", Rect2(262, 154, 54, 22), "Leave", KEY_ESCAPE, Color("#a43a2c"))

func _phone_buttons() -> void:
	for b in buttons.duplicate():
		if str(b["id"]).begins_with("opt_") or b["id"] == "stay" or b["id"] == "hangup":
			buttons.erase(b)
	var step: Array = tree[tree_i]
	say = str(step[0])
	if int(step[2]) < 0:
		hold_t = 4.0
		add_button("stay", Rect2(6, 154, 120, 22), "Stay on hold", KEY_1, Color("#2e5aa8"))
		add_button("hangup", Rect2(130, 154, 90, 22), "Hang up", KEY_2, Color("#7a2a22"))
	else:
		var opts: Array = step[1]
		for i in opts.size():
			add_button("opt_%d" % i, Rect2(6 + i * 85, 154, 82, 22), str(opts[i]).substr(0, 18), [KEY_1, KEY_2, KEY_3][i])

func _relabel() -> void:
	for it in AISLE:
		var b: = get_button("buy_" + str(it[0]))
		if not b.is_empty():
			var have: = int(m.inventory.get(it[0], 0)) if m else 0
			b["label"] = "%s $%d (have %d)" % [it[1], aisle_price(it), have]

func _tick(d: float) -> void:
	match state:
		"line": _tick_line(d)
		"wait", "aisle": _tick_wait(d)
		"phone":
			if hold_t > 0.0:
				hold_t -= d
				if hold_t <= 0.0:
					minutes += 10.0
					_phone_next()

func _tick_line(d: float) -> void:
	serve_t -= d
	if serve_t <= 0.0:
		serve_t = SERVE_T
		ahead -= 1
		minutes += 3.0
		if ahead <= 0:
			cut_on = 0.0
			go("counter")
			return
		say = HOLDUPS[rng.randi() % HOLDUPS.size()]
	if cut_on > 0.0:
		cut_on -= d
		if cut_on <= 0.0:
			ahead += 1
			let_cut += 1
			say = "He cuts. Line-skip pass, $9.99/month. Of course that's a thing now."
			cut_t = rng.randf_range(2.5, 4.5)
	else:
		cut_t -= d
		if cut_t <= 0.0 and ahead >= 1:
			cut_on = CUT_WINDOW
			say = "! Line-cutter: " + CUTTERS[rng.randi() % CUTTERS.size()]

func _tick_wait(d: float) -> void:
	if outcome != "not_ready" or got_meds or prev_state == "browse" or (state == "aisle" and prev_state != "wait"):
		return
	if ding_t > 0.0:
		ding_t -= d
		if ding_t <= 0.0:
			wait_fill = 0.7
			minutes += 3.0
			say = "I'm too slow. A guy with a 'Premium Line' app badge gets there first. Back to waiting. Damn."
			_set_pickup(false)
		return
	wait_fill = minf(1.0, wait_fill + d / WAIT_T)
	if wait_fill >= 1.0:
		ding_t = DING_T
		say = "*DING* {pharmacist}: \"{partner}? Pickup for {partner}!\""
		_set_pickup(true)

func _set_pickup(on: bool) -> void:
	var b: = get_button("pickup")
	if not b.is_empty():
		b["enabled"] = on

func _phone_next() -> void:
	tree_i += 1
	if tree_i >= tree.size():
		phone_tree_beaten = true
		insured = true
		copay = INSURED_COPAY
		say = "Approved! The robot goes \"Have a blessed day.\" {pharmacist} runs it again: insurance covers more now. Copay $%d." % copay
		go("pay")
		return
	_phone_buttons()

func _on_button(id: String) -> void:
	match id:
		"leave":
			finish(1.0 if got_meds else 0.0)
		"ahem":
			if cut_on > 0.0:
				cut_on = 0.0
				shooed += 1
				cut_t = rng.randf_range(2.5, 4.5)
				say = "AHEM. The cutter shuffles to the back. Behind, buddy. Quiet, polite Midwestern victory."
			else:
				serve_t += 0.4
				say = "I cough at nobody. Lady ahead turns around. Slowly. Hell."
		"n_partner":
			minutes += 2.0
			_outcome()
		"n_hero":
			minutes += 1.0
			say = "{pharmacist}: Nothing under {hero}, hon. You look like you could use a nap, though."
		"n_bun":
			minutes += 1.0
			say = "{pharmacist}: ...Is that what you call her? Cute. I need her actual name."
		"ask":
			asked += 1
			if wait_fill < 1.0:
				wait_fill = maxf(0.0, wait_fill - 0.15)
				say = ["{pharmacist}: Not yet, hon. We're staffed by me and a printer.", "{pharmacist}: Still not yet. Corporate cut our tech to 'part-time vibes.'", "{pharmacist}: Sweetie. The chair. Sit in the chair."][mini(asked - 1, 2)]
		"pickup":
			if ding_t > 0.0:
				ding_t = 0.0
				copay = FULL_COPAY
				say = "{pharmacist}: Here you go! That's $%d." % copay
				go("pay")
		"stay":
			say = "(The saxophone hits a note that should be illegal.) Still holding. Twenty-three minutes. This is fine."
		"hangup":
			tree_i = 0
			minutes += 3.0
			say = "I hang up out of spite. Call back. Start of the damn menu."
			_phone_buttons()
			say = "I call back. " + say
		"pay":
			_pay()
		"aisle":
			prev_state = state
			go("aisle")
		"back":
			if prev_state == "browse":
				finish(0.0)
			else:
				go(prev_state)
		_:
			if id.begins_with("opt_"):
				var pick: = int(id.substr(4))
				var step: Array = tree[tree_i]
				if pick == int(step[2]):
					minutes += 2.0
					_phone_next()
				else:
					wrong += 1
					minutes += 4.0
					tree_i = maxi(0, tree_i - 1)
					_phone_buttons()
					say = "\"Sorry, I didn't get that.\" Back one menu. " + say
			elif id.begins_with("buy_"):
				_buy(id.substr(4))

func _outcome() -> void:
	match outcome:
		"ready":
			copay = FULL_COPAY
			say = "{pharmacist}: It's ready! Miracles happen. That's $%d, hon." % copay
			if m and m.has_method("charisma") and m.charisma() > 0:
				say += " ...Ooh, is that {cologne}? Somebody's got a date tonight."
			go("pay")
		"not_ready":
			say = "{pharmacist}: It's not quite ready. Fifteen minutes, hon. Have a seat, or browse the aisle."
			minutes += 15.0
			wait_fill = 0.0
			go("wait")
		_:
			say = "{pharmacist}: Ope. Insurance put a hold on it. Their algorithm denies first, asks never. Gotta call them, hon."
			tree_i = 0
			go("phone")
			say = "{pharmacist}: Insurance hold. Call them. (So I dial.) " + say

func _pay() -> void:
	say = "Got {partner}'s prescription bag. Receipt's longer than my arm and it's 90% coupons for stuff we can't afford."
	if m and m.money < copay:
		say = "My card gets declined. {pharmacist} covers it from the 'kindness jar'. Only working safety net in America. Pay it forward."
		copay = 0
	elif m:
		m.money -= copay
	got_meds = true
	go("done")

func aisle_price(it: Array) -> int:

	var mult: float = m.price_mult() if m and m.has_method("price_mult") else 1.0
	var extra: int = m.formula_extra() if m and str(it[0]) == "formula" and m.has_method("formula_extra") else 0
	return int(ceil((int(it[2]) + extra) * mult))

func _buy(id: String) -> void:
	var price: = 0
	for it in AISLE:
		if it[0] == id:
			price = aisle_price(it)
	if m == null or m.money < price:
		flash("Not enough cash. The gum rack judges me.", Color("#e06a4a"))
		return
	m.money -= price
	m.inventory[id] = int(m.inventory.get(id, 0)) + (3 if id == "cologne" else 1)
	bought.append(id)
	flash("Bought %s. -$%d" % [id, price], Color("#c0d890"), 0.9)
	_relabel()

func _draw_game() -> void:

	txt(Vector2(90, 24), "PHARMACY  (drop-off / pick-up / despair)", 6, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 140)
	_person(Vector2(160, 36), Color("#ffffff"), Color("#c68642"), true)
	txt(Vector2(236, 22), "{pharmacist}", 6, Color("#7a2a2a"))
	txt(Vector2(4, 84), "FORMULA / ENSURE", 6, Color(0, 0, 0, 0.6))
	if state == "aisle":
		draw_rect(Rect2(0, 12, W, 140), Color(0.95, 0.94, 0.9, 0.97))
		txt(Vector2(6, 26), "Aisle 3: baby formula, Ensure, and one (1) dusty foot spa.   Cash $%d" % (m.money if m else 0), 7, Color(0.1, 0.1, 0.1))
		if outcome == "not_ready" and not got_meds and prev_state == "wait":
			_wait_meter(Rect2(6, 110, 308, 6))
		_say_box()
		return
	match state:
		"line":
			for i in mini(ahead, 6):
				var p: = Vector2(160.0 + (7.0 if i % 2 == 1 else -7.0), 60 + i * 9)
				_person(p, [Color("#5a7ab0"), Color("#9a5a8a"), Color("#6a8a4a"), Color("#b08a3a")][i % 4], Color("#dcae8e"), false)
			var dp: = Vector2(160, 60 + mini(ahead, 6) * 9)
			if ahead > 6:
				txt(Vector2(172, 100), "+%d more" % (ahead - 6), 6, Color(0.2, 0.2, 0.2))
			_person(dp, Color("#fbf6ec"), Color("#f2d2b4"), false)
			txt(dp + Vector2(8, 2), "you", 6, Color(0.2, 0.2, 0.6))
			if cut_on > 0.0:
				var cp: = Vector2(184, 70)
				_person(cp, Color("#b03030"), Color("#dcae8e"), false)
				txt(cp + Vector2(-2, -12), "!", 12, Color("#c8573a"))
				bar(Rect2(200, 60, 60, 4), cut_on / CUT_WINDOW, Color("#ff7a3a"))
			txt(Vector2(236, 64), "Ahead of you: %d" % ahead, 7, Color(0.1, 0.1, 0.1))
			bar(Rect2(236, 68, 76, 4), 1.0 - serve_t / SERVE_T, Color("#4e7a3a"))
		"counter", "pay", "done":
			_person(Vector2(160, 60), Color("#fbf6ec"), Color("#f2d2b4"), false)
			if got_meds:
				draw_rect(Rect2(170, 52, 10, 12), Color("#ffffff"))
				draw_rect(Rect2(170, 52, 10, 12), Color("#c83a3a"), false, 1.0)
				draw_rect(Rect2(181, 50, 2, 40), Color("#ffffff"))
		"wait":
			draw_rect(Rect2(20, 92, 40, 10), Color("#4a6a9a"))
			_person(Vector2(40, 88), Color("#fbf6ec"), Color("#f2d2b4"), false)
			txt(Vector2(10, 108), "the chair", 6, Color(0, 0, 0, 0.5))
			_wait_meter(Rect2(90, 70, 220, 6))
		"phone":
			_person(Vector2(160, 62), Color("#fbf6ec"), Color("#f2d2b4"), false)
			draw_rect(Rect2(166, 52, 4, 8), Color("#2b2218"))
			txt(Vector2(236, 64), "Menu %d/%d" % [tree_i + 1, tree.size()], 7, Color(0.1, 0.1, 0.1))
			if hold_t > 0.0:
				txt(Vector2(150, 80), "~ hold music ~", 9, Color("#3a3a8a"))
				bar(Rect2(200, 70, 100, 4), 1.0 - hold_t / 4.0, Color("#2e5aa8"))
	_say_box()

func _wait_meter(r: Rect2) -> void:
	txt(r.position + Vector2(0, -2), "Prescription: %s" % ("READY! Grab it!" if ding_t > 0.0 else "being counted..."), 6, Color(0.1, 0.1, 0.1))
	bar(r, wait_fill, Color("#4e7a3a") if ding_t <= 0.0 else Color("#e6a640"))

func _say_box() -> void:
	var r: = Rect2(6, 118, 308, 32)
	draw_rect(r, Color(0.1, 0.08, 0.15, 0.92))
	mtxt(r.position + Vector2(4, 10), say, r.size.x - 8, 7, Color.WHITE, 3)

const LINE_FOLKS: = ["ch_karen", "ch_hoa", "ch_sitter", "ch_usher", "ch_cashier", "ch_jen"]

func _person(p: Vector2, shirt: Color, _skin: Color, coat: bool) -> void:

	var nm: = "ch_pharmacist" if coat else ("duff_apron_red" if shirt == Color("#fbf6ec") else str(LINE_FOLKS[absi(int(p.y)) % LINE_FOLKS.size()]))
	Art.person(self, nm, p + Vector2(0, 8), Vector2.DOWN if coat else Vector2.UP, t, false)
