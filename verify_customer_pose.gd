extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	game.shift.set_process(false)
	game.shift.start_demo()
	for frame in range(620): game.shift._process(1.0 / 60.0)
	assert(game.shift.limbs.size() == 4)
	assert(game.shift.customer_skeleton.get_bone_count() == 5)
	var at: Vector3 = game.shift.customer.position
	# Place the customer in clear floor space for a full-body inspection.
	game.shift.customer.position = Vector3(2, -0.094, 0)
	at = game.shift.customer.position
	game.player.position = Vector3(2, -0.094, -3.2)
	game.camera.look_at(at + Vector3(0, 0.9, 0))
	game.shift._pose_customer(0)
	for id in game.shift.limbs:
		var skeleton: Skeleton3D = game.shift.customer_skeleton
		assert(skeleton.get_bone_pose_rotation(id).angle_to(game.shift.limb_rest_rotations[id]) < 0.001, "Idle must preserve the imported relaxed rest pose")
		if skeleton.get_bone_name(id).begins_with("Arm"):
			var bone := skeleton.get_bone_global_pose(id)
			var wrist := bone * Vector3(0, 0.70, 0)
			assert(wrist.y < bone.origin.y - 0.5, "Relaxed wrists must hang below shoulders")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/customer-fixed-idle.png")
	game.shift._pose_customer(1.0)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/customer-fixed-walk.png")
	print("PASS: connected skinned body, five-bone skeleton, four animated limbs; idle and walk previews saved")
	quit()
