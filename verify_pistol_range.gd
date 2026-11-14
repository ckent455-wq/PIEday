extends SceneTree
func _initialize(): call_deferred("run")
func run():
 root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene=game
 game.set_physics_process(false)
 var shift=game.shift
 shift.start_demo()
 shift.set_process(false)
 shift._reset_customer()
 var actor=shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),"robber_1")
 shift._bind_customer_actor(actor)
 shift.phase="waiting"
 shift.walking=false
 shift.carried_item="Pistol"
 shift._refresh_carried()
 await physics_frame
 await physics_frame
 var eye=Vector3(-2.4,2,1)
 var aim:Vector3=actor.global_position+Vector3(0,1.7,0)
 assert(eye.distance_to(aim)>2.7)
 assert(shift.pistol.fire_ray(eye,Vector3.UP))
 assert(shift.carried_item=="Pistol" and shift.refusal_required(),"Misses fire without losing pistol")
 var wall=StaticBody3D.new()
 root.add_child(wall)
 var collision=CollisionShape3D.new()
 var box=BoxShape3D.new()
 box.size=Vector3(2,3,.2)
 collision.shape=box
 wall.add_child(collision)
 wall.position=Vector3(-2.4,1.5,-1)
 await physics_frame
 assert(shift.pistol.fire_ray(eye,eye.direction_to(aim)))
 assert(shift.refusal_required(),"Cover stops player bullets")
 wall.queue_free()
 await physics_frame
 await physics_frame
 game.player.position=eye-Vector3.UP*2
 game.camera.look_at(aim)
 game._update_interaction()
 assert(not is_instance_valid(game.target_action),"Robber is beyond item interaction range")
 game._interact()
 assert(shift.robbery.robber_health==50 and shift.refusal_required(),"Distant hit damages robber")
 game._interact()
 assert(not shift.refusal_required() and shift.corpses.bodies.size()==1,"Real firing input hits robber beyond interaction range")
 print("PASS: long-range firing input, misses retain gun, cover blocks bullets, distant robber can be defeated")
 quit()
