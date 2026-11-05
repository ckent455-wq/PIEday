extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	var events = shift.closing_events
	assert(events.figure.has_node("MonsterModel") and not events.figure.has_node("MeshInstance3D"))
	var animated := false
	for player in events.figure.find_children("*","AnimationPlayer",true,false): animated = animated or player.is_playing()
	assert(animated, "Replacement monster retains an idle animation")
	var dumpster = game.find_child("OutdoorDumpster",true,false)
	var saved: Transform3D = dumpster.transform
	for offset in [Vector3.ZERO,Vector3(2.8,0,0),Vector3(1.4,0,1.0)]:
		dumpster.transform = saved
		dumpster.position += offset
		assert(events._place_figure(), "A safe spawn exists with the dumpster in alternate positions")
		assert(not events._dumpster_bounds().grow(0.25).intersects(events._figure_bounds(events.figure.global_position)), "Monster cannot intersect dumpster or collision hull")
	dumpster.transform = saved
	shift.begin_cleanup()
	events.encounter = "figure"
	events.figure_at = 0
	events.figure_done = false
	events.extra_done = true
	events.bell_done = true
	events.flicker_done = true
	assert(events._place_figure())
	game.player.position = Vector3(1.0,-0.09,-18.2)
	events.encounter = "figure"
	events.figure_done = false
	game._set_door_open(game.find_child("BackDoor",true,false),true)
	await create_timer(.6).timeout
	game.camera.rotation = Vector3.ZERO
	events.on_trash_disposed()
	events.tick(.1)
	game.camera.look_at(events.figure.global_position + Vector3(0,1.4,0))
	await physics_frame
	await physics_frame
	events.tick(0.4)
	assert(events.figure.visible and events.figure_seen)
	if DisplayServer.get_name() != "headless":
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/yard-monster.png")
	game.camera.rotate_y(PI)
	events.tick(1.1)
	events.tick(3.1)
	assert(not events.figure.visible and events.figure_done)
	print("PASS: local animated monster, no placeholder coat, safe spawn for default/moved dumpsters, collision clearance, visible at night, look-away disappearance")
	quit()
