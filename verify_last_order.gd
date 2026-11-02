extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func require(ok: bool,message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	for i in range(620): shift._process(1.0/60)
	var active = shift.customer
	shift.order.assign(["Soda"])
	shift.order_taken = true
	shift.pickup_item("Soda")
	shift.customer_line.waiting.append({"actor":shift.customer_line.make_actor(Vector3(0,-.094,2)),"seconds":10.0,"junction":true})
	shift.shift_remaining = .1
	shift._process(.2)
	require(shift.phase == "waiting" and shift.customer == active and shift.closing_time,"Accepted customer stays after expiry")
	require(shift.order_taken and shift.carried_item == "Soda" and shift.order == ["Soda"],"Current order and held item are preserved")
	require(shift.customer_line.waiting.is_empty() and shift.customer_line.departing.size() == 1,"Queue leaves immediately")
	require(shift.shift_clock.text == "CLOSED · LAST ORDER" and shift.shift_remaining == 0,"HUD explains last order and clock stays at zero")
	shift.customer_line.next_arrival = 0
	shift._spawn_customer()
	shift._process(30)
	require(shift.customer == active and shift.customer_line.waiting.is_empty() and shift.phase == "waiting","No new customers or forced cleanup during final order")
	var snapshot := preload("res://save_states.gd").capture(game)
	require(snapshot.shift.closing_time and snapshot.shift.order_taken and snapshot.shift.shift_remaining == 0,"Manual save captures final-order state")
	require(shift.place_carried() and shift.serve_order(),"Final order can be placed and served correctly")
	require(shift.phase == "cleanup" and shift.served == 1 and shift.earnings.correct_orders == 1,"Paid final order leads directly to chores")
	# A wrong final order still resolves service and allows closing.
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	for i in range(620): shift._process(1.0/60)
	shift.order.assign(["Coffee"])
	shift.order_taken = true
	shift.add_item("Soda")
	shift.shift_remaining = .1
	shift._process(.2)
	require(not shift.serve_order() and shift.phase == "cleanup","Incorrect final order ends service normally")
	# An untaken order does not keep an entire queue after hours.
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	for i in range(620): shift._process(1.0/60)
	shift.shift_remaining = .1
	shift._process(.2)
	require(shift.phase == "cleanup" and not is_instance_valid(shift.customer),"Customer without an accepted order leaves at closing")
	if failures == 0: print("PASS: last accepted order survives closing, queue exits, no arrivals, held food preserved, save state retained, correct/wrong serving then chores, untaken orders leave")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
