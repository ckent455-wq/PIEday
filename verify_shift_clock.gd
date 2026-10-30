extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.customer_line.next_arrival = INF
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings = preload("res://earnings.gd").new(false)
	shift._process(600)
	assert(shift.phase == "prep" and shift.shift_remaining == 300, "Chores do not consume service time")
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	assert(shift.shift_clock.text == "SHIFT  5:00")
	# Expiry during the gap before an arrival closes without spawning anyone.
	shift.shift_remaining = 0.1
	shift._process(0.2)
	assert(shift.phase == "cleanup")
	for task in shift.tasks: shift.complete_task(task)
	assert(shift.phase == "closed" and not is_instance_valid(shift.customer) and shift.arrival_delay == 0)
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	for frame in range(620): shift._process(1.0/60.0)
	assert(shift.phase == "waiting")
	var last_customer = shift.customer
	shift.shift_remaining = 0.1
	shift._process(0.2)
	assert(shift.closing_time and shift.phase == "waiting" and shift.customer == last_customer)
	assert(shift.shift_clock.text == "CLOSING - FINISH THE LINE")
	shift._spawn_customer()
	assert(shift.customer == last_customer, "Closing cannot spawn a new customer")
	shift.order_taken = true
	shift.add_item("Soda")
	shift.serve_order()
	for frame in range(1200): shift._process(1.0/60.0)
	assert(shift.phase == "cleanup")
	for task in shift.tasks: shift.complete_task(task)
	assert(shift.phase == "closed" and shift.shift_clock.text == "CLOSED")
	shift.begin_prep()
	assert(shift.shift_remaining == 300 and not shift.closing_time)
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	shift.customers_this_shift = 4
	for frame in range(620): shift._process(1.0/60.0)
	shift.order_taken = true
	shift.add_item("Soda")
	shift.serve_order()
	for frame in range(1600): shift._process(1.0/60.0)
	assert(shift.phase == "waiting" and shift.customers_this_shift == 5, "More than four customers allowed before closing")
	print("PASS: five-minute timer, chores untimed, no late arrivals, last customer finishes, day summary, next-day reset, no four-customer cap")
	quit()
