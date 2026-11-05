extends SceneTree
func _initialize(): call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.shift.earnings.save_enabled=false
 game.set_physics_process(false)
 game.set_process_unhandled_input(false)
 game.shift.set_process(false)
 for yaw in [0.0,PI/2,PI,-PI/2]:
  for tilt in [-1.2,0.0,1.2]:
   game.player.rotation.y=yaw
   game.camera.rotation=Vector3(tilt,.6,0)
   var facing: Vector3=-game.camera.global_basis.z
   facing.y=0
   assert(game._movement_direction(Vector2(0,-1)).is_equal_approx(facing.normalized()),"W follows view at every yaw and pitch")
   assert(game._movement_direction(Vector2(0,1)).is_equal_approx(-facing.normalized()))
   assert(is_equal_approx(game._movement_direction(Vector2(1,-1)).length(),1.0))
 game.face_point(Vector3(-1.7,.56,-19.1))
 assert(is_zero_approx(game.camera.rotation.y) and is_equal_approx(game.pitch,game.camera.rotation.x))
 print("PASS: camera-relative forward/backward/diagonal movement and synchronized test yaw/pitch")
 quit()
