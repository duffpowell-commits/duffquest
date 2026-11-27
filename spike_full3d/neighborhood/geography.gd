extends RefCounted
## Canonical 2D footprints, projected at 0.1 metres per map unit; x east, z south.
const PLACES = [
 ["home", "HOME", Rect2(40,40,110,70), Vector2(95,118), "house"],
 ["neighbor", "NEIGHBOR", Rect2(190,40,80,60), Vector2(230,104), "house"],
 ["shop", "KWIK-N-GO", Rect2(470,40,130,70), Vector2(536,124), "diner"],
 ["fork", "THE BUSTED SPATULA", Rect2(460,240,150,70), Vector2(535,318), "brick"],
 ["hoa", "HOA HQ", Rect2(40,240,120,70), Vector2(100,318), "brick"],
 ["ghoster", "SEEN CAFE", Rect2(205,108,60,40), Vector2(235,154), "brick"],
 ["gymbro", "IRON TEMPLE", Rect2(400,40,55,50), Vector2(427.5,96), "brick"],
 ["djvape", "CLUB CLOUD 9", Rect2(350,232,80,52), Vector2(390,290), "club"],
 ["crypto", "MINING RIG", Rect2(200,228,58,42), Vector2(229,276), "garage"],
 ["willnot", "GLASSHAUS TOWER", Rect2(340,6,52,80), Vector2(366,92), "tower"],
 ["pharmacy", "PHARMACY", Rect2(345,306,76,38), Vector2(383,352), "brick"],
 ["grocery", "GROCERY", Rect2(176,290,110,48), Vector2(231,346), "diner"],
 ["plasma", "PLASMA", Rect2(392,100,72,40), Vector2(428,148), "brick"],
]
const PHASES = ["Morning", "Afternoon", "Evening", "Night"]
const HOURS = [8, 13, 18, 23]
const MARKERS = {"porch": Vector2(122,117), "waffle_sign": Vector2(606,150), "bounty_board": Vector2(578,318), "backdoor": Vector2(482,318), "bus_home": Vector2(132,150), "bus_kwik": Vector2(560,150), "bus_fork": Vector2(600,202), "bus_market": Vector2(250,202)}
const PORCH = Vector2(122,117)
const ROAD_X = 316.0
const ROAD_Y = 175.0
static func world(p: Vector2) -> Vector3:
 return Vector3((p.x-320)*0.1,0,(p.y-180)*0.1)
static func clear(p: Vector2) -> bool:
 if not Rect2(3,3,634,354).has_point(p): return false
 for place in PLACES:
  if place[2].grow(3).has_point(p): return false
 return true
static func nearest(p: Vector2) -> String:
 var best := 13.0
 var found := ""
 for place in PLACES:
  if p.distance_to(place[3]) < best:
   best=p.distance_to(place[3]); found=place[0]
 for key in MARKERS:
  if p.distance_to(MARKERS[key]) < best:
   best=p.distance_to(MARKERS[key]); found=key
 return found
