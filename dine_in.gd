extends Node3D
var shift: Node3D
var tables: Array[Dictionary] = []
var diners: Array[Dictionary] = []
const DEFAULT_DINE_CHANCE := 0.75
const COUNTER_AISLE := Vector3(-2.4, -0.094, -0.2)
var dine_chance := DEFAULT_DINE_CHANCE
var mess_chance := .45
var carried_table := -1
var bin: Node3D

func setup(host: Node3D) -> void:
	shift = host
	name = "DiningRoom"
	for table_name in ["Table","Table_01","Table_02","Table_03","Table_04","Table_05"]:
		var mesh = shift.game.find_child(table_name,true,false)
		if not mesh is MeshInstance3D: continue
		var bounds: AABB = mesh.global_transform*mesh.mesh.get_aabb()
		var center := bounds.get_center()
		var side := 1.0 if center.x < 0 else -1.0
		var seat := Vector3(center.x+side*(bounds.size.x/2+.48),-.094,center.z)
		var approach := Vector3(seat.x,-.094,bounds.position.z-.65)
		if bounds.size.x > bounds.size.z:
			seat = Vector3(center.x,-.094,center.z+.48+bounds.size.z/2)
			approach = Vector3(bounds.end.x+.65,-.094,seat.z)
		var facing := atan2(center.x-seat.x,center.z-seat.z)
		var inward := Vector3(center.x - seat.x, 0, center.z - seat.z).normalized()
		var walk_end := seat + inward * 0.30
		approach += inward * 0.30
		var route: Array[Vector3] = [COUNTER_AISLE]
		# Turn in the open aisle before entering each narrow booth gap.
		match table_name:
			"Table_01", "Table_02", "Table_03", "Table_04":
				route.append(Vector3(approach.x, seat.y, COUNTER_AISLE.z))
			"Table_05":
				# A partition blocks the north end of this booth.
				approach.z = COUNTER_AISLE.z
		if route.back() != approach: route.append(approach)
		route.append(walk_end)
		tables.append({"name":table_name,"top":Vector3(center.x,bounds.end.y+.015,center.z),"seat":seat,"route":route,"facing":facing,"busy":false,"dirty":false,"trash":null,"meal":null})
	var task := StaticBody3D.new()
	task.name = "ClearTablesTask"
	add_child(task)
	shift.task_nodes["tables"] = task
	bin = shift.game.find_child("Trash",true,false)
	bin.set_meta("action","trash_bin")
	var bin_bounds: AABB = bin.global_transform*bin.mesh.get_aabb()
	shift.task_nodes.trash.global_position = bin_bounds.get_center()
	shift.task_nodes.trash.get_node("MorningTrashBag").hide()

func try_seat(actor: Node3D, items: Array, force := false) -> bool:
	if shift.closing_time or actor.get_meta("requires_refusal",false): return false
	if items.any(func(item): return item in shift.BOTTLE_COOLER.ITEMS): return false
	if not force and randf() >= dine_chance: return false
	var free: Array[int] = []
	for i in tables.size():
		if not tables[i].busy and not tables[i].dirty: free.append(i)
	if free.is_empty(): return false
	var index: int = free.pick_random()
	var table: Dictionary = tables[index]
	table.busy = true
	actor.get_node("Interaction").set_meta("action","dining_customer")
	var meal := meal_visual(items)
	actor.add_child(meal)
	meal.position = Vector3(0,1.05,.4)
	var route: Array[Vector3] = table.route.duplicate()
	diners.append({"actor":actor,"table":index,"state":"walking","route":route,"step":0,"remaining":randf_range(18,35),"mess":randf()<mess_chance,"items":items.duplicate(),"meal":meal})
	return true

func meal_visual(items: Array) -> Node3D:
	var root := Node3D.new()
	root.name = "CustomerMeal"
	var tray = preload("res://assets/tray/black_cafeteria_tray.glb").instantiate()
	root.add_child(tray)
	tray.scale = Vector3.ONE*1.25
	var baked := Node3D.new()
	baked.set_meta("bake_quality","perfect")
	for i in items.size():
		var holder := Node3D.new()
		root.add_child(holder)
		shift._item_model(holder,items[i],Vector3(-.16+(i%3)*.16,.012,(i/3)*.18),.55,baked)
	baked.free()
	return root

func tick(delta: float) -> void:
	for entry in diners.duplicate():
		var actor: Node3D = entry.actor
		if entry.state == "walking":
			var moving: bool = shift.customer_line._move(actor,entry.route[entry.step],3.0,delta)
			shift.customer_line._pose(actor,sin(shift.animation_time*12))
			if not moving:
				entry.step += 1
				if entry.step >= entry.route.size(): sit(entry)
		else:
			entry.remaining -= delta
			actor.get_node("Visual").rotation.x = sin(shift.animation_time*1.5)*.025
			var skeleton: Skeleton3D = actor.get_meta("skeleton")
			var seated: Dictionary = actor.get_meta("dining_seated_pose",{})
			for bone_name in ["DEF-forearm.L","DEF-forearm.R"]:
				var id := skeleton.find_bone(bone_name)
				if id < 0 or not seated.has(id): continue
				var rest := skeleton.get_bone_global_rest(id).basis.get_rotation_quaternion()
				var bite := maxf(0,sin(shift.animation_time*2))*0.25
				skeleton.set_bone_pose_rotation(id,seated[id]*rest.inverse()*Quaternion(Vector3.RIGHT,bite)*rest)
			if entry.remaining <= 0: finish_meal(entry)

func sit(entry: Dictionary) -> void:
	var table: Dictionary = tables[entry.table]
	entry.state = "eating"
	entry.actor.position = table.seat
	entry.actor.rotation.y = table.facing
	entry.actor.get_node("Visual").position.y = -.32
	var skeleton: Skeleton3D = entry.actor.get_meta("skeleton")
	var baseline := {}
	for i in skeleton.get_bone_count(): baseline[i] = skeleton.get_bone_pose_rotation(i)
	entry.actor.set_meta("dining_base_pose",baseline)
	for bone_name in ["Leg_L","Leg_R","DEF-shin.L","DEF-shin.R","Arm_L","Arm_R","DEF-forearm.L","DEF-forearm.R"]:
		var id := skeleton.find_bone(bone_name)
		if id < 0: continue
		var rest := skeleton.get_bone_global_rest(id).basis.get_rotation_quaternion()
		var angle := -1.35 if bone_name.begins_with("Leg") else 1.5 if "shin" in bone_name else -.35 if bone_name.begins_with("Arm") else -.9
		skeleton.set_bone_pose_rotation(id,baseline[id]*rest.inverse()*Quaternion(Vector3.RIGHT,angle)*rest)
	var seated := {}
	for i in skeleton.get_bone_count(): seated[i] = skeleton.get_bone_pose_rotation(i)
	entry.actor.set_meta("dining_seated_pose",seated)
	entry.meal.reparent(self)
	entry.meal.global_position = table.top
	entry.meal.rotation = Vector3.ZERO
	table.meal = entry.meal

func stand(actor: Node3D) -> void:
	var skeleton: Skeleton3D = actor.get_meta("skeleton")
	var baseline: Dictionary = actor.get_meta("dining_base_pose",{})
	for id in baseline: skeleton.set_bone_pose_rotation(id,baseline[id])
	actor.get_node("Visual").position = Vector3.ZERO
	actor.get_node("Visual").rotation.x = 0

func finish_meal(entry: Dictionary, emergency := false) -> void:
	var table: Dictionary = tables[entry.table]
	if entry.state == "eating" and entry.mess:
		table.dirty = true
		make_trash(entry.table)
	table.busy = false
	if is_instance_valid(entry.meal): entry.meal.queue_free()
	table.meal = null
	stand(entry.actor)
	shift.customer_line.leave(entry.actor,false,true,emergency)
	var exit_route: Array = []
	if entry.state == "eating":
		# Stand in the booth gap, then retrace the inbound path.
		entry.actor.position = table.route.back()
		exit_route = table.route.duplicate()
		exit_route.reverse()
	elif entry.step > 0:
		exit_route = entry.route.slice(0, entry.step)
		exit_route.reverse()
	else:
		exit_route = [COUNTER_AISLE]
	var departure: Dictionary = shift.customer_line.departing.back()
	departure.route = exit_route + [Vector3(0.76, -0.094, 0.2), Vector3(0.76, -0.094, 6.1)]
	diners.erase(entry)

func make_trash(index: int) -> void:
	var table: Dictionary = tables[index]
	if is_instance_valid(table.trash): return
	var trash := StaticBody3D.new()
	trash.name = "TableTrash_"+str(index)
	trash.collision_layer = 4
	trash.set_meta("action","table_trash")
	trash.set_meta("table",index)
	add_child(trash)
	trash.global_position = table.top
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(.8,.3,.65)
	shape.position.y = .12
	trash.add_child(shape)
	trash_visual(trash)
	table.trash = trash

func trash_visual(parent: Node3D) -> void:
	var cup := CylinderMesh.new()
	cup.top_radius = .05
	cup.bottom_radius = .04
	cup.height = .16
	cup.radial_segments = 8
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = Vector3(.12,.055,.03)
	holder.rotation.z = 1.1
	shift._mesh(holder,cup,Vector3.ZERO,Color("c8b899"))
	for i in range(4):
		shift._box(parent,Vector3(-.15+i*.06,.015+i*.008,-.07+(i%2)*.11),Vector3(.14,.025,.12),Color("c8c1a8"))

func close_for_night(emergency := false) -> void:
	for entry in diners.duplicate(): finish_meal(entry, emergency)

func dirty_count() -> int:
	var total := 0
	for table in tables:
		if table.dirty: total += 1
	return total

func begin_cleanup() -> void:
	shift.tasks.tables = dirty_count() == 0
	shift.task_nodes.tables.visible = false
	shift.task_nodes.trash.collision_layer = 0

func pick_trash(index: int) -> void:
	if shift.phase != "cleanup":
		shift._message("Clear the tables after closing.")
		return
	if not shift.carried_item.is_empty() or shift.has_empty_cup() or shift.carrying_trash:
		shift._message("Free your hands before clearing a table.")
		return
	if index < 0 or index >= tables.size() or not tables[index].dirty: return
	if not is_instance_valid(tables[index].trash) or not tables[index].trash.visible: return
	carried_table = index
	shift.carried_item = "Table trash"
	shift.carried_source = tables[index].trash
	tables[index].trash.visible = false
	tables[index].trash.collision_layer = 0
	shift._refresh_carried()
	shift._message("Take the used cup and wrappers to the indoor trash can.")

func use_bin() -> void:
	if shift.phase != "cleanup":
		shift._message("The trash bag is taken out after closing.")
		return
	if shift.carried_item == "Table trash" and carried_table >= 0:
		var table: Dictionary = tables[carried_table]
		table.dirty = false
		if is_instance_valid(table.trash): table.trash.queue_free()
		table.trash = null
		carried_table = -1
		shift._clear_carried(false)
		if dirty_count() == 0:
			shift.complete_task("tables")
			shift._message("Tables are clear. Collect the bag from this bin and take it to the dumpster.")
		else: shift._message("Trash binned. %d dirty table(s) left." % dirty_count())
	else:
		shift.interact(shift.task_nodes.trash)

func return_trash() -> void:
	if carried_table < 0: return
	var trash = tables[carried_table].trash
	if is_instance_valid(trash):
		trash.visible = true
		trash.collision_layer = 4
	carried_table = -1

func prompt(action: String) -> String:
	if action == "dining_customer": return "Customer is enjoying their meal"
	if action == "table_trash": return "[E] Clear cups and wrappers" if shift.phase == "cleanup" else "Clear this table after closing"
	if shift.carried_item == "Table trash": return "[E] Put table trash in bin"
	if shift.carrying_trash: return "Take the bag to the outdoor dumpster"
	return "[E] Collect trash bag" if shift.phase == "cleanup" and shift.tasks.tables else "Clear all tables into this bin before taking out the bag"

func reset() -> void:
	for entry in diners:
		if is_instance_valid(entry.actor): entry.actor.queue_free()
		if is_instance_valid(entry.meal): entry.meal.queue_free()
	diners.clear()
	for table in tables:
		if is_instance_valid(table.trash): table.trash.queue_free()
		table.trash = null
		table.meal = null
		table.busy = false
		table.dirty = false
	carried_table = -1

func snapshot() -> Dictionary:
	var data := {"dirty":[],"diners":[],"carried_table":carried_table,"dine_chance":dine_chance,"mess_chance":mess_chance}
	for table in tables: data.dirty.append(table.dirty)
	for entry in diners:
		data.diners.append({"actor":preload("res://save_states.gd").actor_data(entry.actor),"table":entry.table,"state":entry.state,"route":entry.route.duplicate(),"step":entry.step,"remaining":entry.remaining,"mess":entry.mess,"items":entry.items.duplicate()})
	return data

func restore(data: Dictionary) -> void:
	reset()
	dine_chance = data.get("dine_chance", DEFAULT_DINE_CHANCE)
	if is_equal_approx(dine_chance, 0.55): dine_chance = DEFAULT_DINE_CHANCE
	mess_chance = data.get("mess_chance",.45)
	var dirty: Array = data.get("dirty",[])
	for i in mini(dirty.size(),tables.size()):
		tables[i].dirty = dirty[i]
		if dirty[i]: make_trash(i)
	for saved in data.get("diners",[]):
		if saved.table < 0 or saved.table >= tables.size(): continue
		var actor = preload("res://save_states.gd").restore_actor(shift.customer_line,saved.actor)
		var entry: Dictionary = saved.duplicate(true)
		var route: Array = tables[entry.table].route
		if entry.route != route:
			# Rejoin the corrected path when loading an older walking route.
			entry.route = route.duplicate()
			entry.step = 0
			if entry.state == "walking": actor.position = COUNTER_AISLE
		entry.actor = actor
		entry.meal = meal_visual(saved.items)
		actor.add_child(entry.meal)
		entry.meal.position = Vector3(0,1.05,.4)
		tables[entry.table].busy = true
		diners.append(entry)
		if entry.state == "eating": sit(entry)
	carried_table = data.get("carried_table",-1)
	if carried_table >= 0 and carried_table < tables.size() and is_instance_valid(tables[carried_table].trash):
		shift.carried_source = tables[carried_table].trash
		shift.carried_source.visible = false
		shift.carried_source.collision_layer = 0
	shift.task_nodes.tables.visible = false
	shift.task_nodes.tables.collision_layer = 0
	shift.task_nodes.trash.collision_layer = 0
