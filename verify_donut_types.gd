extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.shift.set_process(false)
	game.shift.start_demo()
	game.shift.customer_line.next_arrival = INF
	for frame in range(620): game.shift._process(1.0 / 60.0)
	var types = preload("res://donut_types.gd").TYPES
	for i in range(3):
		game.player.position = Vector3(-0.27 + i * 0.49, -0.09, -3.3)
		game.camera.look_at(Vector3(-0.27 + i * 0.49, 1.46, -4.55))
		await create_timer(0.15).timeout
		await physics_frame
		await physics_frame
		game._update_interaction()
		assert(is_instance_valid(game.target_action) and game.target_action.get_meta("action") == "donut")
		assert(game.target_action.get_meta("item") == types[i], "Aim selects matching case section")
		game.shift.interact(game.target_action)
		assert(game.shift.carried_item == types[i])
		assert(game.shift.carried_visual.find_child("Icing", true, false) != null)
		assert(game.shift.place_carried())
	assert(game.shift.tray == types)
	game.shift.order.assign(types)
	game.shift.phase = "waiting"
	game.shift.order_taken = true
	assert(game.shift.serve_order(), "Three flavors can be served together")
	assert(game.shift.earnings.sales == 6)
	for item in types:
		assert(game.shift.earnings.PRICES[item] == 2)
	var counts = {}
	for m in game.find_children("Donus*", "MeshInstance3D", true, false):
		var item = m.get_meta("item")
		counts[item] = counts.get(item, 0) + 1
		assert(m.get_node("Icing").material_override.albedo_color == preload("res://donut_types.gd").COLORS[types.find(item)])
	assert(counts.size() == 3)
	game.player.position = Vector3(0.2,0.2,-3.85)
	game.camera.look_at(Vector3(0.2,1.4,-4.65))
	if DisplayServer.get_name() != "headless":
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/donut-case.png")
	print("PASS: three visible donut flavors, case ray selection, held icing, tray, orders and $2 pricing ", counts)
	quit()
