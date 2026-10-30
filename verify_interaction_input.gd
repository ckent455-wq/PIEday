extends SceneTree

func _initialize(): call_deferred("check")

func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	var shift = game.shift
	shift.earnings.save_enabled = false
	shift.set_process(false)
	shift.start_demo()
	for frame in range(600): shift._process(1.0 / 60.0)
	game.player.position = Vector3(-2.4, -0.09, -5.6)
	game.camera.look_at(shift.customer.global_position + Vector3(0, 1.7, 0))
	await physics_frame
	await physics_frame
	game._update_interaction()
	print("TARGET: ", game.target_action, " PROMPT: ", game.interaction_label.text)
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.physical_keycode = KEY_E
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	game.set_physics_process(true)
	await physics_frame
	await physics_frame
	print("ORDER TAKEN: ", shift.order_taken, " CAPTURE: ", Input.mouse_mode)
	if not shift.order_taken:
		quit(1)
		return
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await physics_frame
	await physics_frame
	var station = shift.get_node("Station_coffee")
	game.player.global_position = station.global_position + Vector3(0, 0, 1.1)
	game.player.position.y = -0.09
	game.camera.look_at(station.global_position)
	await physics_frame
	await physics_frame
	key = key.duplicate()
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await physics_frame
	await physics_frame
	if shift.coffee_station.state == "empty":
		push_error("E did not start coffee preparation")
		quit(1)
		return
	print("PASS: physical E takes customer order and starts coffee through real physics ticks")
	quit()
