extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.customer_line.next_arrival = INF
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
	assert(shift.phase == "prep", "Clipboard must direct players to the window sign")
	shift.donut_fryer.stock = [6,6,6]
	shift.interact(shift.open_sign)
	assert(shift.phase == "arriving", "Stocked donuts and neon sign open the shift")
	var delay: float = shift.arrival_delay
	for press in range(5): shift.interact(board)
	assert(shift.phase == "arriving" and shift.arrival_delay == delay, "Repeated board presses must not restart duties or delay customers")
	assert(shift.tasks.values().all(func(done): return done))
	assert(not shift.start_shift(), "An active shift cannot be opened twice")
	shift.start_demo()
	shift.customer_line.next_arrival = INF
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
	assert(shift.phase == "closed" and shift.hospital_visits.menu.is_open, "Closed shift board opens evening departure choices")
	shift.hospital_visits.menu.finish()
	shift.begin_prep(false)
	assert(shift.phase == "prep" and shift.tasks.values().all(func(done): return done), "Next morning starts clean after evening flow")
	shift.earnings.grandpa.days = 1
	shift.donut_fryer.stock = [6,6,6]
	assert(shift.start_shift())
	shift.customer_line.nude_chance = 0.0
	var previous := -1
	for i in range(12):
		shift._spawn_customer()
		assert(shift.last_recipe_index != previous, "Campaign avoids consecutive recipe repeats")
		previous = shift.last_recipe_index
		if shift.order.any(func(item): return item in shift.BURGER_STATION.BURGERS):
			assert(shift.order.has(shift.FRIES.SERVING), "Every burger comes with fries")
		shift._reset_customer()
		shift.order_index += 1
	for burger in shift.BURGER_STATION.BURGERS:
		assert(shift.ORDERS.any(func(recipe): return burger in recipe and shift.FRIES.SERVING in recipe))
	seed(130)
	for day in 200:
		shift.fries_order_offered = false
		shift.last_recipe_index = -1
		for index in 3:
			shift.order_index = index
			shift._pick_random_order()
		assert(shift.fries_order_offered, "Fries appear within the first three food orders")
	print("PASS: daily task gate, trash disposal, customer arrival, humanoid animation, counter interaction, pickup/return, correct order, angry wrong order, and next customer")
	quit()
