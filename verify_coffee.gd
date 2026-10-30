extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.customer_line.next_arrival = INF
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.shift.set_process(false)
	game.shift.start_demo()
	game.shift.customer_line.next_arrival = INF
	var station = game.shift.coffee_station
	station.interact("coffee")
	assert(station.state == "brewing" and station.cups_left == 9 and station.machine_cup.visible, "One click supplies a cup and starts filling")
	station.interact("coffee")
	assert(station.cups_left == 9 and game.shift.carried_item.is_empty(), "Repeated clicks cannot consume cups or collect early")
	station.reset_station()
	station.cups_left = 0
	station.interact("coffee")
	assert(station.state == "empty", "Quick brew cannot create cups from empty stock")
	station.reset_station()
	game.shift.pickup_item("Donut")
	station.interact("coffee")
	assert(station.state == "empty" and station.cups_left == 10, "A full hand cannot auto-load a cup")
	game.shift.discard_last()
	game.shift.soda_station.interact("soda_cup_stack")
	station.interact("coffee")
	assert(station.state == "empty" and station.cups_left == 10, "A soda cup cannot auto-load coffee")
	game.shift.soda_station.return_empty()
	station.interact("cup_stack")
	assert(station.holding_empty and station.cups_left == 9 and station.held_cup.visible)
	station.interact("cup_stack")
	assert(station.cups_left == 9)
	station.interact("coffee")
	assert(station.state == "brewing" and not station.holding_empty and game.shift.tray.is_empty())
	station.interact("coffee")
	assert(game.shift.tray.is_empty())
	await create_timer(2.7).timeout
	assert(station.state == "ready" and station.machine_cup.visible)
	game.player.position = Vector3(-2.4, -0.09, -5.5)
	game.camera.look_at(Vector3(-2.3, 1.5, -6.9))
	for action in ["coffee", "cup_stack"]:
		var at: Vector3 = station.global_position if action == "coffee" else station.stack.global_position + Vector3(0, 0.2, 0)
		game.camera.look_at(at)
		await physics_frame
		game._update_interaction()
		assert(is_instance_valid(game.target_action) and game.target_action.get_meta("action") == action, "Coffee station and stack must be reachable")
	game.camera.look_at(Vector3(-2.5, 1.5, -6.9))
	game.camera.look_at(station.global_position + Vector3(0.32, 0.22, 0))
	await physics_frame
	game._update_interaction()
	assert(game.target_action == station, "The edges of the machine should be easy to target")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/coffee-station-preview.png")
	station.interact("coffee")
	assert(game.shift.carried_item == "Coffee" and game.shift.tray.is_empty() and station.state == "empty")
	game.shift.place_carried()
	assert(game.shift.tray.size() == 1)
	station.interact("cup_stack")
	game.shift.discard_last()
	assert(not station.holding_empty and station.cups_left == 9 and game.shift.tray.size() == 1)
	station.interact("cup_stack")
	station.interact("coffee")
	await create_timer(2.7).timeout
	for i in range(5): game.shift.add_item("Donut")
	station.interact("coffee")
	assert(station.state == "empty" and game.shift.carried_item == "Coffee" and game.shift.tray.size() == 6)
	assert(not game.shift.place_carried())
	game.shift.discard_last()
	game.shift.discard_last()
	station.interact("cup_stack")
	station.interact("coffee")
	await create_timer(2.7).timeout
	game.shift.discard_last()
	station.interact("coffee")
	game.shift.place_carried()
	assert(station.state == "empty")
	station.interact("cup_stack")
	station.interact("coffee")
	station.reset_station()
	await create_timer(2.7).timeout
	assert(station.state == "empty" and station.cups_left == 10 and not station.held_cup.visible)
	print("PASS: one-click brew, stock and full-hand guards, soda cup guard, manual cup option, timed fill, no early pickup, wider physical targeting, full cup to tray, full-tray retention, return cup, reset during brewing")
	quit()
