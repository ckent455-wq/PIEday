extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.start_demo()
	for frame in range(620): shift._process(1.0/60.0)
	await create_timer(0.2).timeout
	var bell = shift.service_bell
	assert(shift.held_tray.position.x < -3.0)
	assert(bell.position.x > shift.held_tray.position.x)
	assert(bell.sound.stream != null)
	shift.interact(bell)
	assert(shift.served == 0 and shift.lost == 0 and not shift.order_taken)
	var customer_body: Node
	for child in shift.customer.get_children():
		if child.has_meta("action"): customer_body = child
	shift.interact(customer_body)
	await create_timer(0.46).timeout
	shift.interact(bell)
	assert(shift.phase == "waiting" and shift.served == 0)
	for item in shift.order: shift.add_item(item)
	shift.interact(customer_body)
	assert(shift.phase == "waiting" and shift.served == 0, "Talking must never submit an order")
	game.player.position = Vector3(-3.1, -0.09, -5.6)
	for at in [shift.held_tray.position + Vector3(0,0.06,0), bell.position + Vector3(0,0.10,0)]:
		game.camera.look_at(at)
		await physics_frame
		game._update_interaction()
		assert(is_instance_valid(game.target_action))
	game.camera.look_at(Vector3(-3.25,1.25,-4.4))
	shift._update_panel()
	if DisplayServer.get_name() != "headless":
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/bell-tray-preview.png")
	await create_timer(0.46).timeout
	shift.interact(bell)
	assert(shift.served == 1 and shift.phase == "leaving" and shift.tray.is_empty())
	shift.interact(bell)
	assert(shift.served == 1)
	for frame in range(1600): shift._process(1.0/60.0)
	for child in shift.customer.get_children():
		if child.has_meta("action"): shift.interact(child)
	shift.add_item("Coffee")
	await create_timer(0.46).timeout
	shift.interact(bell)
	assert(shift.lost == 1 and shift.angry and shift.phase == "leaving")
	print("PASS: marked tray/bell placement, sound asset, physical targeting, bell-only submission, empty/no-order guards, correct and wrong orders, repeat-ring protection")
	quit()
