extends SceneTree
var failures := 0
func _initialize(): call_deferred("check")
func require(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func advance(shift, seconds: float):
	for frame in range(int(seconds * 60)): shift._process(1.0 / 60.0)
func check_evacuation(shift):
	shift.start_demo()
	var line = shift.customer_line
	line.nude_chance = 0.0
	line.next_arrival = INF
	advance(shift, 4)
	var counter: Node3D = shift.customer
	shift.order_taken = true
	shift.add_item("Coffee")
	var queued: Node3D = line.make_actor(Vector3(-1.55, -0.094, -2.05), "male_1")
	var queued_behind: Node3D = line.make_actor(Vector3(-0.75, -0.094, -0.55), "female_1")
	for actor in [queued, queued_behind]:
		line.waiting.append({"actor": actor, "seconds": 4.0, "junction": true})
	var seated: Node3D = line.make_actor(counter.position, "male_2")
	var dining = shift.dine_in
	require(dining.try_seat(seated, ["Coffee"], true), "Customer can take a booth before the robbery")
	dining.sit(dining.diners[0])
	var walking: Node3D = line.make_actor(counter.position, "female_2")
	require(dining.try_seat(walking, ["Coffee"], true), "Customer can be on their way to a booth")
	dining.tick(0.3)
	line.next_arrival = 0.0
	line.force_nude_next = true
	shift._process(1.0 / 60.0)
	require(shift.refusal_required() and shift.phase == "arriving", "Robber interrupts a full line and takes the counter")
	require(line.waiting.is_empty() and dining.diners.is_empty(), "Queue and dining area are evacuated")
	require(shift.tray == ["Coffee"] and shift.order.is_empty() and not shift.order_taken, "The interrupted order clears while prepared food stays")
	require(line.departing.size() == 5, "All five customers head for the exit")
	for entry in line.departing:
		require(entry.speed == line.EVACUATION_RUN_SPEED, "Evacuating customers run")
	line.next_arrival = 0.0
	advance(shift, 5)
	require(line.departing.is_empty() and shift.dialogue.is_open, "Evacuation completes before the robbery dialogue pauses play")
	require(line.waiting.is_empty() and line.next_arrival == 0.0, "Regular arrivals are suspended during the robbery")
	shift.dialogue.finish()
	shift.pistol.drawer_open = true
	shift.pistol.take()
	require(shift.pistol.fire(shift.customer.get_node("Interaction")), "The robber can be stopped after evacuation")
	shift.corpses.grab(shift.corpses.bodies[0].body)
	shift.corpses.dispose()
	advance(shift, 4)
	require(shift.phase == "waiting" and not shift.refusal_required(), "Regular service resumes after the robbery")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	shift.start_demo()
	var line = shift.customer_line
	line.next_arrival = INF
	line.force_nude_next = true
	line.force_nude_model = "robber_2"
	advance(shift, 4)
	require(shift.phase == "waiting" and shift.refusal_required(), "Adult encounter reaches counter")
	require(shift.dialogue.is_open and shift.dialogue.body.text == "Give me all your money!", "Robber speaks first")
	require(is_instance_valid(shift.customer.find_child("RobberGun", true, false)), "Robber carries a gun")
	require(shift.robbery.remaining < 0.0, "The countdown waits for the demand to close")
	shift.dialogue.finish()
	var actor = shift.customer
	var action = actor.get_node("Interaction")
	require(actor.get_meta("customer_model") == "robber_2", "Uses the clothed masked robber")
	require(shift.action_prompt(action).contains("Tell the robber to leave"), "Explicit refusal prompt")
	require(shift.order.is_empty() and not shift.order_taken, "No food order generated")
	if DisplayServer.get_name() != "headless":
		game.camera.look_at(actor.global_position + Vector3(0, 1.7, 0))
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/customer-import/refusal-counter.png")
	shift.earnings.streak = 3
	shift.earnings.cash = 1234
	shift.add_item("Coffee")
	var tray = shift.tray.duplicate()
	shift.service_bell.ring()
	require(not shift.serve_order() and shift.refusal_required(), "Cannot submit food to this customer")
	# A normal queued customer must move up immediately after refusal.
	var next: Node3D = line.make_actor(Vector3(-1.55, -0.094, -2.05))
	line.waiting.append({"actor": next, "seconds": 4.0, "junction": true})
	shift.interact(action)
	require(shift.customer == next and line.departing.size() == 1, "Refused customer leaves and queue advances")
	require(shift.earnings.cash == 0 and shift.robbery.blackout.visible, "Telling the robber to leave causes a blackout and empties the fund")
	require(shift.robbery.caption.text.contains("$1234"), "The blackout reports the amount stolen")
	require(shift.tray == tray, "Prepared food is preserved")
	require(actor.get_node("Interaction").get_meta("action") == "departing_customer", "No duplicate refusal")
	await create_timer(2.5).timeout
	advance(shift, 1)
	shift.interact(next.get_node("Interaction"))
	require(shift.order_taken and not shift.refusal_required(), "Next regular customer takes normal order")
	# Closing after a refusal still drains departures and starts cleanup.
	shift.start_demo()
	line.force_nude_next = true
	line.next_arrival = INF
	advance(shift, 4)
	shift.dialogue.finish()
	shift.shift_remaining = 0
	shift._process(0.1)
	require(shift.phase == "waiting" and shift.closing_time and shift.refusal_required(), "Closing preserves the chance to confront an active robber")
	require(shift.robbery.remaining == shift.robbery.REACTION_SECONDS, "The countdown starts when control returns")
	shift.earnings.cash = 800
	shift.robbery.tick(shift.robbery.REACTION_SECONDS - 0.1)
	require(shift.earnings.cash == 800 and not shift.robbery.blackout.visible, "The player gets the full response window")
	shift.robbery.tick(0.2)
	require(shift.earnings.cash == 0 and shift.robbery.blackout.visible, "Running out of time causes the same failure")
	advance(shift, 10)
	require(shift.phase == "cleanup", "Final refusal allows closing chores")
	await create_timer(2.5).timeout
	check_evacuation(shift)
	line.nude_chance = 1.0
	line.last_was_nude = false
	for i in range(6):
		var sample = line.make_actor(Vector3.ZERO)
		require(bool(sample.get_meta("requires_refusal")) == (i % 2 == 0), "Back-to-back special customers are prevented")
		sample.queue_free()
	if failures == 0: print("PASS: armed demand, countdown, blackouts, savings loss, closing and full-diner evacuation")
	quit(1 if failures else 0)
