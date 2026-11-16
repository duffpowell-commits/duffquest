extends SubViewportContainer
## 3D town view (Settings > "3D view"). The game itself stays 2D: main.gd owns movement, walls, combat, saves.
## This node only READS the 2D world every frame and draws it as an HD-2D diorama: painted cards standing on a
## ground plane, a real sun with shadows, an orbit-free follow camera. 2D (x, y) maps onto the ground as
## (x * U, 0, y * U).
## game.gd creates it only when the engine has 3D (ClassDB.class_exists("Node3D")) and loads it with load(),
## never preload: the slim 2D web engine must never parse this file.
## Step 2 of spike3d/PLAN_3D.md: ground, sun + sky from the clock, Duff. Step 3 adds the rest of the town.

const Art: = preload("res://scripts/art.gd")
const Ground: = preload("res://scripts/ground.gd")
const HdPresentation: = preload("res://scripts/hd_presentation.gd")
const AudioScript: = preload("res://scripts/audio.gd")

const U: = 0.1                              # metres per 2D world unit
const CAM_OFF: = Vector3(0, 12.5, 16.0)     # fixed-yaw follow camera, pitched ~38 degrees like the 2D 3/4 view
const CAM_FOV: = 34.0
const FEET: = Vector2(0, 11)                # player.gd draws Duff's feet 11 units below his node

var main: Node                              # main.gd (the 2D world)
var vp2d: SubViewport                       # game.gd's 640x360 world viewport (made transparent while 3D is live)
var vp: SubViewport
var world: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var ground: MeshInstance3D
var duff: Sprite3D
var live: = false
var _ground_tex: Texture2D

static func to3(p: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(p.x * U, h, p.y * U)

func _ready() -> void:
	name = "View3D"
	stretch = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	_build_env()
	_build_ground()
	_build_sun()
	duff = _card()
	world.add_child(duff)
	cam = Camera3D.new()
	cam.fov = CAM_FOV
	world.add_child(cam)
	if main != null:
		main.view3d = self

## The 3D view is live outdoors when the setting is on. Opaque full-screen menus pause it (like the 2D world).
func wanted() -> bool:
	var a: Node = AudioScript.inst
	return main != null and a != null and bool(a.get("view3d")) and str(main.location) == "outside"

func _process(_d: float) -> void:
	var on: = wanted()
	if on != live:
		_set_live(on)
	if not live:
		return
	var covered: bool = main.world_covered()
	var mode: = SubViewport.UPDATE_DISABLED if covered else SubViewport.UPDATE_ALWAYS
	if vp.render_target_update_mode != mode:
		vp.render_target_update_mode = mode
	if covered:
		return
	_sync_sky()
	_sync_duff()
	_sync_cam()

func _set_live(on: bool) -> void:
	live = on
	visible = on
	main.view3d_on = on
	if vp2d != null:
		vp2d.transparent_bg = on
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	if on:
		_sync_duff()
		cam.position = _cam_target() + CAM_OFF
		cam.look_at(_cam_target())

## Last 3D frame (main.gd blurs it behind menu cards).
func snapshot() -> Image:
	var t: = vp.get_texture()
	return t.get_image() if t != null else null

# --- building blocks ---------------------------------------------------------------------------------------

func _build_env() -> void:
	var we: = WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_density = 0.003
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.06
	we.environment = env
	world.add_child(we)

func _build_ground() -> void:
	ground = MeshInstance3D.new()
	ground.name = "Ground"
	var mat: = StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.roughness = 1.0
	ground.material_override = mat
	world.add_child(ground)
	_refresh_ground()
	# beyond the map: a dark lawn so the camera never sees void
	var under: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = Vector2(400, 400)
	under.mesh = pm
	var um: = StandardMaterial3D.new()
	um.albedo_color = Color("#3d5a2a")
	um.roughness = 1.0
	under.material_override = um
	under.position = to3(Vector2(320, 180), -0.02)
	world.add_child(under)

## Same texture and placement as main.gd _draw_outside: Rect2(origin / 2, size / 2) in world units.
## Re-checked every frame because on the web the painted street arrives later with a pack (Ground.clear_cache()).
func _refresh_ground() -> void:
	var gt: = Ground.texture()
	if gt == null or gt == _ground_tex:
		return
	_ground_tex = gt
	var r: = Rect2(Ground.origin() / 2.0, gt.get_size() / 2.0)
	var pm: = PlaneMesh.new()
	pm.size = r.size * U
	ground.mesh = pm
	(ground.material_override as StandardMaterial3D).albedo_texture = gt
	ground.position = to3(r.get_center())

func _build_sun() -> void:
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 50.0
	world.add_child(sun)

## A painted cutout that stands on the ground and casts a real shadow.
func _card() -> Sprite3D:
	var s: = Sprite3D.new()
	s.centered = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.shaded = true
	s.double_sided = true
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return s

## Point a card at one cell of a 2D sheet (cell/origin/density from art_manifest.gd), feet on `foot`.
func _show_cell(s: Sprite3D, sheet: String, col: int, row: int, foot: Vector2) -> void:
	var tx: = Art.tex(sheet)
	s.visible = tx != null
	if tx == null:
		return
	var inf: = Art.info(sheet)
	var cell: Array = inf.get("cell", [tx.get_width(), tx.get_height()])
	var org: Array = inf.get("origin", [float(cell[0]) / 2.0, cell[1]])
	s.texture = tx
	s.region_enabled = true
	s.region_rect = Rect2(col * float(cell[0]), row * float(cell[1]), float(cell[0]), float(cell[1]))
	s.offset = Vector2(-float(org[0]), -(float(cell[1]) - float(org[1])))
	s.pixel_size = U / Art.density(inf)
	s.position = to3(foot)

# --- per-frame mirroring of the 2D world ------------------------------------------------------------------

func _sync_duff() -> void:
	var p: Node2D = main.player
	if p == null:
		return
	var swinging: bool = float(p.swing_t) > 0.0
	var col: = 3 if swinging else Art.walk_col(float(p.anim_t), bool(p.moving))
	_show_cell(duff, p.sheet_name(), col, Art.row_for(p.facing), p.position + FEET)
	var hurt: bool = float(p.hurt_t) > 0.0 and int(float(p.hurt_t) * 20.0) % 2 == 0
	duff.modulate = Color(1, 0.55, 0.55) if hurt else Color.WHITE

## Sun, ambient and sky follow the same clock keys as the 2D grade (hd_presentation.gd SKY).
func _sync_sky() -> void:
	_refresh_ground()
	var minute: = float(main.clock)
	var sky: = HdPresentation.sky_at(minute)
	var dark: = HdPresentation.darkness(minute)
	# sun arcs east -> west across the day (06:00 .. 20:00); at night a dim blue moon holds a high angle
	var day_f: = clampf((fmod(minute, 1440.0) - 360.0) / 840.0, 0.0, 1.0)
	var elev: = lerpf(-62.0, -30.0, dark) if dark < 0.95 else -55.0
	elev = lerpf(elev, -24.0, clampf(absf(day_f - 0.5) * 2.0 - 0.6, 0.0, 1.0) * (1.0 - dark))   # low early/late
	sun.rotation_degrees = Vector3(elev, lerpf(55.0, -55.0, day_f), 0.0)
	sun.light_color = Color(1.0, 0.97, 0.9).lerp(sky, 0.7) if dark < 0.5 else Color("#8aa0ff")
	# warm = golden hour / dusk (the 2D grade loses green + blue), dark = night
	var warm: = clampf((1.0 - sky.b) * 2.5, 0.0, 1.0) * (1.0 - dark)
	sun.light_energy = lerpf(0.82, 0.28, dark) + 0.25 * warm
	env.ambient_light_color = sky.lerp(Color("#8a86b8"), 0.4)
	env.ambient_light_energy = lerpf(0.3, 0.6, maxf(warm, dark * 0.6))
	env.glow_intensity = lerpf(0.3, 0.9, maxf(warm, dark))
	env.adjustment_contrast = lerpf(1.14, 1.06, warm)
	env.background_color = Color("#9cc8e8").lerp(sky, 0.5).darkened(dark * 0.6)
	env.fog_light_color = Color("#c8dcef").lerp(sky, 0.6).darkened(dark * 0.5)
	env.fog_density = lerpf(0.0012, 0.004, maxf(warm, dark))

func _cam_target() -> Vector3:
	var p: Node2D = main.player
	var c: = p.position if p != null else Vector2(320, 180)
	# keep the frame inside the map the way the 2D camera's limits do (a little looser: the view is tilted)
	c.x = clampf(c.x, 110.0, 530.0)
	c.y = clampf(c.y, 95.0, 330.0)
	return to3(c, 0.8)

func _sync_cam() -> void:
	var want: = _cam_target() + CAM_OFF
	cam.position = cam.position.lerp(want, clampf(get_process_delta_time() * 6.0, 0.0, 1.0))
	cam.look_at(cam.position - CAM_OFF)
