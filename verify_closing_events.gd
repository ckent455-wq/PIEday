extends SceneTree
var failures := 0

func _initialize(): call_deferred("check")

func require(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func check():
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.earnings.save_enabled = false
	var events = shift.closing_events
	require(not events.active and not events.figure.visible, "No haunting during daylight")
	shift.begin_cleanup()
	events.rng.seed = 42517
	var counts := {"": 0, "bell": 0, "flicker": 0, "figure": 0, "knocks": 0, "cooler": 0, "footsteps": 0}
	for night in range(300):
		events.begin()
		var enabled := int(not events.bell_done) + int(not events.flicker_done) + int(not events.figure_done) + int(not events.extra_done)
		require(enabled <= 1, "At most one encounter even on the first shift")
		counts[events.encounter] += 1
	for count in counts.values(): require(count > 12, "Quiet nights and each encounter occur")
	print("Seeded encounter distribution: ", counts)
	events.begin()
	events.extra_done = true
	events.bell_done = false
	events.flicker_done = true
	events.figure_done = true
	events.bell_at = 0
	events.flicker_at = 100
	events.figure_at = 0
	var notice: String = shift.notice.text
	events.tick(0.1)
	require(events.bell_done and shift.service_bell.sound.playing, "Unattended bell sounds")
	require(shift.notice.text == notice and shift.phase == "cleanup", "Bell leaves chores and orders alone")
	events.flicker_at = 0
	events.flicker_done = false
	events.tick(0.05)
	var light = game.get_node("NightInteriorLights").get_child(0)
	require(light.light_energy < 0.2, "Interior lights dim")
	events.tick(1.3)
	require(is_equal_approx(light.light_energy, 1.6), "Lights recover")
	game.player.position = Vector3(-0.6, -0.09, -15.7)
	game.camera.look_at(events.figure.global_position + Vector3(0, 1.7, 0))
	events.figure_done = false
	await physics_frame
	await physics_frame
	events.tick(0.4)
	require(events.figure.visible and events.figure_seen, "Human-sized figure is visible in rear corner")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/closing-figure.png")
	game.camera.rotate_y(PI)
	events.tick(0.3)
	require(not events.figure.visible and events.figure_done, "Figure disappears after looking away")
	events.tick(10)
	require(not events.figure.visible, "Figure does not respawn that night")
	events.figure_done = false
	events.figure_seen = false
	events.seen_seconds = 0
	game.camera.look_at(events.figure.global_position + Vector3(0, 1.7, 0))
	events.tick(2.1)
	require(events.figure_done and not events.figure.visible, "Staring only gives a short glimpse")
	events.flicker_done = false
	events.flicker_at = 0
	events.tick(0.05)
	shift.begin_prep()
	require(not events.active and not events.figure.visible and is_equal_approx(light.light_energy, 1.6), "Next day cancels effects and restores lighting")
	if failures == 0: print("PASS: closing-only bell, light recovery, visible yard figure, look-away disappearance, next-day reset")
	quit(1 if failures > 0 else 0)
