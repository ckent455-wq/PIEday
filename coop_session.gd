extends Node

const PORT := 27841
const PROTOCOL := 16
const NAME_LIMIT := 20
const DEFAULT_NAME := "PARTNER"
const CAMPAIGN_PATH := "user://coop_earnings.cfg"
const SAVE := preload("res://save_states.gd")
const UNIFORM := preload("res://coop_uniform.gd")
const SUPPORTED_ACTIONS := ["appliance_repair","clock", "open_sign", "burger_grill", "burger_prep", "burger_raw", "burger_topping", "pie", "donut", "donut_fryer", "frozen_fries", "tray", "coffee", "cup_stack", "soda", "soda_cup_stack", "bottle", "oven", "bell", "customer", "pistol", "pistol_drawer", "corpse", "task", "table_trash", "trash_bin", "dining_customer", "freezer_stock", "freezer_tomato", "freezer_onion", "freezer_lettuce", "freezer_cheese", "restock_cooler", "dispose"]
var hosting := false
var partner_id := 0
var partner_ready := false
var game: Node3D
var partner: Node3D
var partner_target := Vector3.ZERO
var partner_yaw := 0.0
var replicas := {}
var guest_item := ""
var guest_source: Node3D
var guest_coffee_cup := false
var guest_soda_cup := false
var update_time := 0.0
var last_action := -1000
var night := false
var leaving := false
var acting_guest := false
var ui_applying := false
var wallet: RefCounted
var guest_trash := false
var guest_table := -1
var guest_body: Node3D
var partner_pitch := 0.0
var guest_cleaning := ""
var guest_cleaning_time := 0.0
var last_pose_at := 0
var scene_epoch := 0
var transporting := false
var pause_votes := {}
var guest_loaded_epoch := -1
var mirror_bodies := {}
var partner_camera: Camera3D
var saved_guest_position: Array = []
var host_carrying_body: Node3D
var host_holding_pistol := false
var partner_hand: Node3D
var partner_hand_key := ""
var intro_scene: Control
var connection_confirmed := false
var character_model := 0
var character_apron := 0
var character_face := 0
var character_name := ""
var partner_model := 0
var partner_apron := 0
var partner_face := 0
var partner_name := DEFAULT_NAME
var character_received := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

static func active(node: Node):
	return node.get_tree().root.get_node_or_null("CoopSession")

static func clean_name(value: String) -> String:
	return value.strip_escapes().strip_edges().left(NAME_LIMIT).strip_edges()

func connect_game(as_host: bool, address: String, port := PORT) -> Error:
	hosting = as_host
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, 1) if hosting else peer.create_client(address, port)
	if error != OK: return error
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_connection_failed)
	multiplayer.multiplayer_peer = peer
	if not hosting: _check_connection_timeout()
	return OK

func _peer_connected(id: int) -> void:
	if not hosting: return
	partner_id = id
	_check_connection_timeout()
	if wallet == null: wallet = preload("res://earnings.gd").new(true, CAMPAIGN_PATH)
	var progress := _wallet_state(wallet)
	progress["character"] = Vector3i(character_model, character_apron, character_face)
	progress["character_name"] = clean_name(character_name)
	_enter_diner.rpc_id(id, PROTOCOL, progress)

@rpc("authority", "call_remote", "reliable")
func _enter_diner(version: int, progress: Dictionary) -> void:
	if hosting: return
	if version != PROTOCOL:
		leave("Your partner is using a different co-op build.")
		return
	partner_id = 1
	var character: Vector3i = progress.character
	_set_partner_character(character.x, character.y, character.z, str(progress.get("character_name", "")))
	wallet = _read_wallet(progress)
	_join_character.rpc_id(1, character_model, character_apron, character_face, clean_name(character_name))
	_load_diner.call_deferred()

@rpc("any_peer", "call_remote", "reliable")
func _join_character(model: int, apron: int, face: int, player_name: String) -> void:
	if not hosting or leaving or character_received or multiplayer.get_remote_sender_id() != partner_id: return
	character_received = true
	_set_partner_character(model, apron, face, player_name)
	_load_diner.call_deferred()

func _set_partner_character(model: int, apron: int, face: int, player_name: String) -> void:
	partner_model = clampi(model, 0, UNIFORM.MODELS.size() - 1)
	partner_apron = clampi(apron, 0, UNIFORM.APRONS.size() - 1)
	partner_face = clampi(face, 0, UNIFORM.FACES[partner_model].size() - 1)
	var cleaned := clean_name(player_name)
	partner_name = DEFAULT_NAME if cleaned.is_empty() else cleaned

func _load_diner() -> void:
	if leaving: return
	get_tree().root.set_meta("pie_day_wallet", wallet)
	var destination := "res://grandpa_ending.tscn" if wallet.grandpa.is_dead() else "res://grandpa_victory.tscn" if wallet.grandpa.campaign_won else "res://hospital_room.tscn" if wallet.grandpa.visit_in_progress else "res://intro.tscn" if wallet.grandpa.days == 0 else "res://main.tscn"
	get_tree().change_scene_to_file(destination)

func attach(diner: Node3D) -> void:
	intro_scene = null
	game = diner
	replicas.clear()
	mirror_bodies.clear()
	partner_ready = hosting and guest_loaded_epoch == scene_epoch
	guest_item = ""
	guest_source = null
	guest_coffee_cup = false
	guest_soda_cup = false
	guest_trash = false
	guest_table = -1
	guest_body = null
	_create_partner()
	game.player.position = Vector3(-2.4 if hosting else -0.9, 0.03, -5.8)
	game.spawn_point = game.player.position
	game.player.rotation.y = PI
	partner_target = Vector3(-0.9 if hosting else -2.4, 0.03, -5.8)
	partner.position = partner_target
	partner_yaw = PI
	wallet = game.shift.earnings
	game.shift._message("Finish donut prep, then flip the OPEN sign in the front window to open the shared shift." if game.shift.phase == "prep" else game.shift.notice.text)
	if not hosting:
		game.shift.set_process(false)
		game.shift.oven.set_process(false)
		game.shift.corpses.set_physics_process(false)
		_ready_to_play.rpc_id(1, scene_epoch)

func _create_partner() -> void:
	partner = Node3D.new()
	game.add_child(partner)
	var visual := UNIFORM.add_character(partner, partner_model, partner_apron, partner_face)
	# Customer meshes face +Z; the first-person player's forward is -Z.
	visual.rotation.y = PI
	partner.name = "CoopPartner"
	partner_camera = Camera3D.new()
	partner_camera.current = false
	partner.add_child(partner_camera)
	partner_camera.position.y = game.camera.position.y
	partner_hand = Node3D.new()
	partner.add_child(partner_hand)
	partner_hand.position = Vector3(0, 1.15, -0.35)
	partner_hand.rotation.y = PI
	partner_hand_key = ""
	var label := Label3D.new()
	label.name = "PlayerName"
	label.text = partner_name
	label.position.y = 2.35
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("e6bb78")
	label.font_size = 32
	label.pixel_size *= minf(1.0, 12.0 / partner_name.length())
	partner.add_child(label)

func attach_hospital(room: Node3D) -> void:
	intro_scene = null
	game = room
	replicas.clear()
	mirror_bodies.clear()
	partner_ready = hosting and guest_loaded_epoch == scene_epoch
	wallet = room.earnings
	_create_partner()
	game.player.position.x += -0.55 if hosting else 0.55
	partner_target = game.player.position + Vector3(1.1 if hosting else -1.1, 0, 0)
	partner.position = partner_target
	if not hosting: _ready_to_play.rpc_id(1, scene_epoch)

@rpc("any_peer", "call_remote", "reliable")
func _ready_to_play(epoch: int) -> void:
	if hosting and multiplayer.get_remote_sender_id() == partner_id and epoch == scene_epoch:
		guest_loaded_epoch = epoch
		partner_ready = true
		connection_confirmed = true
		if not saved_guest_position.is_empty():
			_place_guest.rpc_id(partner_id, saved_guest_position[0], saved_guest_position[1], saved_guest_position[2])
			saved_guest_position.clear()

func _process(delta: float) -> void:
	if is_instance_valid(intro_scene) and not leaving:
		update_time += delta
		if hosting and partner_ready and update_time >= 0.08:
			update_time = 0.0
			_intro_state.rpc_id(partner_id, intro_scene.passage_index, intro_scene.narrative.visible_characters, intro_scene.complete, intro_scene.starting)
		return
	if leaving or not is_instance_valid(game) or not is_instance_valid(partner): return
	var walking := partner.position.distance_squared_to(partner_target) > 0.008
	partner.position = partner.position.lerp(partner_target, minf(delta * 20.0, 1.0))
	partner.rotation.y = lerp_angle(partner.rotation.y, partner_yaw, minf(delta * 20.0, 1.0))
	partner_camera.rotation.x = partner_pitch
	if game.scene_file_path == "res://main.tscn":
		game.shift.customer_line._pose(partner, sin(Time.get_ticks_msec() * 0.01) if walking else 0.0)
	if not hosting:
		for actor in replicas.values():
			actor.transform = actor.transform.interpolate_with(actor.get_meta("target_transform"), minf(delta * 20.0, 1.0))
	if hosting and not get_tree().paused and game.scene_file_path == "res://main.tscn":
		_tick_guest_cleaning(delta)
		_update_partner_hand(guest_item, guest_source, guest_coffee_cup, guest_soda_cup, guest_trash)
		if guest_item == "Pistol" and not game.shift.pistol.available():
			guest_item = ""
			guest_source = null
		if is_instance_valid(guest_body):
			for entry in game.shift.corpses.bodies:
				if entry.body == guest_body: game.shift.corpses._position_carried(entry, partner_camera)
	update_time += delta
	if update_time < 0.08: return
	update_time = 0.0
	if hosting and partner_ready:
		var packet := var_to_bytes(_snapshot()).compress(FileAccess.COMPRESSION_DEFLATE)
		_sync_shift.rpc_id(partner_id, packet)
	elif not hosting:
		_guest_pose.rpc_id(1, game.player.position, game.player.rotation.y, game.pitch, Input.is_action_pressed("interact"))

func attach_intro(scene: Control) -> void:
	intro_scene = scene
	game = null
	partner_ready = hosting and guest_loaded_epoch == scene_epoch
	if not hosting:
		scene.set_process(false)
		_ready_to_play.rpc_id(1, scene_epoch)

func intro_input() -> void:
	if not hosting:
		_intro_input.rpc_id(1)
		return
	if not is_instance_valid(intro_scene): return
	ui_applying = true
	intro_scene._continue()
	ui_applying = false

@rpc("any_peer", "call_remote", "reliable")
func _intro_input() -> void:
	if hosting and multiplayer.get_remote_sender_id() == partner_id: intro_input()

@rpc("authority", "call_remote", "reliable")
func _intro_state(page: int, characters: int, complete: bool, starting: bool) -> void:
	if hosting or not is_instance_valid(intro_scene): return
	connection_confirmed = true
	if intro_scene.passage_index != page:
		intro_scene.passage_index = page
		intro_scene._show_passage()
	if characters > intro_scene.narrative.visible_characters and not complete: intro_scene.key_audio.play()
	intro_scene.narrative.visible_characters = characters
	intro_scene.complete = complete
	intro_scene.starting = starting
	intro_scene.continue_button.text = "Open the Diner [E / Space]" if complete and page == intro_scene.PASSAGES.size() - 1 else "Continue [E / Space]" if complete else "Reveal sentence [E / Space]"
	intro_scene.goal_label.modulate.a = 1.0 if complete and page == intro_scene.PASSAGES.size() - 1 else 0.0

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _guest_pose(position: Vector3, yaw: float, pitch: float, cleaning: bool) -> void:
	if not hosting or not partner_ready or multiplayer.get_remote_sender_id() != partner_id: return
	if _valid_pose(position, yaw) and is_finite(pitch) and absf(pitch) < 1.51:
		partner_target = position
		partner_yaw = yaw
		partner_pitch = pitch
		last_pose_at = Time.get_ticks_msec()
		_update_cleaning_target(cleaning)

func _valid_pose(position: Vector3, yaw: float) -> bool:
	return position.is_finite() and is_finite(yaw) and absf(position.x) < 25.0 and absf(position.z) < 25.0 and absf(position.y) < 8.0

func request_action(return_item := false) -> void:
	_guest_action.rpc_id(1, game.player.position, game.player.rotation.y, game.pitch, return_item)

@rpc("any_peer", "call_remote", "reliable")
func _guest_action(position: Vector3, yaw: float, pitch: float, return_item: bool) -> void:
	if leaving or not hosting or not partner_ready or multiplayer.get_remote_sender_id() != partner_id: return
	if not is_instance_valid(game) or get_tree().paused: return
	if game.scene_file_path == "res://main.tscn" and game.shift.robbery.blackout.visible: return
	if not _valid_pose(position, yaw) or not is_finite(pitch) or absf(pitch) > 1.51: return
	var now := Time.get_ticks_msec()
	if now - last_action < 75 and not return_item: return
	last_action = now
	partner_target = position
	partner_yaw = yaw
	partner_pitch = pitch
	var direction := -Basis.from_euler(Vector3(pitch, yaw, 0)).z
	if game.scene_file_path == "res://hospital_room.tscn":
		var origin: Vector3 = position + Vector3.UP * game.camera.position.y
		var ray := PhysicsRayQueryParameters3D.create(origin, origin + direction * 2.6, 5, [game.player.get_rid()])
		var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
		var previous: String = game.target
		game.target = str(hit.collider.get_meta("action", "")) if not hit.is_empty() else ""
		acting_guest = true
		game.interact()
		acting_guest = false
		game.target = previous
		return
	if not return_item and guest_item == "Pistol":
		_apply_guest_interaction(null,false,func(): game.shift.pistol.fire_ray(position+Vector3.UP*2.0,direction))
		return
	var target: Dictionary = game.interaction_at(position + Vector3.UP * 2.0, direction)
	var action: Node = target.action
	if not return_item and not is_instance_valid(action):
		if is_instance_valid(target.door):
			if target.door.name == "Door_03" and game.shift.phase == "closed": game.shift.hospital_visits.open_departure()
			else: game._toggle_door(target.door)
		return
	if not return_item and action.get_meta("action", "") not in SUPPORTED_ACTIONS: return
	_apply_guest_interaction(action, return_item)

func _apply_guest_interaction(action: Node, return_item: bool, callback: Callable = Callable()) -> void:
	var shift = game.shift
	var host_hand := [shift.carried_item, shift.carried_source, shift.coffee_station.holding_empty, shift.soda_station.holding_empty, shift.carrying_trash, shift.dine_in.carried_table, shift.corpses.carried_body]
	host_carrying_body = host_hand[6]
	host_holding_pistol = host_hand[0] == "Pistol"
	shift.carried_item = guest_item
	shift.carried_source = guest_source
	shift.coffee_station.holding_empty = guest_coffee_cup
	shift.soda_station.holding_empty = guest_soda_cup
	shift.carrying_trash = guest_trash
	shift.dine_in.carried_table = guest_table
	shift.corpses.carried_body = guest_body
	var host_camera: Camera3D = game.camera
	game.camera = partner_camera
	acting_guest = true
	if callback.is_valid(): callback.call()
	elif return_item: shift.discard_last()
	else: shift.interact(action)
	acting_guest = false
	game.camera = host_camera
	host_carrying_body = null
	host_holding_pistol = false
	guest_item = shift.carried_item
	guest_source = shift.carried_source
	guest_coffee_cup = shift.coffee_station.holding_empty
	guest_soda_cup = shift.soda_station.holding_empty
	guest_trash = shift.carrying_trash
	guest_table = shift.dine_in.carried_table
	guest_body = shift.corpses.carried_body
	shift.carried_item = host_hand[0]
	shift.carried_source = host_hand[1]
	shift.coffee_station.holding_empty = host_hand[2]
	shift.soda_station.holding_empty = host_hand[3]
	shift.carrying_trash = host_hand[4]
	shift.held_trash.visible = host_hand[4]
	shift.dine_in.carried_table = host_hand[5]
	shift.corpses.carried_body = host_hand[6]
	shift.coffee_station.held_cup.visible = host_hand[2]
	shift.soda_station.held_cup.visible = host_hand[3]
	shift._refresh_carried()

func begin_dialogue(actor: Node3D, items: Array, reminder: bool) -> void:
	var lines: Array = game.shift.dialogue.make_pages(actor, items, reminder)
	show_shared_dialogue(lines)

func show_shared_dialogue(lines: Array) -> void:
	game.shift.dialogue.show_pages(lines)
	_broadcast_customer_dialogue()

@rpc("authority", "call_remote", "reliable")
func _show_dialogue(lines: Array, page: int, opened: bool, revealed: bool) -> void:
	if hosting or not is_instance_valid(game): return
	ui_applying = true
	var dialogue = game.shift.dialogue
	if opened:
		if not dialogue.is_open: dialogue.show_pages(lines)
		if dialogue.page != page:
			dialogue.page = page
			dialogue._show_page()
		if revealed: dialogue.typewriter.reveal()
	else:
		dialogue.finish()
	ui_applying = false

func _broadcast_customer_dialogue() -> void:
	var dialogue = game.shift.dialogue
	_show_dialogue.rpc_id(partner_id, dialogue.pages, dialogue.page, dialogue.is_open, not dialogue.typewriter.typing)

func customer_dialogue_input(close := false) -> void:
	if not hosting:
		_customer_dialogue_input.rpc_id(1, close)
		return
	ui_applying = true
	if close: game.shift.dialogue.finish()
	else: game.shift.dialogue.advance()
	ui_applying = false
	_broadcast_customer_dialogue()

@rpc("any_peer", "call_remote", "reliable")
func _customer_dialogue_input(close: bool) -> void:
	if hosting and multiplayer.get_remote_sender_id() == partner_id and is_instance_valid(game) and game.scene_file_path == "res://main.tscn":
		customer_dialogue_input(close)

func _snapshot() -> Dictionary:
	if game.scene_file_path == "res://hospital_room.tscn":
		return {"scene": game.scene_file_path, "epoch": scene_epoch, "progress": _wallet_state(game.earnings), "paused": get_tree().paused, "menu_paused": not pause_votes.is_empty(), "host": [game.player.position, game.player.rotation.y], "light": game.bedside_light.visible, "incident": game.incident.snapshot()}
	var shift = game.shift
	var actors := {}
	var line = shift.customer_line
	if is_instance_valid(shift.customer): _capture_actor(actors, shift.customer)
	for entry in line.waiting: _capture_actor(actors, entry.actor)
	for entry in line.departing: _capture_actor(actors, entry.actor)
	for entry in shift.dine_in.diners:
		_capture_actor(actors, entry.actor, {"items": entry.items, "table": entry.table, "seated": entry.state == "eating"})
	var pies := []
	for pie in shift.all_pies: pies.append([pie.visible, pie.get_meta("bake_quality", "raw")])
	var tray_sources := []
	for source in shift.tray_sources: tray_sources.append(SAVE.source_id(shift, source))
	var drinks := []
	for station in [shift.coffee_station, shift.soda_station]:
		drinks.append([station.state, station.cups_left, station.fill, station.drink_name, station.status.text])
	var door_states := []
	for door in game.doors: door_states.append([door.get_meta("open"), door.rotation.y])
	return {
		"scene": game.scene_file_path, "epoch": scene_epoch, "paused": get_tree().paused, "progress": _wallet_state(shift.earnings),
		"donuts": shift.donut_fryer.snapshot(), "burger": shift.burger_station.snapshot(),
		"bottles": shift.bottle_cooler.snapshot(),
		"training": [shift.tutorial.tutorial_state, shift.tutorial.practice_order_index],
		"phase": shift.phase, "remaining": shift.shift_remaining, "closing": shift.closing_time, "rush": shift.rush_started,
		"robbery_remaining": shift.robbery.remaining,
		"robbery_health": shift.robbery.health_state(),
		"order": shift.order, "taken": shift.order_taken, "cash": shift.earnings.cash, "notice": shift.notice.text,
		"actors": actors, "customer": str(shift.customer.get_instance_id()) if is_instance_valid(shift.customer) else "",
		"pies": pies, "tray": shift.tray, "tray_sources": tray_sources, "drinks": drinks, "doors": door_states,
		"oven": [shift.oven.pie_item, shift.oven.elapsed],
		"hand": [guest_item, SAVE.source_id(shift, guest_source), guest_coffee_cup, guest_soda_cup, guest_trash, guest_table],
		"host": [game.player.position, game.player.rotation.y],
		"host_hand": [shift.carried_item, SAVE.source_id(shift, shift.carried_source), shift.coffee_station.holding_empty, shift.soda_station.holding_empty, shift.carrying_trash],
		"menu_paused": not pause_votes.is_empty(),
		"tasks": shift.tasks, "trash": [shift.carrying_trash, guest_trash],
		"dirty": shift.dine_in.tables.map(func(table): return [table.dirty, is_instance_valid(table.trash) and table.trash.visible]),
		"missing": shift.restock.missing.map(func(pie): return SAVE.source_id(shift, pie)),
		"corpses": _capture_corpses(),
		"events": _capture_events(),
		"pistol": [shift.carried_item == "Pistol" or guest_item == "Pistol", shift.pistol.shot.playing, shift.pistol.drawer_open],
		"payment": [shift.payment_label.text, shift.payment_label.visible],
	}

func _capture_actor(actors: Dictionary, actor: Node3D, meal: Dictionary = {}) -> void:
	var skeleton: Skeleton3D = actor.get_meta("skeleton")
	var pose := []
	for i in skeleton.get_bone_count(): pose.append(skeleton.get_bone_pose_rotation(i))
	actors[str(actor.get_instance_id())] = [actor.transform, actor.get_meta("customer_model"), actor.get_meta("display_name"), actor.get_node("Interaction").get_meta("action"), pose, meal, actor.get_node("Visual").position]

@rpc("authority", "call_remote", "reliable")
func _sync_shift(packet: PackedByteArray) -> void:
	if hosting or leaving or not is_instance_valid(game): return
	var contents := packet.decompress_dynamic(262144, FileAccess.COMPRESSION_DEFLATE)
	if contents.is_empty(): return
	var decoded = bytes_to_var(contents)
	if not decoded is Dictionary: return
	var state: Dictionary = decoded
	if game.scene_file_path != state.scene or scene_epoch != state.epoch: return
	connection_confirmed = true
	get_tree().paused = state.paused
	_apply_wallet(wallet, state.progress)
	partner_target = state.host[0]
	partner_yaw = state.host[1]
	if game.scene_file_path == "res://hospital_room.tscn":
		game.bedside_light.visible = state.light
		game.incident.restore_visual(state.get("incident",{}))
		game.hospital_music.set_music_paused(state.menu_paused)
		return
	var shift = game.shift
	game.diner_music.set_music_paused(state.menu_paused)
	partner_target = state.host[0]
	partner_yaw = state.host[1]
	shift.phase = state.phase
	shift.tutorial.tutorial_state = state.training[0]
	shift.tutorial.practice_order_index = state.training[1]
	shift.donut_fryer.restore(state.get("donuts", {}))
	shift.bottle_cooler.restore(state.bottles)
	shift.burger_station.restore(state.get("burger", {}))
	shift.shift_remaining = state.remaining
	shift.robbery.remaining = state.robbery_remaining
	shift.closing_time = state.closing
	shift.set_rush_started(state.get("rush", false))
	shift.order.assign(state.order)
	shift.order_taken = state.taken
	shift.earnings.cash = state.cash
	_update_partner_hand(state.host_hand[0], SAVE.source_node(shift, state.host_hand[1]), state.host_hand[2], state.host_hand[3], state.host_hand[4])
	shift.notice.text = state.notice
	shift.payment_label.text = state.payment[0]
	shift.payment_label.visible = state.payment[1]
	if night != state.closing:
		night = state.closing
		game.set_night(night)
	_sync_actors(state.actors)
	shift.customer = replicas.get(state.customer)
	shift.robbery.restore_health(state.get("robbery_health", {}))
	shift.tasks.merge(state.tasks, true)
	for id in shift.tasks:
		var node: Node3D = shift.task_nodes[id]
		node.visible = shift.phase == "cleanup" and not shift.tasks[id] and id not in ["trash", "restock", "tables"]
		node.collision_layer = 4 if node.visible else 0
	var bag: Node3D = shift.task_nodes.trash
	bag.visible = shift.phase == "cleanup" and not shift.tasks.trash and not state.trash[0] and not state.trash[1]
	bag.collision_layer = 4 if bag.visible else 0
	_sync_tables(state.dirty)
	shift.restock.missing.clear()
	for index in state.missing: shift.restock.missing.append(SAVE.source_node(shift,index))
	shift.restock.cooler_target.collision_layer = 4 if shift.phase == "cleanup" else 0
	for i in shift.all_pies.size():
		var pie: Node3D = shift.all_pies[i]
		var value: Array = state.pies[i]
		if pie.visible != value[0]: shift._set_pickup_visible(pie, value[0])
		pie.set_meta("bake_quality", value[1])
	var sources := []
	for index in state.tray_sources: sources.append(SAVE.source_node(shift, index))
	if shift.tray != state.tray or shift.tray_sources != sources:
		shift.tray.assign(state.tray)
		shift.tray_sources.assign(sources)
		shift._refresh_tray()
	var source := SAVE.source_node(shift, state.hand[1])
	if state.hand[0] == "Table trash" and state.hand[5] >= 0: source = shift.dine_in.tables[state.hand[5]].trash
	if state.hand[0] == "Pistol": source = shift.pistol.pickup
	if shift.carried_item != state.hand[0] or shift.carried_source != source:
		shift.carried_item = state.hand[0]
		shift.carried_source = source
		shift._refresh_carried()
	shift._set_carrying_trash(state.hand[4])
	shift.dine_in.carried_table = state.hand[5]
	for i in range(2):
		var station = [shift.coffee_station, shift.soda_station][i]
		_sync_drink(station, state.drinks[i], state.hand[2 + i])
	for i in game.doors.size():
		var door: MeshInstance3D = game.doors[i]
		var opening: bool = not door.get_meta("open", false) and state.doors[i][0]
		door.set_meta("open", state.doors[i][0])
		door.rotation.y = state.doors[i][1]
		if opening and door.has_node("OpeningSound"): door.get_node("OpeningSound").play()
	var oven = shift.oven
	var old_item: String = oven.pie_item
	var old_elapsed: float = oven.elapsed
	oven.pie_item = state.oven[0]
	oven.elapsed = state.oven[1]
	if not oven.pie_item.is_empty() and old_elapsed < oven.PERFECT_AT and oven.quality() == "perfect":
		oven.ready_audio.play()
	if old_item != oven.pie_item or oven.shown_quality != oven.quality(): oven._refresh_visual()
	oven._update_display()
	_sync_corpses(state.corpses)
	_sync_events(state.events)
	shift.pistol.set_drawer_open(state.pistol[2])
	shift.pistol.refresh_pickup(state.pistol[0])
	if state.pistol[1] and not shift.pistol.shot.playing: shift.pistol.shot.play()
	shift._update_shift_clock()
	shift._update_cash_display()
	shift._refresh_hud()

func _sync_actors(actors: Dictionary) -> void:
	for id in replicas.keys():
		if not actors.has(id):
			if replicas[id].has_meta("network_meal"):
				var meal: Node = replicas[id].get_meta("network_meal")
				if is_instance_valid(meal): meal.queue_free()
			replicas[id].queue_free()
			replicas.erase(id)
	for id in actors:
		var data: Array = actors[id]
		if not replicas.has(id):
			var actor: Node3D = game.shift.customer_line.make_actor(data[0].origin, data[1])
			actor.transform = data[0]
			actor.set_meta("display_name", data[2])
			replicas[id] = actor
		var actor: Node3D = replicas[id]
		actor.set_meta("target_transform", data[0])
		actor.get_node("Interaction").set_meta("action", data[3])
		var skeleton: Skeleton3D = actor.get_meta("skeleton")
		for i in mini(skeleton.get_bone_count(), data[4].size()): skeleton.set_bone_pose_rotation(i, data[4][i])
		actor.get_node("Visual").position = data[6]
		if not data[5].is_empty():
			if not actor.has_meta("network_meal"):
				var meal: Node3D = game.shift.dine_in.meal_visual(data[5].items)
				actor.add_child(meal)
				actor.set_meta("network_meal", meal)
			var meal: Node3D = actor.get_meta("network_meal")
			if data[5].seated:
				meal.global_position = game.shift.dine_in.tables[data[5].table].top
				meal.global_rotation = Vector3.ZERO
			else:
				meal.position = Vector3(0, 1.05, 0.4)

func _sync_drink(station: Node, data: Array, holding: bool) -> void:
	if station.cups_left != data[1]:
		station.cups_left = data[1]
		station._rebuild_stack()
	if station.drink_name != data[3]:
		station.drink_name = data[3]
		if station.has_method("apply_flavor"): station.apply_flavor()
	station.state = data[0]
	station.holding_empty = holding
	station.held_cup.visible = holding
	station.machine_cup.visible = station.state != "empty"
	station.stream.visible = station.state == "brewing"
	station._fill_cup(data[2])
	if station.state != "brewing":
		for player in [station.get_node_or_null("CoffeePourSound"), station.get_node_or_null("FizzySodaPour")]:
			if player != null and player.playing: player.stop()
	station.status.text = data[4]

func _wallet_state(progress: RefCounted) -> Dictionary:
	var config := ConfigFile.new()
	progress.grandpa.write_config(config)
	return {"values": SAVE.properties(progress, SAVE.WALLET_FIELDS), "grandpa": config.encode_to_text()}

func _apply_wallet(progress: RefCounted, data: Dictionary) -> void:
	SAVE.apply(progress, data["values"], SAVE.WALLET_FIELDS)
	var config := ConfigFile.new()
	if config.parse(data.grandpa) == OK: progress.grandpa.read_config(config)

func _read_wallet(data: Dictionary) -> RefCounted:
	var progress = preload("res://earnings.gd").new(false)
	_apply_wallet(progress, data)
	return progress

func save_partner() -> Dictionary:
	var data := {"position": partner_target, "yaw": partner_yaw, "pitch": partner_pitch}
	if game.scene_file_path == "res://main.tscn":
		var shift = game.shift
		var body_index := -1
		for i in shift.corpses.bodies.size():
			if shift.corpses.bodies[i].body == guest_body: body_index = i
		data.merge({"item": guest_item, "source": SAVE.source_id(shift, guest_source), "coffee": guest_coffee_cup, "soda": guest_soda_cup, "trash": guest_trash, "table": guest_table, "body": body_index})
	return data

func restore_partner(data: Dictionary) -> void:
	partner_target = data.position
	partner_yaw = data.yaw
	partner_pitch = data.pitch
	saved_guest_position = [partner_target, partner_yaw, partner_pitch]
	if partner_ready:
		_place_guest.rpc_id(partner_id, partner_target, partner_yaw, partner_pitch)
		saved_guest_position.clear()
	if game.scene_file_path != "res://main.tscn": return
	var shift = game.shift
	guest_item = data.get("item", "")
	guest_source = SAVE.source_node(shift, data.get("source", -1))
	guest_coffee_cup = data.get("coffee", false)
	guest_soda_cup = data.get("soda", false)
	guest_trash = data.get("trash", false)
	guest_table = data.get("table", -1)
	if guest_item == "Table trash" and guest_table >= 0: guest_source = shift.dine_in.tables[guest_table].trash
	if guest_item == "Pistol": guest_source = shift.pistol.pickup
	var body_index: int = data.get("body", -1)
	if body_index >= 0 and body_index < shift.corpses.bodies.size():
		var entry: Dictionary = shift.corpses.bodies[body_index]
		_apply_guest_interaction(null, false, func(): shift.corpses._begin_carry(entry))

@rpc("authority", "call_remote", "reliable")
func _place_guest(position: Vector3, yaw: float, pitch: float) -> void:
	if hosting or not is_instance_valid(game): return
	game.player.position = position
	game.player.rotation.y = yaw
	game.pitch = pitch
	game.camera.rotation.x = pitch

func request_pause(paused: bool) -> void:
	if hosting: _set_pause_vote(1, paused)
	else: _pause_vote.rpc_id(1, paused)

@rpc("any_peer", "call_remote", "reliable")
func _pause_vote(paused: bool) -> void:
	if hosting and multiplayer.get_remote_sender_id() == partner_id: _set_pause_vote(partner_id, paused)

func _set_pause_vote(id: int, paused: bool) -> void:
	if paused: pause_votes[id] = true
	else: pause_votes.erase(id)
	get_tree().paused = not pause_votes.is_empty()

func restart_day() -> void:
	if not hosting: return
	pause_votes.clear()
	get_tree().paused = false
	var progress = game.shift.earnings if game.scene_file_path == "res://main.tscn" else game.earnings
	travel(game, game.scene_file_path, progress)

func travel(host: Node, destination: String, progress: RefCounted) -> void:
	if not hosting or transporting: return
	wallet = progress
	partner_ready = false
	scene_epoch += 1
	guest_cleaning = ""
	guest_body = null
	guest_item = ""
	guest_source = null
	_receive_travel.rpc_id(partner_id, destination, _wallet_state(wallet), scene_epoch)
	transporting = true
	preload("res://hospital_travel.gd").go(host, destination, wallet)
	transporting = false

@rpc("authority", "call_remote", "reliable")
func _receive_travel(destination: String, progress: Dictionary, epoch: int) -> void:
	if hosting or destination not in ["res://main.tscn", "res://hospital_room.tscn", "res://grandpa_ending.tscn", "res://grandpa_victory.tscn", "res://intro.tscn"]: return
	scene_epoch = epoch
	get_tree().paused = false
	wallet = _read_wallet(progress)
	transporting = true
	preload("res://hospital_travel.gd").go(self, destination, wallet)
	transporting = false

func modal_for_scene():
	if not is_instance_valid(game): return null
	if game.scene_file_path != "res://main.tscn": return game.conversation
	return game.shift.tutorial.lesson if game.shift.phase == "prep" else game.shift.hospital_visits.menu

func share_modal() -> void:
	if not hosting or ui_applying or not partner_ready: return
	var modal = modal_for_scene()
	var options := []
	for button in modal.footer.get_children(): options.append(button.text)
	_modal_state.rpc_id(partner_id, {"open": modal.is_open, "dialogue": modal.dialogue_mode, "pages": modal.pages, "page": modal.page, "title": modal.title.text, "text": modal.body.text, "options": options, "revealed": not modal.typewriter.typing})

@rpc("authority", "call_remote", "reliable")
func _modal_state(state: Dictionary) -> void:
	if hosting or not is_instance_valid(game): return
	var modal = modal_for_scene()
	if modal == null: return
	ui_applying = true
	if state.open:
		if not modal.is_open:
			get_tree().paused = false
			if state.dialogue:
				var lines: Array[String] = []
				lines.assign(state.pages)
				modal.show_dialogue(lines)
			else: modal.show_choices(state.title, state.text, state.options)
		if state.dialogue and modal.page != state.page:
			modal.page = state.page
			modal._update_page()
		if state.revealed: modal.typewriter.reveal()
	else: modal.finish()
	ui_applying = false

func modal_input(command: String, index := -1) -> void:
	if not hosting:
		_modal_input.rpc_id(1, command, index)
		return
	var modal = modal_for_scene()
	if modal == null or not modal.is_open: return
	ui_applying = true
	match command:
		"advance": modal.advance()
		"choose":
			if index >= 0 and index < modal.footer.get_child_count(): modal._choose(index)
		"close": modal.finish()
		"reveal": modal.typewriter.reveal()
	ui_applying = false
	share_modal()

@rpc("any_peer", "call_remote", "reliable")
func _modal_input(command: String, index: int) -> void:
	if hosting and multiplayer.get_remote_sender_id() == partner_id: modal_input(command, index)

func _update_cleaning_target(cleaning: bool) -> void:
	if not is_instance_valid(game) or game.scene_file_path != "res://main.tscn": return
	var next := ""
	if cleaning and game.shift.phase == "cleanup":
		var direction := -Basis.from_euler(Vector3(partner_pitch, partner_yaw, 0)).z
		var hit: Dictionary = game.interaction_at(partner_target + Vector3.UP * 2.0, direction)
		if is_instance_valid(hit.action) and hit.action.get_meta("action", "") == "task":
			var id: String = hit.action.get_meta("task", "")
			if id in ["bathroom", "kitchen"] and not game.shift.tasks[id]: next = id
	if guest_cleaning != next: guest_cleaning_time = 0.0
	guest_cleaning = next

func _tick_guest_cleaning(delta: float) -> void:
	if Time.get_ticks_msec() - last_pose_at > 500 or game.shift.phase != "cleanup":
		guest_cleaning = ""
	if guest_cleaning.is_empty(): return
	var shift = game.shift
	if shift.tasks[guest_cleaning]:
		guest_cleaning = ""
		return
	guest_cleaning_time += delta
	shift.scrubbing_audio.global_position = shift.task_nodes[guest_cleaning].global_position
	if not shift.scrubbing_audio.playing: shift.scrubbing_audio.play()
	if guest_cleaning_time >= 1.5:
		var finished := guest_cleaning
		guest_cleaning = ""
		guest_cleaning_time = 0.0
		shift.complete_task(finished)

func _sync_tables(dirty: Array) -> void:
	var dining = game.shift.dine_in
	for i in mini(dirty.size(), dining.tables.size()):
		var table: Dictionary = dining.tables[i]
		if table.dirty != dirty[i][0]:
			table.dirty = dirty[i][0]
			if table.dirty: dining.make_trash(i)
			elif is_instance_valid(table.trash):
				table.trash.queue_free()
				table.trash = null
		if is_instance_valid(table.trash):
			table.trash.visible = dirty[i][1]
			table.trash.collision_layer = 4 if table.trash.visible else 0

func _update_partner_hand(item: String, source: Node3D, coffee: bool, soda: bool, trash: bool) -> void:
	var quality: String = str(source.get_meta("bake_quality", "")) if is_instance_valid(source) else ""
	var key := "%s/%s/%s/%s/%s" % [item, quality, coffee, soda, trash]
	if key == partner_hand_key: return
	partner_hand_key = key
	for child in partner_hand.get_children(): child.queue_free()
	var shift = game.shift
	if trash:
		var bag := preload("res://assets/trashbag/trashbag_a.glb").instantiate()
		partner_hand.add_child(bag)
		bag.scale = Vector3.ONE * 1.5
	elif coffee or soda:
		var station = shift.coffee_station if coffee else shift.soda_station
		station._cup(partner_hand)
	elif item == "Table trash":
		shift.dine_in.trash_visual(partner_hand)
	elif not item.is_empty() and item != "Carrying body":
		shift._item_model(partner_hand, item, Vector3.ZERO, 0.9, source)

func partner_sees(point: Vector3, radius: float, threshold: float, door: Node = null) -> bool:
	if not partner_ready or not is_instance_valid(partner_camera): return false
	var origin := partner_target + Vector3.UP * 2
	var forward := -Basis.from_euler(Vector3(partner_pitch, partner_yaw, 0)).z
	var direction := point - origin
	if direction.length() > radius or forward.dot(direction.normalized()) < threshold: return false
	var ray := PhysicsRayQueryParameters3D.create(origin, point, 1, [game.player.get_rid()])
	var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or (door != null and door.is_ancestor_of(hit.collider))

func _capture_corpses() -> Dictionary:
	var bodies := {}
	for entry in game.shift.corpses.bodies:
		bodies[str(entry.body.get_instance_id())] = {
			"actor": SAVE.actor_data(entry.actor), "transform": entry.body.transform,
			"pose": preload("res://customer_ragdoll.gd").snapshot(entry.ragdoll),
			"guest_carries": entry.body == guest_body,
		}
	return bodies

func _sync_corpses(bodies: Dictionary) -> void:
	var corpses = game.shift.corpses
	for id in mirror_bodies.keys():
		if not bodies.has(id):
			var entry: Dictionary = mirror_bodies[id]
			corpses.bodies.erase(entry)
			entry.body.queue_free()
			mirror_bodies.erase(id)
	corpses.carried_body = null
	for id in bodies:
		var data: Dictionary = bodies[id]
		if not mirror_bodies.has(id):
			var actor := SAVE.restore_actor(game.shift.customer_line, data.actor)
			var entry: Dictionary = corpses.kill(actor, false)
			mirror_bodies[id] = entry
			for bone in entry.ragdoll.bones:
				PhysicsServer3D.body_set_mode(bone.get_rid(), PhysicsServer3D.BODY_MODE_KINEMATIC)
		var entry: Dictionary = mirror_bodies[id]
		entry.body.transform = data.transform
		preload("res://customer_ragdoll.gd").restore(entry.ragdoll, data.pose)
		if data.guest_carries: corpses.carried_body = entry.body

func _capture_events() -> Dictionary:
	var event = game.shift.closing_events
	var light_energy := []
	for light in game.get_node_or_null("NightInteriorLights").get_children() if game.has_node("NightInteriorLights") else []:
		if light is Light3D: light_energy.append(light.light_energy)
	var streams := []
	for sound in [event.effect_audio, event.monster_audio, game.shift.scrubbing_audio]:
		streams.append([sound.playing, sound.stream.resource_path if sound.stream != null else "", sound.global_position, sound.pitch_scale])
	return {"visible": event.figure.visible, "transform": event.figure.transform, "dissolve": maxf(0.0, event.dissolve_elapsed / event.DISSOLVE_SECONDS), "lights": light_energy, "sounds": streams, "gassy_pie": event.gassy_pie.closing_state()}

func _sync_events(data: Dictionary) -> void:
	var event = game.shift.closing_events
	var pie: Dictionary = data.get("gassy_pie", {})
	if pie.is_empty() or not event.gassy_pie.visible or pie.get("settled", false) != event.gassy_pie.settled:
		event.gassy_pie.restore_closing(pie)
	event.figure.visible = data.visible
	event.figure.transform = data.transform
	event._set_dissolve(data.dissolve)
	if data.visible and data.dissolve > 0 and not event.shadow_wisps.emitting:
		event.shadow_wisps.global_position = event.figure.global_position + Vector3(0,1.25,0)
		event.shadow_wisps.visible = true
		event.shadow_wisps.restart()
		event.shadow_wisps.emitting = true
	if not data.visible: event.shadow_wisps.emitting = false
	if game.has_node("NightInteriorLights"):
		var lights := game.get_node("NightInteriorLights").get_children()
		for i in mini(data.lights.size(), lights.size()): lights[i].light_energy = data.lights[i]
	var sounds := [event.effect_audio, event.monster_audio, game.shift.scrubbing_audio]
	for i in sounds.size():
		var source: Array = data.sounds[i]
		var sound: AudioStreamPlayer3D = sounds[i]
		if source[0]:
			if not source[1].is_empty() and (sound.stream == null or sound.stream.resource_path != source[1]): sound.stream = load(source[1])
			sound.global_position = source[2]
			sound.pitch_scale = source[3]
			if sound.stream != null and not sound.playing: sound.play()
		elif sound.playing: sound.stop()

func _peer_disconnected(id: int) -> void:
	if id == partner_id: leave("Your partner left the shift.")

func share_bell() -> void:
	if hosting and partner_ready: _hear_bell.rpc_id(partner_id)

func share_blood(at: Vector3, normal: Vector3, headshot: bool) -> void:
	if hosting and partner_ready: _blood_impact.rpc_id(partner_id,at,normal,headshot)

@rpc("authority", "call_remote", "unreliable")
func _blood_impact(at: Vector3, normal: Vector3, headshot: bool) -> void:
	if is_instance_valid(game) and game.scene_file_path == "res://main.tscn": preload("res://bullet_blood.gd").impact(game.shift,at,normal,headshot)

func share_shot(guest_fired: bool) -> void:
	if hosting and partner_ready: _hear_shot.rpc_id(partner_id, guest_fired)

func share_robber_shot(at: Vector3) -> void:
	if hosting and partner_ready: _robber_missed.rpc_id(partner_id,at)

@rpc("authority", "call_remote", "unreliable")
func _robber_missed(at: Vector3) -> void:
	if is_instance_valid(game) and game.scene_file_path == "res://main.tscn": game.shift.robbery.play_enemy_shot(at)

func share_robbery_failure(stolen: int, practice: bool) -> void:
	if hosting and partner_ready: _show_robbery_failure.rpc_id(partner_id, stolen, practice)

@rpc("authority", "call_remote", "reliable")
func _show_robbery_failure(stolen: int, practice: bool) -> void:
	if not hosting and is_instance_valid(game) and game.scene_file_path == "res://main.tscn":
		game.shift.robbery.show_blackout(stolen, practice)

@rpc("authority", "call_remote", "reliable")
func _hear_shot(guest_fired: bool) -> void:
	if hosting or not is_instance_valid(game): return
	game.shift.pistol.shot.play()
	var local_camera: Camera3D = game.camera
	if not guest_fired: game.camera = partner_camera
	game.shift.pistol.muzzle_flash()
	game.camera = local_camera

@rpc("authority", "call_remote", "reliable")
func _hear_bell() -> void:
	if not hosting and is_instance_valid(game): game.shift.service_bell.play_ding()

func _connection_failed() -> void:
	leave("Connection ended. Check the host address and UDP port %d." % PORT)

func _check_connection_timeout() -> void:
	await get_tree().create_timer(15.0).timeout
	if not leaving and not connection_confirmed:
		leave("Could not start co-op. Both players need the same build and a reachable host.")

func leave(message := "You left the co-op shift.") -> void:
	if leaving: return
	leaving = true
	_return_to_lobby.call_deferred(message)

func _return_to_lobby(message: String) -> void:
	var tree := get_tree()
	tree.root.set_meta("coop_status", message)
	shutdown()
	tree.change_scene_to_file("res://coop_lobby.tscn")

func shutdown() -> void:
	leaving = true
	get_tree().paused = false
	if get_tree().root.has_meta("pie_day_wallet") and get_tree().root.get_meta("pie_day_wallet") == wallet:
		get_tree().root.remove_meta("pie_day_wallet")
	var peer := multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer: peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	queue_free()
