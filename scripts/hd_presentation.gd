extends Node2D
# Presentation only. World-space coordinates and gameplay state are untouched.
var lights: Array[PointLight2D] = []
var post: CanvasLayer
var low: = false            # perf_guard.gd "lite graphics": no screen shader, no window lights
var world_shown: = true     # main.gd: false while an opaque full-screen menu/minigame hides the world

func _ready() -> void:
 name = "HD2DPresentation"
 _fit_small_window()
 get_window().size_changed.connect(_fit_small_window)
 var grade := CanvasModulate.new()
 grade.name = "WarmWorldGrade"
 grade.color = Color(1.0, 0.98, 0.94, 1.0)
 add_child(grade)
 var env := WorldEnvironment.new()
 env.name = "HDEnvironment"
 env.environment = Environment.new()
 # Godot 4.4 Web requires GL Compatibility and cannot render HDR 2D.
 # The screen shader supplies gentle LDR bloom there, instead of silently failing HDR glow.
 if RenderingServer.get_current_rendering_method() != "gl_compatibility":
  get_viewport().use_hdr_2d = true
  env.environment.glow_enabled = true
  env.environment.glow_intensity = 0.15
 add_child(env)
 post = CanvasLayer.new()
 post.name = "WorldOnlyPostProcess"
 post.layer = 0
 add_child(post)
 var rect := ColorRect.new()
 rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
 rect.size = get_viewport_rect().size
 rect.color = Color.WHITE
 var mat := ShaderMaterial.new()
 mat.shader = preload("res://shaders/hd2d.gdshader")
 rect.material = mat
 post.add_child(rect)
 get_viewport().size_changed.connect(func() -> void: rect.size = get_viewport_rect().size)
 var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
 for y in 96:
  for x in 96:
   var d := Vector2(x-48,y-48).length()/48.0
   image.set_pixel(x,y,Color(1.0,0.86,0.64,pow(maxf(0.0,1.0-d),2.0)*0.50))
 var texture := ImageTexture.create_from_image(image)
 for pos in [Vector2(70,88),Vector2(120,88),Vector2(535,100),Vector2(535,289),Vector2(138,147),Vector2(288,221),Vector2(628,139),Vector2(46,465),Vector2(272,465)]:
  var light := PointLight2D.new()
  light.name = "SoftWindowLight"
  light.position = pos
  light.texture = texture
  light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
  light.texture_scale = 0.55
  light.energy = 0.18
  light.color = Color(1.0,0.91,0.75)
  light.blend_mode = PointLight2D.BLEND_MODE_ADD
  add_child(light)
  lights.append(light)

## Lite graphics for slow phones (perf_guard.gd). The pixel art is untouched; only the HD-2D
## screen shader (soft bloom, vignette, far-edge blur) and the 9 soft window lights go.
func set_low(on: bool) -> void:
 low = on
 _refresh()

## Nothing to post-process while an opaque overlay covers the world: skip the screen copy + shader.
func set_world_shown(on: bool) -> void:
 if on != world_shown:
  world_shown = on
  _refresh()

func _refresh() -> void:
 if post:
  post.visible = world_shown and not low
 for l in lights:
  l.enabled = not low

func _fit_small_window() -> void:
 var window := get_window()
 # Integer upscaling normally; allow nearest-filtered downscaling only when
 # the screen cannot fit a 640x360 frame (e.g. a phone held in portrait).
 var tiny := window.size.x < 640 or window.size.y < 360
 var target := Window.CONTENT_SCALE_STRETCH_FRACTIONAL if tiny else Window.CONTENT_SCALE_STRETCH_INTEGER
 if window.content_scale_stretch != target:
  window.content_scale_stretch = target
