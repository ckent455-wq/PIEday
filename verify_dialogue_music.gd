extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.shift.start_demo()
	game.shift.customer_line.next_arrival = INF
	await create_timer(.3).timeout
	var actor := Node3D.new()
	actor.set_meta("display_name", "Test Customer")
	game.add_child(actor)
	var music = game.diner_music
	game.shift.dialogue.begin(actor,["Coffee"])
	await create_timer(.15).timeout
	var position: float = music.get_playback_position()
	var clock: float = game.shift.shift_remaining
	await create_timer(.4).timeout
	assert(paused and game.shift.dialogue.is_open)
	assert(music.get_playback_position() > position + .25, "Music continues through dialogue")
	assert(is_equal_approx(game.shift.shift_remaining,clock), "Dialogue still freezes shift clock")
	game.shift.dialogue.finish()
	game.pause_menu.pause_game()
	await create_timer(.15).timeout
	position = music.get_playback_position()
	await create_timer(.3).timeout
	assert(absf(music.get_playback_position()-position)<.02, "Esc pause still pauses music")
	game.pause_menu.resume_game()
	await create_timer(.3).timeout
	assert(music.get_playback_position() > position + .15)
	print("PASS: music continues during dialogue, shift clock stays frozen, pause-menu audio pause/resume preserved")
	quit()
