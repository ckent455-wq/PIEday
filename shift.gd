extends Node3D

const PIE_NAMES := ["Meat pie", "Apple pie", "Cherry pie"]
const SHIRT_COLORS := [Color(0.12,0.32,0.42), Color(0.48,0.12,0.10), Color(0.18,0.35,0.17), Color(0.48,0.32,0.10), Color(0.32,0.18,0.40), Color(0.60,0.53,0.39), Color(0.21,0.22,0.25), Color(0.57,0.30,0.23)]
var last_shirt_color := -1
const ORDERS := [["Meat pie", "Donut", "Coffee"], ["Apple pie", "Soda"], ["Cherry pie", "Donut", "Coffee"], ["Apple pie", "Donut", "Coffee"], ["Meat pie", "Soda"], ["Cherry pie", "Soda"]]
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
var notice: Label
var held_tray: Node3D
var task_nodes: Dictionary = {}
var carrying_trash := false
var held_trash: Node3D
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
var oven: StaticBody3D
var earnings := preload("res://earnings.gd").new()
var service_seconds := 0.0
var payment_label: Label
var payment_time := 0.0
var cash_label: Label
const SHIFT_SECONDS := 300.0
var shift_remaining := SHIFT_SECONDS
var closing_time := false
var shift_clock: Label
var customer_line: Node
var closing_events: Node3D

func setup(host: Node3D) -> void:
	game = host
	name = "ShiftScenario"
	_build_hud()
	_tag_pies()
	_setup_donut_case()
	_make_shift_board()
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
	held_trash = preload("res://assets/trashbag/trashbag_a.glb").instantiate()
	held_trash.name = "HeldTrashBag"
	hand_anchor.add_child(held_trash)
	held_trash.position = Vector3(0.45, -0.72, -1.2)
	held_trash.scale = Vector3.ONE * 1.25
	held_trash.visible = false
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
	coffee_station.easy_coffee = true
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
	# Rest on the dispenser's recessed drip tray, directly below a nozzle.
	soda_station.cup_position = Vector3(0.126, -0.195, -0.48)
	soda_station.spout_position = Vector3(0.126, 0.358, -0.48)
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
	oven = preload("res://oven.gd").new()
	add_child(oven)
	oven.setup(self)
	customer_line = preload("res://customer_line.gd").new()
	customer_line.shift = self
	add_child(customer_line)
	closing_events = preload("res://closing_events.gd").new()
	add_child(closing_events)
	closing_events.setup(self)
	if "--closing-demo" in OS.get_cmdline_user_args():
		begin_cleanup()
		game.spawn_point = Vector3(-0.6, 0.03, -11.7)
		game.player.position = game.spawn_point
		game.player.rotation = Vector3.ZERO
		game.camera.rotation = Vector3.ZERO
	elif "--refusal-demo" in OS.get_cmdline_user_args():
		start_demo()
		customer_line.force_nude_next = true
		_message("REFUSAL DEMO: Wait for the customer to reach the counter, then face them and press E to refuse service. Clothing is required.")
	elif "--customer-demo" in OS.get_cmdline_user_args():
		start_demo()
	else:
		begin_prep()

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	notice = Label.new()
	notice.position = Vector2(24, 598)
	notice.size = Vector2(1190, 100)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size", 23)
	notice.add_theme_color_override("font_shadow_color", Color.BLACK)
	notice.add_theme_constant_override("shadow_offset_x", 2)
	notice.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(notice)
	payment_label = Label.new()
	payment_label.position = Vector2(24, 510)
	payment_label.add_theme_font_size_override("font_size", 25)
	payment_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	payment_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	payment_label.add_theme_constant_override("shadow_offset_x", 2)
	payment_label.add_theme_constant_override("shadow_offset_y", 2)
	payment_label.visible = false
	canvas.add_child(payment_label)
	cash_label = Label.new()
	cash_label.position = Vector2(24, 20)
	cash_label.add_theme_font_size_override("font_size", 30)
	cash_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.70))
	cash_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	cash_label.add_theme_constant_override("shadow_offset_x", 2)
	cash_label.add_theme_constant_override("shadow_offset_y", 2)
	cash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(cash_label)
	_update_cash_display()
	shift_clock = Label.new()
	shift_clock.position = Vector2(24, 58)
	shift_clock.add_theme_font_size_override("font_size", 21)
	shift_clock.add_theme_color_override("font_shadow_color", Color.BLACK)
	shift_clock.add_theme_constant_override("shadow_offset_x", 2)
	shift_clock.add_theme_constant_override("shadow_offset_y", 2)
	shift_clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shift_clock)
	_update_shift_clock()

func _update_shift_clock() -> void:
	if phase == "prep": shift_clock.text = "READY TO OPEN"
	elif phase == "cleanup": shift_clock.text = "AFTER HOURS - CLEANUP"
	elif phase == "closed": shift_clock.text = "CLOSED"
	else:
		var seconds := int(ceil(shift_remaining))
		shift_clock.text = "SHIFT  %d:%02d" % [seconds / 60, seconds % 60]
	shift_clock.modulate = Color(1, 0.7, 0.4) if closing_time else Color.WHITE

func _finish_day() -> void:
	begin_cleanup()

func _show_day_summary() -> void:
	earnings.finish_day()
	_update_cash_display()
	phase = "closed"
	closing_events.reset()
	arrival_delay = 0
	_message("SHIFT COMPLETE! Sales: $%d | Tips: $%d | Service: $%d | Streak: $%d\nClosing bonus: $%d | Today: $%d | Cash: $%d\n%s" % [earnings.sales, earnings.tips, earnings.service_rewards, earnings.streak_rewards, earnings.closing_bonus, earnings.day_total(), earnings.cash, "TREATMENT FUNDED! You have saved enough for Grandpa." if earnings.cash >= earnings.TREATMENT_GOAL else "Use the shift clipboard to begin the next day."])
	notice_time = 0
	_update_shift_clock()

func _update_cash_display() -> void:
	if is_instance_valid(cash_label): cash_label.text = "CASH  $%d / $15,000" % earnings.cash

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

func _setup_donut_case() -> void:
	# Use the actual case, trays and displayed donuts as pickup targets.
	for mesh in game.find_children("*", "MeshInstance3D", true, false):
		if mesh.name == "Showcase" or mesh.name.begins_with("Donus") or mesh.name in ["Tray_04", "Tray_03", "Tray_02", "Tray_01_001"]:
			mesh.set_meta("action", "donut")
		if mesh.name == "Showcase":
			for surface in range(mesh.mesh.get_surface_count()):
				var original: Material = mesh.get_active_material(surface)
				if original.resource_name != "Glass": continue
				var glass := StandardMaterial3D.new()
				glass.resource_name = "Donut case clear glass"
				glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				glass.albedo_color = Color(0.82, 0.94, 1.0, 0.10)
				glass.roughness = 0.08
				glass.metallic_specular = 0.35
				glass.cull_mode = BaseMaterial3D.CULL_DISABLED
				mesh.set_surface_override_material(surface, glass)

func _make_shift_board() -> void:
	var node := StaticBody3D.new()
	node.name = "Station_clock"
	node.collision_layer = 4
	add_child(node)
	# The dining-room side of this wall faces +X at x = -3.7496.
	node.position = Vector3(-3.735, 2.05, -5.0)
	node.set_meta("action", "clock")
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.10, 0.80, 0.54)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.x = 0.04
	node.add_child(collider)
	var clipboard: Node3D = preload("res://assets/clipboard/shift_clipboard.glb").instantiate()
	clipboard.name = "ShiftClipboard"
	node.add_child(clipboard)
	clipboard.rotation.y = PI / 2

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
		var bag: Node3D = preload("res://assets/trashbag/trashbag_a.glb").instantiate()
		bag.name = "MorningTrashBag"
		bag.scale = Vector3.ONE * 1.55
		node.add_child(bag)
		shape.size = Vector3(0.95, 0.90, 0.95)
		collider.position.y = 0.45
		for mesh in bag.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var material = mesh.get_active_material(surface)
				if material is BaseMaterial3D:
					material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	else:
		for i in range(5):
			var stain := CylinderMesh.new()
			stain.top_radius = 0.16 + i * 0.025
			stain.bottom_radius = stain.top_radius
			stain.height = 0.006
			stain.radial_segments = 10
			_mesh(node, stain, Vector3(sin(i * 2.1) * 0.3, 0.005 + i * 0.0004, cos(i * 1.7) * 0.3), Color(0.21, 0.16, 0.075))
	_label(node, title, Vector3(0, 1.0 if id == "trash" else 0.65, 0), 0.0015)
	task_nodes[id] = node

func begin_prep() -> void:
	if is_instance_valid(customer_line): customer_line.nude_chance = 0.08
	if is_instance_valid(closing_events): closing_events.reset()
	if is_instance_valid(customer_line): customer_line.clear_all()
	if phase != "prep": shift_number += 1
	_reset_customer()
	_clear_tray(true)
	phase = "prep"
	closing_time = false
	shift_remaining = SHIFT_SECONDS
	_update_shift_clock()
	_set_carrying_trash(false)
	cleaning_progress = 0.0
	for id in tasks:
		tasks[id] = true
		task_nodes[id].visible = false
		task_nodes[id].collision_layer = 0
	_reset_stock()
	_open_staff_doors()
	game.set_night(false)
	_message("Ready for the day. Use the shift clipboard to open the diner.")

func begin_cleanup() -> void:
	if is_instance_valid(customer_line): customer_line.evacuate()
	_reset_customer()
	walking = false
	order_taken = false
	order.clear()
	_clear_tray(true)
	arrival_delay = 0
	phase = "cleanup"
	closing_time = true
	_set_carrying_trash(false)
	cleaning_progress = 0
	for id in tasks:
		tasks[id] = false
		task_nodes[id].visible = true
		task_nodes[id].collision_layer = 4
	game.set_night(true)
	closing_events.begin()
	_update_shift_clock()
	_message("DINER CLOSED! Customers are heading out. Clean the bathroom and kitchen, then take the trash outside to the dumpster.")

func start_demo() -> void:
	customer_line.nude_chance = 0.0
	customer_line.force_nude_next = false
	if is_instance_valid(closing_events): closing_events.reset()
	if is_instance_valid(customer_line): customer_line.clear_all()
	game.set_night(false)
	_set_carrying_trash(false)
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
	phase = "prep"
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
	if phase != "prep": return false
	for done in tasks.values():
		if not done:
			_message("Finish all three daily tasks before opening the shift.")
			return false
	phase = "arriving"
	closing_time = false
	shift_remaining = SHIFT_SECONDS
	_update_shift_clock()
	earnings.start_day()
	service_seconds = 0
	payment_label.visible = false
	customers_this_shift = 0
	arrival_delay = 0.25
	_message("SHIFT OPEN! A customer is on the way. Take their order at the counter.")
	return true

func _spawn_customer() -> void:
	if phase in ["cleanup", "closed"] or closing_time: return
	if is_instance_valid(customer): return
	var queued: bool = not customer_line.waiting.is_empty()
	_reset_customer()
	order.assign(ORDERS[order_index % ORDERS.size()])
	order_taken = false
	angry = false
	customer = customer_line.pop_front() if queued else customer_line.make_actor(Vector3(0.76,-0.094,5))
	customer.name = "Customer"
	if customer.get_meta("requires_refusal", false): order.clear()
	customer_visual = customer.get_node("Visual")
	customer_visual.rotation.z = 0
	phase = "arriving"
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
	customer.get_node("Interaction").set_meta("action", "customer")
	speech = _label(customer, "CUSTOMER", Vector3(0, 2.45, 0), 0.0021)
	if customer.position.z <= 0.2:
		_set_route([Vector3(-2.4,-0.094,-3.6)])
	else:
		_set_route([Vector3(0.76,-0.094,0.2),Vector3(-2.4,-0.094,-3.6)])
	for door in game.doors:
		if door.name == "Door_03" and not door.get_meta("open"):
			game._toggle_door(door)

func _randomize_customer_shirt(visual: Node3D = null) -> void:
	if not is_instance_valid(visual): visual = customer_visual
	var index := randi_range(0, SHIRT_COLORS.size() - 1)
	if last_shirt_color >= 0:
		index = (last_shirt_color + 1 + randi_range(0, SHIRT_COLORS.size() - 2)) % SHIRT_COLORS.size()
	last_shirt_color = index
	for mesh in visual.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.get_active_material(surface)
			if original is StandardMaterial3D and original.resource_name.to_lower().begins_with("shirt"):
				var shirt: StandardMaterial3D = original.duplicate()
				shirt.albedo_color = SHIRT_COLORS[index]
				mesh.set_surface_override_material(surface, shirt)

func _set_route(points: Array[Vector3]) -> void:
	route = points
	route_index = 0
	walking = true

func _process(delta: float) -> void:
	if not is_instance_valid(game):
		return
	animation_time += delta
	closing_events.tick(delta)
	if phase in ["arriving", "waiting", "leaving"] and not closing_time:
		shift_remaining = maxf(0.0, shift_remaining - delta)
		if shift_remaining <= 0:
			begin_cleanup()
	customer_line.tick(delta)
	if phase in ["arriving","waiting","leaving"] and not is_instance_valid(customer):
		if not customer_line.waiting.is_empty(): _spawn_customer()
	_update_shift_clock()
	if phase == "waiting" and order_taken: service_seconds += delta
	if payment_time > 0:
		payment_time -= delta
		if payment_time <= 0: payment_label.visible = false
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
		var speed := (6.5 if angry else 5.5) if phase == "leaving" else 4.0
		var movement := goal - customer.position
		if movement.length() < speed * delta:
			customer.position = goal
			route_index += 1
			if route_index >= route.size():
				walking = false
				phase = "waiting"
				customer.rotation.y = PI
				speech.text = "CLOTHING REQUIRED - E: REFUSE SERVICE" if refusal_required() else "E: TAKE MY ORDER"
		else:
			customer.position += movement.normalized() * speed * delta
			customer.rotation.y = atan2(movement.x, movement.z)
		if is_instance_valid(customer_visual):
			var gait_speed := minf(speed, 2.5)
			customer_visual.position.y = absf(sin(animation_time * gait_speed * 8)) * 0.018
			_pose_customer(sin(animation_time * gait_speed * 7))
	elif is_instance_valid(customer_visual):
		customer_visual.position.y = 0
		_pose_customer(0)
	_update_cleaning(delta)

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
	if phase != "cleanup" or not is_instance_valid(target) or not target.has_meta("task") or not Input.is_physical_key_pressed(KEY_E) or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
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
	if phase != "cleanup": return
	tasks[id] = true
	task_nodes[id].visible = false
	task_nodes[id].collision_layer = 0
	cleaning_progress = 0
	_message(id.capitalize() + " done. Finish the remaining closing chores.")
	if tasks.values().all(func(done): return done): _show_day_summary()

func action_prompt(node: Node) -> String:
	var action: String = node.get_meta("action", "")
	match action:
		"pie": return "[Click / E] Pick up " + str(node.get_meta("item"))
		"donut": return "[Click / E] Grab a donut" if carried_item.is_empty() and not has_empty_cup() else "Hands full - place or return your item first"
		"tray": return "[Click / E] Place " + carried_item + " on tray" if not carried_item.is_empty() else "[Click / E] Take last item off tray" if not tray.is_empty() else "Serving tray - bring the customer's items here"
		"coffee", "cup_stack": return coffee_station.prompt(action)
		"soda", "soda_cup_stack": return soda_station.prompt(action)
		"bell": return "Refuse this customer service first" if refusal_required() else "[Click / E] Ding bell and serve the tray"
		"oven": return oven.prompt()
		"customer":
			if phase != "waiting": return "Customer is leaving" if phase == "leaving" else "Customer is approaching"
			if refusal_required(): return "[E] Refuse service - clothing required"
			return "[E] " + ("Hear order again - ring bell to serve" if order_taken else "Take customer's order")
		"queued_customer": return "Waiting in line"
		"departing_customer": return "Customer is leaving"
		"task": return "[E] Collect trash bag" if node.get_meta("task") == "trash" else "Hold [E] to clean " + str(node.get_meta("task"))
		"dispose": return "[Click / E] Throw trash into dumpster" if carrying_trash else "Dumpster - collect the morning trash bag first"
		"clock":
			if phase == "prep": return "[E] Open shift"
			if phase == "closed": return "[E] Begin the next day"
			if phase == "cleanup": return "Finish closing chores to end the day"
			return "Shift is open - serve customers at the counter"
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
		"oven": oven.interact()
		"customer":
			if phase != "waiting": return
			if refusal_required():
				refuse_service()
				return
			if not order_taken: service_seconds = 0.0
			order_taken = true
			speech.text = "I'd like " + ", ".join(order) + ", please."
			_message("CUSTOMER: " + ", ".join(order) + ". Place everything on the counter tray, then ring the bell to serve.")
		"task":
			if phase != "cleanup": return
			if node.get_meta("task") == "trash":
				_set_carrying_trash(true)
				node.visible = false
				node.collision_layer = 0
				_message("Trash collected. Take it through the kitchen back door and throw it in the outdoor dumpster.")
		"dispose":
			if carrying_trash:
				_set_carrying_trash(false)
				complete_task("trash")
		"clock":
			if phase == "prep": start_shift()
			elif phase == "closed": begin_prep()
			elif phase == "cleanup": _message("Finish cleaning and take the trash to the dumpster before starting the next day.")
			else: _message("Your shift is already open. Customers are waiting at the counter.")

func _set_carrying_trash(value: bool) -> void:
	carrying_trash = value
	if is_instance_valid(held_trash): held_trash.visible = value

func add_item(item: String, source: Node3D = null) -> bool:
	if item.ends_with("pie") and (not is_instance_valid(source) or source.get_meta("bake_quality", "raw") == "raw"):
		_message("Bake the pie in the kitchen oven before putting it on the serving tray.")
		return false
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

func refusal_required() -> bool:
	return is_instance_valid(customer) and bool(customer.get_meta("requires_refusal", false))

func refuse_service() -> void:
	if phase != "waiting" or not refusal_required(): return
	speech.text = "Okay. I'm leaving."
	_message("SERVICE REFUSED: Clothing is required. The customer is leaving. No penalty.")
	# Keep prepared food, cash, correct/incorrect counts and streak untouched.
	customers_this_shift += 1
	_depart_customer(false)

func _depart_customer(angry_exit: bool) -> void:
	phase = "leaving"
	if is_instance_valid(customer): customer_line.leave(customer, angry_exit)
	customer = null
	customer_visual = null
	customer_skeleton = null
	limbs.clear()
	walking = false
	order_taken = false
	arrival_delay = 0.15
	if not customer_line.waiting.is_empty(): _spawn_customer()

func serve_order() -> bool:
	if refusal_required():
		_message("Clothing is required. Face the customer and press E to refuse service.")
		return false
	if not carried_item.is_empty() or has_empty_cup():
		_message("Place the held item on the counter tray, or return it, before serving.")
		return false
	if phase != "waiting" or not order_taken or tray.is_empty(): return false
	var expected := order.duplicate()
	var actual := tray.duplicate()
	expected.sort()
	actual.sort()
	var correct := expected == actual
	for index in range(tray.size()):
		if tray[index].ends_with("pie"):
			var source := tray_sources[index]
			if not is_instance_valid(source) or source.get_meta("bake_quality", "raw") != "perfect": correct = false
	angry = not correct
	if correct:
		var has_perfect_pie := tray.any(func(item): return item.ends_with("pie"))
		var queue_wait: float = float(customer.get_meta("queue_wait",0.0))
		var payment: Dictionary = earnings.payout(order, true, service_seconds + maxf(0,queue_wait - 60.0), has_perfect_pie)
		_update_cash_display()
		payment_label.text = "Order +$%d  |  Tip +$%d  |  Service +$%d" % [payment.sale, payment.tip, payment.service]
		if payment.streak_bonus > 0: payment_label.text += "  |  Streak +$%d" % payment.streak_bonus
		payment_label.visible = true
		payment_time = 6.0
		served += 1
		speech.text = "Perfect! Thank you!"
		speech.modulate = Color(0.55, 1, 0.65)
		_message("CORRECT ORDER! The customer leaves happy.")
	else:
		earnings.payout(order, false, service_seconds, false)
		lost += 1
		speech.text = "That's NOT what I ordered!"
		speech.modulate = Color(1, 0.35, 0.25)
		_message("Customer wanted " + ", ".join(order) + ", with a perfectly baked pie. They are storming out.")
	_clear_tray(false)
	phase = "leaving"
	customers_this_shift += 1
	order_index += 1
	_depart_customer(angry)
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
		_item_model(item, tray[index], Vector3(-0.275 + (index % 3) * 0.275, height, -0.14 + (index / 3) * 0.28), 0.95, tray_sources[index])

func _set_pickup_visible(node: Node3D, shown: bool) -> void:
	node.visible = shown
	for body in node.find_children("*", "StaticBody3D", true, false):
		body.collision_layer = 1 if shown else 0

func _reset_stock() -> void:
	if is_instance_valid(oven): oven.reset_oven()
	if is_instance_valid(coffee_station): coffee_station.reset_station()
	if is_instance_valid(soda_station): soda_station.reset_station()
	for pie in all_pies:
		pie.set_meta("bake_quality", "raw")
		pie.set_meta("bake_seconds", 0.0)
		_set_pickup_visible(pie, true)

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

func _item_model(parent: Node3D, item: String, at: Vector3, size: float, source: Node3D = null) -> void:
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = at
	holder.scale = Vector3.ONE * size
	if item.ends_with("pie"):
		var quality: String = str(source.get_meta("bake_quality", "raw")) if is_instance_valid(source) else "raw"
		var path := "res://assets/pies/pie_ps2_toasted.glb" if quality in ["perfect", "burnt"] else "res://assets/pies/pie_ps2.glb"
		if quality == "burnt": path = "res://assets/pies/pie_ps2_burnt.glb"
		var pie = load(path).instantiate()
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
	_message("Picked up " + item + (". Bake it in the kitchen oven first." if item.ends_with("pie") and (not is_instance_valid(source) or source.get_meta("bake_quality", "raw") == "raw") else ". Click the tray on the counter to place it."))
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
	if not carried_item.is_empty(): _item_model(carried_visual, carried_item, Vector3.ZERO, 0.95, carried_source)

func has_empty_cup() -> bool:
	return (is_instance_valid(coffee_station) and coffee_station.holding_empty) or (is_instance_valid(soda_station) and soda_station.holding_empty)
