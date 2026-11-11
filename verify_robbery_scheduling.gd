extends SceneTree
func _initialize(): call_deferred("run")
func advance(shift,seconds: float):
	for frame in int(seconds*60): shift._process(1.0/60)
func run():
	var wallet=preload("res://earnings.gd").new(false)
	wallet.cash=1000
	root.set_meta("pie_day_wallet",wallet)
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.shift.set_process(false)
	var shift=game.shift
	shift.start_demo()
	var line=shift.customer_line
	line.nude_chance=0
	line.next_arrival=INF
	advance(shift,4)
	assert(shift.phase=="waiting" and not shift.refusal_required())
	line.nude_chance=1
	line.last_was_nude=false
	assert(not line._roll_robber(),"Waiting for an unaccepted order cannot trigger a robber")
	shift.order_taken=true
	for position in [Vector3(4.25,.03,-12.3),Vector3(.7,.03,-18),Vector3(-2.95,.03,-4.8)]:
		game.player.position=position
		assert(not shift.robbery.can_start_encounter(),"Kitchen/freezer/appliance positions cannot trigger a robber")
		for sample in 10: assert(not line._roll_robber())
	game.player.position=game.spawn_point
	assert(line._roll_robber(),"Accepted order at the front counter permits a robbery")
	shift.closing_time=true
	assert(not line._roll_robber(),"No new robberies after closing")
	shift.closing_time=false
	line.next_arrival=0
	shift._process(.016)
	assert(shift.refusal_required() and shift.phase=="arriving")
	game.player.position=Vector3(4.25,.03,-12.3)
	advance(shift,15)
	assert(not shift.walking and shift.phase=="arriving" and not shift.dialogue.is_open,"Demand waits when staff leave the counter before arrival")
	assert(shift.robbery.remaining<0 and not shift.robbery.blackout.visible and wallet.cash==1000,"Working in back cannot silently start a countdown or steal money")
	game.player.position=game.spawn_point
	shift._process(.016)
	assert(shift.dialogue.is_open and shift.phase=="waiting")
	assert(shift.robbery.remaining<0,"Dialogue preserves the full reaction window")
	shift.dialogue.finish()
	shift.robbery.tick(.016)
	assert(shift.robbery.remaining==shift.robbery.REACTION_SECONDS)
	game.player.position=Vector3(4.25,.03,-12.3)
	shift.robbery.tick(.25)
	assert(shift.robbery.remaining<shift.robbery.REACTION_SECONDS,"An announced robbery still requires a response")
	shift.robbery.remaining=-1
	shift.robbery.tick(10)
	assert(shift.robbery.remaining<0 and wallet.cash==1000,"Restored unarmed countdown stays safe in the kitchen")
	var coop=preload("res://coop_session.gd").new()
	game.coop=coop
	coop.partner_ready=true
	coop.partner_target=game.spawn_point
	assert(shift.robbery.staff_at_counter(),"Co-op partner can staff the service counter")
	coop.partner_ready=false
	assert(not shift.robbery.staff_at_counter(),"Disconnected partners cannot trigger a robbery")
	game.coop=null
	coop.free()
	print("PASS: counter/order-only scheduling, kitchen/freezer safety, deferred demand, full reaction window, restore safety and co-op staff detection")
	quit()
