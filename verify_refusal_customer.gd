extends SceneTree
var failures := 0
func _initialize(): call_deferred("check")
func require(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func advance(shift, seconds: float):
	for frame in range(int(seconds * 60)): shift._process(1.0 / 60.0)
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
	advance(shift, 4)
	require(shift.phase == "waiting" and shift.refusal_required(), "Adult encounter reaches counter")
	var actor = shift.customer
	var action = actor.get_node("Interaction")
	require(actor.get_meta("customer_model") == "adult_unclothed", "Uses downloaded adult base")
	require(shift.action_prompt(action).contains("Refuse service"), "Explicit refusal prompt")
	require(shift.order.is_empty() and not shift.order_taken, "No food order generated")
	if DisplayServer.get_name() != "headless":
		game.camera.look_at(actor.global_position + Vector3(0, 1.7, 0))
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/customer-import/refusal-counter.png")
	shift.earnings.streak = 3
	var cash: int = shift.earnings.cash
	shift.add_item("Coffee")
	var tray = shift.tray.duplicate()
	shift.service_bell.ring()
	require(not shift.serve_order() and shift.refusal_required(), "Cannot submit food to this customer")
	# A normal queued customer must move up immediately after refusal.
	var next: Node3D = line.make_actor(Vector3(-1.55, -0.094, -2.05))
	line.waiting.append({"actor": next, "seconds": 4.0, "junction": true})
	shift.interact(action)
	require(shift.customer == next and line.departing.size() == 1, "Refused customer leaves and queue advances")
	require(shift.earnings.cash == cash and shift.earnings.streak == 3 and shift.served == 0 and shift.lost == 0, "Refusal is penalty-free")
	require(shift.tray == tray, "Prepared food is preserved")
	require(actor.get_node("Interaction").get_meta("action") == "departing_customer", "No duplicate refusal")
	advance(shift, 1)
	shift.interact(next.get_node("Interaction"))
	require(shift.order_taken and not shift.refusal_required(), "Next regular customer takes normal order")
	# Closing after a refusal still drains departures and starts cleanup.
	shift.start_demo()
	line.force_nude_next = true
	line.next_arrival = INF
	advance(shift, 4)
	shift.shift_remaining = 0
	shift._process(0.1)
	require(shift.phase == "cleanup" and not shift.refusal_required(), "Closing dismisses even special customers immediately")
	advance(shift, 10)
	require(shift.phase == "cleanup", "Final refusal allows closing chores")
	line.nude_chance = 1.0
	line.last_was_nude = false
	for i in range(6):
		var sample = line.make_actor(Vector3.ZERO)
		require(bool(sample.get_meta("requires_refusal")) == (i % 2 == 0), "Back-to-back special customers are prevented")
		sample.queue_free()
	if failures == 0: print("PASS: adult appearance, refusal prompt, blocked serving, penalty-free exit, tray preserved, queue handoff and closing")
	quit(1 if failures else 0)
