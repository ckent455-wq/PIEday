extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for i in range(100): await process_frame
func run() -> void:
	var wallet = preload("res://earnings.gd").new(false)
	wallet.grandpa.health = 1
	wallet.grandpa.days = 20
	wallet.start_day()
	wallet.finish_day()
	require(wallet.grandpa.health == 0 and wallet.grandpa.death_day == 21,"Daily decline can kill Grandpa at zero")
	require(not wallet.grandpa.visit_available() and not wallet.grandpa.visit_in_progress,"Death cancels evening visits")
	var day: int = wallet.grandpa.days
	wallet.start_day()
	wallet.finish_day()
	var paid: Dictionary = wallet.payout(["Coffee"],true,10,false)
	require(wallet.grandpa.days == day and paid.total == 0,"Ended campaigns cannot advance or earn money")
	wallet.grandpa.advance_day(true)
	require(wallet.grandpa.is_dead() and wallet.grandpa.days == day,"Funding cannot resurrect an ended campaign")
	var config := ConfigFile.new()
	wallet.grandpa.write_config(config)
	var restored = preload("res://grandpa_progress.gd").new()
	restored.read_config(config)
	require(restored.is_dead() and restored.death_day == 21 and restored.condition() == "Deceased","Death survives save/load")
	var fatal_setback := false
	for seed_value in range(1,600):
		var sample = preload("res://grandpa_progress.gd").new()
		sample.health = 8
		sample.days = 2
		sample.setback_seed = seed_value
		sample.advance_day(false)
		if sample.last_setback_day == 3:
			require(sample.is_dead() and sample.health == 0 and sample.death_day == 3,"A setback can be fatal without negative health")
			fatal_setback = true
			break
	require(fatal_setback,"Fatal random setback was exercised")
	var rescued = preload("res://earnings.gd").new(false)
	rescued.cash = rescued.TREATMENT_GOAL - rescued.CLOSING_BONUS
	rescued.grandpa.health = 1
	rescued.start_day()
	rescued.correct_orders = 1
	rescued.finish_day()
	require(rescued.cash == 15000 and rescued.grandpa.health == 1 and not rescued.grandpa.is_dead(),"Reaching goal with closing bonus saves Grandpa before daily decline")
	# Trigger the actual ending through the final cleanup task.
	var campaign = preload("res://earnings.gd").new(false)
	campaign.cash = 3500
	campaign.grandpa.days = 20
	campaign.grandpa.health = 1
	root.set_meta("pie_day_wallet",campaign)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.shift.start_demo()
	game.shift.begin_cleanup()
	for task in game.shift.tasks: game.shift.complete_task(task)
	require(game.shift.phase == "game_over","Fatal closing ends the shift instead of offering tomorrow")
	game.shift.begin_prep()
	game.shift.start_demo()
	require(game.shift.phase == "game_over" and not game.shift.start_shift(),"Shift/debug restart cannot bypass death")
	await settle()
	require(current_scene.scene_file_path == "res://grandpa_ending.tscn","Fatal day shows the ending scene")
	require(current_scene.earnings == campaign and not paused,"Ending retains campaign results and accepts input")
	if DisplayServer.get_name() != "headless":
		require(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"Ending buttons have a visible cursor")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/grandpa-death-ending.png")
	# Every public scene entry point must honor a saved death.
	for path in ["res://intro.tscn","res://main.tscn","res://hospital_room.tscn"]:
		preload("res://hospital_travel.gd").go(current_scene,path,campaign)
		await settle()
		require(current_scene.scene_file_path == "res://grandpa_ending.tscn","Saved death is respected by "+path)
	current_scene.new_game_button.pressed.emit()
	require(current_scene.restart_dialog.visible,"Starting over requires an explicit confirmation")
	current_scene.restart_dialog.hide()
	require(campaign.grandpa.is_dead(),"Canceling restart keeps the completed campaign")
	current_scene.start_new_campaign()
	await settle()
	require(current_scene.scene_file_path == "res://intro.tscn","Confirmed restart returns to the introduction")
	var fresh = root.get_meta("pie_day_wallet")
	require(fresh.cash == 0 and fresh.grandpa.health == 100 and fresh.grandpa.days == 0 and not fresh.save_enabled,"New campaign resets all progress without touching the real save in tests")
	if failures == 0: print("PASS: daily/setback death, zero clamp, last-day funding, saved death, blocked continuation, ending UI, all reload paths and explicit new campaign")
	current_scene.queue_free()
	await process_frame
	root.remove_meta("pie_day_wallet")
	quit(1 if failures else 0)
