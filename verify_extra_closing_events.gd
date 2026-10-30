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
	require(is_instance_valid(events.bathroom_door), "Bathroom source exists")
	var at: Vector3 = (events.bathroom_door.global_transform * events.bathroom_door.get_aabb()).get_center()
	game.player.global_position = at + Vector3(1, 0, 1)
	events.tick(0.1)
	require(events.extra_done and events.effect_audio.playing, "Knocking plays near bathroom")
	require(events.effect_audio.global_position.distance_to(at) < 0.01, "Knocking comes from actual cubicle door")
	select(events, "cooler")
	var cooler: MeshInstance3D
	for door in game.doors:
		if door.has_meta("cooler"):
			game._set_door_open(door, false)
			cooler = door
	at = (cooler.global_transform * cooler.get_aabb()).get_center()
	game.player.global_position = at + Vector3(0, 0, 3)
	game.camera.look_at(game.camera.global_position + Vector3(0, 0, 1))
	events.tick(0.1)
	require(events.extra_done and is_instance_valid(events.opened_cooler), "Cooler opens while player looks away")
	var opened = events.opened_cooler
	require(opened.get_meta("open"), "Normal door state tracks haunted opening")
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
	if failures == 0: print("PASS: spatial bathroom knocks, cooler opening and player closing, six moving footsteps, next-day cleanup")
	quit(1 if failures else 0)
