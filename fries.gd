extends StaticBody3D

const RAW := "Frozen fries"
const SERVING := "Basket of fries"
const CHEESE_FRIES := "Basket of cheese fries"
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
	var mask := topping_mask(item)
	if mask & 1: _melted_cheese(holder)
	for sauce in range(2):
		if mask & (2 << sauce): _sauce_drizzle(holder, sauce, bool(mask & 1))

# Sample the actual golden fries so toppings follow the pile instead of floating.
static var fry_heights: Dictionary = {}
static func _prepare_surface() -> void:
	if not fry_heights.is_empty(): return
	var basket := BASKET_MODEL.instantiate()
	var fries := basket.find_child("Hand-cut golden fries", true, false) as MeshInstance3D
	var faces := fries.mesh.get_faces()
	var transform := fries.transform
	for i in range(0, faces.size(), 3):
		var a: Vector3 = transform * faces[i]
		var b: Vector3 = transform * faces[i+1]
		var c: Vector3 = transform * faces[i+2]
		var denominator := (b.z-c.z)*(a.x-c.x)+(c.x-b.x)*(a.z-c.z)
		if absf(denominator) < .00000001: continue
		for x in range(int(floor(minf(a.x,minf(b.x,c.x))/.004)),int(ceil(maxf(a.x,maxf(b.x,c.x))/.004))+1):
			for z in range(int(floor(minf(a.z,minf(b.z,c.z))/.004)),int(ceil(maxf(a.z,maxf(b.z,c.z))/.004))+1):
				var u := ((b.z-c.z)*(x*.004-c.x)+(c.x-b.x)*(z*.004-c.z))/denominator
				var v := ((c.z-a.z)*(x*.004-c.x)+(a.x-c.x)*(z*.004-c.z))/denominator
				if u < 0 or v < 0 or u+v > 1: continue
				var key := Vector2i(x,z)
				fry_heights[key] = maxf(float(fry_heights.get(key,.02)),u*a.y+v*b.y+(1-u-v)*c.y)
	basket.free()

static func _surface(x: float, z: float) -> float:
	_prepare_surface()
	# A local envelope lets melted toppings bridge small gaps between fries.
	var height := .025
	for dx in range(-1,2):
		for dz in range(-1,2):
			var key := Vector2i(roundi(x/.004)+dx,roundi(z/.004)+dz)
			height = maxf(height,float(fry_heights.get(key,.025)))
	return height

static func _food_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func _melted_cheese(holder: Node3D) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_food_material(Color("efad30"),.33))
	var rings: Array[PackedVector3Array] = []
	for ring in range(7):
		var points := PackedVector3Array()
		for segment in range(40):
			var angle := TAU*segment/40.0
			var radius := ring/6.0 * (1+.09*sin(angle*5)+.05*cos(angle*9))
			var x := cos(angle)*.072*radius
			var z := sin(angle)*.043*radius
			var sag := maxf(0,radius-.82)*.028
			points.append(Vector3(x,_surface(x,z)+.003-sag,z))
		rings.append(points)
	for ring in range(6):
		for segment in range(40):
			var next := (segment+1)%40
			for point in [rings[ring][segment],rings[ring+1][next],rings[ring+1][segment],rings[ring][segment],rings[ring][next],rings[ring+1][next]]:
				tool.add_vertex(point)
	tool.generate_normals()
	var cheese := MeshInstance3D.new()
	cheese.name = "MeltedCheese"
	cheese.mesh = tool.commit()
	holder.add_child(cheese)

static func _sauce_drizzle(holder: Node3D, sauce: int, cheese: bool) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_food_material(Color("b82619") if sauce == 0 else Color("e5b820"),.25))
	var rings: Array[PackedVector3Array] = []
	for step in range(101):
		var t := step/100.0
		var x := sin(t*TAU*2.5+sauce*.55)*.065
		var z := (t-.5)*.075
		var radius := .0025*(.80+.20*sin(t*PI))
		var at := Vector3(x,_surface(x,z)+(.007 if cheese else .003)+sauce*.001,z)
		var tangent := Vector3(cos(t*TAU*2.5+sauce*.55)*.065*TAU*2.5,0,.075).normalized()
		var side := tangent.cross(Vector3.UP)
		var points := PackedVector3Array()
		for segment in range(8):
			var angle := TAU*segment/8.0
			points.append(at+(side*cos(angle)+Vector3.UP*sin(angle))*radius)
		rings.append(points)
	for step in range(100):
		for segment in range(8):
			var next := (segment+1)%8
			for point in [rings[step][segment],rings[step+1][next],rings[step+1][segment],rings[step][segment],rings[step][next],rings[step+1][next]]:
				tool.add_vertex(point)
	tool.generate_normals()
	var drizzle := MeshInstance3D.new()
	drizzle.name = "KetchupDrizzle" if sauce == 0 else "MustardDrizzle"
	drizzle.mesh = tool.commit()
	holder.add_child(drizzle)

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

static func topping_mask(item: String) -> int:
	var parts := item.split(" with ")
	if parts[0] not in [SERVING,CHEESE_FRIES]: return -1
	var mask := 1 if parts[0] == CHEESE_FRIES else 0
	if parts.size() > 1:
		for sauce in parts[1].split(", "):
			if sauce == "ketchup": mask |= 2
			elif sauce == "mustard": mask |= 4
			else: return -1
	return mask

static func serving_name(mask: int) -> String:
	var sauces := PackedStringArray()
	if mask & 2: sauces.append("ketchup")
	if mask & 4: sauces.append("mustard")
	return (CHEESE_FRIES if mask & 1 else SERVING) + (" with " + ", ".join(sauces) if not sauces.is_empty() else "")

static func topping_bit(index: int) -> int:
	return {0:1,4:2,5:4}.get(index,0)
