#!/bin/sh
# Local Linux upgrade-path regression. Uses only disposable XDG data; never touches real saves.
set -eu
cd "$(git rev-parse --show-toplevel)"
repo="$PWD"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/old-root" "$work/old-porch"
printf 'config_version=5\n[application]\nconfig/name="Fork Around and Find Out"\n' > "$work/old-root/project.godot"
printf 'config_version=5\n[application]\nconfig/name="Fork Around and Find Out - Porch Encounter"\n' > "$work/old-porch/project.godot"
cat > "$work/probe.gd" <<'GD'
extends SceneTree
func _initialize() -> void:
	var path := ProjectSettings.globalize_path("user://")
	var args := OS.get_cmdline_user_args()
	print("user directory: ", path)
	if args[0] == "seed-root":
		var f := FileAccess.open("user://duffquest_save.json", FileAccess.WRITE)
		f.store_string('{"version":0,"day_count":7,"day_i":2,"money":123,"quest":2,"inventory":{}}')
		f.close()
	elif args[0] == "seed-porch":
		var c := ConfigFile.new()
		c.set_value("porch", "grade", "A")
		c.set_value("porch", "time", 42.5)
		if c.save("user://porch_best.cfg") != OK:
			quit(1)
			return
	else:
		var c := ConfigFile.new()
		if c.load("user://porch_best.cfg") != OK or c.get_value("porch", "grade") != "A" or c.get_value("porch", "time") != 42.5:
			printerr("FAIL porch legacy best")
			quit(1)
			return
		print("PASS porch legacy best grade and time")
	quit()
GD
cat > "$work/read.gd" <<'GD'
extends SceneTree
const SaveGame = preload("res://scripts/save_game.gd")
func _initialize() -> void:
	print("user directory: ", ProjectSettings.globalize_path("user://"))
	var d := SaveGame.read()
	if int(d.get("version", -1)) != SaveGame.VERSION or int(d.get("day_count", 0)) != 7 or int(d.get("money", 0)) != 123 or int(d.get("inventory", {}).get("honey buns", 0)) != 1:
		printerr("FAIL legacy save upgrade: ", d)
		quit(1)
		return
	print("PASS legacy version 0 -> ", SaveGame.VERSION, "; Day 7, $123, honey buns migration")
	quit()
GD
for edition in root hd; do
  target="$repo"
  [ "$edition" != hd ] || target="$repo/duffquesthd"
  export XDG_DATA_HOME="$work/$edition"
  godot --headless --path "$work/old-root" --script "$work/probe.gd" -- seed-root
  godot --headless --path "$target" --script "$work/read.gd"
done
export XDG_DATA_HOME="$work/porch"
godot --headless --path "$work/old-porch" --script "$work/probe.gd" -- seed-porch
godot --headless --path "$repo/spike_full3d" --script "$work/probe.gd" -- check-porch
