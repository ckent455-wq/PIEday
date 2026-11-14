extends RefCounted
## A small floor grid for the diner; capsule sweeps keep pursuit out of furniture.
const CELL := .4
var grid: AStarGrid2D
var shift: Node3D
var route := PackedVector2Array()
var repath := 0.0
var capsule := CapsuleShape3D.new()
var ignored: Array[RID] = []
var door_ignored: Array[RID] = []

func setup(host: Node3D) -> void:
 shift = host
 capsule.radius = .23
 capsule.height = 1.75

func exclusions() -> Array[RID]:
 var result: Array[RID] = [shift.game.player.get_rid()]
 for node in shift.game.find_children("*", "CollisionObject3D", true, false):
  if node.has_meta("action") and node.get_meta("action") in ["customer","queued_customer"]: result.append(node.get_rid())
 return result

func query(at: Vector3, exclude_doors := false) -> PhysicsShapeQueryParameters3D:
 var q := PhysicsShapeQueryParameters3D.new()
 q.shape = capsule
 q.transform = Transform3D(Basis.IDENTITY,at+Vector3(0,1.1,0))
 q.collision_mask = 3
 q.exclude = ignored + door_ignored if exclude_doors else ignored
 return q

func build() -> void:
 ignored = exclusions()
 door_ignored.clear()
 for door in shift.game.doors:
  for body in door.find_children("*","CollisionObject3D",true,false): door_ignored.append(body.get_rid())
 grid = AStarGrid2D.new()
 grid.region = Rect2i(-27,-53,55,75)
 grid.cell_size = Vector2.ONE*CELL
 grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 grid.update()
 var space := shift.get_world_3d().direct_space_state
 for x in range(grid.region.position.x,grid.region.end.x):
  for z in range(grid.region.position.y,grid.region.end.y):
   var at := Vector3(x*CELL,-.094,z*CELL)
   var floor_ray := PhysicsRayQueryParameters3D.create(at+Vector3(0,.22,0),at-Vector3(0,.6,0),1,ignored+door_ignored)
   var blocked := space.intersect_ray(floor_ray).is_empty() or not space.intersect_shape(query(at,true),1).is_empty()
   grid.set_point_solid(Vector2i(x,z),blocked)

func nearest(at: Vector3) -> Vector2i:
 var cell := Vector2i(roundi(at.x/CELL),roundi(at.z/CELL))
 var best := cell
 var distance := INF
 for x in range(-4,5):
  for z in range(-4,5):
   var p := cell+Vector2i(x,z)
   if not grid.is_in_boundsv(p) or grid.is_point_solid(p): continue
   var d := Vector2(p).distance_squared_to(Vector2(at.x,at.z)/CELL)
   if d < distance: best=p;distance=d
 return best

func move(actor: Node3D, target: Vector3, delta: float) -> bool:
 if grid == null: build()
 ignored = exclusions()
 repath -= delta
 if repath <= 0:
  repath = .55
  var start := nearest(actor.position)
  var finish := nearest(target)
  route = grid.get_point_path(start,finish) if grid.is_in_boundsv(start) and grid.is_in_boundsv(finish) and not grid.is_point_solid(start) and not grid.is_point_solid(finish) else PackedVector2Array()
 while route.size()>0 and Vector2(actor.position.x,actor.position.z).distance_to(route[0]) < .18: route.remove_at(0)
 if route.is_empty(): return false
 for door in shift.game.doors:
  if door.has_meta("cooler") or "Refrigerator" in door.name or "Oven" in door.name: continue
  var center: Vector3 = door.global_transform*door.mesh.get_aabb().get_center()
  if Vector2(center.x,center.z).distance_to(Vector2(actor.position.x,actor.position.z)) < 1.5 and not door.get_meta("open",false): shift.game._set_door_open(door,true)
 var goal := Vector3(route[0].x,actor.position.y,route[0].y)
 var step := (goal-actor.position).limit_length(3.3*minf(delta,.1))
 var q := query(actor.position)
 q.motion = step
 var safe := shift.get_world_3d().direct_space_state.cast_motion(q)
 step *= safe[0]
 actor.position += step
 if step.length()>.001: actor.rotation.y = atan2(step.x,step.z)
 return step.length()>.001
