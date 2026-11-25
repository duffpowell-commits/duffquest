extends Node
## "Golden hour" look (Duff's pick, Nov 25 2026, card A/B/C; renders in docs/renders/porch3d/look_*):
## low warm sun with long shadows, cool sky fill, porch lamp glow, soft vignette, and fighters that pop
## off the lawn (thin ink outline, soft rim, contact shadow under the feet). MSAA smooths edges.
## Phone guard: if the frame rate sits under LITE_BELOW for LITE_AFTER seconds, glow and MSAA turn
## off (the "lite" golden hour); `--lite` starts that way. `--plain` keeps the old daylight look.

const LITE_BELOW := 50.0
const LITE_AFTER := 3.0
const LITE_SCALE := .75  ## lite draws the 3D at this size, nearest-scaled up (4.7)
const OUTLINE_PX := 1.6
const RIM_TINT := Color("#ffd29a")

const Daylight = preload("porch_daylight.gd")
const Hud = preload("porch_hud.gd")

var env: Environment
var sun: DirectionalLight3D
var game  ## porch.gd
var minute_shown := -1.0  ## the clock minute the light was last set for
var lite := false
static var stay_lite := false  ## once the phone proved slow, retries start lite too
var slow_for := 0.0
var warmup := 2.0  ## ignore the first seconds (shader compiles) before judging speed

static func apply(scene: Node3D, fighters: Array) -> Node:
	var look = (load("res://porch_look.gd") as GDScript).new()
	look.name = "Look"
	scene.add_child(look)
	look._setup(scene, fighters)
	return look

func _setup(scene: Node3D, fighters: Array) -> void:
	game = scene
	env = (scene.find_children("*", "WorldEnvironment", true, false)[0] as WorldEnvironment).environment
	sun = scene.find_children("*", "DirectionalLight3D", true, false)[0]
	sun.shadow_blur = 1.6
	env.glow_intensity = .6
	env.glow_hdr_threshold = .9
	for actor in fighters:
		_pop(actor)
		_contact_shadow(actor.get_parent())
	_vignette(scene)
	set_lite(stay_lite or OS.get_cmdline_user_args().has("--lite"))
	dress(scene)
	daylight(Hud.start_min())

## A zone was built: tint its lawn, and let its lamps follow the clock.
func dress(root: Node) -> void:
	for lawn in root.find_children("Lawn", "MeshInstance3D", true, false):
		var mat := (lawn as MeshInstance3D).material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color("#8fa874")
	for lamp in root.find_children("*", "OmniLight3D", true, false):
		if lamp.has_meta("look_range"):
			(lamp as OmniLight3D).omni_range = lamp.get_meta("look_range")
	if game.hud:
		daylight(game.hud.game_minute())

## Sun, sky fill, background, lamps and windows for a minute of the day (porch_daylight.gd).
## Indoors (zone meta "indoor") the fill is warmer and the windows show the sky.
func daylight(minute: float) -> void:
	var d := Daylight.at(minute)
	var indoor: bool = game.zones != null and game.zones.indoor
	sun.rotation_degrees = d.sun_rot
	sun.light_color = d.sun_color
	sun.light_energy = d.sun_energy * (.8 if indoor else 1.0)
	env.ambient_light_color = d.fill.lerp(Color("#d8a888"), .25) if indoor else d.fill
	env.ambient_light_energy = d.fill_energy * (clampf(d.sun_energy, .4, 1.0) if indoor else 1.0)  # dark rooms at night: the lamps carry it
	env.background_color = Color("#241c26") if indoor else d.sky
	for lamp in get_tree().get_nodes_in_group("zone_lamp"):
		(lamp as OmniLight3D).light_energy = float(lamp.get_meta("base_energy", 1.0)) * d.lamp
	for pane in get_tree().get_nodes_in_group("zone_window"):
		var mat := (pane as MeshInstance3D).material_override as StandardMaterial3D
		mat.emission = d.sky.lerp(d.sun_color, .35)
		mat.emission_energy_multiplier = (.25 + d.sun_energy * .5) * (.15 if game.blinds_down else 1.0)
		mat.albedo_color = Color("#8a8478") if game.blinds_down else Color("#e8e2d8")
	minute_shown = minute

func set_lite(on: bool) -> void:
	lite = on
	env.glow_enabled = not on
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if on else Viewport.MSAA_4X
	# 4.7: draw the 3D at 3/4 size and scale it up with nearest filtering: about 44% fewer pixels, still crisp
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST if on else Viewport.SCALING_3D_MODE_BILINEAR
	get_viewport().scaling_3d_scale = LITE_SCALE if on else 1.0

func _process(delta: float) -> void:
	# The light holds still through a fight (the porch stays golden hour) and follows the clock after.
	var minute: float = (game.hud.game_minute() if game.exploring else float(game.hud.clock_start)) if game.hud else minute_shown
	if absf(minute - minute_shown) >= .05:
		daylight(minute)
	if lite or OS.has_feature("editor"):  # judge speed only in exported builds (the phone)
		return
	warmup -= delta
	if warmup > 0:
		return
	slow_for = slow_for + delta if Engine.get_frames_per_second() < LITE_BELOW else 0.0
	if slow_for >= LITE_AFTER:
		stay_lite = true
		set_lite(true)

## Soft warm rim + thin ink outline, keeping each model's own Meshy texture.
func _pop(actor: Node) -> void:
	var outline := ShaderMaterial.new()
	outline.shader = load("res://ink_outline.gdshader")
	outline.set_shader_parameter("width_px", OUTLINE_PX)
	for node in actor.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for i in mesh.mesh.get_surface_count():
			var src := mesh.get_active_material(i) as StandardMaterial3D
			if src == null:
				continue
			var mat := src.duplicate() as StandardMaterial3D
			mat.rim_enabled = true
			mat.rim = .35
			mat.rim_tint = .8
			mat.next_pass = outline
			mesh.set_surface_override_material(i, mat)

func _contact_shadow(body: Node3D) -> void:
	var quad := MeshInstance3D.new()
	quad.name = "ContactShadow"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.3, .9)
	quad.mesh = plane
	quad.position.y = .02
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode unshaded, blend_mix, depth_draw_never;\n" \
		+ "void fragment() { float d = length(UV - .5) * 2.0; ALBEDO = vec3(.05, .03, .06);" \
		+ " ALPHA = .55 * (1.0 - smoothstep(.2, 1.0, d)); }"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	quad.material_override = mat
	body.add_child(quad)

func _vignette(scene: Node) -> void:
	var layer := CanvasLayer.new()
	layer.name = "Vignette"
	layer.layer = -1  # over the 3D, under the HUD
	scene.add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment() {" \
		+ " float d = length((UV - .5) * vec2(1.5, 1.0));" \
		+ " COLOR = vec4(.08, .04, .1, smoothstep(.45, 1.0, d) * .55); }"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	layer.add_child(rect)
