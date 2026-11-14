extends "res://scripts/minigames/minigame.gd"

const Errands: = preload("res://scripts/errands.gd")
const Buffs: = preload("res://scripts/buffs.gd")
const FLOOR: = Rect2(8, 14, 304, 136)
const SHELVES: = [Rect2(46, 36, 228, 8), Rect2(46, 64, 228, 8), Rect2(46, 92, 228, 8), Rect2(46, 120, 228, 8)]
const AISLE_NAMES: = ["1 Bakery + baking", "2 Produce + dairy", "3 Baby + Ensure", "4 Pets + snacks"]
## Each list item sits on top of the shelf run under its aisle (shelf y - 3), grabbed from the lane above.
const SPOTS: = {
	"honey buns": Vector2(90, 33), "flour": Vector2(160, 33), "chocolate": Vector2(235, 33),
	"cherries": Vector2(80, 61), "eggs": Vector2(155, 61), "cream": Vector2(240, 61),
	"formula": Vector2(90, 89), "diapers": Vector2(170, 89), "ensure": Vector2(250, 89),
	"treats": Vector2(120, 117),
}
const ICON: = {"honey buns": "#d9a441", "flour": "#f4f0e0", "chocolate": "#5a3220", "cherries": "#c0182a", "eggs": "#f6ead0",
	"cream": "#eef4ff", "formula": "#7ab0e0", "diapers": "#a0d0a0", "ensure": "#e6e6f0", "treats": "#e08a2a" }
const KIOSK: = Rect2(18, 134, 44, 14)
const STOCK: = ["kf_shop_honey", "kf_shop_flour", "kf_shop_chocolate", "kf_shop_cherries", "kf_shop_eggs",
	"kf_shop_cream", "kf_shop_formula", "kf_shop_diapers", "kf_shop_ensure", "kf_shop_treats"]
const COUPON: = Rect2(258, 134, 44, 14)
const START: = Vector2(160, 140)
const ACCEL: = 260.0
const MAX_V: = 85.0
const R: = 5.0
const KAREN_Y: = 53.0
const DECOYS: = [["$0.50 off Bigfoot repellent", "Bigfoot has not been spotted in {city}. Yet."], ["EXPIRED: eggnog, 1998", "Expired in 1998. The eggnog has evolved."], ["BOGO garden gnome", "Nobody needs a gnome. The economy needs you to need a gnome."], ["10% off a $400 blender", "Saving $40 by spending $400. Finance bros call this 'alpha.'"], ["Free sample: mystery dip", "Not a coupon. A data-harvesting agreement with a dip."]]
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
var pops: Array = []
var karen_say: = ""
var karen_say_t: = 0.0
const KAREN_BARKS: = ["MANAGER!", "Do you WORK here?", "This aisle is MINE.", "Excuse ME."]

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
	show_header = s != "shop"   # the shop shows the painted HY-WHEE sign + its own budget/cart chips
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
	karen_say_t = maxf(0.0, karen_say_t - d)
	_tick_pops(d)
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
			pop("Got it! $%d" % int(cart[id]), SPOTS[id] + Vector2(0, -14), Color("#c0f090"))
	if not coupons_done and COUPON.grow(6).has_point(pos):
		coupon_t = 7.0
		vel = Vector2.ZERO
		say = "Coupon kiosk! Clip the ones on my list before it times out (7s)."
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
		pop("CLANG!", pos + Vector2(0, -24), Color("#f2b63c"))
		say = "CLANG. \"Clean up on aisle %d.\"" % aisle

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
		karen_say = KAREN_BARKS[(karen_hits - 1) % KAREN_BARKS.size()]
		karen_say_t = 1.6

func begin_scan() -> void:
	scan_list = cart.keys()
	scan_i = 0
	scan_t = 0.0
	say = "Self-checkout: \"Please scan your first item.\" Hit SCAN when the marker is in the green."
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
		flash("Not enough cash. I sniff the tester. That's as close as I get.", Color("#e06a4a"))
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
		lines += " Card declined. I put back the %s. We had a good run." % ", ".join(put_back)
	say = lines
	go("receipt")

func _on_button(id: String) -> void:
	match id:
		"leave":
			say = "Abandoned the cart in aisle 2. Sorry, man. I know that's your night now."
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
			say = "Back to the aisles."
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
						_end_coupons("I clip all the good coupons. Beat the algorithm at its own game.")
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

## Aisle sign: a dark tag in the lane's empty left end, just above its shelf (Nov 9 QA: the old
## translucent text sat on the painted shelves/windows of the backdrop and was hard to read).
func aisle_tag_rect(i: int) -> Rect2:
	var s: Rect2 = SHELVES[i]
	var w: = font.get_string_size(AISLE_NAMES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x + 6.0
	return Rect2(10, s.position.y - 11, w, 9)

func _aisle_tag(i: int) -> void:
	var r: = aisle_tag_rect(i)
	draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, Color("#2a2a3a"))
	draw_rect(r, Color("#c0d890"), false, 1.0)
	txt(r.position + Vector2(3, 7), AISLE_NAMES[i], 6, Color("#f4f0e0"))

## Painted shelf run i as it sits in bg_grocery (tools/grocery_floor_compose.py): the collision rect
## plus the stocked top that shows above it.
func shelf_art_rect(i: int) -> Rect2:
	var s: Rect2 = SHELVES[i]
	return Rect2(s.position.x, s.position.y - 4.0, s.size.x, s.size.y + 5.5)

## Redraw one shelf run from the backdrop so it covers whoever stands behind it (y-sort).
func _shelf(i: int) -> void:
	var bg: = Art.tex("bg_grocery")
	if bg == null:
		var s: Rect2 = SHELVES[i]
		draw_rect(Rect2(s.position + Vector2(2, 2), s.size), Color(0, 0, 0, 0.2))
		draw_rect(s, Color("#8a6a4a"))
		return
	var k: = float(bg.get_width()) / W
	var r: = shelf_art_rect(i)
	draw_texture_rect_region(bg, r, Rect2(r.position * k, r.size * k))

## The list items on shelf i: one big painted item each, a shelf tag with its price under it.
func _shelf_items(i: int) -> void:
	for id in items:
		if not SPOTS.has(id) or not is_equal_approx(SPOTS[id].y, SHELVES[i].position.y - 3.0):
			continue
		var sp: Vector2 = SPOTS[id]
		var got: = cart.has(id)
		var gone: = skipped.has(id)
		var tint: = Color.WHITE if not (got or gone) else Color(0.55, 0.55, 0.6, 0.55)
		Art.shadow(self, sp + Vector2(0, 4.5), 6.0, 1.6, 0.35)
		if not pic(_icon(id), sp + Vector2(0, -3), 15.0, tint):
			draw_rect(Rect2(sp + Vector2(-6, -10), Vector2(12, 12)), Color(ICON.get(id, "#ffffff")) * tint)
			draw_rect(Rect2(sp + Vector2(-6, -10), Vector2(12, 12)), UiStyle.INK, false, 1.0)
		var tag: = Rect2(sp + Vector2(-8, 5), Vector2(16, 8))
		if id == oos and not got:
			draw_rect(tag, Color("#a43a2c"))
			draw_rect(tag, UiStyle.INK, false, 1.0)
			txt(tag.position + Vector2(0, 6.5), "OUT", 6, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x)
		elif got:
			_badge(sp + Vector2(6, -9), Color("#4e9a3a"), true)
		elif gone:
			_badge(sp + Vector2(6, -9), Color("#7a7a80"), false)
		else:
			draw_rect(tag, Color("#fff1a8"))
			draw_rect(tag, UiStyle.INK, false, 1.0)
			txt(tag.position + Vector2(0, 6.5), "$%d" % int(Errands.PRICES.get(id, 2)), 7, UiStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x)
			# bobbing "grab me" arrow over items still on the list
			var ay: = sp.y - 15.0 + sin(shop_t * 6.0) * 1.2
			var tri: = PackedVector2Array([Vector2(sp.x - 3.5, ay - 3), Vector2(sp.x + 3.5, ay - 3), Vector2(sp.x, ay + 1.5)])
			draw_colored_polygon(tri, UiStyle.INK)
			draw_colored_polygon(PackedVector2Array([tri[0] + Vector2(1.2, 0.6), tri[1] + Vector2(-1.2, 0.6), tri[2] + Vector2(0, -1.2)]), Color("#f2b63c"))

## Round badge with a tick (got it) or a cross (skipped).
func _badge(c: Vector2, col: Color, tick: bool) -> void:
	draw_circle(c, 3.6, UiStyle.INK)
	draw_circle(c, 2.8, col)
	if tick:
		draw_polyline(PackedVector2Array([c + Vector2(-1.6, 0), c + Vector2(-0.4, 1.3), c + Vector2(1.8, -1.4)]), Color.WHITE, 1.0)
	else:
		draw_line(c + Vector2(-1.4, -1.4), c + Vector2(1.4, 1.4), Color.WHITE, 1.0)
		draw_line(c + Vector2(1.4, -1.4), c + Vector2(-1.4, 1.4), Color.WHITE, 1.0)

func _draw_game() -> void:
	if state == "shop":
		_shop_hud()
	for i in SHELVES.size():
		_aisle_tag(i)
	_station(KIOSK, "kf_kiosk_self", "SELF-CHECK", Color("#2a2a3a"), Color("#c0d890"), true)
	_station(COUPON, "kf_kiosk_coupon", "COUPONS", Color("#c8a83a"), Color.BLACK, not coupons_done)
	# y-sorted layers: shelf runs (with their items), Karen's party, Duff + cart
	var layers: Array = []
	for i in SHELVES.size():
		layers.append([SHELVES[i].position.y, "shelf", i])
	if karen_on:
		layers.append([KAREN_Y, "karen", 0])
	layers.append([pos.y, "duff", 0])
	layers.sort_custom(func (a, b): return a[0] < b[0])
	for l in layers:
		match str(l[1]):
			"shelf":
				_shelf(int(l[2]))
				_shelf_items(int(l[2]))
			"karen":
				var kp: = Vector2(karen_x, KAREN_Y)
				if not _people(kp, karen_dir):
					_karen_rects(kp)
			"duff":
				_draw_duff_and_cart()
	if karen_on and karen_say_t > 0.0:
		_bubble(Vector2(karen_x, KAREN_Y - 22), karen_say)
	if stun_t > 0.0:
		UiStyle.label(self, pos + Vector2(-5, -22), "!?", 9, Color("#ff8a5a"), -1.0, HORIZONTAL_ALIGNMENT_LEFT, 3)
	_draw_pops()
	_draw_overlay()

func _draw_duff_and_cart() -> void:
	var cp: = pos + face * 9.0
	var front: = face.y > 0.3   # pushing toward the camera: the cart is drawn over Duff
	if front:
		_draw_duff()
	if not _cart(cp):
		_cart_rects(cp)
	if not front:
		_draw_duff()

## Budget + cart chips on the back wall, either side of the painted HY-WHEE sign (the shop hides the
## title bar so the sign shows).
func _shop_hud() -> void:
	var money: = ("Budget $%d" % budget) if has_errand else ("Your $%d" % (m.money if m else 0))
	_chip(Rect2(4, 1.5, 64, 10), money, UiStyle.GOLD)
	var over: = has_errand and cart_total() > budget
	_chip(Rect2(W - 68, 1.5, 64, 10), "Cart $%d" % cart_total(), Color("#e06a4a") if over else UiStyle.CREAM)

func _chip(r: Rect2, label: String, col: Color) -> void:
	draw_rect(Rect2(r.position + Vector2(1, 1), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, col)
	draw_rect(r, UiStyle.INK, false, 1.0)
	draw_string(UiStyle.display, r.position + Vector2(0, 8), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 8, UiStyle.INK)

## Small comic speech bubble with a tail, anchored at its tail tip.
func _bubble(tip: Vector2, s: String) -> void:
	var w: = UiStyle.display.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 8.0
	var r: = Rect2(clampf(tip.x - w * 0.5, 2.0, W - w - 2.0), tip.y - 13.0, w, 10.0)
	var tail: = PackedVector2Array([Vector2(tip.x - 3, r.end.y - 0.5), Vector2(tip.x + 3, r.end.y - 0.5), tip + Vector2(0, 3)])
	draw_rect(r.grow(1.0), UiStyle.INK)
	draw_colored_polygon(PackedVector2Array([tail[0] + Vector2(-1, 0), tail[1] + Vector2(1, 0), tail[2] + Vector2(0, 1.2)]), UiStyle.INK)
	draw_rect(r, Color.WHITE)
	draw_colored_polygon(tail, Color.WHITE)
	draw_string(UiStyle.display, r.position + Vector2(0, 7.5), s, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 7, UiStyle.INK)

## Floating outlined text over the floor ("+$2", "CLANG!") instead of a banner across the aisles.
func pop(s: String, p: Vector2, col: Color) -> void:
	pops.append({"s": s, "p": p, "col": col, "t": 0.0})

func _tick_pops(d: float) -> void:
	for p in pops:
		p["t"] = float(p["t"]) + d
	pops = pops.filter(func (p): return float(p["t"]) < 1.0)

func _draw_pops() -> void:
	for p in pops:
		var k: = float(p["t"])
		var c: Color = p["col"]
		c.a = clampf(2.0 - k * 2.0, 0.0, 1.0)
		var at: Vector2 = p["p"] + Vector2(-40.0, -k * 10.0)
		UiStyle.label(self, at, str(p["s"]), 8, c, 80.0, HORIZONTAL_ALIGNMENT_CENTER, 3)

func _karen_rects(kp: Vector2) -> void:
		draw_rect(Rect2(kp + Vector2(karen_dir * 6 - 5, -3), Vector2(10, 7)), Color("#9a9aa8"))
		draw_rect(Rect2(kp + Vector2(-3, -4), Vector2(6, 8)), Color("#c86aa0"))
		draw_rect(Rect2(kp + Vector2(-3, -10), Vector2(6, 6)), Color("#f2d2b4"))
		draw_rect(Rect2(kp + Vector2(-4, -12), Vector2(8, 4)), Color("#e8c050"))
		draw_rect(Rect2(kp + Vector2(-karen_dir * 9 - 2, -2), Vector2(5, 7)), Color("#6a8ac0"))
		draw_rect(Rect2(kp + Vector2(-karen_dir * 9 - 2, -7), Vector2(5, 5)), Color("#dcae8e"))

func _draw_duff() -> void:
	if not _duff(pos):
		draw_rect(Rect2(pos + Vector2(-3, -2), Vector2(6, 7)), Color("#fbf6ec"))
		draw_rect(Rect2(pos + Vector2(-3, -8), Vector2(6, 6)), Color("#f2d2b4"))

func _cart_rects(cp: Vector2) -> void:
	draw_rect(Rect2(cp + Vector2(-5, -4), Vector2(10, 8)), Color("#b0b0c0"))
	draw_rect(Rect2(cp + Vector2(-5, -4), Vector2(10, 8)), Color("#5a5a6a"), false, 1.0)
	var n: = 0
	for id in cart:
		draw_rect(Rect2(cp + Vector2(-4 + (n % 3) * 3, -3 + (n / 3) * 3), Vector2(3, 3)), Color(ICON.get(id, "#ffffff")))
		n += 1

## Painted shelf items: kf_shop_* (tools/import_kitchen_props.py k6 sheet).
func _icon(id: String) -> String:
	return "kf_shop_honey" if id == "honey buns" else "kf_shop_" + id

## Self-check / coupon station: painted kiosk standing on its spot with a name plate; flat box if the art is missing.
func _station(r: Rect2, art: String, label: String, col: Color, ink: Color, lit: bool) -> void:
	if Art.tex(art) == null:
		draw_rect(r, col if lit else Color("#6a6a5a"))
		txt(r.position + Vector2(0, 10), label, 6, ink, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		return
	Art.shadow(self, Vector2(r.get_center().x, r.end.y - 1.0), 10.0, 2.5, 0.35)
	pic(art, Vector2(r.get_center().x, r.end.y - 14.0), 24.0, Color.WHITE if lit else Color(0.55, 0.55, 0.55))
	var plate: = Rect2(r.position.x + 2.0, r.end.y - 6.0, r.size.x - 4.0, 7.0)
	draw_rect(plate, Color(0.08, 0.07, 0.1, 0.85))
	txt(plate.position + Vector2(0, 6), label, 5, Color("#f2c66a") if lit else Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_CENTER, plate.size.x)

const PEOPLE_SCALE: = 0.75   # overworld sprites (32 tall) at 24 units: big enough to read on a phone, under one lane + shelf

## Karen with her cart, plus the buddy she dragged along, as their overworld sprites. False if the art is missing.
func _people(kp: Vector2, dir: float) -> bool:
	if Art.tex("ch_karen") == null:
		return false
	_small_person("ch_karen_buddy", kp + Vector2(-dir * 13.0, 4.0), Vector2(dir, 0), true)
	pic("sd_shopping_cart", kp + Vector2(dir * 11.0, -2.0), 15.0)
	_small_person("ch_karen", kp + Vector2(0, 4.0), Vector2(dir, 0), true)
	return true

## Sprite at PEOPLE_SCALE with a 1-unit ink outline (8 offset ink copies under it), so it reads on the floor.
func _small_person(name: String, foot: Vector2, dir: Vector2, moving: bool) -> void:
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		draw_set_transform(foot + o * 0.9, 0.0, Vector2(PEOPLE_SCALE, PEOPLE_SCALE))
		Art.person(self, name, Vector2.ZERO, dir, t, moving, false, Color(UiStyle.INK, 0.9), false)
	draw_set_transform(foot, 0.0, Vector2(PEOPLE_SCALE, PEOPLE_SCALE))
	Art.person(self, name, Vector2.ZERO, dir, t, moving)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _cart(cp: Vector2) -> bool:
	if Art.tex("sd_shopping_cart") == null:
		return false
	pic("sd_shopping_cart", cp + Vector2(0, -1), 15.0)
	var n: = 0
	for id in cart:   # what's in the basket peeks over the rim
		pic(_icon(id), cp + Vector2(-4.5 + (n % 3) * 4.5, -8.0 - (n / 3) * 3.0), 6.5)
		n += 1
	return true

func _duff(p: Vector2) -> bool:
	if Art.tex("duff_home") == null:
		return false
	_small_person("duff_home", p + Vector2(0, 5.0), face, vel.length() > 5.0)
	return true

func _draw_overlay() -> void:
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

## Shopping list as chips: item picture + name; ticked and dimmed once it's in the cart, crossed out
## if skipped. Duff's last line runs underneath.
func _list_bar() -> void:
	UiStyle.panel(self, Rect2(0, 151, 259, 29), UiStyle.PANEL, 0.94, 1.0 / 1.5)
	var ids: Array = items.keys()
	var cols: = maxi(1, int(ceil(ids.size() / 2.0)))
	var cw: = 254.0 / cols
	for n in ids.size():
		var id: = str(ids[n])
		var at: = Vector2(4 + (n % cols) * cw, 153 + (n / cols) * 9)
		var got: = cart.has(id)
		var gone: = skipped.has(id)
		var dim: = got or gone
		if dim:   # done: the tick (or cross) takes the picture's place
			_badge(at + Vector2(3.5, 4), Color("#4e9a3a") if got else Color("#7a7a80"), got)
		else:
			pic(_icon(id), at + Vector2(3.5, 4), 7.0)
		var label: = str(Errands.LABELS.get(id, id)).to_lower()
		var col: = Color(1, 1, 1, 0.45) if dim else UiStyle.CREAM
		txt(at + Vector2(9, 6.5), label, 6, col, HORIZONTAL_ALIGNMENT_LEFT, cw - 16)
		if dim:
			var lw: = minf(font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x, cw - 16)
			draw_line(at + Vector2(9, 4.5), at + Vector2(9 + lw, 4.5), Color(1, 1, 1, 0.5), 0.6)
	mtxt(Vector2(4, 177), say, 252, 6, Color(1, 1, 1, 0.75), 1)

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
		if not pic(_icon(id), Vector2(160, 92), 22.0):
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
