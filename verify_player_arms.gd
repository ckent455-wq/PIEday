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
 shift.start_demo()
 shift.set_process(false)
 var arms=shift.serving_arms
 arms.refresh(0)
 assert(arms.active_pose.is_empty())
 assert(arms.find_children("*","CollisionObject3D",true,false).is_empty(),"Viewmodel cannot obstruct interaction rays")
 for item in ["Apple pie","Burger","Fries","Coffee","Cola","Glazed donut"]:
  shift._clear_carried(false)
  assert(shift.pickup_item(item))
  assert(not arms.active_pose.is_empty())
  assert(shift.carried_visual.position.z > -.8,"Food and hands share a close camera-space grip")
 shift._clear_carried(false)
 for station in [shift.coffee_station,shift.soda_station]:
  station.interact(station.stack_action)
  arms.refresh(0)
  assert(station.holding_empty and arms.active_pose=="grip")
  assert(station.held_cup.position.is_equal_approx(shift.carried_visual.position))
  station.return_empty()
  arms.refresh(0)
  assert(arms.active_pose.is_empty())
 shift.pickup_item("Glazed donut")
 assert(shift.place_carried())
 assert(arms.active_pose.is_empty() and shift.tray.back()=="Glazed donut")
 shift.carried_item="Pistol"
 shift._refresh_carried()
 assert(arms.active_pose.is_empty() and shift.carried_visual.position==Vector3(.25,-.32,-.8),"Serving pose does not alter pistol aiming")
 shift._clear_carried(false)
 print("PASS: food/drink poses, both empty cup pickups/returns, tray placement, clear state, no collision rays, pistol layout preserved")
 quit()
