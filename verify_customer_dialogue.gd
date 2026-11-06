extends SceneTree
var failures := 0
func _initialize(): call_deferred("check")
func require(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func key(code: int, pressed := true):
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.earnings.save_enabled = false
	shift.set_process(false)
	shift.start_demo()
	for frame in range(620): shift._process(1.0 / 60.0)
	shift.coffee_station.interact("cup_stack")
	shift.coffee_station.interact("coffee")
	game.camera.look_at(shift.customer.global_position + Vector3(0, 1.65, 0))
	await physics_frame
	shift.set_process(true)
	shift.interact(shift.customer.get_node("Interaction"))
	var chat = shift.dialogue
	var customer_name: String = shift.customer.get_meta("display_name")
	require(customer_name.split(" ").size() == 2 and chat.pages[0][0] == customer_name.to_upper(), "Generated name appears as dialogue speaker")
	var generated: Dictionary = {}
	var previous_name := ""
	for i in range(100):
		var sample: String = preload("res://customer_names.gd").generate()
		require(sample != previous_name, "Consecutive generated names differ")
		generated[sample] = true
		previous_name = sample
	require(generated.size() > 70, "Names combine varied first and last names")
	require(paused and chat.is_open and chat.pages.size() == 3, "Small talk, reply and order open paused")
	require(chat.typewriter.typing and chat.body.visible_characters == 0,"Dialogue starts hidden for typewriter reveal")
	require(chat.speaker.text.contains("CLOCK PAUSED"), "Player sees pause status")
	require(chat.pages[2][1].contains(shift.order[0]), "Dialogue contains actual order")
	var seconds: float = shift.shift_remaining
	var service: float = shift.service_seconds
	var fill: float = shift.coffee_station.fill
	var next_arrival: float = shift.customer_line.next_arrival
	await create_timer(0.4).timeout
	require(is_equal_approx(seconds, shift.shift_remaining) and is_equal_approx(service, shift.service_seconds), "Shift and tip timers do not advance")
	require(is_equal_approx(fill, shift.coffee_station.fill) and is_equal_approx(next_arrival, shift.customer_line.next_arrival), "Brewing and customer arrivals freeze")
	require(chat.body.visible_characters > 0 and chat.typewriter.typing,"Text types while the game is paused")
	key(KEY_SPACE)
	require(chat.page == 0 and chat.body.visible_characters == -1,"First Space reveals current line without skipping it")
	key(KEY_SPACE,false)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/customer-dialogue.png")
	key(KEY_SPACE)
	require(chat.page == 1 and chat.speaker.text.begins_with("YOU"), "Space advances to player reply")
	key(KEY_SPACE, false)
	chat.next_button.pressed.emit()
	await process_frame
	await process_frame
	require(chat.page == 1 and not chat.typewriter.typing,"First button click reveals the player reply")
	chat.next_button.pressed.emit()
	await process_frame
	await process_frame
	require(chat.page == 2 and chat.typewriter.typing,"Button advances to a typing order")
	chat.typewriter.reveal()
	require(chat.next_button.text == "Start order","Completed order shows its action")
	game.set_physics_process(true)
	key(KEY_E)
	await physics_frame
	await physics_frame
	require(not paused and not chat.is_open, "E finishes conversation without reopening")
	key(KEY_E, false)
	await create_timer(0.2).timeout
	require(shift.shift_remaining < seconds and shift.coffee_station.fill > fill, "Game continues after conversation")
	var service_before: float = shift.service_seconds
	shift.interact(shift.customer.get_node("Interaction"))
	require(paused and chat.pages.size() == 1 and shift.service_seconds == service_before, "Repeat interaction reminds order without resetting tips")
	require(chat.customer_name == customer_name, "Returning to the same customer preserves their name")
	key(KEY_ESCAPE)
	require(not paused and not chat.is_open and not game.pause_menu.is_open, "Esc ends chat without opening pause menu")
	shift.interact(shift.customer.get_node("Interaction"))
	shift.begin_cleanup()
	require(not paused and not chat.is_open and shift.phase == "cleanup", "Shift transition clears dialogue pause")
	if failures == 0: print("PASS: small talk and order, stopped shift/tip/brewing/arrival timers, keyboard/button advance, E release guard, reminders and clean exit")
	quit(1 if failures else 0)
