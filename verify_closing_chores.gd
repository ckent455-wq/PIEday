extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.customer_line.next_arrival = INF
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	assert(shift.phase == "prep" and shift.tasks.values().all(func(done): return done))
	for task in shift.task_nodes.values(): assert(not task.visible)
	assert(shift.start_shift())
	for frame in range(620): shift._process(1.0/60.0)
	assert(shift.phase == "waiting")
	shift.shift_remaining = 0
	shift._process(0.1)
	assert(shift.phase == "waiting", "Finish the last customer before chores")
	shift.order_taken = true
	shift.add_item("Coffee")
	shift.serve_order()
	for frame in range(1200): shift._process(1.0/60.0)
	assert(shift.phase == "cleanup" and shift.tasks.values().all(func(done): return not done))
	assert(game.get_node("NightInteriorLights").visible)
	shift.interact(shift.get_node("Station_clock"))
	assert(shift.phase == "cleanup", "Cannot skip closing chores at the board")
	shift.complete_task("bathroom")
	shift.complete_task("kitchen")
	assert(shift.phase == "cleanup")
	shift.interact(shift.task_nodes.trash)
	assert(shift.carrying_trash and shift.held_trash.visible)
	var dumpster = game.find_child("OutdoorDumpster", true, false)
	game.player.position = Vector3(0.1,-0.09,-16.4)
	game.camera.look_at(dumpster.global_position + Vector3(0,0.65,0))
	if DisplayServer.get_name() != "headless":
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/night-cleanup.png")
	shift.interact(dumpster)
	assert(shift.phase == "closed" and not shift.held_trash.visible)
	assert(shift.notice.text.contains("SHIFT COMPLETE"))
	shift.interact(shift.get_node("Station_clock"))
	assert(shift.phase == "prep" and not game.get_node("NightInteriorLights").visible)
	assert(shift.tasks.values().all(func(done): return done))
	assert(shift.start_shift() and shift.shift_remaining == 300)
	print("PASS: no morning chores, full service first, final customer completes, nighttime cleanup, board cannot skip chores, trash visual/disposal, summary after chores, daylight next day")
	quit()
