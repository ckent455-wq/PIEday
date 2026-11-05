extends SceneTree
func _initialize(): call_deferred("check")
func key(down: bool):
	if down: Input.action_press("interact")
	else: Input.action_release("interact")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.begin_cleanup()
	shift.closing_events.active = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	shift.target = shift.task_nodes.kitchen
	key(true)
	await process_frame
	shift._update_cleaning(.2)
	assert(shift.scrubbing_audio.playing and shift.cleaning_progress > 0)
	key(false)
	await process_frame
	shift._update_cleaning(.1)
	assert(not shift.scrubbing_audio.playing and shift.cleaning_progress == 0)
	key(true)
	await process_frame
	shift._update_cleaning(.2)
	shift.target = null
	shift._update_cleaning(.1)
	assert(not shift.scrubbing_audio.playing, "Looking away stops scrub")
	shift.target = shift.task_nodes.kitchen
	shift._update_cleaning(1.6)
	assert(shift.tasks.kitchen and not shift.scrubbing_audio.playing, "Finishing stops scrub")
	shift.target = shift.task_nodes.trash
	shift._update_cleaning(.2)
	assert(not shift.scrubbing_audio.playing)
	shift.target = shift.task_nodes.bathroom
	shift._update_cleaning(.2)
	assert(shift.scrubbing_audio.playing)
	shift.begin_prep(false)
	assert(not shift.scrubbing_audio.playing)
	key(false)
	print("PASS: scrub only during held-E cleaning, immediate release/look-away/completion stop, trash silent, next-day reset")
	quit()
