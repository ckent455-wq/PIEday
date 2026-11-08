extends Node3D
## One non-graphic witnessed incident, followed by the existing bedside dialogue.
const DURATION := 3.8
const CONTACT := 1.85
var room: Node3D
var active := false
var elapsed := 0.0
var impacted := false
var grunted := false
var nurse: Node3D
var rig: Skeleton3D
var grandpa: Node3D
var grandpa_start: Transform3D
var shot: Camera3D
var overlay: CanvasLayer
var blackout: ColorRect
var caption: Label
var impact: AudioStreamPlayer3D
var grunt: AudioStreamPlayer3D
var contact_point := Vector3.ZERO

func setup(host: Node3D) -> void:
	room = host
	name = "WitnessedHospitalIncident"

func pending() -> bool:
	var progress = room.earnings.grandpa
	return progress.last_setback_id == "mistreatment" and progress.last_setback_day > progress.last_discussed_setback_day and progress.last_setback_day > progress.last_witnessed_mistreatment_day

func begin() -> bool:
	if active or not pending(): return false
	active = true
	elapsed = 0
	impacted = false
	grunted = false
	grandpa = room.get_node("Furniture/Bed/Grandpa")
	grandpa_start = grandpa.transform
	var skeleton: Skeleton3D = grandpa.find_children("*","Skeleton3D",true,false)[0]
	# Imported skeleton overrides can be internal to the packed character.
	# Compose the local hierarchy so the shot still follows the edited bed.
	var head := skeleton.get_bone_global_pose(6)
	var ancestor: Node3D = skeleton
	while ancestor != grandpa:
		head = ancestor.transform * head
		ancestor = ancestor.get_parent()
	contact_point = grandpa.to_global(head.origin)
	nurse = preload("res://assets/customers/female_1.glb").instantiate()
	nurse.name = "NurseInScrubs"
	add_child(nurse)
	nurse.global_position = contact_point + Vector3(0.64,-contact_point.y,0.05)
	nurse.look_at(Vector3(contact_point.x,0,contact_point.z),Vector3.UP,true)
	rig = nurse.find_children("*","Skeleton3D",true,false)[0]
	# Add a white nurse cap and badge to the existing clothed scrubs character.
	var cap := BoneAttachment3D.new()
	cap.bone_name = "DEF-spine.006"
	rig.add_child(cap)
	var hat := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(0.18,0.055,0.12)
	hat.mesh = shape
	hat.position = Vector3(0,0.18,0)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.88,0.91,0.89)
	hat.material_override = white
	cap.add_child(hat)
	shot = Camera3D.new()
	add_child(shot)
	shot.fov = 58
	shot.global_position = contact_point + Vector3(1.65,1.05,1.8)
	shot.look_at(contact_point + Vector3(0.28,0.28,0))
	shot.make_current()
	overlay = CanvasLayer.new()
	overlay.layer = 85
	add_child(overlay)
	for bottom in [false,true]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if bottom else Control.PRESET_TOP_WIDE)
		bar.offset_top = -62 if bottom else 0
		bar.offset_bottom = 0 if bottom else 62
	caption = Label.new()
	caption.add_theme_font_size_override("font_size",22)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -58
	caption.offset_bottom = -8
	blackout = ColorRect.new()
	blackout.color = Color(0,0,0,0)
	blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(blackout)
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Captions stay visible over the brief blackout.
	overlay.move_child(caption,overlay.get_child_count()-1)
	impact = AudioStreamPlayer3D.new()
	impact.stream = preload("res://assets/audio/hospital_impact.wav")
	impact.volume_db = 0
	impact.unit_size = 3
	add_child(impact)
	impact.global_position = contact_point
	grunt = AudioStreamPlayer3D.new()
	grunt.name = "GrandpaHurtGrunt"
	grunt.stream = preload("res://assets/audio/grandpa_hurt_grunt.mp3")
	grunt.volume_db = 0
	grunt.pitch_scale = 0.88
	grunt.unit_size = 3
	add_child(grunt)
	grunt.global_position = contact_point
	room.prompt.get_parent().hide()
	_render()
	return true

func _process(delta: float) -> void:
	if not active: return
	elapsed += delta
	_render()
	if elapsed >= DURATION and (room.coop == null or room.coop.hosting): finish(true)

func _arm(shoulder: Vector3, elbow: Vector3, wrist: Vector3) -> void:
	var names := ["Arm_R","DEF-upper_arm.R.001","DEF-forearm.R","DEF-forearm.R.001","DEF-hand.R"]
	var positions := [shoulder,shoulder.lerp(elbow,0.5),elbow,elbow.lerp(wrist,0.5),wrist]
	for i in range(names.size()):
		var bone := rig.find_bone(names[i])
		var rest := rig.get_bone_global_rest(bone)
		var direction: Vector3 = (elbow-shoulder) if i < 2 else (wrist-elbow)
		var rest_direction := Vector3(-0.17,-0.19,-0.015) if i < 2 else Vector3(-0.23,-0.20,0.07)
		var rotation := Quaternion(rest_direction.normalized(),direction.normalized())
		rig.set_bone_global_pose_override(bone,Transform3D(Basis(rotation)*rest.basis,positions[i]),1.0,true)

func _render() -> void:
	if not active: return
	var shoulder := rig.get_bone_global_rest(rig.find_bone("Arm_R")).origin
	var target := rig.to_local(contact_point + Vector3(0.04,0.04,0))
	var raised := shoulder + Vector3(-0.08,0.32,0.24)
	var resting := shoulder + Vector3(-0.18,-0.38,0.02)
	var hand := resting.lerp(raised,smoothstep(0.45,1.3,elapsed))
	if elapsed >= 1.55: hand = raised.lerp(target,smoothstep(1.55,CONTACT,elapsed))
	if elapsed > CONTACT: hand = target.lerp(resting,smoothstep(CONTACT+0.08,2.35,elapsed))
	var elbow := shoulder.lerp(hand,0.5) + Vector3(0,0.03,0.13)
	_arm(shoulder,elbow,hand)
	if elapsed >= CONTACT and not impacted:
		impacted = true
		impact.play()
	if elapsed >= CONTACT + 0.10 and not grunted:
		grunted = true
		grunt.play()
	var recoil := sin(clampf((elapsed-CONTACT)/0.38,0,1)*PI) if elapsed >= CONTACT else 0.0
	grandpa.transform = grandpa_start
	grandpa.position.x += recoil * 0.045
	grandpa.rotation.z += recoil * 0.055
	caption.text = 'GRANDPA: "Could you help me sit up?"' if elapsed < 1.35 else ('NURSE: "Hold still."' if elapsed < CONTACT else 'STAFF: "Step away from him. Now."')
	if elapsed >= CONTACT and elapsed < CONTACT + 0.40: caption.text = "GRANDPA: [pained grunt]"
	var alpha := smoothstep(2.06,2.19,elapsed) * (1.0-smoothstep(2.85,3.35,elapsed))
	blackout.color.a = alpha
	nurse.visible = elapsed < 2.3
	if elapsed > 2.3: caption.text = 'A staff member intervenes and removes the nurse.'

func finish(show_dialogue: bool) -> void:
	if not active: return
	active = false
	grandpa.transform = grandpa_start
	room.camera.make_current()
	room.prompt.get_parent().show()
	room.interaction_release_required = true
	for node in [nurse,shot,overlay,impact,grunt]:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	if show_dialogue:
		room.earnings.grandpa.last_witnessed_mistreatment_day = room.earnings.grandpa.last_setback_day
		room.earnings._save()
		room.conversation.show_dialogue(room.earnings.grandpa.visit_dialogue(room.earnings.cash))

func snapshot() -> Dictionary:
	return {"active":active,"elapsed":elapsed}

func restore_visual(state: Dictionary) -> void:
	if state.get("active",false):
		if not active: begin()
		elapsed = float(state.elapsed)
		_render()
	elif active: finish(false)
