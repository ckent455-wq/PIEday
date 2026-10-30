extends SceneTree

var yard: Node3D
var details: Node3D
var rng := RandomNumberGenerator.new()

func _initialize(): call_deferred("dress")

func material(color: Color, texture_path := "") -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	if not texture_path.is_empty(): mat.albedo_texture = load(texture_path)
	return mat

func mesh_node(title: String, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.material_override = mat
	node.set_meta("nonblocking_decor", true)
	details.add_child(node)
	node.owner = yard
	node.position = at
	return node

func box(title: String, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh_node(title, shape, at, mat)

func line(title: String, a: Vector3, b: Vector3, width: float, mat: Material):
	var node := box(title, (a + b) * 0.5, Vector3(width, 0.002, a.distance_to(b)), mat)
	node.rotation.y = atan2(b.x - a.x, b.z - a.z)

func dress():
	rng.seed = 271029
	yard = load("res://service_yard.tscn").instantiate()
	root.add_child(yard)
	var saved_dumpster: Transform3D = yard.get_node("OutdoorDumpster").transform
	if yard.has_node("YardDetails"):
		var old = yard.get_node("YardDetails")
		yard.remove_child(old)
		old.free()
	details = Node3D.new()
	details.name = "YardDetails"
	yard.add_child(details)
	details.owner = yard
	var concrete := material(Color(0.68, 0.70, 0.69), "res://assets/DINER/Textures/Concrete.jpg")
	concrete.uv1_triplanar = true
	concrete.uv1_world_triplanar = true
	concrete.uv1_scale = Vector3.ONE * 0.65
	yard.get_node("ConcretePad").material_override = concrete
	var seam := material(Color(0.14, 0.15, 0.14))
	for x in [-1.65, 0.15, 1.95]:
		line("ConcreteExpansionJoint", Vector3(x, -0.087, -14.9), Vector3(x, -0.087, -20.0), 0.012, seam)
	for z in [-16.25, -18.1, -19.95]:
		line("ConcreteExpansionJoint", Vector3(-3.05, -0.087, z), Vector3(2.45, -0.087, z), 0.012, seam)
	for origin in [Vector3(-2.8,-0.084,-16.6), Vector3(1.3,-0.084,-17.3), Vector3(0.1,-0.084,-19.5)]:
		var at: Vector3 = origin
		for segment in range(6):
			var next := at + Vector3(rng.randf_range(0.08, 0.22), 0, rng.randf_range(-0.22, 0.15))
			line("HairlineCrack", at, next, 0.004, seam)
			if segment == 3: line("CrackBranch", at, at + Vector3(-0.17,0,-0.20), 0.003, seam)
			at = next
	var grime := material(Color(0.12,0.10,0.06,0.18))
	grime.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in range(16):
		var shape := CylinderMesh.new()
		shape.top_radius = rng.randf_range(0.09,0.27)
		shape.bottom_radius = shape.top_radius
		shape.height = 0.001
		shape.radial_segments = 9
		var stain := mesh_node("ConcreteDirtPatch", shape, Vector3(rng.randf_range(-2.8,2.2),-0.083 + i*0.00005,rng.randf_range(-19.8,-15.0)), grime)
		stain.scale.z = rng.randf_range(0.5,1.6)
	var rust := material(Color(0.22,0.18,0.13))
	box("DrainRecess", Vector3(0.85,-0.083,-17.35), Vector3(0.50,0.003,0.42), seam)
	for i in range(9): box("DrainGrate", Vector3(0.63+i*0.055,-0.078,-17.35), Vector3(0.023,0.008,0.40), rust)
	for z in [-17.55,-17.15]: box("DrainFrame", Vector3(0.85,-0.076,z), Vector3(0.52,0.009,0.025), rust)
	var cardboard := material(Color(0.66,0.49,0.30), "res://assets/DINER/Textures/Paperboard.jpg")
	for i in range(4):
		var carton := box("FlattenedCardboard", Vector3(2.0,-0.065+i*0.018,-18.5+i*0.15), Vector3(0.60,0.018,0.44), cardboard)
		carton.rotation.y = rng.randf_range(-0.4,0.4)
	box("DiscardedCarton", Vector3(1.98,0.095,-19.25), Vector3(0.48,0.37,0.42), cardboard)
	box("CartonOpenFlap", Vector3(1.73,0.29,-19.25), Vector3(0.23,0.012,0.42), cardboard).rotation.z = 0.3
	var paper := material(Color(0.72,0.69,0.56))
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(11):
		var x: float = rng.randf_range(1.4,2.3) if i%2 == 0 else rng.randf_range(-2.9,-2.4)
		var scrap := box("PaperScrap", Vector3(x,-0.075,rng.randf_range(-19.5,-15.7)), Vector3(rng.randf_range(0.10,0.22),0.003,rng.randf_range(0.12,0.23)), paper)
		scrap.rotation.y = rng.randf_range(0,TAU)
	var tin := material(Color(0.43,0.45,0.42))
	for i in range(4):
		var can := CylinderMesh.new()
		can.top_radius = 0.035
		can.bottom_radius = 0.038
		can.height = 0.12
		can.radial_segments = 10
		var node := mesh_node("DiscardedCan", can, Vector3(1.65+i*0.12,-0.042,-18.0+i*0.2), tin)
		node.rotation = Vector3(PI/2, rng.randf_range(0,TAU), 0)
	var grass := material(Color(0.24,0.28,0.10))
	grass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(18):
		var at := Vector3(-2.99 if i%2==0 else 2.40,-0.085,rng.randf_range(-19.8,-15.2))
		for blade in range(3):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			surface.add_vertex(Vector3(-0.015,0,0))
			surface.add_vertex(Vector3(0.015,0,0))
			surface.add_vertex(Vector3(rng.randf_range(-0.06,0.06),rng.randf_range(0.08,0.19),0.025))
			surface.generate_normals()
			mesh_node("FenceWeed", surface.commit(), at, grass).rotation.y = rng.randf_range(0,TAU)
	# Add narrow ribs and weathered finish to the existing solid service fence.
	var fence := material(Color(0.28,0.32,0.29), "res://assets/DINER/Textures/Metal_03.jpg")
	fence.uv1_triplanar = true
	fence.uv1_scale = Vector3.ONE * 0.5
	for title in ["FenceLeft","FenceRight","FenceRear"]: yard.get_node(title).material_override = fence
	for i in range(18):
		box("FenceRearRib", Vector3(-3.0+i*0.32,1.18,-19.997), Vector3(0.025,2.5,0.025), fence)
	assert(yard.get_node("OutdoorDumpster").transform == saved_dumpster)
	var scene := PackedScene.new()
	assert(scene.pack(yard) == OK)
	assert(ResourceSaver.save(scene,"res://service_yard.tscn") == OK)
	print("DRESSED_YARD: saved dumpster transform preserved; concrete, joints, cracks, dirt, drain, cardboard, paper, cans and weeds")
	quit()
