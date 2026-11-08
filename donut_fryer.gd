extends Node3D
## Shared, host-authoritative donut batches using the original kitchen fryers.
const TYPES = preload("res://donut_types.gd")
const READY := 5.0
const BURNT := 10.0
var shift: Node
var stock := [0, 0, 0]
var batches: Array[Dictionary] = []
var effect_time := 0.0

func setup(owner_shift: Node) -> void:
	shift = owner_shift
	for mesh in shift.game.find_children("Fryer*", "MeshInstance3D", true, false):
		mesh.set_meta("action", "donut_fryer")
		mesh.set_meta("fryer_index", batches.size())
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		var holder := Node3D.new()
		add_child(holder)
		holder.global_position = Vector3(box.get_center().x, box.end.y - 0.15, box.get_center().z)
		holder.set_meta("base_y", holder.position.y)
		var baskets: Array = []
		var oil_pans: Array = []
		for basket in shift.game.find_children("Mesh*", "MeshInstance3D", true, false):
			if basket.name not in ["Mesh", "Mesh_01", "Mesh_02", "Mesh_03"]: continue
			var bounds: AABB = basket.global_transform * basket.get_aabb()
			if absf(bounds.get_center().x - box.get_center().x) > 0.61 or absf(bounds.get_center().z - box.get_center().z) > 0.6: continue
			basket.set_meta("action", "donut_fryer")
			basket.set_meta("fryer_index", batches.size())
			baskets.append({"mesh": basket, "raised": basket.position})
			oil_pans.append(_make_oil(bounds))
			# A shallow wire insert supports the batch near the basket rim.
			# Keep its surface exactly beneath the dough rather than suspending it.
			var rack := Node3D.new()
			basket.add_child(rack)
			rack.global_transform = Transform3D(Basis.IDENTITY, Vector3(bounds.get_center().x, bounds.position.y + 0.20, bounds.position.z + 0.21))
			var steel := StandardMaterial3D.new()
			steel.albedo_color = Color(0.52, 0.55, 0.56)
			steel.metallic = 0.65
			steel.roughness = 0.6
			for axis in range(2):
				for wire in range(9):
					var bar := MeshInstance3D.new()
					var shape := BoxMesh.new()
					shape.size = Vector3(0.32, 0.006, 0.006) if axis == 0 else Vector3(0.006, 0.006, 0.38)
					bar.mesh = shape
					bar.material_override = steel
					bar.position = Vector3(0, 0, (wire - 4) * 0.0475) if axis == 0 else Vector3((wire - 4) * 0.04, 0, 0)
					rack.add_child(bar)
			# Three smaller rings run front-to-back inside each wire basket.
			# The full mesh bounds include its handle projecting toward the player.
			for row in range(3):
				var ring := MeshInstance3D.new()
				ring.mesh = TYPES.dough()
				ring.scale = Vector3.ONE * 0.56
				ring.material_override = StandardMaterial3D.new()
				holder.add_child(ring)
				ring.global_position = Vector3(bounds.get_center().x, bounds.position.y + 0.222, bounds.position.z + 0.09 + row * 0.12)
		var sizzle := AudioStreamPlayer3D.new()
		sizzle.name = "FryerSizzle"
		var loop: AudioStreamWAV = preload("res://assets/audio/fryer_sizzle.wav").duplicate()
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop.loop_end = int(round(loop.get_length() * loop.mix_rate))
		sizzle.stream = loop
		sizzle.volume_db = -12.0
		sizzle.unit_size = 2.0
		sizzle.max_distance = 12.0
		add_child(sizzle)
		sizzle.global_position = Vector3(box.get_center().x, box.end.y - 0.25, box.get_center().z)
		batches.append({"state": "empty", "elapsed": 0.0, "holder": holder, "baskets": baskets, "lower": 0.0, "oil": oil_pans, "audio": sizzle})
	reset()

func _make_oil(bounds: AABB) -> Node3D:
	var pan := Node3D.new()
	pan.name = "FryingOil"
	add_child(pan)
	pan.global_position = Vector3(bounds.get_center().x, bounds.position.y + 0.065, bounds.position.z + 0.21)
	var surface := MeshInstance3D.new()
	surface.name = "OilSurface"
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.40, 0.43)
	plane.subdivide_width = 10
	plane.subdivide_depth = 10
	surface.mesh = plane
	var oil := ShaderMaterial.new()
	oil.shader = preload("res://fryer_oil.gdshader")
	surface.material_override = oil
	pan.add_child(surface)
	var foam := StandardMaterial3D.new()
	foam.albedo_color = Color(0.78, 0.60, 0.28)
	foam.roughness = 0.3
	var bubble_mesh := SphereMesh.new()
	bubble_mesh.radius = 0.009
	bubble_mesh.height = 0.018
	bubble_mesh.radial_segments = 8
	bubble_mesh.rings = 4
	for i in range(24):
		var bubble := MeshInstance3D.new()
		bubble.mesh = bubble_mesh
		bubble.material_override = foam
		bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bubble.position = Vector3(sin(i * 13.17) * 0.16, 0, cos(i * 7.31) * 0.18)
		bubble.visible = false
		pan.add_child(bubble)
	return pan

func reset() -> void:
	stock = [0, 0, 0]
	for batch in batches:
		batch.state = "empty"
		batch.elapsed = 0.0
	refresh()

func tick(delta: float) -> void:
	for batch in batches:
		if batch.state == "frying": batch.elapsed += delta
	refresh()

func _process(delta: float) -> void:
	effect_time += delta
	for batch in batches:
		batch.lower = move_toward(float(batch.lower), 0.15 if batch.state == "frying" else 0.0, delta * 0.45)
		for basket in batch.baskets:
			basket.mesh.position = basket.raised - Vector3.UP * float(batch.lower)
		var active: bool = batch.state == "frying" and batch.lower > 0.10
		for pan in batch.oil:
			pan.get_node("OilSurface").material_override.set_shader_parameter("frying", 1.0 if active else 0.0)
			for i in range(1, pan.get_child_count()):
				var bubble: MeshInstance3D = pan.get_child(i)
				var life := fposmod(effect_time * (1.8 + (i % 4) * 0.22) + i * 0.37, 1.0)
				bubble.visible = active and life < 0.85
				bubble.position.y = life * 0.018
				bubble.scale = Vector3.ONE * (0.4 + sin(life * PI) * 0.8)
	refresh()

func prepared() -> bool:
	return stock.all(func(count): return count > 0)

func prompt(node: Node) -> String:
	var batch: Dictionary = batches[int(node.get_meta("fryer_index"))]
	match batch.state:
		"raw": return "[E] Lower basket again — donuts still raw"
		"empty": return "[E] Lower 6 raw dough rings into fryer — ready at 5s, burns at 10s"
		"frying": return "[E] Lift basket — %0.1fs / %s" % [batch.elapsed, "BURNT" if batch.elapsed >= BURNT else "GOLDEN!" if batch.elapsed >= READY else "still raw"]
	return "Batch ready — aim at a flavor in the donut case to ice and stock it"

func use(node: Node) -> void:
	if shift.phase == "cleanup" or shift.phase == "closed": return
	var batch: Dictionary = batches[int(node.get_meta("fryer_index"))]
	if batch.state in ["empty", "raw"]:
		var fresh: bool = batch.state == "empty"
		batch.state = "frying"
		if fresh: batch.elapsed = 0.0
		shift._message("Donuts frying! Lift the basket after 5 seconds, before 10 seconds.")
	elif batch.state == "frying":
		if batch.elapsed < READY:
			batch.state = "raw"
			shift._message("Basket lifted, but donuts are still raw. Press E to lower them again.")
		elif batch.elapsed >= BURNT:
			batch.state = "empty"
			shift._message("Burnt batch discarded. Press E at the fryer to try again.")
		else:
			batch.state = "ready"
			shift._message("Basket lifted! Aim at strawberry, chocolate or glazed in the display and press E to ice and stock this batch.")
	else: shift._message("Finish this batch at the donut case before frying more.")
	refresh()

func use_case(flavor: String) -> void:
	var index: int = TYPES.TYPES.find(flavor)
	if index < 0: return
	for batch in batches:
		if batch.state == "ready":
			stock[index] += 6
			batch.state = "empty"
			refresh()
			shift._message("Iced and stocked 6 %ss. %s" % [flavor.to_lower(), "All flavors ready — flip the OPEN sign in the front window!" if prepared() and shift.phase == "prep" else "Prepare the other flavors or refill during service."])
			return
	if shift.is_practicing():
		shift.pickup_item(flavor)
		return
	if stock[index] <= 0:
		shift._message("No %ss left. Fry a batch in the kitchen first." % flavor.to_lower())
		return
	if shift.pickup_item(flavor):
		stock[index] -= 1
		refresh()

func refresh() -> void:
	for batch in batches:
		if batch.state == "frying":
			if not batch.audio.playing: batch.audio.play(fposmod(float(batch.elapsed), batch.audio.stream.get_length()))
		elif batch.audio.playing: batch.audio.stop()
		batch.holder.visible = batch.state != "empty"
		batch.holder.position.y = float(batch.holder.get_meta("base_y")) - float(batch.lower)
		for ring in batch.holder.get_children():
			ring.material_override.albedo_color = Color(0.13, 0.055, 0.02) if batch.elapsed >= BURNT else Color(0.72, 0.38, 0.10) if batch.elapsed >= READY else Color(0.87, 0.73, 0.49)
	var counts := [0, 0, 0]
	for mesh in shift.game.find_children("Donus*", "MeshInstance3D", true, false):
		var index: int = TYPES.TYPES.find(str(mesh.get_meta("item", "")))
		if index < 0: continue
		mesh.visible = counts[index] < stock[index]
		counts[index] += 1

func snapshot() -> Dictionary:
	return {"stock": stock.duplicate(), "batches": batches.map(func(batch): return [batch.state, batch.elapsed])}

func restore(data: Dictionary) -> void:
	if data.is_empty(): return
	stock.assign(data.stock)
	for i in mini(batches.size(), data.batches.size()):
		batches[i].state = data.batches[i][0]
		batches[i].elapsed = data.batches[i][1]
	refresh()
