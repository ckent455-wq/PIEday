extends SceneTree

const SESSION := preload("res://coop_session.gd")
var session
var game
var shift
var hosting := false

func _initialize():
	call_deferred("run")

func wait_for(predicate: Callable, timeout := 8.0) -> bool:
	var end := Time.get_ticks_msec() + int(timeout * 1000)
	while not predicate.call():
		if Time.get_ticks_msec() >= end: return false
		await process_frame
	return true

func aim_at(point: Vector3, feet: Vector3, action: String) -> void:
	game.player.position = feet
	await physics_frame
	game.face_point(point)
	await physics_frame
	game._update_interaction()
	assert(is_instance_valid(game.target_action) and game.target_action.get_meta("action") == action, "Ray misses " + action)
	session.request_action()
	await create_timer(.2).timeout

func run():
	if "host" not in OS.get_cmdline_user_args() and "guest" not in OS.get_cmdline_user_args():
		await coordinate()
		return
	hosting = "host" in OS.get_cmdline_user_args()
	session = SESSION.new()
	session.name = "CoopSession"
	root.add_child(session)
	if hosting: session.wallet = preload("res://earnings.gd").new(false)
	assert(session.connect_game(hosting, "127.0.0.1", int(OS.get_cmdline_user_args()[-1])) == OK)
	if not hosting:
		assert(await wait_for(func(): return is_instance_valid(session.intro_scene)))
		while is_instance_valid(session.intro_scene) and not session.intro_scene.starting:
			session.intro_input()
			await create_timer(.12).timeout
	assert(await wait_for(func(): return is_instance_valid(session.game)))
	game = session.game
	shift = game.shift
	game.set_physics_process(false)
	assert(not shift.earnings.save_enabled)
	if hosting:
		assert(await wait_for(func(): return session.partner_ready))
		shift.customer_line.nude_chance = 0.0
		shift.dine_in.mess_chance = 0.0
		assert(shift.start_shift(false))
		assert(await wait_for(func(): return shift.phase == "waiting"))
		shift.order.assign(["Glazed donut", "Coffee"])
		shift.interact(shift.customer.get_node("Interaction"))
		assert(shift.dialogue.is_open and paused)
		assert(await wait_for(func(): return not shift.dialogue.is_open))
		assert(not paused)
		assert(shift.pickup_item("Glazed donut"))
		assert(await wait_for(func(): return session.guest_coffee_cup))
		assert(shift.carried_item == "Glazed donut" and not shift.coffee_station.holding_empty)
		var saved: Dictionary = preload("res://save_states.gd").capture(game)
		session._apply_guest_interaction(null, true)
		assert(not session.guest_coffee_cup)
		preload("res://save_states.gd").restore(game, saved)
		assert(session.guest_coffee_cup and shift.carried_item == "Glazed donut")
		assert(shift.place_carried())
		assert(await wait_for(func(): return shift.tray.has("Coffee")))
		assert(shift.tray == ["Glazed donut", "Coffee"])
		shift.order_taken = true
		shift.dine_in.dine_chance = 1.0
		assert(shift.serve_order())
		assert(shift.dine_in.diners.size() == 1)
		await create_timer(.6).timeout
		shift.begin_cleanup()
		assert(shift.phase == "cleanup")
		var fallen = shift.customer_line.make_actor(Vector3(-1,-.094,-5.5),"adult_unclothed")
		shift.corpses.kill(fallen)
		assert(await wait_for(func(): return is_instance_valid(session.guest_body), 8.0))
		assert(await wait_for(func(): return not is_instance_valid(session.guest_body), 5.0))
		shift.corpses.reset()
		shift.tasks.bodies = true
		shift.closing_events.reset()
		shift.closing_events.active = true
		shift.closing_events.encounter = "figure"
		shift.closing_events.figure_done = false
		shift.closing_events._place_figure()
		shift.closing_events.figure.visible = true
		await create_timer(.5).timeout
		assert(await wait_for(func(): return shift.tasks.kitchen, 8.0))
		for id in shift.tasks.keys(): shift.complete_task(id)
		assert(shift.phase == "closed" and shift.earnings.correct_orders == 1)
		shift.hospital_visits.open_departure()
		assert(await wait_for(func(): return is_instance_valid(session.game) and session.game.scene_file_path == "res://hospital_room.tscn", 8.0))
		game = session.game
		assert(await wait_for(func(): return session.partner_ready))
		game.target = "grandpa"
		game.interact()
		assert(await wait_for(func(): return not game.conversation.is_open))
		game.target = "exit"
		game.interact()
		assert(await wait_for(func(): return is_instance_valid(session.game) and session.game.scene_file_path == "res://main.tscn", 8.0))
		assert(session.game.shift.phase == "prep" and session.game.shift.earnings.grandpa.days == 1)
		assert(await wait_for(func(): return not is_instance_valid(session), 10.0))
		print("PASS: authoritative shared dialogue, independent hands, closing, hospital and next day")
	else:
		assert(await wait_for(func(): return shift.phase == "waiting" and shift.order.has("Glazed donut") and shift.order.has("Coffee")))
		assert(is_instance_valid(shift.customer))
		assert(await wait_for(func(): return shift.dialogue.is_open))
		assert(paused)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://builds/coop-dialogue.png")
		while shift.dialogue.is_open:
			shift.dialogue.advance()
			await create_timer(.15).timeout
		assert(not paused)
		var machine = shift.coffee_station
		session.request_pause(true)
		assert(await wait_for(func(): return paused))
		var stopped_at: float = shift.shift_remaining
		await create_timer(.2).timeout
		assert(is_equal_approx(shift.shift_remaining, stopped_at))
		session.request_pause(false)
		assert(await wait_for(func(): return not paused))
		var feet := Vector3(-2.4, -0.09, -5.5)
		await aim_at(machine.stack.global_position + Vector3.UP * .2, feet, "cup_stack")
		assert(await wait_for(func(): return machine.holding_empty and shift.tray.has("Glazed donut")))
		await aim_at(machine.global_position, feet, "coffee")
		assert(await wait_for(func(): return machine.state == "ready"))
		await aim_at(machine.global_position, feet, "coffee")
		assert(await wait_for(func(): return shift.carried_item == "Coffee"))
		var tray = shift.held_tray
		var tray_feet = Vector3(tray.global_position.x, -.09, -5.45)
		await aim_at(tray.global_position + Vector3.UP * .05, tray_feet, "tray")
		assert(await wait_for(func():
			for actor in session.replicas.values():
				if actor.get_node("Interaction").get_meta("action") == "dining_customer" and actor.has_meta("network_meal"): return true
			return false
		))
		assert(await wait_for(func(): return shift.phase == "cleanup" and shift.earnings.cash > 145))
		assert(await wait_for(func(): return session.mirror_bodies.size() == 1))
		await create_timer(.8).timeout
		var corpse: Dictionary = session.mirror_bodies.values()[0]
		var hip: Vector3 = corpse.ragdoll.hip.global_position
		var reached := false
		for bone in corpse.ragdoll.bones:
			var point: Vector3 = bone.global_position
			game.player.position = Vector3(point.x,-.09,point.z-1.0)
			game.face_point(point)
			await physics_frame
			game._update_interaction()
			if is_instance_valid(game.target_action) and game.target_action.get_meta("action") == "corpse":
				session.request_action()
				reached = true
				break
		assert(reached, "Ragdoll must be reachable on the guest")
		assert(await wait_for(func(): return shift.carried_item == "Carrying body"))
		session.request_action(true)
		assert(await wait_for(func(): return shift.carried_item.is_empty()))
		assert(await wait_for(func(): return shift.closing_events.figure.visible))
		var chore: Node3D = shift.task_nodes.kitchen
		game.player.position = Vector3(chore.global_position.x, -.09, chore.global_position.z + .6)
		game.face_point(chore.global_position + Vector3.UP * .15)
		Input.action_press("interact")
		assert(await wait_for(func(): return shift.tasks.kitchen, 5.0))
		Input.action_release("interact")
		assert(await wait_for(func(): return shift.phase == "closed"))
		assert(await wait_for(func(): return shift.hospital_visits.menu.is_open))
		var modal = shift.hospital_visits.menu
		modal._choose(0)
		await create_timer(.2).timeout
		modal._choose(0)
		assert(await wait_for(func(): return is_instance_valid(session.game) and session.game.scene_file_path == "res://hospital_room.tscn", 8.0))
		game = session.game
		assert(await wait_for(func(): return game.conversation.is_open))
		while game.conversation.is_open:
			game.conversation.advance()
			await create_timer(.15).timeout
		assert(await wait_for(func(): return is_instance_valid(session.game) and session.game.scene_file_path == "res://main.tscn", 8.0))
		assert(session.game.shift.earnings.grandpa.days == 1)
		print("PASS: shared dialogue and pause, remote drink, closing chores, hospital visit and next day")
		session.shutdown()
	quit()

func coordinate() -> void:
	var folder := ProjectSettings.globalize_path("res://.godot/verification")
	DirAccess.make_dir_recursive_absolute(folder)
	var host_log := folder.path_join("coop-campaign-host.log")
	var guest_log := folder.path_join("coop-campaign-guest.log")
	var script := "res://verify_coop_campaign.gd"
	var arguments := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", script, "--max-fps", "120", "--quit-after", "5400"])
	var port := str(30000 + OS.get_process_id() % 15000)
	var host_args := arguments.duplicate()
	host_args.append_array(["--log-file", host_log, "--", "--coop-lobby", "host", port])
	var host_pid := OS.create_process(OS.get_executable_path(), host_args)
	if host_pid < 0:
		push_error("Could not start co-op host check")
		quit(1)
		return
	await create_timer(.3).timeout
	var guest_args := arguments.duplicate()
	guest_args.append_array(["--log-file", guest_log, "--", "--coop-lobby", "guest", port])
	var guest_pid := OS.create_process(OS.get_executable_path(), guest_args)
	if guest_pid < 0:
		OS.kill(host_pid)
		push_error("Could not start co-op guest check")
		quit(1)
		return
	var end := Time.get_ticks_msec() + 43000
	while (OS.is_process_running(host_pid) or OS.is_process_running(guest_pid)) and Time.get_ticks_msec() < end:
		await process_frame
	var ok := true
	for item in [[host_pid,host_log],[guest_pid,guest_log]]:
		if OS.is_process_running(item[0]):
			OS.kill(item[0])
			ok = false
		var log_text := FileAccess.get_file_as_string(item[1])
		if not log_text.contains("PASS:") or log_text.contains("SCRIPT ERROR") or log_text.contains("Assertion failed"):
			push_error(log_text)
			ok = false
	if ok: print("PASS: two-peer story, dialogue and pause, independent hands and saves, dining meals, ragdoll carrying, replicated scare, closing chores, hospital and next day")
	quit(0 if ok else 1)
