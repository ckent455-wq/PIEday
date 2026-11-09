extends StaticBody3D

const RAW := "Frozen fries"
const SERVING := "Basket of fries"
const COOK_SECONDS := 3.0
const BASKET_MODEL := preload("res://assets/fries/serving_basket.glb")
const FROZEN_MODEL := preload("res://assets/fries/frozen_fries.glb")
const GOLDEN_COLORS := {
	"Pale frozen potato": Color("efbd54"),
	"Frozen cut faces": Color("ffd675"),
	"Frozen edges": Color("c5812c"),
}
var shift: Node3D

func setup(owner_shift: Node3D) -> void:
	shift = owner_shift
	name = "FrozenFriesRack"
	position = Vector3(9.1, -0.09, -7.53)
	collision_layer = 5
	set_meta("action", "frozen_fries")
	var collision := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(1.08, 1.90, 0.58)
	collision.shape = bounds
	collision.position.y = 0.95
	add_child(collision)
	var steel := Color(0.37, 0.44, 0.47)
	for x in [-0.50, 0.50]:
		for z in [-0.26, 0.26]:
			shift._box(self, Vector3(x, 0.90, z), Vector3(0.045, 1.80, 0.045), steel)
	for y in [0.40, 0.92, 1.44]:
		shift._box(self, Vector3(0, y, 0), Vector3(1.06, 0.045, 0.56), steel)
		for x in [-0.32, 0.0, 0.32]:
			var pack := Node3D.new()
			add_child(pack)
			pack.position = Vector3(x, y + 0.024, 0.04)
			_package(shift, pack, Vector3(0.24, 0.30, 0.24))
	var sign: Label3D = shift._label(self, "FROZEN FRIES", Vector3(0, 1.79, -0.30), 0.002)
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sign.rotation.y = PI

func take() -> void:
	if shift.pickup_item(RAW):
		shift._message("Frozen fries picked up. Aim at a basket in an empty fryer and press E to cook them for 3 seconds.")

static func model(host: Node3D, holder: Node3D, item: String) -> void:
	if item == RAW:
		_package(host, holder, Vector3(0.16, 0.21, 0.075))
		return
	holder.add_child(BASKET_MODEL.instantiate())

static func set_golden(portion: Node3D, golden: bool) -> void:
	if portion.get_meta("golden", false) == golden: return
	portion.set_meta("golden", golden)
	for mesh in portion.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var frozen: StandardMaterial3D = mesh.mesh.surface_get_material(surface)
			if golden:
				var cooked := frozen.duplicate() as StandardMaterial3D
				cooked.albedo_color = GOLDEN_COLORS[frozen.resource_name]
				mesh.set_surface_override_material(surface, cooked)
			else:
				mesh.set_surface_override_material(surface, null)

static func _package(host: Node3D, holder: Node3D, size: Vector3) -> void:
	host._box(holder, Vector3.UP * size.y * 0.5, size, Color(0.35, 0.55, 0.68))
	host._box(holder, Vector3(0, size.y * 0.58, -size.z * 0.5), Vector3(size.x * 0.84, size.y * 0.42, 0.006), Color(0.9, 0.81, 0.56))
	var label: Label3D = host._label(holder, "FRIES", Vector3(0, size.y * 0.58, -size.z * 0.5 - 0.004), size.x * 0.005)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.rotation.y = PI
