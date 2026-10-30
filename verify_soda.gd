extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.start_demo()
	shift.order_index = 1
	for frame in range(620): shift._process(1.0/60.0)
	var soda = shift.soda_station
	assert(soda.built_in_cup_holder and soda.stack_visual.get_child_count() == 0, "No separate soda cup stack")
	assert(soda.reference_cup_mesh.get_faces().size() == 57, "Use the exact 19-triangle source cup")
	assert(absf(soda.reference_cup_mesh.get_aabb().size.y - 0.2255) < 0.001)
	var coffee = shift.coffee_station
	soda.interact("soda")
	assert(soda.state == "empty" and shift.carried_item.is_empty())
	coffee.interact("cup_stack")
	soda.interact("soda_cup_stack")
	assert(soda.cups_left == 10 and not soda.holding_empty)
	soda.interact("soda")
	assert(soda.state == "empty", "Coffee cup cannot be used as soda cup")
	coffee.return_empty()
	soda.interact("soda_cup_stack")
	assert(soda.holding_empty and soda.cups_left == 9 and soda.held_cup.visible)
	coffee.interact("cup_stack")
	assert(coffee.cups_left == 10)
	assert(not shift.pickup_item("Donut"))
	soda.interact("soda")
	assert(soda.state == "brewing" and not soda.holding_empty and soda.stream.visible)
	soda.interact("soda")
	assert(shift.carried_item.is_empty())
	coffee.interact("cup_stack")
	coffee.interact("coffee")
	await create_timer(2.7).timeout
	assert(soda.state == "ready" and coffee.state == "ready" and not soda.stream.visible)
	game.player.position = Vector3(1.1,-0.09,-5.7)
	for action in ["soda", "soda_cup_stack"]:
		var at: Vector3 = soda.global_position if action == "soda" else soda.stack.global_position
		game.player.position.x = at.x
		game.camera.look_at(at)
		await physics_frame
		game._update_interaction()
		print("SODA_TARGET ", action, " ", game.target_action)
		assert(is_instance_valid(game.target_action) and game.target_action.get_meta("action") == action, "Dispenser and stack must be reachable from directly in front")
	game.camera.look_at(Vector3(1.35,1.6,-7.0))
	if DisplayServer.get_name() != "headless":
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/soda-station-preview.png")
	soda.interact("soda")
	assert(shift.carried_item == "Soda" and shift.tray.is_empty() and soda.state == "empty")
	coffee.interact("coffee")
	assert(coffee.state == "ready" and shift.carried_item == "Soda")
	shift.place_carried()
	var apple: Node3D
	for pie in shift.all_pies:
		if pie.get_meta("item") == "Apple pie":
			apple = pie
			break
	apple.set_meta("bake_quality", "perfect") # Oven flow is covered by verify_oven.gd.
	shift.pickup_item("Apple pie", apple)
	shift.place_carried()
	for child in shift.customer.get_children():
		if child.has_meta("action"): shift.interact(child)
	shift.interact(shift.service_bell)
	assert(shift.served == 1 and shift.phase == "leaving")
	shift.start_demo()
	assert(soda.state == "empty" and soda.cups_left == 10 and coffee.state == "empty" and coffee.cups_left == 10)
	soda.interact("soda_cup_stack")
	shift.discard_last()
	assert(not shift.has_empty_cup() and soda.cups_left == 10)
	print("PASS: soda cup required, cross-station hand locks, timed filling, no early pickup, simultaneous dispensers, physical targeting, full soda -> hand -> counter tray, apple/soda order served by bell, reset and return cup")
	quit()
