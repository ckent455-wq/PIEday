extends Node

var shift: Node3D
var waiting: Array[Dictionary] = []
var departing: Array[Dictionary] = []
var next_arrival := 6.0
var time := 0.0

func make_actor(at: Vector3) -> Node3D:
	var actor := Node3D.new()
	actor.name = "DinerCustomer"
	shift.add_child(actor)
	actor.position = at
	var visual: Node3D = load("res://assets/customer/customer.glb").instantiate()
	visual.name = "Visual"
	actor.add_child(visual)
	visual.scale = Vector3.ONE * 1.2
	shift._randomize_customer_shirt(visual)
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
			if id >= 0: bones[id] = skeleton.get_bone_pose_rotation(id)
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

func leave(actor: Node3D, angry: bool) -> void:
	actor.get_node("Interaction").set_meta("action", "departing_customer")
	departing.append({"actor":actor,"route":[Vector3(-2.4,-0.094,-0.2),Vector3(0.76,-0.094,0.2),Vector3(0.76,-0.094,6.1)],"step":0,"speed":6.5 if angry else 5.5})

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
