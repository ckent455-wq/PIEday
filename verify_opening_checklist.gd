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
 shift._refresh_hud()
 assert(shift.phase=="prep" and shift.order_panel.visible and shift.order_heading.text=="OPENING CHECKLIST")
 assert(not shift.start_shift(),"Checklist respects existing opening requirements")
 shift.donut_fryer.stock=[6,0,0]
 var station=shift.burger_station
 station.take_produce(station.TOMATO_INDEX)
 shift.interact(station.get_node("TomatoBin"))
 shift._refresh_hud()
 assert(shift.order_text.text.contains("✓  Stock strawberry donuts"))
 assert(shift.order_text.text.contains("○  Stock chocolate donuts"))
 assert(shift.order_text.text.contains("✓  Restock tomatoes"))
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 await create_timer(.4).timeout
 shift.donut_fryer.stock=[6,6,6]
 for index in [station.ONION_INDEX,station.LETTUCE_INDEX,station.CHEESE_INDEX]:
  station.take_produce(index)
  shift.interact(station.get_node({0:"CheeseBin",1:"LettuceBin",3:"OnionBin"}[index]))
 shift._refresh_hud()
 assert(shift.order_text.text.contains("Switch on the OPEN sign"))
 assert(shift.start_shift())
 shift._refresh_hud()
 assert(shift.order_heading.text!="OPENING CHECKLIST","Checklist yields to customer HUD")
 shift.begin_cleanup()
 shift._refresh_hud()
 assert(shift.order_heading.text=="CLOSING CHECKLIST")
 print("PASS: live partial donut/produce completion, existing opening gates, ready sign prompt, service transition and unchanged closing checklist")
 quit()
