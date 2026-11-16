extends Node
## Root of the game. The game (main.tscn) lives in 640×360 coordinates inside a SubViewport that renders
## res_scale times bigger (1280×720), then is shown at the window's size. On top, at the screen's real
## resolution, sit things that must stay sharp: the HD cartoon dialogue portraits.
const Art: = preload("res://scripts/art.gd")
## The world keeps its 640x360 coordinate system, but renders RES_SCALE times bigger so the
## HD art (4 texture px per world unit; the camera zooms 2x) is not crushed. Audit: docs/reviews/hd_audit_2026-11-16.md
const BASE: = Vector2i(640, 360)
var res_scale: = 2
var _vp: SubViewport
var _box: SubViewportContainer

## 1 = the old 640x360 render (phones that can't keep up), 2 = 1280x720 (every s:4 sprite pixel shows).
func set_res_scale(n: int) -> void:
	res_scale = clampi(n, 1, 2)
	if _vp == null:
		return
	_vp.size = BASE * res_scale
	_box.size = Vector2(BASE * res_scale)
	_box.scale = Vector2.ONE / float(res_scale)

func _ready() -> void:
	var box: = SubViewportContainer.new()
	box.stretch = false
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(box)
	var vp: = SubViewport.new()
	_vp = vp
	_box = box
	vp.size_2d_override = BASE
	vp.size_2d_override_stretch = true
	set_res_scale(res_scale)
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.snap_2d_transforms_to_pixel = true
	vp.snap_2d_vertices_to_pixel = true
	vp.audio_listener_enable_2d = true
	box.add_child(vp)
	Art.hd_enabled = true
	var main: = (load("res://main.tscn") as PackedScene).instantiate()
	vp.add_child(main)
	# 3D town view (Settings > 3D view), under the 2D viewport. Engines without 3D (the slim web build) skip it,
	# and load() (not preload) keeps them from ever parsing the script.
	var v3: Node = null
	if ClassDB.class_exists("Node3D"):
		v3 = load("res://scripts/view3d/view3d.gd").new()
		v3.set("main", main)
		v3.set("vp2d", vp)
		v3.z_index = -1      # drawn under the 2D viewport; stays child 1 so tools that walk child(0) still find main
		add_child(v3)
	var layer: = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var overlay: = preload("res://scripts/hd_portrait_overlay.gd").new()
	overlay.main = main
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	layer.add_child(overlay)
	var gate: = WorldGate.new()
	gate.name = "WorldGate"
	gate.vp = vp
	gate.process_priority = 1000
	gate.process_mode = Node.PROCESS_MODE_ALWAYS
	for path in ["res://scripts/loading_screen.gd", "res://scripts/fridge_calendar.gd", "res://scripts/knockout.gd"]:   # above the portraits
		var n: Node2D = load(path).new()
		n.main = main
		n.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		layer.add_child(n)
		gate.covers.append(n)
	if v3 != null:
		gate.vp3d = v3.get("vp")
	add_child(gate)
	var extra: = preload("res://scripts/extra_pack.gd").new()   # web: streams the deferred art in the background
	extra.name = "ExtraPack"
	add_child(extra)
	var guard: = preload("res://scripts/perf_guard.gd").new()
	guard.name = "PerfGuard"
	guard.main = main
	add_child(guard)

## Full-screen HD overlays (loading screen, fridge calendar, knockout) are opaque: while one is up,
## stop rendering the 640x360 world under it (the container keeps showing its last frame). On a
## phone that's the whole world pass + lights + screen shader saved, every frame of a cutscene.
## Runs after every other node's _process (priority), so it sees this frame's overlay state.
class WorldGate extends Node:
	var vp: SubViewport
	var vp3d: SubViewport          # View3D's viewport (null on 2D-only engines); paused under the same overlays
	var covers: Array = []
	func _process(_d: float) -> void:
		var hide: = false
		for n in covers:
			if is_instance_valid(n) and n.covers_screen():
				hide = true
				break
		var mode: = SubViewport.UPDATE_DISABLED if hide else SubViewport.UPDATE_ALWAYS
		if vp.render_target_update_mode != mode:
			vp.render_target_update_mode = mode
		if hide and vp3d != null and vp3d.render_target_update_mode != mode:
			vp3d.render_target_update_mode = mode   # View3D turns it back on next frame when the cover lifts
