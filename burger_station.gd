extends Node3D

const SIDE_SECONDS := 3.0
const BURNS_AT := 12.0
var shift: Node
var cooking := false
var elapsed := 0.0
var flipped_at := -1.0
var visual: Node3D
var shown := ""
var audio: AudioStreamPlayer3D
var grill: StaticBody3D
var prep: StaticBody3D
var raw_tray: StaticBody3D

func setup(owner_shift: Node) -> void:
	shift = owner_shift
	name = "BurgerStation"
	grill = _target("burger_grill", Vector3(-2.99, 1.15245, -11.45), Vector3(0.9, 0.26, 1.05))
	prep = _target("burger_prep", Vector3(-3.0, 1.2625, -12.18), Vector3(0.72, 0.18, 0.44))
	raw_tray = _target("burger_raw", Vector3(-3.0, 1.2625, -12.82), Vector3(0.72, 0.18, 0.44))
	var stove = shift.game.find_child("Stoves",true,false)
	if stove != null and stove.has_meta("burger_grill_anchor"):
		grill.global_transform = stove.global_transform * Transform3D(stove.get_meta("burger_grill_basis", Basis.IDENTITY),stove.get_meta("burger_grill_anchor"))
	var counter = shift.game.find_child("StainlessPrepCounter",true,false)
	if counter != null:
		prep.global_transform = counter.global_transform * Transform3D(Basis.IDENTITY,Vector3(0.0815,0.0925,0.30))
		raw_tray.global_transform = counter.global_transform * Transform3D(Basis.IDENTITY,Vector3(0.0815,0.0925,-0.34))
	for tray in [prep,raw_tray]:
		shift._box(tray, Vector3(0,-0.05,0), Vector3(0.70,0.025,0.42), Color(0.62,0.64,0.63))
		for x in [-0.35,0.35]:
			shift._box(tray,Vector3(x,-0.033,0),Vector3(0.012,0.035,0.42),Color(0.62,0.64,0.63))
		for z in [-0.21,0.21]:
			shift._box(tray,Vector3(0,-0.033,z),Vector3(0.70,0.035,0.012),Color(0.62,0.64,0.63))
	for i in range(3):
		var raw := preload("res://assets/burger/burger_patty_raw.glb").instantiate()
		raw_tray.add_child(raw)
		raw.position = Vector3(-0.20 + i * 0.20,-0.034,0)
	for i in range(2):
		var bun := Node3D.new()
		prep.add_child(bun)
		bun.position = Vector3(-0.16+i*0.32,-0.034,0)
		var bun_bottom = preload("res://assets/burger/burger_bun_bottom.glb").instantiate()
		bun.add_child(bun_bottom)
		var bun_top = preload("res://assets/burger/burger_bun_top.glb").instantiate()
		bun.add_child(bun_top)
		bun_top.position.y = 0.018
	visual = Node3D.new()
	grill.add_child(visual)
	visual.position.y = 0.012
	audio = AudioStreamPlayer3D.new()
	grill.add_child(audio)
	var loop: AudioStreamWAV = preload("res://assets/audio/fryer_sizzle.wav").duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = int(round(loop.get_length()*loop.mix_rate))
	audio.stream = loop
	audio.volume_db = -13
	audio.unit_size = 2
	audio.max_distance = 12
	refresh()

func _target(action: String, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = action
	body.collision_layer = 4
	body.set_meta("action",action)
	add_child(body)
	body.global_position = at
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	body.add_child(collider)
	return body

func quality() -> String:
	if elapsed >= BURNS_AT: return "burnt"
	if flipped_at >= 0 and elapsed-flipped_at >= SIDE_SECONDS - 0.00001: return "ready"
	return "raw"

func tick(delta: float) -> void:
	if cooking: elapsed += delta
	refresh()

func reset() -> void:
	cooking = false
	elapsed = 0
	flipped_at = -1
	refresh()

func prompt(action: String) -> String:
	if action == "burger_raw": return "[E] Take raw patty — raw meat tray" if shift.carried_item.is_empty() and not shift.has_empty_cup() else "Raw meat tray — keep cooked food on the bun tray"
	if action == "burger_prep":
		return "[E] Assemble burger in bun" if shift.carried_item == "Cooked patty" else "Bun tray — bring a cooked patty from the flat top"
	if not cooking: return "[E] Put raw patty on flat top" if shift.carried_item == "Raw patty" else "Flat top — get a raw patty from the metal tray"
	if quality() == "burnt": return "[E] Discard burnt patty"
	if quality() == "ready": return "[E] Take cooked patty — assemble at the bun tray"
	if flipped_at < 0: return "[E] Flip patty — first side %0.1f / 3s" % elapsed
	return "Cooking second side — %0.1f / 3s (burns at 12s total)" % (elapsed-flipped_at)

func use(action: String) -> void:
	if shift.phase not in ["waiting","arriving","leaving"]:
		shift._message("Burgers are cooked to order during service. Finish donut prep and switch the OPEN sign on first.")
		return
	if action == "burger_raw":
		if shift.carried_item.is_empty() and not shift.has_empty_cup(): shift.pickup_item("Raw patty")
		else: shift._message("Keep raw and cooked food separate. Take cooked patties to the bun tray; free your hands before taking raw meat.")
		return
	if action == "burger_prep":
		if shift.carried_item == "Cooked patty":
			shift._clear_carried(false)
			shift.pickup_item("Burger")
			shift._message("Burger assembled! Put it on the serving tray.")
		else: shift._message("This tray is for buns and cooked patties only. Cook raw meat on the flat top first.")
		return
	if not cooking:
		if shift.carried_item != "Raw patty":
			shift._message("Take a raw patty from the metal tray beside the flat top first.")
			return
		shift._clear_carried(false)
		cooking = true
		elapsed = 0
		flipped_at = -1
		shift._message("Patty on the flat top. Cook the first side for 3 seconds, press E to flip, then cook the other side for 3 seconds. Burns at 12 seconds total.")
	elif quality() == "burnt":
		reset()
		shift._message("Burnt patty discarded. Start again with a fresh one.")
	elif flipped_at < 0:
		if elapsed < SIDE_SECONDS:
			shift._message("First side needs 3 seconds before flipping.")
			return
		flipped_at = elapsed
		var flip := create_tween()
		flip.tween_property(visual,"rotation:z",PI,0.3)
		shift._message("Patty flipped. Cook the second side for 3 seconds, then collect it before it burns.")
	elif quality() == "ready":
		if shift.pickup_item("Cooked patty"):
			reset()
			shift._message("Take the cooked patty to the bun tray beside the flat top and press E to assemble your burger.")
	else: shift._message("Second side still cooking. Give it 3 seconds after flipping.")
	refresh()

func refresh() -> void:
	if not is_instance_valid(visual): return
	var state := ("second" if quality() == "raw" and flipped_at >= 0 else quality()) if cooking else "empty"
	if state != shown:
		shown = state
		for child in visual.get_children():
			visual.remove_child(child)
			child.queue_free()
		visual.rotation = Vector3.ZERO
		if cooking:
			var model = load("res://assets/burger/burger_patty_" + ("raw" if state == "raw" and flipped_at < 0 else "cooked") + ".glb").instantiate()
			visual.add_child(model)
			model.position.y = -0.011
			if state == "burnt":
				for mesh in model.find_children("*","MeshInstance3D",true,false):
					var charred := StandardMaterial3D.new()
					charred.albedo_color = Color(0.065,0.035,0.022)
					mesh.material_override = charred
	if cooking and not audio.playing: audio.play()
	elif not cooking and audio.playing: audio.stop()

func snapshot() -> Dictionary:
	return {"cooking":cooking,"elapsed":elapsed,"flipped_at":flipped_at}

func restore(data: Dictionary) -> void:
	if data.is_empty():
		reset()
		return
	cooking = data.cooking
	elapsed = data.elapsed
	flipped_at = data.flipped_at
	refresh()

static func model(parent: Node3D) -> void:
	var bottom = preload("res://assets/burger/burger_bun_bottom.glb").instantiate()
	parent.add_child(bottom)
	var patty = preload("res://assets/burger/burger_patty_cooked.glb").instantiate()
	parent.add_child(patty)
	patty.position.y = 0.018
	var top = preload("res://assets/burger/burger_bun_top.glb").instantiate()
	parent.add_child(top)
	top.position.y = 0.0405
