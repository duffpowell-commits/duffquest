extends Node3D
# Minimal 3D render check for the web engine: ground, sun with shadows, HD Duff card, fog/glow env.
func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.7)
	e.glow_enabled = true
	e.fog_enabled = true
	e.fog_density = 0.01
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(20, 20)
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.45, 0.55, 0.35)
	pm.material = gm
	ground.mesh = pm
	add_child(ground)
	var box := MeshInstance3D.new(); box.mesh = BoxMesh.new(); box.position = Vector3(2, 0.5, -1)
	add_child(box)
	var s := Sprite3D.new()
	s.texture = load("res://art/duff_home_hd3d.png")
	s.hframes = 4; s.vframes = 4; s.frame = 0
	s.pixel_size = 2.4 / 512.0
	s.offset = Vector2(0, 256 - 32)
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = true
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	add_child(s)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.2, 5); cam.rotation_degrees = Vector3(-15, 0, 0); cam.fov = 40
	add_child(cam)
	print("WEBCHECK 3D OK: ", RenderingServer.get_video_adapter_name())
