extends SceneTree
## Preview isolation, unchanged station/cast origins, camera visibility contract.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var s = load("res://kitchen_preview.tscn").instantiate()
	root.add_child(s)
	var expected := {"Grill":Vector3(-4.35,0,-2.55),"Fryer":Vector3(-2.55,0,-2.55),"Saute":Vector3(-.7,0,-2.55),"ColdPrep":Vector3(1.8,0,-1.94),"Pass":Vector3(3,0,2.19),"Duff":Vector3(-2.5,0,1),"Sendback":Vector3(-4.25,0,-.85),"Camper":Vector3(-1,0,-1),"Coupon":Vector3(.3,0,.65),"Allergy":Vector3(4.45,0,-.7)}
	for key in expected:
		if not s.has_node(key) or not s.get_node(key).position.is_equal_approx(expected[key]):
			printerr("FAIL: changed origin ",key)
			quit(1)
			return
	if not s.roof.visible or not s.east_wall.visible or not s.south_wall.visible or s.camera.projection != Camera3D.PROJECTION_PERSPECTIVE:
		printerr("FAIL: default interior camera")
		quit(1)
		return
	s.set_view(Vector3(7,5,10),Vector3.ZERO,70)
	if s.roof.visible or s.east_wall.visible or s.south_wall.visible:
		printerr("FAIL: outer walls occlude inspection camera")
		quit(1)
		return
	if ProjectSettings.get_setting("application/run/main_scene") != "res://porch.tscn" or ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile") != "gl_compatibility":
		printerr("FAIL: preview isolation or mobile renderer")
		quit(1)
		return
	print("PASS: five station origins, five character origins, perspective, selective visibility and production isolation")
	quit()
