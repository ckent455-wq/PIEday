extends SceneTree
func _initialize(): call_deferred("check")
func check():
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var room=load("res://hospital_room.tscn").instantiate()
	root.add_child(room)
	current_scene=room
	room.set_physics_process(false)
	var music=room.hospital_music
	assert(music.playing and music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)
	await create_timer(2.1).timeout
	assert(is_equal_approx(music.volume_db,-17.0))
	music.seek(music.stream.get_length()-.15)
	await create_timer(.4).timeout
	assert(music.playing and music.get_playback_position()<1.0)
	var lines: Array[String]=["Test bedside conversation"]
	room.conversation.show_dialogue(lines)
	await create_timer(.1).timeout
	var at: float=music.get_playback_position()
	await create_timer(.3).timeout
	assert(paused and music.get_playback_position()>at+.15,"Hospital music continues through Grandpa dialogue")
	room.conversation.finish()
	room.paused.pause_game()
	await create_timer(.15).timeout
	at=music.get_playback_position()
	await create_timer(.3).timeout
	assert(absf(music.get_playback_position()-at)<.02,"Esc pauses hospital music")
	room.paused.resume_game()
	music.fade_out(.2)
	await create_timer(.3).timeout
	assert(music.volume_db < -59.0)
	var reference=weakref(music)
	room.queue_free()
	await process_frame
	assert(reference.get_ref()==null,"Music is removed when leaving the hospital scene")
	print("PASS: hospital theme loops, soft volume, uninterrupted Grandpa dialogue, pause/resume, departure fade and scene cleanup")
	quit()
