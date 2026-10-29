extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.shift.set_process(false)
	game.shift.start_demo()
	for door in game.doors:
		if door.has_meta("cooler"):
			game._toggle_door(door)
	await create_timer(0.6).timeout
	for action in ["coffee", "donut", "soda", "clock"]:
		var station: Node3D = game.shift.get_node("Station_" + action)
		game.player.global_position = station.global_position + Vector3(0, -1.57, -1.1 if action in ["donut", "clock"] else 1.1)
		game.camera.look_at(station.global_position)
		await physics_frame
		game._update_interaction()
		assert(game.target_action == station, "Station must be reachable: " + action)
	for flavor in ["Meat pie", "Apple pie", "Cherry pie"]:
		var source: Node3D
		for pie in game.shift.all_pies:
			if pie.get_meta("item") == flavor and pie.name.begins_with("Pie_2_0"):
				source = pie
		game.player.position = Vector3(source.global_position.x, -0.09, -10.7)
		game.camera.look_at(source.global_position + Vector3(0, 0.10, 0))
		await physics_frame
		game._update_interaction()
		assert(game.target_action == source, "Pie must be reachable inside open cooler: " + flavor)
	print("PASS: coffee, donut, soda, shift board, and all three cooler pie flavors can be targeted from playable positions")
	quit()
