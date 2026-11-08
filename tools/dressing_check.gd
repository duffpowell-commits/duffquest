extends SceneTree
## Lists street-dressing walls that sit on top of an outdoor interaction spot (doors, Brittany,
## bus stops, the Ensure, raccoon spots...). Run after editing data/town_dressing.json:
##   godot --headless --path . --script tools/dressing_check.gd
## Prints "dressing_check: OK" or one line per clash; exits 1 on clashes.

func _initialize() -> void:
	var m: Node = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var spots: Array = m.interactables()
	spots.append({"id": "ensure", "pos": m.ENSURE_POS, "r": 10.0})
	var bad: = 0
	for it in m.dressing:
		if it["wall"] == null:
			continue
		var w: Rect2 = it["wall"]
		for s in spots:
			var p: Vector2 = s["pos"]
			if p.y > 360.0:
				continue
			# a spot needs a clear patch around it to stand on
			if w.grow(6.0).has_point(p) or w.grow(float(s["r"]) * 0.6).has_point(p):
				print("clash: %s wall %s vs %s at %s" % [it["a"], w, s["id"], p])
				bad += 1
	print("dressing_check: OK" if bad == 0 else "dressing_check: %d clashes" % bad)
	quit(1 if bad else 0)
