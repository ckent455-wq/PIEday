extends SceneTree
var failures := 0
func _initialize(): call_deferred("check")
func require(value: bool, message: String):
	if not value:
		push_error(message)
		failures += 1
func check():
	var incident_count := 0
	var nurse_count := 0
	for seed_value in range(1,5001):
		var weighted = preload("res://grandpa_progress.gd").new()
		weighted.days = 2
		weighted.setback_seed = seed_value
		weighted.advance_day(false)
		if weighted.last_setback_day == 3:
			incident_count += 1
			if weighted.last_setback_id == "mistreatment": nurse_count += 1
		var no_repeat = preload("res://grandpa_progress.gd").new()
		no_repeat.days = 8
		no_repeat.last_setback_day = 3
		no_repeat.last_setback_id = "mistreatment"
		no_repeat.setback_seed = seed_value
		no_repeat.advance_day(false)
		require(no_repeat.last_setback_day != 9 or no_repeat.last_setback_id != "mistreatment", "Nurse weighting preserves no consecutive repeats")
	require(incident_count > 500 and incident_count < 700,"Overall eligible-day setback rate remains about twelve percent")
	var nurse_share := float(nurse_count)/maxi(1,incident_count)
	require(nurse_share > 0.29 and nurse_share < 0.38,"Nurse represents about one third of first setbacks")
	var examples: Dictionary = {}
	for seed_value in range(1, 600):
		var progress = preload("res://grandpa_progress.gd").new()
		progress.days = 2
		progress.health = 90
		progress.setback_seed = seed_value
		var before := ConfigFile.new()
		progress.write_config(before)
		var reloaded = preload("res://grandpa_progress.gd").new()
		reloaded.read_config(before)
		progress.advance_day(false)
		reloaded.advance_day(false)
		require(progress.health == reloaded.health and progress.setback_history == reloaded.setback_history, "Loading before a day cannot reroll outcome")
		if progress.last_setback_day == 3:
			var event: Dictionary = progress.setback_history.back()
			if event.event_id == "mistreatment":
				require(event.health_loss == 22, "Nurse incident removes 20 health points plus normal 2-point daily decline")
			else:
				require(event.health_loss >= 10 and event.health_loss <= 14, "Incident records significant actual loss")
			require(progress.setback_history.size() == 1, "Each incident is recorded once")
			if not examples.has(event.event_id): examples[event.event_id] = progress
		if examples.size() == 5: break
	require(examples.size() == 5, "All five incident types are possible")
	require(" ".join(examples.wrong_meds.visit_dialogue(0)).contains("They gave me the wrong meds and now my blood is on fire!"), "Wrong-medication setback delivers the requested dialogue")
	require(" ".join(examples.chemo.visit_dialogue(0)).contains("I asked for less cancer, not less Grandpa."), "Chemo setback delivers the requested bedside dialogue")
	var sample = examples.mistreatment
	require(" ".join(sample.visit_dialogue(0)).contains("A nurse hit me"), "Mistreatment is explained at bedside")
	var saved := ConfigFile.new()
	sample.write_config(saved)
	var restored = preload("res://grandpa_progress.gd").new()
	restored.read_config(saved)
	require(restored.last_setback_day == 3 and restored.last_setback_id == "mistreatment" and restored.setback_history.back().event_id == "mistreatment", "Incident and metadata survive saving")
	for i in range(5):
		var before_health: int = restored.health
		restored.advance_day(false)
		require(restored.health == before_health - 2, "Six-day spacing prevents clustered health shocks")
	var funded = preload("res://grandpa_progress.gd").new()
	funded.read_config(saved)
	var health: int = funded.health
	funded.advance_day(true)
	require(funded.health == health and " ".join(funded.visit_dialogue(15000)).contains("surgery money is there"), "Surgery funding prevents setbacks")
	var wallet = preload("res://earnings.gd").new(false)
	wallet.grandpa.days = 2
	wallet.grandpa.health = 90
	wallet.grandpa.setback_seed = sample.setback_seed
	wallet.start_day()
	wallet.finish_day()
	health = wallet.grandpa.health
	wallet.finish_day()
	require(wallet.grandpa.health == health and wallet.grandpa.days == 3, "Repeat finish cannot apply incident twice")
	if DisplayServer.get_name() != "headless":
		var game = load("res://main.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		game.shift.set_process(false)
		game.set_physics_process(false)
		game.shift.earnings.save_enabled = false
		game.shift.earnings.grandpa = sample
		var clipboard = game.shift.get_node("Station_clock")
		var prompt: String = game.shift.action_prompt(clipboard)
		require(prompt.contains("Recent setback"), "Clipboard flags sudden decline")
		game.interaction_label.text = prompt
		game.interaction_label.show()
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/grandpa-setback-hud.png")
	if failures == 0: print("PASS: significant setbacks, bedside updates, spacing, stable saved outcomes, funding protection, no duplicate damage and HUD indicator")
	quit(1 if failures else 0)
