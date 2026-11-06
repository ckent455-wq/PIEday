extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var demo = preload("res://playable_demo.gd").session(self)
	var background := ColorRect.new()
	background.color = Color("101118")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 640
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	var title := Label.new()
	title.text = "ONE DAY CLOSER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	column.add_child(title)
	var body := Label.new()
	var cash: int = demo.wallet.cash if demo != null else 0
	var orders: int = demo.wallet.correct_orders if demo != null else 0
	body.text = "Today you raised $%d and served %d correct orders.\n\nGrandpa needs $15,000. This was only the first day.\nHis story continues in PIEday.\n\nThank you for playing the demo." % [cash, orders]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	column.add_child(body)
	for caption in ["Replay Demo", "Quit to Desktop"]:
		var button := Button.new()
		button.text = caption
		button.custom_minimum_size.y = 48
		column.add_child(button)
		if caption == "Replay Demo":
			button.pressed.connect(func():
				if demo != null: demo.restart.call_deferred()
			)
			button.grab_focus()
		else: button.pressed.connect(func(): get_tree().quit())
	add_child(preload("res://hospital_music.gd").new())
