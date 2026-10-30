extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.player.position = Vector3(1.25, -0.09, -11.3)
	game.player.rotation.y = PI
	game.camera.rotation.x = -0.10
	await physics_frame
	var count := 0
	for door in game.doors:
		if door.has_meta("cooler"):
			count += 1
			var closed_center: Vector3 = door.global_transform * door.mesh.get_aabb().get_center()
			game._toggle_door(door)
			await create_timer(0.55).timeout
			var open_center: Vector3 = door.global_transform * door.mesh.get_aabb().get_center()
			assert(open_center.z < closed_center.z - 0.2, "Cooler doors must open outward")
	assert(count == 2)
	assert(game.find_children("Pie_*", "Node3D", true, false).size() == 24)
	assert(game.find_children("Pie_*", "Sprite3D", true, false).is_empty(), "Pies must be actual 3D models")
	for door in game.doors:
		if not door.has_meta("cooler"):
			continue
		var center: Vector3 = door.global_transform * door.mesh.get_aabb().get_center()
		var normal: Vector3 = door.global_basis.z.normalized()
		for side in [-1.0, 1.0]:
			game.player.global_position = center + normal * side * 0.65 - Vector3(0, 1.62, 0)
			game.camera.look_at(center, Vector3.UP)
			await physics_frame
			game._update_interaction()
			assert(game.target_door == door, "Open cooler door must be targetable from both sides: " + door.name)
	game.player.position = Vector3(1.25, -0.09, -11.3)
	game.player.rotation.y = PI
	game.camera.rotation = Vector3(-0.10, 0, 0)
	await create_timer(1).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/cooler-preview.png")
	for door in game.doors:
		if door.has_meta("cooler"):
			game._toggle_door(door)
	await create_timer(0.55).timeout
	game.camera.rotation.x = -0.1
	game.player.position.x = 0.8
	game._update_interaction()
	assert(is_instance_valid(game.target_door), "Closed cooler must be reachable by interaction ray")
	assert(game.target_door.has_meta("cooler"))
	game.player.position.x = 1.2476
	game._update_interaction()
	assert(is_instance_valid(game.target_door), "Meeting strip must cover the gap and allow interaction")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/cooler-closed-preview.png")
	print("PASS: cooler has two outward opening doors and 24 low-poly 3D pies")
	quit()
