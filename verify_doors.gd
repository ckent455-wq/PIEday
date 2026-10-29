extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	for door in game.doors:
		if door.get_meta("open"): game._toggle_door(door)
	await create_timer(0.55).timeout
	assert(game.doors.size() == 13, "Expected all 13 building, cubicle, cooler and appliance doors")
	for door in game.doors:
		var closed: float = door.rotation.y
		var closed_center: Vector3 = door.global_transform * door.mesh.get_aabb().get_center()
		game._toggle_door(door)
		await create_timer(0.55).timeout
		assert(absf(door.rotation.y - closed - float(door.get_meta("swing_angle"))) < 0.01)
		if "Refrigerator_Door" in door.name or "Oven_Door" in door.name:
			var open_center: Vector3 = door.global_transform * door.mesh.get_aabb().get_center()
			assert(open_center.z > closed_center.z + 0.15, "Appliance door must open outward: " + door.name)
		game._toggle_door(door)
		await create_timer(0.55).timeout
		assert(absf(door.rotation.y - closed) < 0.01)
	assert(game.player.is_on_floor(), "Indoor spawn must settle on floor")
	assert(game.player.position.distance_to(Vector3(-2, -0.094, 0)) < 0.2)
	assert(game.get_node("IndoorBoundary_Door_03").collision_layer == 2)
	assert(not game.has_node("IndoorBoundary_Door_02"), "Freezer is an interior room")
	print("PASS: 13 doors open and close; indoor spawn on floor; exterior barriers active.")
	quit()

