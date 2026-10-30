extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.customer_line.next_arrival = INF
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.begin_cleanup()
	assert(game.find_child("Stove_001", true, false) == null)
	assert(not shift.has_node("Station_dispose"), "Indoor disposal target must be removed")
	var door = game.find_child("BackDoor", true, false)
	assert(door in game.doors)
	game.player.position = Vector3(-0.6, -0.09, -13.1)
	game.camera.look_at(Vector3(-0.6, 1.2, -14.64))
	await physics_frame
	game._update_interaction()
	assert(game.target_door == door, "Back door must be targetable from the kitchen")
	for frame in range(60):
		await physics_frame
		game.player.velocity = Vector3(0, -1, -3)
		game.player.move_and_slide()
	print("CLOSED_DOOR_POSITION ", game.player.position)
	assert(game.player.position.z > -14.5, "Closed door blocks passage")
	game._toggle_door(door)
	await create_timer(0.6).timeout
	for frame in range(100):
		await physics_frame
		game.player.velocity = Vector3(0, -1, -3)
		game.player.move_and_slide()
	print("YARD_POSITION ", game.player.position)
	assert(game.player.position.z < -15.5, "Walk through the actual wall opening")
	assert(preload("res://service_yard.gd").WALK_AREA.has_point(Vector2(game.player.position.x, game.player.position.z)))
	assert(game.player.position.y > -0.3, "Yard has a solid floor")
	var dumpster = game.find_child("OutdoorDumpster", true, false)
	game.player.position = dumpster.global_position + Vector3(1.8, 0, 0)
	game.camera.look_at(dumpster.global_position + Vector3(0, 0.7, 0))
	await physics_frame
	game._update_interaction()
	assert(is_instance_valid(game.target_action) and game.target_action.get_meta("action") == "dispose", "Dumpster must be physically targetable")
	shift.interact(game.target_action)
	assert(not shift.tasks.trash, "Empty hands cannot finish the task")
	shift.interact(shift.task_nodes.trash)
	assert(shift.held_trash.visible)
	shift.interact(game.target_action)
	assert(shift.tasks.trash and not shift.carrying_trash and not shift.held_trash.visible)
	game.player.position = Vector3(-0.6, -0.09, -15.7)
	for frame in range(75):
		await physics_frame
		game.player.velocity = Vector3(0, -1, 3)
		game.player.move_and_slide()
	assert(game.player.position.z > -13.7, "Player can return to the kitchen")
	game._toggle_door(door)
	await create_timer(0.6).timeout
	assert(not door.get_meta("open"))
	print("PASS: grill removal, door targeting, closed collision, real wall opening, yard floor, dumpster targeting, trash disposal, held bag removal, return indoors and closing door")
	quit()
