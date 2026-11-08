extends SceneTree
func _initialize(): call_deferred("check")
func check():
 root.set_meta("pie_day_wallet", preload("res://earnings.gd").new(false))
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 var shift = game.shift
 shift.set_process(false)
 var sign = shift.open_sign
 sign.use()
 assert(shift.phase == "prep")
 shift.donut_fryer.stock = [6,6,6]
 await process_frame
 await physics_frame
 game.set_physics_process(false)
 game.player.rotation.y = 0
 game.player.position = Vector3(-2.45,0.03,2.0)
 game.camera.look_at(sign.global_position)
 game.pitch = game.camera.rotation.x
 await physics_frame
 await physics_frame
 game._update_interaction()
 print("TARGET ",game.target_action," camera ",game.camera.global_position)
 assert(game.target_action == sign, "Window sign must be targetable from inside")
 shift.interact(sign)
 assert(shift.phase == "arriving")
 sign._process(0)
 assert(sign.opened and sign.neon_light.light_energy > 0)
 shift.closing_time = true
 sign._process(0)
 assert(not sign.opened and sign.neon_light.light_energy == 0)
 print("PASS: prep gate, physical window targeting, opens service and closes at closing time")
 quit()

