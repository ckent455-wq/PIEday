extends CanvasLayer

var overlay: Control
var resume_button: Button
var restart_button: Button
var quit_button: Button
var restart_dialog: ConfirmationDialog
var is_open := false
var saves: CanvasLayer
const UI := preload("res://diner_ui.gd")

func _ready() -> void:
	name = "PauseMenu"
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = Control.new()
	overlay.theme = UI.theme()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.012, 0.02, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	var style := UI.box(UI.INK, 30)
	style.border_color = Color("4a4439")
	style.set_border_width_all(1)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	var title := Label.new()
	title.text = "PIEday"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", UI.GOLD)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "PAUSED"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", UI.MUTED)
	column.add_child(subtitle)
	resume_button = _button(column, "Resume")
	var save_button := _button(column,"Save Game")
	var load_button := _button(column,"Load Game")
	restart_button = _button(column, "Restart Day")
	quit_button = _button(column, "Quit to Desktop")
	# Resume after the button event finishes so its click cannot pick up an item.
	resume_button.pressed.connect(func(): resume_game.call_deferred())
	restart_button.pressed.connect(func(): restart_dialog.popup_centered())
	quit_button.pressed.connect(func(): get_tree().quit())
	var hint := Label.new()
	hint.text = "Esc to resume"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", UI.MUTED)
	column.add_child(hint)
	restart_dialog = ConfirmationDialog.new()
	restart_dialog.theme = UI.theme()
	restart_dialog.title = "Restart Day"
	restart_dialog.dialog_text = "Restart from the beginning of the day?\nCash already earned is kept."
	restart_dialog.ok_button_text = "Restart"
	restart_dialog.confirmed.connect(func(): restart_day.call_deferred())
	add_child(restart_dialog)
	saves = preload("res://save_load_menu.gd").new()
	add_child(saves)
	saves.setup(get_parent(),self)
	save_button.pressed.connect(func(): saves.open(true))
	load_button.pressed.connect(func(): saves.open(false))
	overlay.hide()

func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 22)
	parent.add_child(button)
	return button

func _input(event: InputEvent) -> void:
	if is_instance_valid(saves) and saves.is_open: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		# The intro's fade also pauses the scene; do not interrupt that transition.
		if get_tree().paused and not is_open: return
		get_viewport().set_input_as_handled()
		if restart_dialog.visible:
			restart_dialog.hide()
			resume_button.grab_focus()
		elif is_open:
			resume_game()
		else:
			pause_game()

func pause_game() -> void:
	if is_open or get_tree().paused: return
	is_open = true
	overlay.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()

func resume_game() -> void:
	if not is_open: return
	restart_dialog.hide()
	is_open = false
	overlay.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func restart_day() -> void:
	resume_game()
	get_tree().reload_current_scene()

func _exit_tree() -> void:
	if is_open: get_tree().paused = false
