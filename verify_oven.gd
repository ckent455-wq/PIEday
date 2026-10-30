extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.earnings.save_enabled = false
	shift.start_demo()
	shift.set_process(false)
	for frame in range(620): shift._process(1.0 / 60.0)
	var oven = shift.oven
	oven.set_process(false)
	for prop in ["Bread", "Bread_01"]:
		var node = game.find_child(prop, true, false)
		assert(not node.visible)
		for body in node.find_children("*", "StaticBody3D", true, false): assert(body.collision_layer == 0)
	var pie = shift.all_pies[0]
	assert(shift.pickup_item(pie.get_meta("item"), pie))
	assert(not shift.place_carried(), "Raw pies cannot go straight to the tray")
	oven.interact()
	assert(oven.pie_item.is_empty(), "Closed doors prevent loading")
	var other_states := {}
	for door in game.doors:
		if door not in oven.doors: other_states[door] = door.get_meta("open")
	game._toggle_door(oven.doors[0])
	assert(oven.all_open(), "Either oven door opens both leaves")
	for door in other_states: assert(door.get_meta("open") == other_states[door], "Other doors must stay unchanged")
	await create_timer(0.5).timeout
	oven.interact()
	assert(not oven.pie_item.is_empty() and shift.carried_item.is_empty())
	oven._process(10)
	assert(oven.elapsed == 0, "Open doors cannot bake")
	game._toggle_door(oven.doors[0])
	oven._process(10)
	assert(oven.elapsed == 0, "Wait until the doors finish closing")
	await create_timer(0.5).timeout
	oven._process(4)
	assert(oven.quality() == "undercooked")
	game._toggle_door(oven.doors[0])
	oven._process(10)
	assert(oven.elapsed == 4, "Opening either door stops heat immediately")
	game._toggle_door(oven.doors[0])
	await create_timer(0.5).timeout
	oven._process(3)
	assert(oven.quality() == "perfect")
	oven.interact()
	assert(shift.carried_item.is_empty(), "Closed doors prevent retrieval")
	game._toggle_door(oven.doors[1])
	assert(oven.all_open(), "The other oven door also controls both leaves")
	await create_timer(0.5).timeout
	# Confirm a player can aim at the pie through the actual open doors.
	game.player.position = Vector3(4.25, -0.09, -12.6)
	game.camera.look_at(oven.global_position)
	await physics_frame
	game._update_interaction()
	assert(game.target_action == oven, "Open oven must be reachable with the interaction ray")
	oven.interact()
	assert(pie.get_meta("bake_quality") == "perfect" and oven.pie_item.is_empty())
	assert(shift.place_carried())
	for item in ["Donut", "Coffee"]: assert(shift.add_item(item))
	shift.order_taken = true
	assert(shift.serve_order(), "Perfect pie plus correct sides satisfies customer")
	shift.start_demo()
	shift.set_process(false)
	for frame in range(620): shift._process(1.0 / 60.0)
	assert(oven.pie_item.is_empty() and pie.get_meta("bake_quality") == "raw")
	assert(shift.pickup_item(pie.get_meta("item"), pie))
	oven.interact()
	game._toggle_door(oven.doors[0])
	await create_timer(0.5).timeout
	oven._process(14)
	assert(oven.quality() == "burnt")
	game._toggle_door(oven.doors[1])
	await create_timer(0.5).timeout
	oven.interact()
	assert(pie.get_meta("bake_quality") == "burnt")
	assert(shift.place_carried())
	for item in ["Donut", "Coffee"]: shift.add_item(item)
	shift.phase = "waiting"
	shift.order_taken = true
	assert(not shift.serve_order(), "Burnt pie fails even with correct flavor and sides")
	shift.start_demo()
	assert(shift.pickup_item(pie.get_meta("item"), pie))
	oven.interact()
	oven.elapsed = 3
	oven.interact()
	assert(pie.get_meta("bake_quality") == "undercooked")
	oven.interact()
	assert(oven.elapsed == 3, "Undercooked pies can go back in without losing progress")
	shift.begin_prep()
	assert(oven.pie_item.is_empty() and pie.visible and pie.get_meta("bake_quality") == "raw")
	print("PASS: props removed, raw tray guard, door loading/retrieval, sealed-only timer, pause/resume, physical targeting, perfect serving, burnt rejection, re-baking and shift reset")
	quit()
