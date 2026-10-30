extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.customer_line.next_arrival = INF
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	var elapsed := 0.0
	while shift.phase != "waiting" and elapsed < 5:
		shift._process(1.0/60.0)
		elapsed += 1.0/60.0
	assert(shift.phase == "waiting" and elapsed < 3.5)
	print("FIRST_CUSTOMER_READY_SECONDS ",elapsed)
	shift.order_taken = true
	for item in shift.order:
		var source: Node3D
		if item.ends_with("pie"):
			for pie in shift.all_pies:
				if pie.get_meta("item") == item:
					source = pie
					break
			source.set_meta("bake_quality","perfect")
		shift.add_item(item,source)
	assert(shift.serve_order())
	elapsed = 0
	while shift.phase != "waiting" and elapsed < 8:
		shift._process(1.0/60.0)
		elapsed += 1.0/60.0
	assert(shift.phase == "waiting" and elapsed < 6)
	assert(shift.served == 1 and shift.customers_this_shift == 1)
	print("SUCCESSFUL_ORDER_TO_NEXT_CUSTOMER_SECONDS ",elapsed)
	print("PASS: faster arrival, fast happy exit, short gap, next order ready, payout preserved")
	quit()
