extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var room = load("res://hospital_room.tscn").instantiate()
	# Check saved collision nodes before runtime can repair missing ones.
	var count := 0
	for item in room.get_node("Furniture").get_children():
		require(item.has_node("SolidCollision"),"Missing saved collision: "+str(item.name))
		if item.has_node("SolidCollision"):
			require(item.get_node("SolidCollision").get_child_count() > 0,"Empty collision: "+str(item.name))
			count += 1
	root.add_child(room)
	current_scene = room
	room.set_physics_process(false)
	await physics_frame
	await physics_frame
	var checked := 0
	for item in room.furnishings.get_children():
		var file: String = item.scene_file_path.get_file()
		if not (file.begins_with("Bed.") or file.begins_with("Cabinet_") or file == "Chair.glb" or file == "Wheel_chair.glb"): continue
		var meshes = item.find_children("*","MeshInstance3D",true,false)
		var mesh = meshes[0]
		var bounds: AABB = mesh.global_transform * mesh.mesh.get_aabb()
		var center: Vector3 = bounds.get_center()
		# Sweep the actual player capsule sideways into each piece of furniture.
		var from := center + Vector3(bounds.size.x*.5+.7,0,0)
		from.y = .03
		var start := Transform3D(Basis.IDENTITY,from)
		# Isolate the item so adjacent furniture cannot mask a missing collider.
		var layers := {}
		for body in room.find_children("*","StaticBody3D",true,false):
			layers[body] = body.collision_layer
			body.collision_layer = 1 if body == item.get_node("SolidCollision") else 0
		var hit := KinematicCollision3D.new()
		var blocked: bool = room.player.test_move(start,Vector3(-bounds.size.x-1.4,0,0),hit)
		require(blocked,"Player capsule passes through "+str(item.name))
		if blocked:
			require(hit.get_collider() == item.get_node("SolidCollision"),"Sweep hit a different object for "+str(item.name))
		for body in layers: body.collision_layer = layers[body]
		checked += 1
	require(checked >= 7,"Must test bed, three cabinets, two chairs and wheelchair")
	room.ensure_furniture_collisions()
	for item in room.furnishings.get_children():
		var bodies := 0
		for child in item.get_children():
			if child.name == "SolidCollision": bodies += 1
		require(bodies == 1,"Repeated setup duplicated collisions")
	if failures == 0: print("PASS: %d saved collision bodies; player capsule blocked by all %d major furniture pieces; no duplicate bodies" % [count,checked])
	room.queue_free()
	await process_frame
	quit(1 if failures else 0)
