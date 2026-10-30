extends SceneTree
func _initialize(): call_deferred("check")
func advance(shift, seconds: float):
	for frame in range(int(seconds*60)): shift._process(1.0/60.0)
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	shift.start_demo()
	advance(shift,22)
	assert(shift.phase == "waiting" and shift.customer_line.waiting.size() == 2)
	var line = shift.customer_line
	for i in range(2):
		assert(line.waiting[i].actor.position.distance_to(Vector3(-1.55+i*0.8,-0.094,-2.05+i*1.5)) < 0.01)
	if DisplayServer.get_name() != "headless":
		game.player.position = Vector3(-2.5,-0.09,-5.6)
		game.camera.look_at(Vector3(-2.4,1.2,-1.8))
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/customer-line.png")
	var old = shift.customer
	var next = line.waiting[0].actor
	shift.order_taken = true
	shift.add_item("Coffee")
	shift.serve_order()
	assert(shift.customer == next and line.departing.size() == 1 and is_instance_valid(old))
	advance(shift,0.5)
	assert(shift.phase == "waiting", "Next customer reaches the counter without waiting for the exit")
	assert(is_instance_valid(old), "Old customer can still be walking out")
	advance(shift,12)
	assert(line.waiting.size() == 2, "Queue refills but stays capped")
	var lost_before: int = shift.lost
	var cash_before: int = shift.earnings.cash
	var streak_before: int = shift.earnings.streak
	shift.shift_remaining = 0
	shift._process(0.1)
	assert(shift.phase == "cleanup" and line.waiting.is_empty() and not is_instance_valid(shift.customer))
	assert(line.departing.size() == 3, "Active customer and queued customers walk out immediately")
	assert(shift.lost == lost_before and shift.earnings.cash == cash_before and shift.earnings.streak == streak_before, "Closing does not penalize pending orders")
	advance(shift,12)
	assert(line.waiting.is_empty() and line.departing.is_empty())
	shift.start_demo()
	advance(shift,75)
	assert(line.waiting.size() == 2 and line.waiting[0].seconds > 60)
	shift.order_taken = true
	shift.add_item("Coffee")
	shift.serve_order()
	assert(float(shift.customer.get_meta("queue_wait")) > 60)
	shift.begin_prep()
	assert(line.waiting.is_empty() and line.departing.is_empty())
	print("PASS: three-person queue, handoff, refill, immediate penalty-free closing evacuation, no late arrivals, next-day reset")
	quit()
