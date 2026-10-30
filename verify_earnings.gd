extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var ledger = preload("res://earnings.gd").new(false)
	ledger.rng.seed = 1826
	assert(ledger.tip_chance(30,true) > ledger.tip_chance(90,true))
	assert(ledger.tip_chance(90,true) > ledger.tip_chance(130,true))
	assert(ledger.tip_chance(90,true) > ledger.tip_chance(90,false))
	var result = ledger.payout(["Meat pie","Apple pie","Cherry pie","Donut","Coffee","Soda"],true,60,true)
	assert(result.sale == 27)
	assert(result.total == result.sale + result.tip + result.service + result.streak_bonus and result.tip in [0,3,4,5,6,7,8])
	var cash: int = ledger.cash
	result = ledger.payout(["Meat pie"],false,1,true)
	assert(result.total == 0 and ledger.cash == cash)
	var tipped := false
	var untipped := false
	for sample in range(100):
		result = ledger.payout(["Soda"],true,90,false)
		assert(result.sale == 2 and result.tip in [0,3,4,5,6,7,8])
		tipped = tipped or result.tip > 0
		untipped = untipped or result.tip == 0
	assert(tipped and untipped, "Tips are possible but not guaranteed")
	cash = ledger.cash
	ledger.start_day()
	assert(ledger.sales == 0 and ledger.tips == 0 and ledger.cash == cash)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.customer_line.next_arrival = INF
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings = preload("res://earnings.gd").new(false)
	shift.earnings.rng.seed = 1924
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	for label in game.find_children("*","Label",true,false):
		assert(not label.text.contains("WASD"), "Top-left controls must be removed")
	for customer_index in range(4):
		for frame in range(1800): shift._process(1.0/60.0)
		assert(shift.phase == "waiting" and not shift.order_taken)
		assert(shift.service_seconds == 0 or customer_index > 0)
		var customer_body: Node
		for child in shift.customer.get_children():
			if child.has_meta("action"): customer_body = child
		shift.interact(customer_body)
		assert(shift.service_seconds == 0)
		shift._process(12)
		shift.interact(customer_body)
		assert(shift.service_seconds == 12, "Repeating an order must not reset tip timing")
		if customer_index < 2:
			for item in shift.order:
				var source: Node3D
				if item.ends_with("pie"):
					for pie in shift.all_pies:
						if pie.get_meta("item") == item:
							source = pie
							break
					source.set_meta("bake_quality","perfect")
				assert(shift.add_item(item, source))
		else:
			assert(shift.add_item("Coffee"))
		cash = shift.earnings.cash
		var expected_sale := 13 if customer_index == 0 else 8
		var correct: bool = shift.serve_order()
		if customer_index < 2:
			assert(correct and shift.payment_label.visible)
			assert(shift.earnings.cash - cash >= expected_sale + 35 + customer_index*5 and shift.earnings.cash - cash <= expected_sale + 43 + customer_index*5)
			if customer_index == 0 and DisplayServer.get_name() != "headless":
				await create_timer(0.2).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://../work/payment-preview.png")
		else:
			assert(not correct and shift.earnings.cash == cash)
		cash = shift.earnings.cash
		assert(not shift.serve_order() and shift.earnings.cash == cash, "Repeated serving cannot award twice")
	shift.shift_remaining = 0
	for frame in range(1800): shift._process(1.0/60.0)
	assert(shift.phase == "cleanup")
	for task in shift.tasks: shift.complete_task(task)
	assert(shift.phase == "closed")
	assert(shift.earnings.sales == 21)
	assert(shift.earnings.service_rewards == 70 and shift.earnings.streak_rewards == 5 and shift.earnings.closing_bonus == 100)
	cash = shift.earnings.cash
	assert(shift.earnings.finish_day() == 0 and shift.earnings.cash == cash, "Closing bonus cannot be claimed twice")
	assert(shift.notice.text.contains("Sales: $21") and shift.notice.text.contains("Tips:") and shift.notice_time == 0)
	cash = shift.earnings.cash
	shift.begin_prep()
	for task in shift.tasks: shift.complete_task(task)
	assert(shift.start_shift())
	assert(shift.earnings.sales == 0 and shift.earnings.tips == 0 and shift.earnings.cash == cash)
	print("PASS: menu prices, tip chance by speed/quality, tipped and untipped orders, first-order timer, no timer reset, exact payouts, wrong-order zero payout, duplicate protection, day summary, wallet carryover, day reset, controls removed; test writes no money saves")
	quit()
