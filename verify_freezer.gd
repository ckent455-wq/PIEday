extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.shift.earnings.save_enabled = false
	game.set_physics_process(false)
	await physics_frame
	var door: MeshInstance3D
	for candidate in game.doors:
		if candidate.name == "Door_02":
			door = candidate
	assert(door != null)
	assert(not game.has_node("IndoorBoundary_Door_02"))
	game.player.position = Vector3(5.7, -0.09, -11.9)
	for step in range(45):
		await physics_frame
		game.player.velocity = Vector3(3, -1, 0)
		game.player.move_and_slide()
	assert(game.player.position.x < 6.6, "Closed freezer door must block the player")
	game._toggle_door(door)
	await create_timer(0.6).timeout
	for step in range(65):
		await physics_frame
		game.player.velocity = Vector3(3, -1, 0)
		game.player.move_and_slide()
	assert(game.player.position.x > 8.0, "Player must fit through the open freezer doorway")
	assert(Rect2(-10.2, -14.35, 21.25, 6.95).has_point(Vector2(game.player.position.x, game.player.position.z)))
	print("PASS: closed freezer blocks movement; open freezer admits player at ", game.player.position)
	quit()
