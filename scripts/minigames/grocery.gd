extends "res://scripts/minigames/minigame.gd"

const Errands: = preload("res://scripts/errands.gd")
const Buffs: = preload("res://scripts/buffs.gd")
const FLOOR: = Rect2(8, 14, 304, 136)
const SHELVES: = [Rect2(46, 36, 228, 8), Rect2(46, 64, 228, 8), Rect2(46, 92, 228, 8), Rect2(46, 120, 228, 8)]
const AISLE_NAMES: = ["1 Bakery + baking", "2 Produce + dairy", "3 Baby + Ensure", "4 Pets + snacks"]
const SPOTS: = {
	"honey buns": Vector2(90, 25), "flour": Vector2(160, 25), "chocolate": Vector2(235, 25),
	"cherries": Vector2(80, 53), "eggs": Vector2(155, 53), "cream": Vector2(240, 53),
	"formula": Vector2(90, 81), "diapers": Vector2(170, 81), "ensure": Vector2(250, 81),
	"treats": Vector2(120, 109),
}
const ICON: = {"honey buns": "#d9a441", "flour": "#f4f0e0", "chocolate": "#5a3220", "cherries": "#c0182a", "eggs": "#f6ead0",
	"cream": "#eef4ff", "formula": "#7ab0e0", "diapers": "#a0d0a0", "ensure": "#e6e6f0", "treats": "#e08a2a" }
const KIOSK: = Rect2(18, 134, 44, 14)
const COUPON: = Rect2(258, 134, 44, 14)
const START: = Vector2(160, 140)
const ACCEL: = 260.0
const MAX_V: = 85.0
const R: = 5.0
const KAREN_Y: = 53.0
const DECOYS: = [["$0.50 off Bigfoot repellent", "Bigfoot has not been spotted in {city}. Yet."], ["EXPIRED: eggnog, 2009", "Expired in 2009. The eggnog has evolved."], ["BOGO garden gnome", "Nobody needs a gnome. The economy needs you to need a gnome."], ["10% off a $400 blender", "Saving $40 by spending $400. Finance bros call this 'alpha.'"], ["Free sample: mystery dip", "Not a coupon. A data-harvesting agreement with a dip."]]
const KAREN_LINES: = ["Karen: \"Excuse me. I need to speak to your MANAGER.\" (You don't have one here.)", "Karen: \"Do you WORK here?\" (No. Nobody does. They replaced everyone with a kiosk.)", "Linda: \"She's right, you know.\" (About what?)", "Karen: \"This aisle is MINE. I have a premium membership.\""]

var m: Node = null
var rng: = RandomNumberGenerator.new()
var state: = "shop"
var say: = ""
var has_errand: = true
var items: = {}
var budget: = 0
var oos: = ""
var cart: = {}
var skipped: Array = []
var subs: = 0
var sub_notes: Array = []
var sub_item: = ""
var pos: = START
var vel: = Vector2.ZERO
var face: = Vector2.UP
var stun_t: = 0.0
var bump_cd: = 0.0
var bumps: = 0
var karen_on: = true
var karen_x: = 80.0
var karen_dir: = 1.0
var karen_cd: = 0.0
var karen_hits: = 0
var shop_t: = 0.0
var coupons: Array = []
var coupon_t: = 0.0
var coupons_done: = false
var coupon_save: = 0
var scan_list: Array = []
var scan_i: = 0
var scan_t: = 0.0
var misses: = 0
var gag_at: = 1
var gag_done: = false
var lift_tries: = 0
var attendant_t: = 0.0
var price_check: = false
var pc_item: = ""
var pc_opts: Array = []
var overcharge: = 0
var total: = 0
var overage: = 0
var change: = 0
var card_strain: = false
var paid: = false
var put_back: Array = []
var minutes: = 0.0
var steer: = Vector2.ZERO

func _setup() -> void:
	backdrop = "grocery"
	title = "{GROCERY}"
	time_limit = 0.0
	space_is_pen = false
	rng.seed = int(ctx.get("seed", randi()))
	has_errand = bool(ctx.get("errand", true))
	items = (ctx.get("items", {"cherries": 1, "chocolate": 1, "cream": 1, "flour": 1, "eggs": 1 }) as Dictionary).duplicate()
	budget = int(ctx.get("budget", 0))
	oos = str(ctx.get("oos", ""))
	karen_on = bool(ctx.get("karen", true))
	price_check = bool(ctx.get("price_check", rng.randf() < 0.5))
	gag_at = mini(1, maxi(0, items.size() - 1))
	_make_coupons()
	say = "{GROCERY}: %s. My cart's got a wonky wheel. Prices got a wonky 'dynamic pricing algorithm.'" % Cast.T("{grocery_slogan}")
	if str(ctx.get("start", "")) in ["checkout", "bagging"]:
		for id in items:
			cart[id] = int(Errands.PRICES.get(id, 2))
		pos = KIOSK.get_center() + Vector2(0, -12)
		begin_scan()
		if str(ctx["start"]) == "bagging":
			scan_i = gag_at + 1
			say = "UNEXPECTED ITEM IN BAGGING AREA. Please remove the item. (There is no item. The item is your dignity.)"
			go("bagging")
	else:
		go("shop")

func go(s: String) -> void:
	state = s
	buttons.clear()
	match s:
		"shop":
			add_button("leave", Rect2(262, 154, 54, 22), "Leave", KEY_ESCAPE, Color("#a43a2c"))
		"sub":
			var opts: Array = Errands.SUBS.get(sub_item, [])
			for i in opts.size():
				var o: Array = opts[i]
				var p: = maxi(0, int(Errands.PRICES.get(sub_item, 2)) + int(o[1]))
				add_button("sub_%d" % i, Rect2(6, 98 + i * 24, 308, 21), "%s  $%d" % [str(o[0]).substr(0, 48), p], [KEY_1, KEY_2][i])
			add_button("skip", Rect2(6, 154, 120, 22), "Skip it", KEY_3, Color("#7a2a22"))
		"coupons":
			for i in coupons.size():
				var c: Array = coupons[i]
				var b: = add_button("cp_%d" % i, Rect2(8 + (i % 3) * 102, 40 + (i / 3) * 40, 98, 34), str(c[0]), [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6][i], Color("#e8dca0"))
				b["enabled"] = not bool(c[3])
			add_button("cp_done", Rect2(6, 154, 120, 22), "Done clipping", KEY_ESCAPE, Color("#2e5aa8"))
		"confirm":
			add_button("yes", Rect2(6, 154, 140, 22), "Check out anyway", KEY_1, Color("#4e7a3a"))
			add_button("no", Rect2(150, 154, 110, 22), "Keep shopping", KEY_2, Color("#2e5aa8"))
		"scan":
			add_button("scan", Rect2(6, 154, 150, 22), "SCAN  (Space)", KEY_SPACE, Color("#4e7a3a"))
		"bagging":
			add_button("lift", Rect2(6, 154, 100, 22), "Lift the bag", KEY_1)
			add_button("wave", Rect2(110, 154, 100, 22), "Wave for help", KEY_2)
			add_button("stare", Rect2(214, 154, 100, 22), "Stare at it", KEY_3)
		"pricecheck":
			for i in pc_opts.size():
				add_button("pc_%d" % i, Rect2(6 + i * 104, 154, 100, 22), "$%d" % int(pc_opts[i]), [KEY_1, KEY_2, KEY_3][i])
		"receipt":
			add_button("done", Rect2(110, 154, 100, 22), "Leave store", KEY_ESCAPE, Color("#4e7a3a"))
			if m:
				add_button("cologne", Rect2(214, 154, 102, 22), "{cologne} $%d" % cologne_price(), KEY_C, Color("#a8406a"))

func _make_coupons() -> void:
	coupons.clear()
	var ids: = items.keys()
	ids.shuffle()
	for i in mini(3, ids.size()):
		var id: String = ids[i]
		var save: = 2 if id in ["formula", "diapers"] else 1
		coupons.append(["$%d off %s" % [save, str(Errands.LABELS.get(id, id)).to_lower()], id, save, false])
	var dec: = DECOYS.duplicate()
	while coupons.size() < 6 and not dec.is_empty():
		var dd: Array = dec.pop_at(rng.randi() % dec.size())
		coupons.append([dd[0], "", 0, false, dd[1]])
	for i in range(coupons.size() - 1, 0, -1):
		var j: = rng.randi() % (i + 1)
		var tmp = coupons[i]
		coupons[i] = coupons[j]
		coupons[j] = tmp

func list_done() -> bool:
	for id in items:
		if not cart.has(id) and not skipped.has(id):
			return false
	return true

func missing_items() -> Array:
	var out: Array = []
	for id in items:
		if not cart.has(id) and not skipped.has(id):
			out.append(id)
	return out

func cart_total() -> int:
	var s: = 0
	for id in cart:
		s += int(cart[id])
	return s

func _tick(d: float) -> void:
	show_cursor = false
	title = "{GROCERY}     " + ("Budget $%d" % budget if has_errand else "Your $%d" % (m.money if m else 0)) + "     Cart $%d" % cart_total()
	match state:
		"shop": _tick_shop(d)
		"coupons":
			coupon_t -= d
			if coupon_t <= 0.0:
				_end_coupons("Time's up. The kiosk prints me a 3-foot receipt of ads and sells my data. Twice.")
		"scan": scan_t += d
		"bagging":
			if attendant_t > 0.0:
				attendant_t -= d
				if attendant_t <= 0.0:
					_gag_resolved("Finally the one attendant covering 14 self-checkouts taps a code. \"You're good.\" Corporate calls her a 'team of one.'")

func _tick_shop(d: float) -> void:
	shop_t += d
	stun_t = maxf(0.0, stun_t - d)
	bump_cd = maxf(0.0, bump_cd - d)
	karen_cd = maxf(0.0, karen_cd - d)
	var dir: = steer
	if dir == Vector2.ZERO and InputMap.has_action("move_left"):
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO and pen_down and cursor.distance_to(pos) > 6.0:
		dir = (cursor - pos).normalized()
	if stun_t > 0.0:
		dir = Vector2.ZERO
	if dir != Vector2.ZERO:
		vel += dir.normalized() * ACCEL * d
		face = dir.normalized()
	else:
		vel *= exp(-5.0 * d)
	if vel.length() > MAX_V:
		vel = vel.normalized() * MAX_V
	if vel.length() > 15.0:
		vel = vel.rotated(-0.45 * d)
	_move(vel * d)
	_karen(d)
	for id in items:
		if cart.has(id) or skipped.has(id) or not SPOTS.has(id):
			continue
		if pos.distance_to(SPOTS[id]) < 11.0:
			if id == oos:
				sub_item = id
				vel = Vector2.ZERO
				say = "OUT OF STOCK: %s. The shelf's got one (1) price tag, a lot of dust and a sign about record profits. Swap it?" % str(Errands.LABELS.get(id, id)).to_lower()
				go("sub")
				return
			cart[id] = int(Errands.PRICES.get(id, 2))
			flash("Got %s ($%d)" % [str(Errands.LABELS.get(id, id)).to_lower(), int(cart[id])], Color("#c0d890"), 0.9)
	if not coupons_done and COUPON.grow(6).has_point(pos):
		coupon_t = 7.0
		vel = Vector2.ZERO
		say = "Then I hit the coupon kiosk. Clip the ones on my list before it times out (7s)."
		go("coupons")
		return
	if KIOSK.grow(6).has_point(pos) and not cart.is_empty():
		vel = Vector2.ZERO
		if list_done():
			begin_scan()
		else:
			say = "My list isn't done. Missing: %s. Check out anyway?" % ", ".join(missing_items().map(func (x): return str(Errands.LABELS.get(x, x)).to_lower()))
			go("confirm")

func _blocked(p: Vector2) -> bool:
	if not FLOOR.grow(-R).has_point(p):
		return true
	for s in SHELVES:
		if (s as Rect2).grow(R).has_point(p):
			return true
	if KIOSK.has_point(p) or COUPON.has_point(p):
		return true
	return false

func _move(step: Vector2) -> void:
	var hit: = false
	var nx: = pos + Vector2(step.x, 0)
	if _blocked(nx):
		hit = true
		vel.x *= -0.4
	else:
		pos = nx
	var ny: = pos + Vector2(0, step.y)
	if _blocked(ny):
		hit = true
		vel.y *= -0.4
	else:
		pos = ny
	if hit and step.length() > 45.0 * 0.016 and bump_cd <= 0.0 and vel.length() > 25.0:
		bumps += 1
		bump_cd = 1.0
		var aisle: = clampi(int((pos.y - 14.0) / 28.0) + 1, 1, 4)
		flash("CLANG. \"Clean up on aisle %d.\"" % aisle, Color("#e6a640"), 1.0)

func _karen(d: float) -> void:
	if not karen_on:
		return
	karen_x += karen_dir * 28.0 * d
	if karen_x > 262.0 or karen_x < 58.0:
		karen_dir = -karen_dir
	var kp: = Vector2(karen_x, KAREN_Y)
	if karen_cd <= 0.0 and pos.distance_to(kp) < 13.0:
		karen_cd = 3.0
		karen_hits += 1
		stun_t = 1.2
		minutes += 2.0
		vel = (pos - kp).normalized() * 60.0
		say = KAREN_LINES[(karen_hits - 1) % KAREN_LINES.size()]
		flash("Karen blocks the aisle!", Color("#e06a4a"), 1.0)

func begin_scan() -> void:
	scan_list = cart.keys()
	scan_i = 0
	scan_t = 0.0
	say = "So I hit self-checkout. \"Please scan your first item.\" Hit SCAN when the marker is in the green."
	go("scan")

func scan_marker() -> float:
	return pingpong(scan_t * 1.3, 1.0)

func scan_in_zone() -> bool:
	var x: = scan_marker()
	return x >= 0.36 and x <= 0.64

func _end_coupons(msg: String) -> void:
	coupons_done = true
	say = msg
	pos = COUPON.get_center() + Vector2(-6, -16)
	go("shop")

func _gag_resolved(msg: String) -> void:
	gag_done = true
	attendant_t = 0.0
	say = msg + " Keep scanning."
	go("scan")
	if scan_i >= scan_list.size():
		_after_scans()

func _after_scans() -> void:
	if price_check and not cart.is_empty():
		pc_item = str(cart.keys()[rng.randi() % cart.size()])
		var real: = int(cart[pc_item])
		pc_opts = [real, real + 1, real + 5]
		pc_opts.shuffle()
		say = "PRICE CHECK: the screen says %s is $%d.99?! The hell? What did the shelf tag say?" % [str(Errands.LABELS.get(pc_item, pc_item)).to_lower(), real + 5]
		go("pricecheck")
	else:
		pay()

func coupon_savings() -> int:
	var s: = 0
	for c in coupons:
		if bool(c[3]) and str(c[1]) != "" and cart.has(str(c[1])):
			s += int(c[2])
	return s

func cologne_price() -> int:
	return int(ceil(Buffs.COLOGNE_PRICE * (m.price_mult() if m and m.has_method("price_mult") else 1.0)))

func buy_cologne() -> bool:

	var p: = cologne_price()
	if m == null or m.money < p:
		flash("Not enough cash. The cologne rack sneers at me.", Color("#e06a4a"))
		return false
	m.money -= p
	m.inventory["cologne"] = int(m.inventory.get("cologne", 0)) + Buffs.COLOGNE_SPRAYS
	flash("I buy {cologne}. -$%d. I already feel 4%% more handsome." % p, Color("#e88aa8"), 1.4)
	return true

func charm_total(x: int) -> int:
	if m and m.has_method("charisma") and m.charisma() > 0:
		return int(floor(x * Buffs.CHA_GROCERY))
	return x

func pay() -> void:
	coupon_save = coupon_savings()
	total = charm_total(maxi(0, cart_total() + overcharge - coupon_save))
	var wallet: int = m.money if m else 999
	if has_errand:
		overage = maxi(0, total - budget)
		change = maxi(0, budget - total)
		if overage > wallet:
			card_strain = true
			overage = wallet
		if m:
			m.money -= overage
	else:
		while total > wallet and not cart.is_empty():
			var worst: = ""
			for id in cart:
				if worst == "" or int(cart[id]) > int(cart[worst]):
					worst = id
			put_back.append(worst)
			cart.erase(worst)
			total = charm_total(maxi(0, cart_total() + overcharge - coupon_save))
		if m:
			m.money -= total
	paid = true
	var lines: = "Total $%d (coupons -$%d)." % [total, coupon_save]
	if charm_total(100) < 100:
		lines += " Self-checkout: SCENT DETECTED. CUSTOMER IS... ALLURING. 10% OFF. (We're selling this data too.)"
	if has_errand:
		lines += " Budget $%d: %s" % [budget, ("$%d under. {partner}'s card, so I keep the change when I drop it off." % change) if change > 0 else (("$%d over, out of my wallet." % overage) if overage > 0 else "dead on.")]
		if card_strain:
			lines += " My wallet runs dry; her card takes the rest. She'll notice."
	if not put_back.is_empty():
		lines += " Card declined. I put back the %s with dignity. What's left of it." % ", ".join(put_back)
	say = lines
	go("receipt")

func _on_button(id: String) -> void:
	match id:
		"leave":
			say = "So I abandon the cart in aisle 2. Sorry, man. I know that's your night now."
			finish(0.0)
		"skip":
			skipped.append(sub_item)
			say = "I skip the %s. 86'd. She'll live." % str(Errands.LABELS.get(sub_item, sub_item)).to_lower()
			go("shop")
		"cp_done":
			_end_coupons("Coupons clipped. I'm saving $%d at the register." % coupon_savings_potential())
		"yes":
			for x in missing_items():
				skipped.append(x)
			begin_scan()
		"no":
			pos = KIOSK.get_center() + Vector2(14, -16)
			say = "Back to the aisles I go."
			go("shop")
		"scan":
			if scan_i >= scan_list.size():
				return
			if scan_in_zone():
				var it: = str(scan_list[scan_i])
				scan_i += 1
				flash("*BEEP* %s" % str(Errands.LABELS.get(it, it)).to_lower(), Color("#c0d890"), 0.6)
				if scan_i == gag_at + 1 and not gag_done:
					lift_tries = 0
					say = "UNEXPECTED ITEM IN BAGGING AREA. Please remove the item. (There is no item. The item is your dignity.)"
					go("bagging")
				elif scan_i >= scan_list.size():
					_after_scans()
			else:
				misses += 1
				flash("*BOOP* Item not scanned. Please try again.", Color("#e06a4a"), 0.8)
		"lift":
			lift_tries += 1
			if lift_tries >= 2:
				_gag_resolved("I lift the bag and set it down like it's a sleeping {baby}. The machine accepts this. Dad skills.")
			else:
				say = "I lift the bag. \"UNEXPECTED ITEM IN BAGGING AREA.\" I put it back. \"UNEXPECTED ITEM IN BAGGING AREA.\""
		"wave":
			if attendant_t <= 0.0:
				attendant_t = 2.5
				say = "I wave. The lone attendant is fixing three other machines. She's coming. Eventually."
		"stare":
			say = "I stare at the machine. It stares back. It's judging my credit score."
		"done":
			finish(1.0)
		"cologne":
			buy_cologne()
		_:
			if id.begins_with("sub_"):
				var i: = int(id.substr(4))
				var o: Array = Errands.SUBS[sub_item][i]
				cart[sub_item] = maxi(0, int(Errands.PRICES.get(sub_item, 2)) + int(o[1]))
				subs += 1
				sub_notes.append(Cast.T("{partner}: " + str(o[2])))
				say = "I grab %s instead." % str(o[0])
				go("shop")
			elif id.begins_with("cp_"):
				var c: Array = coupons[int(id.substr(3))]
				if str(c[1]) != "":
					c[3] = true
					get_button(id)["enabled"] = false
					flash("Clipped! -$%d" % int(c[2]), Color("#c0d890"), 0.7)
					if coupon_savings_potential() >= _max_coupon():
						_end_coupons("I clip all the good coupons. Beat the algorithm at its own game. Heard.")
				else:
					flash(str(c[4]) if c.size() > 4 else "Nope.", Color("#e6a640"), 1.4)
			elif id.begins_with("pc_"):
				var v: = int(pc_opts[int(id.substr(3))])
				var pc_msg: = "Called it! Manager fixes it. The scanner does not apologize. Neither does corporate."
				if v != int(cart[pc_item]):
					overcharge = 5
					pc_msg = "Wrong tag. I pay the scanner's price (+$5). Damn robot wins again."
				pay()
				say = pc_msg + " " + say

func coupon_savings_potential() -> int:
	var s: = 0
	for c in coupons:
		if bool(c[3]):
			s += int(c[2])
	return s

func _max_coupon() -> int:
	var s: = 0
	for c in coupons:
		s += int(c[2])
	return s

func _draw_game() -> void:

	for i in SHELVES.size():
		var s: Rect2 = SHELVES[i]
		draw_rect(Rect2(s.position + Vector2(2, 2), s.size), Color(0, 0, 0, 0.2))
		draw_rect(s, Color("#8a6a4a"))
		for x in range(int(s.position.x) + 4, int(s.end.x) - 4, 9):
			draw_rect(Rect2(x, s.position.y + 1, 6, 6), Color.from_hsv(fmod(x * 0.137 + i * 0.3, 1.0), 0.45, 0.85))
		txt(Vector2(10, s.position.y - 2 - 18.0 + 4.0), AISLE_NAMES[i], 6, Color(0, 0, 0, 0.45))
	for id in items:
		if not SPOTS.has(id):
			continue
		var sp: Vector2 = SPOTS[id]
		var got: = cart.has(id)
		var gone: = skipped.has(id)
		draw_rect(Rect2(sp + Vector2(-4, -4), Vector2(8, 8)), Color(ICON.get(id, "#ffffff")) if not gone else Color(0.5, 0.5, 0.5, 0.4))
		draw_rect(Rect2(sp + Vector2(-4, -4), Vector2(8, 8)), Color(0, 0, 0, 0.6), false, 1.0)
		if id == oos and not got:
			txt(sp + Vector2(-10, -6), "OUT", 6, Color("#a43a2c"))
		elif not got and not gone:
			txt(sp + Vector2(-12, -6 + sin(shop_t * 6.0) * 1.5), "v", 7, Color("#a43a2c"))
			txt(sp + Vector2(6, 3), "$%d" % int(Errands.PRICES.get(id, 2)), 6, Color("#3a5a2c"))
		else:
			txt(sp + Vector2(-3, 3), "x" if gone else "ok", 6, Color.WHITE)

	draw_rect(KIOSK, Color("#2a2a3a"))
	txt(KIOSK.position + Vector2(0, 10), "SELF-CHECK", 6, Color("#c0d890"), HORIZONTAL_ALIGNMENT_CENTER, KIOSK.size.x)
	draw_rect(COUPON, Color("#c8a83a") if not coupons_done else Color("#6a6a5a"))
	txt(COUPON.position + Vector2(0, 10), "COUPONS", 6, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, COUPON.size.x)
	if karen_on:
		var kp: = Vector2(karen_x, KAREN_Y)
		draw_rect(Rect2(kp + Vector2(karen_dir * 6 - 5, -3), Vector2(10, 7)), Color("#9a9aa8"))
		draw_rect(Rect2(kp + Vector2(-3, -4), Vector2(6, 8)), Color("#c86aa0"))
		draw_rect(Rect2(kp + Vector2(-3, -10), Vector2(6, 6)), Color("#f2d2b4"))
		draw_rect(Rect2(kp + Vector2(-4, -12), Vector2(8, 4)), Color("#e8c050"))
		draw_rect(Rect2(kp + Vector2(-karen_dir * 9 - 2, -2), Vector2(5, 7)), Color("#6a8ac0"))
		draw_rect(Rect2(kp + Vector2(-karen_dir * 9 - 2, -7), Vector2(5, 5)), Color("#dcae8e"))

	var cp: = pos + face * 7.0
	draw_rect(Rect2(cp + Vector2(-5, -4), Vector2(10, 8)), Color("#b0b0c0"))
	draw_rect(Rect2(cp + Vector2(-5, -4), Vector2(10, 8)), Color("#5a5a6a"), false, 1.0)
	var n: = 0
	for id in cart:
		draw_rect(Rect2(cp + Vector2(-4 + (n % 3) * 3, -3 + (n / 3) * 3), Vector2(3, 3)), Color(ICON.get(id, "#ffffff")))
		n += 1
	draw_rect(Rect2(pos + Vector2(-3, -2), Vector2(6, 7)), Color("#fbf6ec"))
	draw_rect(Rect2(pos + Vector2(-3, -8), Vector2(6, 6)), Color("#f2d2b4"))
	if stun_t > 0.0:
		txt(pos + Vector2(-6, -11), "!?", 7, Color("#c8573a"))
	if state == "shop":
		_list_bar()
		return
	draw_rect(Rect2(0, 12, W, 140), Color(0.08, 0.07, 0.1, 0.82))
	match state:
		"coupons":
			txt(Vector2(8, 32), "COUPON KIOSK  %.1fs  (clip only what's on the list)" % maxf(0.0, coupon_t), 8, Color("#f2c66a"))
		"scan", "bagging":
			_draw_kiosk()
		"receipt":
			_draw_receipt()
		"sub":
			txt(Vector2(8, 32), "OUT OF STOCK", 10, Color("#e06a4a"))
	var r: = Rect2(6, 120 if state in ["scan", "bagging", "pricecheck", "confirm"] else 128, 308, 24)
	if state == "sub":
		r = Rect2(6, 40, 308, 50)
	if state != "receipt":
		draw_rect(r, Color(0.1, 0.08, 0.15, 0.95))
		mtxt(r.position + Vector2(4, 9), say, r.size.x - 8, 7, Color.WHITE, 4)

func _list_bar() -> void:
	draw_rect(Rect2(0, 152, 258, 28), Color(0.1, 0.08, 0.15, 0.9))
	var parts: Array = []
	for id in items:
		var mark: = "[x]" if cart.has(id) else ("[-]" if skipped.has(id) else "[ ]")
		parts.append("%s %s" % [mark, str(Errands.LABELS.get(id, id)).to_lower()])
	mtxt(Vector2(4, 160), "LIST: " + "  ".join(parts), 252, 6, Color("#f2c66a"), 2)
	mtxt(Vector2(4, 175), say, 252, 6, Color(1, 1, 1, 0.75), 1)

func _draw_kiosk() -> void:
	txt(Vector2(8, 30), "SELF-CHECKOUT  item %d/%d" % [mini(scan_i + 1, scan_list.size()), scan_list.size()], 8, Color("#c0d890"))
	if state == "bagging":
		var blink: = int(t * 3.0) % 2 == 0
		draw_rect(Rect2(40, 44, 240, 40), Color("#a43a2c") if blink else Color("#7a1018"))
		txt(Vector2(40, 60), "UNEXPECTED ITEM", 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 240)
		txt(Vector2(40, 76), "IN BAGGING AREA", 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 240)
		if attendant_t > 0.0:
			bar(Rect2(40, 90, 240, 4), 1.0 - attendant_t / 2.5, Color("#2e5aa8"))
		return
	var r: = Rect2(40, 60, 240, 14)
	draw_rect(r, Color(0.2, 0.2, 0.25))
	draw_rect(Rect2(r.position.x + r.size.x * 0.36, r.position.y, r.size.x * 0.28, r.size.y), Color("#2a8a3a"))
	var mx: = r.position.x + r.size.x * scan_marker()
	draw_rect(Rect2(mx - 1, r.position.y - 3, 3, r.size.y + 6), Color("#c8573a"))
	if scan_i < scan_list.size():
		var id: = str(scan_list[scan_i])
		draw_rect(Rect2(150, 82, 20, 20), Color(ICON.get(id, "#ffffff")))
		txt(Vector2(0, 112), str(Errands.LABELS.get(id, id)), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)

func _draw_receipt() -> void:
	draw_rect(Rect2(90, 16, 140, 134), Color("#fbfaf4"))
	txt(Vector2(90, 26), "{GROCERY}", 7, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, 140)
	var y: = 36.0
	for id in cart:
		txt(Vector2(96, y), str(Errands.LABELS.get(id, id)).substr(0, 20), 6, Color.BLACK)
		txt(Vector2(196, y), "$%d" % int(cart[id]), 6, Color.BLACK)
		y += 8.0
	if overcharge > 0:
		txt(Vector2(96, y), "price check 'oops'", 6, Color("#7a2a22"))
		txt(Vector2(196, y), "$%d" % overcharge, 6, Color("#7a2a22"))
		y += 8.0
	if coupon_save > 0:
		txt(Vector2(96, y), "coupons", 6, Color("#3a5a2c"))
		txt(Vector2(192, y), "-$%d" % coupon_save, 6, Color("#3a5a2c"))
		y += 8.0
	txt(Vector2(96, y + 4), "TOTAL", 7, Color.BLACK)
	txt(Vector2(192, y + 4), "$%d" % total, 7, Color.BLACK)
	mtxt(Vector2(96, y + 16), say, 128, 6, Color(0.2, 0.2, 0.2), 6)
