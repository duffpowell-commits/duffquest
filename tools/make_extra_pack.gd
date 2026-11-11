extends SceneTree
## Builds the web build's second pack: art the first minutes don't need (knockout stills, boss intro cards,
## most loading screens, minigame backdrops). The Web export preset excludes exactly these from index.pck
## (its exclude_filter entries that start with "assets/"), so first boot downloads far less; game.gd fetches
## this pack in the background and mounts it (scripts/extra_pack.gd).
##   godot --headless --path . --script tools/make_extra_pack.gd -- build/web/extra.pck
## Every packed texture = its .import remap + the imported .ctex it points to, same as a normal export.

func _init() -> void:
	var out: = "build/web/extra.pck"
	var args: = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var pats: = deferred_patterns()
	if pats.is_empty():
		push_error("make_extra_pack: no assets/ patterns in the Web preset's exclude_filter")
		quit(1)
		return
	var files: Array = []
	_walk("res://assets", pats, files)
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
	print("extra pack: %d textures, %.1f MB -> %s" % [files.size(), bytes / 1048576.0, out])
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
