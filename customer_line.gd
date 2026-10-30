extends Node

var shift: Node3D
var waiting: Array[Dictionary] = []
var departing: Array[Dictionary] = []
var next_arrival := 6.0
var time := 0.0
const CUSTOMER_MODELS := ["male_1", "female_1", "male_2", "female_2", "male_3", "female_3"]
var last_model := -1
var nude_chance := 0.08
var last_was_nude := false
var force_nude_next := false

func make_actor(at: Vector3) -> Node3D:
	var actor := Node3D.new()
	actor.name = "DinerCustomer"
	shift.add_child(actor)
	actor.position = at
	var model_index := randi_range(0, CUSTOMER_MODELS.size() - 1)
	if last_model >= 0:
		model_index = (last_model + randi_range(1, CUSTOMER_MODELS.size() - 1)) % CUSTOMER_MODELS.size()
	last_model = model_index
	var unclothed := force_nude_next or (not last_was_nude and randf() < nude_chance)
	force_nude_next = false
	last_was_nude = unclothed
	var model_name: String = "adult_unclothed" if unclothed else CUSTOMER_MODELS[model_index]
	var visual: Node3D = load("res://assets/customers/" + model_name + ".glb").instantiate()
	visual.name = "Visual"
	actor.add_child(visual)
	visual.scale = Vector3.ONE * 1.17
	actor.set_meta("customer_model", model_name)
	actor.set_meta("requires_refusal", unclothed)
	var body := StaticBody3D.new()
	body.name = "Interaction"
	body.collision_layer = 5
	body.set_meta("action", "queued_customer")
	actor.add_child(body)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 2.15
	collider.shape = shape
	collider.position.y = 1.075
	body.add_child(collider)
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
	actor.set_meta("queue_wait", 0.0)
	return actor

func pop_front() -> Node3D:
	var entry: Dictionary = waiting.pop_front()
	_pose(entry.actor, 0)
	entry.actor.set_meta("queue_wait", entry.seconds)
	return entry.actor

func leave(actor: Node3D, angry: bool, closing := false) -> void:
	actor.get_node("Interaction").set_meta("action", "departing_customer")
	var route := [Vector3(-2.4,-0.094,-0.2),Vector3(0.76,-0.094,0.2),Vector3(0.76,-0.094,6.1)]
	if closing:
		route = [Vector3(0.76,-0.094,0.2),Vector3(0.76,-0.094,6.1)] if actor.position.z < 0.2 else [Vector3(0.76,-0.094,6.1)]
	departing.append({"actor":actor,"route":route,"step":0,"speed":6.5 if angry else 5.5})

func evacuate() -> void:
	if is_instance_valid(shift.customer):
		if is_instance_valid(shift.speech): shift.speech.text = "Diner's closed. Good night."
		leave(shift.customer, false, true)
		shift.customer = null
	for entry in waiting:
		leave(entry.actor, false, true)
	waiting.clear()

func tick(delta: float) -> void:
	time += delta
	if not shift.closing_time and shift.phase in ["arriving","waiting","leaving"]:
		next_arrival -= delta
		if next_arrival <= 0 and waiting.size() + int(is_instance_valid(shift.customer)) < 3:
			waiting.append({"actor":make_actor(Vector3(0.76,-0.094,5)),"seconds":0.0,"junction":false})
			next_arrival = 8.0
	for index in range(waiting.size()):
		var entry: Dictionary = waiting[index]
		entry.seconds += delta
		var goal := Vector3(-1.55 + index*0.8,-0.094,-2.05 + index*1.5) if entry.junction else Vector3(0.76,-0.094,0.2)
		var moving := _move(entry.actor,goal,4.0,delta)
		if not moving: entry.junction = true
		_pose(entry.actor, sin(time*17.5) if moving else 0)
		entry.actor.get_node("Visual").rotation.z = sin(time*1.8 + index)*0.018 if entry.seconds > 45 and not moving else 0
	for entry in departing.duplicate():
		var moving := _move(entry.actor,entry.route[entry.step],entry.speed,delta)
		_pose(entry.actor,sin(time*17.5))
		if not moving:
			entry.step += 1
			if entry.step >= entry.route.size():
				entry.actor.queue_free()
				departing.erase(entry)

func _move(actor: Node3D, goal: Vector3, speed: float, delta: float) -> bool:
	var offset := goal - actor.position
	if offset.length() <= speed*delta:
		actor.position = goal
		actor.rotation.y = PI
		return false
	actor.position += offset.normalized()*speed*delta
	actor.rotation.y = atan2(offset.x,offset.z)
	return true

func _pose(actor: Node3D, stride: float) -> void:
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
	for entry in waiting + departing:
		if is_instance_valid(entry.actor): entry.actor.queue_free()
	waiting.clear()
	departing.clear()
	next_arrival = 6.0
