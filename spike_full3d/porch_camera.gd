extends RefCounted
## Fight camera (standards: smart camera, hero always readable). Frames Duff and the foe he is
## fighting and pulls back as they separate, smoothed so hits don't jolt it.
## Modes (Nov 25 2026 camera card, renders docs/renders/porch3d/camera_compare.jpg):
##   low   = low beat-'em-up angle, house as the backdrop (recommended, default)
##   frame = higher tilted 3D view
##   close = the old top-down orthographic view, closer, following Duff
##   explore = walking around a zone with nobody to fight: higher and closer, follows Duff
##             (Phase 2 step 3). Each zone sets its own bounds with set_zone().
## `--cam=<mode>` overrides MODE for comparing on a phone or in renders.

const MODE := "low"
const MODES := {
	#         pitch  fov   base dist  per metre apart  min   max   aim height
	"low":   [22.0, 38.0, 4.5, .9, 5.0, 9.0, .9],
	"frame": [42.0, 32.0, 5.0, 1.1, 6.0, 11.0, .8],
	"explore": [34.0, 42.0, 8.6, 0.0, 8.6, 8.6, 1.0],
}
const CLOSE_SIZE := 4.4
const CLOSE_OFFSET := Vector3(0, 5.76, 7.8)
const FOLLOW := 5.0     ## how fast it catches up (per second)
const X_LIMIT := 5.2    ## aim stops short of the fences; FIT pulls back for the rest
const Z_RANGE := Vector2(-1.2, 4.6)
const FIT_MARGIN := .86 ## every fighter's head and feet stay inside this share of the frame
const FIT_MAX := 16.0   ## farthest it will pull back to keep both in frame

var camera: Camera3D
var mode := MODE
var fight_mode := MODE  ## the mode fights use (MODE or --cam=); zones without a fight use explore
var x_limit := X_LIMIT
var z_range := Z_RANGE

func _init(cam: Camera3D) -> void:
	camera = cam
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cam="):
			mode = arg.trim_prefix("--cam=")
	if not (mode in MODES or mode == "close"):
		mode = MODE
	fight_mode = mode
	_apply_mode()

## A zone loaded: its bounds, and the fight camera or the explore camera.
func set_zone(explore: bool, limit: float, zs: Vector2) -> void:
	x_limit = limit
	z_range = zs
	mode = "explore" if explore else fight_mode
	_apply_mode()

func _apply_mode() -> void:
	if mode == "close":
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = CLOSE_SIZE
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = MODES[mode][1]

## Where the camera wants to be for Duff (and his foe, if any).
func goal(duff: Vector3, foe = null) -> Transform3D:
	var mid := duff
	var apart := 0.0
	if foe != null:
		mid = (duff + foe) * .5
		apart = duff.distance_to(foe)
	mid.x = clampf(mid.x, -x_limit, x_limit)
	mid.z = clampf(mid.z, z_range.x, z_range.y)
	if mode == "close":
		var at := Vector3(clampf(duff.x, -x_limit, x_limit), 0, clampf(duff.z, z_range.x, z_range.y))
		return Transform3D.IDENTITY.translated(at + CLOSE_OFFSET).looking_at(at + Vector3(0, .55, -.54))
	var m: Array = MODES[mode]
	var dist := clampf(m[2] + apart * m[3], m[4], m[5])
	var pitch := deg_to_rad(m[0])
	var aim := mid + Vector3(0, m[6], 0)
	var dir := Vector3(0, sin(pitch), cos(pitch))
	var points := [duff, duff + Vector3.UP * 1.8]
	if foe != null:
		points += [foe, foe + Vector3.UP * 1.8]
	var tf := Transform3D.IDENTITY.translated(aim + dir * dist).looking_at(aim)
	while dist < FIT_MAX and not _fits(tf, points):  # never lose a fighter off the edge
		dist += .25
		tf = Transform3D.IDENTITY.translated(aim + dir * dist).looking_at(aim)
	return tf

## True when every point lands inside FIT_MARGIN of the frame seen from `tf` (perspective modes).
func _fits(tf: Transform3D, points: Array) -> bool:
	var size := camera.get_viewport().get_visible_rect().size if camera.is_inside_tree() else Vector2(16, 9)
	var half_y := tan(deg_to_rad(camera.fov) * .5)
	var half_x := half_y * size.x / size.y
	var inv := tf.affine_inverse()
	for p in points:
		var local: Vector3 = inv * p
		if local.z > -.1:
			return false
		if absf(local.x / -local.z) > half_x * FIT_MARGIN or absf(local.y / -local.z) > half_y * FIT_MARGIN:
			return false
	return true

func snap(duff: Vector3, foe = null) -> void:
	camera.global_transform = goal(duff, foe)

func follow(delta: float, duff: Vector3, foe = null) -> void:
	camera.global_transform = camera.global_transform.interpolate_with(goal(duff, foe), minf(1.0, delta * FOLLOW))
