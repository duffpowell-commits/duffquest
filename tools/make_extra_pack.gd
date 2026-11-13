extends SceneTree
## Builds the web build's after-boot packs. The Web export preset leaves out of index.pck every asset glob in
## its exclude_filter (entries that start with "assets/"); this tool packs those files into three tiers:
##   street  the WORLD files that also match STREET (the cold open's street, Duff, porch pirates): fetched
##           first, gates "New Game"
##   world   the rest of the WORLD globs (cast, portraits, music...): fetched second, gates "Continue"
##   late    every other excluded glob (knockout stills, boss cards, most loading screens, backdrops)
## scripts/extra_pack.gd downloads street.pck, world.pck, then extra.pck after boot and mounts them.
##   godot --headless --path . --script tools/make_extra_pack.gd -- build/web/street.pck street
##   godot --headless --path . --script tools/make_extra_pack.gd -- build/web/world.pck world
##   godot --headless --path . --script tools/make_extra_pack.gd -- build/web/extra.pck [late]
## Every packed texture = its .import remap + the imported .ctex it points to, same as a normal export.

## Globs (also in the Web preset's exclude_filter) that go in world.pck. Storefront/prop walls come from
## data/art_rects.json (tools/bake_art_rects.gd), so their art can wait here too.
const WORLD: = ["assets/art/ch_*", "assets/art/sf_*", "assets/art/sd_*", "assets/art/portraits_hd/*", "assets/art/kf_*", "assets/art/kp_*",
	"assets/art/arena_*", "assets/art/duff_*", "assets/art/gala*", "assets/art/home_*", "assets/art/bg_kitchen*",
	"assets/art/ground_painted*", "assets/art/loading/*", "assets/audio/mus_*", "assets/sfx/ko/*"]

## Subset of WORLD the cold open needs (main.gd cold_open): the street outside home, Duff's walk/roll layers,
## the street's day-1/2 walkers and porch pirates, the home interior and Duff's dialogue portrait. Keep it small: it's the wait between
## tapping New Game and the first punch. Duff's finisher stills (duff_*.jpg) wait for world.pck.
const STREET: = ["assets/art/sf_*", "assets/art/sd_*", "assets/art/ground_painted*", "assets/art/home_*", "assets/art/duff_*.png",
	"assets/art/ch_pirate*", "assets/art/ch_scammer*", "assets/art/ch_hustler*", "assets/art/ch_karen*", "assets/art/ch_madison.png",
	"assets/art/portraits_hd/duff.png"]   # the cold open's one line is Duff's: no empty portrait frame

func _init() -> void:
	var out: = "build/web/extra.pck"
	var tier: = "late"
	var args: = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		tier = args[1]
	var pats: = deferred_patterns()
	for g in WORLD:
		if not pats.has(g):
			push_error("make_extra_pack: WORLD glob %s is missing from the Web preset's exclude_filter" % g)
			quit(1)
			return
	var late: = PackedStringArray()
	for g in pats:
		if not WORLD.has(g):
			late.append(g)
	if late.is_empty():
		push_error("make_extra_pack: no late assets/ patterns in the Web preset's exclude_filter")
		quit(1)
		return
	var files: Array = []
	_walk("res://assets", late, files)   # late globs win (loading/* overlaps the late loading screens)
	if tier == "world" or tier == "street":
		var late_files: = files
		files = []
		_walk("res://assets", PackedStringArray(WORLD), files)
		files = files.filter(func(f): return not late_files.has(f))
		var street_files: Array = []
		_walk("res://assets", PackedStringArray(STREET), street_files)
		if tier == "street":
			files = files.filter(func(f): return street_files.has(f))
		else:
			files = files.filter(func(f): return not street_files.has(f))
	var pk: = PCKPacker.new()
	if pk.pck_start(out) != OK:
		push_error("make_extra_pack: can't write " + out)
		quit(1)
		return
	var bytes: = 0
	for src in files:
		var imp: String = src + ".import"
		var dest: = _remap_path(imp)
		if dest == "" or not FileAccess.file_exists(dest):
			push_error("make_extra_pack: %s has no imported data (run --import first)" % src)
			quit(1)
			return
		pk.add_file(imp, imp)
		pk.add_file(dest, dest)
		bytes += FileAccess.get_file_as_bytes(dest).size()
	pk.flush(false)
	print("%s pack: %d files, %.1f MB -> %s" % [tier, files.size(), bytes / 1048576.0, out])
	quit(0)

## The asset globs the Web preset leaves out of index.pck (export_presets.cfg, preset "Web").
static func deferred_patterns() -> PackedStringArray:
	var cf: = ConfigFile.new()
	if cf.load("res://export_presets.cfg") != OK:
		return PackedStringArray()
	var out: = PackedStringArray()
	for sec in cf.get_sections():
		if sec.ends_with(".options") or str(cf.get_value(sec, "name", "")) != "Web":
			continue
		for p in str(cf.get_value(sec, "exclude_filter", "")).split(","):
			var g: = p.strip_edges()
			if g.begins_with("assets/"):
				out.append(g)
	return out

func _walk(dir: String, pats: PackedStringArray, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		var full: = dir.path_join(f)
		if f.ends_with(".import") or not FileAccess.file_exists(full + ".import"):
			continue
		var rel: = full.trim_prefix("res://")
		for g in pats:
			if rel.match(g):
				out.append(full)
				break
	for d in DirAccess.get_directories_at(dir):
		_walk(dir.path_join(d), pats, out)

static func _remap_path(imp: String) -> String:
	var cf: = ConfigFile.new()
	if cf.load(imp) != OK:
		return ""
	return str(cf.get_value("remap", "path", ""))
