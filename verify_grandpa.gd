extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("check")
func require(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func check() -> void:
	var wallet = preload("res://earnings.gd").new(false)
	wallet.cash = 640
	wallet.start_day()
	wallet.finish_day()
	require(wallet.grandpa.days == 1 and wallet.grandpa.health == 98,"First completed shift advances health once")
	wallet.finish_day()
	require(wallet.grandpa.days == 1 and wallet.grandpa.health == 98,"Repeated completion does not damage health twice")
	var progress = wallet.grandpa
	var previous := -1
	for day in [1,4,7,10,13,19]:
		progress.days = day
		progress.health = 100
		require(progress.desperation_stage() > previous,"Time increases desperation even with good health")
		previous = progress.desperation_stage()
		var lines: String = " ".join(progress.visit_dialogue(640))
		require(lines.contains("$640") and lines.contains("$14360") and not lines.to_lower().contains("letter"),"Every visit gives current savings without letter references")
	progress.days = 1
	progress.health = 20
	require(progress.desperation_stage() == 5,"Critical health accelerates desperation")
	require(" ".join(progress.visit_dialogue(640)).contains("I'm begging"),"Late desperation includes direct pleas")
	var relief: String = " ".join(progress.visit_dialogue(15000))
	require(relief.contains("surgery money is there") and not relief.contains("I'm begging"),"Funding replaces desperate money pleas with relief")
	var legacy := ConfigFile.new()
	legacy.set_value("grandpa","days",7)
	legacy.set_value("grandpa","health",66)
	legacy.set_value("grandpa","last_setback_day",3)
	legacy.set_value("grandpa","last_setback_id","fall")
	legacy.set_value("grandpa","letters",[{"day":3,"kind":"setback","event_id":"fall","health_before":90,"health_after":78,"health_loss":12}])
	legacy.set_value("grandpa","next_letter_day",8)
	var restored = preload("res://grandpa_progress.gd").new()
	restored.read_config(legacy)
	require(restored.days == 7 and restored.health == 66 and restored.setback_history.size() == 1,"Old saves retain health, days and incident history")
	require(" ".join(restored.visit_dialogue(640)).contains("I fell"),"Unreported incidents remain available after skipped visits")
	restored.write_config(legacy)
	require(not legacy.has_section_key("grandpa","letters") and not legacy.has_section_key("grandpa","next_letter_day"),"Retired archive is removed on saving")
	restored.finish_visit_conversation()
	restored.write_config(legacy)
	var reloaded = preload("res://grandpa_progress.gd").new()
	reloaded.read_config(legacy)
	require(not " ".join(reloaded.visit_dialogue(640)).contains("I fell"),"Finished conversation persists incident acknowledgement")
	wallet.cash = 15000
	var before: int = progress.health
	wallet.start_day()
	wallet.finish_day()
	require(progress.health == before,"Funding still stops health decline")
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.shift.start_demo()
	game.shift.begin_cleanup()
	for task in game.shift.tasks: game.shift.complete_task(task)
	game.shift._process(.1)
	require(game.shift.phase == "closed" and not paused,"Closing finishes without a letter popup")
	require(game.find_children("GrandpaLetters","",true,false).is_empty(),"Letter reader is removed")
	var clipboard = game.shift.get_node("Station_clock")
	var prompt: String = game.shift.action_prompt(clipboard)
	require(prompt.contains("98%") and not prompt.contains("[L]"),"Clipboard shows current health without a letter shortcut")
	var key := InputEventKey.new()
	key.keycode = KEY_L
	key.pressed = true
	root.push_input(key)
	require(not paused,"L does not open an archive")
	if failures == 0: print("PASS: escalating visit dialogue, health urgency, funding relief, legacy migration, incident acknowledgement, no letter UI or shortcut, once-per-day health")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
