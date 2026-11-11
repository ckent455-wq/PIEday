extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var wallet=preload("res://earnings.gd").new(false)
	wallet.cash=1000
	root.set_meta("pie_day_wallet",wallet)
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.shift.set_process(false)
	game.shift.start_demo()
	assert(wallet.lose_shift_takings()==0 and wallet.cash==1000,"No earnings means no savings can be stolen")
	var earned := 0
	for i in 4: earned += wallet.payout(["Coffee"],true,30,false).total
	assert(wallet.shift_takings==earned and wallet.cash==1000+earned)
	assert(game.shift.maintenance.break_appliance("coffee"))
	assert(game.shift.maintenance.repair("coffee"))
	assert(wallet.shift_takings==earned-250)
	var stolen: int = wallet.lose_shift_takings()
	assert(stolen==earned-250 and wallet.cash==1000,"Repairs spend new earnings first and theft preserves old savings")
	assert(wallet.robbery_losses==stolen and wallet.day_total()==250,"Summary subtracts actual robbery losses")
	assert(wallet.lose_shift_takings()==0 and wallet.cash==1000,"Repeated robbery cannot steal the same earnings twice")
	var next: int = wallet.payout(["Apple pie"],true,30,false).total
	assert(wallet.lose_shift_takings()==next and wallet.cash==1000,"Later robberies take only money earned since the previous robbery")
	wallet.payout(["Coffee"],true,30,false)
	var banked: int = wallet.cash
	wallet.start_day()
	assert(wallet.lose_shift_takings()==0 and wallet.cash==banked and wallet.robbery_losses==0,"Starting the next shift protects earlier earnings")
	wallet.payout(["Coffee"],true,30,false)
	var saved: Dictionary = preload("res://save_states.gd").capture(game)
	assert(saved.wallet.shift_takings==wallet.shift_takings)
	var guest=preload("res://earnings.gd").new(false)
	var coop=preload("res://coop_session.gd").new()
	coop._apply_wallet(guest,coop._wallet_state(wallet))
	assert(guest.shift_takings==wallet.shift_takings and guest.robbery_losses==wallet.robbery_losses)
	coop.free()
	wallet.save_path="res://builds/robbery-takings-test.cfg"
	wallet.save_enabled=true
	wallet._save()
	var loaded=preload("res://earnings.gd").new(true,wallet.save_path)
	assert(loaded.cash==wallet.cash and loaded.shift_takings==wallet.shift_takings and loaded.robbery_losses==wallet.robbery_losses)
	wallet.save_enabled=false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(wallet.save_path))
	print("PASS: previous savings protected, current earnings stolen once, repairs accounted for, day reset, loss summary, manual/autosave and co-op accounting")
	quit()
