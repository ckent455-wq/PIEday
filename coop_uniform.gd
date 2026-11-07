extends RefCounted

static func dress(visual: Node3D, guest: bool) -> void:
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		var original := mesh.get_active_material(0) as StandardMaterial3D
		if original == null or original.resource_name != "Clothes": continue
		var uniform_material := ShaderMaterial.new()
		uniform_material.shader = preload("res://coop_uniform.gdshader")
		uniform_material.set_shader_parameter("uniform_texture", original.albedo_texture)
		uniform_material.set_shader_parameter("blue_outfit", guest)
		mesh.set_surface_override_material(0, uniform_material)

	var apron := Node3D.new()
	apron.name = "DinerApron"
	visual.add_child(apron)
	var fabric := _cloth(Color("853b36"))
	var binding := _cloth(Color("512925"))
	var trim := _cloth(Color("dab582"))
	# The panel follows the chest and flares out over the hips.
	_panel(apron, "Apron", fabric, [
		Vector3(0.088, 1.405, 0.132),
		Vector3(0.105, 1.30, 0.143),
		Vector3(0.146, 1.12, 0.124),
		Vector3(0.182, 0.96, 0.145),
		Vector3(0.169, 0.69, 0.145),
	], 0.025)
	_panel(apron, "Pocket", binding, [Vector3(0.103, 0.999, 0.152), Vector3(0.093, 0.859, 0.156)], 0.013)
	_panel(apron, "PocketTrim", trim, [Vector3(0.103, 0.999, 0.155), Vector3(0.102, 0.987, 0.156)], 0.013)
	_panel(apron, "Hem", binding, [Vector3(0.170, 0.713, 0.146), Vector3(0.169, 0.69, 0.147)], 0.025)
	for side in [-1.0, 1.0]:
		var shoulder := Vector3(side * 0.098, 1.523 if guest else 1.534, -0.018)
		_strap(apron, Vector3(side * 0.076, 1.39, 0.126), shoulder, 0.024, binding)
		_strap(apron, shoulder, Vector3(side * 0.075, 1.34, -0.109), 0.024, binding)
		_strap(apron, Vector3(side * 0.137, 1.118, 0.107), Vector3(side * 0.158, 1.118, -0.056), 0.030, binding)
		_strap(apron, Vector3(side * 0.158, 1.118, -0.056), Vector3(0, 1.118, -0.135), 0.030, binding)
	var badge := Label3D.new()
	badge.text = "PIEday"
	badge.font_size = 26
	badge.pixel_size = 0.00115
	badge.modulate = Color("f3d6a5")
	badge.outline_size = 0
	apron.add_child(badge)
	badge.position = Vector3(0, 1.31, 0.148)

static func _cloth(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

static func _panel(parent: Node3D, name: String, material: Material, rows: Array, curvature: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rows.size() - 1):
		var upper: Vector3 = rows[i]
		var lower: Vector3 = rows[i + 1]
		for j in range(4):
			var left := j * 0.5 - 1.0
			var right := left + 0.5
			var a := _panel_point(upper, left, curvature)
			var b := _panel_point(upper, right, curvature)
			var c := _panel_point(lower, left, curvature)
			var d := _panel_point(lower, right, curvature)
			for point in [a, b, c, b, d, c]: surface.add_vertex(point)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = surface.commit()
	mesh.material_override = material
	parent.add_child(mesh)

static func _panel_point(row: Vector3, across: float, curvature: float) -> Vector3:
	return Vector3(row.x * across, row.y, row.z - curvature * across * across)

static func _strap(parent: Node3D, a: Vector3, b: Vector3, width: float, material: Material) -> void:
	var strap := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, width, a.distance_to(b))
	strap.mesh = box
	strap.material_override = material
	parent.add_child(strap)
	strap.position = (a + b) * 0.5
	strap.look_at(parent.to_global(b), Vector3.UP)
