extends AcceptDialog

var controls: VBoxContainer

func _ready() -> void:
	title = "Audio Settings"
	ok_button_text = "Done"
	controls = preload("res://audio_volume_controls.gd").new()
	add_child(controls)

func show_settings() -> void:
	popup_centered(Vector2i(400, 155))
	controls.music_slider.grab_focus()
