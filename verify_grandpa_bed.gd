extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var room = load("res://hospital_room.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	var bed = room.get_node("Furniture/Bed")
	var grandpa = bed.get_node("Grandpa")
	assert(grandpa.get_meta("face_texture") == "D28")
	assert(grandpa.global_basis.y.normalized().dot(-bed.global_basis.z.normalized()) > .99,"Grandpa must lie along the bed")
	room.set_physics_process(false)
	room.set_process_unhandled_input(false)
	room.player.position = bed.global_position + Vector3(1.7,.15,.1)
	await process_frame
	room.camera.look_at(bed.global_position + Vector3(0,.9,-.2))
	for i in range(5): await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/grandpa-bed-preview.png")
	print("PASS: D28 Grandpa lies on hospital bed")
	room.queue_free()
	await process_frame
	quit()
