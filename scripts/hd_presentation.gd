extends Node2D
const Art := preload("res://scripts/art.gd")
# Presentation only. World-space coordinates and gameplay state are untouched.
var lights: Array[PointLight2D] = []
var post: CanvasLayer
var low: = false            # perf_guard.gd "lite graphics": no screen shader, no window lights
var world_shown: = true     # main.gd: false while an opaque full-screen menu/minigame hides the world
var grade: CanvasModulate
var door_lights: Array[PointLight2D] = []   # warm pools at shop doors, lit from dusk (style_board_2's lamp glow)
var dark: = 0.0             # 0 = full day, 1 = deep night (drives light energy)

## Time-of-day grade, outdoors (minutes since midnight -> world multiply colour). style_board_2: warm morning,
## neutral noon, golden late afternoon, violet dusk, cool blue night. Keys wrap at midnight.
const SKY: = [
 [0.0, Color(0.40, 0.46, 0.74)],
 [300.0, Color(0.42, 0.47, 0.74)],
 [420.0, Color(1.0, 0.95, 0.88)],
 [660.0, Color(1.0, 0.99, 0.97)],
 [960.0, Color(1.0, 0.97, 0.92)],
 [1080.0, Color(1.0, 0.86, 0.70)],
 [1170.0, Color(0.70, 0.62, 0.80)],
 [1260.0, Color(0.40, 0.46, 0.74)],
 [1440.0, Color(0.40, 0.46, 0.74)],
]

func _ready() -> void:
 name = "HD2DPresentation"
 _fit_small_window()
 get_window().size_changed.connect(_fit_small_window)
 grade = CanvasModulate.new()
 grade.name = "WarmWorldGrade"
 grade.color = Color(1.0, 0.98, 0.94, 1.0)
 add_child(grade)
 # Godot 4.4 Web requires GL Compatibility and cannot render HDR 2D.
 # The screen shader supplies gentle LDR bloom there, instead of silently failing HDR glow.
 # Built by name: the trimmed web engine (tools/web_template) has no 3D classes, WorldEnvironment included.
 if RenderingServer.get_current_rendering_method() != "gl_compatibility" and ClassDB.class_exists("WorldEnvironment"):
  get_viewport().use_hdr_2d = true
  var env: Node = ClassDB.instantiate("WorldEnvironment")
  env.name = "HDEnvironment"
  var e: Resource = ClassDB.instantiate("Environment")
  e.set("glow_enabled", true)
  e.set("glow_intensity", 0.15)
  env.set("environment", e)
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
 var image := Image.create_empty(96, 96, false, Image.FORMAT_RGBA8)
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
 var m := get_parent()
 if m != null and m.get("buildings") != null:
  for b in m.buildings:
   if not b.has("art"):
    continue
   var r: Rect2 = b.get("vis", b["r"])
   var pool := PointLight2D.new()
   pool.name = "DoorLight"
   pool.position = Vector2(r.get_center().x, r.end.y - 2.0)
   pool.texture = texture
   pool.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
   pool.texture_scale = clampf(r.size.x / 110.0, 0.5, 1.1)
   pool.energy = 0.0
   pool.color = Color(1.0, 0.82, 0.55)
   pool.blend_mode = PointLight2D.BLEND_MODE_ADD
   add_child(pool)
   door_lights.append(pool)

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
 for l in door_lights:
  l.enabled = not low and dark > 0.02

static func sky_at(minute: float) -> Color:
 var c := fmod(minute, 1440.0)
 for i in SKY.size() - 1:
  var a: Array = SKY[i]
  var b: Array = SKY[i + 1]
  if c >= float(a[0]) and c <= float(b[0]):
   return (a[1] as Color).lerp(b[1], (c - float(a[0])) / maxf(1.0, float(b[0]) - float(a[0])))
 return SKY[0][1]

## 0 by day, 1 at night: how much the lamps and windows matter.
static func darkness(minute: float) -> float:
 var sky := sky_at(minute)
 return clampf((1.0 - sky.g) / 0.54, 0.0, 1.0)

func _process(_d: float) -> void:
 var m := get_parent()
 if m == null or m.get("clock") == null:
  return
 var loc := str(m.location)
 var c := float(m.clock)
 var was := dark > 0.02
 var target := Color.WHITE
 if loc == "outside":
  target = sky_at(c)
  dark = darkness(c)
 elif loc == "home":
  # indoors: lamps are on, so night only warms and dims a little
  target = Color(1.0, 0.98, 0.94).lerp(Color(0.9, 0.82, 0.74), darkness(c))
  dark = 0.0
 else:
  dark = 0.0
 grade.color = target
 for l in lights:
  l.energy = 0.18 + 0.32 * dark
 for l in door_lights:
  l.energy = 1.6 * dark
 if was != (dark > 0.02):
  _refresh()
 # long soft shadows: the sun swings east -> west through the day and the shadows stretch at dawn / dusk
 if loc == "outside":
  var day := clampf((fmod(c, 1440.0) - 420.0) / (1140.0 - 420.0), 0.0, 1.0)
  Art.sun_shift = Vector2(lerpf(3.0, -3.0, day), 0.5) * (1.0 - dark)
  Art.sun_stretch = 1.0 + 0.45 * absf(day - 0.5) * 2.0 * (1.0 - dark)
 else:
  Art.sun_shift = Vector2.ZERO
  Art.sun_stretch = 1.0

## True when integer scaling would leave more than 10% of the window unused (or the
## window can't fit a 640x360 frame at all).
static func use_fractional(size: Vector2i) -> bool:
 var fit := minf(size.x / 640.0, size.y / 360.0)
 if fit < 1.0:
  return true
 return floorf(fit) / fit < 0.9

func _fit_small_window() -> void:
 var window := get_window()
 # Integer upscaling when it fills most of the screen; otherwise fractional, so the
 # frame fills the window. Without this a 907x510 portal iframe (CrazyGames' default
 # desktop size) or any window under 1280x720 drew the game at 1x, 640x360, in a sea
 # of black. canvas_items stretch draws text and the 4x art at screen resolution, so
 # fractional scales stay sharp.
 var target := Window.CONTENT_SCALE_STRETCH_FRACTIONAL if use_fractional(window.size) else Window.CONTENT_SCALE_STRETCH_INTEGER
 if window.content_scale_stretch != target:
  window.content_scale_stretch = target
