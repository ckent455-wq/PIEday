extends RefCounted

const MODELS := ["male_1", "female_1"]
const FACES := [
	[
		preload("res://assets/customers/male_1_head_M_D1.png"),
		preload("res://assets/customers/male_2_head_M_D2.png"),
		preload("res://assets/customers/male_3_head_M_D3.png"),
		preload("res://assets/customers/grandpa_head_M_D28.png"),
	],
	[
		preload("res://assets/customers/female_1_head_F_D1.png"),
		preload("res://assets/customers/female_2_head_F_D2.png"),
		preload("res://assets/customers/female_3_head_F_D3.png"),
		preload("res://assets/customers/female_3_head_F_D9.png"),
	],
]
const APRONS := ["Brick red", "Midnight blue", "Pine green", "Plum", "Charcoal"]
const APRON_COLORS := [Color("853b36"), Color("3f6090"), Color("3d735a"), Color("744c78"), Color("4b5057")]
const SKIN_TINTS := [
	[Vector3.ONE, Vector3(0.84, 0.78, 0.71), Vector3(0.53, 0.39, 0.31), Vector3(0.87, 0.84, 0.79)],
	[Vector3.ONE, Vector3(0.96, 0.92, 0.88), Vector3(0.86, 0.74, 0.65), Vector3(0.52, 0.39, 0.33)],
]

static func add_character(actor: Node3D, model: int, apron: int, face := 0) -> Node3D:
	model = clampi(model, 0, MODELS.size() - 1)
	apron = clampi(apron, 0, APRONS.size() - 1)
	face = clampi(face, 0, FACES[model].size() - 1)
	var visual := preload("res://customer_line.gd").attach_visual(actor, MODELS[model])
	_apply_face(visual, FACES[model][face])
	dress(visual, model == 1, apron, SKIN_TINTS[model][face])
	actor.set_meta("customer_model", MODELS[model])
	actor.set_meta("apron_color", apron)
	actor.set_meta("face_index", face)
	return visual

static func _apply_face(visual: Node3D, texture: Texture2D) -> void:
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(surface) as StandardMaterial3D
			if original == null or original.resource_name != "Face": continue
			var face := original.duplicate() as StandardMaterial3D
			face.albedo_texture = texture
			mesh.set_surface_override_material(surface, face)
			return

static func dress(visual: Node3D, blue_outfit: bool, apron_index: int, skin_tint: Vector3) -> void:
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		var original := mesh.get_active_material(0) as StandardMaterial3D
		if original == null or original.resource_name != "Clothes": continue
		var uniform_material := ShaderMaterial.new()
		uniform_material.shader = preload("res://coop_uniform.gdshader")
		uniform_material.set_shader_parameter("uniform_texture", original.albedo_texture)
		uniform_material.set_shader_parameter("blue_outfit", blue_outfit)
		uniform_material.set_shader_parameter("skin_tint", skin_tint)
		mesh.set_surface_override_material(0, uniform_material)

	var apron := Node3D.new()
	apron.name = "DinerApron"
	visual.add_child(apron)
	var color: Color = APRON_COLORS[apron_index]
	var fabric := _cloth(color)
	var binding := _cloth(color.darkened(0.35))
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
		var shoulder := Vector3(side * 0.098, 1.523 if blue_outfit else 1.534, -0.018)
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
