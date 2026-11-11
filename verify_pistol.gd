extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func require(ok: bool, message: String):
	if not ok:
		push_error(message)
		failures += 1
func run():
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.start_demo()
	var drawer = shift.pistol.drawer
	var eye := Vector3(-2.35, 1.91, -5.85)
	await physics_frame
	require(not shift.pistol.pickup.visible and shift.pistol.pickup.collision_layer == 0, "Closed drawer hides the gun")
	require(game.interaction_at(eye, eye.direction_to(drawer.global_position)).action == drawer, "Drawer can be targeted from behind the counter")
	shift.interact(drawer)
	shift.pistol.tick()
	await create_timer(0.3).timeout
	var gun_center: Vector3 = shift.pistol.pickup.global_position + Vector3.UP * 0.04
	require(game.interaction_at(eye, eye.direction_to(gun_center)).action == shift.pistol.pickup, "Open drawer exposes a reachable pickup")
	shift.pistol.take()
	require(shift.carried_item.is_empty(),"Pistol unavailable outside special encounter")
	shift.customer_line.force_nude_next = true
	shift.customer_line.next_arrival = INF
	for i in 240: shift._process(1.0/60)
	require(shift.refusal_required() and shift.phase == "waiting","Encounter reaches counter")
	shift.dialogue.finish()
	shift.interact(drawer)
	shift.pistol.tick()
	shift.pistol.take()
	require(shift.carried_item.is_empty() and not shift.pistol.pickup.visible, "Closed drawer blocks pickup during the encounter")
	shift.interact(drawer)
	shift.pistol.take()
	require(shift.carried_item == "Pistol","Kitchen pickup equips pistol")
	shift.pistol.tick()
	require(not shift.pistol.pickup.visible,"Kitchen model hidden while held")
	require(not shift.place_carried() and shift.tray.is_empty(),"Pistol cannot enter tray")
	var other = StaticBody3D.new()
	other.set_meta("action","customer")
	root.add_child(other)
	require(not shift.pistol.fire(other),"Unrelated customer cannot be targeted")
	shift.discard_last()
	shift.pistol.tick()
	require(shift.carried_item.is_empty() and shift.pistol.pickup.visible,"Q returns pistol")
	shift.pistol.take()
	var cash = shift.earnings.cash
	var actor = shift.customer
	var target = actor.get_node("Interaction")
	require(shift.pistol.fire(target),"Encounter target accepts shot")
	require(shift.carried_item.is_empty() and shift.pistol.pickup.visible,"Shot returns pistol")
	require(actor.get_node("Interaction").get_meta("action") == "corpse","Shot creates a body instead of a departing customer")
	require(shift.corpses.bodies.size() == 1,"Body persists in diner")
	require(shift.earnings.cash == cash and shift.lost == 0,"No order penalty")
	require(not shift.pistol.fire(target),"No duplicate shot")
	require(shift.phase == "robbery_cleanup", "Shooting the robber suspends service")
	var time_left: float = shift.shift_remaining
	shift.customer_line.next_arrival = 0
	for i in 60: shift._process(1.0 / 60.0)
	require(not is_instance_valid(shift.customer) and shift.customer_line.waiting.is_empty(), "Customers stay away while the body is inside")
	require(shift.shift_remaining == time_left, "The service clock pauses during disposal")
	await physics_frame
	require(shift.corpses.bodies[0].ragdoll.bones.size() >= 10,"Death uses articulated physical bones")
	shift.corpses.grab(target)
	require(is_instance_valid(shift.corpses.carried_body) and shift.carried_item == "Carrying body","Body can be picked up")
	game.player.position.x += 1
	shift.corpses._physics_process(1.0/60)
	var hip: PhysicalBone3D = shift.corpses.bodies[0].ragdoll.hip
	require(hip.global_position.distance_to(game.camera.to_global(Vector3(0,-.85,-1.15))) < .01,"Carried body follows player without dragging")
	for bone in shift.corpses.bodies[0].ragdoll.bones:
		require(bone.collision_layer == 0 and PhysicsServer3D.body_get_mode(bone.get_rid()) == PhysicsServer3D.BODY_MODE_KINEMATIC,"Carried body stays fixed without collision forces")
	var saved: Dictionary = shift.corpses.snapshot()
	shift.corpses.restore(saved)
	require(shift.corpses.bodies.size() == 1 and is_instance_valid(shift.corpses.carried_body),"Body and drag state survive restore")
	var saves = preload("res://save_states.gd")
	var config := ConfigFile.new()
	config.set_value("save","state",saves.capture(game))
	var decoded := ConfigFile.new()
	require(decoded.parse(config.encode_to_text()) == OK,"Body state serializes without node references")
	saves.restore(game,decoded.get_value("save","state"))
	require(shift.corpses.bodies.size() == 1 and is_instance_valid(shift.corpses.carried_body) and shift.carried_item == "Carrying body","Full save restores body and held drag state")
	shift.discard_last()
	require(not is_instance_valid(shift.corpses.carried_body) and shift.carried_item.is_empty(),"Q releases body")
	for bone in shift.corpses.bodies[0].ragdoll.bones:
		require(bone.collision_layer == 4 and PhysicsServer3D.body_get_mode(bone.get_rid()) == PhysicsServer3D.BODY_MODE_RIGID,"Setting body down restores ragdoll physics")
	var body = shift.corpses.bodies[0].body
	shift.corpses.grab(body)
	shift.interact(game.find_child("OutdoorDumpster", true, false))
	require(shift.corpses.bodies.is_empty(), "Dumpster disposal removes the body")
	require(shift.phase == "leaving", "Disposing of the body reopens service")
	for i in 240: shift._process(1.0 / 60.0)
	require(shift.phase == "waiting" and is_instance_valid(shift.customer), "New customers arrive after disposal")
	shift.begin_cleanup()
	var legacy_save: Dictionary = saves.capture(game)
	legacy_save.shift.tasks.bodies = false
	saves.restore(game, legacy_save)
	require(not shift.tasks.has("bodies") and not shift.order_text.text.contains("Dispose of bodies"), "Closing ignores the retired task in older saves")
	other.free()
	if failures == 0: print("PASS: pistol restrictions, ragdoll, body pickup, fixed carry pose, Q set down, save/load and disposal")
	quit(failures)
