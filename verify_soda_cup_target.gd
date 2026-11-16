extends SceneTree
func _initialize():call_deferred("check")
func check():
 root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 game.set_physics_process(false)
 game.shift.set_process(false)
 game.shift.start_demo()
 await physics_frame
 await physics_frame
 var station=game.shift.soda_station
 var tests=0
 for x in [1.0,1.7,2.4]:
  for z in [-5.2,-5.6]:
   for cup_x in [0.95,1.20,1.45,1.72,1.97,2.22,2.47]:
    for height in [.8,.89,.98]:
     var origin=Vector3(x,2.0,z)
     var aim=Vector3(cup_x,height,-6.43)
     var found=game.interaction_at(origin,(aim-origin).normalized())
     assert(found.action==station.stack,"Cup pickup should work across holder and approach angles")
     tests+=1
 for i in range(3):
  var button=station.get_node("Flavor_"+str(i))
  var origin=Vector3(button.global_position.x,2.0,-5.6)
  assert(game.interaction_at(origin,(button.global_position-origin).normalized()).action==button)
  station.drink_name=station.FLAVORS[i]
  station.apply_flavor()
  var cup=station.machine_cup.global_position+Vector3.UP*.1
  var found=game.interaction_at(origin,(cup-origin).normalized())
  assert(found.action!=station.stack,"Empty-cup hitbox must not steal filled-cup targeting")
  station._finish_brewing()
  await physics_frame
  await physics_frame
  for side in [-0.9, 0.9]:
   var side_origin: Vector3 = origin + Vector3(side, 0, -0.25)
   for offset in [Vector3(-0.16, 0, 0), Vector3.ZERO, Vector3(0.16, 0, 0)]:
    var target = game.interaction_at(side_origin, side_origin.direction_to(cup + offset))
    assert(target.action == station, "Full soda pickup should work from either side of each nozzle")
  game.shift.interact(station)
  assert(game.shift.carried_item == station.FLAVORS[i] and station.state == "empty")
  assert(station.full_cup_target.disabled)
  game.shift.discard_last()
  await physics_frame
  await physics_frame
 game.shift.interact(station.stack)
 assert(station.holding_empty and station.cups_left==9)
 print("PASS: ",tests," empty-cup rays across holder/angles/heights, all flavor buttons, no interception of filled-cup rays and real empty-cup pickup")
 quit()
