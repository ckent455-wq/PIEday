extends RefCounted

const TYPES := ["Strawberry donut", "Chocolate donut", "Glazed donut"]
const COLORS := [Color(0.94, 0.30, 0.49), Color(0.20, 0.065, 0.025), Color(0.83, 0.59, 0.30)]

static func flavor_at(x: float) -> String:
	return TYPES[0 if x < -0.025 else 1 if x < 0.475 else 2]

static func dough() -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.032
	mesh.outer_radius = 0.10
	mesh.rings = 32
	mesh.ring_segments = 12
	return mesh

static func icing() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(32):
		for arc in range(8):
			for corner in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]:
				var a: float = TAU * (ring + corner.x) / 32.0
				var t: float = PI * (arc + corner.y) / 8.0
				# A slightly uneven edge makes the coating look dipped.
				var drip := 0.002 * sin(a * 7.0) * pow(abs(cos(t)), 6.0)
				var radius := 0.066 + 0.0355 * cos(t)
				tool.set_normal(Vector3(cos(a) * cos(t), sin(t), sin(a) * cos(t)))
				tool.add_vertex(Vector3(cos(a) * radius, sin(t) * 0.0355 + 0.001 + drip, sin(a) * radius))
	return tool.commit()

static func coating(parent: Node3D, flavor: String) -> void:
	var top := MeshInstance3D.new()
	top.name = "Icing"
	top.mesh = icing()
	var mat := StandardMaterial3D.new()
	var index := TYPES.find(flavor)
	mat.albedo_color = COLORS[maxi(index, 0)]
	mat.roughness = 0.25 if index == 2 else 0.36
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	top.material_override = mat
	parent.add_child(top)

static func model(parent: Node3D, flavor: String) -> void:
	var base := MeshInstance3D.new()
	base.name = "DonutDough"
	base.mesh = dough()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.31, 0.095)
	mat.roughness = 0.8
	base.material_override = mat
	parent.add_child(base)
	base.position.y = 0.035
	coating(base, flavor)
