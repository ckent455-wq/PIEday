extends SceneTree
func _initialize(): call_deferred("check")
func check():
	var intro = load("res://intro.tscn").instantiate()
	root.add_child(intro)
	current_scene = intro
	intro.set_process(false)
	assert(intro.narrative.visible_characters == 0 and not intro.complete)
	intro._process(0.75)
	assert(intro.key_sounds_played > 0 and intro.key_audio.stream != null)
	var typed_sounds: int = intro.key_sounds_played
	assert(intro.narrative.visible_characters > 0 and intro.narrative.visible_characters < intro.PASSAGES[0].length())
	intro._continue()
	assert(intro.key_sounds_played == typed_sounds and not intro.key_audio.playing, "Revealing text must stop sound, without a burst of skipped keystrokes")
	assert(intro.complete and intro.narrative.visible_characters == -1)
	assert(intro.passage_index == 0 and intro.goal_label.modulate.a == 0)
	for page in range(1,intro.PASSAGES.size()):
		intro._continue()
		assert(intro.passage_index == page and not intro.complete and intro.narrative.visible_characters == 0)
		var key := InputEventKey.new()
		key.keycode = KEY_E if page % 2 == 0 else KEY_SPACE
		key.pressed = true
		intro._unhandled_input(key)
		assert(intro.complete and intro.passage_index == page, "E/Space reveals without skipping a passage")
	assert(intro.goal_label.modulate.a == 1 and intro.continue_button.text.contains("Open the Diner"))
	if DisplayServer.get_name() != "headless":
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../work/intro-preview.png")
	intro._continue()
	assert(paused and root.has_node("IntroTransition"), "Fade blocks gameplay during the transition")
	await create_timer(2.6).timeout
	assert(not paused and not root.has_node("IntroTransition"), "Fade releases gameplay and cleans up")
	assert(current_scene.name == "DinerExplorer")
	assert(current_scene.shift.phase == "prep" and current_scene.shift.shift_remaining == 300)
	assert(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	print("PASS: black-screen intro, gradual typing, reveal without premature start, goal reveal, continue into morning duties, full shift clock and mouse capture")
	quit()
