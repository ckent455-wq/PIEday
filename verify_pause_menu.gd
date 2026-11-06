extends SceneTree
var failures := 0
func _initialize(): call_deferred("check")
func require(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func escape():
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event)
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.shift.earnings.save_enabled = false
	game.shift.start_demo()
	game.shift.coffee_station.interact("cup_stack")
	game.shift.coffee_station.interact("coffee")
	await create_timer(0.15).timeout
	var menu = game.pause_menu
	escape()
	require(paused and menu.is_open and menu.overlay.visible, "Esc opens pause menu through viewport input")
	require(menu.resume_button.has_focus(), "Keyboard focus starts at Resume")
	if DisplayServer.get_name() != "headless":
		require(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Pause releases cursor")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/pause-menu.png")
	var seconds: float = game.shift.shift_remaining
	var fill: float = game.shift.coffee_station.fill
	var at: Vector3 = game.player.position
	await create_timer(0.4).timeout
	require(is_equal_approx(seconds, game.shift.shift_remaining), "Shift timer is frozen")
	require(is_equal_approx(fill, game.shift.coffee_station.fill), "Brewing tween is frozen")
	require(game.player.position.is_equal_approx(at), "Player physics is frozen")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(20, 20)
	root.push_input(click)
	require(paused and menu.is_open, "Background clicks do not resume or interact")
	menu.restart_button.pressed.emit()
	require(menu.restart_dialog.visible, "Restart asks before discarding day progress")
	escape()
	await process_frame
	await process_frame
	require(paused and not menu.restart_dialog.visible, "Esc cancels restart and keeps game paused")
	menu.resume_button.pressed.emit()
	await process_frame
	await process_frame
	require(not paused and not menu.is_open, "Resume button unpauses")
	await create_timer(0.2).timeout
	require(game.shift.shift_remaining < seconds and game.shift.coffee_station.fill > fill, "Clock and brewing continue after resume")
	game.shift.begin_cleanup()
	var door = game.doors[0]
	game._set_door_open(door, not door.get_meta("open"))
	await create_timer(0.05).timeout
	escape()
	var elapsed: float = game.shift.closing_events.elapsed
	var angle: float = door.rotation.y
	await create_timer(0.3).timeout
	require(is_equal_approx(elapsed, game.shift.closing_events.elapsed), "Closing encounters freeze")
	require(is_equal_approx(angle, door.rotation.y), "Door animations freeze")
	escape()
	require(not paused and not menu.is_open, "Esc resumes")
	escape()
	menu.restart_day()
	await process_frame
	await process_frame
	require(not paused and current_scene != game and current_scene.shift.phase == "prep", "Restart reloads day and clears pause state")
	current_scene.shift.earnings.save_enabled = false
	if failures == 0: print("PASS: Esc/button pause and resume, timer/brewing/physics/doors/encounters freeze, restart confirmation, input isolation, restart reset")
	quit(1 if failures else 0)
