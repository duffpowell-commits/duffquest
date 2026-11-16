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
const HD: = {"duff_home": {"path": "res://assets/art3d/duff_home_hd3d.png", "cell": [512, 512], "origin": [256, 480], "s": 16.0}}
const NO_3D: = ["map_objects"]               # full-map overlays drawn by main (the old bus-stop sign layer)
var _hd_tex: = {}
var static_art: = {}                         # art names _build_town already stands up (main's own draws of them are skipped)
var cam_base: = Vector3.ZERO                 # follow-camera position before the shake offset
var _ground_tex: Texture2D
## The 3D frame renders at the screen's real pixel size (the 2D game is 640x360 scaled up), times this.
## 1.0 = native; Auto Lite drops it (step 6). Env DQ_3D_LOWRES=1 forces the old 640x360 render (renders/compare).
var res_scale: = 1.0

static func to3(p: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(p.x * U, h, p.y * U)

func _ready() -> void:
	name = "View3D"
	stretch = false   # sized by hand in _fit(): native pixels, not the 640x360 logical size
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
	var k: = maxf(1.0, minf(win.x / 640.0, win.y / 360.0)) * res_scale
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
	_sync_sky()
	_sync_town()
	_sync_actors()
	_sync_labels()
	_sync_cam()
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
	if on:
		_redraw_world(main)   # everything draws once more so the capture sees it
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
	caption = Label3D.new()
	caption.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	caption.outline_size = 8
	caption.font_size = 40
	caption.pixel_size = 0.012
	caption.modulate = Color.WHITE
	caption.outline_modulate = Color(0, 0, 0, 0.85)
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
	town.add_child(under)

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
func _sync_actors() -> void:
	var used: = 0
	var toward: = CAM_OFF.normalized() * 0.012
	for id in Art.rec.keys():
		var ci: = instance_from_id(id) as CanvasItem
		if ci == null or not is_instance_valid(ci):
			Art.rec.erase(id)
			continue
		if ci.get("it") != null or not ci.is_visible_in_tree() or (ci != main and not main.is_ancestor_of(ci)):
			continue
		var g: = ci.get_global_transform()
		var k: = 0
		for d in Art.rec[id]:
			var name: String = d[0]
			if name in NO_3D or (ci == main and static_art.has(name)):
				continue
			var full: Transform2D = g * (d[5] as Transform2D)
			var sc: = full.get_scale()
			var hd: = HD.has(name) and _hd(name) != null
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
			var mod: Color = d[4]
			s.modulate = mod
			s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD if mod.a > 0.95 else SpriteBase3D.ALPHA_CUT_DISABLED
			var pos: Vector2 = d[1]
			if d[6]:   # sheet frame
				var cell: Array = inf.get("cell", [tx.get_width(), tx.get_height()])
				var org: Array = inf.get("origin", [0, 0])
				s.region_enabled = true
				s.region_rect = Rect2(int(d[2]) * float(cell[0]), int(d[3]) * float(cell[1]), float(cell[0]), float(cell[1]))
				s.offset = Vector2(-float(org[0]), -(float(cell[1]) - float(org[1])))
				s.pixel_size = U / dens * absf(sc.y)
				s.position = to3(full * pos) + toward * k
			else:      # plain image, scale packed into the row slot
				var isc: = float(d[3]) / 1000.0
				var org2: Array = inf.get("origin", [0, 0])
				s.region_enabled = false
				s.offset = Vector2(-float(org2[0]), 0.0)
				s.pixel_size = U / dens * isc * absf(sc.y)
				if flat:   # top-left corner on the floor, image runs south
					s.offset = Vector2(-float(org2[0]), -float(tx.get_height()) + float(org2[1]))
					s.position = to3(full * pos, 0.0)
				else:
					var bottom: = pos + Vector2(0, (float(tx.get_height()) - float(org2[1])) * isc / dens)
					s.position = to3(full * bottom) + toward * k
			if s.flip_h:
				s.offset.x = -float(s.region_rect.size.x if s.region_enabled else tx.get_width()) - s.offset.x
			k += 1
	for i in range(used, pool.size()):
		(pool[i] as Sprite3D).visible = false

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
		buildings.append([b, s])
		static_art[n] = true
		# a dark block behind the facade: it only throws a shadow (the sun sees a building, not a playing card)
		var mass: = MeshInstance3D.new()
		var bm: = BoxMesh.new()
		var h: = float(tx.get_height()) / k * U * 0.6
		bm.size = Vector3(r.size.x * U * 0.96, h, r.size.y * U * 0.6)
		mass.mesh = bm
		mass.position = Vector3((r.position.x + r.size.x * 0.5) * U, h * 0.5, (bottom_y - r.size.y * 0.35) * U)
		mass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		town.add_child(mass)
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
			if it.get("tree", false):
				c.set_meta("sway", randf() * TAU)
				c.add_to_group("view3d_sway")
		town.add_child(c)

func _lamp(p: Vector2, h: float, c: Color, e: float, rng: float) -> void:
	var l: = OmniLight3D.new()
	l.light_color = c
	l.omni_range = rng
	l.omni_attenuation = 1.6
	l.position = to3(p, h)
	l.light_energy = 0.0
	town.add_child(l)
	lamps.append([l, e])

func _sync_town() -> void:
	var t: = Time.get_ticks_msec() / 1000.0
	for s in get_tree().get_nodes_in_group("view3d_sway"):
		s.rotation_degrees.z = sin(t * 1.3 + float(s.get_meta("sway"))) * 0.9
	for e in buildings:
		(e[1] as Sprite3D).modulate = Color(0.72, 0.72, 0.78) if main.building_shut(e[0]) else Color.WHITE
	var dark: = HdPresentation.darkness(float(main.clock))
	var on: = clampf((dark - 0.15) / 0.5, 0.0, 1.0)
	for l in lamps:
		(l[0] as OmniLight3D).light_energy = float(l[1]) * on * 1.6
		(l[0] as OmniLight3D).visible = on > 0.01

# --- floating markers -----------------------------------------------------------------------------------------

## Quest '!'/'?' (same rules as main.draw_quest_markers), story '!' over open fights, house names.
func _sync_labels() -> void:
	var want: Array = []   # [world point, text, colour, size]
	var t: = float(main.t)
	if main.dialog.is_empty() and room().size == Vector2.ZERO:
		var spots: Dictionary = main.quest_spots()
		for npc in spots:
			if str(spots[npc][0]) != "outside":
				continue
			var mk: String = main.SideQuests.marker_for(main.side_quests, str(npc), main.show_hidden_quests, main.day_count)
			if mk != "":
				want.append([spots[npc][1] + Vector2(0, sin(t * 3.2) * 1.5), mk, Color("#ffd640") if mk == "!" else Color("#7fd0ff"), 64])
	for b in main.buildings:
		var r: Rect2 = b.get("vis", b["r"])
		if b.get("art", "") in ["sf_home", "sf_neighbor"]:
			want.append([Vector2(r.get_center().x, r.position.y - 8), main.Cast.T(b["n"]), Color.WHITE, 28])
		if b.has("story") and not main.story_beaten(str(b["story"])) and main.story_available(str(b["story"])):
			want.append([Vector2(r.get_center().x, r.position.y - 28 + sin(t * 5.0) * 2.0), "!", Color("#e6a640"), 64])
	while marks.size() < want.size():
		var l: = Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.fixed_size = false
		l.pixel_size = 0.004
		l.outline_size = 10
		l.outline_modulate = Color("#1a1024")
		l.render_priority = 10
		l.outline_render_priority = 9
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
		# a 2D marker floats above a point on the ground plane; stand it up at the matching height
		var p: Vector2 = w[0]
		l.position = to3(Vector2(p.x, p.y + 26.0), 2.6)

## Rooms get a fixed key light from the front-left (a ceiling lamp / the arena floods), soft ambient,
## no fog. Night tint and the like still come from main's own overlay draws.
func _room_light() -> void:
	sun.rotation_degrees = Vector3(-58.0, 28.0, 0.0)
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	env.ambient_light_color = Color("#d8d0e8")
	env.ambient_light_energy = 0.55
	env.glow_intensity = 0.35
	env.adjustment_contrast = 1.1
	env.background_color = Color("#141018")
	env.fog_enabled = false

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
	sun.shadow_enabled = dark < 0.6      # moonlight shadows read as stray dark polygons on the lawns
	env.ambient_light_color = sky.lerp(Color("#8a86b8"), 0.4)
	env.ambient_light_energy = lerpf(0.3, 0.6, maxf(warm, dark * 0.6))
	env.glow_intensity = lerpf(0.3, 0.9, maxf(warm, dark))
	env.adjustment_contrast = lerpf(1.14, 1.06, warm)
	env.background_color = Color("#9cc8e8").lerp(sky, 0.5).darkened(dark * 0.6)
	env.fog_light_color = Color("#c8dcef").lerp(sky, 0.6).darkened(dark * 0.5)
	env.fog_enabled = true
	env.fog_density = lerpf(0.0012, 0.004, maxf(warm, dark))

func _cam_off() -> Vector3:
	return CAM_OFF

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
	c.y = clampf(c.y, 95.0, 330.0)
	return to3(c, 0.8)

func _sync_cam() -> void:
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
	cam.fov = CAM_FOV / clampf(punch, 0.9, 1.2)

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
