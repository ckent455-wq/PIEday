extends RefCounted
const DIRECTORY := "user://manual_saves"
const SLOTS := 3
const WALLET_FIELDS := ["cash","sales","tips","service_rewards","streak_rewards","streak","correct_orders","closing_bonus","day_completed","equipment","shift_takings","robbery_losses"]
const SHIFT_FIELDS := ["phase","tasks","tray","order","order_taken","route","route_index","walking","angry","served","lost","order_index","randomize_orders","last_recipe_index","fries_order_offered","arrival_delay","shift_number","customers_this_shift","service_seconds","shift_remaining","rush_started","rush_order","closing_time","cleaning_progress","cleaning_task","carried_item","animation_time"]
const LINE_FIELDS := ["next_arrival","time","last_model","nude_chance","last_was_nude","force_nude_next","force_nude_model","front_door_auto_opened","front_door_open_for"]
const EVENT_FIELDS := ["active","encounter","elapsed","bell_at","flicker_at","figure_at","bell_done","flicker_done","figure_done","figure_seen","trash_disposed","dissolve_elapsed","seen_seconds","away_seconds","flicker_time","extra_at","extra_done","steps_left","step_timer","step_position","step_direction"]

static func restore_pending(scene: Node) -> void:
	if not scene.get_tree().root.has_meta("restore_manual_state"): return
	var data: Dictionary = scene.get_tree().root.get_meta("restore_manual_state")
	scene.get_tree().root.remove_meta("restore_manual_state")
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	for i in range(3): await scene.get_tree().physics_frame
	restore(scene,data)
	while scene.get_tree().root.has_meta("hospital_travel_busy"): await scene.get_tree().process_frame
	scene.process_mode = Node.PROCESS_MODE_INHERIT

static func properties(node: Object, fields: Array) -> Dictionary:
	var result := {}
	for key in fields: result[key] = node.get(key)
	return result.duplicate(true)

static func apply(node: Object, data: Dictionary, fields: Array) -> void:
	for key in fields:
		if not data.has(key): continue
		var old = node.get(key)
		if old is Array and data[key] is Array: old.assign(data[key])
		elif old is Dictionary and data[key] is Dictionary:
			old.clear()
			old.merge(data[key],true)
		else: node.set(key,data[key])

static func wallet_for(scene: Node) -> RefCounted:
	return scene.shift.earnings if scene.scene_file_path == "res://main.tscn" else scene.earnings

static func source_id(shift: Node, source: Node) -> int:
	if not is_instance_valid(source): return -1
	var bottle_index: int = shift.bottle_cooler.bottles.find(source)
	if bottle_index >= 0: return 2000 + bottle_index
	var pie_index: int = shift.all_pies.find(source)
	if pie_index >= 0: return pie_index
	var donuts = shift.game.find_children("Donus*","MeshInstance3D",true,false)
	var donut_index: int = donuts.find(source)
	return 1000 + donut_index if donut_index >= 0 else -1

static func source_node(shift: Node, index: int) -> Node:
	if index >= 2000:
		return shift.bottle_cooler.bottles[index - 2000] if index - 2000 < shift.bottle_cooler.bottles.size() else null
	if index >= 1000:
		var donuts = shift.game.find_children("Donus*","MeshInstance3D",true,false)
		return donuts[index-1000] if index-1000 < donuts.size() else null
	return shift.all_pies[index] if index >= 0 and index < shift.all_pies.size() else null

static func actor_data(actor: Node3D) -> Dictionary:
	if not is_instance_valid(actor): return {}
	return {"transform":actor.transform,"model":actor.get_meta("customer_model"),"display_name":actor.get_meta("display_name"),"queue_wait":actor.get_meta("queue_wait",0.0),"action":actor.get_node("Interaction").get_meta("action"),"chat_index":actor.get_meta("chat_index",-1)}

static func restore_actor(line: Node, data: Dictionary) -> Node3D:
	var actor: Node3D = line.make_actor(data.transform.origin,data.model)
	actor.transform = data.transform
	for key in ["display_name","queue_wait","chat_index"]: actor.set_meta(key,data[key])
	actor.get_node("Interaction").set_meta("action",data.action)
	return actor

static func capture(scene: Node) -> Dictionary:
	var wallet = wallet_for(scene)
	var progress := ConfigFile.new()
	wallet.grandpa.write_config(progress)
	var data := {"version":1,"scene":scene.scene_file_path,"timestamp":Time.get_datetime_string_from_system(),"wallet":properties(wallet,WALLET_FIELDS),"grandpa":progress.encode_to_text(),"rng_state":wallet.rng.state,"player":scene.player.transform,"velocity":scene.player.velocity,"camera":scene.camera.rotation,"pitch":scene.pitch}
	var coop = preload("res://coop_session.gd").active(scene)
	if coop != null and coop.hosting: data["coop"] = coop.save_partner()
	if scene.scene_file_path == "res://hospital_room.tscn":
		data["bedside_light"] = scene.bedside_light.visible
		return data
	var shift = scene.shift
	data["shift"] = properties(shift,SHIFT_FIELDS)
	data["donuts"] = shift.donut_fryer.snapshot()
	data["bottles"] = shift.bottle_cooler.snapshot()
	data["burger"] = shift.burger_station.snapshot()
	data["training"] = [shift.tutorial.tutorial_state, shift.tutorial.practice_order_index, shift.tutorial.PRACTICE_ORDERS.size()]
	data["drawer_open"] = shift.pistol.drawer_open
	data["robbery_remaining"] = shift.robbery.remaining
	data["dine_in"] = shift.dine_in.snapshot()
	data["corpses"] = shift.corpses.snapshot()
	data["pies"] = []
	for pie in shift.all_pies: data.pies.append({"visible":pie.visible,"quality":pie.get_meta("bake_quality","raw"),"seconds":pie.get_meta("bake_seconds",0.0)})
	data["tray_sources"] = []
	for source in shift.tray_sources: data.tray_sources.append(source_id(shift,source))
	data["carried_source"] = source_id(shift,shift.carried_source)
	data["carrying_trash"] = shift.carrying_trash
	data["oven"] = properties(shift.oven,["pie_item","elapsed"])
	data.oven["source"] = source_id(shift,shift.oven.pie_source)
	data["drinks"] = []
	for station in [shift.coffee_station,shift.soda_station]:
		var drink := properties(station,["state","holding_empty","cups_left","fill","drink_name"])
		drink["status"] = station.status.text
		data.drinks.append(drink)
	data["doors"] = []
	for door in scene.doors: data.doors.append({"open":door.get_meta("open"),"rotation":door.rotation})
	data["line"] = properties(shift.customer_line,LINE_FIELDS)
	data["customer"] = actor_data(shift.customer)
	data["waiting"] = []
	data["departing"] = []
	for entry in shift.customer_line.waiting:
		data.waiting.append({"actor":actor_data(entry.actor),"seconds":entry.seconds,"junction":entry.junction})
	for entry in shift.customer_line.departing:
		data.departing.append({"actor":actor_data(entry.actor),"route":entry.route.duplicate(),"step":entry.step,"speed":entry.speed})
	data["events"] = properties(shift.closing_events,EVENT_FIELDS)
	data.events["rng_state"] = shift.closing_events.rng.state
	data.events["figure_visible"] = shift.closing_events.figure.visible
	data.events["figure_transform"] = shift.closing_events.figure.transform
	data.events["energies"] = shift.closing_events.lights.map(func(light): return light.light_energy)
	data.events["opened_cooler"] = scene.doors.find(shift.closing_events.opened_cooler) if is_instance_valid(shift.closing_events.opened_cooler) else -1
	data["missing"] = []
	for pie in shift.restock.missing: data.missing.append(source_id(shift,pie))
	return data

static func write(slot: int, data: Dictionary, directory := DIRECTORY) -> Error:
	if slot < 1 or slot > SLOTS: return ERR_INVALID_PARAMETER
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK: return error
	var config := ConfigFile.new()
	config.set_value("save","state",data)
	var path := "%s/slot_%d.cfg" % [directory,slot]
	error = config.save(path+".tmp")
	if error != OK: return error
	return DirAccess.rename_absolute(path+".tmp",path)

static func read(slot: int, directory := DIRECTORY) -> Dictionary:
	if slot < 1 or slot > SLOTS: return {}
	var config := ConfigFile.new()
	if config.load("%s/slot_%d.cfg" % [directory,slot]) != OK: return {}
	var data = config.get_value("save","state",{})
	if not data is Dictionary or not data.has_all(["version","scene","timestamp","wallet","grandpa","rng_state","player","velocity","camera","pitch"]): return {}
	if data.version != 1 or data.scene not in ["res://main.tscn","res://hospital_room.tscn"]: return {}
	var progress := ConfigFile.new()
	if not data.grandpa is String or progress.parse(data.grandpa) != OK: return {}
	if data.scene == "res://main.tscn" and not data.has_all(["shift","pies","doors","customer","line","waiting","departing","drinks","oven","events","missing","tray_sources","carried_source","carrying_trash"]): return {}
	return data

static func load_state(host: Node, data: Dictionary, persist := true) -> void:
	var wallet = preload("res://earnings.gd").new(false)
	var config := ConfigFile.new()
	if config.parse(data.grandpa) != OK: return
	wallet.grandpa.read_config(config)
	apply(wallet,data.wallet,WALLET_FIELDS)
	wallet.rng.state = data.rng_state
	wallet.save_enabled = persist
	var coop = preload("res://coop_session.gd").active(host)
	if coop != null: wallet.save_path = coop.CAMPAIGN_PATH
	wallet._save()
	host.get_tree().root.set_meta("restore_manual_state",data)
	preload("res://hospital_travel.gd").go(host,data.scene,wallet)

static func restore(scene: Node, data: Dictionary) -> void:
	scene.player.transform = data.player
	scene.player.velocity = data.velocity
	scene.camera.rotation = data.camera
	scene.pitch = data.pitch
	if scene.scene_file_path == "res://hospital_room.tscn":
		scene.bedside_light.visible = data.get("bedside_light",true)
		var coop = preload("res://coop_session.gd").active(scene)
		if coop != null and coop.hosting and data.has("coop"): coop.restore_partner(data.coop)
		return
	var shift = scene.shift
	shift.customer_line.clear_all()
	shift._reset_customer()
	shift.closing_events.reset()
	if not data.shift.tasks.has("tables"): data.shift.tasks["tables"] = true
	data.shift.tasks.erase("bodies")
	apply(shift,data.shift,SHIFT_FIELDS)
	shift.fries_order_offered = data.shift.get("fries_order_offered", shift.order.has(shift.FRIES.SERVING))
	var training: Array = data.get("training", ["welcome", 0])
	shift.tutorial.tutorial_state = training[0]
	shift.tutorial.practice_order_index = training[1]
	# The encounter follows the last food order, including in earlier saves.
	var saved_order_count: int = training[2] if training.size() > 2 else 3
	if training[1] == saved_order_count:
		shift.tutorial.practice_order_index = shift.tutorial.PRACTICE_ORDERS.size()
	shift.pistol.set_drawer_open(data.get("drawer_open", false))
	shift.robbery.remaining = data.get("robbery_remaining", -1.0)
	shift.donut_fryer.restore(data.get("donuts", {}))
	shift.bottle_cooler.refill()
	shift.bottle_cooler.restore(data.get("bottles", []))
	shift.burger_station.restore(data.get("burger", {}))
	for i in mini(data.pies.size(),shift.all_pies.size()):
		var pie = shift.all_pies[i]
		pie.set_meta("bake_quality",data.pies[i].quality)
		pie.set_meta("bake_seconds",data.pies[i].seconds)
		shift._set_pickup_visible(pie,data.pies[i].visible)
	shift.tray_sources.clear()
	for index in data.tray_sources: shift.tray_sources.append(source_node(shift,index))
	shift.carried_source = source_node(shift,data.carried_source)
	if shift.carried_item == "Pistol": shift.carried_source = shift.pistol.pickup
	shift._refresh_tray()
	shift._refresh_carried()
	shift._set_carrying_trash(data.carrying_trash)
	for id in shift.tasks:
		shift.task_nodes[id].visible = shift.phase == "cleanup" and not shift.tasks[id]
		shift.task_nodes[id].collision_layer = 4 if shift.task_nodes[id].visible else 0
	shift.restock.missing.clear()
	for index in data.missing:
		var pie = source_node(shift,index)
		if pie != null: shift.restock.missing.append(pie)
	shift.restock.cooler_target.collision_layer = 4 if shift.phase == "cleanup" else 0
	apply(shift.oven,data.oven,["pie_item","elapsed"])
	shift.oven.pie_source = source_node(shift,data.oven.source)
	for i in mini(data.doors.size(),scene.doors.size()):
		var door = scene.doors[i]
		var tween = door.get_meta("tween") if door.has_meta("tween") else null
		if tween is Tween and tween.is_valid(): tween.kill()
		door.set_meta("open",data.doors[i].open)
		door.rotation = data.doors[i].rotation
		var target_angle: float = door.get_meta("closed_rotation") + (float(door.get_meta("swing_angle")) if data.doors[i].open else 0.0)
		if absf(door.rotation.y-target_angle) > .001:
			var remaining := .45*absf(door.rotation.y-target_angle)/maxf(.001,absf(float(door.get_meta("swing_angle"))))
			var motion: Tween = scene.create_tween()
			motion.tween_property(door,"rotation:y",target_angle,remaining)
			door.set_meta("tween",motion)
	shift.oven._refresh_visual()
	shift.oven._update_display()
	for i in range(2):
		var station = [shift.coffee_station,shift.soda_station][i]
		station.reset_station()
		apply(station,data.drinks[i],["state","holding_empty","cups_left","fill","drink_name"])
		if station.has_method("apply_flavor"): station.apply_flavor()
		station._rebuild_stack()
		station.held_cup.visible = station.holding_empty
		station.machine_cup.visible = station.state != "empty"
		station.stream.visible = station.state == "brewing"
		station._fill_cup(station.fill)
		station.status.text = data.drinks[i].status
		if station.state == "brewing":
			station.brew_tween = station.create_tween()
			station.brew_tween.tween_method(station._fill_cup,station.fill,1.0,maxf(.01,(1-station.fill)*station.fill_seconds))
			station.brew_tween.tween_callback(station._finish_brewing)
	if not data.customer.is_empty(): shift._bind_customer_actor(restore_actor(shift.customer_line,data.customer))
	for entry in data.waiting:
		shift.customer_line.waiting.append({"actor":restore_actor(shift.customer_line,entry.actor),"seconds":entry.seconds,"junction":entry.junction})
	for entry in data.departing:
		shift.customer_line.departing.append({"actor":restore_actor(shift.customer_line,entry.actor),"route":entry.route,"step":entry.step,"speed":entry.speed})
	apply(shift.customer_line,data.line,LINE_FIELDS)
	scene.set_night(shift.closing_time or shift.phase == "closed")
	apply(shift.closing_events,data.events,EVENT_FIELDS)
	shift.closing_events._set_dissolve(clampf(shift.closing_events.dissolve_elapsed / shift.closing_events.DISSOLVE_SECONDS, 0.0, 1.0))
	shift.closing_events.rng.state = data.events.rng_state
	shift.closing_events.figure.visible = data.events.figure_visible
	shift.closing_events.figure.transform = data.events.figure_transform
	# Older saves stored scale and position for the previous shadow-person model.
	shift.closing_events.figure.scale = Vector3.ONE
	if shift.closing_events.figure.visible:
		shift.closing_events.figure.visible = shift.closing_events._place_figure()
	var cooler_index: int = data.events.get("opened_cooler",-1)
	shift.closing_events.opened_cooler = scene.doors[cooler_index] if cooler_index >= 0 and cooler_index < scene.doors.size() else null
	for i in mini(data.events.energies.size(),shift.closing_events.lights.size()): shift.closing_events.lights[i].light_energy = data.events.energies[i]
	shift.dine_in.restore(data.get("dine_in",{}))
	shift.corpses.restore(data.get("corpses",{}))
	apply(shift.customer_line,data.line,LINE_FIELDS)
	shift._update_cash_display()
	shift._update_shift_clock()
	shift._refresh_hud()
	shift._message("Save state loaded.")
	var coop = preload("res://coop_session.gd").active(scene)
	if coop != null and coop.hosting and data.has("coop"): coop.restore_partner(data.coop)
