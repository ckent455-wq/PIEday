extends SceneTree
func _initialize(): call_deferred("check")
func check():
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.shift.customer_line.next_arrival = INF
	game.shift.customer_line.nude_chance = 0.0
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	assert(shift.phase == "prep" and shift.tasks.values().all(func(done): return done))
	for task in shift.task_nodes.values(): assert(not task.visible)
	shift.donut_fryer.stock = [6,6,6]
	assert(shift.start_shift())
	for frame in range(620): shift._process(1.0/60.0)
	assert(shift.phase == "waiting")
	shift.shift_remaining = 0
	shift._process(0.1)
	assert(shift.phase == "cleanup" and not is_instance_valid(shift.customer), "Closing immediately ends service")
	for frame in range(1200): shift._process(1.0/60.0)
	assert(shift.phase == "cleanup" and not shift.tasks.bathroom and not shift.tasks.kitchen and not shift.tasks.trash)
	assert(shift.tasks.restock, "An untouched cooler needs no replenishment")
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
	assert(shift.phase == "closed" and shift.hospital_visits.menu.is_open,"Board offers evening departure instead of skipping it")
	shift.hospital_visits.menu.typewriter.reveal()
	shift.hospital_visits.menu._choose(1 if shift.hospital_visits.offered_visit else 0)
	await create_timer(1.5).timeout
	var morning = current_scene
	assert(morning.shift.phase == "prep" and not morning.get_node("NightInteriorLights").visible)
	assert(morning.shift.tasks.values().all(func(done): return done))
	morning.shift.donut_fryer.stock = [6,6,6]
	assert(morning.shift.start_shift() and morning.shift.shift_remaining == 180)
	print("PASS: immediate nighttime cleanup, board cannot skip chores, trash disposal, summary after chores, daylight next day")
	quit()
