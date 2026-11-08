extends RefCounted
## Retain the flat top and cabinet, replacing the gas hob with a work surface.
static func install(diner: Node3D) -> void:
	var stove := diner.find_child("Stoves",true,false) as MeshInstance3D
	if stove == null or stove.has_meta("prep_conversion"): return
	stove.set_meta("prep_conversion",true)
	var original_steel: Material = stove.mesh.surface_get_material(0)
	var result := ArrayMesh.new()
	for surface in range(stove.mesh.get_surface_count()):
		var arrays := stove.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for i in vertices.size(): indices.append(i)
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		builder.set_material(stove.mesh.surface_get_material(surface))
		var kept := 0
		for triangle in range(0,indices.size(),3):
			var center := Vector3.ZERO
			var knob := true
			for corner in range(3):
				var p: Vector3 = stove.global_transform * vertices[indices[triangle+corner]]
				center += p / 3.0
				knob = knob and p.x > -2.56 and p.y > 0.895 and p.y < 1.04
			var burner := center.y >= 1.11 and (center.z < -11.70 or center.z > -10.2)
			if burner or knob: continue
			for corner in range(3):
				var index := indices[triangle+corner]
				builder.set_normal(normals[index])
				builder.set_uv(uv[index])
				builder.add_vertex(vertices[index])
			kept += 1
		if kept > 0: builder.commit(result)
	stove.mesh = result
	var top := MeshInstance3D.new()
	top.name = "StainlessPrepCounter"
	var box := BoxMesh.new()
	box.size = Vector3(1.448,0.06,1.384)
	top.mesh = box
	top.material_override = original_steel
	diner.add_child(top)
	top.global_position = Vector3(-3.0815,1.17,-12.482)
	var side := MeshInstance3D.new()
	side.name = "SidePrepSurface"
	var side_box := BoxMesh.new()
	side_box.size = Vector3(1.04,0.04,0.63)
	side.mesh = side_box
	side.material_override = original_steel
	diner.add_child(side)
	side.global_position = Vector3(-3.17,1.13,-9.81)
