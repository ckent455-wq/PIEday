extends SceneTree
func _initialize():call_deferred("check")
func check():
 var editor=load("res://main.tscn").instantiate()
 editor.set_script(null)
 root.add_child(editor)
 var expected={}
 for name in ["Stoves","StainlessPrepCounter","SidePrepSurface"]:
  expected[name]=editor.get_node("DinerLayout/"+name).global_transform
 editor.free()
 root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 for name in expected:
  assert(game.get_node("DinerLayout/"+name).global_transform.is_equal_approx(expected[name]),name+" editor/game position mismatch")
 assert(game.get_node("DinerLayout").find_child("Stove_001",true,false)==null)
 var prep=game.shift.burger_station.prep
 var counter=game.get_node("DinerLayout/StainlessPrepCounter")
 assert(is_equal_approx(counter.to_local(prep.global_position).y,0.0925))
 print("PASS: saved editor and runtime stove/counter transforms match; no obsolete stove; burger prep follows moved counter")
 quit()
