extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func require(ok: bool, message: String):
	if not ok:
		push_error(message)
		failures += 1
func run():
	var wallet = preload("res://earnings.gd").new(false)
	wallet.cash = 14999
	require(not wallet.complete_campaign(),"Cannot win before reaching the treatment goal")
	wallet.cash = 15000
	wallet.grandpa.days = 12
	wallet.grandpa.health = 1
	require(wallet.complete_campaign(),"Funding while Grandpa lives completes the campaign")
	require(wallet.grandpa.campaign_won and wallet.grandpa.health == 100 and wallet.grandpa.victory_day == 12,"Victory records recovery and completion day")
	var config := ConfigFile.new()
	wallet.grandpa.write_config(config)
	var loaded = preload("res://grandpa_progress.gd").new()
	loaded.read_config(config)
	require(loaded.campaign_won and loaded.victory_day == 12,"Victory persists across save/load")
	loaded.advance_day(false)
	require(loaded.days == 12 and loaded.health == 100,"Completed campaign cannot keep declining")
	var dead = preload("res://earnings.gd").new(false)
	dead.cash = 15000
	dead.grandpa.health = 0
	require(not dead.complete_campaign(),"Funding cannot undo Grandpa's death")
	root.set_meta("pie_day_wallet",wallet)
	var scene = load("res://grandpa_victory.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set_process(false)
	scene.elapsed = 3.5
	scene._update_shot()
	require(scene.grandpa.position.z > 3.8 and scene.front_door.rotation.y != scene.closed_angle,"Grandpa enters through an open front door")
	require(not scene.find_child("DINER_Collision",true,false).visible,"Collision helper cannot obscure the entrance")
	scene.elapsed = 7.8
	scene._update_shot()
	require(scene.grandpa.position.z < 3.65 and is_equal_approx(scene.front_door.rotation.y,scene.closed_angle),"Door closes only after Grandpa clears the threshold")
	scene.elapsed = 12.0
	scene._update_shot()
	var dancing_position: Vector3 = scene.grandpa.position
	scene.elapsed = 12.2
	scene._update_shot()
	require(scene.grandpa.position.distance_to(dancing_position) > .02,"Grandpa dances with lateral steps and a bounce")
	require(is_equal_approx(scene.camera.position.x,.76),"Camera stays in clear center aisle")
	scene.elapsed = scene.DIALOGUE_AT
	scene._process(0)
	require(scene.state == "speech" and scene.speech.visible and not scene.body_text.text.is_empty(),"Homecoming reaches populated retro dialogue")
	for i in scene.LINES.size()*2:
		scene.advance()
		await process_frame
	require(scene.state == "credits_fade" and not scene.end_card.visible and not paused,"Finishing dialogue begins the credits fade")
	require(scene.music.playing and scene.music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,"Victory music continues through the credits transition")
	scene._advance_credits(scene.fade_countdown + 0.01)
	require(scene.state == "credits" and scene.credits.visible and is_equal_approx(scene.opening.modulate.a, 1.0),"Credits roll begins over a black screen")
	scene._advance_credits(scene.CREDITS_SECONDS + scene.FADE_SECONDS)
	require(scene.state == "ending" and scene.end_card.visible and not scene.credits.visible,"Credits lead to the victory card")
	scene.replay()
	require(scene.state == "walk" and scene.elapsed == 0 and not scene.end_card.visible,"Cutscene can be replayed")
	scene.finish()
	scene.free()
	root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	game.shift.set_process(false)
	game.shift.earnings.cash = 14700
	game.shift.earnings.correct_orders = 1
	game.shift.earnings.grandpa.health = 1
	game.shift._show_day_summary()
	require(game.shift.phase == "game_over" and game.shift.earnings.cash == 15000 and game.shift.earnings.grandpa.campaign_won,"Closing bonus can reach goal before health decline and launch victory")
	await create_timer(1.1).timeout
	require(current_scene.scene_file_path == "res://grandpa_victory.tscn","Winning shift travels to the victory cutscene")
	require(current_scene.earnings.save_enabled == false,"Preview/testing wallet remains non-persistent")
	# Restart uses the same wallet persistence choice and resets victory flags.
	current_scene.start_new_campaign()
	await create_timer(1.1).timeout
	require(current_scene.scene_file_path == "res://intro.tscn","New campaign remains available")
	var fresh = root.get_meta("pie_day_wallet")
	require(fresh.cash == 0 and not fresh.grandpa.campaign_won and fresh.grandpa.health == 100,"New campaign clears victory and restores Grandpa")
	if failures == 0: print("PASS: funding threshold, recovery, persisted victory, death protection, entrance/dialogue/replay, closing-bonus win and new campaign")
	quit(failures)
