extends SceneTree
func _initialize(): call_deferred("check")
func check():
 root.set_meta("pie_day_wallet", preload("res://earnings.gd").new(false))
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 await process_frame
 await physics_frame
 game.set_physics_process(false)
 var shift = game.shift
 shift.set_process(false)
 var station = shift.burger_station
 station.use("burger_raw")
 assert(shift.carried_item.is_empty(),"No extra opening duty")
 shift.donut_fryer.stock = [6,6,6]
 assert(shift.start_shift())
 for target in [station.raw_tray,station.prep,station.grill]:
  game.player.position = Vector3(-1.5,0.03,target.global_position.z)
  game.camera.look_at(target.global_position)
  await physics_frame
  await physics_frame
  game._update_interaction()
  assert(game.target_action == target,"Burger targets reachable beside real flat top")
 station.use("burger_raw")
 assert(shift.carried_item == "Raw patty")
 assert(not shift.place_carried(),"Raw meat cannot enter serving tray")
 station.use("burger_prep")
 assert(shift.carried_item == "Raw patty", "Bun tray must reject raw meat")
 station.use("burger_grill")
 assert(station.cooking and shift.carried_item.is_empty() and station.audio.playing)
 station.tick(2)
 station.use("burger_grill")
 assert(station.flipped_at < 0)
 station.tick(1.1)
 station.use("burger_grill")
 assert(station.flipped_at >= 0)
 station.tick(3)
 assert(station.quality() == "ready")
 var saved = station.snapshot()
 station.reset()
 station.restore(saved)
 assert(station.quality() == "ready")
 station.use("burger_grill")
 assert(shift.carried_item == "Cooked patty" and not station.audio.playing)
 assert(not shift.place_carried(),"Patty needs bun")
 station.use("burger_raw")
 assert(shift.carried_item == "Cooked patty", "Raw tray must not assemble cooked food")
 station.use("burger_prep")
 assert(shift.carried_item == "Burger")
 for topping in ["Cheese", "Tomato", "Lettuce"]:
  var bin = station.get_node(topping + "Bin")
  var origin = Vector3(4.5, 2.0, bin.global_position.z)
  assert(game.interaction_at(origin, origin.direction_to(bin.global_position)).action == bin)
  shift.interact(bin)
  var dressed = shift.carried_item
  shift.interact(bin)
  assert(shift.carried_item == dressed, "A topping cannot be added twice")
 assert(shift.carried_item == "Deluxe burger")
 assert(shift.place_carried() and shift.tray == ["Deluxe burger"])
 shift.customer_line.nude_chance = 0
 shift._spawn_customer()
 shift.phase = "waiting"
 shift.order.assign(["Deluxe burger"])
 shift.order_taken = true
 assert(shift.serve_order() and shift.earnings.sales == 10,"Correct burger order pays")
 shift.phase = "arriving"
 station.use("burger_raw")
 station.use("burger_grill")
 station.tick(13)
 assert(station.quality() == "burnt")
 station.use("burger_grill")
 assert(not station.cooking and shift.carried_item.is_empty())
 assert(preload("res://shift.gd").ORDERS.any(func(order):return "Burger" in order))
 print("PASS: physical flat top and prep targeting, raw pickup, two-sided cook, assembly, physical topping bins, deluxe serving/payment, burning, state restoration and burger orders")
 quit()
