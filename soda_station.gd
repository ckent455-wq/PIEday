extends "res://coffee_station.gd"

var pour_audio: AudioStreamPlayer3D

const FLAVORS := ["Cola", "Lemon Fizz", "Dr. Paw Paw"]
const BANDS := [Color(0.80, 0.12, 0.08), Color(0.76, 0.88, 0.12), Color(0.49, 0.16, 0.59)]
const LIQUIDS := [Color(0.10, 0.035, 0.012), Color(0.72, 0.76, 0.24), Color(0.17, 0.045, 0.025)]

func setup(host: Node3D) -> void:
	drink_name = "Cola"
	super.setup(host)
	_add_holder_rims()
	_replace_nozzles()
	pour_audio = AudioStreamPlayer3D.new()
	pour_audio.name = "FizzySodaPour"
	pour_audio.stream = preload("res://assets/audio/soda_pour.wav")
	pour_audio.volume_db = -7.0
	pour_audio.unit_size = 2.5
	pour_audio.max_distance = 12.0
	pour_audio.position = spout_position
	add_child(pour_audio)
	status.position.y = 1.0
	status.pixel_size = 0.0012
	shift._box(self, Vector3(0, 0.64, -0.274), Vector3(0.91, 0.34, 0.012), Color(0.08, 0.085, 0.09))
	for i in range(3):
		var button := StaticBody3D.new()
		button.name = "Flavor_" + str(i)
		button.collision_layer = 4
		button.set_meta("action", "soda")
		button.set_meta("flavor", FLAVORS[i])
		add_child(button)
		button.position = Vector3((i - 1) * 0.285, 0.64, -0.262)
		_collision(button, Vector3(0.23, 0.18, 0.014), Vector3.ZERO)
		shift._box(button, Vector3.ZERO, Vector3(0.23, 0.18, 0.008), BANDS[i])
		var label: Label3D = shift._label(button, ["COLA", "LEMON\nFIZZ", "DR.\nPAW PAW"][i], Vector3(0, 0, 0.008), 0.00085)
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		label.font_size = 32
		label.outline_size = 5
	apply_flavor()

func _add_holder_rims() -> void:
	# The three imported stacks face outward along Z and taper toward their tips.
	var stacks := [
		[Vector3(1.392, 0.883, -6.656), -6.396, 0.085, 0.067],
		[Vector3(1.725, 0.882, -6.656), -6.430, 0.0675, 0.0535],
		[Vector3(2.039, 0.882, -6.653), -6.454, 0.0555, 0.044],
	]
	for cups in stacks:
		for depth in [0.29, 0.44, 0.59]:
			var radius := lerpf(cups[2], cups[3], depth)
			var rim := TorusMesh.new()
			rim.inner_radius = radius - 0.002
			rim.outer_radius = radius + 0.005
			rim.rings = 20
			rim.ring_segments = 8
			var lip: MeshInstance3D = shift._mesh(stack, rim, Vector3.ZERO, Color(0.36, 0.095, 0.09))
			lip.global_position = Vector3(cups[0].x, cups[0].y, lerpf(cups[0].z, cups[1], depth))
			lip.rotation.x = PI / 2

func interact(action: String) -> void:
	super.interact(action)
	if state == "empty": status.text = "SODA: SELECT A FLAVOR"

func flavor_prompt(flavor: String) -> String:
	if state != "empty": return prompt("soda")
	return "[Click / E] Pour " + flavor if holding_empty else "Pull an empty soda cup from the front holder first"

func choose_flavor(flavor: String) -> void:
	# A filled or filling cup retains its flavor even when another button is clicked.
	if state == "empty" and holding_empty and flavor in FLAVORS:
		drink_name = flavor
		apply_flavor()
	interact("soda")

func apply_flavor() -> void:
	var index := FLAVORS.find(drink_name)
	if index < 0: index = 0 # Compatibility with older generic soda saves.
	liquid_color = LIQUIDS[index]
	band_color = BANDS[index]
	if is_instance_valid(machine_cup): machine_cup.position.x = (index - 1) * 0.285
	if is_instance_valid(stream): stream.position.x = (index - 1) * 0.285
	if is_instance_valid(pour_audio): pour_audio.position = Vector3((index - 1) * 0.285, spout_position.y, spout_position.z)
	for node in [liquid, stream]:
		if is_instance_valid(node): node.material_override.albedo_color = liquid_color
	if is_instance_valid(machine_cup):
		var band := machine_cup.get_node_or_null("FlavorBand") as MeshInstance3D
		if band: band.material_override.albedo_color = band_color

func _cup(parent: Node3D) -> Node3D:
	var cup := super._cup(parent)
	var index := FLAVORS.find(drink_name)
	if index < 0: index = 0
	var band := _cylinder(cup, 0.064, 0.055, Vector3(0, 0.105, 0), BANDS[index])
	band.name = "FlavorBand"
	return cup

func drink_model(parent: Node3D, flavor: String) -> void:
	var cup := _cup(parent)
	var index := FLAVORS.find(flavor)
	if index < 0: index = 0
	cup.get_node("FlavorBand").material_override.albedo_color = BANDS[index]
	_cylinder(cup, fill_radius, 0.003, Vector3(0, fill_height, 0), LIQUIDS[index])

func _fill_cup(amount: float) -> void:
	super._fill_cup(amount)
	if is_instance_valid(pour_audio) and state == "brewing" and amount < 1.0 and not pour_audio.playing:
		pour_audio.play(amount * fill_seconds)

func _finish_brewing() -> void:
	if is_instance_valid(pour_audio): pour_audio.stop()
	super._finish_brewing()

func reset_station() -> void:
	if is_instance_valid(pour_audio): pour_audio.stop()
	drink_name = "Cola"
	super.reset_station()
	apply_flavor()
	status.text = "SODA: SELECT A FLAVOR"







func _replace_nozzles() -> void:
	# Remove the four molded spouts and levers from the imported mesh.
	var source: MeshInstance3D = shift.game.find_child("Soft_drink_dispenser_001", true, false)
	var cut := AABB(Vector3(1.28, 1.58, -7.18), Vector3(0.85, 0.32, 0.19))
	var rebuilt := ArrayMesh.new()
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
			var remove := true
			for corner in range(3):
				if not cut.has_point(source.global_transform * vertices[indices[triangle + corner]]): remove = false
			if remove: continue
			for corner in range(3):
				var id := indices[triangle + corner]
				builder.set_normal(normals[id])
				builder.set_uv(uvs[id])
				builder.add_vertex(vertices[id])
				count += 1
		if count > 0:
			builder.set_material(source.get_active_material(surface))
			builder.commit(rebuilt)
	source.mesh = rebuilt
	for child in source.get_children():
		if child is StaticBody3D:
			source.remove_child(child)
			child.queue_free()
	source.create_trimesh_collision()
	for i in range(3):
		var nozzle := Node3D.new()
		nozzle.name = "Nozzle_" + str(i)
		add_child(nozzle)
		nozzle.position = Vector3((i - 1) * 0.285, 0.41, -0.48)
		_cylinder(nozzle, 0.039, 0.11, Vector3.ZERO, Color(0.12, 0.13, 0.14))
		_cylinder(nozzle, 0.028, 0.018, Vector3(0, -0.061, 0), Color(0.035, 0.035, 0.04))
		shift._box(nozzle, Vector3(0, -0.09, -0.075), Vector3(0.062, 0.22, 0.022), Color(0.065, 0.07, 0.075))
		shift._box(nozzle, Vector3(0, -0.20, -0.052), Vector3(0.11, 0.025, 0.065), Color(0.065, 0.07, 0.075))
