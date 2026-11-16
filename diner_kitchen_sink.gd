extends Node3D

var running := false
var water := Node3D.new()
var audio := AudioStreamPlayer3D.new()
var splash := CPUParticles3D.new()

func setup(nozzle: Vector3, impact: Vector3, target_center: Vector3, target_size: Vector3) -> void:
	var target := StaticBody3D.new()
	target.collision_layer = 4
	target.collision_mask = 0
	tag_target(target)
	add_child(target)
	target.position = target_center
	var hitbox := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = target_size
	hitbox.shape = box
	target.add_child(hitbox)

	add_child(water)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.72, 0.9, 0.98, 0.62)
	var stream := MeshInstance3D.new()
	var column := CylinderMesh.new()
	column.height = nozzle.distance_to(impact)
	column.top_radius = 0.012
	column.bottom_radius = 0.008
	column.radial_segments = 8
	column.material = material
	stream.mesh = column
	water.add_child(stream)
	stream.position = (nozzle + impact) * 0.5

	var drops := SphereMesh.new()
	drops.radius = 0.008
	drops.height = 0.016
	drops.radial_segments = 8
	drops.rings = 4
	drops.material = material
	splash.mesh = drops
	splash.amount = 20
	splash.lifetime = 0.24
	splash.direction = Vector3.UP
	splash.spread = 67.0
	splash.initial_velocity_min = 0.65
	splash.initial_velocity_max = 1.45
	splash.gravity = Vector3.DOWN * 9.8
	splash.emitting = false
	water.add_child(splash)
	splash.position = impact
	water.hide()

	var loop: AudioStreamWAV = preload("res://assets/audio/kitchen_faucet.wav").duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	audio.stream = loop
	audio.volume_db = -8.0
	audio.unit_size = 1.8
	audio.max_distance = 9.0
	add_child(audio)
	audio.position = nozzle

func tag_target(node: Node) -> void:
	node.set_meta("action", "sink")
	node.set_meta("sink", self)

func add_drain(at: Vector3) -> void:
	var drain := MeshInstance3D.new()
	drain.name = "BasketDrain"
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("aeb9bd")
	steel.metallic = 0.55
	steel.roughness = 0.39
	var rim := TorusMesh.new()
	rim.inner_radius = 0.043
	rim.outer_radius = 0.061
	rim.rings = 20
	rim.ring_segments = 8
	rim.material = steel
	drain.mesh = rim
	add_child(drain)
	drain.position = at

	var basket := MeshInstance3D.new()
	var plate := CylinderMesh.new()
	plate.top_radius = 0.048
	plate.bottom_radius = 0.048
	plate.height = 0.005
	plate.radial_segments = 20
	plate.material = steel
	basket.mesh = plate
	drain.add_child(basket)
	basket.position.y = -0.004

	var recess := StandardMaterial3D.new()
	recess.albedo_color = Color("182026")
	var hole := PlaneMesh.new()
	hole.size = Vector2(0.011, 0.017)
	hole.material = recess
	for index in 8:
		var angle := TAU * index / 8.0
		var slot := MeshInstance3D.new()
		slot.mesh = hole
		drain.add_child(slot)
		slot.position = Vector3(sin(angle) * 0.029, -0.001, cos(angle) * 0.029)
		slot.rotation.y = angle


func prompt() -> String:
	return "[E] Turn off sink" if running else "[E] Turn on sink"

func set_running(enabled: bool) -> void:
	if running == enabled:
		return
	running = enabled
	water.visible = enabled
	splash.emitting = enabled
	if enabled:
		audio.play()
	else:
		audio.stop()
