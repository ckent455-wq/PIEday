extends RefCounted

const OPENING := AABB(Vector3(-1.36, -0.20, -14.95), Vector3(1.52, 2.80, 0.70))
const WALK_AREA := Rect2(-3.0, -19.7, 5.4, 5.6)

static func install(diner: Node3D) -> void:
	for node in diner.find_children("*", "MeshInstance3D", true, false):
		if node.name == "Stove_001":
			node.get_parent().remove_child(node)
			node.queue_free()
		elif node.name == "DINER":
			_cut_doorway(node)
		elif node.name in ["Trees_001", "Background", "Bush"]:
			# These imported backdrop cards have opaque black backgrounds.
			# Retire them now that the yard exposes the outside of the diner.
			node.get_parent().remove_child(node)
			node.queue_free()
	# Layout and dumpster transforms are edited directly in this scene.
	var yard: Node3D = load("res://service_yard.tscn").instantiate()
	diner.add_child(yard)
	_smooth_dumpster(yard)
	# Player-only boundaries extend above the decorative fence so a jump from
	# props cannot land outside the walkable rectangle and get clamped there.
	for wall in [
		AABB(Vector3(-3.18, -0.2, -20.2), Vector3(0.28, 6, 5.5)),
		AABB(Vector3(2.3, -0.2, -20.2), Vector3(0.28, 6, 5.5)),
		AABB(Vector3(-3.18, -0.2, -20.2), Vector3(5.76, 6, 0.6))]:
		var barrier := StaticBody3D.new()
		barrier.name = "YardJumpBoundary"
		barrier.collision_layer = 2
		yard.add_child(barrier)
		barrier.global_position = wall.get_center()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = wall.size
		collider.shape = shape
		barrier.add_child(collider)

static func _smooth_dumpster(yard: Node3D) -> void:
	var dumpster := yard.get_node("OutdoorDumpster") as Node3D
	var bounds := AABB()
	var first := true
	for mesh in dumpster.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		mesh.set_meta("nonblocking_decor", true)
	# Fill the lid seam and the unusable rear/side gaps against the fence.
	var far := bounds.end
	bounds.position = Vector3(-3.1, -0.1, -20.02)
	bounds.size = far - bounds.position
	var body := StaticBody3D.new()
	body.name = "SmoothDumpsterCollision"
	dumpster.add_child(body)
	body.global_transform = Transform3D(Basis.IDENTITY, bounds.get_center())
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = bounds.size
	collider.shape = shape
	body.add_child(collider)

# Subtract the doorway volume from the wall triangles, keeping UVs and normals.
# The rebuilt render mesh also produces the matching wall collision at startup.
static func _cut_doorway(node: MeshInstance3D) -> void:
	var result := ArrayMesh.new()
	for surface in range(node.mesh.get_surface_count()):
		var arrays := node.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for i in range(vertices.size()): indices.append(i)
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		builder.set_material(node.mesh.surface_get_material(surface))
		for t in range(0, indices.size(), 3):
			var polygon: Array = []
			for corner in range(3):
				var i := indices[t + corner]
				polygon.append({"p": vertices[i], "n": normals[i], "uv": uvs[i]})
			var remaining := polygon
			for plane in range(6):
				if remaining.is_empty(): break
				var axis := plane / 2
				var bound: float = OPENING.position[axis] if plane % 2 == 0 else OPENING.end[axis]
				var split := _split(remaining, node.global_transform, axis, bound, plane % 2 == 0)
				_emit(builder, split[0])
				remaining = split[1]
		builder.commit(result)
	node.mesh = result

static func _split(polygon: Array, world: Transform3D, axis: int, bound: float, lower: bool) -> Array:
	var outside: Array = []
	var inside: Array = []
	for i in range(polygon.size()):
		var a: Dictionary = polygon[i]
		var b: Dictionary = polygon[(i + 1) % polygon.size()]
		var da: float = (world * a.p)[axis] - bound
		var db: float = (world * b.p)[axis] - bound
		if not lower:
			da = -da
			db = -db
		if da >= 0: inside.append(a)
		else: outside.append(a)
		if (da >= 0) != (db >= 0):
			var f := da / (da - db)
			var v := {"p": a.p.lerp(b.p, f), "n": a.n.lerp(b.n, f).normalized(), "uv": a.uv.lerp(b.uv, f)}
			inside.append(v)
			outside.append(v)
	return [outside, inside]

static func _emit(builder: SurfaceTool, polygon: Array) -> void:
	for i in range(1, polygon.size() - 1):
		for v in [polygon[0], polygon[i], polygon[i + 1]]:
			builder.set_normal(v.n)
			builder.set_uv(v.uv)
			builder.add_vertex(v.p)
