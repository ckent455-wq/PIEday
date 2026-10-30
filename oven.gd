extends StaticBody3D

const PERFECT_AT := 7.0
const BURNS_AT := 13.0
var shift: Node3D
var doors: Array[MeshInstance3D] = []
var pie_source: Node3D
var pie_item := ""
var elapsed := 0.0
var display: Label3D
var visual: Node3D
var shown_quality := ""
var heat: OmniLight3D

func setup(host: Node3D) -> void:
	shift = host
	name = "PieOven"
	position = Vector3(4.25, 1.65, -13.91)
	collision_layer = 4
	set_meta("action", "oven")
	for door in shift.game.doors:
		if door.name in ["Oven_Door", "Oven_Door_01"]:
			doors.append(door)
	# Remove the two decorative food props and their collision bodies.
	for node in shift.game.find_children("*", "MeshInstance3D", true, false):
		if node.name in ["Bread", "Bread_01"]:
			node.visible = false
			for body in node.find_children("*", "StaticBody3D", true, false):
				body.collision_layer = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.83, 0.30, 0.30)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	visual = Node3D.new()
	add_child(visual)
	visual.position = Vector3(0, -0.012, -0.12)
	display = shift._label(self, "", Vector3(0, 0.59, 0.37), 0.0015)
	display.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	display.font_size = 32
	display.no_depth_test = false
	heat = OmniLight3D.new()
	heat.light_color = Color(1, 0.35, 0.06)
	heat.light_energy = 0.6
	heat.omni_range = 1.0
	add_child(heat)
	_update_display()

func all_open() -> bool:
	return doors.size() == 2 and doors.all(func(door): return door.get_meta("open", false))

func sealed() -> bool:
	if doors.size() != 2: return false
	for door in doors:
		if door.get_meta("open", false): return false
		if door.has_meta("tween") and door.get_meta("tween").is_running(): return false
	return true

func quality() -> String:
	if elapsed >= BURNS_AT: return "burnt"
	if elapsed >= PERFECT_AT: return "perfect"
	return "undercooked"

func _process(delta: float) -> void:
	if not is_instance_valid(shift): return
	if not pie_item.is_empty() and sealed():
		elapsed = minf(elapsed + delta, BURNS_AT)
	if not pie_item.is_empty() and shown_quality != quality():
		_refresh_visual()
	_update_display()

func prompt() -> String:
	if not all_open(): return "[E on either oven door] Open oven doors"
	if pie_item.is_empty():
		return "[Click / E] Put " + shift.carried_item + " in oven" if shift.carried_item.ends_with("pie") else "Oven empty - bring an unbaked pie"
	return "[Click / E] Take " + quality() + " " + pie_item + " (%.1fs)" % elapsed

func interact() -> void:
	if shift.phase not in ["waiting", "arriving"]:
		shift._message("Open the shift before baking pies.")
		return
	if not all_open():
		shift._message("Open both oven doors to load or take out a pie.")
		return
	if pie_item.is_empty():
		if not shift.carried_item.ends_with("pie") or not is_instance_valid(shift.carried_source):
			shift._message("Bring a pie from the cooler to the oven.")
			return
		pie_source = shift.carried_source
		pie_item = shift.carried_item
		elapsed = float(pie_source.get_meta("bake_seconds", 0.0))
		shift._clear_carried(false)
		_refresh_visual()
		shift._message("Pie loaded. Close BOTH oven doors. Perfect bake: 7-13 seconds; open the doors to stop cooking.")
	else:
		if not shift.carried_item.is_empty() or shift.has_empty_cup():
			shift._message("Free your hand before taking the pie out.")
			return
		pie_source.set_meta("bake_quality", quality())
		pie_source.set_meta("bake_seconds", elapsed)
		if shift.pickup_item(pie_item, pie_source):
			shift._message("Taken out: " + quality() + " " + pie_item + "." + (" Put it on the serving tray." if quality() == "perfect" else " Customers only accept perfectly baked pies."))
			pie_item = ""
			pie_source = null
			_refresh_visual()
	_update_display()

func _refresh_visual() -> void:
	for child in visual.get_children():
		visual.remove_child(child)
		child.queue_free()
	shown_quality = quality()
	if pie_item.is_empty(): return
	var path := "res://assets/pies/pie_ps2.glb" if elapsed < PERFECT_AT else "res://assets/pies/pie_ps2_toasted.glb"
	if quality() == "burnt": path = "res://assets/pies/pie_ps2_burnt.glb"
	var pie: Node3D = load(path).instantiate()
	visual.add_child(pie)
	pie.scale = Vector3.ONE * 1.15

func _update_display() -> void:
	heat.visible = not pie_item.is_empty() and sealed()
	if pie_item.is_empty():
		display.text = "PIE OVEN\nPERFECT: 7-13 SECONDS"
		display.modulate = Color.WHITE
		return
	var state := quality().to_upper()
	if elapsed < PERFECT_AT: state = "READY IN %.1fs" % (PERFECT_AT - elapsed)
	display.text = "%s  %.1fs\n%s" % [pie_item.to_upper(), elapsed, state]
	if not sealed(): display.text += "\nHEAT OFF - TAKE PIE" if quality() in ["perfect", "burnt"] else "\nHEAT PAUSED"
	display.modulate = Color(1, 0.3, 0.15) if quality() == "burnt" else Color(0.5, 1, 0.55) if quality() == "perfect" else Color(1, 0.85, 0.5)

func reset_oven() -> void:
	pie_item = ""
	pie_source = null
	elapsed = 0
	_refresh_visual()
	_update_display()
