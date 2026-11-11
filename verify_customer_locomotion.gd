extends SceneTree
func _initialize(): call_deferred("run")
func run():
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.shift.set_process(false)
	var line = game.shift.customer_line
	line.nude_chance = 0
	for model in line.CUSTOMER_MODELS:
		var actor = line.make_actor(Vector3.ZERO,model)
		var motion = actor.get_meta("locomotion")
		motion.set_process(false)
		assert(motion.player.has_animation("Walk") and motion.player.has_animation("Jog_Fwd") and motion.player.has_animation("Idle"))
		var skeleton: Skeleton3D = actor.get_meta("skeleton")
		var knee := skeleton.find_bone("DEF-shin.L")
		for clip in ["Idle","Walk","Jog_Fwd"]:
			motion.player.play(clip)
			for sample in 20:
				motion.player.seek(motion.player.get_animation(clip).length*sample/20.0,true)
				skeleton.force_update_all_bone_transforms()
				for bone in ["DEF-spine.004","DEF-spine.005","DEF-spine.006"]:
					var id := skeleton.find_bone(bone)
					assert(skeleton.get_bone_global_pose(id).basis.get_rotation_quaternion().angle_to(skeleton.get_bone_global_rest(id).basis.get_rotation_quaternion()) < .002,"Head and neck remain upright throughout every clip")
				var head := skeleton.find_bone("DEF-spine.006")
				var chest := skeleton.find_bone("DEF-spine.003")
				var offset := skeleton.get_bone_global_pose(head).origin-skeleton.get_bone_global_pose(chest).origin
				var rest_offset := skeleton.get_bone_global_rest(head).origin-skeleton.get_bone_global_rest(chest).origin
				assert(offset.distance_to(rest_offset) < .002,"Head stays above the chest without projecting forward")
		motion.player.play("Walk")
		motion.player.seek(.1,true)
		var before := skeleton.get_bone_pose_rotation(knee)
		motion.player.seek(.5,true)
		assert(before.angle_to(skeleton.get_bone_pose_rotation(knee)) > .1,"Retargeted walk bends the knees")
		assert(actor.position == Vector3.ZERO and actor.get_node("Visual").position == Vector3.ZERO,"In-place clips cannot move the customer off the route")
		actor.position.x += .4
		motion._process(.1)
		assert(motion.player.current_animation == "Walk")
		actor.position.x += .8
		motion._process(.1)
		assert(motion.player.current_animation == "Jog_Fwd")
		motion._process(.1)
		assert(motion.player.current_animation == "Idle")
		motion.suspend(true)
		assert(not motion.player.active,"Seated eating owns the pose")
		motion.suspend(false)
		assert(motion.player.active)
		actor.free()
	var robber = line.make_actor(Vector3.ZERO,"robber_1")
	assert(not robber.has_meta("locomotion"),"Pistol and ragdoll poses remain separate")
	robber.free()
	print("PASS: all ",line.CUSTOMER_MODELS.size()," customer appearances, knee motion, walk/jog/idle transitions, in-place routes, seated suspension and robber poses")
	quit()
