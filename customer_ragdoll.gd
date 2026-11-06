extends RefCounted

# Bone endpoints are in the imported rig's rest space. Intermediate twist bones
# follow their simulated parent; disconnected rig roots are attached first.
const SEGMENTS := [
	["DEF-spine","DEF-spine.003",.17,16.0],
	["DEF-spine.003","DEF-spine.005",.18,18.0],
	["DEF-spine.006","",.12,5.0],
	["Leg_L","DEF-shin.L",.09,7.0], ["DEF-shin.L","DEF-foot.L",.07,4.0], ["DEF-foot.L","DEF-toe.L",.065,1.5],
	["Leg_R","DEF-shin.R",.09,7.0], ["DEF-shin.R","DEF-foot.R",.07,4.0], ["DEF-foot.R","DEF-toe.R",.065,1.5],
	["Arm_L","DEF-forearm.L",.065,3.0], ["DEF-forearm.L","DEF-hand.L",.055,2.0],
	["Arm_R","DEF-forearm.R",.065,3.0], ["DEF-forearm.R","DEF-hand.R",.055,2.0]]

static func build(actor: Node3D, player: PhysicsBody3D) -> Dictionary:
	var skeleton: Skeleton3D = actor.get_meta("skeleton")
	var rests: Array[Transform3D] = []
	var poses: Array[Transform3D] = []
	for i in skeleton.get_bone_count():
		rests.append(skeleton.get_bone_global_rest(i))
		poses.append(skeleton.get_bone_global_pose(i))
	for i in skeleton.get_bone_count():
		if skeleton.get_bone_parent(i) >= 0 or i == 0: continue
		var bone_name := skeleton.get_bone_name(i)
		var parent := skeleton.find_bone("DEF-spine" if bone_name.begins_with("Leg") or "pelvis" in bone_name else "DEF-spine.003")
		skeleton.set_bone_parent(i,parent)
		skeleton.set_bone_rest(i,rests[parent].affine_inverse()*rests[i])
		var local := poses[parent].affine_inverse()*poses[i]
		skeleton.set_bone_pose_position(i,local.origin)
		skeleton.set_bone_pose_rotation(i,local.basis.get_rotation_quaternion())
		skeleton.set_bone_pose_scale(i,local.basis.get_scale())
	var simulator := PhysicalBoneSimulator3D.new()
	simulator.name = "DeathRagdoll"
	skeleton.add_child(simulator)
	var bones: Array[PhysicalBone3D] = []
	for segment in SEGMENTS:
		var id := skeleton.find_bone(segment[0])
		var end_id := skeleton.find_bone(segment[1])
		var start := rests[id].origin
		var end: Vector3 = rests[end_id].origin if end_id >= 0 else start+Vector3(0,.19,0)
		var axis := (end-start).normalized()
		var offset := Transform3D(Basis(Quaternion(Vector3.UP,axis)),(start+end)/2)
		var physical := PhysicalBone3D.new()
		physical.name = "Ragdoll_"+str(segment[0]).replace(".","_")
		physical.set("bone_name",segment[0])
		physical.body_offset = rests[id].affine_inverse()*offset
		physical.joint_type = PhysicalBone3D.JOINT_TYPE_CONE if id != 0 else PhysicalBone3D.JOINT_TYPE_NONE
		if id != 0:
			physical.set("joint_constraints/swing_span",55.0)
			physical.set("joint_constraints/twist_span",30.0)
			physical.set("joint_constraints/bias",.25)
			physical.set("joint_constraints/softness",.75)
		physical.mass = segment[3]
		physical.friction = .6
		physical.bounce = 0
		physical.linear_damp = .45
		physical.angular_damp = 4.0
		physical.collision_layer = 4
		physical.collision_mask = 3
		physical.set_meta("action","corpse")
		var collision := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = segment[2]
		capsule.height = maxf(start.distance_to(end),capsule.radius*2)
		collision.shape = capsule
		physical.add_child(collision)
		simulator.add_child(physical)
		physical.add_collision_exception_with(player)
		player.add_collision_exception_with(physical)
		PhysicsServer3D.body_set_enable_continuous_collision_detection(physical.get_rid(),true)
		bones.append(physical)
	simulator.physical_bones_start_simulation()
	return {"simulator":simulator,"bones":bones,"hip":bones[0]}

static func snapshot(ragdoll: Dictionary) -> Array:
	var saved: Array = []
	for bone in ragdoll.bones:
		saved.append({"transform":bone.global_transform,"linear":bone.linear_velocity,"angular":bone.angular_velocity})
	return saved

static func restore(ragdoll: Dictionary, saved: Array) -> void:
	for i in mini(saved.size(),ragdoll.bones.size()):
		var bone: PhysicalBone3D = ragdoll.bones[i]
		bone.global_transform = saved[i].transform
		PhysicsServer3D.body_set_state(bone.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,saved[i].transform)
		bone.linear_velocity = saved[i].linear
		bone.angular_velocity = saved[i].angular
