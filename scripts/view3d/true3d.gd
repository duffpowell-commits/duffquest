extends Node3D
## "True 3D" test slice (web link #true3d, env DQ_TRUE3D=1): Duff and the porch pirates stand in the 3D view as
## real meshes instead of painted cards. OFF for players: view3d.gd only creates this node when the switch is on.
## Duff uses the mesh built from his 2D sheets (tools/true3d/). Porch pirates can use a low-poly stand-in
## until their authored meshes are available. Both use the same animation poses: walk
## swing, idle breathing, the skillet swing on attack frames, a tumble on the dodge roll. The game still runs
## in 2D: view3d hands every captured sheet draw to claim() first; a claimed draw gets a model, not a card.

const U: = 0.1
## sheet -> model. "h": figure height in 2D world units (the sheet's idle figure, top of hair to soles);
## "arm": walk arm swing (pirates hug the package with both hands, so theirs barely move).
const MODELS: = {"duff": {"res": "res://assets/model3d/duff.res", "h": 26.0, "arm": 0.45},
	"pirate0": {"res": "res://assets/model3d/pirate0.res", "h": 26.0, "arm": 0.08},
	"pirate1": {"res": "res://assets/model3d/pirate1.res", "h": 26.0, "arm": 0.08},
	"pirate2": {"res": "res://assets/model3d/pirate2.res", "h": 26.0, "arm": 0.08},
	"pirate3": {"res": "res://assets/model3d/pirate3.res", "h": 26.0, "arm": 0.08}}
## sheet row -> facing yaw (model front is +z, the camera looks down -z): 0 front, 1 back, 2 right, 3 left
const ROW_YAW: = [0.0, PI, PI / 2.0, -PI / 2.0]

# Joint positions are in normalized model space (+Z is forward).
const PIRATE_BONES: Array = [
	["spine", -1, [0.0, 0.53, 0.0]],
	["head", 0, [0.0, 0.78, 0.0]],
	["arm_l", 0, [0.19, 0.72, 0.01]],
	["arm_r", 0, [-0.19, 0.72, 0.01]],
	["leg_l", -1, [0.09, 0.49, 0.0]],
	["leg_r", -1, [-0.09, 0.49, 0.0]],
]
const PIRATE_CLOTHES: Array[Color] = [
	Color("#26252e"), Color("#30313c"), Color("#243534"), Color("#382d38"),
]

var _mesh: = {}            # model key -> ArrayMesh (or null if missing from this build)
var actors: = {}           # "<canvas id>:<key>" -> Rig
var _seen: = {}            # actor keys claimed this frame

class Rig:
	var root: Node3D
	var turn: Node3D
	var skel: Skeleton3D
	var mi: MeshInstance3D
	var mat: StandardMaterial3D
	var bone: = {}
	var yaw: = 0.0
	var phase: = 0.0
	var walk: = 0.0          # 0 idle .. 1 full stride, eased
	var last: = Vector3.INF
	var swing: = -1.0        # attack swing timer (s), -1 = none
	var roll: = -1.0
	var skillet: Node3D
	var arm: = 0.45
	var pirate_clothes: StandardMaterial3D
	var pirate_color: Color

static func model_for(sheet: String) -> String:
	if sheet.begins_with("duff_shades") or sheet.begins_with("duff_"):
		return "duff"
	if sheet.begins_with("ch_pirate"):
		return sheet.substr(3)
	return ""

func _model_mesh(key: String) -> ArrayMesh:
	if _mesh.get(key) == null:
		var p: String = MODELS[key]["res"]
		# web: the models ride in extra.pck (late tier); until it lands the actor stays a painted card
		_mesh[key] = load(p) if ResourceLoader.exists(p) else null
	return _mesh[key]

func begin_frame() -> void:
	_seen.clear()

func end_frame() -> void:
	for k in actors.keys():
		(actors[k] as Rig).root.visible = _seen.has(k)

## view3d calls this for each captured sheet frame. True = drawn here (view3d makes no card for it).
## d = Art.rec entry [name, pos, col, row, modulate, t, is_frame]; foot = 3D point of the frame's origin.
func claim(id: int, d: Array, foot: Vector3, flip: bool, dt: float, tilt: float = 0.0) -> bool:
	var sheet: String = d[0]
	var key: = model_for(sheet)
	if key == "" or not d[6] or not MODELS.has(key):
		return false
	if key == "duff" and _model_mesh(key) == null:
		return false
	if sheet.begins_with("duff_shades"):
		return true   # his shades aren't on the model yet: drop the 2D overlay rather than float it
	var ak: = "%d:%s" % [id, key]
	var r: Rig = actors.get(ak)
	if r == null:
		r = _make(key)
		actors[ak] = r
	_seen[ak] = true
	var col: = int(d[2])
	var row: = int(d[3])
	var mod: Color = d[4]
	_pose(r, sheet, col, row, flip, foot, mod, dt)
	r.root.rotation.z = -tilt   # a 2D KO tips the sprite over; tip the model the same way (screen plane)
	return true

func _make(key: String) -> Rig:
	var r: = Rig.new()
	var mesh: ArrayMesh = _model_mesh(key)
	r.root = Node3D.new()
	add_child(r.root)
	r.turn = Node3D.new()
	r.root.add_child(r.turn)
	var s: = float(MODELS[key]["h"]) * U
	r.turn.scale = Vector3(s, s, s)
	r.arm = float(MODELS[key]["arm"])
	r.skel = Skeleton3D.new()
	r.turn.add_child(r.skel)
	var bones: Array = mesh.get_meta("bones") if mesh != null else PIRATE_BONES
	for b in bones:
		r.skel.add_bone(str(b[0]))
	for i in bones.size():
		var b: Array = bones[i]
		var par: = int(b[1])
		var head: = Vector3(b[2][0], b[2][1], b[2][2])
		var off: = head
		if par >= 0:
			r.skel.set_bone_parent(i, par)
			var ph: Array = bones[par][2]
			off = head - Vector3(ph[0], ph[1], ph[2])
		r.skel.set_bone_rest(i, Transform3D(Basis(), off))
		r.skel.reset_bone_pose(i)
		r.bone[str(b[0])] = i
	if mesh == null:
		_build_pirate(r, key)
		return r
	r.mi = MeshInstance3D.new()
	r.mi.mesh = mesh
	r.mat = (mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
	r.mi.material_override = r.mat
	r.mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	r.skel.add_child(r.mi)
	r.mi.skeleton = NodePath("..")
	r.mi.skin = r.skel.create_skin_from_rest_transforms()
	if key == "duff":
		r.skillet = _skillet()
		r.skel.add_child(r.skillet)
		r.skillet.visible = false
	return r

func _build_pirate(r: Rig, key: String) -> void:
	r.pirate_color = PIRATE_CLOTHES[int(key.right(1))]
	r.pirate_clothes = _pirate_material(r.pirate_color)
	var skin: = _pirate_material(Color("#be896e"))
	var dark: = _pirate_material(Color("#14151d"))
	var cardboard: = _pirate_material(Color("#be8b50"))
	var tape: = _pirate_material(Color("#e8ca8e"))
	var spine: = _joint(r, "spine")
	_pirate_box(spine, Vector3(0, 0.09, 0), Vector3(0.31, 0.28, 0.21), r.pirate_clothes)
	var head: = _joint(r, "head")
	_pirate_box(head, Vector3(0, 0.09, -0.015), Vector3(0.25, 0.26, 0.22), r.pirate_clothes)
	_pirate_box(head, Vector3(0, 0.075, 0.093), Vector3(0.175, 0.16, 0.06), skin)
	_pirate_box(head, Vector3(0, 0.103, 0.13), Vector3(0.183, 0.047, 0.02), dark)
	for side in ["l", "r"]:
		var leg: = _joint(r, "leg_" + side)
		_pirate_box(leg, Vector3(0, -0.21, 0), Vector3(0.145, 0.42, 0.135), dark)
		_pirate_box(leg, Vector3(0, -0.44, 0.032), Vector3(0.15, 0.1, 0.21), r.pirate_clothes)
		var arm: = _joint(r, "arm_" + side)
		_pirate_box(arm, Vector3(0, -0.09, 0.04), Vector3(0.115, 0.21, 0.12), r.pirate_clothes)
		_pirate_box(arm, Vector3(0, -0.18, 0.115), Vector3(0.107, 0.105, 0.19), r.pirate_clothes)
		_pirate_box(arm, Vector3(0, -0.18, 0.215), Vector3(0.085, 0.08, 0.065), skin)
	_pirate_box(spine, Vector3(0, 0.04, 0.245), Vector3(0.31, 0.20, 0.24), cardboard)
	_pirate_box(spine, Vector3(0, 0.141, 0.245), Vector3(0.055, 0.006, 0.24), tape)

func _joint(r: Rig, bone_name: String) -> BoneAttachment3D:
	var joint: = BoneAttachment3D.new()
	r.skel.add_child(joint)
	joint.bone_name = bone_name
	return joint

func _pirate_material(color: Color) -> StandardMaterial3D:
	var material: = StandardMaterial3D.new()
	material.albedo_color = color
	return material

func _pirate_box(parent: Node3D, offset: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var part: = MeshInstance3D.new()
	var box: = BoxMesh.new()
	box.size = size
	part.mesh = box
	part.material_override = material
	part.position = offset
	parent.add_child(part)

## A cast-iron skillet for the attack swing (the 2D attack frames draw one; the model has empty hands).
func _skillet() -> Node3D:
	var n: = Node3D.new()
	var iron: = StandardMaterial3D.new()
	iron.albedo_color = Color(0.13, 0.13, 0.14)
	iron.roughness = 0.5
	iron.metallic = 0.6
	var pan: = MeshInstance3D.new()
	var cyl: = CylinderMesh.new()
	cyl.top_radius = 0.13
	cyl.bottom_radius = 0.11
	cyl.height = 0.035
	cyl.radial_segments = 20
	pan.mesh = cyl
	pan.material_override = iron
	pan.position = Vector3(0, -0.3, 0.0)
	pan.rotation_degrees.x = 90.0
	n.add_child(pan)
	var handle: = MeshInstance3D.new()
	var bx: = BoxMesh.new()
	bx.size = Vector3(0.025, 0.16, 0.02)
	handle.mesh = bx
	handle.material_override = iron
	handle.position = Vector3(0, -0.12, 0)
	n.add_child(handle)
	return n

func _pose(r: Rig, sheet: String, col: int, row: int, flip: bool, foot: Vector3, mod: Color, dt: float) -> void:
	r.root.position = foot
	# facing: from movement when moving (any angle: that's the point of a model), else from the sheet row
	var moved: = 0.0
	if r.last != Vector3.INF:
		var dv: = foot - r.last
		dv.y = 0.0
		moved = dv.length()
		if moved > 0.004 and moved < 1.0:
			r.yaw = lerp_angle(r.yaw, atan2(dv.x, dv.z), clampf(dt * 14.0, 0.0, 1.0))
		elif moved <= 0.004:
			var ry: float = ROW_YAW[clampi(row, 0, 3)]
			if flip and row >= 2:
				ry = -ry
			r.yaw = lerp_angle(r.yaw, ry, clampf(dt * 10.0, 0.0, 1.0))
	else:
		r.yaw = ROW_YAW[clampi(row, 0, 3)]
	r.last = foot
	r.turn.rotation.y = r.yaw
	var speed: = moved / maxf(dt, 0.001)
	var walking: = speed > 0.15 or col == 1 or col == 2
	r.walk = move_toward(r.walk, 1.0 if walking else 0.0, dt * 6.0)
	r.phase += moved * 7.0 if moved < 1.0 else 0.0
	if walking and moved < 0.001:
		r.phase += dt * 9.0   # walking frames with no ground speed (cutscene steps, knockback)
	# attack: sheet column 3 is the swing pose (Duff's skillet, a pirate's throw)
	var attacking: = col == 3 and not sheet.begins_with("duff_roll")
	if attacking and r.swing < 0.0:
		r.swing = 0.0
	if r.swing >= 0.0:
		r.swing += dt
		if r.swing > 0.32 and not attacking:
			r.swing = -1.0
	if sheet.begins_with("duff_roll"):
		r.roll = r.roll + dt if r.roll >= 0.0 else 0.0
	else:
		r.roll = -1.0
	_apply(r)
	if r.pirate_clothes != null:
		r.pirate_clothes.albedo_color = r.pirate_color * Color(mod.r, mod.g, mod.b)
		return
	r.mat.albedo_color = Color(mod.r, mod.g, mod.b, 1.0)
	var see_through: = mod.a < 0.95
	r.mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if see_through else BaseMaterial3D.TRANSPARENCY_DISABLED
	if see_through:
		r.mat.albedo_color.a = mod.a

func _rot(r: Rig, b: String, e: Vector3) -> void:
	if r.bone.has(b):
		r.skel.set_bone_pose_rotation(r.bone[b], Quaternion.from_euler(e))

func _apply(r: Rig) -> void:
	var w: = r.walk
	var s: = sin(r.phase)
	var breathe: = sin(Time.get_ticks_msec() / 1000.0 * 2.2) * (1.0 - w)
	_rot(r, "leg_l", Vector3(-0.55 * s * w, 0, 0))
	_rot(r, "leg_r", Vector3(0.55 * s * w, 0, 0))
	_rot(r, "arm_l", Vector3(r.arm * s * w, 0, 0.06 * r.arm / 0.45))
	_rot(r, "arm_r", Vector3(-r.arm * s * w, 0, -0.06 * r.arm / 0.45))
	_rot(r, "spine", Vector3(0.05 * w + 0.015 * breathe, 0.06 * s * w, 0))
	_rot(r, "head", Vector3(-0.03 * w, -0.04 * s * w, 0))
	r.turn.position.y = absf(cos(r.phase)) * 0.06 * w + 0.004 * breathe
	if r.swing >= 0.0:
		# wind up overhead, then chop down and forward (Duff swings with his left; the art holds the pan there)
		var t: = clampf(r.swing / 0.3, 0.0, 1.0)
		var up: = -1.8 * sin(t * PI) if t < 0.5 else lerpf(-1.8, -0.6, (t - 0.5) * 2.0)
		_rot(r, "arm_l", Vector3(up, 0, 0.15))
		_rot(r, "spine", Vector3(0.18 * t, -0.25 * (1.0 - t), 0))
	if r.skillet != null:
		r.skillet.visible = r.swing >= 0.0
		if r.skillet.visible and r.bone.has("arm_l"):
			var gt: = r.skel.get_bone_global_pose(r.bone["arm_l"])
			r.skillet.transform = gt * Transform3D(Basis(), Vector3(0, -0.28, 0.02))
	r.turn.rotation.x = r.roll * TAU / 0.45 if r.roll >= 0.0 else 0.0
	if r.roll >= 0.0:
		r.turn.position.y += 0.12
