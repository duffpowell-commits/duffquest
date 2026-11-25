extends RefCounted
## Fight camera (standards: smart camera, hero always readable). Frames Duff and the foe he is
## fighting and pulls back as they separate, smoothed so hits don't jolt it.
## Modes (Nov 25 2026 camera card, renders docs/renders/porch3d/camera_compare.jpg):
##   low   = low beat-'em-up angle, house as the backdrop (recommended, default)
##   frame = higher tilted 3D view
##   close = the old top-down orthographic view, closer, following Duff
## `--cam=<mode>` overrides MODE for comparing on a phone or in renders.

const MODE := "low"
const MODES := {
	#         pitch  fov   base dist  per metre apart  min   max   aim height
	"low":   [22.0, 38.0, 4.5, .9, 5.0, 9.0, .9],
	"frame": [42.0, 32.0, 5.0, 1.1, 6.0, 11.0, .8],
}
const CLOSE_SIZE := 4.4
const CLOSE_OFFSET := Vector3(0, 5.76, 7.8)
const FOLLOW := 5.0     ## how fast it catches up (per second)
const X_LIMIT := 3.4    ## keeps the fences at the edge of frame
const Z_RANGE := Vector2(-1.2, 3.0)

var camera: Camera3D
var mode := MODE

func _init(cam: Camera3D) -> void:
	camera = cam
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cam="):
			mode = arg.trim_prefix("--cam=")
	if not (mode in MODES or mode == "close"):
		mode = MODE
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
	mid.x = clampf(mid.x, -X_LIMIT, X_LIMIT)
	mid.z = clampf(mid.z, Z_RANGE.x, Z_RANGE.y)
	if mode == "close":
		var at := Vector3(clampf(duff.x, -X_LIMIT, X_LIMIT), 0, clampf(duff.z, Z_RANGE.x, Z_RANGE.y))
		return Transform3D.IDENTITY.translated(at + CLOSE_OFFSET).looking_at(at + Vector3(0, .55, -.54))
	var m: Array = MODES[mode]
	var dist := clampf(m[2] + apart * m[3], m[4], m[5])
	var pitch := deg_to_rad(m[0])
	var aim := mid + Vector3(0, m[6], 0)
	var from := aim + Vector3(0, sin(pitch), cos(pitch)) * dist
	return Transform3D.IDENTITY.translated(from).looking_at(aim)

func snap(duff: Vector3, foe = null) -> void:
	camera.global_transform = goal(duff, foe)

func follow(delta: float, duff: Vector3, foe = null) -> void:
	camera.global_transform = camera.global_transform.interpolate_with(goal(duff, foe), minf(1.0, delta * FOLLOW))
