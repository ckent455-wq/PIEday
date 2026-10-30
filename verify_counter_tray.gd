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
	var shift = game.shift
	shift.set_process(false)
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	for frame in range(620): shift._process(1.0 / 60.0)
	await physics_frame
	await physics_frame
	await physics_frame
	await create_timer(0.2).timeout
	assert(shift.held_tray.get_parent() == shift)
	var tray_position: Vector3 = shift.held_tray.global_position
	print("COUNTER_TRAY ", tray_position)
	assert(tray_position.y > 1.0 and tray_position.y < 1.6)
	var tray_target: Node
	for node in shift.held_tray.get_children():
		if node.has_meta("action"): tray_target = node
	for child in shift.customer.get_children():
		if child.has_meta("action"): shift.interact(child)
	var station = shift.coffee_station
	station.interact("cup_stack")
	station.interact("coffee")
	await create_timer(2.7).timeout
	station.interact("coffee")
	assert(shift.carried_item == "Coffee" and shift.tray.is_empty())
	assert(not shift.pickup_item("Donut"), "Only one item can be held")
	shift.interact(tray_target)
	assert(shift.carried_item.is_empty() and shift.tray == ["Coffee"])
	var pie: Node3D
	for node in shift.all_pies:
		if node.get_meta("item") == "Meat pie":
			pie = node
			break
	shift.interact(pie)
	assert(shift.carried_item == "Meat pie" and not pie.visible and shift.tray.size() == 1)
	assert(not shift.serve_order(), "Held food must be placed before serving")
	pie.set_meta("bake_quality", "perfect") # Oven flow is covered by verify_oven.gd.
	shift.interact(tray_target)
	shift.pickup_item("Donut")
	shift.interact(tray_target)
	assert(shift.tray.size() == 3)
	shift.interact(tray_target)
	assert(shift.carried_item == "Donut" and shift.tray.size() == 2)
	shift.interact(tray_target)
	game.player.position = Vector3(-2.0, -0.09, -5.85)
	game.camera.look_at(shift.held_tray.global_position + Vector3(0, 0.06, 0))
	await physics_frame
	game._update_interaction()
	assert(game.target_action == tray_target, "Counter tray must be targetable from staff position")
	assert(shift.held_tray.global_position.is_equal_approx(tray_position), "Tray must stay fixed when player moves")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/counter-tray-preview.png")
	assert(shift.serve_order() and shift.tray.is_empty())
	assert(shift.held_tray.visible and shift.held_tray.global_position.is_equal_approx(tray_position))
	shift.begin_prep()
	assert(pie.visible and shift.carried_item.is_empty())
	print("PASS: stationary world tray, coffee brew -> hand -> tray, pie pickup -> placement, single hand slot, removal/replacement, physical targeting, exact order, persistent tray after serving, reset")
	quit()
