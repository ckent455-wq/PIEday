extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	assert(shift.held_tray.has_node("BlackCafeteriaTray"), "Serving tray must use the imported Blender model")
	assert(shift.held_tray.visible, "The empty tray should be visible")
	shift.set_process(false)
	assert(shift.phase == "prep")
	assert(shift.tasks.values().all(func(done): return done), "No chores before opening")
	var board = shift.get_node("Station_clock")
	shift.interact(board)
	assert(shift.phase == "arriving", "Completed duties plus shift board must open the shift")
	var delay: float = shift.arrival_delay
	for press in range(5): shift.interact(board)
	assert(shift.phase == "arriving" and shift.arrival_delay == delay, "Repeated board presses must not restart duties or delay customers")
	assert(shift.tasks.values().all(func(done): return done))
	assert(not shift.start_shift(), "An active shift cannot be opened twice")
	shift.start_demo()
	for frame in range(620):
		shift._process(1.0 / 60.0)
	assert(shift.phase == "waiting", "Customer must arrive at counter")
	shift.interact(board)
	assert(shift.phase == "waiting" and is_instance_valid(shift.customer), "Board cannot reset a waiting customer")
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
	pie.set_meta("bake_quality", "perfect") # Oven flow is covered by verify_oven.gd.
	shift.add_item(flavor, pie)
	assert(not pie.visible)
	shift.discard_last()
	assert(pie.visible and shift.tray.is_empty())
	for item in shift.order:
		assert(shift.add_item(item, pie if item.ends_with("pie") else null))
	if DisplayServer.get_name() != "headless":
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
	shift.interact(board)
	assert(shift.phase == "leaving" and shift.tasks.values().all(func(done): return done), "Board cannot reset an active shift")
	shift.phase = "closed"
	shift.interact(board)
	assert(shift.phase == "prep" and shift.tasks.values().all(func(done): return done), "Next duties are available only after closing")
	print("PASS: daily task gate, trash disposal, customer arrival, humanoid animation, counter interaction, pickup/return, correct order, angry wrong order, and next customer")
	quit()
