extends Control

const UI := preload("res://diner_ui.gd")
const SESSION := preload("res://coop_session.gd")
const UNIFORM := preload("res://coop_uniform.gd")
const PROFILE_PATH := "user://coop_character.cfg"
var status: Label
var address: LineEdit
var host_button: Button
var join_button: Button
var name_field: LineEdit
var model_choice: OptionButton
var face_choice: OptionButton
var apron_choice: OptionButton
var preview_stage: Node3D
var preview_actor: Node3D
var preview_name: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = UI.theme()
	var background := ColorRect.new()
	background.color = Color("111113")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := UI.card()
	center.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	panel.add_child(row)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 440
	column.add_theme_constant_override("separation", 10)
	row.add_child(column)
	column.add_child(UI.label("PIEday  /  ONLINE CO-OP", 28, UI.GOLD))
	column.add_child(UI.label("Two players · The full diner campaign", 18))
	column.add_child(UI.label("Build v%s · Both PCs must match" % ProjectSettings.get_setting("application/config/version"), 16, UI.GOLD))
	name_field = LineEdit.new()
	name_field.max_length = SESSION.NAME_LIMIT
	name_field.placeholder_text = "Partner"
	_field_row(column, "Name", name_field)
	model_choice = _choice(column, "Character", ["Character 1", "Character 2"])
	face_choice = _choice(column, "Face", [])
	apron_choice = _choice(column, "Apron", UNIFORM.APRONS)
	host_button = _button(column, "Host Shift", func(): _connect_game(true))
	address = LineEdit.new()
	address.placeholder_text = "Host IP address"
	address.custom_minimum_size.y = 42
	address.text_submitted.connect(func(_value): _connect_game(false))
	column.add_child(address)
	join_button = _button(column, "Join Shift", func(): _connect_game(false))
	status = UI.label("Direct connection over UDP port %d." % SESSION.PORT, 16, UI.MUTED)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if get_tree().root.has_meta("coop_status"):
		status.text = get_tree().root.get_meta("coop_status")
		get_tree().root.remove_meta("coop_status")
	column.add_child(status)
	_button(column, "Back to Main Menu", func(): _back.call_deferred())
	_build_preview(row)
	var profile := ConfigFile.new()
	profile.load(PROFILE_PATH)
	name_field.text = SESSION.clean_name(str(profile.get_value("appearance", "name", "")))
	model_choice.select(clampi(int(profile.get_value("appearance", "model", 0)), 0, model_choice.item_count - 1))
	_update_face_choices(int(profile.get_value("appearance", "face", 0)))
	apron_choice.select(clampi(int(profile.get_value("appearance", "apron", 0)), 0, apron_choice.item_count - 1))
	_refresh_character()
	_update_name()
	name_field.text_changed.connect(func(_value: String):
		_update_name()
		_write_profile()
	)
	model_choice.item_selected.connect(func(index: int):
		_update_face_choices(0)
		_save_character(index)
	)
	face_choice.item_selected.connect(_save_character)
	apron_choice.item_selected.connect(_save_character)

func _choice(parent: Control, caption: String, choices: Array) -> OptionButton:
	var field := OptionButton.new()
	for choice in choices: field.add_item(choice)
	_field_row(parent, caption, field)
	return field

func _field_row(parent: Control, caption: String, field: Control) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := UI.label(caption, 16)
	label.custom_minimum_size.x = 100
	row.add_child(label)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size.y = 38
	row.add_child(field)

func _build_preview(parent: Control) -> void:
	var column := VBoxContainer.new()
	parent.add_child(column)
	var title := UI.label("YOUR DINER UNIFORM", 17, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var frame := SubViewportContainer.new()
	frame.custom_minimum_size = Vector2(270, 320)
	frame.stretch = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(frame)
	preview_name = UI.label("", 18)
	preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(preview_name)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	frame.add_child(viewport)
	preview_stage = Node3D.new()
	viewport.add_child(preview_stage)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("272831")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("eae1d5")
	world.environment.ambient_light_energy = 0.72
	preview_stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-28, -26, 0)
	light.light_energy = 1.15
	preview_stage.add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.06, 3.5)
	camera.fov = 39
	preview_stage.add_child(camera)
	camera.current = true

func _update_face_choices(selected: int) -> void:
	face_choice.clear()
	for index in UNIFORM.FACES[model_choice.selected].size():
		face_choice.add_item("Face %d" % (index + 1))
	face_choice.select(clampi(selected, 0, face_choice.item_count - 1))

func _refresh_character() -> void:
	if is_instance_valid(preview_actor):
		preview_actor.free()
	preview_actor = Node3D.new()
	preview_stage.add_child(preview_actor)
	UNIFORM.add_character(preview_actor, model_choice.selected, apron_choice.selected, face_choice.selected)

func _save_character(_index: int) -> void:
	_write_profile()
	_refresh_character()

func _update_name() -> void:
	var cleaned := SESSION.clean_name(name_field.text)
	preview_name.text = SESSION.DEFAULT_NAME if cleaned.is_empty() else cleaned

func _write_profile() -> void:
	var profile := ConfigFile.new()
	profile.set_value("appearance", "name", SESSION.clean_name(name_field.text))
	profile.set_value("appearance", "model", model_choice.selected)
	profile.set_value("appearance", "face", face_choice.selected)
	profile.set_value("appearance", "apron", apron_choice.selected)
	profile.save(PROFILE_PATH)

func _button(parent: Control, caption: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 44
	parent.add_child(button)
	button.pressed.connect(pressed)
	return button

func _connect_game(hosting: bool) -> void:
	if SESSION.active(self) != null: return
	var target := address.text.strip_edges()
	if not hosting and target.is_empty():
		status.text = "Enter the host's IP address."
		return
	var session := SESSION.new()
	session.name = "CoopSession"
	_write_profile()
	session.character_name = SESSION.clean_name(name_field.text)
	session.character_model = model_choice.selected
	session.character_face = face_choice.selected
	session.character_apron = apron_choice.selected
	get_tree().root.add_child(session)
	var error := session.connect_game(hosting, target)
	if error != OK:
		session.queue_free()
		status.text = "Could not %s: %s" % ["host" if hosting else "join", error_string(error)]
		return
	host_button.disabled = true
	join_button.disabled = true
	model_choice.disabled = true
	face_choice.disabled = true
	apron_choice.disabled = true
	name_field.editable = false
	if hosting:
		var addresses := PackedStringArray()
		for ip in IP.get_local_addresses():
			if ip.is_valid_ip_address() and ":" not in ip and not ip.begins_with("127.") and not ip.begins_with("169.254."):
				addresses.append(ip)
		status.text = "Waiting for your partner on UDP %d.\nLocal addresses: %s" % [SESSION.PORT, ", ".join(addresses)]
	else:
		status.text = "Connecting to %s…" % target

func _back() -> void:
	var session = SESSION.active(self)
	if session != null: session.shutdown()
	get_tree().change_scene_to_file("res://main_menu.tscn")
