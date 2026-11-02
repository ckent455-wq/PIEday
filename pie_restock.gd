extends Node3D

var shift: Node3D
var bins: Array[StaticBody3D] = []
var cooler_target: StaticBody3D
var missing: Array[Node3D] = []

func setup(host: Node3D) -> void:
	shift = host
	name = "PieRestocking"
	var light := OmniLight3D.new()
	light.position = Vector3(9.3, 2.7, -12)
	light.light_color = Color(0.72, 0.84, 1.0)
	light.light_energy = 0.7
	light.omni_range = 4.0
	add_child(light)
	var task := StaticBody3D.new()
	task.name = "RestockTask"
	add_child(task)
	shift.task_nodes["restock"] = task
	var stand := StaticBody3D.new()
	add_child(stand)
	stand.position = Vector3(10.15, 1.22, -12.0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.65, 0.08, 3.6)
	_collision(stand, shape)
	shift._box(stand, Vector3.ZERO, shape.size, Color(0.36, 0.4, 0.42))
	for i in range(3):
		var bin := StaticBody3D.new()
		bin.name = "FreezerStock_" + str(i)
		bin.collision_layer = 4
		bin.set_meta("action", "freezer_stock")
		bin.set_meta("item", shift.PIE_NAMES[i])
		add_child(bin)
		bin.position = Vector3(10.15, 1.48, -13.2 + i * 1.2)
		var box := BoxShape3D.new()
		box.size = Vector3(0.65, 0.46, 0.9)
		_collision(bin, box)
		shift._box(bin, Vector3(0, -0.1, 0), Vector3(0.62, 0.25, 0.8), Color(0.5, 0.39, 0.24))
		for z in [-0.2, 0.2]:
			var pie = preload("res://assets/pies/pie_ps2.glb").instantiate()
			bin.add_child(pie)
			pie.position = Vector3(0, 0.035, z)
			pie.scale = Vector3.ONE * 0.85
		shift._label(bin, str(shift.PIE_NAMES[i]).to_upper(), Vector3(0, 0.5, 0), 0.0012)
		bins.append(bin)
	cooler_target = StaticBody3D.new()
	cooler_target.name = "CoolerRestockTarget"
	cooler_target.set_meta("action", "restock_cooler")
	cooler_target.collision_layer = 0
	add_child(cooler_target)
	cooler_target.position = Vector3(1.25, 1.14, -8.55)
	var target_shape := BoxShape3D.new()
	target_shape.size = Vector3(1.64, 2.0, 0.65)
	_collision(cooler_target, target_shape)

func _collision(body: StaticBody3D, shape: Shape3D) -> void:
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

func begin() -> void:
	missing.clear()
	for pie in shift.all_pies:
		if not pie.visible: missing.append(pie)
	cooler_target.collision_layer = 4
	if missing.is_empty(): shift.complete_task("restock")

func reset() -> void:
	missing.clear()
	cooler_target.collision_layer = 0

func needed(flavor: String) -> int:
	var count := 0
	for pie in missing:
		if pie.get_meta("item") == flavor: count += 1
	return count

func prompt(action: String, node: Node) -> String:
	if shift.phase != "cleanup": return "Freezer pie stock - for closing replenishment"
	if action == "freezer_stock":
		var flavor: String = node.get_meta("item")
		return "[E / Click] Take " + flavor + " crate (%d needed)" % needed(flavor) if needed(flavor) > 0 else flavor + " shelf is full"
	if missing.is_empty(): return "Cooler fully replenished"
	return "[E / Click] Refill cooler with " + shift.carried_item.trim_suffix(" stock") if shift.carried_item.ends_with(" stock") else "Bring replacement pie crates from the freezer room"

func take(node: Node) -> void:
	if shift.phase != "cleanup":
		shift._message("Freezer stock is for replenishing the cooler during closing.")
		return
	var flavor: String = node.get_meta("item")
	if needed(flavor) == 0:
		shift._message(flavor + " shelf is already full.")
		return
	if not shift.carried_item.is_empty() or shift.has_empty_cup() or shift.carrying_trash:
		shift._message("Free your hands before collecting a pie crate.")
		return
	shift.carried_item = flavor + " stock"
	shift._refresh_carried()
	shift._message("Carry the " + flavor + " crate to the kitchen cooler. Open both doors and interact inside to replenish its shelf. Q returns the crate.")

func deliver() -> void:
	if shift.phase != "cleanup" or not shift.carried_item.ends_with(" stock"): return
	for door in shift.game.doors:
		if door.has_meta("cooler") and not door.get_meta("open"):
			shift._message("Open both cooler doors before replenishing the shelves.")
			return
	var flavor: String = shift.carried_item.trim_suffix(" stock")
	for pie in missing.duplicate():
		if pie.get_meta("item") == flavor:
			pie.set_meta("bake_quality", "raw")
			pie.set_meta("bake_seconds", 0.0)
			shift._set_pickup_visible(pie, true)
			missing.erase(pie)
	shift._clear_carried(false)
	if missing.is_empty():
		shift.complete_task("restock")
	else:
		shift._message(flavor + " replenished. %d more pies need replacing from the freezer." % missing.size())
