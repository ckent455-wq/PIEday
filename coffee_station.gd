extends StaticBody3D

var drink_name := "Coffee"
var machine_action := "coffee"
var stack_action := "cup_stack"
var station_position := Vector3(-2.95, 1.40, -6.53)
var stack_offset := Vector3(1.03, -0.20, -0.57)
var fill_seconds := 2.5
var cup_color := Color(0.88, 0.82, 0.67)
var band_color := Color(0.36, 0.19, 0.085)
var liquid_color := Color(0.10, 0.035, 0.012)
var built_in_cup_holder := false
var easy_coffee := false
var reference_cup_mesh: ArrayMesh
var fill_height := 0.15
var fill_radius := 0.048
var cup_position := Vector3(0, -0.20, -0.09)
var spout_position := Vector3(0, 0.175, -0.09)
var shift: Node3D
var state := "empty"
var holding_empty := false
var cups_left := 10
var stack: StaticBody3D
var stack_visual: Node3D
var held_cup: Node3D
var machine_cup: Node3D
var liquid: MeshInstance3D
var stream: MeshInstance3D
var status: Label3D
var brew_tween: Tween
var fill := 0.0

func setup(host: Node3D) -> void:
	shift = host
	name = "Station_" + machine_action
	position = station_position
	collision_layer = 4
	set_meta("action", machine_action)
	if built_in_cup_holder: _extract_reference_cup()
	_collision(self, Vector3(0.85, 0.70, 0.55) if easy_coffee else Vector3(0.42, 0.42, 0.32), Vector3.ZERO)
	status = shift._label(self, drink_name.to_upper() + ": TAKE A CUP FIRST", Vector3(0, 0.58, 0), 0.0016)
	stack = StaticBody3D.new()
	stack.name = "CupHolder" if built_in_cup_holder else "CupStack"
	stack.collision_layer = 4
	stack.set_meta("action", stack_action)
	add_child(stack)
	stack.position = stack_offset
	_collision(stack, Vector3(0.95, 0.32, 0.40) if built_in_cup_holder else Vector3(0.20, 0.38, 0.20), Vector3.ZERO if built_in_cup_holder else Vector3(0, 0.18, 0))
	shift._label(stack, "PULL SODA CUP" if built_in_cup_holder else drink_name.to_upper() + " CUPS", Vector3(0, 0.28, 0.12) if built_in_cup_holder else Vector3(0, 0.50, 0), 0.0015)
	stack_visual = Node3D.new()
	stack.add_child(stack_visual)
	held_cup = _cup(shift.hand_anchor)
	held_cup.name = "HeldEmpty" + drink_name + "Cup"
	held_cup.position = Vector3(-0.30, -0.28, -0.68)
	machine_cup = _cup(self)
	machine_cup.name = drink_name + "CupUnderSpout"
	machine_cup.position = cup_position
	liquid = _cylinder(machine_cup, fill_radius, 0.003, Vector3(0, 0.012, 0), liquid_color)
	var cup_surface := cup_position + Vector3(0, fill_height, 0)
	stream = _cylinder(self, 0.004, spout_position.y - cup_surface.y, (spout_position + cup_surface) * 0.5, liquid_color)
	reset_station()

func prompt(action: String) -> String:
	if action == stack_action:
		if holding_empty: return "Holding an empty " + drink_name.to_lower() + " cup - click its dispenser"
		return "[Click / E] Pull cup from dispenser (%d left)" % cups_left if built_in_cup_holder and cups_left > 0 else "[Click / E] Take an empty cup (%d left)" % cups_left if cups_left > 0 else "Cups are empty until next shift"
	match state:
		"brewing": return "Filling %s... %d%%" % [drink_name.to_lower(), int(fill * 100)]
		"ready": return "[Click / E] Pick up full " + drink_name.to_lower() + " cup"
	if easy_coffee and not holding_empty:
		return "[Click / E] Make coffee (%d cups left)" % cups_left if cups_left > 0 else "No coffee cups left until next shift"
	return "[Click / E] Place empty cup and fill" if holding_empty else "Pull an empty cup from the dispenser's front holder first" if built_in_cup_holder else "Take an empty cup from the stack first"

func interact(action: String) -> void:
	if shift.phase not in ["waiting", "arriving"]:
		_say("Open the shift before preparing coffee.")
		return
	if action == stack_action:
		if shift.has_empty_cup() or not shift.carried_item.is_empty():
			_say("Your hand is full. Place or return the held item first.")
			return
		if cups_left <= 0:
			_say("No empty cups left. The stack is refilled next shift.")
			return
		cups_left -= 1
		holding_empty = true
		held_cup.visible = true
		_rebuild_stack()
		_say("Empty cup picked up. Aim at the coffee machine and click to place it under the spout.")
		return
	if state == "ready":
		if shift.pickup_item(drink_name):
			state = "empty"
			machine_cup.visible = false
			status.text = drink_name.to_upper() + ": TAKE A CUP FIRST"
			if easy_coffee: status.text = "COFFEE: CLICK TO MAKE"
			_say("Full coffee picked up. Click the serving tray on the counter to place it.")
		return
	if state == "brewing":
		_say("The cup is still filling. Pick it up when the machine says READY.")
		return
	if not holding_empty:
		if not easy_coffee:
			_say("Pick up an empty cup from the stack beside the machine first.")
			return
		if shift.has_empty_cup() or not shift.carried_item.is_empty():
			_say("Free your hand before making coffee.")
			return
		if cups_left <= 0:
			_say("No empty cups left. The stack is refilled next shift.")
			return
		cups_left -= 1
		_rebuild_stack()
	holding_empty = false
	held_cup.visible = false
	state = "brewing"
	fill = 0
	machine_cup.visible = true
	liquid.position.y = 0.012
	stream.visible = true
	status.text = "FILLING " + drink_name.to_upper() + "..."
	brew_tween = create_tween()
	brew_tween.tween_method(_fill_cup, 0.0, 1.0, fill_seconds)
	brew_tween.tween_callback(_finish_brewing)
	_say("Cup placed. Coffee is filling - collect the full cup when ready.")

func _fill_cup(amount: float) -> void:
	fill = amount
	liquid.position.y = lerpf(0.012, fill_height, amount)
	if easy_coffee: status.text = "COFFEE: FILLING %d%%" % int(amount * 100)

func _finish_brewing() -> void:
	state = "ready"
	stream.visible = false
	status.text = drink_name.to_upper() + " READY - PICK UP CUP"
	_say("Coffee is ready. Click the full cup, then click the serving tray on the counter.")

func return_empty() -> bool:
	if not holding_empty: return false
	holding_empty = false
	held_cup.visible = false
	cups_left += 1
	_rebuild_stack()
	_say("Empty cup returned to the stack.")
	return true

func reset_station() -> void:
	if brew_tween and brew_tween.is_valid(): brew_tween.kill()
	state = "empty"
	fill = 0
	holding_empty = false
	cups_left = 10
	held_cup.visible = false
	machine_cup.visible = false
	stream.visible = false
	status.text = drink_name.to_upper() + ": TAKE A CUP FIRST"
	if easy_coffee: status.text = "COFFEE: CLICK TO MAKE"
	_rebuild_stack()

func _rebuild_stack() -> void:
	if built_in_cup_holder: return
	for child in stack_visual.get_children():
		stack_visual.remove_child(child)
		child.queue_free()
	for index in range(cups_left):
		var cup := _cup(stack_visual)
		cup.position.y = index * 0.018

func _cup(parent: Node3D) -> Node3D:
	var cup := Node3D.new()
	parent.add_child(cup)
	if built_in_cup_holder and reference_cup_mesh:
		var reference := MeshInstance3D.new()
		reference.mesh = reference_cup_mesh
		cup.add_child(reference)
		return cup
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile := [Vector2(0.043, 0), Vector2(0.055, 0.16), Vector2(0.058, 0.165), Vector2(0.058, 0.171), Vector2(0.051, 0.171), Vector2(0.050, 0.158), Vector2(0.039, 0.008), Vector2(0.001, 0.008)]
	for ring in range(profile.size() - 1):
		for index in range(20):
			var a := TAU * index / 20
			var b := TAU * (index + 1) / 20
			var p: Vector2 = profile[ring]
			var q: Vector2 = profile[ring + 1]
			var vertices := [Vector3(cos(a)*p.x, p.y, sin(a)*p.x), Vector3(cos(b)*p.x, p.y, sin(b)*p.x), Vector3(cos(b)*q.x, q.y, sin(b)*q.x), Vector3(cos(a)*q.x, q.y, sin(a)*q.x)]
			for corner in [0, 1, 2, 0, 2, 3]: builder.add_vertex(vertices[corner])
	builder.generate_normals()
	var material := StandardMaterial3D.new()
	material.albedo_color = cup_color
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := MeshInstance3D.new()
	mesh.mesh = builder.commit()
	mesh.material_override = material
	cup.add_child(mesh)
	_cylinder(cup, 0.051, 0.055, Vector3(0, 0.085, 0), band_color)
	return cup

func _cylinder(parent: Node3D, radius: float, height: float, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	var node: MeshInstance3D = shift._mesh(parent, mesh, at, color)
	return node

func _collision(parent: Node3D, size: Vector3, at: Vector3) -> void:
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	collider.position = at
	parent.add_child(collider)

func _say(text: String) -> void:
	if built_in_cup_holder:
		text = text.replace("stack beside the machine", "front cup holder on the dispenser").replace("stack", "dispenser cup holder")
	shift._message(text.replace("coffee", drink_name.to_lower()).replace("Coffee", drink_name))

func _extract_reference_cup() -> void:
	# Reuse the middle mounted cup, including its original UVs and material.
	var source: MeshInstance3D = shift.game.find_child("R_V", true, false)
	var upright := Basis(Vector3.RIGHT, PI / 2)
	var base := Vector3(1.72537, 0.88245, -6.43014)
	var normal_basis := source.global_basis.inverse().transposed()
	var result := ArrayMesh.new()
	for surface in range(source.mesh.get_surface_count()):
		var arrays := source.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for i in range(vertices.size()): indices.append(i)
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var count := 0
		for triangle in range(0, indices.size(), 3):
			var selected := true
			for corner in range(3):
				var world: Vector3 = source.global_transform * vertices[indices[triangle + corner]]
				if world.x < 1.65 or world.x > 1.80 or world.y < 0.80 or world.y > 0.96 or world.z < -6.66 or world.z > -6.42: selected = false
			if not selected: continue
			for corner in range(3):
				var id := indices[triangle + corner]
				builder.set_normal((upright * normal_basis * normals[id]).normalized())
				builder.set_uv(uvs[id])
				builder.add_vertex(upright * (source.global_transform * vertices[id] - base))
				count += 1
		if count > 0:
			var material: Material = source.get_active_material(surface).duplicate()
			if material is BaseMaterial3D: material.cull_mode = BaseMaterial3D.CULL_DISABLED
			builder.set_material(material)
			builder.commit(result)
	reference_cup_mesh = result
