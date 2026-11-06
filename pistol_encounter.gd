extends Node3D

const MODEL = preload("res://assets/pistol/pistol.glb")
var shift: Node3D
var pickup: StaticBody3D
var shot: AudioStreamPlayer

func setup(host: Node3D) -> void:
	shift = host
	name = "KitchenPistol"
	pickup = shift.game.get_node_or_null("KitchenPistolPickup")
	if pickup == null:
		pickup = preload("res://kitchen_pistol.tscn").instantiate()
		add_child(pickup)
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
	return shift.phase == "waiting" and shift.refusal_required()

func prompt() -> String:
	if not available(): return "Pistol · only available during a clothing-required encounter"
	return "[E] Take pistol · Q returns it" if shift.carried_item.is_empty() and not shift.has_empty_cup() else "Free your hands first"

func take() -> void:
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
	pickup.visible = shift.carried_item != "Pistol"
	pickup.collision_layer = 4 if pickup.visible else 0

func fire(target: Node) -> bool:
	if shift.carried_item != "Pistol" or not available(): return false
	if not is_instance_valid(target) or target.get_meta("action","") != "customer": return false
	if not shift.customer.is_ancestor_of(target): return false
	shot.play()
	muzzle_flash()
	shift._clear_carried(false)
	shift.customers_this_shift += 1
	shift.corpses.kill(shift.customer)
	shift.customer = null
	shift._depart_customer(false)
	shift._message("The customer is dead. Dispose of the body during closing cleanup. Pistol returned to the kitchen.")
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
