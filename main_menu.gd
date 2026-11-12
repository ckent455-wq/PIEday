extends Control

const UI := preload("res://diner_ui.gd")

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
	var background := ColorRect.new()
	background.color = Color("111113")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := UI.card()
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 340
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var title := UI.label("PIEday", 42, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_add_button(column, "Solo Campaign", func(): _open("res://intro.tscn"))
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

func _add_button(column: VBoxContainer, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 48
	button.pressed.connect(action)
	column.add_child(button)

func _open(scene: String) -> void:
	get_tree().change_scene_to_file.call_deferred(scene)
