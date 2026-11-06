extends SceneTree

func _initialize() -> void: call_deferred("run")

func settle() -> void:
	await create_timer(1.1).timeout

func run() -> void:
	var demo = preload("res://playable_demo.gd").new()
	demo.name = "PlayableDemo"
	root.add_child(demo)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var shift = game.shift
	assert(shift.earnings == demo.wallet and not demo.wallet.save_enabled)
	assert(demo.wallet.cash == 0 and shift.phase == "prep")
	var clipboard := Node.new()
	clipboard.set_meta("action", "clock")
	shift.add_child(clipboard)
	shift.interact(clipboard)
	var lesson = shift.get_node("TutorialLesson")
	assert(lesson.is_open and paused)
	lesson.typewriter.reveal()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var panel: Control = lesson.body.get_parent().get_parent()
		assert(Rect2(Vector2.ZERO, root.size).encloses(panel.get_global_rect()))
	lesson._choose(0)
	assert(shift.is_practicing())
	shift.interact(clipboard)
	assert(shift.phase == "prep")
	shift.coffee_station.interact("coffee")
	assert(shift.coffee_station.state == "empty")
	shift.coffee_station.interact("cup_stack")
	assert(shift.coffee_station.holding_empty)
	shift.coffee_station.interact("coffee")
	assert(shift.coffee_station.state == "brewing")
	await create_timer(3.0).timeout
	assert(shift.coffee_station.state == "ready")
	shift.coffee_station.interact("coffee")
	assert(shift.carried_item == "Coffee" and shift.place_carried())
	assert(shift.pickup_item("Glazed donut") and shift.place_carried())
	shift.service_bell.ring()
	assert(demo.practice_order_index == 1 and shift.is_practicing() and shift.tray.is_empty())
	shift.soda_station.choose_flavor("Cola")
	assert(shift.soda_station.state == "empty")
	shift.soda_station.interact("soda_cup_stack")
	shift.soda_station.choose_flavor("Cola")
	await create_timer(2.1).timeout
	assert(shift.soda_station.state == "ready")
	shift.soda_station.choose_flavor("Cola")
	assert(shift.carried_item == "Cola" and shift.place_carried())
	var apple: Node3D
	for pie in shift.all_pies:
		if pie.get_meta("item") == "Apple pie":
			apple = pie
			break
	assert(is_instance_valid(apple) and shift.pickup_item("Apple pie", apple))
	for door in shift.oven.doors: game._set_door_open(door, true)
	shift.oven.interact()
	assert(shift.oven.pie_item == "Apple pie")
	for door in shift.oven.doors: game._set_door_open(door, false)
	await create_timer(5.9).timeout
	assert(shift.oven.quality() == "perfect")
	for door in shift.oven.doors: game._set_door_open(door, true)
	shift.oven.interact()
	assert(shift.carried_item == "Apple pie" and shift.place_carried())
	shift.service_bell.ring()
	assert(demo.tutorial_state == "done" and shift.tray.is_empty())
	assert(apple.get_meta("bake_quality") == "raw" and shift.soda_station.cups_left == 10)
	assert(demo.wallet.cash == 0 and shift.phase == "prep")
	shift.interact(clipboard)
	assert(shift.phase == "arriving")
	shift._spawn_customer()
	assert(shift.order == ["Glazed donut", "Coffee"])
	assert(shift.customer_line.nude_chance == 0.0)
	shift.begin_cleanup()
	assert(shift.closing_events.encounter == "figure")
	shift.closing_events.on_trash_disposed()
	assert(shift.closing_events.awaiting_doorway_scare())
	shift.closing_events.figure_done = true
	for task in shift.tasks: shift.tasks[task] = true
	shift._show_day_summary()
	assert(shift.phase == "closed")
	shift.hospital_visits.open_departure()
	shift.hospital_visits.menu.typewriter.reveal()
	shift.hospital_visits.menu._choose(1)
	assert(current_scene == game and not paused)
	shift.hospital_visits.open_departure()
	shift.hospital_visits.menu.typewriter.reveal()
	shift.hospital_visits.menu._choose(0)
	await settle()
	var hospital = current_scene
	assert(hospital.scene_file_path == "res://hospital_room.tscn")
	assert(hospital.earnings == demo.wallet)
	hospital.target = "exit"
	hospital.interact()
	assert(hospital.conversation.is_open and not hospital.leaving)
	hospital.conversation.finish()
	hospital.target = "grandpa"
	hospital.interact()
	while hospital.conversation.is_open: hospital.conversation.advance()
	assert(demo.talked_to_grandpa)
	hospital.target = "exit"
	hospital.interact()
	await settle()
	assert(current_scene.scene_file_path == "res://demo_ending.tscn")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/demo-ending.png")
	demo.restart()
	await settle()
	assert(current_scene.scene_file_path == "res://intro.tscn")
	assert(demo.wallet.cash == 0 and not demo.talked_to_grandpa and not demo.wallet.save_enabled)
	print("PLAYABLE DEMO PASS: tutorial, isolated wallet, orders, cleanup, hospital gate, ending, replay")
	quit()
