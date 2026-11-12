extends SceneTree
func _initialize():call_deferred("check")
func check():
 root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 var shift=game.shift
 shift.set_process(false)
 game.set_physics_process(false)
 var fryer=shift.donut_fryer
 fryer.stock=[6,6,6]
 fryer.refresh()
 shift.burger_station.tomatoes_stocked = true
 shift.burger_station.onions_stocked = true
 shift.burger_station.lettuce_stocked = true
 shift.burger_station.cheese_stocked = true
 assert(shift.start_shift())
 var flavor="Glazed donut"
 var slots=game.find_children("Donus*","MeshInstance3D",true,false).filter(func(mesh):return mesh.get_meta("item","")==flavor)
 var chosen=slots.filter(func(mesh):return mesh.visible)[2]
 fryer.use_case(flavor,chosen)
 assert(not chosen.visible and fryer.stock[2]==5 and shift.carried_source==chosen)
 var id=preload("res://save_states.gd").source_id(shift,chosen)
 assert(preload("res://save_states.gd").source_node(shift,id)==chosen)
 var saved=fryer.snapshot()
 fryer.reset()
 fryer.restore(saved)
 assert(not chosen.visible and slots.filter(func(mesh):return mesh.visible).size()==5)
 shift.discard_last()
 assert(chosen.visible and fryer.stock[2]==6)
 fryer.use_case(flavor,chosen)
 assert(shift.place_carried())
 shift.discard_last()
 assert(chosen.visible and fryer.stock[2]==6)
 for i in range(6):
  var visible=slots.filter(func(mesh):return mesh.visible)
  assert(visible.size()==6-i)
  fryer.use_case(flavor,visible[0])
  shift._clear_carried(false)
 assert(fryer.stock[2]==0 and slots.all(func(mesh):return not mesh.visible))
 fryer.use_case(flavor)
 assert(shift.carried_item.is_empty())
 var target=game.find_children("Fryer*","MeshInstance3D",true,false)[0]
 fryer.use(target)
 fryer.tick(5.1)
 fryer.use(target)
 fryer.use_case(flavor)
 assert(fryer.stock[2]==6 and slots.filter(func(mesh):return mesh.visible).size()==6)
 fryer.use(target)
 fryer.tick(5.1)
 fryer.use(target)
 fryer.use_case(flavor)
 assert(fryer.stock[2]==8 and fryer.batches[0].remaining==4)
 var partial=fryer.snapshot()
 fryer.reset()
 fryer.restore(partial)
 assert(fryer.batches[0].remaining==4)
 fryer.use_case("Strawberry donut")
 assert(fryer.stock[0]==8 and fryer.batches[0].remaining==2)
 fryer.use_case("Chocolate donut")
 assert(fryer.stock==[8,8,8] and fryer.batches[0].state=="empty")
 assert(game.find_children("Donus*","MeshInstance3D",true,false).all(func(mesh):return mesh.visible))
 print("PASS: exact donut disappears, hand/tray returns restore stock, save source identity, all six deplete, empty pickup blocked and fresh frying restocks six visible donuts")
 quit()
