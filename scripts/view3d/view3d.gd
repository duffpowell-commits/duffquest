extends SubViewportContainer
## 3D town view (Settings > "3D view"). The game itself stays 2D: main.gd owns movement, walls, combat, saves.
## This node only READS the 2D world every frame and draws it as an HD-2D diorama: painted cards standing on a
## ground plane, a real sun with shadows, an orbit-free follow camera. 2D (x, y) maps onto the ground as
## (x * U, 0, y * U).
## game.gd creates it only when the engine has 3D (ClassDB.class_exists("Node3D")) and loads it with load(),
## never preload: the slim 2D web engine must never parse this file.
## Static town (storefronts, street dressing, lamps) is built once from main.gd's data. Everything that moves is
## mirrored from the 2D draw calls themselves: art.gd writes down each sheet frame / image an actor draws while the
## view is live (Art.rec), and every one becomes a card here. New enemies, NPCs and props need no 3D code.

const Art: = preload("res://scripts/art.gd")
const Ground: = preload("res://scripts/ground.gd")
const HdPresentation: = preload("res://scripts/hd_presentation.gd")
const AudioScript: = preload("res://scripts/audio.gd")
const TownLife: = preload("res://scripts/town_life.gd")

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
var live: = false
var pool: Array = []                        # Sprite3D cards for captured actor draws, reused every frame
## Top-down vehicle art (town vans, the HONK delivery truck): stood up as a card it read as a van tipped on its side
## (Duff's phone test, Nov 17). In 3D it swaps for a standing van drawn for this camera (tools/import_vans.py):
## the side view for vans driving across (mirrored when going left), the front for vans coming toward the camera,
## the back for vans driving away.
const VANS: = ["truck_h", "truck_v"]
var buildings: Array = []                   # [building dict, card]
var lamps: Array = []                       # [OmniLight3D, base energy]
var marks: Array = []                       # Label3D pool: quest/story markers + house names
var labels_root: Node3D
var town: Node3D                            # the outdoor map (ground, storefronts, props, lamps); hidden in rooms
## Rooms (home, gala, arenas): main draws one painted floor image per room; it lies flat and the rest stands.
## Where each painted room's back wall meets its floor (fraction of the image height). The band above stands
## up as a wall card, the rest lies flat as the floor.
const WALL: = {"arena_alley": 0.29, "arena_crypto": 0.33, "arena_djvape": 0.31, "arena_ghoster": 0.31,
	"arena_gymbro": 0.35, "arena_waffle": 0.52, "arena_willnot": 0.37, "gala": 0.26, "home_interior": 0.19}
var floor_card: Sprite3D
var wall_card: Sprite3D
var room_dark: Node3D                        # dark box around a room so the camera never sees void
var caption: Label3D

## The 3D view gets Duff's HD sheet (2048, same 4x4 layout and world size as the 2x one). Built only by
## tools/duff_hd3d/build_duff_hd.sh: plain black sleeves (test_daily checks), his fox on the LEFT of his neck.
const HD: = {"duff_home": {"path": "res://assets/art3d/duff_home_hd3d.png", "cell": [512, 512], "origin": [256, 480], "s": 16.0},
	# his round shades, fitted to the HD faces (tools/duff_hd3d/shades_hd.py); only used over the HD sheet
	"duff_shades_home": {"path": "res://assets/art3d/duff_shades_home_hd3d.png", "cell": [512, 512], "origin": [256, 480], "s": 16.0}}
const HD_OVER: = {"duff_shades_home": "duff_home"}   # overlay -> the sheet it was fitted to
const NO_3D: = ["map_objects"]               # full-map overlays drawn by main (the old bus-stop sign layer)
var _hd_tex: = {}
var true3d: Node3D                           # #true3d test slice: real models for Duff + porch pirates (true3d.gd)
var britt_head: = Vector3.INF                # top of {coworker}'s card this frame (her "$" sits on it)
var static_art: = {}                         # art names _build_town already stands up (main's own draws of them are skipped)
var cam_base: = Vector3.ZERO                 # follow-camera position before the shake offset
var _ground_tex: Texture2D
var under_mat: StandardMaterial3D           # the plain lawn past the map edge (tinted to the map's own border)
## The 3D frame renders at the screen's real pixel size (the 2D game is 640x360 scaled up), times this.
## 1.0 = native; Auto Lite drops it (step 6). Env DQ_3D_LOWRES=1 forces the old 640x360 render (renders/compare).
var res_scale: = 1.0
## Lite graphics (perf_guard.gd, same switch as the 2D lite): render at 1.5x the logical size instead of native,
## no MSAA, no sun shadows, no glow. Full graphics still caps the render at 3x (1920x1080): a phone's extra pixels
## past that cost fill rate for detail the 4 px/unit art doesn't have.
var low: = false
const MAX_K: = 3.0
const LOW_K: = 1.5

## Tilt-shift diorama blur (shaders/tilt_shift.gdshader) on this container: only the 3D frame, off in Lite.
var tilt_mat: ShaderMaterial

## Depth pass (Nov 19, Duff: "slightly more of a three-dimensional feel"). All of it is off in Lite.
## Camera sway: the follow camera turns a few degrees round Duff as he walks off centre (and leads his walk a
## little), so near things slide past far ones and the box sides of the buildings show. Standing cards turn with
## it, so nobody goes paper-thin. Fights open with a short push-in.
const YAW_MAX: = 7.0            # degrees at the map's (or room's) edge
const YAW_ROOM: = 4.0
const YAW_LEAD: = 2.0           # extra degrees toward where Duff is walking
var yaw: = 0.0                  # current camera yaw, degrees (smoothed)
var _last_p: = Vector2.INF
var _room_key: = ""
var _push: = 0.0                # 1 at a fight's start, eases to 0
const PUSH_T: = 1.1
## Round cut-outs: characters, trees and street props get shaders/card3d.gdshader (silhouette = height map, so
## the sun and lamps wrap round them; trees bend in the wind). Facades stay flat painted cards.
var card_shader: Shader = preload("res://shaders/card3d.gdshader")
var ao_shader: Shader = preload("res://shaders/ao_blob.gdshader")
var ao_nodes: Array = []        # contact shadows (buildings, props, room walls): hidden in Lite
var round_cards: Array = []     # static dressing cards with the round material: [Sprite3D, ShaderMaterial]
var wall_ao: MeshInstance3D

func set_low(on: bool) -> void:
	low = on
	material = null if low else tilt_mat
	vp.msaa_3d = Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	env.glow_enabled = not low
	for a in ao_nodes:
		(a as Node3D).visible = not low
	for e in round_cards:
		(e[0] as Sprite3D).material_override = null if low else e[1]
	if low:
		sun.shadow_enabled = false
	elif live:
		_sync_sky()
	_fit()

static func to3(p: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(p.x * U, h, p.y * U)

func _ready() -> void:
	name = "View3D"
	stretch = false   # sized by hand in _fit(): native pixels, not the 640x360 logical size
	tilt_mat = ShaderMaterial.new()
	tilt_mat.shader = preload("res://shaders/tilt_shift.gdshader")
	material = tilt_mat
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	town = Node3D.new()
	world.add_child(town)
	_build_env()
	_build_ground()
	_build_sun()
	_build_town()
	if main != null:
		_build_signs()
	labels_root = Node3D.new()
	world.add_child(labels_root)
	_build_room_parts()
	cam = Camera3D.new()
	cam.fov = CAM_FOV
	world.add_child(cam)
	if main != null:
		main.view3d = self

## The 3D view is live outdoors when the setting is on. Opaque full-screen menus pause it (like the 2D world).
func wanted() -> bool:
	var a: Node = AudioScript.inst
	if main == null or a == null or not bool(a.get("view3d")):
		return false
	if str(main.location) == "arena" and str(main.arena_id) == "waffle":
		return false   # the Waffle Haus shift is a station game drawn for the flat view (grill hot spots)
	return str(main.location) in ["outside", "home", "arena", "gala"]

## The room the player is in (zero rect outdoors).
func room() -> Rect2:
	match str(main.location):
		"home":
			return Rect2(main.INT_ORIGIN, main.INT_SIZE)
		"arena":
			return Rect2(main.ARENA_ORIGIN, main.ARENA_SIZE)
		"gala":
			return Rect2(main.GALA_ORIGIN, main.GALA_SIZE)
	return Rect2()

## main's painted room floors, laid flat instead of stood up.
func is_floor(name: String) -> bool:
	return name in ["home_interior", "gala"] or name.begins_with("arena_")

## Render the 3D view at native resolution: the SubViewport gets the real pixel size and this container is
## scaled back down to the 640x360 logical screen.
func _fit() -> void:
	var win: = Vector2(DisplayServer.window_get_size())
	var k: = minf(maxf(1.0, minf(win.x / 640.0, win.y / 360.0)), LOW_K if low else MAX_K) * res_scale
	if OS.get_environment("DQ_3D_LOWRES") == "1":
		k = 1.0
	var want: = Vector2i(roundi(640.0 * k), roundi(360.0 * k))
	if vp.size != want:
		vp.size = want
		size = Vector2(want)
		scale = Vector2.ONE * (640.0 / float(want.x))

func _process(_d: float) -> void:
	_fit()
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
	var in_room: = room().size != Vector2.ZERO
	town.visible = not in_room
	room_dark.visible = in_room
	if not in_room:
		floor_card.visible = false
		wall_card.visible = false
		wall_ao.visible = false
	_sync_sky()
	_sync_town()
	_sync_actors(_d)
	_sync_cam()
	_sync_labels()   # after the camera: house names clamp under the HUD in screen space
	_sync_overlay()

func _set_live(on: bool) -> void:
	live = on
	visible = on
	main.view3d_on = on
	Art.rec_on = on
	if not on:
		Art.rec.clear()
	if vp2d != null:
		vp2d.transparent_bg = on
	var c2: Camera2D = main.get("cam")
	if c2 != null:
		c2.enabled = not on   # View3D drives the world canvas transform while live (_sync_overlay)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	_redraw_world(main)   # everything draws once more: on = the capture sees it; off = static props that never
	# redraw (dressing_front items) paint for real again instead of keeping their recorded-only (empty) frame
	if on:
		cam_base = _cam_target() + _cam_off()
		cam.position = cam_base
		cam.look_at(_cam_target())

func _build_room_parts() -> void:
	floor_card = _card()
	floor_card.rotation_degrees.x = -90.0
	floor_card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	floor_card.region_enabled = true
	floor_card.double_sided = false
	world.add_child(floor_card)
	wall_card = _card()
	wall_card.region_enabled = true
	wall_card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(wall_card)
	room_dark = Node3D.new()
	world.add_child(room_dark)
	var m: = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("#120e16")
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 2:   # under the floor, and a backdrop behind the wall
		var q: = MeshInstance3D.new()
		var pm: = PlaneMesh.new()
		pm.size = Vector2(300, 300)
		q.mesh = pm
		q.material_override = m
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if i == 1:
			q.rotation_degrees.x = 90.0
		q.set_meta("i", i)
		room_dark.add_child(q)
	wall_ao = _ao(world, Vector3.ZERO, Vector2(1, 0.01), 1.4, 0.42)
	caption = Label3D.new()
	caption.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	caption.outline_size = 8
	caption.font_size = 40
	caption.pixel_size = 0.012
	caption.modulate = Color.WHITE
	caption.outline_modulate = Color(0, 0, 0, 0.85)
	caption.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(caption)

## A room's painted floor image: the back band stands up as the wall, the rest lies on the ground.
func _place_room(name: String, tx: Texture2D, inf: Dictionary, pos: Vector2, isc: float, dens: float) -> void:
	var org: Array = inf.get("origin", [0, 0])
	var w: = float(tx.get_width())
	var h: = float(tx.get_height())
	var band: = roundf(h * float(WALL.get(name, 0.0)))
	var px: = U / dens * isc
	var top_left: = pos - Vector2(float(org[0]), float(org[1])) * isc / dens
	var base: = top_left + Vector2(0, band * isc / dens)   # where the wall meets the floor
	floor_card.texture = tx
	floor_card.pixel_size = px
	floor_card.region_rect = Rect2(0, band, w, h - band)
	floor_card.offset = Vector2(0, -(h - band))
	floor_card.position = to3(base, 0.0)
	floor_card.visible = true
	wall_card.visible = band > 0.0
	if band > 0.0:
		wall_card.texture = tx
		wall_card.pixel_size = px
		wall_card.region_rect = Rect2(0, 0, w, band)
		wall_card.offset = Vector2.ZERO
		wall_card.position = to3(base, 0.0)
	# contact shadow where the back wall meets the floor
	var ww: = w * isc / dens * U
	(wall_ao.material_override as ShaderMaterial).set_shader_parameter("extent", Vector2(ww * 0.5, 0.01))
	(wall_ao.mesh as PlaneMesh).size = Vector2(ww + 2.8, 2.82)
	wall_ao.position = to3(base + Vector2(w * isc / dens * 0.5, 0), 0.006)
	wall_ao.visible = band > 0.0 and not low
	for q in room_dark.get_children():
		if int(q.get_meta("i")) == 0:
			q.position = to3(base, -0.02)
		else:
			q.position = to3(base, 0.0) + Vector3(0, 0, -0.05)
	caption.visible = not main.arena_caption_3d.is_empty()
	if caption.visible:
		caption.text = str(main.arena_caption_3d[0])
		caption.modulate = main.arena_caption_3d[1]
		var top: = band * isc / dens * U
		caption.position = to3(base + Vector2(w * isc / dens * 0.5, 0), top * 0.86) + Vector3(0, 0, 0.06)

## Last 3D frame (main.gd blurs it behind menu cards).
func snapshot() -> Image:
	var t: = vp.get_texture()
	if t == null:
		return null
	var img: = t.get_image()
	if img != null and img.get_width() != 640:
		img.resize(640, 360, Image.INTERPOLATE_BILINEAR)   # main.gd's veil blur expects the logical size
	return img

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
	town.add_child(ground)
	# beyond the map: a dark lawn so the camera never sees void
	var under: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = Vector2(400, 400)
	under.mesh = pm
	var um: = StandardMaterial3D.new()
	um.albedo_color = Color("#3d5a2a")
	um.roughness = 1.0
	under.material_override = um
	under_mat = um
	under.position = to3(Vector2(320, 180), -0.02)
	town.add_child(under)
	_refresh_ground()

## Same texture and placement as main.gd _draw_outside: Rect2(origin / 2, size / 2) in world units.
## Re-checked every frame because on the web the painted street arrives later with a pack (Ground.clear_cache()).
func _refresh_ground() -> void:
	var gt: = Ground.texture()
	if gt == null or gt == _ground_tex:
		return
	_ground_tex = gt
	var r: = Ground.world_rect()
	var pm: = PlaneMesh.new()
	pm.size = r.size * U
	ground.mesh = pm
	(ground.material_override as StandardMaterial3D).albedo_texture = gt
	ground.position = to3(r.get_center())
	# past the map the camera sees the plain plane under it (top corners, mostly); give it the average colour of
	# the painting's outer rows so the edge reads as more street, not a mint-green band
	var img: = gt.get_image()
	if img != null and under_mat != null:
		if img.is_compressed():
			img.decompress()
		var sum: = Color(0, 0, 0, 0)
		var n: = 0
		var w: = img.get_width()
		var h: = img.get_height()
		for x in range(0, w, 8):
			for y in [2, h - 3]:
				sum += img.get_pixel(x, y)
				n += 1
		for y in range(0, h, 8):
			for x in [2, w - 3]:
				sum += img.get_pixel(x, y)
				n += 1
		if n > 0:
			var c: = sum / float(n)
			under_mat.albedo_color = Color(c.r, c.g, c.b).darkened(0.08)

func _build_sun() -> void:
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.shadow_blur = 3.0
	sun.shadow_opacity = 0.62     # the painted ground already carries its own shade; keep cast shadows soft
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

## The round material for one card (shaders/card3d.gdshader). `dens` = art pixels per world unit: the bevel's
## width is set in world units, so HD art (16 px/unit) rolls off as wide as the 4 px/unit sheets.
func _round_mat(tx: Texture2D, dens: float, bevel: float = 1.0) -> ShaderMaterial:
	var m: = ShaderMaterial.new()
	m.shader = card_shader
	m.set_shader_parameter("tex", tx)
	m.set_shader_parameter("bevel", bevel)
	m.set_shader_parameter("spread", 3.0 * maxf(1.0, dens / 4.0))
	return m

## Pool cards: reuse each card's own material, point it at this frame's texture.
func _round_pool(s: Sprite3D, tx: Texture2D, dens: float, on: bool) -> void:
	if not on or low:
		s.material_override = null
		return
	var m: ShaderMaterial = s.get_meta("rm") if s.has_meta("rm") else null
	if m == null:
		m = _round_mat(tx, dens)
		s.set_meta("rm", m)
		s.set_meta("rm_tx", tx)
		s.set_meta("rm_d", dens)
	if s.get_meta("rm_tx") != tx:
		m.set_shader_parameter("tex", tx)
		s.set_meta("rm_tx", tx)
	if float(s.get_meta("rm_d")) != dens:
		m.set_shader_parameter("spread", 3.0 * maxf(1.0, dens / 4.0))
		s.set_meta("rm_d", dens)
	s.material_override = m

## A soft dark contact shadow on the ground: a rounded rect (half size `half`, metres) fading out over `fall`.
## Fakes the ambient occlusion the Compatibility renderer can't do: walls and props stop floating on the street.
func _ao(parent: Node3D, centre: Vector3, half: Vector2, fall: float, strength: float) -> MeshInstance3D:
	var q: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = (half + Vector2(fall, fall)) * 2.0
	q.mesh = pm
	var m: = ShaderMaterial.new()
	m.shader = ao_shader
	m.set_shader_parameter("extent", half)
	m.set_shader_parameter("fall", fall)
	m.set_shader_parameter("strength", strength)
	q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.position = centre
	parent.add_child(q)
	ao_nodes.append(q)
	q.visible = not low
	return q

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

func _redraw_world(n: Node) -> void:
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	for c in n.get_children():
		if not c is CanvasLayer:
			_redraw_world(c)

func _hd(name: String) -> Texture2D:
	if not _hd_tex.has(name):
		_hd_tex[name] = load(HD[name]["path"]) if ResourceLoader.exists(HD[name]["path"]) else null
	return _hd_tex[name]

## One card per captured draw. Sheet frames stand on their origin (the feet); plain images stand on their
## bottom edge (a carried package, a drone, the delivery truck), facing the camera like the 2D art did.
func _sync_actors(dt: float = 0.016) -> void:
	var used: = 0
	if true3d == null and AudioScript.inst != null and bool(AudioScript.inst.get("true3d")):
		true3d = load("res://scripts/view3d/true3d.gd").new()
		world.add_child(true3d)
	if true3d != null:
		true3d.begin_frame()
	var toward: = CAM_OFF.normalized() * 0.012
	britt_head = Vector3.INF
	for id in Art.rec.keys():
		var ci: = instance_from_id(id) as CanvasItem
		if ci == null or not is_instance_valid(ci):
			Art.rec.erase(id)
			continue
		if ci.get("it") != null or not ci.is_visible_in_tree() or (ci != main and not main.is_ancestor_of(ci)):
			continue
		var g: = ci.get_global_transform()
		var k: = 0
		var hd_drawn: = {}   # HD sheets this actor drew this frame (an overlay only goes HD over its HD sheet)
		for d in Art.rec[id]:
			var name: String = d[0]
			if name in NO_3D or (ci == main and static_art.has(name)):
				continue
			var full: Transform2D = g * (d[5] as Transform2D)
			var sc: = full.get_scale()
			var hd: = HD.has(name) and _hd(name) != null and (not HD_OVER.has(name) or hd_drawn.has(HD_OVER[name]))
			if hd:
				hd_drawn[name] = true
			if true3d != null and d[6] and true3d.claim(id, d, to3(full * (d[1] as Vector2)), sc.x < 0.0, dt, full.get_rotation()):
				continue   # drawn as a real model (#true3d test slice)
			var tx: Texture2D = _hd(name) if hd else Art.tex(name)
			if tx == null:
				continue
			var inf: Dictionary = HD[name] if hd else Art.info(name)
			var dens: = float(inf.get("s", 1.0))
			if dens <= 0.0:
				dens = 1.0
			if used >= pool.size():
				var c: = _card()
				world.add_child(c)
				pool.append(c)
			var s: Sprite3D = pool[used]
			used += 1  # (room floors never get here)
			s.visible = true
			var flat: = ci == main and is_floor(name)
			if flat:
				_place_room(name, tx, inf, d[1], float(d[3]) / 1000.0, dens)
				continue
			s.rotation_degrees.x = -90.0 if flat else 0.0
			s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if flat else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			s.texture = tx
			s.flip_h = sc.x < 0.0
			s.flip_v = false
			var mod: Color = d[4]
			s.modulate = mod
			s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD if mod.a > 0.95 else SpriteBase3D.ALPHA_CUT_DISABLED
			s.rotation_degrees.y = yaw   # face the swayed camera
			# round only solid sheet frames (people, critters); fading cards and plain images keep the flat material
			_round_pool(s, tx, dens, d[6] and mod.a > 0.95)
			var pos: Vector2 = d[1]
			if d[6]:   # sheet frame
				var cell: Array = inf.get("cell", [tx.get_width(), tx.get_height()])
				var org: Array = inf.get("origin", [0, 0])
				s.region_enabled = true
				s.region_rect = Rect2(int(d[2]) * float(cell[0]), int(d[3]) * float(cell[1]), float(cell[0]), float(cell[1]))
				s.offset = Vector2(-float(org[0]), -(float(cell[1]) - float(org[1])))
				s.pixel_size = U / dens * absf(sc.y)
				s.position = to3(full * pos) + toward * k
				if name == "ch_brittany":
					britt_head = s.position + Vector3(0, float(org[1] - 12) * s.pixel_size, 0)
			else:      # plain image, scale packed into the row slot
				var isc: = float(d[3]) / 1000.0
				var org2: Array = inf.get("origin", [0, 0])
				s.region_enabled = false
				s.offset = Vector2(-float(org2[0]), 0.0)
				s.pixel_size = U / dens * isc * absf(sc.y)
				if name in VANS and _van(s, name, full * pos, sc, toward * k):
					k += 1
					continue
				if flat:   # top-left corner on the floor, image runs south
					s.offset = Vector2(-float(org2[0]), -float(tx.get_height()) + float(org2[1]))
					s.position = to3(full * pos, 0.0)
				else:
					var bottom: = pos + Vector2(0, (float(tx.get_height()) - float(org2[1])) * isc / dens)
					s.position = to3(full * bottom) + toward * k
					if name == "amb_puff":   # roof steam: stand on the facade front, lifted by its 2D height above it
						var gp: Vector2 = full * bottom
						s.position = to3(Vector2(gp.x, TownLife.PUFF_BASE_Y + 1.0)) + Vector3(0, (TownLife.PUFF_BASE_Y - gp.y) * U, 0)
			if s.flip_h:
				s.offset.x = -float(s.region_rect.size.x if s.region_enabled else tx.get_width()) - s.offset.x
			k += 1
	for i in range(used, pool.size()):
		(pool[i] as Sprite3D).visible = false
	if true3d != null:
		true3d.end_frame()

## A town van / delivery truck as a standing card (see VANS). `at` = the van's centre on the road, `sc` = the 2D
## draw's scale (its sign is the direction). False when the van art isn't in the build (then the old card shows).
func _van(s: Sprite3D, name: String, at: Vector2, sc: Vector2, nudge: Vector3) -> bool:
	var vname: = "van_side" if name == "truck_h" else ("van_front" if sc.y > 0.0 else "van_back")
	var tx: = Art.tex(vname)
	if tx == null:
		return false
	s.texture = tx
	s.region_enabled = false
	s.rotation_degrees.x = 0.0
	s.material_override = null
	s.flip_h = name == "truck_h" and sc.y < 0.0   # get_scale() reports a mirror (negative determinant) on y
	s.flip_v = false
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	s.pixel_size = U / 4.0
	s.offset = Vector2(-tx.get_width() * 0.5, 0.0)
	# stand on the van's near edge, so its body sits over the lane it drives in
	s.position = to3(at + Vector2(0, 5.0 if name == "truck_h" else 0.0)) + nudge
	return true

# --- the static town ------------------------------------------------------------------------------------------

func _build_town() -> void:
	for b in main.buildings:
		var n: = str(b.get("art", ""))
		if n == "" or Art.tex(n) == null:
			continue
		var tx: = Art.tex(n)
		var inf: = Art.info(n)
		var k: = Art.density(inf)
		var org: Array = inf.get("origin", [0, 0])
		var r: Rect2 = b["r"]
		# 2D draws the art's top-left at r.position - origin / k; its bottom edge is where the facade meets the ground
		var bottom_y: = r.position.y - float(org[1]) / k + float(tx.get_height()) / k
		var left_x: = r.position.x - float(org[0]) / k
		var s: = _card()
		s.texture = tx
		s.pixel_size = U / k
		s.position = to3(Vector2(left_x, bottom_y))
		town.add_child(s)
		static_art[n] = true
		var box: = _box(b, tx, k, left_x, bottom_y)
		buildings.append([b, s, box, 1.0])   # [building, facade card, box info (or {}), current see-through alpha]
		# warm pool at the door from dusk (hd_presentation.gd does the same in 2D)
		if n != "sf_home":
			_lamp(Vector2(r.get_center().x, r.end.y + 6), 2.2, Color("#ffc27a"), 1.0, 6.0)
	_lamp(Vector2(103, 103), 3.0, Color("#ffb45a"), 1.3, 7.0)       # Duff's porch lantern
	for x in [60, 300, 540]:
		_lamp(Vector2(x, 200), 4.5, Color("#ffd9a0"), 1.0, 10.0)   # main-road street lights
	for it in main.dressing:
		var a: = str(it["a"])
		if a == "" or Art.tex(a) == null:
			continue
		static_art[a] = true
		var tx2: = Art.tex(a)
		var inf2: = Art.info(a)
		var k2: = Art.density(inf2) / float(it["s"])
		var org2: Array = inf2.get("origin", [tx2.get_width() / 2, tx2.get_height()])
		var c: = _card()
		c.texture = tx2
		c.pixel_size = U / k2
		var p: Vector2 = it["p"]
		if "leaves" in a:   # litter lies flat on the grass
			c.offset = Vector2(-float(org2[0]), -float(org2[1]))
			c.rotation_degrees.x = -90.0
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			c.position = to3(p, 0.01)
		else:
			c.offset = Vector2(-float(org2[0]), -(float(tx2.get_height()) - float(org2[1])))
			c.position = to3(p)
			c.add_to_group("view3d_face")   # turns with the camera sway
			var rm: = _round_mat(tx2, k2, 0.8)
			var hm: = float(tx2.get_height()) * c.pixel_size
			if it.get("tree", false):
				c.set_meta("sway", randf() * TAU)
				c.add_to_group("view3d_sway")
				rm.set_shader_parameter("sway", clampf(hm * 0.035, 0.03, 0.18))
				rm.set_shader_parameter("sway_phase", float(c.get_meta("sway")))
				rm.set_shader_parameter("card_h", hm)
			round_cards.append([c, rm])
			c.material_override = null if low else rm
			# contact shadow under its foot (wider for a tree's trunk spread / a bench's legs)
			var wm: = float(tx2.get_width()) * c.pixel_size
			_ao(town, to3(p, 0.012), Vector2(wm * 0.32, 0.12), 0.35 if it.get("tree", false) else 0.2, 0.45)
		town.add_child(c)

## The painted facade is a card; behind it a solid box gives the building real depth: a roof you see past the
## facade's top, side walls in perspective, a real shadow. Its top sits at the first row of the art that runs
## (almost) the full width (the eave, under any sign or chimney), its colours come from the art itself
## (roof = the rows just under that line, walls = the facade's outer columns), its depth from the lot.
func _box(b: Dictionary, tx: Texture2D, k: float, left_x: float, bottom_y: float) -> Dictionary:
	var img: = tx.get_image()
	if img == null:
		return {}
	if img.is_compressed():
		img.decompress()
	var w: = img.get_width()
	var h: = img.get_height()
	var top: = -1
	var x0: = 0
	var x1: = w - 1
	for want in [0.85, 0.6]:
		for y in range(h):
			var n: = 0
			var lo: = w
			var hi: = -1
			for x in range(0, w, 4):
				if img.get_pixel(x, y).a > 0.5:
					n += 1
					lo = mini(lo, x)
					hi = maxi(hi, x)
			if float(n) / (w / 4.0) > want:
				top = y
				x0 = lo
				x1 = hi
				break
		if top >= 0:
			break
	if top < 0:
		return {}
	var wall: = _avg(img, Rect2i(x0, (top + h) / 2, mini(6, x1 - x0), (h - top) / 3)).lerp(_avg(img, Rect2i(maxi(x0, x1 - 6), (top + h) / 2, mini(6, x1 - x0), (h - top) / 3)), 0.5)
	var r: Rect2 = b["r"]
	var bw: = float(x1 - x0) / k * U
	var bh: = float(h - top) / k * U
	var bd: = minf(r.size.y * 0.35, 22.0) * U   # shallow: a deep box shows a roof the size of a parking lot
	var z_front: = bottom_y * U - 0.02                     # just behind the card
	var cx: = (left_x + (float(x0 + x1) * 0.5) / k) * U
	var root: = Node3D.new()
	root.position = Vector3(cx, 0, z_front - bd * 0.5)
	town.add_child(root)
	var walls: = MeshInstance3D.new()
	var wm: = BoxMesh.new()
	wm.size = Vector3(bw, bh, bd)
	walls.mesh = wm
	walls.position.y = bh * 0.5
	var wc: = wall.darkened(0.15)
	if wc.get_luminance() < 0.22:   # sampled off a dark edge: a black slab reads as a hole in the street
		wc = wc.lerp(Color(0.55, 0.5, 0.46), 0.5)
	var wmat: = _flat(wc)
	wmat.emission_enabled = true   # side walls face away from a low sun at dusk; keep them lit like the painted card
	wmat.emission = wc * 0.45
	walls.material_override = wmat
	root.add_child(walls)
	# the roof is the art's own painted roof strip (the rows under the eave line), tiled back over the box's depth
	# a patch of plain roof: the least busy window just under the eave line (skips the shop sign, the fascia,
	# vents and chimneys), tiled across the whole roof
	var rh: = clampi(int(2.0 * k), 4, maxi(4, (h - top) / 4))   # thin: some roofs are a strip of a few px over the sign band
	var ww: = mini(int(12.0 * k), x1 - x0)
	var best: = Vector2i(x0, top + 1)
	var best_v: = INF
	for wy in range(maxi(0, top - rh), mini(top + 1 + rh, h - rh), 2):   # from above the eave line: a thin roof strip sits over it
		for wx in range(x0, x1 - ww + 1, maxi(2, ww / 4)):
			var v: = _busy(img, Rect2i(wx, wy, ww, rh))
			if v < best_v:
				best_v = v
				best = Vector2i(wx, wy)
	var strip: = img.get_region(Rect2i(best, Vector2i(ww, rh)))
	strip.generate_mipmaps()
	var cap: = MeshInstance3D.new()
	var pm: = PlaneMesh.new()
	pm.size = Vector2(bw + 0.04, bd + 0.02)
	cap.mesh = pm
	cap.position.y = bh + 0.005
	var rmat: = _flat(Color.WHITE)
	rmat.albedo_texture = ImageTexture.create_from_image(strip)
	rmat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rmat.texture_repeat = true
	rmat.uv1_scale = Vector3(maxf(1.0, round(bw / (float(ww) / k * U))), maxf(1.0, round(bd / (float(strip.get_height()) / k * U))), 1.0)
	cap.material_override = rmat
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cap)
	# eave: a thin lip along the top of the facade that juts out over the street and throws a real shadow line
	# down the painted front (coloured like the roof patch, a shade darker)
	var eave: = MeshInstance3D.new()
	var em: = BoxMesh.new()
	var lip: = 0.22
	em.size = Vector3(bw + 0.1, 0.07, lip)
	eave.mesh = em
	eave.position = Vector3(0, bh - 0.02, bd * 0.5 + lip * 0.5 + 0.03)
	var emat: = _flat(_avg(strip, Rect2i(0, 0, strip.get_width(), strip.get_height())).darkened(0.25))
	emat.emission_enabled = true
	emat.emission = emat.albedo_color * 0.35
	eave.material_override = emat
	root.add_child(eave)
	# contact shadow round the whole box (spills out in front of the facade onto the sidewalk)
	_ao(root, Vector3(0, 0.008, 0.02), Vector2(bw * 0.5, bd * 0.5 + 0.03), 0.9, 0.5)
	# 2D area where Duff is hidden behind this building: across its width, from the facade back past the box
	# by as far as its top hides the ground from the ~38 degree camera (+ Duff's own height)
	var hide_back: = bd / U + (bh / U) * CAM_OFF.z / CAM_OFF.y + 4.0
	return {"mats": [wmat, rmat, emat], "x0": left_x + float(x0) / k, "x1": left_x + float(x1) / k, "y0": bottom_y - hide_back, "y1": bottom_y - 2.0}

## Duff behind a building: fade its facade and box see-through (like any 3D game), back to solid when he leaves.
func _fade_buildings(delta: float) -> void:
	var p: Node2D = main.player
	if p == null:
		return
	var f: = p.position + FEET
	for e in buildings:
		var box: Dictionary = e[2]
		if box.is_empty():
			continue
		var behind: = f.x > float(box["x0"]) - 4.0 and f.x < float(box["x1"]) + 4.0 and f.y > float(box["y0"]) and f.y < float(box["y1"])
		var a: = move_toward(float(e[3]), 0.0 if behind else 1.0, delta * 6.0)   # hidden outright: a ghost over Duff read as a bug
		if is_equal_approx(a, float(e[3])):
			continue
		e[3] = a
		var s: Sprite3D = e[1]
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD if a >= 0.999 else SpriteBase3D.ALPHA_CUT_DISABLED
		s.modulate.a = a
		s.visible = a > 0.01
		for m in box["mats"]:
			(m as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if a >= 0.999 else BaseMaterial3D.TRANSPARENCY_ALPHA
			(m as StandardMaterial3D).albedo_color.a = a

func _shown(b: Dictionary) -> bool:
	for e in buildings:
		if e[0] == b:
			return float(e[3]) > 0.5
	return true

## How busy a patch is (colour variance plus see-through pixels): signs and vents score high, plain roof low.
func _busy(img: Image, r: Rect2i) -> float:
	var m: = _avg(img, r)
	var v: = 0.0
	var n: = 0
	for y in range(r.position.y, r.end.y, 3):
		for x in range(r.position.x, r.end.x, 3):
			var p: = img.get_pixel(x, y)
			v += 1.0 if p.a < 0.5 else (p.r - m.r) ** 2 + (p.g - m.g) ** 2 + (p.b - m.b) ** 2
			n += 1
	return v / maxf(1.0, n)

func _avg(img: Image, r: Rect2i) -> Color:
	var c: = Color(0, 0, 0, 0)
	var n: = 0
	r = r.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	for y in range(r.position.y, r.end.y, 3):
		for x in range(r.position.x, r.end.x, 3):
			var p: = img.get_pixel(x, y)
			if p.a > 0.5:
				c += p
				n += 1
	return Color(c.r / n, c.g / n, c.b / n) if n > 0 else Color("#5a4a44")

func _flat(c: Color) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	return m

func _lamp(p: Vector2, h: float, c: Color, e: float, rng: float) -> void:
	var l: = OmniLight3D.new()
	l.light_color = c
	l.omni_range = rng
	l.omni_attenuation = 1.6
	l.position = to3(p, h)
	l.light_energy = 0.0
	town.add_child(l)
	lamps.append([l, e])

## Hand-drawn street signs (the Waffle Haus pole, the 86 List board): main draws them with plain draw calls, so
## the capture never sees them and the flat overlay slid them off their spots. Each gets its own little 2D
## viewport (main's draw function at SIGN_K x) shown on a standing card.
const SIGN_K: = 4.0
const HUD_FRAC: = 0.12   # the HUD strip covers the top ~12% of the screen (house names slide below it)
var signs: Array = []   # [SignCanvas, SubViewport]

class SignCanvas extends Node2D:
	var fn: Callable
	var o: = Vector2.ZERO
	func _draw() -> void:
		fn.call(self, o, SIGN_K)

## r = the drawing's 2D world rect; the card's bottom-left goes at `at` (a ground point or a facade point).
func _sign(fn: Callable, r: Rect2, at: Vector3) -> void:
	var sv: = SubViewport.new()
	sv.size = Vector2i((r.size * SIGN_K).ceil())
	sv.transparent_bg = true
	sv.disable_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	world.add_child(sv)   # not under this container: a SubViewportContainer shows every SubViewport child on screen
	var c: = SignCanvas.new()
	c.fn = fn
	c.o = -r.position
	sv.add_child(c)
	var s: = _card()
	s.texture = sv.get_texture()
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	s.pixel_size = U / SIGN_K
	s.position = at
	town.add_child(s)
	signs.append([c, sv])

func _build_signs() -> void:
	var sp: Vector2 = main.WAFFLE_SIGN_PT
	_sign(Callable(main, "draw_waffle_sign"), Rect2(sp + Vector2(-17, -37), Vector2(34, 38)), to3(sp + Vector2(-17, 1)))
	var bp: Vector2 = main.BOARD_PT + Vector2(-10, -20)
	var br: = Rect2(bp + Vector2(-6, -7), Vector2(34, 21))
	var at: = _facade(main.buildings[3], Vector2(br.position.x, br.end.y))
	at.y = maxf(at.y, 0.02)   # its bottom sits a hair under the facade's base line in 2D
	_sign(Callable(main, "draw_86_board"), br, at)

func _sync_signs() -> void:
	for e in signs:
		(e[0] as SignCanvas).queue_redraw()
		(e[1] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE

func _sync_town() -> void:
	if town.visible:
		_sync_signs()
	var t: = Time.get_ticks_msec() / 1000.0
	var wind: = 1.0
	var tl: Node = main.get("town_life")
	if tl != null and tl.has_method("weather_kind"):
		wind = {"rain": 1.7, "snow": 1.3}.get(str(tl.weather_kind()), 1.0)
	for s in get_tree().get_nodes_in_group("view3d_sway"):
		if low:   # flat material: the old whole-card rock
			s.rotation_degrees.z = sin(t * 1.3 + float(s.get_meta("sway"))) * 0.9
		else:
			s.rotation_degrees.z = 0.0
	for e in round_cards:
		(e[1] as ShaderMaterial).set_shader_parameter("wind", wind)
	for s in get_tree().get_nodes_in_group("view3d_face"):
		(s as Node3D).rotation_degrees.y = yaw
	for e in buildings:
		var tint: = Color(0.72, 0.72, 0.78) if main.building_shut(e[0]) else Color.WHITE
		tint.a = float(e[3])
		(e[1] as Sprite3D).modulate = tint
	_fade_buildings(get_process_delta_time())
	var dark: = HdPresentation.darkness(float(main.clock))
	var on: = clampf((dark - 0.15) / 0.5, 0.0, 1.0)
	for l in lamps:
		(l[0] as OmniLight3D).light_energy = float(l[1]) * on * 1.6
		(l[0] as OmniLight3D).visible = on > 0.01

# --- floating markers -----------------------------------------------------------------------------------------

## Quest '!'/'?' (same rules as main.draw_quest_markers), story '!' over open fights, house names.
## A 2D point on a building's facade -> the same spot on its standing card (and a hair in front of it).
func _facade(b: Dictionary, p: Vector2) -> Vector3:
	for e in buildings:
		if e[0] == b:
			var s: Sprite3D = e[1]
			var by: = s.position.z / U
			return Vector3(p.x * U, (by - p.y) * U, s.position.z + 0.05)
	return _float(p)

## A 2D marker floats above a point on the ground plane; stand it up at the matching height.
func _float(p: Vector2) -> Vector3:
	return to3(Vector2(p.x, p.y + 26.0), 2.6)

## Everything main's flat WorldLabels layer draws, stood up in 3D (that layer is hidden while the view is live:
## its affine overlay only matches the camera near the target, so signs slid off their shops toward the edges).
func _sync_labels() -> void:
	var want: Array = []   # [3D point, text, colour, size]
	var t: = float(main.t)
	var loc: = str(main.location)
	if main.dialog.is_empty() and loc in ["outside", "home"]:
		var spots: Dictionary = main.quest_spots()
		for npc in spots:
			if str(spots[npc][0]) != loc:
				continue
			var mk: String = main.SideQuests.marker_for(main.side_quests, str(npc), main.show_hidden_quests, main.day_count, main.quest_ctx())
			if mk != "":
				want.append([_float(spots[npc][1] + Vector2(0, sin(t * 3.2) * 1.5)), mk, Color("#ffd640") if mk == "!" else Color("#7fd0ff"), 64])
	if loc == "outside":
		# Lost & Found: each unfound thing glints now and then (no '?' while hunting)
		if main.SideQuests.is_active(main.side_quests, "alley") and main.SideQuests.stage(main.side_quests, "alley") == 1:
			var i: = 0
			for k in main.LOST_SPOTS:
				i += 1
				if main.SideQuests.has_clue(main.side_quests, "alley", k):
					continue
				var a: = clampf(sin(t * 2.4 + i * 2.1) * 1.6 - 0.6, 0.0, 1.0)
				if a > 0.0:
					want.append([to3(main.LOST_SPOTS[k], 0.6), "+", Color(1.0, 0.95, 0.6, a), int(16 + a * 16)])
		for b in main.buildings:
			if not _shown(b):
				continue
			var r: Rect2 = b.get("vis", b["r"])
			if b.get("art", "") in ["sf_home", "sf_neighbor"]:
				want.append([_float(Vector2(r.get_center().x, r.position.y - 8)), main.Cast.T(b["n"]), Color.WHITE, 36, Color("#1a1024"), "house"])
			var r2: = Rect2(r.position - Vector2(0, 22), r.size)
			match main.building_sign(b):
				"closed":
					if main.closed_near(r2):
						want.append([_facade(b, Vector2(r.get_center().x, r.end.y - 14)), "CLOSED", Color("#f0ead8"), 22, Color("#a43a2c")])   # on the door, not floating over the roof
				"errand":
					want.append([_facade(b, Vector2(r.get_center().x, r.position.y - 24 + sin(t * 5.0) * 2.0)), "!", Color("#8cc4e8"), 64])
				"cleared":
					want.append([_facade(b, Vector2(r.get_center().x, r.end.y - 20)), "CLEARED", Color("#c0d890"), 30])
			if b.has("story") and not main.story_beaten(str(b["story"])) and main.story_available(str(b["story"])):
				want.append([_facade(b, Vector2(r.get_center().x, r.position.y - 28 + sin(t * 5.0) * 2.0)), "!", Color("#e6a640"), 64])
		# {coworker}'s "$" (a bet on offer today) over her head, like draw_brittany's 2D one
		if int(main.bet["day"]) != int(main.day_count) and main.phase() != "Night":
			var head: = britt_head if britt_head != Vector3.INF else to3(main.BRITT_POS + Vector2(0, 6), 3.0)
			want.append([head + Vector3(0, 0.15 + sin(t * 3.0) * 0.1, 0), "$", Color("#60e060"), 40, Color("#1a1024"), "over"])
		var fork: Dictionary = main.buildings[3]
		var fr: Rect2 = fork.get("vis", fork["r"])
		if _shown(fork):   # its building hid to show Duff behind it: the roof sign goes with it
			want.append([_facade(fork, Vector2(fr.get_center().x, fr.position.y + 1)), "NOW HIRING (you)", main.UiStyle.CREAM, 30, Color("#1a1024"), "sign"])
	while marks.size() < want.size():
		var l: = Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.fixed_size = false
		l.pixel_size = 0.02   # font_size 64 = 12.8 world units, the 2D marker's size
		l.outline_size = 6
		l.render_priority = 10
		l.outline_render_priority = 9
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # text is a screen marker; edge-on to a low sun it threw a stray line
		labels_root.add_child(l)
		marks.append(l)
	for i in marks.size():
		var l: Label3D = marks[i]
		l.visible = i < want.size()
		if not l.visible:
			continue
		var w: Array = want[i]
		l.text = str(w[1])
		l.modulate = w[2]
		l.font_size = int(w[3])
		l.outline_modulate = w[4] if w.size() > 4 else Color("#1a1024")
		l.outline_modulate.a = (w[2] as Color).a
		l.position = w[0]
		if w.size() > 5 and w[5] == "over" and not cam.is_position_behind(l.position):
			_plumb(l)
		if w.size() > 5 and w[5] == "house":
			_below_hud(l)
		elif w.size() > 5 and w[5] == "sign" and not cam.is_position_behind(l.position):
			# a roof sign on a shop that sits low in the frame is close to the camera: oversized, under the touch pad
			l.visible = cam.unproject_position(l.position).y < float(vp.size.y) * 0.75   # near the bottom it is also close and huge
			# closer than the camera target, perspective blows it up past the shop's width: shrink it back to its size at the target
			var near: = cam.global_position.distance_to(l.position) / CAM_OFF.length()
			if near < 1.0:
				l.font_size = maxi(8, int(float(w[3]) * near))

## A marker over someone's head: the label is a billboard, the person a card that perspective leans, so a point
## straight above the feet lands off to the side of the head. Slide it sideways until it is plumb over the feet.
func _plumb(l: Label3D) -> void:
	var feet: = Vector3(l.position.x, 0.0, l.position.z)
	var want_x: = cam.unproject_position(feet).x
	var at: = cam.unproject_position(l.position)
	var per_m: = cam.unproject_position(l.position + Vector3.RIGHT).x - at.x
	if absf(per_m) > 0.01:
		l.position.x += (want_x - at.x) / per_m

## House names float over the roof; when the house sits at the top of the frame that's under the HUD strip.
## Slide the name down (never below the ground) until it clears the strip, like main.draw_world_labels in 2D.
func _below_hud(l: Label3D) -> void:
	if cam.is_position_behind(l.position):
		return
	var top: = float(vp.size.y) * HUD_FRAC
	var sy: = cam.unproject_position(l.position).y
	if sy >= top:
		return
	var per_m: = cam.unproject_position(l.position + Vector3.DOWN).y - sy   # screen px per metre straight down
	if per_m <= 0.01:
		return
	l.position.y = maxf(0.3, l.position.y - (top - sy) / per_m)

## Rooms get a fixed key light from the front-left (a ceiling lamp / the arena floods), soft ambient,
## no fog. Night tint and the like still come from main's own overlay draws.
func _room_light() -> void:
	sun.rotation_degrees = Vector3(-58.0, 28.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 0.7
	sun.shadow_enabled = not low
	env.ambient_light_color = Color("#d8d0e8")
	env.ambient_light_energy = 0.55
	env.glow_intensity = 0.35
	env.adjustment_contrast = 1.1
	env.background_color = Color("#141018")
	env.fog_enabled = false
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL

## Sun, ambient and sky follow the same clock keys as the 2D grade (hd_presentation.gd SKY).
func _sync_sky() -> void:
	_refresh_ground()
	if room().size != Vector2.ZERO:
		_room_light()
		return
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
	sun.shadow_enabled = dark < 0.6 and not low     # moonlight shadows read as stray dark polygons on the lawns
	env.ambient_light_color = sky.lerp(Color("#8a86b8"), 0.4)
	env.ambient_light_energy = lerpf(0.3, 0.6, maxf(warm, dark * 0.6))
	env.glow_intensity = lerpf(0.3, 0.9, maxf(warm, dark))
	env.adjustment_contrast = lerpf(1.14, 1.06, warm)
	env.background_color = Color("#9cc8e8").lerp(sky, 0.5).darkened(dark * 0.6)
	env.fog_light_color = Color("#c8dcef").lerp(sky, 0.6).darkened(dark * 0.5)
	env.fog_enabled = true
	# distance haze: the street up the screen (further from the camera) goes a little paler and bluer
	env.fog_mode = Environment.FOG_MODE_DEPTH
	# (it starts well short of Duff: the old flat fog lifted his black shirt at night; keep that much at his depth)
	env.fog_depth_begin = lerpf(19.0, 6.0, dark)
	env.fog_depth_end = 52.0
	env.fog_depth_curve = 1.1
	env.fog_density = lerpf(lerpf(0.24, 0.3, warm), 0.4, dark) if not low else 0.1

func _cam_off() -> Vector3:
	return CAM_OFF.rotated(Vector3.UP, deg_to_rad(yaw))

## Where the camera yaw wants to be: off-centre Duff turns it toward the middle (you see past him into the
## street), and it leads a little toward where he walks. Rooms turn less (their painted walls end at the sides).
func _yaw_target(dt: float) -> float:
	if low or main.player == null:
		return 0.0
	var p: Vector2 = main.player.position
	var v: = 0.0
	if _last_p != Vector2.INF and dt > 0.0:
		v = clampf((p.x - _last_p.x) / dt / 60.0, -1.0, 1.0)
	_last_p = p
	var rr: = room()
	if rr.size != Vector2.ZERO:
		return clampf((p.x - rr.get_center().x) / (rr.size.x * 0.5), -1.0, 1.0) * YAW_ROOM + v * YAW_LEAD * 0.5
	return clampf((p.x - 320.0) / 210.0, -1.0, 1.0) * YAW_MAX + v * YAW_LEAD

func _cam_target() -> Vector3:
	var rr: = room()
	if rr.size != Vector2.ZERO:
		# follow Duff across, hold the depth so the front edge sits at the bottom of the screen
		var px: float = main.player.position.x if main.player != null else rr.get_center().x
		return to3(Vector2(clampf(px, rr.position.x + 128.0, rr.end.x - 128.0), rr.end.y - 70.0), 0.8)
	var p: Node2D = main.player
	var c: = p.position if p != null else Vector2(320, 180)
	# keep the frame inside the map the way the 2D camera's limits do (a little looser: the view is tilted)
	c.x = clampf(c.x, 110.0, 530.0)
	# y: the frame's bottom edge sees the ground ~67 units past the target and the row just under the HUD strip
	# ~126 units before it (CAM_OFF pitch + CAM_FOV); the painted ground spans y -16..368 (Ground.world_rect), so
	# 112..300 keeps the plain lawn past the map out of the bottom strip and out from under the HUD
	c.y = clampf(c.y, 112.0, 300.0)
	return to3(c, 0.8)

func _sync_cam() -> void:
	var dt: = get_process_delta_time()
	# a new room (door, fight) snaps the yaw too; a fight opens with a short push-in
	var key: = str(main.location) + ":" + str(main.arena_id)
	if key != _room_key:
		var first: = _room_key == ""
		_room_key = key
		_last_p = Vector2.INF
		yaw = _yaw_target(0.0)
		_push = 1.0 if str(main.location) == "arena" and not first and not low else 0.0
	yaw = lerpf(yaw, _yaw_target(dt), clampf(dt * 1.8, 0.0, 1.0))
	_push = move_toward(_push, 0.0, dt / PUSH_T)
	var want: = _cam_target() + _cam_off()
	# snap on a room change (doors cut in 2D too), glide while walking the town
	var jump: = cam_base.distance_to(want) > 30.0
	cam_base = want if jump else cam_base.lerp(want, clampf(get_process_delta_time() * 6.0, 0.0, 1.0))
	cam.position = cam_base
	cam.look_at(cam_base - _cam_off())
	# juice.gd's screen shake + zoom punch move the (disabled) Camera2D; the 3D camera takes them over
	var c2: Camera2D = main.get("cam")
	var off: = c2.offset if c2 != null else Vector2.ZERO
	cam.position += cam.basis.x * off.x * U - cam.basis.y * off.y * U
	var punch: = c2.zoom.x / 2.0 if c2 != null and c2.zoom.x > 0.0 else 1.0
	var ease: = _push * _push * (3.0 - 2.0 * _push)   # smoothstep: holds close a beat, then eases out
	cam.fov = CAM_FOV / clampf(punch, 0.9, 1.2) * (1.0 - 0.1 * ease)

## What the 2D world still draws under the 3D view (sparks, slashes, damage numbers, HP bars, telegraphs,
## speech bubbles) is laid over the 3D frame: the world canvas gets the affine map that best matches the
## camera near its target. x follows the ground; y splits the difference between ground depth and standing
## height, because most of what's left floats at body height (exact at the target, drifts toward the edges).
func _sync_overlay() -> void:
	if vp2d == null:
		return
	var t3: = cam_base - _cam_off()
	var c: = Vector2(t3.x, t3.z) / U
	var r: = Vector2(640, 360) / Vector2(vp.size)   # canvas units (vp2d's size_2d_override)
	var s0: = cam.unproject_position(to3(c)) * r
	var sx: = (cam.unproject_position(to3(c + Vector2(32, 0))) * r - s0) / 32.0
	var sg: = (cam.unproject_position(to3(c + Vector2(0, 32))) * r - s0) / 32.0
	var sv: = (s0 - cam.unproject_position(to3(c, 32.0 * U)) * r) / 32.0
	var sy: = (sg + sv) * 0.5
	vp2d.canvas_transform = Transform2D(sx, sy, s0 - sx * c.x - sy * c.y)
