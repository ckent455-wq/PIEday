extends RefCounted

static func equip(actor: Node3D) -> void:
	var skeleton: Skeleton3D = actor.get_meta("skeleton", null)
	if skeleton == null: return
	var arm := skeleton.find_bone("Arm_R")
	var hand := skeleton.find_bone("DEF-hand.R")
	if arm < 0 or hand < 0: return
	var parent := skeleton.get_bone_parent(arm)
	var raised := Basis(Vector3.RIGHT, -1.45) * skeleton.get_bone_global_pose(arm).basis
	var parent_basis := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var pose := (parent_basis.inverse() * raised).get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(arm, pose)
	var rest_bones: Dictionary = actor.get_meta("rest_bones")
	rest_bones[arm] = pose
	skeleton.force_update_all_bone_transforms()
	var hand_pose := skeleton.get_bone_global_pose(hand)
	var attachment := BoneAttachment3D.new()
	attachment.bone_idx = hand
	skeleton.add_child(attachment)
	var gun := Node3D.new()
	gun.name = "RobberGun"
	attachment.add_child(gun)
	var grip := hand_pose.origin + hand_pose.basis.y.normalized() * 0.034
	gun.transform = hand_pose.affine_inverse() * Transform3D(Basis.IDENTITY, grip)
	var steel := Color("3d4147")
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.016
	barrel.bottom_radius = 0.016
	barrel.height = 0.16
	barrel.radial_segments = 8
	_mesh(gun, barrel, Vector3(0, 0.046, 0.126), steel).rotation.x = PI / 2
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.034
	cylinder.bottom_radius = 0.034
	cylinder.height = 0.057
	cylinder.radial_segments = 8
	_mesh(gun, cylinder, Vector3(0, 0.043, 0.035), Color("535862")).rotation.x = PI / 2
	var frame := BoxMesh.new()
	frame.size = Vector3(0.039, 0.040, 0.110)
	_mesh(gun, frame, Vector3(0, 0.043, 0.009), steel)
	var handle := BoxMesh.new()
	handle.size = Vector3(0.041, 0.090, 0.046)
	_mesh(gun, handle, Vector3(0, -0.011, -0.035), Color("292322")).rotation.x = 0.22

static func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.61
	node.material_override = material
	parent.add_child(node)
	node.position = at
	return node
