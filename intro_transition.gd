extends CanvasLayer

func begin() -> void:
	name = "IntroTransition"
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(black)
	var tree := get_tree()
	var was_paused := tree.paused
	tree.paused = true
	var fade_out := create_tween()
	fade_out.tween_property(black, "color:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished
	if tree.change_scene_to_file("res://main.tscn") != OK:
		tree.paused = was_paused
		queue_free()
		return
	# This overlay survives the scene change and covers the first diner frame.
	await tree.process_frame
	await tree.process_frame
	var fade_in := create_tween()
	fade_in.tween_property(black, "color:a", 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_in.finished
	tree.paused = was_paused
	queue_free()
