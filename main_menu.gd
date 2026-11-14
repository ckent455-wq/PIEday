extends Control

const UI := preload("res://diner_ui.gd")
const EARNINGS := preload("res://earnings.gd")
const TITLE_FONT := preload("res://assets/ui/PressStart2P-Regular.ttf")

func _ready() -> void:
	if preload("res://game_updater.gd").redirect_to_installed(get_tree()): return
	var root := get_tree().root
	var first_open := not root.has_meta("main_menu_opened")
	root.set_meta("main_menu_opened", true)
	if OS.has_feature("playable_demo") or (first_open and not OS.get_cmdline_user_args().is_empty()):
		get_tree().change_scene_to_file.call_deferred("res://intro.tscn")
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = UI.theme()
	_build_backdrop()
	add_child(preload("res://diner_music.gd").new())
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 340
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)
	var title := UI.label("PIEday", 44, UI.GOLD)
	title.add_theme_font_override("font", TITLE_FONT)
	title.custom_minimum_size.y = 82
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(title)
	var has_autosave := FileAccess.file_exists(EARNINGS.SAVE_PATH)
	var resume := _add_button(column, "Continue", _continue_campaign)
	resume.disabled = not has_autosave
	var confirm := ConfirmationDialog.new()
	confirm.title = "Start a New Game?"
	confirm.dialog_text = "Start over with $0 and Grandpa at full health? Your manual save slots are kept."
	confirm.ok_button_text = "New Game"
	confirm.confirmed.connect(_new_game)
	add_child(confirm)
	var new_game := _add_button(column, "New Game", func():
		if has_autosave: confirm.popup_centered()
		else: _new_game()
	)
	var saves := preload("res://save_load_menu.gd").new()
	saves.name = "SaveLoadMenu"
	add_child(saves)
	saves.setup(self)
	_add_button(column, "Load Game", func(): saves.open(false))
	_add_button(column, "Online Co-op", func(): _open("res://coop_lobby.tscn"))
	_add_button(column, "Quit", func(): get_tree().quit())
	var version := UI.label("v" + str(ProjectSettings.get_setting("application/config/version")), 14, UI.MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(version)
	if preload("res://game_updater.gd").enabled():
		var updater := preload("res://game_updater.gd").new()
		add_child(updater)
		updater.setup(column)
	(resume if has_autosave else new_game).grab_focus()

func _build_backdrop() -> void:
	var diner := preload("res://diner_layout.tscn").instantiate()
	add_child(diner)
	for mesh in diner.find_children("*", "MeshInstance3D", true, false):
		if "Collision" in mesh.name: mesh.hide()
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("222737")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("a9b1cb")
	world.environment.ambient_light_energy = 0.65
	add_child(world)
	var warm_light := OmniLight3D.new()
	warm_light.light_color = Color("ffb577")
	warm_light.light_energy = 2.2
	warm_light.omni_range = 10.0
	add_child(warm_light)
	warm_light.position = Vector3(1.6, 2.65, -3.0)
	var pie := preload("res://title_pie.gd").new()
	pie.title_kitchen_door = diner.get_node("Door_01")
	pie.title_door_closed_angle = pie.title_kitchen_door.rotation.y
	add_child(pie)
	var camera := Camera3D.new()
	camera.fov = 69
	add_child(camera)
	camera.position = Vector3(-3.2, 1.85, 1.0)
	camera.look_at(Vector3(-0.7, 1.30, -3.55))
	camera.make_current()
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.39, 0.70, 1.0])
	colors.colors = PackedColorArray([Color(0.05, 0.04, 0.05, 0.98), Color(0.05, 0.04, 0.05, 0.92), Color(0.05, 0.04, 0.05, 0.24), Color(0.05, 0.04, 0.05, 0.12)])
	var gradient := GradientTexture2D.new()
	gradient.gradient = colors
	gradient.fill_to = Vector2.RIGHT
	var backdrop := TextureRect.new()
	backdrop.texture = gradient
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _add_button(column: VBoxContainer, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 48
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(action)
	column.add_child(button)
	return button

func _new_game() -> void:
	var wallet := EARNINGS.new(false)
	wallet.save_enabled = true
	wallet._save()
	get_tree().root.set_meta("pie_day_wallet", wallet)
	_open("res://intro.tscn")

func _continue_campaign() -> void:
	var wallet := EARNINGS.new()
	get_tree().root.set_meta("pie_day_wallet", wallet)
	_open("res://hospital_room.tscn" if wallet.grandpa.visit_in_progress else "res://main.tscn")

func _open(scene: String) -> void:
	get_tree().change_scene_to_file.call_deferred(scene)
