extends SceneTree
func _initialize(): call_deferred("check")
func check():
	root.set_meta("pie_day_wallet", preload("res://earnings.gd").new(false))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.shift.set_process(false)
	await process_frame
	var showcase = game.get_node("ScareShowcase")
	var events = game.shift.closing_events
	assert(not game.shift.earnings.save_enabled)
	for i in range(6):
		showcase.select_scare(i)
		assert(events.encounter == showcase.SCARES[i])
		assert(game.shift.phase == "cleanup" and not events.figure.visible)
		await create_timer(.55).timeout
		if i == 2:
			game._update_interaction()
			assert(is_instance_valid(game.target_action) and game.target_action.get_meta("action","") == "dispose")
			game.shift.interact(game.target_action)
			events.tick(.01)
			assert(events.figure.visible)
			game.face_point(events.figure.global_position+Vector3(0,2.1,0))
			await physics_frame
			events.tick(.01)
			assert(events.monster_audio.playing and events.dissolve_elapsed >= 0)
			events.tick(.7)
			assert(events.figure_done)
		else:
			events.tick(1.4)
			events.tick(.11)
			match i:
				0: assert(game.shift.service_bell.sound.playing)
				1: assert(events.flicker_done and events.flicker_time >= 0)
				3: assert(events.extra_done and events.effect_audio.playing)
				4: assert(events.extra_done and is_instance_valid(events.opened_cooler) and events.opened_cooler.get_node("OpeningSound").playing)
				5:
					assert(events.extra_done and events.steps_left == 6)
					for j in range(6): events.tick(.7)
					assert(events.steps_left == 0 and events.effect_audio.playing)
		print("PASS: showcase ",i+1," ",events.encounter)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_R
	showcase._input(key)
	assert(showcase.current == 5 and events.steps_left == 0 and not events.extra_done)
	key.keycode = KEY_N
	showcase._input(key)
	assert(showcase.current == 0)
	key.keycode = KEY_4
	showcase._input(key)
	assert(showcase.current == 3)
	if DisplayServer.get_name() != "headless":
		await create_timer(.15).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/scare-showcase.png")
	print("PASS: all six real encounters, audio/visual triggers, isolated save-free test mode, replay/next/direct-selection controls")
	quit()
