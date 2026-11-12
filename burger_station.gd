extends Node3D

const SIDE_SECONDS := 3.0
const BURNS_AT := 12.0
const LETTUCE_LEAF := preload("res://assets/burger/lettuce_leaf.glb")
const TOMATO_SLICE := preload("res://assets/burger/tomato_slice.glb")
const TOMATO_STOCK := "Tomato stock"
const ONION_STOCK := "Onion stock"
const LETTUCE_STOCK := "Lettuce stock"
const LETTUCE_INDEX := 1
const TOMATO_INDEX := 2
const ONION_INDEX := 3
const CHEESE_STOCK := "Cheese stock"
const CHEESE_INDEX := 0
const PRODUCE_INDICES := [TOMATO_INDEX, ONION_INDEX, LETTUCE_INDEX, CHEESE_INDEX]
const PRODUCE_ITEMS := [TOMATO_STOCK, ONION_STOCK, LETTUCE_STOCK, CHEESE_STOCK]
const CHEESE_SLICE := preload("res://assets/burger/cheese_slice.glb")
const CHEESE_DRAPED := preload("res://assets/burger/cheese_draped.glb")
const TOPPINGS := ["Cheese", "Lettuce", "Tomato", "Onion"]
# Each topping has one bit, so ingredients can be added in any order.
const BURGERS := [
	"Burger", "Cheeseburger", "Lettuce burger", "Cheese and lettuce burger",
	"Tomato burger", "Cheese and tomato burger", "Lettuce and tomato burger", "Cheese, lettuce and tomato burger",
	"Onion burger", "Cheese and onion burger", "Lettuce and onion burger", "Cheese, lettuce and onion burger",
	"Tomato and onion burger", "Cheese, tomato and onion burger", "Lettuce, tomato and onion burger", "Deluxe burger",
]
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
var ingredient_groups: Array[Node3D] = []
var ingredients_visible := true
var tomatoes_stocked := false
var tomato_ingredients: Node3D
var onions_stocked := false
var onion_ingredients: Node3D
var lettuce_stocked := false
var lettuce_ingredients: Node3D
var cheese_stocked := false
var cheese_ingredients: Node3D

func setup(owner_shift: Node) -> void:
	shift = owner_shift
	name = "BurgerStation"
	grill = _target("burger_grill", Vector3(-2.99, 1.15245, -11.45), Vector3(0.9, 0.26, 1.05))
	prep = _target("burger_prep", Vector3(-2.79, 1.2195, -11.97), Vector3(0.72, 0.18, 0.44))
	raw_tray = _target("burger_raw", Vector3(-3.17, 1.2125, -9.81), Vector3(0.72, 0.18, 0.44))
	var stove = shift.game.find_child("Stoves",true,false)
	if stove != null and stove.has_meta("burger_grill_anchor"):
		grill.global_transform = stove.global_transform * Transform3D(stove.get_meta("burger_grill_basis", Basis.IDENTITY),stove.get_meta("burger_grill_anchor"))
	var counter := shift.game.find_child("StainlessPrepCounter", true, false) as MeshInstance3D
	if counter != null:
		prep.global_transform = counter.global_transform * Transform3D(Basis.IDENTITY,Vector3(0.30,0.0925,0.45))
	var side_surface := shift.game.find_child("SidePrepSurface", true, false) as MeshInstance3D
	if side_surface != null:
		var bounds := side_surface.get_aabb()
		var tray_center := bounds.get_center()
		tray_center.y = bounds.end.y + 0.0625
		raw_tray.global_transform = side_surface.global_transform * Transform3D(Basis.IDENTITY, tray_center)
	for tray in [prep,raw_tray]:
		shift._box(tray, Vector3(0,-0.05,0), Vector3(0.70,0.025,0.42), Color(0.62,0.64,0.63))
		for x in [-0.35,0.35]:
			shift._box(tray,Vector3(x,-0.033,0),Vector3(0.012,0.035,0.42),Color(0.62,0.64,0.63))
		for z in [-0.21,0.21]:
			shift._box(tray,Vector3(0,-0.033,z),Vector3(0.70,0.035,0.012),Color(0.62,0.64,0.63))
	var patties := _ingredient_group(raw_tray)
	for i in range(3):
		var raw := preload("res://assets/burger/burger_patty_raw.glb").instantiate()
		patties.add_child(raw)
		raw.position = Vector3(-0.20 + i * 0.20,-0.034,0)
	var buns := _ingredient_group(prep)
	for i in range(2):
		var bun := Node3D.new()
		buns.add_child(bun)
		bun.position = Vector3(-0.16+i*0.32,-0.034,0)
		var bun_bottom = preload("res://assets/burger/burger_bun_bottom.glb").instantiate()
		bun.add_child(bun_bottom)
		var bun_top = preload("res://assets/burger/burger_bun_top.glb").instantiate()
		bun.add_child(bun_top)
		bun_top.position.y = 0.018
	_setup_toppings(counter)
	_setup_produce_box(TOMATO_INDEX, "freezer_tomato", -9.75, "TOMATOES")
	_setup_produce_box(ONION_INDEX, "freezer_onion", -8.77, "ONIONS")
	_setup_produce_box(LETTUCE_INDEX, "freezer_lettuce", -7.84, "LETTUCE")
	_setup_produce_box(CHEESE_INDEX, "freezer_cheese", -10.40, "CHEESE")
	_setup_prep_sheet()
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

func _ingredient_group(tray: StaticBody3D) -> Node3D:
	var group := Node3D.new()
	group.name = "Ingredients"
	tray.add_child(group)
	ingredient_groups.append(group)
	return group

func _setup_toppings(counter: MeshInstance3D) -> void:
	for index in range(TOPPINGS.size()):
		var offset := Vector3(-0.40, 0.11, (1 - index) * 0.45)
		if TOPPINGS[index] == "Onion": offset = Vector3(0.30, 0.11, -0.44)
		var bin := _target("burger_topping", Vector3(-3.0946, 1.127, -12.4165) + offset, Vector3(0.48, 0.19, 0.44))
		if counter != null:
			bin.global_transform = counter.global_transform * Transform3D(Basis.IDENTITY, offset)
		bin.name = TOPPINGS[index] + "Bin"
		bin.set_meta("topping_index", index)
		shift._box(bin, Vector3(0, -0.065, 0), Vector3(0.47, 0.03, 0.43), Color(0.48, 0.51, 0.53))
		for x in [-0.23, 0.23]:
			shift._box(bin, Vector3(x, -0.04, 0), Vector3(0.015, 0.05, 0.43), Color(0.48, 0.51, 0.53))
		for z in [-0.21, 0.21]:
			shift._box(bin, Vector3(0, -0.04, z), Vector3(0.47, 0.05, 0.015), Color(0.48, 0.51, 0.53))
		var ingredients := _ingredient_group(bin)
		if index == TOMATO_INDEX: tomato_ingredients = ingredients
		if index == ONION_INDEX: onion_ingredients = ingredients
		if index == LETTUCE_INDEX: lettuce_ingredients = ingredients
		if index == CHEESE_INDEX: cheese_ingredients = ingredients
		if index == 0:
			for stack in [-1, 1]:
				for i in range(3):
					var cheese := _topping_mesh(ingredients, index, Vector3(i * 0.024 - 0.024, -0.048 + i * 0.0035, stack * 0.10 + i * 0.016))
					cheese.rotation.y = stack * 0.16 + i * 0.14
			continue
		if index == 1:
			for i in range(3):
				var leaf := _topping_mesh(ingredients, index, Vector3((i - 1) * 0.115, -0.038 + i * 0.006, (i % 2) * 0.065 - 0.03))
				leaf.rotation.y = (i - 1) * 0.68
			continue
		for row in range(3):
			for column in range(2):
				_topping_mesh(ingredients, index, Vector3((column - 0.5) * 0.16, -0.044 + row * 0.005, (row - 1) * 0.105))

func _setup_produce_box(index: int, action: String, z_position: float, label: String) -> void:
	var box := _target(action, Vector3(10.90, 1.24, z_position), Vector3(0.70, 0.39, 0.58))
	box.set_meta("topping_index", index)
	shift._box(box, Vector3(0, -0.12, 0), Vector3(0.67, 0.10, 0.55), Color("9a744b"))
	for x in [-0.32, 0.32]:
		shift._box(box, Vector3(x, 0, 0), Vector3(0.035, 0.20, 0.55), Color("a48259"))
	for z in [-0.26, 0.26]:
		shift._box(box, Vector3(0, 0, z), Vector3(0.67, 0.20, 0.035), Color("a48259"))
	var columns := [-0.14, 0.14] if index in [LETTUCE_INDEX, CHEESE_INDEX] else [-0.20, 0.0, 0.20]
	for x in columns:
		for z in [-0.11, 0.11]:
			produce_model(box, stock_item(index), Vector3(x, 0.015, z))
	shift._label(box, label, Vector3(0, 0.28, 0), 0.0016)

static func stock_item(index: int) -> String:
	return PRODUCE_ITEMS[PRODUCE_INDICES.find(index)]

static func produce_model(parent: Node3D, item: String, at := Vector3.ZERO) -> void:
	if item == CHEESE_STOCK:
		for index in range(5):
			var slice := _topping_mesh(parent, CHEESE_INDEX, at + Vector3(0.002 * index, 0.007 * index, 0))
			slice.scale = Vector3.ONE * 1.25
			slice.rotation.y = 0.04 * index
		return
	if item == LETTUCE_STOCK:
		_lettuce_head(parent, at)
		return
	var onion := item == ONION_STOCK
	var tomato := MeshInstance3D.new()
	var fruit := SphereMesh.new()
	fruit.radius = 0.077
	fruit.height = 0.14 if onion else 0.122
	fruit.radial_segments = 10
	fruit.rings = 5
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("884568") if onion else Color("bc382b")
	fruit.material = skin
	tomato.mesh = fruit
	parent.add_child(tomato)
	tomato.position = at
	var stem := MeshInstance3D.new()
	var cap := CylinderMesh.new()
	cap.top_radius = 0.017
	cap.bottom_radius = 0.027
	cap.height = 0.012
	cap.radial_segments = 5
	var green := StandardMaterial3D.new()
	green.albedo_color = Color("a98a59") if onion else Color("52703d")
	cap.material = green
	stem.mesh = cap
	tomato.add_child(stem)
	stem.position.y = 0.069 if onion else 0.060

static func _lettuce_head(parent: Node3D, at: Vector3) -> void:
	var head := MeshInstance3D.new()
	var core := SphereMesh.new()
	core.radius = 0.071
	core.height = 0.119
	core.radial_segments = 12
	core.rings = 6
	var leaf_green := StandardMaterial3D.new()
	leaf_green.albedo_color = Color("91ac43")
	leaf_green.roughness = 0.82
	core.material = leaf_green
	head.mesh = core
	parent.add_child(head)
	head.position = at + Vector3.UP * 0.022
	for layer in range(2):
		var leaf_count := 5 if layer == 0 else 3
		for index in range(leaf_count):
			var angle := TAU * float(index) / leaf_count + layer * 0.55
			var leaf := LETTUCE_LEAF.instantiate() as Node3D
			head.add_child(leaf)
			leaf.position = Vector3(sin(angle) * (0.032 - layer * 0.015), 0.018 + layer * 0.027, cos(angle) * (0.032 - layer * 0.015))
			leaf.rotation = Vector3(0.72 - layer * 0.38, angle, 0.10 * sin(index))
			leaf.scale = Vector3.ONE * (0.76 - layer * 0.18)

func missing_produce() -> String:
	if not tomatoes_stocked: return "tomato"
	if not onions_stocked: return "onion"
	if not lettuce_stocked: return "lettuce"
	if not cheese_stocked: return "cheese"
	return ""

func _produce_stocked(index: int) -> bool:
	match index:
		TOMATO_INDEX: return tomatoes_stocked
		ONION_INDEX: return onions_stocked
		LETTUCE_INDEX: return lettuce_stocked
		CHEESE_INDEX: return cheese_stocked
	return false

func produce_box_prompt(index: int) -> String:
	var name: String = TOPPINGS[index]
	if shift.phase != "prep" or shift.is_practicing(): return name + " stock · opening prep"
	if _produce_stocked(index): return name + " tray is stocked"
	return "[E] Take " + name.to_lower() + " for the burger station"

func take_produce(index: int) -> void:
	if shift.phase != "prep" or shift.is_practicing() or _produce_stocked(index): return
	var name: String = TOPPINGS[index].to_lower()
	if not shift.carried_item.is_empty() or shift.has_empty_cup() or shift.carrying_trash:
		shift._message("Free your hands before taking " + name + " stock.")
		return
	shift.carried_item = stock_item(index)
	shift._refresh_carried()
	shift._message("Take the " + name + " to its tray by the buns. Q returns it.")

func _setup_prep_sheet() -> void:
	var sheet := Node3D.new()
	sheet.name = "BurgerPrepSheet"
	add_child(sheet)
	sheet.global_position = Vector3(-3.73, 1.88, -12.42)
	sheet.rotation.y = PI / 2
	shift._box(sheet, Vector3.ZERO, Vector3(1.38, 0.68, 0.012), Color("eee2bc"))
	shift._box(sheet, Vector3(0, 0.227, 0.007), Vector3(1.38, 0.14, 0.002), Color("71382d"))
	_prep_sheet_label(sheet, "BURGER PREP", 0.228, 0.0020, Color("fff2ce"))
	_prep_sheet_label(sheet, "BURGER", 0.112, 0.0014, Color("40231c"))
	_prep_sheet_label(sheet, "Patty + bun", 0.055, 0.00125, Color("27261f"))
	_prep_sheet_label(sheet, "CHEESEBURGER", -0.023, 0.0014, Color("40231c"))
	_prep_sheet_label(sheet, "Patty + bun + cheese", -0.080, 0.00125, Color("27261f"))
	_prep_sheet_label(sheet, "DELUXE BURGER", -0.158, 0.0014, Color("40231c"))
	_prep_sheet_label(sheet, "Patty + bun + cheese + lettuce + tomato + onion", -0.215, 0.00125, Color("27261f"))

func _prep_sheet_label(sheet: Node3D, caption: String, y: float, pixel: float, ink: Color) -> void:
	var label: Label3D = shift._label(sheet, caption, Vector3(0, y, 0.010), pixel)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.outline_size = 0
	label.modulate = ink

func topping_prompt(index: int) -> String:
	if index in PRODUCE_INDICES and shift.phase == "prep" and not shift.is_practicing() and not _produce_stocked(index):
		var name: String = TOPPINGS[index].to_lower()
		return "[E] Stock " + name + " tray" if shift.carried_item == stock_item(index) else "Bring " + name + " stock from the freezer"
	var mask := BURGERS.find(shift.carried_item)
	if mask < 0: return TOPPINGS[index] + " — bring an assembled burger"
	if mask & (1 << index): return TOPPINGS[index] + " already added"
	return "[E] Add " + TOPPINGS[index].to_lower()

func add_topping(index: int) -> void:
	if not ingredients_visible: return
	if index in PRODUCE_INDICES and shift.phase == "prep" and not shift.is_practicing():
		if not _produce_stocked(index) and shift.carried_item == stock_item(index):
			match index:
				TOMATO_INDEX: tomatoes_stocked = true
				ONION_INDEX: onions_stocked = true
				LETTUCE_INDEX: lettuce_stocked = true
				CHEESE_INDEX: cheese_stocked = true
			shift._clear_carried(false)
			refresh()
			shift._message(TOPPINGS[index] + " tray stocked for the shift.")
		return
	var mask := BURGERS.find(shift.carried_item)
	if mask < 0:
		shift._message("Assemble a cooked patty and bun before adding toppings.")
		return
	var dressed := mask | (1 << index)
	if dressed == mask: return
	shift.carried_item = BURGERS[dressed]
	shift._refresh_carried()
	shift._message("Added " + TOPPINGS[index].to_lower() + " · " + shift.carried_item)

static func _topping_mesh(parent: Node3D, index: int, at: Vector3, on_burger := false) -> Node3D:
	if TOPPINGS[index] == "Onion":
		var slice := Node3D.new()
		slice.name = "OnionSlice"
		parent.add_child(slice)
		slice.position = at
		for radius in [0.049, 0.036, 0.023]:
			var mesh := TorusMesh.new()
			mesh.outer_radius = radius
			mesh.inner_radius = radius - 0.008
			mesh.rings = 20
			mesh.ring_segments = 8
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("b676a3") if radius > 0.04 else Color("ead5e4")
			material.roughness = 0.75
			mesh.material = material
			var ring := MeshInstance3D.new()
			ring.mesh = mesh
			ring.scale.y = 0.65
			slice.add_child(ring)
		return slice
	var scene: PackedScene
	match index:
		0: scene = CHEESE_DRAPED if on_burger else CHEESE_SLICE
		1: scene = LETTUCE_LEAF
		2: scene = TOMATO_SLICE
	var topping := scene.instantiate() as Node3D
	parent.add_child(topping)
	topping.position = at
	return topping

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
	if shift.phase not in ["waiting","arriving","leaving"] and not shift.is_practicing():
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
			shift._message("Burger assembled. Dress it at the bun counter. Deluxe gets cheese, lettuce, tomato and onion.")
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
	var stocked: bool = shift.phase not in ["cleanup", "closed", "game_over"]
	if ingredients_visible != stocked:
		ingredients_visible = stocked
		for group in ingredient_groups:
			group.visible = stocked
			group.get_parent().set_collision_layer_value(3, stocked)
	if is_instance_valid(tomato_ingredients):
		tomato_ingredients.visible = stocked and (tomatoes_stocked or shift.is_practicing())
	if is_instance_valid(onion_ingredients):
		onion_ingredients.visible = stocked and (onions_stocked or shift.is_practicing())
	if is_instance_valid(lettuce_ingredients):
		lettuce_ingredients.visible = stocked and (lettuce_stocked or shift.is_practicing())
	if is_instance_valid(cheese_ingredients):
		cheese_ingredients.visible = stocked and (cheese_stocked or shift.is_practicing())
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
	return {"cooking":cooking,"elapsed":elapsed,"flipped_at":flipped_at,"tomatoes_stocked":tomatoes_stocked,"onions_stocked":onions_stocked,"lettuce_stocked":lettuce_stocked,"cheese_stocked":cheese_stocked}

func restore(data: Dictionary) -> void:
	var in_service: bool = shift.phase in ["arriving", "waiting", "leaving", "robbery_cleanup"]
	tomatoes_stocked = data.get("tomatoes_stocked", in_service)
	onions_stocked = data.get("onions_stocked", in_service)
	lettuce_stocked = data.get("lettuce_stocked", in_service)
	cheese_stocked = data.get("cheese_stocked", in_service)
	if data.is_empty():
		reset()
		return
	cooking = data.cooking
	elapsed = data.elapsed
	flipped_at = data.flipped_at
	refresh()

static func model(parent: Node3D, item := "Burger") -> void:
	var bottom = preload("res://assets/burger/burger_bun_bottom.glb").instantiate()
	parent.add_child(bottom)
	var patty = preload("res://assets/burger/burger_patty_cooked.glb").instantiate()
	parent.add_child(patty)
	patty.position.y = 0.018
	var top = preload("res://assets/burger/burger_bun_top.glb").instantiate()
	parent.add_child(top)
	var height := 0.0405
	var mask := maxi(0, BURGERS.find(item))
	for index in range(TOPPINGS.size()):
		if mask & (1 << index):
			var offset := 0.003 if index == 1 else 0.0
			_topping_mesh(parent, index, Vector3(0, height + offset, 0), true)
			height += [0.006, 0.012, 0.010, 0.006][index]
	top.position.y = height
