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
	for path in ["res://scripts/loading_screen.gd", "res://scripts/knockout.gd"]:   # above the portraits
		var n: Node2D = load(path).new()
		n.main = main
		n.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		layer.add_child(n)
