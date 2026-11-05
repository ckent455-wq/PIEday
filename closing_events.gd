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
var trash_disposed := false
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
var trash_audio: AudioStreamPlayer3D
var monster_audio: AudioStreamPlayer3D
var effect_audio: AudioStreamPlayer3D
var bathroom_door: MeshInstance3D
var opened_cooler: MeshInstance3D
var steps_left := 0
var step_timer := 0.0
var step_position := Vector3.ZERO
var step_direction := Vector3.ZERO
var figure_radius := 0.45
var figure_height := 2.0
var dissolve_materials: Array[ShaderMaterial] = []
var dissolve_elapsed := -1.0
var shadow_wisps: CPUParticles3D
const DISSOLVE_SECONDS := 0.65
const FIGURE_AWAY_SECONDS := 0.2

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
	trash_audio = AudioStreamPlayer3D.new()
	trash_audio.name = "TrashBagImpact"
	trash_audio.stream = preload("res://assets/audio/trash_bag_drop.wav")
	trash_audio.unit_size = 4.0
	trash_audio.max_distance = 14.0
	trash_audio.volume_db = -7.0
	add_child(trash_audio)
	monster_audio = AudioStreamPlayer3D.new()
	monster_audio.name = "ShadowDissipationSound"
	monster_audio.stream = preload("res://assets/audio/shadow_dissipate.wav")
	monster_audio.unit_size = 5.0
	monster_audio.max_distance = 14.0
	monster_audio.volume_db = -6.0
	add_child(monster_audio)
	for door in shift.game.doors:
		if "Cubicles_Door" in door.name:
			bathroom_door = door
			break
	figure = Node3D.new()
	figure.name = "YardStalker"
	add_child(figure)
	var visual: Node3D = preload("res://assets/monster/yard_stalker.glb").instantiate()
	visual.name = "MonsterModel"
	figure.add_child(visual)
	_soften_monster(visual)
	_make_shadow_wisps()
	# Keep the creature somewhat taller than the player.
	visual.scale = Vector3.ONE * 1.35
	figure_radius = 0.70
	figure_height = 2.5
	for player in visual.find_children("*", "AnimationPlayer", true, false):
		for animation in player.get_animation_list():
			if "idle" in animation.to_lower():
				player.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
				player.speed_scale = 0.65
				player.play(animation)
				break
	_place_figure()
	figure.visible = false

func _make_shadow_wisps() -> void:
	shadow_wisps = CPUParticles3D.new()
	shadow_wisps.name = "DissipatingShadow"
	shadow_wisps.emitting = false
	shadow_wisps.one_shot = true
	shadow_wisps.amount = 42
	shadow_wisps.lifetime = 0.85
	shadow_wisps.explosiveness = 0.85
	shadow_wisps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	shadow_wisps.emission_box_extents = Vector3(0.26, 0.95, 0.12)
	shadow_wisps.direction = Vector3.UP
	shadow_wisps.spread = 65.0
	shadow_wisps.gravity = Vector3(0.08, 0.5, 0)
	shadow_wisps.initial_velocity_min = 0.15
	shadow_wisps.initial_velocity_max = 0.45
	shadow_wisps.scale_amount_min = 0.6
	shadow_wisps.scale_amount_max = 1.5
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(0.04,0.045,0.055,0.0), Color(0.04,0.045,0.055,0.4), Color(0.04,0.045,0.055,0.0)])
	fade.offsets = PackedFloat32Array([0.0,0.12,1.0])
	shadow_wisps.color_ramp = fade
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5,.5)
	texture.fill_to = Vector2(1,.5)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var quad := QuadMesh.new()
	quad.size = Vector2(.48,.65)
	quad.material = material
	shadow_wisps.mesh = quad
	add_child(shadow_wisps)

func _soften_monster(visual: Node3D) -> void:
	# Low-resolution, bilinear-filtered skin keeps facial detail indistinct.
	var image := preload("res://assets/monster/yard_stalker_zombie_color.png").get_image()
	if image.is_compressed(): image.decompress()
	image.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	image.resize(128, 128, Image.INTERPOLATE_BILINEAR)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.get_active_material(surface)
			if original is StandardMaterial3D:
				var material := ShaderMaterial.new()
				material.shader = preload("res://assets/monster/dissipate.gdshader")
				material.set_shader_parameter("albedo_texture", texture)
				material.set_shader_parameter("base_color", Color(0.52, 0.55, 0.60))
				dissolve_materials.append(material)
				mesh.set_surface_override_material(surface, material)

func _dumpster_bounds() -> AABB:
	var dumpster: Node3D = shift.game.find_child("OutdoorDumpster", true, false)
	var bounds := AABB()
	var first := true
	for mesh in dumpster.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	# Also respect the smooth collision hull that closes rear/side gaps.
	var hull := dumpster.get_node_or_null("SmoothDumpsterCollision")
	if is_instance_valid(hull):
		for collider in hull.get_children():
			if collider is CollisionShape3D and collider.shape is BoxShape3D:
				bounds = bounds.merge(collider.global_transform * AABB(-collider.shape.size*0.5,collider.shape.size))
	return bounds

func _figure_bounds(at: Vector3) -> AABB:
	return AABB(at + Vector3(-figure_radius,0,-figure_radius),Vector3(figure_radius*2,figure_height,figure_radius*2))

func _place_figure() -> bool:
	var opening: AABB = preload("res://service_yard.gd").OPENING
	figure.global_position = Vector3(opening.get_center().x, -0.09, opening.get_center().z - 0.20)
	return true

func on_trash_disposed() -> void:
	trash_audio.global_position = shift.game.find_child("OutdoorDumpster", true, false).global_position + Vector3(0, 0.8, 0)
	trash_audio.pitch_scale = rng.randf_range(0.96, 1.04)
	trash_audio.play()
	if active and encounter == "figure" and not figure_done:
		trash_disposed = true

func awaiting_doorway_scare() -> bool:
	return active and encounter == "figure" and trash_disposed and not figure_done

func begin() -> void:
	reset()
	_place_figure()
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
	if is_instance_valid(monster_audio): monster_audio.stop()
	if is_instance_valid(opened_cooler): shift.game._set_door_open(opened_cooler, false)
	opened_cooler = null
	steps_left = 0
	extra_done = true
	active = false
	encounter = ""
	elapsed = 0
	flicker_time = -1
	figure_seen = false
	trash_disposed = false
	dissolve_elapsed = -1.0
	if is_instance_valid(shadow_wisps):
		shadow_wisps.emitting = false
		shadow_wisps.visible = false
	_set_dissolve(0.0)
	seen_seconds = 0
	away_seconds = 0
	if is_instance_valid(figure): figure.visible = false

func _set_dissolve(amount: float) -> void:
	for material in dissolve_materials: material.set_shader_parameter("dissolve", amount)

func _dismiss_figure() -> void:
	if dissolve_elapsed < 0.0:
		dissolve_elapsed = 0.0
		monster_audio.global_position = figure.global_position + Vector3(0, 1.5, 0)
		monster_audio.play()
		shadow_wisps.global_position = figure.global_position + Vector3(0, 1.25, 0)
		shadow_wisps.visible = true
		shadow_wisps.restart()
		shadow_wisps.emitting = true

func tick(delta: float) -> void:
	if shift.phase != "cleanup" and not (shift.phase == "closed" and (awaiting_doorway_scare() or monster_audio.playing)):
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
	if dissolve_elapsed >= 0.0 and not figure_done:
		dissolve_elapsed += delta
		_set_dissolve(clampf(dissolve_elapsed / DISSOLVE_SECONDS, 0.0, 1.0))
		if dissolve_elapsed >= DISSOLVE_SECONDS:
			figure.visible = false
			figure_done = true
		return
	if not figure_done and trash_disposed:
		# Appear behind the player after disposal, never pop into their current view.
		if not figure.visible and preload("res://service_yard.gd").WALK_AREA.has_point(Vector2(shift.game.player.position.x, shift.game.player.position.z)) and not _figure_in_view():
			figure.visible = _place_figure()
		if figure.visible:
			var target: Vector3 = shift.game.player.global_position
			target.y = figure.global_position.y
			if target.distance_to(figure.global_position) > 0.1: figure.look_at(target,Vector3.UP,true)
			if shift.game.player.global_position.distance_to(figure.global_position) < 1.2:
				_dismiss_figure()
				return
			var watching := _figure_in_view()
			if watching:
				seen_seconds += delta
				away_seconds = 0
				figure_seen = true
				_dismiss_figure()
			elif figure_seen:
				away_seconds += delta
				if away_seconds >= FIGURE_AWAY_SECONDS: _dismiss_figure()

func _figure_in_view() -> bool:
	var camera: Camera3D = shift.game.camera
	var head := figure.global_position + Vector3(0, figure_height * 0.88, 0)
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

func _cooler_in_view(door: MeshInstance3D, at: Vector3) -> bool:
	var camera: Camera3D = shift.game.camera
	var direction := at - camera.global_position
	if -camera.global_basis.z.dot(direction.normalized()) < 0.85: return false
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, at, 1, [shift.game.player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or door.is_ancestor_of(hit.collider)

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
			if player_position.distance_to(at) < 7 and _cooler_in_view(door, at):
				extra_done = true
				opened_cooler = door
				shift.game._set_door_open(door, true)
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
