extends SceneTree
## Headless checks for the daily-life layer (shift shuffle, muscle memory, calendar, curveballs).
##   godot --headless --path . --script tools/test_daily.gd
## Prints PASS/FAIL per check and exits 1 on any failure.

const Shift: = preload("res://scripts/shift.gd")
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
	main.queue_free()
	await process_frame
	print("%s (%d failed)" % ["ALL PASS" if fails == 0 else "FAILURES", fails])
	quit(1 if fails > 0 else 0)

## M11/M12 checks get added here.
func _extra_checks(_main: Node) -> void:
	pass

class FakeMain extends Node:
	var station_best: Dictionary = {}
