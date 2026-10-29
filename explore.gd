extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var spawn_point := Vector3.ZERO
var pitch := 0.0
var interaction_label: Label
var target_door: MeshInstance3D
var doors: Array[MeshInstance3D] = []
var target_action: Node
var shift: Node3D

func _ready() -> void:
	var diner = load("res://assets/DINER/Models/DINER.dae").instantiate()
	add_child(diner)
	preload("res://cooler.gd").install(diner)
	var bounds := AABB()
	var first := true
	for node in diner.find_children("*", "MeshInstance3D", true, false):
		if node.mesh:
			if "Collision" in node.name:
				node.visible = false
				continue
			var box: AABB = node.global_transform * node.mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
			node.create_trimesh_collision()
			if (node.name.begins_with("Door") and not node.name.begins_with("Door_frame")) or "Cubicles_Door" in node.name or "Refrigerator_Door" in node.name or "Oven_Door" in node.name or node.has_meta("cooler"):
				_setup_door(node)
	print("DINER_BOUNDS ", bounds)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.4, 0.55, 0.7)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.82, 0.88, 1.0)
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	player = CharacterBody3D.new()
	player.name = "Player"
	player.collision_mask = 3
	add_child(player)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 2.15
	shape.shape = capsule
	shape.position.y = 1.075
	player.add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 2.0
	camera.fov = 78
	camera.far = 1500
	player.add_child(camera)
	# Start on the dining room floor, facing the interior doors.
	spawn_point = Vector3(-2, 0.05, 0)
	player.position = spawn_point
	var ground := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(maxf(bounds.size.x + 30, 100), 1, maxf(bounds.size.z + 30, 100))
	floor_shape.shape = floor_box
	ground.position = Vector3(bounds.get_center().x, -0.85, bounds.get_center().z)
	ground.add_child(floor_shape)
	add_child(ground)
	var hud := CanvasLayer.new()
	add_child(hud)
	var label := Label.new()
	label.text = "PIEDAY\nWASD move  •  Mouse look  •  Shift sprint  •  Space jump\nE interact / doors  •  Click cups / coffee machine\nQ remove item / return cup  •  R respawn\nEsc release mouse  •  Click capture"
	label.position = Vector2(24, 20)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(label)
	interaction_label = Label.new()
	interaction_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	interaction_label.position = Vector2(520, 400)
	interaction_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	interaction_label.add_theme_constant_override("shadow_offset_x", 2)
	interaction_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(interaction_label)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(635, 348)
	hud.add_child(crosshair)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	shift = preload("res://shift.gd").new()
	add_child(shift)
	shift.setup(self)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * 0.0025)
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.5, 1.5)
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if event.keycode == KEY_R:
			player.position = spawn_point
			player.velocity = Vector3.ZERO
		if event.keycode == KEY_E and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if is_instance_valid(target_action):
				shift.interact(target_action)
			elif is_instance_valid(target_door):
				_toggle_door(target_door)
		if event.keycode == KEY_Q:
			shift.discard_last()
		if event.keycode == KEY_F6:
			shift.start_demo()
		if event.keycode == KEY_F7:
			shift.begin_prep()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and is_instance_valid(target_action) and target_action.get_meta("action", "") in ["coffee", "cup_stack", "tray", "pie", "donut", "soda", "soda_cup_stack", "customer", "bell"]:
			shift.interact(target_action)
			return
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var direction := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	direction = (player.basis * direction).normalized()
	var speed := 6.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 3.2
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed
	if not player.is_on_floor():
		player.velocity.y -= 18.0 * delta
	elif Input.is_physical_key_pressed(KEY_SPACE):
		player.velocity.y = 6.0
	var previous_position := player.position
	player.move_and_slide()
	# The two floor rectangles describe the dining room and rear rooms.
	var p := Vector2(player.position.x, player.position.z)
	var dining := Rect2(-10.35, -7.7, 21.4, 14.65)
	var rear := Rect2(-10.2, -14.35, 21.25, 6.95)
	if not (dining.has_point(p) or rear.has_point(p)):
		player.position.x = previous_position.x
		player.position.z = previous_position.z
	_update_interaction()
	if player.position.y < -100:
		player.position = spawn_point

func _setup_door(door: MeshInstance3D) -> void:
	doors.append(door)
	door.set_meta("closed_rotation", door.rotation.y)
	door.set_meta("open", false)
	var swing := deg_to_rad(95)
	if "Refrigerator_Door" in door.name or "Oven_Door" in door.name:
		# Appliance fronts face +Z. Each leaf swings away from its cabinet,
		# using the opposite direction for left and right hinge positions.
		var center: Vector3 = door.global_transform * door.mesh.get_aabb().get_center()
		swing *= -1.0 if center.x > door.global_position.x else 1.0
	if door.has_meta("cooler"):
		var center: Vector3 = door.global_transform * door.mesh.get_aabb().get_center()
		swing *= 1.0 if center.x > door.global_position.x else -1.0
	door.set_meta("swing_angle", swing)
	# Solid box shapes respond to interaction rays from either side of a leaf.
	# Imported triangle meshes may have no back face, preventing close prompts.
	for body in door.find_children("*", "StaticBody3D", true, false):
		if body.get_parent() == door:
			door.remove_child(body)
			body.queue_free()
	var body := StaticBody3D.new()
	body.name = "DoorCollision"
	body.set_meta("door", door)
	door.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var box := door.mesh.get_aabb()
	shape.size = Vector3(maxf(box.size.x, 0.05), maxf(box.size.y, 0.05), maxf(box.size.z, 0.05))
	collision.shape = shape
	collision.position = box.get_center()
	body.add_child(collision)
	# Exterior doors can swing, but their thresholds remain impassable.
	if door.name == "Door_03":
		var exit_box: AABB = door.global_transform * door.mesh.get_aabb()
		var barrier := StaticBody3D.new()
		barrier.name = "IndoorBoundary_" + door.name
		add_child(barrier)
		barrier.global_position = exit_box.get_center()
		var exit_collision := CollisionShape3D.new()
		var exit_shape := BoxShape3D.new()
		exit_shape.size = exit_box.size + Vector3(0.1, 0.1, 0.1)
		exit_collision.shape = exit_shape
		barrier.add_child(exit_collision)
		# Interaction rays ignore this boundary; player movement still hits it.
		barrier.collision_layer = 2

func _toggle_door(door: MeshInstance3D) -> void:
	if door.has_meta("tween"):
		var old_tween: Tween = door.get_meta("tween")
		if old_tween.is_valid():
			old_tween.kill()
	var opened: bool = not door.get_meta("open")
	door.set_meta("open", opened)
	var angle: float = door.get_meta("closed_rotation")
	if opened:
		angle += float(door.get_meta("swing_angle"))
	var tween := create_tween()
	tween.tween_property(door, "rotation:y", angle, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	door.set_meta("tween", tween)

func _update_interaction() -> void:
	target_door = null
	target_action = null
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 2.7, 5, [player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var node: Node = hit.collider
		while is_instance_valid(node):
			if node.has_meta("action"):
				target_action = node
				break
			if node.has_meta("door"):
				target_door = node.get_meta("door")
				break
			if node is MeshInstance3D and node in doors:
				target_door = node
				break
			node = node.get_parent()
	interaction_label.text = ""
	if is_instance_valid(shift):
		shift.target = target_action
	if is_instance_valid(target_action):
		interaction_label.text = shift.action_prompt(target_action)
	if is_instance_valid(target_door):
		interaction_label.text = "[E] " + ("Close door" if target_door.get_meta("open") else "Open door")
		if target_door.name == "Door_03":
			interaction_label.text += " (exterior access restricted)"
