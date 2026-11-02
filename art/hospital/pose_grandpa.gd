extends SceneTree
func _initialize() -> void:
	var grandpa := Node3D.new()
	grandpa.name = "Grandpa"
	grandpa.set_meta("character","Grandpa")
	grandpa.set_meta("face_texture","D28")
	var visual = load("res://assets/customers/grandpa.glb").instantiate()
	visual.name = "Visual"
	grandpa.add_child(visual)
	visual.owner = grandpa
	for skeleton in visual.find_children("*","Skeleton3D",true,false):
		for bone_name in ["Arm_L","Arm_R"]:
			var id = skeleton.find_bone(bone_name)
			var rest: Quaternion = skeleton.get_bone_global_rest(id).basis.get_rotation_quaternion()
			var baseline: Quaternion = skeleton.get_bone_pose_rotation(id)
			skeleton.set_bone_pose_rotation(id,baseline*rest.inverse()*Quaternion(Vector3.FORWARD,.8 if bone_name == "Arm_L" else -.8)*rest)
	assign_owners(grandpa,grandpa)
	var scene := PackedScene.new()
	var result := scene.pack(grandpa)
	if result == OK: result = ResourceSaver.save(scene,"res://grandpa.tscn")
	print("GRANDPA_POSED ",result)
	grandpa.free()
	quit(result)

func assign_owners(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		assign_owners(child,scene_root)
