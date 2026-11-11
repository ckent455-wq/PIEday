extends Node

var shift: Node3D
var waiting: Array[Dictionary] = []
var departing: Array[Dictionary] = []
var next_arrival := 6.0
var time := 0.0
var front_door_auto_opened := false
var front_door_open_for := 0.0
const CUSTOMER_MODELS := ["male_1", "female_1", "male_2", "female_2", "male_3", "female_3", "male_photo", "male_glasses"]
const ROBBER_MODELS := ["robber_1", "robber_2"]
const WALK_SPEED := 4.0
const ROBBER_RUN_SPEED := 7.5
const EVACUATION_RUN_SPEED := 8.0
const LEGACY_ENCOUNTERS := {"adult_unclothed": "robber_1", "adult_female_unclothed": "robber_2"}
var last_model := -1
var nude_chance := 0.08
var last_was_nude := false
var force_nude_next := false
var force_nude_model := ""

func _roll_robber() -> bool:
	# Explicit practice/test requests bypass scheduling; random encounters require
	# an accepted order and a staff member physically at the service counter.
	return force_nude_next or (shift.robbery.can_start_encounter() and not last_was_nude and randf() < nude_chance)

func make_actor(at: Vector3, saved_model := "") -> Node3D:
	var actor := Node3D.new()
	actor.name = "DinerCustomer"
	shift.add_child(actor)
	actor.position = at
	actor.set_meta("display_name", preload("res://customer_names.gd").generate())
	var model_index := randi_range(0, CUSTOMER_MODELS.size() - 1)
	if last_model >= 0:
		model_index = (last_model + randi_range(1, CUSTOMER_MODELS.size() - 1)) % CUSTOMER_MODELS.size()
	last_model = model_index
	var robber := _roll_robber()
	force_nude_next = false
	last_was_nude = robber
	var model_name: String = CUSTOMER_MODELS[model_index]
	if robber:
		var forced: String = LEGACY_ENCOUNTERS.get(force_nude_model, force_nude_model)
		model_name = forced if forced in ROBBER_MODELS else ROBBER_MODELS.pick_random()
		force_nude_model = ""
	saved_model = LEGACY_ENCOUNTERS.get(saved_model, saved_model)
	if saved_model in CUSTOMER_MODELS or saved_model in ROBBER_MODELS:
		model_name = saved_model
		robber = saved_model in ROBBER_MODELS
	if robber:
		var variant := ROBBER_MODELS.find(model_name)
		var visual := attach_visual(actor, "male_1" if variant == 0 else "female_1", false)
		_disguise_robber(visual, variant)
		preload("res://robber_weapon.gd").equip(actor)
		actor.set_meta("display_name", "Masked robber")
	else:
		attach_visual(actor, model_name)
	actor.set_meta("customer_model", model_name)
	actor.set_meta("requires_refusal", robber)
	var body := StaticBody3D.new()
	body.name = "Interaction"
	body.collision_layer = 5
	body.set_meta("action", "queued_customer")
	actor.add_child(body)
	if is_instance_valid(shift.corpses): shift.corpses.ignore_customer(body)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 2.15
	collider.shape = shape
	collider.position.y = 1.075
	body.add_child(collider)
	actor.set_meta("queue_wait", 0.0)
	return actor

static func _disguise_robber(visual: Node3D, variant: int) -> void:
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(surface) as StandardMaterial3D
			if original == null or original.resource_name not in ["Face", "Clothes"]: continue
			var disguise := ShaderMaterial.new()
			disguise.shader = preload("res://robber_disguise.gdshader")
			disguise.set_shader_parameter("original_texture", original.albedo_texture)
			disguise.set_shader_parameter("head", original.resource_name == "Face")
			disguise.set_shader_parameter("jacket", Vector3(0.085, 0.10, 0.13) if variant == 0 else Vector3(0.13, 0.085, 0.10))
			mesh.set_surface_override_material(surface, disguise)

static func attach_visual(actor: Node3D, model_name: String, animate := true) -> Node3D:
	var visual: Node3D = load("res://assets/customers/" + model_name + ".glb").instantiate()
	visual.name = "Visual"
	actor.add_child(visual)
	visual.scale = Vector3.ONE * 1.17
	var bones: Dictionary = {}
	for skeleton in visual.find_children("*", "Skeleton3D", true, false):
		for bone_name in ["Arm_L","Arm_R","Leg_L","Leg_R"]:
			var id: int = skeleton.find_bone(bone_name)
			if id >= 0:
				var baseline: Quaternion = skeleton.get_bone_pose_rotation(id)
				if bone_name.begins_with("Arm"):
					var rest: Quaternion = skeleton.get_bone_global_rest(id).basis.get_rotation_quaternion()
					baseline *= rest.inverse() * Quaternion(Vector3.FORWARD, 0.65 if bone_name == "Arm_L" else -0.65) * rest
					skeleton.set_bone_pose_rotation(id, baseline)
				bones[id] = baseline
		actor.set_meta("skeleton", skeleton)
		break
	actor.set_meta("rest_bones", bones)
	if animate and model_name in CUSTOMER_MODELS and not actor.has_meta("locomotion"):
		# Robbers retain their raised weapon arm and existing combat poses.
		var locomotion := preload("res://customer_locomotion.gd").new()
		actor.add_child(locomotion)
		locomotion.setup(actor,visual,model_name)
		actor.set_meta("locomotion",locomotion)
	return visual

func pop_front() -> Node3D:
	var entry: Dictionary = waiting.pop_front()
	_pose(entry.actor, 0)
	entry.actor.set_meta("queue_wait", entry.seconds)
	return entry.actor

func arrival_speed(actor: Node3D) -> float:
	return ROBBER_RUN_SPEED if actor.get_meta("requires_refusal", false) else WALK_SPEED

func leave(actor: Node3D, angry: bool, closing := false, emergency := false) -> void:
	actor.get_node("Interaction").set_meta("action", "departing_customer")
	var route := [Vector3(-2.4,-0.094,-0.2),Vector3(0.76,-0.094,0.2),Vector3(0.76,-0.094,6.1)]
	if closing:
		route = [Vector3(0.76,-0.094,0.2),Vector3(0.76,-0.094,6.1)] if actor.position.z < 0.2 else [Vector3(0.76,-0.094,6.1)]
	var speed := 6.5 if angry else 5.5
	if emergency: speed = EVACUATION_RUN_SPEED
	departing.append({"actor":actor,"route":route,"step":0,"speed":speed})

func evacuate(keep_active := false, emergency := false) -> void:
	if not keep_active and is_instance_valid(shift.customer):
		if not emergency and is_instance_valid(shift.speech): shift.speech.text = "Diner's closed. Good night."
		leave(shift.customer, false, true, emergency)
		shift.customer = null
	for entry in waiting:
		leave(entry.actor, false, true, emergency)
	waiting.clear()
	if emergency:
		for entry in departing: entry.speed = EVACUATION_RUN_SPEED

func _tick_arrivals(delta: float) -> void:
	# Older saves can contain a robber who was already in line.
	for index in range(waiting.size()):
		var queued: Node3D = waiting[index].actor
		if queued.get_meta("requires_refusal", false):
			if not shift.robbery.staff_at_counter(): return
			waiting.remove_at(index)
			shift._begin_robbery_arrival(queued)
			return
	next_arrival -= delta
	if next_arrival > 0: return
	var rushing: bool = shift.rush_active()
	var line_capacity := 4 if rushing else 3
	next_arrival = 3.0 if rushing else 8.0
	if waiting.size() + int(is_instance_valid(shift.customer)) >= line_capacity:
		force_nude_next = _roll_robber()
		if not force_nude_next: return
	var actor := make_actor(Vector3(0.76,-0.094,5))
	if actor.get_meta("requires_refusal", false):
		shift._begin_robbery_arrival(actor)
	else:
		waiting.append({"actor":actor,"seconds":0.0,"junction":false})

func tick(delta: float) -> void:
	time += delta
	if not shift.closing_time and not shift.refusal_required() and shift.phase in ["arriving","waiting","leaving"]:
		_tick_arrivals(delta)
	for index in range(waiting.size()):
		var entry: Dictionary = waiting[index]
		entry.seconds += delta
		var goal := Vector3(-1.55 + index*0.8,-0.094,-2.05 + index*1.5) if entry.junction else Vector3(0.76,-0.094,0.2)
		var speed := arrival_speed(entry.actor)
		var moving := _move(entry.actor,goal,speed,delta)
		if not moving: entry.junction = true
		var running := speed == ROBBER_RUN_SPEED
		_pose(entry.actor, sin(time * (28.0 if running else 17.5)) * (1.35 if running else 1.0) if moving else 0.0)
		entry.actor.get_node("Visual").rotation.z = sin(time*1.8 + index)*0.018 if entry.seconds > 45 and not moving else 0
	for entry in departing.duplicate():
		var moving := _move(entry.actor,entry.route[entry.step],entry.speed,delta)
		var running: bool = entry.speed == EVACUATION_RUN_SPEED
		_pose(entry.actor, sin(time * 28.0) * 1.35 if running else sin(time * 17.5))
		if not moving:
			entry.step += 1
			if entry.step >= entry.route.size():
				entry.actor.queue_free()
				departing.erase(entry)

	_tick_front_door(delta)

func _tick_front_door(delta: float) -> void:
	var front: MeshInstance3D
	for door in shift.game.doors:
		if door.name == "Door_03": front = door; break
	if not is_instance_valid(front): return
	var center := _front_door_center(front)
	front_door_open_for = front_door_open_for + delta if front.get_meta("open", false) else 0.0
	var actors: Array[Node3D] = []
	if is_instance_valid(shift.customer): actors.append(shift.customer)
	for entry in waiting + departing:
		if is_instance_valid(entry.actor): actors.append(entry.actor)
	var passing := false
	for actor in actors:
		var at := actor.global_position
		if absf(at.z - center.z) < 2.0 and absf(at.x - center.x) < 1.2:
			passing = true
			break
	if passing and not front.get_meta("open", false):
		front_door_auto_opened = true
		shift.game._set_door_open(front, true)
	elif not passing and front_door_auto_opened:
		if front.get_meta("open", false): shift.game._set_door_open(front, false)
		front_door_auto_opened = false

func _front_door_center(front: MeshInstance3D) -> Vector3:
	var closed := Transform3D(Basis(Vector3.UP, float(front.get_meta("closed_rotation"))), front.position)
	return front.get_parent().global_transform * closed * front.mesh.get_aabb().get_center()

func front_door_passage_ready(actor: Node3D, goal: Vector3) -> bool:
	var front: MeshInstance3D = shift.game.find_child("Door_03", true, false)
	if not is_instance_valid(front): return true
	var center := _front_door_center(front)
	if (actor.position.z - center.z) * (goal.z - center.z) >= 0: return true
	if absf(actor.position.z - center.z) >= 2.0: return true
	return front.get_meta("open", false) and front_door_open_for >= 0.45

func _move(actor: Node3D, goal: Vector3, speed: float, delta: float) -> bool:
	if not front_door_passage_ready(actor, goal): return true
	var offset := goal - actor.position
	if offset.length() <= speed*delta:
		actor.position = goal
		actor.rotation.y = PI
		return false
	actor.position += offset.normalized()*speed*delta
	actor.rotation.y = atan2(offset.x,offset.z)
	return true

func _pose(actor: Node3D, stride: float) -> void:
	if actor.has_meta("locomotion"): return
	var skeleton: Skeleton3D = actor.get_meta("skeleton", null)
	if not is_instance_valid(skeleton): return
	var baselines: Dictionary = actor.get_meta("rest_bones")
	for id in baselines:
		var bone_name: String = skeleton.get_bone_name(id)
		var amplitude := 0.16 if bone_name.begins_with("Arm") else 0.29
		var angle := stride*amplitude*(-1 if bone_name in ["Arm_L","Leg_R"] else 1)
		var rest := skeleton.get_bone_global_rest(id).basis.get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(id,baselines[id]*rest.inverse()*Quaternion(Vector3.RIGHT,angle)*rest)

func clear_all() -> void:
	front_door_open_for = 0.0
	if front_door_auto_opened:
		for door in shift.game.doors:
			if door.name == "Door_03": shift.game._set_door_open(door, false)
		front_door_auto_opened = false
	for entry in waiting + departing:
		if is_instance_valid(entry.actor): entry.actor.queue_free()
	waiting.clear()
	departing.clear()
	next_arrival = 6.0
