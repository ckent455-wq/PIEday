extends Node3D
## Standalone visit location. Campaign scheduling is added separately.

var player: CharacterBody3D
var camera: Camera3D
var pitch := 0.0
var prompt: Label
var bedside_light: OmniLight3D
var target := ""
var paused: CanvasLayer
var furnishings: Node3D
var fixtures: Node3D
var earnings := preload("res://earnings.gd").new()
var conversation: CanvasLayer
var hospital_music: AudioStreamPlayer
var interaction_release_required := false
var leaving := false
var coop: Node
var incident: Node3D

func _ready() -> void:
	coop = preload("res://coop_session.gd").active(self)
	preload("res://playable_demo.gd").prepare(self)
	if get_tree().root.has_meta("pie_day_wallet"):
		earnings = get_tree().root.get_meta("pie_day_wallet")
		get_tree().root.remove_meta("pie_day_wallet")
	if earnings.grandpa.campaign_won and not get_tree().root.has_meta("restore_manual_state"):
		leaving = true
		set_physics_process(false)
		set_process_unhandled_input(false)
		get_tree().root.set_meta("pie_day_wallet",earnings)
		get_tree().change_scene_to_file.call_deferred("res://grandpa_victory.tscn")
		return
	if earnings.grandpa.is_dead():
		leaving = true
		set_process_unhandled_input(false)
		get_tree().root.set_meta("pie_day_wallet",earnings)
		get_tree().change_scene_to_file.call_deferred("res://grandpa_ending.tscn")
		return
	name = "GrandpasHospitalRoom"
	if has_node("Furniture"):
		furnishings = get_node("Furniture")
		fixtures = get_node("RoomShell")
		bedside_light = get_node("BedsideLight")
	else:
		furnishings = Node3D.new()
		furnishings.name = "Furniture"
		add_child(furnishings)
		fixtures = Node3D.new()
		fixtures.name = "RoomShell"
		add_child(fixtures)
		_build_room()
	ensure_furniture_collisions()
	_build_player()
	_build_hud()
	hospital_music = preload("res://hospital_music.gd").new()
	add_child(hospital_music)
	conversation = preload("res://visit_modal.gd").new()
	add_child(conversation)
	conversation.setup(self)
	conversation.dialogue_completed.connect(func():
		var demo = preload("res://playable_demo.gd").session(self)
		if demo != null: demo.talked_to_grandpa = true
		earnings.grandpa.finish_visit_conversation()
		earnings._save()
	)
	var bed = get_node("Furniture/Bed")
	# The bedside target follows the bed when the player rearranges furniture.
	_action("TalkToGrandpa",Vector3.ZERO,Vector3(.85,.7,1.4),"grandpa")
	var talk = get_node("TalkToGrandpa")
	talk.reparent(bed,false)
	talk.position = Vector3(0,1.2,-.35)
	paused = preload("res://pause_menu.gd").new()
	add_child(paused)
	if coop != null: coop.attach_hospital(self)
	paused.restart_button.text = "Restart Room"
	paused.restart_dialog.title = "Restart Room"
	paused.restart_dialog.dialog_text = "Return to the hospital room entrance?"
	if earnings.grandpa.visit_in_progress:
		prompt.text = "Visit Grandpa at his bedside. Leave through the door when you're ready to head home."
	incident = preload("res://hospital_incident.gd").new()
	add_child(incident)
	incident.setup(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	preload("res://save_states.gd").restore_pending(self)

func ensure_furniture_collisions() -> void:
	# Keep bodies directly under each movable furniture root, so imported-mesh
	# ownership cannot discard them when the room is saved in the editor.
	var furniture_root := get_node("Furniture")
	for item in furniture_root.get_children():
		if item.has_node("SolidCollision"):
			if item.get_node("SolidCollision").get_meta("version",0) == 2: continue
			item.get_node("SolidCollision").free()
		var body := StaticBody3D.new()
		body.name = "SolidCollision"
		body.collision_layer = 1
		body.collision_mask = 1
		body.set_meta("version",2)
		item.add_child(body)
		body.owner = self
		for mesh in item.find_children("*","MeshInstance3D",true,false):
			if not mesh.mesh or mesh is MeshInstance3D and mesh.skin != null: continue
			var shape := CollisionShape3D.new()
			var architectural: bool = item.scene_file_path.get_file().begins_with("Tile_") or item.scene_file_path.get_file().begins_with("Floor_") or item.scene_file_path.get_file().begins_with("Ceiling_")
			var file: String = item.scene_file_path.get_file()
			var solid_furniture: bool = file == "Bed.glb" or file.begins_with("Cabinet_") or file == "Chair.glb" or file == "Wheel_chair.glb"
			shape.shape = mesh.mesh.create_trimesh_shape() if architectural else mesh.mesh.create_convex_shape()
			var local: Transform3D = mesh.transform
			var ancestor: Node = mesh.get_parent()
			while ancestor != item:
				local = ancestor.transform * local
				ancestor = ancestor.get_parent()
			if solid_furniture:
				var bounds: AABB = mesh.mesh.get_aabb()
				var box := BoxShape3D.new()
				box.size = bounds.size
				shape.shape = box
				local.origin += local.basis * bounds.get_center()
			body.add_child(shape)
			shape.transform = local
			shape.owner = self

func _piece(asset: String, at: Vector3, angle := 0.0, size := Vector3.ONE, blocking := true) -> Node3D:
	var item: Node3D = load("res://assets/hospital/%s.glb" % asset).instantiate()
	furnishings.add_child(item)
	item.position = at
	item.rotation.y = deg_to_rad(angle)
	item.scale = size
	for mesh in item.find_children("*", "MeshInstance3D", true, false):
		if blocking: mesh.create_trimesh_collision()
		for i in mesh.mesh.get_surface_count():
			var mat = mesh.get_active_material(i)
			if mat is StandardMaterial3D: mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return item

func _box(label: String, at: Vector3, size: Vector3, color: Color, blocking := true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh.material_override = mat
	fixtures.add_child(mesh)
	mesh.position = at
	if blocking: mesh.create_trimesh_collision()
	return mesh

func _sign(text: String, at: Vector3, font_size := 40, angle := 0.0) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.004
	label.modulate = Color("dce5d5")
	label.outline_size = 0
	label.no_depth_test = false
	fixtures.add_child(label)
	label.position = at
	label.rotation.y = deg_to_rad(angle)
	return label

func _build_room() -> void:
	for x in [-3.0, -1.0, 1.0, 3.0]:
		for z in [-3.0, -1.0, 1.0, 3.0]:
			_piece("Floor_tile_1", Vector3(x,-0.1,z), 0, Vector3.ONE, false)
			_piece("Ceiling_Tile", Vector3(x,3.05,z), 0, Vector3.ONE, false)
		_piece("Tile_Wall_Window" if x > 0 else "Tile_Wall", Vector3(x,0,-4), 0, Vector3(1,1.22,1))
		_piece("Tile_Wall", Vector3(-4,0,x), 90, Vector3(1,1.22,1))
		_piece("Tile_Wall", Vector3(4,0,x), -90, Vector3(1,1.22,1))
		if x < 3: _piece("Tile_Wall", Vector3(x,0,4), 180, Vector3(1,1.22,1))
	var floor_collision = _box("FloorCollision", Vector3(0,-0.12,0), Vector3(8.2,0.24,8.2), Color("acb3a9"))
	floor_collision.visible = false
	# Physical boundaries also close window openings and seams between kit pieces.
	for at in [Vector3(0,1.5,-4.15),Vector3(0,1.5,4.15)]:
		var boundary = _box("Boundary", at, Vector3(8.5,3.2,.15), Color("414c51"))
		boundary.visible = false
	_piece("Door_1", Vector3(3,0,3.94), 0, Vector3(1.2,1.2,1.2), false)
	_box("DoorLeftJamb",Vector3(2.2,1.5,4),Vector3(.4,3,.2),Color("98a69d"))
	_box("DoorRightJamb",Vector3(3.8,1.5,4),Vector3(.4,3,.2),Color("98a69d"))
	_box("DoorLintel",Vector3(3,2.75,4),Vector3(1.2,.55,.2),Color("98a69d"))
	_action("ReturnToDiner",Vector3(3,1.2,3.8),Vector3(1.3,2.4,.3),"exit")
	_piece("Exit_sign",Vector3(3,2.55,3.76),180,Vector3(.8,.8,.8),false)
	_box("RoomPlaque",Vector3(1.65,1.7,3.8),Vector3(.65,.35,.06),Color("334b4b"),false)
	_sign("204",Vector3(1.65,1.7,3.75),40,180)
	# Bed, bedside storage, IV stand, and a deliberately clear walking aisle.
	_piece("Bed",Vector3(-1.65,0,-1.75),0,Vector3(.85,.85,.85))
	_piece("Cabinet_3",Vector3(-3.05,0,-2.6),0,Vector3(1.1,1.1,1.1))
	_piece("Iv_bag_holder",Vector3(-.5,0,-2.65),0,Vector3.ONE)
	_piece("IV_bag",Vector3(-.5,1.25,-2.65),0,Vector3(.35,.35,.35),false)
	_piece("Chair",Vector3(.6,0,-.5),90,Vector3(.8,.8,.8))
	_piece("Chair",Vector3(1.65,0,.5),140,Vector3(.8,.8,.8))
	_piece("Cabinet_2",Vector3(1.6,0,-3.35),0,Vector3(1.1,1.1,1.1))
	_piece("Magazine",Vector3(1.6,.73,-3.35),15,Vector3(1.3,1.3,1.3),false)
	_piece("Wheel_chair",Vector3(3.1,0,1.65),-35,Vector3(.8,.8,.8))
	_piece("Cabinet_1",Vector3(-2.5,0,3.25),180,Vector3(.8,.8,.8))
	_piece("Landline_phone",Vector3(-2.5,.7,3.2),180,Vector3.ONE,false)
	# Bedhead panel and a small monitor give the room a patient-care focal point.
	_box("BedheadPanel",Vector3(-1.65,1.2,-3.82),Vector3(2.3,.5,.12),Color("88988b"),false)
	_box("MonitorStand",Vector3(-3.05,.95,-2.6),Vector3(.12,.28,.12),Color("6b7670"),false)
	_box("Monitor",Vector3(-3.05,1.26,-2.58),Vector3(.58,.42,.15),Color("bac4b5"),false)
	_box("MonitorScreen",Vector3(-3.05,1.26,-2.495),Vector3(.49,.32,.015),Color("102928"),false)
	_sign("72  ♥\nNORMAL",Vector3(-3.05,1.26,-2.48),19)
	# Soft bedside lighting and cool overhead panels suit the existing PSX art.
	bedside_light = OmniLight3D.new()
	bedside_light.name = "BedsideLight"
	bedside_light.position = Vector3(-2.6,1.8,-2.4)
	bedside_light.light_color = Color("ffd2a1")
	bedside_light.light_energy = .8
	bedside_light.omni_range = 3.5
	add_child(bedside_light)
	_box("BedsideSwitch",Vector3(-2.8,1.45,-3.69),Vector3(.12,.18,.04),Color("d1d5bf"),false)
	_action("BedsideSwitch",Vector3(-2.8,1.45,-3.6),Vector3(.22,.26,.15),"light")
	for at in [Vector3(-1.5,2.98,1),Vector3(1.5,2.98,-1.5)]:
		_piece("Ceiling_Light",at,0,Vector3(1.3,1.3,1.3),false)
		var light := OmniLight3D.new()
		light.position = at - Vector3(0,.2,0)
		light.light_color = Color("d8e7dc")
		light.light_energy = 1.1
		light.omni_range = 7
		add_child(light)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("495b70")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("a0b2b7")
	world.environment.ambient_light_energy = .45
	add_child(world)

func _action(label: String, at: Vector3, size: Vector3, action: String) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 4
	body.set_meta("action",action)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(shape)
	add_child(body)
	body.position = at

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Visitor"
	add_child(player)
	player.position = Vector3(2.7,.03,2.8)
	player.rotation.y = .55
	var collision := CollisionShape3D.new()
	collision.shape = CapsuleShape3D.new()
	collision.shape.height = 1.75
	collision.shape.radius = .25
	collision.position.y = .875
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = 75
	player.add_child(camera)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.theme = preload("res://diner_ui.gd").theme()
	hud.add_child(ui)
	var title := Label.new()
	title.text = "ROOM 204  /  GRANDPA\nWASD: Walk     Mouse: Look     Esc: Pause"
	title.position = Vector2(24,24)
	title.add_theme_stylebox_override("normal",preload("res://diner_ui.gd").box(Color("191a1bdd"),16))
	ui.add_child(title)
	prompt = Label.new()
	ui.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -300
	prompt.offset_right = 300
	prompt.offset_top = -70
	prompt.offset_bottom = -25
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var dot := Label.new()
	dot.text = "·"
	ui.add_child(dot)
	dot.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dot.add_theme_font_size_override("font_size",24)
	preload("res://diner_ui.gd").passive(ui)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(incident) and incident.active: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * .0025)
		pitch = clampf(pitch-event.relative.y*.0025,-1.4,1.4)
		camera.rotation.x = pitch

func interact() -> void:
	if coop != null and not coop.hosting:
		coop.request_action()
		return
	if leaving or get_tree().paused or incident.active: return
	if target == "light": bedside_light.visible = not bedside_light.visible
	if target == "grandpa":
		if not incident.begin(): conversation.show_dialogue(earnings.grandpa.visit_dialogue(earnings.cash))
	if target == "exit":
		var demo = preload("res://playable_demo.gd").session(self)
		if demo != null:
			if not demo.talked_to_grandpa:
				conversation.show_choices("BEFORE YOU GO", "Talk to Grandpa at his bedside before heading home.", ["Okay"])
				return
			leaving = true
			preload("res://hospital_travel.gd").go(self,"res://demo_ending.tscn",earnings)
			return
		leaving = true
		if earnings.grandpa.visit_in_progress:
			earnings.grandpa.finish_evening()
			earnings._save()
		preload("res://hospital_travel.gd").go(self,"res://main.tscn",earnings)

func _physics_process(delta: float) -> void:
	if leaving or (is_instance_valid(incident) and incident.active): return
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	var forward := -camera.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP)
	var motion := (right * direction.x - forward * direction.y).normalized()
	player.velocity.x = motion.x * 3.0
	player.velocity.z = motion.z * 3.0
	if not player.is_on_floor(): player.velocity.y -= 18 * delta
	else: player.velocity.y = 0
	player.move_and_slide()
	var ray := PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*2.6,5,[player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	target = str(hit.collider.get_meta("action","")) if not hit.is_empty() else ""
	prompt.text = ("E: Go home / Start next morning" if earnings.grandpa.visit_in_progress else "E: Return to diner") if target == "exit" else (("E: Talk to Grandpa\n" + earnings.health_status()) if target == "grandpa" else ("E: Toggle bedside light" if target == "light" else ""))
	if interaction_release_required and not Input.is_action_pressed("interact"):
		interaction_release_required = false
	elif Input.is_action_just_pressed("interact") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not interaction_release_required:
		interact()
