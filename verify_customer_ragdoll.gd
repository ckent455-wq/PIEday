extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func require(ok: bool, message: String):
	if not ok:
		push_error(message)
		failures += 1
func run():
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.start_demo()
	for model in ["adult_unclothed","adult_female_unclothed"]:
		shift.corpses.reset()
		game.player.position = Vector3(-2.4,.03,-5.2)
		var actor = shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),model)
		var entry = shift.corpses.kill(actor)
		var rag: Dictionary = entry.ragdoll
		for bone in rag.bones:
			require(bone.get_bone_id() >= 0,"Every physics body drives a real skeletal bone")
			require(bone.collision_mask == 3,"Ragdoll collides with furniture and architecture")
		for i in 360: await physics_frame
		var hip: PhysicalBone3D = rag.hip
		require(hip.global_position.y < .7 and hip.global_position.y > -.2,"Body settles at the floor rather than hovering or tunneling")
		for bone in rag.bones:
			require(bone.global_position.y > -.25,"Limbs remain above floor")
			require(bone.global_position.distance_to(hip.global_position) < 2.5,"Jointed body remains connected")
		var visitor = shift.customer_line.make_actor(hip.global_position,"male_1")
		for bone in rag.bones:
			require(bone.get_collision_exceptions().has(game.player),"Ragdoll ignores player contact")
			require(bone.get_collision_exceptions().has(visitor.get_node("Interaction")),"New customers cannot shove the ragdoll")
		for i in 120:
			visitor.global_position = hip.global_position+Vector3(sin(i*.2)*.6,0,cos(i*.2)*.6)
			game.player.global_position = visitor.global_position
			await physics_frame
			for bone in rag.bones:
				require(bone.global_position.distance_to(hip.global_position) < 2.5,"Contact does not stretch the ragdoll apart")
		visitor.free()
		var saved: Dictionary = shift.corpses.snapshot()
		var before := hip.global_position
		shift.corpses.restore(saved)
		await physics_frame
		hip = shift.corpses.bodies[0].ragdoll.hip
		require(hip.global_position.distance_to(before) < .15,"Settled physics pose survives save/load without standing back up")
		shift.phase = "cleanup"
		shift.corpses.begin_cleanup()
		shift.corpses.grab(shift.corpses.bodies[0].body)
		game.player.position = hip.global_position+Vector3(0,.03-hip.global_position.y,3)
		game.player.rotation = Vector3.ZERO
		game.camera.rotation = Vector3.ZERO
		for i in 120: await physics_frame
		require(hip.global_position.distance_to(before) > .15,"Carried body follows the player")
		for i in 180:
			if i%30 == 0:
				shift.corpses.drop()
				shift.corpses.grab(shift.corpses.bodies[0].body)
			game.player.position = Vector3(-2.4+sin(i*.04)*2,.03,-3.6+cos(i*.04)*2)
			await physics_frame
			for bone in shift.corpses.bodies[0].ragdoll.bones:
				require(bone.global_position.distance_to(hip.global_position) < 2.5,"Repeated pickups keep the carried pose intact")
				require(PhysicsServer3D.body_get_mode(bone.get_rid()) == PhysicsServer3D.BODY_MODE_KINEMATIC,"Carried limbs remain fixed even when the player turns quickly")
		shift.corpses.drop()
		shift.phase = "waiting"
	shift.corpses.reset()
	if failures == 0: print("PASS: both rigs, floor settling, saved poses, player/customer contact, repeated grabs and body pickup and carrying")
	quit(failures)
