extends SceneTree
func _initialize(): call_deferred("run")
func run():
 root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene=game
 game.set_physics_process(false)
 game.shift.set_process(false)
 var prompt=game.interaction_label
 prompt.text="[E] Add ketchup — Hold a burger or fries"
 prompt.show()
 assert(prompt.keycap.text=="E" and prompt.title.text=="ADD KETCHUP" and prompt.detail.visible)
 prompt.text="Cleaning kitchen... 75%"
 assert(prompt.keycap.text=="!" and not prompt.detail.visible)
 prompt.text="[Click / E] Fire · [Q] Return pistol"
 assert(prompt.keycap.text=="E / LMB" and prompt.detail.text=="[Q] Return pistol")
 assert(prompt.mouse_filter==Control.MOUSE_FILTER_IGNORE)
 game.shift.dialogue.show_pages([["CUSTOMER","Coffee, please."]])
 assert(not prompt.visible and paused)
 game.shift.dialogue.finish()
 assert(not paused)
 prompt.text="[E] Take customer's order"
 prompt.show()
 assert(prompt.visible and prompt.title.text=="TAKE CUSTOMER'S ORDER")
 print("PASS: prompt key badges, details, status updates, passive input, dialogue hiding and restoration")
 quit()
