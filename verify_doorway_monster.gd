extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	shift.begin_cleanup()
	var events = shift.closing_events
	events.encounter = "figure"
	events.figure_done = false
	events.bell_done = true
	events.flicker_done = true
	events.extra_done = true
	game.player.position = Vector3(1,-0.09,-18.2)
	game.camera.rotation = Vector3.ZERO
	var door = game.find_child("BackDoor",true,false)
	game._set_door_open(door,true)
	await create_timer(.6).timeout
	events.tick(100)
	assert(not events.figure.visible, "No monster before trash disposal")
	for id in shift.tasks: shift.tasks[id] = id != "trash"
	shift._set_carrying_trash(true)
	shift.interact(game.find_child("OutdoorDumpster",true,false))
	assert(events.trash_audio.playing and not events.monster_audio.playing, "Trash sounds at dumpster; monster is silent until seen")
	assert(shift.phase == "closed" and events.awaiting_doorway_scare(), "Last chore keeps encounter alive")
	events.tick(.1)
	assert(events.figure.visible and events.figure.global_position.z > -15, "Monster appears in doorway behind player")
	assert(not events._dumpster_bounds().intersects(events._figure_bounds(events.figure.global_position)))
	var saved = preload("res://save_states.gd").capture(game)
	assert(saved.events.trash_disposed and saved.events.figure_visible)
	game.camera.look_at(events.figure.global_position+Vector3(0,2.1,0))
	await physics_frame
	await physics_frame
	events.tick(.4)
	assert(events.monster_audio.playing, "Shadow sound starts with visible dissipation")
	assert(events.figure_seen and events.figure.visible, "Visible on turning back to the door")
	if DisplayServer.get_name() != "headless":
		await create_timer(.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/doorway-monster.png")
	events.tick(.2)
	assert(events.figure.visible and events.dissolve_elapsed >= 0.0)
	events.tick(.75)
	assert(events.figure_done and not events.figure.visible)
	events.tick(10)
	assert(not events.figure.visible)
	shift.begin_prep(false)
	assert(not events.active and not events.trash_disposed)
	print("PASS: disposal-triggered doorway monster, hidden until trash, final-chore handling, turn-around visibility, save capture, disappearance and next-day reset")
	quit()
