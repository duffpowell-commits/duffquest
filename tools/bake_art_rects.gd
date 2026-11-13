extends SceneTree
## Bakes data/art_rects.json: pixel size + opaque rect of every storefront (sf_*) and street prop (sd_*).
## main.gd builds walls from it at startup (scripts/art.gd used_rect / tex_size), so the web build can ship that
## art in world.pck and still get the walls right before it lands. Re-run after re-importing sf_* or sd_* art:
##   godot --headless --path . --script tools/bake_art_rects.gd
## test_daily fails if the file is out of date.
const Art: = preload("res://scripts/art.gd")

static func measure() -> Dictionary:
	var out: = {}
	var names: Array = Art.names()
	names.sort()
	for n in names:
		var s: = str(n)
		if not (s.begins_with("sf_") or s.begins_with("sd_")):
			continue
		var tx: = Art.tex(s)
		if tx == null:
			continue
		var u: = tx.get_image().get_used_rect()
		out[s] = {"size": [tx.get_width(), tx.get_height()], "used": [u.position.x, u.position.y, u.size.x, u.size.y]}
	return out

func _init() -> void:
	var d: = measure()
	var f: = FileAccess.open(Art.RECTS, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "\t", true) + "\n")
	f.close()
	print("art rects: %d entries -> %s" % [d.size(), Art.RECTS])
	quit(0)
