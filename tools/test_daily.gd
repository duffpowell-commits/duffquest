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
	_ko_sfx_checks()
	_button_fit_checks()
	_qa_leftover_checks()
	SaveGame.erase("user://test_daily_save.json")
	main.queue_free()
	await process_frame
	print("%s (%d failed)" % ["ALL PASS" if fails == 0 else "FAILURES", fails])
	quit(1 if fails > 0 else 0)

const Daily: = preload("res://scripts/daily.gd")

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

class FakeMain extends Node:
	var station_best: Dictionary = {}
