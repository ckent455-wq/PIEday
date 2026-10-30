extends SceneTree
var failures := 0
func _initialize(): call_deferred("check")
func require(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func move(player: CharacterBody3D, direction: Vector3, frames: int):
	for frame in range(frames):
		await physics_frame
		player.velocity.x = direction.x * 3.2
		player.velocity.z = direction.z * 3.2
		player.velocity.y -= 18.0 / 60.0
		player.move_and_slide()
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	game.shift.set_process(false)
	game.shift.earnings.save_enabled = false
	var player: CharacterBody3D = game.player
	var dumpster = game.find_child("OutdoorDumpster", true, false)
	require(dumpster.has_node("SmoothDumpsterCollision"), "Single smooth dumpster hull")
	# Land on the lid and step off its front and right edges.
	for direction in [Vector3.FORWARD * -1, Vector3.RIGHT]:
		player.position = Vector3(-1.65, 2.0, -19.0)
		player.velocity = Vector3.ZERO
		await move(player, Vector3.ZERO, 45)
		require(player.is_on_floor() and player.position.y > 1.2, "Can land on the lid without sinking into it")
		await move(player, direction, 65)
		require(player.position.y < 0.1 and player.is_on_floor(), "Can walk off dumpster onto yard floor")
	# Jump toward rear/side fence, then reverse out without a boundary clamp.
	for direction in [Vector3.FORWARD, Vector3.LEFT]:
		player.position = Vector3(-1.65, 1.35, -19.0)
		player.velocity = Vector3(0, 6, 0)
		await move(player, direction, 40)
		require(preload("res://service_yard.gd").WALK_AREA.has_point(Vector2(player.position.x, player.position.z)), "Jump cannot cross yard boundary")
		await move(player, Vector3(1, 0, 1).normalized(), 65)
		require(player.position.z > -18.0 and player.position.y < 0.1, "Can return from fence edge without getting wedged")
	game.camera.look_at(dumpster.global_position + Vector3(0, 0.7, 0))
	game._update_interaction()
	require(is_instance_valid(game.target_action) and game.target_action.get_meta("action") == "dispose", "Smooth hull retains trash interaction")
	if failures == 0: print("PASS: dumpster landings, step-offs, rear/side jump boundaries, escape paths and disposal targeting")
	quit(1 if failures else 0)
