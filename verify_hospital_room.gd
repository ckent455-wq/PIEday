extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room = load("res://hospital_room.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	for i in range(60): await physics_frame
	assert(room.player.is_on_floor(), "Visitor must spawn on solid floor")
	assert(room.player.position.y > -.1, "Visitor must not fall through floor")
	assert(room.furnishings.get_child_count() >= 50, "Hospital kit pieces should load")
	var world = room.get_world_3d().direct_space_state
	var bed_hit = world.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-1.65,2,-1.75),Vector3(-1.65,0,-1.75),1))
	assert(not bed_hit.is_empty(), "Bed must have collision")
	var exit_hit = world.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(3,1.2,3),Vector3(3,1.2,4),4))
	assert(not exit_hit.is_empty() and exit_hit.collider.get_meta("action") == "exit", "Exit interaction must be reachable")
	room.player.velocity = Vector3.ZERO
	room.player.position = Vector3(0,.03,2.4)
	room.player.rotation.y = 0.25
	room.camera.rotation.x = -.08
	for i in range(3): await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/hospital-preview.png")
	print("PASS: hospital loads, grounded spawn, bed collision, exit interaction and room screenshot")
	quit()
