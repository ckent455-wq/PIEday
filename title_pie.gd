extends Node3D

const PIE := preload("res://assets/pies/pie_ps2_toasted.glb")
const FOOTSTEP := preload("res://assets/audio/title_pie_footstep.wav")
const FOOTSTEP_VOLUME_DB := -19.0
const SPEED := 1.25
const TRIP_CHANCE := 0.4
const TRIP_SPOTS := [Vector2(-1.35, -0.45), Vector2(0.05, 1.0), Vector2(1.65, 2.85)]
const FALL_END := 0.30
const SKID_END := 0.76
const STAND_START := 0.93
const STAND_END := 1.47
const TRIP_SECONDS := 2.0
const HOP_SECONDS := 0.85
const ROUTE := [
	Vector3(-3.0, -0.09, -2.49),
	Vector3(3.78, -0.09, -2.49),
	Vector3(4.05, -0.09, -2.83),
	Vector3(4.05, -0.09, -5.30),
	Vector3(3.70, -0.09, -5.65),
	Vector3(3.05, -0.09, -6.20),
	Vector3(3.05, -0.09, -7.40),
	Vector3(3.05, -0.09, -8.95),
]

var crust: Node3D
var legs: Array[Node3D] = []
var footsteps: Array[AudioStreamPlayer] = []
var waypoint := 1
var stride := 0.0
var wait_time := 1.4
var trip_point := INF
var trip_elapsed := -1.0
var trip_start_x := 0.0
var closing_encounter := false
var title_kitchen_door: MeshInstance3D
var title_door_closed_angle := 0.0
var game: Node3D
var kitchen_route: Array[Vector3] = []
var door_wait := 0.0
var hop_time := -1.0
var shelf_spot := Vector3.ZERO
var shelf_scale := 1.15
var settled := false

func start_closing() -> void:
	position = ROUTE[0]
	rotation = Vector3(0, PI / 2.0, 0)
	waypoint = 1
	stride = 0.0
	trip_elapsed = -1.0
	wait_time = 0.0
	door_wait = 0.0
	hop_time = -1.0
	settled = false
	crust.scale = Vector3.ONE * 1.95
	for leg in legs: leg.show()
	_plan_trip()
	show()

func closing_state() -> Dictionary:
	if not visible: return {}
	return {
		"transform": transform, "waypoint": waypoint, "stride": stride,
		"trip_point": trip_point, "trip_elapsed": trip_elapsed, "trip_start_x": trip_start_x,
		"door_wait": door_wait, "hop_time": hop_time, "shelf_spot": shelf_spot,
		"shelf_scale": shelf_scale, "settled": settled,
	}

func restore_closing(data: Dictionary) -> void:
	if data.is_empty():
		hide()
		return
	transform = data.transform
	waypoint = data.waypoint
	stride = data.stride
	trip_point = data.trip_point
	trip_elapsed = data.trip_elapsed
	trip_start_x = data.trip_start_x
	door_wait = data.get("door_wait", 0.0)
	hop_time = data.get("hop_time", -1.0)
	shelf_spot = data.get("shelf_spot", Vector3(1.8, 0.2245, -8.7))
	shelf_scale = data.get("shelf_scale", 1.15)
	settled = data.get("settled", false)
	crust.scale = Vector3.ONE * (shelf_scale if settled else 1.95)
	for leg in legs: leg.visible = not settled
	wait_time = 0.0
	if settled:
		hide()
		return
	show()

func _ready() -> void:
	var muffled_step := _muffled_footstep()
	crust = PIE.instantiate()
	add_child(crust)
	crust.scale = Vector3.ONE * 1.95
	var dough := StandardMaterial3D.new()
	dough.albedo_color = Color("c88742")
	dough.roughness = 0.85
	var shoe := StandardMaterial3D.new()
	shoe.albedo_color = Color("503321")
	shoe.roughness = 0.9
	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		add_child(hip)
		hip.position = Vector3(side * 0.135, 0.35, 0)
		legs.append(hip)
		var calf := CapsuleMesh.new()
		calf.radius = 0.046
		calf.height = 0.31
		calf.radial_segments = 8
		calf.rings = 3
		_add_part(hip, calf, dough, Vector3(0, -0.15, 0))
		var foot := BoxMesh.new()
		foot.size = Vector3(0.12, 0.065, 0.18)
		_add_part(hip, foot, shoe, Vector3(0, -0.29, 0.04))
		var plop := AudioStreamPlayer.new()
		plop.stream = muffled_step
		plop.volume_db = FOOTSTEP_VOLUME_DB
		plop.pitch_scale = 0.94 if side < 0.0 else 1.06
		hip.add_child(plop)
		footsteps.append(plop)
	position = ROUTE[0]
	rotation.y = PI / 2.0
	_plan_trip()
	hide()

func _muffled_footstep() -> AudioStreamWAV:
	var stream := FOOTSTEP.duplicate() as AudioStreamWAV
	if stream.format != AudioStreamWAV.FORMAT_16_BITS or stream.stereo: return stream
	var samples := stream.data
	var alpha := 1.0 - exp(-TAU * 2800.0 / stream.mix_rate)
	var filtered := 0.0
	for offset in range(0, samples.size(), 2):
		filtered = lerpf(filtered, samples.decode_s16(offset), alpha)
		samples.encode_s16(offset, roundi(filtered))
	stream.data = samples
	return stream

func _add_part(parent: Node3D, mesh: Mesh, material: Material, at: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	parent.add_child(part)
	part.position = at

func _process(delta: float) -> void:
	if closing_encounter and not visible: return
	if settled: return
	if hop_time >= 0.0:
		_animate_hop(delta)
		return
	if door_wait > 0.0:
		door_wait -= delta
		return
	if wait_time > 0.0:
		wait_time -= delta
		if wait_time > 0.0: return
		show()
	if trip_elapsed >= 0.0:
		_animate_trip(delta)
		return
	var route = kitchen_route if closing_encounter else ROUTE
	var target: Vector3 = route[waypoint]
	var direction := target - position
	if direction.length_squared() > 0.00001:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 10.0))
	position = position.move_toward(target, SPEED * delta)
	var entrance := smoothstep(-2.6, -0.5, position.x)
	var exit := 1.0 if closing_encounter else 1.0 - smoothstep(4.25, 5.65, -position.z)
	var gain := entrance * exit
	if closing_encounter:
		var listener := get_viewport().get_camera_3d()
		if listener != null:
			gain *= 1.0 - smoothstep(3.0, 11.0, global_position.distance_to(listener.global_position))
	for footstep in footsteps:
		footstep.volume_db = FOOTSTEP_VOLUME_DB + linear_to_db(maxf(gain, 0.0001))
	if waypoint == 1 and position.x >= trip_point:
		trip_point = INF
		trip_start_x = position.x
		trip_elapsed = 0.0
		return
	var previous_contact := floori(stride / PI)
	stride += delta * 12.5
	var contact := floori(stride / PI)
	if contact > previous_contact:
		footsteps[(contact + 1) % legs.size()].play()
	crust.position = Vector3(sin(stride) * 0.034, 0.34 + absf(sin(stride)) * 0.048, 0)
	crust.rotation.z = sin(stride) * 0.14
	for index in legs.size():
		var step := sin(stride + index * PI)
		legs[index].rotation.x = step * 0.52
		legs[index].position.y = 0.35 + maxf(step, 0.0) * 0.045
	if position != target: return
	waypoint += 1
	if closing_encounter:
		if waypoint == 7: _open_path_doors(["Door_01"])
		if waypoint == route.size():
			_open_path_doors(["Cooler_Door_Left", "Cooler_Door_Right"])
			_aim_hop()
		return
	if waypoint == route.size():
		_swing_title_door(false)
		hide()
		position = ROUTE[0]
		rotation.y = PI / 2.0
		waypoint = 1
		stride = 0.0
		wait_time = 4.0
		_plan_trip()
	elif waypoint == route.size() - 1:
		_swing_title_door(true)
		door_wait = 0.5

func _swing_title_door(opened: bool) -> void:
	if not is_instance_valid(title_kitchen_door): return
	var angle := title_door_closed_angle + (deg_to_rad(100.0) if opened else 0.0)
	create_tween().tween_property(title_kitchen_door, "rotation:y", angle, 0.45).set_trans(Tween.TRANS_SINE)

func _open_path_doors(names: Array[String]) -> void:
	door_wait = 0.5
	if game.coop != null and not game.coop.hosting: return
	for door in game.doors:
		if door.name in names and not door.get_meta("open", false):
			game._set_door_open(door, true)

func _aim_hop() -> void:
	var nearest := INF
	var closest: Node3D
	for slot in game.shift.all_pies:
		if not slot.visible: continue
		var distance: float = slot.global_position.distance_squared_to(global_position)
		if distance < nearest:
			nearest = distance
			closest = slot
	if closest == null:
		hide()
		return
	shelf_spot = get_parent_node_3d().to_local(closest.global_position)
	shelf_scale = closest.scale.x
	hop_time = 0.0

func _animate_hop(delta: float) -> void:
	if door_wait > 0.0:
		door_wait -= delta
		return
	hop_time += delta
	var progress := clampf(hop_time / HOP_SECONDS, 0.0, 1.0)
	position = kitchen_route.back().lerp(shelf_spot, progress)
	position.y += sin(progress * PI) * 0.34
	crust.position = Vector3.UP * lerpf(0.34, 0.0, progress)
	crust.rotation = Vector3(-0.28 * sin(progress * PI), 0, 0)
	crust.scale = Vector3.ONE * lerpf(1.95, shelf_scale, progress)
	for leg in legs:
		leg.scale = Vector3.ONE * maxf(0.02, 1.0 - progress)
		leg.rotation.x = -0.65 * sin(progress * PI)
	if progress >= 1.0: _settle_on_shelf()

func _settle_on_shelf() -> void:
	settled = true
	position = shelf_spot
	crust.position = Vector3.ZERO
	crust.rotation = Vector3.ZERO
	for leg in legs:
		leg.hide()
		leg.scale = Vector3.ONE
	hide()

func _plan_trip() -> void:
	trip_point = INF
	if randf() < TRIP_CHANCE:
		var span: Vector2 = TRIP_SPOTS.pick_random()
		trip_point = randf_range(span.x, span.y)

func _animate_trip(delta: float) -> void:
	trip_elapsed += delta
	var fall := smoothstep(0.0, FALL_END, trip_elapsed)
	var skid := clampf(inverse_lerp(FALL_END, SKID_END, trip_elapsed), 0.0, 1.0)
	var stand := smoothstep(STAND_START, STAND_END, trip_elapsed)
	var shake := clampf(inverse_lerp(STAND_END, TRIP_SECONDS, trip_elapsed), 0.0, 1.0)
	var shake_motion := sin(shake * TAU * 3.0) * (1.0 - shake)
	var tilt := fall * (1.0 - stand)
	position.x = trip_start_x + 0.12 * fall + 0.46 * (1.0 - pow(1.0 - skid, 2.0))
	crust.position = Vector3(0, lerpf(0.34, 0.15, tilt), 0.22 * tilt)
	crust.position.x = 0.035 * shake_motion
	crust.rotation = Vector3(1.35 * tilt, 0.12 * shake_motion, 0.20 * shake_motion)
	for index in legs.size():
		legs[index].rotation.x = tilt * (-1.15 + index * 0.48)
		legs[index].position.y = lerpf(0.35, 0.16, tilt)
	if trip_elapsed >= TRIP_SECONDS:
		trip_elapsed = -1.0
		stride = 0.0
