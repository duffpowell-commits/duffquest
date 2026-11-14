extends SceneTree
## Headless checks for the daily-life layer (shift shuffle, muscle memory, calendar, curveballs).
##   godot --headless --path . --script tools/test_daily.gd
## Prints PASS/FAIL per check and exits 1 on any failure.

const Shift: = preload("res://scripts/shift.gd")
const SaveGame: = preload("res://scripts/save_game.gd")
var fails: = 0

func check(name: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + name)
	if not ok:
		fails += 1

func _init() -> void:
	# web: walls come from baked rects (world.pck carries the art); they must match the textures
	check("data/art_rects.json matches sf_/sd_ art (re-run tools/bake_art_rects.gd)",
		FileAccess.get_file_as_string("res://data/art_rects.json") == JSON.stringify(preload("res://tools/bake_art_rects.gd").measure(), "\t", true) + "\n")
	_edition_checks()
	# full shift: quiz first, same 8 stations, order changes across shifts
	var orders: = {}
	for i in 30:
		var o: Array = Shift.full_order()
		orders[str(o)] = true
		if i == 0:
			check("full shift keeps quiz first", o[0] == "quiz")
			var a: = o.duplicate(); a.sort()
			var b: Array = Shift.FULL.duplicate(); b.sort()
			check("full shift has all 8 stations once", a == b)
	check("full shift order varies (got %d orders in 30)" % orders.size(), orders.size() > 5)

	# muscle memory
	var sh: Node = Shift.new()
	var fake: = FakeMain.new()
	sh.m = fake
	fake.station_best = {"fryer": "S", "salad": "A"}
	check("autopilot offered for S station", sh.can_autopilot("fryer"))
	check("autopilot not offered for A station", not sh.can_autopilot("salad"))
	check("autopilot never for inspector", not sh.can_autopilot("inspector"))
	check("autopilot grade is B", Shift.grade_for(Shift.AUTOPILOT_SCORE) == "B")
	sh.free()

	# record + save round trip on the real main scene
	var main: Node = load("res://main.tscn").instantiate()
	main.save_path = "user://test_daily_save.json"   # never touch the real save
	root.add_child(main)
	await process_frame
	main.station_best = {}
	main.record_station_bests([
		{"key": "fryer", "grade": "A", "kind": "station"},
		{"key": "salad", "grade": "S", "kind": "station"},
		{"key": "inspector", "grade": "S", "kind": "event"},
	])
	main.record_station_bests([
		{"key": "fryer", "grade": "S", "kind": "station"},
		{"key": "salad", "grade": "B", "kind": "station", "autopilot": true},
	])
	check("best grade upgrades A -> S", main.station_best.get("fryer") == "S")
	check("autopilot doesn't overwrite best", main.station_best.get("salad") == "S")
	check("events aren't stations", not main.station_best.has("inspector"))
	var d: Dictionary = main.to_dict()
	main.station_best = {}
	main.from_dict(JSON.parse_string(JSON.stringify(d)))
	check("station_best survives save/load", main.station_best.get("fryer") == "S")
	_extra_checks(main)
	_money_path_checks(main)
	_review_fix_checks(main)
	_ko_sfx_checks()
	_ko_gore_checks()
	_button_fit_checks()
	_qa_leftover_checks()
	_signature_move_checks(main)
	_heard_checks()
	_taunt_variety_checks()
	_side_quest_checks(main)
	_morning_checks(main)
	_zebra_checks(main)
	_too_loud_checks(main)
	_look_checks(main)
	_spatter_cut_checks()
	_first_bet_checks(main)
	SaveGame.erase("user://test_daily_save.json")
	main.queue_free()
	await process_frame
	print("%s (%d failed)" % ["ALL PASS" if fails == 0 else "FAILURES", fails])
	quit(1 if fails > 0 else 0)

## Nov 14 portal review: a second fight inside five minutes. Cold-open pirate down -> {coworker}'s first bet
## (Marketplace Mike, alley) -> payout -> rules. Pitched once; a loss costs nothing.
func _first_bet_checks(main: Node) -> void:
	var B: = preload("res://scripts/boss.gd")
	check("first bet: Mike is a boss", B.BOSSES.has("mike"))
	main.new_game(false)
	main.dialog.clear()
	var pirate: Node = null
	for e in main.get_tree().get_nodes_in_group("enemy"):
		if e.has_meta("cold_open"):
			pirate = e
	check("first bet: cold open spawns the pirate", pirate != null)
	if pirate == null:
		return
	main.enemy_defeated(pirate)
	var cash0: int = main.money   # the pirate's own drop is in
	check("first bet: pirate KO opens {coworker}'s bet card", main.overlay_node != null)
	check("first bet: pitched flag set", bool(main.story.get("first_bet", false)))
	check("first bet: rules held until the bet", bool(main.story.get("cold_open", false)))
	main.close_overlay()
	main.dialog.clear()
	main.start_first_bet()
	main.dialog.clear()
	check("first bet: alley arena", main.location == "arena" and main.arena_mode == "firstbet" and main.arena_boss != null)
	var boss: Node = main.arena_boss
	main.boss_defeated(boss)
	if main.arena_mode == "firstbet":   # knockout cutscene ran first
		main.boss_defeated(boss)
	check("first bet: back on the street", main.location == "outside" and main.arena_mode == "")
	check("first bet: pays $%d" % main.FIRST_BET_PAY, main.money == cash0 + main.FIRST_BET_PAY)
	check("first bet: counts on her record, today's bet used", int(main.bet["won"]) == 1 and int(main.bet["day"]) == main.day_count)
	check("first bet: rules shown after", not bool(main.story.get("cold_open", true)))
	var d: Dictionary = main.to_dict()
	main.from_dict(JSON.parse_string(JSON.stringify(d)))
	check("first bet: pitched flag survives save/load", bool(main.story.get("first_bet", false)))
	# never pitched twice: a later cold-open-style call goes straight to rules
	main.dialog.clear()
	main.first_bet_pitch("")
	check("first bet: not pitched twice", main.overlay_node == null)
	# a loss on a fresh game: no money lost, still to the rules
	main.dialog.clear()
	main.new_game(false)
	main.dialog.clear()
	cash0 = main.money
	main.story["first_bet"] = true
	main.story["cold_open"] = true
	main.start_first_bet()
	main.dialog.clear()
	main.energy = 0.0
	main._arena_process(0.1)
	check("first bet: a loss costs nothing", main.money == cash0 and int(main.bet["lost"]) == 1)
	check("first bet: a loss still ends on the street with rules", main.location == "outside" and not bool(main.story.get("cold_open", true)))
	main.dialog.clear()

const Daily: = preload("res://scripts/daily.gd")
const TransitS: = preload("res://scripts/transit.gd")
const MarketS: = preload("res://scripts/market.gd")
const DatesS: = preload("res://scripts/dates.gd")
const SymphonyS: = preload("res://scripts/minigames/symphony.gd")

## Paths the 30-day soak bot never takes (docs/qa/soak_report.md): bus pass, minivan, stock trades,
## the college fund, the symphony date. Money must never go negative or vanish.
func _money_path_checks(main: Node) -> void:
	main.no_loading = true
	main.close_overlay()
	main.dialog.clear()
	var keep_story: Dictionary = main.story.duplicate(true)
	main.day_count = 6
	# bus pass
	main.bus_pass_until = -1
	main.has_car = false
	main.money = TransitS.PASS_PRICE - 1
	main.buy_bus_pass()
	check("bus pass refused when short, money kept", main.money == TransitS.PASS_PRICE - 1 and not main.pass_active())
	main.money = 100
	main.buy_bus_pass()
	check("bus pass: -$%d, good through day %d" % [TransitS.PASS_PRICE, main.day_count + TransitS.PASS_DAYS - 1],
		main.money == 100 - TransitS.PASS_PRICE and main.bus_pass_until == main.day_count + TransitS.PASS_DAYS - 1)
	main.buy_bus_pass()
	check("second bus pass not charged", main.money == 100 - TransitS.PASS_PRICE)
	check("pass rides free on its last day", main.fare_for(2) == 0)
	main.day_count = main.bus_pass_until + 1
	check("pass expires: fare back to $%d" % TransitS.FARE, main.fare_for(1) == TransitS.FARE)
	main.day_count = 6
	# minivan
	main.story["ending_seen"] = false
	main.money = 5000
	main.buy_car()
	check("minivan locked before the ending", not main.has_car and main.money == 5000)
	main.story["ending_seen"] = true
	main.money = TransitS.CAR_PRICE - 1
	main.buy_car()
	check("minivan refused when short", not main.has_car and main.money == TransitS.CAR_PRICE - 1)
	main.money = TransitS.CAR_PRICE + 10
	main.happiness = 95.0
	main.buy_car()
	check("minivan bought: -$%d, rides free, happiness capped" % TransitS.CAR_PRICE,
		main.has_car and main.money == 10 and main.fare_for(2) == 0 and main.happiness <= 100.0)
	var d: Dictionary = JSON.parse_string(JSON.stringify(main.to_dict()))
	main.has_car = false
	main.bus_pass_until = -1
	main.from_dict(d)
	check("minivan + bus pass survive save/load", main.has_car and main.bus_pass_until == 6 + TransitS.PASS_DAYS - 1)
	main.has_car = false
	main.bus_pass_until = -1
	main.story = keep_story
	# brokerage: buy and sell at one price keeps total wealth (cents may sit in brokerage cash)
	main.market = MarketS.new_state(1234)
	main.brokerage = MarketS.new_account(false)
	main.money = 500
	var wealth: = func () -> float: return float(main.money) + float(main.brokerage["cash"]) + MarketS.holdings_value(main.brokerage, main.market)
	var w0: float = wealth.call()
	var spent: float = main.trade_buy("brokerage", "VOOM", 200.0)
	check("buy $200 of VOOM: wallet $%d" % main.money, is_equal_approx(spent, 200.0) and main.money == 300)
	check("buy keeps total wealth ($%.2f -> $%.2f)" % [w0, wealth.call()], absf(wealth.call() - w0) < 0.01)
	main.trade_buy("brokerage", "GMSTP", -1.0)
	check("buy everything: wallet $0, never negative", main.money == 0 and float(main.brokerage["cash"]) >= 0.0)
	main.trade_sell("brokerage", "GMSTP", 1.0)
	main.trade_sell("brokerage", "VOOM", 1.0)
	check("sell everything: wealth back ($%.2f)" % wealth.call(), absf(wealth.call() - w0) < 0.01 and MarketS.holdings_value(main.brokerage, main.market) < 0.01)
	check("selling nothing returns 0", main.trade_sell("brokerage", "DOGEB", 1.0) == 0.0)
	main.trade_buy("brokerage", "BUNZ", 300.0)
	main.trade_buy("brokerage", "DOGEB", 100.0)
	var bad: = []
	for wk in 60:
		main.market_week()
		for a in MarketS.ASSETS:
			var px: float = MarketS.price(main.market, a["t"])
			if is_nan(px) or is_inf(px) or px <= 0.0:
				bad.append("%s wk%d" % [a["t"], wk])
	var wv: float = wealth.call()
	check("60 market weeks: prices finite and > 0 (%s)" % ", ".join(bad.slice(0, 4)), bad.is_empty())
	check("60 market weeks: wealth finite, wallet >= 0 ($%.2f)" % wv, not is_nan(wv) and not is_inf(wv) and wv >= 0.0 and main.money >= 0)
	# college fund
	main.college = MarketS.new_account(true)
	main.money = 50
	var dep: int = main.fund_deposit(100)
	check("fund deposit capped at the wallet ($%d)" % dep, dep == 50 and main.money == 0 and is_equal_approx(float(main.college["cash"]), 50.0))
	check("fund deposit with $0 does nothing", main.fund_deposit(-1) == 0 and main.money == 0)
	check("college buy with no cash spends nothing", main.trade_buy("college", "VOOM", 500.0) <= 50.0 and float(main.college["cash"]) >= 0.0)
	main.brokerage = MarketS.new_account(true)
	main.college = MarketS.new_account(true)
	# symphony date
	check("symphony comes after a sushi date (day 4+)",
		DatesS.next_kind({"akarui": 1, "symphony": 0}, 5) == "symphony" and DatesS.next_kind({"akarui": 0, "symphony": 0}, 5) == "akarui")
	check("no date before day 2", DatesS.next_kind(DatesS.new_stats(), 1) == "")
	main.location = "home"
	main.invite_date("symphony")
	main.money = DatesS.SITTER_COST + DatesS.TICKETS - 1
	check("symphony refused when short of sitter + tickets", not main.start_date("symphony", "sitter") and main.money == DatesS.SITTER_COST + DatesS.TICKETS - 1)
	main.dialog.clear()
	var stats_before: Dictionary = main.date_stats.duplicate()
	main.happiness = 40.0
	var g: Node = SymphonyS.new()
	main._after_date(g, 1.0, [], "symphony")
	check("symphony date: happiness up, counted, invite cleared",
		main.happiness > 40.0 and int(main.date_stats["symphony"]) == int(stats_before["symphony"]) + 1 and str(main.date_invite["kind"]) == "")
	check("symphony date: Culture Vulture unlocked", main.achievements.has("Culture Vulture"))
	g.free()
	main.dialog.clear()
	main.money = 0

func _extra_checks(main: Node) -> void:
	# calendar data
	var days: Dictionary = Daily.calendar().get("days", {})
	check("calendar has all 30 days", days.size() == 30)
	var bad: = []
	for k in days:
		var e: Dictionary = days[k]
		if str(e.get("card", "")) == "": bad.append(k)
		for n in e.get("notes", []):
			if not str(n.get("from", "")) in ["hero", "partner", "baby", "cat1", "cat2", "cat3"]: bad.append(k)
	check("every day has a card, every note a known author %s" % str(bad), bad.is_empty())
	check("day 10 is a headline (Falcor)", bool(Daily.entry(10).get("headline", false)) and Daily.entry(10).get("event") == "falcor")
	check("no calendar past the month", Daily.entry(31).is_empty())
	check("day 31 is December 1", Daily.month_name(31) == "DECEMBER" and Daily.day_of_month(31) == 1)
	# events
	var ids: = {}
	for e in Daily.events_data().get("events", []):
		ids[str(e["id"])] = str(e.get("pool", ""))
	check("event ids unique and pooled", ids.size() == Daily.events_data()["events"].size() and not ids.values().has(""))
	check("headline day rolls no event", Daily.roll(10, 6, [], 5, 123) == "")
	check("roll is deterministic", Daily.roll(5, 1, [], 0, 77) == Daily.roll(5, 1, [], 0, 77))
	var weekend_ok: = true
	var repeat_ok: = true
	var beaten_ok: = true
	var hits: = 0
	for sd in 400:
		var id: = Daily.roll(5 + sd % 20, 5, [], 0, sd)
		if id != "":
			hits += 1
			if ids[id] != "weekend": weekend_ok = false
		var id2: = Daily.roll(4, 1, ["inspector", "ice"], 0, sd)
		if id2 in ["inspector", "ice"]: repeat_ok = false
		if Daily.roll(4, 1, [], 0, sd) == "boss_tips": beaten_ok = false
	check("weekend rolls only weekend events", weekend_ok)
	check("recent events don't repeat", repeat_ok)
	check("boss_tips needs a beaten boss", beaten_ok)
	check("roughly 75%% of mornings get an event (%d/400)" % hits, hits > 240 and hits < 360)
	check("no_repeat list capped", Daily.remember(["a", "b", "c", "d", "e"], "f") == ["b", "c", "d", "e", "f"])
	check("short_staffed = full shift only, x1.5", Daily.shift_modes("short_staffed") == ["full"] and Daily.shift_pay("short_staffed") == 1.5)
	check("quiet day = no modifiers", Daily.shift_pay("") == 1.0 and Daily.walk("") == 1.0 and Daily.spawn("") == 1.0)
	# main wiring
	main.day_count = 4
	main.day_i = 7
	main.daily = Daily.new_state()
	main.daily_new_day()
	check("morning roll stamps today", int(main.daily["day"]) == 4)
	main.daily = {"day": 4, "id": "ice", "recent": ["ice"], "falcor": ""}
	check("today_event reads today's id", main.today_event() == "ice")
	check("ice counts as the headline (bill roll waits)", main.daily_headline())
	main.apply_gear()
	check("ice slows walking", main.player.speed_mult < 0.9)
	main.day_count = 5
	check("yesterday's event expires", main.today_event() == "")
	main.daily = {"day": 5, "id": "", "recent": [], "falcor": ""}
	main.day_count = 2
	main.daily = {"day": 2, "id": "lazy", "recent": [], "falcor": ""}
	var d: Dictionary = main.to_dict()
	main.daily = Daily.new_state()
	main.from_dict(JSON.parse_string(JSON.stringify(d)))
	check("daily state survives save/load", main.today_event() == "lazy")
	var sh: Node = Shift.new()
	sh.modes = ["quick"]
	var opts: Array = sh.menu_opts()
	check("sick day menu = Quick + Never mind", opts.size() == 2 and opts[0][0] == "quick")
	sh.free()
	await _falcor_checks(main)
	_soak_regressions(main)
	_gala_gate_checks(main)
	_bedtime_skip_checks(main)
	_balance_checks(main)
	_touch_tut_checks(main)

## Bugs the 30-day soak (tools/soak.gd) found. Keep them fixed.
func _soak_regressions(main: Node) -> void:
	main.day_count = 9
	main.day_i = 12
	main.money = 0
	main.daily = Daily.new_state()
	var farm_seed: = -1
	for sd in 2000:
		if Daily.roll(9, 5, [], 0, sd) == "farmers_market":
			farm_seed = sd
			break
	main.wordle_seed = farm_seed
	main.daily_new_day()
	check("farmers market on $0 doesn't go negative (got $%d)" % main.money, main.today_event() == "farmers_market" and main.money == 0)
	main.dialog.clear()
	main.location = "outside"
	main.in_title = false
	main.close_overlay()
	main.energy = 3.0
	main.player.hurt_t = 0.0
	main.player.roll_t = 0.0
	main.player.frozen = false
	var hit: bool = main.hurt_player(50.0, main.player.position + Vector2(10, 0), 0.0, "")
	check("a big hit floors energy at 0, never negative (got %.1f)" % main.energy, hit and main.energy == 0.0)
	main.energy = 100.0

## Gala opens on story day 24 (main.GALA_DAY), not at the $100k fund (Duff, Nov 9).
func _gala_gate_checks(main: Node) -> void:
	main.no_loading = true
	main.close_overlay()
	main.dialog.clear()
	main.gala_unlocked = false
	main.threads["gala"] = []
	main.daily = Daily.new_state()
	main.day_count = 9
	main.day_i = 12
	main.college["cash"] = 200000.0
	main.check_fund_goal()
	check("gala: a full fund no longer opens the gala", not main.gala_unlocked and main.achievements.has("Fully Funded"))
	main.college["cash"] = 0.0
	check("gala: GALA_DAY is 24", int(main.GALA_DAY) == 24)
	main.day_count = 22
	main.day_i = 25
	main._wake(0)
	main.close_overlay()
	main.dialog.clear()
	check("gala: locked on day 23", main.day_count == 23 and not main.gala_unlocked)
	main._wake(0)
	main.close_overlay()
	main.dialog.clear()
	var mad: Array = main.threads.get("madison", [])
	var invite: = false
	for t in mad:
		if str(t["text"]).contains("gala guest list") and int(t["day"]) == 24:
			invite = true
	check("gala: unlocked on day 24", main.day_count == 24 and main.gala_unlocked)
	check("gala: day-24 morning brings the Committee text + Madison's guest-list text", invite and not (main.threads.get("gala", []) as Array).is_empty() and main.unread["gala"])
	check("gala: day 24 is a calendar headline marked GALA", bool(Daily.entry(24).get("headline", false)) and str(Daily.entry(24).get("tag", "")) == "GALA" and main.today_event() == "")
	var n_gala: = (main.threads["gala"] as Array).size()
	main._wake(0)
	main.close_overlay()
	main.dialog.clear()
	check("gala: invite only sent once (day 25 keeps it open)", main.gala_unlocked and (main.threads["gala"] as Array).size() == n_gala)
	# old save from the fund-gate era that already had the gala keeps it, even before day 24
	var d: Dictionary = main.to_dict()
	d["day_count"] = 6
	d["gala_unlocked"] = true
	main.from_dict(JSON.parse_string(JSON.stringify(d)))
	check("gala: old save with gala_unlocked=true stays unlocked (day 6)", main.gala_unlocked)
	# old save past day 24 that never unlocked it catches up on load
	d["day_count"] = 26
	d["gala_unlocked"] = false
	main.from_dict(JSON.parse_string(JSON.stringify(d)))
	check("gala: old save on day 26 without the gala catches up on load", main.gala_unlocked)
	d["day_count"] = 20
	d["gala_unlocked"] = false
	main.from_dict(JSON.parse_string(JSON.stringify(d)))
	check("gala: save on day 20 stays locked", not main.gala_unlocked)
	SaveGame.erase(main.save_path)

## Nov 10 review fixes: gentler first week, gala after the ending, phone wording.
func _review_fix_checks(main: Node) -> void:
	main.no_loading = true
	main.close_overlay()
	main.dialog.clear()
	main.weeks_paid = 0
	main.late_notices = 0
	main.rent_debt = 0
	main.day_count = 1
	var full: int = main.weekly_base()
	check("first week: rent is prorated to half", main.first_week_prorate() and main.rent_due() == int(ceil(full / 2.0)))
	main.money = 1000
	main.pay_rent()
	check("first week: paying takes only the prorated amount", main.money == 1000 - int(ceil(full / 2.0)) and main.weeks_paid == 1)
	check("second week: full rent again", not main.first_week_prorate() and main.rent_due() == full)
	main.weeks_paid = 0
	main.day_count = 8
	check("prorate never applies after the first week", not main.first_week_prorate())
	main.day_count = 2
	check("first weekend: the Fork is open on day 2", main.first_weekend())
	main.day_count = 4
	check("later weekends: the Fork is closed again", not main.first_weekend())
	# the gala follows the story ending (day 12), not only GALA_DAY
	main.gala_unlocked = false
	main.threads["gala"] = []
	main.daily = Daily.new_state()
	main.story["ending_seen"] = false
	main.day_count = 12
	check("gala: not due on day 12 before the ending", not main.gala_due())
	main.story["ending_seen"] = true
	check("gala: due the moment the ending has played", main.gala_due())
	main.day_count = 12
	main.day_i = 15
	main._wake(0)
	main.close_overlay()
	main.dialog.clear()
	check("gala: the morning after the ending (day 13) brings the invite", main.day_count == 13 and main.gala_unlocked and not (main.threads.get("gala", []) as Array).is_empty())
	main.story["ending_seen"] = false
	main.gala_unlocked = false
	# phone wording: keyboard hints are rewritten only while touch controls are up
	Cast.touch = true
	var phone: = Cast.T("PULL (Space)")
	Cast.touch = false
	check("touch: keyboard hints become tap words", phone == "PULL IT" and Cast.T("PULL (Space)") == "PULL (Space)")

## Every quoted string in scripts/ and data/ (cast files aside) that says "Fork" outside a {token}. The menu id
## "Club Fork" is shown through {club_sandwich}, and old achievement names are only looked up to migrate them.
func _bare_fork_lines() -> Array:
	var rx: = RegEx.new()
	rx.compile("\"(?:[^\"\\\\]|\\\\.)*\"")
	var word: = RegEx.new()
	word.compile("\\bFork\\b")
	var out: = []
	var files: = []
	for dir in ["res://scripts", "res://scripts/minigames", "res://scripts/iso", "res://data"]:
		for f in DirAccess.get_files_at(dir):
			if (f.ends_with(".gd") or f.ends_with(".json")) and not f.begins_with("cast"):
				files.append(dir + "/" + f)
	for path in files:
		var lines: = FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var line: String = lines[i]
			if line.strip_edges().begins_with("#") or "achievements.find(" in line:   # comments, old-save migration ids
				continue
			for m in rx.search_all(line):
				var q: String = m.get_string().replace("Club Fork", "")
				if word.search(q):
					out.append("%s:%d" % [path.get_file(), i + 1])
	return out


## Editions (docs/legal/RISK_AUDIT.md): the public build (default, no feature tag) renames real brands and the
## real-ex final boss and swaps in *_pub art; the family build ("family" tag) keeps every original.
func _edition_checks() -> void:
	var C: = preload("res://scripts/cast.gd")
	var A: = preload("res://scripts/art.gd")
	var was: bool = C.family
	C.set_family(false)
	var shown: = " ".join(PackedStringArray(C.names().values().map(func(v): return str(v))))
	var leaked: = []
	for w in ["Twisted", "Wordle", "Willnot", "Gucchi", "aisle-ish", "Nakatomeh", "Brittany"]:
		if w in shown:
			leaked.append(w)
	check("public edition: no real brand / real-ex names in cast (%s)" % ", ".join(leaked), leaked.is_empty())
	check("public edition: the house sandwich is renamed with the restaurant", C.T("{HOUSE_SANDWICH}") == "SPATULA CLASSIC")
	check("public edition: {FORK} and {wordle} tokens renamed", C.T("{FORK} / {wordle} / {coworker}") == "THE BUSTED SPATULA / Word Brawl / Mazikeen")
	check("public edition: the Fork nickname and club sandwich follow the rename", C.T("{fork_nick} / {club_sandwich}") == "Spatula / Club Spatula")
	var bare: = _bare_fork_lines()
	check("public edition: no bare 'Fork' left in player-facing strings (%s)" % ", ".join(bare), bare.is_empty())
	var pubs: = ["sf_fork.png", "sf_walgrumps.png", "ch_willnot.png", "portraits_hd/willnot.png", "boss_intro/willnot.png",
		"ko/willnot_a.jpg", "ko/willnot_b.jpg", "ko/willnot_c.jpg"]
	var bad: = []
	for f in pubs:
		var p: String = "res://assets/art/" + f
		var q: = A.pub(p)
		if q == p or (load(q) as Texture2D).get_size() != (load(p) as Texture2D).get_size():
			bad.append(f)
	check("public edition: *_pub art exists at the original size (%s)" % ", ".join(bad), bad.is_empty())
	C.set_family(true)
	check("family edition: real names kept", C.T("{fork} {wordle} {ex_final} {coworker}") == "The Twisted Fork Wordle Bruce Willnot Brittany")
	check("family edition: the Fork nickname kept", C.T("{fork_nick} / {club_sandwich}") == "Fork / Club Fork")
	check("family edition: original art kept", A.pub("res://assets/art/sf_fork.png") == "res://assets/art/sf_fork.png")
	C.set_family(was)

func _falcor_checks(main: Node) -> void:
	main.no_loading = true
	main.daily = Daily.new_state()
	main.day_count = 9
	main.day_i = 12
	var h0: float = main.happiness
	main._wake(0)
	check("day 10 wakes into the Falcor card", main.day_count == 10 and main.overlay_node != null and str(main.overlay_node.get("heading")) == "SUNDAY")
	check("no random event on Falcor's day", main.today_event() == "")
	main.overlay_node.chosen.emit("stay")
	check("Stay with her: choice saved", str(main.daily["falcor"]) == "stay")
	check("Stay with her: +Happiness", main.happiness > h0 or main.happiness >= 100.0)
	check("Falcor card closed", main.overlay_node == null)
	main.dialog.clear()
	main._wake(0)
	check("day 11: grief line in the morning", main.falcor_grief())
	var thread: Array = main.threads.get("madison", [])
	check("day 11: Madison's text about the bowl", not thread.is_empty() and str(thread[-1]["text"]).contains("bowl"))
	check("no fussy rolls while she's grieving", str(main.mood["kind"]) != "fussy")
	main.dialog.clear()
	main.day_count = 27
	main.day_i = 30
	main._wake(0)
	check("day 28 is Thanksgiving", main.calendar_event() == "thanksgiving")
	main.dialog.clear()
	main.clock = 600.0
	main.location = "outside"
	main.try_shift()
	check("Fork closed on Thanksgiving", not main.in_shift)

const Knockout: = preload("res://scripts/knockout.gd")
const Combat: = preload("res://scripts/combat.gd")
const UiStyle: = preload("res://scripts/ui_style.gd")
const Cast: = preload("res://scripts/cast.gd")

## Searing Spatter was cut (Nov 13). Old saves stored the special as an index with Spatter first.
func _spatter_cut_checks() -> void:
	var c: Node = Combat.new()
	c.from_dict({})
	check("no special at Lv 1", c.current().is_empty())
	c.from_dict({"level": 5, "selected": 2})          # old list: spatter, pinwheel, julienne, ...
	check("old save index 2 still means Julienne", str(c.current().get("id", "")) == "julienne")
	c.from_dict({"level": 5, "selected": 0})          # had Spatter picked
	check("old Spatter pick falls back to Pinwheel", str(c.current().get("id", "")) == "pinwheel")
	c.from_dict({"level": 3, "selected": 1, "extra_unlocks": ["hashbrown"]})   # old: spatter, pinwheel, julienne, hashbrown
	check("old save index 1 still means Pinwheel", str(c.current().get("id", "")) == "pinwheel")
	c.from_dict({"level": 3, "selected": 3, "extra_unlocks": ["hashbrown"]})
	check("old save index 3 still means Hash Brown", str(c.current().get("id", "")) == "hashbrown")
	var d: Dictionary = c.to_dict()
	c.from_dict(JSON.parse_string(JSON.stringify(d)))
	check("special pick survives save/load by id", str(c.current().get("id", "")) == "hashbrown")
	c.free()

func _ko_sfx_checks() -> void:
	var missing: = []
	var want: = []
	for b in Knockout.BEATS:
		for c in Knockout.SFX_CUES.get(b, []):
			want.append(c[1])
			if not ResourceLoader.exists(Knockout.SFX_DIR + str(c[1]) + ".ogg"):
				missing.append(c[1])
	check("knockout sfx files all import (%s)" % ", ".join(missing), missing.is_empty())
	var ko: Node2D = Knockout.new()
	root.add_child(ko)
	ko.start("gymbro")
	var steps: = 0
	while ko.playing() and steps < 2000:
		ko._process(0.05)
		steps += 1
	check("knockout plays every cue once, in beat order", ko.played == want)
	ko.start("gymbro")                       # tap through fast: the opening cue of each beat still fires
	for i in 3:
		ko._process(0.05)
		ko._next()
	check("tapping through: xray crack fires, later cues skipped", ko.played.has("crack") and not ko.played.has("snap2"))
	ko.queue_free()

const AudioScript: = preload("res://scripts/audio.gd")
const Gore: = preload("res://scripts/ko_gore.gd")

func _gore_nodes(ko: Node) -> int:
	var n: = 0
	for c in ko.get_children():
		if c.get_script() == Gore:
			n += 1
	return n

func _ko_gore_checks() -> void:
	# setting: default ON, saves and loads (throwaway settings file, never the real one)
	var path: = "user://test_daily_settings.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var a: Node = AudioScript.new()
	a.settings_path = path
	a.load_settings()
	check("cartoon gore defaults ON", a.gore == true)
	a.set_gore(false)
	var b: Node = AudioScript.new()
	b.settings_path = path
	b.load_settings()
	check("cartoon gore OFF survives save/load", b.gore == false and not bool(b.to_dict().get("gore", true)))
	# gore hits land on KO sound cues
	var ok_t: = true
	for beat in Gore.HITS:
		var cue_t: = []
		for c in Knockout.SFX_CUES.get(beat, []):
			cue_t.append(snappedf(float(c[0]), 0.01))
		for h in Gore.HITS[beat]:
			ok_t = ok_t and cue_t.has(snappedf(float(h[0]), 0.01))
	check("gore hits fire on KO sfx cue times", ok_t)
	# ON: a gore node with blood in the air on the x-ray hit; same seed = same particles
	var keep: Node = AudioScript.inst
	b.gore = true
	AudioScript.inst = b
	var ko: Node2D = Knockout.new()
	root.add_child(ko)
	ko.fixed_seed = 77
	ko.start("ghoster")
	ko._next(); ko._next()                  # -> xray
	ko._process(0.3)
	var g: Node = ko.gore
	check("gore ON: one gore node", _gore_nodes(ko) == 1 and g != null)
	var kinds: = {}
	if g:
		for q in g.alive():
			kinds[q["k"]] = true
	check("gore ON: blood, spit and a tooth in the air on the x-ray", kinds.has("drop") and kinds.has("tooth"))
	var first: Array = g.parts.duplicate(true) if g else []
	ko.start("ghoster")
	ko._next(); ko._next()
	ko._process(0.3)
	check("gore is repeatable with a fixed seed", ko.gore != null and str(ko.gore.parts) == str(first))
	while ko.playing():
		ko._next()
	check("gore node removed when the cutscene ends", ko.gore == null)
	# OFF: no gore node at all, on any beat
	b.gore = false
	ko.start("ghoster")
	var none: = true
	for i in 4:
		ko._process(0.3)
		none = none and _gore_nodes(ko) == 0 and ko.gore == null
		ko._next()
	check("gore OFF: no gore nodes", none)
	AudioScript.inst = keep
	ko.queue_free()
	a.free()
	b.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _button_fit_checks() -> void:
	# stat points card: 2 columns of 308/2 - 4 wide, 21 tall (card.gd), label size 8
	var w: = 308.0 / 2.0 - 4.0 - UiStyle.BUTTON_PAD
	var bad: = []
	var labels: = ["Later (press T anytime)"]
	for k in ["str", "def", "heat", "grit"]:
		labels.append("%s: %s" % [Combat.STATS[k]["name"], Combat.STATS[k]["desc"]])
	for l in labels:
		var f: Array = UiStyle.fit_text(Cast.N(l), w, 20.0, 8)
		var lines: PackedStringArray = f[0]
		var widest: = 0.0
		for ln in lines:
			widest = maxf(widest, UiStyle.display.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, int(f[1])).x)
		if widest > w or lines.size() * int(f[1]) * UiStyle.LINE_H > 21.0 or " ".join(lines).contains("..."):
			bad.append(l)
	check("stat point buttons fit their boxes (%s)" % ", ".join(bad), bad.is_empty())
	var long: Array = UiStyle.fit_text("a b c d e f g h i j k l m n o p q r s t u v w x y z " .repeat(4), 60.0, 12.0, 8)
	check("fit_text cuts what can't fit with ...", (long[0] as PackedStringArray).size() == 1 and str(long[0][0]).ends_with("..."))

const AudioS: = preload("res://scripts/audio.gd")
const JuiceS: = preload("res://scripts/juice.gd")
const GroceryS: = preload("res://scripts/minigames/grocery.gd")

func _qa_leftover_checks() -> void:
	# screen shake setting: default ON, saved as `screen_shake`, and OFF really stops the shake.
	# Throwaway settings file, never user://settings.json.
	var path: = "user://test_settings_shake.json"
	var a: Node = AudioS.new()
	a.settings_path = path
	SaveGame.erase(path)
	a.load_settings()
	check("screen shake defaults ON", JuiceS.shake_on)
	a.set_screen_shake(false)
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check("screen_shake saved in settings", saved is Dictionary and saved.get("screen_shake") == false)
	JuiceS.shake_on = true
	a.load_settings()
	check("screen shake OFF survives reload", not JuiceS.shake_on)
	var j: Node = JuiceS.new()
	j.shake(3.0)
	check("shake OFF: no trauma", j._trauma == 0.0)
	JuiceS.shake_on = true
	j.shake(3.0)
	check("shake ON: trauma", j._trauma > 0.0)
	j.free()
	a.free()
	SaveGame.erase(path)
	# grocery aisle tags sit in the lane's empty left end: no item marker/icon, no shelf under them
	var g: Node2D = GroceryS.new()
	g.font = ThemeDB.fallback_font
	var bad: = []
	for i in GroceryS.SHELVES.size():
		var r: Rect2 = g.aisle_tag_rect(i)
		if r.intersects(GroceryS.SHELVES[i]):
			bad.append("aisle %d on shelf" % (i + 1))
		for id in GroceryS.SPOTS:
			var sp: Vector2 = GroceryS.SPOTS[id]
			if r.intersects(Rect2(sp + Vector2(-13, -13), Vector2(30, 20))):
				bad.append("aisle %d over %s" % [i + 1, id])
	check("grocery aisle tags clear of shelves + items (%s)" % ", ".join(bad), bad.is_empty())
	g.free()
	# every outdoor door point sits on paving in data/town_ground.txt (nearest dual-grid corner = 's')
	var MainS: GDScript = load("res://scripts/main.gd")
	var C: Dictionary = MainS.get_script_constant_map()
	var doors: = {"home": C["HOME_DOOR"], "kwik": C["SHOP_PT"], "fork": C["FORK_DOOR"], "pharmacy": C["PHARM_DOOR"],
		"grocery": C["GROC_DOOR"], "plasma": C["PLASMA_DOOR"]}
	for e in C["STORY"]:
		var r: Rect2 = e["r"]
		doors[str(e["id"])] = Vector2(r.get_center().x, r.end.y + 6.0)
	var grid: Array = []
	var origin: = Vector2.ZERO
	var tile: = 64.0
	for line in FileAccess.get_file_as_string("res://data/town_ground.txt").split("\n"):
		var l: = line.strip_edges()
		if l == "" or l.begins_with("#"):
			continue
		if l.begins_with("tile "):
			tile = float(l.split(" ")[1])
		elif l.begins_with("origin "):
			origin = Vector2(float(l.split(" ")[1]), float(l.split(" ")[2]))
		else:
			grid.append(l)
	var off: = []
	for k in doors:
		var w: Vector2 = doors[k]
		var c: = ((w * 2.0 - origin) / tile).round()   # world -> art px (x2) -> corner index
		var row: String = grid[clampi(int(c.y), 0, grid.size() - 1)]
		if row[clampi(int(c.x), 0, row.length() - 1)] != "s":
			off.append(k)
	check("door points on a footpath (%s)" % ", ".join(off), off.is_empty())
	# ambient enemy barks: a second enemy close by keeps quiet while the first is talking
	var EnemyS: = load("res://scripts/enemy.gd")
	var e1: Node2D = EnemyS.new()
	var e2: Node2D = EnemyS.new()
	e1.add_to_group("enemy"); e2.add_to_group("enemy")
	root.add_child(e1); root.add_child(e2)
	e1.set_physics_process(false); e2.set_physics_process(false)
	e1.global_position = Vector2(100, 100); e2.global_position = Vector2(130, 100)
	e1.line_t = 0.0; e2.line_t = 0.0
	check("bark: nobody talking -> free to bark", not e2.bark_crowded())
	e1.say("hey")
	check("bark: neighbour talking -> wait", e2.bark_crowded())
	e2.global_position = Vector2(400, 100)
	check("bark: far away -> free to bark", not e2.bark_crowded())
	e1.free(); e2.free()

class FakeMain extends Node:
	var station_best: Dictionary = {}

## IGN review: the nightly routine gets a skip after night one (autopilot, smaller payoff).
func _bedtime_skip_checks(main: Node) -> void:
	main.no_loading = true
	main.close_overlay()
	main.dialog.clear()
	main.couch_night = false
	main.mood = main.Moods.new_mood()
	main.cats_fed_day = main.day_count
	main.routine_played = false
	main.go_to_sleep(false)
	check("bedtime: first night goes straight to Show & Tell (no skip card)", main.overlay_node != null and main.overlay_node.get_script() == main.ShowTellScript)
	main.close_overlay()
	main.routine_played = true
	main.inventory["formula"] = 2
	main.inventory["diapers"] = 0
	main.happiness = 50.0
	var d0: int = main.day_count
	main._skip_night_routine()
	main.close_overlay()
	main.dialog.clear()
	var rep: = "\n".join(main.night_report)
	check("bedtime skip: day advances, +8 Show & Tell, dish towel when out of diapers, 1 bottle used",
		main.day_count == d0 + 1 and rep.contains("+8 Happiness") and rep.contains("Dish towel") and int(main.inventory["formula"]) == 1)
	var dd: Dictionary = main.to_dict()
	check("bedtime: routine_played survives a save", bool(dd.get("routine_played", false)))

## Duff, Nov 10: softer gates + waiting drain.
func _balance_checks(main: Node) -> void:
	var gates: Array = main.STORY.map(func (n): return float(n["happy"]))
	check("balance: story gates are 45/50/55/60/65 (got %s)" % str(gates), gates == [45.0, 50.0, 55.0, 60.0, 65.0])
	main.day_count = 3
	check("balance: week-one waiting drain is half the later one", is_equal_approx(main.wait_drain(), main.WAIT_DRAIN_WEEK1) and main.WAIT_DRAIN_WEEK1 * 2.0 == main.WAIT_DRAIN)
	main.day_count = 10
	check("balance: later drain <= 0.1/s and the floor is 40", main.wait_drain() <= 0.1 and main.WAIT_FLOOR == 40.0)

## IGN review v2: phone onboarding (three control cards, once per install, phones only).
func _touch_tut_checks(main: Node) -> void:
	var Cast: = preload("res://scripts/cast.gd")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://touch_tut.cfg"))
	var was: bool = Cast.touch
	Cast.touch = false
	main.maybe_touch_tutorial()
	check("touch tut: never on keyboard", not main.tut.active())
	Cast.touch = true
	main.maybe_touch_tutorial()
	check("touch tut: starts on a phone's first game and blocks the world", main.tut.active() and main.busy())
	main.tut.next(); main.tut.next()
	check("touch tut: still on card 3 of 3", main.tut.active() and main.tut.card == 2)
	main.tut.next()
	check("touch tut: done after 3 cards, remembered", not main.tut.active() and not main.busy() and main.TouchTutScript.seen())
	main.maybe_touch_tutorial()
	check("touch tut: not shown twice", not main.tut.active())
	var T: = preload("res://scripts/touch_controls.gd")
	check("touch buttons: G, S, swap, D all >= A", T.BTN_G_R >= T.BTN_R and T.BTN_S_R >= T.BTN_R and T.BTN_SW_R >= T.BTN_R and T.BTN_D_R >= T.BTN_R)
	Cast.touch = was


## Bounty signature moves (Nov 10, IGN v2 "six bounties, three original movesets"): each is wired into its boss,
## and each does its one job through the real projectile code.
func _signature_move_checks(main: Node) -> void:
	var B: = preload("res://scripts/boss.gd")
	for pair in [["coupon", "storm"], ["camper", "lasso"], ["allergy", "gluten"]]:
		check("signature: %s throws %s" % pair, (B.BOSSES[pair[0]]["attacks"] as Array).has(pair[1]) and B.TELE.has(pair[1]))
	main.start_bounty("camper")
	main.dialog.clear()
	var boss: Node2D = main.arena_boss
	var pl: CharacterBody2D = main.player
	boss.position = main.ARENA_ORIGIN + Vector2(160, 60)
	pl.position = main.ARENA_ORIGIN + Vector2(160, 140)
	var reset: = func() -> void:
		pl.frozen = false; pl.hurt_t = 0.0; pl.roll_t = 0.0; pl.stun_t = 0.0; pl.knock = Vector2.ZERO; main.energy = 100.0
	reset.call()
	var cord: Node2D = boss._proj("cord", pl.global_position, Vector2.ZERO, 6.0)
	cord._special(0.016)
	check("lasso: yanks Duff TOWARD the Camper", pl.knock.dot(boss.global_position - pl.global_position) > 0.0)
	check("lasso: tangles him", pl.stun_t > 0.0)
	reset.call()
	pl.roll_t = 0.3
	var cord2: Node2D = boss._proj("cord", pl.global_position, Vector2.ZERO, 6.0)
	cord2._special(0.016)
	check("lasso: a roll slips it", pl.stun_t == 0.0 and pl.knock == Vector2.ZERO)
	reset.call()
	var ring: Node2D = boss._proj("gluten", boss.global_position, Vector2.ZERO, 4.0)
	ring.radius = boss.global_position.distance_to(pl.global_position) - 1.0
	ring._special(0.02)
	check("gluten: the shout ring stuns", pl.stun_t > 0.0)
	reset.call()
	var cp: Node2D = boss._proj("coupon", pl.global_position, Vector2.ZERO, 6.0)
	cp.fuse = 0.5
	cp._special(0.02)
	check("storm: no hit while the coupon is still falling", main.energy == 100.0)
	cp._special(0.5)
	check("storm: a landed coupon hurts", main.energy < 100.0)
	for n in [cord, cord2, ring, cp]:
		if is_instance_valid(n):
			n.queue_free()


## Duff's "Heard." lives in the kitchens only (Duff, Nov 10): Waffle Haus, the Fork's shift flow and Fork stations.
## Plain verb uses ("never heard of it") are fine; this catches the callout: Heard. / Heard, / HEARD!
const HEARD_OK: = ["res://scripts/waffle.gd", "res://scripts/shift.gd", "res://scripts/minigames/sandwich.gd"]

func _heard_checks() -> void:
	var rx: = RegEx.create_from_string("\\b(Heard|HEARD)[.,!]")
	var bad: Array = []
	for root in ["res://scripts", "res://data"]:
		_heard_scan(root, rx, bad)
	check("'Heard.' only in the kitchens (%s)" % ", ".join(bad), bad.is_empty())

func _heard_scan(dir: String, rx: RegEx, bad: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		var p: = dir.path_join(f)
		if (f.ends_with(".gd") or f.ends_with(".json")) and not HEARD_OK.has(p):
			if rx.search(FileAccess.get_file_as_string(p)) != null:
				bad.append(p.get_file())
	for d in DirAccess.get_directories_at(dir):
		_heard_scan(dir.path_join(d), rx, bad)


## Boss taunts (IGN v2: "lean on one joke formula"): at most 2 use the "I'm not X. I'm Y." reframe across every
## boss, and no two bosses open on the same first three words.
func _taunt_variety_checks() -> void:
	var B: = preload("res://scripts/boss.gd")
	var rx: = RegEx.create_from_string("(?i)\\b(I'm|You're|It's|I am|You are) not\\b")
	var formula: = 0
	var openers: = {}
	var dupes: Array = []
	for id in B.BOSSES:
		for line in B.BOSSES[id].get("taunts", []):
			if rx.search(str(line)) != null:
				formula += 1
			var words: = str(line).to_lower().split(" ")
			var head: = " ".join(words.slice(0, 3))
			if openers.has(head) and openers[head] != id:
				dupes.append(head)
			openers[head] = id
	check("taunts: 'I'm not X, I'm Y' used at most twice (%d)" % formula, formula <= 2)
	check("taunts: no shared openers across bosses (%s)" % ", ".join(dupes), dupes.is_empty())


## Side quests (Nov 12): save-safe state, v7 -> v8 migrate, journal, markers, typewriter dialogue, dev warp.
func _side_quest_checks(main: Node) -> void:
	var SQ: = preload("res://scripts/side_quests.gd")
	var st: Dictionary = SQ.new_state()
	check("sq: every quest has an id, title, giver and stages", SQ.LIST.all(func (e): return str(e.get("id", "")) != "" and str(e.get("title", "")) != "" and str(e.get("giver", "")) != "" and (e.get("stages", []) as Array).size() > 0))
	check("sq: unknown quest can't start", not SQ.start(st, "nope") and st.is_empty())
	check("sq: start -> active stage 1, NEW", SQ.start(st, "porch") and SQ.stage(st, "porch") == 1 and SQ.is_active(st, "porch") and SQ.unread(st, true) == 1)
	check("sq: can't start twice", not SQ.start(st, "porch"))
	check("sq: clue added once", SQ.add_clue(st, "porch", "crumbs") and not SQ.add_clue(st, "porch", "crumbs") and SQ.has_clue(st, "porch", "crumbs"))
	SQ.advance(st, "porch")
	check("sq: advance -> stage 2", SQ.stage(st, "porch") == 2)
	for i in 5:
		SQ.advance(st, "porch")
	check("sq: advancing past the end finishes", SQ.is_done(st, "porch") and SQ.stage(st, "porch") == SQ.stage_count("porch"))
	check("sq: bad branch choice refused", not SQ.set_choice(st, "gig", "explode"))
	SQ.start(st, "gig")
	SQ.finish(st, "gig", "rat")
	check("sq: branch choice kept", SQ.choice(st, "gig") == "rat" and SQ.is_done(st, "gig"))
	var dirty: = {"porch": {"stage": 99, "status": "active", "clues": ["a", "a", 3], "choice": "x"}, "ghost": {"stage": 1}, "gig": "junk",
		"grease": {"status": "lol", "stage": 2}, "alley": {"status": "active", "stage": 0}}
	var c: = SQ.clean(dirty)
	check("sq: clean drops unknown ids and junk", not c.has("ghost") and not c.has("gig"))
	check("sq: clean clamps stage, dedupes clues, drops bad choice", int(c["porch"]["stage"]) == SQ.stage_count("porch") and c["porch"]["clues"] == ["a", "3"] and str(c["porch"]["choice"]) == "")
	check("sq: clean resets bad status, fixes active stage 0", str(c["grease"]["status"]) == "" and int(c["grease"]["stage"]) == 0 and int(c["alley"]["stage"]) == 1)
	check("sq: clean survives non-dicts", SQ.clean(null).is_empty() and SQ.clean([1, 2]).is_empty())
	# markers + journal: hidden until a quest is "ready"
	var fresh: = SQ.new_state()
	check("sq: no '!' before a quest's first day, no journal rows for unstarted quests", SQ.marker_for(fresh, "mail", false, 2) == "" and SQ.marker_for(fresh, "mail", false, 3) == "!" and SQ.journal(fresh).is_empty())
	check("sq: every quest is live", SQ.ids().all(func (i): return SQ.visible(str(i), false)))
	check("sq: porch is live: '!' over Madison from day 2, not day 1", SQ.marker_for(fresh, "madison") == "!" and SQ.marker_for(fresh, "madison", false, 1) == "" and SQ.offerable(fresh, "porch", 2) and not SQ.offerable(fresh, "porch", 1))
	check("sq: dev sees the '!' over the porch giver", SQ.marker_for(fresh, "madison", true) == "!")
	SQ.start(fresh, "porch")
	check("sq: stage 1 wants Brittany -> '?' over her", SQ.marker_for(fresh, "brittany", true) == "?")
	check("sq: journal lists the active quest with its step", SQ.journal(fresh, true).size() == 1 and str(SQ.journal(fresh, true)[0]["step"]).length() > 0)
	SQ.mark_read(fresh)
	check("sq: mark_read clears NEW", SQ.unread(fresh, true) == 0)
	SQ.warp(fresh, "porch", 0)
	check("sq: warp 0 resets", SQ.status(fresh, "porch") == "")
	SQ.warp(fresh, "gig", 99)
	check("sq: warp past the end = done", SQ.is_done(fresh, "gig"))
	# save: an old v7 save loads with empty side quests; state round-trips
	var old: = SaveGame.migrate({"version": 7, "money": 12})
	check("save v8: v7 save gains empty side_quests", int(old["version"]) == SaveGame.VERSION and SaveGame.VERSION >= 8 and old.has("side_quests") and (old["side_quests"] as Dictionary).is_empty())
	main.from_dict({"version": 7})
	check("save v8: from_dict without side_quests is safe", main.side_quests.is_empty())
	SQ.start(main.side_quests, "alley")
	SQ.add_clue(main.side_quests, "alley", "bike")
	var dd: Dictionary = JSON.parse_string(JSON.stringify(main.to_dict()))
	main.side_quests = {}
	main.from_dict(dd)
	check("save v8: side quest + clue survive save/load", SQ.is_active(main.side_quests, "alley") and SQ.has_clue(main.side_quests, "alley", "bike"))
	main.side_quests = {}
	# typewriter: the first tap finishes the line, the second moves on
	main.dialog.clear()
	main.dialog.append_array(["One two three four five six seven eight nine ten.", "Second."])
	main._tick_dialog(0.05)
	check("typewriter: a line starts partly hidden", main.dlg_chars < main.dialog_len())
	main.advance_dialog()
	check("typewriter: first tap reveals the whole line", main.dialog.size() == 2 and main.dlg_chars >= main.dialog_len())
	main.advance_dialog()
	check("typewriter: second tap moves on", main.dialog.size() == 1)
	main._tick_dialog(0.0)
	check("typewriter: next line restarts the reveal", main.dlg_chars < main.dialog_len())
	main.dialog.clear()
	var H: = preload("res://scripts/hud.gd")
	var f: Font = ThemeDB.fallback_font
	var line: = "Keep Madison happy. Pay the rent. Guard the porch. That's the whole religion."
	var wr: String = H.wrap_words(f, line, 120.0, 7)
	check("typewriter: pre-wrap keeps length, adds breaks", wr.length() == line.length() and wr.count("\n") >= 1)
	var fits: = true
	for row in wr.split("\n"):
		fits = fits and f.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x <= 120.0
	check("typewriter: every wrapped row fits", fits)
	# dev warp: jumps the quest and walks Duff to whoever the stage needs
	main.dev_warp_quest("porch", 1)
	check("dev warp: porch stage 1 -> outside by Brittany", SQ.stage(main.side_quests, "porch") == 1 and main.location == "outside" and main.player.position.distance_to(main.BRITT_POS) < 60.0)
	main.dev_warp_quest("porch", 0)
	check("dev warp: reset sends Duff to the giver (home)", SQ.status(main.side_quests, "porch") == "" and main.location == "home")
	main.dev_warp_quest("porch", 9)
	check("dev warp: past the end = done", SQ.is_done(main.side_quests, "porch"))
	main.side_quests = {}
	# the porch mystery, end to end through the real hooks
	main.dialog.clear()
	main.show_hidden_quests = false
	var dc0: int = main.day_count
	var ck0: float = main.clock
	main.day_count = 3
	main.clock = 600.0
	check("porch: Madison hands it out", main.quest_talk("madison") and SQ.stage(main.side_quests, "porch") == 1)
	check("porch: Madison doesn't repeat herself", not main.quest_talk("madison"))
	check("porch: Brittany gives the first clue", main.quest_talk("brittany") and SQ.has_clue(main.side_quests, "porch", "orange fingers") and SQ.stage(main.side_quests, "porch") == 2)
	check("porch: porch clue spot appears", main.quest_interactables().any(func (it): return it["id"] == "quest_porch"))
	check("porch: porch gives the receipt", main.quest_talk("porch") and SQ.stage(main.side_quests, "porch") == 3)
	check("porch: neighbor door appears, porch spot gone", main.quest_interactables().size() == 1 and main.quest_interactables()[0]["id"] == "quest_neighbor")
	if main.location != "outside":
		main.leave_home()
	main.quest_talk("neighbor")
	var chad: Node = null
	for e in main.get_tree().get_nodes_in_group("enemy"):
		if e.has_meta("quest_porch"):
			chad = e
	check("porch: knocking flushes out the suspect", chad != null and chad.display_name() == "Cheeto Chad")
	main.quest_talk("neighbor")
	check("porch: knocking again doesn't clone him", main.get_tree().get_nodes_in_group("enemy").filter(func (e): return e.has_meta("quest_porch")).size() == 1)
	var cash0: int = main.money
	if chad:
		main.enemy_defeated(chad)
	check("porch: catching him finishes the quest and pays", SQ.is_done(main.side_quests, "porch") and main.money >= cash0 + 60 and main.achievements.has("Neighborhood Watch"))
	check("porch: done quest leaves no interactables", main.quest_interactables().is_empty())
	# the Grease Trap, end to end: 86 List entry -> night -> alley fight -> paid, achievement, bounty day untouched
	main.side_quests = {}
	main.dialog.clear()
	main.day_count = 3
	check("grease: not on the 86 List before day 4", not main.quest_talk("bounty_board"))
	main.day_count = 4
	main.clock = 600.0
	check("grease: the 86 List hands it out", main.quest_talk("bounty_board") and SQ.stage(main.side_quests, "grease") == 2)
	main.dialog.clear()
	check("grease: daytime = come back later, no fight", main.quest_talk("bounty_board") and main.location == "outside" and main.arena_boss == null)
	main.dialog.clear()
	main.clock = 1380.0
	main.energy = 100.0
	var bday0 = main.bounties["day"]
	var gcash0: int = main.money
	check("grease: after 10 PM the board starts the fight", main.quest_talk("bounty_board") and main.location == "arena" and main.arena_boss != null and str(main.arena_boss.kind) == "grease")
	if main.arena_boss != null:
		main.boss_defeated(main.arena_boss)
	check("grease: beating it finishes the quest and pays", SQ.is_done(main.side_quests, "grease") and main.money >= gcash0 + 90 and main.achievements.has("Fryer Exorcist") and main.location == "outside")
	check("grease: doesn't burn today's 86 List bounty", main.bounties["day"] == bday0)
	main.dialog.clear()
	check("grease: done = board opens the normal 86 List again", not main.quest_talk("bounty_board"))
	# Brittany's Side Gig, both branches: offer (day 5+, daytime) -> pitch -> pick -> next-day payoff
	for pick in ["cover", "rat"]:
		main.side_quests = {}
		main.dialog.clear()
		main.close_overlay()
		main.day_count = 4
		main.clock = 600.0
		check("gig(%s): not offered before day 5 (bets instead)" % pick, not main.quest_talk("brittany"))
		main.dialog.clear()
		main.close_overlay()
		main.day_count = 5
		main.clock = 1400.0
		check("gig(%s): night = she's gone, quest not started" % pick, main.quest_talk("brittany") and SQ.status(main.side_quests, "gig") == "")
		main.dialog.clear()
		main.clock = 600.0
		check("gig(%s): Brittany offers it" % pick, main.quest_talk("brittany") and SQ.stage(main.side_quests, "gig") == 1)
		main.dialog.clear()
		check("gig(%s): the pitch moves to the choice" % pick, main.quest_talk("brittany") and SQ.stage(main.side_quests, "gig") == 2)
		main.dialog.clear()
		main.gig_choose("nope")
		check("gig(%s): junk choice ignored" % pick, SQ.stage(main.side_quests, "gig") == 2)
		main.gig_choose(pick)
		check("gig(%s): choice stored, stage 3" % pick, SQ.choice(main.side_quests, "gig") == pick and SQ.stage(main.side_quests, "gig") == 3)
		main.dialog.clear()
		check("gig(%s): same day = not yet" % pick, main.quest_talk("brittany") and SQ.is_active(main.side_quests, "gig"))
		main.dialog.clear()
		main.day_count = 6
		var gm0: int = main.money
		check("gig(%s): next day pays off and finishes" % pick, main.quest_talk("brittany") and SQ.is_done(main.side_quests, "gig") and SQ.choice(main.side_quests, "gig") == pick and main.money == gm0 + (60 if pick == "cover" else 40))
		check("gig(%s): its achievement" % pick, main.achievements.has("Ranch Cartel" if pick == "cover" else "Narc of the {fork_nick}"))
		main.dialog.clear()
		check("gig(%s): done = Brittany is back to bets" % pick, not main.quest_talk("brittany"))
		main.dialog.clear()
		main.close_overlay()
	# Lost & Found: flyer in the mail (day 3+) -> three finds outside, any order -> paper box pays out
	main.side_quests = {}
	main.dialog.clear()
	main.close_overlay()
	main.day_count = 2
	main.bills.clear()
	check("alley: no flyer before day 3 (mail is just mail)", not main.quest_talk("mail"))
	main.dialog.clear()
	main.day_count = 3
	check("alley: the flyer comes with the mail", main.quest_talk("mail") and SQ.stage(main.side_quests, "alley") == 1)
	main.dialog.clear()
	check("alley: mail is mail again while hunting", not main.quest_talk("mail"))
	var ids0: Array = main.quest_interactables().map(func (it): return str(it["id"]))
	check("alley: three things to find outside", ids0.has("quest_ring") and ids0.has("quest_collar") and ids0.has("quest_shoe") and not ids0.has("quest_lostbox"))
	check("alley: the box does nothing yet", not main.quest_talk("lostbox"))
	check("alley: a find is a clue", main.quest_talk("shoe") and SQ.has_clue(main.side_quests, "alley", "shoe") and SQ.stage(main.side_quests, "alley") == 1)
	main.dialog.clear()
	check("alley: the same thing can't be found twice", not main.quest_talk("shoe"))
	check("alley: found things leave the street", not main.quest_interactables().any(func (it): return str(it["id"]) == "quest_shoe"))
	main.quest_talk("ring")
	main.dialog.clear()
	check("alley: third find moves to the return", main.quest_talk("collar") and SQ.stage(main.side_quests, "alley") == 2)
	main.dialog.clear()
	check("alley: '?' over the paper box", SQ.marker_for(main.side_quests, "lostbox") == "?" and main.quest_interactables().any(func (it): return str(it["id"]) == "quest_lostbox"))
	var am0: int = main.money
	check("alley: the box pays and finishes", main.quest_talk("lostbox") and SQ.is_done(main.side_quests, "alley") and main.money == am0 + 50 and main.achievements.has("Omaha's Finest"))
	main.dialog.clear()
	check("alley: done = nothing left on the street, mail is mail", main.quest_interactables().is_empty() and not main.quest_talk("mail"))
	main.dialog.clear()
	main.side_quests = {}
	main.day_count = dc0
	main.clock = ck0
	main.dialog.clear()
	main.show_hidden_quests = false
	main.dialog.clear()

## Madison's mornings (mornings.gd): rolls, the slow-morning chores, the 10 AM self-up text, saves.
func _morning_checks(main: Node) -> void:
	var M: = preload("res://scripts/mornings.gd")
	var counts: = {"slow": 0, "migraine": 0, "good": 0, "": 0}
	var last: = -99
	var back_to_back: = false
	for d in range(2, 702):
		var k: = M.roll(d, 7, true, last)
		counts[k] += 1
		if k != "":
			back_to_back = back_to_back or last == d - 1
			last = d
	check("mornings: about 2 hard + 1 good a week (slow %d, migraine %d, good %d per 700 days)" % [counts["slow"], counts["migraine"], counts["good"]],
		counts["slow"] + counts["migraine"] > 140 and counts["slow"] + counts["migraine"] < 240 and counts["good"] > 40 and counts["good"] < 110)
	check("mornings: never two in a row", not back_to_back)
	check("mornings: none on day 1 or when not eligible", M.roll(1, 7, true, -99) == "" and M.roll(5, 7, false, -99) == "")
	check("mornings: old save without the key loads as no morning", M.clean(null) == M.new_state() and M.clean({"kind": "bogus"})["kind"] == "")
	check("mornings: pain lines get the hurting face", M.pained(M.SLOW_BED[0]) and M.pained(M.MIGRAINE_BED) and not M.pained(M.SLOW_LATER[0]))
	var dc0: int = main.day_count
	var ck0: float = main.clock
	main.no_loading = true
	main.close_overlay()
	main.dialog.clear()
	main.dev_morning("slow")
	var h0: float = main.happiness
	check("slow morning: she's in bed", main.madison_in_bed() and main.madison_spot() != main.MADISON_POS)
	main._talk_to_madison()
	check("slow morning: talking before the bottle repeats her ask, no coffee yet", str(main.morning["done"]) == "" and main.happiness == h0)
	main.dialog.clear()
	main.check_crib()
	main.dialog.clear()
	main.kitchen()
	main.dialog.clear()
	check("slow morning: crib then kitchen = fed + coffee", bool(main.morning["fed"]) and bool(main.morning["coffee"]))
	main.happiness = 50.0
	main._talk_to_madison()
	main.dialog.clear()
	check("slow morning: coffee brought, +8, still in bed till the meds kick in", str(main.morning["done"]) == "brought" and is_equal_approx(main.happiness, 58.0) and main.madison_in_bed())
	main.clock += 100.0
	check("slow morning: up after 90 min", not main.madison_in_bed())
	main._talk_to_madison()
	check("slow morning: one 'later' line", bool(main.morning["later_said"]))
	main.dialog.clear()
	main.dev_morning("migraine")
	main.clock = 610.0
	main.morning_tick()
	check("migraine skipped: she gets herself up at 10 AM and texts, no happiness hit", str(main.morning["done"]) == "self" and not main.madison_in_bed())
	var dd: Dictionary = main.to_dict()
	check("mornings: state survives a save", str(dd.get("morning", {}).get("kind", "")) == "migraine")
	main.morning = M.new_state()
	main.day_count = dc0
	main.clock = ck0
	main.dialog.clear()
	# portal iframe fit (CrazyGames): fractional when integer scale wastes >10% of the window
	var HdP: = preload("res://scripts/hd_presentation.gd")
	check("fit: 907x510 iframe fills (fractional)", HdP.use_fractional(Vector2i(907, 510)))
	check("fit: 800x450 phone iframe fills (fractional)", HdP.use_fractional(Vector2i(800, 450)))
	check("fit: 1280x720 stays integer 2x", not HdP.use_fractional(Vector2i(1280, 720)))
	check("fit: 1920x1080 stays integer 3x", not HdP.use_fractional(Vector2i(1920, 1080)))
	check("fit: portrait phone 360x640 fractional", HdP.use_fractional(Vector2i(360, 640)))
	var TouchS: = preload("res://scripts/touch_controls.gd")
	var emu: = InputEventScreenTouch.new()
	emu.device = InputEvent.DEVICE_ID_EMULATION
	var fing: = InputEventScreenTouch.new()
	check("touch pad: a mouse click (emulated touch) doesn't count as a finger", not TouchS.real_touch(emu) and TouchS.real_touch(fing))

func _zebra_checks(main: Node) -> void:
	var Z: = preload("res://scripts/zebra.gd")
	var A: = preload("res://scripts/art.gd")
	var dc0: int = main.day_count
	var seen0: bool = main.zebra_seen
	main.dialog.clear()
	main.zebra_seen = false
	main.day_count = Z.FIRST_DAY - 1
	check("zebra: not before day 4", main.zebra_spot().is_empty())
	main.day_count = Z.FIRST_DAY
	check("zebra: offered from day 4", main.zebra_spot().size() == 1)
	main.happiness = 50.0
	main.zebra_story()
	check("zebra: story plays once, +5", main.zebra_seen and is_equal_approx(main.happiness, 55.0) and main.dialog.size() == Z.LINES.size())
	main.dialog.clear()
	main.zebra_story()
	check("zebra: never twice", main.dialog.is_empty() and main.zebra_spot().is_empty())
	check("zebra: survives a save", bool(main.to_dict().get("zebra_seen", false)))
	check("zebra: her story lines use her happy face even when happiness is low",
		A.madison_mood(Cast.T(Z.LINES[1]), 20.0) == 0 and A.madison_mood(Cast.T(Z.LINES[6]), 20.0) == 0)
	main.zebra_seen = seen0
	main.day_count = dc0
	main.dialog.clear()

func _too_loud_checks(main: Node) -> void:
	var TL: = preload("res://scripts/too_loud.gd")
	var A: = preload("res://scripts/art.gd")
	var N: = preload("res://scripts/minigames/noise.gd")
	var dc0: int = main.day_count
	var di0: int = main.day_i
	var seen0: bool = main.too_loud_seen
	var loc0: String = main.location
	main.dialog.clear()
	main.too_loud_seen = false
	main.day_count = TL.FIRST_DAY
	main.day_i = TL.SATURDAY - 1
	check("too loud: not on a Friday", not TL.available(main.day_count, main.day_i, false))
	main.day_i = TL.SATURDAY
	main.day_count = TL.FIRST_DAY - 1
	check("too loud: not before day 6", not TL.available(main.day_count, main.day_i, false))
	main.day_count = TL.FIRST_DAY
	check("too loud: first Saturday from day 6", TL.available(main.day_count, main.day_i, false))
	main.happiness = 50.0
	main.too_loud_story()
	check("too loud: store lines first", main.dialog.size() == TL.STORE.size() and main.after_dialog.is_valid())
	main._after_noise(null, 1.0, [])
	check("too loud: headphones found = calm lines", main.dialog.size() == TL.STORE.size() + TL.CALM.size())
	main.dialog.clear()
	main._after_noise(null, 0.0, [])
	check("too loud: meter full = they leave the cart", main.dialog.size() == TL.BAIL.size())
	main.dialog.clear()
	main._too_loud_home()
	check("too loud: home, crash, +5, once", main.location == "home" and main.too_loud_seen and is_equal_approx(main.happiness, 55.0) and main.dialog.size() == TL.HOME.size())
	check("too loud: never twice", not TL.available(main.day_count, main.day_i, main.too_loud_seen))
	check("too loud: survives a save", bool(main.to_dict().get("too_loud_seen", false)))
	check("too loud: her lines use her happy face even when happiness is low",
		A.madison_mood(Cast.T(TL.STORE[1]), 20.0) == 0 and A.madison_mood(Cast.T(TL.CALM[1]), 20.0) == 0 and A.madison_mood(Cast.T(TL.HOME[1]), 20.0) == 0)
	var g: = N.new()
	g._setup()
	check("too loud: the bag holds her headphones", not g.get_button("headphones").is_empty() and g.buttons.size() == N.ITEMS.size())
	g.free()
	main.dialog.clear()
	main.after_dialog = Callable()
	main.too_loud_seen = seen0
	main.day_count = dc0
	main.day_i = di0
	if loc0 != "home":
		main.leave_home()

## "Look At This" (look_at_this.gd): her phone, his story. Once, at home, from FIRST_DAY, never in the way of a hand-over.
func _look_checks(main: Node) -> void:
	var LA: = preload("res://scripts/look_at_this.gd")
	var A: = preload("res://scripts/art.gd")
	var dc0: int = main.day_count
	var seen0: bool = main.look_seen
	var loc0: String = main.location
	main.dialog.clear()
	check("look: not before day 3", not LA.available(LA.FIRST_DAY - 1, false))
	check("look: from day 3", LA.available(LA.FIRST_DAY, false))
	check("look: her reel shows on line 2 and 3", LA.screen(Cast.T(LA.LINES[1])) == "reel" and LA.screen(Cast.T(LA.LINES[2])) == "reel")
	check("look: the text shows on line 5", LA.screen(Cast.T(LA.LINES[4])) == "text")
	check("look: no phone on Duff's lines", LA.screen(Cast.T(LA.LINES[0])) == "" and LA.screen(Cast.T(LA.LINES[3])) == "" and LA.screen(Cast.T(LA.LINES[5])) == "")
	check("look: her lines use her happy face", A.madison_mood(Cast.T(LA.LINES[1]), 20.0) == 0 and A.madison_mood(Cast.T(LA.LINES[4]), 20.0) == 0)
	main.happiness = 50.0
	main.look_seen = false
	main.look_story()
	check("look: plays all lines, +3, once", main.look_seen and main.dialog.size() == LA.LINES.size() and is_equal_approx(main.happiness, 53.0))
	check("look: never twice", not LA.available(LA.FIRST_DAY + 5, main.look_seen))
	check("look: survives a save", bool(main.to_dict().get("look_seen", false)))
	var bare_ok: = true
	for l in LA.LINES:
		if str(l).contains("Facebook") or str(l).contains("Brittany"):
			bare_ok = false
	check("look: no real brand or name in her lines", bare_ok)
	main.dialog.clear()
	main.look_seen = seen0
	main.day_count = dc0
	if loc0 != main.location and loc0 != "home" and main.location == "home":
		main.leave_home()
