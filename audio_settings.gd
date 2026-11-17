extends Node

const SAVE_PATH := "user://audio_settings.cfg"
const MUSIC := &"Music"
const EFFECTS := &"Sound Effects"
const SCARES := &"Scares"
const VOLUMES := "volume"

var settings := ConfigFile.new()

func _ready() -> void:
	settings.load(SAVE_PATH)
	for bus_name in [MUSIC, EFFECTS]:
		_apply_volume(bus_name, volume(bus_name))
	get_tree().node_added.connect(_route_effects)

func volume(bus_name: StringName) -> float:
	return clampf(float(settings.get_value(VOLUMES, bus_name, 100.0)), 0.0, 100.0)

func set_volume(bus_name: StringName, percent: float) -> void:
	percent = clampf(percent, 0.0, 100.0)
	settings.set_value(VOLUMES, bus_name, percent)
	_apply_volume(bus_name, percent)
	settings.save(SAVE_PATH)

func _apply_volume(bus_name: StringName, percent: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index, percent == 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(percent / 100.0, 0.0001)))

func _route_effects(node: Node) -> void:
	# Scene audio defaults to effects. Soundtrack players explicitly select Music.
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		if node.bus == &"Master":
			node.bus = EFFECTS
