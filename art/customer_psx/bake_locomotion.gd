extends SceneTree
## Retarget Quaternius global rest-relative rotations to the existing split deform rigs.
const MAP := {
	"DEF-spine":"pelvis", "DEF-spine.001":"spine_01", "DEF-spine.002":"spine_02",
	"DEF-spine.003":"spine_03", "DEF-spine.004":"neck_01", "DEF-spine.005":"neck_01", "DEF-spine.006":"Head",
	"DEF-pelvis.L":"pelvis", "DEF-pelvis.R":"pelvis", "DEF-breast.L":"spine_03", "DEF-breast.R":"spine_03"}
func _initialize(): call_deferred("run")
func run():
	var donor = load("res://assets/animations/quaternius/UAL1_Standard.glb").instantiate()
	root.add_child(donor)
	var source: Skeleton3D = donor.find_children("*","Skeleton3D",true,false)[0]
	var player: AnimationPlayer = donor.find_children("*","AnimationPlayer",true,false)[0]
	print("DONOR ",player.get_animation_list())
	for model in ["male_1","female_1","female_2"]:
		var visual = load("res://assets/customers/"+model+".glb").instantiate()
		root.add_child(visual)
		var target: Skeleton3D = visual.find_children("*","Skeleton3D",true,false)[0]
		var mapping := MAP.duplicate()
		for side in ["L","R"]:
			var s: String = side.to_lower()
			mapping.merge({"Arm_"+side:"upperarm_"+s,"DEF-upper_arm."+side+".001":"upperarm_"+s,
				"DEF-forearm."+side:"lowerarm_"+s,"DEF-forearm."+side+".001":"lowerarm_"+s,
				"DEF-hand."+side:"hand_"+s,"DEF-shoulder."+side:"clavicle_"+s,
				"Leg_"+side:"thigh_"+s,"DEF-thigh."+side+".001":"thigh_"+s,
				"DEF-shin."+side:"calf_"+s,"DEF-shin."+side+".001":"calf_"+s,
				"DEF-foot."+side:"foot_"+s,"DEF-toe."+side:"ball_"+s})
		var library := AnimationLibrary.new()
		for clip in ["Walk","Jog_Fwd","Idle"]:
			player.play(clip)
			var length: float = player.get_animation(clip).length
			var anim := Animation.new()
			anim.length = length
			anim.loop_mode = Animation.LOOP_LINEAR
			for id in target.get_bone_count():
				var track := anim.add_track(Animation.TYPE_ROTATION_3D)
				anim.track_set_path(track,NodePath(str(visual.get_path_to(target))+":"+target.get_bone_name(id)))
			var neck := target.find_bone("DEF-spine.004")
			var neck_position := anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(neck_position,NodePath(str(visual.get_path_to(target))+":DEF-spine.004"))
			var samples := ceili(length*30)
			for frame in samples+1:
				var at := minf(float(frame)/30,length)
				player.seek(at,true)
				source.force_update_all_bone_transforms()
				var desired: Array[Quaternion] = []
				for id in target.get_bone_count():
					var bone := target.get_bone_name(id)
					var rest := target.get_bone_global_rest(id).basis.get_rotation_quaternion()
					var source_id := source.find_bone(mapping.get(bone,""))
					var delta := Quaternion.IDENTITY
					var alignment := Quaternion.IDENTITY
					if source_id >= 0:
						var source_rest := source.get_bone_global_rest(source_id).basis.get_rotation_quaternion()
						delta = source.get_bone_global_pose(source_id).basis.get_rotation_quaternion()*source_rest.inverse()
						# The donor has a pronounced forward lean. Keep only a gentle
						# torso lean on these shorter-necked customer meshes.
						if bone in ["DEF-spine","DEF-spine.001","DEF-spine.002","DEF-spine.003"]:
							var lean := delta.get_euler()
							lean.x *= .35
							delta = Quaternion.from_euler(lean)
						if bone.begins_with("Arm_") or bone.begins_with("Leg_") or "upper_arm" in bone or "forearm" in bone or "hand." in bone or "thigh." in bone or "shin." in bone or "foot." in bone or "toe." in bone:
							alignment = Quaternion(rest*Vector3.UP,source_rest*Vector3.UP)
					desired.append((delta*alignment*rest).normalized())
				# Keep the original upright head/neck orientation. These separate
				# head meshes magnify even a small donor chest/neck pitch.
				for bone in ["DEF-spine.004","DEF-spine.005","DEF-spine.006"]:
					var id := target.find_bone(bone)
					desired[id] = target.get_bone_global_rest(id).basis.get_rotation_quaternion()
				var origins: Array[Vector3] = []
				for id in target.get_bone_count():
					var parent := target.get_bone_parent(id)
					var local_position := target.get_bone_rest(id).origin
					if id == neck:
						# Anchor the neck above the chest at the mesh's own rest
						# offset, rather than letting torso pitch project it forward.
						var offset := target.get_bone_global_rest(id).origin-target.get_bone_global_rest(parent).origin
						local_position = desired[parent].inverse()*offset
						anim.position_track_insert_key(neck_position,at,local_position)
					origins.append(origins[parent]+desired[parent]*local_position if parent >= 0 else local_position)
				for id in target.get_bone_count():
					var parent := target.get_bone_parent(id)
					var local: Quaternion = desired[parent].inverse()*desired[id] if parent >= 0 else desired[id]
					anim.rotation_track_insert_key(id,at,local.normalized())
			library.add_animation(clip,anim)
		DirAccess.make_dir_recursive_absolute("res://assets/animations/customers")
		var path: String = "res://assets/animations/customers/"+model+".res"
		assert(ResourceSaver.save(library,path)==OK)
		print("BAKED ",path)
		visual.free()
	donor.free()
	quit()
