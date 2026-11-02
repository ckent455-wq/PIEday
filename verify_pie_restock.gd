extends SceneTree
var failures := 0
func _initialize(): call_deferred("check")
func require(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	var missing: Array[Node3D] = []
	for flavor in shift.PIE_NAMES:
		for pie in shift.all_pies:
			if pie.get_meta("item") == flavor:
				shift._set_pickup_visible(pie, false)
				pie.set_meta("bake_quality", "burnt")
				missing.append(pie)
				break
	shift.begin_cleanup()
	shift._refresh_hud()
	require(not shift.tasks.restock and shift.restock.missing.size() == 3, "Missing service stock creates closing duty")
	shift.complete_task("bathroom")
	shift.complete_task("kitchen")
	shift.complete_task("trash")
	require(shift.phase == "cleanup", "Other chores cannot end day before replenishment")
	shift.interact(shift.get_node("Station_clock"))
	require(shift.phase == "cleanup", "Clipboard cannot skip restocking")
	var freezer: MeshInstance3D
	for door in game.doors:
		if door.name == "Door_02": freezer = door
	game._set_door_open(freezer, true)
	await create_timer(0.6).timeout
	for bin in shift.restock.bins:
		game.player.position = bin.global_position + Vector3(-1.5, 0, 0)
		game.player.position.y = -0.09
		game.camera.look_at(bin.global_position)
		await physics_frame
		game._update_interaction()
		require(game.target_action == bin, "Freezer crates are reachable in actual room")
		shift.interact(bin)
		require(shift.carried_item == str(bin.get_meta("item")) + " stock", "Take matching crate")
		if bin == shift.restock.bins[0] and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://builds/freezer-pie-stock.png")
		require(not shift.place_carried(), "Stock cannot be served on tray")
		shift.discard_last()
		require(shift.carried_item.is_empty(), "Q returns crate without completing task")
		shift.interact(bin)
		if bin == shift.restock.bins[0]:
			shift.restock.deliver()
			require(shift.restock.missing.size() == 3 and not shift.carried_item.is_empty(), "Closed cooler blocks delivery")
		for door in game.doors:
			if door.has_meta("cooler"): game._set_door_open(door, true)
		await create_timer(0.6).timeout
		game.player.position = Vector3(1.25, -0.09, -10.4)
		game.camera.look_at(shift.restock.cooler_target.global_position)
		await physics_frame
		game._update_interaction()
		require(game.target_action == shift.restock.cooler_target, "Cooler restocking is physically targetable")
		shift.interact(game.target_action)
		require(shift.carried_item.is_empty(), "Delivery clears held crate")
	for pie in missing:
		require(pie.visible and pie.get_meta("bake_quality") == "raw", "Replacement pies appear raw on correct shelves")
	require(shift.tasks.restock and shift.phase == "closed", "Final replenishment completes day")
	shift.begin_prep()
	require(shift.restock.cooler_target.collision_layer == 0 and shift.all_pies.all(func(pie): return pie.visible), "Next service has full usable cooler")
	shift.begin_cleanup()
	require(shift.tasks.restock, "Full cooler auto-completes duty")
	if failures == 0: print("PASS: depletion-based closing duty, reachable freezer crates, carry/return, no tray misuse, open-door delivery, raw shelf restoration, day gating and next-shift reset")
	quit(1 if failures else 0)
