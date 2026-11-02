extends SceneTree
const SAVES := preload("res://save_states.gd")
var failures := 0
var directory := "user://save_state_test_"+str(Time.get_ticks_usec())
func _initialize() -> void: call_deferred("run")
func require(ok: bool,message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for i in range(100): await process_frame
func await_loaded(path: String) -> void:
	for i in range(2400):
		await process_frame
		if current_scene != null and current_scene.scene_file_path == path and not root.has_meta("hospital_travel_busy") and current_scene.process_mode != Node.PROCESS_MODE_DISABLED: return
	require(false,"Loading timed out: "+path)
func run() -> void:
	var wallet = preload("res://earnings.gd").new(false)
	wallet.cash = 1200
	wallet.grandpa.days = 7
	wallet.grandpa.health = 62
	root.set_meta("pie_day_wallet",wallet)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.shift.start_demo()
	var shift = game.shift
	shift.set_process(false)
	game.set_physics_process(false)
	shift.customer_line.next_arrival = INF
	for i in range(620): shift._process(1.0/60)
	require(shift.phase == "waiting","Test customer reaches counter")
	shift.order_taken = true
	shift.shift_remaining = 91.5
	shift.service_seconds = 12
	shift.earnings.streak = 4
	shift.earnings.correct_orders = 3
	shift.all_pies[0].set_meta("bake_quality","perfect")
	shift.all_pies[0].set_meta("bake_seconds",9.0)
	shift.add_item(shift.all_pies[0].get_meta("item"),shift.all_pies[0])
	shift._set_pickup_visible(shift.all_pies[0],false)
	shift.pickup_item(shift.all_pies[1].get_meta("item"),shift.all_pies[1])
	shift.oven.pie_source = shift.all_pies[2]
	shift.oven.pie_item = shift.all_pies[2].get_meta("item")
	shift.oven.elapsed = 8.7
	shift._set_pickup_visible(shift.all_pies[2],false)
	shift.coffee_station.state = "brewing"
	shift.coffee_station.fill = .4
	shift.coffee_station.cups_left = 9
	shift.coffee_station.status.text = "FILLING COFFEE..."
	shift.customer_line.waiting.append({"actor":shift.customer_line.make_actor(Vector3(0.2,-.094,1)),"seconds":22.0,"junction":true})
	var data := SAVES.capture(game)
	require(SAVES.write(1,data,directory) == OK,"Write a manual slot")
	require(SAVES.write(2,data,directory) == OK,"Write a second slot")
	var loaded := SAVES.read(1,directory)
	require(not loaded.is_empty() and loaded.shift.shift_remaining == 91.5,"Slot preserves midshift timer")
	data.wallet.cash = 1234
	require(SAVES.write(1,data,directory) == OK and SAVES.read(1,directory).wallet.cash == 1234,"Atomic overwrite updates the selected slot")
	require(SAVES.read(2,directory).wallet.cash == 1200,"Overwriting one slot leaves another untouched")
	require(SAVES.read(3,directory).is_empty(),"Empty slot is unavailable")
	# Reach the death screen, then recover the living campaign through its UI.
	shift.earnings.grandpa.health = 1
	shift.begin_cleanup()
	for task in shift.tasks: shift.complete_task(task)
	await settle()
	require(current_scene.scene_file_path == "res://grandpa_ending.tscn","Test reaches death ending")
	var ending = current_scene
	ending.saves.directory = directory
	ending.saves.open(false)
	require(ending.saves.rows.get_child_count() == 3 and ending.saves.rows.get_child(2).disabled,"Load UI exposes three slots and disables empty slots")
	ending.saves.choose(1)
	require(ending.saves.confirm.visible,"Loading requires explicit confirmation")
	ending.saves.execute(1)
	await await_loaded("res://main.tscn")
	game = current_scene
	shift = game.shift
	shift.set_process(false)
	game.set_physics_process(false)
	require(game.scene_file_path == "res://main.tscn" and shift.phase == "waiting","Loading after death restores the active shift")
	require(shift.earnings.cash == 1234 and shift.earnings.grandpa.health == 62 and shift.earnings.grandpa.days == 7,"Health, cash and campaign day roll back")
	require(shift.shift_remaining <= 91.5 and shift.shift_remaining > 89,"Loaded clock resumes from saved time: "+str(shift.shift_remaining))
	require(shift.order == data.shift.order and shift.order_taken and shift.customer.get_meta("display_name") == data.customer.display_name,"Customer identity and order survive")
	require(shift.customer.get_meta("customer_model") == data.customer.model and shift.customer_line.waiting.size() == 1,"Actor model and queue survive")
	require(shift.tray == data.shift.tray and shift.tray_sources[0] == shift.all_pies[0],"Tray restores pie references")
	require(shift.carried_source == shift.all_pies[1] and shift.carried_item == data.shift.carried_item,"Held pie restores its source")
	require(shift.all_pies[0].get_meta("bake_quality") == "perfect" and not shift.all_pies[0].visible,"Pie stock and baking quality survive")
	require(shift.earnings.streak == 4 and shift.earnings.correct_orders == 3,"Daily earnings counters survive")
	require(shift.oven.pie_source == shift.all_pies[2] and shift.oven.elapsed >= 8.7 and shift.oven.elapsed < 9,"Oven restores source and bake timer")
	require(shift.coffee_station.state == "brewing" and shift.coffee_station.fill >= .4 and shift.coffee_station.fill < .7 and shift.coffee_station.cups_left == 9,"Coffee fill tween resumes from saved progress")
	require(not paused and not shift.earnings.save_enabled,"Loading leaves input enabled without modifying the actual user save in tests")
	# Closing duties and trash must also be recoverable.
	shift.begin_cleanup()
	shift.complete_task("bathroom")
	shift._set_carrying_trash(true)
	var cleanup := SAVES.capture(game)
	SAVES.load_state(game,cleanup,false)
	await settle()
	game = current_scene
	shift = game.shift
	shift.set_process(false)
	require(shift.phase == "cleanup" and shift.tasks.bathroom and not shift.tasks.kitchen and shift.carrying_trash,"Closing task/trash state is restored")
	# Hospital saves return to the same position and keep campaign/visit state.
	var hospital_wallet = preload("res://earnings.gd").new(false)
	hospital_wallet.cash = 2000
	hospital_wallet.grandpa.days = 4
	hospital_wallet.grandpa.evening_pending = true
	hospital_wallet.grandpa.start_visit()
	preload("res://hospital_travel.gd").go(game,"res://hospital_room.tscn",hospital_wallet)
	await settle()
	var room = current_scene
	room.player.position = Vector3(2,.03,1)
	room.bedside_light.visible = false
	var hospital := SAVES.capture(room)
	SAVES.write(3,hospital,directory)
	SAVES.load_state(room,SAVES.read(3,directory),false)
	await settle()
	room = current_scene
	require(room.scene_file_path == "res://hospital_room.tscn" and room.earnings.grandpa.visit_in_progress,"Hospital visit resumes from save")
	require(room.player.position.distance_to(hospital.player.origin) < .1 and not room.bedside_light.visible,"Hospital position and light state survive")
	if DisplayServer.get_name() != "headless":
		room.paused.pause_game()
		room.paused.saves.directory = directory
		room.paused.saves.open(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/save-load-slots.png")
		room.paused.saves.close()
		room.paused.resume_game()
	for slot in range(1,4): DirAccess.remove_absolute("%s/slot_%d.cfg" % [directory,slot])
	DirAccess.remove_absolute(directory)
	if failures == 0: print("PASS: three independent slots, overwrite, midshift restore, death recovery, orders/queue/food, closing duties, hospital state and no writes to real saves")
	current_scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
