extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for i in range(100): await process_frame
func check_layout(menu: CanvasLayer, context: String) -> void:
	var panel = menu.body.get_parent().get_parent()
	var box: Rect2 = panel.get_global_rect()
	require(box.position.y >= 0 and box.end.y <= root.size.y,context+": panel must fit on screen")
	require(box.grow(1).encloses(menu.title.get_global_rect()),context+": title must stay inside panel")
	require(box.grow(1).encloses(menu.body.get_global_rect()),context+": text must stay inside panel")
	require(box.grow(1).encloses(menu.footer.get_global_rect()),context+": buttons must stay inside panel")
func run() -> void:
	var wallet = preload("res://earnings.gd").new(false)
	wallet.cash = 640
	require(not wallet.grandpa.visit_available(),"No visit before first completed shift")
	wallet.start_day()
	wallet.finish_day()
	require(wallet.grandpa.visit_available() and wallet.grandpa.days == 1,"First visit is after Day 1")
	var health: int = wallet.grandpa.health
	root.set_meta("pie_day_wallet",wallet)
	var diner = load("res://main.tscn").instantiate()
	root.add_child(diner)
	current_scene = diner
	var shift = diner.shift
	await process_frame
	require(shift.phase == "closed","Reloading finished duties restores evening")
	shift.phase = "cleanup"
	shift.hospital_visits.open_departure()
	require(not shift.hospital_visits.menu.is_open,"No departure while duties remain")
	shift.phase = "closed"
	shift.hospital_visits.open_departure()
	require(shift.hospital_visits.menu.is_open and paused,"Departure choices pause gameplay")
	for i in range(4): await process_frame
	check_layout(shift.hospital_visits.menu,"Visit choices")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/visit-choice-layout.png")
	shift.hospital_visits.menu.typewriter.reveal()
	shift.hospital_visits.menu._choose(2)
	require(not paused and wallet.grandpa.visit_available(),"Staying preserves visit opportunity")
	shift.hospital_visits.open_departure()
	shift.hospital_visits.menu.typewriter.reveal()
	shift.hospital_visits.menu._choose(0)
	await settle()
	var hospital = current_scene
	require(hospital.scene_file_path == "res://hospital_room.tscn","Visit choice travels to hospital")
	require(hospital.earnings == wallet and wallet.grandpa.visit_in_progress,"Wallet and visit state survive scene change")
	var config := ConfigFile.new()
	wallet.grandpa.write_config(config)
	var restored = preload("res://grandpa_progress.gd").new()
	restored.read_config(config)
	require(restored.visit_in_progress and restored.evening_pending and restored.next_visit_day == 4,"Saving preserves an in-progress visit and schedule")
	var bed = hospital.get_node("Furniture/Bed")
	hospital.player.position = bed.global_position + Vector3(1.05,.03,-.35)
	await process_frame
	hospital.camera.look_at(bed.get_node("TalkToGrandpa").global_position)
	for i in range(3): await physics_frame
	require(hospital.target == "grandpa","Bedside conversation must be reachable through the actual interaction ray")
	hospital.interact()
	require(hospital.conversation.is_open and paused,"Bedside interaction opens paused dialogue")
	for i in range(4): await process_frame
	check_layout(hospital.conversation,"Grandpa dialogue")
	require(hospital.conversation.pages[0].contains("first day") and " ".join(hospital.conversation.pages).contains("$640"),"Dialogue reflects first visit and savings")
	while hospital.conversation.is_open: hospital.conversation.advance()
	require(not paused and hospital.interaction_release_required,"Conversation closes without reopening on held E")
	if DisplayServer.get_name() != "headless":
		hospital.target = "grandpa"
		hospital.interact()
		hospital.conversation.typewriter.reveal()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/hospital-visit-dialogue.png")
		hospital.conversation.finish()
	hospital.target = "exit"
	hospital.interact()
	await settle()
	require(current_scene.scene_file_path == "res://main.tscn" and current_scene.shift.phase == "prep","Leaving hospital starts next morning")
	require(wallet.grandpa.days == 1 and wallet.grandpa.health == health and wallet.cash == 640,"Visit never charges cash or advances health/day twice")
	require(not wallet.grandpa.evening_pending and not wallet.grandpa.visit_in_progress,"Visit resolves evening once")
	for i in range(2):
		wallet.start_day()
		wallet.finish_day()
		require(not wallet.grandpa.visit_available(),"Days 2 and 3 are outside visiting hours")
		wallet.grandpa.finish_evening()
	wallet.start_day()
	wallet.finish_day()
	require(wallet.grandpa.visit_available() and wallet.grandpa.days == 4,"Next visit opens Day 4")
	wallet.grandpa.finish_evening()
	require(wallet.grandpa.next_visit_day == 7 and not wallet.grandpa.visit_available(),"Going home skips this visit and schedules the next")
	wallet.grandpa.health = 20
	require(" ".join(wallet.grandpa.visit_dialogue(640)).contains("I'm weak"),"Dialogue responds to critical health")
	require(" ".join(wallet.grandpa.visit_dialogue(15000)).contains("surgery money is there"),"Dialogue recognizes funded treatment")
	if failures == 0: print("PASS: first/recurring visits, closing gate, choices, fades, bedside dialogue, save/resume state, next morning, health/cash preservation and skipping")
	current_scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
