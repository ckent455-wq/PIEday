extends SceneTree
func _initialize(): call_deferred("run")
func run():
 root.set_meta("pie_day_wallet",preload("res://earnings.gd").new(false))
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene=game
 game.set_physics_process(false)
 game.shift.start_demo()
 var shift=game.shift
 shift.set_process(false)
 shift.customer_line.next_arrival=INF
 shift._reset_customer()
 var actor=shift.customer_line.make_actor(Vector3(-2.4,-.094,-3.6),"robber_1")
 shift._bind_customer_actor(actor)
 shift.phase="waiting"
 shift.walking=false
 var ai=shift.robbery
 game.player.position=game.spawn_point
 await physics_frame
 await physics_frame
 ai.tick(.016)
 assert(ai.remaining==5.0 and ai.shots_fired==0)
 ai.tick(4.9)
 assert(ai.shots_fired==0 and not ai.blackout.visible,"No shot before five seconds")
 ai.base_accuracy=0
 ai.rng.seed=12345
 ai.tick(.11)
 assert(ai.shots_fired==1 and not ai.blackout.visible,"A missed shot leaves a chance to escape")
 ai.tick(.4)
 assert(ai.shots_fired==1,"Robber cannot fire continuously")
 game.player.position=Vector3(4.25,.03,-12.3)
 await physics_frame
 assert(not ai.can_see(game.player.position),"Kitchen cover blocks shots")
 ai.remaining=0
 ai.shot_cooldown=0
 var shots:int=ai.shots_fired
 ai.tick(.016)
 assert(ai.shots_fired==shots and not ai.blackout.visible,"No shot through walls")
 ai.remaining=60
 var start:Vector3=actor.position
 for frame in 750:
  ai.tick(1.0/60)
  await physics_frame
 print("CHASE start=",start," end=",actor.position," target=",game.player.position," path=",ai.chase.route.size())
 assert(actor.position.distance_to(game.player.position)<2.8 and actor.position.distance_to(game.player.position)>1.5,"Robber navigates from counter into kitchen")
 print("PASS: five-second grace, missed shot survival, fire cooldown, solid-cover visibility and collision-safe pursuit into kitchen")
 quit()
