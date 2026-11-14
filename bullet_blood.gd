extends RefCounted
## Short-lived, low-poly impact flecks and a fading surface stain.
static func impact(world: Node3D, at: Vector3, normal: Vector3, headshot := false) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "BulletBlood"
	world.add_child(particles)
	particles.global_position = at
	particles.amount = 22 if headshot else 14
	particles.lifetime = .42
	particles.one_shot = true
	particles.explosiveness = 1
	particles.direction = (normal+Vector3.UP*.55).normalized()
	particles.spread = 55
	particles.initial_velocity_min = .5
	particles.initial_velocity_max = 1.6
	particles.gravity = Vector3(0,-5,0)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(.018,.018,.018)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8b1720")
	material.roughness = 1
	mesh.material = material
	particles.mesh = mesh
	particles.finished.connect(particles.queue_free)
	particles.restart()
	var ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*.1,at-Vector3.UP*3,1)
	var excluded: Array[RID] = []
	for body in world.find_children("*","CollisionObject3D",true,false):
		if body.has_meta("action") and body.get_meta("action") in ["customer","queued_customer","corpse"]: excluded.append(body.get_rid())
	ray.exclude = excluded
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.normal.y < .8: return
	var stain := MeshInstance3D.new()
	stain.name = "FadingBloodStain"
	world.add_child(stain)
	stain.global_position = hit.position+Vector3.UP*.008
	var disc := CylinderMesh.new()
	disc.top_radius = .15 if headshot else .10
	disc.bottom_radius = disc.top_radius
	disc.height = .002
	disc.radial_segments = 9
	stain.mesh = disc
	stain.scale.z = .65
	stain.rotation.y = randf()*TAU
	var red := StandardMaterial3D.new()
	red.albedo_color = Color("59121a")
	red.roughness = 1
	red.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	stain.material_override = red
	stain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fade := stain.create_tween()
	fade.tween_interval(10)
	fade.tween_property(red,"albedo_color:a",0.0,3)
	fade.tween_callback(stain.queue_free)
