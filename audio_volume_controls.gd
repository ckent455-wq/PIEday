extends VBoxContainer

const UI := preload("res://diner_ui.gd")
var music_slider: HSlider

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	music_slider = _volume_slider(AudioSettings.MUSIC)
	_volume_slider(AudioSettings.EFFECTS)

func _volume_slider(bus_name: StringName) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var label := UI.label(bus_name, 16)
	label.custom_minimum_size.x = 112
	row.add_child(label)
	var slider := HSlider.new()
	slider.accessibility_name = bus_name
	slider.custom_minimum_size = Vector2(110, 28)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = AudioSettings.volume(bus_name)
	row.add_child(slider)
	var value := UI.label("%d%%" % int(slider.value), 16, UI.MUTED)
	value.custom_minimum_size.x = 48
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	slider.value_changed.connect(func(percent: float):
		value.text = "%d%%" % int(percent)
		AudioSettings.set_volume(bus_name, percent)
	)
	return slider
