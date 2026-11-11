extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func require(ok: bool, message: String):
	if not ok:
		push_error(message)
		failures += 1
func run():
	var wallet = preload("res://earnings.gd").new(false)
	wallet.cash = 1000
	wallet.grandpa.days = 2
	root.set_meta("pie_day_wallet",wallet)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	var shift = game.shift
	shift.set_process(false)
	shift.start_demo()
	var maintenance = shift.maintenance
	shift.order_taken = true
	require(not maintenance.break_appliance("oven"),"Accepted orders cannot lose their equipment")
	shift.order_taken = false
	shift.oven.pie_item = "Apple pie"
	require(not maintenance.break_appliance("oven"),"In-use oven cannot break")
	shift.oven.pie_item = ""
	require(maintenance.break_appliance("oven"),"Idle oven can break")
	require(maintenance.smoke.oven.emitting and maintenance.smoke.oven.visible and maintenance.bangs.oven.playing,"New breakdown starts smoke and a bang")
	require(maintenance.markers.oven.has_node("OutOfOrderSign"),"Broken equipment has a physical out-of-order sign")
	require(not maintenance.item_available("Apple pie") and maintenance.markers.oven.visible,"Broken oven removes pies and shows repair target")
	require(maintenance.break_appliance("grill") and not maintenance.break_appliance("coffee"),"At most two appliances can be broken")
	for i in 100:
		shift._pick_random_order()
		shift.order.assign(maintenance.adapt_order(shift.order))
		require(not shift.order.is_empty() and shift.order.all(func(item): return maintenance.item_available(item)),"Generated orders contain only working menu items")
	wallet.cash = 100
	require(not maintenance.repair("oven") and wallet.cash == 100 and maintenance.is_broken("oven"),"Insufficient money never repairs or charges")
	wallet.cash = 1000
	shift.interact(maintenance.markers.oven)
	require(wallet.cash == 650 and not maintenance.is_broken("oven") and wallet.equipment.spent == 350,"Repair deducts exact cost from surgery fund")
	require(not maintenance.smoke.oven.emitting and not maintenance.smoke.oven.visible and not maintenance.bangs.oven.playing,"Repair removes smoke and stops breakdown sound")
	shift.interact(maintenance.markers.oven)
	require(wallet.cash == 650,"Repeated repair action cannot double-charge")
	require(maintenance.item_available("Meat pie"),"Repaired appliance restores menu")
	var config := ConfigFile.new()
	config.set_value("save","state",preload("res://save_states.gd").capture(game))
	var decoded := ConfigFile.new()
	require(decoded.parse(config.encode_to_text()) == OK,"Manual equipment state is serializable")
	var saved: Dictionary = decoded.get_value("save","state")
	require(saved.wallet.equipment.broken.has("grill") and saved.wallet.equipment.spent == 350,"Manual saves retain equipment and repair spending")
	var coop = preload("res://coop_session.gd").new()
	var shared: Dictionary = coop._wallet_state(wallet)
	var guest = preload("res://earnings.gd").new(false)
	coop._apply_wallet(guest,shared)
	require(guest.cash == 650 and guest.equipment.broken.has("grill"),"Co-op wallet shares broken equipment and repair balance")
	coop.free()
	var path := "res://builds/appliance-test.cfg"
	wallet.save_path = path
	wallet.save_enabled = true
	wallet._save()
	var loaded = preload("res://earnings.gd").new(true,path)
	require(loaded.equipment.broken.has("grill") and loaded.cash == 650,"Autosave retains broken equipment across visits/restarts")
	wallet.save_enabled = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	wallet.equipment.broken.clear()
	shift.phase = "prep"
	shift.order_taken = false
	shift.donut_fryer.reset()
	require(maintenance.break_appliance("fryer"),"Fryer can break with depleted stock")
	shift.tutorial.tutorial_state = "done"
	require(shift.start_shift(),"Broken fryer cannot soft-lock opening prep")
	wallet.equipment.broken.clear()
	wallet.equipment.roll_day = -1
	wallet.grandpa.days = 0
	maintenance.begin_shift(true)
	require(not wallet.equipment.pending,"First shift cannot have random breakdowns")
	wallet.grandpa.days = 2
	wallet.equipment.roll_day = -1
	wallet.equipment.seed = 8934
	maintenance.begin_shift(true)
	var scheduled: Dictionary = wallet.equipment.duplicate(true)
	maintenance.begin_shift(true)
	require(wallet.equipment == scheduled,"Restarting same day cannot reroll breakdown")
	wallet.equipment.pending = true
	wallet.equipment.break_at = 120
	shift.shift_remaining = 100
	maintenance.before_customer()
	require(wallet.equipment.broken.size() == 1 and not wallet.equipment.pending,"Scheduled failure occurs between customers only once")
	if failures == 0: print("PASS: idle-only breakdowns, menu filtering, repair charges, soft-lock prevention, persistence, co-op state and stable daily scheduling")
	quit(failures)
