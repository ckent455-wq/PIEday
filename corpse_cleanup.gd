extends Node3D

var shift: Node3D
var bodies: Array[Dictionary] = []
var carried_body: Node3D

func setup(host: Node3D) -> void:
	shift = host
	name = "BodyCleanup"
	var marker := StaticBody3D.new()
	add_child(marker)
	shift.task_nodes["bodies"] = marker
	shift.tasks["bodies"] = true

func kill(actor: Node3D, animate := true) -> Dictionary:
	var body := Node3D.new()
	body.name = "FallenCustomer"
	body.set_meta("action","corpse")
	add_child(body)
	body.global_transform = actor.global_transform
	actor.reparent(body)
	actor.transform = Transform3D.IDENTITY
	actor.get_node("Interaction").collision_layer = 0
	actor.get_node("Interaction").set_meta("action","corpse")
	var ragdoll: Dictionary = preload("res://customer_ragdoll.gd").build(actor,shift.game.player)
	var entry := {"body":body,"actor":actor,"ragdoll":ragdoll}
	bodies.append(entry)
	for other in shift.game.find_children("Interaction","StaticBody3D",true,false):
		ignore_customer(other)
	if animate: _kick.call_deferred(entry)
	return entry

func _kick(entry: Dictionary) -> void:
	await get_tree().physics_frame
	if not is_instance_valid(entry.body) or entry.body == carried_body: return
	var direction: Vector3 = entry.ragdoll.hip.global_position-shift.game.camera.global_position
	direction.y = 0
	direction = direction.normalized()
	for bone in entry.ragdoll.bones:
		bone.linear_velocity = direction*1.7+Vector3.UP*.25
		bone.angular_velocity = Vector3(direction.z,0,-direction.x)*1.8

func ignore_customer(interaction: PhysicsBody3D) -> void:
	for entry in bodies:
		for bone in entry.ragdoll.bones:
			bone.add_collision_exception_with(interaction)
			interaction.add_collision_exception_with(bone)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(carried_body): return
	if shift.phase != "cleanup":
		drop()
		return
	for entry in bodies:
		if entry.body == carried_body: _position_carried(entry)

func _begin_carry(entry: Dictionary) -> void:
	carried_body = entry.body
	var hip: PhysicalBone3D = entry.ragdoll.hip
	var head: PhysicalBone3D = entry.ragdoll.bones[2]
	var along := (head.global_position-hip.global_position).normalized()
	var turn := Basis(Quaternion(along,Vector3.RIGHT))
	var relative: Array[Transform3D] = []
	for bone in entry.ragdoll.bones:
		relative.append(Transform3D(turn*bone.global_basis,turn*(bone.global_position-hip.global_position)))
		bone.collision_layer = 0
		bone.collision_mask = 0
		bone.linear_velocity = Vector3.ZERO
		bone.angular_velocity = Vector3.ZERO
		PhysicsServer3D.body_set_mode(bone.get_rid(),PhysicsServer3D.BODY_MODE_KINEMATIC)
	entry["carry_pose"] = relative
	shift.carried_item = "Carrying body"
	shift._refresh_carried()
	_position_carried(entry)

func _position_carried(entry: Dictionary, camera_override: Camera3D = null) -> void:
	var camera: Camera3D = camera_override if camera_override != null else shift.game.camera
	var anchor := camera.global_transform
	anchor.origin = camera.to_global(Vector3(0,-.85,-1.15))
	for i in entry.ragdoll.bones.size():
		var bone: PhysicalBone3D = entry.ragdoll.bones[i]
		var target: Transform3D = anchor*entry.carry_pose[i]
		bone.global_transform = target
		PhysicsServer3D.body_set_state(bone.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,target)

func prompt() -> String:
	if shift.phase != "cleanup": return "Body · dispose of it during closing cleanup"
	return "[E] Release body · drag it to the outdoor dumpster" if is_instance_valid(carried_body) else "[E] Pick up body"

func grab(target: Node) -> void:
	if shift.phase != "cleanup":
		shift._message("Bodies must be disposed of during closing cleanup.")
		return
	if is_instance_valid(carried_body):
		drop()
		return
	if not shift.carried_item.is_empty() or shift.has_empty_cup() or shift.carrying_trash:
		shift._message("Free your hands before picking up a body.")
		return
	for entry in bodies:
		if target == entry.body or entry.body.is_ancestor_of(target):
			var coop = preload("res://coop_session.gd").active(self)
			if coop != null and not coop.acting_guest and entry.body == coop.guest_body:
				shift._message("Your partner is carrying that body.")
				return
			if coop != null and coop.acting_guest and entry.body == coop.host_carrying_body:
				shift._message("Your partner is carrying that body.")
				return
			_begin_carry(entry)
			shift._message("Body picked up. Carry it to the outdoor dumpster and press E to dispose. Q sets it down.")
			return

func drop() -> void:
	if is_instance_valid(carried_body):
		for entry in bodies:
			if entry.body != carried_body: continue
			for bone in entry.ragdoll.bones:
				bone.collision_layer = 4
				bone.collision_mask = 3
				PhysicsServer3D.body_set_mode(bone.get_rid(),PhysicsServer3D.BODY_MODE_RIGID)
				bone.linear_velocity = Vector3.ZERO
				bone.angular_velocity = Vector3.ZERO
	carried_body = null
	if shift.carried_item in ["Carrying body","Dragging body"]:
		shift.carried_item = ""
		shift._refresh_carried()

func dispose() -> void:
	if shift.phase != "cleanup" or not is_instance_valid(carried_body): return
	var body := carried_body
	drop()
	for i in bodies.size():
		if bodies[i].body == body:
			bodies.remove_at(i)
			break
	body.queue_free()
	shift.tasks.bodies = bodies.is_empty()
	shift._message("Body disposed of. %d remaining." % bodies.size())
	if shift.tasks.values().all(func(done): return done): shift._show_day_summary()

func begin_cleanup() -> void:
	drop()
	shift.tasks.bodies = bodies.is_empty()
	shift.task_nodes.bodies.hide()
	shift.task_nodes.bodies.collision_layer = 0

func reset() -> void:
	drop()
	for entry in bodies: entry.body.free()
	bodies.clear()

func snapshot() -> Dictionary:
	var saved: Array = []
	for entry in bodies:
		saved.append({"actor":preload("res://save_states.gd").actor_data(entry.actor),"transform":entry.body.transform,"ragdoll":preload("res://customer_ragdoll.gd").snapshot(entry.ragdoll),"carried":entry.body == carried_body})
	return {"bodies":saved}

func restore(data: Dictionary) -> void:
	reset()
	for saved in data.get("bodies",[]):
		var actor: Node3D = preload("res://save_states.gd").restore_actor(shift.customer_line,saved.actor)
		actor.global_transform = global_transform*saved.transform*actor.transform
		var entry := kill(actor,false)
		preload("res://customer_ragdoll.gd").restore(entry.ragdoll,saved.get("ragdoll",[]))
		if saved.get("carried",saved.get("dragged",false)) and shift.phase == "cleanup":
			_begin_carry(entry)
	shift.tasks.bodies = bodies.is_empty()
	shift.task_nodes.bodies.hide()
	shift.task_nodes.bodies.collision_layer = 0
