extends Node3D

const PIE_NAMES := ["Meat pie", "Apple pie", "Cherry pie"]
const ORDERS := [["Meat pie", "Donut", "Coffee"], ["Apple pie", "Soda"], ["Cherry pie", "Donut", "Coffee"], ["Meat pie", "Soda"]]
var game: Node3D
var phase := "prep"
var tasks := {"bathroom": false, "kitchen": false, "trash": false}
var tray: Array[String] = []
var tray_sources: Array[Node3D] = []
var order: Array[String] = []
var order_taken := false
var customer: Node3D
var customer_visual: Node3D
var speech: Label3D
var limbs: Array[int] = []
var customer_skeleton: Skeleton3D
var limb_rest_rotations: Dictionary = {}
var route: Array[Vector3] = []
var route_index := 0
var walking := false
var angry := false
var served := 0
var lost := 0
var order_index := 0
var arrival_delay := 0.0
var animation_time := 0.0
var panel: Label
var notice: Label
var held_tray: Node3D
var task_nodes: Dictionary = {}
var carrying_trash := false
var cleaning_progress := 0.0
var cleaning_task := ""
var all_pies: Array[Node3D] = []
var notice_time := 0.0
var target: Node
var shift_number := 1
var customers_this_shift := 0
var hand_anchor: Node3D
var carried_item := ""
var carried_source: Node3D
var carried_visual: Node3D
var coffee_station: StaticBody3D
var soda_station: StaticBody3D
var service_bell: StaticBody3D

func setup(host: Node3D) -> void:
	game = host
	name = "ShiftScenario"
	_build_hud()
	_tag_pies()
	_make_station("donut", "DONUTS", Vector3(0.15, 1.46, -5.02), Color(0.85, 0.55, 0.23))
	_make_station("clock", "SHIFT BOARD", Vector3(-3.9, 1.3, -5.0), Color(0.2, 0.65, 0.43))
	_make_station("dispose", "REFUSE HATCH", Vector3(10.5, 1.05, 3.65), Color(0.48, 0.52, 0.53))
	_make_task("bathroom", "BATHROOM: hold E to scrub", Vector3(-7.15, -0.075, -10.1))
	_make_task("kitchen", "KITCHEN: hold E to scrub", Vector3(0, -0.075, -11.7))
	_make_task("trash", "TRASH: E to collect bag", Vector3(10.1, -0.075, 1.5))
	held_tray = Node3D.new()
	held_tray.name = "ServingTray"
	# Render held objects separately so nearby counters cannot hide the food.
	var tray_layer := CanvasLayer.new()
	tray_layer.layer = 0
	add_child(tray_layer)
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray_layer.add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var tray_camera := Camera3D.new()
	tray_camera.fov = game.camera.fov
	tray_camera.near = 0.01
	viewport.add_child(tray_camera)
	hand_anchor = Node3D.new()
	tray_camera.add_child(hand_anchor)
	carried_visual = Node3D.new()
	hand_anchor.add_child(carried_visual)
	carried_visual.position = Vector3(0.25, -0.32, -0.8)
	add_child(held_tray)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -25, 0)
	light.light_energy = 0.8
	viewport.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.85, 0.9, 1)
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	held_tray.position = Vector3(-3.1, 1.202, -4.4)
	var tray_body := StaticBody3D.new()
	tray_body.collision_layer = 4
	tray_body.set_meta("action", "tray")
	held_tray.add_child(tray_body)
	var tray_collision := CollisionShape3D.new()
	var tray_shape := BoxShape3D.new()
	tray_shape.size = Vector3(0.99, 0.24, 0.72)
	tray_collision.shape = tray_shape
	tray_collision.position.y = 0.1
	tray_body.add_child(tray_collision)
	call_deferred("_place_counter_tray")
	var tray_model: Node3D = preload("res://assets/tray/black_cafeteria_tray.glb").instantiate()
	tray_model.name = "BlackCafeteriaTray"
	held_tray.add_child(tray_model)
	tray_model.scale = Vector3.ONE * 1.95
	held_tray.visible = true
	coffee_station = preload("res://coffee_station.gd").new()
	add_child(coffee_station)
	coffee_station.setup(self)
	soda_station = preload("res://coffee_station.gd").new()
	soda_station.drink_name = "Soda"
	soda_station.machine_action = "soda"
	soda_station.stack_action = "soda_cup_stack"
	soda_station.station_position = Vector3(1.7, 1.40, -6.57)
	soda_station.built_in_cup_holder = true
	soda_station.stack_offset = Vector3(0, -0.50, 0.10)
	soda_station.fill_height = 0.205
	soda_station.fill_radius = 0.061
	soda_station.fill_seconds = 1.8
	soda_station.cup_color = Color(0.75, 0.10, 0.065)
	soda_station.band_color = Color(0.9, 0.88, 0.80)
	soda_station.liquid_color = Color(0.12, 0.055, 0.018)
	add_child(soda_station)
	soda_station.setup(self)
	# Replace the source model's decorative filled cups with the playable station.
	for node in game.find_children("*", "MeshInstance3D", true, false):
		if node.name in ["Tumbler", "Tumbler_01"]:
			node.visible = false
			for body in node.find_children("*", "StaticBody3D", true, false):
				body.collision_layer = 0
	service_bell = preload("res://service_bell.gd").new()
	add_child(service_bell)
	service_bell.setup(self)
	if "--customer-demo" in OS.get_cmdline_user_args():
		start_demo()
	else:
		begin_prep()

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var background := ColorRect.new()
	background.color = Color(0.025, 0.035, 0.045, 0.92)
	background.position = Vector2(824, 18)
	background.size = Vector2(438, 370)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	panel = Label.new()
	panel.position = Vector2(842, 32)
	panel.size = Vector2(402, 345)
	panel.add_theme_font_size_override("font_size", 19)
	panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	canvas.add_child(panel)
	notice = Label.new()
	notice.position = Vector2(24, 598)
	notice.size = Vector2(1190, 100)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size", 23)
	notice.add_theme_color_override("font_shadow_color", Color.BLACK)
	notice.add_theme_constant_override("shadow_offset_x", 2)
	notice.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(notice)

func _tag_pies() -> void:
	all_pies.clear()
	for pie in game.find_children("Pie_*", "Node3D", true, false):
		if pie is Sprite3D or not pie.name.get_slice("_", 1).is_valid_int():
			continue
		var column := int(pie.name.get_slice("_", 3))
		pie.set_meta("action", "pie")
		pie.set_meta("item", PIE_NAMES[column])
		all_pies.append(pie)
	var interior := game.find_child("PieCoolerInterior", true, false)
	for row in range(4):
		for column in range(3):
			_label(interior, PIE_NAMES[column].to_upper(), Vector3(0.68 + column * 0.56, 0.17 + row * 0.52, -8.91), 0.0012)

func _make_station(action: String, title: String, location: Vector3, color: Color) -> void:
	var node := StaticBody3D.new()
	node.name = "Station_" + action
	node.collision_layer = 4
	add_child(node)
	node.position = location
	node.set_meta("action", action)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.42, 0.28, 0.3)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	node.add_child(collider)
	_box(node, Vector3(0, -0.12, 0), Vector3(0.45, 0.035, 0.32), color)
	_label(node, title, Vector3(0, 0.24, 0), 0.0018)
	if action in ["coffee", "soda", "donut"]:
		_item_model(node, {"coffee": "Coffee", "soda": "Soda", "donut": "Donut"}[action], Vector3(0, -0.09, 0), 1.0)
	elif action == "dispose":
		_box(node, Vector3.ZERO, Vector3(0.4, 0.24, 0.05), color)

func _make_task(id: String, title: String, location: Vector3) -> void:
	var node := StaticBody3D.new()
	node.collision_layer = 4
	node.set_meta("action", "task")
	node.set_meta("task", id)
	add_child(node)
	node.position = location
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.4, 1.0)
	collider.shape = shape
	collider.position.y = 0.2
	node.add_child(collider)
	if id == "trash":
		var bag := SphereMesh.new()
		bag.radius = 0.22
		bag.height = 0.52
		_mesh(node, bag, Vector3(0, 0.26, 0), Color(0.045, 0.05, 0.04))
	else:
		for i in range(5):
			var stain := CylinderMesh.new()
			stain.top_radius = 0.16 + i * 0.025
			stain.bottom_radius = stain.top_radius
			stain.height = 0.006
			stain.radial_segments = 10
			_mesh(node, stain, Vector3(sin(i * 2.1) * 0.3, 0.005 + i * 0.0004, cos(i * 1.7) * 0.3), Color(0.21, 0.16, 0.075))
	_label(node, title, Vector3(0, 0.65, 0), 0.0015)
	task_nodes[id] = node

func begin_prep() -> void:
	if phase != "prep": shift_number += 1
	_reset_customer()
	_clear_tray(true)
	phase = "prep"
	carrying_trash = false
	cleaning_progress = 0.0
	for id in tasks:
		tasks[id] = false
		task_nodes[id].visible = true
		task_nodes[id].collision_layer = 4
	_reset_stock()
	_open_staff_doors()
	_message("Before opening: clean the bathroom and kitchen, then take the trash to the refuse hatch inside the diner.")

func start_demo() -> void:
	_reset_customer()
	_clear_tray(true)
	for id in tasks:
		tasks[id] = true
		task_nodes[id].visible = false
		task_nodes[id].collision_layer = 0
	_reset_stock()
	order_index = 0
	shift_number = 1
	served = 0
	lost = 0
	_open_staff_doors()
	start_shift()
	game.spawn_point = Vector3(-2.4, 0.03, -5.8)
	game.player.position = game.spawn_point
	game.player.rotation.y = PI
	game.camera.rotation = Vector3.ZERO
	game.pitch = 0.0
	_message("CUSTOMER DEMO: E to take the order. Pick up each item and click the counter tray to place it. Ring the counter bell to submit the completed tray.")

func _open_staff_doors() -> void:
	for door in game.doors:
		if door.name in ["Door", "Door_01"] and not door.get_meta("open"):
			game._toggle_door(door)

func start_shift() -> bool:
	for done in tasks.values():
		if not done:
			_message("Finish all three daily tasks before opening the shift.")
			return false
	phase = "arriving"
	customers_this_shift = 0
	arrival_delay = 1.2
	return true

func _spawn_customer() -> void:
	_reset_customer()
	order.assign(ORDERS[order_index % ORDERS.size()])
	order_taken = false
	angry = false
	customer = Node3D.new()
	customer.name = "Customer"
	add_child(customer)
	customer.position = Vector3(0.76, -0.094, 5.0)
	customer_visual = load("res://assets/customer/customer.glb").instantiate()
	customer.add_child(customer_visual)
	customer_visual.scale = Vector3.ONE * 1.2
	limbs.clear()
	limb_rest_rotations.clear()
	for node in customer_visual.find_children("*", "Node3D", true, false):
		if node is Skeleton3D:
			customer_skeleton = node
			for bone_name in ["Arm_L", "Arm_R", "Leg_L", "Leg_R"]:
				var bone_id: int = node.find_bone(bone_name)
				if bone_id >= 0:
					limbs.append(bone_id)
					limb_rest_rotations[bone_id] = node.get_bone_pose_rotation(bone_id)
	var body := StaticBody3D.new()
	body.collision_layer = 5
	body.set_meta("action", "customer")
	customer.add_child(body)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 2.15
	collider.shape = shape
	collider.position.y = 1.075
	body.add_child(collider)
	speech = _label(customer, "CUSTOMER", Vector3(0, 2.45, 0), 0.0021)
	_set_route([Vector3(0.76, -0.094, 0.2), Vector3(-2.4, -0.094, -3.6)])
	for door in game.doors:
		if door.name == "Door_03" and not door.get_meta("open"):
			game._toggle_door(door)

func _set_route(points: Array[Vector3]) -> void:
	route = points
	route_index = 0
	walking = true

func _process(delta: float) -> void:
	if not is_instance_valid(game):
		return
	animation_time += delta
	if notice_time > 0:
		notice_time -= delta
		if notice_time <= 0:
			notice.text = ""
	if arrival_delay > 0:
		arrival_delay -= delta
		if arrival_delay <= 0:
			_spawn_customer()
	if is_instance_valid(customer) and walking:
		var goal := route[route_index]
		var speed := 3.1 if angry else 1.25
		var movement := goal - customer.position
		if movement.length() < speed * delta:
			customer.position = goal
			route_index += 1
			if route_index >= route.size():
				walking = false
				if phase == "leaving":
					_reset_customer()
					if customers_this_shift >= 4:
						phase = "closed"
						_message("SHIFT COMPLETE! Happy: %d, lost: %d. F7 begins the next shift's daily tasks." % [served, lost])
					else:
						phase = "arriving"
						arrival_delay = 2.0
				else:
					phase = "waiting"
					customer.rotation.y = PI
					speech.text = "E: TAKE MY ORDER"
		else:
			customer.position += movement.normalized() * speed * delta
			customer.rotation.y = atan2(movement.x, movement.z)
		if is_instance_valid(customer_visual):
			customer_visual.position.y = absf(sin(animation_time * speed * 8)) * 0.018
			_pose_customer(sin(animation_time * speed * 7))
	elif is_instance_valid(customer_visual):
		customer_visual.position.y = 0
		_pose_customer(0)
	_update_cleaning(delta)
	_update_panel()

func _pose_customer(stride: float) -> void:
	if not is_instance_valid(customer_skeleton): return
	for bone_id in limbs:
		var bone_name := customer_skeleton.get_bone_name(bone_id)
		var amplitude := 0.16 if bone_name.begins_with("Arm") else 0.29
		var angle := stride * amplitude * (-1.0 if bone_name in ["Arm_L", "Leg_R"] else 1.0)
		var rest := customer_skeleton.get_bone_global_rest(bone_id).basis.get_rotation_quaternion()
		var baseline: Quaternion = limb_rest_rotations[bone_id]
		customer_skeleton.set_bone_pose_rotation(bone_id, baseline * rest.inverse() * Quaternion(Vector3.RIGHT, angle) * rest)

func _update_cleaning(delta: float) -> void:
	if phase != "prep" or not is_instance_valid(target) or not target.has_meta("task") or not Input.is_physical_key_pressed(KEY_E) or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		cleaning_progress = 0
		return
	var id: String = target.get_meta("task")
	if id == "trash" or tasks[id]:
		return
	if cleaning_task != id:
		cleaning_task = id
		cleaning_progress = 0
	cleaning_progress += delta
	game.interaction_label.text = "Cleaning %s... %d%%" % [id, mini(100, int(cleaning_progress / 1.5 * 100))]
	if cleaning_progress >= 1.5:
		complete_task(id)

func complete_task(id: String) -> void:
	tasks[id] = true
	task_nodes[id].visible = false
	task_nodes[id].collision_layer = 0
	cleaning_progress = 0
	_message(id.capitalize() + " done. Use the shift board behind the counter when all tasks are complete.")

func action_prompt(node: Node) -> String:
	var action: String = node.get_meta("action", "")
	match action:
		"pie": return "[Click / E] Pick up " + str(node.get_meta("item"))
		"donut": return "[Click / E] Pick up " + action.capitalize()
		"tray": return "[Click / E] Place " + carried_item + " on tray" if not carried_item.is_empty() else "[Click / E] Take last item off tray" if not tray.is_empty() else "Serving tray - bring the customer's items here"
		"coffee", "cup_stack": return coffee_station.prompt(action)
		"soda", "soda_cup_stack": return soda_station.prompt(action)
		"bell": return "[Click / E] Ding bell and serve the tray"
		"customer":
			if phase != "waiting": return "Customer is leaving" if phase == "leaving" else "Customer is approaching"
			return "[E] " + ("Hear order again - ring bell to serve" if order_taken else "Take customer's order")
		"task": return "[E] Collect trash bag" if node.get_meta("task") == "trash" else "Hold [E] to clean " + str(node.get_meta("task"))
		"dispose": return "[E] Dispose of trash bag" if carrying_trash else "Refuse hatch - collect the trash bag first"
		"clock": return "[E] Open shift" if phase == "prep" else "[E] Start next shift's daily tasks"
	return ""

func interact(node: Node) -> void:
	var action: String = node.get_meta("action", "")
	match action:
		"pie": pickup_item(str(node.get_meta("item")), node)
		"donut": pickup_item(action.capitalize())
		"tray":
			if not carried_item.is_empty(): place_carried()
			elif not tray.is_empty() and not has_empty_cup():
				carried_item = tray.pop_back()
				carried_source = tray_sources.pop_back()
				_refresh_tray()
				_refresh_carried()
		"coffee", "cup_stack": coffee_station.interact(action)
		"soda", "soda_cup_stack": soda_station.interact(action)
		"bell": service_bell.ring()
		"customer":
			if phase != "waiting": return
			order_taken = true
			speech.text = "I'd like " + ", ".join(order) + ", please."
			_message("CUSTOMER: " + ", ".join(order) + ". Place everything on the counter tray, then ring the bell to serve.")
		"task":
			if phase != "prep": return
			if node.get_meta("task") == "trash":
				carrying_trash = true
				node.visible = false
				node.collision_layer = 0
				_message("Trash collected. Carry it to the REFUSE HATCH on the right side of the dining room.")
		"dispose":
			if carrying_trash:
				carrying_trash = false
				complete_task("trash")
		"clock":
			if phase == "prep": start_shift()
			else: begin_prep()

func add_item(item: String, source: Node3D = null) -> bool:
	if phase not in ["waiting", "arriving"]:
		_message("Start a shift before preparing orders.")
		return false
	if tray.size() >= 6:
		_message("Your tray is full. Q removes the last item.")
		return false
	tray.append(item)
	tray_sources.append(source)
	if is_instance_valid(source):
		_set_pickup_visible(source, false)
	_refresh_tray()
	_message("Added " + item + ". Q removes the last item; Ring the bell to submit the whole tray.")
	return true

func discard_last() -> void:
	if coffee_station.return_empty() or soda_station.return_empty(): return
	if not carried_item.is_empty():
		_clear_carried(true)
		_message("Held item returned / set aside.")
		return
	if tray.is_empty(): return
	var item: String = tray.pop_back()
	var source: Node3D = tray_sources.pop_back()
	if is_instance_valid(source): _set_pickup_visible(source, true)
	_refresh_tray()
	_message("Removed " + item + " from tray.")

func serve_order() -> bool:
	if not carried_item.is_empty() or has_empty_cup():
		_message("Place the held item on the counter tray, or return it, before serving.")
		return false
	if phase != "waiting" or not order_taken or tray.is_empty(): return false
	var expected := order.duplicate()
	var actual := tray.duplicate()
	expected.sort()
	actual.sort()
	var correct := expected == actual
	angry = not correct
	if correct:
		served += 1
		speech.text = "Perfect! Thank you!"
		speech.modulate = Color(0.55, 1, 0.65)
		_message("CORRECT ORDER! The customer leaves happy.")
	else:
		lost += 1
		speech.text = "That's NOT what I ordered!"
		speech.modulate = Color(1, 0.35, 0.25)
		_message("WRONG ORDER! Customer wanted " + ", ".join(order) + ". They are storming out.")
	_clear_tray(false)
	phase = "leaving"
	customers_this_shift += 1
	order_index += 1
	if is_instance_valid(customer):
		_set_route([Vector3(-2.4, -0.094, -0.2), Vector3(0.76, -0.094, 0.2), Vector3(0.76, -0.094, 6.1)])
	return correct

func _clear_tray(restore: bool) -> void:
	_clear_carried(restore)
	if restore:
		for source in tray_sources:
			if is_instance_valid(source): _set_pickup_visible(source, true)
	tray.clear()
	tray_sources.clear()
	if is_instance_valid(held_tray): _refresh_tray()

func _refresh_tray() -> void:
	for node in held_tray.get_children():
		if node.has_meta("held_item"):
			held_tray.remove_child(node)
			node.queue_free()
	held_tray.visible = true
	for index in range(tray.size()):
		var item := Node3D.new()
		item.set_meta("held_item", true)
		held_tray.add_child(item)
		var height := 0.004 if tray[index].ends_with("pie") else 0.014
		_item_model(item, tray[index], Vector3(-0.275 + (index % 3) * 0.275, height, -0.14 + (index / 3) * 0.28), 0.95)

func _set_pickup_visible(node: Node3D, shown: bool) -> void:
	node.visible = shown
	for body in node.find_children("*", "StaticBody3D", true, false):
		body.collision_layer = 1 if shown else 0

func _reset_stock() -> void:
	if is_instance_valid(coffee_station): coffee_station.reset_station()
	if is_instance_valid(soda_station): soda_station.reset_station()
	for pie in all_pies: _set_pickup_visible(pie, true)

func _reset_customer() -> void:
	walking = false
	arrival_delay = 0
	limbs.clear()
	if is_instance_valid(customer):
		remove_child(customer)
		customer.queue_free()
	customer = null
	customer_visual = null
	customer_skeleton = null

func _message(text: String) -> void:
	notice.text = text
	notice_time = 9.0

func _update_panel() -> void:
	var text := "PIEDAY  /  SHIFT %02d\n" % shift_number
	if phase == "prep":
		text += "BEFORE OPENING\n"
		for id in tasks:
			text += ("[DONE] " if tasks[id] else "[  ] ") + id.capitalize() + "\n"
		if carrying_trash: text += "Carrying trash -> refuse hatch\n"
		text += "Finish tasks, then E at SHIFT BOARD."
	else:
		text += "Happy: %d   Lost: %d\n" % [served, lost]
		if order_taken and phase == "waiting": text += "ORDER: " + ", ".join(order) + "\n"
		elif phase == "waiting": text += "Customer waiting - E to take order\n"
		elif phase == "leaving": text += "Customer leaving...\n"
		elif phase == "closed": text += "SHIFT COMPLETE - F7 to prepare next\n"
		else: text += "Customer arriving...\n"
		text += "TRAY: " + (", ".join(tray) if not tray.is_empty() else "Empty") + "\n"
		text += "Pies: cooler (meat / apple / cherry).\nSoda cups: dispenser's front holder.\nDrinks: empty cup -> fill -> tray.\nRING THE BELL TO SERVE.\n"
		if not carried_item.is_empty(): text += "HAND: " + carried_item + " -> counter tray\n"
		elif has_empty_cup(): text += "HAND: EMPTY CUP\n"
		elif coffee_station.state == "brewing": text += "COFFEE: filling...\n"
		elif coffee_station.state == "ready": text += "COFFEE: ready to collect\n"
		elif soda_station.state == "brewing": text += "SODA: filling...\n"
		elif soda_station.state == "ready": text += "SODA: ready to collect\n"
	text += "\nQ remove item  |  F6 customer demo\nF7 new shift with daily tasks"
	panel.text = text

func _item_model(parent: Node3D, item: String, at: Vector3, size: float) -> void:
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = at
	holder.scale = Vector3.ONE * size
	if item.ends_with("pie"):
		var pie = load("res://assets/pies/pie_ps2.glb").instantiate()
		holder.add_child(pie)
	elif item in ["Coffee", "Soda"] and is_instance_valid(coffee_station):
		var station: StaticBody3D = coffee_station if item == "Coffee" else soda_station
		var cup: Node3D = station._cup(holder)
		station._cylinder(cup, station.fill_radius, 0.003, Vector3(0, station.fill_height, 0), station.liquid_color)
	elif item == "Donut":
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.035
		mesh.outer_radius = 0.10
		mesh.rings = 16
		mesh.ring_segments = 8
		_mesh(holder, mesh, Vector3(0, 0.03, 0), Color(0.68, 0.33, 0.10))
	else:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.055
		mesh.bottom_radius = 0.045
		mesh.height = 0.17
		mesh.radial_segments = 12
		_mesh(holder, mesh, Vector3(0, 0.085, 0), Color(0.75, 0.12, 0.065) if item == "Soda" else Color(0.88, 0.8, 0.62))
		var lid := CylinderMesh.new()
		lid.top_radius = 0.058
		lid.bottom_radius = 0.058
		lid.height = 0.012
		lid.radial_segments = 12
		_mesh(holder, lid, Vector3(0, 0.175, 0), Color(0.6, 0.63, 0.65) if item == "Soda" else Color(0.13, 0.085, 0.04))

func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	node.material_override = material
	parent.add_child(node)
	node.position = at
	return node

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_mesh(parent, mesh, at, color)

func _label(parent: Node3D, text: String, at: Vector3, pixel: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 40
	label.pixel_size = pixel
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	label.position = at
	return label

func _place_counter_tray() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var at := held_tray.global_position
	# Clear small imported garnish props from the serving space.
	var space := AABB(at + Vector3(-0.50, -0.04, -0.37), Vector3(1.0, 0.7, 0.74))
	for node in game.find_children("*", "MeshInstance3D", true, false):
		if not str(node.get_path()).contains("/DINER/"): continue
		var box: AABB = node.global_transform * node.mesh.get_aabb()
		if box.size.x < 0.8 and box.size.z < 0.8 and box.intersects(space):
			node.global_position.x += 2.0
	await get_tree().physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, 2, at.z), Vector3(at.x, 0.2, at.z), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): held_tray.global_position.y = hit.position.y + 0.006

func pickup_item(item: String, source: Node3D = null) -> bool:
	if phase not in ["waiting", "arriving"]:
		_message("Open the shift before preparing an order.")
		return false
	if not carried_item.is_empty() or has_empty_cup():
		_message("Your hand is full. Place the held item on the counter tray first.")
		return false
	carried_item = item
	carried_source = source
	if is_instance_valid(source): _set_pickup_visible(source, false)
	_refresh_carried()
	_message("Picked up " + item + ". Click the tray on the counter to place it.")
	return true

func place_carried() -> bool:
	if carried_item.is_empty(): return false
	if not add_item(carried_item, carried_source): return false
	_clear_carried(false)
	_message("Item placed on the counter tray. Ring the bell when the order is complete.")
	return true

func _clear_carried(restore: bool) -> void:
	if restore and is_instance_valid(carried_source): _set_pickup_visible(carried_source, true)
	carried_item = ""
	carried_source = null
	_refresh_carried()

func _refresh_carried() -> void:
	if not is_instance_valid(carried_visual): return
	for child in carried_visual.get_children():
		carried_visual.remove_child(child)
		child.queue_free()
	if not carried_item.is_empty(): _item_model(carried_visual, carried_item, Vector3.ZERO, 0.95)

func has_empty_cup() -> bool:
	return (is_instance_valid(coffee_station) and coffee_station.holding_empty) or (is_instance_valid(soda_station) and soda_station.holding_empty)
