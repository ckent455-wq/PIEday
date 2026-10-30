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
	var line = shift.customer_line
	line.nude_chance = 0.0
	var actors: Array[Node3D] = []
	for i in range(line.CUSTOMER_MODELS.size()):
		# Force each distinct model once while using the production actor builder.
		var actor: Node3D = line.make_actor(Vector3(-5.0 + i * 1.3, -0.094, 0.5))
		for attempt in range(100):
			if actor.get_meta("customer_model") == line.CUSTOMER_MODELS[i]: break
			actor.queue_free()
			actor = line.make_actor(Vector3(-5.0 + i * 1.3, -0.094, 0.5))
		actors.append(actor)
		require(actor.get_meta("customer_model") == line.CUSTOMER_MODELS[i], "Every model can spawn")
		var skeleton: Skeleton3D = actor.get_meta("skeleton")
		require(skeleton.get_bone_count() >= 30 and actor.get_meta("rest_bones").size() == 4, "Full deform rig plus four walk limbs")
		line._pose(actor, 0.7)
		require(not skeleton.get_bone_pose_rotation(skeleton.find_bone("Leg_L")).is_equal_approx(Quaternion.IDENTITY), "Legs animate")
		line._pose(actor, 0)
	game.get_child(0).visible = false
	game.player.position = Vector3(-1.75, 0.05, 4.0)
	game.camera.look_at(Vector3(-1.75, 1.05, 0.5))
	if DisplayServer.get_name() != "headless":
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/customer-import/customer-lineup.png")
	for actor in actors: actor.queue_free()
	game.get_child(0).visible = true
	shift.start_demo()
	line.next_arrival = INF
	for frame in range(620): shift._process(1.0 / 60.0)
	require(shift.phase == "waiting", "New customer reaches counter")
	shift.interact(shift.customer.get_node("Interaction"))
	require(shift.order_taken, "Customer still accepts interaction")
	game.camera.look_at(shift.customer.global_position + Vector3(0, 1.65, 0))
	if DisplayServer.get_name() != "headless":
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/customer-import/customer-counter.png")
	if failures == 0: print("PASS: six new rigged customer appearances, walking, arrival, order interaction")
	quit(1 if failures else 0)
