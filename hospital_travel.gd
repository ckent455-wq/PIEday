extends RefCounted

static func go(host: Node, destination: String, wallet: RefCounted = null) -> void:
	var coop = preload("res://coop_session.gd").active(host)
	if coop != null and not coop.transporting:
		coop.travel(host, destination, wallet)
		return
	if host.get_tree().root.has_meta("hospital_travel_busy"): return
	var tree := host.get_tree()
	if wallet != null: tree.root.set_meta("pie_day_wallet",wallet)
	tree.root.set_meta("hospital_travel_busy",true)
	var previous_scene := tree.current_scene
	if is_instance_valid(previous_scene):
		var music := previous_scene.get_node_or_null("HospitalMusic")
		if is_instance_valid(music): music.fade_out(.35)
		previous_scene.process_mode = Node.PROCESS_MODE_DISABLED
	var layer := CanvasLayer.new()
	layer.layer = 120
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var fade := layer.create_tween()
	fade.tween_property(shade,"color:a",1.0,.35)
	await fade.finished
	var error := tree.change_scene_to_file(destination)
	if error != OK:
		push_error("Could not travel to " + destination)
		if is_instance_valid(previous_scene): previous_scene.process_mode = Node.PROCESS_MODE_INHERIT
	await tree.process_frame
	var reveal := layer.create_tween()
	reveal.tween_property(shade,"color:a",0.0,.4)
	await reveal.finished
	tree.root.remove_meta("hospital_travel_busy")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if destination in ["res://grandpa_ending.tscn","res://intro.tscn","res://demo_ending.tscn"] else Input.MOUSE_MODE_CAPTURED
	layer.queue_free()
