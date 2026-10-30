extends Node3D

var shift: Node3D
var active := false
var encounter := ""
var elapsed := 0.0
var bell_at := 0.0
var flicker_at := 0.0
var figure_at := 0.0
var bell_done := false
var flicker_done := false
var figure_done := false
var figure_seen := false
var seen_seconds := 0.0
var away_seconds := 0.0
var flicker_time := -1.0
var lights: Array[Light3D] = []
var energies: Array[float] = []
var figure: Node3D
var rng := RandomNumberGenerator.new()
const ENCOUNTERS := ["bell", "flicker", "figure", "knocks", "cooler", "footsteps"]
var extra_at := 0.0
var extra_done := true
var effect_audio: AudioStreamPlayer3D
var bathroom_door: MeshInstance3D
var opened_cooler: MeshInstance3D
var steps_left := 0
var step_timer := 0.0
var step_position := Vector3.ZERO
var step_direction := Vector3.ZERO

func setup(host: Node3D) -> void:
	shift = host
	name = "ClosingEvents"
	rng.randomize()
	effect_audio = AudioStreamPlayer3D.new()
	effect_audio.name = "ClosingEncounterSound"
	effect_audio.unit_size = 3.0
	effect_audio.max_distance = 15.0
	effect_audio.volume_db = -5
	add_child(effect_audio)
	for door in shift.game.doors:
		if "Cubicles_Door" in door.name:
			bathroom_door = door
			break
	figure = preload("res://assets/customer/customer.glb").instantiate()
	add_child(figure)
	# A normal-sized person in the unlit rear corner, not a giant over the fence.
	figure.position = Vector3(-1.0, -0.094, -19.5)
	figure.scale = Vector3.ONE * 1.1
	figure.rotation.y = -0.65
	var shadow := StandardMaterial3D.new()
	shadow.albedo_color = Color(0.045, 0.05, 0.06)
	shadow.roughness = 1.0
	for mesh in figure.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = shadow
	var coat := MeshInstance3D.new()
	var coat_mesh := CylinderMesh.new()
	coat_mesh.top_radius = 0.23
	coat_mesh.bottom_radius = 0.29
	coat_mesh.height = 1.05
	coat_mesh.radial_segments = 8
	coat.mesh = coat_mesh
	coat.material_override = shadow
	coat.position.y = 0.95
	figure.add_child(coat)
	figure.visible = false

func begin() -> void:
	reset()
	active = true
	# One independent roll per closing, including the first: 30% quiet nights.
	encounter = "" if rng.randf() < 0.3 else ENCOUNTERS[rng.randi_range(0, ENCOUNTERS.size() - 1)]
	bell_done = encounter != "bell"
	flicker_done = encounter != "flicker"
	figure_done = encounter != "figure"
	extra_done = encounter not in ["knocks", "cooler", "footsteps"]
	extra_at = rng.randf_range(10, 35)
	bell_at = rng.randf_range(10, 38)
	flicker_at = rng.randf_range(10, 38)
	figure_at = rng.randf_range(5, 14)

func reset() -> void:
	_restore_lights()
	if is_instance_valid(effect_audio): effect_audio.stop()
	if is_instance_valid(opened_cooler): shift.game._set_door_open(opened_cooler, false)
	opened_cooler = null
	steps_left = 0
	extra_done = true
	active = false
	encounter = ""
	elapsed = 0
	flicker_time = -1
	figure_seen = false
	seen_seconds = 0
	away_seconds = 0
	if is_instance_valid(figure): figure.visible = false

func tick(delta: float) -> void:
	if shift.phase != "cleanup":
		if active: reset()
		return
	if not active: return
	elapsed += delta
	_tick_extra(delta)
	if not bell_done and elapsed >= bell_at:
		bell_done = true
		# Sound and button animation only: never submit an order or overwrite chores.
		shift.service_bell.play_ding()
	if not flicker_done and elapsed >= flicker_at:
		flicker_done = true
		flicker_time = 0
		var interior: Node3D = shift.game.get_node("NightInteriorLights")
		for light in interior.get_children():
			if light is Light3D:
				lights.append(light)
				energies.append(light.light_energy)
	if flicker_time >= 0:
		flicker_time += delta
		if flicker_time >= 1.25:
			_restore_lights()
			flicker_time = -1
		else:
			var dim := (flicker_time < 0.12 or (flicker_time > 0.28 and flicker_time < 0.46) or (flicker_time > 0.72 and flicker_time < 1.02))
			for i in range(lights.size()):
				lights[i].light_energy = energies[i] * (0.06 if dim else 1.0)
	if not figure_done and elapsed >= figure_at:
		# Wait for the player to actually enter the fenced yard.
		if preload("res://service_yard.gd").WALK_AREA.has_point(Vector2(shift.game.player.position.x, shift.game.player.position.z)):
			figure.visible = true
		if figure.visible:
			var watching := _figure_in_view()
			if watching:
				seen_seconds += delta
				away_seconds = 0
				if seen_seconds >= 0.3: figure_seen = true
				if seen_seconds >= 1.25:
					figure.visible = false
					figure_done = true
			elif figure_seen:
				away_seconds += delta
				if away_seconds >= 0.2:
					figure.visible = false
					figure_done = true

func _figure_in_view() -> bool:
	var camera: Camera3D = shift.game.camera
	var head := figure.global_position + Vector3(0, 1.7, 0)
	var direction := head - camera.global_position
	if direction.length() > 12 or -camera.global_basis.z.dot(direction.normalized()) < 0.78:
		return false
	# Walls and the solid fence must not count as seeing the figure.
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, head, 1, [shift.game.player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _restore_lights() -> void:
	for i in range(lights.size()):
		if is_instance_valid(lights[i]): lights[i].light_energy = energies[i]
	lights.clear()
	energies.clear()

func _sound(stream: AudioStream, at: Vector3) -> void:
	effect_audio.stream = stream
	effect_audio.global_position = at
	effect_audio.pitch_scale = rng.randf_range(0.94, 1.06)
	effect_audio.play()

func _tick_extra(delta: float) -> void:
	if steps_left > 0:
		step_timer -= delta
		if step_timer <= 0:
			_sound(preload("res://assets/audio/closing_footstep.wav"), step_position)
			step_position += step_direction
			steps_left -= 1
			step_timer = rng.randf_range(0.45, 0.65)
	if extra_done or elapsed < extra_at or not shift.customer_line.departing.is_empty(): return
	var player_position: Vector3 = shift.game.player.global_position
	if encounter == "knocks" and is_instance_valid(bathroom_door):
		var at: Vector3 = (bathroom_door.global_transform * bathroom_door.get_aabb()).get_center()
		if player_position.distance_to(at) < 6:
			extra_done = true
			_sound(preload("res://assets/audio/closing_knocks.wav"), at)
	elif encounter == "cooler":
		for door in shift.game.doors:
			if not door.has_meta("cooler") or door.get_meta("open", false): continue
			var at: Vector3 = (door.global_transform * door.get_aabb()).get_center()
			var facing: float = -shift.game.camera.global_basis.z.dot((at - shift.game.camera.global_position).normalized())
			if player_position.distance_to(at) < 7 and facing < 0.65:
				extra_done = true
				opened_cooler = door
				shift.game._set_door_open(door, true)
				_sound(preload("res://assets/audio/closing_creak.wav"), at)
				break
	elif encounter == "footsteps" and player_position.z > -14:
		var camera: Camera3D = shift.game.camera
		for at in [Vector3(-6, 0.1, -2), Vector3(4, 0.1, -2), Vector3(-1, 0.1, -11)]:
			var distance: float = player_position.distance_to(at)
			var facing := -camera.global_basis.z.dot((at - camera.global_position).normalized())
			if distance > 3 and distance < 11 and facing < 0.4:
				extra_done = true
				step_position = at
				step_direction = Vector3(0.55 if at.x < 0 else -0.55, 0, 0)
				steps_left = 6
				step_timer = 0
				break
