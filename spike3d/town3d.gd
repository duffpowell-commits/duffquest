extends Node3D
## 3D spike: the real town map (same rects, same dressing data, same painted art) rebuilt as an HD-2D diorama.
## 2D world units map 1:1 onto the ground plane: 2D (x, y) -> 3D (x * U, 0, y * U). Art stands up as cards.
## Run: godot --path spike3d [-- dusk|day|night] [demo] [shots]

const U: = 0.1                     # metres per 2D world unit
const Duff3D: = preload("duff3d.gd")
const Raccoon3D: = preload("raccoon3d.gd")

## copied from scripts/main.gd `buildings` (public edition art)
const BUILDINGS: = [
	[Rect2(40, 40, 110, 70), "sf_home"], [Rect2(190, 40, 80, 60), "sf_neighbor"],
	[Rect2(470, 40, 130, 70), "sf_kwik"], [Rect2(460, 240, 150, 70), "sf_fork_pub"],
	[Rect2(40, 240, 120, 70), "sf_hoa"], [Rect2(205, 108, 60, 40), "sf_seen"],
	[Rect2(400, 40, 55, 50), "sf_iron"], [Rect2(350, 232, 80, 52), "sf_club"],
	[Rect2(200, 228, 58, 42), "sf_mining"], [Rect2(340, 6, 52, 80), "sf_plaza_pub"],
	[Rect2(345, 306, 76, 38), "sf_walgrumps_pub"], [Rect2(176, 290, 110, 48), "sf_hywhee"],
	[Rect2(392, 100, 72, 40), "sf_plazmart"],
]
const SPAWN: = Vector2(96, 128)    # just off Duff's porch steps

var meta: Dictionary
var mode: = "dusk"
var player: CharacterBody3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var shake: = 0.0
var shake_dir: = Vector3.ZERO
var hitstop: = 0.0
var frame: = 0
var demo: = false
var shots: = false

static func to3(p: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(p.x * U, h, p.y * U)

func _ready() -> void:
	meta = JSON.parse_string(FileAccess.get_file_as_string("res://art/meta.json"))
	for a in OS.get_cmdline_user_args():
		if a in ["dusk", "day", "night"]:
			mode = a
		demo = demo or a == "demo"
		shots = shots or a == "shots"
	_setup_input()
	_build_env()
	_build_ground()
	for b in BUILDINGS:
		_building(b[0], b[1])
	_build_dressing()
	_build_lights()
	_build_ambient()
	player = Duff3D.new()
	player.position = to3(SPAWN)
	add_child(player)
	player.bonked.connect(_on_bonk)
	for i in 3:
		var r: = Raccoon3D.new()
		r.home = to3([Vector2(96, 196), Vector2(186, 178), Vector2(300, 184)][i])
		r.position = r.home
		add_child(r)
		r.add_to_group("critters")
	cam = Camera3D.new()
	cam.fov = 32.0
	add_child(cam)
	_snap_cam()
	_build_tiltshift()

func art(n: String) -> Texture2D:
	return load("res://art/%s.png" % n)

## A painted cutout standing on the ground. `contact` = its 2D origin point (bottom centre for props).
func card(n: String, contact: Vector2, sc: float = 1.0, lift: = 0.0) -> Sprite3D:
	var inf: Dictionary = meta[n]
	var s: = Sprite3D.new()
	s.texture = art(n)
	s.centered = false
	var org: Array = inf.get("origin", [inf["w"] / 2, inf["h"]])
	s.offset = Vector2(-float(org[0]), -(float(inf["h"]) - float(org[1])))
	s.pixel_size = U / float(inf.get("s", 1)) * sc
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.shaded = true
	s.double_sided = true
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	s.position = to3(contact, lift)
	add_child(s)
	return s

func _building(r: Rect2, n: String) -> void:
	var inf: Dictionary = meta[n]
	var k: = float(inf["s"])
	var org: Array = inf["origin"]
	# 2D draws the art's top-left at r.position - origin/k; its bottom edge is where the facade meets the ground
	var bottom_y: = r.position.y - float(org[1]) / k + float(inf["h"]) / k
	var s: = card(n, Vector2(r.position.x, bottom_y))
	s.offset = Vector2(0, 0)
	# a box behind the facade gives the building real depth: it blocks Duff and throws a proper shadow
	var body: = StaticBody3D.new()
	var cs: = CollisionShape3D.new()
	var box: = BoxShape3D.new()
	box.size = Vector3(r.size.x * U, 3.0, r.size.y * U)
	cs.shape = box
	body.add_child(cs)
	body.position = to3(r.get_center(), 1.5)
	add_child(body)
	var mass: = MeshInstance3D.new()
	var bm: = BoxMesh.new()
	var h: = float(inf["h"]) / k * U * 0.6
	bm.size = Vector3(r.size.x * U * 0.96, h, r.size.y * U * 0.6)
	mass.mesh = bm
	mass.position = Vector3((r.position.x + r.size.x * 0.5) * U, h * 0.5, (bottom_y - r.size.y * 0.35) * U)
	mass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(mass)

func _build_ground() -> void:
	var tex: = art("ground_painted")
	var size2: = Vector2(tex.get_width(), tex.get_height()) / 2.0      # 2 art px per world unit
	var origin2: = Vector2(-10, -32) / 2.0                             # data/town_ground.txt origin
	var m: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = size2 * U
	m.mesh = pm
	var mat: = StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.roughness = 1.0
	m.material_override = mat
	m.position = to3(origin2 + size2 / 2.0)
	add_child(m)
	# world edge: big dark lawn so the camera never sees void
	var under: = MeshInstance3D.new()
	var up: = PlaneMesh.new()
	up.size = Vector2(400, 400)
	under.mesh = up
	var um: = StandardMaterial3D.new()
	um.albedo_color = Color("#3d5a2a")
	under.material_override = um
	under.position = to3(origin2 + size2 / 2.0, -0.02)
	add_child(under)
	# floor collider
	var floor: = StaticBody3D.new()
	var cs: = CollisionShape3D.new()
	cs.shape = WorldBoundaryShape3D.new()
	floor.add_child(cs)
	add_child(floor)
	# map edge walls
	var bounds: = Rect2(origin2, size2)
	for w in [[Vector2(bounds.position.x, bounds.get_center().y), Vector3(0.2, 4, size2.y * U)],
			[Vector2(bounds.end.x, bounds.get_center().y), Vector3(0.2, 4, size2.y * U)],
			[Vector2(bounds.get_center().x, bounds.position.y + 20), Vector3(size2.x * U, 4, 0.2)],
			[Vector2(bounds.get_center().x, bounds.end.y), Vector3(size2.x * U, 4, 0.2)]]:
		var b: = StaticBody3D.new()
		var c: = CollisionShape3D.new()
		var sh: = BoxShape3D.new()
		sh.size = w[1]
		c.shape = sh
		b.add_child(c)
		b.position = to3(w[0], 2.0)
		add_child(b)

func _build_dressing() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://town_dressing.json"))
	for o in d["objects"]:
		var n: = str(o["a"])
		var p: = Vector2(o["p"][0], o["p"][1])
		if "leaves" in n:
			var leaf: = card(n, p, float(o.get("s", 1.0)))
			leaf.rotation_degrees.x = -90.0       # lies flat on the grass
			leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			leaf.position.y = 0.01
			continue
		var s: = card(n, p, float(o.get("s", 1.0)))
		if o.get("tree", false):
			s.set_meta("sway", randf() * TAU)
			s.add_to_group("sway")
		if o.has("wall") or o.get("tree", false):
			var w: Array = o.get("wall", [8, 4])
			var b: = StaticBody3D.new()
			var c: = CollisionShape3D.new()
			var sh: = BoxShape3D.new()
			sh.size = Vector3(float(w[0]) * U, 2.0, float(w[1]) * U * 2.0)
			c.shape = sh
			b.add_child(c)
			b.position = to3(p, 1.0)
			add_child(b)
	for f in d["fences"]:
		for i in int(f["n"]):
			card("sd_%s_straight" % f["kind"], Vector2(f["p"][0] + i * 39.0, f["p"][1]))

func _build_env() -> void:
	var we: = WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_density = 0.004
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.06
	match mode:
		"day":
			env.background_color = Color("#9cc8e8")
			env.ambient_light_color = Color("#a8b8d8")
			env.ambient_light_energy = 0.35
			env.glow_intensity = 0.35
			env.adjustment_contrast = 1.12
			env.fog_light_color = Color("#c8dcef")
			env.fog_density = 0.0015
		"night":
			env.background_color = Color("#0d1230")
			env.ambient_light_color = Color("#3a4a8a")
			env.ambient_light_energy = 0.35
			env.fog_light_color = Color("#1a2250")
		_:
			env.background_color = Color("#e89a6a")
			env.ambient_light_color = Color("#8a86b8")
			env.ambient_light_energy = 0.6
			env.fog_light_color = Color("#c89a90")
	we.environment = env
	add_child(we)

func _build_lights() -> void:
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 60.0
	match mode:
		"day":
			sun.rotation_degrees = Vector3(-58, -35, 0)
			sun.light_color = Color("#fff4e0")
			sun.light_energy = 1.0
		"night":
			sun.rotation_degrees = Vector3(-50, 40, 0)
			sun.light_color = Color("#8aa0ff")
			sun.light_energy = 0.25
		_:
			sun.rotation_degrees = Vector3(-34, -48, 0)    # low golden-hour sun, long shadows
			sun.light_color = Color("#ffc490")
			sun.light_energy = 1.2
	add_child(sun)
	var lamp_e: = 0.0 if mode == "day" else (2.2 if mode == "night" else 1.2)
	# porch lantern on Duff's house + warm pools at each storefront door
	_lamp(Vector2(103, 103), 3.0, Color("#ffb45a"), lamp_e * 1.3, 7.0)
	for b in BUILDINGS:
		if b[1] == "sf_home":
			continue
		var r: Rect2 = b[0]
		_lamp(Vector2(r.get_center().x, r.end.y + 6), 2.2, Color("#ffc27a"), lamp_e, 6.0)
	# street lamps along the main road
	for x in [60, 300, 540]:
		_lamp(Vector2(x, 200), 4.5, Color("#ffd9a0"), lamp_e, 10.0)

func _lamp(p: Vector2, h: float, c: Color, e: float, rng: float) -> void:
	if e <= 0.0:
		return
	var l: = OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = rng
	l.omni_attenuation = 1.6
	l.position = to3(p, h)
	add_child(l)

## Ambient life: drifting maple leaves + dust/fireflies (CPU particles: the web renderer has no GPU particles 3D).
func _build_ambient() -> void:
	var leaves: = CPUParticles3D.new()
	leaves.amount = 60
	leaves.lifetime = 9.0
	leaves.preprocess = 9.0
	leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	leaves.emission_box_extents = Vector3(34, 0.5, 19)
	leaves.position = Vector3(32, 7, 18)
	leaves.direction = Vector3(1, -0.4, 0.3)
	leaves.spread = 25.0
	leaves.gravity = Vector3(0.4, -0.5, 0)
	leaves.initial_velocity_min = 0.3
	leaves.initial_velocity_max = 0.8
	leaves.angular_velocity_min = -120
	leaves.angular_velocity_max = 120
	var qm: = QuadMesh.new()
	qm.size = Vector2(0.18, 0.12)
	var lm: = StandardMaterial3D.new()
	lm.albedo_color = Color("#e0602a")
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	lm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = lm
	leaves.mesh = qm
	add_child(leaves)
	if mode != "day" and not "pose" in OS.get_cmdline_user_args():
		var ff: = CPUParticles3D.new()
		ff.amount = 50
		ff.lifetime = 5.0
		ff.preprocess = 5.0
		ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		ff.emission_box_extents = Vector3(30, 1.0, 17)
		ff.position = Vector3(32, 1.2, 18)
		ff.gravity = Vector3.ZERO
		ff.direction = Vector3(0, 1, 0)
		ff.spread = 180.0
		ff.initial_velocity_min = 0.05
		ff.initial_velocity_max = 0.25
		var sm: = SphereMesh.new()
		sm.radius = 0.04
		sm.height = 0.08
		sm.radial_segments = 6
		sm.rings = 3
		var fm: = StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.albedo_color = Color(1.0, 0.85, 0.45) * 3.0
		sm.material = fm
		ff.mesh = sm
		add_child(ff)

## Tilt-shift: soft blur at the top and bottom of the frame, the HD-2D "diorama" look.
func _build_tiltshift() -> void:
	var cl: = CanvasLayer.new()
	var rect: = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh: = Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float sharpen = 0.6;
uniform float blur = 1.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	float band = (smoothstep(0.30, 0.0, uv.y) + smoothstep(0.72, 1.0, uv.y)) * blur;
	float lod = band * 2.6;
	vec3 c = textureLod(screen_tex, uv, lod).rgb;
	// sharpen the in-focus band (unsharp mask): crisper sprite edges without touching the art
	vec2 px = 1.0 / vec2(textureSize(screen_tex, 0));
	vec3 nb = textureLod(screen_tex, uv + vec2(px.x, 0.0), 0.0).rgb + textureLod(screen_tex, uv - vec2(px.x, 0.0), 0.0).rgb
		+ textureLod(screen_tex, uv + vec2(0.0, px.y), 0.0).rgb + textureLod(screen_tex, uv - vec2(0.0, px.y), 0.0).rgb;
	c = mix(c, clamp(c + (c - nb * 0.25) * sharpen, 0.0, 1.0), 1.0 - clamp(band * 3.0, 0.0, 1.0));
	float vig = smoothstep(1.15, 0.35, length((uv - 0.5) * vec2(1.4, 1.0)));
	COLOR = vec4(c * mix(0.78, 1.0, vig), 1.0);
}
"""
	var mat: = ShaderMaterial.new()
	mat.shader = sh
	if "pose" in OS.get_cmdline_user_args():
		mat.set_shader_parameter("blur", 0.35)
	rect.material = mat
	cl.add_child(rect)
	add_child(cl)

func _setup_input() -> void:
	var map: = {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "attack": [KEY_SPACE, KEY_J],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for k in map[action]:
				var ev: = InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(action, ev)

func _cam_target() -> Vector3:
	return player.position + Vector3(0, 0.8, 0)

## Fixed-yaw follow camera, pitched ~38 degrees like the 2D game's 3/4 view.
const CAM_OFF: = Vector3(0, 12.5, 16.0)

func _snap_cam() -> void:
	cam.position = _cam_target() + CAM_OFF
	cam.look_at(_cam_target())

func _on_bonk(at: Vector3, dir: Vector3) -> void:
	var hit: = false
	for c in get_tree().get_nodes_in_group("critters"):
		if c.position.distance_to(at) < 1.6 and c.has_method("bonk") and c.bonk(dir):
			hit = true
			_spark(c.position + Vector3(0, 0.6, 0))
	if hit:
		hitstop = 0.09
		shake = 0.35
		shake_dir = dir

func _spark(p: Vector3) -> void:
	var s: = CPUParticles3D.new()
	s.one_shot = true
	s.emitting = true
	s.amount = 24
	s.lifetime = 0.45
	s.explosiveness = 1.0
	s.spread = 180.0
	s.initial_velocity_min = 3.0
	s.initial_velocity_max = 6.0
	s.gravity = Vector3(0, -9, 0)
	s.scale_amount_min = 0.6
	s.scale_amount_max = 1.2
	var bm: = BoxMesh.new()
	bm.size = Vector3(0.08, 0.08, 0.08)
	var m: = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.9, 0.5) * 4.0
	bm.material = m
	s.mesh = bm
	s.position = p
	add_child(s)
	get_tree().create_timer(1.0).timeout.connect(s.queue_free)

func _process(delta: float) -> void:
	frame += 1
	if hitstop > 0.0:
		hitstop -= delta
		Engine.time_scale = 0.05 if hitstop > 0.0 else 1.0
	var t: = Time.get_ticks_msec() / 1000.0
	for s in get_tree().get_nodes_in_group("sway"):
		s.rotation_degrees.z = sin(t * 1.3 + float(s.get_meta("sway"))) * 0.9
	if "pose" in OS.get_cmdline_user_args() and frame >= 20:
		_pose_shots()
		return
	var want: = _cam_target() + CAM_OFF
	cam.position = cam.position.lerp(want, clampf(delta * 5.0, 0.0, 1.0))
	cam.look_at(cam.position - CAM_OFF)
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 1.6)
		cam.position += (shake_dir * 0.6 + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.4) * shake * 0.35
	if demo:
		_demo_inputs()
	elif "pose" in OS.get_cmdline_user_args():
		_pose_shots()

## Scripted take: walk off the porch, down the walk, bonk the raccoons, stroll the street.
func _demo_inputs() -> void:
	var f: = frame
	_press("move_down", (f > 20 and f < 50) or (f > 170 and f < 178))
	_press("move_right", (f > 70 and f < 138) or (f > 180 and f < 250))
	_press("move_up", f > 250 and f < 282)
	_press("attack", f in [54, 55, 141, 142])
	if shots and f in [12, 58, 146, 220, 282]:
		get_viewport().get_texture().get_image().save_png("/tmp/qa3d/%s_%03d.png" % [mode, f])
	if f == 100 and "stats" in OS.get_cmdline_user_args():
		print("STATS draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " prims=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), " vram_MB=", Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)
	if f > 310:
		get_tree().quit()

## Close-ups of Duff on his porch path: the four facings, the bonk, then a low hero angle.
const POSES: = [[0, "front"], [8, "right"], [12, "left"], [4, "back"], [3, "bonk"], [1, "walk"]]

func _pose_shots() -> void:
	var i: = (frame - 20) / 8
	if frame < 20 or i >= POSES.size() + 1:
		if frame > 20 + 8 * (POSES.size() + 1):
			get_tree().quit()
		return
	var hero: = i == POSES.size()
	player.posed = 0 if hero else int(POSES[i][0])
	var look: = player.position + Vector3(0, 1.0, 0)
	cam.position = look + (Vector3(-2.2, 0.5, 4.2) if hero else Vector3(0, 1.8, 5.6))
	cam.look_at(look)
	if (frame - 20) % 8 == 7:
		get_viewport().get_texture().get_image().save_png("/tmp/qa3d/pose_%s_%s.png" % [mode, "hero" if hero else POSES[i][1]])

func _press(a: String, on: bool) -> void:
	if on:
		Input.action_press(a)
	elif Input.is_action_pressed(a):
		Input.action_release(a)
