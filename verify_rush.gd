extends SceneTree
func _initialize(): call_deferred("check")
func check():
 root.set_meta("pie_day_wallet", preload("res://earnings.gd").new(false))
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.set_physics_process(false)
 var shift = game.shift
 shift.set_process(false)
 shift.customer_line.nude_chance = 0.0
 shift.donut_fryer.stock = [8,8,8]
 assert(shift.start_shift())
 shift.shift_remaining = 180.1
 shift._process(0.2)
 assert(shift.rush_active() and shift.shift_clock.text.begins_with("RUSH"))
 shift.customer_line.tick(0.2)
 assert(shift.customer_line.next_arrival <= 3.0)
 if not is_instance_valid(shift.customer): shift._spawn_customer()
 shift.phase = "waiting"
 shift.order.assign(["Burger"])
 shift.interact(shift.customer.get_node("Interaction"))
 assert(shift.rush_order)
 shift.dialogue.finish()
 shift.shift_remaining = 149.9
 assert(not shift.rush_active())
 var saved = preload("res://save_states.gd").capture(game)
 assert(saved.shift.rush_started and saved.shift.rush_order)
 assert(shift.add_item("Burger") and shift.serve_order())
 assert(shift.earnings.tips >= shift.RUSH_TIP)
 shift.begin_prep(false)
 assert(not shift.rush_started and not shift.rush_order)
 print("PASS: rush countdown, faster arrivals, order qualification, bonus after rush ends, save fields and next-day reset")
 quit()
