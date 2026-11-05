extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.shift.set_process(false)
	var music = game.diner_music
	assert(music.playing and music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	assert(music.stream.get_length() > 33 and music.stream.get_length() < 34)
	await create_timer(1.4).timeout
	assert(is_equal_approx(music.volume_db, -13.0))
	music.seek(music.stream.get_length() - .15)
	await create_timer(.4).timeout
	assert(music.playing and music.get_playback_position() < 1.0, "Song loops at the actual ending")
	game.pause_menu.pause_game()
	await create_timer(.15).timeout
	var position: float = music.get_playback_position()
	await create_timer(.3).timeout
	assert(absf(music.get_playback_position()-position)<.02, "Music pauses with gameplay")
	game.pause_menu.resume_game()
	game.set_night(true)
	await create_timer(2.2).timeout
	assert(not music.playing and music.night and music.night_track.playing, "Night track replaces daytime music at closing")
	assert(music.night_track.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	game.pause_menu.pause_game()
	await create_timer(.15).timeout
	position = music.night_track.get_playback_position()
	await create_timer(.3).timeout
	assert(absf(music.night_track.get_playback_position()-position)<.02, "Night track pauses in Esc menu")
	game.pause_menu.resume_game()
	game.set_night(false)
	await create_timer(2.2).timeout
	assert(music.playing and not music.night and not music.night_track.playing and is_equal_approx(music.volume_db,-13.0))
	game.set_night(true)
	game.set_night(false)
	await create_timer(2.2).timeout
	assert(music.playing and is_equal_approx(music.volume_db,-13.0), "Interrupted fades recover")
	print("PASS: original diner track, seamless repeat, pause/resume, closing fade-out, new-day fade-in and interrupted transitions")
	quit()
