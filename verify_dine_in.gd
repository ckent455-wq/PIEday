extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func require(ok: bool,message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.start_demo()
	shift.customer_line.next_arrival = INF
	var dining = shift.dine_in
	require(dining.tables.size() == 6,"All six booths are available")
	await physics_frame
	await physics_frame
	var space := game.get_world_3d().direct_space_state as PhysicsDirectSpaceState3D
	for table in dining.tables:
		var start := Vector3(-2.4, -0.094, -3.6)
		for target: Vector3 in table.route:
			var side := start.direction_to(target).cross(Vector3.UP)
			for offset in [Vector3.UP * 0.4, Vector3.UP * 1.15 + side * 0.15, Vector3.UP * 1.15 - side * 0.15]:
				var ray := PhysicsRayQueryParameters3D.create(start + offset, target + offset, 1, [game.player.get_rid()])
				var hit := space.intersect_ray(ray)
				require(hit.is_empty(), "%s route hits diner geometry from %s to %s" % [table.name, start, target])
			start = target
	dining.dine_chance = 1
	dining.mess_chance = 1
	# Use the near booth for repeatable visual inspection.
	for i in range(1,dining.tables.size()): dining.tables[i].busy = true
	for i in range(620): shift._process(1.0/60)
	shift.order.assign(["Soda"])
	shift.order_taken = true
	shift.add_item("Soda")
	var name: String = shift.customer.get_meta("display_name")
	require(shift.serve_order() and dining.diners.size() == 1,"A correctly served customer can dine in")
	require(shift.tray.is_empty() and not is_instance_valid(shift.customer),"Counter is free for the next order")
	var paid: int = shift.earnings.cash
	for i in range(500):
		dining.tick(.05)
		if dining.diners[0].state == "eating": break
	require(dining.diners[0].state == "eating" and dining.tables[0].busy,"Customer walks to a reserved booth and sits")
	require(dining.diners[0].actor.get_meta("display_name") == name,"Dine-in retains the customer identity")
	dining.diners[0].remaining = 10.0
	var snapshot := preload("res://save_states.gd").capture(game)
	var config := ConfigFile.new()
	config.set_value("save","state",snapshot)
	var decoded := ConfigFile.new()
	require(decoded.parse(config.encode_to_text()) == OK,"Dining state serializes without object references")
	preload("res://save_states.gd").restore(game,decoded.get_value("save","state"))
	require(dining.diners.size() == 1 and dining.diners[0].state == "eating" and dining.diners[0].remaining == 10.0,"Save restores seated customer and meal timer")
	for i in range(4): await process_frame
	if DisplayServer.get_name() != "headless":
		var table: Dictionary = dining.tables[0]
		game.player.position = table.top+Vector3(1.8,-table.top.y+.03,-1.4)
		await process_frame
		game.camera.look_at(table.top+Vector3(.6,.35,0))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/dine-in-customer.png")
	dining.tick(11)
	require(dining.diners.is_empty() and dining.dirty_count() == 1,"Messy customer leaves cups and wrappers")
	var return_route: Array = dining.tables[0].route.duplicate()
	return_route.reverse()
	require(shift.customer_line.departing.back().route.slice(0, return_route.size()) == return_route, "Departing diner retraces the booth route")
	require(shift.earnings.cash == paid,"Eating does not award payment twice")
	shift.begin_cleanup()
	require(not shift.tasks.tables,"Dirty tables become a nightly chore")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/table-trash-cleanup.png")
	shift.interact(shift.task_nodes.trash)
	require(not shift.carrying_trash,"Bag cannot be collected before tables are cleared")
	dining.pick_trash(0)
	require(shift.carried_item == "Table trash" and not dining.tables[0].trash.visible,"Player picks up the used cup and wrappers")
	shift.discard_last()
	require(shift.carried_item.is_empty() and dining.tables[0].trash.visible and dining.tables[0].trash.collision_layer == 4,"Q returns litter to the original table")
	dining.pick_trash(0)
	var held := preload("res://save_states.gd").capture(game)
	preload("res://save_states.gd").restore(game,held)
	require(dining.carried_table == 0 and shift.carried_source == dining.tables[0].trash and not shift.carried_source.visible,"Save restores carried table trash without duplication")
	dining.use_bin()
	require(shift.tasks.tables and dining.dirty_count() == 0 and shift.carried_item.is_empty(),"Depositing litter completes table clearing")
	dining.use_bin()
	require(shift.carrying_trash,"The indoor bin now supplies the bag")
	shift.interact(game.find_child("OutdoorDumpster",true,false))
	require(shift.tasks.trash and not shift.carrying_trash,"Bag must still go to the outdoor dumpster")
	# A tidy customer leaves no litter, while closing evicts diners promptly.
	shift.start_demo()
	dining.mess_chance = 0
	var actor = shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),"male_1")
	require(dining.try_seat(actor,["Coffee"],true),"A second customer can take a clean table")
	dining.sit(dining.diners[0])
	dining.tick(100)
	require(dining.dirty_count() == 0,"Some customers clean up after themselves")
	dining.mess_chance = 1
	actor = shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),"female_1")
	dining.try_seat(actor,["Donut"],true)
	dining.sit(dining.diners[0])
	shift.begin_cleanup()
	require(dining.diners.is_empty() and dining.dirty_count() == 1 and not shift.tasks.tables,"Closing sends diners home and retains their table trash")
	if failures == 0: print("PASS: booth reservations, meal delivery, seated eating, random clean/messy departures, nightly table-bin-bag-dumpster routine, Q return, closing evacuation and save/load")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
