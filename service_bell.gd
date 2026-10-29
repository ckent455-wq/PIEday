extends StaticBody3D

var shift: Node3D
var button: Node3D
var sound: AudioStreamPlayer3D
var next_ring := 0

func setup(host: Node3D) -> void:
	shift = host
	name = "ServiceBell"
	position = Vector3(-2.35, 1.201732, -4.65)
	collision_layer = 4
	set_meta("action", "bell")
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.13
	shape.height = 0.24
	collision.shape = shape
	collision.position.y = 0.11
	add_child(collision)
	var base := CylinderMesh.new()
	base.top_radius = 0.115
	base.bottom_radius = 0.12
	base.height = 0.025
	base.radial_segments = 32
	shift._mesh(self, base, Vector3(0, 0.0125, 0), Color(0.035, 0.035, 0.04))
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile: Array[Vector2] = [Vector2(0.105,0.026),Vector2(0.105,0.04),Vector2(0.098,0.065),Vector2(0.084,0.095),Vector2(0.063,0.12),Vector2(0.036,0.138),Vector2(0.012,0.145),Vector2(0,0.145)]
	for ring in range(profile.size()-1):
		for index in range(32):
			var a := TAU*index/32
			var b := TAU*(index+1)/32
			var p := profile[ring]
			var q := profile[ring+1]
			var vertices := [Vector3(cos(a)*p.x,p.y,sin(a)*p.x),Vector3(cos(b)*p.x,p.y,sin(b)*p.x),Vector3(cos(b)*q.x,q.y,sin(b)*q.x),Vector3(cos(a)*q.x,q.y,sin(a)*q.x)]
			for corner in [0,1,2,0,2,3]: builder.add_vertex(vertices[corner])
	builder.generate_normals()
	var chrome := StandardMaterial3D.new()
	chrome.albedo_color = Color(0.65,0.67,0.7)
	chrome.metallic = 0.25
	chrome.roughness = 0.25
	chrome.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dome := MeshInstance3D.new()
	dome.mesh = builder.commit()
	dome.material_override = chrome
	add_child(dome)
	button = Node3D.new()
	add_child(button)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.012
	stem.bottom_radius = 0.012
	stem.height = 0.035
	shift._mesh(button, stem, Vector3(0,0.155,0), Color(0.16,0.17,0.18))
	var cap := CylinderMesh.new()
	cap.top_radius = 0.032
	cap.bottom_radius = 0.032
	cap.height = 0.012
	var cap_mesh: MeshInstance3D = shift._mesh(button, cap, Vector3(0,0.177,0), Color.WHITE)
	cap_mesh.material_override = chrome
	sound = AudioStreamPlayer3D.new()
	sound.stream = preload("res://assets/audio/service_bell.wav")
	sound.unit_size = 3
	sound.max_distance = 12
	add_child(sound)
	shift._label(self, "RING TO SERVE", Vector3(0,0.31,0), 0.0012)

func ring() -> void:
	var now := Time.get_ticks_msec()
	if now < next_ring: return
	next_ring = now + 450
	sound.play()
	var tween := create_tween()
	tween.tween_property(button, "position:y", -0.013, 0.055)
	tween.tween_property(button, "position:y", 0.0, 0.12)
	if shift.phase != "waiting":
		shift._message("Ding! Wait for a customer to reach the counter.")
	elif not shift.order_taken:
		shift._message("Take the customer's order before ringing to serve.")
	elif shift.tray.is_empty():
		shift._message("The tray is empty. Place the order on it before ringing the bell.")
	else:
		shift.serve_order()
