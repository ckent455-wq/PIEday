extends SceneTree
func _initialize(): call_deferred("run")
func run():
 root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene=game
 game.set_physics_process(false)
 game.set_process_unhandled_input(false)
 var shift=game.shift
 shift.set_process(false)
 shift.start_demo()
 var fries=shift.FRIES
 var station=shift.burger_station
 for mask in range(8):
  assert(fries.topping_mask(fries.serving_name(mask))==mask)
  shift._clear_tray(false)
  shift.phase="waiting"
  shift._bind_customer_actor(shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),"male_1"))
  shift.pickup_item(fries.SERVING)
  for index in [0,4,5]:
   if not (mask & fries.topping_bit(index)): continue
   var target=station.get_node("CheeseBin" if index==0 else station.ingredient_name(index)+"Dispenser")
   shift.interact(target)
   var before=shift.carried_item
   shift.interact(target)
   assert(before==shift.carried_item,"Duplicate toppings ignored")
  assert(shift.carried_item==fries.serving_name(mask))
  shift.order.assign([fries.serving_name(mask)])
  shift.order_taken=true
  assert(shift.place_carried())
  assert(shift.serve_order(),"Matching fries toppings accepted")
 shift.phase="waiting"
 shift._bind_customer_actor(shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),"male_1"))
 shift.order.assign([fries.serving_name(1)])
 shift.order_taken=true
 shift.pickup_item(fries.serving_name(2))
 assert(shift.place_carried())
 assert(not shift.serve_order(),"Wrong fries topping rejected")
 print("PASS: all eight fries combinations, real topping interactions, duplicates, rendering, matching orders and rejected wrong toppings")
 quit()
