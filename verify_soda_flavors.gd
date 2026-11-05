extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	for frame in range(620): shift._process(1.0/60.0)
	var soda = shift.soda_station
	var flavors = soda.FLAVORS
	for i in range(3):
		var button = soda.get_node("Flavor_" + str(i))
		game.player.position = Vector3(button.global_position.x,-0.09,-5.6)
		game.camera.look_at(button.global_position)
		await create_timer(0.1).timeout
		await physics_frame
		game._update_interaction()
		assert(game.target_action == button, "Each labeled flavor button is physically reachable")
		shift.interact(button)
		assert(soda.state == "empty", "Empty cup required")
		shift.interact(soda.stack)
		shift.interact(button)
		assert(soda.state == "brewing" and soda.drink_name == flavors[i])
		assert(is_equal_approx(soda.machine_cup.position.x, button.position.x))
		assert(is_equal_approx(soda.stream.position.x, soda.get_node("Nozzle_" + str(i)).position.x))
		assert(soda.find_children("Nozzle_*", "Node3D", false, false).size() == 3)
		await create_timer(.05).timeout
		assert(soda.pour_audio.playing, "Soda recording plays during filling")
		assert(is_equal_approx(soda.pour_audio.position.x, button.position.x))
		soda.choose_flavor(flavors[(i+1)%3])
		assert(soda.drink_name == flavors[i] and shift.carried_item.is_empty(), "Cannot change flavor while pouring")
		var data = preload("res://save_states.gd").capture(game)
		assert(data.drinks[1].drink_name == flavors[i], "Save retains brewing flavor")
		await create_timer(1.9).timeout
		assert(soda.state == "ready" and not soda.pour_audio.playing)
		shift.interact(button)
		assert(shift.carried_item == flavors[i])
		assert(shift.carried_visual.find_child("FlavorBand", true, false).material_override.albedo_color == soda.BANDS[i])
		assert(shift.place_carried())
	assert(shift.tray == flavors)
	shift.order.assign(flavors)
	shift.order_taken = true
	assert(shift.serve_order())
	assert(shift.earnings.sales == 6)
	game.player.position = Vector3(1.7,-0.09,-5.3)
	game.camera.look_at(Vector3(1.7,1.60,-6.55))
	if DisplayServer.get_name() != "headless":
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/soda-flavors.png")
	print("PASS: all three physical flavor buttons, cup required, locked pouring flavor, save identity, colored cups and exact-flavor orders at $2")
	quit()
