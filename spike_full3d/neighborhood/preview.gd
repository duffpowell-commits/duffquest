extends Node3D
const Geo = preload("res://neighborhood/geography.gd")
const Daylight = preload("res://porch_daylight.gd")
const Kit = preload("res://neighborhood/kit.gd")
var kit: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var environment: Environment
var actor: Node3D
var p := Vector2(95,130)
var phase := 0
var hud: Label
var lamps: Array = []
var touch_dir := Vector2.ZERO
var npcs: Array = []
func _ready() -> void:
 kit=Kit.new(); add_child(kit)
 var lawn=kit.material("lawn",Color("7c9356"),"concrete")
 var road=kit.material("road",Color("53585a"),"concrete")
 var walk=kit.material("walk",Color("b9b1a0"),"concrete")
 var stripe=kit.material("stripe",Color("d8bf76"))
 kit.box(Vector3(0,-.16,0),Vector3(84,.3,56),lawn)
 kit.box(Geo.world(Vector2(320,175))+Vector3(0,.01,0),Vector3(84,.04,4.4),road)
 kit.box(Geo.world(Vector2(316,180))+Vector3(0,.02,0),Vector3(4.4,.04,56),road)
 for y in [141,211]: kit.box(Geo.world(Vector2(320,y))+Vector3(0,.04,0),Vector3(64,.12,1.7),walk)
 for x in [283,349]: kit.box(Geo.world(Vector2(x,180))+Vector3(0,.04,0),Vector3(1.7,.12,36),walk)
 for x in range(15,640,32):
  if abs(x-316)>35: kit.box(Geo.world(Vector2(x,175))+Vector3(0,.045,0),Vector3(1.5,.01,.09),stripe)
 for y in range(12,360,32):
  if abs(y-175)>35: kit.box(Geo.world(Vector2(316,y))+Vector3(0,.045,0),Vector3(.09,.01,1.5),stripe)
 for place in Geo.PLACES:
  var r: Rect2=place[2]
  kit.building(Geo.world(r.get_center()),r.size*.1,place[4],place[1])
  var door: Vector2=place[3]
  kit.box(Geo.world(door)+Vector3(0,.04,0),Vector3(1.8,.1,1.4),walk)
 var metal=kit.material("iron",Color("49474a"))
 var light=kit.material("lamp",Color("ffd59c"),"plain",true)
 for x in [20,170,290,350,450,625]:
  for y in [132,218]:
   var at=Geo.world(Vector2(x,y))
   if Geo.clear(Vector2(x,y)):
    kit.tree(at)
 for x in [55,155,275,365,465,595]:
  var at=Geo.world(Vector2(x,205))
  kit.box(at+Vector3(0,1.8,0),Vector3(.12,3.6,.12),metal)
  kit.box(at+Vector3(0,3.6,-.35),Vector3(.12,.12,.8),metal)
  kit.box(at+Vector3(0,3.5,-.7),Vector3(.35,.16,.35),light)
  if x in [275,465]:
   var lamp:=OmniLight3D.new(); lamp.position=at+Vector3(0,3.3,-.7); lamp.omni_range=5; lamp.light_color=Color("ffd59c"); lamp.shadow_enabled=false; add_child(lamp); lamps.append(lamp)
 # Utility poles and overhead lines, parked sedans and a porch mailbox.
 var timber=kit.material("utility",Color("786046"),"siding")
 for x in [20,180,340,500,630]:
  var at=Geo.world(Vector2(x,125))
  kit.box(at+Vector3(0,2.7,0),Vector3(.19,5.4,.19),timber)
  kit.box(at+Vector3(0,5.1,0),Vector3(.18,.14,1.2),timber)
 for line_z in [-.5,.5]:
  kit.box(Geo.world(Vector2(325,125))+Vector3(0,5.23,line_z),Vector3(61,.035,.035),metal)
 var car_glass=kit.material("car_glass",Color("3e525e"))
 var rubber=kit.material("rubber",Color("292a2c"))
 for car in [[Vector2(75,189),Color("607c81")],[Vector2(455,160),Color("a95c49")],[Vector2(590,189),Color("d1b799")]]:
  var at=Geo.world(car[0]); var paint=kit.material("car"+str(car[0]),car[1])
  kit.box(at+Vector3(0,.47,0),Vector3(3.6,.65,1.5),paint)
  kit.box(at+Vector3(-.1,1.03,0),Vector3(1.9,.6,1.32),car_glass)
  kit.box(at+Vector3(-.1,1.34,0),Vector3(1.8,.1,1.34),paint)
  for x in [-1.05,1.05]:
   for z in [-.72,.72]: kit.shape("ball",at+Vector3(x,.3,z),Vector3(.65,.65,.21),rubber)
 var mailbox=Geo.world(Vector2(116,123))
 kit.box(mailbox+Vector3(0,.55,0),Vector3(.1,1.1,.1),timber)
 kit.box(mailbox+Vector3(0,1.18,0),Vector3(.45,.35,.65),metal)
 var bench=kit.material("bench",Color("876147"),"siding")
 for xy in [Vector2(170,205),Vector2(445,145),Vector2(610,210)]:
  var at=Geo.world(xy)
  kit.box(at+Vector3(0,.45,0),Vector3(1.6,.12,.5),bench)
  kit.box(at+Vector3(0,.8,.23),Vector3(1.6,.55,.12),bench)
  for side in [-1,1]: kit.box(at+Vector3(side*.6,.22,0),Vector3(.12,.45,.45),metal)
 for marker in Geo.MARKERS:
  var at=Geo.world(Geo.MARKERS[marker])
  kit.box(at+Vector3(0,.7,0),Vector3(.1,1.4,.1),metal)
  kit.box(at+Vector3(0,1.4,0),Vector3(.55,.35,.1),light)
 kit.finish()
 sun=DirectionalLight3D.new(); sun.shadow_enabled=true; sun.directional_shadow_max_distance=65; add_child(sun)
 var env := WorldEnvironment.new(); environment=Environment.new(); environment.background_mode=Environment.BG_COLOR; environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.environment=environment; add_child(env)
 camera=Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=24; add_child(camera); camera.current=true
 if ResourceLoader.exists("res://rig_actor.gd") and ResourceLoader.exists("res://models/duff.glb"):
  var rig=load("res://rig_actor.gd")
  actor=rig.make(self,"duff",1.8)
  for who in ["madison","brittany"]:
   var npc=rig.make(self,who,1.65); npcs.append(npc)
 else:
  actor=Node3D.new(); add_child(actor)
 var ui:=CanvasLayer.new(); add_child(ui)
 hud=Label.new(); hud.position=Vector2(18,14); hud.add_theme_font_size_override("font_size",22); ui.add_child(hud)
 var controls:=HBoxContainer.new(); controls.position=Vector2(18,82); ui.add_child(controls)
 for i in 4:
  var btn:=Button.new(); btn.text=Geo.PHASES[i]; btn.custom_minimum_size=Vector2(112,48); btn.pressed.connect(set_phase.bind(i)); controls.add_child(btn)
 var pad:=HBoxContainer.new(); ui.add_child(pad); pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT); pad.position=Vector2(18,455)
 for item in [["←",Vector2.LEFT],["↑",Vector2.UP],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
  var btn:=Button.new(); btn.text=item[0]; btn.custom_minimum_size=Vector2(60,58); btn.button_down.connect(func(): touch_dir=item[1]); btn.button_up.connect(func(): touch_dir=Vector2.ZERO); pad.add_child(btn)
 set_phase(0)
 if "--capture" in OS.get_cmdline_user_args(): capture()
 if "--smoke" in OS.get_cmdline_user_args(): smoke()
func set_phase(i: int) -> void:
 phase=i
 var key = Daylight.at(Geo.HOURS[i]*60.0)
 environment.background_color=key.sky; environment.ambient_light_color=key.fill; environment.ambient_light_energy=key.fill_energy
 sun.rotation_degrees=key.sun_rot; sun.light_color=key.sun_color; sun.light_energy=key.sun_energy
 for lamp in lamps: lamp.light_energy=key.lamp*.7
 for name in ["lamp","windows","neon","diner_window"]:
  kit.palette[name].emission_energy_multiplier=key.lamp
 if npcs.size()==2:
  npcs[0].position=Geo.world([Vector2(115,125),Vector2(105,130),Vector2(105,130),Vector2(105,130)][i]); npcs[0].visible=i==0 or i==2
  npcs[1].position=Geo.world([Vector2(288,140),Vector2(540,319),Vector2(288,140),Vector2(288,140)][i]); npcs[1].visible=i!=3
func _physics_process(delta: float) -> void:
 var direction=Input.get_vector("ui_left","ui_right","ui_up","ui_down")+touch_dir
 direction=direction.limit_length()
 var step=direction*45*delta
 if Geo.clear(p+Vector2(step.x,0)): p.x+=step.x
 if Geo.clear(p+Vector2(0,step.y)): p.y+=step.y
 actor.position=Geo.world(p)
 if actor.has_method("move_at"):
  actor.move_at(direction.length()*4.5)
  if direction.length()>.1: actor.turn_to(atan2(-direction.x,-direction.y))
 camera.position=actor.position+Vector3(10,16,20); camera.look_at(actor.position+Vector3(0,0,-4))
 var near=Geo.nearest(p)
 hud.text="NEIGHBORHOOD PREVIEW  |  %s  %02d:00  |  %s\nArrows / touch to explore  •  doors are preview markers only" % [Geo.PHASES[phase],Geo.HOURS[phase],near if near!="" else "street"]
func capture() -> void:
 var dir=OS.get_cmdline_user_args()[-1]
 for i in 4:
  set_phase(i); p=Vector2(316,211)
  for frame in 12: await get_tree().process_frame
  var start=Time.get_ticks_usec()
  for frame in 30: await get_tree().process_frame
  var ms=(Time.get_ticks_usec()-start)/30000.0
  RenderingServer.force_draw()
  var img=get_viewport().get_texture().get_image(); img.save_png(dir+"/"+Geo.PHASES[i].to_lower()+".png")
  print("CAPTURE ",Geo.PHASES[i]," mean_ms=",ms," draws=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
 for shot in [["home-street",Vector2(95,130),0],["storefronts",Vector2(535,318),2],["nightlife",Vector2(390,290),3]]:
  p=shot[1]; set_phase(shot[2])
  for frame in 12: await get_tree().process_frame
  RenderingServer.force_draw()
  get_viewport().get_texture().get_image().save_png(dir+"/"+shot[0]+".png")
 get_tree().quit()

func smoke() -> void:
 assert(actor.has_method("move_at") and npcs.size()==2)
 assert(actor.current=="idle")
 for i in 4:
  set_phase(i)
  assert(phase==i and sun.light_energy>0)
 var start=p
 touch_dir=Vector2.RIGHT
 for i in 10: await get_tree().physics_frame
 touch_dir=Vector2.ZERO
 assert(p.x>start.x)
 print("PASS scene: approved three rigs, four lighting states, movement")
 get_tree().quit()
