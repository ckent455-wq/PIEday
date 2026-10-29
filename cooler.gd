extends RefCounted

# Split the imported cooler into its original shell and two hinged leaves.
static func install(diner: Node3D) -> void:
	for source in diner.find_children("*", "MeshInstance3D", true, false):
		if not source.name.begins_with("Refrigerator_01"):
			continue
		var builders: Array[SurfaceTool] = []
		for part in range(3):
			var builder := SurfaceTool.new()
			builder.begin(Mesh.PRIMITIVE_TRIANGLES)
			builder.set_material(source.mesh.surface_get_material(0))
			builders.append(builder)
		var hinges := [Vector3.ZERO, Vector3(0.3415, 1.176, -8.943), Vector3(2.1537, 1.176, -8.943)]
		var arrays: Array = source.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for index in range(vertices.size()):
				indices.append(index)
		for index in range(0, indices.size(), 3):
			var center := Vector3.ZERO
			for corner in range(3):
				center += source.global_transform * vertices[indices[index + corner]] / 3.0
			var part := 0
			if center.z < -8.94 and center.y > 0.07 and center.y < 2.28 and center.x > 0.33 and center.x < 2.16:
				# The source has two large faces sealing the cavity behind both
				# doors. Remove those instead of attaching them to either leaf.
				var backing := false
				for corner in range(3):
					var world: Vector3 = source.global_transform * vertices[indices[index + corner]]
					if world.x < 0.33 or world.x > 2.16 or world.y < 0.07 or world.y > 2.28:
						backing = true
				if backing:
					continue
				part = 1 if center.x < 1.2476 else 2
			var offset: Vector3 = source.to_local(hinges[part]) if part > 0 else Vector3.ZERO
			for corner in range(3):
				var vertex := indices[index + corner]
				builders[part].set_normal(normals[vertex])
				builders[part].set_uv(uvs[vertex])
				builders[part].add_vertex(vertices[vertex] - offset)
		var original_transform: Transform3D = source.global_transform
		source.mesh = builders[0].commit()
		var liner := StandardMaterial3D.new()
		liner.albedo_color = Color(0.47, 0.51, 0.53)
		liner.metallic = 0.65
		liner.roughness = 0.5
		for part in range(1, 3):
			var door := MeshInstance3D.new()
			door.name = "Cooler_Door_Left" if part == 1 else "Cooler_Door_Right"
			door.mesh = builders[part].commit()
			source.get_parent().add_child(door)
			door.global_transform = Transform3D(original_transform.basis, hinges[part])
			door.set_meta("cooler", true)
			# The imported leaves have no inner face. Add solid inner liners.
			var center_x := 0.7714 if part == 1 else 1.7238
			_box(door, Vector3(center_x, 1.176, -8.943), Vector3(0.86, 2.193, 0.025), liner)
			if part == 2:
				# Overlapping meeting strip closes the source model's center gap.
				_box(door, Vector3(1.2476, 1.176, -8.975), Vector3(0.115, 2.2, 0.035), liner)
		_box(source.get_parent(), Vector3(1.2476, 2.295, -8.97), Vector3(1.82, 0.06, 0.04), liner)
		_stock(diner)
		return

static func _stock(diner: Node3D) -> void:
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.65, 0.70, 0.72)
	metal.metallic = 0.7
	metal.roughness = 0.45
	var interior := Node3D.new()
	interior.name = "PieCoolerInterior"
	diner.add_child(interior)
	# Light interior liners also make the cavity visible behind the original shell.
	_box(interior, Vector3(1.2476, 1.15, -8.07), Vector3(1.75, 2.2, 0.04), metal)
	for x in [0.36, 2.14]:
		_box(interior, Vector3(x, 1.15, -8.5), Vector3(0.03, 2.2, 0.85), metal)
	var pie_scene: PackedScene = load("res://assets/pies/pie_ps2.glb")
	for row in range(4):
		var height := 0.22 + row * 0.52
		_box(interior, Vector3(1.2476, height, -8.5), Vector3(1.73, 0.025, 0.78), metal)
		for depth in range(2):
			for column in range(3):
				var pie: Node3D = pie_scene.instantiate()
				pie.name = "Pie_%d_%d_%d" % [row, depth, column]
				interior.add_child(pie)
				pie.scale = Vector3.ONE * 1.15
				pie.global_position = Vector3(0.68 + column * 0.56, height + 0.0045, -8.70 + depth * 0.37)
				pie.rotation.y = (row * 7 + column * 13 + depth * 19) * PI / 180.0
				for mesh in pie.find_children("*", "MeshInstance3D", true, false):
					for surface in range(mesh.mesh.get_surface_count()):
						var material = mesh.get_active_material(surface)
						if material is BaseMaterial3D:
							material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	var light := OmniLight3D.new()
	light.light_color = Color(0.82, 0.92, 1.0)
	light.light_energy = 0.6
	light.omni_range = 2.1
	interior.add_child(light)
	light.global_position = Vector3(1.25, 2.1, -8.65)

static func _box(parent: Node3D, location: Vector3, size: Vector3, material: Material) -> void:
	var panel := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	panel.mesh = mesh
	parent.add_child(panel)
	panel.global_transform = Transform3D(Basis.IDENTITY, location)
