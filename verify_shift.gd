extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	assert(shift.held_tray.has_node("BlackCafeteriaTray"), "Serving tray must use the imported Blender model")
	assert(shift.held_tray.visible, "The empty tray should be visible")
	shift.set_process(false)
	assert(shift.phase == "prep")
	assert(not shift.start_shift(), "Dirty diner must not open")
	shift.complete_task("bathroom")
	shift.complete_task("kitchen")
	shift.interact(shift.task_nodes["trash"])
	assert(shift.carrying_trash and not shift.tasks.trash)
	shift.interact(shift.get_node("Station_dispose"))
	assert(shift.tasks.trash and not shift.carrying_trash)
	assert(shift.start_shift(), "Clean diner can open")
	shift.start_demo()
	for frame in range(620):
		shift._process(1.0 / 60.0)
	assert(shift.phase == "waiting", "Customer must arrive at counter")
	assert(shift.limbs.size() == 4, "Imported humanoid limbs must animate")
	var customer_body: Node
	for child in shift.customer.get_children():
		if child.has_meta("action"): customer_body = child
	game.camera.look_at(shift.customer.global_position + Vector3(0, 1.35, 0))
	await physics_frame
	game._update_interaction()
	print("COUNTER_RAY ", game.target_action)
	assert(game.target_action == customer_body, "Customer must be reachable from staff position")
	shift.interact(customer_body)
	assert(shift.order_taken)
	var pie: Node3D = shift.all_pies[0]
	var flavor: String = pie.get_meta("item")
	shift.add_item(flavor, pie)
	assert(not pie.visible)
	shift.discard_last()
	assert(pie.visible and shift.tray.is_empty())
	for item in shift.order:
		assert(shift.add_item(item))
	if DisplayServer.get_name() != "headless":
		shift._update_panel()
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/customer-scenario-preview.png")
	assert(shift.serve_order())
	assert(shift.served == 1 and not shift.angry and shift.phase == "leaving")
	for frame in range(1600): shift._process(1.0 / 60.0)
	assert(shift.phase == "waiting", "Next customer should arrive")
	for child in shift.customer.get_children():
		if child.has_meta("action"): customer_body = child
	shift.interact(customer_body)
	shift.add_item("Coffee")
	assert(not shift.serve_order())
	assert(shift.lost == 1 and shift.angry and shift.phase == "leaving")
	assert(shift.tray.is_empty())
	print("PASS: daily task gate, trash disposal, customer arrival, humanoid animation, counter interaction, pickup/return, correct order, angry wrong order, and next customer")
	quit()
