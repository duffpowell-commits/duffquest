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
	SaveGame.erase("user://test_daily_save.json")
	main.queue_free()
	await process_frame
	print("%s (%d failed)" % ["ALL PASS" if fails == 0 else "FAILURES", fails])
	quit(1 if fails > 0 else 0)

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
