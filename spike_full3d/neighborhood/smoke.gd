extends SceneTree
const Geo=preload("res://neighborhood/geography.gd")
func _initialize() -> void:
 assert(Geo.PLACES.size()==13)
 for place in Geo.PLACES:
  assert(Geo.clear(place[3]),"blocked entrance: "+place[0])
  assert(Geo.nearest(place[3])==place[0])
  assert(not Geo.clear(place[2].get_center()))
 assert(Geo.clear(Vector2(316,175)))
 assert(not Geo.clear(Vector2(-1,0)))
 print("PASS geography: 13 entrances, footprints, bounds and crossroads")
 # Flood-fill at one map unit (10 cm) to verify all destinations share a connected street network.
 var seen := {Vector2i(95,130): true}
 var queue: Array[Vector2i] = [Vector2i(95,130)]
 var head := 0
 while head < queue.size():
  var at:=queue[head]; head+=1
  for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var next: Vector2i=at+dir
   if not seen.has(next) and Geo.clear(Vector2(next)):
    seen[next]=true; queue.append(next)
 for place in Geo.PLACES:
  assert(seen.has(Vector2i(place[3])),"unreachable entrance: "+place[0])
 for marker in Geo.MARKERS:
  assert(seen.has(Vector2i(Geo.MARKERS[marker])),"unreachable marker: "+marker)
 print("PASS routes: all 13 entrances and 8 markers reachable from home")
 quit()
