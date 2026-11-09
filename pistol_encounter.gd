extends Node3D

const MODEL = preload("res://assets/pistol/pistol.glb")
var shift: Node3D
var pickup: StaticBody3D
var drawer: StaticBody3D
var drawer_open := false
var drawer_motion: Tween
var shot: AudioStreamPlayer

func setup(host: Node3D) -> void:
	shift = host
	name = "KitchenPistol"
	position = Vector3(shift.service_bell.position.x, 0.93, -4.77)
	_build_drawer()
	shot = AudioStreamPlayer.new()
	add_child(shot)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(11025*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 451
	for i in 11025:
		var t := float(i)/22050
		var crack := rng.randf_range(-1,1)*exp(-t*85)
		var thump := sin(t*TAU*(125-90*t))*exp(-t*26)
		var echo: float = rng.randf_range(-1,1)*exp(-maxf(t-.045,0)*18)*(.22 if t>.045 else 0)
		var value := clampf(crack*.85+thump*.6+echo,-1,1)
		samples.encode_s16(i*2,int(value*30000))
	stream.data = samples
	shot.stream = stream
	shot.volume_db = -5

func _build_drawer() -> void:
	drawer = StaticBody3D.new()
	drawer.name = "PistolDrawer"
	drawer.collision_layer = 4
	drawer.collision_mask = 0
	drawer.set_meta("action", "pistol_drawer")
	add_child(drawer)
	var steel := Color(0.41, 0.43, 0.44)
	var liner := Color(0.13, 0.14, 0.15)
	shift._box(self, Vector3.ZERO, Vector3(0.70, 0.23, 0.025), liner)
	shift._box(drawer, Vector3(0, 0, -0.03), Vector3(0.65, 0.19, 0.03), steel)
	shift._box(drawer, Vector3(0, -0.087, 0.23), Vector3(0.62, 0.025, 0.50), liner)
	for side in [-1, 1]:
		shift._box(drawer, Vector3(side * 0.30, -0.034, 0.23), Vector3(0.025, 0.095, 0.49), steel)
	shift._box(drawer, Vector3(0, -0.034, 0.46), Vector3(0.60, 0.095, 0.025), steel)
	_build_drawer_pull()
	var collision := CollisionShape3D.new()
	var face := BoxShape3D.new()
	face.size = Vector3(0.65, 0.19, 0.13)
	collision.shape = face
	collision.position.z = -0.085
	drawer.add_child(collision)
	pickup = preload("res://kitchen_pistol.tscn").instantiate()
	drawer.add_child(pickup)
	pickup.position = Vector3(0, -0.067, 0.21)
	refresh_pickup(false)

func _build_drawer_pull() -> void:
	var chrome := StandardMaterial3D.new()
	chrome.albedo_color = Color(0.82, 0.84, 0.86)
	chrome.metallic = 0.25
	chrome.roughness = 0.34
	var grip := CapsuleMesh.new()
	grip.radius = 0.019
	grip.height = 0.30
	grip.radial_segments = 12
	grip.rings = 4
	var bar: MeshInstance3D = shift._mesh(drawer, grip, Vector3(0, 0, -0.13), Color.WHITE)
	bar.rotation.z = PI / 2
	bar.material_override = chrome
	var post := CylinderMesh.new()
	post.top_radius = 0.017
	post.bottom_radius = 0.026
	post.height = 0.086
	post.radial_segments = 12
	for side in [-1, 1]:
		var mount: MeshInstance3D = shift._mesh(drawer, post, Vector3(side * 0.125, 0, -0.0875), Color.WHITE)
		mount.rotation.x = -PI / 2
		mount.material_override = chrome

func set_drawer_open(open: bool) -> void:
	if drawer_open == open: return
	drawer_open = open
	if drawer_motion != null: drawer_motion.kill()
	drawer_motion = create_tween()
	drawer_motion.tween_property(drawer, "position:z", -0.52 if open else 0.0, 0.24).set_trans(Tween.TRANS_SINE)

func refresh_pickup(held: bool) -> void:
	pickup.visible = drawer_open and not held
	pickup.collision_layer = 4 if pickup.visible else 0

func visual(parent: Node3D, held := false) -> Node3D:
	var model = MODEL.instantiate()
	parent.add_child(model)
	model.scale = Vector3.ONE*.36
	if held: model.rotation.y = PI
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var material = mesh.get_active_material(surface)
			if material is BaseMaterial3D:
				material = material.duplicate()
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				mesh.set_surface_override_material(surface,material)
	return model

func available() -> bool:
	return shift.refusal_required() and (shift.phase == "waiting" or shift.is_practicing())

func prompt() -> String:
	if not available(): return "Pistol · only available during a clothing-required encounter"
	return "[E] Take pistol · Q returns it" if shift.carried_item.is_empty() and not shift.has_empty_cup() else "Free your hands first"

func take() -> void:
	if not drawer_open: return
	var coop = preload("res://coop_session.gd").active(self)
	if coop != null and ((not coop.acting_guest and coop.guest_item == "Pistol") or (coop.acting_guest and coop.host_holding_pistol)):
		shift._message("Your partner has the pistol.")
		return
	if not available():
		shift._message("The pistol is only available during a clothing-required encounter.")
		return
	if not shift.carried_item.is_empty() or shift.has_empty_cup():
		shift._message("Free your hands before taking the pistol.")
		return
	shift.carried_item = "Pistol"
	shift.carried_source = pickup
	shift._refresh_carried()
	shift._message("Aim at the unclothed customer and click or press E. Q returns the pistol.")

func tick() -> void:
	if shift.carried_item == "Pistol" and not available(): shift._clear_carried(false)
	var coop = preload("res://coop_session.gd").active(self)
	refresh_pickup(shift.carried_item == "Pistol" or (coop != null and coop.guest_item == "Pistol"))

func fire(target: Node) -> bool:
	if shift.carried_item != "Pistol" or not available(): return false
	if not is_instance_valid(target) or target.get_meta("action","") != "customer": return false
	if not shift.customer.is_ancestor_of(target): return false
	shot.play()
	muzzle_flash()
	var coop = preload("res://coop_session.gd").active(self)
	if coop != null: coop.share_shot(coop.acting_guest)
	shift._clear_carried(false)
	shift.corpses.kill(shift.customer)
	shift.customer = null
	if shift.is_practicing():
		shift.tutorial.complete_encounter(shift)
		tick()
		return true
	shift.customers_this_shift += 1
	shift._depart_customer(false)
	shift._message("The customer is dead. Dispose of the body during closing cleanup. Pistol returned to the drawer.")
	tick()
	return true

func muzzle_flash() -> void:
	var flash := Node3D.new()
	shift.game.camera.add_child(flash)
	flash.position = Vector3(.25,-.24,-1.03)
	var star := SurfaceTool.new()
	star.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 16:
		star.add_vertex(Vector3.ZERO)
		for index in [i,i+1]:
			var angle: float = index*TAU/16
			var radius := .105 if index%2 == 0 else .033
			star.add_vertex(Vector3(cos(angle)*radius,sin(angle)*radius,0))
	var mesh := MeshInstance3D.new()
	mesh.mesh = star.commit()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(1,.8,.24)
	material.emission_enabled = true
	material.emission = Color(1,.55,.08)
	material.emission_energy_multiplier = 3
	mesh.material_override = material
	flash.add_child(mesh)
	var light := OmniLight3D.new()
	light.light_color = Color(1,.65,.25)
	light.light_energy = 2
	light.omni_range = 3
	flash.add_child(light)
	var tween := flash.create_tween()
	tween.tween_property(flash,"scale",Vector3.ONE*.05,.1)
	tween.tween_callback(flash.queue_free)
