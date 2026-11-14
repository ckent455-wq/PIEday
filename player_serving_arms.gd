extends Node3D
## Camera-space serving hands share the held-item viewport and its lighting.
var shift: Node3D
var poses := {}
var active_pose := ""
var motion_time := 0.0
const FOOD_AT := Vector3(0, -.32, -.55)
const CUP_AT := Vector3(.18, -.32, -.55)
const SINGLE_AT := Vector3(.18, -.32, -.55)

func setup(host: Node3D) -> void:
 shift = host
 name = "ServingArms"
 shift.hand_anchor.add_child(self)
 for pose in ["support", "single", "grip"]:
  var model: Node3D = load("res://assets/player_arms/"+pose+".glb").instantiate()
  add_child(model)
  if pose == "single": model.position.y = -.05
  model.visible = false
  for mesh in model.find_children("*", "MeshInstance3D", true, false):
   mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  poses[pose] = model
 refresh(0)

func _process(delta: float) -> void:
 refresh(delta)

func refresh(delta: float) -> void:
 if not is_instance_valid(shift): return
 var item: String = shift.carried_item
 var empty_station: Node3D = null
 for station in [shift.coffee_station, shift.soda_station]:
  if is_instance_valid(station) and station.holding_empty: empty_station = station
 var serving := not item.is_empty() and item not in ["Pistol", "Carrying body", "Table trash"]
 var cup: bool = is_instance_valid(empty_station) or item in ["Coffee", "Soda"] or item in preload("res://soda_station.gd").FLAVORS or item in shift.BOTTLE_COOLER.ITEMS
 var pose := "grip" if cup else "single" if item == "Donut" or item in shift.DONUTS.TYPES else "support"
 active_pose = pose if serving or is_instance_valid(empty_station) else ""
 for key in poses: poses[key].visible = key == active_pose
 if active_pose.is_empty():
  position = Vector3.ZERO
  shift.carried_visual.position = Vector3(.25,-.32,-.8)
  return
 motion_time += delta
 var moving: float = Vector2(shift.game.player.velocity.x,shift.game.player.velocity.z).length()
 var sway := Vector3(sin(motion_time*7)*.003, abs(sin(motion_time*7))*.004, 0) * minf(moving/4,1)
 position = sway
 shift.carried_visual.position = (CUP_AT if cup else SINGLE_AT if pose == "single" else FOOD_AT)+sway
 if is_instance_valid(empty_station): empty_station.held_cup.position = CUP_AT+sway
