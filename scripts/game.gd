extends Node
## Root of the game. The pixel game (main.tscn) renders at 640×360 inside a SubViewport and is
## scaled up with nearest filtering, so it looks exactly as before. On top, at the screen's real
## resolution, sit things that must stay sharp: the HD cartoon dialogue portraits.
const Art: = preload("res://scripts/art.gd")

func _ready() -> void:
	var box: = SubViewportContainer.new()
	box.stretch = true
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(box)
	var vp: = SubViewport.new()
	vp.size = Vector2i(640, 360)
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.snap_2d_transforms_to_pixel = true
	vp.snap_2d_vertices_to_pixel = true
	vp.audio_listener_enable_2d = true
	box.add_child(vp)
	Art.hd_enabled = true
	var main: = (load("res://main.tscn") as PackedScene).instantiate()
	vp.add_child(main)
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
