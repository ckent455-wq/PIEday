extends StaticBody3D

var shift: Node
var board: Node3D
var opened := false
var tubes: Array[MeshInstance3D] = []
var glow_materials: Array[StandardMaterial3D] = []
var neon_light: OmniLight3D

func setup(owner_shift: Node) -> void:
 shift = owner_shift
 name = "WindowOpenSign"
 position = Vector3(-2.45, 1.95, 3.61)
 collision_layer = 4
 set_meta("action", "open_sign")
 shift.add_child(self)
 var collision := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(0.92, 0.47, 0.09)
 collision.shape = shape
 add_child(collision)
 board = Node3D.new()
 add_child(board)
 var backing := MeshInstance3D.new()
 var plate := BoxMesh.new()
 plate.size = Vector3(0.91, 0.46, 0.025)
 backing.mesh = plate
 var black := StandardMaterial3D.new()
 black.albedo_color = Color(0.012, 0.014, 0.019)
 black.roughness = 0.5
 backing.material_override = black
 board.add_child(backing)
 for side in [-1, 1]:
  var face := Node3D.new()
  board.add_child(face)
  face.position.z = side * 0.025
  face.rotation.y = PI if side == -1 else 0.0
  var oval: Array[Vector2] = []
  for i in range(65):
   var angle := TAU * i / 64.0
   oval.append(Vector2(cos(angle) * 0.415, sin(angle) * 0.193))
  _stroke(face, oval, Color(0.05, 0.28, 1.0))
  var letter_o: Array[Vector2] = []
  for i in range(25):
   var angle := TAU * i / 24.0
   letter_o.append(Vector2(-0.265 + cos(angle) * 0.055, sin(angle) * 0.093))
  _stroke(face, letter_o, Color(1.0, 0.055, 0.035))
  _stroke(face, [Vector2(-0.145,-0.093),Vector2(-0.145,0.093),Vector2(-0.075,0.093),Vector2(-0.046,0.068),Vector2(-0.046,0.023),Vector2(-0.075,0),Vector2(-0.145,0)], Color(1.0,0.055,0.035))
  _stroke(face, [Vector2(0.105,0.093),Vector2(0.015,0.093),Vector2(0.015,-0.093),Vector2(0.105,-0.093)], Color(1.0,0.055,0.035))
  _stroke(face, [Vector2(0.015,0),Vector2(0.09,0)], Color(1.0,0.055,0.035))
  _stroke(face, [Vector2(0.165,-0.093),Vector2(0.165,0.093),Vector2(0.285,-0.093),Vector2(0.285,0.093)], Color(1.0,0.055,0.035))
 for x in [-0.29,0.29]:
  _tube(self, Vector3(x,0.23,0), Vector3(x,0.57,0), 0.003, _material(Color(0.18,0.18,0.18),false))
 neon_light = OmniLight3D.new()
 neon_light.light_color = Color(1.0,0.08,0.04)
 neon_light.omni_range = 1.3
 neon_light.light_energy = 0.0
 add_child(neon_light)
 _update_neon()

func _material(color: Color, glow: bool) -> StandardMaterial3D:
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 if glow:
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
  mat.albedo_color.a = 0.10
  mat.no_depth_test = false
 return mat

func _tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
 var tube := MeshInstance3D.new()
 var cylinder := CylinderMesh.new()
 cylinder.top_radius = radius
 cylinder.bottom_radius = radius
 cylinder.height = a.distance_to(b)
 cylinder.radial_segments = 6
 tube.mesh = cylinder
 tube.material_override = mat
 tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 parent.add_child(tube)
 tube.position = (a+b)*0.5
 tube.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
 return tube

func _stroke(parent: Node3D, points: Array, color: Color) -> void:
 var core := _material(color,false)
 core.set_meta("lit_color",color)
 glow_materials.append(core)
 var halo := _material(color,true)
 halo.set_meta("lit_color",color)
 glow_materials.append(halo)
 for i in range(points.size()-1):
  var a := Vector3(points[i].x,points[i].y,0)
  var b := Vector3(points[i+1].x,points[i+1].y,0)
  _tube(parent,a,b,0.006,core)
  tubes.append(_tube(parent,a,b,0.017,halo))

func _update_neon() -> void:
 for mat in glow_materials:
  var color: Color = mat.get_meta("lit_color")
  if mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
   color.a = 0.10 if opened else 0.0
  elif not opened: color = Color(0.12,0.075,0.07) if color.r > 0.5 else Color(0.055,0.07,0.12)
  else: color = color.lightened(0.25)
  mat.albedo_color = color
 neon_light.light_energy = 0.45 if opened else 0.0

func _process(_delta: float) -> void:
 var service: bool = shift.phase in ["arriving", "waiting", "leaving"] and not shift.closing_time
 if service == opened: return
 opened = service
 _update_neon()

func prompt() -> String:
 if shift.phase == "prep":
  if not shift.donut_fryer.prepared() and not shift.maintenance.is_broken("fryer"): return "Sign off — fry and stock all three donut flavors first"
  var missing: String = shift.burger_station.missing_produce()
  if not missing.is_empty(): return "Sign off — bring %s stock from the freezer to the bun counter" % missing
  return "[E] Switch neon OPEN sign on — start shift"
 return "OPEN — serving customers" if opened else "Sign off — service finished for today"

func use() -> void:
 if shift.phase != "prep": return
 var demo = preload("res://playable_demo.gd").session(shift)
 if demo != null and demo.tutorial_state != "done":
  shift._message("Finish training at the clipboard before opening.")
  return
 shift.start_shift()
