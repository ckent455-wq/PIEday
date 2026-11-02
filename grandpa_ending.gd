extends Control
const UI := preload("res://diner_ui.gd")
var earnings: RefCounted
var restart_dialog: ConfirmationDialog
var new_game_button: Button
var summary: Label
var saves: CanvasLayer

static func present(host: Node, wallet: RefCounted) -> void:
	preload("res://hospital_travel.gd").go(host,"res://grandpa_ending.tscn",wallet)

func _ready() -> void:
	if get_tree().root.has_meta("restore_manual_state"): get_tree().root.remove_meta("restore_manual_state")
	if get_tree().root.has_meta("pie_day_wallet"):
		earnings = get_tree().root.get_meta("pie_day_wallet")
		get_tree().root.remove_meta("pie_day_wallet")
	else: earnings = preload("res://earnings.gd").new()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = UI.theme()
	var background := TextureRect.new()
	background.texture = preload("res://assets/ui/death_grandpa_morgue.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,.12)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.anchor_left = .035
	center.anchor_right = .48
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 560
	panel.add_theme_stylebox_override("panel",UI.box(Color("101315df"),28))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",20)
	panel.add_child(column)
	var heading := UI.label("GRANDPA IS GONE.",24,Color("d2c7c0"))
	heading.add_theme_font_override("font",preload("res://retro_dialogue.gd").font())
	column.add_child(heading)
	var message := UI.label("The hospital called after closing.\nGrandpa passed away before you could get him the surgery.\n\nHe will never come back to work at the Diner.",21)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	summary = UI.label("Day %d  ·  Funds raised: $%d / $15,000\nGrandpa's health: 0%%\n\nThis campaign has ended.\nLoad an earlier save or start a new campaign." % [earnings.grandpa.death_day,earnings.cash],18,UI.MUTED)
	column.add_child(summary)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation",18)
	column.add_child(buttons)
	var load_button := Button.new()
	load_button.text = "Load Saved Game"
	load_button.custom_minimum_size.y = 48
	buttons.add_child(load_button)
	saves = preload("res://save_load_menu.gd").new()
	add_child(saves)
	saves.setup(self)
	load_button.pressed.connect(func(): saves.open(false))
	new_game_button = Button.new()
	new_game_button.text = "Start a New Campaign"
	new_game_button.custom_minimum_size = Vector2(300,48)
	buttons.add_child(new_game_button)
	var quit_button := Button.new()
	quit_button.text = "Quit to Desktop"
	quit_button.custom_minimum_size = Vector2(240,48)
	buttons.add_child(quit_button)
	restart_dialog = ConfirmationDialog.new()
	restart_dialog.title = "Start a New Campaign"
	restart_dialog.dialog_text = "Start over with $0 and Grandpa at full health?\nThis replaces the active campaign. Manual save slots are kept."
	restart_dialog.ok_button_text = "Start Over"
	add_child(restart_dialog)
	new_game_button.pressed.connect(func(): restart_dialog.popup_centered())
	restart_dialog.confirmed.connect(func(): start_new_campaign.call_deferred())
	quit_button.pressed.connect(func(): get_tree().quit())
	new_game_button.grab_focus()

func start_new_campaign() -> void:
	var fresh = preload("res://earnings.gd").new(false)
	fresh.save_enabled = earnings.save_enabled
	fresh._save()
	preload("res://hospital_travel.gd").go(self,"res://intro.tscn",fresh)
