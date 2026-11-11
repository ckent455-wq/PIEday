extends Node3D
## Optional licensed PYROLUX installation; original particles keep source-only clones runnable.
const PRESET := "res://addons/pyrolux_fx/presets/3d/smoke_chimney.tscn"
var effect: Node3D
var uses_downloaded_asset := false
var emitting := false:
	set(value):
		if emitting == value: return
		emitting = value
		if not is_instance_valid(effect): return
		if uses_downloaded_asset:
			if value: effect.play()
			else: effect.stop()
		else: effect.emitting = value

func setup(fallback: CPUParticles3D) -> void:
	if ResourceLoader.exists(PRESET):
		uses_downloaded_asset = true
		fallback.free()
		effect = load(PRESET).instantiate()
		effect.autoplay = false
		effect.preview_in_editor = false
		effect.height = 1.35
		effect.lifetime = 2.5
		effect.puffs = 22
		effect.source_radius = .09
		effect.puff_size = Vector2(.16,.65)
		effect.opacity = .55
		effect.color = Color(.4,.42,.44,.65)
		effect.fade_time = .3
		effect.wind_follow = 0
	else:
		effect = fallback
	add_child(effect)
