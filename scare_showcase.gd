extends CanvasLayer

const SCARES := ["bell", "flicker", "figure", "knocks", "cooler", "footsteps"]
const TITLES := ["Bell rings by itself", "Lights flicker (currently silent)", "Monster in the back doorway", "Bathroom stall knocking", "Cooler opens while you watch", "Footsteps in the empty diner"]
var game: Node3D
var current := 0
var heading: Label

func setup(host: Node3D) -> void:
	game = host
	name = "ScareShowcase"
	layer = 75
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 260
	panel.offset_right = -260
	panel.offset_top = 148
	panel.offset_bottom = 212
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", preload("res://diner_ui.gd").box(Color("14161aee"), 12))
	add_child(panel)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 16)
	panel.add_child(heading)
	select_scare.call_deferred(0)

func _input(event: InputEvent) -> void:
	if get_tree().paused or not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode >= KEY_1 and event.keycode <= KEY_6:
		get_viewport().set_input_as_handled()
		select_scare(event.keycode - KEY_1)
	elif event.keycode == KEY_R:
		get_viewport().set_input_as_handled()
		select_scare(current)
	elif event.keycode == KEY_N:
		get_viewport().set_input_as_handled()
		select_scare((current + 1) % SCARES.size())

func _place(at: Vector3, look: Vector3) -> void:
	game.spawn_point = at
	game.player.position = at
	game.player.velocity = Vector3.ZERO
	game.face_point(look)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func select_scare(index: int) -> void:
	current = index
	var shift = game.shift
	shift.earnings.save_enabled = false
	shift.begin_cleanup()
	shift.service_bell.sound.stop()
	var events = shift.closing_events
	events.trash_audio.stop()
	events.encounter = SCARES[index]
	events.bell_done = index != 0
	events.flicker_done = index != 1
	events.figure_done = index != 2
	events.extra_done = index < 3
	events.bell_at = 1.5
	events.flicker_at = 1.5
	events.extra_at = 1.5
	var hint := ""
	match index:
		0:
			_place(Vector3(-2.35, 0.03, -3.1), shift.service_bell.global_position)
			hint = "Watch and listen to the counter bell. It rings in 1.5 seconds."
		1:
			_place(Vector3(0, 0.03, -2), Vector3(0, 2.1, -8))
			hint = "Watch the interior lights. The flicker starts in 1.5 seconds; it currently has no sound."
		2:
			shift.tasks.tables = true
			shift._set_carrying_trash(true)
			shift.task_nodes.trash.visible = false
			shift.task_nodes.trash.collision_layer = 0
			game._set_door_open(game.find_child("BackDoor", true, false), true)
			_place(Vector3(0.7, 0.03, -18), game.find_child("OutdoorDumpster", true, false).global_position + Vector3(0, 0.65, 0))
			hint = "E / click: dump the trash. Turn toward the diner to see and hear the monster dissolve."
		3:
			var door: MeshInstance3D = events.bathroom_door
			var at: Vector3 = (door.global_transform * door.get_aabb()).get_center()
			_place(Vector3(at.x + 1, 0.03, at.z + 1), at)
			hint = "Listen for three knocks from the stall door in 1.5 seconds."
		4:
			var cooler: MeshInstance3D
			for door in game.doors:
				if door.has_meta("cooler"):
					game._set_door_open(door, false)
					if not is_instance_valid(cooler): cooler = door
			var at: Vector3 = (cooler.global_transform * cooler.get_aabb()).get_center()
			var stand := Vector3(at.x, 0.03, at.z - 2.5)
			_place(stand, at)
			hint = "Watch the cooler ahead: its door opens by itself in 1.5 seconds."
		5:
			_place(Vector3(-2.4, 0.03, -5.8), Vector3(-2.4, 1.5, -11))
			hint = "Listen behind you: six footsteps move through the empty dining room. No visible walker."
	heading.text = "SCARE TEST  %d/6 — %s\n1 Bell · 2 Lights · 3 Doorway · 4 Knocks · 5 Cooler · 6 Footsteps\nR Replay     N Next" % [index + 1, TITLES[index]]
	shift._message(hint)
	shift.notice_time = 0
