extends SceneTree
var failures := 0
func _initialize(): call_deferred("check")
func require(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func select(events, name: String):
	events.begin()
	events.encounter = name
	events.bell_done = true
	events.flicker_done = true
	events.figure_done = true
	events.extra_done = false
	events.extra_at = 0
func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	shift.begin_cleanup()
	var events = shift.closing_events
	select(events, "knocks")
	require(events.stall_doors.size() == 3, "All three stall doors are connected")
	events.tick(30.0)
	events.on_mopping_started("kitchen")
	require(not events.extra_done and not events.effect_audio.playing, "No bangs from waiting or mopping the kitchen")
	events.on_mopping_started("bathroom")
	require(events.extra_done and events.finishing_stall_scare(), "Bangs start with bathroom mopping")
	for motion in events.stall_motions.values():
		motion.pause()
		motion.custom_step(0.075)
	for i in events.stall_doors.size():
		var door: MeshInstance3D = events.stall_doors[i]
		var moved := absf(door.rotation.y - events._stall_rest_angle(door)) > 0.2
		require(moved == (i == 0), "Only the first struck door moves on the first bang")
	for motion in events.stall_motions.values():
		motion.custom_step(0.23)
	var second: MeshInstance3D = events.stall_doors[2]
	require(absf(second.rotation.y - events._stall_rest_angle(second)) > 0.2, "The next bang moves a different door")
	for motion in events.stall_motions.values():
		motion.custom_step(1.1)
	for door in events.stall_doors:
		require(is_equal_approx(door.rotation.y, events._stall_rest_angle(door)), "Every door settles at its original open or closed angle")
	select(events, "cooler")
	var cooler: MeshInstance3D
	for door in game.doors:
		if door.has_meta("cooler"):
			game._set_door_open(door, false)
			cooler = door
	var at: Vector3 = (cooler.global_transform * cooler.get_aabb()).get_center()
	game.player.global_position = Vector3(at.x, 0.03, at.z - 2.5)
	game.face_point(game.camera.global_position + Vector3(0, 0, -1))
	await physics_frame
	await physics_frame
	events.tick(.1)
	require(not events.extra_done and not is_instance_valid(events.opened_cooler), "Looking away does not trigger the cooler")
	game.face_point(at)
	await physics_frame
	events.tick(0.1)
	require(events.extra_done and is_instance_valid(events.opened_cooler), "Cooler opens while player watches")
	var opened = events.opened_cooler
	require(opened.get_meta("open"), "Normal door state tracks haunted opening")
	require(opened.get_node("OpeningSound").playing and not events.effect_audio.playing, "Haunted opening uses the same door audio once")
	game._toggle_door(opened)
	require(not opened.get_meta("open"), "Player can close haunted door normally")
	game._toggle_door(opened)
	select(events, "footsteps")
	require(not opened.get_meta("open"), "Reset restores a haunted door left open")
	game.player.position = Vector3(-2.4, 0.03, -5.8)
	game.camera.look_at(Vector3(-2.4, 1.5, -11))
	events.tick(0.1)
	require(events.extra_done and events.steps_left == 6, "Footsteps start offscreen")
	var start: Vector3 = events.step_position
	for i in range(6): events.tick(0.7)
	require(events.steps_left == 0 and events.effect_audio.playing, "Exactly six footsteps play")
	require(events.effect_audio.global_position.distance_to(start) > 2, "Footstep audio moves through empty diner")
	shift.begin_prep()
	require(not events.active and not events.effect_audio.playing and events.steps_left == 0, "Effects stop on next day")
	require(not shift.tasks.values().has(false), "Encounters do not add or block chores")
	if failures == 0: print("PASS: bathroom-mop bangs and door motion, cooler opening and player closing, six moving footsteps, next-day cleanup")
	quit(1 if failures else 0)
