extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	shift.begin_cleanup()
	var events = shift.closing_events
	events.figure_done = false
	events.figure_at = 0
	events.extra_done = true
	events.bell_done = true
	events.flicker_done = true
	game.player.position = Vector3(1.0,-0.09,-18.2)
	events.encounter = "figure"
	events.figure_done = false
	game._set_door_open(game.find_child("BackDoor",true,false),true)
	await create_timer(.6).timeout
	game.camera.rotation = Vector3.ZERO
	events.on_trash_disposed()
	events.tick(.1)
	game.camera.look_at(events.figure.global_position+Vector3(0,2.1,0))
	await physics_frame
	await physics_frame
	events.tick(1.0/60.0)
	assert(events.figure.visible and events.dissolve_elapsed >= 0.0, "Dissolve begins on first frame seen")
	events.tick(.2)
	assert(events.figure.visible and events.dissolve_materials[0].get_shader_parameter("dissolve") > 0.0)
	events.tick(.5)
	assert(not events.figure.visible and events.figure_done)
	events.tick(10)
	assert(not events.figure.visible)
	print("PASS: immediate dissolve on first sight, no hold, quick dissipating effect, no respawn")
	quit()
