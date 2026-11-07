extends Node

const PORT := 27841
const PROTOCOL := 1
const SAVE := preload("res://save_states.gd")
const SERVICE_ACTIONS := ["clock", "pie", "donut", "tray", "coffee", "cup_stack", "soda", "soda_cup_stack", "oven", "bell", "customer"]
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

static func active(node: Node):
	return node.get_tree().root.get_node_or_null("CoopSession")

func connect_game(as_host: bool, address: String) -> Error:
	hosting = as_host
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, 1) if hosting else peer.create_client(address, PORT)
	if error != OK: return error
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_connection_failed)
	multiplayer.multiplayer_peer = peer
	return OK

func _peer_connected(id: int) -> void:
	if not hosting: return
	partner_id = id
	_enter_diner.rpc_id(id, PROTOCOL)
	_load_diner.call_deferred()

@rpc("authority", "call_remote", "reliable")
func _enter_diner(version: int) -> void:
	if hosting: return
	if version != PROTOCOL:
		leave("Your partner is using a different co-op build.")
		return
	partner_id = 1
	_load_diner.call_deferred()

func _load_diner() -> void:
	if leaving: return
	get_tree().root.set_meta("pie_day_wallet", preload("res://earnings.gd").new(false))
	get_tree().change_scene_to_file("res://main.tscn")

func attach(diner: Node3D) -> void:
	game = diner
	partner = game.shift.customer_line.make_actor(Vector3.ZERO, "male_1" if not hosting else "female_1")
	partner.get_node("Interaction").free()
	partner.reparent(game, false)
	partner.name = "CoopPartner"
	var label := Label3D.new()
	label.text = "PARTNER"
	label.position.y = 2.35
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("e6bb78")
	label.font_size = 32
	partner.add_child(label)
	game.player.position = Vector3(-2.4 if hosting else -0.9, 0.03, -5.8)
	game.spawn_point = game.player.position
	game.player.rotation.y = PI
	partner_target = Vector3(-0.9 if hosting else -2.4, 0.03, -5.8)
	partner.position = partner_target
	partner_yaw = PI
	game.shift.customer_line.nude_chance = 0.0
	game.shift.dine_in.dine_chance = 0.0
	game.shift._message("Online co-op. Use the clipboard to open the shared shift.")
	if not hosting:
		game.shift.set_process(false)
		game.shift.oven.set_process(false)
		_ready_to_play.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _ready_to_play() -> void:
	if hosting and multiplayer.get_remote_sender_id() == partner_id:
		partner_ready = true

func _process(delta: float) -> void:
	if leaving or not is_instance_valid(game) or not is_instance_valid(partner): return
	var walking := partner.position.distance_squared_to(partner_target) > 0.008
	partner.position = partner.position.lerp(partner_target, minf(delta * 20.0, 1.0))
	partner.rotation.y = lerp_angle(partner.rotation.y, partner_yaw, minf(delta * 20.0, 1.0))
	game.shift.customer_line._pose(partner, sin(Time.get_ticks_msec() * 0.01) if walking else 0.0)
	if not hosting:
		for actor in replicas.values():
			actor.transform = actor.transform.interpolate_with(actor.get_meta("target_transform"), minf(delta * 20.0, 1.0))
	update_time += delta
	if update_time < 0.08: return
	update_time = 0.0
	if hosting and partner_ready:
		var packet := var_to_bytes(_snapshot()).compress(FileAccess.COMPRESSION_DEFLATE)
		_sync_shift.rpc_id(partner_id, packet)
	elif not hosting:
		_guest_pose.rpc_id(1, game.player.position, game.player.rotation.y)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _guest_pose(position: Vector3, yaw: float) -> void:
	if not hosting or not partner_ready or multiplayer.get_remote_sender_id() != partner_id: return
	if _valid_pose(position, yaw):
		partner_target = position
		partner_yaw = yaw

func _valid_pose(position: Vector3, yaw: float) -> bool:
	return position.is_finite() and is_finite(yaw) and absf(position.x) < 25.0 and absf(position.z) < 25.0 and absf(position.y) < 8.0

func request_action(return_item := false) -> void:
	_guest_action.rpc_id(1, game.player.position, game.player.rotation.y, game.pitch, return_item)

@rpc("any_peer", "call_remote", "reliable")
func _guest_action(position: Vector3, yaw: float, pitch: float, return_item: bool) -> void:
	if leaving or not hosting or not partner_ready or multiplayer.get_remote_sender_id() != partner_id: return
	if not is_instance_valid(game) or game.shift.phase == "closed": return
	if not _valid_pose(position, yaw) or not is_finite(pitch) or absf(pitch) > 1.51: return
	var now := Time.get_ticks_msec()
	if now - last_action < 75: return
	last_action = now
	partner_target = position
	partner_yaw = yaw
	var direction := -Basis.from_euler(Vector3(pitch, yaw, 0)).z
	var target: Dictionary = game.interaction_at(position + Vector3.UP * 2.0, direction)
	var action: Node = target.action
	if not return_item and not is_instance_valid(action):
		if is_instance_valid(target.door): game._toggle_door(target.door)
		return
	if not return_item and action.get_meta("action", "") not in SERVICE_ACTIONS: return
	_apply_guest_interaction(action, return_item)

func _apply_guest_interaction(action: Node, return_item: bool) -> void:
	var shift = game.shift
	var host_hand := [shift.carried_item, shift.carried_source, shift.coffee_station.holding_empty, shift.soda_station.holding_empty]
	shift.carried_item = guest_item
	shift.carried_source = guest_source
	shift.coffee_station.holding_empty = guest_coffee_cup
	shift.soda_station.holding_empty = guest_soda_cup
	if return_item: shift.discard_last()
	else: shift.interact(action)
	guest_item = shift.carried_item
	guest_source = shift.carried_source
	guest_coffee_cup = shift.coffee_station.holding_empty
	guest_soda_cup = shift.soda_station.holding_empty
	shift.carried_item = host_hand[0]
	shift.carried_source = host_hand[1]
	shift.coffee_station.holding_empty = host_hand[2]
	shift.soda_station.holding_empty = host_hand[3]
	shift.coffee_station.held_cup.visible = host_hand[2]
	shift.soda_station.held_cup.visible = host_hand[3]
	shift._refresh_carried()

func finish_service() -> void:
	var shift = game.shift
	if shift.phase == "closed": return
	shift.customer_line.evacuate()
	shift._reset_customer()
	shift._clear_tray(true)
	shift.phase = "closed"
	shift.closing_time = true
	shift.order_taken = false
	shift.earnings.finish_day()
	shift._update_cash_display()
	game.set_night(true)
	shift._message("CO-OP SHIFT COMPLETE\n%d correct orders · $%d earned together\nPress Esc and choose Leave Co-op to return to the lobby." % [shift.earnings.correct_orders, shift.earnings.cash])
	shift.notice_time = 0.0

func _snapshot() -> Dictionary:
	var shift = game.shift
	var actors := {}
	var line = shift.customer_line
	if is_instance_valid(shift.customer): _capture_actor(actors, shift.customer)
	for entry in line.waiting: _capture_actor(actors, entry.actor)
	for entry in line.departing: _capture_actor(actors, entry.actor)
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
		"phase": shift.phase, "remaining": shift.shift_remaining, "closing": shift.closing_time,
		"order": shift.order, "taken": shift.order_taken, "cash": shift.earnings.cash, "notice": shift.notice.text,
		"actors": actors, "customer": str(shift.customer.get_instance_id()) if is_instance_valid(shift.customer) else "",
		"pies": pies, "tray": shift.tray, "tray_sources": tray_sources, "drinks": drinks, "doors": door_states,
		"oven": [shift.oven.pie_item, shift.oven.elapsed],
		"hand": [guest_item, SAVE.source_id(shift, guest_source), guest_coffee_cup, guest_soda_cup],
		"host": [game.player.position, game.player.rotation.y],
	}

func _capture_actor(actors: Dictionary, actor: Node3D) -> void:
	actors[str(actor.get_instance_id())] = [actor.transform, actor.get_meta("customer_model"), actor.get_meta("display_name"), actor.get_node("Interaction").get_meta("action")]

@rpc("authority", "call_remote", "unreliable_ordered")
func _sync_shift(packet: PackedByteArray) -> void:
	if hosting or leaving or not is_instance_valid(game): return
	var contents := packet.decompress_dynamic(65536, FileAccess.COMPRESSION_DEFLATE)
	if contents.is_empty(): return
	var decoded = bytes_to_var(contents)
	if not decoded is Dictionary: return
	var state: Dictionary = decoded
	var shift = game.shift
	partner_target = state.host[0]
	partner_yaw = state.host[1]
	shift.phase = state.phase
	shift.shift_remaining = state.remaining
	shift.closing_time = state.closing
	shift.order.assign(state.order)
	shift.order_taken = state.taken
	shift.earnings.cash = state.cash
	shift.notice.text = state.notice
	if night != state.closing:
		night = state.closing
		game.set_night(night)
	_sync_actors(state.actors)
	shift.customer = replicas.get(state.customer)
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
	if shift.carried_item != state.hand[0] or shift.carried_source != source:
		shift.carried_item = state.hand[0]
		shift.carried_source = source
		shift._refresh_carried()
	for i in range(2):
		var station = [shift.coffee_station, shift.soda_station][i]
		_sync_drink(station, state.drinks[i], state.hand[2 + i])
	for i in game.doors.size():
		var door: MeshInstance3D = game.doors[i]
		door.set_meta("open", state.doors[i][0])
		door.rotation.y = state.doors[i][1]
	var oven = shift.oven
	var old_item: String = oven.pie_item
	var old_elapsed: float = oven.elapsed
	oven.pie_item = state.oven[0]
	oven.elapsed = state.oven[1]
	if not oven.pie_item.is_empty() and old_elapsed < oven.PERFECT_AT and oven.quality() == "perfect":
		oven.ready_audio.play()
	if old_item != oven.pie_item or oven.shown_quality != oven.quality(): oven._refresh_visual()
	oven._update_display()
	shift._update_shift_clock()
	shift._update_cash_display()
	shift._refresh_hud()

func _sync_actors(actors: Dictionary) -> void:
	for id in replicas.keys():
		if not actors.has(id):
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

func _peer_disconnected(id: int) -> void:
	if id == partner_id: leave("Your partner left the shift.")

func share_bell() -> void:
	if hosting and partner_ready: _hear_bell.rpc_id(partner_id)

@rpc("authority", "call_remote", "reliable")
func _hear_bell() -> void:
	if not hosting and is_instance_valid(game): game.shift.service_bell.play_ding()

func _connection_failed() -> void:
	leave("Connection ended. Check the host address and UDP port %d." % PORT)

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
	var peer := multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer: peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	queue_free()
